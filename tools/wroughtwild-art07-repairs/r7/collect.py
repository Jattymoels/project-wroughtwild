"""Recompute exact preservation/cost conclusions from real R7 engine reports."""
import copy,math,shutil,re,struct
from common import *
OLD=ROOT/'build/art07-repairs/r7/v01';E=OUT/'runtime/evidence';B=OLD/'runtime/evidence'
result={'passed':False,'anchors':[],'costs':[],'jobs':[],'diagnostics':[]};checks=0
def require(value,label):
    global checks
    checks+=1;assert value,label
def physical(a,b):
    require(set(a)==set(b),'same physical shape IDs')
    differences=[]
    for name in a:
        if a[name]==b[name]:continue
        x=copy.deepcopy(a[name]);y=copy.deepcopy(b[name]);differences.append({'path':name,'before':x,'after':y})
        require(name=='Player/CollisionShape3D' and x['type']=='CapsuleShape3D' and x['pose'][9:]==y['pose'][9:],'only inspector player yaw may differ')
        require(x['pose'][3:6]==y['pose'][3:6]==[0.0,1.0,0.0],'round capsule remains upright')
        y['pose']=x['pose'];require(x==y,'all player shape flags and dimensions retained')
    return differences
for renderer in ['forward_plus','gl_compatibility']:
    a=read(B/('r7-views-before-'+renderer)/'report.json');b=read(E/('r7-views-after-'+renderer)/'report.json')
    require(a['failures']==b['failures']==0,'matched view fixture passes')
    require(a['views']==b['views'],'exact camera/target/light contexts')
    for x,y in zip(a['measurements'],b['measurements']):
        require(x['trees']==y['trees'] and x['overlaps']==y['overlaps'],'R1 actual projected crown dimensions and overlaps retained')
        aa=x['cover'];bb=y['cover'];require(aa['geography_sha256']==bb['geography_sha256'],'exact geography')
        require(aa['counts']==bb['counts'] and set(aa['anchors'])==set(bb['anchors']),'same anchor IDs/counts')
        require(not bb['envelope_failures'],'all group envelopes pass')
        samples=[];max_world_sway=0.0
        for key in aa['anchors']:
            u=aa['anchors'][key];v=bb['anchors'][key]
            require(u['poses']==v['poses'] and u['pose_sha256']==v['pose_sha256'],'exact retained pose '+key)
            require(u['hidden_by_building']==v['hidden_by_building'],'exact building-cleared masks')
            require(u['visibility_end']==v['visibility_end'] and u['visibility_margin']==v['visibility_margin'],'same transition distances')
            samples.extend(s['signed_gap_m'] for s in v.get('root_support',[]))
            if 'composition' in v:
                box=[float(n) for n in re.findall(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?',v['original_envelope'])]
                bend=.018*(box[1]+box[4]-float(v['parts'][0]['root_y']))
                for pose in v['poses']:
                    max_world_sway=max(max_world_sway,*(abs(pose[i]+.35*pose[6+i])*bend for i in range(3)))
        require(samples and max(abs(s) for s in samples)<.071,'actual sampled root burial retained')
        require(max_world_sway<.3,'measured global wind excursion remains inside existing 0.3 m native building clearance padding')
        player_yaw=physical(aa['collision'],bb['collision'])
        result['anchors'].append({'renderer':renderer,'view':x['camera_id'],'anchor_batches':len(aa['anchors']),'anchors':sum(aa['counts'].values()),'composed_anchors':bb['composed_instances'],'geography_sha256':aa['geography_sha256'],'exact_ids_counts_poses':True,'static_collision_exact':True,'inspector_capsule_yaw_differences':player_yaw,'maximum_world_sway_component_bound_m':max_world_sway,'unchanged_building_clearance_m':.3,'root_samples':len(samples),'root_gap_min_m':min(samples),'root_gap_max_m':max(samples)})
    before=read(E/('r7-cost-before-'+renderer)/'report.json');after=read(E/('r7-cost-after-'+renderer)/'report.json')
    require(before['failures']==after['failures']==0 and before['views']==after['views'],'cost fixture and cameras match')
    require(before['gpu']==after['gpu'],'same actual GPU')
    for u,v in zip(before['samples'],after['samples']):
        require((u['scene'],u['lighting'],u['samples'])==(v['scene'],v['lighting'],300),'same settled sample set')
        result['costs'].append({'renderer':renderer,'view':u['scene'],'lighting':u['lighting'],'samples_each':300,'before':u,'after':v,'frame_median_change_percent':(v['frame_median_ms']/u['frame_median_ms']-1)*100,'frame_p95_change_percent':(v['frame_p95_ms']/u['frame_p95_ms']-1)*100})
# Every original paid/native assertion remains, and separate processes restore each state.
a=read(E/'paid-art-r7-before/paid.json');b=read(E/'paid-art-r7-after/paid.json')
require(a['failures']==b['failures']==0,'paid native flows pass')
paid={}
for stage in ['initial','paid','final']:
    require(a[stage]==b[stage],'entire native paid snapshot is identical at '+stage)
    paid[stage]={'full_snapshot_equal':True,'raw_differences':[],'native_ownership_and_geography_equal':True}
for mode in ['before','after']:
    r=read(E/('paid-art-r7-restart-'+mode)/'paid-restart.json');require(r['failures']==0,'fresh native restart '+mode)
for renderer in ['forward_plus','gl_compatibility']:
    cat=read(E/('r1-catalogue-'+renderer)/'checks.json')
    require(cat['failures']==0 and len(cat['pairs'])==273,'all native legal pairs '+renderer)
    require(len({(r['shape'],r['family']) for r in cat['pairs']})==273,'no duplicated legal pair evidence')
    require(read(B/('r7-views-before-'+renderer)/'distances.json')==read(E/('r7-views-after-'+renderer)/'distances.json'),'same retained anchor and cameras at all three stand-offs')
saved_states=[]
for mode,flow in [('before',a),('after',b)]:
    saved=OUT/'users'/('paid-'+mode)/'ART07G1/g1-paid.json'
    require(saved.exists(),'actual isolated paid save exists '+mode)
    actual=read(saved);captured=copy.deepcopy(flow['final']);raw_player={'saved':actual['player'],'report':captured['player']}
    require(set(actual['player'])==set(captured['player'])=={'position','pitch','yaw'},'same serialized player fields')
    require(len(actual['player']['position'])==len(captured['player']['position'])==3,'same position dimensions')
    av=actual['player']['position']+[actual['player']['pitch'],actual['player']['yaw']]
    bv=captured['player']['position']+[captured['player']['pitch'],captured['player']['yaw']]
    require(all(struct.pack('f',u)==struct.pack('f',v) for u,v in zip(av,bv)),'full-precision save and report decimal values reproduce identical Godot float32 player pose')
    captured['player']=actual['player'];require(actual==captured,'every other actual saved field exactly matches captured final state')
    target=OUT/'evidence/paid-state'/(mode+'.json');target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(saved,target)
    saved_states.append({'mode':mode,'source':str(saved),'copy':target.relative_to(OUT).as_posix(),'sha256':sha(saved),'bytes':saved.stat().st_size,'player_json_precision_evidence':raw_player,'comparison':'Exact non-player JSON; player position and angles reproduce identical engine float32 values. Save JSON uses full precision and report JSON uses default precision.'})
require(saved_states[0]['sha256']==saved_states[1]['sha256'],'actual before/after paid saves are byte-identical')
write(OUT/'evidence/paid-state-provenance.json',saved_states)
result['paid']={'stages':paid,'checks_before':a['count'],'checks_after':b['count'],'walk_before':a['walk'],'walk_after':b['walk']}
mesh=read(E/'r7-mesh-checks.json');require(mesh['failures']==0,'full vertex/sway envelope checks');result['mesh']=mesh
require(len(read(OUT/'evidence/role-audit.json')['roles'])==33,'all 33 roles audited')
# Job IDs/arguments/log hashes come from actual guarded runs, never inferred from specs.
specs=['r7-import-smoke-01.json','accepted-parse-jobs.json','candidate-view-jobs-01.json','reopen-jobs-01.json','paid-jobs-01.json','accepted-regression-jobs.json','cost-jobs-01.json','source-probe-jobs-03.json','route-motion-only.json']
for spec in specs:
    for job in read(OUT/spec):
        row=read(Path(job['log']+'.json'));require(row['exit_code']==0 and not row['failure'],'actual job passed '+job['id'])
        require(row['arguments']==job['arguments'] and row['log_sha256']==sha(job['log']),'exact job/log identity')
        require(not row['processes_before'] and not row['benchmark_competitors'],'isolated guarded process')
        result['jobs'].append(row)
for renderer in ['forward_plus','gl_compatibility']:
    name='views-before-'+renderer+'-02.log';row=read(OLD/'logs'/(name+'.json'));require(row['exit_code']==0 and not row['failure'],'executed R1 comparison baseline')
    require(row['log_sha256']==sha(OLD/'logs'/name),'baseline log hash');result['jobs'].append(row)
# Preserve original parent payloads except the four explicitly owned presentation hooks.
base=read(OUT/'evidence/parent-runtime-hashes.json');allowed={r['path'] for r in read(OUT/'evidence/r7-overlay-application.json')}
for name,digest in base.items():require(name in allowed or sha(OUT/'runtime'/name)==digest,'unchanged parent payload '+name)
for r in read(OUT/'evidence/selected-source-hashes.json'):require(sha(GAME/'b2/assets'/Path(r['path']).name)==r['sha256'],'unchanged selected B2 mesh')
result['diagnostics']=['The direct standalone grounding scene failed during resource preloading; the owned wrapper preloads the existing sandpit resource graph before running the unchanged original fixture. Original failure log remains. ','V02 first historical ecology test hit the inherited C6 expectation of CataclysmSites, absent in frontier_v3. Owned fixture now supplies an empty typed history container only; original profile/build logic/assertions are retained. Failure log is preserved.','V02 first mesh-check parser run failed inference of a local Vector3; explicit type fixed in fixture and fresh parse-mesh_checks-02 passed. Failed original log retained.','V01 first source probe failed because its output directory was missing; corrected before the accepted source probe.','V01 first view fixture rejected mixed indentation; corrected and explicitly parsed.','V01 darker/narrow shrub candidate rejected visually; all original images/logs retained. V02 changes only its composition and nonemissive leaf lighting.','Busy-slot attempts launched no engine and the shared wrapper exposed its missing-empty-log diagnostic; process/mutex guards remained unchanged.','Existing Compatibility SSAO warnings remain visible; no rendering diagnostic is suppressed.']
result['checks']=checks;result['passed']=True
write(OUT/'evidence/final-checks.json',result)
print('R7_FINAL_CHECKS',checks,'actual jobs',len(result['jobs']),'passed')
