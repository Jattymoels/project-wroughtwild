"""Copy completed sources into a fresh isolated Godot review. No engine/game mutation."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
parser.add_argument('--smoke-first-only', action='store_true')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
recipe = repo/'tools/wroughtwild-roster'
config = json.loads((recipe/'roster.json').read_text(encoding='utf-8'))
if args.smoke_first_only:
    config['assets'] = config['assets'][:1]
    config['stage'] = 'First-source tool smoke only, not the final six-source review.'
output = args.output.resolve()
assert output.is_relative_to(repo/'build') and not output.exists()
sources = []
for row in config['assets']:
    for version in [row['previous'], row['version']]:
        folder = repo/'build/roster-art06'/f"{row['id']}-source-{version}"
        record = json.loads((folder/'generation.json').read_text(encoding='utf-8-sig'))
        source = folder/(row['id']+'.glb')
        assert record['exit_code'] == 0 and record['input_unchanged']
        assert hashlib.sha256(source.read_bytes()).hexdigest() == record['glb_sha256']
        sources.append((source, row['id']+'-'+version+'.glb', record))
output.mkdir(parents=True)
(output/'assets').mkdir()
for name in ['project.godot', 'review.gd', 'review.tscn']:
    shutil.copy2(recipe/name, output/name)
(output/'roster.json').write_text(json.dumps(config, indent=2)+'\n', encoding='utf-8')
manifest = []
for source, filename, record in sources:
    shutil.copy2(source, output/'assets'/filename)
    # Review the source's actual geometry, not an uninspected generated Godot LOD.
    (output/'assets'/(filename+'.import')).write_text(
        '[remap]\nimporter="scene"\ntype="PackedScene"\n\n[deps]\nsource_file="res://assets/'
        +filename+'"\n\n[params]\nmeshes/generate_lods=false\n', encoding='utf-8')
    manifest.append({'file': 'assets/'+filename, 'sha256': record['glb_sha256'],
                     'input_sha256': record['input_sha256'], 'seconds': record['seconds']})
(output/'sources.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
print('ROSTER_REVIEW_PREPARED', output)
