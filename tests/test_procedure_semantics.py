"""Regression contracts for the four Database procedure diagnostics."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from skill_tools import lint

SKILL = ROOT / 'src/gql-procedure-generator'


def issues(sql, scope='database'):
    return lint(sql, SKILL, scope)['issues']


class ProcedureSemanticTests(unittest.TestCase):
    def diagnostic(self, sql, code, scope='database'):
        found = [i for i in issues(sql, scope) if i.get('code') == code]
        self.assertEqual(len(found), 1, (sql, found))
        result = found[0]
        self.assertGreaterEqual(result['line'], 1)
        self.assertGreaterEqual(result['column'], 1)
        return result

    def test_duplicate_reports_both_declarations(self):
        sql = 'NODE VALUE bank_loan_ids ListAgg<INT64>\nVALUE `bank_loan_ids` INT64 = 0'
        issue = self.diagnostic(sql, 'NS002')
        self.assertEqual((issue['line'], issue['column']), (2, 7))
        for word in ['bank_loan_ids', '1:12', 'rename']:
            self.assertIn(word, issue['message'])
        self.diagnostic('VALUE `x` INT64 = 0\nNODE VALUE x ListAgg<INT64>', 'NS002')

    def test_wrong_global_aggregator_is_not_a_missing_node_aggregator(self):
        for sql, name in [('VALUE `iteration` INT64 = 0\nRETURN @iteration AS `result`', 'iteration'),
                          ('RETURN @hop_attenuation AS `result`', 'hop_attenuation'),
                          ('CREATE PROCEDURE `p`(`hop_attenuation` DOUBLE) AS { '
                           'RETURN CAST(@`hop_attenuation` AS INT64) }', 'hop_attenuation'),
                          ('NODE VALUE `total` SumAgg<INT64> = 0 RETURN @`total`', 'total')]:
            with self.subTest(sql=sql):
                hit = self.diagnostic(sql, '42N56')
                self.assertEqual(hit['rule'], 'undeclared-global-aggregator')
                for word in (name, 'global', 'parameter'):
                    self.assertIn(word, hit['message'])
        self.assertEqual(issues('CREATE PROCEDURE `p`(`hop_attenuation` DOUBLE) AS { '
                                'VALUE `total` SumAgg<INT64> = 0 SET @`total` += 1 '
                                'RETURN `hop_attenuation`, @`total` }'), [])
        self.diagnostic('VALUE `Total` SumAgg<INT64> = 0 RETURN (@`total`)', '42N56')

    def test_type_annotations_are_not_global_references(self):
        for sql in ['MATCH (`n`@`Borrower`) RETURN `n`',
                    'RETURN EXISTS { (@`Borrower`) } AS `ok`',
                    'MATCH (@`Borrower`)-[@`OWNS`]->(@`Account`) RETURN 1',
                    'MATCH (`n`) WHERE `n`@`Borrower` RETURN `n`',
                    'MATCH `p` = WALK (`b`@`Borrower`)((@`Borrower`)-[`e`]->(@`Borrower`)){0,2}(`c`) RETURN `p`']:
            with self.subTest(sql=sql):
                self.assertEqual(issues(sql), [])
        insert = 'INSERT OR REPLACE (@`Borrower` {`id`: 1})'
        self.assertNotIn('42N56', [issue.get('code') for issue in issues(insert)])

    def test_single_node_per_path_preserves_filter_and_edge_intent(self):
        prefix = 'VALUE `total` SumAgg<INT64> = 0\nMATCH (`b`:`Borrower`)'
        tail = ' { SET @`total` += 1 }'
        for predicate in ['', ' WHERE `b`.`id` > 0', ' WHERE EXISTS { MATCH (`b`)-[]->() RETURN 1 }']:
            with self.subTest(predicate=predicate):
                sql = prefix + predicate + '\nPER PATH' + tail
                hit = self.diagnostic(sql, 'NS238')
                self.assertEqual((hit['line'], hit['column']), (3, 1))
                for word in ('PER NODE', 'WHERE', 'relationship'):
                    self.assertIn(word, hit['message'])
                self.assertEqual(issues(prefix + predicate + ' PER NODE (`b`)' + tail), [])
                self.assertEqual(issues(prefix + '-[`e`]->(`c`)' + predicate + ' PER PATH' + tail), [])

    def test_standalone_cli_reports_global_and_path_locations(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'input.gql'
            path.write_text('MATCH (`b`:`Borrower`) WHERE `b`.`id` > 0\n'
                            'PER PATH { SET @`total` += 1 }')
            run = subprocess.run([sys.executable, '-I', str(SKILL / 'scripts/skill_tools.py'),
                                  'lint', str(path), '--scope', 'database'], cwd=tmp,
                                 text=True, capture_output=True)
            self.assertEqual(run.returncode, 1)
            locations = {(i['code'], i['line'], i['column']) for i in json.loads(run.stdout)['issues']}
            self.assertEqual(locations, {('NS238', 2, 1), ('42N56', 2, 17)})

    def test_independent_scopes_and_case(self):
        sql = ('CALL { VALUE `a` INT64 = 0 RETURN `a` AS `one` }\n'
               'CALL { VALUE `a` INT64 = 1 RETURN `a` AS `two` } RETURN `one`, `two`')
        self.assertEqual(issues(sql), [])
        self.assertEqual(issues('VALUE `State` INT64 = 1 VALUE `state` INT64 = 0'), [])
        self.assertEqual(issues('VALUE `a` INT64 = 0; VALUE `a` STRING = "x"'), [])

    def test_node_aggregator_requires_visible_node_declaration(self):
        use = 'MATCH (`n`) PER NODE (`n`) { SET `n`.@application_borrower_keys += 1 }'
        for prefix in ['', 'VALUE `application_borrower_keys` ListAgg<INT64>\n',
                       'NODE VALUE `Application_borrower_keys` ListAgg<INT64>\n',
                       'CREATE PROCEDURE `old`() AS { NODE VALUE `application_borrower_keys` ListAgg<INT64> FINISH };\n']:
            with self.subTest(prefix=prefix):
                issue = self.diagnostic(prefix + use, '42N56')
                self.assertIn('application_borrower_keys', issue['message'])
                self.assertIn('NODE VALUE', issue['message'])
        self.assertEqual(issues('NODE VALUE `state` SumAgg<INT64> = 0\n'
                                'MATCH (`n`) PER NODE (`n`) { SET `n`.@`state` += `n`.`property` }'), [])
        self.assertEqual(issues('VALUE `state` SumAgg<INT64> = 0\nSET @`state` += 1 RETURN @`state`'), [])

    def test_node_scalar_and_cross_node_update(self):
        for scope in ('database', 'analytics'):
            with self.subTest(scope=scope):
                q = 'RETURN node(1) AS `n`'
                issue = self.diagnostic(q, 'NR002', scope)
                self.assertEqual((issue['line'], issue['column']), (1, 8))
                self.assertIn('MATCH', issue['message'])
                self.assertIn('key', issue['message'])
                q = ('NODE VALUE `state` SumAgg<INT64> = 0\n'
                     'MATCH (`n`) PER NODE (`n`) { VALUE `id` = element_id(`n`) '
                     'SET NODE(`id`).@`state` += 1 }')
                self.assertEqual(issues(q, scope), [])
        self.assertEqual(issues('MATCH (`n`:`Loan` {`id`: 1}) RETURN `n`'), [])
        self.assertEqual(issues('RETURN "node(1), n.@state" AS `node` /* NODE VALUE state */'), [])

    def test_size_overloads_and_targets(self):
        for decl, expr, actual in (
            ('VALUE `x` LIST<INT64> = LIST[]', 'size(`x`)', 'INT32'),
            ('VALUE `x` TYPED SET<INT64>', 'size(`x`)', 'INT32'),
            ('VALUE `x` :: MAP<INT64, STRING>', 'size(`x`)', 'INT32'),
            ('TABLE `x` TYPED TABLE {`k` INT64}', 'size(`x`)', 'INT64'),
            ('VALUE `x` ListAgg<INT64>', '@`x`.size()', 'UINT64'),
        ):
            with self.subTest(expr=expr, decl=decl):
                bad = 'UINT64' if actual != 'UINT64' else 'INT32'
                for assignment in (f'VALUE `count` {bad} = {expr}', f'VALUE `count` {bad} SET `count` = {expr}'):
                    issue = self.diagnostic(decl + '\n' + assignment, 'NS208')
                    for word in (actual, bad, 'count', 'CAST'):
                        self.assertIn(word, issue['message'])
                for target, rhs in [(actual, expr), (bad, f'CAST({expr} AS {bad})')]:
                    self.assertEqual(issues(f'{decl}\nVALUE `count` {target} = {rhs}'), [])

    def test_size_is_conservative_about_visibility_and_expression_type(self):
        cases = [
            'VALUE `q` UINT64 = size($unknown)',
            'VALUE `q` UINT64 = size(`row`.`keys`)',
            'VALUE `x` LIST<INT64> VALUE `q` INT64 = size(`x`)',
            'VALUE `x` LIST<INT64> VALUE `q` BOOL = size(`x`) > 1',
            'VALUE `x` LIST<INT64> SET `unknown` = size(`x`)',
            'CALL { VALUE `x` LIST<INT64> FINISH } VALUE `q` UINT64 = size(`x`)',
        ]
        for sql in cases:
            with self.subTest(sql=sql):
                self.assertNotIn('NS208', [i.get('code') for i in issues(sql)])
        q = ('CREATE PROCEDURE `p`(`keys` LIST<INT64>) AS { '
             'VALUE `q` UINT64 = size(`keys`) FINISH }')
        self.diagnostic(q, 'NS208')

    def test_node_and_global_size_receivers_keep_their_declared_overload(self):
        for agg in ('ListAgg<INT64>', 'SetAgg<INT64>', 'MapAgg<INT64, SumAgg<INT64>>', 'TopKAgg<1, `score` INT64 DESC>'):
            sql = (f'NODE VALUE `state` {agg}\nMATCH (`n`) PER NODE (`n`) {{ '
                   'VALUE `q` UINT64 = `n`.@`state`.size() }')
            with self.subTest(agg=agg):
                self.assertFalse(lint(sql, SKILL)['needs_review'])
                self.assertEqual(issues(sql), [])
                self.diagnostic(sql.replace('UINT64', 'INT32'), 'NS208')

    def test_size_only_uses_complete_known_expressions(self):
        self.diagnostic('VALUE `x` LIST<INT64> VALUE `q` BOOL = size(`x`)', 'NS208')
        self.diagnostic('VALUE `x` = [1, 2] VALUE `q` UINT64 = size(`x`)', 'NS208')
        self.diagnostic('VALUE `d` LIST<INT64> VALUE `q` = CAST(0 AS UINT64) '
                        'SET `q` = (size(`d`))', 'NS208')
        self.assertEqual(issues('VALUE `d` LIST<INT64> VALUE `q` BOOL = (size(`d`) > 0)'), [])
        self.assertFalse([i for i in issues('VALUE `q` UINT64 = size(`custom`(1))') if i.get('code')])

    def test_nested_locals_and_named_procedure_boundaries(self):
        statement = ('CREATE PROCEDURE `one`(`k` LIST<INT64>) AS { VALUE `u` INT32 = size(`k`) FINISH }; '
                     'CREATE PROCEDURE `two`(`k` TABLE) AS { VALUE `u` INT64 = size(`k`) FINISH }')
        self.assertEqual(issues(statement), [])
        self.diagnostic(statement.replace('INT64 = size', 'INT32 = size'), 'NS208')
        self.diagnostic('VALUE `v` INT64 = 0 CALL { VALUE v INT64 = 1 FINISH }', 'NS002')
        self.assertEqual(issues('IF TRUE THEN { VALUE `v` INT64 = 1 RETURN `v` AS `result` } '
                                'ELSE { VALUE `v` INT64 = 2 RETURN `v` AS `result` }'), [])
