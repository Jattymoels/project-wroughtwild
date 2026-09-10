"""Pristine standalone D6 source library; verify a copy, never import the master."""
import hashlib,json,shutil,sys
from pathlib import Path
here=Path(__file__).resolve().parent
version,textures,review,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
assert out.is_relative_to(here.parents[2]/'build/art07/d6');out.mkdir(parents=True,exist_ok=False)
shutil.copytree(here,out/'recipes',ignore=shutil.ignore_patterns('__pycache__','*.pyc','manifest.json'))
shutil.copytree(review,out/'review',ignore=shutil.ignore_patterns('.godot','evidence','*.uid'))
(out/'source').mkdir()
for name in ['d6_materials.blend','d6_proxies.glb','blender-audit.json']:shutil.copy2(version/'blender'/name,out/'source'/name)
shutil.copy2(version/'provenance.json',out/'provenance.json')
shutil.copy2(textures.parent/'texture-checks.json',out/'texture-checks.json')
(out/'evidence').mkdir()
curated=here.parents[2]/'docs/art/leyline-studies/2026-09-09/art07/d6'
for p in curated.iterdir():
    if p.suffix in ['.png','.webp']:shutil.copy2(p,out/'evidence'/p.name)
checked=here.parents[2]/'build/art07/d6/check3/review/evidence'
for p in checked.glob('*-benchmark.json'):shutil.copy2(p,out/'evidence'/p.name)
shutil.copy2(version/'reopened/reopen-audit.json',out/'evidence/reopen-audit.json')
(out/'README.txt').write_text('ART-07D6 worked metals: copy this entire package before opening.\nEditable packed source: source/d6_materials.blend\nGodot project: review/project.godot. 1-4 families; 0 overview; Escape exit.\nStatic proxies only, no paid placement or save state here.\nRead recipes/README.md for material binding, exact-envelope proxy limitations and reproduction.\nOwner acceptance pending; no ordinary game adoption.\n')
files=[]
for p in sorted(out.rglob('*')):
    if p.is_file():files.append({'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
manifest={'schema':1,'slice':'ART-07D6','base_commit':'f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d','selected_geometry':'v03; corrected metric UV and exact measured coupon depth metadata','selected_textures':'v01; unchanged original deterministic maps','families':json.loads((here/'materials.json').read_text())['families'],'files':files,'triangles':json.loads((out/'source/blender-audit.json').read_text())['triangles'],'owner_visual_acceptance':'pending','texture_contract':'12 shared 1024-square RGB maps; sRGB albedo; linear OpenGL +Y normal and ORM; static opaque unlit energy; metal roughness channels B/G','runtime_scope':'10 inspection proxies, not replacement native collision or world adoption'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print('D6_PACKAGE_OK',out,hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
