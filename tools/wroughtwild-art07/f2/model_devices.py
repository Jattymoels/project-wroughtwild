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
def export_group(root,path):
    # Collapse immobile pieces to material surfaces without losing motion pivots.
    for parent in [root]+[c for c in root.children_recursive if c.type=='EMPTY']:
        meshes=[c for c in parent.children if c.type=='MESH']
        if len(meshes)>1:
            bpy.ops.object.select_all(action='DESELECT')
            for o in meshes:o.select_set(True)
            bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();meshes[0].name='Housing' if parent==root else 'MovingAssembly'
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for o in root.children_recursive:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_animations=False)
def audit(root):
    coords=[];tris=0;surfaces=0;deg=0
    for o in root.children_recursive:
        if o.type!='MESH':continue
        ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles();tris+=len(me.loop_triangles);surfaces+=len(set(f.material_index for f in me.polygons));deg+=sum(t.area<1e-12 for t in me.loop_triangles);coords.extend(o.matrix_world@ve.co for ve in me.vertices);ev.to_mesh_clear()
    lo=[min(p[i] for p in coords) for i in range(3)];hi=[max(p[i] for p in coords) for i in range(3)]
    return {'triangles':tris,'surfaces':surfaces,'degenerate':deg,'blender_min':lo,'blender_max':hi,'godot_size':[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]]}
def setup_render():
    s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=32;s.render.resolution_x=1440;s.render.resolution_y=1000;s.render.resolution_percentage=100;s.world.color=(.2,.2,.2)
    for at,power,size in [((3,-4,5),900,4),((-3,-1,3),650,3),((0,4,4),1000,3)]:
        bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(3,-4,2.8));s.camera=bpy.context.object;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=3.5
    return s
def render(root,out,s):
    target=v((0,.9,0)) if root.name in ['Winch','Landing'] else v((0,.2,0))
    s.camera.data.ortho_scale=3.5 if root.name in ['Winch','Landing'] else 1.2
    for name,at in [('front',(0,-4,1.4)),('back',(0,4,1.4)),('side',(4,0,1.4)),('three-quarter',(3,-4,2.7)),('top',(0,0,5)),('underside',(2,-3,-2))]:
        s.camera.location=at;s.camera.rotation_euler=(target-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(out/(root.name+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
def main():
    global WOOD_END
    out=Path(sys.argv[sys.argv.index('--')+1]).resolve();assert out.is_relative_to(ROOT/'build/art07/f2');out.mkdir(parents=True,exist_ok=False)
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    wood=textured('D4 Timber',D4/'review/textures','d4_wood_face');iron=textured('D6 Iron',D6/'review/textures','d6_iron',1)
    WOOD_END=textured('D4 Timber cut end',D4/'review/textures','d4_wood_edge')
    rootmat=textured('Thrumroot bark',D4/'review/textures','d4_bog_oak_face');scar=material('Thrumroot living incision',(.045,.07,.035),.85)
    scar.node_tree.nodes.get('Principled BSDF').inputs['Emission Color'].default_value=(.16,.23,.13,1);scar.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.05
    allroots=[]
    for landing in [False,True]:
        base=empty('Landing' if landing else 'Winch');allroots.append(base)
        for x in [-.52,.52]:
            box('SledFoot',(x,.065,0),(.22,.13,1.02),wood,base)
            box('Upright',(x,.94,-.27),(.16,1.75,.19),wood,base)
            for z in [-.31,.31]:
                a=(x,.14,z);b=(x,.60,-.27)
                o=box('Diagonal knee',tuple((a[k]+b[k])/2 for k in range(3)),(.10,(v(b)-v(a)).length,.11),wood,base);o.rotation_euler=(v(b)-v(a)).to_track_quat('Z','Y').to_euler()
            for y in [.22,1.13,1.49]:
                box('Iron collar',(x,y,-.27),(.19,.065,.22),iron,base,.003)
                cylinder('Peened pin',(x,y,-.153),(x,y,-.131),.026,iron,12,base)
            if not landing:
                box('Bearing cantilever',(x,1.05,-.13),(.115,.085,.31),iron,base,.004)
        box('Ground tie',(0,.105,.0),(1.17,.12,.15),wood,base)
        box('Guide bridge',(0,1.78,-.27),(1.18,.075,.23),wood,base)
        box('Guide cantilever',(0,1.775,-.135),(.085,.06,.34),iron,base,.004)
        cylinder('Guide pendant',(0,1.755,0),(0,1.735,0),.018,iron,12,base)
        # Guide aperture axis X meets native (0,1.7,0), not a decorative offset.
        for x in [-.025,.025]:
            bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=6,location=v((x,1.70,0)),major_radius=.035,minor_radius=.009)
            o=bpy.context.object;o.name='Cable eye';o.rotation_euler=(0,math.pi/2,0);o.data.materials.append(iron);parent_keep(o,base)
        socket=empty('CableSocket',(0,1.7,0));parent_keep(socket,base)
        if not landing:
            drum=empty('Drum',(0,1.05,0));parent_keep(drum,base)
            cylinder('Spindle',(-.64,1.05,0),(.64,1.05,0),.038,iron,20,drum)
            cylinder('Wood barrel',(-.39,1.05,0),(.39,1.05,0),.091,wood,24,drum)
            for x in [-.41,.41]:cylinder('Drum flange',(x-.014,1.05,0),(x+.014,1.05,0),.18,iron,32,drum)
            pts=[]
            for i in range(529):
                t=i/528;angle=t*11*math.tau;pts.append((-.375+.75*t,1.05+math.sin(angle)*.119,math.cos(angle)*.119))
            root_tube('Recovered root winding',pts,.027,rootmat,scar,.012,16,drum)
            for i in [38,122,231,329,451]:
                a=pts[i];end=(a[0]+.045,a[1]+.013,a[2]*1.13)
                root_tube('Attached root spur',[a,tuple((a[k]+end[k])/2 for k in range(3)),end],.009,rootmat,scar,.003,8,drum)
            # Crank rotates around the same native X pivot; full swept bound < body.
            cylinder('Crank arm',(.62,1.05,0),(.62,.81,0),.025,iron,12,drum)
            cylinder('Hand grip',(.61,.81,0),(.68,.81,0),.035,wood,16,drum)
        else:
            for x in [-.28,.28]:box('Empty cradle shoulder',(x,1.15,0),(.075,.12,.48),wood,base)
            box('Empty cradle floor',(0,1.20,0),(.62,.045,.49),wood,base)
        export_group(base,out/(base.name.lower()+'.glb'))
    basket=empty('Basket');allroots.append(basket)
    box('Basket floor',(0,.025,0),(.50,.05,.40),wood,basket,.004)
    for x in [-.24,.24]:
        for z in [-.19,.19]:box('Basket stake',(x,.155,z),(.025,.29,.025),wood,basket,.003)
    for j in range(6):
        h=.065+j*.042
        for z in [-.203,.203]:box('Slat',(0,h,z),(.52,.027,.018),wood,basket,.002)
        for x in [-.253,.253]:box('Slat',(x,h,0),(.018,.027,.41),wood,basket,.002)
    for x in [-.22,.22]:cylinder('Basket suspension',(x,.285,0),(0,.435,0),.009,iron,8,basket)
    cylinder('Hanger shoe',(-.025,.435,0),(.025,.435,0),.014,iron,10,basket)
    # Native sweep is a radius-.3 sphere centred .20 above basket origin.
    # Keep every corner and hanger inside the existing gameplay clearance.
    for o in basket.children_recursive:
        if o.type!='MESH':continue
        world=o.matrix_world.copy()
        for ve in o.data.vertices:
            co=world@ve.co;co.x*=.72;co.y*=.72
            if co.z<.30:co.z=.025+.85*co.z
            else:co.z=.28+(co.z-.30)*(.16862/.14862)
            ve.co=world.inverted()@co
    bpy.context.view_layer.update()
    sweep_radius=max((o.matrix_world@ve.co-Vector((0,0,.2))).length for o in basket.children_recursive if o.type=='MESH' for ve in o.data.vertices)
    assert sweep_radius<=.3,sweep_radius
    export_group(basket,out/'basket.glb')
    coil=empty('RecoveredCoil');allroots.append(coil)
    pts=[(.16*math.cos(i/240*math.tau*3),.04+.13*i/240,.16*math.sin(i/240*math.tau*3)) for i in range(241)]
    root_tube('Closed recovered tendon',pts,.034,rootmat,scar,.014,16,coil);export_group(coil,out/'recovered-coil.glb')
    report={o.name:audit(o) for o in allroots}
    for o in allroots:
        assert report[o.name]['degenerate']==0,report[o.name]
    for name in ['Winch','Landing']:
        assert all(a<=b+.002 for a,b in zip(report[name]['godot_size'],[1.4,1.83,1.15])),report[name]
    report['contracts']={'device_body_m':[1.4,1.83,1.15],'cable_socket':[0,1.7,0],'drum_pivot':[0,1.05,0],'drum_axis':'Godot X','basket_base_offset_from_cable':[0,-.45,0],'root_groove_depth_m':[.012,.014],'lod':'same bounded mechanism geometry; shared mipmapped maps'}
    (out/'geometry.json').write_text(json.dumps(report,indent=2)+'\n')
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'f2-devices.blend'))
    s=setup_render()
    for o in allroots:
        for other in allroots:
            for child in other.children_recursive:child.hide_render=other!=o
        render(o,out,s)
    print('F2_DEVICES_OK',report)
if __name__=='__main__':main()
