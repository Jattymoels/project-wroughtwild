"""Actual read-only Blender inspection of the previous Thrumroot source."""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
depot=Path('C:/Users/Matty/Dev/project-wroughtwild')
root=Path(__file__).resolve().parents[3]
out=Path(sys.argv[sys.argv.index('--')+1])
if not out.is_absolute():out=root/out
assert out.is_relative_to(root/'build/art07/f2')
out.mkdir(parents=True,exist_ok=False)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
report=[]
for i,name in enumerate(['strange_thrumroot_core','strange_thrumroot_shell','deadfall']):
    bpy.ops.object.select_all(action='DESELECT');bpy.ops.import_scene.gltf(filepath=str(depot/'game/assets/authored'/f'{name}.glb'))
    objs=list(bpy.context.selected_objects);meshes=[o for o in objs if o.type=='MESH']
    coords=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    lo=Vector(tuple(min(v[k] for v in coords) for k in range(3)));hi=Vector(tuple(max(v[k] for v in coords) for k in range(3)))
    scale=2.2/max(hi-lo)
    for o in objs:
        if o.parent is None:o.location=(o.location-Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z)))*scale+Vector((0,(i-1)*1.8,0));o.scale*=scale
    tri=0
    for o in meshes:o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
    report.append({'name':name,'source_bounds':list(hi-lo),'triangles':tri,'inspection_uniform_scale':scale})
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.resolution_x=1200;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.color=(.2,.2,.2)
for loc,power,size in [((1,-3,6),1500,5),((-3,2,4),1000,4)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,.3))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(4,-6,5));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=6;scene.camera=cam
scene.render.filepath=str(out/'existing-source.png');bpy.ops.render.render(write_still=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print('F2_EXISTING_INSPECTED',report)
