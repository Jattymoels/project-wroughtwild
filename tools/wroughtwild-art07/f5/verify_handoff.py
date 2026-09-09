"""Verify immutable delivery bytes before making a fresh engine-writable copy."""
import sys,shutil,json
from pathlib import Path
from audit import read,sha
source,out=map(lambda x:Path(x).resolve(),sys.argv[1:3]);assert not out.exists()
manifest=read(source/'manifest.json')
for name,entry in manifest['files'].items():
    assert sha(source/name)==entry['sha256'],name
    target=out/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source/name,target)
    assert sha(target)==entry['sha256'],name
shutil.copy2(source/'manifest.json',out/'manifest.json')
(out.parent/'copy-verification.json').write_text(json.dumps({'source':str(source),'copy':str(out),'manifest_sha256':sha(source/'manifest.json'),'verified_files':len(manifest['files']),'failures':[]},indent=2))
print('F5_FRESH_HANDOFF_COPY_VERIFIED',len(manifest['files']))
