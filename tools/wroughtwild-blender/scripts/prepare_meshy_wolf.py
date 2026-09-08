"""Audit and normalize the one approved experimental Meshy wolf, preserving raw form.

Blender --background --python-exit-code 1 --python prepare_meshy_wolf.py -- RAW.glb CONFIG.json NEW_OUTPUT
No remeshing, vertex smoothing, decimation, topology repair, posing or game integration.
Optional shading normals do not move vertices.
"""
import hashlib
import json
import math
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index('--') + 1:]
assert len(args) == 3, 'RAW.glb CONFIG.json NEW_OUTPUT'
source, config_path, output = [Path(arg).resolve() for arg in args]
config = json.loads(config_path.read_text(encoding='utf-8'))
source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
assert source_hash == config['source_sha256'], 'Different input: inspect and document its own normalization.'
assert not output.exists(), 'Use a new output directory.'
assert math.isfinite(config['target_height_metres']) and config['target_height_metres'] > 0
assert math.isfinite(config['yaw_degrees'])
assert config['face_area_epsilon'] > 0
assert 0 < config['sharp_edge_angle_degrees'] < 180
output.mkdir(parents=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
objects = list(bpy.context.scene.objects)
meshes = [obj for obj in objects if obj.type == 'MESH']
assert len(meshes) == 1, 'This inspected export is one mesh.'
assert not any(obj.type == 'ARMATURE' for obj in objects)
obj = meshes[0]
mesh = obj.data
mesh.calc_loop_triangles()
raw_world = [obj.matrix_world @ vertex.co for vertex in mesh.vertices]
assert all(math.isfinite(value) for point in raw_world for value in point)

def bounds(points):
    return [[min(point[i] for point in points) for i in range(3)],
            [max(point[i] for point in points) for i in range(3)]]

bm = bmesh.new()
bm.from_mesh(mesh)
bm.verts.ensure_lookup_table()
seen = set()
components = []
for vertex in bm.verts:
    if vertex.index in seen:
        continue
    pending = [vertex]
    seen.add(vertex.index)
    indices = []
    while pending:
        current = pending.pop()
        indices.append(current.index)
        for edge in current.link_edges:
            other = edge.other_vert(current)
            if other.index not in seen:
                seen.add(other.index)
                pending.append(other)
    components.append({'vertices': len(indices),
                       'bounds_source': bounds([raw_world[i] for i in indices])})
report = {
    'source': source.name, 'source_sha256': source_hash,
    'config': config_path.name, 'config_sha256': hashlib.sha256(config_path.read_bytes()).hexdigest(),
    'blender_version': bpy.app.version_string,
    'vertices': len(mesh.vertices), 'edges': len(mesh.edges),
    'triangles': len(mesh.loop_triangles), 'polygons': len(mesh.polygons),
    'boundary_edges': sum(edge.is_boundary for edge in bm.edges),
    'nonmanifold_edges': sum(not edge.is_manifold for edge in bm.edges),
    'loose_vertices': sum(not vertex.link_edges for vertex in bm.verts),
    'loose_edges': sum(edge.is_wire for edge in bm.edges),
    'inconsistent_winding_edges': sum(edge.is_manifold and not edge.is_contiguous for edge in bm.edges),
    'near_zero_area_faces': sum(face.calc_area() <= config['face_area_epsilon'] for face in bm.faces),
    'components': sorted(components, key=lambda item: item['vertices'], reverse=True),
    'euler_characteristic': len(bm.verts) - len(bm.edges) + len(bm.faces),
    'materials': len(mesh.materials), 'uv_layers': len(mesh.uv_layers),
    'vertex_groups': len(obj.vertex_groups), 'armatures': 0,
    'animations': len(bpy.data.actions), 'shape_keys': bool(mesh.shape_keys),
    'smooth_faces': sum(face.use_smooth for face in mesh.polygons),
    'raw_blender_bounds': bounds(raw_world),
    'limitations': ['Closed manifold geometry does not prove good anatomy, no self-intersections or animation readiness.',
                    'Only uniform scale, orientation, translation and optional shading normals are changed; generated anatomy and topology are retained.']
}
sharp_keys = {tuple(sorted(vertex.index for vertex in edge.verts)) for edge in bm.edges
              if edge.is_manifold and edge.calc_face_angle() > math.radians(config['sharp_edge_angle_degrees'])}
bm.free()
rotation = Matrix.Rotation(math.radians(config['yaw_degrees']), 4, 'Z')
rotated = [rotation @ point for point in raw_world]
lo, hi = map(Vector, bounds(rotated))
factor = config['target_height_metres'] / (hi.z - lo.z)
origin = Vector(((lo.x + hi.x) * .5, (lo.y + hi.y) * .5, lo.z))
normalized = [(point - origin) * factor for point in rotated]
for vertex, point in zip(mesh.vertices, normalized):
    vertex.co = point
obj.matrix_world = Matrix.Identity(4)
obj.name = 'STUDY ONLY - Meshy 6 Lite wolf'
mesh.update()
if config['smooth_shading']:
    for face in mesh.polygons:
        face.use_smooth = True
    for edge in mesh.edges:
        edge.use_edge_sharp = tuple(sorted(edge.vertices)) in sharp_keys
report['shading'] = {'smooth': config['smooth_shading'],
                     'sharp_edge_angle_degrees': config['sharp_edge_angle_degrees'],
                     'marked_sharp_edges': sum(edge.use_edge_sharp for edge in mesh.edges)}
bpy.context.view_layer.update()
obj['source_sha256'] = source_hash
obj['attribution'] = 'Model created with Meshy - CC BY 4.0 License'
obj['study_status'] = 'Experimental geometry, not accepted game art'
report['normalization'] = {'yaw_degrees': config['yaw_degrees'], 'uniform_scale': factor,
                           'rotated_origin_before_scale': list(origin),
                           'target_height_metres': config['target_height_metres'],
                           'coordinates': 'Blender metres, +Y front, +Z up',
                           'normalized_bounds': bounds(normalized)}
# Verify rigid/uniform conversion rather than allowing accidental form changes.
maximum_error = max(abs((mesh.vertices[edge.vertices[0]].co - mesh.vertices[edge.vertices[1]].co).length
                        - (raw_world[edge.vertices[0]] - raw_world[edge.vertices[1]]).length * factor)
                    for edge in mesh.edges)
assert maximum_error < 1e-6, 'Uniform normalization changed an edge length unexpectedly.'
assert abs(min(point.z for point in normalized)) < 1e-7
assert abs(max(point.z for point in normalized) - config['target_height_metres']) < 1e-6
report['normalization']['max_edge_length_error_metres'] = maximum_error
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
normalized_path = output / 'wolf-normalized.glb'
bpy.ops.export_scene.gltf(filepath=str(normalized_path), export_format='GLB',
                          use_selection=True, export_animations=False)
report['normalized_glb_sha256'] = hashlib.sha256(normalized_path.read_bytes()).hexdigest()
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'wolf-candidate.blend'), compress=True)
assert hashlib.sha256(source.read_bytes()).hexdigest() == source_hash
(output / 'audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print('MESHY_WOLF_PREPARED ' + str(output), flush=True)
