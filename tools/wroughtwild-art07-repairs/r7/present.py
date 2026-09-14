"""Resize/tile or encode actual R7 frames; never paint, synthesize or interpolate evidence."""
import shutil
from PIL import Image,ImageStat
from common import *
guard();E=OUT/'runtime/evidence';B=OUT/'evidence/r1-comparison'
DEST=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r7';DEST.mkdir(parents=True,exist_ok=True)
records=[]
def source(p):
    with Image.open(p) as im:
        size=list(im.size);variance=ImageStat.Stat(im.convert('RGB').crop((0,min(100,im.height-1),im.width,im.height))).stddev
    assert max(variance)>.1,('Blank capture below caption',str(p))
    return {'path':str(p),'sha256':sha(p),'pixels':size,'rgb_stddev_below_caption':variance}
def grid(name,paths):
    pictures=[]
    for p in paths:
        with Image.open(p) as im:pictures.append(im.convert('RGB').resize((720,450),Image.Resampling.LANCZOS))
    canvas=Image.new('RGB',(1440,450*((len(pictures)+1)//2)))
    for i,im in enumerate(pictures):canvas.paste(im,((i%2)*720,(i//2)*450))
    dest=DEST/name;assert not dest.exists();canvas.save(dest,quality=94)
    records.append({'path':str(dest),'sha256':sha(dest),'sources':[source(p) for p in paths],'pixels':list(canvas.size),'operation':'Lanczos resize to 720 x 450 and row-major tiling. Left is executed R1 parent, right is V02 R7. JPEG94 encoding; original 1440 x 900 PNGs remain sealed. No painted/generated pixels.'})
def motion(name,paths,durations,scope):
    frames=[]
    for p in paths:
        with Image.open(p) as im:frames.append(im.convert('RGB').resize((960,600),Image.Resampling.LANCZOS))
    dest=DEST/name;assert not dest.exists();frames[0].save(dest,save_all=True,append_images=frames[1:],duration=durations,loop=0,quality=88,method=4)
    records.append({'path':str(dest),'sha256':sha(dest),'sources':[source(p) for p in paths],'pixels':[960,600],'duration_ms':durations,'operation':scope+' Lanczos resize and WebP88 encoding only; all original PNGs retained.'})
for renderer in ['forward_plus','gl_compatibility']:
    before=B/('r7-views-before-'+renderer);after=E/('r7-views-after-'+renderer)
    grid(renderer+'-habitat-pair.jpg',[before/'habitat-player-height-day.png',after/'habitat-player-height-day.png'])
    for light in ['day','shade','dusk']:
        grid(renderer+'-'+light+'-pairs.jpg',[base/(view+'-'+light+'.png') for view in ['home-player-height','route-player-height','clearing-player-height','habitat-player-height'] for base in [before,after]])
    grid(renderer+'-distance-pairs.jpg',[base/('distance-'+distance+'.png') for distance in ['2.5','18.0','72.0'] for base in [before,after]])
    rows=read(after/'motion.json')['frames'];durations=[rows[i+1]['wall_msec']-r['wall_msec'] for i,r in enumerate(rows[:-1])];durations.append(durations[-1]);assert min(durations)>0
    motion(renderer+'-rooted-sway.webp',[after/r['file'] for r in rows],durations,'Actual live environment-clock frames with recorded wall-time intervals, including capture overhead. Last duration repeats previous interval. No interpolation, animated source geometry or synthetic camera movement.')
    for name in ['habitat-player-height-day.png','distance-2.5.png']:
        dest=DEST/(renderer+'-'+name);assert not dest.exists();shutil.copy2(after/name,dest)
        records.append({'path':str(dest),'sha256':sha(dest),'sources':[source(after/name)],'operation':'Byte-identical selected full-resolution PNG'})
route=E/'paid-art-forward_plus-r7-route-motion/walk';paths=sorted(route.glob('*.png'));assert len(paths)>20
motion('native-route.webp',paths,[300]*len(paths),'Actual controller-input route frames captured every 18 movement physics ticks at 60 Hz. Nominal 300 ms display intervals; drawing/capture adds unmeasured pacing between captures, so this is not a realtime timing record or camera animation.')
ref=ROOT/'docs/art/concepts/environment/2026-09-09-frontier/01-world-keyframe.png';dest=DEST/'selected-fullness-reference.png';assert not dest.exists();shutil.copy2(ref,dest)
records.append({'path':str(dest),'sha256':sha(dest),'sources':[source(ref)],'operation':'Unchanged previously generated concept reference, not an engine capture or approved new geography.'})
write(OUT/'evidence/image-provenance.json',records);write(DEST/'image-provenance.json',records)
print('R7_ACTUAL_FRAME_ARTIFACTS',len(records))
