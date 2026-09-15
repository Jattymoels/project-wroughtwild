"""One saved-master reopening check; unchanged dense input evidence is reused."""
import json,sys
from pathlib import Path
import bpy
source,output=map(Path,sys.argv[sys.argv.index('--')+1:])
bpy.ops.wm.open_mainfile(filepath=str(source/'stone_husk-rigged.blend'))
mesh=bpy.data.objects['RamSkin'];arm=bpy.data.objects['RamRig']
assert not mesh.data.validate(verbose=True)
assert len(arm.data.bones)==23
assert len(mesh.modifiers)==1 and mesh.modifiers[0].object==arm
assert set(t.name for t in arm.animation_data.nla_tracks)=={'idle','walk','windup','release','guard'}
assert len(mesh.data.polygons)==109998
weights=[sum(g.weight for g in v.groups) for v in mesh.data.vertices]
assert max(abs(v-1) for v in weights)<1e-5
images=[node.image for node in mesh.data.materials[0].node_tree.nodes if node.type=='TEX_IMAGE' and node.image]
print('MOB02_REQUIRED_IMAGES '+json.dumps([{'name':im.name,'source':im.source,'packed':bool(im.packed_file),'has_data':im.has_data,'size':list(im.size)} for im in images]),flush=True)
assert images and all(im.packed_file or im.source=='GENERATED' for im in images), 'Required material image lacks packed or generated data'
report={'saved_master':str(source/'stone_husk-rigged.blend'),'mesh_valid_without_changes':True,
        'bones':23,'triangles':len(mesh.data.polygons),'packed_images':len(images),
        'max_weight_sum_error':max(abs(v-1) for v in weights),'clips':[t.name for t in arm.animation_data.nla_tracks],
        'scope':'One selected saved master; unchanged ART-06C identity/depth evidence reused.'}
output.write_text(json.dumps(report,indent=2)+'\n')
print('MOB02_SAVED_MASTER_OK '+json.dumps(report))
