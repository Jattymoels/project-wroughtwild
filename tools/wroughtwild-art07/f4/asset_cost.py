"""Actual exported triangle/surface and distinct texture cost; no assumed budget."""
import json,sys,struct,hashlib
from pathlib import Path
import numpy as np
from glb import read
from inputs import DEPOT,PACKAGES
assets,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);assert not out.exists()
maps=json.loads((assets/'source/textures.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def accessor(p,d,i):
 raw=p.read_bytes();jlen=struct.unpack_from('<I',raw,12)[0];binary=raw[28+jlen:]
 a=d['accessors'][i];v=d['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5121:'u1',5125:'<u4'}[a['componentType']];width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
 offset=v.get('byteOffset',0)+a.get('byteOffset',0);step=v.get('byteStride',np.dtype(dtype).itemsize*width)
 return np.ndarray((a['count'],width),dtype=dtype,buffer=binary,offset=offset,strides=(step,np.dtype(dtype).itemsize))
records=[]
for p in sorted((assets/'runtime').glob('*.glb')):
 d=read(p);prims=[x for m in d['meshes'] for x in m['primitives']];uv=[]
 for x in prims:
  a=accessor(p,d,x['attributes']['TEXCOORD_0']);extent=np.ptp(a,axis=0)
  assert float(extent.max())>0,(p,'collapsed UVs',x['material'])
  uv.append({'material':d['materials'][x['material']]['name'],'uv_extent':extent.tolist()})
 names={m['name'] for m in d.get('materials',[])};images={e['sha256']:e for n in names for e in maps.get(n,[])}
 records.append({'file':p.name,'sha256':sha(p),'bytes':p.stat().st_size,'triangles':sum(d['accessors'][x['indices']]['count']//3 for x in prims),'surfaces':len(prims),'materials':sorted(names),'textures':sorted(images),'uv_extent':uv})
def total(names):
 selected=[r for r in records if r['file'] in names];digests={h for r in selected for h in r['textures']};images={e['sha256']:e for entries in maps.values() for e in entries if e['sha256'] in digests}
 return {'triangles':sum(r['triangles'] for r in selected),'surfaces':sum(r['surfaces'] for r in selected),'glb_bytes_including_embedded_maps':sum(r['bytes'] for r in selected),'distinct_textures':len(images),'texture_payload_bytes':sum(e['bytes'] for e in images.values()),'rgba8_full_mips_upper_bytes':sum(int(e['size'][0]*e['size'][1]*4*4/3) for e in images.values()),'texture_records':list(images.values())}
report={'exports':records,'combined':{},'limitations':['RGBA8 mip estimate is uncompressed, not measured VRAM. Runtime texture counters include the complete generated scene and both embedded GLB and shared external resources.','Transparent surfaces: none added. Backface culling follows donor materials; no new foliage. Shadow-on/off scene benchmarks report total render draws; their difference includes the generated world, not just F4.']}
for level in ['near','middle','far']:
 loads=['load_clay.glb','load_fuel.glb','load_bricks.glb']
 report['combined']['feeder_'+level]=total(['feeder_'+level+'.glb']+loads)
 report['combined']['feeder_pocket_'+level]=total(['feeder_'+level+'.glb','pocket_'+level+'.glb']+loads)
report['donor_contracts']={'f2_winding_depth_m':.012*.49,'f2_spur_depth_m':.003*.49,'e2_retained_jamb_cut_depth_m':.038,'f3_mount':'Source nominal incision .026 m; actual nonuniform mount scale and resulting displacement lengths measured in packed reopen. Middle and far share the published conservative 8500-triangle membrane.'}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2)+'\n');print('F4_COSTS_OK',len(records))
