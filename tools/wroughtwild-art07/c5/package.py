"""Seal the selected C5 source, isolated review and evidence without engine caches."""
import sys,json,hashlib,shutil
from pathlib import Path
root,out,curated=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent
def copytree(source,target):
    shutil.copytree(source,target,ignore=shutil.ignore_patterns('.godot','__pycache__','*.blend1','evidence'))
copytree(root/'kit-v08',out/'models')
copytree(root/'review-v03/game',out/'review/game')
copytree(root/'review-v03/data',out/'review/data')
copytree(recipe,out/'tools/wroughtwild-art07/c5')
shutil.copytree(curated,out/'evidence')
shutil.copytree(root/'blender-v08',out/'blender-renders')
shutil.copytree(root/'review-v03/game/c5/evidence',out/'godot-evidence')
shutil.copy2(root/'review-v03/cook.json',out/'cook.json')
for folder in ['current-checks','native-v04','capture-v03','benchmark-v01']:
    target=out/'logs'/folder;target.mkdir(parents=True)
    for p in (root/folder).iterdir():
        if p.is_file():shutil.copy2(p,target/p.name)
for name in ['audit-v08.log','audit-v08.log.stderr','audit-v08.log.job.json','render-v08.log','render-v08.log.stderr','render-v08.log.job.json']:
    if (root/name).is_file():shutil.copy2(root/name,out/'logs'/name)
shutil.copytree(root/'source-inspection',out/'source-inspection',ignore=shutil.ignore_patterns('*.blend','*.blend1'))
shutil.copy2(recipe/'README.md',out/'README.md')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('C5_PACKAGE_OK',len(manifest),'bytes',sum(v['bytes'] for v in manifest.values()),'manifest',hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
