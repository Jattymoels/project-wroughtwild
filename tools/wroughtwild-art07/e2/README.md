# ART-07E2 — two appearances, one forge

Source candidate for `forge_basic` and `forge_improved` only. This owns no game,
sim, tuning, queue or catalogue change. The deliverable is an editable Blender
master, six runtime candidates and a copied **current** game that proves their
fit and state mapping. Ordinary-world adoption and owner visual acceptance are
separate. D-013/D-030 set the appearance; D-017/D-026/D-031 retain the contracts.

## Inputs and reproduction

Run from the isolated `codex/art07-e2` worktree. The inspected published base is
`0f35e87c6a23e3197bec968fa4443c8e134317b3`. The canonical tool depot remains
`C:/Users/Matty/Dev/project-wroughtwild`; the worker is
`C:/Users/Matty/Dev/project-wroughtwild/build/art07/e2/worktree`.

`inputs.py` checks all 290 D5 and 78 D6 package files and their published ancestry
before copying nine unchanged maps. Package paths and manifest hashes are pinned
in that script and recorded in `provenance.json`. It also hashes the original
forge exports, augmentation inlay, relevant source/tuning, concept and tools.
The existing forge GLBs were independently imported and rendered first. D6's
local build/slot/native-check recipes are minimally adapted here; originals are
read-only. D5/D6 geometry proxies are not used as station bodies.

No organic component needs generation: PROCESS explicitly calls for direct
Blender modelling of mechanisms. No ImageGen/TRELLIS job, input cutout, new model,
package or service is claimed. The existing Windows TRELLIS v0.6.0 installation
and pinned `ilintar/trellis2-gguf` revision
`a57397bd3d351599d9729fc144b3f87c3f87d65b` remain unchanged.

Existing Python executable:
`C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Blender: `<depot>/build/blender-tool/blender-4.5.9-windows-x64/blender.exe`.
Godot: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe`.

Use fresh directories for each invocation. The receipt pins the delivered
versions; the following command sequence shows the actual argument contracts:

```powershell
& $python -B tools/wroughtwild-art07/e2/inputs.py build/art07/e2/v01/inputs
& tools/wroughtwild-art07/e2/build-native.ps1 -Depot C:/Users/Matty/Dev/project-wroughtwild -Revision 0f35e87c6a23e3197bec968fa4443c8e134317b3 -Output <absolute-fresh-native>
& tools/wroughtwild-art07/e2/queued-job.ps1 -Program $blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/e2/blender_forge.py','--',<textures>,<fresh-source>) -Log <fresh-log>
& tools/wroughtwild-art07/e2/queued-job.ps1 -Program $blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/e2/blender_forge.py','--','--reopen',<packed-master>,<fresh-reopen>) -Log <fresh-log>
& $python -B tools/wroughtwild-art07/e2/prepare_game.py <fresh-review> <source-version> <native> <inputs>
# Guarded Godot --headless --editor --import --path <review/game>, then:
& $python -B tools/wroughtwild-art07/e2/configure_imports.py <review/game>
# Reimport after the preceding import has exited, then:
& tools/wroughtwild-art07/e2/regressions.ps1 -Game <review/game> -Logs <fresh-logs>
& tools/wroughtwild-art07/e2/render_checks.ps1 -Game <review/game> -Logs <fresh-render-logs>
& tools/wroughtwild-art07/e2/render_checks.ps1 -Game <review/game> -Logs <fresh-timing-logs> -BenchmarksOnly
```

`native_checks.py <fresh-directory>` runs unchanged strict world/core/contraption
tests. `--contraptions-only` repeats just the focused 602-check suite. The
regression wrapper has `-From <job>` to continue after a diagnosed harness failure.
The LF flow must start with bootstrap, then Blue, Green, heat and workshop;
it cannot consume a nonexistent predecessor save. Audio lifetime checks use real
time because an uncapped fixed-fps headless clock outruns the audio mixer.

## Geometry and surfaces

Blender uses metres, floor pivot `(0,0,0)`, applied identity scale and **front -Y**.
Export `(x,y,z)` becomes Godot `(x,z,-y)`, so the workface remains **Godot +Z**.
That follows the existing feedback mount; do not apply a second conversion.
Both appearances reuse the exact Common collection and geometry hash. Improved
adds iron cheeks, collar, straps and a refined plate. No duplicate kit exists.

Native body remains **.96 × 2 × .96 m**, centre `(0,1,0)`. Basic visible bounds
are .916 × 1.960 × .905 m; improved .919 × 1.960 × .9085 m (Godot XYZ).
They fit all four yaws. The cowl has front and rear supports; the flue is open
under a pegged rain cap. The front working plate contains the original
`(0,.94,.35)` feedback mount. Feeder connection is still the **world-axis centre
at height .85 m**, with the existing 8 m range and support/obstruction checks.
No directional socket, collision, connection body or footprint is introduced.

The left jamb has a real jagged cut: **.038 m wide/deep**, with its light face
.032 m behind the original skin. Four mesh rays measure the incision floor at
.038 m on every detail level. Material-off/clay renders establish actual depth.
The new cut replaces the older forge-only decorative inlay in the isolated
mesh dispatch; other stations' augmentation remains untouched.

| Tier | Near | Middle | Far | Surfaces |
| --- | ---: | ---: | ---: | ---: |
| Basic | 6,830 | 4,470 | 4,050 | 5 |
| Improved | 7,902 | 5,350 | 4,642 | 5 |

Counts are actual triangles after export/import, not polygons. Simplification
reduces clinker facets and peened fasteners; the opening, plinth, supports,
collars and fracture remain. The copied native scene uses near geometry.
Keys 1/2/3 and 4.4/10/24 m captures inspect explicit alternatives; this slice
does **not** install a distance policy or claim a numeric whole-world budget.

Nine images are packed into the editable master: D5 stone-edge 512² and charcoal
1024², D6 iron 1024², each albedo/normal/ORM. All source bytes are unchanged.
Albedo is sRGB, OpenGL +Y normals/ORM linear; roughness reads G. Iron uses metallic
1, soot .3, stone/clinker 0; emission is separate. Godot shares external maps and
enables explicit mipmapped anisotropic sampling. Conservative RGBA8 source-map
memory including mips is **36 MiB**. Engine counters include other game assets,
shadows, render targets and review geometry, so are not this map-only estimate.

Each stone maps one D5 block interior to avoid mini masonry courses on the jamb.
This deliberately varies texel density with the stone's dimensions; no map is
repainted. Iron uses .5 m metric UVs. `appearance.json` explains every tint,
normal, light-intensity and spatial-wave control. `forge.json` records geometry
dimensions and scar controls; coordinates in the Blender recipe are measured
construction, not gameplay tuning. No recipe or fuel number changes.

## State authority and review controls

The copied game differs from frozen main at only two existing source sites:
forge mesh dispatch in `station_look.gd`, and mounting the read-only view in
`station_site.gd`. Its project setting also selects a separate E2 user directory.
All simulation/data and other production scripts are intact.
The view creates no body, light, saved field, resource, work tick or inventory.

- Cold: no emission from the new scar/clinker. Existing decorative HearthLight
  remains at its original **1.2 energy / 3.5 m range**, so a cold chamber can
  still look warm. That is explicitly not stored fuel or active forging.
- Manual: only the original successful local `CraftWorkResponse` activates
  emission. Its original .38 s lifetime and three small work flecks stay intact.
  Failure, remote knowledge, browsing and load cannot replay completion.
- Feeder: reserved native firing sets intensity .8 and phase `cycle_seconds /
  feeder_cycle_seconds`. Pause/blockage/trial/distance uses .35 held intensity
  with the same native phase. A scene pause freezes it. There is no shader TIME.
  Ordinary fuel and paid Red heat remain separate from mechanical drive.

The review uses supplied stock/skill and deterministic placement/tick targets;
manual recipes, upgrade, final placement, support, obstruction, escrow, save and
collection are real current APIs. Existing regressions additionally exercise
actual controls and generated V5/V6/LF worlds. This is not owner playtesting.
The review camera hides the player render to avoid disembodied first-person
hands; the actual collision and interaction player stays present.

`launch-review.ps1` verifies the package, copies it to a new temporary directory,
imports that copy and opens it under its own APPDATA. C supplies one inspection
manual craft; W winds, F starts, P pauses/resumes, X cancels, K collects, 1/2/3
select candidate detail, Escape quits. Native feeder pages remain available
through the scene's actual inspection calls. No user save is opened. The shader
and other station resources reset on load while exact native ownership returns.

All art jobs use the cooperative mutex `Local\Wroughtwild-Art07-GPU` and inspect
existing render processes. Headless CPU checks need no GPU slot. Benchmarks
refuse all other Godot/Blender/TRELLIS processes. The task stops only its own
identified failed child; no owner playtest is interrupted. Blender renders use
eight-thread CPU Cycles inside the guarded art slot, not a claimed GPU bake.

## Packaging and limits

`evidence.py` preserves selected raw stills unchanged and encodes 60-frame
1200×675 WebP previews at 100 ms/frame for remote inspection. First 48 frames
advance real native work by 1/24 s each; the last 12 freeze explicit pause.
No interpolated geometry or source illustration substitutes for these frames.
Full PNG frames and all 24 reopened material/clay views remain in local output.

`package.py <source> <review> <curated-evidence> <fresh-handoff>` seals packed
source, runtime alternatives, native review, recipes and evidence.
`fresh_copy.py <handoff> <fresh-copy>` rehashes every delivered byte before import.
The final receipt supplies exact canonical paths, hashes, source checks and
commands. Git holds only task recipes, selected evidence and the receipt;
masters, runtime candidates, frozen game/DLL, imports, logs and saves remain
ignored local handoff material. A clone needs that package or reconstruction.

Remaining limits: regular masonry and repeated hammer finish; a narrow workface
forced by the existing body; no added tools, flames, smoke or working door; a
single unbranched fracture; the original decorative light can soften the cold/
active distinction and reveal bright seams between rear blocks. Compatibility
and Forward+ differ in brightness. The review
contains one primary forge/feeder plus eight distant corner fixtures, not a
composed workshop or large factory. Explicit LOD switches, dense-scene texture
sharing, lower-spec hardware and owner visual acceptance remain open.
