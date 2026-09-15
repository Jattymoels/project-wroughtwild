"""Write the species handoff from checked output; keep evidence small and local."""
import hashlib,json,shutil,sys
from pathlib import Path
from PIL import Image
repo=Path(__file__).resolve().parents[2]
source=Path(sys.argv[1]).resolve()
evidence=Path(sys.argv[2]).resolve()
runtime=repo/'game/assets/authored/roster/stone_husk'
curated=repo/'game/tests/mob02/evidence'
curated.mkdir(parents=True,exist_ok=True)
cfg=json.loads((source/'rig.json').read_text(encoding='utf-8-sig'))
report=json.loads((source/'rig-report.json').read_text())
checks=json.loads((evidence/'import-checks.json').read_text())
capture=json.loads((evidence/'capture-checks.json').read_text())
assert not checks['failures'] and not capture['failures']
assert 'import suite reached completion' in checks['checks']
frames=sorted((evidence/'frames').glob('*.png'))
assert len(frames)==264
images=[Image.open(path).convert('RGB') for path in frames]
durations=[round((i+1)*1000/24)-round(i*1000/24) for i in range(len(images))]
images[0].save(curated/'ram-motion.webp',save_all=True,append_images=images[1:],
               duration=durations,loop=0,quality=84,method=4,minimize_size=True)
for im in images:im.close()
with Image.open(curated/'ram-motion.webp') as clip:
    assert clip.n_frames==264 and clip.size==(1080,648)
for name in ['ram-idle.png','ram-windup.png','source-checks.json','import-checks.json','capture-checks.json']:
    shutil.copyfile(evidence/name,curated/name)
shutil.copyfile(source/'rig-report.json',curated/'rig-report.json')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
receipt=json.loads((source.parent/'input-art06c/source-selection.json').read_text())
source_hashes={v['file']:v['sha256'].lower() for v in receipt['files']}
for name in ['base.png','orm.png','scar-mask.png']:
    assert sha(runtime/name)==source_hashes[name],('Map differs from selected input',name)
loop_clips={'idle','walk','guard'}
clips={}
for name,duration in report['clips_seconds'].items():
    clips[name]={'name':name,'duration_seconds':duration,'loop':name in loop_clips,
                 'godot_default_import_loop':'none; wrap sampled time or set LOOP_LINEAR for the three intended loops'}
clips['walk']['travel_source_units']=cfg['step_units']/cfg['stance_fraction']
clips['walk']['stance_fraction']=cfg['stance_fraction']
clips['walk']['touchdown_phase']={v['name']:(1-v['phase'])%1 for v in cfg['legs']}
clips['walk']['liftoff_phase']={v['name']:(cfg['stance_fraction']-v['phase'])%1 for v in cfg['legs']}
clips['windup']['markers']={'anticipation_start_seconds':0,'native_release_boundary_seconds':0.6}
clips['release']['markers']={'native_event_already_occurred_seconds':0,'follow_through_peak_seconds':0.0736,'guard_recovery_seconds':0.32}
descriptor={
'descriptor_kind':'MOB production handoff; not a new shared runtime schema',
'enemy_id':'stone_husk','role':'guard','source_stage':'approved ART-06C ram v03 surface, MOB-02 fitted rig v05',
'model':'res://assets/authored/roster/stone_husk/model.glb',
'maps':{'base':'res://assets/authored/roster/stone_husk/base.png','orm':'res://assets/authored/roster/stone_husk/orm.png','scar':'res://assets/authored/roster/stone_husk/scar-mask.png'},
'nodes_relative_to_model_root':{'skeleton':checks['skeleton'],'animation_player':checks['animation_player'],'mesh':checks['mesh']},
'geometry':{'source_triangles':report['source_triangles'],'triangles':report['runtime_triangles'],
            'blender_vertices':report['runtime_vertices'],'godot_vertices_including_uv_splits':108351,
            'surfaces':1,'bones':23,'max_weights_per_vertex':4,'simplification':'Weld identical seam positions, automatic triangle collapse, remove two duplicate faces; no hand quad retopology or normal-map bake.'},
'clips':clips,
'fit':{'source_coordinates':'Blender Z-up, -Y forward. Exported GLB is Y-up, +Z forward.',
       'source_rest_bounds_blender':[[-0.4505687356,-0.9536213279,0],[0.4521683455,0.9536213279,2]],
       'uniform_metres_per_source_unit':cfg['recommended_scale'],'ground_offset_metres':[0,0,0],
       'rotation_y_degrees':180,'reference_space':'Enemy local metres before world-family and elite scale; do not apply the legacy 0.76 humanoid reduction twice.',
       'root_motion':False,'extra_cull_margin_source_units':0.65,
       'capsule_limit':'Existing upright radius 0.35 m / height 1.3 m does not match the long animal silhouette; keep its native collision and reach.'},
'material':{'reference_recipe':'tools/wroughtwild-roster/lifeline-study.json (stone_husk)',
            'reference_shader':'tools/wroughtwild-roster/surface_scar.gdshader',
            'base_colour_space':'sRGB source_color sampler','orm_colour_space':'linear data; R=AO retained, G=roughness, B=metallic',
            'scar_colour_space':'linear data; R=living core, G=dark damage, B=connected travel delay',
            'albedo_formula':'mix(base, base * damage_tint, scar.g); preserve source host texture inside injuries',
            'damage_tint_linear':[0.16,0.14,0.12],'core_colour_godot_Color':[0.57,0.76,0.91],
            'period_seconds':4,'peak_emission':2.4,'minimum_light':0.32,'crest_width':0.20,'pulse_mode':3,
            'clock':'explicit pause-aware scar_clock and per-instance phase_offset, separate from native attack clocks',
            'normal_map':None,'fallback':'GLB contains a non-emissive neutral PBR fallback; bind the supplied maps and ART-06C shader for production.',
            'status_priority':'Keep existing freeze, hit, burn and bleed presentation over ambient scars.'},
'integration':{'timing':'Sample windup by native normalized _windup_left / windup_seconds; resample release into existing CreatureMotion release_left (currently 0.22 s), not a new 0.32 s gameplay timer.',
               'guard':'No native guard state exists. Use guard only as a stationary alert pose or upper-body blend. Keep walk while moving; guard mitigation always uses native facing/arc, life and stagger.',
               'locomotion':'Measured source travel is 0.5757575758 units/cycle (0.4893939394 m at 0.85 scale). This is shorter than the legacy cosmetic stride setting. Coordinator should retain an explicit cosmetic cadence choice; exact distance matching at native 2.8 m/s produces rapid steps.',
               'suggested_cosmetic_stride_metres_before_family_scale':1.5,
               'cosmetic_stride_purpose':'Start from the existing fauna 1.5 m cosmetic cadence to avoid rapid leg cycling at native speed; this deliberately permits sliding and is not the measured source stride.',
               'native_rules_unchanged':{'windup_seconds':0.6,'move_speed_mps':2.8,'attack_range_m':1.9,'guard_arc_degrees':110,'guard_mitigation_fraction':0.6,'era_two_guard_arc_bonus_degrees':40,'era_two_breaks_timber':True},
               'coordinator_next':'Cherry-pick production commit after MOB-01, add the stone_husk entry to its shared adapter/manifests, then short actual-role and ordinary Continue smoke. No additional owner approval.'},
'provenance':{'editable_master':str(source/'stone_husk-rigged.blend'),'rig_report':str(source/'rig-report.json'),
              'recipe':'tools/wroughtwild-mob02-ram/build_ram.py','tuning':'tools/wroughtwild-mob02-ram/rig.json',
              'immutable_input_receipt':str(source.parent/'input-art06c/source-selection.json'),
              'files_sha256':{name:sha(runtime/name) for name in ['model.glb','base.png','orm.png','scar-mask.png']}},
'known_limits':['Owner playtesting deferred; no claim of normal-game adoption yet.',
                'No terrain IK or facial articulation; source-generated fur/fold detail and slight foot sliding remain.',
                'One runtime detail level; no performance or minimum-hardware clearance.',
                'Later-era physical additions are deferred; existing era gameplay remains unchanged.',
                'The stationary guard/idle switch should blend briefly during integration; it must not lock movement.']}
(runtime/'asset.json').write_text(json.dumps(descriptor,indent=2)+'\n')
media={'frames':264,'frames_per_second':24,'duration_seconds':11,'size':[1080,648],
       'file':'game/tests/mob02/evidence/ram-motion.webp','bytes':(curated/'ram-motion.webp').stat().st_size,
       'sha256':sha(curated/'ram-motion.webp'),'renderer':'Forward+',
       'segments_seconds':{'idle':[0,3],'walk':[3,6.6],'guard':[6.6,8.6],'windup':[8.6,9.2],'release':[9.2,9.52],'guard_recovery':[9.52,11]}}
(curated/'media.json').write_text(json.dumps(media,indent=2)+'\n')
print('MOB02_HANDOFF_ARTIFACTS_OK '+json.dumps(media))
