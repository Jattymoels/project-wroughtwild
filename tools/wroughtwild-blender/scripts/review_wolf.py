"""Neutral inspection of one wolf GLB; never changes its source or game assets.

Blender --background --python-exit-code 1 --python review_wolf.py -- INPUT OUTPUT [BASELINE_REPORT]
Uses the actual imported mesh for every image. No generated illustration is a
substitute for these renders. The editable review scene includes the source rig.
"""
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

arguments = sys.argv[sys.argv.index('--') + 1:]
assert len(arguments) in (2, 3), 'INPUT OUTPUT [BASELINE_REPORT]'
source, output = map(Path, arguments[:2])
matched = json.loads(Path(arguments[2]).read_text()) if len(arguments) == 3 else None
source = source.resolve()
output = output.resolve()
assert source.is_file() and source.suffix.lower() == '.glb', source
assert not output.exists(), 'Use a new review directory; preserve previous evidence.'
output.mkdir(parents=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
rig_helpers = {bone.custom_shape for obj in bpy.context.scene.objects
               if obj.type == 'ARMATURE' for bone in obj.pose.bones
               if bone.custom_shape}
for helper in rig_helpers:
    helper.hide_render = True
meshes = [obj for obj in bpy.context.scene.objects
          if obj.type == 'MESH' and obj not in rig_helpers and not obj.hide_render]
assert meshes, 'The input has no visible mesh.'
for obj in bpy.context.scene.objects:
    if obj.type == 'ARMATURE':
        obj.data.pose_position = 'REST'
    if obj.animation_data:
        obj.animation_data_clear()
bpy.context.view_layer.update()
corners = [obj.matrix_world @ Vector(p) for obj in meshes for p in obj.bound_box]
lo = Vector(tuple(min(p[i] for p in corners) for i in range(3)))
hi = Vector(tuple(max(p[i] for p in corners) for i in range(3)))
assert all(math.isfinite(v) for p in corners for v in p)
centre = (lo + hi) * .5
extent = max(hi - lo)
report = {'input': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'coordinates': 'Blender metres: +Y front, +Z up',
          'bounds': [list(lo), list(hi)], 'meshes': [], 'views': [],
          'stage': 'Actual imported geometry review; no art acceptance implied.',
          'matched_to_sha256': matched['sha256'] if matched else None}
for obj in meshes:
    obj.data.calc_loop_triangles()
    report['meshes'].append({'name': obj.name, 'triangles': len(obj.data.loop_triangles),
                            'materials': len(obj.data.materials)})

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = 1280
scene.render.resolution_y = 960
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.32, .35, .39, 1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .4

def material(name, colour):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    bsdf = result.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*colour, 1)
    bsdf.inputs['Roughness'].default_value = .78
    return result

clay = material('Neutral clay - no textures or emission', (.34, .35, .36))
clay.use_fake_user = True  # Keep clay available after saving with the final material view.
floor_material = material('Neutral ground', (.17, .18, .19))
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, lo.z - .005))
floor = bpy.context.object
floor.name = 'REVIEW ONLY - floor'
floor.data.materials.append(floor_material)

def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat('-Z', 'Y').to_euler()

for name, at, power, size in [('Key', (-3, 4, 6), 650, 5),
                              ('Fill', (4, 1, 4), 300, 4),
                              ('Rim', (1, -4, 5), 600, 3)]:
    obj = bpy.data.objects.new(name, bpy.data.lights.new(name, 'AREA'))
    scene.collection.objects.link(obj)
    obj.location = at
    obj.data.energy = power
    obj.data.shape = 'DISK'
    obj.data.size = size
    aim(obj, centre)
camera = bpy.data.objects.new('REVIEW ONLY - camera', bpy.data.cameras.new('Camera'))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.type = 'ORTHO'

def shot(name, offset, target, span, use_clay=True):
    prior = next((view for view in matched['views'] if view['name'] == name), None) if matched else None
    if matched:
        assert prior, 'Baseline lacks required view: ' + name
        target, span = prior['target'], prior['ortho_scale']
    camera.location = prior['camera'] if prior else Vector(target) + Vector(offset)
    camera.data.ortho_scale = span
    aim(camera, target)
    scene.view_layers[0].material_override = clay if use_clay else None
    scene.render.filepath = str(output / (name + '.png'))
    bpy.ops.render.render(write_still=True)
    report['views'].append({'name': name, 'camera': list(camera.location),
                            'target': list(target), 'ortho_scale': span,
                            'material_override': 'clay' if use_clay else None})
    print('WOLF_REVIEW_IMAGE ' + name, flush=True)

shot('clay-side', (-6, 0, 0), centre, extent * 1.2)
shot('clay-front', (0, 6, 0), centre, extent * .78)
shot('clay-rear', (0, -6, 0), centre, extent * .78)
shot('clay-three-quarter', (-4, 6, 1.8), centre, extent * 1.15)
head = Vector((centre.x, hi.y - .30, hi.z - .38))
shot('clay-head', (-2, 4, .7), head, extent * .44)
shot('material-three-quarter', (-4, 6, 1.8), centre, extent * 1.15, False)
scene['review_note'] = report['stage']
scene['input_sha256'] = report['sha256']
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'wolf-review.blend'), compress=True)
(output / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('WOLF_REVIEW_OK ' + str(output), flush=True)
