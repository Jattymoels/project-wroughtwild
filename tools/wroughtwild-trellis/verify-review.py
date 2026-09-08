"""Blender handoff checks, not art acceptance.

blender --background --python-exit-code 1 --python verify-review.py -- RAW PREPARED REVIEW DETAILS NEW_REPORT
"""
import hashlib
import json
from pathlib import Path
import struct
import sys

import bpy
from mathutils.kdtree import KDTree

raw, prepared, review, details, output = [Path(p).resolve() for p in sys.argv[sys.argv.index('--') + 1:]]
assert not output.exists(), 'Use a fresh verification report.'
repo = Path(__file__).resolve().parents[2]
config = json.loads((Path(__file__).parent / 'wolf-review.json').read_text())
audit = json.loads((prepared / 'audit.json').read_text())
actual = json.loads((review / 'report.json').read_text())
baseline = json.loads((repo / 'docs/art/leyline-studies/2026-09-08/wolf-baseline/report.json').read_text())
checks = []


def check(name, condition):
    checks.append({'name': name, 'passed': bool(condition)})
    assert condition, name


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def glb(path):
    data = path.read_bytes()
    assert struct.unpack_from('<III', data) == (0x46546c67, 2, len(data))
    length, kind = struct.unpack_from('<II', data, 12)
    assert kind == 0x4e4f534a
    document = json.loads(data[20:20 + length])
    binary_length, binary_kind = struct.unpack_from('<II', data, 20 + length)
    assert binary_kind == 0x004e4942
    binary = data[28 + length:]
    assert len(binary) == binary_length
    hashes = []
    for image in document['images']:
        view = document['bufferViews'][image['bufferView']]
        offset = view.get('byteOffset', 0)
        hashes.append(hashlib.sha256(binary[offset:offset + view['byteLength']]).hexdigest())
    return document, hashes


check('Raw export matches the inspected input', digest(raw) == config['source_sha256'] == audit['source_sha256'])
check('Normalization uses the documented configuration', config == audit['config'])
check('Reviewed GLB is the prepared export', digest(prepared / 'wolf-normalized.glb') == actual['sha256'] == audit['normalised_glb_sha256'])
for name, path, expected in [
    ('Game wolf', 'game/assets/authored/mobs/ash_hound.glb', baseline['sha256']),
    ('Moth', 'game/assets/authored/mobs/marsh_wisp.glb', '554ec16fe3c7154239682da327d717f694a7ff20c430d27cbaca0266a749e389'),
    ('Editable beast master', 'art/blender/augmented-beasts-v01.blend', '364d616f69bb7b716ac3b7287372b0c5f016f4d99600e4783c992e9c13a2218c'),
    ('Meshy source', 'art/blender/studies/meshy-wolf-2026-09-08/Meshy_AI_Ironfang_Wolf_0908111014_generate.glb', 'be617990bd397254ead88d5a59ea002c27c852dca60048a41c527bbdb723baff'),
    ('Comparison image', 'docs/art/leyline-studies/2026-09-08/wolf-image3d/input-three-quarter-v01.png', '603da99abb16c5a34295ab8e5bf8117cd0fea05bb0f8b9cb24c9765eb80b2126'),
]:
    check(name + ' remains unchanged', digest(repo / path) == expected)
check('All six cameras exactly match the baseline', actual['views'] == baseline['views'])
extra = json.loads((details / 'report.json').read_text())
check('Supplementary cameras are recorded separately', extra['views'] == config['extra_views'])
for directory, views in [(review, actual['views']), (details, extra['views'])]:
    for view in views:
        header = (directory / (view['name'] + '.png')).read_bytes()[:24]
        check('Rendered 1280x960 PNG: ' + view['name'], header[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', header[16:24]) == (1280, 960))
source_doc, source_images = glb(raw)
normal_doc, normal_images = glb(prepared / 'wolf-normalized.glb')
check('Both embedded PNGs survive byte-for-byte', len(source_images) == 2 and source_images == normal_images)
check('Texture source and sampler mappings survive', source_doc['textures'] == normal_doc['textures'])
for document in (source_doc, normal_doc):
    material = document['materials'][0]
    pbr = material['pbrMetallicRoughness']
    check('Opaque PBR material and texture roles preserved: ' + document['asset']['generator'],
          len(document['materials']) == 1 and material.get('alphaMode', 'OPAQUE') == 'OPAQUE'
          and not material.get('doubleSided', False)
          and pbr.get('metallicFactor', 1) == pbr.get('roughnessFactor', 1) == 1
          and pbr['baseColorTexture'] == {'index': 0} and pbr['metallicRoughnessTexture'] == {'index': 1})
expected_triangles = sum(mesh['triangles'] for mesh in audit['meshes'])
bpy.ops.wm.open_mainfile(filepath=str(prepared / 'wolf-candidate.blend'))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
check('Editable candidate reopens with one mesh and UV layer', len(meshes) == 1 and len(meshes[0].data.uv_layers) == 1)
meshes[0].data.calc_loop_triangles()
check('Editable candidate retains imported counts', len(meshes[0].data.vertices) == audit['meshes'][0]['vertices'] and len(meshes[0].data.loop_triangles) == expected_triangles)
check('Candidate texture images remain packed', all(image.packed_file for image in bpy.data.images if image.source == 'FILE'))
saved_points = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
check('Candidate is grounded at the comparison height', abs(min(p.z for p in saved_points)) < 1e-6 and abs(max(p.z for p in saved_points) - config['target_height_metres']) < 1e-6)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(prepared / 'wolf-normalized.glb'))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
triangles = 0
for obj in meshes:
    obj.data.calc_loop_triangles()
    triangles += len(obj.data.loop_triangles)
check('Export reimports with the triangle count and UV layer', triangles == expected_triangles and all(len(obj.data.uv_layers) == 1 for obj in meshes))
export_points = [obj.matrix_world @ v.co for obj in meshes for v in obj.data.vertices]
errors = []
for reference, comparison in [(saved_points, export_points), (export_points, saved_points)]:
    tree = KDTree(len(reference))
    for index, point in enumerate(reference):
        tree.insert(point, index)
    tree.balance()
    errors.append(max(tree.find(point)[2] for point in comparison))
check('GLB roundtrip preserves surface vertices within one micrometre', max(errors) < 1e-6)
bpy.ops.wm.open_mainfile(filepath=str(review / 'wolf-review.blend'))
scene = bpy.context.scene
check('Review reopens with its camera and three lights', bool(scene.camera) and sum(obj.type == 'LIGHT' for obj in scene.objects) == 3)
clay = bpy.data.materials.get('Neutral clay - no textures or emission')
check('Clay override survives reopening', bool(clay) and clay.use_fake_user)
check('No rig or animation has been claimed or introduced', audit['armatures'] == audit['animations'] == 0 and not any(obj.type == 'ARMATURE' for obj in scene.objects) and len(bpy.data.actions) == 0)
check('Raw source remains intact after verification', digest(raw) == config['source_sha256'])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({'status': 'passed', 'checks': checks,
    'maximum_glb_roundtrip_error_metres': max(errors),
    'source_samplers': source_doc['samplers'], 'normalized_samplers': normal_doc['samplers'],
    'sampler_note': 'Source leaves filters unspecified; Blender exports linear/mipmapped-linear filtering explicitly. Both textures use the same sampler and embedded images are byte-identical.',
    'limitations': 'No self-intersection, deformation, crowd performance or art acceptance claim.'}, indent=2) + '\n')
print('TRELLIS_REVIEW_VERIFIED ' + str(len(checks)), flush=True)
