"""Verify every canonical file, then optionally create and verify a fresh copy."""
import sys,json,shutil
from pathlib import Path
sys.dont_write_bytecode=True
from prerequisites import sha
root=Path(sys.argv[1]).resolve()
def verify_package(path):
    records=json.loads((path/'manifest.json').read_text())
    assert {p.relative_to(path).as_posix() for p in path.rglob('*') if p.is_file()}==set(records)|{'manifest.json'},'Unexpected canonical files'
    for rel,r in records.items():
        p=(path/rel).resolve();assert p.is_relative_to(path)
        assert p.stat().st_size==r['bytes'] and sha(p)==r['sha256'],p
    return {'path':str(path),'files':len(records),'bytes':sum(r['bytes'] for r in records.values()),'manifest_sha256':sha(path/'manifest.json')}
r=verify_package(root)
if len(sys.argv)>2:
    target=Path(sys.argv[2]).resolve();assert not target.exists() and not target.is_relative_to(root)
    shutil.copytree(root,target);r['copy']=verify_package(target)
print(json.dumps(r,indent=2))
