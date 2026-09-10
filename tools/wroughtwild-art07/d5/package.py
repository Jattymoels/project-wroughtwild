"""Create a pristine, hashed D5 handoff. Import a copy, never this directory."""

import hashlib

import json

import shutil

import sys

from pathlib import Path



here=Path(__file__).resolve().parent

version=Path(sys.argv[1]).resolve()

out=Path(sys.argv[2]).resolve()

out.mkdir(parents=True,exist_ok=False)

shutil.copytree(here,out/'recipes',ignore=shutil.ignore_patterns('__pycache__','*.pyc'))

shutil.copy2(here.parents[2]/'data/tuning/construction.json',out/'recipes/construction-reference.json')

review=Path(sys.argv[3]).resolve() if len(sys.argv)>3 else version/'review-template'

# Preserve portable source import SETTINGS (including mipmaps), never caches.

shutil.copytree(review,out/'review',ignore=shutil.ignore_patterns('.godot','*.uid','evidence'))

(out/'source').mkdir()

for name in ['d5_materials.blend','d5_proxies.glb','blender-audit.json']:

    shutil.copy2(version/'blender'/name,out/'source'/name)

for name in ['texture-checks.json','approved-packages.json']:

    shutil.copy2(version/name,out/name)

(out/'README.txt').write_text('ART-07D5: eight static ordinary materials. Copy this whole folder before engine import.\nPacked editable master: source/d5_materials.blend\nIsolated Godot project: review/project.godot; keys 1-8, 0, Escape.\nNo native game state or placement interaction exists in this swatch review.\nSee recipes/README.md and the repository D5 receipt for mapping, reproduction and checks.\n')

shutil.copy2(here/'launch-review.ps1',out/'launch-review.ps1')

shutil.copytree(version/'evidence',out/'evidence')
shutil.copytree(version/'checks',out/'checks')

files=[]

for path in sorted(out.rglob('*')):

    if path.is_file():files.append({'path':path.relative_to(out).as_posix(),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

manifest={'schema':1,'slice':'ART-07D5','base_commit':'f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d','selected_surface_version':'v03','families':json.loads((here/'materials.json').read_text(encoding='utf-8'))['families'],'proxy_triangles':json.loads((version/'blender/blender-audit.json').read_text(encoding='utf-8'))['triangles'],'proxy_count':40,'proxy_purpose':'Static exact-size inspection envelopes only, no added legal forms.','files':files,'texture_contract':'d5_<id>_<face|edge>_<albedo|normal|orm>.png; albedo sRGB; normal +Y and ORM linear; AO=1, metal=0, pane material alpha=0.72; opaque frame; no emission; metric UV repeat from family entries','blender_to_godot':'(x,y,z) -> (x,z,-y), metres','owner_visual_acceptance':'pending'}

(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

print('D5_HANDOFF_OK',out,hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
