"""Check native state and actual pixels, then publish untouched renderer evidence.
Usage: REVIEW EDITABLE OUTPUT_DOCS. Lossless WebP retains each source frame.
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
    check(entries['green-resin.png']['view']['mineral_owned']==30,'native collected resin')
    check(entries['source-spent.png']['view']['mineral_owned']==126 and not entries['source-spent.png']['view']['source_ready'],'actual finite stock exhausted')
    check(entries['source-rare-held.png']['view']['rare_claim']==1 and entries['source-rare-held.png']['view']['raw_claim']==0,'rare-only source ownership exposed')
    initial=entries['junction-restored-idle.png']['view'];blocked=entries['upstream-blocked.png']['view']
    check(initial['blue_pending'] and initial['blue_elapsed']==.5 and initial['pulses']==1 and not initial['passage_visible'],'restored historical counter does not replay')
    check(blocked['blue_pending'] and blocked['blue_elapsed']==.5 and not blocked['passage_visible'],'upstream wall holds request')
    released=entries['request-20.png']['view']
    check(released['pulses']==2 and released['passage_visible'] and released['first_started'] and released['second_started'],'one native event starts both receivers')
    check(released['energy']==0 and released['feeder_energy']==0 and released['clay_escrow']==8 and released['fuel_escrow']==1 and released['drive_escrow']==1,'independent exact native payment')
    check(released['progress']==0 and released['feeder_progress']==0,'new jobs receive no pre-departure frame credit')
    complete=entries['feeder-complete.png']['view']
    check(complete['trips']==5 and complete['at_landing'] and complete['cargo']==10 and complete['bricks']==8 and complete['cycles']==2 and not complete['feeder_working'],'single actual cargo delivery and firing')
    unwound=entries['junction-unwound.png']['view']
    check(unwound['first_sent'] and unwound['second_sent'] and not unwound['first_started'] and not unwound['second_started'] and not unwound['moving'] and not unwound['feeder_working'],'clear signals cannot create unpaid work')
    check(unwound['passage_age']==entries['junction-passage-paused.png']['view']['passage_age'],'paused native passage holds')
    for branch in ['first','second','cargo','feeder']:
        v=entries[f'junction-{branch}-blocked.png']['view']
        check(v['first_sent']==(branch!='first') and v['second_sent']==(branch!='second'),'separate physical signal passage: '+branch)
        check(v['first_started']==(branch not in ['first','cargo']) and v['second_started']==(branch not in ['second','feeder']),'separate actual receiver payment: '+branch)
    held=entries['paid-work-blocked.png']['view']
    check(held['moving'] and held['feeder_working'] and held['feeder_progress']==1.25 and held['clay_escrow']==8 and held['cargo']==10,'blocked paid work retains ownership')
    differences={}
    for a,b,region in [('source-ready.png','source-no-glow.png',(530,340,1120,770)),('junction-unwound.png','junction-unwound-no-glow.png',(680,280,920,485)),('request-21.png','request-25.png',(690,280,915,485)),('junction-first-blocked.png','junction-second-blocked.png',(690,280,915,440))]:
        first=pixels(folder,a,region);second=pixels(folder,b,region)
        changed=int(np.any(first!=second,axis=2).sum());maximum=int(np.abs(first-second).max())
        check(changed>50 and maximum>10,a+' actual core pixels respond to source/native progression or branch')
        differences[a+' / '+b]={'changed_pixels':changed,'maximum_channel_difference':maximum,'region':region}
    region=(690,280,915,485)
    check(np.array_equal(pixels(folder,'junction-unwound.png',region),pixels(folder,'junction-passage-paused.png',region)),'pause keeps exact rendered resin pixels')
    # Compare each arm independently to the common no-emission baseline. The
    # branch walls are outside these tight core crops, so they cannot pass this.
    for branch,region in [('first',(728,309,795,389)),('second',(826,310,899,370))]:
        off=pixels(folder,'junction-unwound-no-glow.png',region)
        sent=pixels(folder,'junction-'+('second' if branch=='first' else 'first')+'-blocked.png',region)
        refused=pixels(folder,'junction-'+branch+'-blocked.png',region)
        sent_green=int(((sent[:,:,1]-off[:,:,1])>15).sum())
        refused_green=int(((refused[:,:,1]-off[:,:,1])>15).sum())
        check(sent_green>15 and refused_green<sent_green*.15,'only the clear '+branch+' resin arm emits')
        differences[branch+' arm']={'sent_green_pixels':sent_green,'blocked_green_pixels':refused_green,'region':region}
    results[folder]={'visual_checks':data['checks'],'captures':len(entries),'renderer':data['renderer'],'rendered_light_differences':differences,'paused_core_pixels_identical':True}
frames=[Image.open(review/'evidence'/f'request-{i:02d}.png').convert('RGB') for i in range(96)]
clip=out/'green-junction.webp';frames[0].save(clip,save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,method=6)
decoded=Image.open(clip);timeline=[];elapsed=0
for frame in ImageSequence.Iterator(decoded):
    frame.load();duration=int(frame.info.get('duration',0));timeline.append((elapsed,elapsed+duration,np.array(frame.convert('RGB'))));elapsed+=duration
check(elapsed==12000,'twelve-second original timeline')
for i,frame in enumerate(frames):
    matching=[p for start,end,p in timeline if start<=i*125<end]
    check(len(matching)==1 and np.array_equal(np.array(frame),matching[0]),'decoded frame equals original engine pixels')
for name in ['source-ready','source-shade','source-no-glow','source-claim','source-spent','source-rare-held','green-resin','junction-restored-idle','junction-idle','junction-unwound','junction-first-blocked','junction-second-blocked','feeder-complete','workshop-overview']:
    shutil.copy2(review/'evidence'/(name+'.png'),out/(name+'.png'))
shutil.copy2(review/'evidence/request-25.png',out/'junction-passage.png')
shutil.copy2(editable/'editable-preview.png',out/'editable-preview.png')
shutil.copy2(review/'evidence/performance.json',out/'performance.json');shutil.copy2(review/'provenance.json',out/'provenance.json')
report={'native':json.loads((review/'evidence/native-checks.json').read_text()),'restart':json.loads((review/'evidence/native-restart.json').read_text()),'assets':json.loads((editable/'asset-checks.json').read_text()),'renderers':results,'evidence_checks':checks,'clip':{'source_frames':96,'encoded_frames':len(timeline),'duration_ms':elapsed,'lossless_exact':True,'sha256':hashlib.sha256(clip.read_bytes()).hexdigest()},'failures':[]}
(out/'checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('GREEN_EVIDENCE_CHECKS',checks,'clip bytes',clip.stat().st_size)
