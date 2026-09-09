"""Blender: authored mineral surface, cut pieces, fitting, LODs and packed source.
Run with -- INSPECTED_SOURCE.blend RAW.glb FRESH_OUTPUT. No gameplay files.
"""
import bpy,bmesh,json,sys,hashlib,struct,math
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
source,raw,out=map(Path,sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(Path(__file__).with_name('green.json').read_text(encoding='utf-8'));sc=cfg['scar']
assert hashlib.sha256(raw.read_bytes()).hexdigest()==cfg['source_sha256']
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source.resolve()))
host=bpy.data.objects['Green inclusion - intact normalized source']
for o in list(bpy.context.scene.objects):
    if o!=host:bpy.data.objects.remove(o,do_unlink=True)
original=host.copy();original.data=host.data.copy();bpy.context.collection.objects.link(original)
original.name='SOURCE - untouched normalized Green inclusion';original.hide_set(True);original.hide_render=True
bpy.context.view_layer.objects.active=host;host.select_set(True)
bm=bmesh.new();bm.from_mesh(host.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002)
# Close the actual boundary loops without resampling or rounding the original
# geological planes. Small cap faces sample the nearest adjacent mineral chart;
# all existing surface positions and UVs survive this local repair unchanged.
from mathutils.kdtree import KDTree
bm.faces.ensure_lookup_table();uv_layer=bm.loops.layers.uv.active
tree=KDTree(len(bm.faces));cap_uv=[]
for i,f in enumerate(bm.faces):
    tree.insert(f.calc_center_median(),i);cap_uv.append(sum((l[uv_layer].uv.copy() for l in f.loops),Vector((0,0)))/len(f.loops))
tree.balance()
boundary=[e for e in bm.edges if e.is_boundary]
caps=bmesh.ops.holes_fill(bm,edges=boundary,sides=0)['faces']
for f in caps:
    _,i,_=tree.find(f.calc_center_median())
    for l in f.loops:l[uv_layer].uv=cap_uv[i]
bmesh.ops.triangulate(bm,faces=list(caps));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
cap_count=len(caps);bm.to_mesh(host.data);bm.free()
dec=host.modifiers.new('Near silhouette reduction','DECIMATE');dec.ratio=cfg['lod_triangles'][0]/len(host.data.polygons)
bpy.ops.object.modifier_apply(modifier=dec.name)
host.name='Green inclusion - ready worked or spent host';mesh=host.data
mesh.validate();mesh.update()
# QEM can move the lowest vertex fractions of a millimetre below the source
# pivot. Seat the finished mesh on zero before projecting the authored surface.
ground_shift=min(v.co.z for v in mesh.vertices)
for v in mesh.vertices:v.co.z-=ground_shift
mesh.update()
for f in mesh.polygons:f.use_smooth=True
p=np.array([v.co for v in mesh.vertices]);lo,hi=p.min(0),p.max(0)
bvh=BVHTree.FromPolygons([Vector(v) for v in p],[tuple(f.vertices) for f in mesh.polygons])
starts,ends,widths,flow0,flow1,paths,branches=[],[],[],[],[],[],[]
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
        flow0.append(path['offset']+travel[i]/travel[-1]*path['span']);flow1.append(path['offset']+travel[i+1]/travel[-1]*path['span']);branches.append(path['branch']*.5)
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
        result[off:off+len(q),3]=np.array(branches)[idx]
    return result
marks=sample(p);normals=np.array([v.normal for v in mesh.vertices]);moved=p-normals*marks[:,1,None]*sc['recess_metres']
mesh.vertices.foreach_set('co',moved.astype(np.float32).ravel());mesh.update()
# Preserve the actual source textures and original exterior UV charts.
data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);binary=data[28+length:]
pbr=doc['materials'][0]['pbrMetallicRoughness']
for name,role in [('green-base.png','baseColorTexture'),('green-orm.png','metallicRoughnessTexture')]:
    im=doc['images'][doc['textures'][pbr[role]['index']]['source']];assert im['mimeType']=='image/png'
    view=doc['bufferViews'][im['bufferView']];offset=view.get('byteOffset',0)
    (out/name).write_bytes(binary[offset:offset+view['byteLength']])
mat=mesh.materials[0].copy();mesh.materials[0]=mat;mat.name='GREEN_MINERAL - attached scar'
nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.get('Principled BSDF');output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
attr=mesh.color_attributes.new(name='Bake source position',type='FLOAT_COLOR',domain='POINT')
col=np.ones((len(p),4),np.float32);col[:,:3]=(p-lo)/(hi-lo);attr.data.foreach_set('color',col.ravel())
n=nodes.new('ShaderNodeAttribute');n.attribute_name=attr.name
em=nodes.new('ShaderNodeEmission');links.new(n.outputs['Color'],em.inputs['Color']);links.new(em.outputs[0],output.inputs['Surface'])
size=sc['mask_size'];mask=bpy.data.images.new('Green scar - linear core damage travel branch',width=size,height=size,alpha=True,float_buffer=True);mask.colorspace_settings.name='Non-Color';mask.alpha_mode='CHANNEL_PACKED'
target=nodes.new('ShaderNodeTexImage');target.image=mask;nodes.active=target
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1;scene.render.bake.margin=8
bpy.ops.object.select_all(action='DESELECT');host.select_set(True);bpy.context.view_layer.objects.active=host
bpy.ops.object.bake(type='EMIT')
texels=np.empty(size*size*4,np.float32);mask.pixels.foreach_get(texels)
positions=texels.reshape(-1,4)[:,:3]*(hi-lo)+lo
mask.pixels.foreach_set(sample(positions).ravel());mask.update();mask.filepath_raw=str((out/'green-scar.png').resolve());mask.file_format='PNG';mask.save();mask.pack()
nodes.remove(em);links.new(bsdf.outputs[0],output.inputs['Surface']);mesh.color_attributes.remove(attr)
separate=nodes.new('ShaderNodeSeparateColor');links.new(target.outputs['Color'],separate.inputs['Color'])
old_base=bsdf.inputs['Base Color'].links[0].from_socket
mix=nodes.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.008,.009,.008,1)
links.new(separate.outputs['Green'],mix.inputs[0]);links.new(old_base,mix.inputs[1]);links.new(mix.outputs[0],bsdf.inputs['Base Color'])
bump=nodes.new('ShaderNodeBump');bump.invert=True;bump.inputs['Distance'].default_value=sc['recess_metres'];bump.inputs['Strength'].default_value=.7
if bsdf.inputs['Normal'].is_linked:links.new(bsdf.inputs['Normal'].links[0].from_socket,bump.inputs['Normal'])
links.new(separate.outputs['Green'],bump.inputs['Height']);links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
# Save non-emissive PBR fallback. Godot binds light from native state explicitly.
bsdf.inputs['Emission Strength'].default_value=0
normal=bpy.data.images.new('Green fracture tangent normal',width=size,height=size,alpha=False)
normal.colorspace_settings.name='Non-Color'
normal_target=nodes.new('ShaderNodeTexImage');normal_target.image=normal;nodes.active=normal_target
bpy.ops.object.bake(type='NORMAL')
normal.filepath_raw=str((out/'green-normal.png').resolve());normal.file_format='PNG';normal.save();normal.pack()
def triangles(o):
    o.data.calc_loop_triangles();return len(o.data.loop_triangles)
def export(objects,name):
    bpy.ops.object.select_all(action='DESELECT')
    if name.startswith('green-source-') or name.startswith('green-fragment-'):
        assert len(objects)==1
        floor=min(v.co.z for v in objects[0].data.vertices)
        for v in objects[0].data.vertices:v.co.z-=floor
        objects[0].data.update()
    for o in objects:o.hide_set(False);o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str((out/name).resolve()),export_format='GLB',use_selection=True,export_animations=False)
def copy(o,name):
    n=o.copy();n.data=o.data.copy();n.name=name;bpy.context.collection.objects.link(n);return n
report={'source_sha256':cfg['source_sha256'],'bounds_blender_xyz':[lo.tolist(),hi.tolist()],'closed_boundary_loops':cap_count,'qem_base_correction_m':ground_shift,'projected_paths':paths,'max_incision_m':float(np.linalg.norm(p-moved,axis=1).max()),'lods':{},'fragments':{}}
for target_count,name in zip(cfg['lod_triangles'],['near','mid','far']):
    lod=host if name=='near' else copy(host,'Green inclusion - '+name)
    if name!='near':
        bpy.context.view_layer.objects.active=lod
        dec=lod.modifiers.new('Distance reduction','DECIMATE');dec.ratio=target_count/triangles(lod);bpy.ops.object.modifier_apply(modifier=dec.name)
    export([lod],'green-source-'+name+'.glb');report['lods'][name]=triangles(lod)
    if name!='near':lod.hide_set(True);lod.hide_render=True

def material(name,color,metallic=0.,rough=.85):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(*color,1);s.inputs['Metallic'].default_value=metallic;s.inputs['Roughness'].default_value=rough
    return m
# Temporary boolean-face marker inherited from the common family recipe.
# bake_fragment replaces every face with the final resin atlas/material.
salt_cut=material('GREEN_CUT - exposed slate face',(.028,.045,.07),.05,.87)
def bake_fragment(piece,index):
    """Per-texel nearest-triangle projection with chart-local barycentric UVs.
    A cage can miss newly exposed cut faces. Sampling the closest real triangle
    covers every face without mixing UVs from unrelated source atlas charts.
    Tangent normals are baked in the fragment's own UV frame afterward.
    """
    bpy.ops.object.select_all(action='DESELECT');piece.select_set(True);bpy.context.view_layer.objects.active=piece
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.022);bpy.ops.object.mode_set(mode='OBJECT')
    fm=material('GREEN_FRAGMENT - '+str(index+1),(.3,.28,.23));piece.data.materials.clear();piece.data.materials.append(fm)
    for f in piece.data.polygons:f.material_index=0;f.use_smooth=False
    fn=fm.node_tree.nodes;fl=fm.node_tree.links;fs=fn.get('Principled BSDF');fo=next(n for n in fn if n.type=='OUTPUT_MATERIAL')
    coords=np.array([v.co for v in piece.data.vertices]);vmin=coords.min(0);vmax=coords.max(0)
    attribute=piece.data.color_attributes.new(name='Fragment source position',type='FLOAT_COLOR',domain='POINT')
    values=np.ones((len(coords),4),np.float32);values[:,:3]=(coords-vmin)/(vmax-vmin);attribute.data.foreach_set('color',values.ravel())
    attr_node=fn.new('ShaderNodeAttribute');attr_node.attribute_name=attribute.name
    emitter=fn.new('ShaderNodeEmission');fl.new(attr_node.outputs['Color'],emitter.inputs['Color']);fl.new(emitter.outputs[0],fo.inputs['Surface'])
    resolution=1024;position_map=bpy.data.images.new('Fragment bake positions',width=resolution,height=resolution,alpha=True,float_buffer=True);position_map.colorspace_settings.name='Non-Color'
    target=fn.new('ShaderNodeTexImage');target.image=position_map;fn.active=target
    scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=8;bpy.ops.object.bake(type='EMIT')
    texels=np.empty(resolution*resolution*4,np.float32);position_map.pixels.foreach_get(texels)
    positions=texels.reshape(-1,4)[:,:3]*(vmax-vmin)+vmin
    nearest=[bvh.find_nearest(Vector(q)) for q in positions]
    assert all(n[0] is not None for n in nearest)
    points=np.array([n[0] for n in nearest]);face_index=np.array([n[2] for n in nearest])
    assert all(len(f.vertices)==3 for f in mesh.polygons)
    face_vertices=np.array([tuple(f.vertices) for f in mesh.polygons]);tris=p[face_vertices[face_index]]
    e0=tris[:,1]-tris[:,0];e1=tris[:,2]-tris[:,0];relative=points-tris[:,0]
    d00=(e0*e0).sum(1);d01=(e0*e1).sum(1);d11=(e1*e1).sum(1);d20=(relative*e0).sum(1);d21=(relative*e1).sum(1)
    denominator=np.maximum(d00*d11-d01*d01,1e-20)
    v=(d11*d20-d01*d21)/denominator;w=(d00*d21-d01*d20)/denominator
    uv_data=mesh.uv_layers.active.data
    triangle_uvs=np.array([[tuple(uv_data[i].uv) for i in f.loop_indices] for f in mesh.polygons])[face_index]
    source_uv=triangle_uvs[:,0]*(1-v-w)[:,None]+triangle_uvs[:,1]*v[:,None]+triangle_uvs[:,2]*w[:,None]
    source_uv=np.clip(source_uv,0,1)
    fn.remove(emitter);fn.remove(attr_node);fn.remove(target);bpy.data.images.remove(position_map);piece.data.color_attributes.remove(attribute);fl.new(fs.outputs[0],fo.inputs['Surface'])
    images={}
    for kind in ['base','orm','scar']:
        original_image=bpy.data.images.load(str((out/('green-'+kind+'.png')).resolve()),check_existing=True)
        original_image.colorspace_settings.name='sRGB' if kind=='base' else 'Non-Color'
        if kind=='scar':original_image.alpha_mode='CHANNEL_PACKED'
        sx,sy=original_image.size;pixels=np.empty(sx*sy*4,np.float32);original_image.pixels.foreach_get(pixels);pixels=pixels.reshape(sy,sx,4)
        xy=source_uv*np.array([sx-1,sy-1]);ij=np.floor(xy).astype(int);delta=xy-ij;upper=np.minimum(ij+1,np.array([sx-1,sy-1]))
        result=pixels[ij[:,1],ij[:,0]]*(1-delta[:,0,None])*(1-delta[:,1,None])+pixels[ij[:,1],upper[:,0]]*delta[:,0,None]*(1-delta[:,1,None])+pixels[upper[:,1],ij[:,0]]*(1-delta[:,0,None])*delta[:,1,None]+pixels[upper[:,1],upper[:,0]]*delta[:,0,None]*delta[:,1,None]
        exposed=np.clip(np.linalg.norm(points-positions,axis=1)/cfg['resin']['cut_transition_m'],0,1)
        if kind=='base':
            variation=.7+.6*np.clip(result[:,:3].mean(1),0,1)
            resin=np.array(cfg['resin']['cut_colour_linear'])[None,:]*variation[:,None]
            result[:,:3]=result[:,:3]*(1-exposed[:,None])+resin*exposed[:,None]
        elif kind=='orm':
            result[:,1]=result[:,1]*(1-exposed)+cfg['resin']['cut_roughness']*exposed;result[:,2]*=(1-exposed)
        im=bpy.data.images.new('Green fragment %d %s'%(index+1,kind),width=resolution,height=resolution,alpha=kind=='scar',float_buffer=kind=='scar')
        if kind=='scar':im.alpha_mode='CHANNEL_PACKED'
        im.colorspace_settings.name='sRGB' if kind=='base' else 'Non-Color';im.pixels.foreach_set(result.astype(np.float32).ravel());im.update()
        im.filepath_raw=str((out/('fragment-%d-%s.png'%(index+1,kind))).resolve());im.file_format='PNG';im.save();im.pack();images[kind]=im
    bn=fn.new('ShaderNodeTexImage');bn.image=images['base'];fl.new(bn.outputs['Color'],fs.inputs['Base Color'])
    on=fn.new('ShaderNodeTexImage');on.image=images['orm'];channels=fn.new('ShaderNodeSeparateColor');fl.new(on.outputs['Color'],channels.inputs['Color']);fl.new(channels.outputs['Green'],fs.inputs['Roughness']);fl.new(channels.outputs['Blue'],fs.inputs['Metallic'])
    scar_node=fn.new('ShaderNodeTexImage');scar_node.image=images['scar'];scar_node.label='Native-state scar atlas'
    separate=fn.new('ShaderNodeSeparateColor');fl.new(scar_node.outputs['Color'],separate.inputs['Color'])
    damage=fn.new('ShaderNodeBump');damage.invert=True;damage.inputs['Distance'].default_value=sc['recess_metres'];damage.inputs['Strength'].default_value=.7;fl.new(separate.outputs['Green'],damage.inputs['Height']);fl.new(damage.outputs['Normal'],fs.inputs['Normal'])
    normal=bpy.data.images.new('Green fragment own tangent normal',width=resolution,height=resolution,alpha=False);normal.colorspace_settings.name='Non-Color';normal_node=fn.new('ShaderNodeTexImage');normal_node.image=normal;fn.active=normal_node;bpy.ops.object.bake(type='NORMAL')
    normal.filepath_raw=str((out/('fragment-%d-normal.png'%(index+1))).resolve());normal.file_format='PNG';normal.save();normal.pack()
    normal_map=fn.new('ShaderNodeNormalMap');normal_map.inputs['Strength'].default_value=.7;fl.new(normal_node.outputs['Color'],normal_map.inputs['Color']);fl.new(normal_map.outputs['Normal'],fs.inputs['Normal'])
pieces=[]
# Actual slices of the source retain its outer texture, UVs and attached mask.
# Cap material records newly exposed fracture, distinct from the old outer host.
for index,(path_index,fraction) in enumerate([(0,.25),(1,.80),(2,.80)]):
    center=np.array(paths[path_index]['projected'][int(fraction*(len(paths[path_index]['projected'])-1))])+np.array([0,.018,0])
    center=center.tolist();size=(.23,.23,.23)
    piece=copy(host,'Green Mineral - cut fragment '+str(index+1));piece.data.materials.append(salt_cut)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=center);cutter=bpy.context.object;cutter.dimensions=size
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
    # faces receive a separate opaque resin atlas, never transparent ribbons.
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
    assert all(e.is_manifold for e in bm.edges),('Unclosed resin fragment',index)
    assert abs(bm.calc_volume())>.0001,('Zero-volume resin fragment',index)
    bm.to_mesh(piece.data);bm.free()
    # Give each solid its own atlas before moving its pivot. Source UV charts
    # cannot be interpolated safely onto these new fracture faces. Bake the
    # mineral and attached scar per texel within one real source triangle chart.
    bpy.context.view_layer.objects.active=piece
    # A small convex chip already has enough silhouette vertices. Subdivide /
    # decimate produced near-coincident slivers that opened after GLB UV weld.
    # Retain the closed hull; the independent atlas carries the fine detail.
    bake_fragment(piece,index)
    p2=np.array([v.co for v in piece.data.vertices]);minimum=p2.min(0);maximum=p2.max(0)
    shift=np.array([(minimum[0]+maximum[0])/2,(minimum[1]+maximum[1])/2,minimum[2]])
    piece.data.vertices.foreach_set('co',(p2-shift).astype(np.float32).ravel());piece.data.update()
    export([piece],'green-fragment-'+str(index+1)+'.glb')
    report['fragments'][str(index+1)]={'triangles':triangles(piece),'source_cut_center':center,'source_cut_bounds':size,'source_shift':shift.tolist(),'result_bounds':(maximum-minimum).tolist(),'closed_volume':True,'texture_transfer':'Independent 1024px atlases: per-texel closest triangle and barycentric chart UV from actual source, plus fragment-local tangent normals'}
    pieces.append(piece);piece.hide_render=True;piece.hide_set(True)

# Precisely fitting player-built post: timber mast, forged cradle/clamps and
# three joined resin solids. Both cables retain the native common anchor.
iron=material('Forged iron',(.045,.047,.044),.72,.62)
edge=material('Worn iron edges',(.115,.10,.082),.72,.52)
ceramic=material('Heat-stained ceramic',(.22,.20,.16),0,.92)
timber=material('Charred timber',(.11,.068,.035),0,.96)
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
# A supported resin Y uses the actual recovered solids and their own atlases.
cube('Broad timber foot',(0,0,.06),(.62,.52,.12),timber,.018)
cube('Timber mast',(0,.065,.41),(.17,.17,.66),timber,.012)
for z in [.17,.55]:
    cube('Forged mast collar',(0,.065,z),(.215,.215,.06),iron,.007);bolt((0,-.055,z))
cube('Resin stem cradle',(0,0,.655),(.21,.24,.055),iron,.007)
for side in [-1,1]:
    arm=cube('Fork backing',(side*.12,.08,.93),(.085,.13,.43),timber,.01);arm.rotation_euler.y=side*.47
    cube('Resin branch jaw',(side*.20,-.015,1.065),(.105,.21,.048),edge,.007)
    bolt((side*.20,-.13,1.065))
cube('Shared terminal bridge',(0,.045,1.142),(.50,.16,.044),iron,.006)
cube('Native cable anchor',(0,0,1.169),(.10,.10,.022),edge,.004)
cores=[]
for index,(at,dimensions,angle) in enumerate([((0,-.055,.6825),(.15,.16,.31),0),((-.015,-.055,.875),(.18,.16,.29),-.48),((.015,-.055,.875),(.18,.16,.29),.48)]):
    core=copy(pieces[index],'GREEN_CORE - '+['stem','first','second'][index]);core.hide_render=False;core.hide_set(False)
    core.rotation_mode='XYZ';core.rotation_euler=(0,0,0);core.dimensions=dimensions
    core.rotation_euler.y=angle;core.location=at;cores.append(core);parts.append(core)
bpy.context.view_layer.update()
for o in parts:
    if o.type=='MESH':
        for v in o.data.vertices:
            co=o.matrix_world@v.co
            assert abs(co.x)<=.325+1e-5 and abs(co.y)<=.275+1e-5 and -.00001<=co.z<=1.18+1e-5,('Post outside native body',o.name,co)
# Join the fixed housing into one object while preserving its material slots.
housing=[o for o in parts if o not in cores]
bpy.ops.object.select_all(action='DESELECT')
for o in housing:o.select_set(True)
bpy.context.view_layer.objects.active=housing[0];bpy.ops.object.join();housing=[bpy.context.object];housing[0].name='POST_HOUSING - paid crafted frame'
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
    im=bpy.data.images.new('Post '+kind+' baked',width=2048,height=2048,alpha=False)
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
        im.filepath_raw=str((out/('post-'+kind+'.png')).resolve());im.file_format='PNG';im.save();im.pack()
rough_pixels=np.empty(2048*2048*4,np.float32);metal_pixels=np.empty_like(rough_pixels)
maps['rough'].pixels.foreach_get(rough_pixels);maps['metal'].pixels.foreach_get(metal_pixels)
orm_pixels=np.ones((2048*2048,4),np.float32);orm_pixels[:,1]=rough_pixels.reshape(-1,4)[:,0];orm_pixels[:,2]=metal_pixels.reshape(-1,4)[:,0]
orm=bpy.data.images.new('Post ORM baked',width=2048,height=2048,alpha=False);orm.colorspace_settings.name='Non-Color';orm.pixels.foreach_set(orm_pixels.ravel())
orm.filepath_raw=str((out/'post-orm.png').resolve());orm.file_format='PNG';orm.save();orm.pack()
baked=material('POST_PBR - worn forged housing',(.1,.1,.1));nodes_=baked.node_tree.nodes;links_=baked.node_tree.links;s=nodes_.get('Principled BSDF')
base_node=nodes_.new('ShaderNodeTexImage');base_node.image=maps['base'];links_.new(base_node.outputs['Color'],s.inputs['Base Color'])
orm_node=nodes_.new('ShaderNodeTexImage');orm_node.image=orm;channels=nodes_.new('ShaderNodeSeparateColor');links_.new(orm_node.outputs['Color'],channels.inputs['Color']);links_.new(channels.outputs['Green'],s.inputs['Roughness']);links_.new(channels.outputs['Blue'],s.inputs['Metallic'])
normal_node=nodes_.new('ShaderNodeTexImage');normal_node.image=maps['normal'];normal_map=nodes_.new('ShaderNodeNormalMap');normal_map.inputs['Strength'].default_value=.7;links_.new(normal_node.outputs['Color'],normal_map.inputs['Color']);links_.new(normal_map.outputs['Normal'],s.inputs['Normal'])
editable=copy(h,'SOURCE - editable procedural housing');editable.hide_render=True;editable.hide_set(True)
h.data.materials.clear();h.data.materials.append(baked)
for f in h.data.polygons:f.material_index=0
for name in ['near','mid','far']:
    export(housing+cores,'green-post-'+name+'.glb')
report['post']={'housing_triangles':triangles(housing[0]),'core_triangles':sum(triangles(o) for o in cores),'body_godot_xyz':cfg['post_body'],'port_height':cfg['port_height'],'cores':[{'name':o.name,'height_local':float(max(v.co.z for v in o.data.vertices)),'triangles':triangles(o)} for o in cores],'note':'Three touching recovered solids share one crafted Y; already small, all three detail exports retain this geometry.'}
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
scene['study']='ART-04 Green isolated handoff; native rules/body/ownership unchanged'
(out/'asset-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str((out/'green-workshop.blend').resolve()),compress=True)
assert hashlib.sha256(raw.read_bytes()).hexdigest()==cfg['source_sha256']
print('ART04_ASSETS_FINISHED')
