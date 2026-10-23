#!/usr/bin/env python3
"""Evaluate saved model outputs; static success never implies execution/semantics.

Input JSON: {"producer": {"kind":"model", "model":"..."}, "outputs":
[{"id":"...", "skill":"gql-query-generator", "query":"...", "explanation":"..."}]}.
The prompt exporter omits references/oracles. Fixture mode tests the harness only.
"""
from __future__ import annotations
import argparse
from collections import Counter
from decimal import Decimal
import hashlib
import json
from pathlib import Path
import re
import statistics
from skill_tools import lint

ROOT = Path(__file__).resolve().parents[1]


def typed(value):
    if value is None: return ['null', None]
    if type(value) is bool: return ['bool', value]
    if type(value) is int: return ['int', str(value)]
    if type(value) is float: return ['float', repr(value)]
    if isinstance(value, Decimal): return ['decimal', str(value)]
    if isinstance(value, str): return ['string', value]
    if isinstance(value, (list,tuple)): return ['list', [typed(v) for v in value]]
    if isinstance(value, dict): return ['record', [[k, typed(v)] for k,v in sorted(value.items())]]
    raise ValueError(f'Unsupported result type: {type(value).__name__}')


def compare_results(expected, actual, ordered=False):
    if expected['columns'] != actual['columns']: return False
    left, right = [typed(r) for r in expected['rows']], [typed(r) for r in actual['rows']]
    if ordered: return left == right
    encode = lambda row: json.dumps(row, ensure_ascii=False, separators=(',',':'))
    return Counter(map(encode,left)) == Counter(map(encode,right))


def performance_summary(samples, equivalent, metadata):
    """Timing claims need matching fixture/settings and repeated alternating runs."""
    if not equivalent: raise ValueError('Result equivalence must pass before timing')
    required = {'fixture','parameters','settings','scale','snapshot'}
    if not required <= metadata.keys() or any(metadata[k] in (None,'',{}) for k in required):
        raise ValueError('Performance metadata incomplete')
    if len(samples) < 6: raise ValueError('At least six alternating paired samples required')
    for i, sample in enumerate(samples):
        order = ['baseline','candidate'] if i % 2 == 0 else ['candidate','baseline']
        if sample['order'] != order: raise ValueError('Run order must alternate')
        for key in order:
            value = sample[key]
            if not isinstance(value,(int,float)) or value <= 0: raise ValueError('Invalid timing')
    result = {'evidence':'fixture-specific repeated execution', 'optimality':'not established',
              'pairs':len(samples),'metadata':metadata}
    for key in ('baseline','candidate'):
        values = sorted(s[key] for s in samples)
        result[key] = {'median_ms':statistics.median(values),'min_ms':min(values),
                       'max_ms':max(values),'p95_ms':values[min(len(values)-1, int(.95*len(values)))]}
    return result


def evaluate_case(case, output):
    issues=[]
    if output.get('skill') != case['skill']: issues.append({'rule':'routing','message':'Wrong skill'})
    query, explanation = output.get('query',''), output.get('explanation','')
    if not isinstance(query,str) or not isinstance(explanation,str):
        return {'id':case['id'],'passed':False,'issues':[{'rule':'format','message':'Strings required'}]}
    negative=case['category']=='negative'
    if negative:
        if not explanation.strip(): issues.append({'rule':'negative','message':'Explain missing capability or input'})
        if query.strip(): issues.append({'rule':'negative','message':'This fixture requires clarification or limitation, not fabricated execution'})
        report={'issues':[],'needs_review':[]}
    else:
        if not query.strip(): issues.append({'rule':'empty','message':'Expected GQL'})
        report=lint(query,ROOT/'src'/case['skill'],case['scope'])
        issues.extend(report['issues'])
    for pattern in case['contract']['requires']:
        if not re.search(pattern,query,re.I|re.S): issues.append({'rule':'contract','message':f'Missing invariant: {pattern}'})
    for pattern in case['contract']['forbids']:
        if re.search(pattern,query,re.I|re.S): issues.append({'rule':'contract','message':f'Forbidden change: {pattern}'})
    for pattern in case['contract'].get('explanation_requires',[]):
        if not re.search(pattern,explanation,re.I|re.S): issues.append({'rule':'explanation-contract','message':f'Missing explanation invariant: {pattern}'})
    if case['category']=='performance':
        if not re.search(r'未验证|待验证|未测|未连接数据库执行|未执行|未运行|尚无性能实测|仅结构分析|仅为结构分析|结构级|结构候选|unverified|not (?:measured|verified)|structure.only',explanation,re.I):
            issues.append({'rule':'performance-evidence','message':'State that runtime performance is unverified'})
        if re.search(r'(?:保证|绝对|必然).{0,8}(?:最优|更快)|guaranteed.*(?:optimal|faster)',explanation,re.I):
            issues.append({'rule':'performance-claim','message':'Unsupported optimality claim'})
    return {'id':case['id'],'passed':not issues,'issues':issues,'needs_review':report['needs_review'],
            'grammar':'not executed','semantics':'not executed', 'category':case['category']}


def evaluate(cases, data, selected=None):
    outputs=data.get('outputs',[])
    if not isinstance(outputs,list): raise ValueError('outputs must be a list')
    ids=[o['id'] for o in outputs]
    if len(ids)!=len(set(ids)): raise ValueError('Duplicate output IDs')
    known={c['id']:c for c in cases}
    if set(ids)-known.keys(): raise ValueError('Unknown output IDs')
    wanted=set(selected) if selected is not None else set(known)
    if wanted-known.keys(): raise ValueError('Unknown selected IDs')
    indexed={o['id']:o for o in outputs}
    results=[]
    for id in sorted(wanted):
        if id not in indexed: results.append({'id':id,'passed':False,'issues':[{'rule':'missing','message':'No model output'}]})
        else: results.append(evaluate_case(known[id],indexed[id]))
    if not results: raise ValueError('Empty evaluation')
    return {'producer':data.get('producer',{'kind':'unknown'}),'evaluation_kind':'static contracts only',
            'total':len(results),'passed':sum(r['passed'] for r in results),'results':results}


def evaluate_routes(cases,data):
    outputs=data.get('outputs',[])
    ids=[o['id'] for o in outputs]
    known={c['id'] for c in cases}
    if len(ids)!=len(set(ids)) or set(ids)-known: raise ValueError('Duplicate or unknown route IDs')
    indexed={o['id']:o for o in outputs}
    results=[{'id':c['id'],'passed':c['id'] in indexed and indexed[c['id']].get('skill')==c['expected_skill']}
             for c in cases]
    return {'producer':data.get('producer',{}),'total':len(results),
            'passed':sum(r['passed'] for r in results),'results':results,
            'evaluation_kind':'saved route decisions, not host auto-trigger telemetry'}


def export_prompts(cases):
    return [{'id':c['id'],'prompt':c['prompt'],'scope':c['scope'],
             'output_format':{'skill':'selected skill or null','query':'GQL only, no fences','explanation':'assumptions/evidence/limitations'}} for c in cases]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--cases',type=Path,default=ROOT/'evals/cases.json')
    g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--outputs',type=Path);g.add_argument('--fixtures',action='store_true');g.add_argument('--export-prompts',action='store_true')
    g.add_argument('--trigger-outputs',type=Path);g.add_argument('--export-triggers',action='store_true')
    p.add_argument('--ids',nargs='+');p.add_argument('--report',type=Path)
    a=p.parse_args()
    if a.export_triggers or a.trigger_outputs:
        triggers=json.loads((ROOT/'evals/triggers.json').read_text())
        if a.export_triggers:
            print(json.dumps([{'id':c['id'],'prompt':c['prompt']} for c in triggers],ensure_ascii=False,indent=2));return
        report=evaluate_routes(triggers,json.loads(a.trigger_outputs.read_text()))
        if a.report:
            a.report.parent.mkdir(parents=True,exist_ok=True)
            a.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
        print(json.dumps(report,ensure_ascii=False,indent=2))
        if report['passed']!=report['total']:raise SystemExit(1)
        return
    raw=a.cases.read_bytes();cases=json.loads(raw)['cases']
    if a.export_prompts:
        print(json.dumps(export_prompts([c for c in cases if not a.ids or c['id'] in a.ids]),ensure_ascii=False,indent=2));return
    data=({'producer':{'kind':'reference-fixture','not_model_accuracy':True},'outputs':[
        dict(id=c['id'],skill=c['skill'],**c['reference']) for c in cases]} if a.fixtures else json.loads(a.outputs.read_text()))
    result=evaluate(cases,data,a.ids)
    result['cases_sha256']=hashlib.sha256(raw).hexdigest()
    if a.outputs: result['outputs_sha256']=hashlib.sha256(a.outputs.read_bytes()).hexdigest()
    if a.report:
        a.report.parent.mkdir(parents=True,exist_ok=True)
        a.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(result,ensure_ascii=False,indent=2))
    if result['passed']!=result['total']: raise SystemExit(1)

if __name__=='__main__':main()
