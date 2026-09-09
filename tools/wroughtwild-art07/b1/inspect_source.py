"""Actual Blender source inspection and packed-source validation, B1 only."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Vector,Matrix
source,out,kind=sys.argv[sys.argv.index('--')+1:]
source=Path(source);out=Path(out);assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
if source.suffix=='.blend':
 bpy.ops.wm.open_mainfile(filepath=str(source))
 target=bpy.data.objects['Quiet river oak']
 for o in list(bpy.context.scene.objects):
  if o!=target:bpy.data.objects.remove(o,do_unlink=True)
 target.hide_set(False);target.hide_render=False
else:
 bpy.ops.import_scene.gltf(filepath=str(source));target=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 pts=[target.matrix_world@v.co for v in target.data.vertices]
 low=Vector([min(p[i] for p in pts) for i in range(3)]);high=Vector([max(p[i] for p in pts) for i in range(3)])
 factor=9/(high.z-low.z)
 target.matrix_world=Matrix.Scale(factor,4)@Matrix.Translation(-Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z)))@target.matrix_world
 bpy.context.view_layer.objects.active=target;target.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 target['raw_to_metres_uniform_scale']=factor;target['raw_centre_base']=list((low+Vector((high.x,high.y,low.z)))/2)
target.name=kind+' source';target.data.calc_loop_triangles()
pts=[v.co for v in target.data.vertices];low=[min(p[i] for p in pts) for i in range(3)];high=[max(p[i] for p in pts) for i in range(3)]
report={'source':str(source),'object':target.name,'bounds_blender_m':[low,high],'triangles':len(target.data.loop_triangles),'scale':target.get('raw_to_metres_uniform_scale',1),'degenerate_triangles':sum(t.area<1e-12 for t in target.data.loop_triangles),'finite':all(math.isfinite(c) for p in pts for c in p)}
assert report['finite']
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=800;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.25,.28,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
sun=bpy.data.objects.new('Inspection sun',bpy.data.lights.new('Inspection sun','SUN'));scene.collection.objects.link(sun);sun.rotation_euler=(.6,-.5,-.5);sun.data.energy=2
cam=bpy.data.objects.new('Inspection camera',bpy.data.cameras.new('Inspection camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=11
clay=bpy.data.materials.new('Neutral clay');clay.diffuse_color=(.42,.42,.42,1);clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.42,.42,.42,1)
for name,at in [('front',(0,-20,4.5)),('back',(0,20,4.5)),('side',(20,0,4.5)),('threequarter',(14,-18,9)),('top',(0,-.1,25)),('underside',(9,-15,-5))]:
 cam.location=at;cam.rotation_euler=(Vector((0,0,4))-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.view_layers[0].material_override=clay if name in ['back','top','underside'] else None
 scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=None
for im in bpy.data.images:
 if im.has_data and im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/(kind+'-source.blend')),compress=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2));print('B1_INSPECTION_OK',report)
