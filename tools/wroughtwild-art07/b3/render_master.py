"""Actual packed-source views, including emission-off and hidden sides."""
import bpy,sys
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];master,out=[Path(p).resolve() for p in args[:2]];assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(master));scene=bpy.context.scene
scene.cycles.device='CPU'
scene.render.filepath=str(out/'blender-kit.png');bpy.ops.render.render(write_still=True)
if '--overview-only' in args:sys.exit(0)
for o in bpy.data.collections['REVIEW'].objects:
 if o.type=='MESH':o.hide_render=True
cam=scene.camera
clay=bpy.data.materials.new('Audit neutral clay');clay.diffuse_color=(.38,.4,.42,1)
groups={'boulder-full':['boulder-full'],'boulder-worked':['boulder-worked'],'boulder-remnant':['boulder-remnant'],'stone-seam':['seam left bedding','seam right bedding'],'river-bank':['river-bank stone','river-bank roots'],'rock-shelf-altered':['rock-shelf-altered'],'cave-threshold':[o.name for o in bpy.data.collections['FINISHED'].objects if o.name.startswith('cave ')]}
for name,names in groups.items():
 for n in names:bpy.data.objects[n].hide_render=False
 target=Vector((0,0,1.4 if name=='cave-threshold' else .45));cam.data.ortho_scale=5.1 if name=='cave-threshold' else (2.1 if name.startswith('boulder') else 4.1)
 for angle,at in [('material',(4,5,3)),('back',(-4,-5,2)),('side',(5,0,1)),('top',(0,0,6)),('underside',(2,2,-5)),('clay',(4,5,3))]:
  cam.location=Vector(at);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.material_override=clay if angle=='clay' else None
  scene.render.filepath=str(out/(name+'-'+angle+'.png'));bpy.ops.render.render(write_still=True)
 for n in names:bpy.data.objects[n].hide_render=True
bpy.context.view_layer.material_override=None
print('B3_MASTER_RENDER_OK')
