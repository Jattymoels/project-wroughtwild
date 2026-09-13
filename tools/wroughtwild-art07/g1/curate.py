"""Copy actual renderer images and encode their ordered frames for remote review."""
import json
import shutil
import sys
from pathlib import Path
from PIL import Image
from verify_inputs import digest

old,new,out=map(Path,sys.argv[1:])
out.mkdir(parents=True,exist_ok=True)
images={
 'godot-home-forward.png':old/'pilot/evidence/views-art-forward_plus/paid-home-day.png',
 'godot-home-compatibility.png':old/'pilot/evidence/views-art-gl_compatibility/paid-home-day.png',
 'godot-interior.png':old/'pilot/evidence/views-art-forward_plus/paid-interior-day.png',
 'godot-catalogue.png':new/'handoff/evidence/catalogue-forward_plus/wood.png',
 'godot-feeder.png':new/'handoff/evidence/forward_plus/03-paid-firing.png',
 'godot-exhausted.png':new/'handoff/evidence/forward_plus/14-exhausted-reload.png',
 'blender-material.png':new/'handoff/blender/material.png',
 'blender-clay.png':new/'handoff/blender/clay.png',
}
report={'images':{},'motion':{}}
for name,source in images.items():
 shutil.copy2(source,out/name)
 report['images'][name]={'source':str(source.resolve()),'sha256':digest(source),'dimensions':list(Image.open(source).size)}
for name,folder,duration in [
 ('paid-route.webp',old/'pilot/evidence/paid-art-forward_plus-walk-review/walk',300),
 ('native-feeder.webp',new/'handoff/evidence/forward_plus',33),
 ('native-feeder-compatibility.webp',new/'handoff/evidence/gl_compatibility',33)]:
 paths=sorted(folder.glob('motion-*.png' if 'feeder' in name else '*.png'))
 assert len(paths)>=20,(name,len(paths))
 frames=[]
 for path in paths:
  with Image.open(path) as im:
   im=im.convert('RGB');im.thumbnail((1024,640));frames.append(im.copy())
 frames[0].save(out/name,save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=78,method=4)
 report['motion'][name]={'frames':[{'file':str(p.resolve()),'sha256':digest(p)} for p in paths],'playback_frame_ms':duration,'dimensions':list(frames[0].size),'sha256':digest(out/name),'scope':'Actual ordered Godot frame sequence, resized and WebP encoded only; no synthetic or interpolated frames. Route playback cadence is illustrative, not a frame-time benchmark. Feeder frames follow native 30 Hz test ticks, including held pause and blocked states.'}
(out/'media.json').write_text(json.dumps(report,indent=2))
print('G1_MEDIA_CURATED',len(images),len(report['motion']))
