import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from evaluate import evaluate
from skill_tools import lint, lookup, read_only, tokens
from validate_database import safe_query

ROOT = Path(__file__).resolve().parents[1]
SKILLS = [ROOT / 'src' / name for name in ('gql-query-generator', 'gql-procedure-generator')]


class RegularExpressionTests(unittest.TestCase):
    def test_source_operator_is_rejected_in_both_skills_and_scopes(self):
        for root in SKILLS:
            for scope in ('database', 'analytics'):
                for code in (
                    r"RETURN lower('job.p_a') =~ '.+\\.[psv]_.+' AS matched",
                    'RETURN NOT ($text =~ $pattern) AS matched',
                    'IF name =~ pattern THEN RETURN TRUE END IF',
                ):
                    with self.subTest(root=root.name, scope=scope, code=code):
                        issues = lint(code, root, scope)['issues']
                        self.assertIn('regex-operator', {i['rule'] for i in issues})
                        self.assertTrue(any('regexp_like' in i['message'] for i in issues))

    def test_operator_in_values_identifiers_and_comments_is_ignored(self):
        for root in SKILLS:
            for code in (
                'RETURN "=~" AS text_value',
                "RETURN '=~' AS text_value",
                'RETURN 1 AS `=~`',
                'RETURN 1 AS n // =~',
                'RETURN 1 AS n -- =~',
                'RETURN 1 AS n /* =~ */',
                'RETURN regexp_like("=~", "=~") AS matched',
            ):
                with self.subTest(root=root.name, code=code):
                    self.assertEqual(lint(code, root)['issues'], [])

    def test_documented_calls_preserve_patterns_and_parameters(self):
        for root in SKILLS:
            for code in (
                r"RETURN regexp_like(lower('job.p_a'), '.+\\.[psv]_.+') AS matched",
                'RETURN REGEXP_LIKE($text, $pattern, "i") AS matched',
                'RETURN NOT regexp_like(NULL, ".*") AS matched',
                'RETURN regexp_like("hello, world", "hello") AS matched',
                r'RETURN split("a.b", "\\.") AS parts',
            ):
                with self.subTest(root=root.name, code=code):
                    self.assertEqual(lint(code, root)['issues'], [])
        code = r"RETURN regexp_like('job.p_a', '.+\\.[psv]_.+') AS matched"
        self.assertIn(('string', r"'.+\\.[psv]_.+'"), tokens(code))

    def test_regexp_like_arity_uses_the_documented_signature(self):
        for root in SKILLS:
            for code in ('RETURN regexp_like("x")', 'RETURN regexp_like("x", "x", "i", 1)'):
                with self.subTest(root=root.name, code=code):
                    self.assertIn('function-arity', {i['rule'] for i in lint(code, root)['issues']})

    def test_read_only_guard_cannot_admit_source_operator(self):
        for root in SKILLS:
            with self.subTest(root=root.name), self.assertRaises(ValueError):
                read_only('RETURN "hello" =~ "hello" AS matched', root)

    def test_regex_guidance_is_discoverable_in_standalone_skills(self):
        for root in SKILLS:
            with self.subTest(root=root.name):
                result = lookup(root, 'regular expressions', kind='topic')
                self.assertEqual(result['matches'], 1)
                self.assertIn('references/regular-expressions.md:', result['text'])
                self.assertIsNone(result['next_offset'])
                self.assertIn('regexp_like', result['text'])
                self.assertIn('options: STRING', lookup(root, 'regexp_like')['text'])


class RegularExpressionFixtureTests(unittest.TestCase):
    def setUp(self):
        self.cases = json.loads((ROOT / 'evals/regex-cases.json').read_text())['cases']

    def test_reference_contracts_and_read_only_live_subset(self):
        outputs = [dict(id=c['id'], skill=c['skill'], **c['reference']) for c in self.cases]
        report = evaluate(self.cases, {'outputs': outputs})
        self.assertEqual(report['passed'], len(self.cases), report)
        for case in self.cases:
            if 'execution' in case:
                with self.subTest(case=case['id']):
                    safe_query(case['reference']['query'])

    def test_migration_rejects_unconverted_operator_and_changed_pattern(self):
        case = next(c for c in self.cases if c['id'] == 'regex-job-migration')
        query = case['reference']['query']
        for changed in (
            r"MATCH (n:`Job`) WHERE lower(n.job_name) =~ '.+\\.[psv]_.+' RETURN n.job_name AS job_name",
            query.replace(r'\\.', '.'),
            query.replace('[psv]', '[ps]'),
            query.replace('lower(n.job_name)', 'lower(n.job.job_name)'),
        ):
            with self.subTest(query=changed):
                output = dict(id=case['id'], skill=case['skill'], query=changed, explanation='')
                self.assertEqual(evaluate([case], {'outputs': [output]})['passed'], 0)


if __name__ == '__main__':
    unittest.main()
