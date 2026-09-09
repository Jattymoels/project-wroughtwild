"""Audit retained Blender sources and GLBs without modifying them.
Blender --background --threads 8 --python-exit-code 1 --python this.py -- PACKAGE COLOUR FRESH_OUTPUT
"""
import bpy,bmesh,json,sys,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
package,colour,out=sys.argv[sys.argv.index('--')+1:]
package=Path(package).resolve();out=Path(out).resolve();assert not out.exists();out.mkdir(parents=True)
review=package/colour/'review';master=package/colour/f'editable/{colour}-workshop.blend'
checks=[];records=[]
def check(ok,label):
    assert ok,label
    checks.append(label)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
original_hash=sha(master)
for role,limit in [('source',np.array([1.5,1.5,1.1])),('buffer' if colour=='red' else 'post',np.array([1,1,1.2]) if colour=='red' else np.array([.65,.55,1.18]))]:
    for lod in ['near','mid','far']:
        path=review/f'{colour}-{role}-{lod}.glb'
        bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        points=np.concatenate([np.array([o.matrix_world@v.co for v in o.data.vertices]) for o in meshes])
        lo,hi=points.min(0),points.max(0)
        check(np.isfinite(points).all(),path.name+' finite')
        check(np.all(lo>=np.array([-limit[0]/2,-limit[1]/2,0])-.00001) and np.all(hi<=np.array([limit[0]/2,limit[1]/2,limit[2]])+.00001),path.name+' native bounds')
        triangles=surfaces=degenerate=0
        for o in meshes:
            o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);surfaces+=len(o.data.materials)
            degenerate+=sum(t.area<1e-12 for t in o.data.loop_triangles)
            check(o.data.uv_layers.active is not None,path.name+' UV layer')
        records.append({'file':path.name,'sha256':sha(path),'triangles':triangles,'surfaces':surfaces,'degenerate_triangles_below_1e-12_m2':degenerate,'bounds_blender_xyz':[lo.tolist(),hi.tolist()]})
for i in range(1,4):
    path=review/f'{colour}-fragment-{i}.glb'
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005)
    check(all(e.is_manifold for e in bm.edges),path.name+' closed after UV seam weld')
    volume=abs(bm.calc_volume());check(volume>.0001,path.name+' nonzero closed volume')
    obj.data.calc_loop_triangles()
    records.append({'file':path.name,'sha256':sha(path),'triangles':len(obj.data.loop_triangles),'volume_m3':volume})
    bm.free()
bpy.ops.wm.open_mainfile(filepath=str(master))
for im in bpy.data.images:
    if im.source=='FILE':
        check(im.packed_file is not None,'packed '+im.name)
        check(im.size[0]>0 and im.size[1]>0,'packed dimensions '+im.name)
cfg=json.loads((review/f'{colour}.json').read_text());sc=cfg['scar']
host=bpy.data.objects[f'{colour.title()} inclusion - ready worked or spent host']
delivered=np.array([v.co for v in host.data.vertices])
# Reconstruct the identical pre-scar QEM surface in memory from the retained original,
# using the original recipe only through its projection/sample definition. No export/bake.
source=bpy.data.objects[f'SOURCE - untouched normalized {colour.title()} inclusion']
host=source.copy();host.data=source.data.copy();bpy.context.scene.collection.objects.link(host)
host.hide_set(False);host.hide_render=True
recipe_name='wroughtwild-workshop' if colour=='red' else 'wroughtwild-'+colour
text=(Path('C:/Users/Matty/Dev/project-wroughtwild/tools')/recipe_name/'finish_assets.py').read_text()
prefix=text.split('bpy.context.view_layer.objects.active=host;host.select_set(True)',1)[1].split('marks=sample(p);',1)[0]
bpy.ops.object.select_all(action='DESELECT');bpy.context.view_layer.objects.active=host;host.select_set(True)
exec(prefix)
check(delivered.shape==p.shape,'pre-scar topology exactly matches retained near master')
marks=sample(p);normals=np.array([v.normal for v in mesh.vertices])
expected=p-normals*marks[:,1,None]*sc['recess_metres']
error=np.linalg.norm(delivered-expected,axis=1)
check(float(error.max())<.000001,'delivered geometry matches actual scar displacement to one micrometre')
depth=np.linalg.norm(delivered-p,axis=1);affected=depth[depth>1e-6]
scar={'configured_max_m':sc['recess_metres'],'measured_max_m':float(depth.max()),'affected_vertices':len(affected),'affected_p50_m':float(np.median(affected)),'reconstruction_max_error_m':float(error.max()),'method':'same pre-scar QEM topology from packed original; exact per-vertex delivered displacement, not bump/brightness inference'}
# Reopen again to discard every in-memory measurement operation.
bpy.ops.wm.open_mainfile(filepath=str(master))
contact={}
if colour in ('white','blue'):
    core=bpy.data.objects.get(colour.upper()+'_CORE - fitted inclusion')
    if core is not None:
        if colour=='blue':
            low=min((core.matrix_world@v.co).z for v in core.data.vertices)
            check(-.004<=low-(.44+.065/2)<=.002,'Blue cradle contact')
        contact['core_bounds']=[list(min((core.matrix_world@v.co)[i] for v in core.data.vertices) for i in range(3)),list(max((core.matrix_world@v.co)[i] for v in core.data.vertices) for i in range(3))]
if colour=='green':
    cores=[bpy.data.objects['GREEN_CORE - '+n] for n in ['stem','first','second']]
    def tree(o):
        o.data.calc_loop_triangles()
        return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles])
    for branch in cores[1:]:check(bool(tree(cores[0]).overlap(tree(branch))),branch.name+' attached stem')
    contact['stem_base_m']=min((cores[0].matrix_world@v.co).z for v in cores[0].data.vertices)
    check(-.004<=contact['stem_base_m']-(.655+.055/2)<=.002,'Green cradle contact')
# Render the delivered packed source in its preserved inspection arrangement.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.resolution_percentage=100;scene.render.resolution_x=1400;scene.render.resolution_y=950
scene.render.filepath=str(out/'packed-reopen.png');bpy.ops.render.render(write_still=True)
check(sha(master)==original_hash,'master bytes unchanged')
report={'colour':colour,'blender':bpy.app.version_string,'checks':len(checks),'assertions':checks,'failures':[],'master_sha256':original_hash,'runtime_assets':records,'scar':scar,'contacts':contact}
(out/'blender-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('F5_BLENDER_AUDIT',colour,len(checks),json.dumps(scar))
