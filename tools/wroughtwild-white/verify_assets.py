"""Blender: reopen exports, check physical envelopes/solid fragments and package.
-- ASSETS_DIRECTORY FRESH_EDITABLE_DIRECTORY
"""
import bpy,bmesh,json,sys,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
assets,out=map(Path,sys.argv[sys.argv.index('--')+1:]);assets=assets.resolve();out=out.resolve()
assert not out.exists();out.mkdir(parents=True)
checks=0;records=[]
def check(condition,label):
    global checks
    checks+=1
    assert condition,label
for kind,limit in [('source',np.array([1.5,1.5,1.1])),('post',np.array([.65,.55,1.18]))]:
    for lod in ['near','mid','far']:
        path=assets/f'white-{kind}-{lod}.glb'
        bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        check(bool(meshes),f'{path.name} has mesh')
        points=np.concatenate([np.array([o.matrix_world@v.co for v in o.data.vertices]) for o in meshes])
        lo,hi=points.min(0),points.max(0)
        check(np.isfinite(points).all(),f'{path.name} finite coordinates')
        check(np.all(lo>=np.array([-limit[0]/2,-limit[1]/2,0])-.00001),f'{path.name} lower native envelope: {lo.tolist()}')
        check(np.all(hi<=np.array([limit[0]/2,limit[1]/2,limit[2]])+.00001),f'{path.name} upper native envelope')
        triangles=0;surfaces=0
        for o in meshes:
            o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);surfaces+=len(o.data.materials)
            check(o.data.uv_layers.active is not None,f'{path.name} UVs')
            check(all(len(f.vertices)>=3 for f in o.data.polygons),f'{path.name} valid faces')
        records.append({'file':path.name,'triangles':triangles,'surfaces':surfaces,'bounds_blender_xyz':[lo.tolist(),hi.tolist()]})
for i in range(1,4):
    path=assets/f'white-fragment-{i}.glb'
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005)
    check(all(e.is_manifold for e in bm.edges),f'{path.name} closed after runtime export/import and UV-seam weld')
    check(abs(bm.calc_volume())>.0001,f'{path.name} positive solid volume')
    check(obj.data.uv_layers.active is not None,f'{path.name} source-projected UVs')
    points=np.array([obj.matrix_world@v.co for v in obj.data.vertices])
    check(abs(points[:,2].min())<.00001,f'{path.name} grounded pivot')
    records.append({'file':path.name,'triangles':len(obj.data.polygons),'volume_m3':abs(bm.calc_volume())})
    bm.free()
bpy.ops.wm.open_mainfile(filepath=str(assets/'white-workshop.blend'))
check('SOURCE - untouched normalized White inclusion' in bpy.data.objects,'dense untouched source retained')
check('SOURCE - editable procedural housing' in bpy.data.objects,'editable material authoring retained')
textures=[(name,2048) for name in ['white-base.png','white-orm.png','white-normal.png','white-scar.png','post-base.png','post-orm.png','post-normal.png']]
textures += [(f'fragment-{i}-{role}.png',1024) for i in range(1,4) for role in ['base','orm','normal','scar']]
for name,resolution in textures:
    im=bpy.data.images.load(str(assets/name),check_existing=False)
    check(tuple(im.size)==(resolution,resolution),name+' expected atlas size')
    pix=np.empty(resolution*resolution*4,np.float32);im.pixels.foreach_get(pix)
    check(np.isfinite(pix).all(),name+' finite texels')
    rgb=pix.reshape(-1,4)[:,:3]
    check(float(rgb.max()-rgb.min())>.1,name+' has nonempty RGB data')
    if name.endswith('-scar.png'):check(float(pix.reshape(-1,4)[:,0].max())>.05,name+' retains a luminous core')
    bpy.data.images.remove(im)
# Make the packed source immediately inspectable, retaining local export pivots
# as custom properties before arranging the three asset roles in the work scene.
for o in bpy.context.scene.objects:o.hide_render=True;o.hide_set(True)
host=bpy.data.objects['White inclusion - ready worked or spent host'];host.location.x=-1.25
housing=bpy.data.objects['POST_HOUSING - paid crafted frame'];housing['export_location']=list(housing.location);housing.location.x+=1.1
core=bpy.data.objects['WHITE_CORE - fitted inclusion'];core['export_location']=list(core.location);core.location.x+=1.1
shown=[host,housing,core]
for i in range(3):
    o=bpy.data.objects['White Mineral - cut fragment '+str(i+1)];o.location=(i*.35-.35,-.8,0);shown.append(o)
for o in shown:o.hide_render=False;o.hide_set(False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1400;scene.render.resolution_y=950;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.14,.17,.17,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
for at,energy,size in [((-3,-4,6),850,4),((4,1,4),600,3)]:
    lamp=bpy.data.objects.new('Softbox',bpy.data.lights.new('Softbox','AREA'));scene.collection.objects.link(lamp);lamp.location=at;lamp.data.energy=energy;lamp.data.shape='DISK';lamp.data.size=size;lamp.rotation_euler=(-lamp.location).to_track_quat('-Z','Y').to_euler()
camera=bpy.data.objects.new('Editable inspection camera',bpy.data.cameras.new('Editable inspection camera'));scene.collection.objects.link(camera);camera.location=(3.6,-6,3.6);camera.rotation_euler=(Vector((-.10,0,.4))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=4.5;scene.camera=camera
for im in bpy.data.images:
    if im.has_data:im.pack()
scene['export_note']='Asset export pivots are preserved in GLBs. This scene is arranged for editing; rebuild with finish_assets.py for exact native placement.'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'white-workshop.blend'),compress=True)
scene.render.filepath=str(out/'editable-preview.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.open_mainfile(filepath=str(out/'white-workshop.blend'))
for im in bpy.data.images:
    if im.has_data:check(im.packed_file is not None,'packed image '+im.name)
check(len([o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render])==6,'packed source reopens with six displayed meshes')
report={'checks':checks,'failures':[],'runtime_assets':records,'blender':bpy.app.version_string,'packed_blend_sha256':hashlib.sha256((out/'white-workshop.blend').read_bytes()).hexdigest()}
(out/'asset-checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ART04_ASSET_CHECKS',checks)
