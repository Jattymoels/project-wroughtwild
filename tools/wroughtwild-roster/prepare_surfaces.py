"""Create a fresh isolated ART-06B viewer from the six checked surface bakes."""
import hashlib
import json
import shutil
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
recipe = Path(__file__).parent
output = Path(sys.argv[1]).resolve()
assert output.is_relative_to(repo/'build') and not output.exists()
config = json.loads((recipe/'surface-study.json').read_text(encoding='utf-8'))
roster = json.loads((recipe/'roster.json').read_text(encoding='utf-8'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
for row in config['assets']:
    folder = repo/'build/roster-art06b'/(row['id']+'-surface-v04')
    report = json.loads((folder/'surface-report.json').read_text(encoding='utf-8'))
    assert report['flipped_faces'] == 0 and report['config_sha256'] == sha(recipe/'surface-study.json')
    original = next(x for x in roster['assets'] if x['id'] == row['id'])
    row.update(animal=original['animal'],surface_report=report)
output.mkdir(parents=True)
for row in config['assets']:
    source = repo/'build/roster-art06b'/(row['id']+'-surface-v04')
    destination = output/'assets'/row['id']
    destination.mkdir(parents=True)
    for name in [row['id']+'-surface.glb','base.png','orm.png','scar-mask.png']:
        shutil.copy2(source/name,destination/name)
    glb = row['id']+'-surface.glb'
    (destination/(glb+'.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n\n[deps]\nsource_file="res://assets/'+row['id']+'/'+glb+'"\n\n[params]\nmeshes/generate_lods=false\n',encoding='utf-8')
for name in ['review.tscn','project.godot']:
    shutil.copy2(recipe/name,output/name)
shutil.copy2(recipe/'surface_review.gd',output/'review.gd')
shutil.copy2(recipe/'surface_scar.gdshader',output/'scar.gdshader')
(output/'surfaces.json').write_text(json.dumps(config,indent=2)+'\n',encoding='utf-8')
(output/'provenance.json').write_text(json.dumps({'stage':config['stage'],'shader_sha256':sha(output/'scar.gdshader'),'files':[{'path':str(p.relative_to(output)).replace('\\','/'),'sha256':sha(p)} for p in sorted((output/'assets').rglob('*')) if p.is_file()]},indent=2)+'\n',encoding='utf-8')
print('ROSTER_SURFACE_REVIEW_PREPARED',output)
