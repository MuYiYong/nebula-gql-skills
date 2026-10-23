#!/usr/bin/env python3
"""Opt-in read-only live validation. Credentials from environment only.

Default suite uses constants/lists, never a business graph. No DDL/DML, arbitrary
CALL, hints, setup or cleanup statements are accepted. Never prints query text,
server error messages, result payloads, credentials or endpoint in its report.
Requires the NebulaGraph 5.3 Python SDK in the selected Python environment.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import time
from evaluate import ROOT, compare_results, performance_summary
from skill_tools import read_only, tokens


def materialize(result):
    if not result.is_succeeded:
        return {'status':result.status_code,'columns':[],'rows':[]}
    rows=[]
    for row in result.as_primitive_by_row():
        if len(rows) >= 100000: raise ValueError('Result budget exceeded; no truncated comparison')
        rows.append(row)
    return {'status':result.status_code,'columns':list(result.column_names),
            'rows':[[r[c] for c in result.column_names] for r in rows]}


def plan_summary(plan):
    if not plan: return None
    # Deliberately omit details: a server plan can echo graph values/parameters.
    return {'operator':plan.name,'rows':plan.rows,'memory_kib':plan.memory_kib,
            'time_ms':plan.time_ms,'children':[plan_summary(c) for c in plan.children]}


def safe_query(query, graph_free=True):
    read_only(query.strip().removesuffix(';'), ROOT/'src/gql-query-generator')
    clean=query.strip().removesuffix(';')
    if graph_free and any(k=='word' and v.upper() in {'MATCH','GRAPH'} for k,v in tokens(clean)):
        raise ValueError('Default live tier forbids graph access')
    return clean


def run_case(client, case, query):
    query=safe_query(query)
    original=case['execution'].get('original_error')
    original_status=None
    if original:
        # Only these fixed, graph-free diagnostic fixtures may bypass invalid-grammar lint.
        # No arbitrary model/user statement is admitted through this branch.
        allowed={
            'RETURN list_distinct() AS items',
            'FOR x IN LIST[3,1,2] RETURN x LIMIT 2 ORDER BY x',
            'RETURN list_distinct(LIST[1,1,2]) AS values',
        }
        if original['query'] not in allowed: raise ValueError('Unreviewed diagnostic fixture')
        original_status=client.execute(original['query']).status_code
        if original_status != original['status']:
            return {'id':case['id'],'passed':False,'stage':'original-error','status':original_status}
    parsed=client.execute('EXPLAIN ' + query)
    if not parsed.is_succeeded:
        return {'id':case['id'],'passed':False,'stage':'parse','status':parsed.status_code}
    result=materialize(client.execute(query))
    equivalent=result['status']=='00000' and compare_results(case['execution'],result,case['execution']['ordered'])
    return {'id':case['id'],'passed':equivalent,'stage':'result-comparison',
            'status':result['status'],'row_count':len(result['rows']),
            'query_sha256':hashlib.sha256(query.encode()).hexdigest(),'original_status':original_status,
            'grammar':'server EXPLAIN passed', 'semantics':'fixture comparison passed' if equivalent else 'failed'}


def measure_pair(client, baseline, candidate, metadata, pairs=6, graph=None):
    baseline=safe_query(baseline, graph_free=graph is None)
    candidate=safe_query(candidate, graph_free=graph is None)
    if graph is not None:
        if not graph.isidentifier(): raise ValueError('Fixture graph must be a simple identifier')
        baseline=f'USE `{graph}` ' + baseline
        candidate=f'USE `{graph}` ' + candidate
    if pairs < 6: raise ValueError('Need at least six alternating paired samples')
    required={'fixture','parameters','settings','scale','snapshot'}
    if not required <= metadata.keys() or any(metadata[k] in (None,'',{}) for k in required):
        raise ValueError('Performance metadata incomplete')
    before=materialize(client.execute(baseline));after=materialize(client.execute(candidate))
    equivalent=before['status']==after['status']=='00000' and compare_results(before,after,metadata.get('ordered',False))
    if not equivalent: raise ValueError('Result equivalence failed before performance run')
    # Warmups are excluded. Every measurement must retain the same full result.
    samples=[]
    for i in range(pairs):
        order=['baseline','candidate'] if i%2==0 else ['candidate','baseline']
        sample={'order':order}
        for name in order:
            start=time.perf_counter()
            result=materialize(client.execute(baseline if name=='baseline' else candidate))
            sample[name]=(time.perf_counter()-start)*1000
            if result['status']!='00000' or not compare_results(before,result,metadata.get('ordered',False)):
                raise ValueError('Result changed during performance measurement')
        samples.append(sample)
    summary=performance_summary(samples,equivalent,metadata)
    summary['samples_ms']=samples
    summary['plans']={}
    for name,query in [('baseline',baseline),('candidate',candidate)]:
        r=client.execute('PROFILE '+query)
        result=materialize(r)
        if result['status']!='00000' or not compare_results(before,result,metadata.get('ordered',False)):
            raise ValueError('PROFILE result mismatch')
        summary['plans'][name]=plan_summary(r.plan_desc)
    return summary


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--outputs',type=Path)
    p.add_argument('--report',type=Path,required=True)
    p.add_argument('--performance',action='store_true')
    p.add_argument('--graph-performance',type=Path,help='Opt-in suite on an existing isolated graph fixture')
    p.add_argument('--graph',help='Explicit fixture graph name, never inferred')
    p.add_argument('--fixture-metadata',type=Path,help='JSON with fixture, parameters, settings, scale, snapshot')
    a=p.parse_args()
    if a.graph_performance and (not a.graph or not a.fixture_metadata): p.error('Graph suite requires explicit --graph and --fixture-metadata')
    required=['NEBULA_ADDRESS','NEBULA_USER','NEBULA_PASSWORD']
    if any(not os.environ.get(k) for k in required): p.error('Set NEBULA_ADDRESS, NEBULA_USER and NEBULA_PASSWORD privately')
    from nebulagraph_python.client import NebulaClient
    cases=json.loads((ROOT/'evals/cases.json').read_text())['cases']
    outputs=None
    if a.outputs:
        data=json.loads(a.outputs.read_text());outputs={o['id']:o for o in data['outputs']}
    report={'compatibility':'5.3.0','scope':'graph-free read-only fixtures',
            'producer':data.get('producer',{}) if a.outputs else {'kind':'reference-fixture'},'results':[]}
    client=None
    try:
        client=NebulaClient(addresses=os.environ['NEBULA_ADDRESS'],user_name=os.environ['NEBULA_USER'],
                            password=os.environ['NEBULA_PASSWORD'],connect_timeout_ms=5000,request_timeout_ms=10000)
        v=materialize(client.execute('SHOW VERSION'))
        if v['status']!='00000': raise ValueError('Version probe failed')
        report['server_version']=v['rows'][0][0]
        for case in cases:
            if 'execution' not in case: continue
            if outputs is not None and case['id'] not in outputs:
                report['results'].append({'id':case['id'],'passed':False,'stage':'missing-output'});continue
            query=(outputs[case['id']] if outputs is not None else case['reference'])['query']
            try:report['results'].append(run_case(client,case,query))
            except ValueError:
                report['results'].append({'id':case['id'],'passed':False,'stage':'read-only guard'})
        if a.performance:
            report['performance']=measure_pair(client,
                'FOR x IN LIST[3,1,2,2] RETURN x ORDER BY x OFFSET 1 LIMIT 2',
                'FOR x IN LIST[3,1,2,2] ORDER BY x OFFSET 1 LIMIT 2 RETURN x',
                {'fixture':'four scalar rows / duplicate pagination','scale':'4 input rows',
                 'parameters':'fixed literal fixture','settings':'same client/default settings',
                 'snapshot':'immutable literals','ordered':True})
        if a.graph_performance:
            suite=json.loads(a.graph_performance.read_text())
            metadata=json.loads(a.fixture_metadata.read_text())
            # Reject incomplete claims before running any graph workload.
            if not {'fixture','parameters','settings','scale','snapshot'} <= metadata.keys():
                raise ValueError('Incomplete fixture metadata')
            report['graph_performance']=[]
            for case in suite['cases']:
                m={**metadata,'ordered':case['ordered']}
                measured=measure_pair(client,case['baseline'],case['candidate'],m,graph=a.graph)
                report['graph_performance'].append({'id':case['id'],'risk':case['risk'],**measured})
    except Exception as exc:
        # Exceptions from transport may contain credentials or addresses.
        report['failure']={'type':type(exc).__name__,'message':'Live validation failed; no exception payload persisted'}
    finally:
        if client: client.close()
    report['passed']=bool(report['results']) and all(r['passed'] for r in report['results']) and 'failure' not in report
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'passed':report['passed'],'cases':len(report['results']),'report':str(a.report)}))
    if not report['passed']:raise SystemExit(1)

if __name__=='__main__':main()
