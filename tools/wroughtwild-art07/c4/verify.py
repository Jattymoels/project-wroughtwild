"""Validate actual rendered evidence and state records, with no invented measurements."""
import json,sys,hashlib
from pathlib import Path
import numpy as np
from PIL import Image
review,native,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
def pix(p):return np.array(Image.open(p).convert('RGB'))[100:,:,:]
results={}
for renderer in ['forward_plus','gl_compatibility']:
    e=review/'evidence'/renderer;n=native/'c4/evidence'/renderer
    checks=json.loads((e/'checks.json').read_text());walk=json.loads((e/'walk.json').read_text());benchmark=json.loads((e/'benchmark.json').read_text())
    assert checks['failures']==0 and len(checks['ground_contacts'])>=100
    assert walk['distance_m']>35 and all(s['supported'] and abs(s['x'])<.08 for s in walk['samples'])
    records={name:json.loads((n/('native-'+name+'.json')).read_text()) for name in ['flow','partial-restart','final-restart']}
    assert all(r['failures']==0 for r in records.values())
    assert records['flow']['ash_wood']==records['final-restart']['ash_wood']==28 and records['partial-restart']['ash_wood']==0
    variation={}
    for kind in ['pulse','wind']:
        files=sorted(e.glob(kind+'-*.png'));assert len(files)==48
        first=pix(files[0]);counts=[float(np.mean(np.max(np.abs(pix(p).astype(float)-first),axis=2)>8)) for p in files[1:]]
        assert max(counts)>0,(renderer,kind,'no rendered movement')
        variation[kind+'_maximum_changed_fraction_gt8']=max(counts)
        if kind=='pulse':
            # Close front camera: measure the scar host, excluding background plants.
            roi=first[:700,650:790,:].astype(float)
            changed=[float(np.mean(np.max(np.abs(pix(p)[:700,650:790,:].astype(float)-roi),axis=2)>8)) for p in files[1:]]
            assert max(changed)>.01,(renderer,'scar host has no visible pulse')
            variation['scar_host_maximum_changed_fraction_gt8']=max(changed)
    paused=sorted(e.glob('paused-*.png'));assert len(paused)==12
    assert all(np.array_equal(pix(paused[2]),pix(p)) for p in paused[3:]),(renderer,'paused frame changed')
    off=pix(e/'ash-scar-off.png');on=pix(e/'ash-scar-on.png');assert np.any(off!=on)
    results[renderer]={'review_checks':checks['assertions'],'native_checks':{k:v['checks'] for k,v in records.items()},'route_m':walk['distance_m'],'supported_samples':len(walk['samples']),'motion':variation,'pause_last_ten_identical':True,'benchmark':benchmark}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(results,indent=2)+'\n')
print('C4_EVIDENCE_VERIFIED')
