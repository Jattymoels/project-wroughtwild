# ART-04D — Green source to junction

One isolated scarred root crown, three closed recovered resin pieces and the
existing Green Junction. One travelling crest divides along woody grain.
The crafted Y uses three touching recovered solids with independent attached
scar atlases. Native Green events light each physically clear output. A request
can reach an unwound receiver without creating motion, ingredients or output.

## Inspect the local package

`build/workshop-green/green-handoff/Launch review.ps1` imports and opens its own
Godot 4.5 review and APPDATA. `editable/green-workshop.blend` contains packed maps,
the retained dense source, finished models and editable housing materials.
Generation does not need to run again. Normal game saves and processes are unused.

Keys: **1** source, **2** junction, **3** route, **4** resin, **5** feeder;
**D** day/shade, **G** emission off, **N/M/F** detail; **U** upstream wall,
**J/K** first/second signal walls, **C** cargo wall, **V** forge connection wall;
**Space** review pause, **A** active/away, **R** copied-save reset, **Esc** close.
Buttons use native extraction, collection, requests, Blue hold/resume/cancel,
Green second-branch rewiring, winding and material transfers.

The copied published checkpoint owns 14 carried Green Resin, source lot 1/8,
one historical Green event and one Blue pending request elapsed 0.5/3 seconds.
The winch owns ten wood and one winding, after four earlier trips. The feeder
owns one winding, eight clay, three wood fuel and four earlier bricks. One
release starts both receivers, each paying its own winding. The feeder reserves
eight clay and one wood, then adds four bricks after eight active work seconds.
The 12-second clip follows this actual sequence once, with camera cuts from
junction to cargo route to feeder. Looping the video does not repeat production.

Three displayed pieces represent the claim/carried stack; native counts own
the inventory. A rare-only Faint Preserving claim remains exposed in the
interface after raw collection. Its test occurs in the original remaining
seven lots, without grants, consumed test stock or rewritten outcomes.

## Reproduce

Use fresh output directories. Existing approved dependencies: local TRELLIS
v0.6.0/models, Blender 4.5.9, Godot 4.5, Python/Pillow/NumPy. No new package,
service or third-party asset is installed. Scripts use UTF-8 and LF newlines.

1. `source-prompt.txt` is the exact built-in ImageGen prompt; the original copied
   input is `docs/art/leyline-studies/2026-09-09/workshop-green/green-root-input-v01.png`.
   Run `tools/wroughtwild-grove/generate-source.ps1 -InputImage IMAGE -Output FRESH_SOURCE -Asset rock`.
   Preserve the raw GLB, log and generation metadata: seed 42, 1024 generation,
   2048 textures, frozen runtime/model revision.
2. Set `BLENDER_USER_RESOURCES` to `build/workshop-green/blender-user` before
   every background Blender run. Use `-b --python-exit-code 1 --python SCRIPT -- ARGS`.
   `inspect_source.py -- RAW.glb FRESH_INSPECTION` normalizes uniformly and renders
   front/back/top. `finish_assets.py -- INSPECTION/source.blend RAW.glb FRESH_ASSETS`
   preserves the selected orientation, authors recessed scars, cuts closed resin
   pieces and fits the supported Y. `green.json` explains presentation controls.
   RGBA scar data uses channel-packed alpha throughout export/import; alpha is
   branch identity, never transparency. ORM blue is metallic, green roughness.
3. Reuse verified `build/workshop-art04/native-v02`. To rebuild, use the Red
   recipe's `build-native.ps1` at frozen commit
   `f7253d20ed1dbeee743219190bdaccac60921c1c`. Do not replace the live game DLL.
4. Python `prepare_review.py NATIVE ASSETS FRESH_REVIEW` copies
   `build/lf2/published-b/lf2-green-pending.json`, frozen tuning and existing
   context. `--update` updates only this isolated review. Explicit Godot material
   binding supplies the maps; Blender node animation is not assumed to export.
5. `run-review.ps1 -Project REVIEW -Mode import`, then `check`, `restart`,
   `capture`, `capture -Compatibility`, and `benchmark`. Benchmark without a
   competing generation/capture job. The offline sandbox certificate-store
   startup warning remains logged; every other engine/script/shader error fails.
6. Blender `verify_assets.py -- ASSETS FRESH_EDITABLE` reopens nine exports,
   checks native envelopes, stem/cradle contact, actual stem/branch overlap,
   UVs, closed resin volumes and atlas content, then renders/reopens the packed
   editable source. It checks linear scar data independently of transparency.
7. Python `finalize_evidence.py REVIEW EDITABLE DOCS_OUTPUT` checks native state,
   actual emission/progression pixels in both renderers, each arm's independent
   emission, exact paused pixels and all 96 frames/12,000 ms of the lossless WebP.
8. Python `package_handoff.py REVIEW EDITABLE ASSETS SOURCE FRESH_HANDOFF` copies
   this study and verifies every file against a SHA-256 manifest. Generated meshes,
   Blender sources, native DLLs and engine imports stay under ignored `build/`.

## Limits

The source remains inside 1.5 × 1.1 × 1.5 m. The junction remains inside
0.65 × 1.18 × 0.55 m with the existing shared top anchor at 1.18 m. Both signal
cables leave that anchor; the two visible resin arms do not invent new native
port positions. Exact relative fixture positions retain the 14 m cargo span and
8.2462/11.1803 m Green output spans.

Actual signal rays, a 0.3 m basket sweep, a 0.045 m feeder connection sweep and
receiver/forge ground probes determine review clearance. Removing the review
ground blocks both receivers. Ordinary placement, walking and streaming still
belong to ART-05. The review floor is composed context, not saved geography.

The generated host is an exterior mesh, not a certified geological solid.
Only recovered pieces have checked closed volumes. Their new faces infer cloudy
olive resin: per-texel nearest source triangle and barycentric UV transfer retain
outer bark/scars, while exposed interior receives documented resin colour and
roughness. Each piece has its own tangent normals. This is asset authoring,
not a simulation of cutting wood or an extra inventory material.

Near/mid/far sources use 35,999 / 15,999 / 7,999 triangles. The whole junction is
1,998 triangles across four surfaces: 1,380 housing + 618 resin. It retains this
small geometry at all three exports. Individual resin pieces use 190/184/244
triangles and 1k atlases; source/housing use 2k. These are handoff levels, not a
world budget. Texture cooking, lower-spec tests, streaming and normal-world
adoption remain later. White/Blue, lever, winches, feeder, forge and grove are
existing context; their base visuals are not remade by this slice.
