"""Verify every sealed file before and after copying to a disposable review."""
import hashlib,json,shutil,sys
from pathlib import Path
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
source,dest=[Path(s).resolve() for s in sys.argv[1:]]


data=json.loads((source/'manifest.json').read_text());assert data['slice']=='ART-07F1';assert not dest.exists();dest.mkdir(parents=True)
for item in data['files']:
 rel=Path(item['path']);assert not rel.is_absolute() and '..' not in rel.parts
 src=source/rel;assert sha(src)==item['sha256'] and src.stat().st_size==item['bytes'],rel
 out=dest/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,out);assert sha(out)==item['sha256']
shutil.copy2(source/'manifest.json',dest/'manifest.json')
(dest/'preimport-verification.json').write_text(json.dumps({'files':len(data['files']),'source':str(source),'source_manifest_sha256':sha(source/'manifest.json'),'all_matched':True},indent=2)+'\n')
print('F1_FRESH_COPY_VERIFIED',len(data['files']),dest)
