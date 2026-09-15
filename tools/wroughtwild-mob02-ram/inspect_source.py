"""Read selected source anatomy without mutating the source."""
import json, sys
from pathlib import Path
import bpy
import numpy as np
source, destination = map(Path, sys.argv[sys.argv.index('--') + 1:])
bpy.ops.wm.open_mainfile(filepath=str(source / 'stone_husk-surface.blend'))
report = {'objects': []}
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH':
        continue
    p = np.array([obj.matrix_world @ v.co for v in obj.data.vertices])
    entry = {'name': obj.name, 'vertices': len(p), 'faces': len(obj.data.polygons),
             'bounds': [p.min(axis=0).tolist(), p.max(axis=0).tolist()],
             'matrix': [list(row) for row in obj.matrix_world],
             'materials': [m.name for m in obj.data.materials], 'slices': []}
    for z in [.05, .15, .35, .55, .75, .95, 1.15, 1.35, 1.55, 1.75]:
        for front in [True, False]:
            for side in [-1, 1]:
                q = p[(abs(p[:, 2] - z) < .045) & (p[:, 0]*side > .06) &
                      ((p[:, 1] < -.1) if front else (p[:, 1] > .1))]
                if len(q):
                    entry['slices'].append({'z': z, 'front': front, 'side': side,
                                            'median': np.median(q, axis=0).tolist(),
                                            'bounds': [q.min(axis=0).tolist(), q.max(axis=0).tolist()]})
    report['objects'].append(entry)
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
