"""Seal/verify a G1 handoff; generated engine caches are never delivery inputs."""
import hashlib
import json
import sys
from pathlib import Path


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()


def files(root):
    return sorted(p for p in root.rglob('*') if p.is_file() and '.godot' not in p.relative_to(root).parts and p.suffix not in ['.uid','.blend1'] and p != root/'manifest.json')


mode,root=sys.argv[1],Path(sys.argv[2]).resolve()
if mode=='seal':
    rows={p.relative_to(root).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in files(root)}
    with (root/'manifest.json').open('x') as stream:json.dump({'scope':'G1 source handoff; generated .godot caches and .uid sidecars excluded. Mutable play saves belong outside the package.','files':rows},stream,indent=2)
elif mode=='verify':
    rows=json.loads((root/'manifest.json').read_text())['files']
    for name,row in rows.items():
        p=(root/name).resolve();assert p.is_relative_to(root),name
        assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
else:raise ValueError(mode)
print('G1_PACKAGE_'+mode.upper(),len(rows),sum(r['bytes'] for r in rows.values()),sha(root/'manifest.json'))
