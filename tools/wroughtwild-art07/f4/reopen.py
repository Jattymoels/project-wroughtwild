"""Fresh packed-source reopen, actual six-view/clay render and independent GLB audit."""
import bpy,bmesh,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];audit_only='--audit-only' in args
src,out=map(lambda p:Path(p).resolve(),[p for p in args if p!='--audit-only']);out.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.open_mainfile(filepath=str(src/'source/f4-master.blend'))
images=[{'name':i.name,'size':list(i.size),'packed':bool(i.packed_file),'colorspace':i.colorspace_settings.name} for i in bpy.data.images if i.source=='FILE'];assert images and all(i['packed'] for i in images)
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=24;s.render.threads_mode='FIXED';s.render.threads=8;s.render.resolution_x=1200;s.render.resolution_y=1000;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Review world');s.world.color=(.22,.22,.22);s.view_settings.view_transform='AgX'
for at,power in [((3,-4,5),850),((-3,-1,3),650),((0,4,4),900)]:
 bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=4;o.rotation_euler=(Vector((0,0,.6))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();s.camera=bpy.context.object;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=2.5
clay=bpy.data.materials.new('Emission-off geometric clay');clay.diffuse_color=(.30,.29,.26,1)
for kind in ([] if audit_only else ['Feeder','Pocket']):
 for level in ['near','middle','far']:
  r=bpy.data.objects[kind+'_'+level];allowed=set(r.children_recursive)
  for o in bpy.data.objects:
   if o.type=='MESH':o.hide_render=o not in allowed
  for label,at in [('front',(0,-4,1.2)),('back',(0,4,1.2)),('side',(4,0,1.2)),('three-quarter',(3,-4,2.7)),('top',(0,-.001,5)),('underside',(2,-3,-2))]:
   if level!='near' and label!='three-quarter':continue
   for mode in ['material','clay']:
    if level!='near' and mode=='clay':continue
    bpy.context.view_layer.material_override=clay if mode=='clay' else None
    s.camera.location=at;s.camera.rotation_euler=(Vector((0,0,.66 if kind=='Feeder' else .5))-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(out/(kind.lower()+'_'+level+'-'+mode+'-'+label+'.png'));bpy.ops.render.render(write_still=True)
mounts=[]
for o in bpy.data.objects:
 if o.type=='MESH' and o.get('source_lod'):
  scales=[o.matrix_world.to_3x3().col[i].length for i in range(3)]
  mounts.append({'object':o.name,'source_lod':o['source_lod'],'axis_scales':scales,'nominal_inherited_026m_displacement_range':[.026*min(scales),.026*max(scales)],'note':'Transform bound on the published geometric incision, not a new same-ray BVH measurement.'})
report={'packed_images':images,'membrane_mounts':mounts,'exports':[],'source_collection_names':[c.name for c in bpy.data.collections]}
for p in sorted((src/'runtime').glob('*.glb')):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(p));tri=0;surfaces=0;deg=0;points=[];topology=[]
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles);surfaces+=len(o.data.materials);deg+=sum(t.area<1e-12 for t in o.data.loop_triangles);points += [o.matrix_world@v.co for v in o.data.vertices]
  assert not o.data.validate(),(p,o.name)
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);nonmanifold=sum(not e.is_manifold for e in bm.edges);topology.append({'object':o.name,'nonmanifold_edges':nonmanifold});bm.free()
 assert points and deg==0 and all(math.isfinite(c) for v in points for c in v),p
 lo=[min(v[i] for v in points) for i in range(3)];hi=[max(v[i] for v in points) for i in range(3)]
 report['exports'].append({'file':p.name,'triangles':tri,'surfaces':surfaces,'degenerate':deg,'min':[lo[0],lo[2],-hi[1]],'max':[hi[0],hi[2],-lo[1]],'topology':topology,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(out/'reopen.json').write_text(json.dumps(report,indent=2));print('F4_PACKED_REOPEN_OK',len(images),len(report['exports']))
