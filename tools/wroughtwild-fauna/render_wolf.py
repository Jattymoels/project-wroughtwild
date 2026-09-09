"""Actual Blender views of the working wolf, including an opened jaw."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Vector,Matrix
source,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True)
if source.suffix=='.glb':
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
else:bpy.ops.wm.open_mainfile(filepath=str(source))
for o in list(bpy.context.scene.objects):
    if o.type in ['CAMERA','LIGHT']:bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
world=bpy.data.worlds.new('Soft studio');world.use_nodes=True;scene.world=world
world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.40,.46,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.7
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
for at,power,size in [((-3,3,4),500,4),((3,1,3),400,3),((1,-4,3),600,3)]:
    o=bpy.data.objects.new('Softbox',bpy.data.lights.new('Softbox','AREA'));scene.collection.objects.link(o);o.location=at;o.data.energy=power;o.data.size=size;aim(o,(0,0,.55))
camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera);scene.camera=camera;camera.data.type='ORTHO'
cfg=json.loads(Path(__file__).with_name('wolf.json').read_text(encoding='utf-8'))
hinge=Vector(cfg['jaw_hinge'])
for name,at,target,scale,jawangle in [('body',(-3.8,4,2.2),(0,0,.54),2.25,0),('face',(-2,4,1.6),(-.035,.63,.52),.64,0),('jaw',(-4,2,1.1),(-.035,.63,.48),.72,-.32),('opposite',(4,2,1.6),(-.035,.63,.52),.74,-.32)]:
    camera.location=at;aim(camera,target);camera.data.ortho_scale=scale
    for o in scene.objects:
        if o.get('attachment')=='jaw':o.matrix_world=Matrix.Translation(hinge)@Matrix.Rotation(jawangle,4,'X')@Matrix.Translation(-hinge)
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
print('WOLF_RENDER_OK')
