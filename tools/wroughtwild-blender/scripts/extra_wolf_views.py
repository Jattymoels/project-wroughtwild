"""Supplement an existing matched wolf review with explicitly unmatched detail views.

Blender --background --python-exit-code 1 --python extra_wolf_views.py -- REVIEW.blend CONFIG.json NEW_OUTPUT
"""
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
assert len(args) == 3, 'REVIEW.blend CONFIG.json NEW_OUTPUT'
source, config_path, output = [Path(arg).resolve() for arg in args]
assert not output.exists(), 'Use a new output directory.'
config = json.loads(config_path.read_text(encoding='utf-8'))
output.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source))
scene = bpy.context.scene
scene.view_layers[0].material_override = bpy.data.materials['Neutral clay - no textures or emission']
floor = bpy.data.objects['REVIEW ONLY - floor']
report = {'stage': 'Supplementary detail views; cameras differ from baseline.', 'views': []}
for view in config['extra_views']:
    scene.camera.location = Vector(view['camera'])
    scene.camera.rotation_euler = (Vector(view['target']) - scene.camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera.data.ortho_scale = view['ortho_scale']
    floor.hide_render = not view['show_floor']
    scene.render.filepath = str(output / (view['name'] + '.png'))
    bpy.ops.render.render(write_still=True)
    report['views'].append(view)
(output / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print('EXTRA_WOLF_VIEWS_OK ' + str(output), flush=True)
