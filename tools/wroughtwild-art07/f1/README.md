# ART-07F1 — Lanternheart and Stormglass

The [contract](CONTRACT.md) records unchanged native boundaries and limitations.
Worktree: `C:/Users/Matty/Dev/project-wroughtwild/build/art07/f1/worktree`;
branch `codex/art07-f1`. Only F1 recipes, evidence and receipt are owned here.

Individual built-in imagegen inputs and exact prompts are in
`docs/art/leyline-studies/2026-09-09/art07/f1/`. The interrupted first local heart
run produced no GLB and is rejected. Selected raw sources are
`build/art07/f1/v05/{lanternheart,stormglass}/source.glb`, with retained PNG
cutouts, raw PBR and exact logs. Metadata identifies TRELLIS v0.6.0, CUDA build
`16f3109e82f3922033bfa62b83c42899678b7b6f`, seed 42. Prerequisite evidence retains
the pinned manifest and every model hash. No installs/downloads are required.

Existing tools:

- Python: `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`
- Blender: `C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe`
- Godot: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe`

Relative commands start in the F1 worktree; allocate fresh output versions.
Run `provenance.py <fresh-json>`, then `generate.ps1 -Subject lanternheart
-Output <fresh-folder>` and the Stormglass equivalent. Blender
`inspect_sources.py <fresh-folder> <raw-heart> <raw-tube>` imports actual sources
for six material/clay views. `build_assets.py <raw-heart> <raw-tube> <fresh-assets>`
finishes cores, mechanisms/aftermath, LODs, renders and packed `f1_master.blend`.
Every Blender invocation uses `--background --threads 8 --python-exit-code 1
--python <script> -- <arguments>` through `queued-job.ps1` and `gpu-slot.ps1`.
They preserve foreign processes and guard `Local\Wroughtwild-Art07-GPU`.

Geometry helpers, GPU/native orchestration and common review checks are bounded
derivatives of inspected F3 recipes at the frozen baseline. Original F3 files
are read-only; no F3 asset/package is consumed. Cage, lever, housings, masks,
fitting and state review are F1-specific. Closed recovery transfers UVs through
interpolated source triangles and their material indices. Newly bored faces use
a cylindrical chart. Rings use continuous transported frames and closed seams.

Build native code with `build-native.ps1 -Revision
bbcb3a7dfd235e8f803141ccb57c38e03d6c1708 -Output <fresh-native> -Depot
C:/Users/Matty/Dev/project-wroughtwild`. Freeze matching game/data using
`freeze_game.py <fresh-root> <native-folder>`, then install only in that copy
with `install_review.py <game-folder> <asset-folder>`.

`run-godot.ps1 -Project <game-folder> -Output <fresh-log> -Mode import` imports.
Modes `checks`, `restart`, `restart-depleted`, `capture`, `motion`, `benchmark`
use the isolated project. Render modes accept `-Renderer forward_plus` or
`-Renderer gl_compatibility`. Benchmark separately after generation, captures,
encoding and compilation. `native_checks.py` and `native_review.ps1` run current
strict core/world and unchanged engine regressions.

`asset_cost.py <assets> <fresh-json>` measures exports. `curate.py <assets> <game>`
copies actual renderer evidence and encodes 30 fps previews. `package.py <assets>
<game> <fresh-handoff>` seals the delivery. `fresh_copy.py <handoff> <fresh-copy>`
verifies every file before import. Blender `reopen.py <fresh-copy/source>
<fresh-reopen-output>` reopens the packed master and independently audits GLBs.
Never import the canonical package. Raw generation, packed masters, caches,
compiled code, saves and full capture sequences remain local outputs.

After copying: `launch.ps1 -Mode import`, then `launch.ps1 -Show`. Select the
second renderer with `-Renderer gl_compatibility`. Controls: 0 overview; 1 heart,
2 tube, 3 lamp, 4 lever; T lamp toggle, P request, W finite source work,
C collect physical bundles, F5/F9 isolated save/restore, Escape quit. This is an
authored inspection stage; normal contextual controls are also checked.
The copied launcher keeps saves under its own `user/F1Native` directory.
