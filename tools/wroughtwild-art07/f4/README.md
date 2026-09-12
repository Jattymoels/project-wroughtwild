# ART-07F4 reconstruction and isolated review

Read `CONTRACT.md` for native pivots, material/ownership boundaries and limitations.
This slice owns only its recipes, curated evidence and receipt. It does not patch
the ordinary game. The publication session integrates the scoped branch separately.

## Tools and inputs

Worktree: `C:/Users/Matty/Dev/project-wroughtwild/build/art07/f4/worktree`.
Branch: `codex/art07-f4`; frozen base `bbcb3a7dfd235e8f803141ccb57c38e03d6c1708`.
Use the existing depot Blender 4.5.9, Godot 4.5 stable, MinGW and bundled Python
with Pillow/NumPy. No new package, model download or network generation is needed.
`inputs.py` fixes and verifies the exact published E2/F2/F3 manifests and all
their files before use. The organic and mechanical sources are reused; no F4
imagegen or TRELLIS call is claimed. Donor receipts preserve their raw lineage.

The bounded process/check wrappers derive from E2; metric modelling helpers
derive from F2. They are local copies, not edits to shared tools. `gpu-slot.ps1`
uses `Local\Wroughtwild-Art07-GPU`, read-only process checks, hidden child windows,
eight Blender threads and F4-only APPDATA. It never interrupts another process.
Benchmarks refuse active art, engine and recognized native compiler processes.

## Reconstruct from this worktree

Run PowerShell here. Every output argument below must be fresh. Read wrapper
arguments rather than silently reusing a previous version. Example reconstruction
version `rebuild01` is not a claim that this exact version was executed:

```powershell
$f4Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $f4Python tools/wroughtwild-art07/f4/inputs.py build/art07/f4/rebuild01/inputs.json
& ./tools/wroughtwild-art07/f4/build-native.ps1 -Output build/art07/f4/rebuild01/native -Depot 'C:/Users/Matty/Dev/project-wroughtwild'
& ./tools/wroughtwild-art07/f4/queued-job.ps1 -Program 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe' -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/f4/build_assets.py','--','build/art07/f4/rebuild01/assets') -Log build/art07/f4/rebuild01/author.log
& $f4Python tools/wroughtwild-art07/f4/prepare.py build/art07/f4/rebuild01/review build/art07/f4/rebuild01/assets build/art07/f4/rebuild01/native
& ./tools/wroughtwild-art07/f4/queued-job.ps1 -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments @('--headless','--editor','--import','--path','build/art07/f4/rebuild01/review/game') -Log build/art07/f4/rebuild01/import.log
& ./tools/wroughtwild-art07/f4/run.ps1 -Game build/art07/f4/rebuild01/review/game -Log build/art07/f4/rebuild01/check.log -Mode check
& ./tools/wroughtwild-art07/f4/run.ps1 -Game build/art07/f4/rebuild01/review/game -Log build/art07/f4/rebuild01/restore.log -Mode restore
& ./tools/wroughtwild-art07/f4/run.ps1 -Game build/art07/f4/rebuild01/review/game -Log build/art07/f4/rebuild01/exhausted.log -Mode exhausted
```

`run.ps1 -Mode capture`, `restore-capture` and `exhausted-capture` take actual
renderer images. Supply each renderer (`forward_plus`, `gl_compatibility`) and
a fresh log. Run `-Mode benchmark` separately after captures and native suites.
`regressions.ps1 -Game ... -Logs FRESH_DIRECTORY` runs unchanged current engine
scenarios; `native_checks.py FRESH_DIRECTORY` builds/runs the domain suites.
`asset_cost.py ASSETS FRESH_JSON` checks exported triangle/surface counts and
noncollapsed UVs, with distinct texture payload and uncompressed mip estimates.

Open the packed source through a new guarded Blender process using
`reopen.py -- ASSETS FRESH_OUTPUT`; it renders six angles in material/clay,
checks every packed image, independently imports nine GLBs, and audits bounds,
finite vertices, triangles and degeneracy. It also records inherited nonmanifold
edge counts honestly; no assertion that every donor is a watertight solid.

`curate.py REVIEW REOPEN FRESH_MEDIA` encodes actual source frames. 30 active
native ticks, 15 paused frames, 15 physically blocked frames are retained with
native ledger evidence. No interpolated or generated success animation is used.

## Standalone handoff

The receipt names the selected absolute package path and its manifest SHA-256.
The ignored package is required; a clean clone alone contains no Blender master,
native DLL or generated runtime bundle. Transfer the sealed package plus verified
manifest to another machine; its existing Godot executable can be passed to the
launcher. Rebuilding requires the separately verified published source handoffs.

```powershell
& $f4Python tools/wroughtwild-art07/f4/fresh_copy.py ABSOLUTE_PACKAGE ABSOLUTE_FRESH_COPY
& ABSOLUTE_FRESH_COPY/launch.ps1 -Mode import
& ABSOLUTE_FRESH_COPY/launch.ps1 -Mode restore
& ABSOLUTE_FRESH_COPY/launch.ps1 -Mode exhausted
& ABSOLUTE_FRESH_COPY/launch.ps1 -Mode play -Renderer forward_plus -Show
```

The last command intentionally shows an interactive window only when the reviewer
requests it. Test launches use hidden windows. Saves live in the fresh copy's
`user/F4Native`, seeded from delivered paid checkpoints only when absent.
Do not import the canonical handoff directly. Rehashing it after fresh-copy tests
must still match its manifest. Git contains recipes, receipt and curated media;
raw/build/master/native/checkpoint/cache files remain local-only.
