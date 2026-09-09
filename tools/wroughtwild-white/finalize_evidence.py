"""Validate actual state/frame evidence and publish selected unchanged captures.
Usage: REVIEW EDITABLE OUTPUT_DOCS. Frame encoding changes no source pixels.
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
for folder in ['evidence','evidence-compat']:
    data=json.loads((review/folder/'visual-checks.json').read_text());check(not data['failures'],folder+' visual failures')
    entries={e['file']:e for e in data['captures']}
    for filename in entries:check((review/folder/filename).is_file(),filename+' real capture exists')
    check(entries['source-claim.png']['view']['raw_claim']==16,'released native lot')
    check(entries['white-mineral.png']['view']['mineral_owned']==30,'native collection')
    check(entries['source-spent.png']['view']['mineral_owned']==126 and not entries['source-spent.png']['view']['source_ready'],'actual source exhaustion')
    check(not entries['post-idle.png']['view']['request_visible'],'no load replay')
    check(entries['post-unwound-request.png']['view']['request_visible'] and not entries['post-unwound-request.png']['view']['moving'],'request is not unpaid motion')
    check(not entries['post-signal-blocked.png']['view']['request_visible'],'obstructed request quiet')
    check(entries['post-request.png']['view']['cargo']==10 and entries['post-request.png']['view']['energy']==0,'real paid outbound')
    check(entries['post-request.png']['view']['request_age']==entries['post-request-paused.png']['view']['request_age'],'pause retains actual pulse phase')
    differences={}
    for a,b,region in [('source-ready.png','source-no-glow.png',(570,355,1000,760)),('post-request.png','post-request-no-glow.png',(560,340,1040,790))]:
        first=np.array(Image.open(review/folder/a).convert('RGB').crop(region),dtype=np.int16)
        second=np.array(Image.open(review/folder/b).convert('RGB').crop(region),dtype=np.int16)
        changed=int(np.any(first!=second,axis=2).sum());maximum=int(np.abs(first-second).max())
        check(changed>50 and maximum>10,a+' visibly changes actual asset pixels')
        differences[a]={'changed_pixels':changed,'maximum_channel_difference':maximum,'region':region}
    results[folder]={'visual_checks':data['checks'],'captures':len(entries),'renderer':data['renderer'],'rendered_light_differences':differences}
frames=[Image.open(review/'evidence'/f'request-{i:02d}.png').convert('RGB') for i in range(48)]
clip=out/'white-request.webp';frames[0].save(clip,save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,method=6)
decoded=Image.open(clip);timeline=[];elapsed=0
for frame in ImageSequence.Iterator(decoded):
    frame.load();duration=int(frame.info.get('duration',0));timeline.append((elapsed,elapsed+duration,np.array(frame.convert('RGB'))));elapsed+=duration
check(elapsed==6000,'six-second source frame timeline')
for i,frame in enumerate(frames):
    t=i*125;matching=[pixels for start,end,pixels in timeline if start<=t<end]
    check(len(matching)==1 and np.array_equal(np.array(frame),matching[0]),'decoded frame exactly matches actual engine image')
for name in ['source-ready','source-shade','source-no-glow','source-claim','source-spent','white-mineral','post-idle','post-request','post-request-paused','post-unwound-request','workshop-overview']:
    shutil.copy2(review/'evidence'/(name+'.png'),out/(name+'.png'))
shutil.copy2(editable/'editable-preview.png',out/'editable-preview.png')
shutil.copy2(review/'evidence/performance.json',out/'performance.json')
shutil.copy2(review/'provenance.json',out/'provenance.json')
report={'native':json.loads((review/'evidence/native-checks.json').read_text()),'restart':json.loads((review/'evidence/native-restart.json').read_text()),'assets':json.loads((editable/'asset-checks.json').read_text()),'renderers':results,'evidence_checks':checks,'clip':{'source_frames':48,'encoded_frames':len(timeline),'duration_ms':elapsed,'lossless_exact':True,'sha256':hashlib.sha256(clip.read_bytes()).hexdigest()},'failures':[]}
(out/'checks.json').write_text(json.dumps(report,indent=2))
print('WHITE_EVIDENCE_CHECKS',checks,'clip bytes',clip.stat().st_size)
