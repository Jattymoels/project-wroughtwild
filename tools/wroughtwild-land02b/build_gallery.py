"""Finish the actual generated bole; author attached living crowns in metres.
Raw input and GLB remain immutable. No runtime stock belongs to these exports.
"""
import bpy,bmesh,math,random,json,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2];OUT=R/'game/land02b/assets';SRC=R/'build/land02b/source-art'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SRC/'root-candidate.blend'))
for o in list(bpy.data.objects):
 if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
raw=next(o for o in bpy.context.scene.objects if o.type=='MESH')
# The actual inspection found a detached upper branch. Remove that connected
# component rather than hiding it inside foliage or treating the raw source as done.
bm=bmesh.new();bm.from_mesh(raw.data)
# glTF duplicates positions along UV charts. Weld coincident geometry before
# finding components, while retaining the per-loop UVs, so charts are not limbs.
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00005)
bm.verts.ensure_lookup_table()
unseen=set(bm.verts);components=[]
while unseen:
 todo=[unseen.pop()];group=[]
 while todo:
  v=todo.pop();group.append(v)
  for e in v.link_edges:
   other=e.other_vert(v)
   if other in unseen:unseen.remove(other);todo.append(other)
 components.append(group)
components.sort(key=len,reverse=True)
removed=sum(len(c) for c in components[1:])
bmesh.ops.delete(bm,geom=[v for c in components[1:] for v in c],context='VERTS');bm.to_mesh(raw.data);bm.free()
for v in raw.data.vertices:v.co=Vector((v.co.x*.55,v.co.y*.55,v.co.z-.14))
raw.name='Generated bole - detached branch removed - retained source';raw.hide_render=True;raw.hide_viewport=True
leafmat=bpy.data.materials.new('Gallery living leaves');leafmat.use_nodes=True;leafmat.use_backface_culling=False
bs=leafmat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.86
vc=leafmat.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Leaf colour';leafmat.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color'])
bark=bpy.data.materials.new('Young branch bark');bark.use_nodes=True
bs=bark.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.89
bt=bark.node_tree.nodes.new('ShaderNodeTexImage');bt.image=bpy.data.images.load(str(R/'game/land02b/textures/gallery-bark.png'));bt.extension='REPEAT'
bark.node_tree.links.new(bt.outputs['Color'],bs.inputs['Base Color'])
class Geometry:
 def __init__(self):self.v=[];self.f=[];self.c=[];self.uv=[]
 def vert(self,p,c=(1,1,1,1),uv=(0,0)):self.v.append(tuple(p));self.c.append(c);self.uv.append(uv);return len(self.v)-1
 def face(self,*v):self.f.append(v)
 def object(self,name,mat):
  mesh=bpy.data.meshes.new(name);mesh.from_pydata(self.v,[],self.f);mesh.update();ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);mesh.materials.append(mat)
  col=mesh.color_attributes.new(name='Leaf colour',type='FLOAT_COLOR',domain='POINT')
  for i,c in enumerate(self.c):col.data[i].color=c
  uv=mesh.uv_layers.new(name='Grain along living branch')
  for loop in mesh.loops:uv.data[loop.index].uv=self.uv[loop.vertex_index]
  for p in mesh.polygons:p.use_smooth=True
  return ob
def tube(g,path,radii,sides=8):
 start=len(g.v);ring=sides+1;distance=0
 for i,p in enumerate(path):
  if i:distance+=(p-path[i-1]).length
  tangent=(path[min(i+1,len(path)-1)]-path[max(0,i-1)]).normalized();ref=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((1,0,0));u=tangent.cross(ref).normalized();v=tangent.cross(u)
  for k in range(ring):
   a=k*math.tau/sides;rr=radii[i]*(1+.08*math.sin((k%sides)*2.3+i*.7));g.vert(p+rr*(u*math.cos(a)+v*math.sin(a)),uv=(k/sides*math.tau*radii[0],distance/2))
  if i:
   for k in range(sides):g.face(start+(i-1)*ring+k,start+(i-1)*ring+k+1,start+i*ring+k+1,start+i*ring+k)
 g.face(*[start+k for k in reversed(range(sides))]);g.face(*[start+(len(path)-1)*ring+k for k in range(sides)])
def leaf(g,base,direction,length,width,rng):
 d=direction.normalized();side=d.cross(Vector((0,0,1))).normalized()
 if side.length<.1:side=Vector((1,0,0))
 n=d.cross(side).normalized();start=len(g.v)
 tone=rng.choice([(.16,.235,.071,1),(.20,.29,.085,1),(.125,.195,.055,1),(.265,.32,.103,1)])
 for p in [base,base+d*length*.43+side*width,base+d*length*.52+n*.045,base+d*length*.85+side*width*.5,base+d*length,base+d*length*.85-side*width*.5,base+d*length*.43-side*width]:g.vert(p,tone)
 for a,b,c in [(0,1,2),(1,3,2),(3,4,2),(4,5,2),(5,6,2),(6,0,2)]:g.face(start+a,start+b,start+c)
forms={};finished=[]
for variant in range(2):
 rng=random.Random(102040+variant*73)
 bole=raw.copy();bole.data=raw.data.copy();bpy.context.collection.objects.link(bole);bole.hide_render=False;bole.hide_viewport=False
 if variant:
  for v in bole.data.vertices:v.co=Vector((v.co.x*1.14+.11*max(0,v.co.z-2),v.co.y*.90,v.co.z*.90))
 bpy.context.view_layer.objects.active=bole;bole.select_set(True)
 dec=bole.modifiers.new('Silhouette-preserving runtime reduction','DECIMATE');dec.ratio=.13;bpy.ops.object.modifier_apply(modifier=dec.name)
 if bole.data.validate(verbose=True):print('LAND02B_MESH_REPAIRED retained bole after reduction',variant)
 wood=BVHTree.FromPolygons([v.co for v in bole.data.vertices],[p.vertices for p in bole.data.polygons])
 # Capture a separately simplified contact surface from actual solid wood.
 contact=bole.copy();contact.data=bole.data.copy();bpy.context.collection.objects.link(contact);bpy.context.view_layer.objects.active=contact
 dec=contact.modifiers.new('Root and trunk contact','DECIMATE');dec.ratio=.075;bpy.ops.object.modifier_apply(modifier=dec.name)
 if contact.data.validate(verbose=True):print('LAND02B_MESH_REPAIRED contact after reduction',variant)
 contact.name='gallery-contact-'+str(variant)
 contact.data.materials.clear()
 bpy.ops.object.select_all(action='DESELECT');contact.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(contact.name+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
 contact.hide_render=True;contact.hide_viewport=True
 branches=Geometry();leaves=Geometry()
 # Purposefully asymmetric crown lobes, joined to the retained living fork.
 lobes=[(-2.6,-.8,10.3,2.8),(.9,.3,12.8,2.3),(3.3,.7,10.6,2.8),(-.7,2.7,11.5,2.7),(1.4,-2.5,11.0,2.6),(-2.5,1.6,12.1,2.3),(.1,-.9,14.1,1.8),(-3.8,-.6,7.8,2.2),(2.6,1.9,8.2,2.0)]
 if variant:lobes=[(-4.8,-.7,8.1,3.0),(.4,.2,10.6,2.8),(4.1,.8,9.2,2.7),(-1.1,2.8,9.8,2.8),(2,-2.7,9.1,2.4),(-5.7,1.6,6.3,1.8),(.8,-3.6,7.2,2.1)]
 for li,(x,y,z,radius) in enumerate(lobes):
  # Graft into the inspected retained wood, not an assumed vertical trunk.
  # Sampling its real cross-section prevents capped branches floating beside
  # the curved generated bole, exposed by the ordinary close-up game capture.
  graft_z=3.9+(li%5)*.25
  section=[v.co for v in bole.data.vertices if abs(v.co.z-graft_z)<.22]
  assert section,'Missing retained wood at requested graft height'
  centre=Vector((sum(v.x for v in section)/len(section),sum(v.y for v in section)/len(section),graft_z))
  outward=Vector((x-centre.x,y-centre.y,0)).normalized()
  hit,normal,_,_=wood.ray_cast(centre+outward*10,-outward,20)
  if hit is None:hit,normal,_,_=wood.find_nearest(centre)
  assert hit is not None,'Unable to attach authored crown to retained bole'
  back,_,_,_=wood.ray_cast(hit-outward*.004,-outward,5)
  assert back is not None,'Retained bole must enclose the buried branch cap'
  base=hit.lerp(back,.5);tip=Vector((x,y,z-1.0));mid=base.lerp(tip,.54)+Vector((x*.1,0,.8))
  root_radius=min(.07,(hit-back).length*.15)
  print('LAND02B_GRAFT',variant,li,list(base),list(hit))
  tube(branches,[base,hit+outward*.08+Vector((0,0,.12)),base.lerp(mid,.5),mid,mid.lerp(tip,.6),tip],[root_radius,.24,.29,.19,.12,.065],10)
  # Secondary branches spread within each crown, leaving visible windows
  # between lobes. Leaves attach to shoots rather than occupying a uniform ball.
  for j in range(20):
   angle=j*2.399+rng.uniform(-.35,.35);spread=radius*rng.uniform(.48,1.08)
   start=mid.lerp(tip,rng.uniform(.25,1));end=Vector((x+math.cos(angle)*spread,y+math.sin(angle)*spread,z+rng.uniform(-1.85,1.55)))
   tube(branches,[start,start.lerp(end,.5)+Vector((0,0,.25)),end],[.055,.028,.009],6)
   for k in range(8):
    at=start.lerp(end,.36+k*.083);cross=Vector((math.cos(angle+math.pi*.5),math.sin(angle+math.pi*.5),.18))
    for sign in [-1,1]:
     shoot=at+cross*sign*rng.uniform(.40,.85)+Vector((0,0,rng.uniform(-.2,.2)))
     tube(branches,[at,shoot],[.013,.003],4)
     for n in range(4):
      b=at.lerp(shoot,.22+n*.22);direc=(end-start).normalized()*.55+cross*sign*.8+Vector((rng.uniform(-.25,.25),rng.uniform(-.25,.25),rng.uniform(-.3,.5)))
      leaf(leaves,b,direc,rng.uniform(.24,.41),rng.uniform(.07,.115),rng)
  # Fewer drooping outer shoots break the broad outline without fine twig noise.
 obbranch=branches.object('Attached live branches',bark);obleaf=leaves.object('Authored layered canopy',leafmat)
 bpy.ops.object.select_all(action='DESELECT')
 for ob in [bole,obbranch,obleaf]:ob.select_set(True)
 bpy.context.view_layer.objects.active=bole;bpy.ops.object.join();bole.name='gallery-'+('column' if variant==0 else 'arch')
 if bole.data.validate(verbose=True):print('LAND02B_MESH_REPAIRED joined runtime assembly',variant)
 bole.data.calc_loop_triangles();forms[bole.name]={'triangles':len(bole.data.loop_triangles),'surfaces':len(bole.data.materials),'purpose':'Existing finite tree; cleaned generated bole with authored attached living crown'}
 bpy.ops.export_scene.gltf(filepath=str(OUT/(bole.name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
 bole['source']='TRELLIS bole + removal of detached branch + runtime reduction + authored hierarchy/canopy';bole['variant']=variant;finished.append(bole);bole.hide_render=True;bole.hide_viewport=True
# Retain the editable scene with the first finished assembly visible.
finished[0].hide_render=False;finished[0].hide_viewport=False
for image in bpy.data.images:
 if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'gallery-production.blend'),compress=True)
report={'method':'Local TRELLIS 0.6.0 textured source; actual detached component removed; Blender authored crown and reduced contact','raw_glb':str(R/'build/land02b/trellis-root-v1/source.glb'),'raw_sha256':hashlib.sha256((R/'build/land02b/trellis-root-v1/source.glb').read_bytes()).hexdigest(),'removed_detached_vertices':removed,'master':str(SRC/'gallery-production.blend'),'forms':forms}
(OUT.parent/'source.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print('LAND02B_ART',json.dumps(report))
