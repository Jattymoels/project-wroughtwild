"""Exact lineage, independent imported geometry, scene checks and native scope."""
import ast,json,struct,sys,zipfile
from pathlib import Path
from inputs import ROOT,sha,verify
build=Path(sys.argv[1]).resolve();assert build.is_relative_to(ROOT/'build/art07/e1')
original=json.loads((ROOT/'build/art07/e1/v01/inputs/provenance.json').read_text())
current=verify();assert current['dependencies']==original['dependencies']
for name,digest in original['sources'].items():assert sha(name)==digest,name
models=build/'models';review=build/'review';geometry=json.loads((models/'source/geometry.json').read_text())
reopen=json.loads((build/'reopen-v02/reopen.json').read_text());assert reopen['packed_images']==12 and len(reopen['imports'])==6
exports={}
for key,row in geometry.items():
 imported=reopen['imports'][key+'.glb']
 assert row['triangles']==imported['triangles'] and row['degenerates']==imported['degenerates']==0
 assert row['nonmanifold_edges']==imported['nonmanifold_edges']==0
 lo,hi=row['bounds_blender'];assert lo[2]>=-.00001 and hi[2]<=2 and all(abs(v)<=.48001 for v in lo[:2]+hi[:2])
 blob=(models/'runtime'/(key+'.glb')).read_bytes();magic,version,total=struct.unpack_from('<III',blob);size,kind=struct.unpack_from('<II',blob,12)
 assert magic==0x46546c67 and version==2 and total==len(blob) and kind==0x4e4f534a
 gltf=json.loads(blob[20:20+size]);primitives=gltf['meshes'][0]['primitives']
 assert sum(gltf['accessors'][p['indices']]['count']//3 for p in primitives)==row['triangles']
 assert sha(models/'runtime'/(key+'.glb'))==sha(review/'game/assets/authored/e1'/(key+'.glb'))
 exports[key]={'triangles':row['triangles'],'surfaces':len(primitives),'bytes':len(blob),'sha256':sha(models/'runtime'/(key+'.glb')),'bounds_blender':row['bounds_blender'],'generator':gltf['asset'].get('generator')}
assert len(geometry['workbench_near']['tool_cut_depths_m'])==5
assert min(geometry['workbench_near']['tool_cut_depths_m'])>.007
for p in Path(__file__).parent.glob('*.py'):ast.parse(p.read_text(),filename=str(p))
changed=[];unchanged=0
with zipfile.ZipFile(review/'frozen.zip') as z:
 for name in z.namelist():
  if name.endswith('/'):continue
  if z.read(name).replace(b'\r\n',b'\n')!=(review/name).read_bytes().replace(b'\r\n',b'\n'):changed.append(name)
  else:unchanged+=1
assert sorted(changed)==['game/art/station_look.gd','game/project.godot','game/scripts/piece_look.gd'],changed
checks={}
for backend in ['forward_plus','gl_compatibility']:
 for name,count in [('checks',304),('restore',132)]:
  row=json.loads((review/'evidence'/backend/(name+'.json')).read_text());assert row['failures']==0 and row['checks']==count,(backend,name,row)
  checks[backend+'/'+name]=row
 assert len(list((review/'evidence'/backend).glob('orbit-*.png')))==96
 assert len(list((review/'evidence'/backend).glob('work-*.png')))==48
 textures=list((review/'game/e1/textures').glob('*.png'));assert len(textures)==12
 result=json.loads((review/'evidence'/backend/'benchmark.json').read_text());assert len(result['rows'])==4
 for r in result['rows']:assert 0<r['p50_ms']<=r['p95_ms']<=r['worst_ms']
data={'base':current['base'],'dependencies':current['dependencies'],'original_sources_unchanged':len(original['sources']),'native_copy_changed_files':changed,'native_copy_unchanged_files':unchanged,'runtime':exports,'master_sha256':sha(models/'source/e1_stations.blend'),'checks':checks,'map_png_bytes':sum(p.stat().st_size for p in textures),'maps':12,'map_base_rgb_bytes':(1024*1024+3*512*512)*3*3,'rgba8_full_mip_upper_bytes':(1024*1024+3*512*512)*3*4*4//3}
(build/'audit.json').write_text(json.dumps(data,indent=2)+'\n')
print('E1_FINAL_AUDIT_OK',len(exports),'exports;',unchanged,'unchanged native files;',len(original['sources']),'original hashes')
