"""Original, deterministic periodic material sources. No image input or light bake.

Run with the existing NumPy/Pillow runtime: surfaces.py FRESH_OUTPUT.

"""

import hashlib

import json

import sys

import time

from pathlib import Path

import numpy as np

from PIL import Image



HERE = Path(__file__).resolve().parent

CFG = json.loads((HERE / 'materials.json').read_text(encoding='utf-8'))

TAU = 2 * np.pi



def noise(n, sx, sy, rng):

    """Periodic smooth value noise, at cell centres (no duplicated edge texels)."""

    grid = rng.uniform(-1, 1, (sy, sx)).astype(np.float32)

    xx = (np.arange(n, dtype=np.float32) + .5) * sx / n

    yy = (np.arange(n, dtype=np.float32) + .5) * sy / n

    ix, iy = xx.astype(int), yy.astype(int)

    tx, ty = xx - ix, yy - iy

    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)

    a = grid[iy[:, None] % sy, ix[None, :] % sx]

    b = grid[iy[:, None] % sy, (ix[None, :] + 1) % sx]

    c = grid[(iy[:, None] + 1) % sy, ix[None, :] % sx]

    d = grid[(iy[:, None] + 1) % sy, (ix[None, :] + 1) % sx]

    return (a * (1 - tx) + b * tx) * (1 - ty[:, None]) + (c * (1 - tx) + d * tx) * ty[:, None]



def distance(a, centre):

    return (a - centre + .5) % 1 - .5



def mineral(c,n,edge,rng):

    y,x=np.mgrid[:n,:n].astype(np.float32)/n+.5/n

    # Place the periodic boundary through host interiors, not mortar centres.

    x=(x+.173)%1; y=(y+.137)%1

    fine=noise(n,210,210,rng); grain=noise(n,53,47,rng); slow=noise(n,7,6,rng)

    family=c['id']; base=np.array(c['colour'])

    h=.17*grain+.045*fine

    rgb=base*(1+.12*grain+.065*fine+.10*slow)[...,None]

    rough=np.full_like(x,c['roughness'])+.035*grain

    if family=='cinderglass':

        if edge:

            rgb=np.array([62,60,52])*(1+.18*grain+.05*fine)[...,None]

            rough=np.full_like(x,.76)+.05*grain

        else:

            smoke=noise(n,6,13,rng)+.3*noise(n,24,8,rng)

            rgb=base*(1+.18*smoke)[...,None]

            h=.7*noise(n,8,14,rng)+.025*grain

            rough=.22+.06*smoke

    elif family=='fieldstone':

        # Periodic irregular packed cobbles, not warped dressed courses.

        near=np.full_like(x,100);second=np.full_like(x,100);tone=np.zeros_like(x)

        for k in range(34):

            cx,cy=rng.random(2)

            d=(distance(x,cx)*2)**2+distance(y,cy)**2

            closer=d<near

            second=np.where(closer,near,np.minimum(second,d))

            near=np.minimum(near,d);tone=np.where(closer,rng.uniform(-1,1),tone)

        gap=np.sqrt(second)-np.sqrt(near)

        contact=np.clip(gap/.016,0,1)

        rgb=base*(.86+.23*tone+.12*grain+.07*fine)[...,None]

        rgb=rgb*contact[...,None]+np.array([49,48,40])*(1-contact[...,None])

        lichen=np.clip((noise(n,33,37,rng)-.30)*2,0,1)*np.clip((tone+.6),0,1)

        rgb=rgb*(1-.4*lichen[...,None])+np.array([136,141,97])*.4*lichen[...,None]

        h=.35*contact-.6*(1-contact)+.14*grain+.035*fine

    elif family=='charcoal':

        lines=np.maximum(0,np.sin(TAU*(x*13+.15*slow)))**18

        cracks=np.maximum(0,np.sin(TAU*(y*7+.26*slow)))**28

        pores=np.clip((-grain-.36)*3,0,1)

        ash=np.clip((slow-.48)*2,0,1)

        rgb=base*(1+.15*grain-.4*lines-.25*cracks-.25*pores)[...,None]+ash[...,None]*48

        h-=.5*lines+.4*cracks+.4*pores

    elif family=='vitrified_basalt':

        skin=np.clip((slow+.12)*3,0,1)

        breaks=np.maximum(0,np.sin(TAU*(x*5+y*3+.35*slow)))**28

        rgb*= (1+.23*skin-.3*breaks)[...,None]

        rough=.84-.61*skin+.08*breaks

        h+=.25*skin-.5*breaks

    else:

        rows=c['courses']; cols=c['columns']

        row=y*rows

        if family in ['fieldstone','slate']:

            row+=.14*noise(n,8,rows,rng)+.065*np.sin(TAU*x*3)

        # Even-numbered period in y preserves staggered wrap.

        # Odd course counts use a periodic sine stagger instead of parity.

        offset=(np.floor(row)%2)*.5 if rows%2==0 else .25*np.sin(TAU*(np.floor(row)%rows)/rows)

        col=x*cols+offset

        if family=='fieldstone':col+=.22*noise(n,cols,rows,rng)

        fy=row%1; fx=col%1

        jx=np.minimum(fx,1-fx); jy=np.minimum(fy,1-fy)

        width=.018 if family=='rustclay_brick' else .025

        joint=1-np.minimum(np.clip(jx/width,0,1),np.clip(jy/width,0,1))

        grid=rng.uniform(-1,1,(rows,cols))

        cell=grid[np.floor(row).astype(int)%rows,np.floor(col).astype(int)%cols]

        rgb*= (1+.14*cell)[...,None]

        joint_colour=np.array([151,136,113] if family=='rustclay_brick' else [58,58,49])

        rgb=rgb*(1-joint[...,None])+joint_colour*joint[...,None]

        h-=joint*.85

        if family=='stone':

            tool=np.sin(TAU*(x*95+y*4+.15*slow))*.02

            h+=tool

        if family=='fieldstone':

            lichen=np.clip((noise(n,35,31,rng)-.45)*3,0,1)

            rgb=rgb*(1-.22*lichen[...,None])+np.array([116,122,78])*.22*lichen[...,None]

        if family=='slate':

            strata=np.sin(TAU*(y*(31 if edge else 23)+.35*slow))

            rgb*= (1+.10*strata)[...,None];h+=.17*strata

        if family=='shellstone':

            fossil=np.zeros_like(x)

            for k in range(c['fossils'] if not edge else 15):

                cx,cy=rng.random(2); rad=rng.uniform(.012,.042)

                dx=distance(x,cx)/rad;dy=distance(y,cy)/(rad*rng.uniform(.7,1.3))

                theta=np.arctan2(dy,dx)+rng.uniform(-3,3);r=np.sqrt(dx*dx+dy*dy)

                ribs=(.5+.5*np.cos(theta*rng.integers(13,23)))**8

                outline=np.exp(-((r-.83)/.08)**2)

                shell=(r<.84)*(r>.15)*ribs*.65+outline*.7

                if k%4: shell*=np.sin(theta+.2)>rng.uniform(-.2,.7)

                fossil=np.maximum(fossil,shell)

            rgb=rgb*(1-.31*fossil[...,None]);h-=.62*fossil

        if family=='rustclay_brick':

            scorch=np.clip((slow-.1)*1.4,0,1)

            rgb*= (1-.18*scorch)[...,None]

    return rgb,rough,h





def build(out):

    started = time.perf_counter()

    out.mkdir(parents=True, exist_ok=False)

    records = []

    for idx, c in enumerate(CFG['families']):

        for edge in [False, True]:

            role = 'edge' if edge else 'face'

            n = CFG['edge_size_px'] if edge else CFG['face_size_px']

            tile = c['edge_metres'] if edge else c['tile_metres']

            rng = np.random.default_rng(CFG['seed'] + idx*103 + edge*7919)

            fn = mineral

            rgb, rough, height = fn(c,n,edge,rng)

            # Tangent normal +Y/OpenGL; image rows run down, UV V runs up.

            du = (np.roll(height,-1,axis=1)-np.roll(height,1,axis=1)) * n/(2*tile[0]) * c['relief_m']

            dv = -(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0)) * n/(2*tile[1]) * c['relief_m']

            normal = np.stack([-du,-dv,np.ones_like(du)],axis=-1)

            normal /= np.linalg.norm(normal,axis=-1)[...,None]

            orm = np.stack([np.ones_like(rough),np.clip(rough,.2,.98),np.zeros_like(rough)],axis=-1)*255

            maps = {'albedo':np.clip(rgb,0,255).astype('uint8'), 'normal':np.clip((normal*.5+.5)*255,0,255).astype('uint8'), 'orm':orm.astype('uint8')}

            for kind, array in maps.items():

                name = f'd5_{c["id"]}_{role}_{kind}.png'

                path = out/name

                Image.fromarray(array).save(path,compress_level=6)

                # Compare wrap steps to ordinary adjacent steps; no forced edge stripe.

                a = array.astype(float)

                wrap = [float(np.mean(abs(a[:,0]-a[:,-1]))),float(np.mean(abs(a[0]-a[-1])))]

                inner = [float(np.mean(abs(np.diff(a,axis=1)))),float(np.mean(abs(np.diff(a,axis=0))))]

                records.append({'file':name,'family':c['id'],'role':role,'map':kind,'size':[n,n],'tile_metres':tile,'colour_space':'sRGB' if kind=='albedo' else 'linear','bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'wrap_mean_delta_8bit':wrap,'interior_mean_delta_8bit':inner})

    (out/'textures.json').write_text(json.dumps({'schema':1,'settings':CFG,'textures':records,'seconds':time.perf_counter()-started,'source':'Original analytical periodic material fields; no source photograph, AI image or illumination bake.'},indent=2)+'\n')

    print(f'D5_TEXTURES_OK {len(records)} maps {time.perf_counter()-started:.2f}s')



if __name__ == '__main__':

    build(Path(sys.argv[1]).resolve())
