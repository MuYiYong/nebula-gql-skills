#!/usr/bin/env python3
"""Calibrate semantic oracles with valid references and deliberately wrong code."""
import argparse
import json
import os
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from quality.calibration import CASES
from quality.run import SUITE, execute_one, source_digest, digest, runner_digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--graph-type', default='basketballplayer_type')
    args = parser.parse_args()
    from nebulagraph_python.client import NebulaClient
    suite = json.loads(SUITE.read_text())
    report = {'kind': 'judge_calibration_not_model_quality', 'suite_sha256': digest(SUITE),
              'skills_sha256': source_digest(), 'runner_sha256': runner_digest(), 'cases': []}
    client = None
    try:
        client = NebulaClient(addresses=os.environ['NEBULA_ADDRESS'], user_name=os.environ['NEBULA_USER'],
                              password=os.environ['NEBULA_PASSWORD'], connect_timeout_ms=5000, request_timeout_ms=10000)
        for case in suite['cases']:
            pair = []
            for query in CASES[case['id']]:
                output = {'case_id': case['id'], 'attempt': 1, 'query': query, 'skills_sha256': report['skills_sha256']}
                receipt = execute_one(client, case, output, suite, args.graph_type)
                pair.append(receipt)
                if not receipt.get('cleanup_ok', True):
                    report['cleanup_failure_receipt'] = receipt
                    raise RuntimeError('Stop after failed owned-object cleanup')
            killed = any(i['state'] == 'failed' and i['stage'] == 'oracle' for i in pair[1]['instances'])
            report['cases'].append({'id': case['id'], 'reference': pair[0], 'mutant': pair[1],
                                    'passed': pair[0]['state'] == 'passed' and killed and pair[1]['cleanup_ok']})
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    except Exception as exc:
        report['runtime_failure'] = type(exc).__name__
    finally:
        if client:
            client.close()
    report['passed'] = len(report['cases']) == len(suite['cases']) and all(c['passed'] for c in report['cases'])
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'passed': report['passed'], 'cases': len(report['cases']), 'report': str(args.report)}))
    if not report['passed']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
