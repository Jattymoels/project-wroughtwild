"""Blender: fit the untouched TRELLIS candidate uniformly inside the native body."""
import bpy, json, sys, hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
raw,out=map(Path,sys.argv[sys.argv.index('--')+1:])
assert not out.exists(); out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(raw.resolve()))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(meshes)==1
host=meshes[0]
p=np.array([host.matrix_world@v.co for v in host.data.vertices])
lo,hi=p.min(0),p.max(0)
factor=float(np.min(np.array([1.44,1.44,1.03])/(hi-lo)))
host.matrix_world=Matrix.Scale(factor,4)@Matrix.Translation(-Vector(((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2])))@host.matrix_world
bpy.context.view_layer.objects.active=host
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
host.name='Red inclusion - intact normalized source'
p=np.array([v.co for v in host.data.vertices])
host.data.calc_loop_triangles()
report={'raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'bounds_blender_xyz':[p.min(0).tolist(),p.max(0).tolist()],'triangles':len(host.data.loop_triangles),'uniform_scale':factor,'native_body_godot_xyz':[1.5,1.1,1.5]}
(out/'inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
scene=bpy.context.scene; scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=1100;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.38,.42,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));scene.collection.objects.link(sun)
sun.rotation_euler=(.5,-.6,-.5);sun.data.energy=2
camera=bpy.data.objects.new('Inspection',bpy.data.cameras.new('Inspection'));scene.collection.objects.link(camera);scene.camera=camera
camera.data.type='ORTHO';camera.data.ortho_scale=2.4
for name,at in [('front',(2,-3,2)),('back',(-2,3,2)),('top',(0,-.02,5))]:
    camera.location=at;camera.rotation_euler=(Vector((0,0,.45))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str((out/(name+'.png')).resolve());bpy.ops.render.render(write_still=True)
for image in bpy.data.images:
    if image.has_data and image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str((out/'source.blend').resolve()),compress=True)
print('ART04_SOURCE_INSPECTION_OK')
