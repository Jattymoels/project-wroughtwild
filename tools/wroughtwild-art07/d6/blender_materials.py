"""D6 direct modelling in metres. Exact-envelope material proxies, not game collision.
Usage: -- TEXTURES FRESH_OUT | -- --reopen MASTER FRESH_OUT
Review scaffolding derives from D4; every D6 mesh is authored here.
"""
import bpy, json, math, sys, time
from pathlib import Path
from mathutils import Vector

def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
def material(f,role,textures):
    m=bpy.data.materials.new('d6_'+f['id']+'_'+role);m.use_nodes=True
    ns=m.node_tree.nodes;links=m.node_tree.links;p=ns.get('Principled BSDF')
    p.inputs['Emission Strength'].default_value=0
    for kind in ['albedo','normal','orm']:
        t=ns.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(textures/f'd6_{f["id"]}_{kind}.png'),check_existing=True)
        t.image.colorspace_settings.name='sRGB' if kind=='albedo' else 'Non-Color'
        if kind=='albedo':
            if role=='seam':
                mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*f['seam_tint'],1)
                links.new(t.outputs['Color'],mix.inputs[1]);links.new(mix.outputs[0],p.inputs['Base Color'])
            else:links.new(t.outputs['Color'],p.inputs['Base Color'])
        elif kind=='normal':
            normal=ns.new('ShaderNodeNormalMap');links.new(t.outputs[0],normal.inputs['Color']);links.new(normal.outputs[0],p.inputs['Normal'])
        else:
            sep=ns.new('ShaderNodeSeparateColor');links.new(t.outputs[0],sep.inputs[0]);links.new(sep.outputs['Green'],p.inputs['Roughness'])
            mul=ns.new('ShaderNodeMath');mul.operation='MULTIPLY';mul.inputs[1].default_value=f['seam_metallic'] if role=='seam' else 1
            links.new(sep.outputs['Blue'],mul.inputs[0]);links.new(mul.outputs[0],p.inputs['Metallic'])
    return m

def uv(o):
    mesh=o.data;mesh.update()
    for old in list(mesh.uv_layers):mesh.uv_layers.remove(old)
    layer=mesh.uv_layers.new(name='D6_metric_half_metre')
    for p in mesh.polygons:
        normal=p.normal;axis=max(range(3),key=lambda k:abs(normal[k]));axes=[k for k in range(3) if k!=axis]
        u,v=axes;tu=Vector([int(k==u) for k in range(3)]);tv=Vector([int(k==v) for k in range(3)])
        sign=1 if tu.cross(tv).dot(normal)>0 else -1
        for li in p.loop_indices:
            co=mesh.vertices[mesh.loops[li].vertex_index].co
            layer.data[li].uv=(co[u]*2*sign,co[v]*2)

def box(name,loc,size,mat,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Worked arris','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(mat);uv(o);return o

def rivet(loc,f,mat):
    if f['id']=='steel':
        bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=f['rivet_radius_m'],depth=.009,location=loc,rotation=(math.pi/2,0,0))
    else:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=loc)
        bpy.context.object.scale=(f['rivet_radius_m'],.012 if f['id']=='iron' else .009,f['rivet_radius_m'])
    o=bpy.context.object;o.name='Supported_'+f['id']+'_fastener';bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    o.data.materials.append(mat);uv(o);return o

def finish(parts,name,f,shape,at,expected):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o['family']=f['id'];o['shape']=shape;o['expected_blender_m']=expected;o['inspection_only']=True
    o['origin_contract']='centre of exact native envelope; review location is staging only'
    o.location=at
    for coll in list(o.users_collection):coll.objects.unlink(o)
    bpy.data.collections['Runtime_proxies'].objects.link(o)
    return o

def girder(f,mats,x):
    body,seam=mats;parts=[];b=f['bevel_m']
    for z in [-.173,.173]:parts.append(box('Flange',(0,0,z),(2,.3,.054),body,b))
    parts.append(box('Web',(0,0,0),(2,.075,.292),body,b))
    width={'iron':.22,'bronze':.28,'steel':.12,'silver':.18}[f['id']]
    for side in [-1,1]:
        parts.append(box('Protected_splice',(0,side*.053,0),(width+.018,.031,.280),seam,.002))
        parts.append(box('Splice_plate',(0,side*.074,0),(width,.018,.270),body,b))
        if f['id']=='silver':
            for dx in [-.061,.061]:parts.append(box('Chased_band',(dx,side*.086,0),(.009,.008,.253),seam,.001))
        for dx in [-width*.30,width*.30]:
            for z in [-.091,.091]:parts.append(rivet((dx,side*.09,z),f,body))
    return finish(parts,f['id']+'_girder_proxy',f,'girder',(x,0,.28),[2,.3,.4])

def coupon(f,mats,x):
    body,seam=mats;b=f['bevel_m'];parts=[]
    # Half-metre joint sample, never a new placeable or component recipe.
    parts.append(box('Seam_backing',(0,.009,0),(.5,.062,.5),seam,.002))
    for dx in [-.126,.126]:parts.append(box('Plate',(dx,-.010,0),(.248,.046,.5),body,b))
    for dx in [-.198,.198]:
        for z in [-.198,.198]:parts.append(rivet((dx,-.035,z),f,body))
    depth={'iron':.087,'bronze':.084,'steel':.0795,'silver':.084}[f['id']]
    return finish(parts,f['id']+'_joint_coupon',f,'coupon',(x,-.015,1.08),[.5,depth,.5])

def arch(f,mats,x):
    # Smooth material test proxy inside native 1 x 1 x .25 envelope.
    # Opening deliberately labelled proxy: native PieceMesh is a stepped strip arch.
    body,seam=mats;verts=[];faces=[];n=40;r=.46
    for i in range(n+1):
        xx=-.5+i/n;zz=math.sqrt(max(0,r*r-xx*xx))-.5
        verts.extend([(xx,-.108,zz),(xx,-.108,.5),(xx,.108,zz),(xx,.108,.5)])
    for i in range(n):
        a=i*4;b=a+4
        faces.extend([(a,b,b+1,a+1),(a+2,a+3,b+3,b+2),(a+1,b+1,b+3,a+3),(a,a+2,b+2,b)])
    faces.extend([(0,1,3,2),(4*n,4*n+2,4*n+3,4*n+1)])
    mesh=bpy.data.meshes.new('Cast_arch');mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new('Cast_arch',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(body);uv(o);parts=[o]
    for side in [-1,1]:
        for dx in [-.40,.40]:
            parts.append(box('Joint_recess',(dx,side*.113,.22),(.135,.014,.46),seam,.002))
            parts.append(box('Cast_lug',(dx,side*.117,.22),(.107,.016,.43),body,.002))
            for z in [.07,.36]:
                # Pin is shallow and seated, below the 0.125 m outer boundary.
                pin=rivet((dx,side*.115,z),f,body);parts.append(pin)
    return finish(parts,f['id']+'_arch_proxy',f,'arch',(x,.18,2.05),[1,.25,1])

def audit():
    result=[]
    for o in bpy.data.objects:
        if o.type!='MESH' or not o.get('inspection_only'):continue
        o.data.calc_loop_triangles();assert all(t.area>1e-12 for t in o.data.loop_triangles),o.name
        assert len(o.data.uv_layers)==1,o.name
        assert len(o.data.materials)==2,(o.name,len(o.data.materials))
        assert all(math.isfinite(c) for v in o.data.vertices for c in v.co)
        expected=o['expected_blender_m'];actual=list(o.dimensions)
        assert all(abs(a-b)<1e-5 for a,b in zip(actual,expected)),(o.name,actual,expected)
        result.append({'name':o.name,'family':o['family'],'shape':o['shape'],'dimensions_blender_m':actual,'triangles':len(o.data.loop_triangles),'surfaces':len(o.data.materials),'metric_uv':True})
    return {'proxies':result,'triangles':sum(o['triangles'] for o in result),'images':[{'name':i.name,'packed':bool(i.packed_file),'space':i.colorspace_settings.name} for i in bpy.data.images if i.source=='FILE'],'degenerate_triangles':0}

def render(scene,out,at,target,size):
    scene.camera.location=at;aim(scene.camera,target);scene.camera.data.ortho_scale=size;scene.render.filepath=str(out);bpy.ops.render.render(write_still=True)

def build(textures,out):
    out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.read_factory_settings(use_empty=True)
    cfg=json.loads(Path(__file__).with_name('materials.json').read_text());scene=bpy.context.scene
    for name in ['Source_materials','Finished_joints','Runtime_proxies','Review']:scene.collection.children.link(bpy.data.collections.new(name))
    for i,f in enumerate(cfg['families']):
        mats=[material(f,r,textures) for r in ['body','seam']];x=(i-1.5)*2.3
        girder(f,mats,x);coupon(f,mats,x)
        if f['id'] in ['bronze','silver']:arch(f,mats,x)
        curve=bpy.data.curves.new('Label','FONT');curve.body=f['name'];curve.align_x='CENTER';curve.size=.14
        label=bpy.data.objects.new('Label_'+f['id'],curve);bpy.data.collections['Review'].objects.link(label);label.location=(x,-.58,.015);label.rotation_euler=(math.pi/2,0,0)
    stage=bpy.data.materials.new('Neutral');stage.diffuse_color=(.12,.12,.12,1)
    ground=box('Review_stage',(0,0,-.02),(200,200,.04),stage)
    world=bpy.data.worlds.new('Neutral_world');world.use_nodes=True;scene.world=world
    world.node_tree.nodes['Background'].inputs[0].default_value=(.3,.3,.3,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
    for name,loc,energy,size in [('Key',(-3,-5,7),1600,6),('Fill',(5,-3,4),900,4),('Rim',(0,4,6),1800,5)]:
        light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.shape='DISK';light.size=size
        obj=bpy.data.objects.new(name,light);bpy.data.collections['Review'].objects.link(obj);obj.location=loc;aim(obj,(0,0,1))
    cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));bpy.data.collections['Review'].objects.link(cam);scene.camera=cam;cam.data.type='ORTHO'
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True
    scene.render.threads_mode='FIXED';scene.render.threads=8;scene.view_settings.view_transform='Standard'
    scene.render.resolution_x=1800;scene.render.resolution_y=850;scene.render.resolution_percentage=100
    bpy.ops.object.select_all(action='DESELECT')
    for o in bpy.data.collections['Runtime_proxies'].objects:o.select_set(True)
    # Godot overrides embedded preview surfaces with explicit shared textures/factors.
    bpy.ops.export_scene.gltf(filepath=str(out/'d6_proxies.glb'),use_selection=True,export_format='GLB',export_extras=True)
    bpy.ops.file.pack_all()
    report=audit();assert len(report['proxies'])==10;assert len(report['images'])==12
    (out/'blender-audit.json').write_text(json.dumps(report,indent=2)+'\n')
    render(scene,out/'blender-overview.png',(3,-14,6),(0,0,1.15),10.5)
    scene.render.resolution_x=1000;scene.render.resolution_y=1100
    for i,f in enumerate(cfg['families']):
        x=(i-1.5)*2.3
        render(scene,out/f'blender-{f["id"]}.png',(x+1.05,-4,2.65),(x,0,1.25),3)
    scene.render.resolution_x=1800;scene.render.resolution_y=850
    cam.location=(3,-14,6);aim(cam,(0,0,1.15));cam.data.ortho_scale=10.5
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'d6_materials.blend'))
    print('D6_BLENDER_OK',report['triangles'])

def reopen(master,out):
    out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.open_mainfile(filepath=str(master));a=audit()
    assert len(a['images'])==12 and all(i['packed'] for i in a['images']);assert len(a['proxies'])==10
    render(bpy.context.scene,out/'packed-reopen.png',(3,-14,6),(0,0,1.15),10.5)
    # All six directions inspect actual packed geometry in independent process.
    scene=bpy.context.scene;scene.render.resolution_x=1200;scene.render.resolution_y=700
    for name,at in [('front',(0,-15,1.2)),('back',(0,15,1.2)),('side',(15,-3,3)),('top',(0,0,15)),('underside',(0,-6,-8))]:
        bpy.data.objects['Review_stage'].hide_render=True
        render(scene,out/(name+'.png'),at,(0,0,1.2),10.5)
    clay=bpy.data.materials.new('Inspection_clay');clay.use_nodes=True
    clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.28,.28,.28,1)
    clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.7
    scene.view_layers[0].material_override=clay
    for name,at in [('front',(0,-15,1.2)),('back',(0,15,1.2)),('side',(15,-3,3)),('three-quarter',(3,-14,6)),('top',(0,0,15)),('underside',(0,-6,-8))]:
        render(scene,out/('clay-'+name+'.png'),at,(0,0,1.2),10.5)
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(master.parent/'d6_proxies.glb'))
    fresh=audit();assert len(fresh['proxies'])==10;assert fresh['triangles']==a['triangles']
    a['fresh_glb_import']=fresh;(out/'reopen-audit.json').write_text(json.dumps(a,indent=2)+'\n');print('D6_REOPEN_OK',a['triangles'])

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:]
    if args[0]=='--reopen':reopen(Path(args[1]).resolve(),Path(args[2]).resolve())
    else:build(Path(args[0]).resolve(),Path(args[1]).resolve())
