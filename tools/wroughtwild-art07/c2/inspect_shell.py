"""Read-only raw shellstone inspection, normalized copy with six material views."""
import bpy,sys,json,struct,hashlib
from pathlib import Path
from mathutils import Vector
source,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]];assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source));objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@v.co for o in objects for v in o.data.vertices];lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)));scale=2/max(hi-lo)
for o in objects:
 world=o.matrix_world.copy();o.parent=None;o.matrix_world.identity()
 for v in o.data.vertices:v.co=(world@v.co-Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z)))*scale
 o.data.calc_loop_triangles()
blob=source.read_bytes();meta=json.loads(blob[20:20+struct.unpack_from('<I',blob,12)[0]])['asset']
(out/'inspection.json').write_text(json.dumps({'source':str(source),'sha256':hashlib.sha256(blob).hexdigest(),'metadata':meta,'raw_bounds_blender_m':[list(lo),list(hi)],'uniform_inspection_scale':scale,'triangles':sum(len(o.data.loop_triangles) for o in objects)},indent=2)+'\n')
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.render.resolution_x=1100;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.4,.46,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));scene.collection.objects.link(sun);sun.data.energy=2;sun.rotation_euler=(.6,-.6,-.4)
cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=2.6
for name,at in [('three-quarter',(3,4,2)),('front',(0,4,1)),('back',(0,-4,1)),('side',(4,0,1)),('top',(0,0,5)),('underside',(0,0,-5))]:
 cam.location=at;cam.rotation_euler=(Vector((0,0,.3))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
print('C2_RAW_SHELL_INSPECTION_OK')
