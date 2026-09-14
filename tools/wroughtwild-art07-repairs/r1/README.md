# ART-07R1 — broad canopy candidate

Run from `D:/project-wroughtwild-art07-r1`, branch `codex/art07-r1`. This recipe
owns only R1 tools, evidence and receipts. The runtime is the exact G1 pin
`6bb2e044dcd0bf1788896aa2c19cdf56fee93522`, not this newer documentation checkout.
The selected candidate is `build/art07-repairs/r1/v03`. v01 and v02 are retained
rejected experiments; never reuse their output directories or logs.

## Presentation contract

The G1 B1 adapter squeezed each entire tree in X/Z to fit its walk-height trunk.
R1 applies the fit to the source mesh's lower region, blending back into its crown.
Each original packed master and source collection is retained. The new editable
collection is `R1 REFITTED RUNTIME`. Exports reuse every original branch, leaf and
packed map, including the alternate and altered forms; there is no new scatter.
Original source Y extrema and burial are retained in every exported LOD.

`native_tree.gd` inherits the unchanged native resource actor and selects the
refitted `a-lod2` plus its matching stump, at unit scale. `install.py` changes only
`G1Art.resource` in the copied baseline: adapter selection, family selection and
retention of the `b1` owner metadata. `--r1-before` selects the original G1 adapter.
This flag is for comparison jobs. C4's existing ash source and fit are unchanged.
The source ID, world position/yaw, collision, targeting, finite stock, drive work,
partial state, fall, pickups, stump lifetime and visibility distances remain native.

No loading/resource reuse changes are included. R2/R8 must reconcile any overlap
in `G1Art.resource` and may consume the R1 selected meshes when merging their own
loading work. R7 owns any later composition decision. Ordinary-world rollout,
rig adoption and owner visual acceptance are outside this worker's completion.

## Controls and tolerances

`settings.json` records the experience controls:

| Value | Purpose |
| --- | --- |
| Lower radius 0.343 m | 98% of the existing 0.35 m half-body width; central wood stays fuller than a single whole-tree squeeze. |
| Clear height 2.6 m | Constrain lower wood above the unchanged 1.92 m capsule and 1.68 m eye/work height. |
| Full-crown height 4.2 m | Smoothstep recovery from the lower fit to source crown spread; preserve connected transitions. |
| Broadleaf burial 0.65 m / pine 0.55 m | Existing B1 seating; no ground or spawn-height change. |
| Selected runtime LOD 2 | Existing G1 selection; near/middle exports are supplied for inspection, with no new LOD switching. |

The lower radial map is `R / sqrt(R*R + radius*radius)`. A cubic smoothstep blends
it to 1 between the two heights. Nonlinear deformation can separate interpolated
leaf/twig attachments; `build.py` re-seats contacts over 7 mm, tapering displacement
to zero at their original tips. It then trims only residual lower-radius excess.
The 1 micrometre weld tolerance reconstructs glTF seam-split connected components;
it does not merge separate authored branches. These are authoring tolerances.

`reopen.py` retains the B1 13 mm leaf-root and 26 mm branchlet contact assertions.
It requires finite geometry, no triangles below 1e-12 square metres, and lower
radius <= 0.343001 m (1 micrometre float allowance). `model_costs.py` requires
unchanged triangle counts, original height extrema within 1e-5 m and identical
sets of decoded embedded maps. These are verification tolerances, not game rules.

## Reconstruct a fresh version

Use the installed Python; no additional dependency or tool download is required.
Choose an absent version in this same assigned worktree. The commands below use
`v04` only as an example for a future absent output; check it first. Never run the
engine directly against a package, owner checkout or peer directory.

```powershell
$repairPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $repairPython tools/wroughtwild-art07-repairs/workspace.py inspect --id r1
& $repairPython tools/wroughtwild-art07-repairs/workspace.py verify --id r1
& $repairPython tools/wroughtwild-art07-repairs/workspace.py prepare --id r1 --version v04
$env:WW_R1_VERSION='v04'
& $repairPython tools/wroughtwild-art07-repairs/r1/copy_sources.py
& $repairPython tools/wroughtwild-art07-repairs/r1/measure.py
& $repairPython tools/wroughtwild-art07-repairs/r1/author_jobs.py
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/model-jobs.json
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/source-audit-jobs.json
& $repairPython tools/wroughtwild-art07-repairs/r1/model_costs.py
& $repairPython tools/wroughtwild-art07-repairs/r1/material_audit.py
& $repairPython tools/wroughtwild-art07-repairs/r1/install.py
& $repairPython tools/wroughtwild-art07-repairs/r1/jobs.py
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/import-smoke.json
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/native-jobs.json
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/core-jobs.json
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/capture-jobs.json
& tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r1/v04/benchmark-jobs.json
```

Retain the full verify output before source consumption. All generated jobs use
fresh log/private-user roots. The unchanged runner owns the single GPU mutex and
checks existing processes. On deferral, leave the other process running. Do not
change the shared guard or re-label an old receipt as a new run. The recipe's
source exports are deterministic geometry transformations; Blender version and
serialized master metadata can change byte-level export identity on a rebuild.
Use the sealed candidate for exact bytes.

## Evidence definitions

- `views.gd`: fixed paid G1 checkpoint, four identical 1.68 m eye-height cameras,
  day/shade/dusk, 1440 x 900, FOV 60, 4x MSAA, VSync off in both renderers.
  Shade multiplies existing sun energy by 0.12; dusk by 0.35 with `d9bd91` light.
  Captures settle for 18 frames. Timing uses 120 settle + 300 measured frames per
  view/light, in separate processes without image writes. These are review settings.
- Projected crown widths use imported upper-mesh bounds in each labelled camera's
  right axis. Only boxes entirely in front of the camera are projected. Pixel overlap is
  clipped, conservative AABB overlap; it is not opaque foliage coverage or a
  complete tree census. Actual renders are the visual evidence.
- `studio.gd`: comparison stand of all 15 crown LODs, emission off/on and 48 frames
  of the existing scar shader at explicitly stepped 12 Hz. This is illustrative
  shader playback on the actual model, not native gameplay or a new effect.
- `b1_native.gd` / `c4_native.gd`: original finite-work/restoration assertions plus
  actual native target rays and controller/capsule movement around the lower body.
  The added support floor exists only in this isolated fixture. Rendered B1 uses
  fixed 60 Hz and records capture physics/draw frame numbers for fall playback.
- `probe.gd`: full paid ownership snapshot and geography before/after presentation.
  `paid.gd`: unchanged no-grants paid workflow and >100 m actual input route, with
  a separate-process restore. Gathering/address selection is harness-paced, as G1.
- `catalogue.gd`: unchanged assertions for every 273 legal pair, including chamfer,
  triangle and octagonal uses; explicitly separate inspection stock, not the paid save.
- `route.gd`: original native controller route in separate capture and timing runs.
  Streaming wall samples include actual loading while traversing that route.

CPU, memory, selected GPU, settings, job durations, logs, native results, map hashes
and image provenance are retained in the candidate. Current-machine measurements
are not minimum-hardware clearance. Known exit cleanup diagnostics remain visible
and are attributed to the unchanged source fixtures; R4 owns lifecycle repairs.

`package.py seal` requires completed strict `final-checks.json`; `package.py verify`
checks the exact set, size and SHA-256 of every file. `apply.py` applies only the
listed R1 delta to an exact fresh prepared R1 runtime, after verifying all inputs.
The receipt lives outside the hashed package. R1 commits owned files only; the
serial publisher integrates and pushes main.

## Selected master containers in v03

The supplemental strict audit found an unused original packed scar mask was dropped
when Blender saved the initial v03 master containers. Those containers are retained at
`v03/models`; they are not selected for handoff. `preserve_packed.py` writes fresh
`v03/models-packed-v2` copies with the exact original packed bytes and byte-identical
tested GLB exports. `packed-master-02-jobs.json` reopens fresh `reopen-packed` copies
and repeats every geometry/attachment/map/source audit. The seal places these
selected masters at `models/`. The original failed audit is retained.

The reconstruction recipe now retains original images with a fake user and packs only unpacked images, so a fresh author run
keeps the original image bytes directly. This repair changes master containers,
not the exported models imported, rendered and timed in the v03 runtime.

## Camera validation

Final world captures/timings use the `views-v02` / `cost-v02` evidence paths.
Ground support is sampled after ensuring that view's chunks, using the native
cell-top height as a reference and a 4 m vertical search reach. This is an
inspection query allowance, not a changed surface or player height. Missing
rendered support fails an assertion; it is never replaced with a guessed height.
The first world-view attempts produced blank images from non-finite camera
coordinates and are retained as rejected evidence. `present.py` also checks
actual pixel variation below the captions before making the review sheets.

Final studio images use a symmetric camera at `(0, 6.5, 24)` aimed at
`(0, 3.5, 0)` with FOV 52, keeping both models at equal viewing distance.
The first asymmetric-camera images are retained but are not the selected sheets.

The Blender exporter reports multiple image nodes sharing a sampler. The retained
`material-bindings.json` checks all 19 actual exports: material properties, decoded
image bindings, sampler settings and triangle totals per material remain equal.
Blender material names/order may change. The warning is retained, as are existing
B1/C4 ObjectDB exit warnings and Compatibility SSAO warnings. No diagnostic is
suppressed.
