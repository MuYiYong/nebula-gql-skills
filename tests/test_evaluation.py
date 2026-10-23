import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from contextlib import redirect_stdout
import io
from decimal import Decimal

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from skill_tools import lint, lookup, read_only
from evaluate import compare_results, evaluate, evaluate_routes, export_prompts, performance_summary
from track_sources import impact
from validate_database import safe_query, run_case, materialize, measure_pair
import refresh_documented_capabilities as refresh

ROOT=Path(__file__).resolve().parents[1]
Q=ROOT/'src/gql-query-generator';P=ROOT/'src/gql-procedure-generator'


class LintTests(unittest.TestCase):
    def rules(self,code,root=Q,scope='database'):
        return {i['rule'] for i in lint(code,root,scope)['issues']}
    def test_unknown_function(self):
        self.assertIn('undocumented-function',self.rules('RETURN property_exists(n.x)'))
    def test_quoted_unknown_function(self):
        self.assertIn('undocumented-function',self.rules('RETURN `array_distinct`(LIST[1])'))
    def test_arity_and_nested_arguments(self):
        self.assertIn('function-arity',self.rules('RETURN list_distinct()'))
        self.assertNotIn('function-arity',self.rules('RETURN list_distinct(LIST[1,2])'))
    def test_optional_arity(self):
        self.assertNotIn('function-arity',self.rules('RETURN split("a,b", ",")'))
        self.assertIn('function-arity',self.rules('RETURN split("a,b")'))
    def test_literal_type(self):
        self.assertIn('function-type',self.rules('RETURN list_distinct(2)'))
    def test_scope(self):
        self.assertIn('function-scope',self.rules('RETURN nodes(p)',P,'analytics'))
    def test_member_receiver_and_arity(self):
        self.assertIn('undocumented-function',self.rules('VALUE a ListAgg<INT> RETURN @a.no_such_method()',P,'analytics'))
        self.assertTrue(lint('RETURN obj.clear()',P,'analytics')['needs_review'])
    def test_strings_comments(self):
        self.assertEqual(self.rules('RETURN "property_exists() // not code" AS x /* array_distinct() */'),set())
    def test_delimiters(self):
        self.assertIn('delimiters',self.rules('RETURN list_distinct(LIST[1,2)'))
    def test_unterminated_string(self):
        self.assertIn('literal',self.rules("RETURN 'hello"))
    def test_dialect(self):
        self.assertIn('dialect',self.rules('MATCH p=(a)-[:KNOWS*1..3]->(b) RETURN p'))
    def test_paging(self):
        self.assertIn('pagination-order',self.rules('RETURN x LIMIT 2 ORDER BY x'))
        self.assertIn('pagination-value',self.rules('RETURN x OFFSET -1'))
    def test_procedure_constraints(self):
        self.assertNotIn('procedure-use',self.rules('CREATE PROCEDURE x() AS { USE g RETURN 1 }',P))
        self.assertIn('node-value-type',self.rules('NODE VALUE x INT64 = 0',P,'analytics'))
        self.assertIn('compute-hop',self.rules('MATCH (a)-[e]->(b)-[f]->(c) PER PATH { SET c.@x += 1 }',P,'analytics'))
    def test_analytics_return_boundaries(self):
        self.assertIn('compute-return',self.rules('MATCH (n) PER NODE (n) { RETURN n.id }',P,'analytics'))
        self.assertIn('analytics-match',self.rules('MATCH (n) RETURN n.id',P,'analytics'))
        self.assertNotIn('analytics-match',self.rules('MATCH (n) RETURN n.id',Q,'database'))
    def test_reserved_alias(self):
        self.assertIn('reserved-alias',self.rules('RETURN 1 AS values'))
        self.assertNotIn('reserved-alias',self.rules('RETURN 1 AS `values`'))
        self.assertIn('reserved-alias',self.rules('RETURN 1 AS order'))
        self.assertNotIn('reserved-alias',self.rules('RETURN CAST(1 AS STRING) AS text_value'))
    def test_edge_id_type(self):
        self.assertIn('function-type',self.rules('MATCH (a)-[e:K]->(b) RETURN element_id(e)'))
    def test_lookup_bounded_and_exact(self):
        r=lookup(Q,'list_distinct');self.assertEqual(r['matches'],1);self.assertIn('LIST',r['text'])
        r=lookup(Q,'MATCH','topic',limit=200);self.assertLessEqual(len(r['text']),200);self.assertIsNotNone(r['next_offset'])
        self.assertEqual(lookup(Q,'invented')['matches'],0)
        ranked=lookup(Q,'RETURN','topic',limit=600)
        self.assertTrue(ranked['text'].startswith('references/documented-syntax.md:'))
        self.assertIn('RETURN',ranked['text'])
        self.assertNotIn('checklist.md',ranked['text'])
    def test_read_only_blocks_side_effects(self):
        for code in ['CALL foo()','RETURN 1; DELETE n','RETURN 1 NEXT INSERT (n)',
                     '/*+ SET_VAR(a=1) */ RETURN 1','RETURN obj.write()', 'RETURN undocumented()']:
            with self.subTest(code=code),self.assertRaises(ValueError):read_only(code,Q)
    def test_read_only_allows_literal_keywords(self):
        self.assertEqual(read_only('RETURN "DELETE" AS x',Q),'RETURN "DELETE" AS x')
    def test_default_live_tier_no_graph(self):
        with self.assertRaises(ValueError):safe_query('MATCH (n) RETURN n')


class EvaluationTests(unittest.TestCase):
    def setUp(self):self.cases=json.loads((ROOT/'evals/cases.json').read_text())['cases']
    def result(self,rows,columns=['x']):return {'columns':columns,'rows':rows}
    def test_bag_preserves_duplicates(self):
        self.assertFalse(compare_results(self.result([[1],[1]]),self.result([[1]])))
        self.assertTrue(compare_results(self.result([[1],[2]]),self.result([[2],[1]])))
    def test_order_null_columns_and_types(self):
        for other in [self.result([[1],[2]]),self.result([[True],[None]]),self.result([[1],[None]],['y'])]:
            self.assertFalse(compare_results(self.result([[1],[None]]),other,True))
        self.assertFalse(compare_results(self.result([[1],[2]]),self.result([[2],[1]]),True))
        self.assertFalse(compare_results(self.result([[Decimal('1.5')]]),self.result([[1.5]])))
    def test_large_int_precise(self):
        self.assertFalse(compare_results(self.result([[9007199254740993]]),self.result([[9007199254740992]])))
    def test_references_pass_static_contracts(self):
        report=evaluate(self.cases,{'outputs':[dict(id=c['id'],skill=c['skill'],**c['reference']) for c in self.cases]})
        self.assertEqual(report['passed'],len(self.cases),report)
    def test_missing_and_duplicate_outputs_fail(self):
        report=evaluate(self.cases,{'outputs':[]});self.assertEqual(report['passed'],0)
        with self.assertRaises(ValueError):evaluate(self.cases,{'outputs':[{'id':'scalar'},{'id':'scalar'}]})
        with self.assertRaises(ValueError):evaluate(self.cases,{'outputs':[{'id':'made-up'}]})
    def test_prompt_export_has_no_oracles(self):
        self.assertFalse(any({'reference','contract','execution','skill'} & c.keys() for c in export_prompts(self.cases)))
    def test_negative_requires_explanation(self):
        r=evaluate(self.cases,{'outputs':[{'id':'unknown-property','skill':'gql-query-generator','query':'','explanation':''}]},['unknown-property'])
        self.assertEqual(r['passed'],0)
    def test_semantic_path_mutation_fails(self):
        c=next(c for c in self.cases if c['id']=='path-duplicates')
        o=dict(id=c['id'],skill=c['skill'],**c['reference']);o['query']=o['query'].replace('TRAIL','ACYCLIC')
        self.assertEqual(evaluate(self.cases,{'outputs':[o]},[c['id']])['passed'],0)
    def test_semantic_counterexamples_fail(self):
        mutations = {
            'grouping': 'MATCH (p:Person) RETURN p.age AS age, count(*) AS total GROUP BY p',
            'perf-optional': 'MATCH (p:Person) OPTIONAL MATCH (p)-[:KNOWS]->(f:Person) FILTER WHERE f.age > 30 RETURN p,f',
            'perf-correlated': 'MATCH (p:Person) WHERE EXISTS { MATCH (a)-[:KNOWS]->(b) } RETURN p',
            'procedure-algorithm': 'NODE VALUE score SumAgg<INT64> = 0 MATCH (s:Person)-[:KNOWS]->(t:Person) PER PATH { SET s.@score += 1 }',
            'procedure-manage': 'ALTER PROCEDURE greet(STRING) COMMENT "unrelated"',
            'procedure-default': 'CREATE PROCEDURE greet(name STRING, prefix STRING DEFAULT "bye") RETURNS message STRING AS { RETURN name || prefix AS message }',
        }
        for id, query in mutations.items():
            c=next(c for c in self.cases if c['id']==id)
            o=dict(id=id,skill=c['skill'],query=query,explanation='结构候选，未验证性能')
            with self.subTest(id=id):self.assertEqual(evaluate(self.cases,{'outputs':[o]},[id])['passed'],0)
        o=dict(id='procedure-multihop',skill='gql-procedure-generator',query='',explanation='已完成')
        self.assertEqual(evaluate(self.cases,{'outputs':[o]},['procedure-multihop'])['passed'],0)
    def test_performance_evidence_wording(self):
        c=next(c for c in self.cases if c['id']=='perf-pagination')
        o=dict(id=c['id'],skill=c['skill'],query=c['reference']['query'],explanation='未连接数据库执行。仅结构级候选，没有 PROFILE。')
        self.assertEqual(evaluate(self.cases,{'outputs':[o]},[c['id']])['passed'],1)
        o['explanation']='保证性能最优，必然更快'
        self.assertEqual(evaluate(self.cases,{'outputs':[o]},[c['id']])['passed'],0)
    def test_route_decisions_fail_on_missing_and_wrong_routes(self):
        cases=[{'id':'r1','expected_skill':None},{'id':'r2','expected_skill':'gql-query-generator'}]
        self.assertEqual(evaluate_routes(cases,{'outputs':[]})['passed'],0)
        self.assertEqual(evaluate_routes(cases,{'outputs':[{'id':'r1','skill':None},{'id':'r2','skill':'gql-query-generator'}]})['passed'],2)
        with self.assertRaises(ValueError):evaluate_routes(cases,{'outputs':[{'id':'r1'},{'id':'r1'}]})
    def test_performance_coverage(self):
        self.assertEqual({c.get('risk') for c in self.cases if c['category']=='performance'},
                         {'supernode','variable_path','intermediate_rows','optional_match','correlated_subquery','pagination'})
    def test_performance_requires_equivalence_repeats_and_context(self):
        meta=dict(fixture='literal',parameters='none',settings='defaults',scale='four rows',snapshot='constant')
        samples=[dict(order=['baseline','candidate'] if i%2==0 else ['candidate','baseline'],baseline=2.,candidate=1.) for i in range(6)]
        for s,e,m in [(samples,False,meta),(samples[:1],True,meta),(samples,True,{})]:
            with self.assertRaises(ValueError):performance_summary(s,e,m)
        r=performance_summary(samples,True,meta);self.assertEqual(r['optimality'],'not established')
        samples[1]['order']=['baseline','candidate']
        with self.assertRaises(ValueError):performance_summary(samples,True,meta)
    def test_incremental_impact(self):
        old={'files':{'docs/database-gql-reference/dql/x':'a'}}
        self.assertFalse(impact(old,old,self.cases)['review_required'])
        new={'files':{'features/x':'b'}}
        self.assertEqual(len(impact(old,new,self.cases)['affected_cases']),len(self.cases))
    def test_refresh_skips_unchanged_and_preserves_curated(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);generated=root/'generated.md';curated=root/'curated.md'
            generated.write_text('same');curated.write_text('human edits')
            before=generated.stat().st_mtime_ns
            with patch.object(refresh,'ROOT',root), patch.object(refresh,'expected_outputs',return_value={generated:'same'}), patch.object(sys,'argv',['refresh','--docs-root',td]), redirect_stdout(io.StringIO()):
                refresh.main()
            self.assertEqual(before,generated.stat().st_mtime_ns)
            self.assertEqual(curated.read_text(),'human edits')
    def test_graph_performance_templates_are_read_only(self):
        cases=json.loads((ROOT/'evals/performance.json').read_text())['cases']
        self.assertEqual(len(cases),6)
        for case in cases:
            for key in ['baseline','candidate']:safe_query(case[key],graph_free=False)
    def test_error_repair_reproduces_expected_failure_first(self):
        from unittest.mock import Mock
        case=next(c for c in self.cases if c['id']=='repair-arity')
        client=Mock();client.execute.return_value.status_code='00000'
        r=run_case(client,case,case['reference']['query'])
        self.assertFalse(r['passed']);self.assertEqual(r['stage'],'original-error')
        self.assertEqual(client.execute.call_count,1)
        case=json.loads(json.dumps(case));case['execution']['original_error']['query']='DELETE n'
        client.reset_mock()
        with self.assertRaises(ValueError):run_case(client,case,case['reference']['query'])
        client.execute.assert_not_called()
    def test_graph_execution_rejects_bad_context_before_query(self):
        from unittest.mock import Mock
        client=Mock()
        with self.assertRaises(ValueError):
            measure_pair(client,'RETURN 1 AS x','RETURN 1 AS x',{},graph='fixture')
        client.execute.assert_not_called()
        with self.assertRaises(ValueError):
            measure_pair(client,'RETURN 1 AS x','RETURN 1 AS x',{},graph='x` DROP GRAPH x')
        client.execute.assert_not_called()
    def test_runtime_copies_identical(self):
        for p in (Q,P):self.assertEqual((p/'scripts/skill_tools.py').read_bytes(),(ROOT/'scripts/skill_tools.py').read_bytes())

if __name__=='__main__':unittest.main()
