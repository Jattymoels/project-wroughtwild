"""Verify sealed bytes and equivalence of the imported copy's source/runtime."""
import hashlib,json,sys
from pathlib import Path
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
canonical,copy,out=map(lambda s:Path(s).resolve(),sys.argv[1:])
data=json.loads((canonical/'manifest.json').read_text());assert data['slice']=='ART-07F1'
runtime=[]
for row in data['files']:
    p=canonical/row['path'];assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],p
    rel=Path(row['path'])
    if rel.parts[0]=='source' or (rel.parts[0]=='review' and 'evidence' not in rel.parts and rel.suffix in ['.gd','.gdshader','.tscn','.json','.glb','.dll','.godot','.tres']):
        assert sha(copy/rel)==row['sha256'],rel
        runtime.append(row['path'])
assert sha(copy/'manifest.json')==sha(canonical/'manifest.json')
assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps({'canonical':str(canonical),'verified_copy':str(copy),'manifest_sha256':sha(canonical/'manifest.json'),'sealed_files':len(data['files']),'payload_bytes':sum(r['bytes'] for r in data['files']),'all_canonical_files_unchanged':True,'equivalent_source_runtime_files':runtime},indent=2)+'\n')
print('F1_DELIVERY_UNCHANGED',len(data['files']),len(runtime),out)
