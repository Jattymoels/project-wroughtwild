"""Assemble existing engine viewport frames into a short shareable motion GIF."""
from pathlib import Path
from PIL import Image
repo=Path(__file__).resolve().parents[2]
out=repo/'docs/art/mob01-porcupine-2026-09-15'
out.mkdir(exist_ok=True)
frames=[]
for p in sorted((repo/'build/mob01/frames').glob('*.png')):
 with Image.open(p) as im: frames.append(im.resize((768,576),Image.Resampling.LANCZOS).convert('P',palette=Image.Palette.ADAPTIVE,colors=128))
assert len(frames)==100
frames[0].save(out/'porcupine-motion.gif',save_all=True,append_images=frames[1:],duration=[30 if i%3 else 40 for i in range(len(frames))],loop=0,optimize=True)
import shutil
for name in ['porcupine-idle.png','porcupine-brace.png']:shutil.copy2(repo/'build/mob01'/name,out/name)
print('MOB01_MOTION',len(frames),'frames, native movement/windup/release, 3.34 seconds')
