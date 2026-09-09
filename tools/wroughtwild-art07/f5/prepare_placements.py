"""Add only F5 tests and retained visual candidates to an isolated current game."""
import sys,shutil,json
from pathlib import Path
from audit import sha
root,package=map(lambda x:Path(x).resolve(),sys.argv[1:3])
target=root/'game/art07f5';assert not target.exists();target.mkdir()
shutil.copy2(Path(__file__).with_name('check_placements.gd'),target/'check_placements.gd')
(target/'check_placements.tscn').write_text((root/'game/tests/living_frontier_flow.tscn').read_text().replace('res://tests/living_frontier_flow.gd','res://art07f5/check_placements.gd').replace('LivingFrontierFlow','F5PlacementAudit'))
paid=root/'appdata/Godot/app_userdata/Wroughtwild/lf2-heat-complete.json'
assert paid.is_file();shutil.copy2(paid,target/'paid-checkpoint.json')
files={}
for c in ['red','white','blue','green']:
    folder=target/'assets'/c;folder.mkdir(parents=True)
    role='buffer' if c=='red' else 'post'
    source=package/c/'review'/f'{c}-{role}-near.glb';shutil.copy2(source,folder/source.name)
    files[c]={'runtime_sha256':sha(source)}
(target/'lineage.json').write_text(json.dumps({'base':'56ce6bbe343012205690cf669491372958b80662','checkpoint_sha256':sha(paid),'files':files,'scope':'Test-only attachment and native placement; two explicitly granted test kits per colour, no normal-game adoption.'},indent=2))
print('F5_PLACEMENT_TEST_PREPARED')
