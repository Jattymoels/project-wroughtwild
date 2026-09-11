"""Render actual packed ash geometry and exported scrub, CPU eight-thread review."""
import bpy,sys,math
from pathlib import Path
from mathutils import Vector
kit,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(kit/'c4-master.blend'))
scene=bpy.context.scene
for o in scene.objects:o.hide_render=True
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('C4 studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.25,.27,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
sun=bpy.data.objects.new('Review light',bpy.data.lights.new('Review light','SUN'));scene.collection.objects.link(sun);sun.rotation_euler=(-.6,-.5,-.5);sun.data.energy=2.5
cam=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO'
clay=bpy.data.materials.new('C4 clay');clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.42,.42,.42,1)
def shot(name,at,target,scale=5.4,clay_on=False):
    cam.data.ortho_scale=scale;cam.location=at;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.view_layers[0].material_override=clay if clay_on else None
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
a=bpy.data.objects['ash-a-lod0'];a.hide_render=False
for name,at in [('front',(0,12,2.3)),('back',(0,-12,2.3)),('side',(12,0,2.3)),('threequarter',(-8,12,5)),('top',(0,.01,16)),('underside',(3,10,-3))]:
    shot(name+'-material',at,(0,0,2.1));shot(name+'-clay',at,(0,0,2.1),clay_on=True)
a.hide_render=True
for name,x in [('ash-a-lod0',-1.5),('ash-b-lod0',0),('ash-short-lod0',1.5)]:
    ob=bpy.data.objects[name];ob.hide_render=False;ob.location.x=x
shot('standing-variants',(-6,14,6),(0,0,2),6)
for o in scene.objects:
    if o.type=='MESH':o.hide_render=True
for name,y in [('ash-felled-a-lod0',-.8),('ash-felled-b-lod0',.8)]:
    ob=bpy.data.objects[name];ob.hide_render=False;ob.location.y=y
ob=bpy.data.objects['ash-stump-lod0'];ob.hide_render=False;ob.location=(2,0,0)
shot('felled-stump',(-6,10,8),(0,0,.3),5.8)
for o in scene.objects:
    if o.type=='MESH':o.hide_render=True
for name,x in [('scrub',-1.2),('thorn',0),('seed-grass',1.1)]:
    bpy.ops.import_scene.gltf(filepath=str(kit/'models'/(name+'-lod0.glb')))
    for ob in bpy.context.selected_objects:
        if ob.type=='MESH':ob.hide_render=False;ob.location.x+=x
shot('surviving-scrub',(-3,6,3),(0,0,.3),4)
for o in scene.objects:
    if o.type=='MESH':o.hide_render=True
for name,x in [('MEASURE before scar',-.45),('MEASURE after scar',.45)]:
    ob=bpy.data.objects[name];ob.hide_render=False;ob.location.x=x
shot('scar-emission-off',(0,8,1.4),(0,0,1.4),2.9,True)
print('C4_MASTER_RENDERS_OK')
