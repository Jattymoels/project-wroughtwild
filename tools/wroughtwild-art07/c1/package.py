"""Selected C1 handoff; large sources/evidence remain local, all files hashed before import."""
import sys,json,shutil,hashlib
from pathlib import Path
root,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).resolve().parent
ignore=shutil.ignore_patterns('.godot','__pycache__','*.pyc','*.blend1','user','local-user','blender-user','evidence')
shutil.copytree(root/'kit-v06',out/'source',ignore=ignore)
shutil.copytree(root/'review-v05',out/'review',ignore=ignore)
shutil.copytree(root/'native-v06',out/'native',ignore=ignore)
shutil.copytree(recipe,out/'recipes',ignore=ignore)
shutil.copy2(recipe/'README.md',out/'README.md');shutil.copy2(recipe/'launch.ps1',out/'launch.ps1')
(out/'raw').mkdir()
for p in (root/'clay-raw').iterdir():
    if p.is_file():shutil.copy2(p,out/'raw'/p.name)
shutil.copy2(recipe.parents[2]/'docs/art/leyline-studies/2026-09-09/art07/c1/clay-input-v01.png',out/'raw/clay-input-v01.png')
shutil.copy2(recipe/'clay-prompt.txt',out/'raw/clay-prompt.txt')
shutil.copy2(root/'provenance-final.json',out/'provenance.json')
for sub,src in [('inspection','inspection'),('blender','blender-v06'),('habitat','review-v05/evidence'),('native','native-v06/game/c1/evidence'),('motion','media-v05')]:shutil.copytree(root/src,out/'evidence'/sub)
logs=out/'evidence/logs';logs.mkdir()
for name in ['current-checks','native-render-v04','native-render-v06','capture-v04','capture-v05','benchmark-v05']:
    src=root/name
    if src.exists():
        for p in src.rglob('*'):
            if p.is_file() and (p.name.endswith(('.log','.stderr','.job.json')) or p.name in ['conditions.json','gpu-before.csv','gpu-after.csv']):
                dest=logs/name/p.relative_to(src);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
for p in root.glob('*'):
    if p.is_file() and (p.suffix in ['.json','.log','.stderr']):shutil.copy2(p,logs/p.name)
for renderer in ['forward_plus','gl_compatibility']:
    for name in ['c1-partial.json','c1-final.json']:
        matches=list((root/'native-render-v06'/renderer).rglob(name));assert len(matches)==1,(renderer,name,matches)
        dest=out/'evidence/native-checkpoints'/renderer/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(matches[0],dest)
records={}
for p in sorted(out.rglob('*')):
    if p.is_file():
        with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
        records[p.relative_to(out).as_posix()]={'bytes':p.stat().st_size,'sha256':h}
(out/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
print(json.dumps({'path':str(out),'files':len(records),'bytes':sum(r['bytes'] for r in records.values()),'manifest_sha256':hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest()},indent=2))
