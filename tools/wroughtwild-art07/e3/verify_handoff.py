"""Verify every immutable file before making an optional fresh import copy."""
import json,shutil,sys
from pathlib import Path
from inputs import sha,ROOT
src=Path(sys.argv[1]).resolve();rows=json.loads((src/'manifest.json').read_text())['files']
for row in rows:
 p=(src/row['path']).resolve();assert p.is_relative_to(src)
 assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],p
if len(sys.argv)>2:
 out=Path(sys.argv[2]).resolve();assert out.is_relative_to(ROOT/'build/art07/e3') and not out.exists()
 shutil.copytree(src,out)
 for row in rows:assert sha(out/row['path'])==row['sha256']
 (out/'preimport-verification.json').write_text(json.dumps({'canonical':str(src),'manifest_sha256':sha(src/'manifest.json'),'verified_files':len(rows)},indent=2))
print('E3_HANDOFF_VERIFIED',len(rows),sha(src/'manifest.json'))
