"""Curate real Blender/Godot renders, label contact sheets, encode actual frames.
No generated imagery or retouching. Original principal PNG bytes are retained.
"""
import json,shutil,sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
from inputs import ROOT,sha
models,review,out=[Path(p).resolve() for p in sys.argv[1:4]]
inspection=Path(sys.argv[4]).resolve() if len(sys.argv)>4 else models/'reopen'
checked=json.loads((inspection/'reopen.json').read_text())
assert checked['packed_images']==42 and len(checked['imports'])==31
assert all(v['objects']==1 and v['degenerates']==0 for v in checked['imports'].values())
assert out.is_relative_to(ROOT/'docs/art/leyline-studies/2026-09-09/art07/e3')
out.mkdir(parents=True,exist_ok=False)
records=[]
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
def remember(dst,sources,operation):
 records.append({'path':dst.relative_to(out).as_posix(),'sha256':sha(dst),'operation':operation,'sources':[{'path':str(p),'sha256':sha(p)} for p in sources]})
def copy(src,dst):
 dst.parent.mkdir(parents=True,exist_ok=True)
 if src.suffix=='.json':dst.write_bytes(src.read_bytes().replace(b'\r\n',b'\n'));operation='JSON line endings normalized to LF; values unchanged'
 else:shutil.copy2(src,dst);operation='unchanged bytes'
 remember(dst,[src],operation)
def sheet(sources,dst,columns=4):
 width,height=400,348
 canvas=Image.new('RGB',(columns*width,((len(sources)+columns-1)//columns)*height),(23,28,30));draw=ImageDraw.Draw(canvas)
 for i,p in enumerate(sources):
  with Image.open(p) as source:
   tile=source.convert('RGB');tile.thumbnail((width,height-40))
   x,y=i%columns*width,i//columns*height
   canvas.paste(tile,(x+(width-tile.width)//2,y+(height-40-tile.height)//2))
   draw.text((x+10,y+height-33),p.stem,font=font,fill=(239,228,212))
 canvas.save(dst);remember(dst,sources,'labelled contact sheet; proportional resizing only')
for name in ['wood-open','wood-closed','wood-fuel','wood-fuel-clay','bronze-open','charcoal-fuel']:
 copy(inspection/(name+'.png'),out/('blender-'+name+'.png'))
sheet([inspection/('wood-clay-'+v+'.png') for v in ['front','back','side','top','underside','three-quarter']],out/'blender-six-angle.png',3)
for backend in ['forward_plus','gl_compatibility']:
 source=review/'evidence'/backend;dest=out/backend;dest.mkdir()
 with Image.open(source/'fire-dusk.png') as on,Image.open(source/'fire-dusk-emission-off.png') as off:
  delta=ImageChops.difference(on.convert('RGB').crop((0,180,1440,900)),off.convert('RGB').crop((0,180,1440,900)))
  visible=sum(1 for pixel in delta.get_flattened_data() if max(pixel)>5)
  assert visible>30,(backend,'ember phase hidden at the inspection angle',visible)
  print('E3_EMBER_VISIBLE',backend,visible,'pixels above 5/255 with emission enabled')
  proof=dest/'ember-visibility.json'
  proof.write_text(json.dumps({'comparison_rectangle':[0,180,1440,900],'pixels_above_5_of_255':visible,'difference_bounds_in_rectangle':delta.getbbox(),'native_point_light':'unchanged in both views','scope':'same native burn age, camera and lighting; only ember shader gain differs'},indent=2)+'\n',newline='\n')
  remember(proof,[source/'fire-dusk.png',source/'fire-dusk-emission-off.png'],'actual rendered emission-on/off pixel comparison outside the caption')
 for name in ['chest-wood-open','chest-wood-closed','chest-bronze-open','02-storage-panel','chest-shade','chest-dusk','ghost-chest','ghost-campfire','fire-wood-new','fire-last-44','fire-last-59','fire-spent','fire-emission-off','fire-dusk','fire-dusk-emission-off','chests-distance-6','chests-distance-12','chests-distance-24']:
  copy(source/(name+'.png'),dest/(name+'.png'))
 sheet([source/f'chest-{family}-open.png' for family in ['wood','pine','bog_oak','ash_wood','resinheart','iron','bronze','steel']],dest/'all-eight-chests.png')
 sheet([source/f'fire-{family}-{state}.png' for state in ['new','late'] for family in ['wood','pine','bog_oak','ash_wood','charcoal']],dest/'all-five-fuels.png',5)
 for kind,duration in [('lid',80),('fire',120)]:
  paths=sorted(source.glob('motion-'+kind+'-*.png'));assert len(paths)==(40 if kind=='lid' else 45)
  if kind=='fire':paths += [source/'fire-spent.png']*8
  frames=[]
  for p in paths:
   with Image.open(p) as im:frames.append(im.convert('RGB').resize((960,600),Image.Resampling.LANCZOS))
  dst=dest/(kind+'-motion.webp');frames[0].save(dst,save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=85,method=5)
  remember(dst,list(dict.fromkeys(paths)),'actual captured frames resized to 960x600; '+('80 ms display per frame; native panel driven cosmetic travel' if kind=='lid' else '120 ms display per one-second native burn step, followed by actual spent view'))
 for name in ['checks.json','benchmark.json']:
  copy(source/name,dest/name)
copy(models/'audit-final.json',out/'source-audit.json')
copy(inspection/'reopen.json',out/'blender-reopen.json')
(out/'manifest.json').write_text(json.dumps({'slice':'ART-07E3','sources':'Unchanged principal renders and derived contact sheets/WebP from actual model captures. Burn movie compresses native time; no real-time claim. JSON uses LF for Git hash stability.','files':records},indent=2)+'\n',newline='\n')
print('E3_EVIDENCE_OK',len(records),sha(out/'manifest.json'))
