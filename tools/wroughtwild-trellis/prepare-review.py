"""Blender: audit and uniformly orient a pinned TRELLIS export for matched review.

blender --background --python prepare-review.py -- RAW.glb CONFIG.json NEW_OUTPUT
Preserves anatomy, topology, materials and UVs. No repair or decimation here.
"""
import hashlib
import json
import math
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

raw, config_path, output = map(lambda p: Path(p).resolve(), sys.argv[sys.argv.index('--') + 1:])
config = json.loads(config_path.read_text())
raw_hash = hashlib.sha256(raw.read_bytes()).hexdigest()
assert raw_hash == config['source_sha256'], 'Different source; inspect before choosing its review transform.'
assert not output.exists(), 'Use a fresh review directory.'
output.mkdir(parents=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(raw))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
assert meshes
points = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
assert all(math.isfinite(value) for p in points for value in p)
def bounds(values):
    return [[min(p[i] for p in values) for i in range(3)], [max(p[i] for p in values) for i in range(3)]]
report = {'source_sha256': raw_hash, 'blender': bpy.app.version_string,
          'original_bounds': bounds(points), 'meshes': [], 'config': config,
          'topology_note': 'Counts describe the unmodified glTF import. UV/normal seams may split touching vertices; component counts alone do not prove anatomical part separation.',
          'armatures': sum(obj.type == 'ARMATURE' for obj in bpy.context.scene.objects),
          'animations': len(bpy.data.actions)}
for obj in meshes:
    mesh = obj.data
    mesh.calc_loop_triangles()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    seen = set()
    components = []
    for vertex in bm.verts:
        if vertex.index in seen: continue
        pending, count = [vertex], 0
        seen.add(vertex.index)
        while pending:
            current = pending.pop()
            count += 1
            for edge in current.link_edges:
                other = edge.other_vert(current)
                if other.index not in seen:
                    seen.add(other.index)
                    pending.append(other)
        components.append(count)
    report['meshes'].append({'name': obj.name, 'vertices': len(mesh.vertices),
        'triangles': len(mesh.loop_triangles), 'uv_layers': len(mesh.uv_layers),
        'materials': len(mesh.materials), 'vertex_groups': len(obj.vertex_groups),
        'boundary_edges': sum(edge.is_boundary for edge in bm.edges),
        'nonmanifold_edges': sum(not edge.is_manifold for edge in bm.edges),
        'component_sizes': sorted(components, reverse=True)})
    bm.free()
rotation = Matrix.Rotation(math.radians(config['yaw_degrees']), 4, 'Z')
rotated = [rotation @ p for p in points]
lo, hi = map(Vector, bounds(rotated))
factor = config['target_height_metres'] / (hi.z - lo.z)
assert math.isfinite(factor) and factor > 0
origin = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
transform = Matrix.Scale(factor, 4) @ Matrix.Translation(-origin) @ rotation
for obj in meshes:
    obj.matrix_world = transform @ obj.matrix_world
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes: obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.context.view_layer.update()
actual = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
error = max((a - transform @ p).length for a, p in zip(actual, points))
assert error < 2e-6
report['uniform_scale'] = factor
report['normalised_bounds'] = bounds(actual)
report['max_transform_error_metres'] = error
report['images'] = [{'name': im.name, 'size': list(im.size), 'packed': bool(im.packed_file)}
                    for im in bpy.data.images if im.source == 'FILE']
bpy.context.scene['study_note'] = 'TRELLIS local trial; not accepted game art.'
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'wolf-candidate.blend'), compress=True)
bpy.ops.export_scene.gltf(filepath=str(output / 'wolf-normalized.glb'), export_format='GLB', use_selection=True)
report['normalised_glb_sha256'] = hashlib.sha256((output / 'wolf-normalized.glb').read_bytes()).hexdigest()
assert hashlib.sha256(raw.read_bytes()).hexdigest() == raw_hash
(output / 'audit.json').write_text(json.dumps(report, indent=2) + '\n')
print('TRELLIS_REVIEW_PREPARED ' + str(output), flush=True)
