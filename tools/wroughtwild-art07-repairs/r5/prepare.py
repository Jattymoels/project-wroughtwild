"""R5 local preparation and job specs. All original packages remain read-only."""
import argparse, hashlib, json, shutil, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'build/art07-repairs/r5/v01'
PY=Path('C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe')
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
def write(p,v):
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('x',encoding='utf-8') as f:json.dump(v,f,indent=2)
def job(version,ident,args,blender=False,state=None):
 base=ROOT/'build/art07-repairs/r5'/version
 program=read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json')['tools']['blender'] if blender else str(base/'runtime/engine/Godot_v4.5-stable_win64.exe')
 return dict(id=ident,program=program,arguments=args,log=str(base/'logs'/f'{ident}.log'),state=str(base/'users'/(state or ident)))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['verify-prepared','copy-master','install-harness','spec']);p.add_argument('--version',default='v01');p.add_argument('--name');p.add_argument('--mode',default='checks');a=p.parse_args()
 base=ROOT/'build/art07-repairs/r5'/a.version
 if a.action=='verify-prepared':
  r=read(base/'prepared.json');bad=[]
  for name,row in r['original_files'].items():
   f=Path(r['runtime'])/name
   if f.stat().st_size!=row['bytes'] or sha(f)!=row['sha256']:bad.append(name)
  assert not bad,bad
  write(base/'preflight/prepared-rehash.json',{'files':r['files'],'bytes':r['bytes'],'bad':bad,'native':sha(Path(r['runtime'])/'game/bin/libwroughtwild_sim.windows.x86_64.dll')})
  print('R5_PREPARED_REHASH_OK',r['files'],r['bytes'])
 elif a.action=='copy-master':
  inputs=read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json');src=Path(inputs['source_packages']['e3']['path']);out=base/'original-source';assert not out.exists()
  manifest=read(src/'manifest.json');rows=manifest.get('files',manifest)
  if isinstance(rows,list):rows={r['path']:r for r in rows}
  selected={k:v for k,v in rows.items() if k.startswith('source/') or k.startswith('runtime/chest_')}
  for k,v in selected.items():
   assert sha(src/k)==v['sha256'];dest=out/k;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src/k,dest);assert sha(dest)==v['sha256']
  write(base/'preflight/selected-source-hashes.json',selected);print('R5_SOURCE_COPIED',len(selected))
 elif a.action=='install-harness':
  out=base/'runtime/game/r5';out.mkdir(exist_ok=True)
  for f in ['review.gd','terrain_review.gd']:
   src=Path(__file__).with_name(f)
   if src.exists():shutil.copy2(src,out/f);(out/f.replace('.gd','.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://r5/'+f+'" id="1"]\n[node name="R5Review" type="Node3D"]\nscript = ExtResource("1")\n')
  terrain=out/'terrain_review.tscn'
  if (out/'terrain_review.gd').exists():terrain.write_text('[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://scenes/sandpit.tscn" id="1"]\n[ext_resource type="Script" path="res://r5/terrain_review.gd" id="2"]\n[node name="R5TerrainReview" instance=ExtResource("1")]\nscript = ExtResource("2")\n')
 elif a.action=='spec':
  runtime=base/'runtime';jobs=[]
  for renderer in ['forward_plus','gl_compatibility']:
   ident=a.name+'-'+renderer
   args=['--rendering-method',renderer,'--path',str(runtime/'game'),'res://r5/'+('terrain_review' if a.mode=='terrain' else 'review')+'.tscn','--','--'+a.mode,'--out='+str(base/'evidence'/ident)]
   jobs.append(job(a.version,ident,args,state=(a.name.replace('restore','checks')+'-'+renderer if a.mode=='restore' else ident)))
  write(base/(a.name+'.json'),jobs)
