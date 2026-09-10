"""Fresh export correction: explicitly carry the named scar colour channel into glTF COLOR_0."""
import bpy,sys,shutil,json,struct
from pathlib import Path
src,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]];assert not out.exists();out.mkdir(parents=True)
for p in src.iterdir():
 if p.suffix in ['.blend','.json','.glb'] and not p.name.startswith('rock-shelf-altered-lod'):shutil.copy2(p,out/p.name)
bpy.ops.wm.open_mainfile(filepath=str(src/'b3-master.blend'))
for lod in range(3):
 bpy.ops.object.select_all(action='DESELECT');o=bpy.data.objects['rock-shelf-altered LOD'+str(lod)];o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
 path=out/('rock-shelf-altered-lod%d.glb'%lod)
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_attributes=True,export_vertex_color='NAME',export_vertex_color_name='Scar')
 data=path.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);assert all('COLOR_0' in p['attributes'] for m in doc['meshes'] for p in m['primitives'])
print('B3_SCAR_EXPORT_OK')
