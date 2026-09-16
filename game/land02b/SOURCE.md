# Scarwater production sources

Selected runtime art for LAND-02B; no harvest stock is defined here.

## Gallery assembly

An isolated grey-barked living trunk with broad buttress roots and an irregular
fork was generated using the built-in image tool. It was an asset input, not a
landscape extraction. Retained input:
`D:/Wroughtwild/work/land02b-scarwater-art/build/land02b/input/root-trunk.png`
(SHA-256 `b74007c0c821e17862178d5a691dc76e49d4ba99037822ad63a0cca56791519c`).

Actual local conversion: TRELLIS CLI v0.6.0, model revision
`a57397bd3d351599d9729fc144b3f87c3f87d65b`, resolution 1024, seed 42, required
GPU 0, BiRefNet background removal, WebP off, eight threads. Existing installed
models were reused. Exact arguments and successful exit are retained in
`build/land02b/trellis-root-v1/generation.json`.

Raw source:
`D:/Wroughtwild/work/land02b-scarwater-art/build/land02b/trellis-root-v1/source.glb`
(SHA-256 `65f507d4f7d5addb205e8f1c19fa4de6a33e4981a3c2d445167582b164591e5a`).
The 296,264-triangle result supplied useful bark and buttresses, but contained a
detached upper branch and did not supply a living crown. Front/rear Blender
inspection at real scale informed those specific corrections.

`tools/wroughtwild-land02b/inspect_root.py` normalises the actual source to a
7.5 m bole and retains the inspected candidate. `build_gallery.py` welds glTF
UV-chart duplicates for component analysis, removes the detached component
(9,015 vertices), narrows/reduces the bole and authors attached branches,
asymmetric crown lobes and leaves. An in-game revision deepened the crowns and
added lower side growth. A close game capture exposed floating branch caps and
vertex-colour darkening: branches now sample the actual bole surface, bury their
small starting caps between its front/back intersections and use white vertex
colour under the bark map. Blender validation removes three duplicate faces
from each reduced bole and contact before export; the diagnostic log is retained.
Final exports have 146,640 and 122,088 triangles before
Godot imported LODs; those counts are not a quality/performance threshold.

Editable packed master:
`D:/Wroughtwild/work/land02b-scarwater-art/build/land02b/source-art/gallery-production.blend`.
Inspected starting master: the same directory's `root-candidate.blend`.
Both are retained with raw GLB, input, inspection images and recipes.
`source.json` records the selected exports. Reduced contact GLBs represent solid
root/bole form without leaves or embedded textures.

`textures/gallery-bark.png` is a separately generated, seamless unlit grey-brown
olive bark base colour, approximately one metre around by two metres along the
branch. Authored UVs follow each branch's length; this avoids projection seams
across the branch hierarchy. Godot's extracted images beside each GLB are the
selected import dependencies. The GLBs and packed master retain the input maps.

## Mineral and editable geology

`textures/fractured-limestone.png` was generated using the built-in image tool:
a seamless neutral unlit grey limestone material with restrained ochre seams,
no horizontal striping or scene illumination. The retained selected map is the
runtime input. World-space triplanar mapping, broad weathering, roughness and
filtered relief are shader-controlled.

The ridge and fissure are directly authored mathematical/native forms, not a
generated shell. Editable recipe: `sim/src/worldgen_frontier_v10.inc` with
`data/tuning/worldgen-frontier-v10.json`; extraction recipe:
`game/extensions/wroughtwild_sim/src/terrain_density_vertex.inc`.
Existing LAND-02 underwood/ground accents are reused where they suit the scene.

Actual game materials, lighting and player-height pictures decide selection.
The generated input, polygon count and Blender preview were not treated as
finished environment quality. Owner playtesting remains deferred.
