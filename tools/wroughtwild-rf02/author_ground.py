"""Original seamless RF-02 surface maps. No reference-image pixels are used.
Deterministic painted turf blades, thatch, humus and curled litter; packed RG
holds signed X/Z relief slope, B matte roughness. Blender/terrain stay undisplaced.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import random, math, json, hashlib, shutil

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/rf02/textures'
SOURCE=Path('D:/Wroughtwild/source-art/rf02-ground-grass')
N=1024
METRES=2.4

def field(seed, frequencies):
    rng=random.Random(seed)
    y,x=np.mgrid[0:N,0:N].astype(np.float32)/N
    a=np.zeros((N,N),np.float32)
    for f,amp in frequencies:
        for _ in range(4):
            kx=rng.randint(-f,f);ky=rng.randint(-f,f)
            if not kx and not ky:kx=1
            a+=amp*np.sin(math.tau*(x*kx+y*ky)+rng.random()*math.tau)/4
    return a

def author(role,seed):
    rng=random.Random(seed)
    forest=role=='woodland'
    macro=field(seed,[(2,1),(5,.48),(13,.18)])
    fine=field(seed+1,[(60,.22),(140,.11)])
    noise=np.random.default_rng(seed).normal(0,1.5,(N,N)).astype(np.float32)
    soil=np.array([72,62,44] if forest else [78,87,47],np.float32)
    col=np.clip(soil+macro[:,:,None]*np.array([9,10,6])+fine[:,:,None]*5+noise[:,:,None],0,255).astype('uint8')
    im=Image.fromarray(col,'RGB')
    height=Image.fromarray(np.clip(98+macro*7+fine*9,0,255).astype('uint8'),'L')
    d=ImageDraw.Draw(im);hd=ImageDraw.Draw(height)
    # Repeat only edge-crossing primitives: tile borders are genuinely wrapped.
    def polygons(points,c,h):
        for ox in [-N,0,N]:
            for oy in [-N,0,N]:
                if max(p[0]+ox for p in points)<0 or min(p[0]+ox for p in points)>=N:continue
                if max(p[1]+oy for p in points)<0 or min(p[1]+oy for p in points)>=N:continue
                pts=[(x+ox,y+oy) for x,y in points]
                d.polygon(pts,fill=c);hd.polygon(pts,fill=h)
    def line(points,c,h,width=1):
        for ox in [-N,0,N]:
            for oy in [-N,0,N]:
                if max(p[0]+ox for p in points)<0 or min(p[0]+ox for p in points)>=N:continue
                if max(p[1]+oy for p in points)<0 or min(p[1]+oy for p in points)>=N:continue
                pts=[(x+ox,y+oy) for x,y in points]
                d.line(pts,fill=c,width=width);hd.line(pts,fill=h,width=width)
    # Fine tangled fibres give turf an established mat and litter a humus bed.
    for _ in range(29000 if not forest else 12500):
        x=rng.random()*N;y=rng.random()*N
        local=macro[int(y)%N,int(x)%N]
        a=rng.random()*math.tau;l=rng.uniform(4,24)
        w=rng.uniform(.65,1.6)
        dried=rng.random() < (.28 if forest else .19)
        base=np.array(([104,91,57] if dried else [78,97,46]) if not forest else ([100,81,51] if dried else [64,65,37]))
        c=tuple(np.clip(base+rng.uniform(-14,13)+local*5,0,255).astype(int))
        ux,uy=math.cos(a),math.sin(a)
        points=[(x,y),(x+ux*l*.45-uy*w,y+uy*l*.45+ux*w),(x+ux*l+uy*l*.14,y+uy*l-ux*l*.14),(x+ux*l*.45+uy*w,y+uy*l*.45-ux*w)]
        polygons(points,c,rng.randint(104,143))
    # Small leaves and broken leaflets. Soil remains visible between them.
    for _ in range(1250 if forest else 90):
        x=rng.random()*N;y=rng.random()*N
        a=rng.random()*math.tau;l=rng.uniform(10,36 if forest else 24);w=l*rng.uniform(.24,.45)
        ux,uy=math.cos(a),math.sin(a)
        points=[]
        for t,side in [(0,0),(.19,-.62),(.48,-1),(.8,-.62),(1,0),(.75,.7),(.42,.94),(.16,.52)]:
            points.append((x+ux*l*t-uy*w*side,y+uy*l*t+ux*w*side))
        b=rng.choice([(101,82,50),(86,72,44),(112,94,61),(78,75,43),(126,105,69)])
        c=tuple(int(v*rng.uniform(.89,1.08)) for v in b)
        polygons(points,c,rng.randint(129,163))
        line([(x,y),(x+ux*l*.87,y+uy*l*.87)],tuple(max(0,v-12) for v in c),151)
        for t in [.3,.49,.68]:
            for side in [-1,1]:
                line([(x+ux*l*t,y+uy*l*t),(x+ux*l*(t+.16)-uy*w*.58*side,y+uy*l*(t+.16)+ux*w*.58*side)],tuple(max(0,v-6) for v in c),144)
    # Sparse fine broken twigs/needles, no large motif or painted shadows.
    if forest:
        for _ in range(240):
            x=rng.random()*N;y=rng.random()*N;a=rng.random()*math.tau;l=rng.uniform(9,40)
            line([(x,y),(x+math.cos(a)*l,y+math.sin(a)*l)],(84,70,47),126,1)
    # Wrapping blur gives quiet relief without discontinuities at tile borders.
    tiled=Image.new('L',(N*3,N*3))
    for x in range(3):
        for y in range(3):tiled.paste(height,(x*N,y*N))
    h=np.asarray(tiled.filter(ImageFilter.GaussianBlur(.8)).crop((N,N,N*2,N*2)),dtype=np.float32)/255
    dx=(np.roll(h,-1,axis=1)-np.roll(h,1,axis=1))*1.4
    dz=(np.roll(h,-1,axis=0)-np.roll(h,1,axis=0))*1.4
    packed=np.stack([.5-dx,.5-dz,np.clip(.94+macro*.012,.87,.99)],axis=2)
    detail=Image.fromarray(np.clip(packed*255,0,255).astype('uint8'),'RGB')
    im.save(OUT/(role+'-albedo.png'),optimize=True)
    detail.save(OUT/(role+'-detail.png'),optimize=True)
    return {'role':role,'pixels':N,'repeat_metres':METRES,'seed':seed,'mean_srgb':(np.asarray(im).mean(axis=(0,1))/255).tolist(),'relief':'RG signed tangent slopes, B roughness; apparent detail only'}

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);SOURCE.mkdir(parents=True,exist_ok=True)
    report={'maps':[author('meadow',90277),author('woodland',90377)],'method':__doc__}
    for p in OUT.glob('*.png'):
        report.setdefault('sha256',{})[p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
        shutil.copy2(p,SOURCE/p.name)
    (SOURCE/'surface-source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    shutil.copy2(__file__,SOURCE/'author_ground.py')
    print(json.dumps(report,indent=2))
