# ART-07D2 roofs, door and metal spans

Seven dimensioned Blender source modules with a disposable current-native Godot
review. Source recipes adapt the D1 closed-solid helpers, process logging,
inspection and packaging conventions; all derivatives are local to D2. D1's
immutable ten GLBs supply context only. No shared helper, game, tuning or save
implementation is edited.

The frozen game/data/simulation revision is
`0f35e87c6a23e3197bec968fa4443c8e134317b3`. The D1 prerequisite is verified by
all 1,597 file hashes before consumption; its manifest is
`a3e92f9692e05eae547290cd6520242f91dfbda31d9236eb6d12842f0453b85a`.
Absolute paths and actual binary/input hashes are in `prerequisites.json`.

## Native geometry and ownership

| Shape | X/Y/Z metres | Element; placement cost | Contract |
| --- | --- | --- | --- |
| codex_roof_slope | 1 / .5 / 1 | oriented volume; 1 | High edge +Z |
| codex_roof_hip | 1 / .5 / 1 | oriented volume; 1 | High corner +X/+Z; min(X,Z) top |
| codex_roof_valley | 1 / .5 / 1 | oriented volume; 1 | Low corner -X/-Z; max(X,Z) top |
| door | 1 / 2 / .25 address | oriented wall face; 2 | Actual leaf .94 / 1.94 / .125 |
| roof_wedge | 1 / 1 / 1 | oriented volume; 1 | Full 45-degree masonry wedge |
| girder | 2 / .4 / .3 | two-cell horizontal edge; 2 | Solid box section |
| arch | 1 / 1 / .25 | wall face; 2 | Twelve native visual strips; existing three colliders |

Covering roofs require `covering` and `stonecut_blocks`; the masonry wedge
requires `masonry` and the same unlock. Doors require `joinery`, girders `metal`,
arches `malleable` (bronze/silver only). Every current material gate is checked.
Full native registry footprints remain reserved, including empty roof space.
Actual placement pays the source item once; duplicate refusal preserves stock.
Existing fixture-kit transaction checks cover retained failed kits and one
usable object on success. Inspection grants are explicit, not gathering evidence.

Every exported object is centred on its native mesh pose in metres. Authoring
converts Godot `(x,y,z)` to Blender `(x,-z,y)`; glTF Y-up performs the inverse
exactly once. `GridPlacement.piece_pose` retains the native half-roof floor
offset. D1 floor/wall skins intentionally intersect along their shared lattice
boundaries. Added detail never changes that policy or introduces support rules.

The door export is a centred single leaf, consumed beneath the existing -X
hinge at -0.5 m with a +0.5 m leaf offset. Native opening is a -90-degree state
assignment; both wall axes and hinge directions remain. Its collider remains a
direct body child and follows the same transform. Recessed rail edges, blind
hinge-fastener sockets and finger pull fit inside the leaf. The native surrounding
wall/corner frame is contextual D1 geometry, not another door collider or kit.
The packed Blender REVIEW collection includes `Door hinge - native two-state
control`: toggle its `open` property to switch the same two poses. The runtime
leaf export remains centred; the game already owns this pivot and state.

The arch deliberately retains the stepped visual opening. Its existing three
box colliders are simpler than that opening: a visual portion above the crown
does not collide. D2 measures the visual against the original mesh and separately
checks every native collider, rather than changing the contract or silently
substituting a smooth arch. It is not a new stone form. Similarly, the girder has
a shallow reinforced web; it cannot use the concept board's deep I section while
retaining the native solid collision honestly.

## Surface treatment and cost

`settings.json` explains all authored controls. Covering relief recedes at most
6 mm vertically; all four outer boundaries and the shared roof diagonal retain
the native planes. Six physical courses suggest overlapping covering. They have
a closed backing, no overhangs and no decorative drainage lip. The measured
horizontal-ray allowance is 14 mm (6 mm relief projects to 12 mm at a 0.5 slope);
other detailed surfaces use 10 mm. Exact outer dimensions are checked separately.
The 25 mm border is a seam preservation control, not collision padding.

Ordinary construction is unlit. These are construction joints, not magical
scars; no emission, source state, free energy or pulse was introduced. Five
packed 256-square sRGB provisional colour maps support Blender inspection.
No normal/ORM/emission data maps are used. The Godot adapter retains the existing
native family/role material, shared by placed pieces, ghost and catalogue.
Final material production is separate; D5/D6 proxies are not geometry inputs.

One mesh/surface per module is used at near, middle and far distances. Actual
counts, GLB sizes and renderer residency are recorded with the receipt. No
arbitrary LOD budget or claim of whole-world/lower-spec readiness is made.

## Reproduction

Run from the D2 worktree. Use fresh version paths; scripts refuse overwrites.

```powershell
$d2Py='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $d2Py -B tools/wroughtwild-art07/d2/prepare.py --depot C:/Users/Matty/Dev/project-wroughtwild --output build/art07/d2/NEW
& tools/wroughtwild-art07/d2/build-native.ps1 -Depot C:/Users/Matty/Dev/project-wroughtwild -Revision 0f35e87c6a23e3197bec968fa4443c8e134317b3 -Output "$PWD/build/art07/d2/NEW-native"
```

The existing Blender binary takes `--background --threads 8 --python-exit-code 1
--python tools/wroughtwild-art07/d2/build.py -- ABSOLUTE_SNAPSHOT FRESH_MODELS`.
Run through `run-job.ps1` with a JSON argument array, isolated paths and `gpu:true`
to claim `Local\Wroughtwild-Art07-GPU`; this also protects other workers'
benchmarks during CPU renders. The process guard refuses existing art/playtest
jobs. An explicitly enabled `allow_headless_peers` admits only positively
identified Godot processes with `--headless`, records their commands and applies
only to correctness/capture jobs. Benchmarks reject all peers and compiler work.
No foreign process is stopped. Logs retain PID, arguments, duration and exit.
The known offline Windows root-certificate-store error is retained in logs but
is not treated as an art failure; all other engine/script errors still fail.

```powershell
& $d2Py -B tools/wroughtwild-art07/d2/install-review.py --snapshot build/art07/d2/NEW/snapshot --models build/art07/d2/NEW/models --native build/art07/d2/NEW-native
& $d2Py -B tools/wroughtwild-art07/d2/make-jobs.py --build build/art07/d2/NEW --models build/art07/d2/NEW/models
& tools/wroughtwild-art07/d2/run-batch.ps1 -Jobs @('build/art07/d2/NEW/jobs/import.json','build/art07/d2/NEW/jobs/d2-check.json','build/art07/d2/NEW/jobs/d2-restart.json','build/art07/d2/NEW/jobs/reopen.json')
```

Run current regression jobs and both renderer captures, then the benchmarks in
separate processes. `build-sim.ps1` compiles the frozen current suite with
`-std=c++17 -Wall -Wextra -Werror -O1` and runs it against matching tuning.
Existing tests are not edited. Source and DLL use the same frozen revision.

`reopen.py` opens the packed master in a new process, renders front/back/side/
three-quarter/top/underside in material and clay, and imports seven GLBs afresh.
It checks closed welded topology, no degenerate/nonfinite geometry, exact
bounds/counts and 528 actual roof-edge samples, then every matching roof/turn
pair along X and Z at native half-grid height offsets. Each legal seam has
eleven sample points. Zero-area eaves use a one-micrometre inward probe.

The native gallery uses paid D2 and D1 pieces with granted inspection stock.
Still views include all modules, a hipped room, valley/ceiling/corner contacts,
door closed/open, underside, shade and dusk. Motion records actual E state
changes and a slight camera move. Native doors have no opening tween. A pause
check preserves the held leaf transform. In an interactive review the geometry
is a posed study; automatic E evidence runs with `--capture`.

## Handoff

`package.py --build BUILD --models MODELS --inspection INSPECTION --native NATIVE --output FRESH`
packages the master, runtime files, isolated game/data, recipe and evidence, then
hashes every file before import. `verify-handoff.py --package PACKAGE --output
FRESH_COPY` validates those hashes and prepares import, placement, fresh-process
restart, both renderer capture and Blender reopen jobs. The canonical package
remains read-only. Verify its hashes again after all checks.

Git contains only D2 recipe/settings/checks, selected actual model evidence and
the D2 receipt. Generated masters, GLBs, native DLL, copied games, caches and
test saves remain local. Main integration/push belongs to the publisher. Owner
visual approval and ordinary-world adoption remain separate.
