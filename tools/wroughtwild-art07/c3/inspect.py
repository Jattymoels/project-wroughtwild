"""Inspect the verified B1 packed oak and deadwood before C3 authoring."""
import bpy, json, sys, math
from pathlib import Path
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).parent))
from prerequisites import PACKAGES, sha
out = Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not out.exists()
out.mkdir(parents=True)
master = PACKAGES['b1'][0]/'models/broadleaf/broadleaf-master.blend'
bpy.ops.wm.open_mainfile(filepath=str(master))
report = {'source': str(master), 'sha256': sha(master), 'objects': [],
          'native_tree_body_xyz': [.805, 4.5, .805], 'native_deadfall_body_xyz': [1.65, .65, .9]}
for obj in bpy.data.objects:
    obj.hide_render = True
    if obj.type != 'MESH': continue
    obj.data.calc_loop_triangles()
    report['objects'].append({'name': obj.name, 'triangles': len(obj.data.loop_triangles)})
host = bpy.data.objects['FINISHED broadleaf']
points = [host.matrix_world@v.co-Vector((0,0,.65)) for v in host.data.vertices]
report['inherited_walk_radius_m'] = max(math.hypot(p.x,p.y) for p in points if 0 <= p.z <= 4.5)
scene = bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world.color=(.18,.18,.18)
camera=bpy.data.objects.new('C3 inspection camera',bpy.data.cameras.new('C3 inspection camera'))
scene.collection.objects.link(camera);scene.camera=camera
camera.data.type='ORTHO';camera.data.ortho_scale=9.7
for name, pos, power, size in [('key',(5,-6,10),1800,7),('fill',(-5,3,7),1200,6)]:
    light=bpy.data.objects.new(name,bpy.data.lights.new(name,'AREA'));scene.collection.objects.link(light)
    light.location=pos;light.data.energy=power;light.data.shape='DISK';light.data.size=size
    light.rotation_euler=(Vector((0,0,4))-light.location).to_track_quat('-Z','Y').to_euler()
host.hide_render=False
for name, direction in [('front',(0,-1,.1)),('back',(0,1,.1)),('side',(1,0,.1)),('three-quarter',(1,-1,.35)),('top',(.01,0,1)),('underside',(0,-.4,-1))]:
    target=Vector((0,0,4));camera.location=target+Vector(direction).normalized()*15
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print('C3_INSPECTION_OK',report['inherited_walk_radius_m'])
