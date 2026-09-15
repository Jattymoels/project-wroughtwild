"""One selected saved tortoise check; reuse approved ART-06C identity evidence."""
import json,sys
from pathlib import Path
import bpy
src,out=map(Path,sys.argv[sys.argv.index('--')+1:])
r=json.loads((src/'rig-report.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(src/'hollow_knight-rigged.blend'))
a=bpy.data.objects['TortoiseRig'];m=bpy.data.objects['TortoiseSkin'];h=bpy.data.objects['hollow_knight - surface host']
checks={
 'dense_v02_source_retained':len(h.data.polygons)==295369,
 '17_bones_four_fitted_chains':len(a.data.bones)==17 and len(r['settings']['legs'])==4 and all(a.data.bones.get(l['name']+'_'+p) for l in r['settings']['legs'] for p in ['upper','lower','foot']),
 'skin_modifier_retained':any(mod.type=='ARMATURE' and mod.object==a for mod in m.modifiers),
 'four_baked_clips_retained':{t.name for t in a.animation_data.nla_tracks}=={'idle','walk','windup','release'},
 'supported_neck_head_tail':all(r['weighted_vertices'][n]>10 for n in ['body','neck','head','tail']),
 'original_source_maps_packed':len([i for i in bpy.data.images if i.packed_file])>=3,
 'normalized_skin':all(abs(sum(g.weight for g in v.groups)-1)<1e-5 and 0<len(v.groups)<=4 for v in m.data.vertices),
 'rigid_upper_shell':all(len(v.groups)==1 and m.vertex_groups[v.groups[0].group].name=='body' for v in m.data.vertices if v.co.z>=.39 and v.co.y>=-.56),
 'runtime_uv_and_topology':len(m.data.uv_layers)==1 and not m.data.validate(verbose=True),
 'planted_solver_checked':r['max_foot_target_error']<1e-5 and r['max_segment_length_error']<1e-5,
 'representative_pose_clearance':all(v['bounds'][0][2]>-.01 for v in r['pose_samples'].values()),
 'three_or_four_feet_in_stance':all(sum((i/1000+l['phase'])%1<r['settings']['stance_fraction'] for l in r['settings']['legs'])>=3 for i in range(1000)),
}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'checks':checks,'passed':sum(checks.values()),'failed':sum(not v for v in checks.values())},indent=2)+'\n')
assert all(checks.values()),checks
print('TORTOISE_SAVED_MASTER_OK',len(checks))
