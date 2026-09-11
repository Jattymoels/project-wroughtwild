"""Encode original rendered frames for chat; no synthetic motion frames."""
import sys,json
from pathlib import Path
from PIL import Image,ImageChops
review,out=[Path(p).resolve() for p in sys.argv[1:3]];assert not out.exists();out.mkdir(parents=True);report={}
for renderer in ['forward_plus','gl_compatibility']:
 source=review/'evidence'/renderer
 for prefix,fps in [('wind',12),('pulse',12),('orbit',9)]:
  paths=sorted(source.glob(prefix+'-*.png'));assert len(paths)>=36
  frames=[Image.open(p).convert('RGB') for p in paths];different=any(ImageChops.difference(frames[0],f).getbbox() for f in frames[1:]);assert different,(renderer,prefix)
  frames=[f.resize((864,540),Image.Resampling.LANCZOS) for f in frames];frames[0].save(out/(renderer+'-'+prefix+'.webp'),save_all=True,append_images=frames[1:],duration=round(1000/fps),loop=0,quality=84)
  report[renderer+'-'+prefix]={'actual_frames':len(paths),'fps':fps,'motion_difference':different}
 paused=[Image.open(p).convert('RGB') for p in sorted(source.glob('paused-*.png'))];assert len(paused)==8 and all(ImageChops.difference(paused[0],f).getbbox() is None for f in paused)
 report[renderer+'-pause']={'byte_visual_invariance':True,'frames':len(paused)}
 if len(sys.argv)>3:
  native=Path(sys.argv[3]).resolve()/'c2/evidence'/renderer
  frames=[Image.open(p).convert('RGB') for p in sorted(native.glob('deplete-*.png'))];assert len(frames)==12
  # Exclude the changing frame-name caption; certify motion in the rendered scene.
  region=(0,100,frames[0].width,frames[0].height)
  different=any(ImageChops.difference(frames[0].crop(region),f.crop(region)).getbbox() for f in frames[1:]);assert different
  frames=[f.resize((864,486),Image.Resampling.LANCZOS) for f in frames];frames[0].save(out/(renderer+'-native-depletion.webp'),save_all=True,append_images=frames[1:],duration=83,loop=0,quality=84)
  report[renderer+'-native-depletion']={'actual_frames':12,'fps':12,'motion_difference':different,'scope':'Native shrink and session-only aftermath, no synthetic frames.'}
(out/'motion-verification.json').write_text(json.dumps(report,indent=2)+'\n');print('C2_MOTION_PIXELS_OK')
