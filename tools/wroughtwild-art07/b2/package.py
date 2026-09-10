"""Immutable cache-free B2 delivery, including exact inputs and packed sources."""
import sys,json,shutil,hashlib
from pathlib import Path
root,out=map(Path,sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent;wt=recipe.parents[2]
def copy(p,d):d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d)
for name in ['groundcover-master.blend','kit-report.json','layout.json']:copy(root/'v08/kit'/name,out/'editable'/name)
copy(root/'v03/inspection/shrub-source.blend',out/'editable/shrub-source.blend')
for file in (root/'v08/kit/renders').glob('*.png'):copy(file,out/'evidence/blender'/file.name)
for file in (root/'v03/inspection').glob('*.png'):copy(file,out/'evidence/source-inspection'/file.name)
copy(root/'v03/inspection/inspection.json',out/'evidence/source-inspection/inspection.json')
for file in (root/'v02/shrub-raw').iterdir():
    if file.is_file() and file.suffix in ['.glb','.png','.json','.log','.stderr']:copy(file,out/'source/shrub'/file.name)
copy(wt/'docs/art/leyline-studies/2026-09-09/art07/b2/shrub-input-v01.png',out/'source/shrub/input.png')
for file in recipe.iterdir():
    if file.is_file():copy(file,out/'recipe'/file.name)
copy(recipe/'README.md',out/'README.md')
shutil.copytree(root/'v09/review',out/'review',ignore=shutil.ignore_patterns('.godot','*.import','*.uid','evidence'))
for renderer in ['forward_plus','gl_compatibility']:
    for file in (root/'v09/review/evidence'/renderer).iterdir():
        if not file.name.startswith('motion-'):copy(file,out/'evidence/godot'/renderer/file.name)
shutil.copytree(root/'v09/motion',out/'evidence/motion')
for file in (root/'v05/current-checks').glob('*'):
    if file.is_file():copy(file,out/'evidence/current-checks'/file.name)
for version in ['v02','v03','v06','v07','v08','v09']:
    for file in (root/version).glob('*.log*'):
        if file.is_file():copy(file,out/'evidence/logs'/version/file.name)
copy(root/'v08/audit.json',out/'evidence/audit.json')
copy(root/'v09/verification.json',out/'evidence/verification.json')
copy(root/'v06/provenance.json',out/'evidence/provenance.json')
for name in ['Capture-slot.json','Benchmark-slot.json']:copy(root/'v09'/name,out/'evidence/logs'/name)
copy(root/'v01/source-verification.json',out/'evidence/source-verification.json')
copy(root/'v05/native/provenance.json',out/'regression/native-provenance.json')
copy(root/'v05/native/bin/libwroughtwild_sim.windows.x86_64.dll',out/'regression/libwroughtwild_sim.windows.x86_64.dll')
copy(root/'v03/game-snapshot.zip',out/'regression/game-snapshot.zip')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('B2_PACKAGE_OK',len(manifest),sum(v['bytes'] for v in manifest.values()),hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
