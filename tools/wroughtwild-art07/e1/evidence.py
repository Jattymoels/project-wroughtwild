"""Curate actual Blender/Godot media; preserve raw frames in the local handoff."""
import json,shutil,sys
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw
from inputs import ROOT,sha
build=Path(sys.argv[1]).resolve();out=ROOT/'docs/art/leyline-studies/2026-09-09/art07/e1'
out.mkdir(parents=True,exist_ok=True)
def sheet(paths,labels,name):
 canvas=Image.new('RGB',(1400,760),(30,32,31));draw=ImageDraw.Draw(canvas)
 for i,(p,label) in enumerate(zip(paths,labels)):
  im=Image.open(p).convert('RGB');im.thumbnail((700,700));canvas.paste(im,(700*i+(700-im.width)//2,35))
  draw.text((700*i+18,12),label,fill='white')
 canvas.save(out/name)
sheet([build/'reopen-v02'/f'{id}-three-quarter.png' for id in ['workbench','mason_yard']],['Blender packed source / workbench','Blender packed source / mason yard'],'blender-models.jpg')
rows={}
for backend in ['forward_plus','gl_compatibility']:
 src=build/'review/evidence'/backend
 sheet([src/'01-workbench.png',src/'02-mason-yard.png'],[backend+' / workbench',backend+' / mason yard'],backend+'-models.jpg')
 for name in ['05-workbench-corner-false.png','05-mason_yard-corner-true.png','07-restored.png']:
  shutil.copy2(src/name,out/(backend+'-'+name))
 for id in ['workbench','mason_yard']:
  for kind,count,duration in [('orbit',48,83),('work',24,50)]:
   paths=sorted(src.glob(f'{kind}-{id}-*.png'));assert len(paths)==count
   frames=[]
   for p in paths:
    im=Image.open(p).convert('RGB');im.thumbnail((960,600));frames.append(im)
   p=out/f'{backend}-{id}-{kind}.webp'
   frames[0].save(p,save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=85,method=4)
   decoded=Image.open(p);elapsed=0
   # WebP coalesces consecutive identical idle frames. Validate retained motion
   # and the complete duration instead of requiring redundant encoded frames.
   assert 1<decoded.n_frames<=count
   for i in range(decoded.n_frames):
    decoded.seek(i);decoded.load();elapsed+=decoded.info['duration']
   assert elapsed==count*duration,(p,elapsed)
   assert frames[0].tobytes()!=frames[-1].tobytes()
   rows[p.name]={'source_frames':count,'encoded_frames':decoded.n_frames,'duration_ms':elapsed,'source_sha256':[sha(p) for p in paths],'scope':'camera orbit' if kind=='orbit' else 'actual native paid-completion frames played at about one-third speed for inspection'}
 shutil.copy2(src/'benchmark.json',out/(backend+'-benchmark.json'))
for name in ['audit.json','model.log.json','reopen-final.log.json']:
 shutil.copy2(build/name,out/name)
files=[{'path':p.name,'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted(out.iterdir()) if p.is_file() and p.name not in ['evidence-manifest.json','README.md','.gitattributes']]
(out/'evidence-manifest.json').write_text(json.dumps({'files':files,'motion':rows},indent=2)+'\n')
print('E1_CURATED_EVIDENCE',len(files))
