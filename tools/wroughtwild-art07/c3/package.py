"""Freeze a checked C3 handoff; fresh copies alone may be imported/reviewed."""
import sys,json,shutil
from pathlib import Path
from prerequisites import sha,verify

kit,review,native,run,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
assert not out.exists()
assert out.is_relative_to(Path(__file__).resolve().parents[3]/'build/art07/c3')
out.mkdir(parents=True)
ignore=shutil.ignore_patterns('.godot','*.uid','__pycache__','*.blend1','current.zip')
shutil.copytree(kit,out/'source',ignore=ignore)
shutil.copytree(review,out/'review',ignore=ignore)
shutil.copytree(native,out/'native',ignore=ignore)
shutil.copytree(Path(__file__).parent,out/'recipe',ignore=ignore)
shutil.copy2(Path(__file__).parent/'README.md',out/'README.md')
logs_ignore=shutil.ignore_patterns('user','local-user','blender-user')
shutil.copytree(run/'current-checks',out/'regression-logs',ignore=logs_ignore)
evidence=out/'evidence';evidence.mkdir()
for name in ['prerequisites.json','environment.json','audit-v05.json','validation.json','powershell-parse.json']:
    shutil.copy2(run/name,evidence/name)
for folder in ['final-capture','final-motion','final-walk','final-native-v05','final-benchmark']:
    shutil.copytree(run/folder,evidence/folder,ignore=logs_ignore)
for name in ['inspect.log','build-v08.log','audit-v05.log','final-review-import.log','final-native-import-v03.log']:
    for p in run.glob(name+'*'):
        if p.is_file():shutil.copy2(p,evidence/p.name)
shutil.copytree(run/'inspection',evidence/'inspection',ignore=ignore)
shutil.copytree(run/'media-v02',evidence/'media')
(evidence/'prerequisites-final.json').write_text(json.dumps(verify(),indent=2)+'\n')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('C3_PACKAGE_OK',len(manifest),sum(e['bytes'] for e in manifest.values()),sha(out/'manifest.json'))
