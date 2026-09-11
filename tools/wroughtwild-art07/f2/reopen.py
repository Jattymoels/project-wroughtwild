"""Independent packed-master reopen and fresh runtime imports, with real renders."""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[3]
devices,source,out=map(lambda s:Path(s).resolve(),sys.argv[sys.argv.index('--')+1:]);assert out.is_relative_to(ROOT/'build/art07/f2');out.mkdir(parents=True,exist_ok=False)
report={'masters':{},'imports':{}}
def render(file,target,scale):
    s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=32;s.render.resolution_x=1440;s.render.resolution_y=900;s.render.resolution_percentage=100;s.world.color=(.16,.16,.16)
    for at,power,size in [((2,-3,5),1000,4),((-3,1,2),650,3)]:
        bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.size=size;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(2.5,-4,2.7));s.camera=bpy.context.object;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=scale;s.camera.rotation_euler=(Vector(target)-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(file);bpy.ops.render.render(write_still=True)
for name,p in [('devices',devices/'f2-devices.blend'),('source',source/'f2-thrumroot.blend')]:
    bpy.ops.wm.open_mainfile(filepath=str(p));images=[{'name':i.name,'packed':bool(i.packed_file),'size':list(i.size)} for i in bpy.data.images if i.type=='IMAGE'];assert images and all(i['packed'] for i in images)
    report['masters'][name]={'images':images,'objects':len(bpy.context.scene.objects)}
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o.hide_render=True
    if name=='source':
        bpy.data.objects['Thrumroot_near'].hide_render=False
        render(out/'reopened-source.png',(0,0,.40),2.75)
    else:
        for r in ['Winch','Basket']:
            root=bpy.data.objects[r]
            for o in root.children_recursive:o.hide_render=False
            if r=='Basket':root.location.z=1.25
        render(out/'reopened-winch-and-basket.png',(0,0,.92),4.0)
for path in sorted(list(devices.glob('*.glb'))+list(source.glob('*.glb'))):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path));objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];coords=[];triangles=0;degenerate=0;colours=0;surfaces=0
    for o in objects:
        o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);degenerate+=sum(t.area<1e-12 for t in o.data.loop_triangles);coords.extend(o.matrix_world@v.co for v in o.data.vertices);surfaces+=len(o.data.materials);colours+=len(o.data.color_attributes)
    assert degenerate==0 and all(all(math.isfinite(c) for c in v) for v in coords),path
    lo=[min(v[i] for v in coords) for i in range(3)];hi=[max(v[i] for v in coords) for i in range(3)];size=[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]]
    if path.name.startswith('thrumroot-'):
        assert colours>0 and all(a<=b+.002 for a,b in zip(size,[2.2,.9,.75]))
    if path.name in ['winch.glb','landing.glb']:assert all(a<=b+.002 for a,b in zip(size,[1.4,1.83,1.15]))
    if path.name=='winch.glb':
        pivot=bpy.data.objects.get('Drum');assert pivot is not None and (pivot.location-Vector((0,0,1.05))).length<.0001
    if path.name=='basket.glb':
        radius=max((v-Vector((0,0,.2))).length for v in coords);assert radius<=.3001,radius
    report['imports'][path.name]={'triangles':triangles,'degenerate':degenerate,'godot_size':size,'surfaces':surfaces,'colour_layers':colours}
(out/'reopen.json').write_text(json.dumps(report,indent=2)+'\n');print('F2_REOPEN_OK',report['imports'])
