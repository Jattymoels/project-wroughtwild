"""Package inspected raw sources and the standalone review, never engine caches."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('review',type=Path)
parser.add_argument('output',type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
root = repo/'build/roster-art06'
review, output = args.review.resolve(), args.output.resolve()
assert output.is_relative_to(root) and not output.exists()
config = json.loads((review/'roster.json').read_text(encoding='utf-8'))
assert len(config['assets']) == 6
result = json.loads((review/'checks.json').read_text(encoding='utf-8'))
assert result['checks'] > 100
output.mkdir(parents=True)
shutil.copytree(review,output/'review',ignore=shutil.ignore_patterns('.godot','*.uid','captures'))
for row in config['assets']:
    asset, version = row['id'], row['version']
    inspection = root/f'{asset}-inspection-{version}'
    reopen = json.loads((root/f'{asset}-reopen-{version}.json').read_text(encoding='utf-8'))
    audit = json.loads((inspection/'inspection.json').read_text(encoding='utf-8'))
    assert reopen['passed'] and reopen['source_sha256'] == audit['source_sha256']
    destination = output/'sources'/asset
    destination.mkdir(parents=True)
    shutil.copy2(inspection/f'{asset}-inspection.blend',destination)
    shutil.copy2(inspection/'inspection.json',destination)
    shutil.copy2(root/f'{asset}-reopen-{version}.json',destination/'reopen.json')
    shutil.copy2(root/f'{asset}-source-{version}'/'generation.json',destination)
    shutil.copy2(root/f'{asset}-source-{version}'/'generation.log',destination)
    for picture in inspection.glob('*.png'): shutil.copy2(picture,destination)
    for v in [row['previous'],version]:
        shutil.copy2(repo/'docs/art/concepts/creatures/2026-09-09-roster'/f'{asset}-{v}.png',destination/f'concept-{v}.png')
    shutil.copy2(repo/'tools/wroughtwild-roster'/f'{asset}-{version}-prompt.txt',destination/'stronger-prompt.txt')
shutil.copy2(repo/'tools/wroughtwild-roster/README.md',output/'README.md')
shutil.copy2(repo/'docs/prototype/remaining-mob-art-2026-09-09.md',output/'work-item.md')
shutil.copy2(repo/'tools/wroughtwild-roster/launch-review.ps1',output/'Launch source review.ps1')
manifest = [{'path':str(p.relative_to(output)).replace('\\','/'),'bytes':p.stat().st_size,
             'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in sorted(output.rglob('*')) if p.is_file()]
(output/'manifest.json').write_text(json.dumps({'stage':config['stage'],'files':manifest,
    'bytes':sum(x['bytes'] for x in manifest)},indent=2)+'\n',encoding='utf-8')
print('ROSTER_SOURCES_PACKAGED',len(manifest),sum(x['bytes'] for x in manifest))
