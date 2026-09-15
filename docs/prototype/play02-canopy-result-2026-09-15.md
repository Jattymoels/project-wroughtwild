# PLAY-02 — fuller active tree crowns

Common broadleaf and pine crowns now use the delivered R1 middle-detail model
in the ordinary game. Their fuller folded leaf surfaces give the exposed branches
more coherent foliage at player height. The forest smoke also restored two
missing C1 presentation dependencies encountered while loading nearby resources.

Worker: `D:/Wroughtwild/work/play02-canopies`, `codex/play02-canopies`, prepared
base `e1d5b8bf68592a4cd845b25bc88d4594ae9a645c`. This is a checked worker delivery
for coordinator integration. Main integration and remote push are not performed
by this worker. Owner standing approval applies; owner playtesting is deferred.

## Diagnosis and implementation

The existing A1 player-height image (`D:/project-wroughtwild-mainline-art-a1/build/a1/ordinary.png`)
shows sparse broadleaf foliage and conspicuous exposed limb ends. R1's retained
Forward+ source comparison (`D:/project-wroughtwild-art07-r1/build/art07-repairs/r1/v03/handoff/review/forward_plus-all-lods.jpg`)
and the source hierarchy provide applicable prior evidence.

The active wood/pine adapter unconditionally selected `a-lod2` even at close range.
All three source components (trunk, branchlets, foliage) are present. Leaves are
opaque and rendered double-sided; there is no alpha mask responsible for holes.
The original recipe keeps the same number of leaf attachments in each LOD but
reduces each LOD2 blade to a four-triangle diamond. LOD1 retains a fuller folded
surface with eight triangles per blade. The selected game views demonstrate the
result on ordinary generated broadleaf and pine resources, not newly scattered
trees. The source's broken limb ends remain intentional geometry.

`game/r1/settings.json: runtime_lod` changes from 2 to 1 and now drives the adapter.
It retains the packed scenes and parsed settings across trees. Selected runtime
GLBs preserve the complete source binary geometry, hierarchy and material data;
only embedded-image bindings use the existing, byte-checked tracked texture aliases.
[Asset provenance and triangle counts](../../game/r1/README.md) identify the selected
exports and retained editable masters. No master was edited or copied.

The first forest view also produced actual errors loading `game/c1/kit.json` and
`game/c1/surface.gdshader`. Both were absent from the adopted runtime. The exact
approved files were copied from
`D:/project-wroughtwild-art07-r8/build/art07-repairs/r8/v01/handoff-final/runtime/game/c1/`.
No C1 model, material tuning or gameplay rule was redesigned. The same forest
view then completed without script/shader errors.

Unchanged: resource IDs/counts/locations, native trunk bodies and targeting,
R1 lower-trunk fit and burial, work/stock, fall/stump behavior, finite depletion,
save schema, distant-canopy eligibility, generation, A1/A2 gameplay, PLAY-01's
shared resource-work budget, intentional dead/broken families and cave access.
Runtime dependencies remain inside tracked `game/` paths.

## Focused verification

The concrete risks were an unsuitable crown assembly at player height, missing
runtime dependencies, and a presentation change disturbing native tree use.
Forward+ was the only rendered backend. Private logs, harness, saves and captures
are retained in `D:/Wroughtwild/work/play02-canopies/build/play02/`.

- Reused A1's ordinary image and R1's delivered comparison/source evidence for the
  initial symptom; no new baseline/camera/seed/performance matrix.
- Hidden headless asset import: exit 0, **32.18 seconds**, no reported errors.
- Ordinary generated seed-77 player-height broadleaf/pine views: **12 checks,
  0 failures**, **44.63 seconds**, no script/shader errors after the C1 repair.
  `wood-corrected.png` and `pine-corrected.png` are the selected captures.
  Both camera eyes are 1.68 m above sampled rendered ground. Mouse mode was
  visible and the disposable window was asserted unfocusable.
- Headless native lifecycle: **58 checks, 0 failures**, **63.35 seconds**.
  One ordinary broadleaf and pine each retained trunk body/ray targeting, lower
  walking clearance, burial, partial chop/stock restoration, whole-crown lean/fall,
  exact final stock release, collision release, matching stump and persistent
  depletion after SaveManager restore. The distant-canopy submission stayed hidden.

The first rendered attempt took 42.47 seconds and reported the missing C1 files;
its `view.*.log` is retained and is not a clean pass. The first lifecycle attempt
(65.37 seconds) reported three harness failures: two exact float comparisons
against engine-rounded burial values, and a MultiMesh readback unsupported by
headless dummy rendering. `multimesh-probe.log` demonstrates a written zero-scale
transform reading back as identity. The corrected check uses approximate numeric
equality and the exact visibility transform submitted and retained by
`ResourceCanopies.update`. Gameplay assertions were preserved. The failed logs
remain alongside the final results; this was a focused correction, not a review restart.

The focused engine verification window ran from 09:24:51 to 09:33:33
Adelaide (8.7 minutes elapsed, including harness work and
diagnosis between runs). Import/view/lifecycle process time totalled 248 seconds,
plus the brief dummy-renderer diagnostic. No broad regression or benchmark ran.
No testing is left running. The disposable `game/override.cfg` is removed for
normal play; generated imports/caches and private evidence are not staged.

## Limits and next steps

The selected foliage is fuller, but broadleaf crowns still have blunt broken limb
ends and both families retain uneven natural branch gaps and dark undersides.
This preserves their delivered identity; owner feedback can guide later art polish.
LOD1 adds geometry (98,032 broadleaf / 130,597 pine source triangles, versus
65,232 / 69,637); hardware cost was not benchmarked or cleared. There is no new
per-frame LOD loop. Distant trees still use the existing separate broadleaf proxy;
its appearance and transition were not redesigned or exhaustively reviewed.

PLAY-03 significant underground lag remains unresolved; this does not change
legitimate caves/digging or claim a lag fix. PLAY-01 owner comfort and station/
campaign feedback remain deferred. Next production is the six approved replacement
mob rigs, one existing role per playable slice. Reclaimed Frontier remains future
work, and R9 remains stopped.

## Integration and normal-main playtest

Cherry-pick the worker commit returned with this result onto current main, then
make the ordinary non-force push under standing permission. Reuse this evidence;
main only needs its local import for the two new model files. Do not merge private
saves, captures, `.godot`, generated sidecars or `override.cfg`.

After integration, launch the normal game:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

Choose Continue or a fresh world. Inspect broadleaf trees near the opening and
pines in woodland at ordinary walking height, then partially chop one, save and
Continue, finish felling it and confirm it stays depleted after another Continue.
Existing world IDs and stock are retained. No preview launcher or special art flag
is required. To inspect the worker before integration, use the same command with
`--path 'D:/Wroughtwild/work/play02-canopies/game'`.
