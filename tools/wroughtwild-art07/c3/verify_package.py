import sys,json,shutil
from pathlib import Path
from prerequisites import sha
root=Path(sys.argv[1]).resolve();manifest=json.loads((root/'manifest.json').read_text())
def check(folder):
    for rel,e in manifest.items():
        p=(folder/rel).resolve();assert p.is_relative_to(folder)
        assert p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],str(p)
check(root)
if len(sys.argv)>2:
    out=Path(sys.argv[2]).resolve();assert not out.exists();shutil.copytree(root,out);check(out)
print('C3_PACKAGE_HASHES_OK',len(manifest),sha(root/'manifest.json'))
