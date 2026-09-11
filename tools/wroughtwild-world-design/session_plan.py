"""Generate/check the ART-07 session prompts and exclusive catalogue coverage.

This creates documents only. It does not launch sessions, GPU jobs or Git work.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
HOME = ROOT / "docs/prototype/art07-production"
CANONICAL = "C:/Users/Matty/Dev/project-wroughtwild"
CATEGORIES = ("resource_nodes", "nature_support", "shapes", "materials", "devices", "fauna_presentation")


def prompt(task, plan):
    tag = "ART-07" + task["id"].upper()
    prefix = f"docs/prototype/art07-production"
    lines = [f"# {tag} — {task['title']}", "", "Copy the complete prompt below into one implementation session.", "", "```text",
             f"Implement {tag} only: {task['title']}.",
             f"Repository/tool depot: {CANONICAL}", "",
             "Read AGENTS.md and follow its required reading order before planning or editing.",
             "Inspect actual status/history/branch/remote and preserve unrelated work, saves and running playtests.",
             "Then read these repository files:",
             f"- {prefix}/COMMON.md",
             f"- {prefix}/PROCESS.md",
             f"- {prefix}/plan.json (only this task and its dependencies)",
             "- docs/prototype/world-and-placeable-art-2026-09-09.md",
             "- docs/art/concepts/environment/2026-09-09-frontier/README.md",
             "- docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json (assigned entries only)"]
    lines += [f"- {path}" for path in task['reading']]
    lines += ["", "OUTCOME", task['outcome'], "", "ASSIGNED CATALOGUE OWNERSHIP"]
    if task['owns']:
        lines += [f"- {category}: {', '.join(ids)}" for category, ids in task['owns'].items()]
    else:
        lines += ["- Integration/verification only; consume predecessor assets without taking over their source recipes."]
    if task['dependencies']:
        lines += ["", "PREREQUISITES", ", ".join("ART-07" + i.upper() for i in task['dependencies']) + ".",
                  "Require checked receipts/recipes published to main and verify each absolute local handoff path/hash.",
                  f"Receipts belong at {prefix}/receipts/<lowercase-id>.md.",
                  "If an input is missing, continue independent inspection/design and report the missing prerequisite; do not invent success."]
    else:
        lines += ["", "PREREQUISITES", "No new ART-07 predecessor. Verify the existing approved source/tool packages described in PROCESS.md."]
    lines += ["", "SESSION AND OUTPUT BOUNDARY",
              f"Use an isolated worktree/branch codex/art07-{task['id']}; reuse an existing correct app worktree.",
              "Do not switch or edit the owner's shared checkout beneath another session.",
              f"Own tools/wroughtwild-art07/{task['id']}/ and docs/art/leyline-studies/2026-09-09/art07/{task['id']}/ only,",
              f"plus {prefix}/receipts/{task['id']}.md. Put generated work in fresh build/art07/{task['id']}/ versions.",
              "Keep old tools/handoffs and other slices read-only. No shared queue/catalogue edit; the publisher owns those.",
              "Follow PROCESS.md: inspect/reuse sources, single-object imagegen where needed, local Windows TRELLIS",
              "v0.6.0 with pinned models (1024, seed 42, GPU required, retained cutout, PNG, eight threads),",
              "then actual Blender inspection/finishing, deep geometric scars, packed-source reopen and isolated Godot review.",
              "Direct-model lattice pieces and mechanisms in Blender; do not reconstruct an entire concept board as one mesh.",
              "Coordinate the one GPU slot with the shared mutex and read-only process checks; never interrupt another session.",
              "Do not message other sessions without explicit owner authorization. Exclude completed workers from GPU notices.",
              "An informational slot release requests neither new work nor an acknowledgement; report your handoff once and stop.", "", "REQUIRED CHECKS"]
    lines += [f"- {check}" for check in task['checks']]
    lines += ["- Run relevant current checks without weakening assertions; import/reopen a fresh handoff copy.",
              "- Preserve finite resources, original source hashes, inventory/work ownership, shapes/material gates and saved geography.",
              "- A failed placement keeps the kit; a successful one creates exactly one usable object.",
              "- Capture actual models in both renderers when applicable; separate benchmark runs from generation/captures."]
    if task['notes']:
        lines += ["", "SLICE-SPECIFIC NOTE", task['notes']]
    lines += ["", "FINISH",
              f"Write {prefix}/receipts/{task['id']}.md using receipts/TEMPLATE.md.",
              "Give absolute package/evidence paths, hashes, commands, dimensions/controls, measured costs and honest limitations.",
              "Show actual Blender/Godot renders and motion in chat for remote visual review, not only the source illustration.",
              "Commit checked scoped work on your branch. Report its exact SHA(s) and stop; the dedicated publisher",
              "integrates/pushes main serially under the owner's standing permission. Do not ask again for routine commit/push approval.",
              "Respect platform approval controls and report any automatic rejection and its reason; do not route around it.",
              "Report implementation, checks, limitations, local commit and publication status separately.",
              "Do not implement the next slice or claim owner visual acceptance from a successful technical check.", "```", ""]
    return "\n".join(lines)


def index(plan, counts):
    tasks = plan['tasks']
    lines = ["# ART-07 production — sliced plan and session prompts", "",
             "**Owner-requested dispatch pack, 9 September 2026.** The owner selected a sliced plan and prompts for other sessions to enact the environment/placeable direction. This delivery prepares those instructions; no implementation sessions or generation jobs are launched here.", "",
             "The plan refines the broad ART-07B–G headings into **26 bounded slices**. It preserves the complete current catalogue and the original concept → local TRELLIS → Blender → isolated Godot process. Ordinary-world rollout remains a later reviewed step after the retained-route pilot.", "",
             "## Current delivery and next prompts", "",
             'B1–B4, C1–C4, D1–D6, E2 and F5 are technically delivered: **16 of 26 slices**. The [first publication](publication-2026-09-10.md), [second publication](publication-2026-09-11.md), [third publication](publication-2026-09-11-batch3.md) and [fourth publication](publication-2026-09-11-batch4.md) record exact commits, verified local handoffs, fresh checks and unresolved visual/performance limits. Owner visual acceptance and ordinary-world adoption remain separate.',
             '',
             'The recommended next batch finishes the remaining regional source kits and supplies the two device prerequisites for F4. Paste one complete prompt into each separate session:',
             '',
             '1. [C5 — Ore-bearing rock family](prompts/C5.md).',
             '2. [C6 — Ruins and workshop approaches](prompts/C6.md).',
             '3. [F2 — Thrumroot winch and landing](prompts/F2.md).',
             '4. [F3 — Pullstone sorter and Ventlung bellows](prompts/F3.md).',
             '',
             'All four are dependency-ready: C5/C6 consume checked B3; F2/F3 consume checked D4/D6. Verify those absolute local handoffs before use. C5/C6 also read B4 contact/fit/cost findings. Completing and publishing F2/F3 unlocks F4; the following proposed batch can then be E1/E3/F1/F4 without dependencies between those four. G1 follows every B–F source slice, then a separate G2 reviewer. These later rows remain planned.',
             '',
             'Use separate worktrees and the shared GPU mutex plus read-only process checks. Cross-session messaging requires explicit owner authorization; exclude completed workers from GPU notices and do not create acknowledgement exchanges. No new sessions are started by this index.',
             '',
             "Use the [publisher prompt](prompts/PUBLISH.md) in one coordinating session after workers deliver checked commits. It integrates/pushes one result at a time and updates the shared queue. A dependent session starts after prerequisite recipes/receipts are published and its local source packages verify. A scheduled or merely generated source does not satisfy a dependency.", "",
             "## Complete slice map", "",
             "Every row has a copy-ready self-contained session prompt. Delivery is recorded separately in the publication report; rows without checked receipts remain planned. Each session finishes its own row and stops.", "",
             "| Slice | Track / result | Requires checked delivery | Prompt |", "| --- | --- | --- | --- |"]
    for task in tasks:
        needs = ", ".join(i.upper() for i in task['dependencies']) or "Existing approved inputs only"
        if task['id'] == 'g1':
            needs = "All B/C/D/E/F slices"
        lines.append(f"| ART-07{task['id'].upper()} | {task['track']}: {task['title']} | {needs} | [Copy {task['id'].upper()}](prompts/{task['id'].upper()}.md) |")
    lines += ["", "## Coverage and handoff contracts", "",
              f"The plan assigns one primary owner to all **{counts['shapes']} shapes, {counts['materials']} material families, {counts['devices']} station/device appearances (14 kits plus one upgrade), {counts['resource_nodes']} resource node types and {counts['nature_support']} supporting environment roles**. G2 audits retention of all {counts['fauna_presentation']} actor/host IDs; it does not reopen mob rigging or design.", "",
              "D1/D2/D3 own 24 structural/covering forms; E3 owns chest/campfire, bringing shape coverage to 26. D4/D5/D6 own the 19 material finishes; G1 verifies all 273 legal shape/family combinations. F1/F2/F3 own the five ordinary rare-resource chains; F4 owns the separate pressure pocket/feeder, and F5 preserves the four approved coloured families.", "",
              "Every output names its owned catalogue IDs and records metres, pivot/orientation, material/data-map semantics, LOD costs, source hashes and native state mapping. Dependencies are by checked manifests and actual files, not by matching filenames. Do not regenerate a good approved asset solely to fill a row.", "",
              "- [Shared session contract](COMMON.md): file ownership, worktrees, source preservation, completion and publication.",
              "- [Generation/Blender/Godot process](PROCESS.md): verified tools, exact generation flags, sample commands, physical scars, packed reopen and real engine evidence.",
              "- [Receipt template](receipts/TEMPLATE.md): one durable technical handoff per slice.",
              "- [Machine-readable plan](plan.json): explicit dependencies and catalogue ownership.",
              "- [Original design/gallery](../../art/concepts/environment/2026-09-09-frontier/README.md) and [ART-07 work item](../world-and-placeable-art-2026-09-09.md).", "",
              "## Review boundaries", "",
              "B4 is the first composition/cost checkpoint; G1 is a real isolated route/home, not a new generation profile. G2 must be performed by a different session from G1 and replay the package, not simply endorse its report. If a dependency is defective, return a bounded defect to its owner before claiming the consuming slice complete.", "",
              "Technical clearance and owner visual acceptance remain separate. Show actual model images/pulse in each session so the owner can review remotely. A requested new gameplay rule, footprint change or unapproved source replacement is a material decision; routine authoring, checking and scoped publication already have standing authorization.", "",
              "## Validation of this planning delivery", "",
              "Run `python tools/wroughtwild-world-design/session_plan.py` from the repository. It checks all 131 catalogue entries for exactly one primary owner, detects unknown/duplicate IDs and dependency cycles, checks reading/link targets and verifies that every generated prompt matches this plan. `--write` deliberately regenerates this index and worker prompts after a reviewed plan edit; it never starts work.", "",
              "[Observed planning checks](dispatch-checks.md) record this delivery's evidence and limits. The six concept PNGs/prompts and original asset catalogue keep their existing independent validators. This pack adds no game tuning, runtime art, save change, package install or background automation.", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    plan = json.loads((HOME / "plan.json").read_text(encoding="utf-8"))
    catalogue = json.loads((ROOT / plan['catalogue']).read_text(encoding="utf-8"))
    tasks = plan['tasks']
    task_ids = [t['id'] for t in tasks]
    assert len(task_ids) == len(set(task_ids)), "Duplicate slice"
    counts = {}
    for category in CATEGORIES:
        expected = {a['id'] for a in catalogue[category]}
        owners = Counter(asset for t in tasks for asset in t['owns'].get(category, []))
        assert set(owners) == expected, f"{category}: missing {expected-set(owners)}, unknown {set(owners)-expected}"
        assert all(v == 1 for v in owners.values()), f"Duplicate primary ownership: {category}"
        counts[category] = len(expected)
    seen = set()
    reads = set()
    for task in tasks:
        assert set(task['owns']) <= set(CATEGORIES), "Unknown catalogue category"
        assert set(task['dependencies']) <= seen, f"Out-of-order, unknown or cyclic dependency in {task['id']}"
        assert len(task['dependencies']) == len(set(task['dependencies'])), "Duplicate dependency"
        assert re.fullmatch(r'[a-g][1-9]', task['id']), "Unexpected slice path"
        for path in task['reading']:
            assert (ROOT / path).is_file(), f"Missing required reading: {path}"
            reads.add(path)
        seen.add(task['id'])
    outputs = {HOME / "README.md": index(plan, counts)}
    outputs.update({HOME / "prompts" / (t['id'].upper() + ".md"): prompt(t, plan) for t in tasks})
    for path, text in outputs.items():
        raw = text.encode("utf-8")
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)
        else:
            assert path.exists() and path.read_bytes() == raw, f"Stale/missing generated prompt: {path}"
    expected_prompts = {t['id'].upper() + ".md" for t in tasks} | {"PUBLISH.md"}
    assert {p.name for p in (HOME / "prompts").glob('*.md')} == expected_prompts, "Unexpected/missing prompt file"
    link_count = 0
    for doc in HOME.rglob('*.md'):
        for target in re.findall(r'\]\(([^)]+)\)', doc.read_text(encoding='utf-8')):
            if target.startswith(('https:', 'http:', '#')):
                continue
            path = target.split('#', 1)[0].strip('<>')
            assert (doc.parent / path).resolve().exists(), f"Broken link: {doc}: {target}"
            link_count += 1
    print(json.dumps({"result": "PASS", "production_slices": len(tasks), "worker_prompts": len(tasks),
                      "publisher_prompts": 1, "catalogue_entries_owned_once": sum(counts.values()),
                      "coverage": counts, "dependency_edges": sum(len(t['dependencies']) for t in tasks),
                      "required_reading_files": len(reads), "local_links": link_count,
                      "initially_ready": [t['id'] for t in tasks if not t['dependencies']]}, indent=2))


if __name__ == '__main__':
    main()
