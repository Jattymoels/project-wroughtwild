"""Seal deliberate F4 source, frozen review, evidence and reconstruction recipes."""
import json,hashlib,shutil,sys,subprocess
from pathlib import Path
from inputs import ROOT,BASE
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def copy(a,b):b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a,b)
assets,review,evidence,runs,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
assert out.is_relative_to(ROOT/'build/art07/f4');out.mkdir(parents=True,exist_ok=False)
for folder in ['source','runtime','textures']:shutil.copytree(assets/folder,out/folder)
files=subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','--name-only',BASE,'game','data'],text=True).splitlines()
for rel in files:copy(review/rel,out/'review'/rel)
for folder in ['f4','e2','assets/authored/e2']:
 for p in (review/'game'/folder).rglob('*'):
  if p.is_file() and p.suffix not in ['.import','.uid']:copy(p,out/'review/game'/p.relative_to(review/'game'))
copy(review/'game/bin/libwroughtwild_sim.windows.x86_64.dll',out/'review/game/bin/libwroughtwild_sim.windows.x86_64.dll')
copy(review/'provenance.json',out/'provenance/review.json')
shutil.copytree(review/'evidence',out/'evidence/engine')
shutil.copytree(evidence,out/'evidence/curated')
for p in runs.rglob('*'):
 if p.is_file() and 'blender-user' not in p.parts and p.suffix not in ['.stdout','.stderr']:copy(p,out/'provenance/final'/p.relative_to(runs))
for name in ['v01/inputs.json','v02/native/provenance.json','v03/native-checks/commands.json','v03/native-checks/core-test.log','v03/native-checks/world-test.log','v03/native-checks/contraptions-test.log']:
 p=ROOT/'build/art07/f4'/name
 if p.exists():copy(p,out/'provenance'/name.replace('/','-'))
for p in Path(__file__).parent.iterdir():
 if p.is_file():copy(p,out/'recipes'/p.name)
copy(Path(__file__).parent/'launch.ps1',out/'launch.ps1')
for name in ['f4-held.json','f4-exhausted.json']:copy(ROOT/'build/art07/f4/u/F4Native'/name,out/'checkpoints'/name)
(out/'README.md').write_text('ART-07F4 technically delivered; owner visual acceptance pending.\nRead recipes/README.md and recipes/CONTRACT.md. Run recipes/fresh_copy.py PACKAGE FRESH_DIRECTORY, then launch.ps1 -Mode import in that fresh copy. Never import this sealed package directly.\n')
records=[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()]
(out/'manifest.json').write_text(json.dumps({'slice':'ART-07F4','base':BASE,'ordinary_adoption':False,'owner_visual_acceptance':'pending','files':records},indent=2)+'\n')
print('F4_PACKAGE_OK',len(records),out,sha(out/'manifest.json'))
