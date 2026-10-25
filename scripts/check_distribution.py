#!/usr/bin/env python3
"""Verify each built standalone archive in an isolated temporary directory."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile
from package_core_skills import CORE_SKILLS, DIST_ROOT, RELEASE_VERSION


def main():
    for name in CORE_SKILLS:
        archive=DIST_ROOT/f'{name}-{RELEASE_VERSION}.zip'
        with tempfile.TemporaryDirectory(prefix='gql-standalone-') as td:
            # package_core_skills already checks archive paths; repeat integrity before extraction.
            from package_core_skills import archive_payload
            payload=archive_payload(archive)
            with zipfile.ZipFile(archive) as z:z.extractall(td)
            root=Path(td)/name
            result=subprocess.run([sys.executable,'-I',str(root/'scripts/skill_tools.py'),'lookup','list_distinct'],
                                  cwd=td,text=True,capture_output=True,check=True)
            found=json.loads(result.stdout)
            if found['matches']!=1 or 'LIST' not in found['text']:raise SystemExit('Standalone lookup failed')
            candidate=Path(td)/'candidate.gql';candidate.write_text('RETURN list_distinct(LIST[1,1,2]) AS items')
            result=subprocess.run([sys.executable,'-I',str(root/'scripts/skill_tools.py'),'lint',str(candidate)],
                                  cwd=td,text=True,capture_output=True,check=True)
            if json.loads(result.stdout)['issues']:raise SystemExit('Standalone lint failed')
            result=subprocess.run([sys.executable,'-I',str(root/'scripts/skill_tools.py'),
                                   'quote-identifiers','values','version','person_id'],
                                  cwd=td,text=True,capture_output=True,check=True)
            if json.loads(result.stdout)!={'values':'`values`','version':'`version`','person_id':'person_id'}:
                raise SystemExit('Standalone keyword quoting failed')
            # Query routing to the sibling is optional handoff, never a link required at runtime.
            if not (root/'references/repair.md').is_file():raise SystemExit('Missing packaged repair contract')
            print(f'{name}: extracted lookup, lint and keyword quoting passed without source/manual/build dependencies')

if __name__=='__main__':main()
