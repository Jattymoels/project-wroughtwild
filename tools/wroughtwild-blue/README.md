# ART-04C — Blue source to delay

One isolated Blue layered fracture, three closed recovered flakes and the
existing Blue Delay fitting. Source light lingers in a fracture before moving;
the device follows actual native elapsed delay. Explicit pause or blocked output
holds the crest at exactly the same position. Expiry releases once even when an
unwound or cargo-blocked receiver refuses to work. No Frost effect is added.

## Inspect the local package

`build/workshop-blue/blue-handoff/Launch review.ps1` imports and opens its own
Godot 4.5 review and APPDATA. `editable/blue-workshop.blend` contains packed maps,
the retained dense source, finished models and editable housing materials.
Generation does not need to run again. Normal game saves and processes are unused.

Keys: **1** source, **2** delay, **3** route, **4** flakes; **D** day/shade,
**G** emission off, **N/M/F** detail, **S** output obstruction, **C** cargo
obstruction, **Space** review pause, **A** active/away, **R** copied-save reset,
**Esc** close. Native buttons extract/collect, wind, request, hold/resume/cancel,
transfer cargo and reconnect. The separate rare collection button exposes any
source-owned Faint Frost claim without turning the Blue material into ice.

The published checkpoint owns 14 carried Blue Flakes, source lot 1/8, ten wood
in the drum, one winding, two previous trips and one pending request elapsed
0.8 of 3 seconds. Let it release, then collect at the landing. Wind again and
request a return; a new outbound load needs actual carried wood. Reset restores
the copied paid state explicitly. It supplies no free kit, drive or materials.
The eight-second clip is one paid request/delivery, not repeated free output.

Three displayed pieces represent the claim or carried stack. Native counts are
authoritative. A rare-only claim remains in the interface after raw collection.
The separate accelerated rare test consumes test-carried flakes to clear space;
it advances actual fixed outcomes and formation, with no grants or outcome edits.
That capture is explicitly labelled and does not claim ordinary pacing.

## Reproduce

Use fresh output directories. Existing approved dependencies: local TRELLIS
v0.6.0/models, Blender 4.5.9, Godot 4.5, Python/Pillow/NumPy. No new package,
service or third-party asset is installed. Scripts require UTF-8 with ordinary
LF or CRLF newlines; do not round-trip GDScript through Windows ANSI encoding.

1. `source-prompt.txt` is the exact built-in ImageGen prompt. The copied input is
   `docs/art/leyline-studies/2026-09-09/workshop-blue/blue-fracture-input-v01.png`.
   Use `tools/wroughtwild-grove/generate-source.ps1 -InputImage IMAGE -Output FRESH_SOURCE -Asset rock`.
   Preserve original GLB, generation log and hashes: seed 42, 1024 generation,
   2048 textures, runtime/model revisions recorded in `generation.json`.
2. Set `BLENDER_USER_RESOURCES` to `build/workshop-blue/blender-user` before every
   background Blender run. Use `-b --python-exit-code 1 --python SCRIPT -- ARGS`.
   `inspect_source.py -- RAW.glb FRESH_INSPECTION` normalizes uniformly and renders
   front/back/top. `finish_assets.py -- INSPECTION/source.blend RAW.glb FRESH_ASSETS`
   corrects orientation, retains UV planes, authors recessed scars, cuts solid
   flakes and fits the delay. `blue.json` explains presentation controls.
3. Reuse `build/workshop-art04/native-v02`, verified against its provenance.
   To rebuild, use the Red recipe's `build-native.ps1` at frozen commit
   `f7253d20ed1dbeee743219190bdaccac60921c1c`. Do not replace the live game DLL.
4. Python `prepare_review.py NATIVE ASSETS FRESH_REVIEW` copies the published
   `build/lf2/published-a/lf2-pending.json`, frozen tuning and existing context.
   `--update` updates only the isolated review. Godot explicitly binds the supplied
   maps/shader; exported authoring node animation is not assumed to transfer.
5. `run-review.ps1 -Project REVIEW -Mode import`, then `check`, `restart`,
   `capture`, `capture -Compatibility`, and `benchmark`. Benchmark with no other
   generation/capture job. The offline sandbox certificate-store startup warning
   remains in logs; every other engine/script/shader/assertion error fails.
6. Blender `verify_assets.py -- ASSETS FRESH_EDITABLE` reopens nine exports,
   checks unchanged native envelopes, cradle contact, UVs, closed flake volumes
   and atlas content, then renders/reopens the packed editable source.
7. Python `finalize_evidence.py REVIEW EDITABLE DOCS_OUTPUT` checks recorded
   ownership, actual emission/progression pixels in both renderers, identical
   paused core pixels, and all 64 frames/8,000 ms of the lossless WebP.
8. Python `package_handoff.py REVIEW EDITABLE ASSETS SOURCE FRESH_HANDOFF` copies
   only this study and verifies every file in a SHA-256 manifest. Generated meshes,
   Blender sources, native DLLs and engine imports stay under ignored `build/`.

## Limits

The source stays within 1.5 × 1.1 × 1.5 m; the delay stays within
0.65 × 1.18 × 0.55 m with its original 1.18 m terminal. The copied
lever/White/Blue/drum/landing relative layout retains 4.1231/4.1231/5.6569 m
signal spans and the 14 m cargo span. Actual signal rays and a 0.3 m basket
sweep drive obstruction; ordinary first-person placement/support is ART-05 work.

The generated source remains an exterior mesh with non-manifold junctions,
not a certified geological solid. Only recovered flakes have a checked closed
volume. Their new cut faces use per-texel nearest-triangle projection and that
triangle's barycentric UV coordinates; independent tangent frames prevent
reusing source normals incorrectly. New faces are inferred mineral appearance.

Near/mid/far sources are 35,999 / 15,999 / 7,999 triangles. The delay adds 2,652
housing triangles and one housing surface. Flakes use 192 / 134 / 176 triangles
and individual 1k atlases; source/housing use 2k. These are measured handoff
levels, not a final world budget. Use the explicit supplied Godot material
binding rather than relying on GLB fallback interpretation of authoring nodes.
Texture cooking, lower-spec testing, streaming and populated-world adoption
remain later. Existing White, lever, winch, landing, grove and table are context.
