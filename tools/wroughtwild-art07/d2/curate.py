"""Copy unretouched model evidence and encode the actual ordered capture frames."""
import argparse,hashlib,json,shutil
from pathlib import Path
from PIL import Image
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); a=ap.parse_args()
root=Path(__file__).resolve().parents[3]; out=root/'docs/art/leyline-studies/2026-09-09/art07/d2'; out.mkdir(parents=True,exist_ok=True)
for mode in ['material','neutral']: shutil.copy2(a.models/'evidence'/('blender-'+mode+'.png'),out/('blender-'+mode+'.png'))
media={}
for renderer in ['forward_plus','gl_compatibility']:
    source=a.build/'snapshot/game/art07_d2/evidence'/renderer/'v03'
    for name in ['catalogue-material','joins-material','valley-contact','door-closed','door-open','ceiling-underside']:
        shutil.copy2(source/(name+'.png'),out/(renderer+'-'+name+'.png'))
    frames=[]
    for p in sorted(source.glob('motion-*.png')):
        # Media-size conversion only: no generative frames, retouch or interpolation.
        frames.append(Image.open(p).convert('RGB').resize((960,600),Image.Resampling.LANCZOS))
    assert len(frames)==48
    path=out/(renderer+'-door-motion.webp'); frames[0].save(path,save_all=True,append_images=frames[1:],duration=83,loop=0,lossless=False,quality=86,method=6)
    with Image.open(path) as im: assert im.n_frames==48
    states=json.loads((source/'motion-states.json').read_text())
    assert [i['open'] for i in states]==[True]*12+[False]*24+[True]*12
    assert all(i['visual']==i['collision'] for i in states)
    shutil.copy2(source/'motion-states.json',out/(renderer+'-motion-states.json'))
    media[renderer]={'frames':48,'display_duration_ms':3984,'encoding':'960x600 WebP quality 86; original 1440x900 PNGs retained','source_frames':str(source),'events':'Native E switch at frames 12 and 36; no tween invented; slight camera orbit','hash':hashlib.sha256(path.read_bytes()).hexdigest()}
(out/'media.json').write_text(json.dumps(media,indent=2)+'\n')
print('D2_CURATED_ACTUAL_MEDIA_OK',out)
