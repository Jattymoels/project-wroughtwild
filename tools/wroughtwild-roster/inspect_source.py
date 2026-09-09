"""Blender source inspection, preserving raw generation and all game assets.

blender -b --python-exit-code 1 --python inspect_source.py -- SOURCE.glb NEW_OUTPUT
View labels refer to imported coordinates, not assumed animal anatomy. Uniform
normalisation is for inspection only, not a selected gameplay size or facing.
"""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

source, output = (Path(p).resolve() for p in sys.argv[sys.argv.index('--') + 1:])
assert source.is_file() and not output.exists()
output.mkdir(parents=True)
raw = source.read_bytes()
source_hash = hashlib.sha256(raw).hexdigest()
assert raw[:4] == b'glTF'
size, kind = struct.unpack_from('<II', raw, 12)
assert kind == 0x4E4F534A
gltf = json.loads(raw[20:20+size])
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
assert meshes
points = [obj.matrix_world @ v.co for obj in meshes for v in obj.data.vertices]
assert all(math.isfinite(v) for p in points for v in p)
lo = Vector([min(p[i] for p in points) for i in range(3)])
hi = Vector([max(p[i] for p in points) for i in range(3)])
scale = 2.0/max(hi-lo)
centre = Vector(((lo.x+hi.x)/2, (lo.y+hi.y)/2, lo.z))
transform = Matrix.Scale(scale, 4) @ Matrix.Translation(-centre)
report = {'source': source.name, 'source_sha256': source_hash,
          'blender': bpy.app.version_string, 'generator': gltf.get('asset', {}),
          'stage': 'Raw generated source inspection; no rig, animation or runtime acceptance.',
          'raw_bounds': [list(lo), list(hi)], 'review_uniform_scale': scale,
          'review_size_note': 'Longest dimension = 2 inspection units; NOT game metres/body fit.',
          'meshes': [], 'views': [], 'armatures': sum(o.type == 'ARMATURE' for o in bpy.data.objects),
          'animations': len(gltf.get('animations', [])), 'skins': len(gltf.get('skins', [])),
          'emission_textures': sum('emissiveTexture' in m for m in gltf.get('materials', []))}
for obj in meshes:
    mesh = obj.data
    mesh.calc_loop_triangles()
    verts = np.empty((len(mesh.vertices), 3), dtype=np.float32)
    mesh.vertices.foreach_get('co', verts.ravel())
    triangles = np.empty((len(mesh.loop_triangles), 3), dtype=np.int32)
    mesh.loop_triangles.foreach_get('vertices', triangles.ravel())
    assert np.isfinite(verts).all() and (triangles >= 0).all() and (triangles < len(verts)).all()
    areas = np.linalg.norm(np.cross(verts[triangles[:, 1]]-verts[triangles[:, 0]],
                                   verts[triangles[:, 2]]-verts[triangles[:, 0]]), axis=1)/2
    report['meshes'].append({'name': obj.name, 'vertices': len(verts),
                            'triangles': len(triangles), 'uv_layers': len(mesh.uv_layers),
                            'materials': len(mesh.materials),
                            'zero_area_triangles': int((areas <= 1e-12).sum()),
                            'geometry_sha256': hashlib.sha256(verts.tobytes()+triangles.tobytes()).hexdigest()})
    obj.matrix_world = transform @ obj.matrix_world
    obj['source_sha256'] = source_hash
bpy.context.view_layer.update()
report['images'] = [{'name': im.name, 'size': list(im.size), 'packed': bool(im.packed_file)}
                    for im in bpy.data.images if im.source == 'FILE']
assert report['images'] and all(min(im['size']) > 0 for im in report['images'])
assert report['armatures'] == 0 and report['animations'] == 0 and report['skins'] == 0
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 16
scene.cycles.use_denoising = True
scene.render.threads_mode = 'FIXED'
scene.render.threads = 8
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.32, .35, .39, 1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .5

def material(name, colour):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*colour, 1)
    bsdf.inputs['Roughness'].default_value = .8
    return mat

clay = material('REVIEW clay - geometry only', (.32, .34, .37))
clay.use_fake_user = True
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.006))
floor = bpy.context.object
floor.name = 'REVIEW floor, not source'
floor.data.materials.append(material('REVIEW floor', (.17, .18, .20)))
target = Vector((0, 0, (hi.z-lo.z)*scale*.5))

def aim(obj, at):
    obj.rotation_euler = (Vector(at)-obj.location).to_track_quat('-Z', 'Y').to_euler()

for name, position, energy in [('Key', (-3, -4, 6), 700), ('Fill', (4, -1, 3), 450), ('Rim', (0, 4, 5), 650)]:
    light = bpy.data.objects.new(name, bpy.data.lights.new(name, 'AREA'))
    scene.collection.objects.link(light)
    light.location = position
    light.data.energy = energy
    light.data.shape = 'DISK'
    light.data.size = 4
    aim(light, target)
camera = bpy.data.objects.new('REVIEW camera', bpy.data.cameras.new('Camera'))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 2.65

def shot(name, offset, use_clay=False, show_floor=True):
    camera.location = target + Vector(offset)
    aim(camera, target)
    floor.hide_render = not show_floor
    scene.view_layers[0].material_override = clay if use_clay else None
    scene.render.filepath = str(output/(name+'.png'))
    bpy.ops.render.render(write_still=True)
    report['views'].append({'name': name, 'camera': list(camera.location),
                            'target': list(target), 'ortho_scale': camera.data.ortho_scale,
                            'clay': use_clay, 'floor': show_floor})
    print('ROSTER_VIEW '+name, flush=True)

for angle in [0, 90, 180, 270]:
    a = math.radians(angle)
    shot('material-az'+str(angle), (5*math.cos(a), 5*math.sin(a), 1.25))
shot('clay-three-quarter', (4, -5, 2), True)
shot('clay-top', (0, -.01, 6), True, False)
shot('clay-underside', (3, -4, -3), True, False)
floor.hide_render = False
scene.view_layers[0].material_override = None
camera.location = target + Vector((0, -5, 1.25))
aim(camera, target)
scene['inspection_stage'] = report['stage']
scene['source_sha256'] = source_hash
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(output/(source.stem+'-inspection.blend')), compress=True)
assert hashlib.sha256(source.read_bytes()).hexdigest() == source_hash
report['source_unchanged'] = True
(output/'inspection.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print('ROSTER_SOURCE_INSPECTED '+source.stem, flush=True)
