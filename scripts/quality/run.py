#!/usr/bin/env python3
"""Execute frozen GQL generation attempts against independent synthetic oracles."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from evaluate import compare_results, typed
from quality.oracles import expected
from quality.runtime import OwnedGraph, CleanupFailure, guard, statement
from validate_database import materialize

ROOT = Path(__file__).resolve().parents[2]
SUITE = ROOT / 'evals/quality/suite.json'
GENERATION_MANIFESTS = ROOT / 'evals/quality/generation-manifests.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_files():
    return {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted((ROOT / 'src').rglob('*'))
            if p.is_file() and '__pycache__' not in p.parts}


def source_digest():
    return hashlib.sha256(json.dumps(source_files(), sort_keys=True).encode()).hexdigest()


def generation_compatible(output, case):
    generated = output.get('skills_sha256')
    if generated == source_digest():
        return True
    manifests = json.loads(GENERATION_MANIFESTS.read_text()) if GENERATION_MANIFESTS.exists() else {}
    old = manifests.get(generated, {}).get('files', {})
    if hashlib.sha256(json.dumps(old, sort_keys=True).encode()).hexdigest() != generated:
        return False
    skill = 'gql-query-generator' if case['stratum'] == 'query' else 'gql-procedure-generator'
    prefix = 'src/' + skill + '/'
    relevant = {p: sha for p, sha in old.items() if p.startswith(prefix)}
    return bool(relevant) and relevant == {p: sha for p, sha in source_files().items() if p.startswith(prefix)}


def runner_digest():
    paths = [*Path(__file__).parent.glob('*.py'), ROOT / 'scripts/evaluate.py',
             ROOT / 'scripts/skill_tools.py', ROOT / 'scripts/validate_database.py', GENERATION_MANIFESTS]
    return hashlib.sha256(json.dumps({p.name: digest(p) for p in paths}, sort_keys=True).encode()).hexdigest()


def export_public():
    suite = json.loads(SUITE.read_text())
    return {
        'skills_sha256': source_digest(), 'suite_sha256': digest(SUITE),
        'attempts_required': suite['required_attempts'],
        'cases': [{k: c[k] for k in ('id', 'stratum', 'split', 'prompt')} for c in suite['cases']],
        'format': {'case_id': 'id', 'attempt': '1 or 2', 'query': 'raw GQL body, no fences',
                   'skills_sha256': 'copy current frozen source digest', 'notes': 'assumptions/evidence'},
    }


def execute_one(client, case, output, suite, graph_type):
    result = {
        'case_id': case['id'], 'attempt': output['attempt'], 'stratum': case['stratum'],
        'split': case['split'], 'output_sha256': hashlib.sha256(json.dumps(output, sort_keys=True).encode()).hexdigest(),
        'instances': [], 'cleanup_ok': True,
    }
    result['generation_package_sha256'] = output.get('skills_sha256')
    result['generation_scope'] = 'entire referenced skill tree must be identical'
    if not generation_compatible(output, case):
        return {**result, 'state': 'unverified', 'reason': 'stale_or_unidentified_skill_source'}
    try:
        query, notices = guard(output['query'], case)
    except (ValueError, KeyError):
        return {**result, 'state': 'unverified', 'reason': 'outside_reviewed_execution_subset'}
    result['static_review_notices'] = notices
    for variant in case['variants']:
        fixture = suite['fixtures'][variant]
        for index, params in enumerate(case['parameter_sets']):
            row = {'variant': variant, 'parameters_index': index}
            owned = None
            try:
                if case['stratum'] == 'database_procedure':
                    raw = client.execute(statement(query, case, params))
                    actual = materialize(raw)
                else:
                    owned = OwnedGraph(client, graph_type)
                    with owned:
                        owned.seed(fixture)
                        raw = client.execute(statement(query, case, params, owned.name))
                        actual = materialize(raw)
                if actual['status'] != '00000':
                    row.update(state='failed', stage='server', status=actual['status'])
                else:
                    oracle = expected(case, fixture, params)
                    equivalent = compare_results(oracle, actual, case['ordered'])
                    engine_types = [t.get_type().name for t in raw.result_table.column_data_types] if raw.result_table else []
                    if case.get('declared_types'):
                        equivalent = equivalent and engine_types == case['declared_types']
                    row.update(state='passed' if equivalent else 'failed', stage='oracle', status='00000',
                               expected_rows=len(oracle['rows']), actual_rows=len(actual['rows']),
                               column_types=engine_types, actual_columns=actual['columns'],
                               actual_typed_rows=[typed(values) for values in actual['rows']],
                               result_sha256=hashlib.sha256(json.dumps(typed(actual), sort_keys=True).encode()).hexdigest())
            except Exception as exc:
                # Server messages may include credentials/addresses; retain only class and own object.
                row.update(state='unverified', stage='runtime', error_type=type(exc).__name__)
                if owned and owned.created and not owned.cleaned:
                    row['owned_graph_needing_cleanup'] = '#' + owned.name
            finally:
                if owned:
                    row['cleanup_ok'] = owned.cleaned
                    result['cleanup_ok'] = result['cleanup_ok'] and owned.cleaned
            result['instances'].append(row)
            if not result['cleanup_ok']:
                result['state'] = 'unverified'
                result['reason'] = 'cleanup_failed_stop_run'
                return result
    states = {row['state'] for row in result['instances']}
    result['state'] = ('failed' if 'failed' in states else 'unverified' if 'unverified' in states
                       or not result['cleanup_ok'] else 'passed')
    return result


def wilson(successes, total):
    if total == 0:
        return None
    z = 1.96
    p = successes / total
    denominator = 1 + z * z / total
    center = (p + z * z / (2 * total)) / denominator
    radius = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total * total)) / denominator
    return [max(0.0, center - radius), min(1.0, center + radius)]


def judge(suite, attempts, skills_sha256, suite_sha256, calibration=None):
    """Unknown/missing/stale cannot count as success. Instances are not trials."""
    grouped = {}
    seen = set()
    for result in attempts:
        key = (result['case_id'], result['attempt'])
        if key in seen:
            raise ValueError('Duplicate attempt receipt')
        seen.add(key)
        grouped.setdefault(result['case_id'], []).append(result)
    known = {c['id'] for c in suite['cases']}
    if set(grouped) - known:
        raise ValueError('Unknown case receipt')
    strata = {}
    for case in suite['cases']:
        bucket = strata.setdefault(case['stratum'], {'cases': [], 'verdict': 'insufficient_evidence'})
        rows = grouped.get(case['id'], [])
        expected_instances = {(variant, i) for variant in case['variants'] for i in range(len(case['parameter_sets']))}
        complete = all(
            {(i['variant'], i['parameters_index']) for i in r.get('instances', [])} == expected_instances
            and len(r.get('instances', [])) == len(expected_instances)
            and all(i.get('state') == 'passed' and i.get('stage') == 'oracle' and i.get('status') == '00000'
                    for i in r.get('instances', [])) for r in rows)

        wanted = set(range(1, suite['required_attempts'] + 1))
        actual = {r['attempt'] for r in rows}
        if any(r['state'] == 'failed' for r in rows):
            state = 'failed'
        elif not complete or actual != wanted or any(r['state'] != 'passed' or not r.get('cleanup_ok') for r in rows):
            state = 'unverified'
        else:
            state = 'passed'
        bucket['cases'].append({'id': case['id'], 'split': case['split'], 'state': state,
                                'attempts_seen': len(rows), 'successful_attempts': sum(r['state'] == 'passed' for r in rows)})
    calibrated = (calibration is not None and calibration.get('passed') is True
                  and calibration.get('skills_sha256') == skills_sha256
                  and calibration.get('suite_sha256') == suite_sha256
                  and calibration.get('runner_sha256') == runner_digest()
                  and {c['id'] for c in calibration.get('cases', []) if c.get('passed')} == known)
    for bucket in strata.values():
        states = {c['state'] for c in bucket['cases']}
        bucket['verdict'] = ('not_met' if 'failed' in states else 'insufficient_evidence' if not calibrated or 'unverified' in states
                             else 'meets_scoped_benchmark')
        bucket['first_attempt_successes'] = sum(
            any(r['case_id'] == c['id'] and r['attempt'] == 1 and r['state'] == 'passed' for r in attempts)
            for c in bucket['cases'])
        bucket['case_count'] = len(bucket['cases'])
        ids = {c['id'] for c in bucket['cases']}
        first_verified = sum(r['case_id'] in ids and r['attempt'] == 1 and r['state'] in ('passed','failed') for r in attempts)
        bucket['first_attempt_verified'] = first_verified
        bucket['first_attempt_wilson95'] = wilson(bucket['first_attempt_successes'], first_verified)
        bucket['interval_caveat'] = 'Descriptive only: curated cases are not a random population sample; repeats are not additional independent cases.'
        bucket['two_attempt_pass_cases'] = sum(c['state'] == 'passed' for c in bucket['cases'])
        bucket['disagreement_cases'] = [c['id'] for c in bucket['cases']
            if {r['state'] for r in attempts if r['case_id'] == c['id']} >= {'passed','failed'}]
    for unavailable in suite['required_unavailable_strata']:
        strata[unavailable] = {'verdict': 'insufficient_evidence', 'reason': 'no_authorized_supported_runtime_receipts'}
    return {
        'skills_sha256': skills_sha256, 'suite_sha256': suite_sha256,
        'oracle_calibrated': calibrated,
        'overall': ('not_met' if any(s['verdict'] == 'not_met' for s in strata.values())
                    else 'meets_declared_benchmark' if all(s['verdict'] == 'meets_scoped_benchmark' for s in strata.values())
                    else 'insufficient_evidence'),
        'scope_note': 'Scoped passes do not establish all GQL/Procedure capabilities or general accuracy.',
        'strata': strata,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--export', action='store_true')
    parser.add_argument('--outputs', type=Path, help='Directory of isolated attempt JSON files')
    parser.add_argument('--report', type=Path)
    parser.add_argument('--graph-type', default='basketballplayer_type')
    parser.add_argument('--calibration', type=Path, default=ROOT/'dist/quality-calibration.json')
    args = parser.parse_args()
    if args.export:
        print(json.dumps(export_public(), ensure_ascii=False, indent=2))
        return
    if not args.outputs or not args.report:
        parser.error('--outputs and --report required for execution')
    suite = json.loads(SUITE.read_text())
    calibration = json.loads(args.calibration.read_text()) if args.calibration.exists() else None
    cases = {c['id']: c for c in suite['cases']}
    outputs = [json.loads(p.read_text()) for p in sorted(args.outputs.glob('*.json'))]
    keys = [(o['case_id'], o['attempt']) for o in outputs]
    if len(keys) != len(set(keys)) or any(k[0] not in cases or type(k[1]) is not int or k[1] not in (1, 2) for k in keys):
        parser.error('Unknown/duplicate case attempt')
    for name in ['NEBULA_ADDRESS', 'NEBULA_USER', 'NEBULA_PASSWORD']:
        if not os.environ.get(name):
            parser.error('Set credentials privately in environment')
    from nebulagraph_python.client import NebulaClient
    started = time.monotonic()
    report = {'version': 1, 'skills_sha256': source_digest(), 'suite_sha256': digest(SUITE),
              'runner_sha256': runner_digest(), 'attempts': []}
    client = None
    try:
        client = NebulaClient(addresses=os.environ['NEBULA_ADDRESS'], user_name=os.environ['NEBULA_USER'],
                              password=os.environ['NEBULA_PASSWORD'], connect_timeout_ms=5000, request_timeout_ms=10000)
        version = materialize(client.execute('SHOW VERSION'))
        report['server_version'] = version['rows'][0][0]
        if not args.graph_type.isidentifier():
            raise ValueError('Invalid graph type')
        schema = client.execute(f'SHOW CREATE GRAPH TYPE `{args.graph_type}`')
        if not schema.is_succeeded:
            raise RuntimeError('Fixture type unavailable')
        report['schema_sha256'] = hashlib.sha256(json.dumps(materialize(schema), sort_keys=True).encode()).hexdigest()
        for output in outputs:
            receipt = execute_one(client, cases[output['case_id']], output, suite, args.graph_type)
            report['attempts'].append(receipt)
            if not receipt.get('cleanup_ok', True):
                raise CleanupFailure('Stop after failed owned-object cleanup')
            # Preserve completed attempts if a subsequent request is interrupted.
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    except Exception as exc:
        report['runtime_failure'] = type(exc).__name__
    finally:
        if client:
            client.close()
    report['elapsed_seconds'] = time.monotonic() - started
    if report['skills_sha256'] != source_digest() or report['runner_sha256'] != runner_digest() or report['suite_sha256'] != digest(SUITE):
        report['runtime_failure'] = 'SourceChangedDuringRun'
    report['judgement'] = judge(suite, report['attempts'], report['skills_sha256'], report['suite_sha256'], calibration)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    counts = {s: sum(r['state'] == s for r in report['attempts']) for s in ('passed', 'failed', 'unverified')}
    print(json.dumps({'attempts': counts, 'overall': report['judgement']['overall'], 'report': str(args.report)}))
    if 'runtime_failure' in report or counts['failed'] or counts['unverified']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
