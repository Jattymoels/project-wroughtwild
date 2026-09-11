"""Independent evidence gates; image presence alone cannot clear a test."""
import json,sys
from pathlib import Path
import numpy as np
from PIL import Image
review,out=[Path(p).resolve() for p in sys.argv[1:]]
result={};canonical=None
for renderer in ['forward_plus','gl_compatibility']:
    root=review/'evidence'/renderer;summary={};native=None
    for mode in ['check','capture','walk','motion','benchmark']:
        report=json.loads((root/(mode+'-77')/'report.json').read_text())
        assert report['checks']>0 and report['failures']==0,(renderer,mode)
        if canonical is None:canonical=report['native_before']
        assert report['native_before']==canonical,(renderer,mode,'cross-renderer native mismatch')
        if native is None:native=report['native_before']
        assert report['native_before']==native,(renderer,mode,'native mismatch')
        summary[mode]={'checks':report['checks'],'failures':0}
        if mode=='walk':
            for walk in report['walks']:assert walk['reached'] and walk['endpoint_supported'] and walk['distance_m']>10,walk
            summary[mode]['walks']=report['walks']
        if mode=='benchmark':summary[mode]['views']=report['views']
    captures=root/'capture-77'
    changed={}
    for after in captures.glob('*-after-day.png'):
        before=Path(str(after).replace('-after-day','-before-day'))
        a=np.array(Image.open(after).convert('RGB'),dtype=np.int16);b=np.array(Image.open(before).convert('RGB'),dtype=np.int16)
        # Exclude the caption from difference evidence.
        difference=np.abs(a[80:]-b[80:]);changed[after.stem]=int(np.count_nonzero(difference.max(2)>8))
    assert changed and max(changed.values())>500
    on=np.array(Image.open(captures/'struck-wall-emission-on.png').convert('RGB'),dtype=np.int16)
    off=np.array(Image.open(captures/'struck-wall-emission-off.png').convert('RGB'),dtype=np.int16)
    emission=int(np.count_nonzero(np.abs(on[80:]-off[80:]).max(2)>5));assert emission>10,(renderer,'no visible emission difference')
    frames=sorted((root/'motion-77').glob('pulse-*.png'));assert len(frames)==48
    arrays=[np.array(Image.open(p).convert('RGB'),dtype=np.int16)[80:] for p in frames]
    motion=max(int(np.count_nonzero(np.abs(a-arrays[0]).max(2)>8)) for a in arrays[1:]);assert motion>20
    summary['visible_change_pixels']=changed;summary['emission_change_pixels']=emission;summary['motion_change_pixels']=motion
    result[renderer]=summary
out.write_text(json.dumps(result,indent=2)+'\n');print('C6_EVIDENCE_VERIFIED')
