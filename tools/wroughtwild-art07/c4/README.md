# ART-07C4 — recovering wastes

C4 owns only ash_snag and wastes_scrub. This is an editable source kit and
isolated habitat/native-state review, not an ordinary-world integration.
The receipt records the selected version, exact local package, hashes,
measurements and limitations. All fresh output stays under this worktree's
build/art07/c4. B1–B4 and ART-02 remain read-only.

## Existing prerequisites

Canonical depot: C:/Users/Matty/Dev/project-wroughtwild.

- Blender: depot build/blender-tool/blender-4.5.9-windows-x64/blender.exe.
- Generator: depot build/trellis-local/runtime/trellis-cli.exe.
- Models: depot build/trellis-local/models; repository install-manifest.json
  pins v0.6.0 and all ten weights. No installation or download is performed.
- Python: C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe,
  with its existing Pillow and NumPy.
- Godot: C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe.
- B1–B3 and ART-02 packages: exact absolute paths and hashes in prerequisites.py.

Run prerequisites.py to verify every prerequisite file. provenance.py verifies
the installed models/tools and original individual ash input. The pine/oak
canopies were inspected and retain B4's body-fit limitation. C4 therefore uses
one new individual built-in imagegen ash source, with the exact submitted text
in ash-prompt.txt and the unchanged PNG in its owned evidence directory.
The shrub and thorn host reuse B2; rock and ground families reuse B3/ART-02.

## Reconstruction

Run reconstruction from the checked C4 worktree. The packaged recipe is a
snapshot for provenance; its standalone launch-review.ps1 works directly from
the package, while production helpers intentionally enforce the worktree's
owned output boundary.

Use new output paths at every production stage. Commands below describe actual
argument contracts; substitute the absolute existing executable paths above.
Every executed process must use run-job.ps1 so its PID, arguments, exit code,
duration and isolated user directory are retained. Use -Gpu for generator and
rendered Godot work. Blender uses CPU Cycles with --threads 8.

1. python prerequisites.py FRESH/prerequisites.json
2. python provenance.py FRESH/provenance.json
3. generate-ash.ps1 -Output FRESH/ash-raw
4. blender --background --threads 8 --python-exit-code 1 --python inspect_source.py -- FRESH/ash-raw/source.glb FRESH/inspection
5. blender --background --threads 8 --python-exit-code 1 --python build.py -- FRESH/inspection/ash-source.blend FRESH/kit
6. blender --background --threads 8 --python-exit-code 1 --python audit.py -- FRESH/kit FRESH/audit.json
7. blender --background --threads 8 --python-exit-code 1 --python render_master.py -- FRESH/kit FRESH/blender
8. python prepare_review.py FRESH/kit FRESH/review
9. python prepare_native.py FRESH/native
10. python prepare_fixture.py FRESH/review FRESH/native/game
11. Import both copied projects with Godot --headless --editor --path PROJECT --import.
12. run-current-checks.ps1 -Project FRESH/native/game -Logs FRESH/current-checks.
13. run-stage.ps1 -Project FRESH/review -Logs FRESH/capture -Stage Capture,
    then distinct Motion and Walk stages/log directories.
14. run-stage.ps1 -Project FRESH/native/game -Logs FRESH/native-checks -Stage Native.
15. Coordinate a quiet CPU/GPU window, then run the separate Benchmark stage
    on FRESH/review. Do not capture, encode or generate during this window.
16. python verify.py FRESH/review FRESH/native/game FRESH/verification.json.
17. python encode.py FRESH/review FRESH/native/game FRESH/blender FRESH/media.

The selected receipt names the actual versioned folders. package.py consumes
that selected root after environment.py and verify.py; it does not infer a
candidate from whichever folder was written most recently. verify_pause.gd
additionally exercises actual Space key events, sixteen paused frames and
resume, rather than inferring interactive pause from sampled clock frames.

prepare_native.py freezes the explicitly inspected published main
f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9. It proves game/sim/data are unchanged
from B3's recorded compiled revision before reusing the verified DLL. This is
binary reuse with source equivalence, not a fresh compilation. Never let an old
helper silently select its historical default.

The shared Local\Wroughtwild-Art07-GPU mutex is cooperative. The runner also
checks existing Blender/Godot/TRELLIS processes and yields without touching them.
Its own logs must be fresh. No broad process termination, normal-save load,
live DLL replacement, shared checkout switch or publisher push occurs.

## Geometry, materials and state

The normalized original source is preserved. Finished lower wood fits within a
0.28 m radius up to 2.6 m; upper branches recover their original spread through a
smooth transition. Two crooked crowns and one shorter broken form vary the
silhouette. One optional altered form carries a measured geometric incision;
its light is ambient and never a stock/work-success signal. Felled timbers are
separate decorative source candidates. The actual native fall uses the standing
mesh, unchanged timing and a matching session stump.

The master preserves SOURCE, FINISHED, RUNTIME and REVIEW collections. It packs
original albedo and ORM images. Albedo is sRGB; ORM and scar UV2 are linear.
The review cook shares images by content hash, with a 1024-pixel cap, preserving
every non-image glTF buffer view byte. Original packed maps remain at full size.
Geometry is opaque and two-sided; plant shadows are disabled in the review.
There are no alpha cards, bloom or per-scar lights. Ground reuses the original
ART-02 litter image with mirrored, blended sampling and explicit mipmaps.

Export maps Blender (x,y,z) to Godot (x,z,-y) once. Standing/stump pivots are
at the ground base; felled pieces have a central horizontal pivot and measured
lowest contact at zero. Native resource collision remains exactly
0.6 × 2.6 × 0.6 m, centred at Y=1.3. Six presses pay fourteen ash wood.
Partial work, finite stock, resource IDs, pickup ownership and depletion use
the current ResourceNode and SaveManager. Normal lean/fall are untouched.

kit.json explains every exposed control. Layout is a deterministic authored
fixture, not a world-generation rule. Review-only slopes, underside seating,
plant vertex conformance and fixed source placements have no save authority.
Rock/ground forms are context, not additional harvestables. The review capsule
is 0.32 m radius, 1.8 m high; it follows an open route using actual input and
move_and_slide. Rocks/felled dressing have no added gameplay collider.

## Review and delivery

Interactive review: WASD/mouse, L day/shade/dusk, M scar light, Space pause,
0 automatic detail or 1/2/3 fixed detail, R start, Escape cursor. The standalone
habitat has no inventory, harvesting, placement, combat or persistence.
The native fixture is a separate automatically exiting posed test of current
work/felling/reload rules. It is not a normal paid campaign.

package.py accepts the selected output root and a fresh package destination.
It writes manifest.json for every delivered file. verify_package.py verifies
the immutable package, optionally creating and verifying a fresh copy.
launch-review.ps1 verifies/copies/imports only that fresh copy and isolates
APPDATA/LOCALAPPDATA there. Never import the canonical handoff.

Raw source, packed masters, runtime GLBs/glTFs, native DLL/copies, frame sequences,
caches, test saves and handoffs remain local and ignored. Git contains only
C4 recipes, the original input, curated actual evidence, reports and receipt.
A clean clone requires the explicitly transferred and verified local handoff,
or reconstruction using the documented local depot and source packages.
