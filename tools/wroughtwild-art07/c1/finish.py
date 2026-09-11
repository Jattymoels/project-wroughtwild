"""Finish v04 reed wind clearance in a new packed master; preserve rejected candidate."""
import bpy,sys,json,shutil,hashlib
from pathlib import Path
import numpy as np
source,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();out.mkdir(parents=True)
shutil.copytree(source/'models',out/'models');records=json.loads((source/'models.json').read_text());cfg=json.loads(Path(__file__).with_name('kit.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(source/'c1-master.blend'));factor=cfg['reed_horizontal_scale']
names=set(n for name,r in records['assets'].items() if name.startswith('reed-') for n in r['objects'])
for o in bpy.data.objects:
    if o.type=='MESH' and (o.name in names or o.name.startswith('REVIEW reed-')):
        for v in o.data.vertices:v.co.x*=factor;v.co.y*=factor
        o.data.update()
for name,r in records['assets'].items():
    if not name.startswith('reed-'):continue
    bpy.ops.object.select_all(action='DESELECT');obs=[bpy.data.objects[n] for n in r['objects']]
    for o in obs:o.hide_set(False);o.hide_render=False;o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(out/'models'/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True,export_attributes=True)
    p=np.array([o.matrix_world@v.co for o in obs for v in o.data.vertices]);r['bounds_blender_m']=[p.min(0).tolist(),p.max(0).tolist()]
    for o in obs:o.hide_render=True;o.hide_set(True)
for row in records['attachment_roots']:
    if row['asset'].startswith('reed-'):row['root'][0]*=factor;row['root'][1]*=factor
records['transforms']['reed_horizontal_finish']={'factor':factor,'purpose':cfg['purposes']['reed_horizontal_scale'],'from_master':str(source/'c1-master.blend'),'source_sha256':hashlib.sha256((source/'c1-master.blend').read_bytes()).hexdigest()}
(out/'models.json').write_text(json.dumps(records,indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'c1-master.blend'),compress=True)
bpy.context.scene.render.filepath=str(out/'blender-kit.png');bpy.ops.render.render(write_still=True)
print('C1_FINISH_OK',factor)
