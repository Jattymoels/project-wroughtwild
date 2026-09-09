"""Collect actual source/engine evidence and exact concept provenance for ART-06."""
import argparse
import hashlib
import json
import shutil
import struct
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('review', type=Path)
parser.add_argument('evidence', type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
root = repo/'build/roster-art06'
recipe = repo/'tools/wroughtwild-roster'
config = json.loads((recipe/'roster.json').read_text(encoding='utf-8'))
concepts = repo/'docs/art/concepts/creatures/2026-09-09-roster'
evidence = args.evidence.resolve()
assert not evidence.exists()
evidence.mkdir(parents=True)
summary = []
for row in config['assets']:
    asset, version = row['id'], row['version']
    folder = root/f'{asset}-source-{version}'
    record = json.loads((folder/'generation.json').read_text(encoding='utf-8-sig'))
    inspection = root/f'{asset}-inspection-{version}'
    audit = json.loads((inspection/'inspection.json').read_text(encoding='utf-8'))
    reopen = json.loads((root/f'{asset}-reopen-{version}.json').read_text(encoding='utf-8'))
    assert record['exit_code'] == 0 and record['input_unchanged'] and audit['source_unchanged'] and reopen['passed']
    assert record['glb_sha256'] == audit['source_sha256'] == reopen['source_sha256']
    assert record['glb_sha256'] == hashlib.sha256((folder/(asset+'.glb')).read_bytes()).hexdigest()
    assert record['input_sha256'] == hashlib.sha256((concepts/f'{asset}-{version}.png').read_bytes()).hexdigest()
    target = evidence/asset
    target.mkdir()
    for name in ['material-az0','material-az90','material-az180','material-az270','clay-three-quarter','clay-top','clay-underside']:
        shutil.copy2(inspection/(name+'.png'),target)
    shutil.copy2(args.review/'captures'/(asset+'.png'),target/'godot.png')
    for name, data in [('inspection',audit),('generation',record),('reopen',reopen)]:
        (target/(name+'.json')).write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    summary.append({'id':asset,'animal':row['animal'],'version':version,
                    'triangles':sum(m['triangles'] for m in audit['meshes']),
                    'zero_area_triangles':sum(m['zero_area_triangles'] for m in audit['meshes']),
                    'source_sha256':record['glb_sha256'],'seconds':record['seconds'],
                    'source_bytes':(folder/(asset+'.glb')).stat().st_size,'reopen_checks':reopen['checks'],
                    'skins':audit['skins'],'animations':audit['animations'],'emission_textures':audit['emission_textures']})
for name in ['compatibility-checks.json','forward-checks.json']:
    shutil.copy2(args.review/name,evidence/name)
rejected = evidence/'rejected-nymph-v02'
rejected.mkdir()
for name in ['clay-top.png','clay-underside.png','inspection.json']:
    shutil.copy2(root/'bog_lurker-inspection-v02'/name,rejected)
(evidence/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
manifest = []
for path in sorted(concepts.glob('*.png')):
    asset, version = path.stem.rsplit('-',1)
    prompt = recipe/f'{asset}-{version}-prompt.txt'
    if not prompt.exists(): prompt = recipe/f'{asset}-prompt.txt'
    assert prompt.exists()
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width,height = struct.unpack_from('>II',data,16)
    parent = None
    if version=='v02' and asset!='stone_husk': parent=asset+'-v01.png'
    if asset=='stone_husk' and version=='v03': parent=asset+'-v02.png'
    if asset=='bog_lurker' and version=='v03': parent=asset+'-v02.png'
    current = next(row for row in config['assets'] if row['id']==asset)
    status = 'current stronger source input' if version==current['version'] else 'earlier ancestry-approved concept'
    if asset=='stone_husk' and version=='v01': status='rejected: too close to boar; not generated'
    if asset=='bog_lurker' and version=='v02': status='rejected mesh: generated eight legs'
    if asset=='bog_lurker' and version=='v03': status='rejected correction: ambiguous legs; not generated'
    manifest.append({'file':path.name,'width':width,'height':height,'sha256':hashlib.sha256(data).hexdigest(),
                     'tool':'built-in image_gen','mode':'edit' if parent else 'generate','reference_image':parent,
                     'prompt':str(prompt.relative_to(repo)).replace('\\','/'),'prompt_sha256':hashlib.sha256(prompt.read_bytes()).hexdigest(),
                     'status':status})
(concepts/'manifest.json').write_text(json.dumps({'images':manifest,'note':'Ancestries approved; stronger revisions requested, final mesh/art review pending.'},indent=2)+'\n',encoding='utf-8')
print('ROSTER_EVIDENCE_COLLECTED',len(summary),len(manifest))
