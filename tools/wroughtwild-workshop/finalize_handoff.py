"""Encode actual frames, retain selected evidence and refresh the checked manifest.
Run only after the packaged project passes import/check/restart/capture in both
renderers and benchmark. The animated WebP is a six-second replay, not a claim
that a success animation loops in gameplay.
"""
import sys,json,hashlib,shutil
from pathlib import Path
from PIL import Image
import numpy as np
package=Path(sys.argv[1]).resolve();repo=Path(__file__).resolve().parents[2]
review=package/'review';evidence=review/'evidence';fallback=review/'evidence-compat'
docs=repo/'docs/art/leyline-studies/2026-09-09/workshop-art04'
checks=package/'checks';checks.mkdir(exist_ok=True)
userdata=package/'review-appdata/Godot/app_userdata/Wroughtwild ART-04 Red study'
reports={}
for key,path in [('native',userdata/'native-checks.json'),('restart',userdata/'native-restart.json'),('assets',package/'editable/asset-checks.json'),('forward',evidence/'capture-checks.json'),('compatibility',fallback/'capture-checks.json')]:
    report=json.loads(path.read_text(encoding='utf-8'))
    assert report['failures']==[],(key,report)
    reports[key]=report;shutil.copy2(path,checks/(key+'.json'))
for folder in [evidence,fallback]:
    states=json.loads((folder/'capture-state.json').read_text(encoding='utf-8'));rows={s['capture']:s for s in states}
    assert rows['05-source-released-claim']['raw_claim']==16
    assert rows['06-source-spent']['raw_claim']==0 and not rows['06-source-spent']['source_ready']
    assert rows['07-recovered-fragments']['salt_owned']==18
    assert not rows['11-thermal-obstruction']['physical_ready'] and rows['11-thermal-obstruction']['progress']==3.25
    assert rows['12-buffer-paused']['progress']==3.25 and not rows['12-buffer-paused']['working']
    assert rows['13-paid-firing-complete']['output']==12 and rows['13-paid-firing-complete']['heat']==3
    assert rows['14-recovered-salt-stored']['heat']==4 and rows['14-recovered-salt-stored']['salt_owned']==16
    assert rows['18-native-rare-only-claim']['raw_claim']==0 and rows['18-native-rare-only-claim']['rare_claim']==1
    assert rows['motion-047']['output']==12 and not rows['motion-047']['working']
    on=np.asarray(Image.open(folder/'02-source-ready-day.png').convert('RGB')).astype(np.int16)[260:700,500:1080]
    off=np.asarray(Image.open(folder/'03-source-light-off.png').convert('RGB')).astype(np.int16)[260:700,500:1080]
    difference=np.abs(on-off)
    assert difference.max()>5 and np.count_nonzero(difference>5)>10,'Source core did not change in the actual rendered region'
frames=[Image.open(evidence/f'motion-{i:03d}.png').convert('RGB') for i in range(48)]
frames[0].save(evidence/'paid-firing.webp',save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,quality=100,method=6)
animation=Image.open(evidence/'paid-firing.webp')
# WebP legitimately coalesces identical held frames. Verify every decoded pixel
# and the complete six-second timeline, rather than mistaking codec frame count
# for simulation frames. No dropped time or changed image may pass this check.
source_frame=0;duration_ms=0
for encoded_frame in range(animation.n_frames):
    animation.seek(encoded_frame);decoded=animation.convert('RGB')
    duration=int(animation.info['duration']);assert duration>0 and duration%125==0
    duration_ms+=duration
    for held_frame in range(duration//125):
        assert source_frame<len(frames)
        assert np.array_equal(np.asarray(decoded),np.asarray(frames[source_frame])),('Preview changed source frame',source_frame)
        source_frame+=1
assert source_frame==48 and duration_ms==6000
selection={'02-source-ready-day.png':'source-ready.png','05-source-released-claim.png':'source-claim.png','06-source-spent.png':'source-spent.png','07-recovered-fragments.png':'red-salt.png','10-buffer-real-firing.png':'buffer-working.png','12-buffer-paused.png':'buffer-paused.png','15-chain-complete.png':'workshop-overview.png','paid-firing.webp':'red-paid-firing.webp'}
for source,name in selection.items():shutil.copy2(evidence/source,docs/name)
shutil.copy2(package/'editable/editable-preview.png',docs/'editable-preview.png')
shutil.copy2(review/'provenance.json',docs/'provenance.json')
shutil.copy2(evidence/'performance.json',docs/'performance.json')
summary={'native_checks':reports['native']['checks'],'fresh_process_checks':reports['restart']['checks'],'asset_checks':reports['assets']['checks'],'forward_visual_checks':reports['forward']['visual_checks'],'compatibility_visual_checks':reports['compatibility']['visual_checks'],'captures_per_renderer':reports['forward']['captures'],'failures':[], 'independent_capture_state_assertions_per_renderer':9,'rendered_core_difference_checked_in_both_renderers':True,'preview':{'frames':48,'encoded_frames':animation.n_frames,'frame_duration_ms':125,'duration_seconds':6,'lossless_pixels_and_complete_timeline_verified':True,'description':'Encoded actual native-state engine frames; replay restarts the recorded checkpoint, not an infinite native production loop.'}}
(docs/'checks.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
(checks/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
def included(path):
    rel=path.relative_to(package)
    return path.is_file() and path.name!='manifest.json' and not any(p in ['.godot','review-appdata','__pycache__'] for p in rel.parts) and not path.name.endswith(('.import','.uid','.blend1','.pyc')) and '_Image_' not in path.name
manifest={p.relative_to(package).as_posix():{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in sorted(package.rglob('*')) if included(p)}
(package/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for name,record in manifest.items():assert hashlib.sha256((package/name).read_bytes()).hexdigest()==record['sha256']
print('ART04_FINAL_HANDOFF_VERIFIED',len(manifest),'files',sum(r['bytes'] for r in manifest.values()),'bytes',json.dumps(summary))
