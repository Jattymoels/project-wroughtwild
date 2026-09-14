"""Retain every required input hash result and copy only selected unchanged masters."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'build/art07-repairs/r3/v01'
INPUTS=json.loads((ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json').read_text())
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
results={}
for ident in ['runtime_source','g2_review','d4','d5','d6']:
    package=INPUTS.get(ident,INPUTS['source_packages'].get(ident))
    root=Path(package['path']);manifest=root/'manifest.json'
    assert sha(manifest)==package['manifest_sha256']
    raw=json.loads(manifest.read_text());rows=raw.get('files',raw)
    if isinstance(rows,list):rows={r['path']:r for r in rows}
    checked=[]
    for name,row in rows.items():
        p=(root/name).resolve();assert p.is_relative_to(root.resolve())
        actual=sha(p);size=p.stat().st_size
        assert actual==row['sha256'].lower() and size==row['bytes'],p
        checked.append({'path':name,'bytes':size,'expected_sha256':row['sha256'].lower(),'actual_sha256':actual})
    results[ident]={'package':package,'files':checked,'result':'all match'}
    print('R3_FULL_HASH_RESULTS',ident,len(checked),flush=True)
    dest=OUT/'inputs'/ident/'manifest.json';dest.parent.mkdir(parents=True,exist_ok=True)
    assert not dest.exists();dest.write_bytes(manifest.read_bytes())
    if ident in ['d4','d5','d6']:
        master_name='source/'+ident+'_materials.blend'
        master=root/master_name;copy=OUT/'masters'/(ident+'_materials.blend');copy.parent.mkdir(exist_ok=True)
        assert not copy.exists();copy.write_bytes(master.read_bytes());assert sha(copy)==rows[master_name]['sha256'].lower()
        results[ident]['selected_master']={'source':str(master),'copy':str(copy),'sha256':sha(copy)}
path=OUT/'input-hash-results.json'
with path.open('x',encoding='utf-8') as f:json.dump(results,f,indent=2)
blender=INPUTS['tools']['blender']
job={'id':'packed-source-reopen-01','program':blender,'arguments':['--background','--threads','8','--python-exit-code','1','--python',str(Path(__file__).with_name('reopen.py')),'--',str(OUT/'masters'),str(OUT/'packed-reopen-01')],'log':str(OUT/'logs/packed-source-reopen-01.log'),'state':str(OUT/'users/packed-source-reopen-01')}
with (OUT/'packed-source-reopen-01.json').open('x') as f:json.dump([job],f,indent=2)
print('R3_INPUT_RESULTS_RETAINED',sha(path))
