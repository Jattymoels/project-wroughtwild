"""Copy a self-contained review without writing to the game or normal saves.
-- NATIVE_BASELINE ASSET_OUTPUT FRESH_REVIEW. Existing prepared reviews may be
updated with --update; user state is never copied from normal APPDATA.
"""
import sys,json,hashlib,shutil
from pathlib import Path
native,assets,review=map(lambda p:Path(p).resolve(),sys.argv[1:4])
repo=Path(__file__).resolve().parents[2];tools=Path(__file__).parent
if '--update' not in sys.argv: assert not review.exists()
review.mkdir(parents=True,exist_ok=True)
(review/'bin').mkdir(exist_ok=True)
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll',review/'bin')
shutil.copy2(native/'snapshot/game/bin/wroughtwild_sim.gdextension',review/'bin')
shutil.copytree(native/'snapshot/data',review/'data',dirs_exist_ok=True)
checkpoint=repo/'build/lf2/published-c/lf2-heat-active.json'
shutil.copy2(checkpoint,review/'paid-checkpoint.json')
for p in tools.iterdir():
    if p.suffix in ['.gd','.gdshader','.godot','.tscn'] or p.name=='red.json':shutil.copy2(p,review/p.name)
for p in assets.iterdir():
    if p.suffix in ['.png','.glb']:shutil.copy2(p,review/p.name)
(review/'context').mkdir(exist_ok=True)
for name in ['forge_basic','strange_winch','strange_basket','strange_ventlung','strange_drum']:
    path=repo/'game/assets/authored'/f'{name}.glb'
    assert path.is_file(),path
    shutil.copy2(path,review/'context'/path.name)
# Reuse approved scenery purely as an isolated backdrop, not generated geography.
grove=repo/'build/grove-art02/emberroot-handoff/review'
for name in ['quiet-tree.glb','canopy-far.glb','understory.glb','forest-floor.png']:
    path=grove/name
    if path.is_file():shutil.copy2(path,review/'context'/name)
report={'native':json.loads((native/'provenance.json').read_text(encoding='utf-8-sig')),
        'paid_checkpoint_sha256':hashlib.sha256(checkpoint.read_bytes()).hexdigest(),
        'asset_report':json.loads((assets/'asset-report.json').read_text(encoding='utf-8')),
        'context':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (review/'context').iterdir() if not p.name.endswith('.import')}}
(review/'provenance.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(review/'evidence').mkdir(exist_ok=True)
print('ART04_REVIEW_PREPARED',review)
