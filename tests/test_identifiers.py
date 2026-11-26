import json
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import skill_tools as tools
import refresh_documented_capabilities as refresh

ROOT = Path(__file__).resolve().parents[1]
SKILLS = [ROOT / 'src' / name for name in ('gql-query-generator', 'gql-procedure-generator')]


class IdentifierTests(unittest.TestCase):
    def keyword_issues(self, code, root=SKILLS[0]):
        return [i for i in tools.lint(code, root)['issues']
                if i['rule'] in {'reserved-alias', 'keyword-identifier'}]

    def test_complete_categories_in_both_packages(self):
        catalogs = [json.loads((p / 'references/documented-keywords.json').read_text()) for p in SKILLS]
        self.assertEqual(catalogs[0], catalogs[1])
        self.assertEqual(len(catalogs[0]['reserved']), 224)
        self.assertEqual(len(catalogs[0]['non_reserved']), 207)
        self.assertFalse(set(catalogs[0]['reserved']) & set(catalogs[0]['non_reserved']))

    def test_non_reserved_identifiers_need_quotes(self):
        for root in SKILLS:
            for query in [
                'RETURN 1 AS version',
                'MATCH (p:date) RETURN p.id',
                'MATCH (node:Person) RETURN node',
                'MATCH (p) RETURN p.property',
                'RETURN RECORD {property: 1} AS row_value',
                'USE schema MATCH (p) RETURN p',
                'CREATE PROCEDURE type(property INT64) AS { RETURN property AS version }',
                'VALUE version INT64 = 1 RETURN version',
                'LET property = 1 RETURN property',
                'FOR version IN LIST[1] RETURN version',
                'CALL type() YIELD version RETURN version',
                'CALL type() YIELD result_value RETURN result_value',
                'RETURN version',
                'MATCH (p) RETURN p.id ORDER BY version',
                'RETURN transform(LIST[1], node -> node + 1) AS items',
                'MATCH (p IS Label) RETURN p',
                'MATCH (p @[Person, User]) RETURN p',
            ]:
                with self.subTest(root=root.name, query=query):
                    self.assertTrue(self.keyword_issues(query, root))

    def test_grammar_and_ordinary_names_are_not_keyword_violations(self):
        for query in [
            'MATCH (p:Person)-[:Follows]->(q) RETURN p.id AS person_id ORDER BY person_id ASC',
            'RETURN CAST(1 AS STRING) AS text_value',
            'RETURN CASE WHEN TRUE THEN 1 ELSE 0 END AS score',
            'RETURN CURRENT_DATE AS today',
            'RETURN date("2026-10-25") AS today',
            'RETURN "version" AS text_value // property AS version',
            'RETURN 1 AS value_count /* AS version */',
            'RETURN LIST[1, 2] AS items',
            'VALUE a SumAgg<STRING> = "" RETURN a',
            'MATCH (p) RETURN p.id IS NOT NULL AS has_id',
            'FOR v, ord IN vals WITH ORDINALITY RETURN v, ord',
            'CREATE PROCEDURE IF NOT EXISTS ...',
            'CREATE OR REPLACE PROCEDURE ...',
            'RETURN EXISTS { MATCH ... } AS found',
            'OPTIONS { METRIC: IP, TYPE: HNSW, EFSEARCH: 16 } RETURN 1',
            'FILE f {name STRING} = DATAFILE {`PATH`: "file:///test", `FORMAT`: "CSV"}',
            'RETURN CAST("2026-10-25" AS DATE) AS today',
            'MATCH (p:Person) WHERE p IS NOT NULL RETURN p',
            'TABLE t TYPED TABLE {id INT64} PARTITION BY DEFAULT',
            'MATCH (p:Person) FILTER WHERE p.id = 1 RETURN p',
            'RETURN VALUE { RETURN 1 } AS scalar_value',
        ]:
            with self.subTest(query=query):
                self.assertFalse(self.keyword_issues(query))

    def test_quoted_keyword_identifiers_are_accepted(self):
        self.assertFalse(self.keyword_issues(
            'USE `schema` MATCH (`node`:`date`) '
            'RETURN `node`.`property` AS `version` ORDER BY `version`'))
        self.assertFalse(self.keyword_issues(
            'CREATE PROCEDURE `type`(`property` INT64) AS '
            '{ RETURN `property` AS `version` }'))

    def test_repayment_null_predicate_repair(self):
        query = (
            'MATCH (`b`:`ReportBatch`)-[`cr`:`CONTAINS_RECORD`]->(`r`:`ReportRecord`)'
            '-[`rl`:`REPORTS_LOAN`]->(`l`:`Loan`)-[`hr`:`HAS_REPAYMENT`]->(`rp`:`Repayment`)\n'
            'WHERE `rp`.`due_amount` IS NULL OR `rp`.`paid_amount` < 0 OR `rp`.`due_amount` < 0 '
            'OR (`rp`.`paid_amount` IS NOT NULL AND `rp`.`due_amount` IS NOT NULL '
            'AND `rp`.`paid_amount` > `rp`.`due_amount`) OR `rp`.`due_date` IS NULL\n'
            'RETURN `b`.`batch_id` AS `batch_id`, `r`.`record_id` AS `record_id`, '
            '`l`.`loan_id` AS `loan_id`, `rp`.`repayment_id` AS `repayment_id`, '
            '`rp`.`due_amount` AS `due_amount`, `rp`.`paid_amount` AS `paid_amount`\n'
            'LIMIT 25'
        )
        self.assertFalse(tools.lint(query, SKILLS[0])['issues'])
        invalid = query.replace('IS NOT NULL', 'IS `NOT` NULL')
        self.assertEqual([issue['rule'] for issue in tools.lint(invalid, SKILLS[0])['issues']],
                         ['null-predicate-quoting'])

    def test_branch_null_predicate_repair(self):
        query = (
            'MATCH (`b`:`ReportBatch`)-[`cr1`:`CONTAINS_RECORD`]->(`r1`:`ReportRecord`)'
            '-[`rc1`:`REPORTS_CUSTOMER`]->(`c1`:`Customer`)-[`oa1`:`OWNS_ACCOUNT`]->(`a1`:`Account`)'
            '-[`as1`:`ACCOUNT_SERVICED_BY`]->(`br`:`Branch`), '
            '(`b`)-[`cr2`:`CONTAINS_RECORD`]->(`r2`:`ReportRecord`)'
            '-[`rc2`:`REPORTS_CUSTOMER`]->(`c2`:`Customer`)-[`oa2`:`OWNS_ACCOUNT`]->(`a2`:`Account`)'
            '-[`as2`:`ACCOUNT_SERVICED_BY`]->(`br`)\n'
            'WHERE `c1`.`customer_id` < `c2`.`customer_id` '
            'AND `a1`.`account_id` <> `a2`.`account_id` '
            'AND (`br`.`branch_code` IS NULL OR `br`.`branch_name` IS NULL)\n'
            'RETURN `b`.`batch_id` AS `batch_id`, `c1`.`customer_id` AS `customer_id_1`, '
            '`a1`.`account_id` AS `account_id_1`, `c2`.`customer_id` AS `customer_id_2`, '
            '`a2`.`account_id` AS `account_id_2`, `br`.`branch_id` AS `branch_id`\n'
            'LIMIT 25'
        )
        self.assertFalse(tools.lint(query, SKILLS[0])['issues'])
        invalid = query.replace('IS NULL', 'IS `NULL`')
        self.assertEqual([issue['rule'] for issue in tools.lint(invalid, SKILLS[0])['issues']],
                         ['null-predicate-quoting'])

    def test_quoted_null_predicate_tokens_are_flagged(self):
        for root in SKILLS:
            for predicate in ('IS `NULL`', '`IS` NULL', '`IS` `NULL`', 'is /* gap */ `nOt`\nnull',
                              'IS NOT `NULL`', '`IS` NOT NULL', '`is` `not` `null`'):
                query = f'RETURN (1 {predicate}) AS `checked`'
                with self.subTest(root=root.name, predicate=predicate):
                    rules = [issue['rule'] for issue in tools.lint(query, root)['issues']]
                    self.assertIn('null-predicate-quoting', rules)

    def test_grouped_null_predicate_is_not_a_pattern_label(self):
        for root in SKILLS:
            for query in [
                'LET `n` = NULL RETURN (`n` IS `NULL`) AS `checked`',
                'MATCH (`n`) WHERE ((`n` IS `NULL`)) RETURN `n`',
                'MATCH (`n` WHERE (`n` IS `NULL`)) RETURN `n`',
            ]:
                with self.subTest(root=root.name, query=query):
                    self.assertEqual([issue['rule'] for issue in tools.lint(query, root)['issues']],
                                     ['null-predicate-quoting'])
                    self.assertFalse(tools.lint(query.replace('IS `NULL`', 'IS NULL'), root)['issues'])

    def test_null_predicates_preserve_keyword_identifiers_and_literals(self):
        for root in SKILLS:
            for query in [
                'MATCH (`n` IS `NULL`)-[`e` IS `NOT`]->(IS `NULL`) '
                'WHERE `n`.`NOT` IS NOT NULL RETURN `e`.`NULL` AS `IS`',
                'MATCH (`NOT`) WHERE `NOT` IS NULL RETURN `NOT` AS `NULL`',
                'VALUE `NOT` INT64 = 1 RETURN `NOT` is /* gap */ not\nnull AS `checked`',
                'RETURN "IS `NOT` NULL" AS `text`, 1 AS `NOT` // IS `NOT` NULL',
            ]:
                with self.subTest(root=root.name, query=query):
                    self.assertFalse(tools.lint(query, root)['issues'])

    def test_every_keyword_quotes_without_changing_identifier_spelling(self):
        for root in SKILLS:
            data = json.loads((root / 'references/documented-keywords.json').read_text())
            for word in data['reserved'] + data.get('non_reserved', []):
                name = word.lower()
                with self.subTest(root=root.name, name=name):
                    self.assertEqual(tools.quote_identifier(name, root), '`' + name + '`')
                    self.assertTrue(self.keyword_issues('RETURN 1 AS ' + name, root))
                    self.assertFalse(self.keyword_issues('RETURN 1 AS `' + name + '`', root))

    def test_ordinary_and_special_identifier_formatting(self):
        for name in ('person_id', 'Person', '_score', '客户'):
            self.assertEqual(tools.quote_identifier(name, SKILLS[0]), '`' + name + '`')
        self.assertEqual(tools.quote_identifier('VerSion', SKILLS[0]), '`VerSion`')
        self.assertEqual(tools.quote_identifier('odd-name', SKILLS[0]), '`odd-name`')
        for invalid in ('', 'a' * 128, 'a`b'):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                tools.quote_identifier(invalid, SKILLS[0])

    def test_single_omission_in_an_otherwise_quoted_statement(self):
        statements = [
            'USE /`Tenant`/`schema`.`social` MATCH `path` = TRAIL '
            '(`left`:!(`User`|`date`))-[`edge`@![`Type`,`version`]]->(`right`) '
            'WHERE `edge`.`order` > $limit RETURN `path` AS `result` ORDER BY `result`',
            'CREATE GRAPH TYPE IF NOT EXISTS `network` AS { '
            'NODE `person` (LABEL `User` {`key` INT PRIMARY KEY, `name` STRING}), '
            'EDGE `link` (`person`)-[:`label` {`weight` INT}]->(`person`) }',
            'CALL `schema`.`g`.`compute`(1) YIELD `first`, `second` '
            'RETURN `first`, `second` AS `sum` ORDER BY `sum`',
            'CREATE PROCEDURE `type`(`date` STRING) RETURNS `out` STRING '
            'AS { RETURN `date` AS `out` }',
            'NODE VALUE `nodeSum` SumAgg<INT> = 0 MATCH (`p`@`player`) '
            'PER NODE (`p`) { SET `p`.@`nodeSum` += 1 }',
            'RETURN RECORD {`a`: 1} AS `row` NEXT RETURN `row`.`a` AS `a`',
            'FOR `x` IN LIST[1] RETURN transform(LIST[`x`], `y` -> `y` + `x`) AS `items`',
            'MATCH (`p`) WHERE `p` IS LABELED (`date`|`label`) '
            'RETURN `p` IS ELEMENT TYPED ![`a`, `b`] AS `is_match`',
            'INSERT OR UPDATE (:`User` {`name`: "date"})',
        ]
        rules = {'reserved-alias', 'keyword-identifier', 'unquoted-identifier'}
        for root in SKILLS:
            for query in statements:
                self.assertFalse(tools.lint(query, root)['issues'], query)
                for match in re.finditer(r'`(\w+)`', query):
                    changed = query[:match.start()] + match[1] + query[match.end():]
                    with self.subTest(root=root.name, changed=changed):
                        issues = tools.lint(changed, root)['issues']
                        self.assertTrue(any(i['rule'] in rules for i in issues), issues)

    def test_concrete_examples_follow_generation_policy(self):
        from audit_skill_capabilities import CATALOG_FILES, NEGATIVE_MARKERS, parse_blocks
        rules = {'reserved-alias', 'keyword-identifier', 'unquoted-identifier'}
        for root in SKILLS:
            for path in (root / 'references').glob('*.md'):
                if path.name in CATALOG_FILES:
                    continue
                for block in parse_blocks(path):
                    if block.language != 'gql' or any(m in block.context for m in NEGATIVE_MARKERS):
                        continue
                    # Grammar templates also contain bare metavariables and alternatives.
                    if '...' in block.code or re.search(r'<[\w|]+>', block.code):
                        continue
                    with self.subTest(path=path.name, line=block.line):
                        issues = tools.lint(block.code, root)['issues']
                        self.assertFalse([i for i in issues if i['rule'] in rules])

    def test_literal_and_syntax_roles_in_fully_quoted_output(self):
        for root in SKILLS:
            for query in [
                'USE #graph MATCH (`return`:`DATE`) RETURN `return`.`order` AS `limit`',
                'RETURN CAST($date AS DATE) AS `date`, CURRENT_DATE AS `when`',
                'RETURN MAP {"type": "date"} AS `m`, NULL AS `n`',
                'RETURN 1 AS `score` /* AS order */ ORDER BY `score`',
                'SHOW PROCEDURE ".*version.*"',
                'OPTIONS { METRIC: IP, TYPE: HNSW, EFSEARCH: 16 }',
            ]:
                with self.subTest(root=root.name, query=query):
                    self.assertFalse(tools.lint(query, root)['issues'])
            self.assertEqual(tools.quote_identifier(r'a\\b', root), r'`a\\\\b`')
            with self.assertRaises(ValueError):
                tools.quote_identifier('@visits', root)

    def test_standalone_quoting_cli(self):
        for root in SKILLS:
            completed = subprocess.run(
                [sys.executable, '-I', str(root / 'scripts/skill_tools.py'),
                 'quote-identifiers', 'property', 'version', 'person_id'],
                cwd=tempfile.gettempdir(), text=True, capture_output=True, check=True)
            self.assertEqual(json.loads(completed.stdout),
                             {'property': '`property`', 'version': '`version`', 'person_id': '`person_id`'})

    def test_keyword_parameters_and_values_are_distinct(self):
        self.assertFalse(tools.lint('RETURN $left + $right AS `total`', SKILLS[0])['issues'])
        self.assertIn('parameter-quoting', {
            i['rule'] for i in tools.lint('RETURN $`left` + $`right` AS `total`', SKILLS[0])['issues']})
        self.assertEqual(tools.tokens('$`left`')[0], ('param', '$`left`'))
        for name in ('with', 'graph', 'return', 'left', 'node'):
            report = tools.lint('RETURN $' + name + ' AS `result_value`', SKILLS[0])
            self.assertFalse(report['issues'], report)

    def test_external_parameter_execution_binding_preserves_names_and_guard(self):
        from quality.runtime import guard, statement
        case = {'oracle': 'contributions', 'stratum': 'database_procedure',
                'parameter_sets': [{'left': 1, 'right': 2}]}
        query = 'RETURN $left + $right AS `total`'
        guard(query, case)
        compiled = statement(query, case, {'left': 1, 'right': 2})
        self.assertIn('PARAMETERS $left = 1, $right = 2', compiled)
        with self.assertRaisesRegex(ValueError, 'Unexpected parameter'):
            guard('RETURN $`unknown` AS `total`', case)
        with self.assertRaises(ValueError):
            guard('RETURN $`left` AS `total`', case)


class KeywordSourceTests(unittest.TestCase):
    def write_docs(self, root, non_reserved='DATE PROPERTY VERSION'):
        for scope in ('database', 'analytics'):
            p = root / f'{scope}-gql-reference/overview/keywords-identifiers/index.html'
            p.parent.mkdir(parents=True)
            p.write_text('<article><h2>保留关键字</h2><p>BIG VALUES RETURN MATCH</p>'
                         '<h2>非保留关键字</h2><p>' + non_reserved + '</p></article>')

    def test_both_categories_and_manuals(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.write_docs(root)
            data = json.loads(refresh.render_keywords(root))
            self.assertEqual(data['reserved'], ['BIG', 'MATCH', 'RETURN', 'VALUES'])
            self.assertEqual(data['non_reserved'], ['DATE', 'PROPERTY', 'VERSION'])

    def test_manual_drift_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.write_docs(root)
            p = root / 'analytics-gql-reference/overview/keywords-identifiers/index.html'
            p.write_text(p.read_text().replace('DATE PROPERTY VERSION', 'DATE PROPERTY VERSION EXTRA'))
            with self.assertRaises(ValueError):
                refresh.render_keywords(root)

    def test_parser_comments_do_not_authorize_keywords(self):
        parsed = refresh.parse_parser_keywords(
            '// NG_RESERVED_KEYWORD("IGNORED", X)\n'
            '/*\nNG_NON_RESERVED_KEYWORD("ALSO_IGNORED", Y)\n*/\n'
            'NG_RESERVED_KEYWORD("MATCH", MATCH)\n'
            'NG_NON_RESERVED_KEYWORD("VERSION", VERSION)\n')
        self.assertEqual(parsed, {'reserved': {'MATCH'}, 'non_reserved': {'VERSION'}})


if __name__ == '__main__':
    unittest.main()
