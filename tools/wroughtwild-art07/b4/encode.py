"""Encode unmodified actual frames; no interpolation or synthetic movement."""
import sys,json
from pathlib import Path
from PIL import Image,ImageDraw
review,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
for renderer in ['forward_plus','gl_compatibility']:
    root=review/'evidence'/renderer
    for prefix in ['walk','pulse','water-wind']:
        paths=sorted(p for p in root.glob(prefix+'-*.png') if p.stem.split('-')[-1].isdigit())
        assert paths
        frames=[]
        for p in paths:
            im=Image.open(p).convert('RGB');im.thumbnail((960,600));frames.append(im)
        duration=round(1000/12)
        if prefix=='walk':
            walk=json.loads((root/'walk.json').read_text());duration=round(len(walk['samples'])/60/len(paths)*1000)
        frames[0].save(out/f'{renderer}-{prefix}.webp',save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=82,method=4)
        if prefix=='walk':frames[0].save(out/f'{renderer}-{prefix}.gif',save_all=True,append_images=frames[1::2],duration=duration*2,loop=0,optimize=False)
    # One remote-review panel from actual unmodified state captures, only resized/labelled.
    panels=['walk-day','walk-shade','walk-dusk','tree-scar-off','tree-scar-on','water-bank-contact']
    sheet=Image.new('RGB',(1440,1428),(23,28,26));draw=ImageDraw.Draw(sheet)
    for i,name in enumerate(panels):
        im=Image.open(root/(name+'.png')).convert('RGB');im.thumbnail((720,450));x=i%2*720;y=i//2*476
        sheet.paste(im,(x,y+26));draw.text((x+12,y+7),renderer+' | '+name,fill='white')
    sheet.save(out/(renderer+'-states.jpg'),quality=92)
print('B4_MEDIA_OK')
