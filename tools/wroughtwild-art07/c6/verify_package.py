"""Verify every immutable package file; optional fresh copy, never import canonical data."""
import json,sys,shutil
from pathlib import Path
sys.dont_write_bytecode=True
from prerequisites import sha
root=Path(sys.argv[1]).resolve();manifest=json.loads((root/'manifest.json').read_text())
actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and p!=root/'manifest.json'}
assert actual==set(manifest),'unlisted or missing canonical files'
for rel,entry in manifest.items():
    path=(root/rel).resolve();assert path.is_relative_to(root)
    assert path.stat().st_size==entry['bytes'] and sha(path)==entry['sha256'],path
if len(sys.argv)>2:
    copy=Path(sys.argv[2]).resolve();assert not copy.exists() and not copy.is_relative_to(root);shutil.copytree(root,copy)
    for rel,entry in manifest.items():assert sha(copy/rel)==entry['sha256'],rel
print(json.dumps({'files':len(manifest),'bytes':sum(e['bytes'] for e in manifest.values()),'manifest_sha256':sha(root/'manifest.json'),'canonical_unchanged':True},indent=2))
