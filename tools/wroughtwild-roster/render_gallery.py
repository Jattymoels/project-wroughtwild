"""Blender: render the six actual stronger GLBs together; no image compositing."""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

repo, output = (Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:])
assert not output.exists()
config = json.loads((repo/'tools/wroughtwild-roster/roster.json').read_text(encoding='utf-8'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.threads_mode = 'FIXED'
scene.render.threads = 8
scene.render.resolution_x = 1800
scene.render.resolution_y = 1250
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.20,.23,.26,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .5
for index, row in enumerate(config['assets']):
    before = set(bpy.data.objects)
    source = repo/'build/roster-art06'/f"{row['id']}-source-{row['version']}"/(row['id']+'.glb')
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in set(bpy.data.objects)-before if obj.type=='MESH']
    rotation = Matrix.Rotation(math.radians(45+(180 if row['id']=='gloom_crawler' else 0)),4,'Z')
    points = [rotation@obj.matrix_world@v.co for obj in meshes for v in obj.data.vertices]
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    factor = 1.65/max(hi-lo)
    x, z = (index%3-1)*2.15, 2.1 if index<3 else 0
    # Vertically centre short/long silhouettes inside the same review cell.
    z += (1.65-(hi.z-lo.z)*factor)*.5
    centre = Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    transform = Matrix.Translation((x,0,z))@Matrix.Scale(factor,4)@Matrix.Translation(-centre)@rotation
    for obj in meshes: obj.matrix_world = transform@obj.matrix_world
    curve = bpy.data.curves.new(row['id']+' label','FONT')
    curve.body = row['id'].replace('_',' ').title()+' / '+row['animal']
    curve.align_x = 'CENTER'
    curve.size = .105
    label = bpy.data.objects.new(curve.name,curve)
    scene.collection.objects.link(label)
    label.location = (x,-1.5,1.96 if index<3 else -.15)
    label.rotation_euler.x = math.pi/2
    mat = bpy.data.materials.get('Labels') or bpy.data.materials.new('Labels')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=(.8,.84,.88,1)
    bsdf.inputs['Emission Color'].default_value=(.8,.84,.88,1)
    bsdf.inputs['Emission Strength'].default_value=.4
    curve.materials.append(mat)

def aim(obj, at):
    obj.rotation_euler=(Vector(at)-obj.location).to_track_quat('-Z','Y').to_euler()

for name, at, energy in [('Key',(-4,-5,7),1200),('Fill',(4,-4,4),800),('Rim',(0,3,6),1000)]:
    obj=bpy.data.objects.new(name,bpy.data.lights.new(name,'AREA'))
    scene.collection.objects.link(obj)
    obj.location=at
    obj.data.energy=energy
    obj.data.shape='DISK'
    obj.data.size=5
    aim(obj,(0,0,1.8))
camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'))
scene.collection.objects.link(camera)
camera.location=(0,-10,1.8)
aim(camera,(0,0,1.8))
camera.data.type='ORTHO'
camera.data.ortho_scale=6.7
scene.camera=camera
scene.render.filepath=str(output)
bpy.ops.render.render(write_still=True)
print('ROSTER_ACTUAL_GALLERY_RENDERED',output)
