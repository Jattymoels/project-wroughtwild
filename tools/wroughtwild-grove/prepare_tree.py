"""Normalize and inspect the unmodified generated tree before surface work."""
import bpy, json, sys, hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
args=sys.argv[sys.argv.index('--')+1:]
raw,out=map(Path,args[:2]);kind=args[2] if len(args)>2 else 'tree'
settings=json.loads(Path(__file__).with_name('rock.json' if kind=='rock' else 'grove.json').read_text())
target_height=settings['height_m'] if kind=='rock' else settings['tree_height_m']
assert not out.exists()
out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(raw.resolve()))
obj = next(o for o in bpy.context.scene.objects if o.type=='MESH')
p=np.array([obj.matrix_world@v.co for v in obj.data.vertices])
lo,hi=p.min(0),p.max(0)
factor=target_height/(hi[2]-lo[2])
obj.matrix_world=Matrix.Scale(factor,4)@Matrix.Translation(-Vector(((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2])))@obj.matrix_world
bpy.context.view_layer.objects.active=obj
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
obj.name='Fractured rock - intact source' if kind=='rock' else 'River oak - intact source'
p=np.array([v.co for v in obj.data.vertices])
report={'raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'bounds':[p.min(0).tolist(),p.max(0).tolist()],'triangles':len(obj.data.polygons),'height_metres':target_height,'uniform_scale':factor}
(out/'inspection.json').write_text(json.dumps(report,indent=2))
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=1100;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.38,.42,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));scene.collection.objects.link(sun)
sun.rotation_euler=(.5,-.6,-.5);sun.data.energy=2
camera=bpy.data.objects.new('Inspection',bpy.data.cameras.new('Inspection'));scene.collection.objects.link(camera);scene.camera=camera
camera.data.type='ORTHO';camera.data.ortho_scale=10.5 if kind=='tree' else 4.1
for name,at in [('front',(0,-18,5)),('back',(0,18,5)),('side',(18,0,5))]:
    camera.location=at if kind=='tree' else Vector(at)*.25;camera.rotation_euler=(Vector((0,0,target_height*.5))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str((out/(name+'.png')).resolve());bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str((out/(kind+'-source.blend')).resolve()),compress=True)
print('TREE_INSPECTION_OK')
