"""Reopen only the selected packed rig; validate its weights and attachments."""
import bpy,json,sys
from pathlib import Path
folder=Path(sys.argv[sys.argv.index('--')+1])
bpy.ops.wm.open_mainfile(filepath=str(folder/'shrieker-rigged.blend'))
arm=bpy.data.objects['CraneRig'];assert len(arm.data.bones)==16
report=json.loads((folder/'rig-report.json').read_text())
assert {t.name for t in arm.animation_data.nla_tracks}==set(report['clips_seconds'])
for entry in report['parts']:
 obj=bpy.data.objects[entry['name']]
 assert not obj.data.validate(verbose=True)
 obj.data.calc_loop_triangles();assert len(obj.data.loop_triangles)==entry['triangles']
 assert obj.parent==arm and obj.modifiers[-1].object==arm
 for v in obj.data.vertices:
  assert 1<=len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<1e-5
assert all(i.packed_file for i in bpy.data.images if i.source=='FILE' and i.has_data)
report['saved_master_reopened']=True
(folder/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n')
print('MOB03_SAVED_MASTER_OK')
