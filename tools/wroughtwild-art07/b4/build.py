"""B4 source reuse, family distance silhouettes and editable composed terrain.
Run in Blender, eight threads. Sources and earlier handoffs remain immutable.
"""
import bpy, sys, json, math, random, shutil
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from prerequisites import PACKAGES, sha
from landform import height, route_x, stream_x

out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not out.exists();out.mkdir(parents=True);(out/'models').mkdir()
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
collections={}
for name in ['SOURCE','FINISHED','RUNTIME','REVIEW']:
    c=bpy.data.collections.new(name);scene.collection.children.link(c);collections[name]=c
sources={};report={};lineage=[]
def import_glb(path,collection):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path),import_pack_images=True)
    obs=[o for o in bpy.data.objects if o not in before]
    for o in obs:
        for c in list(o.users_collection):c.objects.unlink(o)
        collection.objects.link(o)
    return [o for o in obs if o.type=='MESH']
def export(obs,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.hide_set(False);o.hide_viewport=False;o.hide_render=False;o.select_set(True)
    path=out/'models'/f'{name}.glb'
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_texcoords=True,export_normals=True,export_materials='EXPORT',export_attributes=True,export_all_vertex_colors=True)
    n=0;points=[]
    for o in obs:
        o.data.calc_loop_triangles();n+=len(o.data.loop_triangles)
        points.extend(o.matrix_world@v.co for v in o.data.vertices)
    report[name]={'triangles':n,'surfaces':sum(len(o.data.materials) for o in obs),'min':[min(p[k] for p in points) for k in range(3)],'max':[max(p[k] for p in points) for k in range(3)]}
    for o in obs:o.hide_render=True;o.hide_set(True)
def source(path,key):
    lineage.append({'path':str(path),'sha256':sha(path)})
    obs=import_glb(path,collections['SOURCE'])
    for o in obs:o.name=key+' SOURCE '+o.name;o.hide_render=True;o.hide_set(True)
    return obs
def copies(obs,name,col):
    result=[]
    for o in obs:
        n=o.copy();n.data=o.data.copy();n.name=name+' '+o.name.split(' SOURCE ')[-1];col.objects.link(n);n.hide_set(False);n.hide_render=False;result.append(n)
    return result
for family in ['broadleaf-a','broadleaf-altered','pine-a']:
    root=PACKAGES['b1'][0]/'models'/('pine' if family.startswith('pine') else 'broadleaf')
    for level,original in enumerate([0,1,2]):
        obs=source(root/f'{family}-lod{original}.glb',f'{family}-{level}')
        runtime=copies(obs,f'{family}-{level}',collections['RUNTIME'])
        for o in runtime:
            if 'foliage' not in o.name.lower() and 'branchlets' not in o.name.lower():
                for p in o.data.polygons:p.use_smooth=True
                mat=o.data.materials[0].copy();o.data.materials[0]=mat
                ns=mat.node_tree.nodes;ls=mat.node_tree.links;bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
                bs.inputs['Emission Strength'].default_value=0
                if family=='broadleaf-altered':
                    # glTF cannot encode B1's custom UV-driven Blender network.
                    # Rebuild it from the retained UV1 core/damage, not constant glTF emission.
                    uv=ns.new('ShaderNodeUVMap');uv.uv_map=o.data.uv_layers[1].name
                    sep=ns.new('ShaderNodeSeparateXYZ');ls.new(uv.outputs[0],sep.inputs[0])
                    old=bs.inputs['Base Color'].links[0].from_socket
                    mix=ns.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.012,.008,.004,1)
                    ls.new(sep.outputs['Y'],mix.inputs[0]);ls.new(old,mix.inputs[1]);ls.new(mix.outputs[0],bs.inputs['Base Color'])
                    bs.inputs['Emission Color'].default_value=(1,.09,.004,1);ls.new(sep.outputs['X'],bs.inputs['Emission Strength'])
        if level==2:
            for o in runtime:
                o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
                target=8500 if 'foliage' in o.name.lower() else (1800 if 'branchlets' in o.name.lower() else 3500)
                if count>target:
                    bpy.context.view_layer.objects.active=o
                    m=o.modifiers.new('B4 distant silhouette only','DECIMATE');m.ratio=target/count
                    bpy.ops.object.modifier_apply(modifier=m.name)
        key=f'{family}-{level}';export(runtime,key);sources[key]=runtime
for family in ['fern-lush','fern-sparse','grass-meadow','grass-edge','moss','leaf-litter','sapling-shrub']:
    # Whole B2 far fronds retain stems/attachments; no arbitrary near-fern collapse.
    obs=source(PACKAGES['b2'][0]/'review/assets'/f'{family}-lod2.glb',family)
    runtime=copies(obs,family,collections['RUNTIME']);export(runtime,family);sources[family]=runtime
for family in ['river-bank','rock-shelf','rock-shelf-altered','talus-pebbles']:
    for level in [0,1]:
        obs=source(PACKAGES['b3'][0]/'models'/f'{family}-lod{level}.glb',family+str(level))
        runtime=copies(obs,family+str(level),collections['RUNTIME'])
        if family=='rock-shelf-altered':
            for o in runtime:
                mat=o.data.materials[0].copy();o.data.materials[0]=mat;ns=mat.node_tree.nodes;ls=mat.node_tree.links;bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
                attr=ns.new('ShaderNodeVertexColor');attr.layer_name=o.data.color_attributes[0].name
                sep=ns.new('ShaderNodeSeparateColor');ls.new(attr.outputs['Color'],sep.inputs[0])
                ramp=ns.new('ShaderNodeMapRange');ramp.inputs['From Min'].default_value=.55;ramp.inputs['From Max'].default_value=.92
                ls.new(sep.outputs['Red'],ramp.inputs['Value']);ls.new(ramp.outputs['Result'],bs.inputs['Emission Strength']);bs.inputs['Emission Color'].default_value=(1,.10,.005,1)
        key=f'{family}-{level}';export(runtime,key);sources[key]=runtime

# Layout is an authored review fixture. Full-width trees stay outside a measured path.
rng=random.Random(42);layout=[]
def place(role,x,z,scale=1,yaw=0,burial=0):
    row={'role':role,'x':x,'z':z,'y':height(x,z)-burial*scale,'scale':scale,'yaw':yaw,'burial':burial}
    layout.append(row);return row
for role,x,z,s in [('broadleaf-a',4.9,14,1),('pine-a',-12,12,1.1),('broadleaf-altered',4.8,0,1),('broadleaf-a',-12,-3,1.1),('pine-a',5.7,-12,1.1),('broadleaf-a',-11,-17,1),('pine-a',11,1,1.12),('broadleaf-a',11,22,1.1)]:
    place(role,x,z,s,rng.uniform(-.5,.5),.55 if role.startswith('pine') else .65)
for i in range(24):
    angle=2*math.pi*i/24;radius=rng.uniform(24,39)
    x=math.cos(angle)*radius;z=math.sin(angle)*radius+5
    if abs(x)<4 and z>8:continue
    place('pine-a' if i%3==0 else 'broadleaf-a',x,z,rng.uniform(.85,1.3),rng.uniform(0,6.28),.6)
for z in range(-24,26,5):
    place('river-bank',stream_x(z)-1.75,z,1,rng.uniform(-.25,.25),.14)
for x,z,s in [(7,-7,1.5),(9,8,1.2),(-11,5,1.6),(10,-23,2),(-15,-23,2),(18,29,3),(-18,34,3.5)]:
    place('rock-shelf',x,z,s,rng.uniform(0,6.28),.16)
place('rock-shelf-altered',2.9,-2.8,1,0,.14)
for i in range(330):
    z=rng.uniform(-23,24);side=-1 if i%2 else 1
    x=route_x(z)+side*rng.uniform(1.4,4.7)
    if abs(x-stream_x(z))<2.2:continue
    role=['grass-meadow','grass-edge','fern-sparse','grass-meadow','leaf-litter','fern-lush','moss'][i%7]
    place(role,x,z,rng.uniform(.65,1.15),rng.uniform(0,6.28),0)
for x,z in [(3,8),(-3,2),(3,-12),(-3,-15),(8,14),(-9,18)]:place('sapling-shrub',x,z,.8,rng.uniform(0,6.28))
for i in range(12):
    z=rng.uniform(-24,24);place('talus-pebbles',stream_x(z)+1.7,z,.7,rng.uniform(0,6.28),.04)
(out/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')

# Author the exact same sampled ground used for visual and physical review.
verts=[];faces=[];step=.5;nx=201;nz=201
for j in range(nz):
    z=-50+j*step
    for i in range(nx):
        x=-50+i*step;verts.append((x,-z,height(x,z)))
for j in range(nz-1):
    for i in range(nx-1):
        a=j*nx+i;faces.extend([(a,a+nx,a+1),(a+1,a+nx,a+nx+1)])
mesh=bpy.data.meshes.new('ART02 retained sampled landform');mesh.from_pydata(verts,[],faces);mesh.update()
ground=bpy.data.objects.new('Ground',mesh);collections['FINISHED'].objects.link(ground)
mat=bpy.data.materials.new('Humus and inherited ART02 litter');mat.diffuse_color=(.13,.105,.06,1);mat.use_nodes=True
image=bpy.data.images.load(str(PACKAGES['art02'][0]/'review/forest-floor.png')) if (PACKAGES['art02'][0]/'review/forest-floor.png').exists() else bpy.data.images.load(str(Path('C:/Users/Matty/Dev/project-wroughtwild/docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png')))
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
coord=mat.node_tree.nodes.new('ShaderNodeTexCoord');mapping=mat.node_tree.nodes.new('ShaderNodeVectorMath');mapping.operation='SCALE';mapping.inputs[3].default_value=.35
mat.node_tree.links.new(coord.outputs['Object'],mapping.inputs[0]);mat.node_tree.links.new(mapping.outputs[0],tex.inputs['Vector']);mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);ground.data.materials.append(mat)
export([ground],'ground');ground.hide_render=False;ground.hide_set(False)

# Actual packed source composition at selected camera detail; individual sources remain editable.
for idx,row in enumerate(layout):
    role=row['role'];key=role+('-0' if role in ['broadleaf-a','broadleaf-altered','pine-a','river-bank','rock-shelf','rock-shelf-altered','talus-pebbles'] else '')
    if role in ['broadleaf-a','broadleaf-altered','pine-a'] and math.hypot(row['x'],row['z']-18)>34:key=role+'-2'
    for o in copies(sources[key],f'Placed {idx}',collections['REVIEW']):
        o.location=Vector((row['x'],-row['z'],row['y']));o.rotation_euler.z=-row['yaw'];o.scale=(row['scale'],)*3
        # Ground plants conform at every vertex, matching the engine shader.
        if role in ['fern-lush','fern-sparse','grass-meadow','grass-edge','moss','leaf-litter','sapling-shrub']:
            bpy.context.view_layer.update()
            for v in o.data.vertices:
                w=o.matrix_world@v.co
                v.co.z+=(height(w.x,-w.y)-height(row['x'],row['z']))/row['scale']

# Shallow stream is inside the inherited bank footprint, without swimming/flood simulation.
waterverts=[];waterfaces=[]
for j in range(161):
    z=-40+j*.5;x=stream_x(z)
    waterverts.extend([(x-1.5,-z,-.56),(x+1.5,-z,-.56)])
for j in range(160):a=j*2;waterfaces.append((a,a+2,a+3,a+1))
wm=bpy.data.meshes.new('Stream');wm.from_pydata(waterverts,[],waterfaces);wm.update();water=bpy.data.objects.new('Water',wm);collections['FINISHED'].objects.link(water)
wmat=bpy.data.materials.new('Dark shallow water');wmat.diffuse_color=(.06,.15,.15,1);wmat.use_nodes=True;bs=wmat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.045,.13,.13,1);bs.inputs['Metallic'].default_value=.35;bs.inputs['Roughness'].default_value=.23;water.data.materials.append(wmat)
export([water],'water');water.hide_render=False;water.hide_set(False)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.resolution_x=1440;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Cool daylight');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.4,.44,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
bpy.ops.object.light_add(type='SUN',rotation=(math.radians(28),math.radians(-25),math.radians(-35)));bpy.context.object.data.energy=2.5;bpy.context.object.data.angle=.10
bpy.ops.object.camera_add(location=(.4,18,2.2));cam=bpy.context.object;target=Vector((-.3,-15,2.0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=24;scene.camera=cam
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'b4-composition.blend'))
(out/'models.json').write_text(json.dumps(report,indent=2)+'\n');(out/'lineage.json').write_text(json.dumps(lineage,indent=2)+'\n')
scene.render.filepath=str(out/'blender-composition.png');bpy.ops.render.render(write_still=True)
print('B4_BUILD_OK',len(layout),len(report))
