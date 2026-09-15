# MOB-06 tortoise reproduction

The selected ART-06C v02 living tortoise is the ordinary native `hollow_knight`.
The descriptor and species adapter add presentation only. Enemy, PlayerCombat,
save data, world/realtime tuning and native simulation are unchanged.

## Retained source

- Immutable five-file input and matched selection receipt:
  `D:/Wroughtwild/source-art/mob06-tortoise/input-art06c/`.
- Selected editable master, packed original maps, source report and recipe:
  `D:/Wroughtwild/source-art/mob06-tortoise/rig-v01/`.
- [Rig controls and their player-facing purposes](rig.json).
- [Runtime descriptor](../../game/assets/authored/roster/hollow_knight/asset.json).

The 17-bone fit has body, neck, head, tail and four upper/lower/foot chains.
Mantle and scutes stay supported together; there are no floating armour pieces.
Source coordinates are Z-up/-Y-forward. Godot imports Y-up/+Z-forward, and the
adapter uses 180-degree yaw. Uniform .9 fit cancels only the native .76 humanoid
shrink; parent family 1.25 and optional elite 1.3 remain applied once. Four-beat
78-percent stance, .16 source-unit sweep and .055 lift produce planted poses on
a local plane. Stride is cosmetic; native movement and melee reach are unchanged.

## Focused reproduction

Run from this worker root with Blender 4.5.9 LTS and Godot 4.5 stable. Use private
D: APPDATA/TEMP and the prepared native DLL. Do not rebuild the native DLL for
this presentation-only slice. Setup records its reused SHA.

```powershell
$env:APPDATA='D:/Wroughtwild/work/mob06-tortoise/build/mob06/user'
$env:TEMP='D:/Wroughtwild/work/mob06-tortoise/build/mob06/temp'
& 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe' --background --threads 6 --python-exit-code 1 --python tools/wroughtwild-mob06-tortoise/build_tortoise.py -- D:/Wroughtwild/source-art/mob06-tortoise/input-art06c D:/Wroughtwild/source-art/mob06-tortoise/rig-v02 game/assets/authored/roster/hollow_knight
python tools/wroughtwild-mob06-tortoise/prepare_asset.py D:/Wroughtwild/source-art/mob06-tortoise/rig-v02 game/assets/authored/roster/hollow_knight
```

The builder refuses to overwrite a source version. The example uses a **new**
version; the delivered selection is rig-v01. It retains the dense host, welds
coincident positions, collapses one runtime detail level, validates topology,
fits normalized weights, bakes four clips at 40Hz, checks representative pose
clearance/leg lengths and exports. Two collapse-generated duplicate triangles
were removed in the selected export; final topology validates cleanly. This is
automatic simplification, with no manual retopology or new normal bake.

Only rerun a relevant check for a concrete change or observed failure:

```powershell
& 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe' --background --threads 6 --python-exit-code 1 --python tools/wroughtwild-mob06-tortoise/check_saved.py -- D:/Wroughtwild/source-art/mob06-tortoise/rig-v01 build/mob06/saved-master-check.json
powershell -NoProfile -ExecutionPolicy Bypass -File tools/wroughtwild-mob06-tortoise/run_checks.ps1 -Job import
powershell -NoProfile -ExecutionPolicy Bypass -File tools/wroughtwild-mob06-tortoise/run_checks.ps1 -Job native -Capture
powershell -NoProfile -ExecutionPolicy Bypass -File tools/wroughtwild-mob06-tortoise/run_checks.ps1 -Job restore
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-mob06-tortoise/encode_media.py build/mob06/integration game/tests/mob06/evidence
```

Capture uses the nonblocking `Local\WroughtwildArtRender` mutex, Forward+, a
scripted target/camera, `--r8-no-mouse-capture` and an owned no-focus override.
The override is written as BOM-free UTF-8, including under Windows PowerShell.
The fixture stops capture if the visible-mouse/unfocusable-window assertion fails
and leaves the actual
native ward aura visible. The runner refuses an existing override, records its
owned process and removes only its unchanged override in finally. It stops
owned processes on timeout and retains the native process handle for a reliable
exit code. `-Job native -Capture -CaptureOnly` repeats only capture after an
observed capture-harness failure. No desktop pointer automation is used.

The native fixture checks actual warded player damage, range/trial boundaries,
stagger, freeze, native aura, defenses, melee hit/miss/cover, pursuit, per-instance
rigs/materials, family/elite scale, pause, rebind and death. The generated fixture
uses one seed, a real pack-member death and ordinary SaveManager write/read,
including exact drop/progression/ownership equality and transient-pose reset.
No performance benchmark, second renderer, source matrix or parent repack is
required. See the [slice result](../../docs/prototype/mob06-tortoise-result-2026-09-15.md)
for actual results and remaining limits.
