"""Read-only reopen of the selected packed C5 master; R6 changes no model."""
import json
import hashlib
import sys
from pathlib import Path
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
from master_geometry import signatures

master, destination = sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.open_mainfile(filepath=master)
expected = json.loads(Path(master).with_suffix('.geometry.json').read_text(encoding='utf-8'))
assert signatures() == expected, 'Packed/reopened source geometry or object poses changed'
meshes=[]
for obj in bpy.data.objects:
    if obj.type!='MESH': continue
    obj.data.calc_loop_triangles()
    meshes.append({'name':obj.name,'vertices':len(obj.data.vertices),'triangles':len(obj.data.loop_triangles),'dimensions_blender_m':list(obj.dimensions)})
images=[{'name':img.name,'size':list(img.size),'packed':img.packed_file is not None,'has_data':img.has_data} for img in bpy.data.images if img.type=='IMAGE']
assert meshes and images
assert all(row['packed'] and row['has_data'] for row in images)
assert any('R6 C5 surface fields' in image['name'] for image in images)
assert bpy.data.texts.get('R6 surface controls and projection.json') is not None
Path(destination).write_text(json.dumps({'master':master,'blender':bpy.app.version_string,'meshes':meshes,'geometry_signatures':expected,'original_geometry_and_poses_equal':True,'images':images,'changed_master':'Added packed projected field atlas and editable controls; source geometry untouched.','scope':'R6 packed master reopened in a separate Blender process. Original geometry plus source-derived surface fields; no raised faceted mesh.'},indent=2),encoding='utf-8')
print('R6_MASTER_REOPEN',len(meshes),'meshes',len(images),'packed images')
with Path(master).open('rb') as stream:
    master_hash=hashlib.file_digest(stream,'sha256').hexdigest()
Path(master).with_name('selected-master.json').write_text(json.dumps({'path':master,'sha256':master_hash,'reopen_report':destination},indent=2),encoding='utf-8')
