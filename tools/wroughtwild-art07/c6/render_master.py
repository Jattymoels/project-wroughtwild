"""Actual material, clay and hidden-side views of the reopened C6 packed source."""
import bpy, sys
from pathlib import Path
from mathutils import Vector
master,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(master));scene=bpy.context.scene;scene.cycles.device='CPU'
scene.render.resolution_x=1280;scene.render.resolution_y=900;scene.cycles.samples=20
scene.render.filepath=str(out/'kit-overview.png');bpy.ops.render.render(write_still=True)
for o in bpy.data.collections['REVIEW'].objects:
    if o.type=='MESH':o.hide_render=True
cam=scene.camera;light=next(o for o in bpy.data.collections['REVIEW'].objects if o.type=='LIGHT');light.location=(3,-4,6);light.data.energy=1000;light.data.size=5
clay=bpy.data.materials.new('C6 neutral inspection clay');clay.diffuse_color=(.35,.37,.38,1)
groups=['cataclysm_fen_wall','cataclysm_fen_wall_struck','cataclysm_rootvault_frame','cataclysm_forge_threshold','cataclysm_upland_wall','trail_transition','cataclysm_rootvault_roof','workbench','lf_clamp','lf_post']
for name in groups:
    objects=[o for o in bpy.data.collections['FINISHED'].objects if o.name==name or (o.name.startswith(name+' roots') and (('struck' in o.name)==('struck' in name)))]
    if name=='cataclysm_fen_wall_struck':objects+=[o for o in bpy.data.collections['FINISHED'].objects if o.name.startswith('cataclysm_fen_wall roots') and 'struck' in o.name]
    if name=='trail_transition':objects+=[bpy.data.objects['trail_transition litter']]
    for o in objects:o.hide_render=False
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    low=Vector([min(v[i] for v in points) for i in range(3)]);high=Vector([max(v[i] for v in points) for i in range(3)]);target=(low+high)*.5;span=max(high-low)
    cam.data.ortho_scale=span*1.35
    for angle,at in [('material',(1,-1,.6)),('back',(-1,1,.5)),('side',(1,-.12,.25)),('top',(0,0,1)),('underside',(1,-1,-.6)),('clay',(1,-1,.6))]:
        cam.location=target+Vector(at).normalized()*span*2;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.material_override=clay if angle=='clay' else None
        scene.render.filepath=str(out/(name+'-'+angle+'.png'));bpy.ops.render.render(write_still=True)
    for o in objects:o.hide_render=True
bpy.context.view_layer.material_override=None
print('C6_MASTER_RENDER_OK')
