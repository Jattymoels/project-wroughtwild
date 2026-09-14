"""Strict final R1 evidence aggregation; missing/failed evidence never passes."""
import json,statistics,shutil
from pathlib import Path
from measure import OUT,GAME,sha,write
E=OUT/'runtime/evidence'
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
checks=[]
def checked(label,value,detail=None):
    assert value,(label,detail)
    checks.append({'check':label,'passed':True,'detail':detail})

jobs=[]
for name in ['model-jobs.json','packed-master-02-jobs.json','import-smoke.json','native-jobs.json','core-jobs.json','capture-02-jobs.json','studio-final-jobs.json','benchmark-jobs.json']:
    for j in read(OUT/name):
        log=Path(j['log']);r=read(str(log)+'.json')
        checked('real job '+j['id'],r['exit_code']==0 and not r['failure'] and r['child_pid'] is not None and sha(log)==r['log_sha256'])
        checked('isolated job '+j['id'],not r['processes_before'] and not r['benchmark_competitors'])
        jobs.append({'id':j['id'],'seconds':r['seconds'],'exit_code':r['exit_code'],'child_pid':r['child_pid'],'log':str(log),'log_sha256':r['log_sha256'],'appdata':r['appdata'],'stderr':Path(str(log)+'.stderr').read_text(encoding='utf-8-sig')})

before=read(E/'r1-probe-before.json');after=read(E/'r1-probe-after.json')
checked('Full paid probe snapshots identical',before['snapshot']==after['snapshot'])
checked('Full saved geography identical',before['geography_sha256']==after['geography_sha256'],before['geography_sha256'])
checked('Both probe assertion sets pass',before['failures']==after['failures']==0)
paid={m:read(E/('paid-art-r1-'+m)/'paid.json') for m in ['before','after']}
from ownership import compare
paid_comparisons={}
for state in ['initial','paid','final']:
    paid_comparisons[state]=compare(paid['before'][state],paid['after'][state])
    checked('Full no-grants native ownership/geography '+state+' with all raw differences exposed',paid_comparisons[state]['native_ownership_and_geography_equal'],paid_comparisons[state])
checked('Raw initial snapshot identical',paid_comparisons['initial']['full_snapshot_equal'])
for mode in ['before','after']:
    checked('Paid flow '+mode,paid[mode]['failures']==0 and not paid[mode]['walk']['stalled'] and paid[mode]['walk']['metres']>100)
    restart=read(E/('paid-art-r1-restart-'+mode)/'paid-restart.json')
    checked('Real separate-process paid restore '+mode,restart['failures']==0)
    flow_job=next(j for j in jobs if j['id']=='paid-'+mode);restart_job=next(j for j in jobs if j['id']=='paid-restart-'+mode)
    checked('Distinct paid process IDs '+mode,flow_job['child_pid']!=restart_job['child_pid'])

native=[]
for p in sorted(E.glob('r1-native-*/*.json')):
    if p.name=='motion-times.json':continue
    r=read(p);checked('Native '+str(p.relative_to(E)),r['failures']==0 and r['checks']>0)
    native.append({'file':str(p.relative_to(E)),'checks':r['checks'],'wood':r.get('wood'),'pine':r.get('pine'),'ash_wood':r.get('ash_wood')})
for kind in ['b1','c4']:
    for suffix in ['partial','final']:
        key=kind+'-'+('after' if kind=='b1' else 'flow');restart=kind+'-'+suffix
        checked('Distinct '+restart+' process',next(j for j in jobs if j['id']==key)['child_pid']!=next(j for j in jobs if j['id']==restart)['child_pid'])

for kind in ['broadleaf','pine']:
    for p in (OUT/'models'/kind).glob('*.glb'):
        checked('Byte-identical selected export after packed-master repair '+p.name,sha(p)==sha(OUT/'models-packed-v2'/kind/p.name))

geometries=read(OUT/'evidence/model-costs.json')['exports'];reopen=read(OUT/'evidence/blender-reopen-packed.json');source=read(OUT/'evidence/source-and-scar-audit.json')
checked('Two actual packed-master copies reopened',len(reopen['masters'])==2)
checked('Every exported LOD/stage finite and fitted',len(reopen['exports'])==len(geometries)==19 and all(r['degenerate_triangles']==0 and r['lower_radius_m']<=.343001 for r in reopen['exports']))
checked('Original source objects/maps retained inside both masters',len(source['preserved_originals'])==2 and all(r['exact_source_geometry_uv_and_packed_bytes_retained'] for r in source['preserved_originals']))
checked('Actual altered geometry sections measured in every LOD',len(source['scar_sections'])==6)
checked('No extra triangles or changed decoded maps',all(r['source_triangles']==r['triangles'] and r['unique_decoded_maps_preserved'] and r['height_extremes_preserved'] for r in geometries))
materials=read(OUT/'evidence/material-bindings.json')['exports']
checked('All 19 source material bindings and sampler settings retained',len(materials)==19 and all(r['material_properties_texture_bindings_and_sampler_settings_equal'] and r['triangle_totals_by_material_equal'] for r in materials))

views=[];performance=[]
for renderer in ['forward_plus','gl_compatibility']:
    old=read(E/('r1-views-v02-before-'+renderer)/'report.json');new=read(E/('r1-views-v02-after-'+renderer)/'report.json')
    checked(renderer+' identical cameras',old['views']==new['views'])
    checked(renderer+' matched views passed',old['failures']==new['failures']==0)
    for a,b in zip(old['measurements'],new['measurements']):
        checked(renderer+' camera label '+a['camera_id'],a['camera_id']==b['camera_id'] and a['eye']==b['eye'] and a['target']==b['target'])
        old_rows={r['id']:r for r in a['trees']};matched=[]
        for r in b['trees']:
            if r['id'] not in old_rows:continue
            v=old_rows[r['id']]
            checked('Native pose/body/visibility '+renderer+' '+r['id'],all(v[k]==r[k] for k in ['position','body','visibility_end']))
            matched.append({'id':r['id'],'family':r['family'],'before_width_camera_m':v['crown_width_camera_m'],'after_width_camera_m':r['crown_width_camera_m'],'before_scale':v['model_scale'],'after_scale':r['model_scale']})
        views.append({'renderer':renderer,'camera':a['camera_id'],'eye':a['eye'],'target':a['target'],'before_visible_bound_count':len(a['trees']),'after_visible_bound_count':len(b['trees']),'before_overlap_pairs':len(a['overlaps']),'after_overlap_pairs':len(b['overlaps']),'before_sum_overlap_px2':sum(o['overlap_px2'] for o in a['overlaps']),'after_sum_overlap_px2':sum(o['overlap_px2'] for o in b['overlaps']),'matched':matched,'scope':a['scope']})
    catalogue=read(E/('r1-catalogue-'+renderer)/'checks.json')
    checked(renderer+' all 273 legal native pairs',catalogue['failures']==0 and len(catalogue['pairs'])==273)
    for mode in ['before','after']:
        timed=read(E/('r1-cost-v02-'+mode+'-'+renderer)/'report.json')
        checked(renderer+' settled '+mode,timed['failures']==0 and len(timed['samples'])==12 and all(r['samples']==300 for r in timed['samples']))
        stream=read(E/('paid-art-r1-stream-'+mode+'-'+renderer)/'paid.json')
        checked(renderer+' streaming '+mode,stream['failures']==0 and not stream['walk']['stalled'] and stream['walk']['metres']>100 and stream['streaming_frames']['samples']>0)
        performance.append({'renderer':renderer,'mode':mode,'gpu':timed['gpu'],'viewport':timed['viewport'],'settled':timed['samples'],'cost':timed['cost'],'streaming':stream['streaming_frames'],'streamed_walk_metres':stream['walk']['metres'],'scope':'Current measurement machine; not minimum-hardware acceptance.'})
    studio=E/('r1-studio-v02-'+renderer)
    checked(renderer+' actual every-LOD images',all((studio/(kind+'-lod'+str(lod)+'.png')).is_file() for kind in ['broadleaf','pine','broadleaf-b','pine-b','broadleaf-altered'] for lod in range(3)))
    checked(renderer+' altered emission off/on and motion',(studio/'scar-emission-off.png').is_file() and (studio/'scar-emission-on.png').is_file() and len(list(studio.glob('scar-motion-*.png')))==48)
    checked(renderer+' actual native fall frame timing',(E/('r1-native-b1-after-'+renderer)/'motion-times.json').is_file())
route=read(E/'paid-art-forward_plus-r1-route-motion/paid.json')
checked('Actual input route motion',route['failures']==0 and route['walk']['metres']>100 and len(list((E/'paid-art-forward_plus-r1-route-motion/walk').glob('*.png')))>0)

original=read(OUT/'prepared.json')['original_files'];changed=[]
for name,row in original.items():
    if sha(OUT/'runtime'/name)!=row['sha256']:changed.append(name)
checked('Exact pinned originals except one documented selection hook',changed==['game/g1/art.gd'],changed)
for row in read(OUT/'evidence/copied-source-hashes.json'):checked('Unmodified copied source '+Path(row['copy']).name,sha(row['copy'])==row['sha256'] and sha(row['source'])==row['sha256'])
saved=[]
for name in ['b1-partial.json','b1-final.json','c4-partial.json','c4-final.json','g1-paid.json']:
    paths=list((OUT/'users').rglob(name));checked('Private checkpoint retained '+name,bool(paths))
    for p in paths:
        relative=p.relative_to(OUT/'users');dest=OUT/'evidence/private-checkpoints'/relative
        assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        saved.append({'private_path':str(p),'package_evidence_path':str(dest.relative_to(OUT)),'sha256':sha(p)})
write(OUT/'evidence/private-checkpoints.json',saved)
write(OUT/'evidence/view-comparison.json',views)
write(OUT/'evidence/performance-comparison.json',performance)
write(OUT/'evidence/final-checks.json',{'passed':True,'checks':checks,'jobs':jobs,'retained_failed_audit':read(OUT/'logs/source-audit.log.json'),'retained_failed_studio_parse':read(OUT/'logs/studio-forward_plus.log.json'),'retained_failed_missing_mask':read(OUT/'logs/preserve-packed.log.json'),'native':native,'geography_sha256':before['geography_sha256'],'paid_check_counts':{m:paid[m]['count'] for m in paid},'paid_walk_metres':{m:paid[m]['walk']['metres'] for m in paid},'paid_full_snapshot_comparisons':paid_comparisons,'owner_visual_acceptance':'pending','ordinary_world_rollout':'outside scope'})
print('R1_FINAL_CHECKS_OK',len(checks),'checks;',len(jobs),'real jobs')
