"""Original periodic metal reflectance/normal/ORM, no lit photographs or dependencies."""
import hashlib, json, sys
from pathlib import Path
import numpy as np
from PIL import Image

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main(out):
    out.mkdir(parents=True, exist_ok=False)
    cfg=json.loads(Path(__file__).with_name('materials.json').read_text())
    n=cfg['resolution']; y,x=np.mgrid[:n,:n]/n
    rng=np.random.default_rng(cfg['seed']); files=[]
    for f in cfg['families']:
        broad=np.zeros((n,n)); fine=np.zeros_like(broad); dents=np.zeros_like(broad)
        # Integer harmonics make a seamless periodic torus, including derivatives.
        for k in range(40):
            a,b=rng.integers(-9,10,2);phase=rng.uniform(0,2*np.pi)
            broad+=np.sin(2*np.pi*(a*x+b*y)+phase)/40
        broad=np.clip(broad*3,-1,1)
        for k in range(24):
            a,b=rng.integers(25,120,2)
            fine+=np.sin(2*np.pi*(a*x+b*y)+rng.uniform(0,6.28))/24
        for k in range(145):
            cx,cy=rng.random(2);r=rng.uniform(.012,.037)
            dx=(x-cx+.5)%1-.5;dy=(y-cy+.5)%1-.5
            dents-=np.exp(-(dx*dx+dy*dy)/(r*r))*rng.uniform(.3,1)
        if f['id']=='steel':
            dents=.25*dents+.10*np.sin(2*np.pi*(x*120+y*2))
        height=(dents+.08*fine)*f['hammer_mm']/1000
        dx=(np.roll(height,-1,1)-np.roll(height,1,1))/(2*cfg['repeat_metres']/n)
        dy=(np.roll(height,-1,0)-np.roll(height,1,0))/(2*cfg['repeat_metres']/n)
        normal=np.stack([-dx,dy,np.ones_like(dx)],axis=-1)
        normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
        albedo=np.array(f['albedo'])*(1+(.20 if f['id']=='iron' else .105)*broad[...,None]+.035*fine[...,None])
        rough=np.clip(f['roughness']+.10*broad+.03*fine,.12,.88)
        orm=np.stack([np.ones_like(rough),rough,np.ones_like(rough)],axis=-1)
        for kind,arr in [('albedo',albedo),('normal',normal*.5+.5),('orm',orm)]:
            p=out/f'd6_{f["id"]}_{kind}.png'
            Image.fromarray(np.uint8(np.clip(arr,0,1)*255+.5),'RGB').save(p)
            files.append({'path':p.name,'bytes':p.stat().st_size,'sha256':sha(p),'colour_space':'sRGB' if kind=='albedo' else 'linear'})
    report={'settings':cfg,'files':files,'contract':'OpenGL +Y tangent normal; ORM=AO/Roughness/Metal; R=B=1; seam metallic uses material factor; no emission/alpha','rgb_bytes_base':12*n*n*3,'rgba_bytes_with_mips':12*n*n*4*4/3}
    (out/'textures.json').write_text(json.dumps(report,indent=2)+'\n')
    print('D6_SURFACES_OK',len(files))
if __name__=='__main__':main(Path(sys.argv[1]).resolve())
