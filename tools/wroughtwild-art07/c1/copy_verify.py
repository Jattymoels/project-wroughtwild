"""Hash/verify a fresh review copy before any engine can write import caches."""
import sys,json,hashlib,shutil
from pathlib import Path
source,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists()
records=json.loads((source/'manifest.json').read_text())
def verify(root):
    for rel,r in records.items():
        p=(root/rel).resolve();assert p.is_relative_to(root)
        with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
        assert p.stat().st_size==r['bytes'] and h==r['sha256'],p
verify(source);shutil.copytree(source,out);verify(out)
print(json.dumps({'source':str(source),'copy':str(out),'files':len(records),'manifest_sha256':hashlib.sha256((source/'manifest.json').read_bytes()).hexdigest(),'all_hashes_match':True},indent=2))
