"""Read-only inspection of approved ART-02 master; output only to fresh C2 folder."""
import bpy,json,sys,hashlib,struct
from pathlib import Path
from mathutils import Vector
depot,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]];assert not out.exists();out.mkdir(parents=True)
package=depot/'build/grove-art02/emberroot-handoff'
manifest=json.loads((package/'manifest.json').read_text());verified={}
for rel in ['editable/rock-finished.blend','review/root-bank.glb','review/rock-base.png','review/rock-orm.png','review/forest-floor.png']:
 p=package/rel;h=hashlib.sha256(p.read_bytes()).hexdigest();assert h==manifest[rel]['sha256'];verified[rel]=h
raw=depot/'build/grove-art02/rock-source-v01/rock.glb';data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0];metadata=json.loads(data[20:20+length])['asset']
bpy.ops.wm.open_mainfile(filepath=str(package/'editable/rock-finished.blend'))
rows=[]
for o in bpy.context.scene.objects:
 if o.type=='MESH':
  o.data.calc_loop_triangles();rows.append({'name':o.name,'triangles':len(o.data.loop_triangles),'bounds':[list(o.dimensions)],'hidden':o.hide_render,'materials':[m.name for m in o.data.materials]})
(out/'inspection.json').write_text(json.dumps({'verified':verified,'raw_sha256':hashlib.sha256(data).hexdigest(),'raw_metadata':metadata,'objects':rows},indent=2))
scene=bpy.context.scene
for o in scene.objects:o.hide_render=o.type!='MESH' or o.name!='Quiet river oak'
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('C2 neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.3,.34,.4,1)
light=bpy.data.objects.new('C2 sun',bpy.data.lights.new('C2 sun','SUN'));scene.collection.objects.link(light);light.rotation_euler=(.5,-.6,-.5);light.data.energy=2
cam=bpy.data.objects.new('C2 camera',bpy.data.cameras.new('C2 camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=3.7
for name,at in [('front',(0,5,2)),('back',(0,-5,2)),('side',(5,0,2)),('top',(0,0,6)),('underside',(0,0,-6)),('three-quarter',(4,5,3))]:
 cam.location=at;cam.rotation_euler=(Vector((0,0,.8))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
print('C2_SOURCE_INSPECTION_OK')
