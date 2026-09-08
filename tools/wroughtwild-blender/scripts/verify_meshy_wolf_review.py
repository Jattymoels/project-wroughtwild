"""Reopen the experimental wolf deliverables and verify the actual export handoff.

Blender --background --python-exit-code 1 --python verify_meshy_wolf_review.py -- RAW PREPARED REVIEW DETAILS CONFIG NEW_REPORT
These checks do not approve art quality or animation readiness.
"""
import hashlib
import json
from pathlib import Path
import struct
import sys

import bpy
from mathutils.kdtree import KDTree

args = sys.argv[sys.argv.index('--') + 1:]
assert len(args) == 6, 'RAW PREPARED REVIEW DETAILS CONFIG NEW_REPORT'
raw, prepared, review, details, config_path, output = [Path(arg).resolve() for arg in args]
assert not output.exists()
repo = Path(__file__).resolve().parents[3]
config = json.loads(config_path.read_text(encoding='utf-8'))
audit = json.loads((prepared / 'audit.json').read_text(encoding='utf-8'))
actual = json.loads((review / 'report.json').read_text(encoding='utf-8'))
baseline = json.loads((repo / 'docs/art/leyline-studies/2026-09-08/wolf-baseline/report.json').read_text())
checks = []

def check(name, condition):
    checks.append({'name': name, 'passed': bool(condition)})
    assert condition, name

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

check('Raw export hash matches the inspected input', digest(raw) == config['source_sha256'])
check('Normalization uses the current documented configuration', digest(config_path) == audit['config_sha256'])
check('Reviewed GLB matches the prepared export', digest(prepared / 'wolf-normalized.glb') == actual['sha256'] == audit['normalized_glb_sha256'])
check('Original game wolf remains unchanged', digest(repo / 'game/assets/authored/mobs/ash_hound.glb') == baseline['sha256'])
check('Moth game asset remains unchanged', digest(repo / 'game/assets/authored/mobs/marsh_wisp.glb') == '554ec16fe3c7154239682da327d717f694a7ff20c430d27cbaca0266a749e389')
check('Original editable beast master remains unchanged', digest(repo / 'art/blender/augmented-beasts-v01.blend') == '364d616f69bb7b716ac3b7287372b0c5f016f4d99600e4783c992e9c13a2218c')
check('Exactly the six baseline views exist', [view['name'] for view in actual['views']] == [view['name'] for view in baseline['views']])
for view, prior in zip(actual['views'], baseline['views']):
    check('Exact baseline camera: ' + view['name'], all(view[key] == prior[key] for key in ('camera', 'target', 'ortho_scale', 'material_override')))
extra = json.loads((details / 'report.json').read_text())
check('Supplementary cameras are explicitly recorded', extra['views'] == config['extra_views'])
for directory, names in ((review, [view['name'] for view in actual['views']]),
                         (details, [view['name'] for view in extra['views']])):
    for name in names:
        header = (directory / (name + '.png')).read_bytes()[:24]
        check('Rendered PNG 1280x960: ' + name, header[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', header[16:24]) == (1280, 960))
bpy.ops.wm.open_mainfile(filepath=str(prepared / 'wolf-candidate.blend'))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
check('Editable candidate reopens as one preserved mesh', len(meshes) == 1)
candidate = meshes[0]
candidate.data.calc_loop_triangles()
check('Editable candidate retains raw vertex/triangle counts', len(candidate.data.vertices) == audit['vertices'] and len(candidate.data.loop_triangles) == audit['triangles'])
check('Editable candidate retains configured shading', all(face.use_smooth == config['smooth_shading'] for face in candidate.data.polygons) and sum(edge.use_edge_sharp for edge in candidate.data.edges) == audit['shading']['marked_sharp_edges'])
saved_points = [candidate.matrix_world @ vertex.co for vertex in candidate.data.vertices]
check('Candidate has grounded metre height', abs(min(point.z for point in saved_points)) < 1e-6 and abs(max(point.z for point in saved_points) - config['target_height_metres']) < 1e-6)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(prepared / 'wolf-normalized.glb'))
export_meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
export_points = [obj.matrix_world @ vertex.co for obj in export_meshes for vertex in obj.data.vertices]
export_triangles = 0
for obj in export_meshes:
    obj.data.calc_loop_triangles()
    export_triangles += len(obj.data.loop_triangles)
check('Reimported GLB retains triangle count', export_triangles == audit['triangles'])
errors = []
for reference, comparison in ((saved_points, export_points), (export_points, saved_points)):
    tree = KDTree(len(reference))
    for i, point in enumerate(reference):
        tree.insert(point, i)
    tree.balance()
    errors.append(max(tree.find(point)[2] for point in comparison))
check('GLB roundtrip preserves every surface vertex within one micrometre', max(errors) < 1e-6)
bpy.ops.wm.open_mainfile(filepath=str(review / 'wolf-review.blend'))
scene = bpy.context.scene
check('Review reopens with a working camera and three lights', bool(scene.camera) and sum(obj.type == 'LIGHT' for obj in scene.objects) == 3)
clay = bpy.data.materials.get('Neutral clay - no textures or emission')
check('Clay material survives reopening after final material-view save', bool(clay) and clay.use_fake_user)
check('Raw input remains unchanged after verification', digest(raw) == config['source_sha256'])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({'status': 'passed', 'checks': checks,
                             'maximum_glb_roundtrip_error_metres': max(errors),
                             'limitations': 'No self-intersection, deformation, crowd performance or art acceptance claim.'}, indent=2) + '\n', encoding='utf-8')
print('WOLF_REVIEW_VERIFIED ' + str(len(checks)), flush=True)
