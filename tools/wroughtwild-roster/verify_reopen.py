"""Blender --python-exit-code 1 --python verify_reopen.py -- INSPECTION_DIR OUTPUT.json"""
import hashlib
import json
import sys
from pathlib import Path

import bpy
import numpy as np

folder, output = (Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:])
report = json.loads((folder/'inspection.json').read_text(encoding='utf-8'))
blend = list(folder.glob('*-inspection.blend'))
assert len(blend) == 1 and not output.exists()
bpy.ops.wm.open_mainfile(filepath=str(blend[0]))
assert bpy.context.scene['source_sha256'] == report['source_sha256']
checks = 1
for entry in report['meshes']:
    obj = bpy.data.objects[entry['name']]
    mesh = obj.data
    mesh.calc_loop_triangles()
    vertices = np.empty((len(mesh.vertices),3),dtype=np.float32)
    mesh.vertices.foreach_get('co',vertices.ravel())
    triangles = np.empty((len(mesh.loop_triangles),3),dtype=np.int32)
    mesh.loop_triangles.foreach_get('vertices',triangles.ravel())
    assert hashlib.sha256(vertices.tobytes()+triangles.tobytes()).hexdigest() == entry['geometry_sha256']
    assert np.isfinite(vertices).all()
    assert obj['source_sha256'] == report['source_sha256']
    checks += 3
for entry in report['images']:
    image = bpy.data.images[entry['name']]
    assert image.packed_file and list(image.size) == entry['size']
    checks += 1
assert not any(o.type == 'ARMATURE' for o in bpy.data.objects)
checks += 1
output.write_text(json.dumps({'checks':checks,'passed':True,'source_sha256':report['source_sha256'],
                             'scope':'Packed editable source reopening and unchanged mesh streams, not rig/animation acceptance.'},indent=2)+'\n',encoding='utf-8')
print('ROSTER_REOPEN_CHECKS',checks)
