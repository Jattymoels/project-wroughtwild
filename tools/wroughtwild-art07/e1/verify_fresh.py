"""Record independent reopen/import results without modifying the sealed package."""
import json, sys
from pathlib import Path
from PIL import Image
from inputs import ROOT, sha

package, fresh = [Path(p).resolve() for p in sys.argv[1:3]]
manifest = json.loads((package / 'manifest.json').read_text())
preflight = json.loads((fresh / 'preimport-verification.json').read_text())
assert preflight['manifest_sha256'] == sha(package / 'manifest.json')
assert preflight['files'] == len(manifest['files'])
for row in manifest['files']:
    p = package / row['path']
    assert p.resolve().is_relative_to(package)
    assert p.stat().st_size == row['bytes'] and sha(p) == row['sha256'], row['path']

audit = json.loads((package / 'audit.json').read_text())
reopen = json.loads((fresh / 'verified-blender/reopen.json').read_text())
assert reopen['packed_images'] == 12 and len(reopen['imports']) == 6
for key, row in audit['runtime'].items():
    imported = reopen['imports'][key + '.glb']
    assert imported['triangles'] == row['triangles'], key
    assert imported['nonmanifold_edges'] == imported['degenerates'] == 0, key
    assert all(abs(a-b) < .00001 for av, bv in zip(imported['bounds_blender'], row['bounds_blender']) for a, b in zip(av, bv)), key
assert sha(fresh / 'source/e1_stations.blend') == audit['master_sha256']

logs = {}
for name in ['import', 'check', 'restore', 'blender', 'forward_plus-capture',
             'forward_plus-restore', 'gl_compatibility-capture', 'gl_compatibility-restore']:
    p = fresh / 'verification-logs' / (name + '.log.json')
    record = json.loads(p.read_text(encoding='utf-8-sig'))
    assert record['exit_code'] == 0, name
    logs[name] = record

checks = {}
# Headless Godot can retain the configured renderer name; later captures then
# replace its JSON in that renderer's folder. Its separate process log is the
# authoritative retained result, not a guessed empty renderer directory.
for mode, name, count in [('check', 'checks', 304), ('restore', 'restore', 132)]:
    log = (fresh / 'verification-logs' / (mode+'.log')).read_text(encoding='utf-8-sig')
    assert '--headless' in logs[mode]['arguments']
    assert f'E1_{name.upper()} {count} checks, 0 failures' in log, mode
    checks['headless/'+name] = {'checks': count, 'failures': 0, 'source': mode+'.log'}
for backend in ['forward_plus', 'gl_compatibility']:
    for name, count in [('checks', 304), ('restore', 132)]:
        row = json.loads((fresh / 'review/evidence' / backend / (name+'.json')).read_text())
        assert row['checks'] == count and row['failures'] == 0, (backend, name)
        checks[backend + '/' + name] = row

comparisons = {}
for name, original, copied in [
    ('blender', package / 'evidence/blender', fresh / 'verified-blender'),
    ('godot', package / 'evidence/godot', fresh / 'review/evidence')]:
    pngs = sorted(original.rglob('*.png'))
    identical = sum(sha(p) == sha(copied / p.relative_to(original)) for p in pngs)
    pixels = 0
    for p in pngs:
        with Image.open(p) as a, Image.open(copied / p.relative_to(original)) as b:
            pixels += a.size == b.size and a.convert('RGBA').tobytes() == b.convert('RGBA').tobytes()
    comparisons[name] = {'frames': len(pngs), 'identical_sha256': identical,
                         'identical_decoded_pixels': pixels}
    # Record render variance honestly; gameplay/geometry checks above are strict.

out = ROOT / 'docs/art/leyline-studies/2026-09-09/art07/e1'
result = {'canonical': str(package), 'fresh_copy': str(fresh),
          'manifest_sha256': sha(package / 'manifest.json'),
          'canonical_files_unchanged': len(manifest['files']),
          'packed_images': 12, 'independent_glb_imports': 6,
          'checks': checks, 'render_comparisons': comparisons, 'processes': logs}
(out / 'fresh-verification.json').write_bytes((json.dumps(result, indent=2)+'\n').encode())
# Curated JSON is committed with LF; hash those exact bytes, including reports
# copied from Windows processes that originally emitted CRLF.
for p in out.glob('*.json'):
    p.write_bytes(p.read_bytes().replace(b'\r\n', b'\n'))
evidence_path = out / 'evidence-manifest.json'
evidence = json.loads(evidence_path.read_text())
evidence['files'] = [{'path': p.name, 'bytes': p.stat().st_size, 'sha256': sha(p)}
                     for p in sorted(out.iterdir()) if p.is_file()
                     and p.name not in ['README.md', '.gitattributes', 'evidence-manifest.json']]
evidence_path.write_bytes((json.dumps(evidence, indent=2)+'\n').encode())
print('E1_FRESH_VERIFIED', json.dumps(comparisons), len(manifest['files']), 'canonical files unchanged')
