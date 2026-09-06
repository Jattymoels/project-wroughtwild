"""Render inspectable asset plates from the saved authored source blend.

This is an authoring inspection, not a gameplay/performance result.
Blender --background source.blend --python this-file -- output-directory
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Vector

output=Path(sys.argv[sys.argv.index('--')+1]);output.mkdir(parents=True,exist_ok=True)
def xyz(p): return Vector((p[0],-p[2],p[1]))
scene=bpy.context.scene
for obj in scene.objects: obj.hide_render=True
scene.render.engine='CYCLES'
scene.cycles.samples=16
scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.color=(.45,.48,.54)
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
world=scene.world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.59,.66,.74,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.55

def plain(name,colour):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*colour,1);bsdf.inputs['Roughness'].default_value=.96
    return mat
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.15))
ground=bpy.context.object;ground.data.materials.append(plain('Study ground',(.075,.095,.043)))
bpy.ops.object.light_add(type='SUN',location=(0,0,30));sun=bpy.context.object
sun.rotation_euler=(math.radians(28),math.radians(-22),math.radians(-25));sun.data.energy=2.8;sun.data.angle=math.radians(16)
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='ORTHO';camera.data.lens=40
clones=[]
def asset(id,at=(0,0,0),scale=(1,1,1),yaw=0):
    source=bpy.data.objects['strange_'+id]
    obj=source.copy();obj.data=source.data;scene.collection.objects.link(obj)
    obj.hide_render=False;obj.hide_set(False);obj.location=xyz(at);obj.rotation_euler.z=-yaw
    obj.scale=(scale[0],scale[2],scale[1]);clones.append(obj)
    return obj
def capture(id,eye,target,span):
    camera.location=xyz(eye);camera.rotation_euler=(xyz(target)-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=span
    scene.render.filepath=str(output/(id+'.png'));bpy.ops.render.render(write_still=True)
    for obj in clones: bpy.data.objects.remove(obj,do_unlink=True)
    clones.clear()

asset('root_arch');asset('root_crown',(-3.1,9.3,-.65))
asset('wildwood_tree',(7,0,-4),(.75,.75,.75),.7)
for k in range(5):asset('fern',(-6+k*2,0,2.3),(1,1,1),k)
capture('root-and-crown',(18,12,24),(-.6,6.8,0),23)

for k in range(3):asset('hollow_trunk',(-3+k*3.4,0,-.7 if k%2 else .6),(.9+k*.07,.86+k*.07,.9+k*.07),-.25+k*.25)
asset('lantern_shell',(0,0,3));asset('lanternheart',(0,0,3))
for k in range(9):asset('sedge',(-4+k,0,2+(k%3)*.7),(1,1,1),k)
for k in range(4):asset('fern',(-3+k*2,0,1.7),(1,1,1),k)
capture('fen-hollows',(11,7.5,19),(0,2.0,0),13)

asset('stone_rib',(-2,0,-1),(1,1,1),-.25)
asset('low_outcrop',(3,0,.3),(1,1,1),.6)
for k in range(5):asset('scree',(-3+k*1.7,0,2.3),(1,1,1),k)
for k in range(5):asset('sedge',(-3+k*1.7,0,3.1),(.65,.65,.65),k)
capture('layered-stone',(13,8,20),(0,2,0),14)
print('STRANGE_POLISH_PLATES_OK 3')
