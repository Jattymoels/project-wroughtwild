"""Blender: same-camera real surface comparison. -- SURFACE.blend NEW_OUTPUT"""
import json,sys
from pathlib import Path
import bpy
from mathutils import Vector

source,output=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not output.exists();output.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('Neutral review');world.use_nodes=True;scene.world=world
world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.35,.39,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.4
def aim(obj,p):obj.rotation_euler=(Vector(p)-obj.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005))
floor=bpy.context.object;floor.name='REVIEW ONLY - floor'
floor_material=bpy.data.materials.new('Review ground');floor_material.diffuse_color=(.17,.18,.19,1);floor.data.materials.append(floor_material)
for name,p,power,size in [('Key',(-3,4,6),650,5),('Fill',(4,1,4),300,4),('Rim',(1,-4,5),600,3)]:
    obj=bpy.data.objects.new(name,bpy.data.lights.new(name,'AREA'));scene.collection.objects.link(obj)
    obj.location=p;obj.data.energy=power;obj.data.shape='DISK';obj.data.size=size;aim(obj,(0,0,.65))
camera=bpy.data.objects.new('REVIEW ONLY - camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera)
scene.camera=camera;camera.data.type='ORTHO';camera.data.ortho_scale=2.35
camera.location=(-3.8,4,2.3);aim(camera,(0,0,.6))
material=bpy.data.materials['Kilnback - buried Red scars'];gain=material.node_tree.nodes['Review emission gain']
for name,energy in [('scars-unlit',0),('scars-steady',1.3),('scars-peak',3.2)]:
    gain.inputs[1].default_value=energy
    scene.render.filepath=str(output/(name+'.png'));bpy.ops.render.render(write_still=True)
camera.location=(-4,0,1.35);aim(camera,(0,0,.67));camera.data.ortho_scale=2.05
scene.render.filepath=str(output/'scar-side.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(output/'boar-surface-review.blend'),compress=True)
print('BOAR_SURFACE_RENDERED '+str(output),flush=True)
