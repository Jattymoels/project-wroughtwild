"""Matched material off/peak views from the reopened packed master, CPU only."""
import bpy,sys
from pathlib import Path
from mathutils import Vector
master,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(master));scene=bpy.context.scene
scene.cycles.device='CPU';scene.cycles.samples=32
scene.render.resolution_x=1280;scene.render.resolution_y=900
for obj in scene.objects:
    if obj.type=='MESH':obj.hide_render=True
wall=bpy.data.objects['cataclysm_fen_wall_struck'];wall.hide_render=False
for obj in bpy.data.collections['FINISHED'].objects:
    if 'roots' in obj.name and 'struck' in obj.name:obj.hide_render=False
cam=scene.camera;target=Vector((.12,-.12,.42))
cam.data.ortho_scale=1.18;cam.location=target+Vector((.8,-3,.65))
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
light=next(o for o in bpy.data.collections['REVIEW'].objects if o.type=='LIGHT')
light.location=(-2,-2,4);light.data.energy=650;light.data.size=2
material=wall.data.materials[0];node=material.node_tree.nodes.get('Principled BSDF')
socket=node.inputs['Emission Strength'];link=socket.links[0];output=link.from_socket
material.node_tree.links.remove(link);socket.default_value=0
scene.render.filepath=str(out/'scar-material-off.png');bpy.ops.render.render(write_still=True)
material.node_tree.links.new(output,socket)
scene.render.filepath=str(out/'scar-material-peak.png');bpy.ops.render.render(write_still=True)
print('C6_SCAR_PAIR_OK')
