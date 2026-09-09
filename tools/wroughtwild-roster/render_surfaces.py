"""Reopen a packed surface source, verify its geometry/maps, render real views.

Blender -- SURFACE_FOLDER NEW_EVIDENCE
"""
import hashlib
import json
import math
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector

args = sys.argv[sys.argv.index('--')+1:]
source,output = [Path(p).resolve() for p in args[:2]]
assert not output.exists()
output.mkdir(parents=True)
report = json.loads((source/'surface-report.json').read_text(encoding='utf-8'))
asset = report['asset']
bpy.ops.wm.open_mainfile(filepath=str(source/(asset+'-surface.blend')))
host = bpy.data.objects[asset+' - surface host']
mesh = host.data
points = np.array([v.co[:] for v in mesh.vertices],dtype=np.float32)
faces = np.array([p.vertices[:] for p in mesh.polygons],dtype=np.int32)
assert hashlib.sha256(points.tobytes()+faces.tobytes()).hexdigest() == report['geometry_sha256']
assert len(faces) == report['triangles'] and np.isfinite(points).all()
assert host['source_sha256'] == report['source_sha256']
assert not any(o.type == 'ARMATURE' for o in bpy.data.objects)
for attachment in report.get('face_repair',{}).get('attachments',[]):
    obj=bpy.data.objects[attachment['name']]
    p=np.array([v.co[:] for v in obj.data.vertices],np.float32)
    f=np.array([v.vertices[:] for v in obj.data.polygons],np.int32)
    assert hashlib.sha256(p.tobytes()+f.tobytes()).hexdigest()==attachment['geometry_sha256']
    assert len(f)==attachment['triangles'] and obj['attachment']=='head'
assert len(mesh.uv_layers) == 1
mask = next(n.image for n in mesh.materials[0].node_tree.nodes if n.name == 'Attached scar map')
assert mask.packed_file and list(mask.size) == report.get('mask_dimensions',[report['mask_size']]*2)
pixels = np.array(mask.pixels[:],dtype=np.float32).reshape(-1,4)
assert (pixels[:,0] <= pixels[:,1]+.005).all() and pixels[:,0].max()>.9
assert .001 < np.ptp(pixels[pixels[:,0]>.1,2]) <= 1.0
gain = mesh.materials[0].node_tree.nodes['Review emission gain']
peak = gain.inputs[1].default_value
scene = bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=1024;scene.render.resolution_y=1024;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
if scene.world is None: scene.world=bpy.data.worlds.new('Surface review world')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.25,.29,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.4
target=Vector((0,0,(points[:,2].max()+points[:,2].min())*.5))
def aim(obj,at): obj.rotation_euler=(Vector(at)-obj.location).to_track_quat('-Z','Y').to_euler()
for name,at,energy in [('Key',(-3,-4,6),700),('Fill',(4,-1,3),450),('Rim',(0,4,5),650)]:
    light=bpy.data.objects.new(name,bpy.data.lights.new(name,'AREA'));scene.collection.objects.link(light)
    light.location=at;light.data.energy=energy;light.data.size=4;aim(light,target)
camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera)
camera.data.type='ORTHO';camera.data.ortho_scale=2.65;scene.camera=camera
for angle in ([0,180,270] if '--face' in args else [0,180]):
    rad=math.radians(angle);camera.location=target+Vector((5*math.cos(rad),5*math.sin(rad),1.25));aim(camera,target)
    for mode,value in [('dark',0),('lit',peak)]:
        gain.inputs[1].default_value=value
        scene.render.filepath=str(output/(mode+'-az'+str(angle)+'.png'))
        bpy.ops.render.render(write_still=True)
if '--face' in args:
    target=Vector((0,-.85,.78))
    camera.data.ortho_scale=.82
    for angle in [270,315]:
        rad=math.radians(angle);camera.location=target+Vector((5*math.cos(rad),5*math.sin(rad),.6));aim(camera,target)
        gain.inputs[1].default_value=peak
        scene.render.filepath=str(output/('face-az'+str(angle)+'.png'))
        bpy.ops.render.render(write_still=True)
result={'passed':True,'asset':asset,'checks':8+2*len(report.get('face_repair',{}).get('attachments',[])),'geometry_sha256':report['geometry_sha256'],
        'source_sha256':report['source_sha256'],'views':[p.stem for p in sorted(output.glob('*.png'))],
        'note':'Reopened exact surface geometry, identity, finite positions, no rig, UV layer, packed mask dimensions, contained core and nonconstant travel. Renders are static peak/off comparisons.'}
(output/'reopen.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('ROSTER_SURFACE_REOPEN_OK',asset,flush=True)
