"""One selected saved master check. Source identity/depth evidence is reused."""
import json,sys
from pathlib import Path
import bpy
src,out=map(Path,sys.argv[sys.argv.index('--')+1:])
r=json.loads((src/'rig-report.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(src/'gloom_crawler-rigged.blend'))
a=bpy.data.objects['BeetleRig'];m=bpy.data.objects['BeetleSkin'];h=bpy.data.objects['gloom_crawler - surface host']
checks={
 'dense_source_retained':len(h.data.polygons)==293396,
 '25_bones_and_six_fitted_chains':len(a.data.bones)==25 and all(a.data.bones.get(l['name']+'_'+p) for l in r['settings']['legs'] for p in ['upper','lower','foot']),
 'skin_modifier_retained':any(mod.type=='ARMATURE' and mod.object==a for mod in m.modifiers),
 'four_baked_clips_retained':{t.name for t in a.animation_data.nla_tracks}=={'idle','walk','windup','release'},
 'weighted_supported_parts':all(r['weighted_vertices'][n]>10 for n in ['body','head','mandible_L','mandible_R','antenna_L','antenna_R']),
 'source_maps_packed':len([i for i in bpy.data.images if i.packed_file])>=3,
 'normalized_skin':all(abs(sum(g.weight for g in v.groups)-1)<1e-5 and 0<len(v.groups)<=4 for v in m.data.vertices),
 'rigid_shell':all(len(v.groups)==1 and m.vertex_groups[v.groups[0].group].name=='body' for v in m.data.vertices if v.co.y<.55 and v.co.z>.49),
 'runtime_uv_and_topology':len(m.data.uv_layers)==1 and not m.data.validate(verbose=True),
 'planted_solver_checked':r['max_foot_target_error']<1e-5 and r['max_segment_length_error']<1e-5,
}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'checks':checks,'passed':sum(checks.values()),'failed':sum(not v for v in checks.values())},indent=2)+'\n')
assert all(checks.values()),checks
print('BEETLE_SAVED_MASTER_OK',len(checks))
