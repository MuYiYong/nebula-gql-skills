import json
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

    def test_grammar_functions_literals_and_ordinary_names_are_not_identifiers(self):
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
            'FILE f {name STRING} = DATAFILE {PATH: "file:///test", FORMAT: CSV}',
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
            self.assertEqual(tools.quote_identifier(name, SKILLS[0]), name)
        self.assertEqual(tools.quote_identifier('VerSion', SKILLS[0]), '`VerSion`')
        self.assertEqual(tools.quote_identifier('odd-name', SKILLS[0]), '`odd-name`')
        for invalid in ('', 'a' * 128, 'a`b'):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                tools.quote_identifier(invalid, SKILLS[0])

    def test_standalone_quoting_cli(self):
        for root in SKILLS:
            completed = subprocess.run(
                [sys.executable, '-I', str(root / 'scripts/skill_tools.py'),
                 'quote-identifiers', 'property', 'version', 'person_id'],
                cwd=tempfile.gettempdir(), text=True, capture_output=True, check=True)
            self.assertEqual(json.loads(completed.stdout),
                             {'property': '`property`', 'version': '`version`', 'person_id': 'person_id'})

    def test_keyword_parameters_and_values_are_distinct(self):
        self.assertFalse(tools.lint('RETURN $left + $right AS total', SKILLS[0])['issues'])
        self.assertIn('parameter-quoting', {
            i['rule'] for i in tools.lint('RETURN $`left` + $`right` AS total', SKILLS[0])['issues']})
        self.assertEqual(tools.tokens('$`left`')[0], ('param', '$`left`'))
        for name in ('with', 'graph', 'return', 'left', 'node'):
            report = tools.lint('RETURN $' + name + ' AS result_value', SKILLS[0])
            self.assertFalse(report['issues'], report)

    def test_external_parameter_execution_binding_preserves_names_and_guard(self):
        from quality.runtime import guard, statement
        case = {'oracle': 'contributions', 'stratum': 'database_procedure',
                'parameter_sets': [{'left': 1, 'right': 2}]}
        query = 'RETURN $left + $right AS total'
        guard(query, case)
        compiled = statement(query, case, {'left': 1, 'right': 2})
        self.assertIn('PARAMETERS $left = 1, $right = 2', compiled)
        with self.assertRaisesRegex(ValueError, 'Unexpected parameter'):
            guard('RETURN $`unknown` AS total', case)
        with self.assertRaises(ValueError):
            guard('RETURN $`left` AS total', case)


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
