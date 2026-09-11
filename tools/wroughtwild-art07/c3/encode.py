"""Curate unmodified model frames and encode sampled actual motion, no interpolation."""
import json,sys,shutil
from pathlib import Path
from PIL import Image,ImageChops
import numpy as np
kit,review,native,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
assert not out.exists();out.mkdir(parents=True)
report={}
for path in kit.glob('*.png'):shutil.copy2(path,out/('blender-'+path.name))
for renderer in ['forward_plus','gl_compatibility']:
    folder=review/'evidence'/renderer
    for name in ['day','shade','dusk','incision-off','incision-on','cork-full','cork-worked','lod-0','lod-1','lod-2','full-width-source','hero-incision-off','hero-incision-on']:
        shutil.copy2(folder/(name+'.png'),out/(renderer+'-'+name+'.png'))
    motion={}
    for prefix in ['pulse','wind','walk']:
        paths=sorted(folder.glob(prefix+'-*.png'));assert len(paths)>=24
        original=[Image.open(p).convert('RGB') for p in paths]
        # Fixed captions; crop only the common top label area for motion evidence.
        arrays=[np.asarray(im)[80:].astype(np.int16) for im in original]
        difference=max(float(np.mean(np.abs(a-arrays[0]))) for a in arrays[1:])
        assert difference>0,(renderer,prefix,'no actual model motion')
        frames=[]
        for im in original[::2]:
            im.thumbnail((800,563));frames.append(im)
        frames[0].save(out/(renderer+'-'+prefix+'.webp'),save_all=True,append_images=frames[1:],duration=167 if prefix!='walk' else 400,loop=0,quality=82)
        motion[prefix]={'source_frames':len(paths),'max_mean_pixel_difference':difference}
    paused=[Image.open(p).convert('RGB') for p in sorted(folder.glob('paused-*.png'))]
    assert len(paused)==12 and all(ImageChops.difference(paused[0],im).getbbox() is None for im in paused[1:])
    for name in ['full','partial','bark-six-remain','cork-depleting','amber-stump']:
        shutil.copy2(native/'c3/evidence'/renderer/(name+'.png'),out/(renderer+'-native-'+name+'.png'))
    frames=[Image.open(p).convert('RGB') for p in sorted((native/'c3/evidence'/renderer).glob('fall-*.png'))]
    assert len(frames)==42
    for im in frames:im.thumbnail((800,563))
    frames[0].save(out/(renderer+'-native-fall.webp'),save_all=True,append_images=frames[1:],duration=34,loop=0,quality=82)
    report[renderer]={'motion':motion,'paused_identical_frames':len(paused),'native_fall_frames':len(frames)}
(out/'media-verification.json').write_text(json.dumps(report,indent=2)+'\n')
print('C3_MEDIA_OK')
