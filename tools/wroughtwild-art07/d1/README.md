# ART-07D1 core lattice geometry

Ten direct-modelled Blender modules, with an isolated native-game review adapter.
This directory owns no gameplay implementation or material-family production.
The accepted D-017/D-018/D-021 lattice, trait restrictions, costs, footprints,
body shapes and schema-2 saves remain authoritative.

The source baseline is `56ce6bbe343012205690cf669491372958b80662` for both
game/data and the freshly compiled simulation. The canonical read-only tool
depot is `C:/Users/Matty/Dev/project-wroughtwild`. This worker is the separate
`codex/art07-d1` worktree under that depot's ignored `build/art07/d1/worktree`.

## Geometry contract

| ID | Godot X/Y/Z metres | Native element | Local visual/body centre | Cost |
| --- | --- | --- | --- | ---: |
| cube | 1 / 1 / 1 | volume | 0 / 0 / 0 | 2 |
| wall_panel | 1 / 1 / .25 | vertical face | 0 / 0 / 0 | 1 |
| pillar | .3 / 1 / .3 | vertical edge | 0 / 0 / 0 | 1 |
| beam | 1 / .4 / .4 | horizontal edge | 0 / 0 / 0 | 1 |
| floor_slab | 1 / .25 / 1 | horizontal face | 0 / 0 / 0 | 1 |
| stairs | 1 / 1 / 1 | oriented volume | 0 / 0 / 0 | 2 |
| codex_corner | 1 / 1 / 1 | oriented volume | 0 / 0 / 0 | 2 |
| codex_corner_floor | 1 / .25 / 1 | oriented horizontal face | 0 / 0 / 0 | 1 |
| foundation | 1 / .5 / 1 | volume | 0 / -.25 / 0 | 2 |
| dry_wall | 1 / .5 / .3 | vertical face | 0 / -.25 / 0 | 2 |

Every object origin is `(0,0,0)` in the native piece pose. The low-piece offset
is in its vertices, never a second placement offset. Metres map from Blender
`(x,y,z)` to Godot `(x,z,-y)` exactly once through glTF Y-up export. Stairs have
two half-metre treads, rising toward Godot +Z. Both corners retain the native
`x <= z` solid half at rotation zero and reserve the complete element footprint.
The triangle's acute mating edges remain sharp to preserve exact extents.

Closed solids have backed physical joins and no extra colliders. The fieldstone
backing/courses are boolean-unioned into one closed mesh. Texture-seam vertices
may split on glTF export; welding at 1 micrometre verifies the same closed shell.
Use native `PieceMesh.collision_for`; never add visual trimesh collision in play.
The detailed visual ray proxy exists only inside the isolated measurement test.

## Materials and controls

`settings.json` explains every authored number. No game tuning is introduced.
Small physical board joins are 8 mm wide and 6 mm deep; ordinary arrises are
3 mm. Fieldstone uses two courses, 14 mm nominal joints, irregular corner wear
and a cap recessed by up to 18 mm. These are unlit materials, not magical scars.
There is no source progress, pulse, energy reservoir or moving mechanism here.

Blender embeds two small provisional sRGB colour images. Their UVs are local
surface coordinates; no normal/ORM/energy texture is introduced. Native Godot
views use the unchanged existing `PieceLook` family and role materials, including
world-aligned timber and dark framing. Final texture/material breadth belongs to
the separate material slices. The 14 legal ordinary families remain legal for
the first eight shapes; only fieldstone is legal for the two low shapes.

One bounded mesh and one material surface per object are used at every distance.
The review measures near/middle/far costs rather than choosing an unapproved
triangle budget or arbitrary LOD ratios. Fine geometry and roofs are other slices.

## Reproduction

Use the installed Python/Blender/Godot/compiler paths recorded in PROCESS.md.
Do not reinstall packages. Run from this worktree, with a fresh version directory:

```powershell
$d1Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $d1Python -B tools/wroughtwild-art07/d1/prepare.py --depot C:/Users/Matty/Dev/project-wroughtwild --output build/art07/d1/NEW
& tools/wroughtwild-art07/d1/build-native.ps1 -Depot C:/Users/Matty/Dev/project-wroughtwild -Revision 56ce6bbe343012205690cf669491372958b80662 -Output "$PWD/build/art07/d1/NEW-native"
```

Run Blender with `--background --threads 8 --python-exit-code 1 --python
tools/wroughtwild-art07/d1/build.py -- SNAPSHOT FRESH_MODELS`. All paths should be
absolute in the recorded process arguments. `run-job.ps1` accepts a JSON job with
`executable`, `arguments`, `cwd`, fresh `output`, `gpu`, `timeout_seconds` and
optional isolated `appdata`. It records the process PID, arguments, times and
status, restores environment variables, and never stops unrelated processes.

```powershell
& $d1Python -B tools/wroughtwild-art07/d1/install-review.py --snapshot build/art07/d1/NEW/snapshot --models build/art07/d1/NEW/models --native build/art07/d1/NEW-native
& $d1Python -B tools/wroughtwild-art07/d1/make-jobs.py --build build/art07/d1/NEW --models build/art07/d1/NEW/models
& tools/wroughtwild-art07/d1/run-job.ps1 -Job build/art07/d1/NEW/jobs/import.json
& tools/wroughtwild-art07/d1/run-job.ps1 -Job build/art07/d1/NEW/jobs/d1-check.json
& tools/wroughtwild-art07/d1/run-job.ps1 -Job build/art07/d1/NEW/jobs/d1-restart.json
```

`install-review.py` changes only the copied game's mesh-selection branch. It
copies the ten assets, measurement/gallery scripts and frozen native DLL there.
The original PieceMesh bodies, payment, save code and current tests are untouched.
Run the listed current regression job specifications without weakening assertions.
`build-sim.ps1` compiles/runs the current native unit suite with `-Werror`.

Blender reopen is a separate process and produces 120 small actual mesh views:
front/back/side/three-quarter/top/underside in material and neutral modes. It also
fresh-imports each GLB and compares bounds, triangulated faces and welded topology.

Coordinate all heavy jobs with other workers. GPU captures and benchmarks take
`Local\Wroughtwild-Art07-GPU`; a busy slot or existing playtest refuses the job.
Keep CPU compilation/rendering clear of another worker's benchmark too. Run
Forward+ and Compatibility capture jobs first, then their benchmark jobs separately.
All gallery motion is camera orbit around static geometry, not an asset animation.
The gallery shows native automatic seam posts as well as the ten candidate meshes;
those existing posts are not additional D1 exports. Neutral mode includes them.
Review daylight uses the existing helper's 1.15 sun / .45 ambient energy; shade
sets sun to zero, and dusk uses .2 warm sun / .12 ambient to inspect dark contacts.
These are presentation-only controls. Ordinary materials have no emission or wind.

## Handoff and boundaries

The receipt records selected/rejected versions, exact checks, measured costs,
hashes, absolute paths and limitations. Generated GLBs, Blender masters, native
DLLs, copied games, logs and save fixtures stay in ignored D1 build versions.
Only recipes, curated actual evidence and this documentation belong in Git.
The immutable handoff must be hashed before import; use a new handoff copy for
Godot caches and test saves. Ordinary-world adoption and owner visual acceptance
remain separate from a successful technical review.

`package.py --build BUILD --models MODELS --inspection INSPECTION --output FRESH`
assembles the selected source, copied native review and raw evidence before hashing.
`verify-handoff.py --package PACKAGE --output FRESH_COPY` verifies every file first,
then prepares fresh import, placement, restart, both renderer capture and Blender
reopen job specifications in `FRESH_COPY/jobs`. Execute those with `run-batch.ps1`.
Run `verify-handoff.py --package PACKAGE` again afterward to prove the canonical
package stayed unchanged. The handoff launcher likewise copies before import.
