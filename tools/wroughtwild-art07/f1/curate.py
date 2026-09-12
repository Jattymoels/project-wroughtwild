"""Curate actual Blender/Godot frames; retain original full sequences locally."""
import hashlib,json,shutil,sys
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw

ROOT=Path(__file__).resolve().parents[3]
assets,game=map(lambda s:Path(s).resolve(),sys.argv[1:])
dest=ROOT/'docs/art/leyline-studies/2026-09-09/art07/f1'
evidence=game/'f1/evidence'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
records=[]
def copy(p,name=None):
    q=dest/(name or p.name);assert not q.exists(),q
    shutil.copy2(p,q);records.append({'path':q.name,'source':str(p),'sha256':sha(q)})
for name in ['blender-overview.png','lantern_lamp-material-threequarter.png','stormglass_lever-material-threequarter.png','lanternheart_source-material-threequarter.png','stormglass_source-material-threequarter.png']:
    copy(assets/name)
for kind in ['lantern_lamp','stormglass_lever','lanternheart_source','stormglass_source']:
    sheet=Image.new('RGB',(1800,1056),'#222626');draw=ImageDraw.Draw(sheet)
    sources=[]
    for row,mode in enumerate(['material','clay']):
        for col,angle in enumerate(['front','side','back','top','underside','threequarter']):
            p=assets/f'{kind}-{mode}-{angle}.png';sources.append({'path':str(p),'sha256':sha(p)})
            tile=ImageOps.contain(Image.open(p).convert('RGB'),(300,490),Image.Resampling.LANCZOS)
            x,y=col*300,row*528;sheet.paste(tile,(x+(300-tile.width)//2,y+25))
            draw.text((x+8,y+6),mode+' / '+angle,fill='white')
    q=dest/f'{kind}-inspection.webp';assert not q.exists();sheet.save(q,quality=92)
    records.append({'path':q.name,'sources':sources,'sha256':sha(q),'operation':'contact sheet from actual Blender renders; scaled, labelled'})
for p in sorted(evidence.glob('*')):
    if p.is_file() and p.suffix in ['.png','.json']:copy(p)
for renderer in ['forward_plus','gl_compatibility']:
    paths=sorted((evidence/(renderer+'-motion')).glob('*.png'));assert len(paths)==120,len(paths)
    frames=[ImageOps.contain(Image.open(p).convert('RGB'),(1200,675),Image.Resampling.LANCZOS) for p in paths]
    q=dest/(renderer+'-motion.webp');assert not q.exists()
    frames[0].save(q,save_all=True,append_images=frames[1:],duration=[33,33,34]*40,loop=0,quality=86,method=4)
    records.append({'path':q.name,'sha256':sha(q),'frames':[{'path':str(p),'sha256':sha(p)} for p in paths],'operation':'120 actual frames, 30 fps, resized to 1200x675; no synthetic frames'})
(dest/'evidence-manifest.json').write_text(json.dumps({'slice':'ART-07F1','owner_visual_acceptance':'pending','records':records},indent=2)+'\n')
print('F1_CURATED',len(records),dest)
