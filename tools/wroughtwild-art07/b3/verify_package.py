"""Verify canonical bytes, optionally copy to a fresh import target and verify again."""
import sys,json,hashlib,shutil
from pathlib import Path

source=Path(sys.argv[1]).resolve()
manifest=json.loads((source/'manifest.json').read_text())
def verify(root):
    for relative,entry in manifest.items():
        path=(root/relative).resolve()
        assert path.is_relative_to(root),relative
        assert path.stat().st_size==entry['bytes'],relative
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],relative
    return len(manifest)
count=verify(source)
if len(sys.argv)>2:
    target=Path(sys.argv[2]).resolve()
    assert not target.exists() and not target.is_relative_to(source)
    shutil.copytree(source,target)
    assert verify(target)==count
print('B3_MANIFEST_OK',count,hashlib.sha256((source/'manifest.json').read_bytes()).hexdigest())
