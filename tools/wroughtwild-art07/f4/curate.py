"""Encode actual render frames without changing scene content; retain originals."""
import json,sys,hashlib
from pathlib import Path
from PIL import Image
review,reopen,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
for renderer in ['forward_plus','gl_compatibility']:
 folder=review/'evidence'/renderer
 for name in ['01-pocket-full','03-paid-firing','07-rear-emission-off','07-shade','08-both-attachments','11-completed-tray','14-exhausted-reload']:
  Image.open(folder/(name+'.png')).save(out/(renderer+'-'+name+'.webp'),lossless=True)
 frames=[Image.open(folder/('motion-%03d.png'%i)).convert('RGB').resize((1200,675),Image.Resampling.LANCZOS) for i in range(60)]
 frames[0].save(out/(renderer+'-native-motion.webp'),save_all=True,append_images=frames[1:],duration=33,loop=0,quality=88,method=4)
 evidence=json.loads((folder/'checks.json').read_text())['frames']
 assert len(evidence)==60
 assert all(f['working'] for f in evidence[:30]) and not any(f['working'] for f in evidence[30:])
 for a,b in [(30,45),(45,60)]:
  assert all(f['native']==evidence[a]['native'] and f['drum']==evidence[a]['drum'] for f in evidence[a:b])
 assert evidence[0]['drum']!=evidence[29]['drum']
for kind in ['feeder','pocket']:
 for mode in ['material','clay']:
  Image.open(reopen/(kind+'_near-'+mode+'-three-quarter.png')).save(out/('blender-'+kind+'-'+mode+'.webp'),lossless=True)
files=[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.iterdir())]
(out/'evidence.json').write_text(json.dumps({'source_review':str(review),'source_reopen':str(reopen),'motion':'60 actual frames, 30 paid-work native ticks, 15 paused, 15 real physics-blocked; 1200x675 review encode, 33ms per frame, quality 88. Original 1600x900 PNGs and native ledgers retained in package.','files':files},indent=2)+'\n');print('F4_EVIDENCE_OK',len(files))
