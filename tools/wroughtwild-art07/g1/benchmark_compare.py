"""Summarize paired uncontended backend runs without averaging unlike scenes."""
import json
import sys
from pathlib import Path

evidence,out=map(Path,sys.argv[1:])
result={'conditions':'1440x900, 4x MSAA, vsync disabled, 120 warmup frames, 300 sampled frames per camera/light. Fixed same paid checkpoint and native active IDs. Separate processes; no capture during timing.','renderers':{}}
for renderer in ['forward_plus','gl_compatibility']:
    a,b=[json.loads((evidence/f'benchmark-{mode}-{renderer}/report.json').read_text()) for mode in ['art','baseline']]
    assert a['failures']==b['failures']==0 and a['gpu']==b['gpu'] and a['viewport']==b['viewport']
    rows=[]
    assert len(a['samples'])==len(b['samples'])==8
    for x,y in zip(a['samples'],b['samples']):
        for key in ['scene','lighting','samples','camera','target','resources','resource_ids_sha256','chunks']:assert x[key]==y[key],(renderer,key,x[key],y[key])
        rows.append({'scene':x['scene'],'lighting':x['lighting'],'art':x,'baseline':y,'median_delta_ms':x['frame_median_ms']-y['frame_median_ms'],'median_ratio':x['frame_median_ms']/y['frame_median_ms']})
    result['renderers'][renderer]={'gpu':a['gpu'],'rows':rows}
with out.open('x') as f:json.dump(result,f,indent=2)
print('G1_MATCHED_BENCHMARK_OK',sum(len(r['rows']) for r in result['renderers'].values()))
