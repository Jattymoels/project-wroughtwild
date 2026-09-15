# MOB-03 crane production

The approved ART-06C crane now has one weighted runtime surface, an attached
opening lower beak, fitted legs, a supported neck/throat and five in-place clips.
This folder contains the species recipe, not a shared game adapter.

## Selected delivery

- Runtime: `game/assets/authored/roster/shrieker/model.glb`, original base/ORM/scar
  maps, the ART-06C-compatible shader and `asset.json`.
- Editable master: `D:/Wroughtwild/source-art/mob03-crane/rig-v04/shrieker-rigged.blend`.
- The immutable selected inputs remain in `D:/Wroughtwild/source-art/mob03-crane/input-art06c`.
- Handoff: [MOB-03 result](../../docs/prototype/mob03-crane-result-2026-09-15.md).
- Curated evidence: `game/tests/mob03/evidence/`. Large temporary frames/imports
  belong in the ignored D: `build/mob03/` tree.

`rig.json` explains every presentation parameter. Studio coordinates use Z up,
-Y forward and a two-unit height. The GLB uses Y up and +Z forward. Apply a 180°
Y rotation for the existing -Z-facing Enemy. Suggested uniform scale is 0.8;
retain the existing independent family/elite scale and unchanged collider.

## Reproduction

From this checkout, using the installed Blender 4.5.9 and bundled Python:

```powershell
$craneBlender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$cranePython = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
# Choose a fresh source version. The builder refuses existing directories.
& $craneBlender --background --threads 4 --python-exit-code 1 --python tools/wroughtwild-mob03-crane/build.py -- D:/Wroughtwild/source-art/mob03-crane/rig-v05
& $craneBlender --background --threads 4 --python-exit-code 1 --python tools/wroughtwild-mob03-crane/check_saved.py -- D:/Wroughtwild/source-art/mob03-crane/rig-v05
& $cranePython tools/wroughtwild-mob03-crane/prepare.py D:/Wroughtwild/source-art/mob03-crane/rig-v05
& ./tools/wroughtwild-mob03-crane/run.ps1 -Mode Import
& ./tools/wroughtwild-mob03-crane/run.ps1 -Mode State
& ./tools/wroughtwild-mob03-crane/run.ps1 -Mode Capture
& $cranePython tools/wroughtwild-mob03-crane/retain_evidence.py
```

These are reproduction instructions, not an instruction to repeat passed checks
at integration. The wrapper holds `Local\WroughtwildArtRender` for the entire
capture process, returns 75 if busy, isolates application data and terminates
owned failed tests. The fixture asserts a visible pointer and no-focus window.
It never loads a real world, native extension or player save.

The GLB contains no portable loop flags. Set `idle` and `walk` to loop in the
shared adapter or importer, as the descriptor and fixture do. The full `call`
clip returns to neutral; when moving, layer its five named upper-body bones over
the travel-driven gait. Recruitment itself remains entirely in `force_scream()`.
