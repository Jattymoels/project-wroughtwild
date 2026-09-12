# ART-07E1 — Workbench and mason's yard

E1 owns only two station source candidates and this copied-game review. D1's
published wall/slab geometry and D4/D5's unchanged textures are consumed after
full package verification. No ordinary game, simulation, tuning, save, shared
catalogue or other slice is edited. D-013/D-017/D-021 retain art, body and crafting
contracts. Final appearance and normal-world adoption need their later reviews.

## Reproduce

Worktree: `C:/Users/Matty/Dev/project-wroughtwild/build/art07/e1/worktree`, branch
`codex/art07-e1`. The game/data/native baseline is published main
`bbcb3a7dfd235e8f803141ccb57c38e03d6c1708`. Local tools are read from the canonical
depot at `C:/Users/Matty/Dev/project-wroughtwild`. No download/install is needed.

Existing Python:
`C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Blender: `<depot>/build/blender-tool/blender-4.5.9-windows-x64/blender.exe`.
Godot: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe`.

From this worktree, use fresh output directories. The delivered versions and
exact logs are identified by the E1 receipt. `$python`, `$blender` and `$godot`
below refer to those installed executables; `$build` is a fresh absolute path
under this worktree's `build/art07/e1/`.

```powershell
& $python -B tools/wroughtwild-art07/e1/inputs.py "$build/inputs"
& tools/wroughtwild-art07/e1/build-native.ps1 -Revision bbcb3a7dfd235e8f803141ccb57c38e03d6c1708 -Depot C:/Users/Matty/Dev/project-wroughtwild -Output "$build/native"
& tools/wroughtwild-art07/e1/gpu-slot.ps1 -Program $blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/e1/blender_stations.py','--',"$build/inputs/textures","$build/models/source") -Log "$build/model.log"
& tools/wroughtwild-art07/e1/gpu-slot.ps1 -Program $blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/e1/blender_stations.py','--','--reopen',"$build/models/source/e1_stations.blend","$build/reopen") -Log "$build/reopen.log"
& $python -B tools/wroughtwild-art07/e1/prepare_game.py "$build/review" "$build/models" "$build/native" "$build/inputs"
& tools/wroughtwild-art07/e1/gpu-slot.ps1 -Program $godot -JobArguments @('--headless','--path',"$build/review/game",'--editor','--import') -Log "$build/import.log"
& $python -B tools/wroughtwild-art07/e1/configure_imports.py "$build/review/game"
# Repeat import with a fresh log after explicit 3D texture settings.
& tools/wroughtwild-art07/e1/render_checks.ps1 -Game "$build/review/game" -Logs "$build/render-final-logs"
& tools/wroughtwild-art07/e1/regressions.ps1 -Game "$build/review/game" -Logs "$build/regression-logs"
& $python -B tools/wroughtwild-art07/e1/native_checks.py "$build/native-tests"
# Benchmark only after compilation, generation, captures and other art jobs end.
& tools/wroughtwild-art07/e1/render_checks.ps1 -Game "$build/review/game" -Logs "$build/benchmark-logs" -BenchmarksOnly
```

`blender_stations.py -- --original <fresh-output>` inspects the original models.
The modelling, native build, GPU guard, texture import and fresh-copy utilities
are bounded derivatives of published E2, with D1's two-shape adapter copied into
the disposable review. Original tools/handoffs remain read-only.

Selected geometry is v03, independently reopened in `v03/reopen-v02` after
correcting the inspector's removal of hidden LOD collections. Earlier outputs
remain preserved; only the final independent counts are accepted. Seal and
validate the selected delivery from this worktree with:

```powershell
& $python -B tools/wroughtwild-art07/e1/audit.py build/art07/e1/v03
& $python -B tools/wroughtwild-art07/e1/package.py build/art07/e1/v03 build/art07/e1/v03/e1-handoff-v02
& $python -B tools/wroughtwild-art07/e1/fresh_copy.py build/art07/e1/v03/e1-handoff-v02 build/art07/e1/f02
& tools/wroughtwild-art07/e1/fresh_validate.ps1 -Fresh "$PWD/build/art07/e1/f02"
& $python -B tools/wroughtwild-art07/e1/verify_fresh.py build/art07/e1/v03/e1-handoff-v02 build/art07/e1/f02
```

`audit.py`, `package.py` and `evidence.py` describe this selected delivery's
v01 input/native and v02 core-test provenance explicitly. For an independently
reconstructed build, supply equivalent fresh provenance roots when running
those final assembly scripts. They are delivery recipes, not a general asset
framework. A clone contains recipes and curated evidence; ignored handoffs,
masters and tool binaries must be transferred or reconstructed separately.

## Appearance and physical contracts

Both assets are direct Blender mechanisms. No organic host, ImageGen input,
TRELLIS job, cutout or magical scar is required. The selected station board
guides pegged supports, thick wood workface, contained clamp, stone bed and
attached tool rest. Real incisions/chips depict ordinary tool wear. No emission,
light, extra recipe cost, resource pile ownership or automatic work is added.

The export is metres: Blender `(x,y,z)` maps once to Godot `(x,z,-y)`. Front is
Blender -Y / Godot +Z, matching existing completion mounts. Root origins are at
the floor centre. All details remain inside `[-.48,.48]` horizontally and
`[0,2]` vertically, at every yaw. The native 0.96 × 2 × 0.96 m body is unchanged,
including air above the low workface. Fine grid placement offsets a full station;
it does not halve the station. Clamp/tools remain static fixture components.

Bench working surface is 1.04 m; the yard bed is .92 m with a dressing stone
reaching 1.085 m. Existing completion mounts remain at 1.06/1.10 m. Frame members,
pegs and optional near-view chips are separate editable objects. Near/middle/far
candidates are authored explicitly; production distance policy is deferred.

D4 Wood face uses metric U=.5 m and V=2 m along each member; End uses .5² m.
Per-member phases prevent aligned grain. D5 Stone maps use one measured interior
patch U=.12–.28/V=.40–.55 so an individual block never carries miniature courses.
Fixed bed fieldstone uses a small edge patch. Original map bytes are unchanged.
Albedo is sRGB; tangent +Y normal and ORM are linear; ORM G is roughness.
Twelve maps are shared across instances/levels; the runtime adapter avoids
retaining distinct material objects for each station. Dust and chisel finishes
are flat authored materials. Chisels introduce no extra iron input or gate.

`stations.json` documents every exposed source control. Source geometry uses
millimetre-scale bevels, 9 mm tool cuts and finite hand-positioned components.
These are art measurements, not new gameplay tuning. No universal performance
budget or automatic LOD switch is inferred from this isolated benchmark.

## Review and limits

The first two stations cost the original 18 wood + six fieldstone, including
the frame made at the actual bench. Crafting compares the real panel result to
an independent native oracle. The additional 16 corner kits and wall stock are
explicit inspection grants; their placement still pays natively. Actual floor
rays, catalogue selection, click/E dispatch, all four yaws and both grid anchors
check visible previews, body fit, one-owner success and retained-kit refusal.
Existing obstruction tests independently reject genuine wall/ceiling overlap.

Save tests retain every field and exact station identity. Explicit fixture node
names avoid Godot's known sanitization of generated `@` names. Serialized lattice
records are compared exactly after the same JSON conversion, because JSON
numbers decode as floats while live cell coordinates use integers. Assertions
are not removed. Pausing freezes the existing completion tween and native state;
reopening/refreshing does not replay work. Fresh-process E remains usable.

The review has an authored ground and fixed inspection stock; it is not a new
world, paid gathering journey, campaign playtest or owner save. Actual geometry
is cleaner and more regular than the weathered concept; D4 grain is conspicuously
periodic in some close views, and cut wear is deliberately bounded. There is no
claim of final owner acceptance or large-world/lower-spec performance approval.

The sealed handoff's `Launch-review.ps1 -Visible` verifies every hash, copies
the review to a unique temporary folder, imports and opens it with isolated
APPDATA. `-Renderer gl_compatibility` selects the alternate renderer. Controls
1/2 select bench/yard; Escape quits. Automated `--check`, `--restore`,
`--capture` and `--benchmark` modes are separate. Benchmarks record real process
frame intervals and whole-scene counters, not GPU timestamps.
The four rows compare original station assets, then near/middle/far candidates,
with 18 stations and the same paid corner lattice. All levels/maps are loaded
before measurement, so the memory counter cannot isolate their incremental cost.
