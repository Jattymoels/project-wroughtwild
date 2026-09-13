"""G2 independent byte verification and fresh copies; no G1 writes or wrapper edits."""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / 'build/art07/g2'
DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def rows_for(path):
    payload = json.loads(path.read_text(encoding='utf-8-sig'))
    rows = payload.get('files', payload)
    return {r['path']: r for r in rows} if isinstance(rows, list) else rows

def check_package(root, expected):
    root = root.resolve()
    manifest = root / 'manifest.json'
    assert sha(manifest) == expected['manifest_sha256']
    rows = rows_for(manifest)
    for name, row in rows.items():
        file = (root / name).resolve()
        assert file.is_relative_to(root), name
        assert file.stat().st_size == row['bytes'] and sha(file) == row['sha256'].lower(), str(file)
    count, size = len(rows), sum(row['bytes'] for row in rows.values())
    assert count == expected['files'] and size == expected['bytes']
    return {'path': str(root), 'manifest_sha256': sha(manifest), 'files': count, 'bytes': size}

def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], text=True).strip()

def write_new(path, data):
    assert path.resolve().is_relative_to(BUILD.resolve())
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        json.dump(data, stream, indent=2)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    parser.add_argument('--verify-only', action='store_true')
    args = parser.parse_args()
    out = args.output.resolve()
    assert out.is_relative_to(BUILD.resolve()) and not out.exists(), str(out)
    out.mkdir(parents=True)
    spec_path = DEPOT / 'docs/prototype/art07-production/g2-inputs-2026-09-13.json'
    spec = json.loads(spec_path.read_text())
    index_path = Path(spec['input_index']['path'])
    assert sha(index_path) == spec['input_index']['sha256']
    index = json.loads(index_path.read_text())
    report = {'review_base': git('rev-parse', 'HEAD'), 'runtime_base': spec['runtime_base'],
              'input_record': {'path': str(spec_path), 'sha256': sha(spec_path)},
              'input_index': spec['input_index'], 'sources': {}}
    assert git('branch', '--show-current') == 'codex/art07-g2'
    subprocess.run(['git', '-C', str(ROOT), 'merge-base', '--is-ancestor', spec['source_integration_tip'], 'origin/main'], check=True)
    for ident, expected in index['inputs'].items():
        item = check_package(Path(expected['path']), expected)
        receipt = f'docs/prototype/art07-production/receipts/{ident}.md'
        item['receipt_commit'] = git('log', '-1', '--format=%H', 'origin/main', '--', receipt)
        assert item['receipt_commit']
        item['receipt_sha256'] = sha(ROOT / receipt)
        report['sources'][ident] = item
        print('G2_SOURCE_VERIFIED', ident, item['files'], item['bytes'], flush=True)
    assert len(report['sources']) == 24
    assert sum(r['files'] for r in report['sources'].values()) == spec['input_index']['files']
    assert sum(r['bytes'] for r in report['sources'].values()) == spec['input_index']['bytes']
    source = Path(spec['g1_package']['path'])
    report['g1_package'] = check_package(source, spec['g1_package'])
    print('G2_G1_SEAL_VERIFIED', report['g1_package'], flush=True)
    write_new(out / 'inputs.json', report)
    if args.verify_only:
        return
    sealed = out / 'sealed'
    sealed.mkdir()
    rows = rows_for(source / 'manifest.json')
    for name, row in rows.items():
        target = sealed / name
        assert target.resolve().is_relative_to(sealed)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / name, target)
        assert sha(target) == row['sha256'].lower(), name
    shutil.copy2(source / 'manifest.json', sealed / 'manifest.json')
    print('G2_SEALED_COPY_VERIFIED', len(rows), flush=True)
    runtime = out / 'review'
    copied = {}
    for name, row in rows.items():
        if Path(name).parts[0] not in ['game', 'data', 'engine']:
            continue
        target = runtime / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sealed / name, target)
        assert sha(target) == row['sha256'].lower(), name
        copied[name] = row
    dll = runtime / 'game/bin/libwroughtwild_sim.windows.x86_64.dll'
    assert sha(dll) == spec['native']['dll_sha256']
    write_new(out / 'copy.json', {'canonical': str(source), 'sealed_copy': str(sealed),
              'runtime_copy': str(runtime), 'sealed_files': len(rows), 'runtime_files': copied,
              'scope': 'All sealed file bytes copied and rehashed; runtime copied again without inherited caches, saves or UID sidecars. Both copies are G2-owned. Canonical G1 never imported.'})
    print('G2_RUNTIME_COPY_VERIFIED', len(copied), sum(r['bytes'] for r in copied.values()), flush=True)

if __name__ == '__main__':
    main()
