"""Curate actual model output; contact sheets/orbit encoding are labelled derivatives."""
import argparse,json,hashlib,shutil
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--inspection',type=Path,required=True); a=ap.parse_args()
root=Path(__file__).resolve().parents[3]; out=root/'docs/art/leyline-studies/2026-09-09/art07/d3'; out.mkdir(exist_ok=True,parents=True)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
records=[]
def copy(p,name):
    target=out/name; shutil.copy2(p,target); records.append({'file':name,'source':str(p.resolve()),'sha256':sha(target),'unmodified_copy':True})
for mode in ['material','neutral']: copy(a.models/'evidence'/f'blender-{mode}.png',f'blender-{mode}.png')
for renderer in ['forward_plus','gl_compatibility']:
    source=a.build/'snapshot/game/art07_d3/evidence'/renderer
    for name in ['catalogue-material','fine-pieces','coverings-front','coverings-back','source-frames-front','source-frames-back','source-frames-neutral','joins-material','joins-neutral','window-front','window-back','shelf-underside','joins-shade','joins-dusk']:
        copy(source/f'{name}.png',f'{renderer}-{name}.png')
    frames=[Image.open(p).convert('RGB').resize((960,600),Image.Resampling.LANCZOS) for p in sorted(source.glob('motion-*.png'))]
    assert len(frames)==48
    path=out/f'{renderer}-orbit.webp'; frames[0].save(path,save_all=True,append_images=frames[1:],duration=83,loop=0,quality=85,method=5)
    with Image.open(path) as image: assert image.n_frames==48
    records.append({'file':path.name,'sha256':sha(path),'source':str(source.resolve()),'derivative':'48 actual camera-orbit frames resized to 960x600, 83 ms each; static geometry','frames':48})
assets=list(json.loads((a.models/'geometry.json').read_text())['assets'])
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',16)
sheet=Image.new('RGB',(1536,12*280),(39,44,47)); draw=ImageDraw.Draw(sheet)
for row,k in enumerate(assets):
    for column,view in enumerate(['front','back','underside','three-quarter']):
        p=a.inspection/f'{k}-{view}-neutral.png'; im=Image.open(p).convert('RGBA'); im.thumbnail((250,250))
        tile=Image.new('RGBA',(384,280),(39,44,47,255)); tile.alpha_composite(im,((384-im.width)//2,24)); sheet.paste(tile.convert('RGB'),(column*384,row*280))
        draw.text((column*384+12,row*280+4),k+' / '+view,font=font,fill=(236,233,219))
path=out/'blender-topology-views.jpg'; sheet.save(path,quality=92)
records.append({'file':path.name,'sha256':sha(path),'derivative':'Labelled contact sheet of independent actual neutral front/back/underside/three-quarter renders; no shape editing'})
for name in ['geometry.json'] : copy(a.models/name,name)
copy(a.inspection/'reopen.json','blender-reopen.json')
for name in ['check-placement.json','check-restart.json']: copy(a.build/'snapshot/game/art07_d3'/name,name)
for renderer in ['forward_plus','gl_compatibility']:
    p=a.build/'snapshot/game/art07_d3/evidence'/renderer/'benchmark.json'
    if p.exists(): copy(p,renderer+'-benchmark.json')
(out/'evidence.json').write_text(json.dumps({'slice':'ART-07D3','owner_visual_acceptance':'pending','media':records},indent=2)+'\n')
print('D3_CURATED_ACTUAL_MODELS',len(records),out)
