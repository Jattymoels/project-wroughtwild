"""F3 metre-scale editable cores, fitted mechanisms, source housings and LODs.
Direct apparatus; immutable TRELLIS copies; D4/D6 surfaces are read-only inputs.
Usage: Blender --background --threads 8 --python-exit-code 1 --python ... -- RAW_PULL RAW_VENT FRESH_OUT
"""
import bpy,bmesh,json,math,sys,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform
ROOT=Path(__file__).resolve().parents[3]
CFG=json.loads(Path(__file__).with_name('settings.json').read_text())
D4=Path('C:/Users/Matty/Dev/project-wroughtwild-art07-d4/build/art07/d4/h04/review/textures')
D6=Path('C:/Users/Matty/Dev/project-wroughtwild/build/art07/d6/worktree/build/art07/d6/v04/handoff/review/textures')
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def coll(name):
 c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);return c
def move(o,c):
 for old in list(o.users_collection):old.objects.unlink(o)
 c.objects.link(o)
def solid(name,color,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.78;p.inputs['Metallic'].default_value=metal;return m
def pbr(name,folder,prefix):
 m=solid(name,(.5,.5,.5));ns=m.node_tree.nodes;ls=m.node_tree.links;p=ns.get('Principled BSDF')
 for kind in ['albedo','normal','orm']:
  t=ns.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(folder/f'{prefix}_{kind}.png'),check_existing=True);t.image.colorspace_settings.name='sRGB' if kind=='albedo' else 'Non-Color'
  if kind=='albedo':ls.new(t.outputs[0],p.inputs['Base Color'])
  elif kind=='normal':n=ns.new('ShaderNodeNormalMap');ls.new(t.outputs[0],n.inputs['Color']);ls.new(n.outputs[0],p.inputs['Normal'])
  else:s=ns.new('ShaderNodeSeparateColor');ls.new(t.outputs[0],s.inputs[0]);ls.new(s.outputs['Green'],p.inputs['Roughness']);ls.new(s.outputs['Blue'],p.inputs['Metallic'])
 return m
def uv(o,wood=False):
 me=o.data;me.update()
 for old in list(me.uv_layers):me.uv_layers.remove(old)
 uvs=me.uv_layers.new(name='F3_metric_uv')
 length=max(range(3),key=lambda k:o.dimensions[k])
 for p in me.polygons:
  axis=max(range(3),key=lambda k:abs(p.normal[k]));axes=[i for i in range(3) if i!=axis]
  if wood and length in axes:v=length;u=next(i for i in axes if i!=v)
  else:u,v=axes
  tu=Vector([int(k==u) for k in range(3)]);tv=Vector([int(k==v) for k in range(3)]);sign=1 if tu.cross(tv).dot(p.normal)>0 else -1
  if wood:p.material_index=1 if axis==length else 0
  for li in p.loop_indices:
   co=me.vertices[me.loops[li].vertex_index].co;repeat_u=CFG['wood_repeat_m'][0] if wood else CFG['metal_repeat_m'];repeat_v=CFG['wood_repeat_m'][1] if wood and axis!=length else repeat_u;uvs.data[li].uv=(co[u]/repeat_u*sign,co[v]/repeat_v)
def box(name,at,size,mat,bevel=None):
 if bevel is None:bevel=CFG['beam_bevel_m']
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 mats=mat if isinstance(mat,list) else [mat]
 for m in mats:o.data.materials.append(m)
 if bevel:
  mod=o.modifiers.new('Worked edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 uv(o,len(mats)==2);return o
def beam(name,a,b,width,mat):
 a,b=Vector(a),Vector(b);o=box(name,(a+b)/2,(width,width,(b-a).length),mat);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def tube(name,points,radii,mat,sides=12):
 verts=[];faces=[]
 for i,p in enumerate(points):
  p=Vector(p);d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)]);d.normalize();u=d.cross(Vector((0,0,1)))
  if u.length<.01:u=d.cross(Vector((0,1,0)))
  u.normalize();v=d.cross(u).normalized()
  for j in range(sides):verts.append(p+radii[i]*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides)))
 for i in range(len(points)-1):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))])
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);me.materials.append(mat);uv(o);return o
def join(parts,name,c,pivot=(0,0,0)):
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name;bpy.context.scene.cursor.location=pivot;bpy.ops.object.origin_set(type='ORIGIN_CURSOR');move(o,c);return o
def pin(at,iron):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,radius=1,location=at);o=bpy.context.object;o.scale=(.018,.010,.018);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(iron);uv(o);return o
def export(objs,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 # Standard glTF carries original PBR images and explicit scar vertex channels;
 # preview-only Blender node mixing is reconstructed by the engine shader.
 restore=[]
 for m in {m for o in objs if o.type=='MESH' for m in o.data.materials}:
  if not m.get('f3_original_albedo_node'):continue
  p=m.node_tree.nodes.get('Principled BSDF');old=p.inputs['Base Color'].links[0].from_socket
  m.node_tree.links.new(m.node_tree.nodes[m['f3_original_albedo_node']].outputs['Color'],p.inputs['Base Color']);restore.append((m,p,old))
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_extras=True,export_yup=True,export_apply=False,export_vertex_color='NAME',export_vertex_color_name='F3_SCAR',export_all_vertex_colors=False)
 for m,p,old in restore:m.node_tree.links.new(old,p.inputs['Base Color'])
def stats(o):
 o.data.calc_loop_triangles();points=[o.matrix_world@v.co for v in o.data.vertices]
 lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
 bad=sum(t.area<1e-12 for t in o.data.loop_triangles)
 assert all(math.isfinite(x) for p in points for x in p)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);boundary=sum(e.is_boundary for e in bm.edges);nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.free()
 return {'name':o.name,'triangles':len(o.data.loop_triangles),'surfaces':len(o.data.materials),'degenerate':bad,'bounds_blender':[lo,hi],'welded_boundary_edges':boundary,'welded_nonmanifold_edges':nonmanifold}

def seal(o,kind):
 # Recover closed solids from touching/overfull raw triangles; transfer UVs
 # by interpolated source faces, never nearest unrelated source vertices.
 donor=clone(o,kind+'_UV_surface_donor',o.users_collection[0]);donor.hide_render=True;donor.hide_set(True)
 print('F3_RECOVERY_START',kind,flush=True)
 active(o);mod=o.modifiers.new('Closed recovered surface','REMESH');mod.mode='VOXEL';mod.voxel_size=CFG['recovery_voxel_m'][kind];mod.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 print('F3_RECOVERED',kind,len(o.data.vertices),len(o.data.polygons),flush=True)
 # A usable recovered core is one connected solid. Tiny disconnected internal
 # crumbs become duplicate zero-volume triangles under decimation/export.
 bm=bmesh.new();bm.from_mesh(o.data);unseen=set(bm.verts);components=[]
 while unseen:
  seed=unseen.pop();component={seed};pending=[seed]
  while pending:
   v=pending.pop()
   for e in v.link_edges:
    other=e.other_vert(v)
    if other in unseen:unseen.remove(other);component.add(other);pending.append(other)
  components.append(component)
 keep=max(components,key=len);discard=[v for comp in components if comp is not keep for v in comp]
 bmesh.ops.delete(bm,geom=discard,context='VERTS');bm.to_mesh(o.data);bm.free();o.data.update()
 print('F3_CONNECTED_CORE',kind,'discarded components',len(components)-1,'vertices',len(discard),flush=True)
 # One BVH query per recovered face chooses a coherent source triangle chart.
 # Interpolate that triangle's loop UVs for all corners of the new face.
 dm=donor.data;dm.calc_loop_triangles();triangles=list(dm.loop_triangles);positions=[v.co.copy() for v in dm.vertices];tree=BVHTree.FromPolygons(positions,[tuple(t.vertices) for t in triangles],all_triangles=True)
 duv=dm.uv_layers.active.data;layer=o.data.uv_layers.new(name='Recovered_surface_uv')
 for poly in o.data.polygons:
  hit=tree.find_nearest(poly.center);tri=triangles[hit[2]];points=[positions[i] for i in tri.vertices];chart=[Vector((*duv[li].uv,0)) for li in tri.loops]
  for li in poly.loop_indices:
   projected=barycentric_transform(o.data.vertices[o.data.loops[li].vertex_index].co,*points,*chart);layer.data[li].uv=projected.xy
 print('F3_UV_TRANSFERRED',kind,flush=True)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 edges=[e for e in bm.edges if e.is_boundary];count=len(edges)
 if edges:
  cap=solid('f3_'+kind+'_cut_face',(.34,.29,.21) if kind=='ventlung' else (.09,.09,.08));o.data.materials.append(cap)
  faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0)['faces'];layer=bm.loops.layers.uv.active
  for f in faces:
   f.material_index=len(o.data.materials)-1
   if layer:
    for loop in f.loops:loop[layer].uv=(loop.vert.co.x*2,loop.vert.co.y*2)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update();return count
def clone(o,name,c):
 n=o.copy();n.data=o.data.copy();n.name=name;c.objects.link(n);return n
def simplify(o,target):
 active(o)
 # Weld coincident import seam vertices, preserving each loop's original UV.
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bm.to_mesh(o.data);bm.free()
 o.data.calc_loop_triangles();n=len(o.data.loop_triangles)
 if n>target:
  mod=o.modifiers.new('Silhouette detail level','DECIMATE');mod.ratio=target/n;mod.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 # Delete zero-area remnants only, without loosening checks.
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.dissolve_degenerate(bm,dist=1e-7,edges=list(bm.edges));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
 assert not o.data.validate(),(o.name,'simplification produced an invalid mesh')
def scar(o,kind):
 """Cut into front surface while preserving original source UVs and images."""
 me=o.data;me.update();height=max(v.co.z for v in me.vertices);depth=CFG['scar_depth_m'][kind];width=CFG['scar_half_width_m'][kind]
 def path(z):return .14+(.048 if kind=='pullstone' else .026)*math.sin(z*11)
 before=BVHTree.FromPolygons([v.co.copy() for v in me.vertices],[tuple(p.vertices) for p in me.polygons])
 colors=me.color_attributes.new(name='F3_SCAR',type='FLOAT_COLOR',domain='POINT')
 maxcut=0
 for v in me.vertices:
  x,y,z=v.co;dist=abs(x-path(z));fade=max(0,min(1,(z-.08)/.08,(height-.06-z)/.08));front=max(0,min(1,-y/.07));w=math.exp(-(dist/width)**2)*fade*front;cut=depth*w
  v.co.y+=cut;maxcut=max(maxcut,cut);margin=math.exp(-(dist/(width*1.9))**2)*fade*front
  colors.data[v.index].color=(margin,w**3,z/max(height,.01),1)
 me.update();after=BVHTree.FromPolygons([v.co.copy() for v in me.vertices],[tuple(p.vertices) for p in me.polygons]);samples=[]
 for i in range(1,10):
  z=height*i/10;origin=Vector((path(z),-3,z));a=before.ray_cast(origin,Vector((0,1,0)))[0];b=after.ray_cast(origin,Vector((0,1,0)))[0]
  if a is not None and b is not None:samples.append({'z':z,'inward_m':b.y-a.y})
 assert max(s['inward_m'] for s in samples)>depth*.6,(kind,samples)
 for mat in me.materials:
  ns=mat.node_tree.nodes;ls=mat.node_tree.links;p=ns.get('Principled BSDF');vc=ns.new('ShaderNodeVertexColor');vc.layer_name='F3_SCAR';s=ns.new('ShaderNodeSeparateColor');ls.new(vc.outputs['Color'],s.inputs[0])
  mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[2].default_value=(.10,.075,.055,1)
  old=p.inputs['Base Color'].links[0].from_socket if p.inputs['Base Color'].is_linked else None
  if old:
   ls.new(old,mix.inputs[1])
   if old.node.type=='TEX_IMAGE':mat['f3_original_albedo_node']=old.node.name
  else:mix.inputs[1].default_value=p.inputs['Base Color'].default_value
  ls.new(s.outputs['Red'],mix.inputs[0]);ls.new(mix.outputs[0],p.inputs['Base Color'])
  p.inputs['Emission Color'].default_value=(1,.66,.29,1);gate=ns.new('ShaderNodeMath');gate.operation='MULTIPLY';gate.name='F3_WORK';gate.inputs[1].default_value=0.0;ls.new(s.outputs['Green'],gate.inputs[0]);ls.new(gate.outputs[0],p.inputs['Emission Strength'])
  mat.name='f3_'+kind+'_skin'
 return {'nominal_depth_m':depth,'half_width_m':width,'max_vertex_displacement_m':maxcut,'before_after_front_bvh':samples,'meaning':'geometric incision; emission green is work-state gated in Godot, not a free timer'}
def organic(src,kind,source,finished,runtime,out):
 bpy.ops.import_scene.gltf(filepath=str(src));objs=list(bpy.context.selected_objects);meshes=[o for o in objs if o.type=='MESH'];o=join(meshes,'Raw_'+kind,source);active(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 raw=stats(o);lo,hi=map(Vector,raw['bounds_blender']);scale=CFG['source_height_m'][kind]/(hi.z-lo.z);center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 master=clone(o,'Finished_'+kind,finished)
 for v in master.data.vertices:v.co=(v.co-center)*scale
 # Preserve UV/material originals in the hidden Raw collection.
 for i,m in enumerate(master.data.materials):master.data.materials[i]=m.copy()
 sealed=seal(master,kind);print('F3_SEALED',kind,flush=True);injury=scar(master,kind);print('F3_SCARRED',kind,flush=True);o.hide_render=True;o.hide_set(True)
 report={'source':str(src),'sha256':sha(src),'raw':raw,'uniform_scale':scale,'raw_center_blender':list(center),'closed_boundary_edges':sealed,'scar':injury,'lods':{}}
 for label,key in [('near','source_near_triangles'),('middle','source_middle_triangles'),('far','source_far_triangles')]:
  n=clone(master,f'{kind}_{label}',runtime);simplify(n,CFG[key][kind]);report['lods'][label]=stats(n);assert report['lods'][label]['degenerate']==0
  export([n],out/f'{kind}_{label}.glb');n.hide_render=True;n.hide_set(True)
 master.hide_render=True;master.hide_set(True)
 return master,report
def sorter(wood,iron,c,core):
 parts=[]
 for x in [-.565,.565]:
  parts.append(box('Floor runner',(x,0,.055),(.125,.80,.11),wood))
  parts.append(beam('Rear upright',(x,.275,.08),(x,.275,1.24),.09,wood))
  parts.append(beam('Splayed brace',(x,-.32,.1),(x,.26,.86),.07,wood))
 parts.append(box('Cross tie',(0,.28,1.19),(1.21,.09,.09),wood))
 # Native Godot -Z rear feed becomes Blender +Y; two trays face -Y.
 for x in [-.40,.40]:
  parts.append(box('Tray bed',(x,-.15,.235),(.47,.49,.05),wood))
  for y in [-.38,.08]:parts.append(box('Tray end',(x,y,.302),(.49,.035,.17),wood))
  for edge in [-.23,.23]:parts.append(box('Tray side',(x+edge,-.15,.302),(.032,.42,.17),wood))
  for edge in [-.20,.20]:
   parts.append(box('Tray iron corner',(x+edge,-.402,.302),(.045,.018,.14),iron,.002));parts.append(pin((x+edge,-.414,.33),iron))
 # Inclined split chute; the magnet is offset to the ferrous left lane.
 for x in [-.105,.08,.265]:parts.append(beam('Chute plank',(x,.27,1.055),(x,-.23,.405),.17,wood))
 for x in [-.21,.36]:parts.append(beam('Chute raised lip',(x,.27,1.115),(x,-.23,.46),.055,wood))
 parts.append(beam('Deflector lip',(-.1,-.11,.58),(-.31,-.23,.4),.04,wood))
 for z in [.72,1.00]:
  parts.append(box('Nodule strap',(-.355,-.035,z),(.47,.044,.043),iron,.002))
  for x in [-.57,-.14]:parts.append(pin((x,-.065,z),iron))
 parts.append(beam('Magnet brace',(-.56,.25,.6),(-.56,0,1.02),.07,wood))
 housing=join(parts,'Housing',c)
 magnet=clone(core,'Pullstone',c);magnet.hide_render=False;magnet.hide_set(False);magnet.scale=(.48,.48,.48);magnet.location=(-.35,.045,.61)
 return [housing,magnet]
def bellows(wood,iron,reed,c,core):
 parts=[]
 for x in [-.365,.365]:
  parts.append(box('Foot',(x,0,.05),(.14,.84,.10),wood))
  for y in [-.30,.30]:parts.append(beam('Guided platen post',(x,y,.09),(x,y,.91),.062,wood))
 parts.append(box('Bottom board',(0,.03,.17),(.77,.75,.10),wood))
 parts.append(box('Rear brace',(0,.31,.87),(.668,.08,.08),wood))
 # Hollow tapered wooden nozzle and collar: no unpriced iron requirement.
 verts=[];faces=[];n=20
 for y,outer,inner in [(-.22,.097,.055),(-.50,.060,.039),(-.555,.063,.038)]:
  for radius in [outer,inner]:
   for j in range(n):a=j*math.tau/n;verts.append((math.cos(a)*radius,y,.55+math.sin(a)*radius))
 for k in range(2):
  for layer in range(2):
   for j in range(n):a=k*n*2+layer*n+j;b=k*n*2+layer*n+(j+1)%n;faces.append((a,b,b+n*2,a+n*2) if layer==0 else (b,a,a+n*2,b+n*2))
 for k in [0,2]:
  for j in range(n):a=k*n*2+j;b=k*n*2+(j+1)%n;faces.append((a,a+n,b+n,b))
 me=bpy.data.meshes.new('Hollow bored nozzle');me.from_pydata(verts,[],faces);me.update();nozzle=bpy.data.objects.new('Directed hollow wooden nozzle',me);bpy.context.collection.objects.link(nozzle);me.materials.append(wood[0]);uv(nozzle);parts.append(nozzle)
 for y in [-.23,-.25,-.27]:parts.append(tube('Bound nozzle',[ (.10*math.cos(j*math.tau/32),y,.55+.10*math.sin(j*math.tau/32)) for j in range(33)],[.012]*33,reed,8))
 housing=join(parts,'Housing',c)
 top=[];top.append(box('Top platen',(0,.03,.02),(.77,.75,.09),wood))
 top.append(beam('Hand grip',(-.22,.11,.13),(.22,.11,.13),.07,wood))
 for x in [-.22,.22]:top.append(beam('Grip stem',(x,.11,.04),(x,.11,.13),.045,wood))
 # Continuous fibre loops hold the membrane against the two support boards.
 for x in [-.29,.29]:
  for y in [-.25,.25]:top.append(tube('Reed fastening',[(x-.03,y,.04),(x,y,.08),(x+.03,y,.04)],[.009]*3,reed,8))
 platen=join(top,'Platen',c);platen.location=(0,0,.72)
 bladder=clone(core,'Membrane',c);bladder.hide_render=False;bladder.hide_set(False);bladder.scale=(.70,.70,.52);bladder.location=(0,.03,.22)
 return [housing,platen,bladder]
def shell(kind,stone,c):
 parts=[]
 if kind=='pullstone':
  # Weathered supported overhang, built directly as a closed mineral extrusion.
  profile=[(-.94,0),(-.75,.88),(-.60,1.10),(.73,1.10),(.94,.20),(.72,.02),(.59,.68),(.44,.84),(-.48,.82),(-.62,.08)]
  verts=[(x,y,z) for y in [-.46,.46] for x,z in profile];n=len(profile);faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 else:
  # Closed thick mineral bowl with an open centre; empty after harvest.
  n=48;verts=[]
  for ring in range(4):
   for j in range(n):
    a=j*math.tau/n;r=[.50,.54,.38,.32][ring]+.023*math.sin(j*2.7);z=[.015,.36,.32,.025][ring]+(.05*math.sin(j*1.4) if ring in [1,2] else 0);verts.append((r*math.cos(a),r*math.sin(a),z))
  faces=[]
  for ring in range(4):
   for j in range(n):faces.append((ring*n+j,ring*n+(j+1)%n,((ring+1)%4)*n+(j+1)%n,((ring+1)%4)*n+j))
 me=bpy.data.meshes.new(kind+'_mineral_housing');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(kind+'_shell',me);c.objects.link(o);me.materials.append(stone);uv(o);active(o);mod=o.modifiers.new('Chipped exposed edges','BEVEL');mod.width=.02;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 if kind=='pullstone':
  support=box('Closed mineral seat',(0,.06,.095),(.62,.60,.19),stone,.04);o=join([o,support],kind+'_shell',c)
 return o
def stage(out,objects):
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.threads_mode='FIXED';scene.render.threads=8;scene.render.resolution_x=1400;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
 review=coll('Review');ground=box('Review ground',(0,0,-.04),(200,200,.06),solid('Stage',(.09,.10,.09)));move(ground,review)
 world=bpy.data.worlds.new('World');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[1].default_value=.55;scene.world=world
 for name,at,power,size in [('Key',(-3,-4,6),1200,4),('Fill',(4,-2,4),850,4),('Rim',(0,4,6),1500,4)]:
  d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=size;o=bpy.data.objects.new(name,d);review.objects.link(o);o.location=at;aim(o,(0,0,.6))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));review.objects.link(cam);cam.data.type='ORTHO';scene.camera=cam
 for group,items in objects.items():
  for other in objects.values():
   for o in other:o.hide_render=True
  for o in items:o.hide_render=False
  cam.data.ortho_scale=2.25 if group!='pullstone_source' else 2.6
  for name,at in {'threequarter':(3,-5,3),'front':(0,-5,1.3),'back':(0,5,1.3),'side':(5,0,1.3),'top':(0,-.01,6),'underside':(0,-.01,-5)}.items():
   cam.location=at;aim(cam,(0,0,.60));scene.render.filepath=str(out/f'{group}-{name}.png');ground.hide_render=name=='underside';bpy.ops.render.render(write_still=True)
  ground.hide_render=False
  cam.location=(3,-5,3);aim(cam,(0,0,.60))
  for peak in [0,1]:
   for m in bpy.data.materials:
    if m.use_nodes and m.node_tree.nodes.get('F3_WORK'):m.node_tree.nodes['F3_WORK'].inputs[1].default_value=peak
   scene.render.filepath=str(out/f'{group}-emission-{peak}.png');bpy.ops.render.render(write_still=True)
  for m in bpy.data.materials:
   if m.use_nodes and m.node_tree.nodes.get('F3_WORK'):m.node_tree.nodes['F3_WORK'].inputs[1].default_value=0
 for other in objects.values():
  for o in other:o.hide_render=True
 # Editable overview separates finished asset groups, no source is overwritten.
 for i,(name,items) in enumerate(objects.items()):
  for o in items:o.hide_render=False;o.location.x+=(i-1.5)*2.2
 cam.location=(4,-12,6);aim(cam,(0,0,.55));cam.data.ortho_scale=9.8;scene.render.resolution_x=1800;scene.render.resolution_y=850;scene.render.filepath=str(out/'blender-overview.png');bpy.ops.render.render(write_still=True)
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'f3_master.blend'))
def main():
 args=sys.argv[sys.argv.index('--')+1:];pull,vent,out=[Path(a).resolve() for a in args];out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.read_factory_settings(use_empty=True)
 source=coll('Immutable_raw_sources');finished=coll('Finished_organic_masters');runtime=coll('Runtime_candidates');devices=coll('Fitted_mechanisms');hosts=coll('Host_and_component_states')
 wood=[pbr('f3_wood_face',D4,'d4_wood_face'),pbr('f3_wood_end',D4,'d4_wood_edge')];iron=pbr('f3_iron',D6,'d6_iron');reed=solid('f3_reed_lashing',(.27,.19,.10));stone=solid('f3_mineral_case',(.15,.17,.16));report={'base_commit':CFG['base_commit'],'sources':{},'parts':{},'textures':[]}
 cores={}
 for kind,src in [('pullstone',pull),('ventlung',vent)]:cores[kind],report['sources'][kind]=organic(src,kind,source,finished,runtime,out)
 # Device cores are scaled near candidates, not unbounded high-detail masters.
 near={kind:next(o for o in runtime.objects if o.name==kind+'_near') for kind in cores}
 sorter_parts=sorter(wood,iron,devices,near['pullstone']);bellows_parts=bellows(wood,iron,reed,devices,near['ventlung'])
 objects={'magnetic_sorter':sorter_parts,'ventlung_bellows':bellows_parts}
 for kind in ['pullstone','ventlung']:
  host=shell(kind,stone,hosts);export([host],out/f'{kind}_shell.glb');core=clone(near[kind],kind+'_source',hosts);core.hide_render=False;core.hide_set(False)
  if kind=='pullstone':core.scale=(.70,.70,.70);core.location=(0,-.08,.16)
  else:core.scale=(.87,.87,.87);core.location=(0,0,.19)
  objects[kind+'_source']=[host,core]
 for name,items in objects.items():
  for o in items:o.hide_set(False);o.hide_render=False
  bpy.context.view_layer.update();report['parts'][name]=[stats(o) for o in items]
  assert all(r['degenerate']==0 for r in report['parts'][name])
  expected=CFG['native_bounds_m'].get(name,CFG['native_bounds_m'].get(name.replace('_source','')))
  for r in report['parts'][name]:
   lo,hi=r['bounds_blender'];assert lo[0]>=-expected[0]/2-1e-5 and hi[0]<=expected[0]/2+1e-5 and lo[1]>=-expected[2]/2-1e-5 and hi[1]<=expected[2]/2+1e-5 and lo[2]>=-1e-5 and hi[2]<=expected[1]+1e-5,(name,r,expected)
  export(items,out/f'{name}.glb')
 for i in bpy.data.images:
  if i.source=='FILE':
   i.pack();report['textures'].append({'name':i.name,'size':list(i.size),'space':i.colorspace_settings.name,'packed':bool(i.packed_file)})
 (out/'asset-audit.json').write_text(json.dumps(report,indent=2)+'\n');stage(out,objects);print('F3_ASSET_BUILD_OK',out)
main()
