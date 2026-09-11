"""Actual reopened master: clay, contact, hidden sides and family close-ups."""
import bpy,sys
from pathlib import Path
from mathutils import Vector
master,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]];assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(master));scene=bpy.context.scene;scene.cycles.device='CPU';scene.cycles.samples=16;scene.render.resolution_x=1100;scene.render.resolution_y=850
for o in scene.objects:o.hide_render=o.type=='MESH'
cam=scene.camera;clay=bpy.data.materials.new('Inspection neutral clay');clay.diffuse_color=(.4,.42,.43,1)
for name in ['slate-v0-full','slate-v0-worked','shellstone-v0-full','shellstone-v1-full','shellstone-v0-worked','upland-tussock-v0-lod0']:
 o=bpy.data.objects[name];o.hide_render=False;cam.data.ortho_scale=.85 if name.startswith('upland') else 2.55
 target=Vector((0,0,.16 if name.startswith('upland') else .26))
 for angle,at in [('material',(3,4,3.5)),('front',(0,4,.85)),('back',(0,-4,1.5)),('side',(4,0,1.2)),('top',(0,0,5)),('underside',(0,0,-5)),('clay',(3,4,3.5))]:
  cam.location=at;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.material_override=clay if angle=='clay' else None;scene.render.filepath=str(out/(name+'-'+angle+'.png'));bpy.ops.render.render(write_still=True)
 o.hide_render=True
print('C2_MASTER_VIEWS_OK')
