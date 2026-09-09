"""Create a pristine, hashed D4 handoff. Import a copy, never this directory."""
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
for name in ['d4_materials.blend','d4_proxies.glb','blender-audit.json']:
    shutil.copy2(version/'blender'/name,out/'source'/name)
for name in ['texture-checks.json','approved-packages.json']:
    shutil.copy2(version/name,out/name)
(out/'README.txt').write_text('ART-07D4: seven static ordinary materials. Copy this whole folder before engine import.\nPacked editable master: source/d4_materials.blend\nIsolated Godot project: review/project.godot; keys 1-7, 0, Escape.\nNo native game state or placement interaction exists in this swatch review.\nSee recipes/README.md and the repository D4 receipt for mapping, reproduction and checks.\n')
files=[]
for path in sorted(out.rglob('*')):
    if path.is_file():files.append({'path':path.relative_to(out).as_posix(),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
manifest={'schema':1,'slice':'ART-07D4','base_commit':'56ce6bbe343012205690cf669491372958b80662','selected_surface_version':'v02','families':json.loads((here/'materials.json').read_text())['families'],'proxy_triangles':312,'proxy_count':26,'proxy_purpose':'Static exact-size inspection envelopes only, no added legal forms.','files':files,'texture_contract':'d4_<id>_<face|edge>_<albedo|normal|orm>.png; albedo sRGB; normal +Y and ORM linear; AO=1, metal=0, no alpha/emission; metric UV repeat from family entries','blender_to_godot':'(x,y,z) -> (x,z,-y), metres','owner_visual_acceptance':'pending'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('D4_HANDOFF_OK',out,hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
