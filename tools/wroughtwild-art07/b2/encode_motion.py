"""Encode existing actual render frames, no invented/interpolated images."""
import sys,json
from pathlib import Path
from PIL import Image
review,out=map(Path,sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
for renderer in ['forward_plus','gl_compatibility']:
    paths=sorted((review/'evidence'/renderer).glob('motion-*.png'));assert len(paths)==144
    frames=[Image.open(p).convert('RGB').resize((768,540),Image.Resampling.LANCZOS) for p in paths[::2]]
    frames[0].save(out/(renderer+'-walk-wind.gif'),save_all=True,append_images=frames[1:],duration=167,loop=0,optimize=True)
    frames[0].save(out/(renderer+'-walk-wind.webp'),save_all=True,append_images=frames[1:],duration=167,loop=0,quality=85,method=4)
(out/'timing.json').write_text(json.dumps({'source_fps':12,'encoded_fps':6,'route_seconds':8,'close_seconds':4,'pause_last_seconds':2,'note':'Actual offline camera/clock samples; no interpolation, not measured playback FPS.'},indent=2))
