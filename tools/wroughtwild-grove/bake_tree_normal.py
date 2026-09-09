"""Transfer detailed source bark relief into the retained tree UV layout."""
import bpy, json, sys
from pathlib import Path
source,out=map(Path,sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source.resolve()))
high=bpy.data.objects['SOURCE - intact normalized oak'];low=bpy.data.objects['Quiet river oak']
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.context.scene.objects:obj.hide_render=True;obj.hide_set(True)
for obj in [high,low]:obj.hide_render=False;obj.hide_set(False);obj.select_set(True)
bpy.context.view_layer.objects.active=low
normal=bpy.data.images.new('Oak - baked source normal',width=2048,height=2048,alpha=False)
normal.generated_color=(.5,.5,1,1);normal.colorspace_settings.name='Non-Color'
for material in low.data.materials:
    nodes=material.node_tree.nodes;target=nodes.new('ShaderNodeTexImage');target.image=normal;nodes.active=target
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.055;scene.render.bake.max_ray_distance=.11;scene.render.bake.margin=8
bpy.ops.object.bake(type='NORMAL')
normal.filepath_raw=str((out/'tree-normal.png').resolve());normal.file_format='PNG';normal.save();normal.pack()
(out/'normal-report.json').write_text(json.dumps({'source_blend':str(source),'size':2048,'cage_extrusion_m':.055,'max_ray_distance_m':.11,'purpose':'Transfer dense bark normals; no geometry or source texture mutation.'},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str((out/'tree-normal-bake.blend').resolve()),compress=True)
print('TREE_NORMAL_OK')
