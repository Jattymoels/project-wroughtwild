"""Encode actual capture frames, preserving original PNGs and checking paused identity."""
import sys,json,hashlib
from pathlib import Path
from PIL import Image,ImageChops
review,native,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=True);report={}
for renderer in ['forward_plus','gl_compatibility']:
    folder=review/'evidence'/renderer
    wind=sorted(folder.glob('wind-*.png'));paused=sorted(folder.glob('paused-*.png'));assert len(wind)==66 and len(paused)==12
    a=Image.open(paused[0]).convert('RGB');assert all(ImageChops.difference(a,Image.open(p).convert('RGB')).getbbox() is None for p in paused)
    assert ImageChops.difference(a,Image.open(folder/'resumed.png').convert('RGB')).getbbox() is not None
    def encode(paths,dest,ms):
        frames=[]
        for p in paths:
            im=Image.open(p).convert('RGB');im.thumbnail((960,600),Image.Resampling.LANCZOS);frames.append(im)
        frames[0].save(dest,save_all=True,append_images=frames[1:],duration=ms,loop=0,quality=83,method=4)
        return len(frames)
    encode(wind+paused+[folder/'resumed.png'],out/(renderer+'-wind.webp'),83)
    nf=native/'game/c1/evidence'/renderer
    work=sorted(nf.glob('work-*.png'));fall=sorted(nf.glob('fall-*.png'));assert len(work)==36 and len(fall)==24
    encode([nf/'intact.png']+work+fall+[nf/'aftermath.png'],out/(renderer+'-work.webp'),160)
    report[renderer]={'wind_frames':len(wind),'paused_frames':len(paused),'paused_pixels_identical':True,'resumed_pixels_differ':True,'work_frames':len(work),'fall_frames':len(fall),'source_dimensions':list(a.size),'encoding':'Actual PNG frames, resized only; no synthesized motion. Work timeline presented at 160 ms/frame, not realtime.'}
(out/'motion-checks.json').write_text(json.dumps(report,indent=2)+'\n');print('C1_MEDIA_OK',report)
