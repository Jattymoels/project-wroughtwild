"""Immutable local handoff, with recipes, exact source, review and unedited captures."""
import sys,json,shutil
from pathlib import Path
from prerequisites import sha,verify
kit,review,run,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
shutil.copytree(kit,out/'source')
shutil.copytree(review,out/'review',ignore=shutil.ignore_patterns('.godot','*.uid'))
shutil.copytree(Path(__file__).parent,out/'recipe',ignore=shutil.ignore_patterns('__pycache__'))
shutil.copytree(run/'current-checks',out/'regression-logs',ignore=shutil.ignore_patterns('user','local-user','blender-user'))
evidence=out/'evidence';evidence.mkdir()
for name in ['prerequisites.json','selection.json','verification.json','python-parse.json','powershell-parse.json','environment.json']:
    shutil.copy2(run/name,evidence/name)
for folder in ['final-capture','final-walk','final-motion','final-benchmark','final-audit']:
    if (run/folder).exists():shutil.copytree(run/folder,evidence/folder,ignore=shutil.ignore_patterns('user','local-user','blender-user'))
shutil.copytree(run/'media-final',evidence/'media')
shutil.copy2(run/'current-v02/provenance.json',evidence/'current-native-provenance.json')
for name in ['build-v04.log','finish-final.log','import-budget-v05.log']:
    for p in run.glob(name+'*'):
        if p.is_file():shutil.copy2(p,evidence/p.name)
(evidence/'prerequisites-final.json').write_text(json.dumps(verify(),indent=2)+'\n')
shutil.copy2(Path(__file__).parent/'README.md',out/'README.md')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('B4_PACKAGE_OK',len(manifest),sum(e['bytes'] for e in manifest.values()),sha(out/'manifest.json'))
