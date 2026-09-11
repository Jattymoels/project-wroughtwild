"""Reopen packed master and render actual geometry in material and neutral clay."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
master,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(master));scene=bpy.context.scene;scene.cycles.device='CPU'
scene.render.filepath=str(out/'family.png');bpy.ops.render.render(write_still=True)
for o in bpy.data.collections['REVIEW'].objects:
    if o.type=='MESH':o.hide_render=True
cam=scene.camera;cam.data.ortho_scale=2.85;scene.render.resolution_x=1100;scene.render.resolution_y=700;scene.cycles.samples=16
cfg=json.loads(Path(__file__).with_name('kit.json').read_text());clay=bpy.data.materials.new('Neutral inspection clay');clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.45,.45,.45,1);clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.85
for row in cfg['ores']:
    for state,unit,crack in [('full',row['units'],False),('worked',row['units']-2,False),('cracked',row['units'],row['id']!='iron_vein')]:
        o=bpy.data.objects[f"{row['id']}-u{unit}-{'cracked' if crack else 'cold'}"];o.hide_render=False
        views=[('material',(3.2,4.2,3.1)),('clay',(3.2,4.2,3.1))]
        if state=='full':views+=[('front',(0,4,1)),('back',(0,-4,1)),('side',(4,0,1)),('top',(0,0,5)),('underside',(0,0,-5))]
        for view,at in views:
            cam.location=at;cam.rotation_euler=(Vector((0,0,.20))-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.material_override=clay if view=='clay' else None
            scene.render.filepath=str(out/f"{row['id']}-{state}-{view}.png");bpy.ops.render.render(write_still=True)
        o.hide_render=True
print('C5_PACKED_RENDER_OK')
