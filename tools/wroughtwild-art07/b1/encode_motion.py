"""Encode actual captured frames; no synthetic frames or image generation."""
import sys,json
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw
review,native,out=map(Path,sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
for renderer in ['forward_plus','gl_compatibility']:
 folder=review/'evidence'/renderer
 for label,prefix,step,duration in [('canopy-motion','motion-',2,167)]:
  paths=sorted(folder.glob(prefix+'*.png'))[::step];assert len(paths)==66
  frames=[Image.open(p).convert('RGB').resize((720,450),Image.Resampling.LANCZOS) for p in paths]
  frames[0].save(out/(renderer+'-'+label+'.webp'),save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=83,method=4)
  frames[0].save(out/(renderer+'-'+label+'.gif'),save_all=True,append_images=frames[1:],duration=duration,loop=0,optimize=True)
 folder=native/'game/b1/evidence'/renderer
 paths=[folder/'full-partial.png']+sorted(folder.glob('fall-*.png'))+[folder/'stumps.png'];assert len(paths)==44
 frames=[Image.open(p).convert('RGB').resize((720,450),Image.Resampling.LANCZOS) for p in paths]
 frames[0].save(out/(renderer+'-native-felling.gif'),save_all=True,append_images=frames[1:],duration=[650]+[33]*42+[900],loop=0,optimize=True)
(out/'timing.json').write_text(json.dumps({'canopy':'Every second actual capture: 6 fps, 6.9 s camera pass plus 4 s pulse. Offline clock samples, not benchmark FPS.','native':'Actual native .9 s fall + .25 s hold, captured every 2 fixed 60 Hz physics frames. Intro/stump held for review. No interpolated frames.'},indent=2))
