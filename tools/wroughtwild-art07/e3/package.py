"""Seal selected E3 bytes. Outputs are local only; no caches or owner saves."""
import json,shutil,subprocess,sys
from pathlib import Path
from inputs import ROOT,BASE,sha
models,review,inputs,out=[Path(p).resolve() for p in sys.argv[1:5]]
inspection=Path(sys.argv[5]).resolve() if len(sys.argv)>5 else models/'reopen'
checked=json.loads((inspection/'reopen.json').read_text());geometry=json.loads((models/'source/geometry.json').read_text())
assert checked['packed_images']==42 and len(checked['imports'])==31
for name,row in checked['imports'].items():assert row['objects']==1 and row['degenerates']==0 and row['triangles']==geometry[Path(name).stem]['triangles']
assert out.is_relative_to(ROOT/'build/art07/e3');out.mkdir(parents=True,exist_ok=False)
shutil.copytree(models/'source',out/'source');shutil.copytree(models/'runtime',out/'runtime')
shutil.copytree(Path(__file__).parent,out/'recipes',ignore=shutil.ignore_patterns('__pycache__'))
shutil.copy2(inputs/'provenance.json',out/'inputs.json')
tracked=subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','--name-only',BASE,'game','data'],text=True).splitlines()
for name in tracked:
 src=review/name;dst=out/'review'/name
 assert src.is_file(),src
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
for source,target in [(review/'game/e3',out/'review/game/e3'),(review/'game/assets/authored/e3',out/'review/game/assets/authored/e3')]:
 shutil.copytree(source,target,dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot','__pycache__'))
shutil.copy2(review/'game/bin/libwroughtwild_sim.windows.x86_64.dll',out/'review/game/bin/libwroughtwild_sim.windows.x86_64.dll')
shutil.copy2(review/'provenance.json',out/'review/provenance.json')
shutil.copytree(inspection,out/'evidence/blender')
shutil.copytree(review/'evidence',out/'evidence/godot')
shutil.copy2(Path(__file__).with_name('Launch-review.ps1'),out/'Launch-review.ps1')
proof=out/'proof';proof.mkdir()
for version in ['v01','v03','v04','v05','v06','v07','v08','v09','v10']:
 folder=ROOT/'build/art07/e3'/version
 for p in folder.glob('*.log*'):
  dst=proof/version/p.name;dst.parent.mkdir(exist_ok=True);shutil.copy2(p,dst)
for src in [ROOT/'build/art07/e3/v03/native-checks/commands.json',ROOT/'build/art07/e3/v03/native-checks/core-test.log',ROOT/'build/art07/e3/v01/native/provenance.json',ROOT/'build/art07/e3/v01/native/build.log',ROOT/'build/art07/e3/v01/native/CMakeLists.txt',models/'audit-final.json',ROOT/'build/art07/e3/v07/audit-final.json',ROOT/'build/art07/e3/v08/audit-final.json']:
 shutil.copy2(src,proof/(src.parent.name+'-'+src.name))
files=[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()]
manifest={'slice':'ART-07E3','base':BASE,'status':'technically checked source handoff; owner visual acceptance pending','files':files,'commands':'See recipes/README.md and Launch-review.ps1; copy before import','normal_adoption':False}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('E3_PACKAGE_OK',len(files),'files',sum(r['bytes'] for r in files),'bytes',sha(out/'manifest.json'))
