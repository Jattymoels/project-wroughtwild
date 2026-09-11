"""Independent packed reopen and fresh export topology/body inspection."""
import bpy,bmesh,sys,json,math,hashlib
from pathlib import Path
folder,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
bpy.ops.wm.open_mainfile(filepath=str(folder/'c2-master.blend'))
images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
assert images and all(im.packed_file and min(im.size)>0 for im in images)
source=bpy.data.objects['SOURCE approved ART02 fractured bedding'];assert len(source.data.vertices)>1000
result={'packed_images':[{'name':im.name,'size':list(im.size),'colourspace':im.colorspace_settings.name} for im in images],'exports':[]}
for p in sorted((folder/'models').glob('*.glb')):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(p));objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[];triangles=degenerates=boundary=0
 for o in objects:
  o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);degenerates+=sum(t.area<1e-12 for t in o.data.loop_triangles);points.extend(o.matrix_world@v.co for v in o.data.vertices)
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);boundary+=sum(e.is_boundary for e in bm.edges);bm.free()
 assert points and degenerates==0,(p.name,degenerates)
 assert all(math.isfinite(v) for point in points for v in point)
 bounds=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
 if p.name.startswith(('slate','shellstone')):
  assert bounds[0][0]>=-1.001 and bounds[1][0]<=1.001 and bounds[0][1]>=-.576 and bounds[1][1]<=.576 and bounds[0][2]>=-.025 and bounds[1][2]<=.581,(p.name,bounds)
 if p.name.startswith('upland'):
  assert bounds[0][2]>=-.0001 and bounds[1][2]<.4,(p.name,bounds)
 result['exports'].append({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'triangles':triangles,'surfaces':sum(len(o.data.materials) for o in objects),'degenerates':degenerates,'open_edges_after_weld':boundary,'bounds_blender_m':bounds,'bytes':p.stat().st_size})
counts={r['file']:r['triangles'] for r in result['exports']}
for name in ['slate-v0-full','slate-v1-full','shellstone-v0-full','shellstone-v1-full']:
 assert counts[name+'-lod0.glb']>counts[name+'-lod1.glb']>counts[name+'-lod2.glb'],name
fossils=json.loads((folder/'fossils.json').read_text())
if isinstance(fossils,list):
 sections=[s for f in fossils if f['variant'] in [0,1] for s in f['sections']]
 assert len(sections)>=10 and len({s['radius_m'] for s in sections})==len(sections);assert len({s['kind'] for s in sections})==3
 result['fossil_sections']=len(sections);result['fossil_types']=sorted({s['kind'] for s in sections})
else:
 assert (folder/'shellstone-finish.json').exists()
 result['fossil_source_review']=fossils
out.write_text(json.dumps(result,indent=2)+'\n');print('C2_FRESH_BLENDER_AUDIT_OK',len(result['exports']))
