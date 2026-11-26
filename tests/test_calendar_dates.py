import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from skill_tools import lint

SKILLS = [ROOT / 'src' / skill for skill in ('gql-query-generator', 'gql-procedure-generator')]


class CalendarDateTests(unittest.TestCase):
    def test_graph_type_repairs_every_date_and_preserves_source_text(self):
        original = (
            'CREATE GRAPH TYPE `Book` AS {\r\n'
            ' NODE `Row` (LABEL `Row` {`id` STRING PRIMARY KEY,\r\n'
            '   `day` LoCaL date, `stamp` LOCAL DATETIME, `clock` LOCAL TIME,\r\n'
            '   `LOCAL` DATE, `LOCAL DATE` STRING DEFAULT \'LOCAL DATE\'}),\r\n'
            ' EDGE `Link` (`Row`)-[LABEL `Link` {`on` TYPED LOCAL /* keep */ dAtE,\r\n'
            '   `until` :: local\r\n    DATE}]->(`Row`) } // LOCAL DATE\r\n'
        )
        expected = (original.replace('LoCaL date', 'date')
                    .replace('LOCAL /* keep */', '/* keep */')
                    .replace('local\r\n    DATE', '\r\n    DATE'))
        with tempfile.TemporaryDirectory() as tmp:
            candidate = Path(tmp) / 'candidate.gql'
            candidate.write_bytes(original.encode())
            for root in SKILLS:
                with self.subTest(skill=root.name):
                    run = subprocess.run([sys.executable, '-I', str(root / 'scripts/skill_tools.py'),
                                          'lint', str(candidate)], cwd=tmp, text=True, capture_output=True)
                    self.assertEqual(run.returncode, 1)
                    report = json.loads(run.stdout)
                    self.assertEqual([i['rule'] for i in report['issues']], ['local-date-type'] * 3)
                    self.assertEqual(report['corrected_gql'], expected)
                    self.assertFalse(lint(expected, root)['issues'])
                    self.assertNotIn('corrected_gql', lint(expected, root))
            self.assertEqual(candidate.read_bytes(), original.encode())

    def test_type_positions_in_queries_and_procedures(self):
        for candidate in [
            'LOCAL DATE',
            'RETURN CAST($day AS LOCAL DATE)',
            'RETURN CAST($day AS LOCAL -- keep the comment\nDATE)',
            "RETURN LOCAL DATE '2026-11-27'",
            'CREATE PROCEDURE `p`(`d` LOCAL DATE) RETURNS `r` LOCAL DATE AS { RETURN `d` }',
            'VALUE `days` LIST<LOCAL DATE> = LIST[]',
            'TABLE `t` TYPED TABLE {`d` LOCAL DATE}',
            'VALUE `d` :: LOCAL DATE = NULL',
            'VALUE `m` MAP<STRING, LOCAL DATE> = NULL',
        ]:
            for root in SKILLS:
                with self.subTest(skill=root.name, candidate=candidate):
                    report = lint(candidate, root)
                    expected = candidate.replace('LOCAL DATE', 'DATE').replace('LOCAL --', '--')
                    self.assertEqual(report.get('corrected_gql'), expected)
                    self.assertEqual(sum(i['rule'] == 'local-date-type' for i in report['issues']),
                                     candidate.count('LOCAL'))

    def test_ignore_literals_names_valid_types_and_comments(self):
        for query in [
            """RETURN 'LOCAL DATE', "LOCAL DATE", `LOCAL DATE` // LOCAL DATE""",
            'CREATE GRAPH TYPE `G` AS { NODE `N` (LABEL `N` {local DATE, `LOCAL` DATE}) }',
            'VALUE `x` LOCAL DATETIME = NULL; VALUE `y` LOCAL TIME = NULL',
            'CREATE PROCEDURE `p`(local DATE) AS { FINISH }',
            'RETURN $local_date, `a`.`LOCAL DATE` /* LOCAL DATE */',
        ]:
            with self.subTest(query=query):
                self.assertNotIn('corrected_gql', lint(query, SKILLS[0]))

    def test_repair_preserves_other_errors(self):
        q = 'CREATE GRAPH TYPE `G` AS { NODE `N` (LABEL `N` {balance DECIMAL, `d` LOCAL DATE}) }'
        report = lint(q, SKILLS[0])
        self.assertEqual({i['rule'] for i in report['issues']}, {'local-date-type', 'keyword-identifier'})
        self.assertEqual({i['rule'] for i in lint(report['corrected_gql'], SKILLS[0])['issues']},
                         {'keyword-identifier'})
        for stmt in ('DATE = 1', 'RETURN 1 AS DATE'):
            self.assertEqual({i['rule'] for i in lint(stmt, SKILLS[0])['issues']}, {'keyword-identifier'})
