"""Hash-check a package before and after an independent fresh copy."""
import json,shutil,sys
from pathlib import Path
from inputs import ROOT,sha
src,out=[Path(p).resolve() for p in sys.argv[1:3]]
assert out.is_relative_to(ROOT/'build/art07/e2')
assert not out.exists();rows=json.loads((src/'manifest.json').read_text())['files']
for row in rows:
    p=src/row['path'];assert p.resolve().is_relative_to(src)
    assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],str(p)
shutil.copytree(src,out)
for row in rows:assert sha(out/row['path'])==row['sha256'],row['path']
(out/'preimport-verification.json').write_text(json.dumps({'files':len(rows),'manifest_sha256':sha(src/'manifest.json'),'canonical':str(src)},indent=2)+'\n')
print('E2_FRESH_COPY_OK',len(rows))
