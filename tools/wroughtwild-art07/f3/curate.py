"""Curate real Blender/Godot pixels; no synthesized model or motion evidence."""
import json,hashlib,shutil,sys
from pathlib import Path
from PIL import Image,ImageDraw
assets,game,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
def copy(src,name):
 dst=out/name;assert not dst.exists(),dst;shutil.copy2(src,dst)
def sheet(entries,name,columns=2,width=750,height=540):
 canvas=Image.new('RGB',(columns*width,((len(entries)+columns-1)//columns)*height),'#202520');d=ImageDraw.Draw(canvas)
 for i,(path,label) in enumerate(entries):
  with Image.open(path) as im:
   im=im.convert('RGB');im.thumbnail((width,height-32));x=i%columns*width;y=i//columns*height;canvas.paste(im,(x+(width-im.width)//2,y+32+(height-32-im.height)//2));d.text((x+12,y+10),label,fill='white')
 assert not (out/name).exists();canvas.save(out/name)
copy(assets/'blender-overview.png','blender-overview.png')
sheet([(assets/f'{kind}-emission-{state}.png',f'{kind} / emission {"OFF" if state==0 else "PEAK"}') for kind in ['pullstone_source','ventlung_source'] for state in [0,1]],'blender-scars-off-peak.png')
sheet([(assets/f'{kind}-{view}.png',f'{kind} / {view}') for kind in ['magnetic_sorter','ventlung_bellows'] for view in ['threequarter','back','top','underside']], 'blender-device-inspection.png',4,550,440)
evidence=game/'f3/evidence'
for renderer in ['forward_plus','gl_compatibility']:
 copy(evidence/f'{renderer}-overview.png',f'godot-{renderer}.png')
 sheet([(evidence/f'{renderer}-{state}.png',state) for state in ['sorter-input','sorter-first-batch','sorter-trays','bellows-primed','bellows-discharged','depleted']],f'godot-{renderer}-native-states.png',3,640,390)
 frames=[]
 for p in sorted((evidence/f'{renderer}-motion').glob('*.png')):
  with Image.open(p) as im:
   im=im.convert('RGB');im.thumbnail((1100,620));frames.append(im.copy())
 assert len(frames)==120
 frames[0].save(out/f'godot-{renderer}-motion.webp',save_all=True,append_images=frames[1:],duration=33,loop=0,quality=83,method=4)
 for p in evidence.glob(f'{renderer}-*.json'):copy(p,p.name)
records=[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.iterdir()) if p.is_file()]
(out/'evidence-manifest.json').write_text(json.dumps({'method':'Actual renderer pixels. Contact sheets resize and label only. Motion is 120 successive Godot viewport frames at fixed 30 fps; no tweened or invented frames.','files':records},indent=2)+'\n')
print('F3_CURATED',out)
