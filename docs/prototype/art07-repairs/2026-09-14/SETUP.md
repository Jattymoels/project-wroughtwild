# Worktree and runtime setup

Start with [the plan](README.md). The prepared first wave is R1–R4; use one task
per listed working directory and paste its full prompt. No worker task is launched
by this setup. Reuse a prepared directory; do not create another checkout inside it.
The initial [setup record](workspaces.json) distinguishes actual preparation from
future planned paths. Later worktrees are created only after their wave gates pass.

R2 now has a [verified publication](publication-r2.md). The initial setup flags
remain historical; [deliveries.json](deliveries.json) is the current readiness
record. R5-R7 still require R1, R3 and R4 publication as well.

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
