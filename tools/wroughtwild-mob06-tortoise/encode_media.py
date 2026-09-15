"""Encode selected actual native frames; no generated imagery or asset editing."""
import json,sys
from pathlib import Path
from PIL import Image
src,dst=map(Path,sys.argv[1:]);paths=sorted((src/'frames').glob('*.png'))
assert len(paths)==270,('Incomplete native capture',len(paths))
dst.mkdir(parents=True,exist_ok=True)
frames=[Image.open(p).convert('RGB').resize((640,480),Image.Resampling.LANCZOS) for p in paths]
durations=[33,34,33]*90
frames[0].save(dst/'tortoise-motion.webp',save_all=True,append_images=frames[1:],duration=durations,loop=0,quality=78,method=4)
with Image.open(dst/'tortoise-motion.webp') as clip:
 assert clip.is_animated
 encoded_frames=clip.n_frames
 decoded_ms=0
 for i in range(encoded_frames):
  clip.seek(i);clip.load();decoded_ms+=clip.info['duration']
 # WebP coalesces identical consecutive images, including some held poses.
 # Preserve the exact source duration rather than requiring duplicate frames.
 assert decoded_ms==sum(durations)==9000,('Lost motion duration',decoded_ms)
(dst/'media.json').write_text(json.dumps({'captured_frames':270,'encoded_frames':encoded_frames,'duration_seconds':9,'dimensions':[640,480],'renderer':'Forward+','source':'native Enemy in flat capture fixture, fixed 60Hz physics; 30fps selected frames','segments':{'0-1.5':'native idle','1.5-5':'native pursuit of scripted moving target','5-8':'native windup and melee strikes','8-9':'native freeze'},'path':'tortoise-motion.webp','bytes':(dst/'tortoise-motion.webp').stat().st_size},indent=2)+'\n')
print('MEDIA_OK', (dst/'tortoise-motion.webp').stat().st_size)
