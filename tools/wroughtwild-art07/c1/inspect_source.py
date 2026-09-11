"""Fresh actual clay mesh inspection; six material and six clay directions."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Vector,Matrix
source,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]];assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source))
obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
lo=Vector([min(p[i] for p in pts) for i in range(3)]);hi=Vector([max(p[i] for p in pts) for i in range(3)])
base=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));factor=1.8/(hi.x-lo.x)
for o in obs:
    o.matrix_world=Matrix.Scale(factor,4)@Matrix.Translation(-base)@o.matrix_world
    bpy.context.view_layer.objects.active=o;bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
report={'raw_sha256':__import__('hashlib').sha256(source.read_bytes()).hexdigest(),'raw_bounds':[list(lo),list(hi)],'scale':factor,'subtract_raw_base':list(base),'normalized_width_m':1.8,'objects':len(obs)}
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=720;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.25,.28,.3,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
sun=bpy.data.objects.new('Key',bpy.data.lights.new('Key','SUN'));scene.collection.objects.link(sun);sun.rotation_euler=(.6,-.5,-.5);sun.data.energy=2
cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=2.5
clay=bpy.data.materials.new('Clay');clay.diffuse_color=(.42,.42,.42,1)
for name,at in [('front',(0,-4,.7)),('back',(0,4,.7)),('side',(4,0,.7)),('threequarter',(3,-4,2)),('top',(0,-.01,5)),('underside',(3,-4,-2))]:
    cam.location=at;cam.rotation_euler=(Vector((0,0,.35))-cam.location).to_track_quat('-Z','Y').to_euler()
    for mode in ['material','clay']:
        scene.view_layers[0].material_override=clay if mode=='clay' else None
        scene.render.filepath=str(out/(name+'-'+mode+'.png'));bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=None
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'clay-source.blend'),compress=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2));print('C1_INSPECTION_OK')
