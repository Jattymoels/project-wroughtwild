"""Validate and report the six separate uncaptured R2 controller measurements."""
import json
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
build=ROOT/'build/art07-repairs/r8';doc=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8';records=[];reference=None
for version in ['v01','v02']:
    for j in read(build/version/'jobs-traversal-01.json'):
        receipt=read(Path(j['log']+'.json'));assert receipt['exit_code']==0 and not receipt['failure'] and not receipt['benchmark_competitors'] and not receipt['processes_before']
        assert '--benchmark' in j['arguments'] and '--capture' not in j['arguments'] and '--fixed-fps' not in j['arguments']
        matches=list((build/version/'runtime/evidence').glob('*r8-'+j['id']+'/traversal.json'));assert len(matches)==1,(j['id'],matches)
        p=matches[0];d=read(p);assert d['failures']==0 and d['frame_count']==len(d['frames_ms']) and d['frame_count']>300 and d['worst_ms']==max(d['frames_ms'])
        assert d['viewport']=='(1440, 900)' and d['msaa']==2 and d['vsync']==0
        assert not d['walk']['stalled'] and d['walk']['metres']>100
        if reference is None:reference=d['walk']
        assert d['walk']==reference,(j['id'],'native route differs')
        records.append({'version':version,'job':j['id'],'path':str(p),'sha256':sha(p),**{k:d[k] for k in ['frame_count','median_ms','p95_ms','worst_ms','renderer','engine','gpu','gpu_api','viewport','msaa','vsync']},'walk_metres':d['walk']['metres']})
assert len(records)==6
write(doc/'traversal-costs.json',{'runs':records,'scope':'Single uncaptured traversal per mode/backend, following the published R2 protocol. All use the exact native route and original settling/input; no capture calls or fixed-FPS cap. These streaming maxima are separate from settled-camera cost and do not establish minimum-hardware acceptance or repeatability bands.'})
lines=['# Uncaptured controller traversal','','Six separate actual native-route measurements; current-device observations, not settled-frame or target-device acceptance. All walk records are exactly equal.','','| Runtime / mode / backend | Frames | Median ms | p95 ms | Worst ms | Metres |','| --- | --- | --- | --- | --- | --- |']
for r in records:lines.append(f"| {r['version']} / {r['job']} | {r['frame_count']} | {r['median_ms']:.3f} | {r['p95_ms']:.3f} | {r['worst_ms']:.3f} | {r['walk_metres']:.6f} |")
write(doc/'traversal-costs.md','\n'.join(lines)+'\n');print('R8_TRAVERSAL_COSTS_VALID',len(records))
