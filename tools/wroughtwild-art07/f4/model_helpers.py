"""Metric F2 mechanisms. Blender source; no game/collision/economy edits.
Run Blender --background --threads 8 --python-exit-code 1 --python THIS -- OUTPUT.
Coordinates in recipes are Godot XYZ metres; conversion occurs exactly once.
"""
import bpy,math,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[3]
WOOD_END=None
D4=Path('C:/Users/Matty/Dev/project-wroughtwild-art07-d4/build/art07/d4/h04')
D6=Path('C:/Users/Matty/Dev/project-wroughtwild/build/art07/d6/worktree/build/art07/d6/v04/handoff')
def v(p):return Vector((p[0],-p[2],p[1]))
def material(name,colour,rough=.8,metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*colour,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
def textured(name,folder,prefix,metal=0):
    m=material(name,(.35,.25,.15),.8,metal);n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
    for suffix in ['albedo','normal','orm']:
        img=bpy.data.images.load(str(folder/(prefix+'_'+suffix+'.png')),check_existing=True)
        img.colorspace_settings.name='sRGB' if suffix=='albedo' else 'Non-Color'
        t=n.new('ShaderNodeTexImage');t.image=img
        if suffix=='albedo':l.new(t.outputs['Color'],p.inputs['Base Color'])
        elif suffix=='normal':
            normal=n.new('ShaderNodeNormalMap');l.new(t.outputs['Color'],normal.inputs['Color']);l.new(normal.outputs[0],p.inputs['Normal'])
        else:
            sep=n.new('ShaderNodeSeparateColor');l.new(t.outputs['Color'],sep.inputs[0]);l.new(sep.outputs['Green'],p.inputs['Roughness']);l.new(sep.outputs['Blue'],p.inputs['Metallic'])
    return m
def uv_metric(o):
    # Stable planar projection on each face; one UV layer, 0.5 m repeat.
    me=o.data;uv=me.uv_layers.new(name='Metric') if not me.uv_layers else me.uv_layers[0]
    for f in me.polygons:
        normal=f.normal;axis=max(range(3),key=lambda i:abs(normal[i]));axes=[i for i in range(3) if i!=axis]
        for li in f.loop_indices:
            co=me.vertices[me.loops[li].vertex_index].co
            # Timber V follows vertical/local member length; repeat 2 m there.
            long=max(range(3),key=lambda k:o.dimensions[k])
            if o.get('timber',False):
                if axis==long:f.material_index=1
                else:axes=[k for k in axes if k!=long]+[long]
            uv.data[li].uv=(co[axes[0]]/.5,co[axes[1]]/(2 if o.get('timber',False) and axis!=long else .5))
def box(name,at,size,mat,parent=None,bevel=.007):
    bpy.ops.mesh.primitive_cube_add(size=1,location=v(at));o=bpy.context.object;o.name=name;o.dimensions=v((size[0],size[1],-size[2]));bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat);o['timber']=mat.name.startswith('D4')
    if o['timber'] and WOOD_END:o.data.materials.append(WOOD_END)
    uv_metric(o)
    if bevel:
        mod=o.modifiers.new('Hand dressed edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
        o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
    if parent:parent_keep(o,parent)
    return o
def parent_keep(o,p):
    bpy.context.view_layer.update()
    world=o.matrix_world.copy();o.parent=p;o.matrix_world=world
def cylinder(name,a,b,r,mat,segments=16,parent=None):
    a=v(a);b=v(b);d=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=r,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);uv_metric(o)
    bevel=o.modifiers.new('Forged edge','BEVEL');bevel.width=min(r*.15,.004);bevel.segments=2;bpy.ops.object.modifier_apply(modifier=bevel.name)
    if parent:parent_keep(o,parent)
    return o
def empty(name,at=(0,0,0)):
    o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=v(at);return o
def root_tube(name,points,r,mat,scar,depth=.012,segments=16,parent=None):
    # Closed swept tissue. Angular groove is part of its actual cross-section.
    # The four front-facing intervals descend into a broad recessed channel.
    pts=[v(p) for p in points];verts=[];faces=[];idx=[];uvs=[]
    for i,p in enumerate(pts):
        t=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        n=t.cross(Vector((0,0,1))).normalized()
        if n.length<.5:n=t.cross(Vector((0,1,0))).normalized()
        b=t.cross(n).normalized()
        for j in range(segments):
            angle=math.tau*j/segments
            dist=abs(math.atan2(math.sin(angle),math.cos(angle)))
            groove=max(0,1-dist/.68)
            rr=r*(1+.13*math.sin(i*.43)+.06*math.sin(j*2.4+i*.24))-depth*groove
            verts.append(p+(n*math.cos(angle)+b*math.sin(angle))*rr)
    for i in range(len(pts)-1):
        for j in range(segments):
            faces.append((i*segments+j,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,(i+1)*segments+j));idx.append(1 if j in [0,segments-1] and i%17 not in [0,1] else 0)
    faces.extend([tuple(reversed(range(segments))),tuple((len(pts)-1)*segments+j for j in range(segments))]);idx.extend([0,0])
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(mat);mesh.materials.append(scar)
    uv=mesh.uv_layers.new(name='RootLength')
    for f,mi in zip(mesh.polygons,idx):
        f.material_index=mi;f.use_smooth=True
        for li in f.loop_indices:
            vi=mesh.loops[li].vertex_index;uv.data[li].uv=((vi%segments)/segments,(vi//segments)/15)
    o['scar_depth_m']=depth;o['scar_is_geometry']=True
    if parent:parent_keep(o,parent)
    return o
