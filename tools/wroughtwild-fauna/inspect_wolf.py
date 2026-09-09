"""Blender: inspect the preserved normalized wolf and locate actual landmarks."""
import bpy, json, sys
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
repo=Path(__file__).resolve().parents[2]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not out.exists(); out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(repo/'build/trellis-local/normalized-review/wolf-normalized.glb'))
obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=obj
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
p=np.array([v.co for v in obj.data.vertices])
report={'bounds':[p.min(0).tolist(),p.max(0).tolist()], 'slices':[]}
for y in np.arange(-.75,.9,.05):
    q=p[abs(p[:,1]-y)<.015]
    if len(q): report['slices'].append({'y':round(float(y),3),'min':q.min(0).tolist(),'max':q.max(0).tolist()})
obj.name='Wolf - preserved normalized source'
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
world=bpy.data.worlds.new('Review world');world.use_nodes=True;scene.world=world
world.node_tree.nodes['Background'].inputs[0].default_value=(.30,.34,.38,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.6
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));scene.collection.objects.link(sun)
sun.rotation_euler=(.5,-.6,-.5);sun.data.energy=2
camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera);scene.camera=camera
camera.data.type='ORTHO'
for name,at,target,scale in [('side',(-5,0,.525),(0,0,.525),2.1),('face',(-2.5,3,1.4),(0,.66,.68),.72),('front',(0,5,.65),(0,0,.55),1.8)]:
    camera.location=at;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=scale
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
(out/'landmarks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'wolf-source.blend'),compress=True)
print('WOLF_INSPECTION_OK')
