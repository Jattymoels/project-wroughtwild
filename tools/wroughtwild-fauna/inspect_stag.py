"""Blender: normalize and render the actual generated stag before finishing.
-- RAW.glb NEW_OUTPUT YAW_DEGREES. Uniform transforms only.
"""
import bpy,json,sys,math,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
raw,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:][:2])
yaw=float(sys.argv[-1]);assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(raw))
obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
p=np.array([obj.matrix_world@v.co for v in obj.data.vertices]);rot=Matrix.Rotation(math.radians(yaw),4,'Z')
rotated=np.array([rot@Vector(v) for v in p]);lo,hi=rotated.min(0),rotated.max(0);factor=3/(hi[2]-lo[2])
obj.matrix_world=Matrix.Scale(factor,4)@Matrix.Translation(-Vector(((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2])))@rot@obj.matrix_world
bpy.context.view_layer.objects.active=obj;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
obj.name='Vaultcrown - host';p=np.array([v.co for v in obj.data.vertices])
source=obj.copy();source.data=obj.data.copy();source.name='SOURCE - preserved normalized stag';bpy.context.collection.objects.link(source);source.hide_set(True);source.hide_render=True;source.select_set(False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
world=bpy.data.worlds.new('Studio');world.use_nodes=True;scene.world=world;world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.40,.46,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
def aim(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
for at,power,size in [((-5,5,6),1000,5),((4,1,4),700,4),((1,-4,5),900,4)]:
    o=bpy.data.objects.new('Softbox',bpy.data.lights.new('Softbox','AREA'));scene.collection.objects.link(o);o.location=at;o.data.energy=power;o.data.size=size;aim(o,(0,0,1.5))
camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera);scene.camera=camera;camera.data.type='ORTHO'
for name,at,target,scale in [('front',(0,7,1.5),(0,0,1.5),4),('side',(-7,0,1.5),(0,0,1.5),4),('rear',(0,-7,1.5),(0,0,1.5),4),('top',(0,0,7),(0,0,1.5),4),('face',(-3,5,3),(0,.5,2.0),1.3)]:
    camera.location=at;aim(camera,target);camera.data.ortho_scale=scale;scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
for o in list(scene.objects):
    if o.type in ['CAMERA','LIGHT']:bpy.data.objects.remove(o,do_unlink=True)
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
(out/'inspection.json').write_text(json.dumps({'source_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'yaw_degrees':yaw,'scale':factor,'height_metres':3,'bounds':[p.min(0).tolist(),p.max(0).tolist()],'triangles':len(obj.data.polygons)},indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'stag-source.blend'),compress=True)
print('STAG_INSPECTION_OK')
