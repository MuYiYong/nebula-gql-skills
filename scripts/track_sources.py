#!/usr/bin/env python3
"""Fingerprint authorized local sources and report affected skills/evals.

No source content or machine paths are persisted. Code is pinned to a git ref.
This reports changes for review; it never promotes implementation-only features
or overwrites curated skill references. Run refresh separately after review.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from refresh_documented_capabilities import ROOT, QUERY_SYNTAX_ROOTS, PROCEDURE_SYNTAX_ROOTS


def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def fingerprint(docs,features,code,ref):
    files={}
    roots=set(QUERY_SYNTAX_ROOTS+PROCEDURE_SYNTAX_ROOTS)
    roots.update(['database-gql-reference/fe/functions','analytics-gql-reference/fe/functions',
                  'database-gql-reference/data-admin/tuning','database-gql-reference/overview'])
    for base in sorted(roots):
        for p in sorted((docs/base).rglob('index.html')):files['docs/'+p.relative_to(docs).as_posix()]=digest(p)
    # Fingerprint additions too; do not miss new feature coverage outside the old subset.
    wanted={p.relative_to(features).as_posix() for p in features.rglob("*.feature")}
    for p in (ROOT/'src').glob('*/tests/features/**/*.feature'):
        wanted.add(p.as_posix().split('/tests/features/',1)[1])
    for name in sorted(wanted):
        p=features/name;files['features/'+name]=digest(p) if p.is_file() else 'MISSING'
    sha=subprocess.check_output(['git','-C',str(code),'rev-parse',ref+'^{commit}'],text=True).strip()
    listing=subprocess.check_output(['git','-C',str(code),'ls-tree','-r',sha,'--','src/parser','src/function','src/gql','src/analytic','src/exec','src/computing','src/interface/grpc'],text=True)
    for line in listing.splitlines():
        meta,name=line.split('\t',1);files['code/'+name]=meta.split()[2]
    if not any(k.startswith('docs/') for k in files) or not listing:raise ValueError('Missing source coverage')
    return {'version':1,'compatibility':'5.3.0','code_commit':sha,'files':files}


def impact(previous,current,cases):
    old=previous.get('files',{});new=current['files']
    changed=sorted(k for k in old.keys()|new.keys() if old.get(k)!=new.get(k))
    # Conservative for implementation/feature changes: all cases require review.
    broad=any(not k.startswith('docs/') for k in changed)
    ids=[c['id'] for c in cases if broad or any(any(k.startswith('docs/'+d) for d in c['documentation']) for k in changed)]
    if changed and not ids: ids=[c['id'] for c in cases] # no silent coverage gap
    return {'changed_sources':changed,'affected_cases':ids,'review_required':bool(changed),
            'policy':'Review docs first; code/features only constrain implementation. Curated files are never rewritten.'}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for k in ('docs-root','features-root','code-root'):p.add_argument('--'+k,type=Path,required=True)
    p.add_argument('--code-ref',default='v5.3.0');p.add_argument('--manifest',type=Path,default=ROOT/'evals/source-manifest.json')
    p.add_argument('--report',type=Path,required=True);p.add_argument('--update',action='store_true')
    a=p.parse_args();current=fingerprint(a.docs_root,a.features_root,a.code_root,a.code_ref)
    previous=json.loads(a.manifest.read_text()) if a.manifest.exists() else {}
    result=impact(previous,current,json.loads((ROOT/'evals/cases.json').read_text())['cases'])
    a.report.parent.mkdir(parents=True,exist_ok=True);a.report.write_text(json.dumps(result,indent=2)+'\n')
    if a.update:
        a.manifest.parent.mkdir(parents=True,exist_ok=True)
        a.manifest.write_text(json.dumps(current,indent=2)+'\n')
    print(json.dumps({'changed':len(result['changed_sources']),'affected_cases':len(result['affected_cases']),'updated':a.update}))
    if result['review_required'] and not a.update:raise SystemExit(1)

if __name__=='__main__':main()
