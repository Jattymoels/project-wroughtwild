# ART-07B4 — Composed walk, light and distance

One isolated 36 m walk using the published B1/B2/B3 candidates and ART-02's
existing authored landform. No normal game, native rule, resource owner, saved
geography or construction shape changes. This is a source/technical checkpoint;
the owner has not accepted its visual finish or ordinary-world adoption.

The packed master has SOURCE, FINISHED, RUNTIME and REVIEW collections. Full-width
near trees retain B1 geometry; middle trees use B1's middle exports. Distant
family silhouettes reduce trunk/branchlet/leaf surfaces to 3,500/1,800/8,500
triangles respectively. Far reductions are for silhouette review beyond 20 m;
they are not close-up attachment masters. Whole B2 far fronds retain their stems
and contacts, avoiding the 90k-triangle lush near fern in repeated ground cover.

Ground plants use shared meshes in 32-metre groups. Their base and rooted
bend follow the exact 0.5 m ART-02 terrain triangles. Moss/litter stay still.
Tree families share separate batches for each of the three levels (6/20 m).
Nearby trees cast their far silhouette into one 26-metre shadow view; small
plants and distant crowns omit shadow passes. Rocks share repeated submissions;
same-material fern parts and talus fragments concatenate their existing triangles.
All actual full-width collision shapes remain independent. The comparison
enables individual near trees, plant shadows and four 45-metre shadow cascades.
Explicit mipmaps prevent distant floor sparkle. glTF scene import disables
additional engine LODs, shadow meshes and attribute compression so the authored
three levels and linear scar/wind channels remain inspectable.

Textures are shared by content hash, with at most 1024 pixels per side. Only
albedo is sRGB. Metallic/roughness uses linear G/B; its unused R channel is not
treated as occlusion. Original images/GLBs remain in the prerequisite packages.
The cook preserves every non-image buffer-view byte. The B4 Blender finish
repairs glTF's constant-emission/vertex-colour interpretation and matches the
Godot placement yaw; it does not change the exported host positions.

Both scars retain real source displacement and independent runtime surface
distance measurements. Ambient light, attached foliage and broad water flow use
one explicit pause-aware clock, no shader TIME, bloom or local scar lamps.
Ordinary surfaces have no magical emission. The shallow opaque water is a
review surface inside the ART-02 bank, with no swimming or flooding behavior.

Quiet ambience copies the current EnvironmentSound synthesis and look resource
unchanged. Its single scene voice uses 1.6–2.4 second foliage textures, 12–24
second gaps and -36 dB gain. Q mutes this isolated scene; Space pauses it. There
is no new sound pack, animal cue, continuous drone or persisted audio preference.

The interactive capsule is 0.32 m radius and 1.8 m high, with WASD/mouse movement.
L changes day/shade/dusk; M toggles scar light; Space pauses; Q mutes; R returns
to the start; 0 uses distance detail and 1/2/3 force near/middle/far; Escape frees
or captures the mouse. The review has no harvesting, inventory, placement kits,
combat, streaming, save/load or source-work state. Its full-width wood and rock
meshes have physical review collision. **This is not a replacement for the game's
native bodies.** The old 0.7 × 3 × 0.7 m tree-body fit still fails and is measured
explicitly. The supported route clears these actual wide shapes without scaling
the crowns into B1's narrow state-test form. Ordinary adoption needs its own fit
decision and context; no collider or native geography has been changed here.

## Reproduction

Use the existing local Blender 4.5.9 (Cycles CPU, eight threads), Godot 4.5-stable
and bundled Python/Pillow. No download, package or new generation is required.
`prerequisites.py` records the exact absolute packages and expected manifest
hashes and verifies every file, including ART-02. A clone does not contain them.

Run from the isolated `codex/art07-b4` worktree:

```text
python tools/wroughtwild-art07/b4/prerequisites.py NEW_ROOT/prerequisites.json
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-art07/b4/build.py -- NEW_ROOT/kit
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-art07/b4/finish_master.py -- NEW_ROOT/kit NEW_ROOT/finished
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-art07/b4/audit.py -- NEW_ROOT/finished NEW_ROOT/audit.json
python tools/wroughtwild-art07/b4/prepare.py NEW_ROOT/finished NEW_ROOT/review
godot --headless --editor --path NEW_ROOT/review --import
run-stage.ps1 -Project NEW_ROOT/review -Logs NEW_ROOT/final-capture -Stage Capture
run-stage.ps1 -Project NEW_ROOT/review -Logs NEW_ROOT/final-walk -Stage Walk
run-stage.ps1 -Project NEW_ROOT/review -Logs NEW_ROOT/final-motion -Stage Motion
run-stage.ps1 -Project NEW_ROOT/review -Logs NEW_ROOT/final-benchmark -Stage Benchmark
python tools/wroughtwild-art07/b4/encode.py NEW_ROOT/review NEW_ROOT/media-final
python tools/wroughtwild-art07/b4/verify.py NEW_ROOT/review NEW_ROOT/verification.json
python tools/wroughtwild-art07/b4/prepare_native.py NEW_ROOT/current-v02
run-current-checks.ps1 -Project NEW_ROOT/current-v02/game -Logs NEW_ROOT/current-checks
python tools/wroughtwild-art07/b4/package.py NEW_ROOT/finished NEW_ROOT/review NEW_ROOT NEW_ROOT/handoff
python tools/wroughtwild-art07/b4/verify_package.py NEW_ROOT/handoff NEW_ROOT/fresh-copy
```

The short executable names describe argument contracts, not installed aliases.
Actual executable paths/arguments/PIDs, durations and exits are in job JSON files.
The PowerShell stage runner is in this recipe folder, serializes both renderers
with `Local\Wroughtwild-Art07-GPU`, and refuses another renderer/generator. Run
benchmarks separately from generation, capture, encoding and CPU work.
Quiet/grounded and the fourteen current-game regression runs are recorded in the
receipt. `prepare_native.py` verifies that current game/sim/data at `0f35e87`
are byte-identical to the B3 compiled revision before reusing that verified DLL
in a fresh archive. It never replaces the shared native DLL or opens normal saves.

To inspect an immutable package, use its `recipe/launch-review.ps1 -Package
ABSOLUTE_PACKAGE -CopyTo FRESH_DIRECTORY -Renderer forward_plus -Mode review
-Visible`. The launcher verifies every canonical file and its new copy, imports
only the copy, and isolates APPDATA. Use `gl_compatibility` for the other renderer.
If the renderer is busy, the copied files stay ready and no other job is stopped.

`scene.json` explains the candidate controls and provisional scene budgets.
`layout.json` is this one authored composition, not a new world scatter rule.
Original and revised attempts remain under ignored B4 version directories.
Batching can submit off-screen instances; the larger plant cells deliberately
trade coarse culling for fewer draws. A single short shadow view is not suitable
as a general world-shadow convention. Budget assertions cover the stated
start-view day/dusk benchmark, not every possible free-camera or forced-LOD view.
Far tree topology, visible LOD transitions, repeated foliage, bark faceting, renderer differences and
remaining empty ground are visible compromises. RTX results do not certify a
populated forest, the ordinary streamer, a lower-spec device or user comfort.
