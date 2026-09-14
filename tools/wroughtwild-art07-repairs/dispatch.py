"""Generate and validate the fixed ART-07 repair dispatch pack; no task execution."""
import argparse
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOME = ROOT / 'docs/prototype/art07-repairs/2026-09-14'


def prompt(task):
    ident = task['id']; tag = 'ART-07' + ident.upper()
    reads = ['docs/prototype/art07-repairs/2026-09-14/COMMON.md',
             'docs/prototype/art07-repairs/2026-09-14/SETUP.md',
             'docs/prototype/art07-repairs/2026-09-14/inputs.json',
             'docs/prototype/art07-repairs/2026-09-14/plan.json (assigned task and its wave/dependencies only)',
             'docs/prototype/art07-production/publication-2026-09-14.md',
             'docs/art/concepts/environment/2026-09-09-frontier/README.md',
             'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json (assigned entries only)',
             *task['reading']]
    lines = [f'# {tag} — {task["title"]}', '', 'Copy the full fenced prompt into one task using the working directory below.', '', '```text',
             f'Implement {tag} only: {task["title"]}.',
             f'Working directory: {task["worktree"]}', f'Branch: {task["branch"]}',
             'Owner tool/source depot: C:/Users/Matty/Dev/project-wroughtwild', '',
             'PROTOTYPE LIMITS — OWNER CORRECTION, 14 SEPTEMBER 2026',
             'Read C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md Prototype work limits FIRST.',
             'These supersede all older exhaustive instructions below: 10 minutes total',
             'review/verification, at most three focused jobs and one renderer; reuse',
             'applicable evidence. No routine full rehash/copy/seal, two-renderer matrix,',
             'benchmark repetition or source reopens. Stop with explicit unverified limits',
             'at the budget; extra necessary work needs owner approval of the check/time.',
             'Owner visual/aesthetic approval authorises normal game integration. Do not',
             'require separate rollout approval, baseline comparisons or performance gates.',
             'Use a short load/use check; performance investigation follows owner playtesting.',
             *(['R9 was stopped by the owner. Close out from existing results only; launch',
                'no further tests, renders, imports, benchmarks, audits or packaging.'] if ident=='r9' else []), '',
             'Read AGENTS.md in its required order before planning or editing. Inspect actual',
             'branch/status/history and preserve existing work, saves and running playtests.',
             'Reuse the prepared correct worktree. Never switch the owner checkout or edit a',
             'peer worktree. If the directory is missing, follow SETUP.md after checking gates.', '',
             'READING', *['- ' + path for path in reads], '', 'OUTCOME', task['outcome'], '',
             'FINDINGS / CONTEXT', ', '.join(task['findings']) or 'Combined closure of G2-V01–V05, G2-T01 and G2-C01.',
             'Original source-owner context: ' + ', '.join(task['owners']) + '.', '',
             'READINESS', f'Wave {task["wave"]}; direct candidate dependencies: ' + (', '.join(task['depends_on']) or 'none') + '.',
             'The whole wave must be released under plan.json. Require checked predecessor',
             'receipts/commits published to main and real package hashes; a prepared directory',
             'or an unverified branch is not a completed dependency. Do not start another slice.', '',
             'OWNED GIT OUTPUTS', *['- ' + p for p in task['owns']],
             f'Ignored work: {task["worktree"]}/build/art07-repairs/{ident}/<fresh-version>/.', '',
             'SETUP',
             f'From this worktree run the installed Python with tools/wroughtwild-art07-repairs/workspace.py inspect --id {ident}.',
             'Reuse recorded input verification for unchanged published inputs. Hash only',
             'new/changed consumed inputs where needed; no routine full-parent audit.',
             f'Inspect build/art07-repairs/{ident}/v01/prepared.json and reuse the matching prepared',
             'runtime if present. For a new absent version, run the assigned workspace.py',
             f'prepare --id {ident} --version vNN. It hashes the copied runtime entries.',
             'Verify/copy any extra source masters and dependency changes before using them.',
             'Run the generated import-smoke.json and all later engine jobs through',
             'tools/wroughtwild-art07-repairs/run.ps1 with fresh logs/private user paths.',
             'Do not edit the shared setup helpers; put necessary derivatives in your owned tools.', '',
             'BOUNDED WORK', *[f'{i}. {s}' for i, s in enumerate(task['work'], 1)], '',
             'SCOPED EVIDENCE — APPLY THE PROTOTYPE LIMITS ABOVE', *['- ' + s for s in task['checks']], '',
             'NON-NEGOTIABLE BOUNDARIES',
             'Preserve the pinned G1 game/data/native revision, original package bytes, normal',
             'game/sim/data/saves, all 273 legal pairs including octagonal/chamfer/triangle uses,',
             'native collision/targeting, finite stock, paid ownership, source/work states and',
             'saved geography. Do not invent new scatter, shape/recipe/body or game rules.',
             'Approved art belongs in the game; unapproved candidates still need visual review.',
             'A newer documentation checkout is not permission to rebase the runtime.',
             'If a missing body/seat/geography/architecture decision blocks a satisfactory fix,',
             'complete independent evidence and present exact options; do not invent the rule.',
             'Never weaken assertions, suppress diagnostics or call a receipt a fresh engine run.',
             'Use the single GPU mutex and existing-process checks. Keep APPDATA/local/temp and',
             'Blender resources private. Defer to running jobs; never stop another process.',
             'Current-machine cost measurements are not minimum-hardware acceptance. Benchmarks',
             'are separated from imports, generation and captures. Record actual hardware/settings.', '',
             'FINISH',
             'Give a concise result, checks actually run, blockers and unverified limits.',
             'Reuse existing packages for review-only work; do not seal another runtime.',
             'For implementation, record changed files and applicable evidence only;',
             'do not regenerate unchanged source/evidence to fill a historical template.',
             'Record every tuning value and purpose, remaining limits and owner-review status.',
             'Show actual model evidence in chat when applicable. Commit only this task’s owned',
             'paths on its branch. Give exact SHA(s), absolute package path/hash and commands,',
             'then stop. The serial publisher integrates and pushes main under standing permission.',
             'Do not push main, edit the shared delivery/queue files, launch more tasks, create',
             'monitors or send other tasks messages/acknowledgements without owner authorization.',
             'Respect platform approval controls; report any automatic rejection and its reason.', '```', '']
    return '\n'.join(lines)


def index(plan):
    lines = ['# ART-07 repairs — plan, prompts and setup', '',
             '**Prepared at the owner’s request, 14 September 2026.** All 26 original ART-07',
             'slices remain delivered. This follow-up addresses the seven open G2 findings',
             'through seven repairs, one integration and one independent review. No repair',
             'implementation or new worker task is started by preparing this pack.', '',
             'Start with **R1–R4**, one task per prepared worktree. Copy the full fenced prompt',
             'from the linked file. [Setup](SETUP.md) and the [actual workspace record](workspaces.json)',
             'give paths, copied runtime state and commands. GPU jobs remain serial; ordinary',
             'source work can proceed independently in separate tasks.', '',
             '| Wave | Task / prompt | Concrete result | Candidate dependency |',
             '| --- | --- | --- | --- |']
    for t in plan['tasks']:
        lines.append(f'| {t["wave"]} | [{t["id"].upper()} — {t["title"]}](prompts/{t["id"].upper()}.md) | {t["outcome"]} | '+(', '.join(x.upper() for x in t['depends_on']) or 'Common G1/G2 baseline')+' |')
    lines += ['', 'Wave 2 starts after all four first-wave candidates are checked and published.',
              'R7 additionally consumes R1’s canopy. R8 requires all seven repairs; R9 requires',
              'R8 and a **separate task that did not implement R1–R8**. Later wave directories',
              'and input packages are not pre-marked ready. A blocked decision remains open.', '',
              'The [common contract](COMMON.md) defines owned paths and unchanged gameplay.',
              'The [machine-readable plan](plan.json) holds task scope and gates; the',
              '[publisher-owned delivery index](deliveries.json) records only verified deliveries.',
              'Use the [publisher prompt](prompts/PUBLISH.md) for serial integration and dispatch.', '',
              '## Findings and acceptance', '',
              '| G2 finding | Repair |', '| --- | --- |']
    for t in plan['tasks']:
        for finding in t['findings']: lines.append(f'| {finding} | [{t["id"].upper()}](prompts/{t["id"].upper()}.md) |')
    lines += ['', 'R1 restores crown mass while retaining native tree bodies. R2 measures and',
              'reduces setup/residency without disguising the cost by removing visible content.',
              'R3 finishes the existing materials and joins. R4 attributes the eight fixture',
              'cleanup warnings. The next wave addresses chest seating, faceted ore and',
              'retained-anchor habitat composition. R8 resolves shared-file overlaps explicitly.', '',
              'The original [G2 findings and measurements](../../art07-production/publication-2026-09-14.md)',
              'remain the comparison. All 273 building combinations, octagonal support, native',
              'ownership, collision, finite stock and geography are fixed constraints. The six',
              'ART-06C animal rigs/adoption and normal-world rollout remain separate work.', '',
              '**Performance target:** measure the actual current RTX 5090 machine first.',
              'Minimum hardware and an acceptance budget remain open unless the owner selects',
              'them. R2 and R8/R9 distinguish import, repeated startup, first-use/traversal and',
              'settled frame costs. No invented numerical budget substitutes for measurements.', '',
              'Technical repair evidence, owner visual acceptance and target-device clearance',
              'are separate outcomes. New geography/body/seat rules require an explicit decision',
              'only if the existing contract cannot support the bounded visual repair.', '',
              '## Validation and sources', '',
              '[inputs.json](inputs.json) pins the original G1 runtime, G2 seal and source index.',
              'The setup copy helper hashes every copied runtime entry and preserves all original',
              'packages. No cache/import, source regeneration or simulation change is part of setup.',
              '[Preparation evidence](setup-checks.json) records actual checks and limitations.', '',
              'Run the installed Python with `tools/wroughtwild-art07-repairs/dispatch.py` to',
              'validate scopes, finding coverage, dependency gates, links and generated prompts.',
              '`--write` regenerates this index and the nine worker prompts from plan.json.', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    plan = json.loads((HOME / 'plan.json').read_text(encoding='utf-8'))
    tasks = plan['tasks']; ids = [t['id'] for t in tasks]
    assert ids == ['r'+str(i) for i in range(1, 10)]
    assert plan['runtime_base'] == '6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
    expected_findings = {'G2-V0'+str(i) for i in range(1, 6)} | {'G2-T01', 'G2-C01'}
    findings = [f for t in tasks for f in t['findings']]
    assert set(findings) == expected_findings and len(findings) == 7
    seen = set(); owns = []; readings = set()
    for t in tasks:
        assert set(t['depends_on']) <= seen
        wave = next(w for w in plan['waves'] if w['number'] == t['wave'])
        assert t['id'] in wave['tasks'] and set(wave['start_after']) <= seen
        assert t['branch'] == 'codex/art07-' + t['id']
        assert t['worktree'] == 'D:/project-wroughtwild-art07-' + t['id']
        assert t['status'] == 'not_started'  # Publication readiness lives in deliveries.json.
        owns += t['owns']; seen.add(t['id'])
        for path in t['reading']:
            assert (ROOT / path).is_file(), path
            readings.add(path)
    assert len(owns) == len(set(owns)) == 36
    assert plan['waves'][0]['tasks'] == ['r1', 'r2', 'r3', 'r4']
    assert tasks[7]['depends_on'] == ids[:7] and tasks[8]['depends_on'] == ['r8']
    for path in (ROOT / 'tools/wroughtwild-art07-repairs').glob('*.py'):
        ast.parse(path.read_text(encoding='utf-8'), filename=str(path))
    outputs = {HOME / 'README.md': index(plan)}
    outputs.update({HOME / 'prompts' / (t['id'].upper()+'.md'): prompt(t) for t in tasks})
    for path, content in outputs.items():
        raw = content.encode('utf-8')
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(raw)
        else:
            # Worktree checkouts can use CRLF; compare exact decoded document content.
            assert path.read_text(encoding='utf-8') == content, 'Stale generated document: ' + str(path)
    assert {p.name for p in (HOME / 'prompts').glob('*.md')} == {i.upper()+'.md' for i in ids} | {'PUBLISH.md'}
    links = 0
    for doc in HOME.rglob('*.md'):
        text = doc.read_text(encoding='utf-8')
        assert '\ufffd' not in text and '\u00e2\u20ac' not in text, doc
        for target in re.findall(r'\]\(([^)]+)\)', text):
            if target.startswith(('http:', 'https:', '#')): continue
            assert (doc.parent / target.split('#', 1)[0].strip('<>')).resolve().exists(), (doc, target)
            links += 1
    print(json.dumps({'result': 'PASS', 'worker_prompts': 9, 'publisher_prompts': 1,
                      'exclusive_git_outputs': len(owns), 'findings_owned_once': len(findings),
                      'waves': 4, 'reading_files': len(readings), 'local_links': links}, indent=2))


if __name__ == '__main__':
    main()
