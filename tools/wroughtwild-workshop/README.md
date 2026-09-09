# ART-04A — Red source to workshop

An isolated, native-state art handoff. It starts from the existing LF-2C paid
test workshop: three heat stored, one heat/clay/stroke transaction paused at
2.25 seconds, eight bricks already in the tray, and the final Red source lot
still available. These are real checkpoint balances, not free demonstration
items. The review never loads the normal game or its save directory.

## Use the handoff

The local package is `build/workshop-art04/red-handoff/`. Run `Launch review.ps1`
there to import and open its own Godot project with its own APPDATA. It needs
the already installed Godot 4.5 executable; no TRELLIS service is needed to view
it. `editable/red-workshop.blend` contains packed images, the untouched dense
source, the finished roles and editable procedural housing materials.

Keys: **1** source, **2** buffer, **3** whole workshop, **4** fragments;
**D** day/shade, **G** emission off, **N/M/F** near/mid/far, **Space** review pause,
**R** reload the isolated paid checkpoint, **Esc** close. Buttons invoke native
extraction, collection, heat payment, resume, pause and cancellation. The thermal
obstruction button inserts an actual ray-blocking body. Repeated work, full heat
and exhausted claims retain the native refusal rules.

Three small pieces represent a source claim or carried stack; the displayed
native counts are authoritative. A rare catalyst has an independent small
faceted claim marker and native collection action. It is not a new rare-asset
production pass. Stored heat is steady; a travelling marker and stronger core
appear only while the native firing time advances. Neither idle nor a blocked
span loops a success animation.

The initial held firing can be resumed to produce four more bricks. Cancellation
returns its eight clay, one heat and one winding stroke exactly once; start can
then reuse those returned inputs. Charge costs two actual carried Red Salt.
The scene offers no free clay, salt, heat, winding, stock reset or new recipes.
Reset explicitly returns to the copied checkpoint for another inspection.

## Reproduce from the repository

Use fresh output folders for builds. Required tools are the previously approved
local TRELLIS v0.6.0/models, Blender 4.5.9, Godot 4.5, MinGW/CMake and the existing
godot-cpp ABI library under `build/gdext`. No new package or service is installed.

1. `tools/wroughtwild-grove/generate-source.ps1 -Asset rock` accepts the retained
   `red-inclusion-input-v01.png`; its seed, runtime/model revision, input/output
   hashes and timing are in `provenance/generation.json`. The exact image prompt
   is `source-prompt.txt`. Preserve the original input and untouched GLB.
2. Blender background `inspect_source.py -- RAW.glb FRESH_INSPECTION` fits the
   dense source uniformly within the existing body and renders three views.
3. Blender background `finish_assets.py -- INSPECTION/source.blend RAW.glb
   FRESH_ASSETS` authors attached damage/core/travel masks, cuts closed fragments,
   bakes their own UV atlases and fits/bakes the buffer. Always pass
   `--python-exit-code 1` to Blender. All presentation controls are in `red.json`.
4. `build-native.ps1 -Output FRESH_NATIVE` freezes commit
   `f7253d20ed1dbeee743219190bdaccac60921c1c`, then builds into that folder. It
   deliberately does not compile concurrent working-tree changes or replace the
   live game DLL. This is a reviewed baseline, not a claim about later saves.
5. `prepare_review.py NATIVE ASSETS FRESH_REVIEW` copies the isolated project,
   native data, paid checkpoint and existing context assets. `--update` updates
   an existing art review; it never reads normal APPDATA.
6. `run-review.ps1 -Project REVIEW -Mode import`, then `check`, then `restart`.
   `capture` records actual state-driven frames and asserts the material/ownership
   mapping. `capture -Compatibility` writes separate fallback evidence.
   `benchmark` measures six isolated renderer cases; run it without a competing
   capture or generation job.
7. Blender `verify_assets.py -- ASSETS FRESH_EDITABLE` reopens all nine exports,
   checks exact native envelopes, welds imported UV seams to verify closed
   fragment volumes, checks the atlases, packs and reopens the editable source.
8. `package_handoff.py REVIEW EDITABLE ASSETS NATIVE FRESH_HANDOFF` copies only
   this study and records SHA-256 for every delivered file. Imported caches are
   excluded. Raw/local handoffs stay under ignored `build/`, not Git.

## Scope and limits

Source collider: 1.5 × 1.1 × 1.5 m. Buffer: 1 × 1.2 × 1 m. Thermal port remains
0.85 m above the base, with the existing buffer/feeder/forge relative positions.
The original forge and feeder are context assets; only the Red buffer is new.
The backdrop is reused art, not new generated geography or paid construction.

The review is a composed inspection scene with direct native buttons. It does
not adopt the art into normal worlds, test first-person reach/placement, modify
source geography or establish a new renderer policy. ART-05 covers actual route,
placement, streaming and populated-world adoption. The original dense rock is
an exterior surface; only the recovered fragments are certified closed solids.
Small cut faces use cage-baked source detail. Keep their independent UV atlases;
direct nearest-vertex UV transfer was rejected because it crossed source charts.

Forward+ and Compatibility have separate no-bloom captures. SSAO is enabled only
for Forward+. The same desktop GPU was measured; lower-spec devices and ordinary
world frame rates remain unmeasured. The review retains uncompressed/repeated
fallback textures and its grove backdrop, so its texture footprint is not a
production asset budget. Native adoption and texture cooking remain separate.
