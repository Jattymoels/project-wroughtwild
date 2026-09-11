import bpy,sys
from pathlib import Path
from mathutils import Vector
kit,out=map(Path,sys.argv[sys.argv.index('--')+1:]);assert not out.exists();bpy.ops.wm.open_mainfile(filepath=str(kit/'c5-master.blend'));s=bpy.context.scene
for o in s.objects:
 if o.type=='MESH':o.hide_render=True
obj=bpy.data.objects['copper_vein-u8-cold-lod0'];obj.hide_render=False;s.camera.location=(3.2,4.2,3.1);s.camera.rotation_euler=(Vector((0,0,.2))-s.camera.location).to_track_quat('-Z','Y').to_euler();s.camera.data.ortho_scale=2.85;s.render.resolution_x=1100;s.render.resolution_y=700
m=bpy.data.materials.new('runtime clay');m.use_nodes=True;s.view_layers[0].material_override=m;s.render.filepath=str(out);bpy.ops.render.render(write_still=True)
