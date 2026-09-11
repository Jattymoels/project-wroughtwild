"""Fresh import, uniform metric fit, raw metadata and multi-angle inspection."""
import bpy,sys,json,math,struct,hashlib
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[3]
raw,out=map(lambda s:Path(s).resolve(),sys.argv[sys.argv.index('--')+1:]);assert out.is_relative_to(ROOT/'build/art07/f2');out.mkdir(parents=True,exist_ok=False)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(raw));meshes=[o for o in bpy.context.selected_objects if o.type=='MESH']
bpy.context.view_layer.update()
turn=Matrix.Rotation(math.pi/2,4,'Z')
for o in meshes:o.matrix_world=turn@o.matrix_world
bpy.context.view_layer.update()
coords=[o.matrix_world@ve.co for o in meshes for ve in o.data.vertices]
lo=Vector([min(p[k] for p in coords) for k in range(3)]);hi=Vector([max(p[k] for p in coords) for k in range(3)])
# glTF import already maps Y-up to Blender Z-up. No second axis rotation.
factor=2.14/(hi.x-lo.x);centre=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
for o in meshes:
    world=o.matrix_world.copy()
    for ve in o.data.vertices:ve.co=(world@ve.co-centre)*factor
    o.matrix_world.identity();o.name='ThrumrootSource'
rawbytes=raw.read_bytes();length=struct.unpack_from('<I',rawbytes,12)[0];meta=json.loads(rawbytes[20:20+length])
report={'raw_sha256':hashlib.sha256(rawbytes).hexdigest(),'raw_blender_bounds':[list(lo),list(hi)],'uniform_scale':factor,'subtract_before_scaling':list(centre),'game_bounds':[float((hi.x-lo.x)*factor),float((hi.z-lo.z)*factor),float((hi.y-lo.y)*factor)],'gltf_asset':meta.get('asset'),'gltf_extras':meta.get('extras'),'meshes':[]}
for o in meshes:
    o.data.calc_loop_triangles();report['meshes'].append({'triangles':len(o.data.loop_triangles),'degenerate_triangles':sum(t.area<1e-12 for t in o.data.loop_triangles),'nonfinite_vertices':sum(not all(math.isfinite(c) for c in ve.co) for ve in o.data.vertices),'surfaces':len(o.data.materials)})
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'inspected-source.blend'))
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=24;s.render.resolution_x=1200;s.render.resolution_y=800;s.render.resolution_percentage=100;s.world.color=(.25,.25,.25)
for at,power,size in [((2,-3,5),1000,4),((-3,1,2),750,3)]:
    bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.size=size;o.rotation_euler=(Vector((0,0,.4))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();s.camera=bpy.context.object;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=2.75
clay=bpy.data.materials.new('InspectionClay');clay.diffuse_color=(.45,.46,.43,1)
for mode in ['material','clay']:
    s.view_layers[0].material_override=clay if mode=='clay' else None
    for name,at in [('front',(0,-4,1)),('back',(0,4,1)),('side',(4,0,1)),('three-quarter',(2.5,-4,2)),('top',(0,0,5)),('underside',(1,-3,-2))]:
        s.camera.location=at;s.camera.rotation_euler=(Vector((0,0,.42))-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(out/(mode+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2)+'\n');print('F2_SOURCE_INSPECTED',report)
