"""Verify immutable bytes before creating/importing a new review copy."""
import sys,json,shutil,hashlib
from pathlib import Path
def sha(p):
 with open(p,'rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def verify(root):
 records=json.loads((root/'manifest.json').read_text())
 for rel,e in records.items():
  p=(root/rel).resolve();assert p.is_relative_to(root.resolve());assert p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],p
 return records
if __name__=='__main__':
 root=Path(sys.argv[1]).resolve();records=verify(root)
 if len(sys.argv)>2:
  target=Path(sys.argv[2]).resolve();assert not target.exists();assert target!=root and not target.is_relative_to(root);shutil.copytree(root,target);verify(target)
 print('C2_PACKAGE_VERIFIED',len(records),sha(root/'manifest.json'))
