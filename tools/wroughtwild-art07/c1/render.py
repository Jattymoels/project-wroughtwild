"""Actual packed-master views in material, clay and hidden-side directions."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
kit,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(kit/'c1-master.blend'));scene=bpy.context.scene;scene.cycles.device='CPU';scene.cycles.samples=16
scene.render.resolution_x=1100;scene.render.resolution_y=900;scene.render.resolution_percentage=100
for o in list(bpy.data.collections['REVIEW'].objects):o.hide_render=True
records=json.loads((kit/'models.json').read_text());cam=scene.camera
clay=bpy.data.materials.new('Inspection neutral clay');clay.diffuse_color=(.45,.46,.47,1)
for name in ['bog-oak-full-lod0','bog-oak-worked-lod0','bog-oak-stump-lod0','clay-24-lod0','clay-8-lod0','clay-0-lod0','reed-24-lod0','reed-6-lod0','fen-sedge-lod0','fungal-detritus-lod0']:
    objects=[bpy.data.objects[n] for n in records['assets'][name]['objects']]
    for o in objects:o.hide_render=False
    lo,hi=map(Vector,records['assets'][name]['bounds_blender_m']);center=(lo+hi)/2;extent=max(hi-lo)
    cam.data.ortho_scale=extent*1.35
    for angle,offset in [('material',(2,-3,2)),('clay',(2,-3,2)),('back',(-2,3,1)),('side',(3,0,.7)),('top',(0,-.01,4)),('underside',(1,-2,-3))]:
        cam.location=center+Vector(offset)*extent;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();scene.view_layers[0].material_override=clay if angle=='clay' else None
        scene.render.filepath=str(out/(name+'-'+angle+'.png'));bpy.ops.render.render(write_still=True)
    for o in objects:o.hide_render=True
scene.view_layers[0].material_override=None
# Close view of the physical native chopping incision, with emission absent.
for n in records['assets']['bog-oak-worked-lod0']['objects']:bpy.data.objects[n].hide_render=True
print('C1_RENDER_OK',60)
