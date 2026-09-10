"""Verify every delivered file before importing a fresh handoff copy."""
import hashlib,json,shutil,sys
from pathlib import Path
src,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
assert not out.exists();shutil.copytree(src,out)
manifest=json.loads((src/'manifest.json').read_text());checks=[]
for e in manifest['files']:
    for base in [src,out]:
        p=base/e['path'];assert p.stat().st_size==e['bytes'];assert hashlib.sha256(p.read_bytes()).hexdigest()==e['sha256'],p
    checks.append(e['path'])
(out/'preimport-verification.json').write_text(json.dumps({'result':'pass','files':checks,'manifest_sha256':hashlib.sha256((src/'manifest.json').read_bytes()).hexdigest(),'canonical':str(src),'copy':str(out)},indent=2)+'\n')
print('D6_FRESH_COPY_OK',len(checks),'files')
