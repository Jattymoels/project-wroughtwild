"""Verify state and actual renderer pixels; publish unchanged engine captures.
Usage: REVIEW EDITABLE OUTPUT_DOCS. Lossless encoding changes no source pixels.
"""
import sys,json,hashlib,shutil
from pathlib import Path
import numpy as np
from PIL import Image,ImageSequence
review,editable,out=[Path(p).resolve() for p in sys.argv[1:4]];out.mkdir(parents=True,exist_ok=True)
results={};checks=0
def check(value,label):
    global checks
    checks+=1
    assert value,label
def pixels(folder,name,region):
    return np.array(Image.open(review/folder/name).convert('RGB').crop(region),dtype=np.int16)
for folder in ['evidence','evidence-compat']:
    data=json.loads((review/folder/'visual-checks.json').read_text(encoding='utf-8'));check(not data['failures'],folder+' visual failures')
    entries={e['file']:e for e in data['captures']}
    for filename in entries:check((review/folder/filename).is_file(),filename+' real capture exists')
    check(entries['source-claim.png']['view']['raw_claim']==16,'released native lot')
    check(entries['blue-flakes.png']['view']['mineral_owned']==30,'native collection')
    check(entries['source-spent.png']['view']['mineral_owned']==126 and not entries['source-spent.png']['view']['source_ready'],'actual source exhaustion')
    check(entries['source-rare-held.png']['view']['rare_claim']==1 and entries['source-rare-held.png']['view']['raw_claim']==0,'rare-only claim not hidden after raw collection')
    held=entries['delay-held.png']['view'];paused=entries['delay-paused.png']['view']
    check(held['pending'] and not held['release_visible'] and held['delay_seconds']==.8,'load keeps actual pending delay without release replay')
    check(paused['delay_paused'] and paused['delay_seconds']==held['delay_seconds'],'explicit pause retains delay')
    check(entries['delay-signal-blocked.png']['view']['pending'] and entries['delay-signal-blocked.png']['view']['delay_seconds']==.8,'obstructed output holds exact time')
    check(not entries['delay-cancelled.png']['view']['release_visible'] and not entries['delay-cancelled.png']['view']['pending'],'cancellation does not become a release')
    idle=entries['delay-idle.png']['view']
    check(not idle['moving'] and idle['at_landing'] and idle['cargo']==10 and idle['energy']==0 and idle['trips']==3,'one actual paid arrival')
    failed=entries['delay-unwound-release.png']['view']
    check(failed['release_visible'] and not failed['moving'] and not failed['pending'] and failed['energy']==0,'unwound expiry consumes request without work')
    check(failed['release_age']==entries['delay-release-paused.png']['view']['release_age'],'review pause freezes release')
    check(entries['cargo-blocked.png']['view']['energy']==1 and not entries['cargo-blocked.png']['view']['pending'],'blocked cargo refuses payment and retains no future request')
    differences={}
    for a,b,region in [('source-ready.png','source-no-glow.png',(570,355,1000,760)),('delay-held.png','delay-held-no-glow.png',(610,335,965,790)),('delay-held.png','request-12.png',(660,385,910,615))]:
        first=pixels(folder,a,region);second=pixels(folder,b,region)
        changed=int(np.any(first!=second,axis=2).sum());maximum=int(np.abs(first-second).max())
        check(changed>50 and maximum>10,a+' actual scar pixels respond to light or native progress')
        differences[a+' / '+b]={'changed_pixels':changed,'maximum_channel_difference':maximum,'region':region}
    region=(660,385,910,615)
    check(np.array_equal(pixels(folder,'delay-held.png',region),pixels(folder,'delay-paused.png',region)),'explicit pause preserves exact rendered core pixels')
    results[folder]={'visual_checks':data['checks'],'captures':len(entries),'renderer':data['renderer'],'rendered_light_differences':differences,'paused_core_pixels_identical':True}
frames=[Image.open(review/'evidence'/f'request-{i:02d}.png').convert('RGB') for i in range(64)]
clip=out/'blue-delay.webp';frames[0].save(clip,save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,method=6)
decoded=Image.open(clip);timeline=[];elapsed=0
for frame in ImageSequence.Iterator(decoded):
    frame.load();duration=int(frame.info.get('duration',0));timeline.append((elapsed,elapsed+duration,np.array(frame.convert('RGB'))));elapsed+=duration
check(elapsed==8000,'eight-second source frame timeline')
for i,frame in enumerate(frames):
    matching=[p for start,end,p in timeline if start<=i*125<end]
    check(len(matching)==1 and np.array_equal(np.array(frame),matching[0]),'decoded frame equals actual engine image')
for name in ['source-ready','source-shade','source-no-glow','source-claim','source-spent','source-rare-held','blue-flakes','delay-held','delay-paused','delay-idle','delay-unwound-release','workshop-overview']:
    shutil.copy2(review/'evidence'/(name+'.png'),out/(name+'.png'))
shutil.copy2(editable/'editable-preview.png',out/'editable-preview.png')
shutil.copy2(review/'evidence/performance.json',out/'performance.json')
shutil.copy2(review/'provenance.json',out/'provenance.json')
report={'native':json.loads((review/'evidence/native-checks.json').read_text()),'restart':json.loads((review/'evidence/native-restart.json').read_text()),'assets':json.loads((editable/'asset-checks.json').read_text()),'renderers':results,'evidence_checks':checks,'clip':{'source_frames':64,'encoded_frames':len(timeline),'duration_ms':elapsed,'lossless_exact':True,'sha256':hashlib.sha256(clip.read_bytes()).hexdigest()},'failures':[]}
(out/'checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('BLUE_EVIDENCE_CHECKS',checks,'clip bytes',clip.stat().st_size)
