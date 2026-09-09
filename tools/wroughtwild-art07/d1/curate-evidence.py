"""Compose actual renderer frames for remote review; no invented/interpolated art."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--inspection',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); ap.add_argument('--blender-only',action='store_true'); a=ap.parse_args()
out=a.output; out.mkdir(parents=True,exist_ok=True)
for name in ['blender-material.png','blender-neutral.png']:
    (out/name).write_bytes((a.models/'evidence'/name).read_bytes())
ids=list(json.loads((a.models/'geometry.json').read_text())['assets'])
angles=['front','back','side','three-quarter','top','underside']
for mode in ['material','neutral']:
    sheet=Image.new('RGB',(1200,2200),(40,46,50)); draw=ImageDraw.Draw(sheet)
    for row,k in enumerate(ids):
        for column,angle in enumerate(angles):
            im=Image.open(a.inspection/f'{k}-{angle}-{mode}.png').convert('RGBA'); im.thumbnail((200,200))
            sheet.paste(im,(column*200,row*220),im)
            draw.text((column*200+5,row*220+197),k+' / '+angle,fill='white')
    sheet.save(out/f'blender-six-views-{mode}.png')
for renderer in ([] if a.blender_only else ['forward_plus','gl_compatibility']):
    folder=a.build/'snapshot/game/art07_d1/evidence'/renderer
    for name in ['catalogue-material','catalogue-neutral','joins-material','joins-neutral','joins-shade','joins-dusk','ceiling-underside']:
        (out/f'{renderer}-{name}.png').write_bytes((folder/(name+'.png')).read_bytes())
    frames=[]
    for p in sorted(folder.glob('motion-*.png')):
        im=Image.open(p).convert('RGB'); im.thumbnail((960,600)); frames.append(im)
    assert len(frames)==48
    frames[0].save(out/f'{renderer}-orbit.webp',save_all=True,append_images=frames[1:],duration=83,loop=0,quality=82,method=4)
print('D1_EVIDENCE_CURATED',out)
