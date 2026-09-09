"""Encode actual Godot frames; never fabricates or retouches asset appearance.

REVIEW wolf|stag NEW_OUTPUT. Full motion is WebP; compact GIF is an inline preview.
"""
import json, shutil, sys
from pathlib import Path
from PIL import Image

review, kind, output = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])
assert kind in ('wolf', 'stag') and not output.exists()
output.mkdir(parents=True)
source = review / 'evidence'
stills = ['day-0', 'day-3', 'shade-0', 'shade-3', 'pose-turn', 'turn-opposite',
          'view-side', 'view-right']
far_views=sorted(source.glob('lod-far-*.png'),key=lambda p:float(p.stem.removeprefix('lod-far-')))
assert far_views
stills.append(far_views[-1].stem)
stills += ['pose-jaw', 'jaw-close--1.0', 'jaw-close-1.0'] if kind == 'wolf' else ['pose-graze']
for name in stills:
    shutil.copy2(source / (name+'.png'), output / (name+'.png'))
motions = [('day',24,192), ('shade',24,192), ('jaw' if kind == 'wolf' else 'graze',12,144)]
records=[]
for name,fps,count in motions:
    files=sorted(source.glob(name+'-frame-*.png'))
    assert len(files)==count, (name,len(files))
    frames=[]
    for file in files:
        with Image.open(file) as image: frames.append(image.convert('RGB').resize((800,600),Image.Resampling.LANCZOS))
    durations=[round((i+1)*1000/fps)-round(i*1000/fps) for i in range(count)]
    frames[0].save(output/(name+'.webp'),save_all=True,append_images=frames[1:],duration=durations,loop=0,quality=86,method=4)
    # Use a stable global palette to avoid palette flicker in the small preview.
    if name == ('day' if kind == 'wolf' else 'graze'):
        chosen=frames[::2] if fps==24 else frames
        thumb=[im.resize((640,480),Image.Resampling.LANCZOS) for im in chosen]
        sample=Image.new('RGB',(640,480*6))
        for i in range(6):sample.paste(thumb[i*len(thumb)//6],(0,i*480))
        palette=sample.quantize(colors=128)
        indexed=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in thumb]
        delay=[(round((i+1)*100/12)-round(i*100/12))*10 for i in range(len(indexed))]
        indexed[0].save(output/'preview.gif',save_all=True,append_images=indexed[1:],duration=delay,loop=0,disposal=2,optimize=False)
    records.append({'name':name,'source_frames':count,'fps':fps,'duration_seconds':count/fps,'webp_size':[800,600]})
for name in ['engine-checks.json','capture-setup.json','performance.json']:
    shutil.copy2(source/name,output/name)
shutil.copy2(review/'verification.json',output/'verification.json')
(output/'encoding.json').write_text(json.dumps({'source':str(source),'clips':records,'note':'Deterministically sampled Godot frames, resized and encoded only. GIF preview is 12 fps; full WebP retains the captured rate. This is not a measured game frame rate.'},indent=2)+'\n',encoding='utf-8')
print('FAUNA_EVIDENCE_ENCODED',kind)
