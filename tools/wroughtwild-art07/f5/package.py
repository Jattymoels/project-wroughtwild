"""Freeze a fresh four-colour handoff, retaining original recipes and cutouts."""
import sys,shutil,json
from pathlib import Path
from audit import DEPOT,PACKAGES,read,sha
from material_manifest import CUTOUTS,INSPECTIONS
work,out=map(lambda p:Path(p).resolve(),sys.argv[1:3]);assert not out.exists()
def excluded(path):
    return any(x in ('.godot','review-appdata','__pycache__') for x in path.parts) or path.suffix in ('.import','.uid','.pyc')
for source in work.rglob('*'):
    rel=source.relative_to(work)
    if not source.is_file() or excluded(rel):continue
    target=out/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
for colour,relative in PACKAGES.items():
    original=DEPOT/relative;manifest=read(original/'manifest.json');files=manifest.get('files',manifest)
    for name,expected in files.items():
        if name.startswith('recipe/'):
            target=out/colour/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(original/name,target)
            assert sha(target)==expected['sha256']
    for name,source in [('retained-cutout.png',DEPOT/CUTOUTS[colour]),('original-inspection.json',DEPOT/INSPECTIONS[colour])]:
        shutil.copy2(source,out/colour/'provenance'/name)
    # Every retained asset/texture/config/scene and original native test remains exact.
    differences=[]
    for name,expected in files.items():
        target=out/colour/name
        if target.is_file() and sha(target)!=expected['sha256']:differences.append(name)
    allowed=lambda n: n.startswith('review/data/') or n in ['review/bin/libwroughtwild_sim.windows.x86_64.dll','review/provenance.json','review/review.gd'] or n.startswith('review/evidence')
    assert all(allowed(n) for n in differences),differences
    (out/colour/'f5-adapter-differences.json').write_text(json.dumps(differences,indent=2))
for name in ['Launch review.ps1','README.md','PERFORMANCE.md']:
    shutil.copy2(Path(__file__).with_name(name),out/name)
shutil.copytree(Path(__file__).parent,out/'f5-tools',ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
files={p.relative_to(out).as_posix():{'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps({'task':'ART-07F5','base':'56ce6bbe343012205690cf669491372958b80662','files':files},indent=2),encoding='utf-8')
print(json.dumps({'path':str(out),'files':len(files),'bytes':sum(f['bytes'] for f in files.values()),'manifest_sha256':sha(out/'manifest.json')},indent=2))
