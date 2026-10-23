#!/usr/bin/env python3
"""Replay stored synthetic result evidence without a DB; reject stale/partial proof."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from evaluate import typed
from quality.oracles import expected
from quality.run import ROOT, SUITE, digest, judge, runner_digest, source_digest, generation_compatible


def check_header(report):
    if report.get('skills_sha256') != source_digest():
        raise ValueError('Skill source changed since receipt')
    if report.get('suite_sha256') != digest(SUITE):
        raise ValueError('Suite changed since receipt')
    if report.get('runner_sha256') != runner_digest():
        raise ValueError('Judge/executor changed since receipt')
    if report.get('runtime_failure'):
        raise ValueError('Runtime did not complete cleanly')


def verify_attempt(case, receipt, suite):
    wanted = {(v, i) for v in case['variants'] for i in range(len(case['parameter_sets']))}
    instances = receipt.get('instances', [])
    seen = [(i['variant'], i['parameters_index']) for i in instances]
    if len(seen) != len(set(seen)) or set(seen) != wanted:
        raise ValueError('Missing or duplicate input-instance evidence')
    if not receipt.get('cleanup_ok'):
        raise ValueError('Owned fixture cleanup not proven')
    semantic_failures = 0
    for row in instances:
        if row.get('cleanup_ok') is False:
            raise ValueError('Cleanup failure in input instance')
        if row['stage'] == 'server':
            if row['state'] != 'failed' or row['status'] == '00000':
                raise ValueError('Inconsistent server error receipt')
            continue
        if row['stage'] != 'oracle' or row['status'] != '00000':
            raise ValueError('Unexecuted input instance')
        oracle = expected(case, suite['fixtures'][row['variant']], case['parameter_sets'][row['parameters_index']])
        left = [typed(values) for values in oracle['rows']]
        right = row['actual_typed_rows']
        key = lambda value: json.dumps(value, sort_keys=True, ensure_ascii=False)
        equal = (left == right if case['ordered'] else Counter(map(key, left)) == Counter(map(key, right)))
        equal = equal and oracle['columns'] == row['actual_columns']
        if case.get('declared_types'):
            equal = equal and row['column_types'] == case['declared_types']
        if row['state'] != ('passed' if equal else 'failed'):
            raise ValueError('Saved verdict disagrees with independent result replay')
        semantic_failures += not equal
    states = {row['state'] for row in instances}
    state = 'failed' if 'failed' in states else 'passed'
    if receipt['state'] != state:
        raise ValueError('Attempt verdict disagrees with input instances')
    return semantic_failures


def verify(report, calibration, outputs, suite):
    check_header(report)
    check_header(calibration)
    cases = {c['id']: c for c in suite['cases']}
    calibrated = set()
    for pair in calibration.get('cases', []):
        case = cases[pair['id']]
        verify_attempt(case, pair['reference'], suite)
        kills = verify_attempt(case, pair['mutant'], suite)
        if pair['reference']['state'] != 'passed' or not kills or not pair['passed']:
            raise ValueError('Oracle calibration did not discriminate a semantic mutant')
        if pair['id'] in calibrated:
            raise ValueError('Duplicate calibration case')
        calibrated.add(pair['id'])
    if calibrated != set(cases) or not calibration.get('passed'):
        raise ValueError('Incomplete calibration')
    indexed = {}
    for output in outputs:
        key = (output['case_id'], output['attempt'])
        if key in indexed:
            raise ValueError('Duplicate generation attempt')
        indexed[key] = output
    seen = set()
    for receipt in report.get('attempts', []):
        key = (receipt['case_id'], receipt['attempt'])
        if key in seen or key not in indexed:
            raise ValueError('Missing or duplicate generated-output evidence')
        seen.add(key)
        output = indexed[key]
        if not generation_compatible(output, cases[receipt['case_id']]):
            raise ValueError('Generation used a different relevant skill snapshot')
        fingerprint = hashlib.sha256(json.dumps(output, sort_keys=True).encode()).hexdigest()
        if fingerprint != receipt['output_sha256']:
            raise ValueError('Generated output changed after execution')
        verify_attempt(cases[receipt['case_id']], receipt, suite)
    wanted = {(c['id'], n) for c in suite['cases'] for n in range(1, suite['required_attempts'] + 1)}
    if seen != wanted or set(indexed) != wanted:
        raise ValueError('Independent generation attempts incomplete')
    decision = judge(suite, report['attempts'], report['skills_sha256'], report['suite_sha256'], calibration)
    if decision != report['judgement']:
        raise ValueError('Summary differs from recomputed judgement')
    return decision


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--calibration', type=Path, required=True)
    parser.add_argument('--outputs', type=Path, required=True)
    args = parser.parse_args()
    try:
        decision = verify(json.loads(args.report.read_text()), json.loads(args.calibration.read_text()),
                          [json.loads(p.read_text()) for p in args.outputs.glob('*.json')], json.loads(SUITE.read_text()))
    except (ValueError, KeyError, OSError) as exc:
        print(json.dumps({'verified': False, 'reason': str(exc)}))
        raise SystemExit(1)
    print(json.dumps({'verified': True, 'overall': decision['overall'],
                      'strata': {name: data['verdict'] for name, data in decision['strata'].items()}}))
    if any(data['verdict'] != 'meets_scoped_benchmark' for name, data in decision['strata'].items()
           if name not in json.loads(SUITE.read_text())['required_unavailable_strata']):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
