"""Seal source, frozen native review, evidence and exact reproducible recipes.

No .godot imports, test saves, compiler outputs or live owner data. The large
unchanged game assets are review dependencies, not proposed adoption files.
"""
import json, shutil, subprocess, sys
from pathlib import Path
from inputs import ROOT,BASE,sha,verify
source,review,evidence,out=[Path(p).resolve() for p in sys.argv[1:5]]
assert out.is_relative_to(ROOT/'build/art07/e2');out.mkdir(parents=True,exist_ok=False)
audit=verify()
def copy(src,dst):
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
copy(source/'source/e2_forges.blend',out/'source/e2_forges.blend')
copy(source/'source/geometry.json',out/'source/geometry.json')
copy(source/'reopen/reopen.json',out/'source/reopen.json')
for p in (source/'runtime').glob('*.glb'):copy(p,out/'runtime'/p.name)
paths=subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','--name-only',BASE,'game','data'],text=True).splitlines()
for rel in paths:copy(review/rel,out/'review'/rel)
for p in (review/'game/e2').rglob('*'):
    if p.is_file() and not p.name.endswith('.uid'):copy(p,out/'review/game/e2'/p.relative_to(review/'game/e2'))
for p in (review/'game/assets/authored/e2').glob('*.glb'):copy(p,out/'review/game/assets/authored/e2'/p.name)
copy(review/'game/bin/libwroughtwild_sim.windows.x86_64.dll',out/'review/game/bin/libwroughtwild_sim.windows.x86_64.dll')
copy(review/'provenance.json',out/'review/provenance.json')
for p in evidence.rglob('*'):
    if p.is_file():copy(p,out/'evidence'/p.relative_to(evidence))
for folder,target in [(source/'reopen','source-inspection'),(review/'evidence','review-evidence')]:
    for p in folder.rglob('*'):
        if p.is_file() and p.name!='station-roundtrip.json':copy(p,out/target/p.relative_to(folder))
for folder in ['v03/native-checks','v04/native-contraptions','v04/regressions','v04/regressions-real-audio','v04/lf-chain','v04/rendered-clean','v04/benchmarks-clean']:
    for p in (ROOT/'build/art07/e2'/folder).rglob('*'):
        if p.is_file() and (p.suffix in ['.log','.json']):copy(p,out/'checks'/folder/p.relative_to(ROOT/'build/art07/e2'/folder))
for name in ['author.log','author.log.json','reopen.log','reopen.log.json','final-audit.json']:
    copy(source/name,out/'checks'/name)
copy(ROOT/'build/art07/e2/v01/inputs/provenance.json',out/'checks/original-inputs.json')
copy(ROOT/'build/art07/e2/v01/native/provenance.json',out/'checks/native-build.json')
for p in Path(__file__).parent.iterdir():
    if p.is_file() and p.name!='manifest.json':copy(p,out/'recipes'/p.name)
copy(Path(__file__).with_name('launch-review.ps1'),out/'launch-review.ps1')
(out/'provenance.json').write_text(json.dumps(audit,indent=2)+'\n')
files=[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()]
manifest={'schema':1,'slice':'ART-07E2','base':BASE,'selection':'v04 source; current isolated read-only state adapter','files':files,'bytes':sum(f['bytes'] for f in files),'scope':'source handoff and isolated review, not normal-game adoption','owner_visual_acceptance':'pending'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('E2_PACKAGE_OK',len(files),manifest['bytes'],sha(out/'manifest.json'))
