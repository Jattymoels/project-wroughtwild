# Worktree and runtime setup

Start with [the plan](README.md). R1–R8 are checked and published. R9 is the next
independent review; its actual worktree preparation is recorded separately.
No worker task was launched by publication. [Workspaces](workspaces.json) preserves
historical setup and current delivery records.

Published repair candidates: [R1](publication-r1.md) [R2](publication-r2.md) [R3](publication-r3.md) [R4](publication-r4.md) [R5](publication-r5.md) [R6](publication-r6.md) [R7](publication-r7.md) [R8](publication-r8.md).
The initial setup flags remain historical; [deliveries.json](deliveries.json) is
the current readiness record.

The owner depot is `C:/Users/Matty/Dev/project-wroughtwild`. D: was chosen because
C: had about 5 GiB free while D: had about 1.3 TiB when preparing the pack. No old
packages/caches were deleted. Each copied base runtime is about 3.44 GB before
import; changed masters, versions and caches need additional task-local space.

Installed tools (verify before launch):

| Tool | Path |
| --- | --- |
| Python | `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` |
| Blender 4.5.9 | `C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe` |
| Godot | Copied pinned executable under each version's `runtime/engine/` |
| Raw source packages | Exact paths and hashes in [inputs.json](inputs.json) |

## Ready wave 3 — 14 September 2026

Use [the complete R8 prompt](prompts/R8.md) in `D:/project-wroughtwild-art07-r8`,
on branch `codex/art07-r8`. R1–R7 are all checked and published. This setup was
created from verified published main `e58efe3ea5451024c95a07bf8250ca2ecb119df1`.

The prepared `build/art07-repairs/r8/v01/runtime` is the common G1 baseline:
4,787 files, 3,438,257,458 bytes, verified native DLL and no inherited cache.
No candidate delta has been applied and no engine has run in this directory.
The worker must rehash the seven exact packages in deliveries.json before
composing the final runtime. [Wave-3 setup checks](wave3-setup-checks.json)
record the actual preparation and validators.

Integration must account for these recorded overlaps and limits:

- R7 already consumed the 105-file R1 parent delta. Apply that ancestry once.
- Merge R2 resource reuse and image aliases with R3 building face/end/edge
  bindings, R5's eight replacement chest bodies, R6's C5 material/state hooks,
  and R7's consumed shrub albedo/ORM. Verify final bindings and resource dispatch.
- Preserve R4's ten-file fixture cleanup delta when composing review harnesses.
  Keep R7's successful normal-resource-graph grounding bootstrap and the retained
  direct-start failure evidence until separately resolved. Its grounding checks
  need a real renderer: the publisher confirmed that the pinned headless dummy
  renderer returns identity MultiMesh transforms. Use a startup no-focus window
  and preserve all native assertions; see publication-r7.json for the diagnostic.
- R7 fresh saves retain the same native state but differ in two engine-generated
  station scene names. Preserve raw evidence and stable station key/type/pose/
  ownership checks; do not claim fresh byte identity. Its generated previous
  checkpoint is a rotated test output, not an immutable authored source.
- G2 visual findings remain partial where recorded: canopy/colour quality,
  chest feet and lid clearances, flat ore surfaces, and unmet continuous
  understorey. R6 raised geometry and R7 larger envelopes/new roots remain
  proposals. Do not implement new body or geography rules to close those rows.
- Recheck all 273 building pairs, including octagonal/chamfer/triangle uses,
  F4 fractional/exhausted recovery, finite stock and native paid ownership.
  Remeasure R2 setup/residency on the combined result; isolated wins do not
  establish final cost or target-hardware acceptance.

Follow AGENTS.md's desktop-comfort preference and completion-summary format:
background Blender, headless checks where suitable, verified test-only mouse
capture opt-out/non-focusing windows for rendered jobs, and explicit notice if
foreground interaction is unavoidable. Preserve ordinary play controls and
benchmark conditions. Finish with a short summary of what R8 achieved.

Run R8 only. R9 is prepared after checked R8 publication, in an independent task.
No ordinary-world rollout or ART-06C rig adoption is included.

## Ready wave 2 — 14 September 2026

Historical setup: R5–R7 are now completed, checked and published.

| Full prompt | Assignment | Prepared working directory |
| --- | --- | --- |
| [R5](prompts/R5.md) | Correct chest visual seating | `D:/project-wroughtwild-art07-r5` |
| [R6](prompts/R6.md) | Resolve faceted-ore visual coverage | `D:/project-wroughtwild-art07-r6` |
| [R7](prompts/R7.md) | Compose fuller habitat at retained anchors | `D:/project-wroughtwild-art07-r7` |

Created from published main `40dc044a97b28cab7b48b8a37260976b2581989d`. Each has a verified
`build/art07-repairs/<id>/v01/runtime`, with 4,787 copied entries and 3,438,257,458
bytes, a pinned native DLL, fresh import/smoke specifications and no inherited cache.
Setup has started no engine and implemented no repair. Source masters and predecessor
packages remain in their immutable locations until the worker verifies and consumes
them. R7 must apply the published R1 canopy delta deliberately; its prepared runtime
is the common G1 baseline. R5/R6 consume their assigned sources independently.

Paste the complete fenced prompt from the link into a task opened in its listed
directory. R5, R6 and R7 may work independently, sharing the existing serial GPU
guard. After all three are checked and published, release R8; R9 follows R8 in an
independent task. [Wave-2 setup checks](wave2-setup-checks.json) record execution.

## Worker entry

Use the prompt's exact working directory and branch. Inspect the repository status,
branch and setup record first. Prepared `v01/runtime` contains byte-verified G1
game/data/engine entries and no inherited `.godot` cache; it is not a repaired asset
candidate and has not been imported by setup. `prepared.json` records its original
hashes. All other sources/masters stay in their original seals until the worker
selects, verifies and copies the ones needed for the assigned repair.

If v01 already exists, inspect and reuse that correct prepared copy. To make an
additional fresh version, run this from the assigned R worktree, replacing the
ID/version with the real assignment and a path that does not already exist:

```powershell
$repairPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $repairPython tools/wroughtwild-art07-repairs/workspace.py inspect --id r1
& $repairPython tools/wroughtwild-art07-repairs/workspace.py prepare --id r1 --version v02
```

The copy helper verifies the source manifest identity and hashes every copied
runtime entry. It does not claim to rehash unconsumed masters or every earlier
source package. The worker must fully verify each extra source or dependency it
consumes. Do not run Godot/Blender in any canonical or peer package directory.
`workspace.py verify --id r1` (substitute the assigned ID) rehashes every manifest
entry in the runtime source, G2 review, assigned original sources and released
predecessor packages. Retain this read-only verification output before consuming
their source/master files.

Each new version gets `import-smoke.json`, with import and paid-home smoke jobs in
both renderers, copied engine arguments and private user paths. Run it from that
worktree through the guarded runner, then build the task-specific tests from the
recorded G1/G2 arguments and the relevant source fixtures:

```powershell
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v02/import-smoke.json
```

This command occupies the shared GPU slot. If it is busy, leave other tasks alone
and continue CPU work. New test invocations need fresh logs/state directories;
do not overwrite old logs or call old unexecuted results a new run. The runner
allows only this R branch's build subtree and checks existing art/game processes.
For manual review use a new recorded job for `res://g1/play.tscn` without `--smoke`,
with private state; normal WASD/mouse, E, C, B/Tab/Q/R, LMB, I, H and F5/F9 remain.

## Later waves and serial publication

After a wave is published, the coordinator creates the next directories from an
explicit inspected current main commit using this command from the owner depot:

```powershell
$repairPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
# Replace the bracketed value with the actual full, checked published main SHA.
& $repairPython tools/wroughtwild-art07-repairs/workspace.py create --wave 2 --base '[checked main SHA]'
```

`create` checks all wave gates and dependencies in deliveries.json, verifies their
receipt/package identities and published ancestry, and refuses existing paths or
branches. It neither changes the owner's branch nor deletes/rewinds anything.
If a legitimate worktree already exists, inspect and reuse it manually. Later tasks
prepare their own fresh runtime after checking those dependencies. R8 consumes
R1–R7 candidate changes; R9 prepares a fresh copy of R8's final sealed package.
No later dependency is fabricated or pre-marked complete in the setup.

Use [PUBLISH](prompts/PUBLISH.md) in the serial coordinating task after worker
completion. The coordinator updates source and setup records after a real checked
delivery. Platform approval controls still apply; explain any automatic rejection
and do not bypass it. The existing standing permission covers ordinary checked
commits and non-force pushes to the already approved origin/main.
