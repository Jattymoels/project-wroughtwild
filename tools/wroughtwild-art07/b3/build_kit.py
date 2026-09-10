"""ART-07B3: finish approved ART-02 rock geometry; no original source is modified."""
import bpy,bmesh,json,sys,math,random
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
args=sys.argv[sys.argv.index('--')+1:];depot,out=[Path(p).resolve() for p in args[:2]]
assert not out.exists();out.mkdir(parents=True)
cfg=json.loads(Path(__file__).with_name('kit.json').read_text());rng=random.Random(cfg['seed'])
grove=depot/'build/grove-art02/emberroot-handoff'
bpy.ops.wm.open_mainfile(filepath=str(grove/'editable/rock-finished.blend'))
original=bpy.data.objects['Quiet river oak'];raw=bpy.data.objects['SOURCE - intact normalized oak']
for o in list(bpy.context.scene.objects):
 if o not in [original,raw]:bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene
collections={}
for name in ['SOURCE','FINISHED','RUNTIME','REVIEW']:
 c=bpy.data.collections.new(name);scene.collection.children.link(c);collections[name]=c
def move(o,c):
 for old in list(o.users_collection):old.objects.unlink(o)
 collections[c].objects.link(o)
move(raw,'SOURCE');move(original,'SOURCE');raw.hide_render=True;raw.hide_set(True);original.hide_render=True;original.hide_set(True)
raw.name='SOURCE untouched normalized ART02 rock';original.name='SOURCE approved reduced quiet rock'
base=original.data.materials[0].copy();base.name='Ordinary weathered stone - original UV albedo ORM'
# Reduced embedded texture copies: original packed pixels remain on SOURCE material.
for n in base.node_tree.nodes:
 if n.type=='TEX_IMAGE' and n.image:
  n.image=n.image.copy();n.image.scale(1024,1024);n.image.pack()
capmat=base.copy();capmat.name='Fresh cut face - independent planar UV'
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
def clone(src,name,collection='FINISHED'):
 o=src.copy();o.data=src.data.copy();o.name=name;collections[collection].objects.link(o);o.hide_set(False);o.hide_render=False;return o
def fit(o,size):
 p=np.array([v.co for v in o.data.vertices]);lo=p.min(0);hi=p.max(0);q=(p-lo)/(hi-lo)*np.array(size);q[:,:2]-=np.array(size[:2])/2
 for v,co in zip(o.data.vertices,q):v.co=co
 o.data.update()
def clean(o):
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00008)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=0.000001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
def decimate(o,target):
 o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
 before=np.array([v.co for v in o.data.vertices]);before_lo=before.min(0);before_hi=before.max(0)
 if count>target*1.3 and target<5000:
  reference=clone(o,'temporary LOD reference','SOURCE');reference.hide_render=True
  active(o);solid=o.modifiers.new('Preserve shell through distance resampling','SOLIDIFY');solid.thickness=min(o.dimensions)*.12;solid.offset=-1;bpy.ops.object.modifier_apply(modifier=solid.name)
  rem=o.modifiers.new('Distance silhouette resampling','REMESH');rem.mode='VOXEL';rem.voxel_size=min(max(o.dimensions)/(26 if target>=2000 else 16),min(o.dimensions)/6);rem.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=rem.name)
  if not o.data.vertices:o.data=reference.data.copy()
  if not o.data.uv_layers:o.data.uv_layers.new(name=reference.data.uv_layers[0].name)
  dt=o.modifiers.new('Same-surface UV interpolation','DATA_TRANSFER');dt.object=reference;dt.use_loop_data=True;dt.data_types_loops={'UV'};dt.loop_mapping='POLYINTERP_NEAREST';bpy.ops.object.modifier_apply(modifier=dt.name)
  if 'Scar' in reference.data.color_attributes:
   bv=BVHTree.FromPolygons([v.co for v in reference.data.vertices],[tuple(f.vertices) for f in reference.data.polygons]);col=o.data.color_attributes.get('Scar') or o.data.color_attributes.new(name='Scar',type='FLOAT_COLOR',domain='POINT');src_col=reference.data.color_attributes['Scar']
   for v,c in zip(o.data.vertices,col.data):
    hit,no,index,d=bv.find_nearest(v.co);f=reference.data.polygons[index];near=min(f.vertices,key=lambda i:(reference.data.vertices[i].co-hit).length_squared);c.color=src_col.data[near].color
  bpy.data.objects.remove(reference,do_unlink=True);o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
 if count>target:
  active(o);m=o.modifiers.new('Preserve broad bedding','DECIMATE');m.ratio=target/count;m.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=m.name)
 clean(o)
 after=np.array([v.co for v in o.data.vertices]);after_lo=after.min(0);after_hi=after.max(0)
 # LOD resampling cannot enlarge the supplied body or change its contact anchor.
 adjusted=(after-after_lo)/(after_hi-after_lo)*(before_hi-before_lo)+before_lo
 for v,co in zip(o.data.vertices,adjusted):v.co=co
 o.data.update()
def cut(o,axis,coordinate,positive):
 bm=bmesh.new();bm.from_mesh(o.data);normal=Vector((0,0,0));normal[axis]=1;point=normal*coordinate
 result=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=point,plane_no=normal,clear_outer=positive,clear_inner=not positive,dist=.000001)
 edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co[axis]-coordinate)<.0001 for v in e.verts)]
 faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[]) if edges else []
 uv=bm.loops.layers.uv.verify();other=[i for i in range(3) if i!=axis]
 for f in faces:
  f.material_index=1
  for l in f.loops:l[uv].uv=(l.vert.co[other[0]]*.8+.5,l.vert.co[other[1]]*.8+.5)
 bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();clean(o)
# Repair a copy of the generated fragmented shell into a reusable closed host.
# UVs sample the nearest interpolated source polygon (not nearest-vertex transfer).
# Newly authored planar cut faces below use their own independent charts.
repaired=clone(original,'FINISHED repaired closed host');active(repaired)
solid=repaired.modifiers.new('Preserve source shell thickness before volume repair','SOLIDIFY');solid.thickness=.12;solid.offset=-1;solid.use_even_offset=False;bpy.ops.object.modifier_apply(modifier=solid.name)
remesh=repaired.modifiers.new('Close generated shell, retain bedding','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.025;remesh.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=remesh.name)
bm=bmesh.new();bm.from_mesh(repaired.data);unseen=set(bm.verts);components=[]
while unseen:
 stack=[unseen.pop()];group=[]
 while stack:
  v=stack.pop();group.append(v)
  for e in v.link_edges:
   n=e.other_vert(v)
   if n in unseen:unseen.remove(n);stack.append(n)
 components.append(group)
largest=max(components,key=len);keep=set(largest);bmesh.ops.delete(bm,geom=[v for v in bm.verts if v not in keep],context='VERTS');bm.to_mesh(repaired.data);bm.free()
repaired.data.uv_layers.new(name=original.data.uv_layers[0].name)
transfer=repaired.modifiers.new('Interpolate same-source surface UV','DATA_TRANSFER');transfer.object=original;transfer.use_loop_data=True;transfer.data_types_loops={'UV'};transfer.loop_mapping='POLYINTERP_NEAREST';bpy.ops.object.modifier_apply(modifier=transfer.name)
repaired.hide_set(True);repaired.hide_render=True
def rock(name,size,target=12000):
 o=clone(original,name);o.data.materials.clear();o.data.materials.append(base);o.data.materials.append(capmat);fit(o,size);clean(o)
 bm=bmesh.new();bm.from_mesh(o.data)
 edges=[e for e in bm.edges if e.is_boundary]
 faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[]) if edges else []
 uv=bm.loops.layers.uv.verify()
 for f in faces:
  f.material_index=1
  for l in f.loops:l[uv].uv=(l.vert.co.x*.8+.5,l.vert.co.y*.8+.5)
 bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 cut(o,2,size[2]*.04,False)
 for v in o.data.vertices:v.co.z-=size[2]*.04
 decimate(o,target);return o
assets={};full=rock('boulder-full',cfg['boulder_size_xyz_blender']);assets['boulder-full']=[full]
def solid_cut_face(o,axis,coordinate):
 # One independent planar face seals the recovered solid, including generated internal cavities.
 other=[i for i in range(3) if i!=axis];points=sorted(set((round(v.co[other[0]],6),round(v.co[other[1]],6)) for v in o.data.vertices if abs(v.co[axis]-coordinate)<.0001))
 if len(points)<3:return
 def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
 lower=[];upper=[]
 for p in points:
  while len(lower)>=2 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
  lower.append(p)
 for p in reversed(points):
  while len(upper)>=2 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
  upper.append(p)
 hull=lower[:-1]+upper[:-1];bm=bmesh.new();bm.from_mesh(o.data)
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if all(abs(v.co[axis]-coordinate)<.0001 for v in f.verts)],context='FACES')
 verts=[]
 for x,y in hull:
  p=[0.,0.,0.];p[axis]=coordinate;p[other[0]]=x;p[other[1]]=y;verts.append(bm.verts.new(p))
 face=bm.faces.new(verts);face.material_index=1;uv=bm.loops.layers.uv.verify()
 for l in face.loops:l[uv].uv=(l.vert.co[other[0]]*.5+.5,l.vert.co[other[1]]*.5+.5)
 bmesh.ops.triangulate(bm,faces=[face]);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
for state,x in [('boulder-worked',.23),('boulder-remnant',-.20)]:
 o=clone(full,state);cut(o,0,x,True);solid_cut_face(o,0,x);assets[state]=[o]
chunk=clone(full,'released-chunk');cut(chunk,0,.23,False);assets['released-chunk']=[chunk]
seam=rock('stone-seam',cfg['seam_size_xyz_blender']);
# Open the working line down to its recessed bedding. The original native ribbon remains visible through it.
left=clone(seam,'seam left bedding');right=clone(seam,'seam right bedding');cut(left,1,-.065,True);cut(right,1,.065,False)
bpy.data.objects.remove(seam,do_unlink=True);assets['stone-seam']=[left,right]
shelf=rock('rock-shelf',(3.4,2.1,.85));assets['rock-shelf']=[shelf]
altered=clone(shelf,'rock-shelf-altered');assets['rock-shelf-altered']=[altered]
# Ray-projected fracture follows actual top surface, not a floating tube.
p=np.array([v.co for v in altered.data.vertices]);bvh=BVHTree.FromPolygons([Vector(v) for v in p],[tuple(f.vertices) for f in altered.data.polygons])
path=[]
for x in np.linspace(-1.28,1.25,125):
 y=.18*math.sin(x*4)+.05
 hit,normal,idx,d=bvh.ray_cast(Vector((x,y,3)),Vector((0,0,-1)))
 if hit is not None:path.append(np.array(hit))
distance=np.full(len(p),100.)
for point in path:distance=np.minimum(distance,np.linalg.norm(p-point,axis=1))
weight=np.maximum(0,1-distance/cfg['scar_half_width_m']);weight=weight*weight*(3-2*weight)
normals=np.array([v.normal for v in altered.data.vertices]);q=p-normals*weight[:,None]*cfg['scar_depth_m']
for v,co in zip(altered.data.vertices,q):v.co=co
colour=altered.data.color_attributes.new(name='Scar',type='FLOAT_COLOR',domain='POINT')
for i,c in enumerate(colour.data):c.color=(float(weight[i]),float(weight[i]>.01),float((p[i,0]+1.7)/3.4),1)
scar=base.copy();scar.name='Altered shelf - physical incision + inset energy';nt=scar.node_tree;bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED');attr=nt.nodes.new('ShaderNodeVertexColor');attr.layer_name='Scar';sep=nt.nodes.new('ShaderNodeSeparateColor');nt.links.new(attr.outputs['Color'],sep.inputs[0]);mult=nt.nodes.new('ShaderNodeMath');mult.operation='MULTIPLY';mult.inputs[1].default_value=2.2;nt.links.new(sep.outputs['Red'],mult.inputs[0]);nt.links.new(mult.outputs[0],bs.inputs['Emission Strength']);bs.inputs['Emission Color'].default_value=(1,.21,.018,1);altered.data.materials[0]=scar
scar_measure={'max_depth_m':float(np.max(np.linalg.norm(p-q,axis=1))),'vertices_displaced':int(np.count_nonzero(weight)),'half_width_m':cfg['scar_half_width_m'],'reference':'rock-shelf vs rock-shelf-altered, identical vertices before LOD'}
assert scar_measure['max_depth_m']>.055
# Reuse authored ART02 roots, normalized inside a damp bank envelope.
before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=str(grove/'review/root-bank.glb'));roots=[o for o in bpy.context.scene.objects if o not in before and o.type=='MESH']
for o in roots:move(o,'FINISHED');active(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
if len(roots)>1:
 active(roots[0])
 for o in roots:o.select_set(True)
 bpy.ops.object.join()
root=roots[0];root.name='river-bank roots';fit(root,(3.4,1.4,.64));decimate(root,9000)
for m in root.data.materials:
 for n in m.node_tree.nodes:
  if n.type=='TEX_IMAGE' and n.image:n.image=n.image.copy();n.image.scale(1024,1024);n.image.pack()
bank=rock('river-bank stone',(3.5,1.5,.46),6000);root.location.z=.12;assets['river-bank']=[bank,root]
# Talus uses eight differing retained source fragments, grounded individually.
talus=[]
for i in range(8):
 o=rock('talus %02d'%i,(rng.uniform(.20,.48),rng.uniform(.18,.42),rng.uniform(.09,.23)),500)
 o.location=(rng.uniform(-1.0,1.0),rng.uniform(-.52,.52),0);o.rotation_euler.z=rng.uniform(-3,3);talus.append(o)
assets['talus-pebbles']=talus
# Three separate lips frame, never fill, the protected 2.4 m wide / 2.5 m tall aperture.
cave=[]
for sign in [-1,1]:
 for tier in range(3):
  o=rock('cave jamb %d tier %d'%(sign,tier),(.85,1.3,1.0),2600);o.location=(sign*1.72,0,tier*.77);cave.append(o)
lip=rock('cave overhead lip',(4.1,1.3,.65),9000);lip.location.z=2.45;cave.append(lip);assets['cave-threshold']=cave
def export(objects,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.hide_set(False);o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_materials='EXPORT',export_attributes=True,export_vertex_color='NAME',export_vertex_color_name='Scar')
report={'assets':{},'scar':scar_measure,'blender_to_godot':'(x,y,z) -> (x,z,-y)','source_reuse':'ART02 approved quiet rock and attached root bank; no new TRELLIS job'}
for name,objects in assets.items():
 report['assets'][name]=[]
 for level,target in enumerate(cfg['lod_triangle_targets']):
  copies=[]
  for src in objects:
   o=clone(src,name+' LOD'+str(level),'RUNTIME');decimate(o,max(120,int(target/len(objects))));copies.append(o)
  export(copies,out/(name+'-lod%d.glb'%level));count=0;points=[]
  for o in copies:o.data.calc_loop_triangles();count+=len(o.data.loop_triangles);points.extend([o.matrix_world@v.co for v in o.data.vertices])
  report['assets'][name].append({'lod':level,'triangles':count,'surfaces':sum(len(o.data.materials) for o in copies),'bounds_blender':[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]})
  for o in copies:o.hide_render=True;o.hide_set(True)
 for o in objects:o.hide_render=True;o.hide_set(True)
(out/'kit-report.json').write_text(json.dumps(report,indent=2))
# Review is rearrangeable inside the master; source/runtime remain hidden.
layout={'boulder-full':(-4,2,0),'boulder-worked':(-2,2,0),'boulder-remnant':(0,2,0),'stone-seam':(-3,-.6,0),'river-bank':(2,-1,0),'talus-pebbles':(-3,-3,0),'rock-shelf':(2,2,0),'rock-shelf-altered':(2,4.8,0),'cave-threshold':(-3,5.5,0)}
review=[]
for name,offset in layout.items():
 for src in assets[name]:
  o=clone(src,'REVIEW '+src.name,'REVIEW');o.location+=Vector(offset);review.append(o)
scene.render.engine='CYCLES';scene.cycles.samples=20;scene.cycles.use_denoising=True
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral daylight');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.26,.3,.36,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));collections['REVIEW'].objects.link(sun);sun.rotation_euler=(.5,-.6,-.5);sun.data.energy=2
cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));collections['REVIEW'].objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=14
cam.location=(12,16,14);cam.rotation_euler=(Vector((0,1.7,.6))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.04));floor=bpy.context.object;move(floor,'REVIEW');floor.name='Review ground, no exported geometry';floor_mat=bpy.data.materials.new('Neutral earth');floor_mat.diffuse_color=(.17,.15,.115,1);floor.data.materials.append(floor_mat)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'b3-master.blend'),compress=True)
if '--no-render' in args:print('B3_KIT_SOURCE_OK');sys.exit(0)
scene.render.filepath=str(out/'blender-kit.png');bpy.ops.render.render(write_still=True)
for o in review:o.hide_render=True
floor.hide_render=True
for name in ['boulder-full','stone-seam','river-bank','rock-shelf-altered','cave-threshold']:
 objects=assets[name]
 for o in objects:o.hide_render=False
 size=4.8 if name=='cave-threshold' else 4.1;target=Vector((0,0,1.3 if name=='cave-threshold' else .5));cam.data.ortho_scale=size
 for angle,at in [('material',(4,5,3)),('back',(-4,-5,2)),('underside',(2,2,-5)),('clay',(4,5,3))]:
  cam.location=Vector(at);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
  if angle=='clay':
   clay=bpy.data.materials.new('Inspection clay');clay.diffuse_color=(.36,.38,.4,1);bpy.context.view_layer.material_override=clay
  scene.render.filepath=str(out/(name+'-'+angle+'.png'));bpy.ops.render.render(write_still=True);bpy.context.view_layer.material_override=None
 for o in objects:o.hide_render=True
print('B3_KIT_OK',len(report['assets']))
