"""Seeded nature fixtures. Run through Blender; all construction uses Godot metres.

Only the six current resource/habitat roles are represented. Exported collision
proxies reproduce the existing tree/boulder boxes, not the decorative leaves.
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
config = json.loads((Path(__file__).resolve().parents[1] / 'nature.json').read_text())
habitat = (project / 'game/art/habitat_look.gd').read_text()
weathered = (project / 'game/art/weathered_look.tres').read_text()
woodland = (project / 'game/art/weathered_woodland.tres').read_text()
resource_source = (project / 'game/scripts/resource_node.gd').read_text()


def hex_colour(name):
    value = re.search(r'@export var ' + name + r' := Color\("([0-9a-f]+)"\)', habitat)[1]
    return tuple(int(value[i:i+2], 16) / 255 for i in (0, 2, 4))


def terrain_colour(name):
    return tuple(float(n) for n in re.search(r'"' + name + r'": Color\(([^)]+)\)', weathered)[1].split(',')[:3])


def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4


def shade(colour, factor):
    return tuple(min(1, max(0, c * factor)) for c in colour)


def mix(a, b, t):
    return tuple(x + (y-x) * t for x, y in zip(a, b))


def xyz(godot):
    return (godot[0], -godot[2], godot[1])


pal = {name: hex_colour(name) for name in ('shrub_green', 'fern_green', 'bark', 'rot')}
pal.update({name: terrain_colour(name) for name in ('grass', 'forest_floor', 'rock', 'dirt')})
meadow = re.search(r'"meadow": \{([^\n]+)', woodland)[1]
pal['leaf'] = tuple(float(n) for n in re.search(r'"leaf": Color\(([^)]+)', meadow)[1].split(',')[:3])
pal['leaf_dark'] = tuple(float(n) for n in re.search(r'"leaf_dark": Color\(([^)]+)', meadow)[1].split(',')[:3])
foliage_shade = float(re.search(r'foliage_shade = ([0-9.]+)', woodland)[1])
pal['leaf'], pal['leaf_dark'] = shade(pal['leaf'], foliage_shade), shade(pal['leaf_dark'], foliage_shade)

# These are a compatibility contract with ResourceNode, not new tuning.
# Fail if that source changes so the study cannot quietly drift from gameplay.
assert 'shape.size = Vector3(0.7, 3.0, 0.7)' in resource_source
assert 'collider.position = Vector3(0, 1.5, 0)' in resource_source
assert 'shape.size = Vector3(1.4, 1.0, 1.2)' in resource_source
assert 'collider.position = Vector3(0, 0.5, 0)' in resource_source
collisions = {'broadleaf_tree': {'size': [0.7, 3.0, 0.7], 'centre': [0, 1.5, 0]},
              'field_boulder': {'size': [1.4, 1.0, 1.2], 'centre': [0, .5, 0]}}
footprints = {'shrub': .65, 'fern_bed': .5, 'deadfall': .85, 'stump': .4}
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
material = bpy.data.materials.new('Weathered nature - vertex colour')
material.use_nodes = True
shader = material.node_tree.nodes.get('Principled BSDF')
shader.inputs['Roughness'].default_value = 1
colour_node = material.node_tree.nodes.new('ShaderNodeVertexColor')
colour_node.layer_name = 'Color'
material.node_tree.links.new(colour_node.outputs['Color'], shader.inputs['Base Color'])


class Geometry:
    def __init__(self, seed):
        self.rng = random.Random(seed)
        self.vertices, self.faces, self.colours = [], [], []

    def face(self, points, colour):
        start = len(self.vertices)
        self.vertices.extend(tuple(p) for p in points)
        self.faces.append(tuple(range(start, len(self.vertices))))
        self.colours.append(tuple(colour))

    def tube(self, points, radii, colour, sides=None, cap=True, ridged=True):
        sides = sides or config['branch_sides']
        rings = []
        points = list(map(Vector, points))
        previous_cross = None
        # Align each segment's cross section with its tangent; stable at verticals.
        for i, (point, radius) in enumerate(zip(points, radii)):
            direction = (points[min(i+1, len(points)-1)] - points[max(i-1, 0)]).normalized()
            # Transport the previous frame; recomputing from UP flips near a
            # vertical tangent and twists a trunk into an hourglass.
            cross = (previous_cross-direction*previous_cross.dot(direction)) if previous_cross is not None else direction.cross(Vector((0, 1, 0)))
            if cross.length < .01:
                cross = direction.cross(Vector((1, 0, 0)))
            cross.normalize()
            previous_cross = cross
            up = direction.cross(cross).normalized()
            ring = []
            for j in range(sides):
                angle = j * math.tau / sides
                ridge = 1 + config['bark_ridge_fraction'] * math.sin(j * 4.7) if ridged else 1
                ring.append(point + (cross * math.cos(angle) + up * math.sin(angle)) * radius * ridge)
            rings.append(ring)
        for i in range(len(rings)-1):
            for j in range(sides):
                k = (j+1) % sides
                self.face([rings[i][j], rings[i][k], rings[i+1][k], rings[i+1][j]],
                          shade(colour, .90 + .17 * (math.sin(j * 3.13) * .5 + .5)))
        if cap:
            self.face(list(reversed(rings[0])), shade(colour, .8))
            self.face(rings[-1], colour)

    def leaf(self, start, end, width, colour, fold=.014):
        start, end = Vector(start), Vector(end)
        direction = end-start
        cross = direction.cross(Vector((0, 1, 0)))
        if cross.length < .001:
            cross = direction.cross(Vector((1, 0, 0)))
        cross = cross.normalized() * width
        middle = start.lerp(end, .46)
        ridge = middle + Vector((0, fold, 0))
        for a, b in [(start, middle+cross), (middle+cross, end), (end, middle-cross), (middle-cross, start)]:
            points = [a, b, ridge]
            if (b-a).cross(ridge-a).y < 0:
                points.reverse()
            self.face(points, colour)

    def object(self, name):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([xyz(p) for p in self.vertices], [], self.faces)
        mesh.update()
        colour = mesh.color_attributes.new(name='Color', type='FLOAT_COLOR', domain='CORNER')
        for polygon, rgb in zip(mesh.polygons, self.colours):
            for index in polygon.loop_indices:
                colour.data[index].color = tuple(linear(c) for c in rgb) + (1,)
        mesh.materials.append(material)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


def tree(g):
    p = config['tree']
    h, radius = p['height'], p['trunk_radius']
    trunk = [(0, -.10, 0), (.015, .4, -.01), (-.04, 1.3, .025),
             (.055, 2.1, -.035), (.17, 2.9, -.07), (.11, h, -.03)]
    g.tube(trunk, [radius * 1.06, radius, radius*.78, radius*.59, radius*.38, .026], pal['bark'])
    for j in range(5):
        angle = j * math.tau/5 + .2
        foot = Vector((math.cos(angle)*.51, -.03, math.sin(angle)*.51))
        g.tube([foot, foot*.45 + Vector((0, .13, 0)), (0, .45, 0)], [.02, .07, .105], pal['bark'])
    for j in range(p['branches']+1):
        angle = j * 2.399 + .35
        level = 2.05 + j * .20
        reach = p['crown_spread'] * (1 - .035 * j)
        start = Vector((.045, level, -.025))
        end = Vector((math.cos(angle)*reach, level+.64, math.sin(angle)*reach))
        if j == p['branches']:
            start, end = Vector(trunk[-2]), Vector(trunk[-1])+Vector((0, .17, 0))
        knee = start.lerp(end, .52) - Vector((0, .12, 0))
        g.tube([start, knee, end], [.11-j*.009, .052, .013], pal['bark'])
        for k in range(p['sprays_per_branch']):
            t = .4 + k*.13
            twig_start = knee.lerp(end, t)
            twig_angle = angle + (-.95 if k%2 else .80)
            tip = twig_start + Vector((math.cos(twig_angle)*.44, .17+k*.055, math.sin(twig_angle)*.44))
            g.tube([twig_start, tip], [.017, .004], pal['bark'], sides=5)
            spray_tips = []
            for shoot in range(6):
                phase = shoot*math.tau/6 + g.rng.uniform(-.22, .22)
                shoot_tip = tip + Vector((math.cos(phase)*.48, g.rng.uniform(-.06, .20), math.sin(phase)*.36))
                g.tube([tip, shoot_tip], [.007, .002], pal['bark'], sides=4)
                spray_tips.append(shoot_tip)
            for leaf_index in range(p['leaves_per_spray']):
                shoot = leaf_index%6
                t = .24 + .72*(leaf_index//6)/max(1, (p['leaves_per_spray']-1)//6)
                centre = tip.lerp(spray_tips[shoot], t)
                phase = shoot*math.tau/6 + (1.05 if (leaf_index//6)%2 else -1.05)
                direction = Vector((math.cos(phase), g.rng.uniform(-.25, .35), math.sin(phase)))
                length = p['leaf_length'] * g.rng.uniform(.75, 1.25)
                colour = mix(pal['leaf_dark'], pal['leaf'], g.rng.uniform(.25, .9))
                g.leaf(centre, centre+direction*length, length*.25,
                       shade(colour, 1+g.rng.uniform(-config['leaf_colour_variation'], config['leaf_colour_variation'])))


def boulder(g):
    p = config['boulder']
    sides = 11
    rings = []
    for level, radius in [(-p['burial'], .75), (.08, 1), (.38, .98), (.73, .82), (1, .43)]:
        ring = []
        for j in range(sides):
            angle = j*math.tau/sides + .14
            r = radius*(1 + .1*math.sin(j*2.3) + .045*math.cos(j*.8+level*9))
            ring.append(Vector((math.cos(angle)*r, level + .035*math.sin(j*1.7), math.sin(angle)*r*.86)))
        rings.append(ring)
    # Enforce the existing resource footprint while retaining irregular contours.
    all_points = [v for ring in rings for v in ring]
    low = [min(v[i] for v in all_points) for i in range(3)]
    high = [max(v[i] for v in all_points) for i in range(3)]
    for v in all_points:
        v.x = ((v.x-low[0])/(high[0]-low[0])-.5)*p['width']
        v.z = ((v.z-low[2])/(high[2]-low[2])-.5)*p['depth']
        v.y = (v.y-low[1])/(high[1]-low[1])*(p['height']+p['burial'])-p['burial']
    for i in range(len(rings)-1):
        for j in range(sides):
            k = (j+1)%sides
            c = shade(pal['rock'], 1+g.rng.uniform(-config['rock_colour_variation'], config['rock_colour_variation']))
            # Moss follows weather-exposed ledges, not random neon triangles.
            mossed = i >= 2 and (math.sin(j*2.1+i) + 1)/2 < p['moss_coverage']
            if mossed:
                c = mix(c, pal['fern_green'], .64)
            a, b, d, e = rings[i][j], rings[i+1][j], rings[i+1][k], rings[i][k]
            for u in range(4):
                for v in range(4):
                    def at(s, t):
                        return a.lerp(e, s).lerp(b.lerp(d, s), t)
                    points = [at(u/4,v/4), at(u/4,(v+1)/4), at((u+1)/4,(v+1)/4), at((u+1)/4,v/4)]
                    centre = sum(points, Vector())/4
                    patch = (math.sin(centre.x*13+centre.z*8)+math.cos(centre.y*17-centre.z*11))*.5
                    mineral = shade(c, 1+patch*.045)
                    # Broken coverage at a finer scale gives moss a ragged margin.
                    if mossed and patch < -.2:
                        mineral = mix(mineral, pal['rock'], .65)
                    g.face(points, mineral)
    g.face(rings[0], shade(pal['rock'], .8))
    g.face(list(reversed(rings[-1])), mix(pal['rock'], pal['fern_green'], .18))
    # Fine horizontal bedding scar on two ledges, contained inside the silhouette.
    for i, j in [(2, 1), (3, 6)]:
        a, b = rings[i][j], rings[i][(j+1)%sides]
        midpoint = a.lerp(b, .5)
        g.face([a.lerp(midpoint, .1), b.lerp(midpoint, .1), midpoint+Vector((0, -.018, 0))], shade(pal['rock'], .68))


def shrub(g):
    p = config['shrub']
    for j in range(p['branches']):
        angle = j*2.399
        end = Vector((math.cos(angle)*p['radius']*.64, p['height']*g.rng.uniform(.7, 1), math.sin(angle)*p['radius']*.64))
        g.tube([(0, -.035, 0), end*.45, end], [.019, .012, .004], pal['bark'], sides=5)
        for k in range(9):
            at = end*(.32+k*.075)
            phase = angle+k*2.4
            vector = Vector((math.cos(phase)*.16, .06, math.sin(phase)*.16))
            g.leaf(at, at+vector, .045, shade(pal['shrub_green'], g.rng.uniform(.9, 1.14)))


def fern(g):
    p = config['fern_bed']
    for j in range(p['fronds']):
        angle = j*math.tau/p['fronds'] + g.rng.uniform(-.12, .12)
        d = Vector((math.cos(angle), 0, math.sin(angle)))
        side = Vector((-d.z, 0, d.x))
        length = p['radius']*g.rng.uniform(.75, 1)
        height = p['height']*g.rng.uniform(.78, 1)
        def at(t):
            return d*(length*t) + Vector((0, height*math.sin(t*math.pi*.80)-.022, 0))
        g.tube([at(k/6) for k in range(7)], [.007*(1-k/7) for k in range(7)], pal['fern_green'], sides=4)
        for k in range(1, p['leaf_pairs']+1):
            t = k/(p['leaf_pairs']+1)
            spread = .115 * math.sin(t*math.pi)**.65 * (1-t*.4)
            for sign in (-1, 1):
                start = at(t)
                end = start+side*sign*spread+d*.035+Vector((0, .01, 0))
                g.leaf(start, end, .020*(1-t*.5), shade(pal['fern_green'], .87+.22*t), fold=.008)


def rotten(g, stump=False):
    p = config['stump' if stump else 'deadfall']
    sides = 13
    if stump:
        bottom = Vector((0, -p['burial'], 0))
        top = Vector((.025, p['height'], -.015))
        axis = Vector((0, 1, 0))
        u, v = Vector((1, 0, 0)), Vector((0, 0, 1))
        radius = p['radius']
    else:
        radius = p['radius']
        bottom = Vector((-p['length']/2, radius-p['burial'], 0))
        top = Vector((p['length']/2, radius-p['burial']+.015, .045))
        axis = (top-bottom).normalized()
        u, v = Vector((0, 1, 0)), Vector((0, 0, 1))
    rings = []
    for k, centre in enumerate([bottom, bottom.lerp(top, .5), top]):
        ring = []
        for j in range(sides):
            angle = j*math.tau/sides
            irregular = 1+.12*math.sin(j*3.1)
            scale = (1-k*.13) if stump else (1-k*.055)
            tip = centre+(u*math.cos(angle)+v*math.sin(angle))*radius*irregular*scale
            if k==2:
                tip += axis*(.033*math.sin(j*1.9))
            ring.append(tip)
        rings.append(ring)
    for i in range(2):
        for j in range(sides):
            k = (j+1)%sides
            g.face([rings[i][j], rings[i][k], rings[i+1][k], rings[i+1][j]], shade(pal['bark'], .85+.28*((j*7)%9)/9))
    # Recessed broken heartwood and a dark hollow, visibly rotten rather than a resource log.
    for ring, centre, inward in [(rings[0], bottom, axis), (rings[-1], top, -axis)]:
        inner = [centre+(p-centre)*.57+inward*.035 for p in ring]
        for j in range(sides):
            k = (j+1)%sides
            g.face([ring[j], ring[k], inner[k], inner[j]], shade(pal['rot'], .9+.12*math.sin(j)))
        g.face(inner, shade(pal['bark'], .38))
    if stump:
        for j in range(5):
            angle = j*math.tau/5+.17
            foot = Vector((math.cos(angle)*p['root_radius'], -.025, math.sin(angle)*p['root_radius']))
            g.tube([(0, .18, 0), foot*.55+Vector((0, .015, 0)), foot], [.065, .045, .012], pal['bark'], sides=5)
    else:
        for t, sign in [(.23, -1), (.70, 1)]:
            start = bottom.lerp(top, t)
            end = start+Vector((.10, .15, .19*sign))
            g.tube([start, end], [.027, .008], pal['bark'], sides=5)


BUILDERS = {'broadleaf_tree': tree, 'field_boulder': boulder, 'shrub': shrub,
            'fern_bed': fern, 'deadfall': lambda g: rotten(g), 'stump': lambda g: rotten(g, True)}


def export(path, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.hide_set(False)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
                             export_yup=True, export_apply=True, export_cameras=False, export_lights=False)


assets = {}
player_source = (project / 'game/scenes/player.tscn').read_text()
player_shape = re.search(r'\[sub_resource type="CapsuleShape3D"[^\]]*\]([^\[]+)', player_source)[1]
player_capsule = {name: float(re.search(name+r' = ([0-9.]+)', player_shape)[1]) for name in ('radius', 'height')}
report = {'study': 'nature', 'seed': config['seed'], 'assets': {}, 'player_capsule': player_capsule,
          'palette_sources': ['game/art/habitat_look.gd', 'game/art/weathered_look.tres', 'game/art/weathered_woodland.tres'],
          'collision_source': 'game/scripts/resource_node.gd',
          'status': 'isolated fixture study; existing world, harvesting and cover rules retained'}
for index, (name, build) in enumerate(BUILDERS.items()):
    seed = config['seed'] + index*7919
    g = Geometry(seed)
    build(g)
    # Test repeatability over geometry AND authored colours, not Blender metadata.
    twin = Geometry(seed)
    build(twin)
    payload = [g.vertices, g.faces, g.colours]
    assert payload == [twin.vertices, twin.faces, twin.colours], name + ' not deterministic'
    assert all(math.isfinite(n) for point in g.vertices for n in point)
    degenerate = 0
    for face in g.faces:
        a = Vector(g.vertices[face[0]])
        area = sum((Vector(g.vertices[face[j]])-a).cross(Vector(g.vertices[face[j+1]])-a).length for j in range(1, len(face)-1))
        degenerate += area < 1e-10
    assert degenerate == 0, (name, degenerate)
    obj = g.object(name)
    assets[name] = obj
    bounds = [[min(p[i] for p in g.vertices) for i in range(3)], [max(p[i] for p in g.vertices) for i in range(3)]]
    radius = max(math.hypot(p[0], p[2]) for p in g.vertices)
    if name in footprints:
        assert radius <= footprints[name], (name, radius, footprints[name])
    export(output / (name + '.glb'), [obj])
    report['assets'][name] = {'visual_bounds': bounds, 'triangles': sum(len(f)-2 for f in g.faces),
                             'geometry_sha256': hashlib.sha256(json.dumps(payload).encode()).hexdigest(),
                             'mesh_parts': 1, 'materials': 1, 'ground_pivot': True,
                             'collision': collisions.get(name), 'habitat_radius': footprints.get(name),
                             'horizontal_radius': radius, 'degenerate_faces': degenerate}
    if name in collisions:
        contract = collisions[name]
        bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(contract['centre']))
        proxy = bpy.context.object
        proxy.name = name+'-convcolonly'
        proxy.dimensions = (contract['size'][0], contract['size'][2], contract['size'][1])
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        export(output / (name+'_collision.glb'), [proxy])
        bpy.data.objects.remove(proxy, do_unlink=True)

# Keep a small contextual land surface for reviewing grounding and composition.
# It is a render aid; editable game terrain continues to be generated by Godot.
source = bpy.data.collections.new('SOURCE - surface anchored fixtures')
bpy.context.scene.collection.children.link(source)
for obj in assets.values():
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    source.objects.link(obj)
source.hide_render, source.hide_viewport = True, True


def surface(x, z):
    return .11*math.sin(x*.7)*math.cos(z*.65)+.19*math.exp(-((x+1)**2+(z-2)**2)/6)


def place(name, x, z, rotation=0, scale=1):
    obj = assets[name].copy()
    obj.data = assets[name].data
    bpy.context.scene.collection.objects.link(obj)
    obj.location = xyz((x, surface(x, z), z))
    obj.rotation_euler.z = rotation
    obj.scale = (scale,)*3


layout = [('broadleaf_tree', -1.4, -1.1, .25, 1),
          ('field_boulder', .15, .30, -.4, 1), ('field_boulder', .72, .67, .5, .56),
          ('shrub', 1.9, -.6, .6, 1), ('shrub', -2.1, -.25, 2.1, .8),
          ('fern_bed', -.83, .27, .2, 1), ('fern_bed', -1.26, -.15, 1.2, .84),
          ('fern_bed', 1.2, -.17, 2.4, .88), ('fern_bed', 2.0, .2, 3.4, .8),
          ('deadfall', -.85, 1.8, -.36, 1), ('stump', 1.38, 1.4, .8, 1)]
for entry in layout:
    place(*entry)
report['review_placements'] = [{'asset': a, 'position': [x, surface(x,z), z], 'rotation': r, 'scale': s} for a,x,z,r,s in layout]
land = Geometry(config['seed']+1000)
steps, extent = 36, 3.3
for i in range(steps):
    for j in range(steps):
        x, z = -extent+i*extent*2/steps, -extent+j*extent*2/steps
        width = extent*2/steps
        points = [(x, surface(x,z), z), (x, surface(x,z+width), z+width),
                  (x+width, surface(x+width,z+width), z+width), (x+width, surface(x+width,z), z)]
        # Moss islands fade into loam around a quiet worn opening.
        t = min(.92, max(.10, .48+.24*math.sin(x*1.7+z*.8)+.17*math.cos(z*2.2-x)))
        colour = shade(mix(pal['dirt'], pal['forest_floor'], t), 1+land.rng.uniform(-.035,.035))
        land.face(points, colour)
land_obj = land.object('Review land - not exported')

# Sparse, small turf tufts group around the existing cover instead of carpeting it.
grass = Geometry(config['seed']+1001)
for j in range(260):
    x, z = grass.rng.uniform(-2.65, 2.65), grass.rng.uniform(-2.1, 2.8)
    patch = math.sin(x*1.8+z*.7)+math.cos(z*2.1)
    if patch < -.1 or (-.6 < z < .5 and abs(x) < .55):
        continue
    base = Vector((x, surface(x,z)-.015, z))
    for blade in range(5):
        angle = grass.rng.random()*math.tau
        tip = base+Vector((math.cos(angle)*.055, grass.rng.uniform(.10,.21), math.sin(angle)*.055))
        grass.leaf(base, tip, .009, shade(pal['grass'], grass.rng.uniform(.8, 1.05)), fold=.006)
grass.object('Review turf - not exported')

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 1200
scene.render.resolution_percentage = 100
scene.world.color = (.16,.18,.16)
scene.view_settings.view_transform = 'AgX'


def aim(obj, point):
    obj.rotation_euler = (Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()


for name, position, power, size in [('Soft daylight', (-4,-4,8), 1900, 5), ('Sky fill', (4,3,6), 1350, 5)]:
    light = bpy.data.lights.new(name, 'AREA')
    light.energy, light.shape, light.size = power, 'DISK', size
    obj = bpy.data.objects.new(name, light)
    scene.collection.objects.link(obj)
    obj.location = position
    aim(obj, (0,0,1))
camera = bpy.data.objects.new('Nature review camera', bpy.data.cameras.new('Nature review camera'))
scene.collection.objects.link(camera)
camera.location = (6,-10,6.5)
aim(camera, (-.65,-.55,1.8))
camera.data.type, camera.data.ortho_scale = 'ORTHO', 9.2
scene.camera = camera
scene.render.filepath = str(output / 'nature-landscape.png')
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'nature-study.blend'))
bpy.ops.render.render(write_still=True)
camera.location = (3.8,-6.0,2.0)
aim(camera, xyz((.0,.38,-.15)))
camera.data.type, camera.data.lens = 'PERSP', 52
scene.render.filepath = str(output / 'nature-ground-detail.png')
bpy.ops.render.render(write_still=True)
(output / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('WROUGHTWILD_NATURE_OK ' + str(output))
