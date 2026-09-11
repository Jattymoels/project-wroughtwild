# ART-07C2 — Glasswind and Shellcut

Scoped source candidates for `slate_outcrop`, `shellstone_outcrop` and
`upland_tussock`. Normal game/simulation/tuning are unchanged. The source package
contains a static composed review and a separate archived-current-game native
fixture. Technical checks do not grant owner visual acceptance or ordinary-world
adoption. B1 pine and B3 shelves are context, never replacement native bodies.

## Reconstruct from verified local inputs

Run in the isolated `codex/art07-c2` worktree. Existing tools are in the canonical
depot `C:/Users/Matty/Dev/project-wroughtwild`: Blender under
`build/blender-tool/blender-4.5.9-windows-x64/blender.exe`, TRELLIS and pinned
weights under `build/trellis-local/`. Godot is
`C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe`. Python/Pillow/NumPy:
`C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Do not install/download dependencies or overwrite earlier outputs.

1. `prerequisites.py OUTPUT/prerequisites.json` verifies all B1/B3/ART02 files
   and published ancestor commits. `inspect_source.py -- DEPOT OUTPUT/inspection`
   (Blender) inspects the original rock. Its raw/master lineage is retained.
2. `generate.ps1 -InputImage docs/art/leyline-studies/2026-09-09/art07/c2/shellstone-input-v01.png -Output OUTPUT/generation`
   verifies all ten pinned weights, takes the shared GPU mutex, runs Windows
   TRELLIS v0.6.0 at 1024/seed42/GPU0/retained BiRefNet cutout/PNG/eight threads,
   and records exact arguments, PID, timing, exit and provenance. The immutable
   PNG and exact built-in imagegen prompt are tracked. No board is a mesh input.
3. Blender `inspect_shell.py -- OUTPUT/generation/source.glb OUTPUT/raw-inspection`
   renders all sides before finishing. Blender `build.py -- OUTPUT/base-kit`
   builds the retained slate and deliberately rooted tussocks from the approved
   source. This intermediate contains rejected procedural shellstone for history.
   Blender `finish_shell.py -- OUTPUT/base-kit OUTPUT/generation/source.glb OUTPUT/kit`
   replaces every shellstone candidate with the inspected source, fitted inside
   the native envelope, capped at work/cut planes, with separate planar cut UVs.
4. Blender `audit.py -- OUTPUT/kit OUTPUT/audit.json` independently reopens the
   packed master and every GLB. Blender `render_master.py -- OUTPUT/kit/c2-master.blend OUTPUT/blender`
   creates material/clay/front/back/side/top/underside views. Use
   `--background --threads 8 --python-exit-code 1 --python SCRIPT -- ARGS`.
5. `prepare.py OUTPUT/kit OUTPUT/review` cooks shared texture files while checking
   every non-image buffer-view byte. `prepare_native.py OUTPUT/current` archives
   game/data at `f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9`, verifies no game/sim/data
   diff from B3's DLL compile revision, and checks the DLL hash before reuse.
   `install_native.py OUTPUT/current OUTPUT/review OUTPUT/native` installs the
   C2 adapter solely in the fresh game copy.
6. Import each project using Godot `--headless --editor --path PROJECT --import`.
   Run the 14 current suites with `run-current-checks.ps1 -Project GAME -Logs LOGS`.
   Run `res://c2/native_review.tscn` in three processes: normal flow, then
   `-- --restore-partial`, then `-- --restore-final`, using the same isolated
   APPDATA. Run `run-stage.ps1 -Project PROJECT -Logs LOGS -Stage Capture`, then
   `Motion`; `-Stage Native` uses the native GAME. After arranging a quiet window,
   run `benchmark-window.ps1 -Project PROJECT -Logs NEW_LOGS` separately; it holds
   the GPU slot across both renderer measurements and records the environment.
   It executes both Forward+ and Compatibility. Coordinate GPU windows and leave
   CPU jobs quiet for benchmarks. Never terminate another worker or playtest.
7. `encode.py OUTPUT/review OUTPUT/media OUTPUT/native/game` checks actual changed motion pixels
   and invariant paused frames before encoding. `package.py OUTPUT OUTPUT/handoff`
   assembles the selected named paths recorded in that script. For a new run,
   set its selected inputs explicitly; never reuse historical test results as new.
   `report_checks.py OUTPUT OUTPUT/check-summary.json` summarizes the two actual
   14-suite batches; `curate.py OUTPUT DOCS_EVIDENCE` selects original media and
   writes the measured geometry/texture report.
   `verify_package.py PACKAGE FRESH_COPY` hashes before copying and after copying.
   Reopen/import/test the fresh copy, then rehash the canonical package again.

The selected commands, own PIDs, elapsed seconds and exit codes are in the
package's job records. `run-job.ps1` uses isolated APPDATA/LOCALAPPDATA and
Blender resources, hidden subprocesses and a cooperative GPU guard. CPU-only
Cycles jobs do not request a GPU slot. No `--benchmark` job overlaps C2 generation,
capture, encoding or headless checks.

## Controls and boundaries

Static review: click/mouse look, WASD/QE flight, L day/shade/dusk, M inherited B3
scar light, Space pause, 0 automatic distance detail, 1/2/3 near/middle/far,
R overview, Escape release pointer. `launch-review.ps1 -Package PACKAGE -CopyTo NEW_COPY -Renderer forward_plus -Visible`
verifies/copies/imports before launch. Add `-Native` for the automated authored
work fixture. The launcher does not claim human playtesting.

`kit.json` explains art controls and exact dimensional/LOD values. Slate has
seven real bedding sheets; source-derived full/worked/last/recovered candidates
share its mineral family. Shellstone retains its generated embedded fossils and
its original UVs, with caps using the pale mineral palette. A second orientation
is deliberately bounded reuse, not a new fossil population. Tussocks have
240/110/45 rooted blades per detail level, three deterministic variations,
dry margins and green centres. Wind and inherited scar light use an explicit
pause-aware clock; ordinary quarry/vegetation surfaces have no ambient emission.

Native quarry boxes remain 2.0 × 0.58 × 1.15 m. Each original bed has 24 units,
four work presses per four-unit release, full at 24, worked at 20–8 and last at
4. A depleted bed leaves one non-colliding session-only flattened remnant, with
no resource/save owner; restart removes it as before. Work animation, shrinking,
heat/highlight, inventory, pickups and SaveManager remain native. Save restoration
refreshes the cut state through the existing visual-refresh callback.

The flat fixture exercises the real current capsule, approach gap and ray work
targets. Current generated-world regressions run with the adapter installed.
This is not a general arbitrary-slope fitter or a paid first-hour journey.
Inherited pine is distant decorative context because B4 documents an unresolved
canopy/body fit; no source body is enlarged. Runtime adoption belongs to the
later integration review. Source-derived repetition, softened fine fossils,
visible LOD changes and remaining source open edges are documented limitations.
