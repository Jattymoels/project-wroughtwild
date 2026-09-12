"""Seal a portable checked copy; canonical package is never opened by an engine."""
import json,shutil,sys
from pathlib import Path
from inputs import ROOT,sha
build,out=[Path(p).resolve() for p in sys.argv[1:3]]
assert out.is_relative_to(ROOT/'build/art07/e1') and not out.exists()
audit=json.loads((build/'audit.json').read_text());out.mkdir(parents=True)
shutil.copytree(build/'models/source',out/'source')
shutil.copytree(build/'models/runtime',out/'runtime')
shutil.copytree(build/'review/game',out/'review/game',ignore=shutil.ignore_patterns('.godot','*.tmp','*.previous','*.log','*.blend1','__pycache__'))
shutil.copytree(build/'review/data',out/'review/data')
shutil.copytree(build/'review/evidence',out/'evidence/godot')
shutil.copytree(build/'reopen-v02',out/'evidence/blender')
shutil.copytree(ROOT/'tools/wroughtwild-art07/e1',out/'recipes',ignore=shutil.ignore_patterns('__pycache__'))
shutil.copy2(ROOT/'tools/wroughtwild-art07/e1/launch-review.ps1',out/'Launch-review.ps1')
shutil.copy2(build/'audit.json',out/'audit.json')
shutil.copy2(ROOT/'build/art07/e1/v01/inputs/provenance.json',out/'provenance.json')
shutil.copytree(build/'regression-logs',out/'checks/regressions')
shutil.copytree(build/'render-final-logs',out/'checks/renderers')
shutil.copytree(build/'benchmark-logs',out/'checks/benchmarks')
for name in ['unit','art','integration-fixed','model','reopen-final']:
 for p in build.glob(name+'.log*'):shutil.copy2(p,out/'checks'/p.name)
for p in (ROOT/'build/art07/e1/v02/native-tests').glob('*.json'):shutil.copy2(p,out/'checks'/p.name)
for p in (ROOT/'build/art07/e1/v02/native-tests').glob('*-test.log'):shutil.copy2(p,out/'checks'/p.name)
files=[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()]
manifest={'slice':'ART-07E1','base':audit['base'],'status':'technically delivered; owner visual acceptance pending','files':files}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('E1_PACKAGE',out,'files',len(files),'bytes',sum(r['bytes'] for r in files),'manifest',sha(out/'manifest.json'))
