"""Keep three engine stills and one eight-second animated walking clip.
Run with the bundled Python (Pillow); no asset generation or visual alterations.
"""
from pathlib import Path
import json, shutil
from PIL import Image
root=Path(__file__).resolve().parents[2]
out=root/'build/rf03'
report=json.loads((out/'walk-checks.json').read_text())
assert report['failures']==0 and report['route_complete']
assert report['captured_frames']==120 and report['clip_fps']==15
media=out/'media'
evidence=root/'docs/prototype/rf03-evidence-2026-09-15'
evidence.mkdir(parents=True,exist_ok=True)
for name in ['01-woodland-pocket.png','02-meadow-approach.png','03-overlook-home.png']:
    shutil.copy2(media/name,evidence/name)
frames=[]
for i in range(120):
    with Image.open(media/f'walk-{i:03d}.jpg') as im:
        frames.append(im.resize((640,360),Image.Resampling.LANCZOS))
# One palette avoids per-frame adaptive-palette flicker. GIF supports 10ms steps;
# 60/70/70 repeated preserves the exact eight-second duration at 15 fps.
swatch=Image.new('RGB',(320*5,180))
for i in range(5):swatch.paste(frames[i*24].resize((320,180)),(i*320,0))
palette=swatch.quantize(colors=256)
frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
frames[0].save(evidence/'walk.gif',save_all=True,append_images=frames[1:],duration=[60,70,70]*40,loop=0,optimize=False)
with Image.open(evidence/'walk.gif') as clip:
    duration=0
    for i in range(clip.n_frames):clip.seek(i);duration+=clip.info['duration']
    assert duration==8000 and clip.n_frames==120
print('Selected three actual stills and 120-frame / 8-second silent walking GIF:',evidence)
