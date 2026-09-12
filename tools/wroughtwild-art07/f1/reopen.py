"""Reopen a delivered packed master and independently audit every delivered GLB."""
import bpy,bmesh,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source=Path(args[0]).resolve();out=Path(args[1]).resolve();out.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.open_mainfile(filepath=str(source/'f1_master.blend'))
images=[{'name':i.name,'size':list(i.size),'packed':bool(i.packed_file),'colorspace':i.colorspace_settings.name} for i in bpy.data.images if i.source=='FILE']
assert images and all(i['packed'] for i in images)
scene=bpy.context.scene;scene.render.threads_mode='FIXED';scene.render.threads=8;scene.render.filepath=str(out/'reopened-packed-master.png');bpy.ops.render.render(write_still=True)
for o in list(bpy.data.objects):
 if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
report={'packed_images':images,'exports':[]}
for p in sorted(source.glob('*.glb')):
 bpy.ops.import_scene.gltf(filepath=str(p));objects=list(bpy.context.selected_objects);triangles=0;degen=0;points=[];surfaces=0;topology=[]
 for o in objects:
  if o.type!='MESH':continue
  o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);surfaces+=len(o.data.materials);degen+=sum(t.area<1e-12 for t in o.data.loop_triangles);points.extend(o.matrix_world@v.co for v in o.data.vertices)
  assert not o.data.validate(),(p,o.name,'imported mesh needed repair')
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
  boundary=sum(e.is_boundary for e in bm.edges);nonmanifold=sum(not e.is_manifold for e in bm.edges)
  topology.append({'name':o.name,'boundary':boundary,'nonmanifold':nonmanifold});bm.free()
  if p.stem in [k+'_'+level for k in ['lanternheart','stormglass'] for level in ['near','middle','far']]:assert boundary==0 and nonmanifold==0,(p,topology)
 assert points and degen==0,p
 assert all(math.isfinite(c) for v in points for c in v)
 bounds=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
 report['exports'].append({'file':p.name,'triangles':triangles,'surfaces':surfaces,'degenerate':degen,'topology':topology,'bounds_blender_m':bounds,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 for o in objects:
  if o.name in bpy.data.objects:bpy.data.objects.remove(o,do_unlink=True)
(out/'reopen-audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('F1_PACKED_REOPEN_OK',len(images),len(report['exports']))
