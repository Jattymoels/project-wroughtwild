"""F1 metre-scale editable cores, fitted mechanisms, source housings and LODs.
Direct apparatus; immutable TRELLIS copies; D4/D6 surfaces are read-only inputs.
Helper module imported by build_assets.py; does not execute a build itself.
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
 uvs=me.uv_layers.new(name='F1_metric_uv')
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
 verts=[];faces=[];previous_u=None
 closed=(Vector(points[0])-Vector(points[-1])).length<1e-7
 if closed:points=points[:-1];radii=radii[:-1]
 for i,p in enumerate(points):
  p=Vector(p);d=Vector(points[(i+1)%len(points) if closed else min(i+1,len(points)-1)])-Vector(points[(i-1)%len(points) if closed else max(i-1,0)]);d.normalize();u=previous_u-d*previous_u.dot(d) if previous_u is not None else d.cross(Vector((0,0,1)))
  if u.length<.01:u=d.cross(Vector((0,1,0)))
  u.normalize();previous_u=u.copy();v=d.cross(u).normalized()
  for j in range(sides):verts.append(p+radii[i]*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides)))
 for i in range(len(points) if closed else len(points)-1):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;nextrow=((i+1)%len(points))*sides;faces.append((a,b,nextrow+(j+1)%sides,nextrow+j))
 if not closed:faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))])
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
  if not m.get('f1_original_albedo_node'):continue
  p=m.node_tree.nodes.get('Principled BSDF');old=p.inputs['Base Color'].links[0].from_socket
  m.node_tree.links.new(m.node_tree.nodes[m['f1_original_albedo_node']].outputs['Color'],p.inputs['Base Color']);restore.append((m,p,old))
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_extras=True,export_yup=True,export_apply=False,export_vertex_color='NAME',export_vertex_color_name='F1_SCAR',export_all_vertex_colors=False)
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
 print('F1_RECOVERY_START',kind,flush=True)
 active(o);mod=o.modifiers.new('Closed recovered surface','REMESH');mod.mode='VOXEL';mod.voxel_size=CFG['recovery_voxel_m'][kind];mod.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 print('F1_RECOVERED',kind,len(o.data.vertices),len(o.data.polygons),flush=True)
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
 print('F1_CONNECTED_CORE',kind,'discarded components',len(components)-1,'vertices',len(discard),flush=True)
 # One BVH query per recovered face chooses a coherent source triangle chart.
 # Interpolate that triangle's loop UVs for all corners of the new face.
 dm=donor.data;dm.calc_loop_triangles();triangles=list(dm.loop_triangles);positions=[v.co.copy() for v in dm.vertices];tree=BVHTree.FromPolygons(positions,[tuple(t.vertices) for t in triangles],all_triangles=True)
 duv=dm.uv_layers.active.data;layer=o.data.uv_layers.new(name='Recovered_surface_uv')
 for poly in o.data.polygons:
  hit=tree.find_nearest(poly.center);tri=triangles[hit[2]];poly.material_index=dm.polygons[tri.polygon_index].material_index;points=[positions[i] for i in tri.vertices];chart=[Vector((*duv[li].uv,0)) for li in tri.loops]
  for li in poly.loop_indices:
   projected=barycentric_transform(o.data.vertices[o.data.loops[li].vertex_index].co,*points,*chart);layer.data[li].uv=projected.xy
 print('F1_UV_TRANSFERRED',kind,flush=True)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 edges=[e for e in bm.edges if e.is_boundary];count=len(edges)
 if edges:
  cap=solid('f1_'+kind+'_cut_face',(.34,.29,.21) if kind=='ventlung' else (.09,.09,.08));o.data.materials.append(cap)
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
