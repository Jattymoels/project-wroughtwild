"""Rehash consumed immutable inputs and the complete D1 handoff after review."""
import argparse,hashlib,json
from pathlib import Path
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); a=ap.parse_args()
p=json.loads((a.build/'prerequisites.json').read_text())
for path,h in p['inputs'].items(): assert sha(Path(path))==h,path
package=Path(p['d1_package']); assert sha(package/'manifest.json')==p['d1_manifest_sha256']
files=json.loads((package/'manifest.json').read_text())['files']
for rel,e in files.items(): assert sha(package/rel)==e['sha256'],rel
(a.build/'original-inputs-final.json').write_text(json.dumps({'inputs_unchanged':p['inputs'],'d1_package_files_unchanged':len(files),'manifest_sha256':p['d1_manifest_sha256']},indent=2)+'\n')
print('D3_ORIGINAL_INPUTS_UNCHANGED',len(p['inputs']),len(files))
