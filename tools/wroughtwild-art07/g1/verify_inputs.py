"""Verify every sealed G1 dependency before consumption; never import into inputs."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = '6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
INDEX = ROOT / 'docs/prototype/art07-production/g1-inputs-2026-09-12.json'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def entries(manifest):
    payload = manifest.get('files', manifest)
    if isinstance(payload, list):
        return [(row['path'], row) for row in payload]
    return list(payload.items())


def verify(out):
    index = json.loads(INDEX.read_text())
    assert index['source_count'] == len(index['inputs']) == 24
    report = {'base': BASE, 'index_sha256': digest(INDEX), 'inputs': {}}
    for ident, expected in index['inputs'].items():
        package = Path(expected['path']).resolve()
        manifest_path = package / 'manifest.json'
        assert digest(manifest_path) == expected['manifest_sha256'], ident
        rows = entries(json.loads(manifest_path.read_text(encoding='utf-8-sig')))
        total = 0
        for name, row in rows:
            file = (package / name).resolve()
            assert file.is_relative_to(package), (ident, name)
            assert file.stat().st_size == row['bytes'], (ident, name, 'bytes')
            assert digest(file) == row['sha256'].lower(), (ident, name, 'hash')
            total += row['bytes']
        assert len(rows) == expected['files'] and total == expected['bytes'], ident
        receipt = ROOT / f'docs/prototype/art07-production/receipts/{ident}.md'
        assert receipt.is_file(), ident
        history = subprocess.check_output(['git', '-C', str(ROOT), 'log', '-1', '--format=%H', BASE, '--', str(receipt.relative_to(ROOT))], text=True).strip()
        assert history, ident
        report['inputs'][ident] = dict(expected, receipt_sha256=digest(receipt), receipt_commit=history)
        print(f'{ident}: {len(rows)} files, {total} bytes verified', flush=True)
    report['files'] = sum(row['files'] for row in report['inputs'].values())
    report['bytes'] = sum(row['bytes'] for row in report['inputs'].values())
    assert report['files'] == index['files'] and report['bytes'] == index['bytes']
    out = Path(out).resolve()
    assert out.is_relative_to(ROOT / 'build/art07/g1')
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('x') as stream:
        json.dump(report, stream, indent=2)
    print('G1_INPUTS_VERIFIED', report['files'], report['bytes'])


if __name__ == '__main__':
    verify(sys.argv[1])
