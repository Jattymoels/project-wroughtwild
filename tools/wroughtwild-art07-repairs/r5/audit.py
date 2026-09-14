"""Exact runtime/source audit and paired report comparison; no engine invocation."""
import hashlib,json,struct,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];B=ROOT/'build/art07-repairs/r5';BASE=B/'v01';C=B/'v02'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
def embedded(p):
 data=p.read_bytes();jl=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+jl]);start=20+jl+8;blob=data[start:];out={}
 for im in g.get('images',[]):
  v=g['bufferViews'][im['bufferView']];off=v.get('byteOffset',0);out[im.get('name',str(len(out)))]=hashlib.sha256(blob[off:off+v['byteLength']]).hexdigest()
 return out
prep=read(C/'prepared.json');changes=read(C/'changes.json');allowed={v['path'] for v in changes['files']};actual=[]
for name,row in prep['original_files'].items():
 path=C/'runtime'/name
 if sha(path)!=row['sha256']:actual.append(name)
assert set(actual)==allowed,(actual,allowed)
for row in changes['files']:
 assert row['before_sha256']==prep['original_files'][row['path']]['sha256'] and row['after_sha256']==sha(C/'runtime'/row['path'])
for name,row in read(BASE/'preflight/selected-source-hashes.json').items():assert sha(BASE/'original-source'/name)==row['sha256'],name
reopen=read(C/'reopen-v02/reopen.json');assert reopen['packed_images']==42 and len(reopen['imports'])==16 and reopen['source_sha256']==sha(C/'models/r5_chest.blend')
for name,row in reopen['imports'].items():assert row['sha256']==sha(C/'models/runtime'/name),name
for name in ['review.gd','terrain_review.gd']:assert sha(Path(__file__).with_name(name))==sha(C/'runtime/game/r5'/name),name
source_images={};lids={}
for p in (C/'models/runtime').glob('chest_*_body.glb'):
 before=BASE/'original-source/runtime'/p.name
 assert embedded(p)==embedded(before),p
 source_images[p.name]=embedded(p)
for p in (C/'models/runtime').glob('*_lid.glb'):
 original=BASE/'original-source/runtime'/p.name
 assert sha(p)==sha(original)==sha(C/'runtime/game/assets/authored/e3'/p.name)
 lids[p.name]=sha(p)
old_geometry=read(BASE/'runtime/game/e3/geometry.json');new_geometry=read(C/'runtime/game/e3/geometry.json')
assert old_geometry.keys()==new_geometry.keys()
geometry_rows=[k for k in old_geometry if old_geometry[k]!=new_geometry[k]]
assert set(geometry_rows)=={Path(p).stem for p in actual if p.endswith('_body.glb')}
comparisons=[];terrain_comparisons=[]
for backend in ['forward_plus','gl_compatibility']:
 before=read(BASE/'evidence'/('baseline06-capture-'+backend)/'report.json');after=read(C/'evidence'/('candidate-capture-'+backend)/'report.json')
 assert before['failures']==after['failures']==0
 old_save=read(BASE/'users'/('baseline06-capture-'+backend)/'ART07G1/r5-expected.json');new_save=read(C/'users'/('candidate-capture-'+backend)/'ART07G1/r5-expected.json')
 assert old_save==new_save,'Full native ownership and saved block records must be identical: '+backend
 assert len(before['cases'])==len(after['cases'])==12
 for a,b in zip(before['cases'],after['cases']):
  assert a['id']==b['id'] and a['native']==b['native'],a['id']
  assert abs(a['open_top_world']-b['open_top_world'])<1e-5 and abs(a['closed_top_world']-b['closed_top_world'])<1e-5,a['id']
  assert b['cabinet_gap_m']>=-1e-4,a['id']
  comparisons.append({'renderer':backend,'id':a['id'],'old_base_gap_m':a['gap_m'],'new_foot_gap_m':b['gap_m'],'new_cabinet_gap_m':b['cabinet_gap_m'],'native_exact':True,'closed_top_world':b['closed_top_world'],'open_top_world':b['open_top_world']})
 old_terrain=read(BASE/'evidence'/('baseline05-terrain-'+backend)/'report.json');new_terrain=read(C/'evidence'/('candidate-terrain-'+backend)/'report.json')
 assert old_terrain['failures']==new_terrain['failures']==0
 assert old_terrain['terrain_sha256']==new_terrain['terrain_sha256']
 assert len(old_terrain['cases'])==len(new_terrain['cases'])==4
 for a,b in zip(old_terrain['cases'],new_terrain['cases']):
  for key in ['id','pose','element','body_transform','body_size']:assert a[key]==b[key],(backend,a['id'],key)
  assert len(a['support_samples'])==len(b['support_samples'])==9
  for x,y in zip(a['support_samples'],b['support_samples']):
   for key in ['point','support_y','normal','collider']:assert x[key]==y[key],(backend,a['id'],key)
   assert y['cabinet_gap_m']>=-1e-4
  terrain_comparisons.append({'renderer':backend,'id':a['id'],'native_pose_and_body_exact':True,'support_samples_exact':9,'old_base_gap_m':a['support_samples'][0]['gap_m'],'new_foot_gap_m':b['support_samples'][0]['gap_m'],'new_cabinet_gap_m':b['support_samples'][0]['cabinet_gap_m'],'terrain_sha256':new_terrain['terrain_sha256']})
 for label in ['baseline02','candidate']:
  base=BASE if label=='baseline02' else C
  result=read(base/'evidence'/(label+'-restore-'+backend)/'report.json');assert result['failures']==0
report={'runtime_base':prep['runtime_base'],'original_runtime_entries_checked':len(prep['original_files']),'changed_runtime_files':actual,'native_sha256':sha(C/'runtime/game/bin/libwroughtwild_sim.windows.x86_64.dll'),'embedded_image_hashes_unchanged':source_images,'exact_lids':lids,'comparisons':comparisons,'terrain_comparisons':terrain_comparisons,'geometry_semantic_rows_changed':geometry_rows,'geometry_serialization':'JSON reserialized with indent=2 and final LF; only eight body rows differ semantically.'}
(C/'audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('R5_AUDIT_OK',len(actual),'changed runtime files;',len(comparisons),'native-exact paired cases')

changes.update(status='ready_for_integration',delta_base=prep['source']['manifest_sha256'],source_master='source-candidate/r5_chest.blend',source_master_sha256=sha(C/'models/r5_chest.blend'),fit_controls=read(Path(__file__).with_name('fit.json')),owner_visual_acceptance='pending',ordinary_world_rollout='outside scope',fixture_only_files=[])
for row in changes['files']:
 row['before_bytes']=prep['original_files'][row['path']]['bytes'];row['after_bytes']=(C/'runtime'/row['path']).stat().st_size
 row['replacement_asset']='runtime/'+row['path'];row['classification']='authored_visual' if row['path'].endswith('.glb') else 'source_measurement_metadata'
for f in sorted((C/'runtime/game/r5').iterdir()):
 if f.suffix in ['.gd','.tscn']:changes['fixture_only_files'].append({'path':'game/r5/'+f.name,'after_sha256':sha(f),'purpose':'R5-only native capture/restore/cost/retained-terrain review fixture; not an ordinary-world adoption.','overlaps':[]})
(C/'changes.json').write_text(json.dumps(changes,indent=2)+'\n')
