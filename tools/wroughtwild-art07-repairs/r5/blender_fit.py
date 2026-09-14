"""R5 packed-master derivative: retain lid, upper rim, hinge and native envelope.
Only lower body coordinates are remapped. No source image or original is edited.
"""
import bpy,bmesh,json,math,sys,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
ARGS=sys.argv[sys.argv.index('--')+1:]
mode,src,out=ARGS[0],Path(ARGS[1]).resolve(),Path(ARGS[2]).resolve()
cfg=json.loads(Path(__file__).with_name('fit.json').read_text(encoding='utf-8-sig'))
FAMILIES=['wood','pine','bog_oak','ash_wood','resinheart','iron','bronze','steel']
def digest(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
def metric(objects):
 bpy.context.view_layer.update();pts=[];tri=0
 for o in objects:
  bm=bmesh.new();bm.from_mesh(o.data)
  assert all(e.is_manifold for e in bm.edges),o.name
  assert bm.calc_volume(signed=True)>0,o.name;bm.free()
  o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
  for t in o.data.loop_triangles:
   a,b,c=[o.matrix_world@o.data.vertices[i].co for i in t.vertices];assert (b-a).cross(c-a).length>1e-10
  pts.extend(o.matrix_world@v.co for v in o.data.vertices)
 assert all(math.isfinite(a) for p in pts for a in p)
 return {'triangles':tri,'objects':len(objects),'bounds_blender':[[min(v[a] for v in pts) for a in range(3)],[max(v[a] for v in pts) for a in range(3)]]}
def export(objects,path):
 bpy.ops.object.select_all(action='DESELECT');copies=[]
 for o in objects:
  n=o.copy();n.data=o.data.copy();bpy.context.scene.collection.objects.link(n);n.select_set(True);copies.append(n)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();o=bpy.context.object;o.name=path.stem
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 slots=list(o.data.materials);unique=list(dict.fromkeys(slots));idx=[unique.index(slots[p.material_index]) for p in o.data.polygons];o.data.materials.clear()
 for m in unique:o.data.materials.append(m)
 for p,i in zip(o.data.polygons,idx):p.material_index=i
 mod=o.modifiers.new('Export triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_tangents=True,export_materials='EXPORT')
 bpy.data.objects.remove(o,do_unlink=True)
def stage():
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=16;sc.render.threads_mode='FIXED';sc.render.threads=8;sc.render.resolution_x=1200;sc.render.resolution_y=900;sc.render.resolution_percentage=100;sc.world.color=(.22,.22,.22);sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG'
 for name,loc,power in [('Key',(2,-3,4),500),('Fill',(-3,-2,2),350),('Rim',(0,3,3),600)]:
  d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=3;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=loc;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
 d=bpy.data.cameras.new('R5Camera');o=bpy.data.objects.new('R5Camera',d);sc.collection.objects.link(o);sc.camera=o;d.type='ORTHO';d.ortho_scale=1.85
 # Visible full support plane, never hidden/cropped to disguise intersection.
 bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,cfg['foot_bottom_m']));floor=bpy.context.object;floor.name='R5ReviewSupport'
 mat=bpy.data.materials.new('SupportStone');mat.diffuse_color=(.32,.34,.30,1);floor.data.materials.append(mat)
 return floor
def render(objects,floor,name,view=(1.7,-2.5,1.3),clay=False):
 sc=bpy.context.scene
 for o in bpy.data.objects:
  if o.type=='MESH':o.hide_render=o not in objects+[floor]
 sc.camera.data.ortho_scale=2.45 if name.endswith('-open') else 1.85
 sc.camera.location=view;sc.camera.rotation_euler=(Vector((0,0,.25 if name.endswith('-open') else .08))-sc.camera.location).to_track_quat('-Z','Y').to_euler()
 if clay:
  m=bpy.data.materials.get('R5Clay') or bpy.data.materials.new('R5Clay');m.diffuse_color=(.4,.4,.4,1);sc.view_layers[0].material_override=m
 sc.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True);sc.view_layers[0].material_override=None
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(src));images=[i for i in bpy.data.images if i.type=='IMAGE'];assert len(images)==42 and all(i.packed_file for i in images)
if mode=='fit':
 runtime=out/'runtime';runtime.mkdir();records={};before={}
 original=bpy.data.collections.new('R5_ORIGINAL_CHEST_SOURCE');bpy.context.scene.collection.children.link(original);original.hide_render=True;original.hide_viewport=True
 for f in FAMILIES:
  body=list(bpy.data.collections['FINISHED_chest_'+f].objects);before[f]=metric(body)
  for o in body:
   n=o.copy();n.data=o.data.copy();original.objects.link(n)
   if o.name.startswith('Bottom'):template=n
   for v in o.data.vertices:
    z=v.co.z;fixed=cfg['fixed_upper_body_m'];bottom=cfg['source_bottom_m'];target=cfg['candidate_bottom_m']
    if z<fixed:v.co.z=fixed+(z-fixed)*(fixed-target)/(fixed-bottom)
   o.data.update()
   assert all(v.co.x==n.data.vertices[i].co.x and v.co.y==n.data.vertices[i].co.y and (n.data.vertices[i].co.z<fixed or v.co.z==n.data.vertices[i].co.z) for i,v in enumerate(o.data.vertices))
  cabinet=metric(body)
  for x in [-cfg['foot_x_m'],cfg['foot_x_m']]:
   for y in [-cfg['foot_depth_m'],cfg['foot_depth_m']]:
    foot=template.copy();foot.data=template.data.copy();foot.name='R5Foot_'+f;bpy.data.collections['FINISHED_chest_'+f].objects.link(foot)
    coords=[v.co.copy() for v in foot.data.vertices];lo=Vector(tuple(min(v[a] for v in coords) for a in range(3)));hi=Vector(tuple(max(v[a] for v in coords) for a in range(3)))
    foot_lo=Vector((x-cfg['foot_width_m']/2,y-cfg['foot_width_m']/2,cfg['foot_bottom_m']));foot_hi=Vector((x+cfg['foot_width_m']/2,y+cfg['foot_width_m']/2,cfg['candidate_bottom_m']+cfg['foot_joint_overlap_m']))
    for v in foot.data.vertices:
     for a in range(3):v.co[a]=foot_lo[a]+(v.co[a]-lo[a])/(hi[a]-lo[a])*(foot_hi[a]-foot_lo[a])
    foot.data.update()
    uv=foot.data.uv_layers.active
    for poly in foot.data.polygons:
     normal=max(range(3),key=lambda a:abs(poly.normal[a]));axes=[a for a in range(3) if a!=normal];sign=1 if poly.normal[normal]>=0 else -1
     timber=f not in ['iron','bronze','steel'];end=timber and abs(poly.normal.z)>.9
     if timber:poly.material_index=1 if end else 0
     for li in poly.loop_indices:
      v=foot.data.vertices[foot.data.loops[li].vertex_index].co
      if timber and not end:
       cross=next(a for a in axes if a!=2);uv.data[li].uv=(v[cross]*sign/.5+.173,v.z/2+.287)
      else:uv.data[li].uv=(v[axes[0]]*sign/.5+.173,v[axes[1]]/.5+.287)
    body.append(foot)
    inspection=foot.copy();bpy.data.collections['RUNTIME_INSPECTION_COPIES'].objects.link(inspection)
  records['chest_'+f+'_body']=metric(body)
  records['chest_'+f+'_body']['seating']={'cabinet_bounds_blender':cabinet['bounds_blender'],'foot_bottom_m':cfg['foot_bottom_m'],'foot_x_m':cfg['foot_x_m'],'foot_depth_m':cfg['foot_depth_m'],'foot_width_m':cfg['foot_width_m'],'purpose':'Cabinet clears full/fine slabs. Four feet reach nominal flat ground; submerged foot portions stay honestly documented.'}
  export(body,runtime/('chest_'+f+'_body.glb'))
  # Lids are copied as exact original bytes; no re-export churn.
  lid=src.parent.parent/'runtime'/('chest_'+f+'_lid.glb')
  assert lid.exists()
  import shutil
  shutil.copy2(lid,runtime/lid.name)
  records['chest_'+f+'_lid']=metric(list(bpy.data.collections['LID_'+f].objects))
 for i in images:i.pack()
 bpy.context.scene['R5_fit']=json.dumps(cfg)
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'r5_chest.blend'))
 (out/'geometry.json').write_text(json.dumps(records,indent=2))
 (out/'lineage.json').write_text(json.dumps({'original_master':str(src),'original_sha256':digest(src),'settings':cfg,'before':before,'after':records,'packed_images':42},indent=2))
 print('R5_FIT_OK',len(records))
elif mode=='reopen':
 floor=stage();records={};original_lid={}
 for f in FAMILIES:
  body=list(bpy.data.collections['FINISHED_chest_'+f].objects);lid=list(bpy.data.collections['LID_'+f].objects);objects=body+lid
  records[f]={'closed':metric(objects),'hinge_blender':[0,.354,.09]}
  render(objects,floor,f+'-closed')
  if f=='wood':
   for name,loc in [('front',(0,-4,0)),('back',(0,4,0)),('side',(4,0,0)),('top',(0,-.001,4)),('three-quarter',(2,-3,1.8))]:render(objects,floor,'clay-'+name,loc,True)
   # Underside documented separately with support explicitly removed.
   floor.hide_render=True
  pivot=Vector((0,.354,.09));t=Matrix.Translation(pivot)@Matrix.Rotation(math.radians(-78),4,'X')@Matrix.Translation(-pivot)
  for o in lid:o.matrix_world=t
  records[f]['open']=metric(objects);render(objects,floor,f+'-open')
  for o in lid:o.matrix_world.identity()
 expected=json.loads((src.parent/'geometry.json').read_text());imports={}
 for p in sorted((src.parent/'runtime').glob('*.glb')):
  for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
  bpy.ops.import_scene.gltf(filepath=str(p));bpy.context.view_layer.update();objects=[o for o in bpy.data.objects if o.type=='MESH'];pts=[];tri=0
  for o in objects:
   o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles);pts.extend(o.matrix_world@v.co for v in o.data.vertices)
   for t in o.data.loop_triangles:
    a,b,c=[o.matrix_world@o.data.vertices[i].co for i in t.vertices];assert (b-a).cross(c-a).length>1e-10
  bounds=[[min(v[a] for v in pts) for a in range(3)],[max(v[a] for v in pts) for a in range(3)]]
  assert tri==expected[p.stem]['triangles'] and all(abs(bounds[i][a]-expected[p.stem]['bounds_blender'][i][a])<1e-5 for i in range(2) for a in range(3)),p
  imports[p.name]={'sha256':digest(p),'triangles':tri,'bounds_blender':bounds}
 (out/'reopen.json').write_text(json.dumps({'packed_images':42,'source_sha256':digest(src),'measurements':records,'imports':imports},indent=2))
 print('R5_REOPEN_OK',len(imports))
else:raise ValueError(mode)
