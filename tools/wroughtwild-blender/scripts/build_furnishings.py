"""Existing furnishing catalogue, authored in Godot metres through local Blender.

Study assets only. Keep StationSite/PieceMesh's actual primitive bodies, offsets,
station tier silhouettes and construction IDs; no gameplay or save changes.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import re
import sys

import bpy
from mathutils import Vector

project, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
config = json.loads((Path(__file__).resolve().parents[1] / 'furnishings.json').read_text())
shapes = {s['id']: s for s in json.loads((project / 'data/tuning/construction.json').read_text())['shapes']}
station_source = (project / 'game/art/station_look.gd').read_text()
piece_source = (project / 'game/scripts/piece_mesh.gd').read_text()
station_scene = (project / 'game/scenes/station_site.tscn').read_text()
station_size = [float(n) for n in re.search(r'size = Vector3\(([^)]+)', station_scene)[1].split(',')]
station_centre = [float(n) for n in re.search(r'position = Vector3\(([^)]+)', station_scene)[1].split(',')]
assert 'floor_y := -0.5' in piece_source
assert 'Vector3(0.0, -(1.0 - size.y) * 0.5, 0.0)' in piece_source
assert 'box.size = Vector3(size.x * 0.8, size.y * 0.5, size.z * 0.8)' in piece_source
assert 'Vector3(0.0, -size.y * 0.5 + size.y * 0.25, 0.0)' in piece_source
assert 'Vector3(0.94,0.18,0.92)' in station_source and 'Vector3(0.65,0.4,0.45)' in station_source
station_ids = ('workbench', 'mason_yard', 'forge_basic', 'forge_improved')
crafting = json.loads((project / 'data/tuning/crafting.json').read_text())
assert set(station_ids).issubset({s['id'] for s in crafting['stations']})
collisions = {name: {'size': station_size, 'centre': station_centre} for name in station_ids}
# Review proposal only: retain the one-cell horizontal obstruction and solid
# primitive, but bring its top down to the work surface or forge silhouette.
candidate_heights = config['candidate_collision_height_m']
assert set(candidate_heights) == set(station_ids)
candidates = {name:{'size':[station_size[0],height,station_size[2]],'centre':[0,height/2,0]}
              for name,height in candidate_heights.items()}
chest_size, fire_size = shapes['chest']['size_m'], shapes['campfire']['size_m']
collisions['chest'] = {'size': chest_size, 'centre': [0, -(1-chest_size[1])*.5, 0]}
collisions['campfire'] = {'size': [fire_size[0]*.8, fire_size[1]*.5, fire_size[2]*.8],
                         'centre': [0, -fire_size[1]*.25, 0]}
floors = dict.fromkeys(station_ids, 0.)
floors.update(chest=-.5, campfire=-fire_size[1]*.5)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
rng = random.Random(config['seed'])


def xyz(p):
    return (p[0], -p[2], p[1])


def linear(c):
    return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4


def colour(name):
    value = re.search(r'@export var ' + name + r' := Color\("([0-9a-f]+)"\)', station_source)[1]
    return tuple(int(value[i:i+2], 16)/255 for i in (0, 2, 4))


def noise2(x, y):
    ix, iy = math.floor(x), math.floor(y)
    sx, sy = x-ix, y-iy
    sx, sy = sx*sx*(3-2*sx), sy*sy*(3-2*sy)
    def value(a, b):
        n = ((a*374761393+b*668265263+config['seed']*69069) ^ 1274126177) & 0xffffffff
        n = ((n ^ (n >> 13))*1274126177) & 0xffffffff
        return (n ^ (n >> 16))/0xffffffff*2-1
    a = value(ix,iy)*(1-sx)+value(ix+1,iy)*sx
    b = value(ix,iy+1)*(1-sx)+value(ix+1,iy+1)*sx
    return a*(1-sy)+b*sy


def material(name, rgb, texture=None, factor=1., emission=0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    rgba = tuple(linear(c*factor) for c in rgb)+(1,)
    shader.inputs['Base Color'].default_value = rgba
    mat.diffuse_color = rgba
    shader.inputs['Roughness'].default_value = config['wood_roughness'] if texture == 'wood' else .95
    if texture == 'iron':
        shader.inputs['Roughness'].default_value = config['iron_roughness']
        shader.inputs['Metallic'].default_value = config['iron_metallic']
    if emission:
        shader.inputs['Emission Color'].default_value = rgba
        shader.inputs['Emission Strength'].default_value = emission
    if texture:
        width, height = 128, 256
        pixels = []
        for v in range(height):
            for u in range(width):
                noise = math.sin(u*71.3+v*18.7)*math.cos(u*7.2-v*23.1)
                if texture == 'wood':
                    bend = 1.7*math.sin(v*.03)+.6*math.sin(v*.07+u*.03)
                    fibre = .58*math.sin((u+bend)*1.83)+.3*math.sin((u+bend)*.31)+noise*.12
                    value = 1+fibre*config['grain_strength']
                else:
                    strength = config['iron_mottle_strength'] if texture == 'iron' else config['stone_mottle_strength']
                    value = 1+(noise2(u*.065,v*.065)*.65+noise2(u*.26,v*.26)*.25+noise*.10)*strength
                pixels.extend([min(1., max(0., c*factor*value)) for c in rgb]+[1.])
        image = bpy.data.images.new(name+' colour', width=width, height=height)
        image.colorspace_settings.name = 'sRGB'
        image.pixels.foreach_set(pixels)
        image.pack()
        node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = image
        mat.node_tree.links.new(node.outputs['Color'], shader.inputs['Base Color'])
    return mat


mats = {
    'timber': material('Weathered station timber', colour('timber'), 'wood', 1.12),
    'legs': material('Dark joined timber', colour('legs'), 'wood'),
    'stone': material('Dressed workshop stone', colour('stone'), 'stone'),
    'stone_dark': material('Soot stained hearth stone', colour('stone'), 'stone', .63),
    'iron': material('Worn forged iron', colour('iron'), 'iron', .73),
    'char': material('Charred wood and coal', colour('legs'), 'wood', .35),
    'ember': material('Restrained hearth embers', colour('ember'), emission=config['ember_emission']),
}
parts = []


def finish(obj, name, mat, bevel=True):
    obj.name = name
    obj.data.materials.append(mats[mat] if isinstance(mat, str) else mat)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Worn arris', 'BEVEL')
        mod.width = min(config['edge_bevel_m'], min(obj.dimensions)*.20)
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Portable UVs: the longest face axis follows the grain, so boards do not
    # acquire cross-grain stripes when the furniture turns in the world.
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new()
    for polygon in obj.data.polygons:
        normal = max(range(3), key=lambda a: abs(polygon.normal[a]))
        axes = [a for a in range(3) if a != normal]
        long = max(axes, key=lambda a: obj.dimensions[a])
        short = next(a for a in axes if a != long)
        for index in polygon.loop_indices:
            point = obj.data.vertices[obj.data.loops[index].vertex_index].co
            uv.data[index].uv = (point[short]/max(.001, obj.dimensions[short])+.5,
                                 point[long]/max(.001, obj.dimensions[long])+.5)
    parts.append(obj)
    return obj


def box(name, centre, size, mat, bevel=True, turn=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(centre))
    obj = bpy.context.object
    obj.dimensions = (size[0], size[2], size[1])
    finish(obj, name, mat, bevel)
    obj.rotation_euler.z = -turn
    return obj


def rod(name, a, b, radius, mat, sides=8):
    a, b = Vector(xyz(a)), Vector(xyz(b))
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius, depth=(b-a).length, location=(a+b)/2)
    obj = bpy.context.object
    finish(obj, name, mat, False)
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return obj


def rivet(x, y, z):
    rod('Iron fastening', (x,y,z-.006), (x,y,z+.006), .011, 'iron')


def bench(stone=False):
    for x in (-.32, .32):
        for z in (-.32, .32):
            box('Mortised leg', (x,.40,z), (.16,.80,.16), 'legs')
            rivet(x,.66,z+.082)
        box('Lower side rail', (x,.24,0), (.09,.12,.70), 'legs')
    box('Through stretcher', (0,.24,0), (.78,.105,.10), 'legs')
    for z in (-.34,.34):
        box('Top apron', (0,.72,z), (.82,.13,.10), 'legs')
    if stone:
        box('Stone worktop', (0,.86,0), (.94,.18,.92), 'stone')
        box('Dressed workpiece', (-.05,1.02,.06), (.48,.14,.33), 'stone_dark')
        rod('Masonry chisel', (.20,.985,-.12), (.35,1.005,.12), .012, 'iron')
        box('Mallet head', (-.23,1.005,-.23), (.16,.10,.075), 'legs')
        rod('Mallet handle', (-.23,.98,-.21), (-.1,.98,.09), .02, 'timber')
        for i in range(4):
            box('Small stone offcut', (.22+i*.042,.967,-.28+i*.013), (.031,.025,.04), 'stone_dark', turn=i*.7)
    else:
        for i in range(5):
            box('Workbench plank', (0,.86,-.46+(i+.5)*.92/5), (.94,.18,.92/5-config['plank_seam_m']), 'timber')
        box('Vice fixed jaw', (.26,.985,.31), (.26,.12,.07), 'legs')
        box('Vice moving jaw', (.26,.94,.418), (.26,.16,.045), 'timber')
        rod('Vice screw', (.26,.935,.30), (.26,.935,.459), .022, 'iron')
        rod('Vice handle', (.19,.935,.459), (.33,.935,.459), .012, 'iron')
        box('Hand plane body', (-.18,.983,.03), (.12,.065,.26), 'legs')
        box('Hand plane iron', (-.18,1.03,.015), (.08,.045,.055), 'iron')
        box('Bench stop', (-.26,.975,-.29), (.22,.05,.075), 'legs')


def chest():
    w,h,d = chest_size
    y0, split = -.5, -.5+h*.72
    box('Chest bottom', (0,y0+.055,0), (w-.04,.11,d-.04), 'legs')
    for i in range(5):
        x = -w/2+(i+.5)*w/5
        for z in (-d/2+.045,d/2-.045):
            box('Chest wall board', (x,(y0+split)/2,z), (w/5-config['plank_seam_m'],split-y0,.07), 'timber')
    for x in (-w/2+.035,w/2-.035):
        for i in range(4):
            z = -d/2+(i+.5)*d/4
            box('Chest end board', (x,(y0+split)/2,z), (.07,split-y0,d/4-config['plank_seam_m']), 'timber')
    for z in (-d/2+.008,d/2-.008):
        for x in (-w*.33,w*.33):
            box('Chest iron strap', (x,(y0+split)/2,z), (.048,split-y0,.015), 'iron')
            for y in (y0+.07,split-.045):
                rivet(x,y,z)
    box('Latch plate', (0,split-.075,d/2-.009), (.078,.12,.018), 'iron')
    body = join('chest_body', parts[:])
    parts.clear()
    lid_height = h*.28
    for i in range(5):
        box('Chest lid board', (-w/2+(i+.5)*w/5,split+(lid_height-.012)/2,0),
            (w/5-config['plank_seam_m'],lid_height-.012,d-.018), 'timber')
    for x in (-w*.33,w*.33):
        box('Lid iron strap', (x,y0+h-.008,0), (.048,.016,d-.012), 'iron')
        rod('Rear hinge pin', (x-.05,split,-d/2+.02), (x+.05,split,-d/2+.02), .016, 'iron')
        box('Lid front band', (x,split+lid_height/2,d/2-.008), (.048,lid_height,.014), 'iron')
    box('Latch tongue', (0,split+.005,d/2-.011), (.033,.092,.018), 'iron')
    hinge = (0,split,-d/2+.02)
    lid = join('chest_lid_hinge', parts[:], hinge)
    parts.clear()
    return [body,lid], hinge


def forge(improved=False):
    box('Forge iron base', (0,.40,0), (.90,.80,.90), 'iron')
    for x in (-.36,.36):
        for row in range(4):
            for z in (-.222,.222):
                box('Hearth pier stone', (x,.8+(row+.5)*.175,z), (.18,.169,.438), 'stone_dark' if row<2 else 'stone')
    for row in range(4):
        for col in range(3):
            box('Rear firebrick', ((col-1)*.18,.8+(row+.5)*.175,-.388), (.174,.169,.115), 'stone_dark')
    box('Forge lintel', (0,1.50,0), (.95,.15,.95), 'iron')
    box('Hearth bed', (0,.818,.03), (.57,.035,.62), 'char')
    box('Hearth lip', (0,.89,.37), (.59,.16,.15), 'stone_dark')
    for i in range(18):
        x,z = rng.uniform(-.235,.235),rng.uniform(-.24,.25)
        box('Hearth coal', (x,.846,z), (.06,.035,.055), 'ember' if i%3 == 0 else 'char', turn=rng.random()*3)
    box('Ash cleanout', (0,.31,.449), (.43,.24,.018), 'char')
    box('Cleanout pull', (0,.33,.468), (.16,.03,.016), 'iron')
    for x in (-.38,.38):
        for y in (.10,.68):
            rivet(x,y,.45)
    if improved:
        # The taller metal hood is the existing upgrade cue. No smoke simulator.
        box('Upgraded hood', (0,1.7425,.20), (.65,.365,.45), 'iron')
        box('Hood crown lip', (0,1.938,.20), (.65,.044,.45), 'iron')
        for y in (.20,.65):
            for z in (-.451,.451):
                box('Upgrade iron band', (0,y,z), (.92,.065,.023), 'iron')
                for x in (-.36,.36):
                    rivet(x,y,z)
        for x in (-.23,0,.23):
            box('Hood seam', (x,1.765,.426), (.012,.33,.006), 'char', False)


def campfire():
    w,h,d = fire_size
    floor = -h*.5
    for i in range(3):
        angle = i*math.pi/3+.3
        axis = Vector((math.cos(angle),0,math.sin(angle)))
        centre = Vector((0,floor+.072+i*.032,0))
        a,b = centre-axis*w*.37, centre+axis*w*.37
        rod('Charred fuel log', a,b,h*.135,'char',10)
        # Exposed ends are still wood; no stones or free-standing flame collider.
        rod('Cut log end', a-axis*.001,a+axis*.005,h*.123,'legs',10)
        for j in range(3):
            at = centre+axis*((j-1)*.13)
            box('Glowing char fissure', (at.x,at.y+h*.125,at.z), (.045,.008,.012), 'ember',False,turn=-angle)
    for i in range(16):
        angle,radius = rng.random()*math.tau,rng.uniform(.02,.22)
        box('Coal heap', (math.cos(angle)*radius,floor+.045,math.sin(angle)*radius),
            (.06,.075,.058), 'ember' if i%4 == 0 else 'char',turn=angle)


def join(name, objects, pivot=(0,0,0)):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.context.scene.cursor.location = xyz(pivot)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return obj


def export(path, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
                             export_yup=True,export_apply=True,export_cameras=False,export_lights=False)


def geometry(objects):
    bpy.context.view_layer.update()
    payload, points = [],[]
    for obj in objects:
        verts = [obj.matrix_world @ v.co for v in obj.data.vertices]
        godot = [(v.x,v.z,-v.y) for v in verts]
        points.extend(godot)
        obj.data.calc_loop_triangles()
        assert all(t.area > 1e-12 for t in obj.data.loop_triangles), obj.name+' degenerate triangle'
        assert all(math.isfinite(c) for v in godot for c in v)
        payload.append([obj.name,godot,[(list(p.vertices),p.material_index) for p in obj.data.polygons]])
    bounds = [[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
    return bounds,hashlib.sha256(json.dumps(payload).encode()).hexdigest()


player = (project/'game/scenes/player.tscn').read_text()
capsule = re.search(r'\[sub_resource type="CapsuleShape3D"[^\]]*\]([^\[]+)',player)[1]
report = {'study':'furnishings','seed':config['seed'],'assets':{},
          'player_capsule': {key:float(re.search(key+r' = ([0-9.]+)',capsule)[1]) for key in ('height','radius')},
          'status':'isolated mesh study; normal game keeps current art, collision, interactions and saves',
          'collision_sources':['game/scenes/station_site.tscn','game/scripts/piece_mesh.gd','data/tuning/construction.json'],
          'palette_source':'game/art/station_look.gd'}
builders = {'workbench':lambda:bench(), 'mason_yard':lambda:bench(True), 'forge_basic':lambda:forge(),
            'forge_improved':lambda:forge(True), 'chest':chest, 'campfire':campfire}
assets = {}
for index,(name,build) in enumerate(builders.items()):
    parts.clear()
    rng.seed(config['seed']+index*7919)
    result = build()
    objects, hinge = result if name == 'chest' else ([join(name,parts[:])],None)
    parts.clear()
    bounds,digest = geometry(objects)
    assert abs(bounds[0][1]-floors[name]) < .01, (name,'floor',bounds)
    extent = collisions[name]['size']
    if name != 'campfire':
        assert bounds[0][0]>=-extent[0]/2-.00001 and bounds[1][0]<=extent[0]/2+.00001, (name,'width',bounds)
        assert bounds[0][2]>=-extent[2]/2-.00001 and bounds[1][2]<=extent[2]/2+.00001, (name,'depth',bounds)
    root = bpy.data.objects.new(name,None)
    bpy.context.scene.collection.objects.link(root)
    for obj in objects:
        obj.parent=root
    export(output/(name+'.glb'),[root]+objects)
    report['assets'][name] = {'visual_bounds':bounds,'geometry_sha256':digest,
        'mesh_parts':len(objects),'triangles':sum(len(o.data.loop_triangles) for o in objects),
        'material_surfaces':sum(len({p.material_index for p in o.data.polygons}) for o in objects),
        'floor_y':floors[name],'collision':collisions[name],'candidate_collision':candidates.get(name),'lid_hinge':hinge,
        'front_axis':'+Z','ground_lift':-floors[name]}
    assets[name]=[root]+objects
    proxy=box(name+'-convcolonly',collisions[name]['centre'],extent,'iron',False)
    export(output/(name+'_collision.glb'),[proxy])
    bpy.data.objects.remove(proxy,do_unlink=True)
    if name in candidates:
        proxy=box(name+'-convcolonly',candidates[name]['centre'],candidates[name]['size'],'iron',False)
        export(output/(name+'_fit_collision.glb'),[proxy])
        bpy.data.objects.remove(proxy,do_unlink=True)

source=bpy.data.collections.new('SOURCE - game pivots; chest lid has a rear hinge')
bpy.context.scene.collection.children.link(source)
for objects in assets.values():
    for obj in objects:
        for collection in list(obj.users_collection):
            collection.objects.unlink(obj)
        source.objects.link(obj)
source.hide_render,source.hide_viewport=True,True
parts.clear()


def instance(name,position,turn=0):
    parent=bpy.data.objects.new(name+' display',None)
    bpy.context.scene.collection.objects.link(parent)
    parent.location=xyz((position[0],position[1]-floors[name],position[2]))
    parent.rotation_euler.z=-turn
    for obj in assets[name][1:]:
        clone=obj.copy()
        bpy.context.scene.collection.objects.link(clone)
        clone.parent=parent
    return parent


def aim(obj,point):
    obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()


scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=32
scene.cycles.use_denoising=True
scene.render.resolution_x,scene.render.resolution_y=1800,1200
scene.render.resolution_percentage=100
scene.world.color=(.19,.20,.18)
scene.view_settings.view_transform='AgX'
floor_mat=material('Neutral review slate',(.24,.265,.245))
box('Review floor',(0,-.065,0),(200,.1,200),floor_mat,False)
display=[]
layout={'workbench':(-1.65,0,1.30),'mason_yard':(0,0,1.30),'chest':(1.65,0,1.30),
        'forge_basic':(-1.65,0,-1.25),'forge_improved':(0,0,-1.25),'campfire':(1.65,0,-1.25)}
for name,position in layout.items():
    display.append(instance(name,position))
    box('Review plinth '+name,(position[0],-.025,position[2]),(1.25,.05,1.22),floor_mat)
for name,position,power,size in [('Warm daylight',(-3,-4,7),1700,5),('Sky fill',(4,2,5),1150,4)]:
    light=bpy.data.lights.new(name,'AREA')
    light.energy,light.shape,light.size=power,'DISK',size
    obj=bpy.data.objects.new(name,light)
    scene.collection.objects.link(obj)
    obj.location=position
    aim(obj,(0,0,.7))
camera=bpy.data.objects.new('Furnishings review camera',bpy.data.cameras.new('Furnishings review camera'))
scene.collection.objects.link(camera)
camera.location=(6,-10,8)
aim(camera,(0,0,.5))
camera.data.type,camera.data.ortho_scale='ORTHO',7.5
scene.camera=camera
scene.render.filepath=str(output/'furnishings-catalogue.png')
bpy.ops.wm.save_as_mainfile(filepath=str(output/'furnishings-study.blend'))
bpy.ops.render.render(write_still=True)
# Closer functional workface view, using the same unscaled exported geometry.
for obj in display:
    obj.hide_render=True
    for child in obj.children:
        child.hide_render=True
for obj in bpy.data.objects:
    if obj.name.startswith('Review plinth'):
        obj.hide_render=True
for name,position in [('workbench',(-1.15,0,0)),('mason_yard',(.1,0,0)),('forge_improved',(1.35,0,0)),('chest',(-1.35,0,1.4)),('campfire',(1.0,0,1.7))]:
    instance(name,position)
camera.location=(4,-7,4.8)
aim(camera,xyz((0,.65,.55)))
camera.data.ortho_scale=5.6
scene.render.filepath=str(output/'furnishings-workshop.png')
bpy.ops.render.render(write_still=True)
(output/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('WROUGHTWILD_FURNISHINGS_OK '+str(output))
