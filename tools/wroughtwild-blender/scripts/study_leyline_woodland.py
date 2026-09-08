"""An authored river-bank art study using the project's existing nature meshes.

Blender --background --python-exit-code 1 --python SCRIPT -- REPOSITORY OUTPUT
Writes one isolated editable scene and actual renders. Never exports over game
assets. The review land/water/roots/scar have no gameplay or save semantics.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

root, out = map(Path, sys.argv[sys.argv.index('--') + 1:])
root, out = root.resolve(), out.resolve()
assert not out.exists(), 'Preserve previous studies; use a fresh directory.'
out.mkdir(parents=True)
cfg_path = Path(__file__).resolve().parents[1] / 'leyline_woodland_study.json'
cfg = json.loads(cfg_path.read_text())
rng = random.Random(cfg['seed'])
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = cfg['render']['samples']
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = cfg['render']['pixels']
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.world.use_nodes = True
background = scene.world.node_tree.nodes.get('Background')
background.inputs[0].default_value = (.48, .58, .66, 1)
background.inputs[1].default_value = cfg['render']['world_strength']
report = {'purpose': cfg['purpose'], 'seed': cfg['seed'], 'inputs': {}, 'views': [],
          'game_assets_replaced': False, 'runtime_performance_measured': False,
          'coordinates': 'Blender metres: X across river, Y downstream distance, Z up'}

def mesh(name, vertices, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    data.materials.append(mat)
    for poly in data.polygons:
        poly.use_smooth = True
    return obj

def material(name, colour, roughness=.9):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*colour, 1)
    p.inputs['Roughness'].default_value = roughness
    return mat

def tube(name, points, radius, mat):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.resolution_u = 8
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    curve.use_fill_caps = True
    line = curve.splines.new('BEZIER')
    line.bezier_points.add(len(points)-1)
    for i, (bp, point) in enumerate(zip(line.bezier_points, points)):
        bp.co = point
        bp.handle_left_type = bp.handle_right_type = 'AUTO'
        bp.radius = max(.07, 1-i/(len(points)-.25))
    obj = bpy.data.objects.new(name, curve)
    scene.collection.objects.link(obj)
    curve.materials.append(mat)
    return obj

palette = cfg['palette']
ground_mat = material('Loam, moss and fine mineral grain', palette['loam'])
nodes, links = ground_mat.node_tree.nodes, ground_mat.node_tree.links
coordinates = nodes.new('ShaderNodeTexCoord')
noise = nodes.new('ShaderNodeTexNoise')
noise.inputs['Scale'].default_value = cfg['surface']['moss_scale']
noise.inputs['Detail'].default_value = 3
links.new(coordinates.outputs['Object'], noise.inputs['Vector'])
ramp = nodes.new('ShaderNodeValToRGB')
ramp.color_ramp.elements[0].position = .32
ramp.color_ramp.elements[0].color = (*palette['loam'], 1)
ramp.color_ramp.elements[1].position = .68
ramp.color_ramp.elements[1].color = (*palette['moss'], 1)
links.new(noise.outputs['Fac'], ramp.inputs[0])
links.new(ramp.outputs[0], nodes.get('Principled BSDF').inputs['Base Color'])
fine = nodes.new('ShaderNodeTexNoise')
fine.inputs['Scale'].default_value = cfg['surface']['grain_scale']
links.new(coordinates.outputs['Object'], fine.inputs['Vector'])
bump = nodes.new('ShaderNodeBump')
bump.inputs['Strength'].default_value = cfg['surface']['grain_strength']
bump.inputs['Distance'].default_value = cfg['surface']['grain_distance']
links.new(fine.outputs['Fac'], bump.inputs['Height'])
links.new(bump.outputs[0], nodes.get('Principled BSDF').inputs['Normal'])
root_mat = material('Weathered anchoring roots', palette['root'])
water_mat = material('Quiet creek', palette['water'], .2)
water_bsdf = water_mat.node_tree.nodes.get('Principled BSDF')
water_bsdf.inputs['Metallic'].default_value = .12
water_noise = water_mat.node_tree.nodes.new('ShaderNodeTexNoise')
water_noise.inputs['Scale'].default_value = 7
water_bump = water_mat.node_tree.nodes.new('ShaderNodeBump')
water_bump.inputs['Strength'].default_value = .14
water_bump.inputs['Distance'].default_value = .016
water_mat.node_tree.links.new(water_noise.outputs['Fac'], water_bump.inputs['Height'])
water_mat.node_tree.links.new(water_bump.outputs[0], water_bsdf.inputs['Normal'])
scar_mat = material('Dark weathered fracture edge', palette['scar_edge'])
current_mat = material('Narrow exposed leyline current', palette['current'], .45)
current_bsdf = current_mat.node_tree.nodes.get('Principled BSDF')
current_bsdf.inputs['Emission Color'].default_value = (*palette['current'], 1)
current_bsdf.inputs['Emission Strength'].default_value = cfg['current_energy']

def river(y):
    return -1.4+1.35*math.sin(y*.15)+.025*y

def halfwidth(y):
    return 1.35+.3*math.sin(y*.21+.6)

def land(x, y):
    bank = abs(x-river(y))-halfwidth(y)
    t = max(0, min(1, (bank+.7)/1.8))
    level = -.45 + 1.1*t*t*(3-2*t)
    ripple = (.1*math.sin(x*1.3+y*.6)+.08*math.sin(y*1.5-x*.9))*t
    outer = max(0, abs(x)-5)*.13
    return level+ripple+outer

verts, faces = [], []
nx, ny = 100, 176
for j in range(ny+1):
    y = -15+j*.4
    for i in range(nx+1):
        x = -20+i*.4
        verts.append((x, y, land(x,y)))
for j in range(ny):
    for i in range(nx):
        a = j*(nx+1)+i
        faces.append((a,a+1,a+nx+2,a+nx+1))
mesh('REVIEW LAND - isolated river bank, no world generator', verts, faces, ground_mat)
mesh('REVIEW WATER - no fluid or hazard simulation',
     [(-21,-16,.025),(21,-16,.025),(21,56,.025),(-21,56,.025)], [(0,1,2,3)], water_mat)

sources = {}
for name in ['broadleaf_tree','field_boulder','shrub','fern_bed','deadfall','stump']:
    path = root / 'game/assets/authored' / (name+'.glb')
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    imported = set(bpy.data.objects)-before
    parts = [obj for obj in imported if obj.type == 'MESH']
    assert len(parts) == 1, (name, len(parts))
    obj = parts[0]
    sources[name] = obj.data
    report['inputs'][name] = {'path': path.relative_to(root).as_posix(),
                            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)

placements = []
def place(name, x, y, scale=1, yaw=0, z=None):
    obj = bpy.data.objects.new(name, sources[name])
    scene.collection.objects.link(obj)
    obj.location = (x,y,land(x,y) if z is None else z)
    obj.scale = (scale,)*3 if isinstance(scale,(float,int)) else scale
    obj.rotation_euler.z = yaw
    placements.append({'asset': name, 'position': list(obj.location), 'scale': list(obj.scale), 'yaw': yaw})
    return obj

for index, (x,y,scale,yaw) in enumerate(cfg['trees']):
    place('broadleaf_tree',x,y,scale,yaw)
    if index < 8:
        for k in range(cfg['foreground_roots']):
            a = yaw+k*math.tau/cfg['foreground_roots']
            length = scale*rng.uniform(.75,1.25)
            pts=[]
            for j in range(5):
                t=j/4
                px=x+math.cos(a+t*.25)*length*t
                py=y+math.sin(a+t*.25)*length*t
                pts.append((px,py,land(px,py)+.03+.6*scale*(1-t)**3))
            tube('Root anchoring tree %02d'%index,pts,.13*scale,root_mat)

# Distinct river-edge rock groups; a quiet bank on camera-right remains open.
for group_y in [-6,-1,4,9,15,22,30,39]:
    for side in [-1,1]:
        for k in range(4):
            y=group_y+rng.uniform(-1.2,1.2)
            x=river(y)+side*(halfwidth(y)+rng.uniform(.05,.8))
            place('field_boulder',x,y,rng.uniform(.55,1.25),rng.uniform(0,math.tau),land(x,y)-.13)
for x,y,spread in cfg['undergrowth_patches']:
    for k in range(15):
        a=rng.uniform(0,math.tau); d=spread*math.sqrt(rng.random())
        px,py=x+math.cos(a)*d,y+math.sin(a)*d
        if abs(px-river(py)) < halfwidth(py)+.7:
            continue
        place('shrub' if k%4==0 else 'fern_bed',px,py,rng.uniform(.75,1.55),a)
place('deadfall',-3.7,5.6,(2.2,1.8,1.5),.9)
place('stump',4.9,3.0,1.2,.6)

# One rooted fracture study on the near bank. The dark strip sits on the
# sampled host; a narrower current lies within its width. This is a study of
# the shared mark language, not a finished sculpted scar or a runtime asset.
scar_paths = [
    [(2.8,3.2),(2.5,4.0),(2.75,4.6),(2.2,5.2),(2.35,6.1),(1.95,7.0)],
    [(2.75,4.6),(3.45,4.9),(3.8,5.55)],
    [(2.35,6.1),(2.9,6.55),(3.0,7.15)]]
for i,control_path in enumerate(scar_paths):
    # Intermediate samples follow the bank instead of cutting across curved
    # ground between control points. Preserve the authored angular branch path.
    path=[]
    samples=cfg['scar']['segment_samples']
    for a,b in zip(control_path,control_path[1:]):
        path.extend([(a[0]+(b[0]-a[0])*j/samples, a[1]+(b[1]-a[1])*j/samples) for j in range(samples)])
    path.append(control_path[-1])
    # Ribbons are explicitly grounded and remain inside dark host margins.
    for name,width,lift,mat in [('Scar edge',cfg['scar']['edge_half_width'],cfg['scar']['edge_lift'],scar_mat),
                              ('Current',cfg['scar']['current_half_width'],cfg['scar']['current_lift'],current_mat)]:
        points=[]; fs=[]
        for j,(x,y) in enumerate(path):
            tangent=Vector(path[min(j+1,len(path)-1)])-Vector(path[max(j-1,0)])
            tangent.normalize()
            across=Vector((-tangent.y,tangent.x))*width*(1-j/(len(path)+.4))
            for sign in [-1,1]:
                px,py=x+sign*across.x,y+sign*across.y
                points.append((px,py,land(px,py)+lift))
            if j:
                a=(j-1)*2; fs.append((a,a+1,a+3,a+2))
        mesh('%s branch %d'%(name,i),points,fs,mat)

fog_mat=bpy.data.materials.new('Distance mist - disable for clear comparison')
fog_mat.use_nodes=True
fog_mat.node_tree.nodes.clear()
volume=fog_mat.node_tree.nodes.new('ShaderNodeVolumeScatter')
volume.inputs['Color'].default_value=(.59,.68,.72,1)
volume.inputs['Density'].default_value=cfg['render']['mist_density']
volume.inputs['Anisotropy'].default_value=.2
output=fog_mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
fog_mat.node_tree.links.new(volume.outputs[0],output.inputs['Volume'])
bpy.ops.mesh.primitive_cube_add(size=1,location=(0,26,9))
fog=bpy.context.object; fog.name='REVIEW ONLY - distant atmosphere'
fog.dimensions=(46,70,25)
fog.data.materials.append(fog_mat)

sun=bpy.data.objects.new('Late daylight',bpy.data.lights.new('Late daylight','SUN'))
scene.collection.objects.link(sun)
sun.rotation_euler=(.58,-.38,-.65)
sun.data.energy=cfg['render']['sun_energy']
sun.data.color=(1,.88,.72)
sun.data.angle=.12
camera=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'))
scene.collection.objects.link(camera)
scene.camera=camera
for view in cfg['views']:
    eye=view.get('eye')
    if eye is None:
        x,y=view['eye_xy']; eye=(x,y,land(x,y)+view['eye_height'])
    camera.location=eye
    camera.rotation_euler=(Vector(view['target'])-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.lens=view['lens']
    for mist in ([True,False] if view['name']=='river-approach' else [True]):
        fog.hide_render=not mist
        name=view['name']+('' if mist else '-clear-daylight')
        scene.render.filepath=str(out/(name+'.png'))
        bpy.ops.render.render(write_still=True)
        report['views'].append({'name':name,'eye':list(eye),'target':view['target'],'lens':view['lens'],'mist':mist})
        print('WOODLAND_STUDY_IMAGE '+name,flush=True)
fog.hide_render=False
report['placements']=placements
report['mesh_instances']=sum(obj.type=='MESH' for obj in scene.objects)
report['authored_curves']=sum(obj.type=='CURVE' for obj in scene.objects)
report['config_sha256']=hashlib.sha256(cfg_path.read_bytes()).hexdigest()
scene['study_note']=cfg['purpose']
scene['source_revision']='dc64aea'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'leyline-woodland-study.blend'),compress=True)
(out/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('LEYLINE_WOODLAND_STUDY_OK '+str(out),flush=True)
