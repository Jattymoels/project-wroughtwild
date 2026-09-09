"""Arrange actual renderer evidence for remote review; no asset/image synthesis."""
import sys,json,shutil
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from audit import sha
work,out=map(lambda x:Path(x).resolve(),sys.argv[1:3]);assert not out.exists();out.mkdir(parents=True)
colours=['red','white','blue','green']
shots={'red':'10-buffer-real-firing','white':'post-request','blue':'delay-held','green':'junction-unwound'}
clips={'red':'red-paid-firing','white':'white-request','blue':'blue-delay','green':'green-junction'}
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',22)
records=[]
for mode in ['blender','forward','compat']:
    sheet=Image.new('RGB',(1600,1080),(24,29,28));draw=ImageDraw.Draw(sheet)
    sources=[]
    for i,c in enumerate(colours):
        path=work/c/('evidence/packed-reopen.png' if mode=='blender' else 'review/'+('evidence' if mode=='forward' else 'evidence-compat')+'/'+shots[c]+'.png')
        im=Image.open(path).convert('RGB');im.thumbnail((800,500),Image.Resampling.LANCZOS)
        x=(i%2)*800;y=(i//2)*540
        draw.text((x+14,y+5),c.title()+' / '+{'blender':'packed Blender master','forward':'Godot Forward+','compat':'Godot Compatibility'}[mode],fill=(227,232,223),font=font)
        sheet.paste(im,(x+(800-im.width)//2,y+40+(500-im.height)//2))
        sources.append({'path':str(path),'sha256':sha(path)})
    target=out/(mode+'-four-colours.png');sheet.save(target)
    records.append({'file':target.name,'sha256':sha(target),'composition':'2x2 original actual renderer images, uniformly reduced to fit; labels added outside frames','sources':sources})
for c in colours:
    source=work/c/('evidence/forward-'+clips[c]+'.webp');target=out/(c+'-motion.webp');shutil.copy2(source,target)
    records.append({'file':target.name,'sha256':sha(target),'source':str(source),'exact_copy':True})
(out/'evidence-lineage.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('F5_CURATED_ACTUAL_EVIDENCE')
