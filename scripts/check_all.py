#!/usr/bin/env python3
"""Offline release gate. Every subprocess must pass; no DB or model credentials."""
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    for args in [
        ['scripts/audit_skill_capabilities.py'],
        ['-m','unittest','discover','-s','tests','-v'],
        ['scripts/evaluate.py','--fixtures','--report','dist/eval-fixtures.json'],
        ['scripts/evaluate.py','--outputs','evals/observations/current.json','--report','dist/model-current.json'],
        ['scripts/evaluate.py','--trigger-outputs','evals/observations/current-routes.json','--report','dist/routes-current.json'],
        ['scripts/quality/verify.py','--report','evals/quality/evidence/current/model-run.json','--calibration','evals/quality/evidence/current/calibration.json','--outputs','evals/quality/evidence/current/attempts'],
        ['scripts/package_core_skills.py'],
        ['scripts/check_distribution.py'],
    ]:
        result=subprocess.run([sys.executable,*args],cwd=ROOT,text=True,capture_output=True)
        if result.returncode:
            print(result.stdout);print(result.stderr,file=sys.stderr);raise SystemExit(result.returncode)
        print('PASS: '+' '.join(args))
    print('Offline gates passed. Fixture checks are not model accuracy or live DB acceptance.')

if __name__=='__main__':main()
