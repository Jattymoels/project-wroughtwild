"""Seal F1 source, frozen native review, recipes, provenance and curated evidence."""
import json,hashlib,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];TOOL=Path(__file__).resolve().parent
BASE='bbcb3a7dfd235e8f803141ccb57c38e03d6c1708'
def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def copy(a,b):b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a,b)
assets,game,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
assert all(p.is_relative_to(ROOT/'build/art07/f1') for p in [assets,game,out])
out.mkdir(parents=True,exist_ok=False)
for p in assets.iterdir():
    if p.suffix in ['.blend','.glb','.json','.png']:copy(p,out/'source'/p.name)
for kind in ['lanternheart','stormglass']:
    for name in ['source.glb','source_cutout.png','source_base.png','generation.log','generation.log.json','files.json']:
        copy(ROOT/'build/art07/f1/v05'/kind/name,out/'raw'/kind/name)
for rel in subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','--name-only',BASE,'game','data'],text=True).splitlines():
    copy(game.parent/rel,out/'review'/rel)
copy(game/'bin/libwroughtwild_sim.windows.x86_64.dll',out/'review/game/bin/libwroughtwild_sim.windows.x86_64.dll')
for p in (game/'f1').rglob('*'):
    if p.is_file() and p.suffix in ['.glb','.gd','.gdshader','.tscn','.json'] and 'evidence' not in p.parts:
        copy(p,out/'review/game'/p.relative_to(game))
for p in (game/'f1/evidence').glob('*'):
    if p.is_file() and p.suffix in ['.json','.png']:copy(p,out/'review/game/f1/evidence'/p.name)
for p in TOOL.iterdir():
    if p.is_file() and p.name!='manifest.json':copy(p,out/'recipes'/p.name)
for p in (ROOT/'docs/art/leyline-studies/2026-09-09/art07/f1').iterdir():
    if p.is_file():copy(p,out/'evidence'/p.name)
for rel in ['v01/prerequisites.json','v03/native/provenance.json','v05/inspection/inspection.json','v05/native-checks/commands.json','v05/native-checks/core-test.log','v05/native-checks/world-test.log']:
    copy(ROOT/'build/art07/f1'/rel,out/'provenance'/rel.replace('/','-'))
for folder in ['v05/native-regressions','v07','v08','v08/native-regressions','v09']:
    path=ROOT/'build/art07/f1'/folder
    if path.exists():
        for p in path.iterdir():
            if p.is_file() and p.suffix in ['.log','.json','.err']:copy(p,out/'provenance'/folder.replace('/','-')/p.name)
copy(TOOL/'CONTRACT.md',out/'CONTRACT.md');copy(TOOL/'launch.ps1',out/'launch.ps1')
(out/'README.md').write_text('ART-07F1 source candidate. Copy and verify with recipes/fresh_copy.py before importing.\nRun launch.ps1 -Mode import, then launch.ps1 -Renderer forward_plus -Show.\nSee CONTRACT.md and recipes/README.md. Saves belong to the copy. Owner visual acceptance and ordinary adoption remain separate.\n')
records=[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()]
(out/'manifest.json').write_text(json.dumps({'slice':'ART-07F1','base_commit':BASE,'owner_visual_acceptance':'pending','ordinary_adoption':False,'files':records},indent=2)+'\n')
print('F1_SEALED',out,len(records),sha(out/'manifest.json'))
