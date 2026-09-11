"""Curated evidence from actual frames only; no interpolated or generated model views."""
import sys,json,shutil
from pathlib import Path
from PIL import Image,ImageDraw
review,native,blender,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
assert not out.exists();out.mkdir(parents=True)
def animation(files,dest,duration=85):
    frames=[]
    for file in files:
        im=Image.open(file).convert('RGB');im.thumbnail((960,600),Image.Resampling.LANCZOS);frames.append(im)
    frames[0].save(dest,save_all=True,append_images=frames[1:],duration=duration,loop=0)
def panel(files,titles,dest,width=800):
    images=[]
    for p in files:
        im=Image.open(p).convert('RGB');im.thumbnail((width,560),Image.Resampling.LANCZOS);images.append(im)
    height=max(i.height for i in images)+32
    canvas=Image.new('RGB',(width*len(images),height),(31,36,38));draw=ImageDraw.Draw(canvas)
    for i,im in enumerate(images):canvas.paste(im,(i*width,32));draw.text((i*width+12,10),titles[i],fill='white')
    canvas.save(dest)
panel([blender/'standing-variants.png',blender/'felled-stump.png'],['Actual packed Blender ash variants','Actual felled timber and session stump'],out/'blender-ash.png',650)
shutil.copy2(blender/'surviving-scrub.png',out/'blender-scrub.png')
shutil.copy2(blender/'scar-emission-off.png',out/'blender-scar-off.png')
for renderer in ['forward_plus','gl_compatibility']:
    e=review/'evidence'/renderer;n=native/'c4/evidence'/renderer
    panel([e/'day.png',e/'dusk.png'],[renderer+' actual day',renderer+' actual dusk'],out/(renderer+'-habitat.png'))
    panel([e/'ash-scar-off.png',e/'ash-scar-on.png'],['Actual scar, light disabled','Actual scar, ambient light enabled'],out/(renderer+'-scar.png'))
    animation(sorted(e.glob('pulse-*.png'))[::2],out/(renderer+'-pulse.webp'),167)
    animation(sorted(e.glob('wind-*.png'))[::2],out/(renderer+'-wind.webp'),229)
    animation(sorted(e.glob('walk-*.png'))[::2],out/(renderer+'-walk.webp'),333)
    animation([n/'standing.png',n/'partial.png']+sorted(n.glob('fall-*.png'))+[n/'stumps.png'],out/(renderer+'-native-felling.webp'),65)
    for name in ['checks.json','walk.json','benchmark.json','motion.json']:shutil.copy2(e/name,out/(renderer+'-'+name))
    for name in ['flow','partial-restart','final-restart']:shutil.copy2(n/('native-'+name+'.json'),out/(renderer+'-native-'+name+'.json'))
print('C4_CURATED_MEDIA_OK')
