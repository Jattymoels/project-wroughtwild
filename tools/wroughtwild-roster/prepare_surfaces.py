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
deep = '--lifelines' in sys.argv
config_path = recipe/('lifeline-study.json' if deep else 'surface-study.json')
root = repo/'build'/('roster-art06c' if deep else 'roster-art06b')
version = 'v02' if deep else 'v04'
config = json.loads(config_path.read_text(encoding='utf-8'))
roster = json.loads((recipe/'roster.json').read_text(encoding='utf-8'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
for row in config['assets']:
    folder = root/(row['id']+'-surface-'+version)
    report = json.loads((folder/'surface-report.json').read_text(encoding='utf-8'))
    assert report['flipped_faces'] == 0 and report['config_sha256'] == sha(config_path)
    if deep:
        assert report['depth_audit']['median_depth']>=config['minimum_median_depth_units']
        assert all(p['median']>=config['minimum_route_depth_units'] for p in report['depth_audit']['routes'])
    original = next(x for x in roster['assets'] if x['id'] == row['id'])
    row.update(animal=original['animal'],surface_report=report)
output.mkdir(parents=True)
for row in config['assets']:
    source = root/(row['id']+'-surface-'+version)
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
