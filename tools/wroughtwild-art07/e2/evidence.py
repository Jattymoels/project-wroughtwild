"""Curate unchanged actual PNGs and encode a slowed preview of real state frames."""
import json,shutil,sys
from pathlib import Path
from PIL import Image,ImageDraw
from inputs import ROOT,sha
source,review,out=[Path(x).resolve() for x in sys.argv[1:4]]
assert out.is_relative_to(ROOT/'docs/art/leyline-studies/2026-09-09/art07/e2')
out.mkdir(parents=True,exist_ok=False);rows=[]
def copy(src,name):
    dst=out/name;shutil.copy2(src,dst);rows.append({'source':str(src),'path':name,'sha256':sha(dst),'unchanged':sha(src)==sha(dst)})
for tier in ['basic','improved']:
    copy(source/'reopen'/f'{tier}-three-quarter.png',f'blender-{tier}.png')
    copy(source/'reopen'/f'{tier}-clay-front.png',f'blender-{tier}-clay.png')
for backend in ['forward_plus','gl_compatibility']:
    raw=review/'evidence'/backend
    for name in ['01-basic-cold','03-improved-cold','03-working-context','03-working-controls','04-paused','05-complete','07-shade','08-fresh-process-paused']:
        copy(raw/(name+'.png'),backend+'-'+name+'.png')
    for name in ['checks','restore','benchmark','timings']:
        p=raw/(name+'.json');result=json.loads(p.read_text())
        if name!='timings':assert result['failures']==0,result
        copy(p,backend+'-'+name+'.json')
    paths=sorted(raw.glob('motion-*.png'));assert len(paths)==60,len(paths)
    frames=[Image.open(p).convert('RGB').resize((1200,675),Image.Resampling.LANCZOS) for p in paths]
    dst=out/(backend+'-work-pause.webp')
    frames[0].save(dst,save_all=True,append_images=frames[1:],duration=100,loop=0,quality=90,method=6)
    rows.append({'path':dst.name,'sha256':sha(dst),'source_frames':[{'path':str(p),'sha256':sha(p)} for p in paths],'playback':'60 actual frames; 100 ms each for inspection. First 48 advance native work at 24 Hz; final 12 hold explicit pause. No interpolated motion.'})
    # Full multi-angle geometry contact sheet, clearly labelled thumbnails.
tiles=[]
for tier in ['basic','improved']:
    for kind in ['','-clay']:
        for angle in ['front','back','side','three-quarter','top','underside']:
            p=source/'reopen'/f'{tier}{kind}-{angle}.png';im=Image.open(p).convert('RGB');im.thumbnail((260,260))
            tiles.append((im,tier+kind+' / '+angle))
sheet=Image.new('RGB',(6*280,4*300),(26,28,30));draw=ImageDraw.Draw(sheet)
for i,(im,label) in enumerate(tiles):
    x=(i%6)*280+10;y=(i//6)*300+8;sheet.paste(im,(x,y));draw.text((x,y+269),label,fill='white')
sheet.save(out/'blender-contact-sheet.jpg',quality=91)
rows.append({'path':'blender-contact-sheet.jpg','sha256':sha(out/'blender-contact-sheet.jpg'),'source':'24 actual reopened Blender renders; scaled thumbnails only'})
(out/'evidence.json').write_text(json.dumps({'files':rows},indent=2)+'\n')
print('E2_EVIDENCE_OK',len(rows))
