"""Compare fresh G2 evidence and curate actual, unsynthesized model renders."""
import collections
import hashlib
import json
import re
import shutil
from pathlib import Path
from PIL import Image
from verify_copy import ROOT, BUILD, sha
OUT=BUILD/'v01'
EVIDENCE=OUT/'review/evidence'
DOCS=ROOT/'docs/art/leyline-studies/2026-09-09/art07/g2'
DOCS.mkdir(parents=True,exist_ok=True)

def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path,value):
    if path.exists():
        assert read(path)==value,str(path)
        return
    with path.open('x',encoding='utf-8') as stream:json.dump(value,stream,indent=2)

jobs=[]
for log in sorted((OUT/'logs').glob('*.log.json')):
    row=read(log)
    assert row['exit_code']==0 and not row['failure'],str(log)
    assert sha(log.with_suffix(''))==row['log_sha256'],str(log)
    jobs.append(row)
specs=['core-jobs','native-full-jobs' if (OUT/'native-full-jobs.json').exists() else 'native-jobs','render-jobs','supplement-jobs','g2-benchmark-jobs','blender-jobs']
if (OUT/'restart-job.json').exists():specs.append('restart-job')
planned={j['id']:j for spec in specs for j in read(OUT/(spec+'.json'))}
assert len(jobs) in [63,64] and len({j['id'] for j in jobs})==len(jobs)
assert set(planned)=={j['id'] for j in jobs}
for j in jobs:assert j['arguments']==planned[j['id']]['arguments'],j['id']
blender=read(OUT/'blender/report.json')
assert len(blender['masters'])==30 and len(blender['imports'])==6
packed_images=[i for m in blender['masters'] for i in m['images']]
assert len(packed_images)==477 and all(i['packed'] and i['available'] for i in packed_images)
native_reports=[]
for folder in ['b1','b3','c1','c2','c3','c4','c5']:
    for path in sorted((OUT/'review/game'/folder/'evidence').rglob('*.json')):
        if path.relative_to(OUT/'review').as_posix() in read(OUT/'copy.json')['runtime_files']:continue
        value=read(path)
        assert value.get('failures',0)==0 and value['checks']>0,str(path)
        native_reports.append({'path':str(path),'checks':value['checks'],'failures':value.get('failures',0),'sha256':sha(path)})
assert len(native_reports)==12
for renderer in ['forward_plus','gl_compatibility']:
    catalogue=read(EVIDENCE/('catalogue-'+renderer)/'checks.json')
    assert catalogue['failures']==0 and len(catalogue['pairs'])==273
    pairs={(r['shape'],r['family']) for r in catalogue['pairs']}
    assert len(pairs)==273
    if renderer=='forward_plus':reference_pairs=pairs
    else:assert pairs==reference_pairs
actors=[read(EVIDENCE/('g2-fauna-'+r)/'report.json') for r in ['forward_plus','gl_compatibility']]
assert all(r['failures']==0 and len(r['actors'])==16 for r in actors)
assert [r['id'] for r in actors[0]['actors']]==[r['id'] for r in actors[1]['actors']]
canopy=read(EVIDENCE/'g2-canopy.json')
assert canopy['failures']==0
scales=collections.defaultdict(list)
for row in canopy['live_trees']:scales[row['family']].append(row['horizontal_scale'])
canopy_summary={f:{'instances':len(v),'horizontal_scale_min':min(v),'horizontal_scale_max':max(v),'vertical_scale':1.0} for f,v in scales.items()}
comparison={'conditions':'RTX 5090, 1440x900, 4x MSAA, vsync off, 120 warmup/300 sampled wall frames per camera/light; no captures or generation in benchmark processes. Max is independently recorded by the G2-only derivative.','renderers':{}}
for renderer in ['forward_plus','gl_compatibility']:
    a,b=[read(EVIDENCE/('g2-benchmark-'+m+'-'+renderer)/'report.json') for m in ['art','baseline']]
    assert a['failures']==b['failures']==0 and a['gpu']==b['gpu'] and a['viewport']==b['viewport']=='(1440, 900)'
    assert a['vsync']==b['vsync']==0
    assert all(not list((EVIDENCE/('g2-benchmark-'+mode+'-'+renderer)).glob('*.png')) for mode in ['art','baseline'])
    assert len(a['samples'])==len(b['samples'])==8
    rows=[]
    for x,y in zip(a['samples'],b['samples']):
        for key in ['scene','lighting','samples','camera','target','resources','resource_ids_sha256','chunks']:assert x[key]==y[key],(renderer,key)
        rows.append({'scene':x['scene'],'lighting':x['lighting'],'art':x,'baseline':y,'median_delta_ms':x['frame_median_ms']-y['frame_median_ms']})
    comparison['renderers'][renderer]={'gpu':a['gpu'],'setup_elapsed_ms':{'art':a['setup_elapsed_ms'],'baseline':b['setup_elapsed_ms']},'rows':rows}
write(OUT/'cost-comparison.json',comparison)
lines=['# G2 independent combined-cost replay','',comparison['conditions'],'','These are local measurements, not an approved runtime budget or lower-spec clearance. Loaded allocations include hidden/prefetched work stages and LODs; unique triangles count base meshes once, including hidden meshes.','']
for renderer,result in comparison['renderers'].items():
    lines += ['## '+renderer,'',f"Engine-clock setup through paid checkpoint/camera setup: {result['setup_elapsed_ms']['baseline']/1000:.3f} s baseline / {result['setup_elapsed_ms']['art']/1000:.3f} s art. One process each; includes world construction and paid restore, excludes subsequent per-view focus/warmup.",'','| Camera / light | Baseline median / p95 / worst ms | Art median / p95 / worst ms | Baseline / art draws |','| --- | ---: | ---: | ---: |']
    for row in result['rows']:
        a,b=row['art'],row['baseline']
        fmt=lambda r:'/'.join(f'{r[k]:.3f}' for k in ['frame_median_ms','frame_p95_ms','frame_worst_ms'])
        lines.append(f"| {row['scene']} / {row['lighting']} | {fmt(b)} | {fmt(a)} | {b['draw_calls']} / {a['draw_calls']} |")
    lines += ['','| Loaded cost | Baseline range | Art range |','| --- | ---: | ---: |']
    for title,key,divisor in [('Textures MiB','texture_bytes_total_loaded',2**20),('Buffers MiB','buffer_bytes_total_loaded',2**20),('Video allocations MiB','video_bytes_total_loaded',2**20),('Unique triangles incl. hidden','scene_unique_triangles',1),('Unique surfaces incl. hidden','scene_unique_surfaces',1),('Instances incl. hidden/MultiMesh','mesh_instances_including_multimesh_and_hidden',1)]:
        ranges=[]
        for mode in ['baseline','art']:
            vals=[r[mode]['cost'][key]/divisor for r in result['rows']]
            ranges.append(f'{min(vals):,.1f}â€“{max(vals):,.1f}' if divisor>1 else f'{min(vals):,.0f}â€“{max(vals):,.0f}')
        lines.append(f'| {title} | {ranges[0]} | {ranges[1]} |')
    lines.append('')
(DOCS/'costs.md').write_text('\n'.join(lines),encoding='utf-8')
images={
 'home-forward.png':EVIDENCE/'views-art-forward_plus/paid-home-day.png',
 'home-compatibility.png':EVIDENCE/'views-art-gl_compatibility/paid-home-day.png',
 'home-dusk.png':EVIDENCE/'views-art-forward_plus/paid-home-dusk.png',
 'interior.png':EVIDENCE/'views-art-forward_plus/paid-interior-day.png',
 'catalogue.png':EVIDENCE/'catalogue-forward_plus/wood.png',
 'feeder.png':EVIDENCE/'forward_plus/03-paid-firing.png',
 'feeder-no-emission.png':EVIDENCE/'forward_plus/07-rear-emission-off.png',
 'feeder-shade.png':EVIDENCE/'forward_plus/07-shade.png',
 'exhausted-reload.png':EVIDENCE/'forward_plus/14-exhausted-reload.png',
 'fauna-forward.png':EVIDENCE/'g2-fauna-forward_plus/lineup.png',
 'fauna-compatibility.png':EVIDENCE/'g2-fauna-gl_compatibility/lineup.png',
 'blender-material.png':OUT/'blender/material.png',
 'blender-clay.png':OUT/'blender/clay.png'}
media={'images':{},'motion':{}}
for name,source in images.items():
    assert source.is_file(),source
    shutil.copy2(source,DOCS/name)
    assert sha(source)==sha(DOCS/name)
    with Image.open(source) as im:dimensions=list(im.size)
    media['images'][name]={'source':str(source),'sha256':sha(source),'dimensions':dimensions,'scope':'Unedited fresh G2 render; copied byte-for-byte.'}
for name,folder,pattern,duration in [('route.webp',EVIDENCE/'paid-art-forward_plus-g2-walk/walk','*.png',300),('feeder.webp',EVIDENCE/'forward_plus','motion-*.png',33),('feeder-compatibility.webp',EVIDENCE/'gl_compatibility','motion-*.png',33)]:
    paths=sorted(folder.glob(pattern));assert len(paths)>=20,(name,len(paths))
    frames=[]
    for path in paths:
        with Image.open(path) as im:
            frame=im.convert('RGB');frame.thumbnail((1024,640));frames.append(frame.copy())
    frames[0].save(DOCS/name,save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=78,method=4)
    media['motion'][name]={'frames':[{'path':str(p),'sha256':sha(p)} for p in paths],'frame_ms':duration,'sha256':sha(DOCS/name),'dimensions':list(frames[0].size),'scope':'Actual ordered frames, resized/encoded only. No interpolation. Route cadence illustrative; feeder uses native 30 Hz work/pause/blocked ticks.'}
write(DOCS/'media.json',media)
source_audit=read(OUT/'source-audit.json')
summary={'jobs':jobs,'job_count':len(jobs),'source_audit':source_audit,'inputs':read(OUT/'inputs.json'),'paired_paid':read(OUT/'paired-paid.json'),'paired_probes':read(OUT/'paired-probes.json'),'canopy':canopy_summary,'fauna':actors,'costs':comparison,'blender':blender,'native_reports':native_reports,'hardware':read(OUT/'hardware.json'),'execution_notes':['The initial G2 paid-art-restart job mistakenly used --restore, which runs the full paid path; it is an additional 865-assertion replay, not restart evidence. paid-fresh-restart uses the actual --restart flag and is the fresh-process proof. The reproduction recipe is corrected.','The initial direct Git blob audit detected archive CRLF export. Final audit permits only exact CRLF-to-LF text conversion and records every affected archive file; sealed bytes remain untouched.']}
warnings={}
checks_lines=['# G2 executed checks','', f'All {len(jobs)} owned subprocesses exited 0. Native assertions are unchanged; the misnamed paid replay is explicitly excluded from restart proof. Full logs, exact arguments and isolated state paths are sealed locally.','', '| Job | Seconds | Result |', '| --- | ---: | --- |']
compact=[]
for row in jobs:
    log=OUT/'logs'/(row['id']+'.log')
    output=log.read_text(encoding='utf-8-sig').splitlines()
    result=[v for v in output if re.search(r'^(?:[A-Z][A-Z0-9_-]+ .*|[0-9]+ checks.*)$',v) and any(k in v for k in ['_OK','_RESULT','checks','_RESTART','_PLACEMENT'])]
    note='; '.join(result) if result else 'Exit 0; detailed import/render log retained.'
    checks_lines.append(f"| {row['id']} | {row['seconds']:.2f} | {note} |")
    warning=[v for v in output if v.startswith('WARNING:')]
    if warning:warnings[row['id']]=warning
    compact.append({'id':row['id'],'exit_code':row['exit_code'],'seconds':row['seconds'],'results':result,'log_sha256':row['log_sha256']})
checks_lines+=['','Warnings remain visible in the audit: expected invalid-input/save-recovery cases; SSAO unsupported by Compatibility (both art and baseline); ObjectDB shutdown warnings in eight isolated source fixture runs. The latter are a bounded cleanup handback, not proof of leak-free long sessions. No fatal engine/script diagnostic was accepted.','']
(DOCS/'checks.md').write_text('\n'.join(checks_lines),encoding='utf-8')
write(DOCS/'checks.json',{'jobs':compact,'warnings':warnings,'native_reports':native_reports,'packed_masters':30,'packed_file_images':477,'fresh_glb_imports':6})
summary['warnings']=warnings
write(OUT/'review-summary.json',summary)
print('G2_EVIDENCE_CURATED',len(jobs),'jobs',len(images),'images',len(media['motion']),'motion sequences')
