# ART-07D3 fine pieces and complete coverings

Seven existing shapes; twelve direct-modelled Blender exports, with five exact
D1 coarse parents copied read-only for the join review. Source work only, in the
isolated `codex/art07-d3` branch. No production game, tuning or save edit.
The frozen game/data/simulation revision is
`0f35e87c6a23e3197bec968fa4443c8e134317b3`.

| Shape | Godot X / Y / Z metres | Registry footprint | Cost |
| --- | --- | --- | ---: |
| half_cube | .5 / .5 / .5 | one volume | 1 |
| half_wall | .5 / .5 / .125 | one vertical face | 1 |
| half_pillar | .15 / .5 / .15 | one vertical edge | 1 |
| half_beam | .5 / .2 / .2 | one horizontal edge | 1 |
| half_slab | .5 / .125 / .5 | one horizontal face | 1 |
| light_panel | 1 / 1 / .16 | four vertical faces | 1 |
| glazed_window | 1 / 1 / .16 | four vertical faces | 2 |

Every origin is the native pose centre; identity object transforms. Coordinates
map Blender `(x,y,z)` to Godot `(x,z,-y)` once through glTF Y-up. Fine pieces
use the ordinary half-metre registry, including odd addresses. Fine mode selects
the coarse parent and toggles G, as the actual catalogue requires.

Fine timber variants have closed, backed 4 mm wide / 3 mm deep joints; their
solid companions have only an inward 1.5 mm arris. Timber variants apply to wood,
pine, bog oak, ash and resinheart; mineral and metal use the solid companions.
UV coordinates are measured in metres, with the D1 quarter-metre board rhythm.
`settings.json` documents every art control. No game tuning is introduced.

Both coverings include one continuous closed frame and a complete closed infill.
Window frame/muntin widths are the native 75 / 26 mm; panel battens are 45 mm.
The 9 mm seating rebate and small backed frame joints are inside those widths.
Muntins are unioned into the frame. The infill is the existing 38.4 mm thick;
its 60.8 mm inset from the unchanged .16 m body is intentional. This is a fixed
pane; there is no hinge, opening state, extra frame recipe or additional cost.
Native `PieceMesh.collision_for` remains the sole gameplay collider.

The adapter preserves surface 0 (infill) and surface 1 (frame) so existing native
family/role materials apply to the actual imported geometry in previews and play.
All 85 legal combinations and all 48 illegal combinations retain their rules.
Two packed 128 x 256 sRGB inspection images supply the Blender timber/mineral
previews. They are provisional; the Godot review uses the existing family
materials (weave, bark, planks, sheets and smoky depth-prepass glazing). No normal,
ORM or emission texture is added. Ordinary building pieces have no magical scar,
pulse or wind: real recessed joinery here is craft detail, not leyline damage.

Each asset uses the same bounded mesh at near/middle/far. No arbitrary triangle
budget or LOD ratio is selected. Two-sided stills, camera orbit, pause checks
and separate renderer benchmarks document the source candidate's current cost.
Only the glass is transparent. Actual whole-world overdraw, shadow-pass cost and
lower-spec performance remain separate integration questions.

## Reproduce in a fresh D3 version

The existing local depot tools are recorded in PROCESS.md. No install/download.
From this worker checkout:

```powershell
$d3Py='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $d3Py -B tools/wroughtwild-art07/d3/prepare.py --depot C:/Users/Matty/Dev/project-wroughtwild --output build/art07/d3/NEW
& tools/wroughtwild-art07/d3/build-native.ps1 -Depot C:/Users/Matty/Dev/project-wroughtwild -Revision 0f35e87c6a23e3197bec968fa4443c8e134317b3 -Output "$PWD/build/art07/d3/NEW-native"
```

`prepare.py` verifies the entire published D1 handoff and original source hashes.
`build.py` runs in Blender with `--background --threads 8 --python-exit-code 1
--python SCRIPT -- SNAPSHOT FRESH_MODELS`. It produces the packed editable master,
GLBs, exact geometry report and actual material/clay renders. `reopen.py` closes
the authoring process, opens that master in another process, checks packed images,
renders six angles in material/clay and imports every export independently.

```powershell
& $d3Py -B tools/wroughtwild-art07/d3/install-review.py --snapshot build/art07/d3/NEW/snapshot --models build/art07/d3/NEW/models --native build/art07/d3/NEW-native
& $d3Py -B tools/wroughtwild-art07/d3/make-jobs.py --build build/art07/d3/NEW --models build/art07/d3/NEW/models
& tools/wroughtwild-art07/d3/run-batch.ps1 -Jobs @('build/art07/d3/NEW/jobs/import.json','build/art07/d3/NEW/jobs/d3-check.json','build/art07/d3/NEW/jobs/d3-restart.json')
```

Jobs are explicit executable/argument arrays with isolated APPDATA, PID, timing,
exit status and full logs. `run-batch.ps1 -WaitSeconds 45` may wait briefly for
the cooperative art mutex; a busy slot or unrelated Blender/Godot/TRELLIS process
defers work. No foreign process is stopped. Generation/capture/benchmark jobs
are separate, and each rendered benchmark holds the slot for its entire run.

The D3 tests use fixed inspection stock and ordinary paid placement for all legal
pairings on both wall/beam axes, duplicate refusal, current family restrictions,
imported sizes, native poses, two-sided frame/infill ray coverage, coarse/fine
contacts, real player-sized capsule sweeps, shelter opening controls and a
separate-process ownership restore. Existing kit transaction/restart, home,
placement, material, save and native rule tests remain unchanged. Scripted stock
and posed fixtures are not a first-hour economy or human comfort test.

`package.py` hashes the source, runtime assets, copied native review, recipes and
evidence before import. `verify-handoff.py --package PACKAGE --output FRESH_COPY`
rehashes every file and writes fresh import/check/restart/render/reopen jobs.
Run those jobs, then verify the immutable package and original inputs again.
The standalone launcher copies before import and uses the copy's own APPDATA;
`-Visible` opens the gallery, `-Renderer gl_compatibility` selects Compatibility.
Left/right arrows orbit, N switches clay/material, Escape exits. Captured motion
is camera movement around static models, not asset animation.

## Lineage and limits

The selected `03-building-family.png` board supplies style intent, not dimensions.
D1 supplies primitive/UV/topology, process, packed-source and review patterns.
Task-local derivatives preserve D1 sources and handoffs unchanged. New organic
sources are unnecessary for lattice solids and frames; no imagegen/TRELLIS ran.
The receipt records actual geometry, checks, costs, package hashes and shortcomings.
The existing native wall-end trim can visibly double up over integral frames;
the source-frame views omit that separate trim while the native assembly keeps
it. Family patterns remain regular and coarse, and Compatibility is brighter.
The isolated source showcase is not a completed furnished house.

The full placement fixture also reproduces one Godot headless dummy-storage
`material_get_instance_shader_parameters` diagnostic with native primitive
meshes. Full logs are retained. The job runner classifies only that exact single
diagnostic, only in explicitly selected headless D3 checks, with exit zero and
all assertions still required to pass. Rendered material/shader errors are never
accepted. `diagnose-native.py` prepares a disposable native-form control.

At six rotated negative-coordinate frame samples, an exact triangle-edge ray
miss requires all four 10-micrometre neighbouring rays to hit. Reopen still
requires closed welded topology. `shelf-control.py` separately proves that the
original rejected 4 mm shelf slit fails all four of these rays while the repaired
rim passes; this retry cannot conceal that defect.

Final material-source integration, complete cottage/landscape composition, roofs,
mechanisms and ordinary-world adoption remain separate. Human visual acceptance
cannot be inferred from passing checks.
