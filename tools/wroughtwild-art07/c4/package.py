"""Immutable C4 handoff with selected local artifacts and full evidence."""
import sys,shutil,json
from pathlib import Path
from prerequisites import sha,verify
root,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists()
worker=Path(__file__).resolve().parents[3]
assert out.is_relative_to(worker/'build/art07/c4')
assert (root/'verification.json').exists()
out.mkdir()
ignore=shutil.ignore_patterns('.godot','__pycache__','*.blend1')
shutil.copytree(root/'kit-v03',out/'models',ignore=ignore)
shutil.copytree(root/'review-v04',out/'review',ignore=ignore)
shutil.copytree(root/'native-v03',out/'native',ignore=shutil.ignore_patterns('.godot','__pycache__','*.zip'))
shutil.copytree(Path(__file__).parent,out/'recipe',ignore=ignore)
shutil.copytree(root/'ash-raw',out/'source/raw',ignore=shutil.ignore_patterns('user','local-user','blender-user'))
shutil.copytree(root/'inspection',out/'source/inspection',ignore=ignore)
shutil.copy2(worker/'docs/art/leyline-studies/2026-09-09/art07/c4/ash-input-v01.png',out/'source/ash-input-v01.png')
shutil.copytree(root/'media',out/'evidence/curated')
shutil.copytree(root/'blender-v03',out/'evidence/blender')
e=out/'evidence'
for name in ['prerequisites.json','provenance.json','audit-v03.json','verification.json','environment-final.json']:
    shutil.copy2(root/name,e/name)
for name in ['current-checks','captures-v04','motion-v04','walk-v04','native-rendered-v03','benchmark-v04']:
    shutil.copytree(root/name,e/name,ignore=shutil.ignore_patterns('user','local-user','blender-user'))
for name in ['inspection','build-v03','audit-v03','render_master-v03','review-v04-import','native-v03-import','pause-v04']:
    for p in root.glob(name+'.log*'):shutil.copy2(p,e/p.name)
shutil.copy2(Path(__file__).parent/'README.md',out/'README.md')
(e/'prerequisites-final.json').write_text(json.dumps(verify(),indent=2)+'\n')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('C4_HANDOFF',str(out),'files',len(manifest),'bytes',sum(x['bytes'] for x in manifest.values()),'manifest_sha256',sha(out/'manifest.json'))
