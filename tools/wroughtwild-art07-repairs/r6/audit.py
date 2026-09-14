"""Record final preservation hashes and the already published wave release."""
import json
import shutil
import subprocess
from pathlib import Path
from stage import ROOT, OUT, GAME, sha, write

dest = OUT / 'verification'
prepared = json.loads((OUT / 'prepared.json').read_text(encoding='utf-8-sig'))
inputs = json.loads((ROOT / 'docs/prototype/art07-repairs/2026-09-14/inputs.json').read_text(encoding='utf-8-sig'))
index = json.loads((ROOT / 'docs/prototype/art07-repairs/2026-09-14/deliveries.json').read_text(encoding='utf-8-sig'))['deliveries']
changed = []
original_probe=(GAME/'g1/probe.gd').read_text(encoding='utf-8-sig')
derived_probe=(GAME/'r6/probe.gd').read_text(encoding='utf-8-sig')
original_checks=[line.strip() for line in original_probe.splitlines() if 'check(' in line]
derived_checks=[line.strip() for line in derived_probe.splitlines() if 'check(' in line and 'R6 capture frames retain exact paid player pose' not in line]
assert original_checks==derived_checks
assert (GAME/'r6/probe.tscn').read_text(encoding='utf-8-sig')==(GAME/'g1/probe.tscn').read_text(encoding='utf-8-sig').replace('res://g1/probe.gd','res://r6/probe.gd')
for name, row in prepared['original_files'].items():
    path = OUT / 'runtime' / name
    actual = sha(path)
    if actual != row['sha256']:
        changed.append({'path': name, 'before_sha256': row['sha256'], 'after_sha256': actual})
assert {row['path'] for row in changed} == {'game/c5/native_resource.gd', 'game/g1/art.gd'}
published = 'a3aab16f7220d6ccc37cb17a54a164a84bf524b6'
wave = []
for name in ['r1', 'r2', 'r3', 'r4']:
    row = index[name]
    assert row['status'] == 'published'
    subprocess.run(['git', '-C', str(ROOT), 'merge-base', '--is-ancestor', row['source_commit'], published], check=True)
    manifest = Path(row['package']['path']) / 'manifest.json'
    assert sha(manifest) == row['package']['manifest_sha256']
    shutil.copy2(manifest, dest / (name + '-manifest.json'))
    wave.append({'id': name, 'published_source_commit': row['source_commit'], 'package': row['package']})
for name, row in [('runtime_source', inputs['runtime_source']), ('g2_review', inputs['g2_review']), ('c5', inputs['source_packages']['c5'])]:
    manifest = Path(row['path']) / 'manifest.json'
    assert sha(manifest) == row['manifest_sha256']
    shutil.copy2(manifest, dest / (name + '-manifest.json'))
shutil.copy2(OUT / 'prepared.json', dest / 'prepared.json')
write(dest / 'preservation.json', json.dumps({
    'runtime_base': inputs['runtime_base'], 'prepared_checkout_commit': prepared['checkout_commit'],
    'inspected_published_main': published, 'branch': 'codex/art07-r6',
    'original_entries_checked': len(prepared['original_files']),
    'original_entries_unchanged': len(prepared['original_files']) - len(changed),
    'changed_original_entries': changed,
    'wave_release': wave, 'parent_candidates_consumed': [],
    'probe_original_assertion_lines':len(original_checks), 'probe_assertions_and_original_scene_hierarchy_preserved':True,
    'new_runtime_files': {p.name: {'sha256': sha(p), 'bytes': p.stat().st_size} for p in (GAME / 'r6').iterdir() if p.suffix in ['.gd', '.gdshader', '.tscn', '.json', '.png']},
    'scope': 'All original native, data, normal scripts, asset and save payload bytes retained except the two named isolated presentation scripts. Full source payload verification is recorded separately.'
}, indent=2))
print('R6_PRESERVATION', len(prepared['original_files']), 'original entries; exactly two permitted presentation changes; published wave ancestry verified')
