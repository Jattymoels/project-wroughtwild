"""Fresh Blender imports, immutable raw metadata, six actual material/clay views."""
import bpy,json,math,sys,struct,hashlib
from pathlib import Path
from mathutils import Vector
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
def digest(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def main():
 args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]).resolve();out.mkdir(parents=True,exist_ok=False)
 bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
 scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.cycles.device='CPU'
 scene.render.threads_mode='FIXED';scene.render.threads=8
 scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100
 scene.view_settings.view_transform='AgX'
 world=bpy.data.worlds.new('Neutral');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.world=world
 for name,at,power,size in [('Key',(-3,-4,6),850,4),('Fill',(4,-2,3),650,4),('Rim',(0,4,5),950,3)]:
  d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=at;aim(o,(0,0,.7))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(cam);cam.data.type='ORTHO';cam.data.ortho_scale=2.45;scene.camera=cam
 clay=bpy.data.materials.new('Neutral clay');clay.diffuse_color=(.36,.34,.3,1)
 records=[]
 for src in map(Path,args[1:]):
  data=src.read_bytes();chunk=struct.unpack_from('<I',data,12)[0];meta=json.loads(data[20:20+chunk]);name=src.parent.name+'_'+src.stem
  bpy.ops.import_scene.gltf(filepath=str(src));objs=list(bpy.context.selected_objects);meshes=[o for o in objs if o.type=='MESH']
  points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
  lo=Vector([min(p[i] for p in points) for i in range(3)]);hi=Vector([max(p[i] for p in points) for i in range(3)]);factor=1.8/max(hi-lo)
  triangles=0;degen=0
  for o in meshes:
   o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);degen+=sum(t.area<1e-12 for t in o.data.loop_triangles)
   transform=o.matrix_world.copy()
   for v in o.data.vertices:v.co=(transform@v.co-Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z)))*factor
   o.matrix_world.identity()
  records.append({'path':str(src),'sha256':digest(src),'glb_metadata':meta.get('asset',{}),'raw_blender_bounds':[list(lo),list(hi)],'inspection_uniform_scale':factor,'triangles':triangles,'degenerate':degen,'mesh_objects':len(meshes),'images':[{'name':i.name,'size':list(i.size)} for i in bpy.data.images if i.source=='FILE']})
  views={'front':(0,-5,.9),'back':(0,5,.9),'side':(5,0,.9),'threequarter':(3,-5,3),'top':(0,-.01,6),'underside':(0,-.01,-6)}
  for mode in ['material','clay']:
   scene.view_layers[0].material_override=clay if mode=='clay' else None
   for label,at in views.items():cam.location=at;aim(cam,(0,0,.85));scene.render.filepath=str(out/f'{name}-{mode}-{label}.png');bpy.ops.render.render(write_still=True)
  for o in objs:
   if o.name in bpy.data.objects:bpy.data.objects.remove(o,do_unlink=True)
  scene.view_layers[0].material_override=None
 (out/'inspection.json').write_text(json.dumps(records,indent=2)+'\n')
 print('F1_SOURCE_INSPECTION_OK',len(records))
main()
