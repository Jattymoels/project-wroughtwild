# ART-04B — White source to connection

An isolated White Mineral source, three recovered pieces and the existing
White Connection post. The finished mineral has attached recessed damage and
ivory light. Natural readiness uses a gathering swell; the crafted post gives
one short passage only when the native request counter increases.

## Open the local handoff

`build/workshop-white/white-handoff/Launch review.ps1` imports and opens its own
Godot project. It uses the already installed Godot 4.5 executable and its own
APPDATA. `editable/white-workshop.blend` has packed images, the retained dense
source, the finished models and editable housing materials. No TRELLIS service
is needed to inspect the package. The normal game and saves are not opened.

Keys: **1** source, **2** post, **3** complete signal/cargo route, **4** fragments;
**D** day/shade, **G** emission off, **N/M/F** detail, **S** physical signal
obstruction, **C** physical cargo obstruction, **Space** review pause,
**R** reload the copied checkpoint, **Esc** close. Native buttons work the source,
collect material, wind the drum, send a request, transfer cargo and reconnect.

The initial checkpoint already paid for a ten-wood trip. Its progress is
exactly `1.2 / 14` (0.4 seconds along a 14 m trip at 3 m/s), with zero winding
left and three historical requests. Loading never replays those requests.
Finish the trip, collect at the landing, wind once and request an empty return.
At the drum, load ten carried wood and wind again before a new outbound request.
An unwound request can pass through White without moving anything; a blocked
signal cannot pass. White stores neither drive nor a request for future work.
The six-second clip replays the actual paid empty return, not a free work loop.

Three small pieces represent a native claim or carried stack. Counts are
authoritative; these are not additional inventory owners or world pickups.
Work four times to release a lot, then collect. The review supplies no free
mineral, cargo, materials, kits or winding. Reset explicitly restores the copied
paid checkpoint for another inspection.

## Reproduce

Use fresh output folders. Dependencies are the already approved local TRELLIS
v0.6.0/models, Blender 4.5.9, Godot 4.5 and existing Python/Pillow/NumPy. No new
package, service or third-party asset is installed by this recipe.

1. The exact built-in ImageGen prompt is `source-prompt.txt`; its unchanged input
   is `docs/art/leyline-studies/2026-09-09/workshop-white/white-inclusion-input-v01.png`.
   Run `tools/wroughtwild-grove/generate-source.ps1 -InputImage IMAGE -Output FRESH_SOURCE -Asset rock`.
   Preserve `rock.glb`, `generation.json` and the log. Seed 42, resolution 1024,
   model/runtime revisions and SHA-256 are recorded there.
2. Set `BLENDER_USER_RESOURCES` to a task-specific folder under `build/workshop-white/`.
   Use background Blender with `--python-exit-code 1 --python SCRIPT -- ARGS`.
   `inspect_source.py -- RAW.glb FRESH_INSPECTION` uniformly fits and orients the
   original source, renders front/back/top and preserves its images in a blend.
3. `finish_assets.py -- INSPECTION/source.blend RAW.glb FRESH_ASSETS` preserves
   original surface/UV detail, corrects face orientation, authors attached scars,
   cuts closed fragments and bakes/fits the post. `white.json` explains all
   presentation controls and the conservative detail budgets.
4. Reuse the hash-checked isolated native baseline from ART-04A
   (`build/workshop-art04/native-v02`). To rebuild it, use the Red recipe's
   `build-native.ps1` against frozen commit `f7253d20ed1dbeee743219190bdaccac60921c1c`.
   Neither path replaces the live game DLL or compiles concurrent working changes.
5. Python `prepare_review.py NATIVE ASSETS FRESH_REVIEW` copies the project,
   published `build/lf2/wave1-midtrip.json`, tuning and existing backdrop assets.
   `--update` updates only that isolated review. It never reads normal APPDATA.
6. `run-review.ps1 -Project REVIEW -Mode import`, then `check`, `restart`,
   `capture`, `capture -Compatibility`, and `benchmark`. Run benchmark without
   competing GPU generation/capture jobs. The offline review retains a possible
   Windows sandbox certificate-store startup warning in its log; script, shader,
   assertion and other engine errors still fail the run.
7. Blender `verify_assets.py -- ASSETS FRESH_EDITABLE` reopens all nine exports,
   checks native envelopes and closed chip volume, verifies atlases, renders and
   reopens the packed editable source. Failed checks are not waived.
8. Python `finalize_evidence.py REVIEW EDITABLE DOCS_OUTPUT` verifies recorded
   ownership, actual image differences with emission off, and exact pixels/time
   in the lossless six-second WebP. It copies selected unchanged engine captures.
9. Python `package_handoff.py REVIEW EDITABLE ASSETS SOURCE FRESH_HANDOFF` copies
   only this study and verifies every delivered file against its SHA-256 manifest.
   Original meshes, blends, native DLLs and imports stay in ignored `build/`.

## Scope and limits

The source remains within 1.5 × 1.1 × 1.5 m. The post remains within
0.65 × 1.18 × 0.55 m and its terminal meets the existing 1.18 m signal endpoint.
Lever/post/drum/landing positions retain their native relative layout: signal
spans 4.1231 m and 5 m, cargo span 14 m. Actual ray tests and a 0.3 m basket
sweep drive obstruction in the review. First-person placement/support and
normal-world route adoption are ART-05 work, not established by this scene.

The source is an exterior mesh with non-manifold junctions, not a watertight
geological volume. Normal correction retains its planes and original textures;
voxel repair/rebaking was rejected because it visibly softened and distorted
them. Only the recovered pieces are certified closed solids. New cut faces use
per-texel nearest-triangle projection with barycentric UVs from that triangle's
own chart; no interpolation crosses unrelated source UV charts. Their tangent
normal maps are baked in their own UV frames.

Conservative source detail levels are 41,937 / 17,989 / 14,989 triangles; the
post adds 1,596 housing triangles. The original exterior's junctions prevent
clean reduction to the first attempted 2.5k far target. A lower distant budget
needs a future topology pass; no 2.5k result or populated-world performance is
claimed. The three chips use 200 / 178 / 136 triangles with individual 1k maps.
Source/housing maps are 2k. Texture cooking, lower-spec performance and actual
world adoption remain separate. The existing lever/winch and grove are context
assets, not newly finished White props or new generated terrain.
