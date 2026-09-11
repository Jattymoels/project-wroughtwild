"""C2 read-only prerequisites. Derives manifest verification from B4."""
import hashlib, json, sys, subprocess
from pathlib import Path
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE='f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9'
PACKAGES={
 'b1':(Path('C:/Users/Matty/Dev/project-wroughtwild-art07-b1/build/art07/b1/v01/canopy-handoff-v02'),'00a244253614b8c58213a15f929e48fd65c9aec0bb3489600646497bfcbaf7d0'),
 'b3':(DEPOT/'build/art07/b3/worktree/build/art07/b3/v01/handoff-v02','b53961b58ddf4720ec51f77adfe1e87860890f4c3d9b68ec3f6de27102b39321'),
 'art02':(DEPOT/'build/grove-art02/emberroot-handoff','0a4f26a74335bcceddd2d31f9df3774d415f5aca6d982e9cc5305faf6ac9bba8')}
def sha(p):
 with open(p,'rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def verify():
 result={}
 for key,(root,h) in PACKAGES.items():
  assert sha(root/'manifest.json')==h,(key,'manifest')
  records=json.loads((root/'manifest.json').read_text())
  for rel,e in records.items():
   p=(root/rel).resolve();assert p.is_relative_to(root.resolve())
   assert p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],p
  result[key]={'path':str(root),'manifest_sha256':h,'files':len(records)}
 for commit in ['f323624','2ca4f4e','a80c0a8']:
  subprocess.run(['git','merge-base','--is-ancestor',commit,BASE],check=True)
 return result
if __name__=='__main__':
 result=verify();Path(sys.argv[1]).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
