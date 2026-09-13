# G2 independent review tools

These tools review the sealed G1 package. They write only this worktree's
`build/art07/g2/` outputs and the G2-owned source/evidence paths. The canonical
G1 handoff, source packages, normal game, tuning and saves stay read-only.
The G1 wrappers retain their original G1 output guards and are never redirected.

The worktree is `D:/project-wroughtwild-art07-g2`, branch `codex/art07-g2`, based
on published main `8439b5a7745ca491b694406789273a412aec44d2`. D: was selected
because C: had only 1.8 GiB free; no old work or caches were deleted. Game/data/
native remain pinned to `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`.

## Reproduce

Use the installed Python at
`C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
The checked commands and exact argument arrays are also saved in the local
handoff's logs and job specifications. Run from this worktree:

```powershell
$g2Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $g2Python tools/wroughtwild-art07/g2/verify_copy.py build/art07/g2/v01
& $g2Python tools/wroughtwild-art07/g2/source_audit.py
& $g2Python tools/wroughtwild-art07/g2/make_jobs.py
& tools/wroughtwild-art07/g2/run.ps1 -Spec build/art07/g2/v01/core-jobs.json
& tools/wroughtwild-art07/g2/run.ps1 -Spec build/art07/g2/v01/native-jobs.json
& tools/wroughtwild-art07/g2/run.ps1 -Spec build/art07/g2/v01/render-jobs.json
& $g2Python tools/wroughtwild-art07/g2/install_inspection.py
& tools/wroughtwild-art07/g2/run.ps1 -Spec build/art07/g2/v01/supplement-jobs.json
& tools/wroughtwild-art07/g2/run.ps1 -Spec build/art07/g2/v01/g2-benchmark-jobs.json
& tools/wroughtwild-art07/g2/run.ps1 -Spec build/art07/g2/v01/blender-jobs.json
# Record the actual test machine; no asset-generation or benchmark process is active.
$g2Hardware = @{ cpu = @(Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors); os = @(Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,TotalVisibleMemorySize); gpu = @(& nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv); blender = '4.5.9'; godot = '4.5.stable.official.876b29033' }
$g2Hardware | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath build/art07/g2/v01/hardware.json -Encoding utf8
& $g2Python tools/wroughtwild-art07/g2/collect.py
& $g2Python tools/wroughtwild-art07/g2/verify_copy.py build/art07/g2/v01/after --verify-only
& $g2Python tools/wroughtwild-art07/g2/preservation.py
# Finalize the human-readable G2 findings from those actual outputs, then seal.
& $g2Python tools/wroughtwild-art07/g2/package.py
& $g2Python tools/wroughtwild-art07/g2/package.py --verify
```

These are fresh-output recipes: use a new version and update the explicit `OUT`
constants in the small G2 recipes before repeating. Do not overwrite the checked
v01 or reuse its logs as a new run. `verify_copy.py --verify-only <fresh-output>`
rechecks all 24 source packages and the original G1 seal without copying them.

`verify_copy.py` independently verifies every prerequisite manifest/file and its
published receipt before making a complete sealed copy and a second mutable
runtime copy. `source_audit.py` compares both archives to pinned Git blobs,
accepting only an explicitly recorded CRLF-to-LF export difference, reconstructs
the recorded presentation hooks, checks published recipe equivalence, and records
the exact 16 retained actor IDs, source meshes, bodies and existing rig versions.

`run.ps1` uses hidden owned processes, the shared `Local\Wroughtwild-Art07-GPU`
mutex, read-only process checks, distinct APPDATA/LOCALAPPDATA/TEMP/TMP and Blender
resources. It rejects engine/script errors and competing benchmark processes;
it can stop only the specific failed child it launched. All arguments, PIDs,
exit status, durations, diagnostic text and log hashes are recorded. The ordinary
certificate-store diagnostic is distinguished from script/renderer failures.

## Inspection adaptations and limits

All G1/native test assertions are replayed unchanged. `fauna.gd` instantiates
only the 16 existing IDs in a labelled static inspection and checks retained
model identity and body/combat state. It neither authors rigs nor adopts the
six ART-06C source animals. `canopy.gd` reads the actual live B1 fit metadata
without changing geometry, saved poses or inventory.

The G2 benchmark is mechanically derived from sealed `g1/review.gd`. Its only
changes are the G2 output prefix and recording engine-clock setup elapsed time and the maximum wall/GPU frame in
addition to the existing median/p95. Cameras, paid checkpoint, 120 warmup and
300 sample frames, 1440x900 viewport, 4x MSAA, shaders and native state remain.
The derivative and exact substitutions are in the local inspection package.
Blender runs the verified explicit-path G1 reopen recipe against G2 copies;
all 30 packed masters remain unchanged. The six-GLB assembly is static geometry
inspection, never a second gameplay map.

G1's labelled fixture controls and normal WASD/mouse, E, C, B/Tab/Q/R, LMB,
I, H and F5/F9 controls remain. The runtime custom directory name is ART07G1
inside the explicitly G2-owned APPDATA path; the name does not select normal
player data. Launch exact review jobs through the G2 runner, not a canonical
G1 launcher with inherited paths. No game tuning parameters are introduced.

See the G2 evidence report and receipt for the actual verdict, measurements,
commands, execution corrections, visual defects and publication status.

## Actual v01 execution record

`core-jobs.json` retains the original mistakenly named full paid replay.
`restart-job.json` is the correct additional fresh-process restart. The actual
28 source jobs use `native-full-jobs.json`; the initial 24-job native spec was
not run. The checked generator now emits all 28. `g2-benchmark-jobs.json` is the
executed derivative; the original `benchmark-jobs.json` is its recorded input.
All exact spec arrays remain in the handoff's audit directory.

`hardware.json` records the actual CIM CPU/OS fields, NVIDIA GPU/driver/VRAM and
engine versions. It is measurement evidence, not a tunable or prerequisite to
changing content. Repeated collection uses a newly recorded hardware file.
`collect.py` requires the exact executed specification IDs/arguments (64 for
v01; 63 for the corrected fresh recipe without the extra restart), all 477
packed file images and exact matched views/resources. Regenerating derived
JSON on the same evidence must reproduce identical values or fail; it never
counts as a new engine run. For an exact historical replay, use the sealed v01
specs; the corrected generator is a new run whose execution note must identify
its actual flags. It retains diagnostic warnings. `preservation.py`
checks original runtime bytes and inventories new evidence/test state; only the
sealed harness's disposable paid-home checkpoint may change. `package.py` seals
full fresh evidence, logs, G2 tools, inspection additions and test fixtures,
while identifying the unchanged complete source/runtime companions.

A standalone reimport/launch is the `import` followed by the
`smoke-forward_plus` or `smoke-gl_compatibility` job: copy its recorded object
into a new JSON array, give it fresh G2-owned log and state paths, and pass that
JSON to `run.ps1 -Spec`. This launches the copied `res://g1/play.tscn` and
verifies its paid checkpoint before exiting. For manual inspection the same
scene supports the controls above; omit `--smoke` in a new job. All launches
retain isolated G2 APPDATA and never select normal player data.

The final checked evidence seal is `build/art07/g2/v02/handoff`; runtime, logs
and executed captures remain in v01. The preliminary v01 seal is retained after
a staged whitespace check trimmed four G2 recipe EOFs. Only the G2 fauna copy
received that matching whitespace-only trim. `preservation-final.json` checks
the final state; G1 inputs and all executable statements remain unchanged.
