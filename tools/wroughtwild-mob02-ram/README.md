# MOB-02 ram production recipe

Produces the approved ART-06C bighorn ram for the existing stone_husk / guard role.
This directory owns source production; MOB-01/coordinator owns shared game wiring.
The result and precise handoff are in
[the slice report](../../docs/prototype/mob02-ram-result-2026-09-15.md).
The selected source is D:/Wroughtwild/source-art/mob02-ram/rig-v05/.

## Reproduce

Use installed Blender 4.5.9, Godot 4.5-stable and the existing Python runtime
with NumPy/Pillow. No new package or service is needed. Run from this checkout.
Supply a **new** source directory; the builder refuses to overwrite one.

~~~powershell
$ramBlender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$ramPython = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$ramGodot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
& $ramBlender --background --threads 6 --python-exit-code 1 --python tools/wroughtwild-mob02-ram/build_ram.py -- D:/Wroughtwild/source-art/mob02-ram/input-art06c D:/Wroughtwild/source-art/mob02-ram/NEW_VERSION game/assets/authored/roster/stone_husk
# Stop if any command fails. Do not import/capture a previous export after failure.
& $ramPython tools/wroughtwild-mob02-ram/prepare_fixture.py build/mob02/fixture
$env:APPDATA = 'D:/Wroughtwild/work/mob02-ram/build/mob02/appdata'
$env:MOB02_OUTPUT = 'D:/Wroughtwild/work/mob02-ram/build/mob02/NEW_EVIDENCE'
New-Item -ItemType Directory -Force -Path $env:MOB02_OUTPUT | Out-Null
& $ramBlender --background --python-exit-code 1 --python tools/wroughtwild-mob02-ram/check_saved.py -- D:/Wroughtwild/source-art/mob02-ram/NEW_VERSION "$env:MOB02_OUTPUT/source-checks.json"
& $ramGodot --headless --path build/mob02/fixture --editor --import
& $ramGodot --headless --path build/mob02/fixture -- --check
& ./tools/wroughtwild-mob02-ram/capture.ps1 -Output $env:MOB02_OUTPUT
& $ramPython tools/wroughtwild-mob02-ram/prepare_handoff.py D:/Wroughtwild/source-art/mob02-ram/NEW_VERSION $env:MOB02_OUTPUT
~~~

Reuse unchanged source evidence; these commands describe reproduction, not a
required new review wave. The capture launcher acquires Local\WroughtwildArtRender
nonblocking (exit 75 means busy), owns the process until exit, and releases the
mutex in finally. It does not capture the mouse or focus the window. The tiny
fixture's private project/data live under ignored build output on D:.

## Source and controls

- rig.json contains the fitted, asymmetric joints and explains each animation
  control. Coordinates are studio units, Z-up and -Y forward; the longest source
  dimension is two units.
- build_ram.py preserves the dense original in the new master, welds matching
  seam positions, collapses to one runtime detail level, removes two duplicate
  faces, and fits 23 bones with normalized weights (four maximum).
- Four upper/lower/pastern/hoof chains use planted analytic targets. The head,
  ears and horn curls use rigid skull weights. Connected skin diffusion reuses
  the existing tools/wroughtwild-fauna/smooth_weights.py helper; rear torso and
  rigid anchors remain fixed against inappropriate diffusion.
- The five actions are baked at 50 Hz. All export transforms remain in place.
  There are no gameplay events, extra contact bodies, damage or persistent state.
- Actual source walk travel is 0.38 / 0.66 = 0.5757576 units per cycle, separate
  from a suggested 1.5 m cosmetic native cadence. The latter deliberately allows
  sliding to avoid very rapid steps at the existing 2.8 m/s movement speed.
- The GLB fallback is intentionally neutral and non-emissive. Production must
  bind the supplied unchanged ART-06C maps and damage_tint shader behavior.
  The descriptor records channels, settings, intended loops and exact paths.

The original checks above cover the species export. Coordinator integration also
adds `game/art/ram_presentation.gd`, the existing Stone Husk dispatch and the
focused `native.gd` / `restore.gd` fixtures. Native guard and combat rules stay in
Enemy. The descriptor explains uniform size, deliberate cosmetic stride and the
0.12-second stationary idle/brace blend. SaveManager clears the unsaved visual
strike through the existing transient presentation group.

From the owner depot, rerun only a relevant check:

```powershell
./tools/wroughtwild-mob02-ram/run_native.ps1 -Job native -Capture
./tools/wroughtwild-mob02-ram/run_native.ps1 -Job restore
```

The first checks actual guard facing/stagger, melee timing and presentation on
one native actor with one Forward+ capture; the second uses a real seed-77 pack
and ordinary SaveManager/Continue. `-Job import` refreshes Godot resources. Private
saves, temporary data and logs default to D:/Wroughtwild/work/mob02-ram/build/mob02/integration.
The renderer shares the nonblocking mutex, asserts a visible pointer and
unfocusable window, and removes its own override on exit. The evidence directory
is documentation, excluded from Godot resource imports by `.gdignore` (the engine
cannot import its animated WebP preview). No cache or executable is committed.
