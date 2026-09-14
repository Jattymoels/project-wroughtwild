"""Preserve original packed PNG bytes in fresh copies of R1's edited masters.
The tested GLB exports are copied byte-for-byte; no geometry is regenerated.
"""
import bpy,json,sys,hashlib,shutil
from pathlib import Path
root=Path(sys.argv[sys.argv.index('--')+1]);target=root/'models-packed-v2';assert not target.exists();target.mkdir()
def digest(data):return hashlib.sha256(data).hexdigest()
report=[]
for kind in ['broadleaf','pine']:
    original=root/'sources/b1/models'/kind/(kind+'-master.blend')
    bpy.ops.wm.open_mainfile(filepath=str(original))
    source={im.name:{'data':bytes(im.packed_file.data),'colour_space':im.colorspace_settings.name} for im in bpy.data.images if im.packed_file}
    before=root/'models'/kind/(kind+'-master.blend');bpy.ops.wm.open_mainfile(filepath=str(before))
    changes=[]
    for name,original_image in source.items():
        data=original_image['data'];missing=name not in bpy.data.images
        if missing:
            image_dir=root/'packed-source-images';image_dir.mkdir(exist_ok=True)
            image_path=image_dir/(digest(data)+'.png')
            if not image_path.exists():image_path.write_bytes(data)
            assert digest(image_path.read_bytes())==digest(data)
            im=bpy.data.images.load(str(image_path),check_existing=False);im.name=name
            im.colorspace_settings.name=original_image['colour_space']
            old=None
        else:
            im=bpy.data.images[name];old=digest(im.packed_file.data) if im.packed_file else None
        im.use_fake_user=True
        if old!=digest(data):
            im.pack(data=data,data_len=len(data))
            assert digest(im.packed_file.data)==digest(data),name
            changes.append({'name':name,'before_sha256':old,'after_sha256':digest(data),'missing_image_restored':missing})
    folder=target/kind;folder.mkdir()
    for p in (root/'models'/kind).glob('*.glb'):
        q=folder/p.name;shutil.copy2(p,q);assert digest(q.read_bytes())==digest(p.read_bytes())
    shutil.copy2(root/'models'/kind/'build.json',folder/'build.json')
    final=folder/(kind+'-master.blend');bpy.ops.wm.save_as_mainfile(filepath=str(final),compress=True)
    report.append({'kind':kind,'source_master_sha256':digest(original.read_bytes()),'authored_master_sha256':digest(before.read_bytes()),'selected_master':str(final),'selected_master_sha256':digest(final.read_bytes()),'packed_byte_restorations':changes,'all_export_bytes_unchanged':True})
(root/'evidence/master-packed-preservation.json').write_text(json.dumps(report,indent=2))
print('R1_FRESH_PACKED_MASTER_COPIES',len(report))
