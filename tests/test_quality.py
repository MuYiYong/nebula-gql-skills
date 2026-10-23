import copy
import json
import hashlib
import tempfile
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from quality.oracles import expected
from quality.runtime import guard, OwnedGraph, CleanupFailure, seed_statement
from quality.run import judge, runner_digest, source_digest, source_files, generation_compatible, digest, SUITE, wilson
from quality.verify import verify_attempt
from evaluate import typed
from quality.calibration import CASES
from skill_tools import lint, catalog

ROOT = Path(__file__).resolve().parents[1]


class QualityTests(unittest.TestCase):
    def setUp(self):
        self.suite = json.loads(SUITE.read_text())
        self.cases = {c['id']: c for c in self.suite['cases']}
        self.fixture = self.suite['fixtures']['branching']

    def test_oracle_parallel_null_and_isolation(self):
        rows = expected(self.cases['q_optional'], self.fixture, {'min_age': 35})['rows']
        self.assertEqual(rows.count(['a', 'b']), 2)
        self.assertIn(['z', None], rows)
        self.assertIn(['c', None], rows)
        self.assertEqual(len(rows), 8)
        grouped = expected(self.cases['q_group'], self.fixture, {})['rows']
        self.assertIn([40, 2], grouped)
        self.assertIn([None, 1], grouped)

    def test_oracle_trail_vs_acyclic_and_parallel_paths(self):
        trail = expected(self.cases['q_trail'], self.fixture, {'seed': 'a'})['rows']
        acyclic = expected(self.cases['q_acyclic'], self.fixture, {'seed': 'a'})['rows']
        self.assertEqual(len(trail), 13)
        self.assertEqual(len(acyclic), 8)
        self.assertIn([['a', 'c', 'a']], trail)
        self.assertNotIn([['a', 'c', 'a']], acyclic)
        self.assertEqual(trail.count([['a', 'b']]), 2)

    def test_oracle_paging_and_compute(self):
        self.assertEqual(expected(self.cases['q_page'], self.fixture, {})['rows'], [['b', 40], ['c', 40]])
        degrees = expected(self.cases['c_degrees'], self.fixture, {})['rows']
        self.assertEqual(dict(degrees), {'a': 3, 'b': 1, 'c': 2, 'd': 0, 'e': 1, 'z': 0})
        incoming = dict(expected(self.cases['c_incoming'], self.fixture, {})['rows'])
        self.assertEqual(incoming['b'], 30)
        self.assertEqual(incoming['c'], 70)
        self.assertEqual(incoming['d'], 0)

    def test_scalar_oracle_boundary(self):
        self.assertEqual(expected(self.cases['p_sum'], self.suite['fixtures']['scalar'], {'n': -2})['rows'], [[0]])
        self.assertEqual(expected(self.cases['p_sum'], self.suite['fixtures']['scalar'], {'n': 6})['rows'], [[21]])
        for x, text in [(None, 'missing'), (-1, 'negative'), (0, 'zero'), (1, 'positive')]:
            self.assertEqual(expected(self.cases['p_branch'], self.suite['fixtures']['scalar'], {'x': x})['rows'], [[text]])
        self.assertEqual(expected(self.cases['p_contributions'], self.suite['fixtures']['scalar'], {'left': 2, 'right': 2})['rows'], [[4]])

    def test_all_calibration_queries_pass_execution_guard(self):
        for id, pair in CASES.items():
            for query in pair:
                with self.subTest(id=id):
                    guard(query, self.cases[id])
                    guard(query.replace('TYPED TABLE', ''), self.cases[id])

    def test_runtime_guard_blocks_other_graphs_and_effects(self):
        case = self.cases['q_optional']
        for query in ['USE business MATCH (p) RETURN p', 'DELETE p', 'CALL evil()',
                      'CREATE PROCEDURE evil() AS { RETURN 1 }', 'MATCH (p) SET p.age = 0 RETURN p',
                      'RETURN 1; DROP GRAPH x', 'RETURN unknown_function()', 'FILE x = "remote" RETURN 1']:
            with self.subTest(query=query), self.assertRaises(ValueError):
                guard(query, case)

    def test_unbounded_loops_and_paths_rejected(self):
        for query in ['VALUE i = 1 WHILE TRUE THEN { SET i = i + 1 } RETURN i',
                      'VALUE i = 1 WHILE i <= $n THEN { SET i = 1 } RETURN i',
                      'VALUE i = 1 WHILE i <= $n THEN { CONTINUE SET i = i + 1 } RETURN i']:
            with self.assertRaises(ValueError):
                guard(query, self.cases['p_sum'])
        for query in ['MATCH p=(a)-[:follow]->+(b) RETURN p',
                      'MATCH p=(a)-[:follow]->{1,100}(b) RETURN p',
                      'MATCH p=(a)-[:follow]->{1,}(b) RETURN p']:
            with self.assertRaises(ValueError):
                guard(query, self.cases['q_trail'])

    def test_owned_graph_cleans_exact_name_even_on_body_error(self):
        client = Mock()
        client.execute.return_value.is_succeeded = True
        graph = OwnedGraph(client, 'fixture_type')
        with self.assertRaisesRegex(ValueError, 'body failed'):
            with graph:
                raise ValueError('body failed')
        self.assertTrue(graph.cleaned)
        self.assertEqual(client.execute.call_args_list[-1].args[0], 'DROP GRAPH #' + graph.name)
        self.assertNotIn('IF NOT EXISTS', client.execute.call_args_list[0].args[0])

    def test_rejected_creation_never_drops_unowned_name(self):
        client = Mock()
        client.execute.return_value.is_succeeded = False
        client.execute.return_value.status_code = 'existing'
        with self.assertRaises(RuntimeError):
            with OwnedGraph(client, 'fixture_type'):
                pass
        self.assertEqual(client.execute.call_count, 1)

    def test_cleanup_failure_is_not_success(self):
        client = Mock()
        client.execute.side_effect = [Mock(is_succeeded=True), Mock(is_succeeded=False, status_code='error')]
        graph = OwnedGraph(client, 'fixture_type')
        with self.assertRaises(CleanupFailure):
            with graph:
                pass
        self.assertFalse(graph.cleaned)

    def receipts(self):
        return [{'case_id': c['id'], 'attempt': n, 'stratum': c['stratum'], 'state': 'passed', 'cleanup_ok': True,
                 'instances': [{'variant': v, 'parameters_index': i, 'state': 'passed', 'stage': 'oracle', 'status': '00000'}
                               for v in c['variants'] for i in range(len(c['parameter_sets']))]}
                for c in self.suite['cases'] for n in (1, 2)]

    def calibration(self):
        return {'passed': True, 'skills_sha256': 'skill', 'suite_sha256': 'suite', 'runner_sha256': runner_digest(),
                'cases': [{'id': c['id'], 'passed': True} for c in self.suite['cases']]}

    def test_empty_missing_and_unexecuted_are_not_passes(self):
        report = judge(self.suite, [], 'skill', 'suite', self.calibration())
        self.assertEqual(report['overall'], 'insufficient_evidence')
        self.assertEqual(report['strata']['query']['verdict'], 'insufficient_evidence')
        receipts = self.receipts()
        receipts[0]['instances'] = []
        report = judge(self.suite, receipts, 'skill', 'suite', self.calibration())
        self.assertEqual(report['strata']['query']['verdict'], 'insufficient_evidence')
        receipts = [r for r in self.receipts() if r['attempt'] == 1]
        report = judge(self.suite, receipts, 'skill', 'suite', self.calibration())
        self.assertEqual(report['strata']['query']['verdict'], 'insufficient_evidence')

    def test_clean_scoped_pass_does_not_cover_analytics_or_ddl(self):
        report = judge(self.suite, self.receipts(), 'skill', 'suite', self.calibration())
        self.assertEqual(report['strata']['query']['verdict'], 'meets_scoped_benchmark')
        self.assertEqual(report['strata']['named_procedure_lifecycle']['verdict'], 'insufficient_evidence')
        self.assertEqual(report['overall'], 'insufficient_evidence')

    def test_stale_calibration_and_false_success_fail_closed(self):
        for calibration in [None, {**self.calibration(), 'skills_sha256': 'old'},
                            {**self.calibration(), 'runner_sha256': 'old'}]:
            report = judge(self.suite, self.receipts(), 'skill', 'suite', calibration)
            self.assertEqual(report['strata']['query']['verdict'], 'insufficient_evidence')
        receipts = self.receipts()
        receipts[0]['state'] = 'failed'
        self.assertEqual(judge(self.suite, receipts, 'skill', 'suite', self.calibration())['overall'], 'not_met')
        with self.assertRaises(ValueError):
            judge(self.suite, receipts + [receipts[0]], 'skill', 'suite', self.calibration())

    def test_small_perfect_sample_does_not_prove_universal_accuracy(self):
        interval = wilson(3, 3)
        self.assertLess(interval[0], 0.6)
        self.assertAlmostEqual(interval[1], 1)
        self.assertIsNone(wilson(0, 0))

    def test_match_compute_does_not_use_next_between_stages(self):
        skill = ROOT / 'src/gql-procedure-generator'
        bad = 'MATCH (s)-[e]->(t) PER PATH { SET @n += 1 } NEXT MATCH (p) PER NODE (p) { EXPORT p.id INTO rows }'
        self.assertIn('compute-next', {i['rule'] for i in lint(bad, skill)['issues']})
        self.assertNotIn('compute-next', {i['rule'] for i in lint('RETURN 1 AS n NEXT RETURN n + 1 AS m', skill)['issues']})

    def test_reuse_requires_the_entire_relevant_skill_to_be_unchanged(self):
        files = source_files()
        target = next(p for p in files if p.startswith('src/gql-procedure-generator/'))
        files[target] = '0' * 64
        old = hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / 'manifest.json'
            path.write_text(json.dumps({old: {'files': files}}))
            with patch('quality.run.GENERATION_MANIFESTS', path):
                self.assertTrue(generation_compatible({'skills_sha256': old}, self.cases['q_optional']))
                self.assertFalse(generation_compatible({'skills_sha256': old}, self.cases['p_sum']))
                files['src/gql-query-generator/SKILL.md'] = '1' * 64
                path.write_text(json.dumps({old: {'files': files}}))
                self.assertFalse(generation_compatible({'skills_sha256': old}, self.cases['q_optional']))

    def test_receipt_replays_rows_instead_of_trusting_green_status(self):
        case = self.cases['q_optional']
        receipt = {'state': 'passed', 'cleanup_ok': True, 'instances': []}
        for variant in case['variants']:
            for i, params in enumerate(case['parameter_sets']):
                oracle = expected(case, self.suite['fixtures'][variant], params)
                receipt['instances'].append({'variant': variant, 'parameters_index': i,
                    'stage': 'oracle', 'status': '00000', 'state': 'passed',
                    'actual_columns': oracle['columns'], 'actual_typed_rows': [typed(r) for r in oracle['rows']]})
        self.assertEqual(verify_attempt(case, receipt, self.suite), 0)
        receipt['instances'][0]['actual_typed_rows'].pop()
        with self.assertRaisesRegex(ValueError, 'disagrees'):
            verify_attempt(case, receipt, self.suite)

    def test_public_documented_use_and_database_member_scope(self):
        skill = ROOT / 'src/gql-procedure-generator'
        self.assertNotIn('procedure-use', {i['rule'] for i in lint('CREATE PROCEDURE p() AS { USE g RETURN 1 AS n }', skill)['issues']})
        members = catalog(skill)
        self.assertIn('database', members['setagg.clear']['scope'])
        self.assertIn('analytics', members['setagg.clear']['scope'])


if __name__ == '__main__':
    unittest.main()
