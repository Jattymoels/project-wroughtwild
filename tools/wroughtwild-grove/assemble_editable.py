"""Make a packed Blender composition with the actual boar and authored maps.

Blender preview uses steady emission. Godot is the moving-light oracle.
"""
import bpy, json, math, sys
from pathlib import Path
from mathutils import Vector
kit,review,out=map(Path,sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str((kit/'grove-layout.blend').resolve()))
def image(name,linear=False):
    im=bpy.data.images.load(str((review/name).resolve()),check_existing=True)
    if linear:im.colorspace_settings.name='Non-Color'
    im.pack();return im
def pbr(name,base,orm,scar=None,normal=None):
    mat=bpy.data.materials.new(name);mat.use_nodes=True;nodes=mat.node_tree.nodes;links=mat.node_tree.links
    shader=nodes.get('Principled BSDF')
    b=nodes.new('ShaderNodeTexImage');b.image=image(base);links.new(b.outputs['Color'],shader.inputs['Base Color'])
    o=nodes.new('ShaderNodeTexImage');o.image=image(orm,True);s=nodes.new('ShaderNodeSeparateColor');links.new(o.outputs['Color'],s.inputs[0]);links.new(s.outputs['Green'],shader.inputs['Roughness']);links.new(s.outputs['Blue'],shader.inputs['Metallic'])
    if scar:
        t=nodes.new('ShaderNodeTexImage');t.image=image(scar,True);c=nodes.new('ShaderNodeSeparateColor');links.new(t.outputs['Color'],c.inputs[0])
        mix=nodes.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.017,.012,.008,1);links.new(c.outputs['Green'],mix.inputs[0]);links.new(b.outputs['Color'],mix.inputs[1]);links.new(mix.outputs[0],shader.inputs['Base Color'])
        gain=nodes.new('ShaderNodeMath');gain.operation='MULTIPLY';gain.inputs[1].default_value=1.5;links.new(c.outputs['Red'],gain.inputs[0]);links.new(gain.outputs[0],shader.inputs['Emission Strength']);shader.inputs['Emission Color'].default_value=(1,.12,.012,1)
    if normal:
        t=nodes.new('ShaderNodeTexImage');t.image=image(normal,True);n=nodes.new('ShaderNodeNormalMap');links.new(t.outputs['Color'],n.inputs['Color']);links.new(n.outputs[0],shader.inputs['Normal'])
    return mat
quiet=pbr('Quiet oak / packed PBR','tree-base.png','tree-orm.png',normal='tree-normal.png')
scarred=pbr('Scarred oak / steady Blender preview','tree-base.png','tree-orm.png','tree-scar.png','tree-normal.png')
rock=pbr('Fractured mineral / steady Blender preview','rock-base.png','rock-orm.png','rock-scar.png')
quiet_rock=pbr('Quiet mineral / packed PBR','rock-base.png','rock-orm.png')
for o in list(bpy.context.scene.objects):
    if o.type!='MESH' or not o.parent:continue
    role=o.parent.name
    name=o.data.materials[0].name if o.data.materials else ''
    if name in ['Leaf','Bark','Soil']:continue
    o.data=o.data.copy()
    if 'quiet-tree' in role:o.data.materials.clear();o.data.materials.append(quiet)
    elif 'altered-tree' in role or 'root-bank' in role:o.data.materials.clear();o.data.materials.append(scarred)
    elif 'fractured-rock' in role:o.data.materials.clear();o.data.materials.append(rock if -o.parent.location.y>8 else quiet_rock)
soil=bpy.data.materials['Soil'];nodes=soil.node_tree.nodes;links=soil.node_tree.links
t=nodes.new('ShaderNodeTexImage');t.image=image('forest-floor.png')
uv=nodes.new('ShaderNodeTexCoord');scale=nodes.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=2.5
links.new(uv.outputs['UV'],scale.inputs[0]);links.new(scale.outputs[0],t.inputs['Vector']);links.new(t.outputs[0],nodes.get('Principled BSDF').inputs['Base Color'])

layout=json.loads((review/'layout.json').read_text());row=next(r for r in layout['instances'] if r['role']=='boar')
bpy.ops.import_scene.gltf(filepath=str((review/'boar-mid.glb').resolve()))
imported=list(bpy.context.selected_objects)
parent=bpy.data.objects.new('Approved boar - pose/skin reference',None);bpy.context.collection.objects.link(parent)
x,y,z=row['position'];parent.location=(x,-z,y);parent.rotation_euler.z=-math.radians(row['yaw'])
bm=pbr('Kilnback / steady Blender preview','base.png','orm.png','scar-mask.png','normal.png')
for obj in imported:
    if obj.parent not in imported:obj.parent=parent
    if obj.type=='MESH':obj.data.materials.clear();obj.data.materials.append(bm)

# Water is review geometry, with no fluid/temperature/harvesting behaviour.
verts=[];faces=[]
for i in range(177):
    z=-44+i*.5;x=-5.8+math.sin(z*.12)+.35*math.sin(z*.31)
    verts.extend([(x-1.8,-z,-.40),(x+1.8,-z,-.40)])
    if i<176:a=i*2;faces.append((a,a+2,a+3,a+1))
mesh=bpy.data.meshes.new('Review stream');mesh.from_pydata(verts,[],faces)
water=bpy.data.objects.new('Review stream',mesh);bpy.context.collection.objects.link(water)
wm=bpy.data.materials.new('Review water');wm.use_nodes=True
wb=wm.node_tree.nodes.get('Principled BSDF');wb.inputs['Base Color'].default_value=(.045,.095,.105,1);wb.inputs['Roughness'].default_value=.19;wb.inputs['Metallic'].default_value=.35;mesh.materials.append(wm)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.world=bpy.data.worlds.new('Grove daylight');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.40,.51,.60,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
sun=bpy.data.objects.new('Review sun',bpy.data.lights.new('Review sun','SUN'));scene.collection.objects.link(sun);sun.rotation_euler=(.5,-.6,-.5);sun.data.energy=1.5;sun.data.angle=.08
camera=bpy.data.objects.new('Eye-height clearing camera',bpy.data.cameras.new('Clearing camera'));scene.collection.objects.link(camera);scene.camera=camera
capture=json.loads((review/'evidence/capture-manifest.json').read_text());at=next(c['camera'] for c in capture if c['name']=='clearing-day')
camera.location=(at[0],-at[2],at[1]);camera.rotation_euler=(Vector((4,-6,2.1))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.lens=24.77
scene.render.resolution_x=1440;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene['review_note']='ART-02 editable composition. Blender steady-light preview; Godot supplies exact moving scars, lighting and route checks. No game integration.'
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str((out/'emberroot-grove.blend').resolve()),compress=True)
print('GROVE_EDITABLE_OK')
