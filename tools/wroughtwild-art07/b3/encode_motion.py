"""Encode actual renderer frames; never synthesizes or interpolates model evidence."""
import sys,json
from pathlib import Path
from PIL import Image
root,out=[Path(p).resolve() for p in sys.argv[1:]];assert not out.exists();out.mkdir(parents=True)
for renderer in ['forward_plus','gl_compatibility']:
 paths=sorted((root/'review/evidence'/renderer).glob('pulse-*.png'));assert len(paths)==40
 frames=[Image.open(p).convert('RGB').resize((864,540),Image.Resampling.LANCZOS) for p in paths]
 frames[0].save(out/(renderer+'-pulse.gif'),save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True)
 native=root/'native/game/b3/evidence'/renderer
 paths=[native/'intact.png',native/'worked-wedge-half.png',native/'remnant-first-split.png']+sorted(native.glob('deplete-*.png'))+[native/'depleted.png'];assert len(paths)==22
 frames=[Image.open(p).convert('RGB').resize((864,540),Image.Resampling.LANCZOS) for p in paths]
 frames[0].save(out/(renderer+'-native-work.gif'),save_all=True,append_images=frames[1:],duration=[800,900,900]+[33]*18+[900],loop=0,optimize=True)
(out/'timing.json').write_text(json.dumps({'pulse':'40 actual Godot frames at 0.1 s cosmetic clock steps; 4 s loop, not benchmark FPS.','work':'Three held state views, 18 every-second 60 Hz native depletion frames, held empty final state. No invented tween frames.'},indent=2))
print('B3_MOTION_OK')
