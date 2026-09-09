"""Author/editable material library and exact-size inspection proxies in metres.
Blender --background --threads 8 --python-exit-code 1 --python THIS -- TEXTURES FRESH_OUT
Or: ... --python THIS -- --reopen MASTER.blend FRESH_OUT
"""
import bpy
import json
import math
import sys
import time
from pathlib import Path
from mathutils import Vector

def aim(obj, at):
    obj.rotation_euler = (Vector(at)-obj.location).to_track_quat('-Z','Y').to_euler()

def material(c, role, textures):
    m = bpy.data.materials.new('d4_'+c['id']+'_'+role)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Metallic'].default_value = 0
    p.inputs['Emission Strength'].default_value = 0
    for kind in ['albedo','normal','orm']:
        tex = m.node_tree.nodes.new('ShaderNodeTexImage')
        tex.name = 'D4 '+kind
        tex.image = bpy.data.images.load(str(textures/f'd4_{c["id"]}_{role}_{kind}.png'),check_existing=True)
        tex.image.colorspace_settings.name = 'sRGB' if kind == 'albedo' else 'Non-Color'
        tex.extension = 'REPEAT'
        if kind == 'albedo':
            m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
        elif kind == 'normal':
            normal = m.node_tree.nodes.new('ShaderNodeNormalMap')
            normal.inputs['Strength'].default_value = 1
            m.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color'])
            m.node_tree.links.new(normal.outputs['Normal'],p.inputs['Normal'])
        else:
            separate = m.node_tree.nodes.new('ShaderNodeSeparateColor')
            m.node_tree.links.new(tex.outputs['Color'],separate.inputs['Color'])
            m.node_tree.links.new(separate.outputs['Green'],p.inputs['Roughness'])
    return m

def box(name, size, at, c, mats, grain_axis, collection, uv_offset=(0,0)):
    # Local Blender axes XYZ. In Godot XYZ -> XZ-Y; never apply twice.
    sx,sy,sz = size
    verts=[(x*sx/2,y*sy/2,z*sz/2) for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    collection.objects.link(obj)
    obj.location=at
    mesh.materials.append(mats[0]);mesh.materials.append(mats[1])
    uv=mesh.uv_layers.new(name='D4_Metres')
    for poly in mesh.polygons:
        normal_axis=max(range(3),key=lambda k:abs(poly.normal[k]))
        end=normal_axis==grain_axis
        if c['id'] in ['woven_reed','corkbark']:
            end=normal_axis!=1
        poly.material_index=1 if end else 0
        scale=c['edge_metres'] if end else c['tile_metres']
        axes=[k for k in range(3) if k!=normal_axis]
        if not end and grain_axis in axes:
            vaxis=grain_axis;uaxis=next(k for k in axes if k!=vaxis)
        else:
            uaxis,vaxis=axes
        # Right-handed UV frame relative to each face's outward normal.
        tangent=Vector([int(k==uaxis) for k in range(3)])
        bitangent=Vector([int(k==vaxis) for k in range(3)])
        sign=1 if tangent.cross(bitangent).dot(poly.normal)>0 else -1
        for loop in poly.loop_indices:
            co=mesh.vertices[mesh.loops[loop].vertex_index].co
            uv.data[loop].uv=(sign*(co[uaxis]+size[uaxis]/2)/scale[0]+uv_offset[0],(co[vaxis]+size[vaxis]/2)/scale[1]+uv_offset[1])
    obj['inspection_only']=True
    obj['family']=c['id'];obj['grain_axis_blender']=grain_axis
    obj['bounds_metres']=list(size)
    return obj

def text_label(body, at, size, collection):
    curve=bpy.data.curves.new('label','FONT');curve.body=body;curve.size=size;curve.align_x='CENTER'
    obj=bpy.data.objects.new(body,curve);collection.objects.link(obj);obj.location=at
    obj.rotation_euler=(math.pi/2,0,0)
    mat=bpy.data.materials.get('Label')
    if not mat:
        mat=bpy.data.materials.new('Label');mat.diffuse_color=(.65,.67,.65,1)
    obj.data.materials.append(mat)

def audit():
    result=[]
    for o in bpy.data.objects:
        if o.type!='MESH' or not o.get('inspection_only'):continue
        o.data.calc_loop_triangles()
        degenerate=sum(1 for tri in o.data.loop_triangles if tri.area<1e-12)
        assert not degenerate,o.name
        assert all(math.isfinite(v) for vertex in o.data.vertices for v in vertex.co)
        result.append({'name':o.name,'family':o['family'],'dimensions_blender_m':list(o.dimensions),'dimensions_godot_m':[o.dimensions.x,o.dimensions.z,o.dimensions.y],'triangles':len(o.data.loop_triangles),'surfaces':len(o.data.materials),'grain_axis_blender':o['grain_axis_blender'],'origin':'centre; board arrangement only; not a lattice replacement'})
    images=[{'name':i.name,'size':list(i.size),'colour_space':i.colorspace_settings.name,'packed':bool(i.packed_file)} for i in bpy.data.images if i.source=='FILE']
    return {'proxies':result,'triangles':sum(r['triangles'] for r in result),'images':images,'degenerate_triangles':0}

def render(scene, path, at, target, ortho):
    cam=scene.camera;cam.location=at;aim(cam,target);cam.data.type='ORTHO';cam.data.ortho_scale=ortho
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)

def build(textures,out):
    start=time.perf_counter();out.mkdir(parents=True,exist_ok=False)
    cfg=json.loads((textures/'textures.json').read_text())['settings']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    runtime=bpy.data.collections.new('Runtime_proxies');scene.collection.children.link(runtime)
    review=bpy.data.collections.new('Review');scene.collection.children.link(review)
    source=bpy.data.collections.new('Source_materials');scene.collection.children.link(source)
    for i,c in enumerate(cfg['families']):
        mats=[material(c,r,textures) for r in ['face','edge']]
        x=(i-3)*1.55
        cover=c['id'] in ['woven_reed','corkbark']
        # These are plain current catalogue envelopes, not authored D1/D2 modules.
        box(c['id']+'_light_panel' if cover else c['id']+'_wall_panel',(1,.16 if cover else .25,1),(x,.3,1.0),c,mats,2,runtime)
        if not cover:
            box(c['id']+'_beam',(1,.4,.4),(x,-.45,.2),c,mats,0,runtime)
            box(c['id']+'_half_beam',(.5,.2,.2),(x+.2,-.5,.53),c,mats,0,runtime)
            box(c['id']+'_half_wall',(.5,.125,.5),(x,-.02,1.87),c,mats,2,runtime)
        else:
            box(c['id']+'_cut_swatch',(.5,.16,.3),(x,-.45,.2),c,mats,2,runtime)
            # Four tiles meet exactly, each at native physical texture scale.
            # Inspection coupons are explicitly not legal new half covering pieces.
            box(c['id']+'_tiling_coupon',(.5,.04,.5),(x,-.02,1.87),c,mats,2,runtime)
        text_label(c['name'].upper(),(x,-.84,.06),.125,review)
    # Stage contributes no runtime geometry or copied material light.
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.018))
    stage=bpy.context.object;stage.name='Neutral_stage'
    for coll in list(stage.users_collection):coll.objects.unlink(stage)
    review.objects.link(stage)
    stage_mat=bpy.data.materials.new('Neutral_stage');stage_mat.use_nodes=True
    stage_mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.055,.065,.07,1)
    stage_mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.82
    stage.data.materials.append(stage_mat)
    world=bpy.data.worlds.new('Neutral_world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.22,.22,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7;scene.world=world
    for name,loc,power,size in [('Key',(-3,-5,8),1700,8),('Fill',(6,-2,5),1000,7),('Rim',(0,4,6),1300,6)]:
        light=bpy.data.lights.new(name,'AREA');light.energy=power;light.shape='DISK';light.size=size
        o=bpy.data.objects.new(name,light);review.objects.link(o);o.location=loc;aim(o,(0,0,1))
    camera=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',camera);review.objects.link(cam);scene.camera=cam
    scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
    scene.cycles.device='CPU';scene.render.threads_mode='FIXED';scene.render.threads=8
    scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=0;scene.view_settings.gamma=1
    scene.render.resolution_x=2200;scene.render.resolution_y=950;scene.render.resolution_percentage=100
    # Select only inspection proxies for the one reusable review GLB.
    bpy.ops.object.select_all(action='DESELECT')
    for o in runtime.objects:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out/'d4_proxies.glb'),export_format='GLB',use_selection=True,export_yup=True,export_cameras=False,export_lights=False,export_materials='EXPORT',export_extras=True)
    bpy.ops.file.pack_all()
    render(scene,out/'blender-overview.png',(4,-13,7),(0,0,1.0),11.8)
    scene.render.resolution_x=1000;scene.render.resolution_y=1000
    for i,c in enumerate(cfg['families']):
        x=(i-3)*1.55
        render(scene,out/f'blender-{c["id"]}.png',(x+1.05,-3.7,2.5),(x,0,1.0),2.45)
    scene.render.resolution_x=2200;scene.render.resolution_y=950
    cam.location=(4,-13,7);aim(cam,(0,0,1));cam.data.ortho_scale=11.8
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'d4_materials.blend'))
    report=audit();report['seconds']=time.perf_counter()-start
    (out/'blender-audit.json').write_text(json.dumps(report,indent=2)+'\n')
    print('D4_BLENDER_OK',report['triangles'],report['seconds'])

def reopen(master,out):
    out.mkdir(parents=True,exist_ok=False)
    bpy.ops.wm.open_mainfile(filepath=str(master))
    result=audit()
    assert len(result['images'])==42
    assert all(i['packed'] for i in result['images'])
    assert len(result['proxies'])==26
    render(bpy.context.scene,out/'packed-reopen.png',(4,-13,7),(0,0,1),11.8)
    # Import exported GLB in a separate empty scene and inspect actual export.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(master.parent/'d4_proxies.glb'))
    export=[]
    native_path=Path(__file__).resolve().parents[3]/'data/tuning/construction.json'
    if not native_path.exists():native_path=Path(__file__).resolve().parent/'construction-reference.json'
    native={s['id']:s for s in json.loads(native_path.read_text())['shapes']}
    for o in bpy.data.objects:
        if o.type=='MESH':
            o.data.calc_loop_triangles()
            assert all(t.area>1e-12 for t in o.data.loop_triangles)
            matching=next((key for key in ['light_panel','wall_panel','half_beam','half_wall','beam'] if o.name.endswith('_'+key)),None)
            if matching:
                native_size=native[matching]['size_m']
                expected=[native_size[0],native_size[2],native_size[1]]
                assert all(abs(a-b)<1e-6 for a,b in zip(o.dimensions,expected)),(o.name,list(o.dimensions),expected)
            export.append({'name':o.name,'size':list(o.dimensions),'triangles':len(o.data.loop_triangles),'native_shape':matching,'dimension_check':'pass' if matching else 'inspection coupon only'})
    assert len(export)==26,len(export)
    result['fresh_glb_import']=export
    (out/'reopen-audit.json').write_text(json.dumps(result,indent=2)+'\n')
    print('D4_REOPEN_OK',len(export))

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:]
    if args[0]=='--reopen':reopen(Path(args[1]).resolve(),Path(args[2]).resolve())
    else:build(Path(args[0]).resolve(),Path(args[1]).resolve())
