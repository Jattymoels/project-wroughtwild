"""C4 actual multi-angle Blender inspection. Original GLB remains immutable."""
import bpy,json,sys,math,struct
from pathlib import Path
from mathutils import Vector,Matrix
source,out=map(lambda x:Path(x).resolve(),sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
pts=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
low=Vector([min(p[i] for p in pts) for i in range(3)]);high=Vector([max(p[i] for p in pts) for i in range(3)])
# Centre on the lower trunk, not on asymmetric projecting upper branches.
basepts=[p for p in pts if p.z<low.z+(high.z-low.z)*.35]
base=Vector(((min(p.x for p in basepts)+max(p.x for p in basepts))/2,(min(p.y for p in basepts)+max(p.y for p in basepts))/2,low.z))
factor=4.4/(high.z-low.z)
for o in objects:
    o.matrix_world=Matrix.Scale(factor,4)@Matrix.Translation(-base)@o.matrix_world
    bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
pts=[v.co for o in objects for v in o.data.vertices]
blob=source.read_bytes();n=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+n])
report={'raw':str(source),'metadata':doc.get('extras',{}),'asset':doc.get('asset',{}),'scale':factor,'subtract':list(base),'normalized_height':4.4,'walk_radius':max(Vector((p.x,p.y)).length for p in pts if p.z<=2.6),'bounds':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]],'meshes':[]}
for o in objects:
    o.data.calc_loop_triangles()
    report['meshes'].append({'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'degenerates':sum(t.area<1e-12 for t in o.data.loop_triangles)})
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=700;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.23,.26,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
sun=bpy.data.objects.new('Inspection sun',bpy.data.lights.new('Inspection sun','SUN'));scene.collection.objects.link(sun);sun.rotation_euler=(.6,-.5,-.5);sun.data.energy=2
cam=bpy.data.objects.new('Inspection camera',bpy.data.cameras.new('Inspection camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=5.5
clay=bpy.data.materials.new('Neutral clay');clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.35,.35,.35,1)
for name,at in [('front',(0,-12,2.3)),('back',(0,12,2.3)),('side',(12,0,2.3)),('threequarter',(8,-12,5)),('top',(0,-.01,18)),('underside',(5,-10,-4))]:
    cam.location=at;cam.rotation_euler=(Vector((0,0,2.1))-cam.location).to_track_quat('-Z','Y').to_euler()
    for material in [False,True]:
        scene.view_layers[0].material_override=None if material else clay
        scene.render.filepath=str(out/(name+('-material' if material else '-clay')+'.png'));bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=None
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'ash-source.blend'),compress=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2)+'\n');print('C4_SOURCE_INSPECTION_OK',report)
