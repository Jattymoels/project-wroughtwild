"""Collect unaltered render PNGs and encode actual camera frames as motion WebP.

No synthesis, painting or retouching of evidence. Resizing for animation only.

"""

import hashlib

import json

import shutil

import sys

from pathlib import Path

from PIL import Image



def motion(review,dest,renderer):

    frames=[]

    paths=sorted((review/'evidence'/(renderer+'-motion')).glob('*.png'))

    assert len(paths)==96

    for path in paths:

        with Image.open(path) as im:frames.append(im.convert('RGB').resize((960,540),Image.Resampling.LANCZOS))

    frames[0].save(dest/(renderer+'-motion.webp'),save_all=True,append_images=frames[1:],duration=42,loop=0,quality=80,method=4)



if sys.argv[1]=='--motion-only':

    review,dest=map(lambda x:Path(x).resolve(),sys.argv[2:])

    dest.mkdir(parents=True,exist_ok=False)

    for renderer in ['forward_plus','gl_compatibility']:motion(review,dest,renderer)

    print('D5_MOTION_ENCODED',dest)

    raise SystemExit(0)



version,review,dest=map(lambda x:Path(x).resolve(),sys.argv[1:])

dest.mkdir(parents=True,exist_ok=False)

names=['blender-overview.png']+['blender-'+c+'.png' for c in ['stone','fieldstone','slate','shellstone','rustclay_brick','vitrified_basalt','cinderglass','charcoal']]

for name in names:shutil.copy2(version/'blender'/name,dest/name)

for renderer in ['forward_plus','gl_compatibility']:

    for name in ['overview','stone','fieldstone','slate','shellstone','rustclay_brick','vitrified_basalt','cinderglass','charcoal','light','shade','dark','unlit','far']:

        filename=renderer+'-'+name+'.png'

        shutil.copy2(review/'evidence'/filename,dest/filename)

    cached=version/'motion-preview'/(renderer+'-motion.webp')

    if cached.exists():shutil.copy2(cached,dest/cached.name)

    else:motion(review,dest,renderer)

    shutil.copy2(review/'evidence'/(renderer+'-benchmark.json'),dest/(renderer+'-benchmark.json'))

files=[]

for path in sorted(dest.iterdir()):

    if path.is_file():files.append({'file':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

(dest/'evidence-manifest.json').write_text(json.dumps({'files':files,'motion':'96 actual engine camera frames, 24 fps, resized to 960x540 and encoded WebP; materials static; no source illustration substituted.'},indent=2)+'\n')

print('D5_EVIDENCE_OK',len(files))
