# ART-07F2 production recipe

Owns only this tool directory, `docs/art/leyline-studies/2026-09-09/art07/f2/`
and the F2 receipt. All output below is ignored under this worktree's
`build/art07/f2`. Native/game baseline is the published
`4b5d89b376765fbf4d46049aa099e0bb154a82da`. No game, data, native source,
queue, catalogue or other slice is changed. See [CONTRACTS.md](CONTRACTS.md)
for the native integration contract and visual controls.

## Reproduction

From the F2 worktree root in PowerShell, use the already installed executables:

```powershell
$f2Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$f2Blender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$f2Tools=Join-Path (Get-Location) 'tools/wroughtwild-art07/f2'
$f2Build=Join-Path (Get-Location) 'build/art07/f2'
& $f2Python "$f2Tools/verify_inputs.py" "$f2Build/inputs-before-new.json"
```

`verify_inputs.py` checks all 196 D4 and 78 D6 package files, published receipts,
and source/tool hashes. Read their paths and expected hashes in that script.
Never use a new output name to overwrite an older result. The selected run is
raw v01, corrected inspection v02, finished source v03, corrected devices v03.

The single-object input PNG and exact image-generation prompt are tracked in
the F2 gallery. `generate.ps1` verifies all ten pinned TRELLIS model hashes and
uses Windows CUDA v0.6.0, 1024, seed 42, GPU 0 required, BiRefNet with retained
cutout, PNG output and eight threads. It uses the shared GPU mutex. The completed
run's exact CLI is `raw/generation.log.json` in the handoff; the initial wrapper
deferred before generation, then the identical job was queued successfully.
Its raw GLB is unchanged. No external models or packages were downloaded.

Run Blender recipes through `queued-job.ps1` with absolute paths:

```powershell
& "$f2Tools/queued-job.ps1" -Program $f2Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python',"$f2Tools/inspect_source.py",'--',"$f2Build/v01/generated/source.glb","$f2Build/new-inspection") -Log "$f2Build/new-inspection.log"
& "$f2Tools/queued-job.ps1" -Program $f2Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python',"$f2Tools/finish_source.py",'--',"$f2Build/new-inspection","$f2Build/new-source") -Log "$f2Build/new-source.log"
& "$f2Tools/queued-job.ps1" -Program $f2Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python',"$f2Tools/model_devices.py",'--',"$f2Build/new-devices") -Log "$f2Build/new-devices.log"
& "$f2Tools/queued-job.ps1" -Program $f2Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python',"$f2Tools/reopen.py",'--',"$f2Build/new-devices","$f2Build/new-source","$f2Build/new-reopen") -Log "$f2Build/new-reopen.log"
```

The generation recipe's literal dimension/path choices are for this asset,
not a general pipeline. Reopen confirms packed images, all seven fresh GLBs,
zero degenerate/nonfinite geometry, source vertex masks, body fit, native pivot
and basket sphere containment. `--python-exit-code 1` is required: an early
diagnostic reopen returned Blender exit 0 with an assertion traceback; it was
rejected. The wrapper now also rejects Python tracebacks and Godot errors.

Build and freeze the original native/game code using the existing approved
MinGW and godot-cpp installation (paths and hashes recorded by the build):

```powershell
& "$f2Tools/build-native.ps1" -Output "$f2Build/new-native" -Depot 'C:/Users/Matty/Dev/project-wroughtwild'
& $f2Python "$f2Tools/freeze_game.py" "$f2Build/new-game" "$f2Build/new-native"
& $f2Python "$f2Tools/install_review.py" "$f2Build/new-game/game" "$f2Build/new-devices" "$f2Build/new-source"
& "$f2Tools/native_review.ps1" -Project "$f2Build/new-game/game" -Output "$f2Build/new-regression"
& "$f2Tools/check_review.ps1" -Project "$f2Build/new-game/game" -Output "$f2Build/new-checks"
& "$f2Tools/render_review.ps1" -Project "$f2Build/new-game/game" -Output "$f2Build/new-captures" -Mode capture
& "$f2Tools/render_review.ps1" -Project "$f2Build/new-game/game" -Output "$f2Build/new-motion" -Mode motion
# Run only after generation, captures and headless checks have ended.
& "$f2Tools/render_review.ps1" -Project "$f2Build/new-game/game" -Output "$f2Build/new-benchmark" -Mode benchmark
```

`install_review.py` modifies only a guarded frozen game copy. It hooks the
existing `StrangeResourceArt`, without changing `ContraptionSite`,
`ResourceNode`, save manager, player transaction code or native rules.
`art.gd` removes the GLB scene wrapper and normalizes the real static mesh's
name to `Housing`; this preserves the unchanged placement contract.
The study uses actual native crafting, kit placement, wind/start and cargo
transactions. Original regression tests are copied without assertion edits.

Every rendered job acquires `Local\Wroughtwild-Art07-GPU`, checks process
identities read-only, runs its own hidden process and releases the mutex.
Queued jobs wait at most six minutes without owning the slot, then fail before
launch; rerun only after verifying no job output exists. Benchmark jobs also
defer for headless Godot. No background automation or messages to other workers
are installed. Headless tests use the separate F2 save directories `u` and `nu`.

## Evidence and packaging

Captures are unmodified Godot viewport PNGs at 1440×900, 4× MSAA, both
`forward_plus` and `gl_compatibility`. The 108-frame clips are actual paid native
travel at 24 simulation samples/second with a physical obstruction inserted at
frame 24 and removed at 48. Motion JSON records native state and actual basket
and drum poses per frame. `evidence.py` validates conservation and the blocked
pose interval, then assembles those PNGs into a WebP for remote review.
It does not synthesize or interpolate model motion.

Benchmarks are separate process runs, 120 warmup + 600 measured frames,
1440×900, 4× MSAA, VSync off, stable camera and the same two-endpoint study.
Device, rendering path, p50/p95/worst frame times, draw calls, primitives and
texture memory are recorded in JSON. They are not full-game performance claims.

`package.py` selects the checked v03 outputs and seals a **fresh** directory.
Raw/master/build outputs remain local-only. Git receives recipes, contracts,
source input, curated actual evidence, hashes and the receipt. The sealed package
contains a full frozen review project with the fresh native DLL and sibling
tuning data, all seven runtime models, packed masters, original TRELLIS output,
recipes, evidence and a SHA-256 manifest. `validate_package.py` checks all hashes
then makes a fresh copy; run headless import/check/restart and Blender reopen
against that copy, never against the sealed package. Recheck the manifest after.

Known limits and iteration rejections are recorded in CONTRACTS and the receipt.
Technical completion does not imply owner visual acceptance. F4 may consume the
published receipt/package; F2 neither integrates main nor implements F4.
