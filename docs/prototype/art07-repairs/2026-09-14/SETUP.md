# Worktree and runtime setup

Start with [the plan](README.md). R8 still waits for checked R7 publication.
No worker task was launched by publication. [Workspaces](workspaces.json)
preserves historical preparation and current delivery state.

Published repair candidates: [R1](publication-r1.md) [R2](publication-r2.md) [R3](publication-r3.md) [R4](publication-r4.md) [R5](publication-r5.md) [R6](publication-r6.md).
The initial setup flags remain historical; [deliveries.json](deliveries.json)
is the current readiness record.

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

## Ready wave 2 — 14 September 2026

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
