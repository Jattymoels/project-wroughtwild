"""Publish the species descriptor and prepare a tiny disposable Godot fixture."""
import json,struct,shutil,sys,hashlib
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
asset=repo/'game/assets/authored/roster/shrieker'
source=Path(sys.argv[1]).resolve()
fixture=repo/'build/mob03/fixture'
fixture.mkdir(parents=True,exist_ok=True)
report=json.loads((source/'rig-report.json').read_text())
cfg=json.loads((Path(__file__).parent/'rig.json').read_text(encoding='utf-8-sig'))
b= (asset/'model.glb').read_bytes();size=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+size])
assert len(g['skins'])==1
names=[a['name'] for a in g['animations']];assert set(names)==set(report['clips_seconds']),names
triangles=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])
assert triangles==report['triangles']
print('GLB_NODES',[(i,n.get('name'),n.get('children',[])) for i,n in enumerate(g['nodes'])])
print('GLB_ANIMATIONS',names,'TRIANGLES',triangles)
shutil.copy2(repo/'tools/wroughtwild-roster/surface_scar.gdshader',asset/'lifeline.gdshader')
descriptor={
 'enemy_id':'shrieker','animal':'grounded augmented crane','stage':'checked source production; normal-game wiring pending coordinator',
 'model':'model.glb','maps':{'base':'base.png','orm':'orm.png','scar':'scar-mask.png'},'shader':'lifeline.gdshader',
 'skeleton_path':'CraneRig/Skeleton3D','animation_player_path':'AnimationPlayer','mesh_paths':['CraneRig/Skeleton3D/CraneBody','CraneRig/Skeleton3D/CraneLowerBeak'],
 'bone_count':len(report['bones']),'triangles':triangles,'source_triangles':report['source_triangles'],
 'simplification':'One automated 65000-triangle target, fitted beak seam, nine duplicate collapse faces removed; final total includes seam splits. Original UVs and maps retained; no hand retopology or LOD matrix.',
 'clips':{n:{'duration_seconds':v,'loop':n in ['idle','walk']} for n,v in report['clips_seconds'].items()},
 'walk_cycle_travel_source_units':cfg['walk_cycle_travel_units'],
 'walk_stance_fraction':cfg['walk_stance_fraction'],
 'fit':{'uniform_scale':cfg['suggested_scale'],'ground_offset':[0,0,0],'rotation_degrees':[0,180,0],'export_forward':'+Z','actor_forward':'-Z','export_up':'+Y','rest_height_source_units':2.0,'animated_idle_height_source_units':1.95,'note':'Apply fit at ground-anchored visual root, retaining separate existing family/elite scaling. Root clip translation is zero; foot soles stay at Y=0. Old 0.35m radius / 1.3m high capsule remains unchanged and does not enclose the whole bird.'},
 'markers':{'windup':{'native_duration_seconds':.5,'anticipation_end_seconds':.5},'release':{'native_hit_at_seconds':0.0,'visual_peck_peak_seconds':.15,'return_to_idle_seconds':.3},'call':{'native_recruit_at_seconds':0.0,'visible_beak_open_seconds':.10,'full_throat_seconds':.20,'settle_start_seconds':.675,'return_to_idle_seconds':1.25,'observer':'Emit a dedicated presentation-only recruitment_called signal at the end of Enemy.force_scream(), after the unchanged timer reset, recruitment loop and ring. Never map this clip to attack_released, use clip keys to recruit, or run a second recruitment timer.'}},
 'material':{'revision':'ART-06C','core_colour':[.32,.71,.76],'core_colour_godot_parameter':'Pass Color(0.32,0.71,0.76) directly to the source_color uniform, matching the selected ART-06C viewer.','damage_tint':[.16,.14,.12],'period_seconds':4.0,'peak_emission':2.4,'minimum_light':.32,'crest_width':.20,'pulse_mode':3,'channels':{'base':'sRGB original animal colour','orm':'linear RGB = occlusion / roughness / metallic; selected shader uses G and B','scar':'linear RGB = contained light core / damage coverage / connected surface travel phase'},'clock':'Advance scar_clock with the owning presentation delta; freeze on pause. Ambient pulse is independent of recruitment. Set per-instance phase_offset separately. No whole-animal emission.'},
 'source':{'input_receipt':'D:/Wroughtwild/source-art/mob03-crane/input-art06c/source-selection.json','editable_master':str(source/'shrieker-rigged.blend'),'recipe':'tools/wroughtwild-mob03-crane/build.py','settings':'tools/wroughtwild-mob03-crane/rig.json','rig_report':str(source/'rig-report.json')},
 'limitations':['Native recruitment/combat/save/Continue integration remains for coordinator after MOB-01 and ram.','No terrain foot IK; modest sliding on uneven terrain and source feather/cavity roughness remain.','Existing upright capsule differs from the long-necked animal silhouette.','No later-era additional anatomy, hardware benchmark or broad regression performed.','Owner playtesting deferred under standing approval.'],
 'files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in asset.iterdir() if p.name in ['model.glb','base.png','orm.png','scar-mask.png','lifeline.gdshader']}
}
descriptor['playback']={
 'manual_sampling':True,
 'call_upper_body_bones':['neck','upper_neck','head','jaw','resonator'],
 'call_while_moving':'Keep the actual-travel walk pose on root, body, tail, wings and both leg chains; layer only the five listed upper-body local poses from call.',
 'priority':'Death/freeze/stagger retain the shared adapter policy. Melee windup/release takes visual priority over call; a suppressed call is not queued for later. Its presentation age still expires after 1.25 seconds.',
 'reset':'Clear transient call presentation on actor removal, rebind, death, stagger and save restoration; do not persist or replay it.',
 'walk_stride_at_suggested_scale_m':cfg['walk_cycle_travel_units']*cfg['suggested_scale']
}
(asset/'asset.json').write_text(json.dumps(descriptor,indent=2)+'\n')
# Keep exactly the selected production assets; no full game import or save use.
fa=fixture/'assets';fa.mkdir(exist_ok=True)
for name in ['model.glb','base.png','orm.png','scar-mask.png','lifeline.gdshader','asset.json']:shutil.copy2(asset/name,fa/name)
if not (fa/'model.glb.import').exists() or 'path="res://.godot/imported/' not in (fa/'model.glb.import').read_text():
 (fa/'model.glb.import').write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n\n[deps]\nsource_file="res://assets/model.glb"\n\n[params]\nmeshes/generate_lods=false\n',encoding='utf-8')
shutil.copy2(repo/'game/tests/mob03/fixture.gd',fixture/'fixture.gd')
(fixture/'project.godot').write_text('''config_version=5
[application]
config/name="MOB03 crane source fixture"
run/main_scene="res://fixture.tscn"
[display]
window/size/viewport_width=1100
window/size/viewport_height=760
window/size/window_width_override=1100
window/size/window_height_override=760
window/size/no_focus=true
window/vsync/vsync_mode=0
[rendering]
renderer/rendering_method="forward_plus"
textures/default_filters/use_nearest_mipmap_filter=false
''',encoding='utf-8')
(fixture/'fixture.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://fixture.gd" id="1"]\n[node name="CraneFixture" type="Node3D"]\nscript = ExtResource("1")\n')
shutil.copy2(source/'rig-report.json',repo/'build/mob03/evidence/rig-report.json')
print('MOB03_FIXTURE_PREPARED',fixture)
