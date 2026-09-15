"""Retain two actual viewport stills, an eight-second clip and focused reports."""
from pathlib import Path
from PIL import Image
import json,shutil
repo=Path(__file__).resolve().parents[2]
evidence=repo/'build/mob03/evidence'
retained=repo/'game/tests/mob03/evidence'
retained.mkdir(exist_ok=True)
paths=sorted((evidence/'frames').glob('*.png'));assert len(paths)==160
frames=[]
# A fixed palette avoids palette shimmer; only resize the real viewport frames.
palette=Image.open(paths[94]).convert('RGB').resize((825,570)).quantize(colors=192)
for path in paths:
 im=Image.open(path).convert('RGB').resize((825,570),Image.Resampling.LANCZOS)
 frames.append(im.quantize(palette=palette,dither=Image.Dither.NONE))
clip=retained/'crane-motion.gif'
frames[0].save(clip,save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=True,disposal=1)
with Image.open(clip) as movie:
 total=0
 for index in range(movie.n_frames):
  movie.seek(index);total+=movie.info.get('duration',0)
 assert total==8000 and movie.size==(825,570)
for name in ['crane-idle.png','crane-call.png','state-report.json','capture-report.json','rig-report.json']:
 shutil.copy2(evidence/name,retained/name)
(retained/'motion-report.json').write_text(json.dumps({'source':'One Forward+ viewport sequence using the actual selected GLB','source_frames':160,'source_fps':20,'duration_ms':total,'gif_bytes':clip.stat().st_size,'dimensions':[825,570],'segments':['0-2 idle','2-4.4 walk','4.4-5.65 call','5.8-6.3 windup','6.3-6.6 peck','6.6-8 idle'],'pointer':'Visible throughout; no-focus window flag asserted; owning renderer exited before mutex release'},indent=2)+'\n')
print('MOB03_MOTION_RETAINED',clip,clip.stat().st_size,total)
