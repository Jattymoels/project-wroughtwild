"""Verify a sealed package and optionally produce one independently hashed copy."""
import hashlib,json,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BUILD=ROOT/'build/art07/f2'
package=Path(sys.argv[1]).resolve();assert package.is_relative_to(BUILD)
def verify(root):
    data=json.loads((root/'manifest.json').read_text())
    for entry in data['files']:
        p=root/entry['path'];assert p.resolve().is_relative_to(root)
        assert p.stat().st_size==entry['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],p
    return len(data['files'])
count=verify(package)
if len(sys.argv)>2:
    dest=Path(sys.argv[2]).resolve();assert dest.is_relative_to(BUILD) and not dest.exists()
    shutil.copytree(package,dest);assert verify(dest)==count
print('F2_MANIFEST_OK',count,hashlib.sha256((package/'manifest.json').read_bytes()).hexdigest())
