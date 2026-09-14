"""Assemble labelled contact sheets/playback only from real R1 engine frames.
Original 1440x900 captures and timing records remain in the sealed evidence.
"""
import json,shutil
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageStat
from measure import ROOT,OUT,sha,write
E=OUT/'runtime/evidence';DEST=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r1';DEST.mkdir(parents=True,exist_ok=True)
records=[]
def source(p):
    with Image.open(p) as im:
        size=list(im.size);variance=ImageStat.Stat(im.convert('RGB').crop((0,min(100,im.height-1),im.width,im.height))).stddev
    assert max(variance)>.1,('Blank captured world/model below caption',str(p))
    return {'path':str(p),'sha256':sha(p),'pixels':size,'rgb_stddev_below_caption':variance}
def grid(name,paths,columns=2,width=720):
    pictures=[]
    for p in paths:
        with Image.open(p) as im:pictures.append(im.convert('RGB').resize((width,round(im.height*width/im.width)),Image.Resampling.LANCZOS))
    height=max(im.height for im in pictures);canvas=Image.new('RGB',(width*columns,height*((len(pictures)+columns-1)//columns)),(24,29,29))
    for i,im in enumerate(pictures):canvas.paste(im,((i%columns)*width,(i//columns)*height))
    dest=DEST/name;assert not dest.exists();canvas.save(dest,quality=91)
    records.append({'path':str(dest),'sha256':sha(dest),'sources':[source(p) for p in paths],'operation':'Resize and tile actual captured frames, in the listed row-major order. No generated or painted pixels.'})
def motion(name,paths,durations,scope):
    frames=[]
    for p in paths:
        with Image.open(p) as im:frames.append(im.convert('RGB').resize((960,round(im.height*960/im.width)),Image.Resampling.LANCZOS))
    dest=DEST/name;assert not dest.exists();frames[0].save(dest,save_all=True,append_images=frames[1:],duration=durations,loop=0,quality=84,method=4)
    records.append({'path':str(dest),'sha256':sha(dest),'sources':[source(p) for p in paths],'duration_ms':durations,'operation':scope})
for renderer in ['forward_plus','gl_compatibility']:
    studio=E/('r1-studio-v02-'+renderer)
    grid(renderer+'-canopy-pairs.jpg',[studio/'broadleaf-lod2.png',studio/'pine-lod2.png'],columns=1,width=1440)
    grid(renderer+'-all-lods.jpg',[studio/(kind+'-lod'+str(lod)+'.png') for kind in ['broadleaf','pine','broadleaf-b','pine-b','broadleaf-altered'] for lod in range(3)],columns=3,width=480)
    grid(renderer+'-scar-off-on.jpg',[studio/'scar-emission-off.png',studio/'scar-emission-on.png'])
    for view in ['home-player-height','route-player-height']:
        paths=[E/('r1-views-v02-'+mode+'-'+renderer)/(view+'-'+light+'.png') for light in ['day','shade','dusk'] for mode in ['before','after']]
        grid(renderer+'-'+view+'.jpg',paths)
    native=E/('r1-native-b1-after-'+renderer);trace=json.loads((native/'motion-times.json').read_text())
    items=trace['frames'];paths=[native/r['image'] for r in items]
    durations=[max(1,round((items[i+1]['physics_frame']-r['physics_frame'])*1000/trace['physics_ticks_per_second'])) if i+1<len(items) else 900 for i,r in enumerate(items)]
    durations[0]=650
    motion(renderer+'-native-fall.webp',paths,durations,'Actual native work/fall frames, paced from recorded physics frame intervals; first/last inspection pauses are 650/900 ms. Resized, no interpolation or synthesis.')
    motion(renderer+'-scar-pulse.webp',sorted(studio.glob('scar-motion-*.png')),[83]*48,'Actual altered model with existing shader clock explicitly stepped at 12 Hz; illustrative shader playback, not gameplay.')
route=E/'paid-art-forward_plus-r1-route-motion/walk';paths=sorted(route.glob('*.png'));assert paths
motion('native-route.webp',paths,[300]*len(paths),'Actual input/controller route captures every 18 physics ticks at 60 Hz; draw-wait capture pacing differs from the separate benchmark. Nominal 300 ms playback intervals, no interpolation.')
write(OUT/'evidence/image-provenance.json',records)
(DEST/'image-provenance.json').write_text(json.dumps(records,indent=2))
print('R1_ACTUAL_FRAME_ARTIFACTS',len(records))
