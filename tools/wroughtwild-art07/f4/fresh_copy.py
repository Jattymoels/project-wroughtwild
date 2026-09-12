"""Verify sealed bytes and copy into a new directory before import."""
import json,hashlib,shutil,sys
from pathlib import Path
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
source,dest=map(lambda x:Path(x).resolve(),sys.argv[1:]);data=json.loads((source/'manifest.json').read_text())
assert not dest.exists() and not dest.is_relative_to(source);dest.mkdir(parents=True)
for record in data['files']:
 rel=Path(record['path']);assert not rel.is_absolute() and '..' not in rel.parts
 p=source/rel;assert p.stat().st_size==record['bytes'] and sha(p)==record['sha256'],p
 target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target);assert sha(target)==record['sha256']
shutil.copy2(source/'manifest.json',dest/'manifest.json')
(dest/'preimport-verification.json').write_text(json.dumps({'source':str(source),'manifest_sha256':sha(source/'manifest.json'),'files_verified':len(data['files'])},indent=2)+'\n')
print('F4_FRESH_COPY_OK',len(data['files']),dest)
