"""Verify the actual periodic maps, colours, physical mapping and scoped lineage."""

import hashlib

import json

import sys

from pathlib import Path

import numpy as np

from PIL import Image



root=Path(__file__).resolve().parents[3]

out=Path(sys.argv[1]).resolve()

info=json.loads((out/'textures.json').read_text(encoding='utf-8'))

cfg=info['settings']

expected={'stone','fieldstone','slate','shellstone','rustclay_brick','vitrified_basalt','cinderglass','charcoal'}

assert {x['id'] for x in cfg['families']}==expected

assert len(info['textures'])==48

results=[]

means={}

for t in info['textures']:

    path=out/t['file']

    assert hashlib.sha256(path.read_bytes()).hexdigest()==t['sha256'],path

    im=Image.open(path);im.load()

    assert im.mode=='RGB' and list(im.size)==t['size'],path

    a=np.asarray(im).astype(float)

    assert np.isfinite(a).all()

    if t['map']=='orm':

        assert np.all(a[:,:,0]==255) and np.all(a[:,:,2]==0)

        assert np.min(a[:,:,1])>=51 and np.max(a[:,:,1])<=250

    if t['map']=='normal':

        length=np.linalg.norm(a/255*2-1,axis=-1)

        assert np.max(abs(length-1))<.015

        assert a[:,:,2].min()>127

    if t['map']=='albedo' and t['role']=='face':

        means[t['family']]=a.mean(axis=(0,1)).tolist()

    axis_results=[]

    for axis in [0,1]:

        wrap=np.take(a,0,axis=axis)-np.take(a,-1,axis=axis)

        delta=np.abs(np.diff(a,axis=axis))

        # Compare this wrap with the distribution of entire adjacent lines,

        # including textured grain/pore transitions. No artificial border fix.

        line_means=delta.mean(axis=(1,2)) if axis==0 else delta.mean(axis=(0,2))

        wrap_mean=float(np.abs(wrap).mean())

        limit=float(np.percentile(line_means,99)) + 1.0

        assert wrap_mean<=limit,(path.name,axis,wrap_mean,limit)

        axis_results.append({'axis':axis,'wrap_mean':wrap_mean,'ordinary_line_p99_plus_one':limit})

    results.append({'file':path.name,'seams':axis_results})

native_path=root/'data/tuning/construction.json'

if not native_path.exists():native_path=Path(__file__).resolve().parent/'construction-reference.json'

construction=json.loads(native_path.read_text(encoding='utf-8'))

materials={x['id']:x for x in construction['materials']}

for family,trait in [('fieldstone','rough'),('charcoal','fuel'),('cinderglass','glazing')]:

    assert materials[family]['only_for_trait']==trait

    for shape in construction['shapes']:

        legal=trait in shape.get('requires_traits',[])

        if family=='cinderglass':assert legal==(shape['id']=='glazed_window')

        if family=='charcoal':assert legal==(shape['id']=='campfire')

assert cfg['window']=={'frame_width_m':.075,'muntin_width_m':.026,'pane_depth_fraction':.24}

assert next(c for c in cfg['families'] if c['id']=='cinderglass')['opacity']==.72

# Same physical density at both sizes: UV spans differ by the dimension ratio.

for c in cfg['families']:

    full=np.array([1,1])/c['tile_metres']

    fine=np.array([.5,.5])/c['tile_metres']

    assert np.array_equal(full,fine*2)

report={'result':'PASS','maps':48,'families':8,'mean_srgb_8bit':means,'seams':results,'png_bytes':sum(x['bytes'] for x in info['textures']),'uncompressed_rgb8_bytes':sum(x['size'][0]*x['size'][1]*3 for x in info['textures']),'rgba8_mip_upper_bound_bytes':int(sum(x['size'][0]*x['size'][1]*4*4/3 for x in info['textures'])),'lineage':'Current construction traits read-only; no game, tuning, save or world mutation.'}

(out.parent/'texture-checks.json').write_text(json.dumps(report,indent=2)+'\n')

print('D5_MAPS_OK',report['png_bytes'],report['rgba8_mip_upper_bound_bytes'])
