"""One selected saved nymph master check; reuse ART-06C identity/depth evidence."""
import json,sys
from pathlib import Path
import bpy
src,out=map(Path,sys.argv[sys.argv.index('--')+1:])
r=json.loads((src/'rig-report.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(src/'bog_lurker-rigged.blend'))
a=bpy.data.objects['NymphRig'];m=bpy.data.objects['NymphSkin'];h=bpy.data.objects['bog_lurker - surface host']
checks={
 'dense_v04_source_retained':len(h.data.polygons)==290654,
 '27_bones_six_thoracic_chains':len(a.data.bones)==27 and len(r['settings']['legs'])==6 and all(l['hip'][1]<0 and a.data.bones.get(l['name']+'_'+p) for l in r['settings']['legs'] for p in ['upper','lower','foot']),
 'skin_modifier_retained':any(mod.type=='ARMATURE' and mod.object==a for mod in m.modifiers),
 'four_baked_clips_retained':{t.name for t in a.animation_data.nla_tracks}=={'idle','walk','windup','release'},
 'weighted_supported_parts':all(r['weighted_vertices'][n]>10 for n in ['body','head','labium','antenna_L','antenna_R','abdomen_1','abdomen_2','abdomen_3']),
 'original_source_maps_packed':len([i for i in bpy.data.images if i.packed_file])>=3,
 'normalized_skin':all(abs(sum(g.weight for g in v.groups)-1)<1e-5 and 0<len(v.groups)<=4 for v in m.data.vertices),
 'legless_supported_abdomen':all(all(m.vertex_groups[g.group].name.startswith('abdomen_') or m.vertex_groups[g.group].name=='body' for g in v.groups) for v in m.data.vertices if v.co.y>-.05 and abs(v.co.x)<.27),
 'runtime_uv_and_topology':len(m.data.uv_layers)==1 and not m.data.validate(verbose=True),
 'planted_solver_checked':r['max_foot_target_error']<1e-5 and r['max_segment_length_error']<1e-5,
 'representative_pose_clearance':all(min(v['bounds'][0])>-2 and v['bounds'][0][2]>-.01 for v in r['pose_samples'].values()),
}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'checks':checks,'passed':sum(checks.values()),'failed':sum(not v for v in checks.values())},indent=2)+'\n')
assert all(checks.values()),checks
print('NYMPH_SAVED_MASTER_OK',len(checks))
