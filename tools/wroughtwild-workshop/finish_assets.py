"""Blender: authored mineral surface, cut pieces, fitting, LODs and packed source.
Run with -- INSPECTED_SOURCE.blend RAW.glb FRESH_OUTPUT. No gameplay files.
"""
import bpy,bmesh,json,sys,hashlib,struct,math
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
source,raw,out=map(Path,sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(Path(__file__).with_name('red.json').read_text(encoding='utf-8'));sc=cfg['scar']
assert hashlib.sha256(raw.read_bytes()).hexdigest()==cfg['source_sha256']
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source.resolve()))
host=bpy.data.objects['Red inclusion - intact normalized source']
for o in list(bpy.context.scene.objects):
    if o!=host:bpy.data.objects.remove(o,do_unlink=True)
original=host.copy();original.data=host.data.copy();bpy.context.collection.objects.link(original)
original.name='SOURCE - untouched normalized Red inclusion';original.hide_set(True);original.hide_render=True
bpy.context.view_layer.objects.active=host;host.select_set(True)
bm=bmesh.new();bm.from_mesh(host.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002);bm.to_mesh(host.data);bm.free()
dec=host.modifiers.new('Near silhouette reduction','DECIMATE');dec.ratio=cfg['lod_triangles'][0]/len(host.data.polygons)
bpy.ops.object.modifier_apply(modifier=dec.name)
host.name='Red inclusion - ready worked or spent host';mesh=host.data
mesh.validate();mesh.update()
# QEM can move the lowest vertex fractions of a millimetre below the source
# pivot. Seat the finished mesh on zero before projecting the authored surface.
ground_shift=min(v.co.z for v in mesh.vertices)
for v in mesh.vertices:v.co.z-=ground_shift
mesh.update()
for f in mesh.polygons:f.use_smooth=True
p=np.array([v.co for v in mesh.vertices]);lo,hi=p.min(0),p.max(0)
bvh=BVHTree.FromPolygons([Vector(v) for v in p],[tuple(f.vertices) for f in mesh.polygons])
starts,ends,widths,flow0,flow1,paths=[],[],[],[],[],[]
for path in sc['paths']:
    controls=np.array(path['points']);projected=[]
    samples=[]
    for a,b in zip(controls[:-1],controls[1:]):
        samples.extend(a*(1-t)+b*t for t in np.linspace(0,1,max(2,int(np.linalg.norm(b-a)/.014)),endpoint=False))
    samples.append(controls[-1])
    for u,v in samples:
        origin=Vector((u,v,2)) if path['axis']=='top' else Vector((u,-2,v))
        direction=Vector((0,0,-1)) if path['axis']=='top' else Vector((0,1,0))
        hit,normal,index,distance=bvh.ray_cast(origin,direction,4)
        assert hit is not None,('Scar misses host',path,u,v)
        projected.append(np.array(hit))
    q=np.array(projected);distances=np.linalg.norm(np.diff(q,axis=0),axis=1)
    travel=np.concatenate(([0.],np.cumsum(distances)))
    for i,(a,b) in enumerate(zip(q[:-1],q[1:])):
        if np.linalg.norm(b-a)<1e-7:continue
        starts.append(a);ends.append(b)
        widths.append(path['width']*(1-.85*max(0,(i/max(1,len(q)-2)-.70)/.30)))
        flow0.append(path['offset']+travel[i]*.72);flow1.append(path['offset']+travel[i+1]*.72)
    paths.append({'axis':path['axis'],'projected':q.tolist()})
a,b=np.array(starts),np.array(ends);ab=b-a;length2=(ab*ab).sum(1);widths=np.array(widths);f0,f1=np.array(flow0),np.array(flow1)
def smooth(x):
    x=np.clip(x,0,1);return x*x*(3-2*x)
def sample(points):
    result=np.ones((len(points),4),np.float32)
    for off in range(0,len(points),4096):
        q=points[off:off+4096];ap=q[:,None,:]-a
        t=np.clip(np.einsum('ijk,jk->ij',ap,ab)/length2,0,1)
        ds=np.linalg.norm(ap-t[:,:,None]*ab,axis=2);idx=(ds/widths).argmin(1);rows=np.arange(len(q));d=ds[rows,idx];w=widths[idx]
        result[off:off+len(q),0]=1-smooth((d/(sc['core_half_width']*w)-.15)/.85)
        result[off:off+len(q),1]=1-smooth(d/(sc['damage_half_width']*w))
        result[off:off+len(q),2]=np.clip(f0[idx]+t[rows,idx]*(f1[idx]-f0[idx]),0,1)
    return result
marks=sample(p);normals=np.array([v.normal for v in mesh.vertices]);moved=p-normals*marks[:,1,None]*sc['recess_metres']
mesh.vertices.foreach_set('co',moved.astype(np.float32).ravel());mesh.update()
# Extract unchanged source textures by glTF role, not Blender image numbering.
data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);binary=data[28+length:]
pbr=doc['materials'][0]['pbrMetallicRoughness']
for name,role in [('red-base.png','baseColorTexture'),('red-orm.png','metallicRoughnessTexture')]:
    im=doc['images'][doc['textures'][pbr[role]['index']]['source']];assert im['mimeType']=='image/png'
    view=doc['bufferViews'][im['bufferView']];offset=view.get('byteOffset',0)
    (out/name).write_bytes(binary[offset:offset+view['byteLength']])
mat=mesh.materials[0].copy();mesh.materials[0]=mat;mat.name='RED_MINERAL - attached scar'
nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.get('Principled BSDF');output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
attr=mesh.color_attributes.new(name='Bake source position',type='FLOAT_COLOR',domain='POINT')
col=np.ones((len(p),4),np.float32);col[:,:3]=(p-lo)/(hi-lo);attr.data.foreach_set('color',col.ravel())
n=nodes.new('ShaderNodeAttribute');n.attribute_name=attr.name
em=nodes.new('ShaderNodeEmission');links.new(n.outputs['Color'],em.inputs['Color']);links.new(em.outputs[0],output.inputs['Surface'])
size=sc['mask_size'];mask=bpy.data.images.new('Red scar - linear core damage travel',width=size,height=size,alpha=True,float_buffer=True);mask.colorspace_settings.name='Non-Color'
target=nodes.new('ShaderNodeTexImage');target.image=mask;nodes.active=target
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1;scene.render.bake.margin=8
bpy.ops.object.select_all(action='DESELECT');host.select_set(True);bpy.context.view_layer.objects.active=host
bpy.ops.object.bake(type='EMIT')
texels=np.empty(size*size*4,np.float32);mask.pixels.foreach_get(texels)
positions=texels.reshape(-1,4)[:,:3]*(hi-lo)+lo
mask.pixels.foreach_set(sample(positions).ravel());mask.update();mask.filepath_raw=str((out/'red-scar.png').resolve());mask.file_format='PNG';mask.save();mask.pack()
nodes.remove(em);links.new(bsdf.outputs[0],output.inputs['Surface']);mesh.color_attributes.remove(attr)
separate=nodes.new('ShaderNodeSeparateColor');links.new(target.outputs['Color'],separate.inputs['Color'])
old_base=bsdf.inputs['Base Color'].links[0].from_socket
mix=nodes.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.009,.004,.002,1)
links.new(separate.outputs['Green'],mix.inputs[0]);links.new(old_base,mix.inputs[1]);links.new(mix.outputs[0],bsdf.inputs['Base Color'])
bump=nodes.new('ShaderNodeBump');bump.invert=True;bump.inputs['Distance'].default_value=sc['recess_metres'];bump.inputs['Strength'].default_value=.7
links.new(separate.outputs['Green'],bump.inputs['Height']);links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
# Save non-emissive PBR fallback. Godot binds light from native state explicitly.
bsdf.inputs['Emission Strength'].default_value=0
normal=bpy.data.images.new('Red fracture tangent normal',width=size,height=size,alpha=False)
normal.colorspace_settings.name='Non-Color'
normal_target=nodes.new('ShaderNodeTexImage');normal_target.image=normal;nodes.active=normal_target
bpy.ops.object.bake(type='NORMAL')
normal.filepath_raw=str((out/'red-normal.png').resolve());normal.file_format='PNG';normal.save();normal.pack()
def triangles(o):
    o.data.calc_loop_triangles();return len(o.data.loop_triangles)
def export(objects,name):
    bpy.ops.object.select_all(action='DESELECT')
    if name.startswith('red-source-') or name.startswith('red-fragment-'):
        assert len(objects)==1
        floor=min(v.co.z for v in objects[0].data.vertices)
        for v in objects[0].data.vertices:v.co.z-=floor
        objects[0].data.update()
    for o in objects:o.hide_set(False);o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str((out/name).resolve()),export_format='GLB',use_selection=True,export_animations=False)
def copy(o,name):
    n=o.copy();n.data=o.data.copy();n.name=name;bpy.context.collection.objects.link(n);return n
report={'source_sha256':cfg['source_sha256'],'bounds_blender_xyz':[lo.tolist(),hi.tolist()],'qem_base_correction_m':ground_shift,'projected_paths':paths,'max_incision_m':float(np.linalg.norm(p-moved,axis=1).max()),'lods':{},'fragments':{}}
for target_count,name in zip(cfg['lod_triangles'],['near','mid','far']):
    lod=host if name=='near' else copy(host,'Red inclusion - '+name)
    if name!='near':
        bpy.context.view_layer.objects.active=lod
        dec=lod.modifiers.new('Distance reduction','DECIMATE');dec.ratio=target_count/triangles(lod);bpy.ops.object.modifier_apply(modifier=dec.name)
    export([lod],'red-source-'+name+'.glb');report['lods'][name]=triangles(lod)
    if name!='near':lod.hide_set(True);lod.hide_render=True

def material(name,color,metallic=0.,rough=.85):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(*color,1);s.inputs['Metallic'].default_value=metallic;s.inputs['Roughness'].default_value=rough
    return m
salt_cut=material('RED_CUT - fresh ceramic salt face',(.16,.037,.018),.05,.87)
def bake_fragment(piece,index):
    """Bake through a surrounding cage; never interpolate across source UV islands."""
    bpy.ops.object.select_all(action='DESELECT');piece.select_set(True);bpy.context.view_layer.objects.active=piece
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.022);bpy.ops.object.mode_set(mode='OBJECT')
    fm=material('RED_FRAGMENT - '+str(index+1),(.15,.04,.02));piece.data.materials.clear();piece.data.materials.append(fm)
    for f in piece.data.polygons:f.material_index=0
    fn=fm.node_tree.nodes;fl=fm.node_tree.links;fs=fn.get('Principled BSDF')
    source_nodes=mat.node_tree.nodes;source_links=mat.node_tree.links;source_output=next(n for n in source_nodes if n.type=='OUTPUT_MATERIAL');source_bsdf=source_nodes.get('Principled BSDF')
    host.hide_render=False;host.hide_set(False);host.select_set(True)
    scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.9;scene.render.bake.max_ray_distance=1.8;scene.render.bake.margin=8
    images={}
    for kind in ['base','orm','scar','normal']:
        im=bpy.data.images.new('Fragment %d %s'%(index+1,kind),width=1024,height=1024,alpha=False)
        im.colorspace_settings.name='sRGB' if kind=='base' else 'Non-Color'
        target_node=fn.new('ShaderNodeTexImage');target_node.image=im;fn.active=target_node
        if kind!='normal':
            texture=source_nodes.new('ShaderNodeTexImage');texture.image=bpy.data.images.load(str((out/('red-'+kind+'.png')).resolve()),check_existing=True)
            texture.image.colorspace_settings.name='sRGB' if kind=='base' else 'Non-Color'
            emitter=source_nodes.new('ShaderNodeEmission');source_links.new(texture.outputs['Color'],emitter.inputs['Color']);source_links.new(emitter.outputs[0],source_output.inputs['Surface'])
        bpy.ops.object.bake(type='NORMAL' if kind=='normal' else 'EMIT')
        if kind!='normal':
            source_nodes.remove(emitter);source_nodes.remove(texture);source_links.new(source_bsdf.outputs[0],source_output.inputs['Surface'])
        im.filepath_raw=str((out/('fragment-%d-%s.png'%(index+1,kind))).resolve());im.file_format='PNG';im.save();im.pack();images[kind]=im
    scene.render.bake.use_selected_to_active=False
    base_node=fn.new('ShaderNodeTexImage');base_node.image=images['base'];fl.new(base_node.outputs['Color'],fs.inputs['Base Color'])
    orm_node=fn.new('ShaderNodeTexImage');orm_node.image=images['orm'];split=fn.new('ShaderNodeSeparateColor');fl.new(orm_node.outputs['Color'],split.inputs['Color']);fl.new(split.outputs['Green'],fs.inputs['Roughness']);fl.new(split.outputs['Blue'],fs.inputs['Metallic'])
    normal_node=fn.new('ShaderNodeTexImage');normal_node.image=images['normal'];normal_map=fn.new('ShaderNodeNormalMap');normal_map.inputs['Strength'].default_value=.7;fl.new(normal_node.outputs['Color'],normal_map.inputs['Color']);fl.new(normal_map.outputs['Normal'],fs.inputs['Normal'])
    # Keep the scar atlas packed; Godot selects native claim/ownership light.
    scar_node=fn.new('ShaderNodeTexImage');scar_node.image=images['scar'];scar_node.label='Native-state scar atlas'
pieces=[]
# Actual slices of the source retain its outer texture, UVs and attached mask.
# Cap material records newly exposed fracture, distinct from the old outer host.
for index,(center,size) in enumerate([((-.36,-.19,.50),(.30,.27,.33)),((.045,.09,.57),(.28,.23,.27)),((.21,.13,.54),(.26,.24,.28))]):
    piece=copy(host,'Red Salt - cut fragment '+str(index+1));piece.data.materials.append(salt_cut)
    bpy.ops.mesh.primitive_cube_add(size=1,location=center);cutter=bpy.context.object;cutter.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    cutter.data.materials.append(mat);cutter.data.materials.append(salt_cut)
    for f in cutter.data.polygons:f.material_index=1
    bpy.context.view_layer.objects.active=piece
    boolean=piece.modifiers.new('Actual source fracture cut','BOOLEAN');boolean.operation='INTERSECT';boolean.solver='EXACT';boolean.object=cutter
    bpy.ops.object.modifier_apply(modifier=boolean.name);bpy.data.objects.remove(cutter,do_unlink=True)
    assert len(piece.data.vertices)>20,('Empty source cut',index)
    # The generated host is an exterior surface, not a closed geological solid.
    # Boolean clipping alone leaves papery open shells. A convex fragment closes
    # the cut volume; retained outer triangles keep exact source UVs. New fracture
    # faces use the separate opaque salt material, never transparent ribbons.
    old_uv=piece.data.uv_layers.active.data
    old_faces={frozenset(f.vertices):{piece.data.loops[i].vertex_index:tuple(old_uv[i].uv) for i in f.loop_indices} for f in piece.data.polygons if f.material_index==0}
    bm=bmesh.new();source_index=bm.verts.layers.int.new('Original surface vertex')
    for i,v in enumerate(piece.data.vertices):bm.verts.new(v.co)[source_index]=i
    hull=bmesh.ops.convex_hull(bm,input=list(bm.verts),use_existing_faces=False)
    discard=list({e for e in hull['geom_interior']+hull['geom_unused'] if isinstance(e,bmesh.types.BMVert) and e.is_valid})
    if discard:bmesh.ops.delete(bm,geom=discard,context='VERTS')
    uv_layer=bm.loops.layers.uv.new('UVMap')
    for f in bm.faces:
        original_face=old_faces.get(frozenset(v[source_index] for v in f.verts))
        f.material_index=0 if original_face else 1
        f.smooth=bool(original_face)
        if original_face:
            for loop in f.loops:loop[uv_layer].uv=original_face[loop.vert[source_index]]
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),('Unclosed salt fragment',index)
    assert abs(bm.calc_volume())>.0001,('Zero-volume salt fragment',index)
    bm.to_mesh(piece.data);bm.free()
    # Give each solid its own atlas before moving its pivot. Source UV charts
    # cannot be interpolated safely onto these new fracture faces. Bake the
    # mineral and attached scar from the actual host through a surrounding cage.
    bpy.context.view_layer.objects.active=piece
    detail=piece.modifiers.new('Solid fracture surface samples','SUBSURF');detail.subdivision_type='SIMPLE';detail.levels=2
    bpy.ops.object.modifier_apply(modifier=detail.name)
    bake_fragment(piece,index)
    p2=np.array([v.co for v in piece.data.vertices]);minimum=p2.min(0);maximum=p2.max(0)
    shift=np.array([(minimum[0]+maximum[0])/2,(minimum[1]+maximum[1])/2,minimum[2]])
    piece.data.vertices.foreach_set('co',(p2-shift).astype(np.float32).ravel());piece.data.update()
    dec=piece.modifiers.new('Pocket fragment detail','DECIMATE');dec.ratio=min(1,1800/triangles(piece));bpy.ops.object.modifier_apply(modifier=dec.name)
    export([piece],'red-fragment-'+str(index+1)+'.glb')
    report['fragments'][str(index+1)]={'triangles':triangles(piece),'source_cut_center':center,'source_cut_bounds':size,'source_shift':shift.tolist(),'result_bounds':(maximum-minimum).tolist(),'closed_volume':True,'texture_transfer':'Independent 1024px base/ORM/scar/normal atlases baked from the actual host with a surrounding cage'}
    pieces.append(piece);piece.hide_render=True;piece.hide_set(True)

# Precisely fitting player-built buffer: hammered frame, ceramic chamber,
# clamped source mineral and four inspection recesses. No new machine or ports.
iron=material('Forged iron',(.045,.047,.044),.72,.62)
edge=material('Worn iron edges',(.115,.10,.082),.72,.52)
ceramic=material('Heat-stained ceramic',(.12,.066,.041),0,.92)
timber=material('Charred timber',(.075,.047,.027),0,.96)
rivet=material('Peened bronze fasteners',(.23,.115,.049),.67,.58)
dark=material('Dark inspection recess',(.008,.005,.004),0,1)
parts=[]
def cube(name,at,size,mat,bevel=.014):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
    if bevel:
        b=o.modifiers.new('Forged softened edges','BEVEL');b.width=bevel;b.segments=2
        bpy.ops.object.modifier_apply(modifier=b.name)
        n=o.modifiers.new('Weighted faces','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=n.name)
    parts.append(o);return o
def bolt(at):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=1,location=at);o=bpy.context.object;o.name='Peened rivet';o.scale=(.026,.016,.026);o.data.materials.append(rivet);parts.append(o)
for x in [-.33,.33]:
    for y in [-.33,.33]:
        cube('Timber foot',(x,y,.20),(.18,.18,.40),timber)
        cube('Iron foot shoe',(x,y,.055),(.23,.23,.11),iron)
cube('Base hearth plate',(0,0,.26),(.96,.96,.15),iron,.025)
cube('Ceramic chamber',(0,0,.61),(.72,.70,.60),ceramic,.045)
for z in [.40,.78]:
    cube('Hammered front band',(0,-.367,z),(.81,.055,.095),iron)
    cube('Hammered back band',(0,.367,z),(.81,.055,.095),iron)
    for x in [-.39,.39]:cube('Hammered side band',(x,0,z),(.055,.75,.095),iron)
    for x in [-.29,.29]:bolt((x,-.405,z))
for x in [-.30,.30]:
    cube('Frame upright',(x,0,.73),(.075,.09,.85),iron)
    inner_x=math.copysign(.17,x)
    contact,_,_,_=bvh.ray_cast(Vector((inner_x/.37,0,2)),Vector((0,0,-1)),4)
    assert contact is not None
    start=Vector((x,0,1.14));end=Vector((inner_x,0,.825+contact.z*.38))
    jaw=cube('Fitted angled mineral jaw',(start+end)*.5,(.075,.20,(end-start).length+.025),edge)
    jaw.rotation_euler.y=math.atan2(end.x-start.x,end.z-start.z)
for x in [-.25,-.085,.085,.25]:
    cube('Inspection iron lip',(x,-.37,.585),(.135,.065,.235),edge,.012)
    cube('Inspection dark well',(x,-.407,.585),(.040,.019,.174),dark,.006)
cube('Thermal outlet collar',(0,.407,.85),(.28,.16,.22),iron)
cube('Thermal outlet interior',(0,.491,.85),(.17,.012,.11),dark,.004)
# Central crystal is a reduced copy of the same source; presentation transforms
# fit it inside the original inclusion slot. It is not a collectable item.
core=copy(host,'RED_CORE - fitted inclusion');core.scale=(.37,.37,.38);core.location=(0,0,.825)
parts.append(core)
bpy.context.view_layer.update()
for o in parts:
    if o.type=='MESH':
        for v in o.data.vertices:
            co=o.matrix_world@v.co
            assert abs(co.x)<=.5+1e-5 and abs(co.y)<=.5+1e-5 and -.00001<=co.z<=1.2+1e-5,('Buffer outside native body',o.name,co)
# Join the fixed housing into one object while preserving its material slots.
housing=[o for o in parts if o!=core]
bpy.ops.object.select_all(action='DESELECT')
for o in housing:o.select_set(True)
bpy.context.view_layer.objects.active=housing[0];bpy.ops.object.join();housing=[bpy.context.object];housing[0].name='BUFFER_HOUSING - paid crafted frame'
# Editable material wear, baked once to a single runtime PBR surface. The iron
# remains worked metal; the ceramic chamber and vertical timber grain stay
# distinct. Fine detail is texture, not thousands of decorative objects.
h=housing[0]
for m in h.data.materials:
    nt=m.node_tree;nodes_=nt.nodes;links_=nt.links;s=nodes_.get('Principled BSDF')
    base=s.inputs['Base Color'].default_value[:]
    tex=nodes_.new('ShaderNodeTexCoord')
    mapping=nodes_.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY'
    mapping.inputs[1].default_value=(75,75,4) if m==timber else (1,1,1)
    links_.new(tex.outputs['Generated'],mapping.inputs[0])
    noise=nodes_.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=2.0 if m==timber else 42.0;noise.inputs['Detail'].default_value=4
    links_.new(mapping.outputs[0],noise.inputs['Vector'])
    ramp=nodes_.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.23;ramp.color_ramp.elements[0].color=tuple(float(c)*.43 for c in base[:3])+(1,)
    ramp.color_ramp.elements[1].position=.78;ramp.color_ramp.elements[1].color=tuple(min(1,float(c)*1.65+.006) for c in base[:3])+(1,)
    links_.new(noise.outputs['Fac'],ramp.inputs['Fac']);links_.new(ramp.outputs['Color'],s.inputs['Base Color'])
    bump_=nodes_.new('ShaderNodeBump');bump_.inputs['Distance'].default_value=.014 if m==timber else .006;bump_.inputs['Strength'].default_value=.30
    links_.new(noise.outputs['Fac'],bump_.inputs['Height']);links_.new(bump_.outputs['Normal'],s.inputs['Normal'])
bpy.ops.object.select_all(action='DESELECT');h.select_set(True);bpy.context.view_layer.objects.active=h
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.012);bpy.ops.object.mode_set(mode='OBJECT')
maps={}
for kind,socket in [('base','Base Color'),('rough','Roughness'),('metal','Metallic'),('normal','Normal')]:
    im=bpy.data.images.new('Buffer '+kind+' baked',width=2048,height=2048,alpha=False)
    im.colorspace_settings.name='sRGB' if kind=='base' else 'Non-Color'
    temporary=[]
    for m in h.data.materials:
        nt=m.node_tree;nodes_=nt.nodes;links_=nt.links;s=nodes_.get('Principled BSDF');o=next(n for n in nodes_ if n.type=='OUTPUT_MATERIAL')
        target_=nodes_.new('ShaderNodeTexImage');target_.image=im;nodes_.active=target_
        if kind!='normal':
            em_=nodes_.new('ShaderNodeEmission')
            if s.inputs[socket].is_linked:links_.new(s.inputs[socket].links[0].from_socket,em_.inputs['Color'])
            else:
                value=s.inputs[socket].default_value
                em_.inputs['Color'].default_value=tuple(value) if kind=='base' else (value,value,value,1)
            links_.new(em_.outputs[0],o.inputs['Surface']);temporary.append((m,em_,o,s))
    scene.cycles.samples=1;bpy.ops.object.bake(type='NORMAL' if kind=='normal' else 'EMIT')
    for m,em_,o,s in temporary:m.node_tree.nodes.remove(em_);m.node_tree.links.new(s.outputs[0],o.inputs['Surface'])
    maps[kind]=im
    if kind in ['base','normal']:
        im.filepath_raw=str((out/('buffer-'+kind+'.png')).resolve());im.file_format='PNG';im.save();im.pack()
rough_pixels=np.empty(2048*2048*4,np.float32);metal_pixels=np.empty_like(rough_pixels)
maps['rough'].pixels.foreach_get(rough_pixels);maps['metal'].pixels.foreach_get(metal_pixels)
orm_pixels=np.ones((2048*2048,4),np.float32);orm_pixels[:,1]=rough_pixels.reshape(-1,4)[:,0];orm_pixels[:,2]=metal_pixels.reshape(-1,4)[:,0]
orm=bpy.data.images.new('Buffer ORM baked',width=2048,height=2048,alpha=False);orm.colorspace_settings.name='Non-Color';orm.pixels.foreach_set(orm_pixels.ravel())
orm.filepath_raw=str((out/'buffer-orm.png').resolve());orm.file_format='PNG';orm.save();orm.pack()
baked=material('BUFFER_PBR - worn forged housing',(.1,.1,.1));nodes_=baked.node_tree.nodes;links_=baked.node_tree.links;s=nodes_.get('Principled BSDF')
base_node=nodes_.new('ShaderNodeTexImage');base_node.image=maps['base'];links_.new(base_node.outputs['Color'],s.inputs['Base Color'])
orm_node=nodes_.new('ShaderNodeTexImage');orm_node.image=orm;channels=nodes_.new('ShaderNodeSeparateColor');links_.new(orm_node.outputs['Color'],channels.inputs['Color']);links_.new(channels.outputs['Green'],s.inputs['Roughness']);links_.new(channels.outputs['Blue'],s.inputs['Metallic'])
normal_node=nodes_.new('ShaderNodeTexImage');normal_node.image=maps['normal'];normal_map=nodes_.new('ShaderNodeNormalMap');normal_map.inputs['Strength'].default_value=.7;links_.new(normal_node.outputs['Color'],normal_map.inputs['Color']);links_.new(normal_map.outputs['Normal'],s.inputs['Normal'])
editable=copy(h,'SOURCE - editable procedural housing');editable.hide_render=True;editable.hide_set(True)
h.data.materials.clear();h.data.materials.append(baked)
for f in h.data.polygons:f.material_index=0
export(housing+[core],'red-buffer-near.glb')
report['buffer']={'housing_triangles':triangles(housing[0]),'core_triangles':triangles(core),'body_godot_xyz':cfg['buffer_body'],'port_height':cfg['port_height']}
# Smaller core meshes retain the authored mask and housing body.
for name,ratio in [('mid',.285),('far',.0595)]:
    c=copy(core,'RED_CORE - '+name);bpy.context.view_layer.objects.active=c
    d=c.modifiers.new('Core distance reduction','DECIMATE');d.ratio=ratio;bpy.ops.object.modifier_apply(modifier=d.name)
    export(housing+[c],'red-buffer-'+name+'.glb');report['buffer'][name+'_core_triangles']=triangles(c)
    c.hide_render=True;c.hide_set(True)
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
scene['study']='ART-04 Red isolated handoff; native rules/body/ownership unchanged'
(out/'asset-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str((out/'red-workshop.blend').resolve()),compress=True)
assert hashlib.sha256(raw.read_bytes()).hexdigest()==cfg['source_sha256']
print('ART04_ASSETS_FINISHED')
