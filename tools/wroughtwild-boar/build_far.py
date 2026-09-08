"""Blender: volume-based distant LOD, rebaked atlas and transferred fitted skin.

-- SURFACE_DIRECTORY RIG_DIRECTORY NEW_OUTPUT
The generated source's nonmanifold sheets stop ordinary collapse near 35k.
This separate distance candidate closes small gaps; review its silhouette.
"""
import json,sys
from pathlib import Path
import bpy
from mathutils.kdtree import KDTree

surface,rig,output=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not output.exists();output.mkdir(parents=True)
settings=json.loads((Path(__file__).resolve().parent/'rig-study.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(rig/'boar-candidate.blend'))
scene=bpy.context.scene
source=bpy.data.objects['Kilnback - authored source']
near=bpy.data.objects['Kilnback - near candidate']
arm=bpy.data.objects['Kilnback - study rig']
for track in arm.animation_data.nla_tracks:track.mute=True
for bone in arm.pose.bones:bone.matrix_basis.identity()
scene.frame_set(0)
for obj in scene.objects:obj.hide_set(True);obj.hide_render=True
source.hide_set(False);source.hide_render=False
far=source.copy();far.data=source.data.copy();far.name='Kilnback - far rebaked candidate'
scene.collection.objects.link(far);far.hide_set(False);far.hide_render=False
bpy.ops.object.select_all(action='DESELECT');far.select_set(True);bpy.context.view_layer.objects.active=far
remesh=far.modifiers.new('Distant closed volume - 14 mm sampling','REMESH')
remesh.mode='VOXEL';remesh.voxel_size=settings['far_voxel_metres'];remesh.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=remesh.name)
far.data.calc_loop_triangles();volume_triangles=len(far.data.loop_triangles)
decimate=far.modifiers.new('Distant 10k silhouette candidate','DECIMATE')
decimate.ratio=min(1,settings['far_triangles']/volume_triangles);decimate.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=decimate.name)
far.data.validate(verbose=True)
while len(far.data.uv_layers):far.data.uv_layers.remove(far.data.uv_layers[0])
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.1519,island_margin=.012)
bpy.ops.object.mode_set(mode='OBJECT')
material=bpy.data.materials.new('Kilnback - far rebaked PBR');material.use_nodes=True
far.data.materials.clear();far.data.materials.append(material)
nodes=material.node_tree.nodes;links=material.node_tree.links;bsdf=nodes.get('Principled BSDF')
original=source.data.materials[0]
temp=bpy.data.materials.new('Temporary bake channel');temp.use_nodes=True
source.data.materials[0]=temp
tn=temp.node_tree.nodes;tl=temp.node_tree.links
emitter=tn.new('ShaderNodeEmission');tl.new(emitter.outputs[0],tn.get('Material Output').inputs['Surface'])
texture=tn.new('ShaderNodeTexImage');tl.new(texture.outputs['Color'],emitter.inputs['Color'])
scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.045;scene.render.bake.max_ray_distance=.07
scene.render.bake.margin=12
images={}
for name,file in [('base','base.png'),('orm','orm.png'),('scar','scar-mask.png'),('normal',None)]:
    image=bpy.data.images.new('Kilnback far '+name,width=settings['far_texture_pixels'],height=settings['far_texture_pixels'],alpha=False)
    image.colorspace_settings.name='sRGB' if name=='base' else 'Non-Color'
    target=nodes.new('ShaderNodeTexImage');target.image=image;nodes.active=target
    bpy.ops.object.select_all(action='DESELECT');source.select_set(True);far.select_set(True);bpy.context.view_layer.objects.active=far
    if file:
        texture.image=bpy.data.images.load(str(surface/file),check_existing=True)
        texture.image.colorspace_settings.name='sRGB' if name=='base' else 'Non-Color'
        bpy.ops.object.bake(type='EMIT')
    else:
        source.data.materials[0]=original
        scene.render.bake.normal_space='TANGENT';bpy.ops.object.bake(type='NORMAL')
    image.filepath_raw=str(output/('far-'+name+'.png'));image.file_format='PNG';image.save();image.pack()
    images[name]=(image,target)
links.new(images['base'][1].outputs['Color'],bsdf.inputs['Base Color'])
channels=nodes.new('ShaderNodeSeparateColor');links.new(images['orm'][1].outputs['Color'],channels.inputs['Color'])
links.new(channels.outputs['Green'],bsdf.inputs['Roughness']);links.new(channels.outputs['Blue'],bsdf.inputs['Metallic'])
normal=nodes.new('ShaderNodeNormalMap');links.new(images['normal'][1].outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])

tree=KDTree(len(near.data.vertices))
for vertex in near.data.vertices:tree.insert(vertex.co,vertex.index)
tree.balance()
groups=[far.vertex_groups.new(name=group.name) for group in near.vertex_groups]
max_transfer=0.0
for vertex in far.data.vertices:
    co,index,distance=tree.find(vertex.co);max_transfer=max(max_transfer,distance)
    weights=[(g.group,g.weight) for g in near.data.vertices[index].groups if g.weight>1e-7]
    assert 0<len(weights)<=4
    total=sum(w for _,w in weights)
    for index,weight in weights:groups[index].add([vertex.index],weight/total,'REPLACE')
far.parent=arm
modifier=far.modifiers.new('Transferred anatomical deformation','ARMATURE');modifier.object=arm
source.hide_set(True);source.hide_render=True
arm.hide_set(False);arm.hide_render=False
bpy.ops.object.select_all(action='DESELECT');far.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
for track in arm.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=str(output/'boar-far.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
for track in arm.animation_data.nla_tracks:track.mute=True
# Restore the editable scar response after exporting the plain PBR fallback.
marks=nodes.new('ShaderNodeSeparateColor');links.new(images['scar'][1].outputs['Color'],marks.inputs['Color'])
mix=nodes.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.012,.006,.004,1)
links.new(marks.outputs['Green'],mix.inputs[0]);links.new(images['base'][1].outputs['Color'],mix.inputs[1]);links.new(mix.outputs[0],bsdf.inputs['Base Color'])
gain=nodes.new('ShaderNodeMath');gain.operation='MULTIPLY';gain.inputs[1].default_value=3.2
links.new(marks.outputs['Red'],gain.inputs[0]);links.new(gain.outputs[0],bsdf.inputs['Emission Strength']);bsdf.inputs['Emission Color'].default_value=(1,.12,.012,1)
far.hide_set(True);far.hide_render=True;near.hide_set(False);near.hide_render=False
for image in bpy.data.images:
    if image.source=='FILE' and image.has_data:image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(output/'boar-candidate.blend'),compress=True)
far.data.calc_loop_triangles()
(output/'far-report.json').write_text(json.dumps({'voxel_metres':settings['far_voxel_metres'],'texture_pixels':settings['far_texture_pixels'],'volume_triangles':volume_triangles,'final_triangles':len(far.data.loop_triangles),'vertices':len(far.data.vertices),'max_weight_transfer_distance_metres':max_transfer,'purpose':'Volume sampling closes fine source gaps at distance; rebaked maps preserve the original material and attached scar in a new UV atlas. Inspect at 18 m before adoption.'},indent=2)+'\n')
print('BOAR_FAR_OK '+str(output),flush=True)
