"""Select actual engine captures; only the silent GIF is reduced for sharing."""
from pathlib import Path
import json, shutil
from PIL import Image
root=Path(__file__).resolve().parents[2]
out=root/'build/rf06'
report=json.loads((out/'walk-checks.json').read_text())
assert report['failures']==0
media=out/'media'
evidence=root/'docs/prototype/rf06-evidence-2026-09-16'
evidence.mkdir(parents=True,exist_ok=True)
for name in ['01-fen-ground.png','02-fen-opening.png','03-lakeside-home.png','04-water-and-bank.png','05-planted-bank.png']:
    shutil.copy2(media/name,evidence/name)
frames=[]
for i in range(report['captured_frames']):
    with Image.open(media/f'swim-{i:03d}.jpg') as im:
        frames.append(im.resize((640,360),Image.Resampling.LANCZOS))
if frames:
    swatch=Image.new('RGB',(320*5,180))
    for i in range(5):swatch.paste(frames[i*len(frames)//5].resize((320,180)),(i*320,0))
    palette=swatch.quantize(colors=256)
    frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
    frames[0].save(evidence/'shore-walk.gif',save_all=True,append_images=frames[1:],duration=([60,70,70]*40)[:len(frames)],loop=0,optimize=False)
for name in ['placement-checks.json','continue-checks.json','walk-checks.json','expected.json']:
    shutil.copy2(out/name,evidence/name)
print(evidence)
