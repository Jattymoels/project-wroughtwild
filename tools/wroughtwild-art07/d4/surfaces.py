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
CFG = json.loads((HERE / 'materials.json').read_text())
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

def wood(c, n, edge, rng):
    y, x = np.mgrid[:n, :n].astype(np.float32) / n + .5 / n
    fine = noise(n, 510, 190, rng)
    slow = noise(n, 5, 4, rng)
    fibres = noise(n, 170, 9, rng)
    if edge:
        # Offset growth centre outside the representative cut, smoothly periodic.
        radius = np.sqrt((np.sin(np.pi * (x - .17)) * 1.05)**2 + (np.sin(np.pi * (y - .38)))**2 + .004)
        phase = radius * (c['rings'] * 1.9) + .14 * slow
    else:
        warp = .025 * np.sin(TAU * y) + .009 * np.sin(TAU * (3*y + .23))
        warp += .016 * slow
        # A lengthwise slice through annual rings creates cathedral tips.
        # The longitudinal height term is smaller on straight-grained pine.
        radial_x = np.sin(np.pi*(x + .15 + c['warp']*warp))
        radial_y = .20*c['warp']*np.sin(np.pi*(y+.11))
        phase = np.sqrt(radial_x**2 + radial_y**2 + .006) * c['rings']*1.6
        phase += .12*noise(n, 42, 12, rng) + .035*fine
    late = np.exp(-((np.sin(TAU * phase) + .72) / .19)**2)
    broad = np.sin(TAU * phase) * .07 + np.sin(TAU * phase * 2) * .025
    pore = np.clip((-fibres - .3) * 2, 0, 1) * (.35 + .65*late)
    knot = np.zeros_like(x)
    knot_rings = np.zeros_like(x)
    if not edge:
        for _ in range(c['knots']):
            dx = distance(x, rng.uniform(.1, .9)) / rng.uniform(.025, .04)
            dy = distance(y, rng.uniform(.1, .9)) / rng.uniform(.012, .024)
            r = np.sqrt(dx*dx + dy*dy)
            knot = np.maximum(knot, np.exp(-r*r*1.7))
            knot_rings += np.cos(r * 10) * np.exp(-r*r*.2) * .10
    chatter = noise(n, 28, 180, rng) * np.clip(noise(n, 7, 11, rng) - .35, 0, 1)
    value = 1 + broad - .24 * late + .11 * slow + .15 * fibres + .10 * fine - .40 * knot + knot_rings
    value -= pore * (.27 if c['id'] == 'bog_oak' else .09)
    height = -.20*late + .30*fibres + .13*fine - .32*pore - .35*knot
    if c['id'] == 'wood':
        value += .16*chatter
        height += .55*chatter
    colour = np.array(c['colour'], np.float32)
    rgb = value[..., None] * colour
    rough = c['roughness'] + .07 * fibres + .04 * late
    if c['id'] == 'resinheart':
        pocket = np.clip((noise(n, 50, 7, rng) - .48) * 3, 0, 1) * np.clip((late - .25)*2, 0, 1)
        rgb = rgb * (1 - .25*pocket[...,None]) + pocket[...,None]*np.array([19,3,-5])
        rough -= .35 * pocket
    if c['id'] == 'ash_wood':
        silver = np.clip(fibres + .35, 0, 1) * .17
        rgb = rgb * (1 - silver[..., None]) + silver[..., None] * np.array([201,200,193])
    if edge:
        rgb *= 1.08 if c['id'] == 'pine' else 1.025
    return rgb, rough, height

def reed(c, n, edge, rng):
    y, x = np.mgrid[:n, :n].astype(np.float32) / n + .5/n
    irregular = noise(n, 24, 32, rng)
    # Horizontal weft bundles wrap eight vertical stakes, alternating parity.
    row = y*c['courses'] + .08*np.sin(TAU*x*4) + .025*noise(n, 16, 16, rng)
    col = x*c['stakes'] + .045*np.sin(TAU*y*2)
    fy, fx = row % 1, col % 1
    horizontal = np.maximum(np.sin(np.pi*fy), 0)**.18
    vertical = np.exp(-((fx-.5)/.17)**6)
    over = ((np.floor(row)+np.floor(col)) % 2) == 0
    top_vertical = vertical * over
    gaps = (1-horizontal)**.4
    fibre = .03*np.sin(TAU*row*7) + .045*noise(n, 240, 180, rng)
    if edge:
        # Closed bundle cross sections on the cut edge, independent of face weave.
        r = np.sqrt(((x*24 % 1)-.5)**2 + ((y*24 % 1)-.5)**2)
        rgb = np.array(c['colour']) * (1.07 - .38*np.exp(-(r/.18)**2) - .25*np.clip((r-.4)*8,0,1))[...,None]
        h = -np.exp(-(r/.18)**2)*.5 + .1*irregular
    else:
        value = .98 + .15*irregular + fibre - .53*gaps
        horizontal_rgb = np.array(c['colour']) * value[...,None]
        vertical_rgb = np.array([128,99,54]) * (1+.08*np.sin(TAU*col*11)+.13*irregular)[...,None]
        rgb = horizontal_rgb*(1-top_vertical[...,None]) + vertical_rgb*top_vertical[...,None]
        h = .55*horizontal*(1-top_vertical) + .88*top_vertical + fibre - .25*gaps
    return rgb, c['roughness'] + irregular*.045, h

def cork(c, n, edge, rng):
    y, x = np.mgrid[:n, :n].astype(np.float32) / n + .5/n
    grain = noise(n, 34, 34, rng)
    small = noise(n, 380, 380, rng)
    ragged = noise(n, 180, 180, rng)
    nearest = np.full_like(x,100)
    cell = np.zeros_like(x)
    pores = np.zeros_like(x)
    rim = np.zeros_like(x)
    for _ in range(c['pores']):
        cx, cy = rng.random(2)
        radius = rng.uniform(.005, .020)
        dx, dy = distance(x,cx)/radius, distance(y,cy)/(radius*rng.uniform(.5,1.4))
        dist = distance(x,cx)**2 + distance(y,cy)**2
        closer = dist < nearest
        nearest = np.minimum(dist,nearest)
        cell = np.where(closer,rng.uniform(-1,1),cell)
        r = np.sqrt(dx*dx+dy*dy) + .35*grain + .5*ragged
        pores = np.maximum(pores, np.clip((1-r)*3,0,1))
        rim = np.maximum(rim, np.exp(-((r-1)/.25)**2))
    micro_pores = np.clip((-small-.38)*2.2,0,1)
    value = 1 + grain*.14 + cell*.11 + small*.18 - .45*pores - .22*micro_pores + .035*rim
    h = .18*grain + .05*cell + .14*small - .85*pores - .3*micro_pores + .07*rim
    if edge:
        strata = np.sin(TAU*(y*14 + .19*noise(n,8,7,rng)))
        value += .09*strata
        h += .15*strata
    return np.array(c['colour'])*value[...,None], c['roughness']+.035*grain, h

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
            fn = reed if c['id'] == 'woven_reed' else cork if c['id'] == 'corkbark' else wood
            rgb, rough, height = fn(c,n,edge,rng)
            # Tangent normal +Y/OpenGL; image rows run down, UV V runs up.
            du = (np.roll(height,-1,axis=1)-np.roll(height,1,axis=1)) * n/(2*tile[0]) * c['relief_m']
            dv = -(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0)) * n/(2*tile[1]) * c['relief_m']
            normal = np.stack([-du,-dv,np.ones_like(du)],axis=-1)
            normal /= np.linalg.norm(normal,axis=-1)[...,None]
            orm = np.stack([np.ones_like(rough),np.clip(rough,.2,.98),np.zeros_like(rough)],axis=-1)*255
            maps = {'albedo':np.clip(rgb,0,255).astype('uint8'), 'normal':np.clip((normal*.5+.5)*255,0,255).astype('uint8'), 'orm':orm.astype('uint8')}
            for kind, array in maps.items():
                name = f'd4_{c["id"]}_{role}_{kind}.png'
                path = out/name
                Image.fromarray(array).save(path,compress_level=6)
                # Compare wrap steps to ordinary adjacent steps; no forced edge stripe.
                a = array.astype(float)
                wrap = [float(np.mean(abs(a[:,0]-a[:,-1]))),float(np.mean(abs(a[0]-a[-1])))]
                inner = [float(np.mean(abs(np.diff(a,axis=1)))),float(np.mean(abs(np.diff(a,axis=0))))]
                records.append({'file':name,'family':c['id'],'role':role,'map':kind,'size':[n,n],'tile_metres':tile,'colour_space':'sRGB' if kind=='albedo' else 'linear','bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'wrap_mean_delta_8bit':wrap,'interior_mean_delta_8bit':inner})
    (out/'textures.json').write_text(json.dumps({'schema':1,'settings':CFG,'textures':records,'seconds':time.perf_counter()-started,'source':'Original analytical periodic material fields; no source photograph, AI image or illumination bake.'},indent=2)+'\n')
    print(f'D4_TEXTURES_OK {len(records)} maps {time.perf_counter()-started:.2f}s')

if __name__ == '__main__':
    build(Path(sys.argv[1]).resolve())
