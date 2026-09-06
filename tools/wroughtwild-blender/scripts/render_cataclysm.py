"""Inspect assembled cataclysm assets from their saved Blender source.
Authoring plates only; the runtime review must separately prove actual placement.
Blender --background cataclysm-source.blend --python this-file -- output-folder
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Vector

output=Path(sys.argv[sys.argv.index('--')+1]);output.mkdir(parents=True,exist_ok=True)
def xyz(p):return Vector((p[0],-p[2],p[1]))
scene=bpy.context.scene
for obj in scene.objects:obj.hide_render=True
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.59,.66,.73,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.60
bpy.ops.mesh.primitive_plane_add(size=120,location=(0,0,-.08));ground=bpy.context.object
mat=bpy.data.materials.new('Quiet loam');mat.use_nodes=True
mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.105,.119,.080,1)
mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.97;ground.data.materials.append(mat)
bpy.ops.object.light_add(type='SUN');sun=bpy.context.object;sun.rotation_euler=(.45,-.35,-.65);sun.data.energy=2.6;sun.data.angle=.16
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='PERSP';camera.data.lens=40
clones=[]
def asset(id,at=(0,0,0),yaw=0,scale=(1,1,1)):
    obj=bpy.data.objects['cataclysm_'+id].copy();obj.data=obj.data.copy();scene.collection.objects.link(obj)
    obj.hide_render=False;obj.hide_set(False);obj.location=xyz(at);obj.rotation_euler.z=-yaw;obj.scale=(scale[0],scale[2],scale[1]);clones.append(obj)
def shot(id,eye,target):
    camera.location=xyz(eye);camera.rotation_euler=(xyz(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(output/(id+'.png'));bpy.ops.render.render(write_still=True)
    for obj in clones:bpy.data.objects.remove(obj,do_unlink=True)
    clones.clear()

asset('rootvault_frame');asset('rootvault_wall',(-1.64,0,-1.45),math.pi*.5)
asset('rootvault_wall',(0,0,-2.92),0);asset('rootvault_roof',(1.60,0,1.5),.28)
asset('root_fragment',(-3.50,0,-.7),.35)
shot('rootvault-ruin',(7.9,3.8,9.5),(-.7,1.0,-.3))

asset('fen_wall',(-2,0,-.8),-.15);asset('fen_wall',(-3.25,0,.7),math.pi*.5)
asset('fen_cistern',(1.0,0,.7),.15);asset('fen_roof',(-.9,0,2.1),-.32)
shot('fen-waterwork',(6.4,3.5,8.6),(-.8,.7,.6))

asset('upland_shelter',(-1.7,0,-.8),.07);asset('upland_wall',(1.2,0,-.7),-.16)
asset('upland_paving',(-1.4,0,1.8),.05);asset('impact_fragment',(3.8,0,1.0),-.36)
shot('upland-shelter',(8.7,3.4,9.6),(.3,1.0,.1))

asset('forge_threshold');asset('forge_lamella',(-2.4,0,.1),.12);asset('forge_lamella',(2.4,0,.1),-.10)
asset('upland_paving',(0,0,1.6));asset('impact_fragment',(-3.8,0,-1.4),.1)
shot('forge-threshold',(6.4,2.7,8.3),(-.25,1.2,.2))

asset('augmentation_inlay',(0,0,0));asset('impact_fragment',(2.4,0,-.1))
shot('shared-inlay',(1.3,1.4,4.4),(.85,.85,.1))
print('CATACLYSM_PLATES_OK 5')
