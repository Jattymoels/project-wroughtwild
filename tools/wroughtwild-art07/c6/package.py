"""Create a fresh immutable candidate handoff, excluding caches and test saves."""
import json,sys,shutil,zipfile
from pathlib import Path
from prerequisites import sha,PACKAGES,REVISION
root,review,out=[Path(p).resolve() for p in sys.argv[1:]]
assert not out.exists();out.mkdir(parents=True)
def copy_file(source,target):
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
def copy_tree(source,target):
    shutil.copytree(source,target,ignore=shutil.ignore_patterns('__pycache__','.godot','*.blend1'))
copy_tree(root/'kit-v06',out/'models')
copy_tree(Path(__file__).parent,out/'recipes')
native=out/'native';native.mkdir()
# Extract only the reviewed git archive, so test-generated data cannot enter the handoff.
with zipfile.ZipFile(root/'current/current.zip') as archive:archive.extractall(native)
copy_file(root/'current/current.zip',native/'current.zip')
copy_file(review/'game/project.godot',native/'game/project.godot')
copy_file(root/'current/game/bin/libwroughtwild_sim.windows.x86_64.dll',native/'game/bin/libwroughtwild_sim.windows.x86_64.dll')
copy_file(root/'current/provenance.json',native/'provenance.json')
art=native/'game/c6'
for source in (review/'game/c6').rglob('*'):
    if source.is_file() and not source.name.startswith('survey') and source.suffix!='.uid':copy_file(source,art/source.relative_to(review/'game/c6'))
(native/'build/lf3').mkdir(parents=True)
for folder in ['blender-v06','blender-scar-v06','inspection','media-v06']:
    copy_tree(root/folder,out/'evidence'/folder)
copy_tree(review/'evidence',out/'evidence/native')
for name in ['prerequisites.json','audit-v06-rays.json','summary.json','verification.json','environment.json','reproduction.json']:
    copy_file(root/name,out/'evidence'/name)
copy_file(root/'current/game/c6/survey.json',out/'evidence/native-envelope-survey.json')
copy_file(review/'cook.json',out/'evidence/cook.json')
for folder in ['logs','current-checks','native-checks','selected-native-checks','selected-check','selected-capture','selected-walk','selected-motion','selected-benchmark','baseline-capture','release-check','release-capture','release-walk','release-motion','release-benchmark','release-caption-capture','fresh-native-checks']:
    for source in (root/folder).glob('*'):
        if source.is_file():copy_file(source,out/'evidence/logs'/folder/source.name)
if (root/'native-baseline/diagnostic.json').exists():
    copy_file(root/'native-baseline/diagnostic.json',out/'evidence/baseline/diagnostic.json')
    copy_file(root/'native-baseline/evidence/forward_plus/capture-77/report.json',out/'evidence/baseline/report.json')
for key,(path,_) in PACKAGES.items():
    copy_file(path/'manifest.json',out/'lineage'/(key+'-manifest.json'))
copy_file(PACKAGES['b3'][0]/'evidence/provenance.json',out/'lineage/b3-source-provenance.json')
record={'slice':'ART-07C6','status':'source/runtime candidates; owner visual acceptance pending','base':REVISION,'selected_geometry':'kit-v06','selected_native_review':review.name,'shared_textures':6,'asset_variants':19,'exports':57,'ordinary_world_adoption':False,'normal_game_files_changed':False}
(out/'handoff.json').write_text(json.dumps(record,indent=2)+'\n')
(out/'README.md').write_text('''# ART-07C6 candidate handoff

Read recipes/README.md and evidence/summary.json. This is an isolated current-game
review of surfaces for existing ruins and LF approach marks. Normal-world adoption,
owner visual acceptance and lower-spec performance approval remain separate.

Verify manifest.json before import; use recipes/verify_package.py PACKAGE FRESH_COPY.
Open FRESH_COPY/models/c6-master.blend in Blender. Import FRESH_COPY/native/game
in Godot 4.5 with isolated APPDATA. Never import or save into this canonical package.
The visible launcher is recipes/launch-review.ps1 -Package PACKAGE -CopyTo FRESH_COPY
-Renderer forward_plus -Visible. It requires the existing local Godot/Python tools.

Tab cycles all nine native views; WASD/QE flies; B switches the matched original;
L cycles native day/shade/dusk and labelled inspection sun; M disables scar light;
Space freezes/resumes its explicit cosmetic clock; 0 restores automatic detail,
7/8/9 force near/middle/far. Escape releases the mouse. Review light/camera controls
do not persist game state. Automated walks use the ordinary player controller.
''')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'path':str(out),'files':len(manifest),'bytes':sum(e['bytes'] for e in manifest.values()),'manifest_sha256':sha(out/'manifest.json')},indent=2))
