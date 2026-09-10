"""Verify every packaged byte; optionally copy to a fresh location before import."""
import hashlib,json,shutil,sys
from pathlib import Path
src=Path(sys.argv[1]).resolve()
m=json.loads((src/'manifest.json').read_text(encoding='utf-8'))
for r in m['files']:
    p=src/r['path']
    assert p.is_relative_to(src) and p.is_file()
    assert p.stat().st_size==r['bytes']
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],p
if len(sys.argv)>2:
    dest=Path(sys.argv[2]).resolve()
    assert not dest.exists()
    shutil.copytree(src,dest)
    for r in m['files']:
        assert hashlib.sha256((dest/r['path']).read_bytes()).hexdigest()==r['sha256']
print('D5_HANDOFF_VERIFIED',len(m['files']),hashlib.sha256((src/'manifest.json').read_bytes()).hexdigest())
