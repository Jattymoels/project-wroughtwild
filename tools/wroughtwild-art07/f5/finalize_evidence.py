"""Run original pixel/state assertions and lossless timelines on current F5 captures.
Original finalizers remain read-only; Red's historical output paths are adapted here.
"""
import sys,json,shutil,subprocess
from pathlib import Path
from PIL import Image,ImageSequence
import numpy as np
from audit import DEPOT,read,sha
package=Path(sys.argv[1]).resolve();build=package.parent
for colour in ['red','white','blue','green']:
    dest=package/colour/'evidence';assert not dest.exists();dest.mkdir()
    fresh=build/f'blender-{colour}-v02'
    shutil.copy2(fresh/'packed-reopen.png',dest/'packed-reopen.png')
    shutil.copy2(fresh/'blender-audit.json',dest/'blender-audit.json')
    # Keep historical checks separate; current Blender evidence has its own audit.
    if colour!='red':
        for name in ['native-checks.json','native-restart.json']:
            shutil.copy2(package/colour/'review/evidence'/name,dest/name)
        subprocess.run([sys.executable,str(DEPOT/f'tools/wroughtwild-{colour}/finalize_evidence.py'),
            str(package/colour/'review'),str(package/colour/'editable'),str(dest)],check=True)
    else:
        review=package/colour/'review';forward=review/'evidence';fallback=review/'evidence-compat'
        for folder in [forward,fallback]:
            checks=read(folder/'capture-checks.json');assert not checks['failures']
            rows={s['capture']:s for s in read(folder/'capture-state.json')}
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
            difference=np.abs(on-off);assert difference.max()>5 and np.count_nonzero(difference>5)>10
        userdata=package/'red/review-appdata/Godot/app_userdata/Wroughtwild ART-04 Red study'
        for name in ['native-checks.json','native-restart.json']:
            assert not read(userdata/name)['failures'];shutil.copy2(userdata/name,dest/name)
    # Both renderer clips, pixel-for-pixel verified over the complete timeline.
    count={'red':48,'white':48,'blue':64,'green':96}[colour]
    name={'red':'red-paid-firing','white':'white-request','blue':'blue-delay','green':'green-junction'}[colour]
    clips={}
    for renderer,folder in [('forward','evidence'),('compat','evidence-compat')]:
        source=package/colour/'review'/folder
        frames=[Image.open(source/(f'motion-{i:03d}.png' if colour=='red' else f'request-{i:02d}.png')).convert('RGB') for i in range(count)]
        path=dest/(renderer+'-'+name+'.webp')
        frames[0].save(path,save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,method=4)
        decoded=Image.open(path);elapsed=0;index=0
        for frame in ImageSequence.Iterator(decoded):
            frame.load();duration=int(frame.info['duration']);assert duration>0 and duration%125==0
            for held in range(duration//125):
                assert index<count and np.array_equal(np.array(frame.convert('RGB')),np.array(frames[index])),(colour,renderer,index)
                index+=1
            elapsed+=duration
        assert index==count and elapsed==count*125
        clips[renderer]={'source_frames':count,'duration_ms':elapsed,'lossless_exact':True,'sha256':sha(path),'bytes':path.stat().st_size}
    (dest/'f5-motion-checks.json').write_text(json.dumps(clips,indent=2),encoding='utf-8')
print('F5_ALL_RENDERED_STATE_PIXELS_AND_TIMELINES_PASS')
