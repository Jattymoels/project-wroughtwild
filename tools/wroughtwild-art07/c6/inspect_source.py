"""Inspect actual retained GLBs in Blender; CPU render, eight threads from runner."""
import bpy, sys, json, hashlib
from pathlib import Path
from mathutils import Vector

depot, out = [Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not out.exists(); out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=20
scene.render.resolution_x=1280; scene.render.resolution_y=850; scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('inspection daylight'); scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.26,.29,.31,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
bpy.ops.object.light_add(type='AREA', location=(3,-4,7)); bpy.context.object.data.energy=1800; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=6
bpy.ops.object.camera_add(location=(5,-6,4)); cam=bpy.context.object; scene.camera=cam; cam.data.type='ORTHO'
paths=sorted((depot/'game/assets/authored').glob('cataclysm_*.glb'))
paths=[p for p in paths if any(key in p.stem for key in ['fen_','rootvault_','upland_','forge_threshold'])]
paths += [depot/'game/assets/authored/workbench.glb']
result=[]
for path in paths:
    before=set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=str(path))
    objects=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    low=Vector([min(v[i] for v in points) for i in range(3)]); high=Vector([max(v[i] for v in points) for i in range(3)])
    tris=0; materials=[]
    for o in objects:
        o.data.calc_loop_triangles(); tris+=len(o.data.loop_triangles)
        for mat in o.data.materials:
            materials.append({'name':mat.name,'colour':list(mat.diffuse_color),'polygons':sum(f.material_index==list(o.data.materials).index(mat) for f in o.data.polygons)})
    target=(low+high)*.5; span=max(high-low)
    cam.data.ortho_scale=span*1.35
    for angle,direction in [('material',(1,-1,.7)),('back',(-1,1,.5)),('underside',(1,-1,-.6))]:
        cam.location=target+Vector(direction).normalized()*span*2
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(out/(path.stem+'-'+angle+'.png')); bpy.ops.render.render(write_still=True)
    result.append({'file':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bounds_blender_m':[list(low),list(high)],'triangles':tris,'materials':materials})
    for o in list(bpy.data.objects):
        if o not in before: bpy.data.objects.remove(o,do_unlink=True)
(out/'inspection.json').write_text(json.dumps(result,indent=2)+'\n')
print('C6_SOURCE_INSPECTED',len(result))
