"""Prepare only the nine ART-07 repair workspaces and verified local runtime copies.

No engine launch, asset generation, deletion, main mutation or automatic dispatch.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')
DOCS = ROOT / 'docs/prototype/art07-repairs/2026-09-14'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def git(*args):
    return subprocess.check_output(['git', '-c', 'safe.directory=' + ROOT.as_posix(),
                                   '-C', str(ROOT), *args], text=True, encoding='utf-8').strip()


def entries(package):
    root = Path(package['path']).resolve()
    assert sha(root / 'manifest.json') == package['manifest_sha256'], str(root)
    manifest = read(root / 'manifest.json')
    rows = manifest.get('files', manifest)
    if isinstance(rows, list):
        rows = {row['path']: row for row in rows}
    assert len(rows) == package['files']
    assert sum(row['bytes'] for row in rows.values()) == package['bytes']
    for name in rows:
        assert (root / name).resolve().is_relative_to(root), name
    return rows


def prerequisites(plan, task, base):
    wave = next(w for w in plan['waves'] if w['number'] == task['wave'])
    required = sorted(set(wave['start_after'] + task['depends_on']))
    index = read(DOCS / 'deliveries.json')['deliveries']
    for ident in required:
        assert ident in index, 'Not published: ' + ident
        delivery = index[ident]
        assert delivery['status'] == 'published', ident
        receipt = read(ROOT / delivery['receipt'])
        assert receipt['id'] == ident and receipt['status'] == 'ready_for_integration', ident
        assert receipt['package'] == delivery['package'], ident
        git('merge-base', '--is-ancestor', delivery['source_commit'], base)
        entries(delivery['package'])
    return required


def inspect(plan, task):
    inputs = read(DOCS / 'inputs.json')
    for key in ['runtime_source', 'g2_review']:
        entries(inputs[key])
    index = inputs['source_index']
    assert sha(Path(index['path'])) == index['sha256']
    sources = read(Path(index['path']))['inputs']
    for ident in task['sources']:
        entries(sources[ident])
    assert Path(inputs['tools']['python']).is_file()
    assert Path(inputs['tools']['blender']).is_file()
    result = {'id': task['id'], 'branch': task['branch'], 'worktree': task['worktree'],
              'sources': task['sources'], 'manifest_identities': 'verified',
              'scope': 'Manifest identity/count/size and tool availability only. Full payload hashing happens on copy or explicit source consumption.'}
    print(json.dumps(result, indent=2), flush=True)
    return inputs


def verify_inputs(plan, task):
    inputs = inspect(plan, task)
    originals = read(Path(inputs['source_index']['path']))['inputs']
    packages = {'runtime_source': inputs['runtime_source'], 'g2_review': inputs['g2_review']}
    packages.update({ident: originals[ident] for ident in task['sources']})
    for ident in prerequisites(plan, task, git('rev-parse', 'HEAD')):
        packages[ident] = read(DOCS / 'deliveries.json')['deliveries'][ident]['package']
    for ident, package in packages.items():
        root = Path(package['path']).resolve()
        rows = entries(package)
        for name, row in rows.items():
            path = root / name
            assert path.stat().st_size == row['bytes'] and sha(path) == row['sha256'].lower(), str(path)
        print('REPAIR_FULL_INPUT_VERIFIED', ident, len(rows), package['bytes'], flush=True)


def create(plan, wave_number, base):
    assert ROOT.resolve() == DEPOT.resolve(), 'Create from the owner depot only.'
    assert git('branch', '--show-current') == 'main'
    assert re.fullmatch(r'[0-9a-f]{40}', base), 'Use a full inspected published SHA.'
    assert git('rev-parse', 'HEAD') == base
    remote = git('ls-remote', 'origin', 'refs/heads/main').split()[0]
    assert remote == base, 'Main must match the verified remote base.'
    selected = [t for t in plan['tasks'] if t['wave'] == wave_number]
    assert selected
    known = git('worktree', 'list', '--porcelain')
    for task in selected:
        target = Path(task['worktree'])
        assert target.as_posix() == 'D:/project-wroughtwild-art07-' + task['id']
        assert not target.exists(), 'Inspect/reuse existing path: ' + str(target)
        assert not git('branch', '--list', task['branch']), 'Branch already exists.'
        assert task['worktree'] not in known
        prerequisites(plan, task, base)
        inspect(plan, task)
    # All targets are preflighted before the first mutation. Existing work is never reset.
    for task in selected:
        git('worktree', 'add', '-b', task['branch'], task['worktree'], base)
        print('REPAIR_WORKTREE_CREATED', task['id'], task['worktree'], base, flush=True)


def prepare(plan, task, version):
    assert ROOT.resolve() == Path(task['worktree']).resolve(), 'Run the assigned worktree copy of this helper.'
    assert git('branch', '--show-current') == task['branch']
    prerequisites(plan, task, git('rev-parse', 'HEAD'))
    inputs = inspect(plan, task)
    package = inputs['runtime_source']
    if task['id'] == 'r9':
        package = read(DOCS / 'deliveries.json')['deliveries']['r8']['package']
    rows = entries(package)
    source = Path(package['path']).resolve()
    prefix = ''
    test_support = {}
    if task['id'] == 'r9':
        # R8 seals its complete candidate under runtime/, separately from evidence.
        map_path = source / 'runtime-files.json'
        assert sha(map_path) == rows['runtime-files.json']['sha256']
        runtime_map = read(map_path)
        nested = {name.removeprefix('runtime/'): row for name, row in rows.items()
                  if name.startswith('runtime/')}
        assert runtime_map == nested, 'R8 runtime map must exactly match its sealed entries.'
        assert all(Path(name).parts[0] in ['game', 'data', 'engine'] for name in nested)
        override = 'test-support/override.cfg'
        assert sha(source / override) == rows[override]['sha256']
        test_support = {'game/override.cfg': {'source_path': override, **rows[override]}}
        rows = nested
        prefix = 'runtime/'
    selected = {name: row for name, row in rows.items()
                if Path(name).parts[0] in ['game', 'data', 'engine']}
    assert selected and any(n.endswith('project.godot') for n in selected)
    assert re.fullmatch(r'v[0-9]{2,3}', version), 'Use v01, v02, etc.'
    base = (ROOT / 'build/art07-repairs' / task['id']).resolve()
    out = (base / version).resolve()
    assert out.is_relative_to(base) and not out.exists(), 'Use a fresh version.'
    needed = sum(row['bytes'] for row in selected.values())
    extra_bytes = sum(row['bytes'] for row in test_support.values())
    assert shutil.disk_usage(ROOT).free > needed + extra_bytes + 512 * 1024**2, 'Insufficient copy space; leave existing work intact.'
    runtime = out / 'runtime'
    for name, row in selected.items():
        target = (runtime / name).resolve()
        assert target.is_relative_to(runtime.resolve()), name
        origin = (source / prefix / name).resolve()
        assert origin.is_relative_to(source), name
        target.parent.mkdir(parents=True, exist_ok=True)
        assert not target.exists()
        shutil.copy2(origin, target)
        assert target.stat().st_size == row['bytes'] and sha(target) == row['sha256'].lower(), name
    for name, row in test_support.items():
        target = (runtime / name).resolve()
        assert target.is_relative_to(runtime.resolve()) and not target.exists(), name
        shutil.copy2(source / row['source_path'], target)
        assert target.stat().st_size == row['bytes'] and sha(target) == row['sha256'], name
    assert not (runtime / 'game/.godot').exists()
    dll = runtime / 'game/bin/libwroughtwild_sim.windows.x86_64.dll'
    assert sha(dll) == inputs['native']['dll_sha256']
    engine = runtime / 'engine/Godot_v4.5-stable_win64.exe'
    assert engine.is_file()
    jobs = []
    for ident, args in [
        ('import', ['--headless', '--editor', '--path', str(runtime / 'game'), '--import']),
        ('smoke-forward_plus', ['--rendering-method', 'forward_plus', '--path', str(runtime / 'game'), 'res://g1/play.tscn', '--', '--smoke']),
        ('smoke-gl_compatibility', ['--rendering-method', 'gl_compatibility', '--path', str(runtime / 'game'), 'res://g1/play.tscn', '--', '--smoke'])
    ]:
        if task['id'] == 'r9' and ident.startswith('smoke-'):
            args.append('--r8-no-mouse-capture')
        jobs.append({'id': ident, 'program': str(engine), 'arguments': args,
                     'log': str(out / 'logs' / (ident + '.log')), 'state': str(out / 'users' / ident)})
    record = {'id': task['id'], 'branch': task['branch'], 'checkout_commit': git('rev-parse', 'HEAD'),
              'runtime_base': inputs['runtime_base'], 'source': package, 'runtime': str(runtime),
              'files': len(selected), 'bytes': needed, 'original_files': selected,
              'scope': 'Copied runtime entries verified byte-for-byte; no cache inherited, no engine started, no repair implemented. Other source/master payloads must be verified before consumption.'}
    if task['id'] == 'r9':
        record.update({'runtime_package_prefix': prefix, 'test_support': test_support,
                       'test_support_scope': 'Verified R8 no-focus override outside the normal runtime map. Automated smoke uses the mouse-capture opt-out. Normal-play copies must exclude this override.'})
    for name, data in [('prepared.json', record), ('import-smoke.json', jobs)]:
        with (out / name).open('x', encoding='utf-8', newline='\n') as stream:
            json.dump(data, stream, indent=2)
    print('REPAIR_RUNTIME_PREPARED', task['id'], str(runtime), len(selected), needed, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    show = commands.add_parser('inspect'); show.add_argument('--id', required=True)
    check = commands.add_parser('verify'); check.add_argument('--id', required=True)
    make = commands.add_parser('create'); make.add_argument('--wave', type=int, required=True); make.add_argument('--base', required=True)
    copy = commands.add_parser('prepare'); copy.add_argument('--id', required=True); copy.add_argument('--version', required=True)
    args = parser.parse_args()
    plan = read(DOCS / 'plan.json')
    if args.command == 'create':
        create(plan, args.wave, args.base)
        return
    task = next(t for t in plan['tasks'] if t['id'] == args.id)
    if args.command == 'inspect': inspect(plan, task)
    elif args.command == 'verify': verify_inputs(plan, task)
    else: prepare(plan, task, args.version)


if __name__ == '__main__':
    main()
