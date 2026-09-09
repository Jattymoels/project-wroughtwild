"""B1 masters in metres. ART-02 host lineage retained; attached authored crowns.
Derivative geometry conventions: tools/wroughtwild-grove/build_grove.py.
No normal-game files or simulation rules are written.
"""
import bpy,bmesh,json,math,random,sys,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
source,out,kind=map(str,sys.argv[sys.argv.index('--')+1:]);source=Path(source);out=Path(out)
assert not out.exists();out.mkdir(parents=True)
cfg=json.loads(Path(__file__).with_name('kit.json').read_text(encoding='utf-8-sig'));sc=cfg[kind];rng=random.Random(cfg['seed'])
bpy.ops.wm.open_mainfile(filepath=str(source));raw=bpy.data.objects[kind+' source']
for o in list(bpy.context.scene.objects):
 if o!=raw:bpy.data.objects.remove(o,do_unlink=True)
raw.name='SOURCE immutable '+kind
src_col=bpy.data.collections.new('01 SOURCE');bpy.context.scene.collection.children.link(src_col)
fin_col=bpy.data.collections.new('02 FINISHED');bpy.context.scene.collection.children.link(fin_col)
run_col=bpy.data.collections.new('03 RUNTIME');bpy.context.scene.collection.children.link(run_col)
review_col=bpy.data.collections.new('04 REVIEW');bpy.context.scene.collection.children.link(review_col)
for c in list(raw.users_collection):c.objects.unlink(raw)
src_col.objects.link(raw);raw.hide_set(True);raw.hide_render=True
report={'kind':kind,'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'assets':{},'attachments':{},'scar':{},'coordinates':'Blender (x,y,z) to Godot (x,z,-y), one unit = one metre; root base origin','native_state':'full -> existing 0.9 s fall + 0.25 s hold -> session-only stump; depleted absent after load'}
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o

def clone(o,name,col=run_col):
 n=o.copy();n.data=o.data.copy();n.name=name;col.objects.link(n);n.hide_set(False);n.hide_render=False;return n

def cleanup(o):
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00005)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
 # Tiny isolated raw fragments are excluded from runtime, recorded separately.
 unseen=set(bm.verts);groups=[]
 while unseen:
  start=unseen.pop();stack=[start];group=[start]
  while stack:
   v=stack.pop()
   for edge in v.link_edges:
    n=edge.other_vert(v)
    if n in unseen:unseen.remove(n);stack.append(n);group.append(n)
  groups.append(group)
 groups.sort(key=len,reverse=True)
 removed=[v for g in groups[1:] for v in g]
 if removed:bmesh.ops.delete(bm,geom=removed,context='VERTS')
 bm.to_mesh(o.data);bm.free();o.data.update();return {'components':len(groups),'removed_fragment_vertices':len(removed)}

def bvh(o):return BVHTree.FromPolygons([v.co for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons])

def decimate(o,target):
 active(o);o.data.calc_loop_triangles();n=len(o.data.loop_triangles)
 if n>target:
  mod=o.modifiers.new('Silhouette candidate target '+str(target),'DECIMATE');mod.ratio=target/n;bpy.ops.object.modifier_apply(modifier=mod.name)
 cleanup(o)

def stats(objects):
 pts=[];tris=surfaces=bad=0
 for o in objects:
  o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles);surfaces+=len(o.data.materials);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles)
  pts.extend([o.matrix_world@v.co for v in o.data.vertices])
 assert all(math.isfinite(c) for p in pts for c in p)
 lo=[min(p[i] for p in pts) for i in range(3)];hi=[max(p[i] for p in pts) for i in range(3)]
 return {'triangles':tris,'surfaces':surfaces,'degenerate_triangles':bad,'bounds_blender_m':[lo,hi],'dimensions_m':[hi[i]-lo[i] for i in range(3)]}

def export(objects,name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.hide_set(False);o.hide_render=False;o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_image_format='AUTO')
 report['assets'][name]=stats(objects)
 report['assets'][name]['sha256']=hashlib.sha256((out/(name+'.glb')).read_bytes()).hexdigest()
 for o in objects:o.hide_render=True;o.hide_set(True)

host=clone(raw,'FINISHED '+kind,fin_col);report['cleanup']=cleanup(host)
# Preserve embedded originals in SOURCE; runtime derivatives have explicit 1K maps.
mat=host.data.materials[0].copy();mat.name=kind+' bark';host.data.materials[0]=mat
for n in mat.node_tree.nodes:
 if n.type=='TEX_IMAGE' and n.image:
  im=n.image.copy();im.name=kind+' runtime '+im.name;im.scale(1024,1024);im.pack();n.image=im
for p in host.data.polygons:p.use_smooth=True
# Host UV2 carries physical scar core/damage, independent of original albedo/ORM UV.
for layer in list(host.data.uv_layers)[1:]:host.data.uv_layers.remove(layer)
uv2=host.data.uv_layers.new(name='Incision core damage')
for d in uv2.data:d.uv=(0,0)
base_nodes=mat.node_tree.nodes;bsdf=next(n for n in base_nodes if n.type=='BSDF_PRINCIPLED');bsdf.inputs['Roughness'].default_value=.9
leaf_mat=bpy.data.materials.new(kind+' foliage');leaf_mat.use_nodes=True
bs=leaf_mat.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.79
attr=leaf_mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Leaf colour';leaf_mat.node_tree.links.new(attr.outputs['Color'],bs.inputs['Base Color'])
twig_mat=bpy.data.materials.new(kind+' twigs');twig_mat.use_nodes=True;tb=twig_mat.node_tree.nodes['Principled BSDF'];tb.inputs['Base Color'].default_value=(.14,.105,.065,1);tb.inputs['Roughness'].default_value=.92
wood_mat=bpy.data.materials.new(kind+' cut wood');wood_mat.use_nodes=True
wn=wood_mat.node_tree.nodes;wl=wood_mat.node_tree.links;wb=wn['Principled BSDF'];wb.inputs['Roughness'].default_value=.86
# Packed cut-wood albedo, concentric growth with irregular grain; coherent planar UV.
size=512;yy,xx=np.mgrid[0:size,0:size]/size;radius=np.sqrt((xx-.5)**2+(yy-.5)**2)
ring=np.sin(radius*190+np.sin(xx*21)*.45+np.sin(yy*13)*.28)
grain=np.sin(xx*611+np.sin(yy*120))*np.sin(yy*307)*.022
base=np.array([.48,.32,.16] if kind=='broadleaf' else [.67,.50,.28])
pixels=np.ones((size,size,4),np.float32);pixels[:,:,:3]=base[None,None,:]*(.88+.10*ring[:,:,None])+grain[:,:,None]
cut_image=bpy.data.images.new(kind+' coherent cut grain',width=size,height=size,alpha=True);cut_image.pixels.foreach_set(pixels.ravel());cut_image.pack()
tex=wn.new('ShaderNodeTexImage');tex.image=cut_image;wl.new(tex.outputs['Color'],wb.inputs['Base Color'])
class Mesh:
 def __init__(self):self.v=[];self.f=[];self.uv=[];self.wind=[];self.col=[]
 def vertex(self,p,uv=(0,0),wind=0,col=(.09,.18,.035)):
  self.v.append(tuple(p));self.uv.append(uv);self.wind.append((wind,0));self.col.append((*col,1));return len(self.v)-1
 def face(self,*v):self.f.append(v)
 def object(self,name,material):
  me=bpy.data.meshes.new(name);me.from_pydata(self.v,[],self.f);me.update()
  uv=me.uv_layers.new(name='Leaf UV');w=me.uv_layers.new(name='Attachment wind')
  for loop in me.loops:uv.data[loop.index].uv=self.uv[loop.vertex_index];w.data[loop.index].uv=self.wind[loop.vertex_index]
  col=me.color_attributes.new(name='Leaf colour',type='FLOAT_COLOR',domain='POINT');col.data.foreach_set('color',np.asarray(self.col,dtype=np.float32).ravel())
  me.materials.append(material);o=bpy.data.objects.new(name,me);run_col.objects.link(o);return o

def tube(m,path,radii):
 start=len(m.v);sides=5
 for j,(p,r) in enumerate(zip(path,radii)):
  tangent=(path[min(j+1,len(path)-1)]-path[max(0,j-1)]).normalized();u=tangent.cross(Vector((0,0,1)))
  if u.length<.01:u=Vector((1,0,0))
  u.normalize();v=tangent.cross(u).normalized()
  for k in range(sides):
   a=k*math.tau/sides;m.vertex(p+r*(u*math.cos(a)+v*math.sin(a)))
 for j in range(len(path)-1):
  for k in range(sides):
   a=start+j*sides+k;b=start+j*sides+(k+1)%sides;m.face(a,b,b+sides,a+sides)
 m.face(*[start+i for i in reversed(range(sides))]);m.face(*[start+(len(path)-1)*sides+i for i in range(sides)])

def blade(m,p,d,length,width,colour,level,conifer=False):
 d=d.normalized();u=d.cross(Vector((0,0,1)))
 if u.length<.01:u=Vector((1,0,0))
 u.normalize();base=m.vertex(p,(.5,0),0,colour)
 widths=([.3,1,.65,.85,.5] if level==0 else [1,.55]) if not conifer else ([.95,.22,.85,.18,.72,.13,.48] if level==0 else [.9,.5])
 if level==2:widths=[.88]
 rows=[]
 for j,w in enumerate(widths):
  t=(j+1)/(len(widths)+1);mid=p+d*length*t+Vector((0,0,math.sin(t*math.pi)*length*.05))
  a=m.vertex(mid-u*width*w,(0,t),t*t,colour);c=m.vertex(mid+Vector((0,0,length*.025)),(.5,t),t*t,colour);b=m.vertex(mid+u*width*w,(1,t),t*t,colour);rows.append((a,c,b))
 tip=m.vertex(p+d*length,(.5,1),1,colour)
 a,c,b=rows[0];m.face(base,a,c);m.face(base,c,b)
 for (a,c,b),(aa,cc,bb) in zip(rows[:-1],rows[1:]):m.face(a,aa,cc,c);m.face(c,cc,bb,b)
 a,c,b=rows[-1];m.face(a,tip,c);m.face(c,tip,b)

# Reduce hosts first, then select only parent sockets that survive all three silhouettes.
hosts=[]
for level,target in enumerate(sc['trunk_triangles']):
 trunk=clone(host,kind+' trunk L'+str(level));decimate(trunk,target);hosts.append(trunk)
host_bvhs=[bvh(h) for h in hosts]
points=np.array([v.co[:] for v in host.data.vertices]);radius=np.linalg.norm(points[:,:2],axis=1)
if kind=='broadleaf':eligible=points[(points[:,2]>3.9)&(radius>.75)]
else:eligible=points[(points[:,2]>2.4)&(radius>np.maximum(.13,.38*(1-points[:,2]/9)))]
eligible=np.array([p for p in eligible if all(tree.find_nearest(Vector(p))[3]<.07 for tree in host_bvhs)])
assert len(eligible)>sc['sprays']
sockets=[]
for i in range(sc['sprays']):
 p=Vector(eligible[rng.randrange(len(eligible))]);sockets.append(p)
(out/'attachment-sockets.json').write_text(json.dumps([list(p) for p in sockets]))

def crown(parent,level,variant):
 r=random.Random(42+variant*1024);leaves=Mesh();twigs=Mesh();tree_bvh=bvh(parent);max_offset=0;roots=[]
 for i,old in enumerate(sockets):
  p,n,idx,dist=tree_bvh.find_nearest(old);assert p is not None
  max_offset=max(max_offset,dist);roots.append(list(p))
  a=p-n*.009
  d=Vector((old.x*.32+r.uniform(-.8,.8),old.y*.32+r.uniform(-.8,.8),r.uniform(.02,.5))).normalized()
  length=r.uniform(.48,1.03) if kind=='broadleaf' else r.uniform(.38,.78)*(1.10-old.z/20)
  end=a+d*length;mid=a+d*length*.5+Vector((0,0,.045));path=[a,mid,end]
  tube(twigs,path,[.011,.006,.0015])
  lateral=d.cross(Vector((0,0,1))).normalized()
  for j in range(7 if kind=='broadleaf' else 9):
   t=.16+j*(.11 if kind=='broadleaf' else .09)
   at=a.lerp(mid,t*2) if t<.5 else mid.lerp(end,(t-.5)*2)
   for side in [-1,1]:
    ld=(d*r.uniform(.0,.65)+lateral*side+Vector((r.uniform(-.2,.2),r.uniform(-.2,.2),r.uniform(-.35,.35)))).normalized()
    ll=r.uniform(*sc['leaf_length_m']);shade=r.uniform(.72,1.3)
    colour=(.075*shade,.17*shade,.025*shade) if kind=='broadleaf' else (.035*shade,.095*shade,.032*shade)
    blade(leaves,at,ld,ll,ll*(.38 if kind=='broadleaf' else .25),colour,level,kind=='pine')
 objs=[twigs.object(kind+' branchlets '+str(variant)+' L'+str(level),twig_mat),leaves.object(kind+' foliage '+str(variant)+' L'+str(level),leaf_mat)]
 report['attachments'][str(variant)+'-'+str(level)]={'sockets':len(sockets),'max_resnap_m':max_offset,'root_embed_m':.009,'leaf_roots_on_piecewise_twig':True,'wind_root_weight':0,'wind_tip_weight':1}
 assert max_offset<.13,('Over-reduced branch attachment',max_offset)
 return objs

variants={}
for level,trunk in enumerate(hosts):
 for variant in [0,1]:
  parts=[trunk]+crown(trunk,level,variant);name=kind+('-a' if variant==0 else '-b')+'-lod'+str(level);variants[name]=parts;export(parts,name)

# Match cut planes using actual host geometry, filled planar boundary and own cut UV.
def cut_piece(bottom,top,name):
 o=clone(host,name);active(o);bm=bmesh.new();bm.from_mesh(o.data)
 for z,normal in [(top,(0,0,1)),(bottom,(0,0,-1))]:
  result=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,z),plane_no=normal,clear_outer=True,clear_inner=False)
  boundary=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-z)<.0001 for v in e.verts)]
  if boundary:
   filled=bmesh.ops.holes_fill(bm,edges=boundary,sides=0)
   for f in filled['faces']:f.material_index=1
 bm.to_mesh(o.data);bm.free();o.data.materials.append(wood_mat)
 uv=o.data.uv_layers[0]
 cap_points=[o.data.vertices[i].co for poly in o.data.polygons if poly.material_index==1 for i in poly.vertices]
 cx=(min(v.x for v in cap_points)+max(v.x for v in cap_points))/2;cy=(min(v.y for v in cap_points)+max(v.y for v in cap_points))/2
 span=max(max(v.x for v in cap_points)-min(v.x for v in cap_points),max(v.y for v in cap_points)-min(v.y for v in cap_points))/.92
 for poly in o.data.polygons:
  if poly.material_index==1:
   for li in poly.loop_indices:
    co=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=((co.x-cx)/span+.5,(co.y-cy)/span+.5)
 return o
stump=cut_piece(-.02,sc['cut_height_m'],kind+' matching stump');export([stump],kind+'-stump')
root=cut_piece(-.02,sc['cut_height_m']+.08,kind+' root skirt');export([root],kind+'-root-skirt')
log=cut_piece(sc['cut_height_m'],2.05,kind+' inert deadwood')
for v in log.data.vertices:v.co=Matrix.Rotation(math.pi/2,4,'Y')@(v.co-Vector((0,0,sc['cut_height_m'])))
low=min(v.co.z for v in log.data.vertices)
for v in log.data.vertices:v.co.z-=low
export([log],kind+'-deadwood')
# One altered oak derived from original approved routes, incision remains with emission off.
if kind=='broadleaf':
 altered=clone(host,'FINISHED deep injured oak',fin_col);me=altered.data;before=np.array([v.co[:] for v in me.vertices]);norm=np.array([v.normal[:] for v in me.vertices]);tree_bvh=bvh(altered)
 depot=Path('C:/Users/Matty/Dev/project-wroughtwild');paths=json.loads((depot/'build/grove-art02/emberroot-handoff/review/tree-report.json').read_text())['projected_paths']
 samples=np.array([p for path in paths for p in path]);dist=np.full(len(before),999.)
 for start in range(0,len(before),1024):dist[start:start+1024]=np.linalg.norm(before[start:start+1024,None,:]-samples[None,:,:],axis=2).min(1)
 damage=np.clip(1-dist/cfg['scar']['damage_half_width_m'],0,1);damage=damage*damage*(3-2*damage)
 core=np.clip(1-dist/cfg['scar']['core_half_width_m'],0,1)
 after=before-norm*damage[:,None]*cfg['scar']['depth_m'];me.vertices.foreach_set('co',after.astype(np.float32).ravel());me.update()
 for loop in me.loops:me.uv_layers[1].data[loop.index].uv=(float(core[loop.vertex_index]),float(damage[loop.vertex_index]))
 am=mat.copy();am.name='Deep oak bark';me.materials[0]=am;ns=am.node_tree.nodes;ls=am.node_tree.links;bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED');old=bs.inputs['Base Color'].links[0].from_socket if bs.inputs['Base Color'].is_linked else None
 uv=ns.new('ShaderNodeUVMap');uv.uv_map='Incision core damage';sep=ns.new('ShaderNodeSeparateXYZ');ls.new(uv.outputs[0],sep.inputs[0]);mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[2].default_value=(.012,.008,.004,1);ls.new(sep.outputs['Y'],mix.inputs[0]);ls.new(old,mix.inputs[1]);ls.new(mix.outputs[0],bs.inputs['Base Color']);bs.inputs['Emission Color'].default_value=(1,.09,.004,1);ls.new(sep.outputs['X'],bs.inputs['Emission Strength'])
 report['scar']={'requested_depth_m':cfg['scar']['depth_m'],'measured_vertex_displacement_m':float(np.linalg.norm(after-before,axis=1).max()),'vertices_displaced_over_2cm':int((np.linalg.norm(after-before,axis=1)>.02).sum()),'original_routes':str(depot/'build/grove-art02/emberroot-handoff/review/tree-report.json'),'quiet_source_unchanged':True}
 # Retain damaged host detail at the important close cavity; independent reductions after incision.
 for level,target in enumerate(sc['trunk_triangles']):
  a=clone(altered,'Deep oak L'+str(level));decimate(a,target);parts=[a]+crown(a,level,0);variants['broadleaf-altered-lod'+str(level)]=parts;export(parts,'broadleaf-altered-lod'+str(level))

for o in bpy.context.scene.objects:o.hide_render=True;o.hide_set(True)
# Review the exact exported source assemblies, metre ruler and six material/clay views.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.device='CPU';scene.cycles.use_denoising=True
scene.render.resolution_x=1100;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('B1 neutral studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.23,.26,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));review_col.objects.link(sun);sun.rotation_euler=(.55,-.5,-.5);sun.data.energy=2.1
cam=bpy.data.objects.new('Actual model camera',bpy.data.cameras.new('Actual model camera'));review_col.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=11.4
clay=bpy.data.materials.new('Review clay');clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.35,.35,.35,1)
selected=variants[kind+'-a-lod0']
for o in selected:o.hide_render=False;o.hide_set(False)
for name,at in [('front',(0,-20,5)),('back',(0,20,5)),('side',(20,0,5)),('threequarter',(14,-18,9)),('top',(0,-.1,25)),('underside',(10,-16,-5))]:
 cam.location=at;cam.rotation_euler=(Vector((0,0,4))-cam.location).to_track_quat('-Z','Y').to_euler();scene.view_layers[0].material_override=clay if name in ['back','top','underside'] else None
 scene.render.filepath=str(out/('blender-'+name+'.png'));bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=None
if kind=='broadleaf':
 for o in selected:o.hide_render=True
 for o in variants['broadleaf-altered-lod0']:o.hide_render=False
 cam.data.ortho_scale=3.7;cam.location=(1,-9,2.5);cam.rotation_euler=(Vector((0,0,2.5))-cam.location).to_track_quat('-Z','Y').to_euler()
 for name,override in [('scar-lit',None),('scar-clay',clay)]:
  scene.view_layers[0].material_override=override;scene.render.filepath=str(out/('blender-'+name+'.png'));bpy.ops.render.render(write_still=True)
 scene.view_layers[0].material_override=None
for im in bpy.data.images:
 if im.has_data and im.source in ['FILE','GENERATED']:im.pack()
scene['scope']='ART-07B1 source/runtime candidates; not normal-world adoption';scene['controls']=json.dumps(cfg)
(out/'kit-report.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(out/(kind+'-master.blend')),compress=True)
print('B1_KIT_OK',json.dumps(report['scar']))
