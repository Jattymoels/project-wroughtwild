"""Read-only reopen of three original packed material masters, in private Blender."""
import bpy,json,sys,hashlib
from pathlib import Path
root,out=map(Path,sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True)
rows=[]
for master in sorted(root.glob('*.blend')):
    before=hashlib.sha256(master.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(master))
    images=[]
    for im in bpy.data.images:
        if im.type not in ['IMAGE','UV_TEST']:continue
        assert im.size[0]>0 and im.size[1]>0,im.name
        assert im.packed_file or im.packed_files or Path(bpy.path.abspath(im.filepath)).is_file(),im.name
        images.append({'name':im.name,'width':im.size[0],'height':im.size[1],'packed':bool(im.packed_file or im.packed_files),'colour_space':im.colorspace_settings.name})
    assert images,master
    triangles=0
    for m in bpy.data.meshes:m.calc_loop_triangles();triangles+=len(m.loop_triangles)
    assert hashlib.sha256(master.read_bytes()).hexdigest()==before
    rows.append({'master':master.name,'sha256':before,'images':images,'triangles_in_original_master':triangles})
assert len(rows)==3
(out/'report.json').write_text(json.dumps({'blender':bpy.app.version_string,'masters':rows,'scope':'Fresh reopen of unchanged D4/D5/D6 packed material sources. No geometry or map reauthoring; R3 changes runtime binding only.'},indent=2))
print('R3_PACKED_SOURCE_REOPEN_OK',len(rows),'masters',sum(len(r['images']) for r in rows),'images')
