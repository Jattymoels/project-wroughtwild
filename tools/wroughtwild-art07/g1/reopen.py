"""Fresh actual Blender reopen of every consumed editable master and GLB review."""
import bpy
import hashlib
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

masters,game,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
out.mkdir(parents=True,exist_ok=False)
rows=json.loads((masters/'masters.json').read_text())
report={'masters':[],'imports':[],'scope':'Original checked masters reopened from copied bytes. Static metric inspection assembly, not a second gameplay map or native work simulation.'}
for row in rows:
    path=masters/row['copy']
    assert hashlib.sha256(path.read_bytes()).hexdigest()==row['sha256']
    bpy.ops.wm.open_mainfile(filepath=str(path))
    images=[{'name':i.name,'size':list(i.size),'packed':bool(i.packed_file),'available':bool(i.packed_file) or Path(bpy.path.abspath(i.filepath)).is_file()} for i in bpy.data.images if i.source=='FILE']
    assert all(i['available'] for i in images),(row['copy'],[i for i in images if not i['available']])
    report['masters'].append(dict(row,meshes=sum(o.type=='MESH' for o in bpy.data.objects),images=images))
    print('G1_MASTER_REOPEN',row['copy'],len(images),flush=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
assets=[('assets/authored/e1/workbench_middle.glb',(-2.0,0,0)),
        ('assets/authored/e2/forge_basic_middle.glb',(0,0,0)),
        ('f4/assets/feeder_middle.glb',(2,0,0)),
        ('f5/red/red-source-mid.glb',(-2,-2.5,0)),
        ('f5/green/green-post-mid.glb',(0,-2.5,0)),
        ('art07_d2/assets/codex_roof_hip.glb',(2,-2.5,.5))]
for relative,offset in assets:
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(game/relative))
    added=set(bpy.data.objects)-before
    for obj in added:
        if obj.parent is None:obj.location+=Vector(offset)
    triangles=0
    for obj in added:
        if obj.type!='MESH':continue
        obj.data.calc_loop_triangles();triangles+=len(obj.data.loop_triangles)
        assert all(math.isfinite(c) for vertex in obj.data.vertices for c in vertex.co)
    report['imports'].append({'file':relative,'triangles':triangles,'offset_blender_m':offset})

# The F4/F5 GLBs deliberately externalize their runtime texture bindings.
# Resolve the same published maps for this static, emission-off Blender view.
maps=json.loads((game/'f4/textures.json').read_text())
for mat in bpy.data.materials:
    files={}
    if mat.name.startswith('RED_MINERAL'):
        files={role:game/'f5/red'/('red-'+suffix+'.png') for role,suffix in [('base','base'),('orm','orm'),('normal','normal')]}
    elif mat.name in maps:
        for row in maps[mat.name]:
            role='base' if row['colorspace']=='sRGB' else 'normal' if 'normal' in row['image'].lower() else 'orm'
            files[role]=game/'f4/textures'/(row['sha256']+'.png')
    if not files:continue
    mat.use_nodes=True
    nodes=mat.node_tree.nodes;nodes.clear();links=mat.node_tree.links
    output=nodes.new('ShaderNodeOutputMaterial');bsdf=nodes.new('ShaderNodeBsdfPrincipled');links.new(bsdf.outputs['BSDF'],output.inputs['Surface'])
    for role,path in files.items():
        image=bpy.data.images.load(str(path),check_existing=True);image.colorspace_settings.name='sRGB' if role=='base' else 'Non-Color'
        tex=nodes.new('ShaderNodeTexImage');tex.image=image
        if role=='base':links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
        elif role=='normal':
            normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.45;links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
        else:
            channels=nodes.new('ShaderNodeSeparateColor');links.new(tex.outputs['Color'],channels.inputs['Color']);links.new(channels.outputs['Green'],bsdf.inputs['Roughness']);links.new(channels.outputs['Blue'],bsdf.inputs['Metallic'])

scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('G1 neutral inspection');scene.world.color=(.25,.25,.25)
scene.view_settings.view_transform='AgX'
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.02))
floor=bpy.context.object
mat=bpy.data.materials.new('Neutral inspection floor');mat.diffuse_color=(.12,.15,.14,1);floor.data.materials.append(mat)
for at,power in [((2,-5,8),1800),((-5,-1,5),1400),((0,4,6),2000)]:
    bpy.ops.object.light_add(type='AREA',location=at)
    obj=bpy.context.object;obj.data.energy=power;obj.data.shape='DISK';obj.data.size=5
    obj.rotation_euler=(Vector((0,-1,.7))-obj.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(7,-11,8));scene.camera=bpy.context.object
scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=9
scene.camera.rotation_euler=(Vector((0,-1,.6))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'g1-inspection.blend'))
# Reopen our packed integration assembly, then render material and emission-off clay.
bpy.ops.wm.open_mainfile(filepath=str(out/'g1-inspection.blend'));scene=bpy.context.scene
for mode in ['material','clay']:
    if mode=='clay':
        clay=bpy.data.materials.new('Emission-off geometry');clay.diffuse_color=(.32,.30,.26,1)
        bpy.context.view_layer.material_override=clay
    scene.render.filepath=str(out/(mode+'.png'));bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps(report,indent=2))
print('G1_BLENDER_REOPEN_OK',len(rows),len(assets))
