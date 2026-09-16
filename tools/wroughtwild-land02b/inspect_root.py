"""Inspect the actual generated source, retaining its editable normalized copy."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2];OUT=R/'build/land02b/source-art';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(R/'build/land02b/trellis-root-v1/source.glb'))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
coords=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
lo=Vector([min(p[i] for p in coords) for i in range(3)]);hi=Vector([max(p[i] for p in coords) for i in range(3)])
scale=7.5/(hi.z-lo.z);centre=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
report={'raw_bounds':[list(lo),list(hi)],'scale':scale,'normalisation':'raw world coordinates, centred XY, base Z=0, height=7.5 m','meshes':[]}
for ob in objects:
 matrix=ob.matrix_world.copy()
 for v in ob.data.vertices:v.co=(matrix@v.co-centre)*scale
 ob.matrix_world.identity();ob.data.calc_loop_triangles()
 report['meshes'].append({'name':ob.name,'triangles':len(ob.data.loop_triangles),'materials':len(ob.data.materials),'uv_layers':len(ob.data.uv_layers)})
 ob['source']='TRELLIS 0.6.0 raw candidate; uniform normalization only'
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.device='CPU'
scene.render.resolution_x=850;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.22,.22,.22)
scene.view_settings.view_transform='AgX'
for loc,energy,size in [((5,-7,11),1700,7),((-6,3,7),1200,6),((1,7,10),1800,5)]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=energy;l.data.shape='DISK';l.data.size=size;l.rotation_euler=(Vector((0,0,3.5))-l.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(11,-16,10));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=10.5;scene.camera=cam
for name,loc in [('root-front',(11,-16,10)),('root-rear',(-12,15,9))]:
 cam.location=loc;cam.rotation_euler=(Vector((0,0,3.5))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
for im in bpy.data.images:
 if im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'root-candidate.blend'),compress=True)
(OUT/'root-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ROOT_INSPECTION',json.dumps(report))
