"""Read-only fresh Blender reopen of consumed unchanged B2 packed masters."""
import bpy,hashlib,json,sys
from pathlib import Path
root=Path(sys.argv[sys.argv.index('--')+1]);out=Path(sys.argv[sys.argv.index('--')+2]);assert not out.exists()
records=[]
for source in sorted(root.rglob('*.blend')):
    before=hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    images=[]
    for image in bpy.data.images:
        if image.type in ['RENDER_RESULT','COMPOSITING']:continue
        images.append({'name':image.name,'size':list(image.size),'packed':image.packed_file is not None,'packed_bytes':image.packed_file.size if image.packed_file else 0})
    records.append({'path':str(source),'sha256':before,'meshes':len([o for o in bpy.data.objects if o.type=='MESH']),'images':images,'source_unchanged':hashlib.sha256(source.read_bytes()).hexdigest()==before})
    assert records[-1]['source_unchanged']
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'sources':records,'scope':'Fresh read-only reopened original packed masters; R7 changes composition transforms and material bindings only. No geometry/map/source master edits.'},indent=2))
print('R7_PACKED_REOPEN_OK',len(records))
