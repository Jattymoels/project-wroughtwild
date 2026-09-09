"""Reopen the packed editable artifacts in a fresh Blender process."""
import bpy,json,sys
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:];output=Path(args[0]);reports=[]
for filename in args[1:]:
    bpy.ops.wm.open_mainfile(filepath=str(Path(filename).resolve()))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert meshes
    files=[im for im in bpy.data.images if im.source=='FILE']
    for im in files:
        assert im.packed_file,('Unpacked image',im.name)
        assert len(im.pixels)>0 and min(im.size)>0,('Unreadable packed image',im.name)
    assert files
    unique={o.data.name:o.data for o in meshes}
    assert all(not mesh.validate() for mesh in unique.values()),'Invalid mesh on reopening'
    reports.append({'file':filename,'objects':len(bpy.context.scene.objects),'mesh_objects':len(meshes),'unique_meshes':len(unique),'packed_images':len(files),'armatures':sum(o.type=='ARMATURE' for o in bpy.context.scene.objects),'actions':len(bpy.data.actions),'camera':bpy.context.scene.camera.name if bpy.context.scene.camera else None,'passed':True})
output.write_text(json.dumps(reports,indent=2)+'\n')
print('GROVE_SOURCE_REOPEN_OK',len(reports))
