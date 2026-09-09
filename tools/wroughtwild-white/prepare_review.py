"""Prepare White review using the recorded frozen ART-04 native binary.
Usage: NATIVE ASSETS REVIEW [--update]. Never touches normal APPDATA/game files.
"""
import sys,json,hashlib,shutil
from pathlib import Path
native,assets,review=[Path(p).resolve() for p in sys.argv[1:4]]
repo=Path(__file__).resolve().parents[2];recipe=Path(__file__).parent
assert '--update' in sys.argv or not review.exists()
review.mkdir(parents=True,exist_ok=True)
(review/'bin').mkdir(exist_ok=True)
dll=native/'bin/libwroughtwild_sim.windows.x86_64.dll'
provenance=json.loads((native/'provenance.json').read_text(encoding='utf-8-sig'))
assert provenance['revision']=='f7253d20ed1dbeee743219190bdaccac60921c1c'
assert provenance['godot_cpp_sha256']=='701934d2505314d4272ef258beca75974de9f2bb2d94d98b29d22670de42370c'
assert hashlib.sha256(dll.read_bytes()).hexdigest()==provenance['dll_sha256']
shutil.copy2(dll,review/'bin')
shutil.copy2(native/'snapshot/game/bin/wroughtwild_sim.gdextension',review/'bin')
shutil.copytree(native/'snapshot/data',review/'data',dirs_exist_ok=True)
checkpoint=repo/'build/lf2/wave1-midtrip.json'
shutil.copy2(checkpoint,review/'paid-checkpoint.json')
for p in recipe.iterdir():
    if p.suffix in ['.gd','.gdshader','.godot','.tscn'] or p.name=='white.json':shutil.copy2(p,review/p.name)
if assets.is_dir():
    for p in assets.iterdir():
        if p.suffix in ['.png','.glb']:shutil.copy2(p,review/p.name)
(review/'context').mkdir(exist_ok=True)
for name in ['strange_winch','strange_basket','strange_drum','strange_lever']:
    path=repo/'game/assets/authored'/f'{name}.glb';assert path.is_file(),path
    shutil.copy2(path,review/'context'/path.name)
grove=repo/'build/grove-art02/emberroot-handoff/review'
for name in ['quiet-tree.glb','canopy-far.glb','forest-floor.png']:
    shutil.copy2(grove/name,review/'context'/name)
report={'native':json.loads((native/'provenance.json').read_text(encoding='utf-8-sig')),
        'paid_checkpoint_sha256':hashlib.sha256(checkpoint.read_bytes()).hexdigest(),
        'context':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (review/'context').iterdir() if not p.name.endswith('.import')}}
(review/'provenance.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(review/'evidence').mkdir(exist_ok=True)
print('WHITE_REVIEW_PREPARED',review)
