"""Replace rejected procedural shellstone in a fresh kit with inspected local generation.
Slate/tussock and dependency GLBs are copied unchanged. All cuts are actual capped planes.
"""
import bpy,bmesh,sys,json,shutil,math,hashlib
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];kit,source,out=[Path(p).resolve() for p in args];assert not out.exists();shutil.copytree(kit,out)
cfg=json.loads(Path(__file__).with_name('kit.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(kit/'c2-master.blend'));scene=bpy.context.scene;source_col=bpy.data.collections['SOURCE'];finished=bpy.data.collections['FINISHED'];runtime=bpy.data.collections['RUNTIME'];review=bpy.data.collections['REVIEW']
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
def move(o,col):
 for c in list(o.users_collection):c.objects.unlink(o)
 col.objects.link(o)
def clone(o,name,col):
 n=o.copy();n.data=o.data.copy();n.modifiers.clear();n.name=name;col.objects.link(n);n.hide_set(False);n.hide_render=False;return n
def clean(o):
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000008);bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
def reduce(o,target):
 clean(o);o.data.calc_loop_triangles();n=len(o.data.loop_triangles)
 if n>target:
  active(o);m=o.modifiers.new('Retain fossil face and cleaving bed','DECIMATE');m.ratio=target/n;m.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=m.name)
 clean(o)
def cut(o,axis,at,positive):
 bm=bmesh.new();bm.from_mesh(o.data);normal=Vector((0,0,0));normal[axis]=1
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=normal*at,plane_no=normal,clear_outer=positive,clear_inner=not positive,dist=.000001)
 edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co[axis]-at)<.00002 for v in e.verts)];faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[]);uv=bm.loops.layers.uv.verify();axes=[i for i in range(3) if i!=axis]
 for f in faces:
  f.material_index=1
  for l in f.loops:l[uv].uv=(l.vert.co[axes[0]]*.7+.5,l.vert.co[axes[1]]*.7+.5)
 bm.to_mesh(o.data);bm.free();clean(o)
# Keep rejected finished examples out of the delivered collections; original ignored kits remain intact.
for col in [finished,runtime,review]:
 for o in list(col.objects):
  if o.name.startswith('shellstone'):bpy.data.objects.remove(o,do_unlink=True)
before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(source));objects=[o for o in scene.objects if o not in before and o.type=='MESH'];assert objects
for o in objects:
 world=o.matrix_world.copy();o.parent=None;o.matrix_world.identity()
 for v in o.data.vertices:v.co=world@v.co
active(objects[0])
for o in objects:o.select_set(True)
if len(objects)>1:bpy.ops.object.join()
raw=objects[0];raw.name='SOURCE original shellstone generation';move(raw,source_col);raw.hide_render=True
full=clone(raw,'shellstone-v0-full',finished)
points=[v.co.copy() for v in full.data.vertices];lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)));scale=Vector(tuple(size/(hi[i]-lo[i]) for i,size in enumerate(cfg['shellstone_fit_blender_m'])))
for v in full.data.vertices:
 v.co=Vector(tuple((v.co[i]-lo[i])*scale[i]-offset for i,offset in enumerate((.97,.54,0))))
for m in full.data.materials:
 if m and m.use_nodes:
  for n in m.node_tree.nodes:
   if n.type=='TEX_IMAGE' and n.image:
    n.image=n.image.copy();n.image.scale(1024,1024);n.image.pack()
cap=bpy.data.materials['shellstone shared weathered mineral'];full.data.materials.append(cap)
reduce(full,cfg['shellstone_lod_triangles'][0]);cut(full,2,.012,False)
for v in full.data.vertices:v.co.z-=.012
raw.hide_set(True)
assets={full.name:full};variant=clone(full,'shellstone-v1-full',finished)
for v in variant.data.vertices:v.co.x*=-1;v.co.y*=-1
clean(variant);cut(variant,0,.82,True);assets[variant.name]=variant
for idx,base in enumerate([full,variant]):
 for state,x in [('worked',.23),('last',-.28)]:
  o=clone(base,'shellstone-v%d-%s'%(idx,state),finished);cut(o,0,x,True);assets[o.name]=o
 o=clone(base,'shellstone-v%d-recovered'%idx,finished);cut(o,0,.32,False)
 points=[v.co for v in o.data.vertices];low=Vector(tuple(min(v[i] for v in points) for i in range(3)));high=Vector(tuple(max(v[i] for v in points) for i in range(3)));centre=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
 for v in o.data.vertices:v.co=(v.co-centre)*.37
 reduce(o,2500);assets[o.name]=o
rows=[r for r in json.loads((kit/'models.json').read_text()) if not r['name'].startswith('shellstone')]
for name,o in assets.items():
 for lod,target in enumerate(cfg['shellstone_lod_triangles']):
  n=clone(o,name+'-lod%d'%lod,runtime);reduce(n,target);active(n)
  bpy.ops.export_scene.gltf(filepath=str(out/'models'/(n.name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_materials='EXPORT',export_attributes=True)
  n.data.calc_loop_triangles();pts=[n.matrix_world@v.co for v in n.data.vertices];rows.append({'name':n.name,'triangles':len(n.data.loop_triangles),'surfaces':len(n.data.materials),'bounds_blender_m':[[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]});n.hide_render=True;n.hide_set(True)
 o.hide_render=True
for state,x in [('full',-2.5),('worked',0),('last',2.5),('recovered',4)]:
 o=clone(assets['shellstone-v0-'+state],'shellstone '+state+' review',review);o.location=Vector((x,-1,0))
(out/'models.json').write_text(json.dumps(rows,indent=2)+'\n')
(out/'fossils.json').write_text(json.dumps({'method':'Source-local textured and geometric fossil surfaces, never repeated UV medallion tiles. Rejected procedural fossil strokes are removed from the selected shellstone exports.','forms':'One ribbed fan and irregular partial/calcified circular cross-sections on the generated front face. Fine coil detail is softened in the generated source.','variants':'Second candidate rotates the same source and trims one edge; it is not a second unique fossil population.'},indent=2)+'\n')
(out/'shellstone-finish.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'raw_bounds_blender':[list(lo),list(hi)],'raw_to_native_scale_xyz':list(scale),'native_fit_m':[1.94,1.08,.545],'ground_cut_m':.012,'near_mid_far_targets':[32000,7000,1800],'variant':'Second source is a half-turn and bounded edge removal, not a new generated fossil surface. Fossils are embedded in the original textured geometry; no tiling of medallions.','cap_uv':'Independent planar UV and shared pale mineral, original UV retained elsewhere.'},indent=2)+'\n')
scene.camera.location=(6,-8,7);scene.camera.rotation_euler=(Vector((.6,-.5,.2))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'c2-master.blend'));scene.render.filepath=str(out/'blender-kit.png');scene.cycles.device='CPU';bpy.ops.render.render(write_still=True);print('C2_SHELL_FINISH_OK')
