"""Blender: inspect the retained porcupine face without altering its source."""
import json
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

repo = Path(__file__).resolve().parents[2]
out = Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert out.is_relative_to(repo/'build') and not out.exists()
out.mkdir(parents=True)
report = json.loads((repo/'docs/art/leyline-studies/2026-09-09/roster-art06/cinder_archer/inspection.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(repo/'build/roster-art06/cinder_archer-source-v02/cinder_archer.glb'))
host = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
lo,hi = map(Vector,report['raw_bounds'])
host.matrix_world = Matrix.Scale(report['review_uniform_scale'],4)@Matrix.Translation(-Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z)))@host.matrix_world
bpy.context.view_layer.objects.active = host
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
p = np.array([v.co[:] for v in host.data.vertices],np.float32)
f = np.array([x.vertices[:] for x in host.data.polygons],np.int32)
np.savez_compressed(out/'source.npz',points=p,faces=f)
bvh = BVHTree.FromPolygons(p.tolist(),f.tolist(),all_triangles=True)
probes=[]
for name,pixels in [('material-az270',[(463,518),(556,518),(512,577),(484,592),(537,592),(407,570),(436,599),(457,626),(581,608),(601,570)]),('material-az0',[(190,451),(136,487),(165,514),(171,535),(198,520)])]:
    view=next(x for x in report['views'] if x['name']==name)
    camera,target=Vector(view['camera']),Vector(view['target'])
    rot=(target-camera).to_track_quat('-Z','Y').to_matrix()
    right,up,direction=[rot@Vector(v) for v in [(1,0,0),(0,1,0),(0,0,-1)]]
    for x,y in pixels:
        origin=camera+right*((x/1024-.5)*view['ortho_scale'])+up*((.5-y/1024)*view['ortho_scale'])
        hit,normal,face,distance=bvh.ray_cast(origin,direction,12)
        probes.append(dict(view=name,pixel=[x,y],point=list(hit) if hit else None,normal=list(normal) if normal else None,face=face))
(out/'probes.json').write_text(json.dumps(probes,indent=2)+'\n')
print(json.dumps(probes,indent=2),flush=True)
