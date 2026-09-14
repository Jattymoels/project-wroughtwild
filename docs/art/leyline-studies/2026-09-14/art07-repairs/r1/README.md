# ART-07R1 — restore broad canopy silhouettes

Status: ready_for_integration candidate. Technical checks and full manifest verification passed.
Owner visual acceptance: pending. Ordinary-world rollout: outside scope.

The v03 candidate restores B1 broadleaf/pine crown spread by fitting lower source
wood to the unchanged native body and blending back into the crown. It keeps the
existing G1 LOD2 choice and source heights. C4's existing ash fit is retained.
No native game, data, save schema, visibility distances, scatter or loading-cache
policy is changed. Ordinary-world rollout is outside this repair.

## Measured source and lower fit

G2 reported 289 wood instances at horizontal scale 0.2694963 and 32 pines at
0.1313987, both with vertical scale 1. R1 reproduced the whole-tree squeeze from
the delivered meshes before authoring. The CPU glTF calculation differs from the
live pine scale by about 0.000002 because of transform precision; runtime camera
reports retain actual live scales. This table is source-axis geometry after the
unchanged burial, not a projected foliage-coverage measurement.

| Selected export | Delivered crown X x Z | R1 crown X x Z | Triangles, unchanged | Total height, unchanged |
| --- | --- | --- | --- | --- |
| broadleaf LOD2 | 2.236 x 1.673 m | 8.176 x 6.209 m | 65,232 | 8.259 m |
| pine LOD2 | 0.852 x 0.758 m | 6.120 x 5.770 m | 69,637 | 9.144 m |

The lower visual radius is <= 0.343 m through 2.6 m. A smooth transition reaches
source crown spread at 4.2 m; attachment corrections taper to the original tips.
The unchanged player capsule is radius 0.42 m, height 1.92 m, with eye height
1.68 m above its feet. Native broadleaf/pine walk-width remains 0.7 m. C4 remains
0.6 m wide with a 2.6 m body; its measured lower visual radius is 0.268 m.
The C4 crown remains about 1.277 x 1.396 m. All source burial and Y extrema remain.

Two fresh packed-master copies and every one of the 19 exports passed finite
geometry, degenerate-triangle, lower-radius and attachment checks. This includes
15 crown LODs and four root/stump exports. Leaf-root and branchlet contacts remain
within the original B1 13 mm / 26 mm assertions. All decoded embedded maps and
triangle counts match the original exports. Each selected crown uses two 1024 x
1024 maps. Exact texture bytes, source hashes, bounds and per-LOD geometry appear
in [export-geometry-and-maps.json](export-geometry-and-maps.json).

The selected masters retain 30 original broadleaf meshes and 20 original pine
meshes, their UVs and all 11 original packed image records. The additional scar
mask was initially dropped as unused during Blender save; it has been restored
from its exact verified source bytes and retained explicitly. The changed masters
are fresh `v03/models-packed-v2` copies. All 19 tested GLB bytes are unchanged by
this container repair. The handoff uses these selected master copies.

Real altered-mesh lower/upper sections were measured in all three LODs.
[The scar audit](source-and-scar-audit.json) records nearest-surface separation
from the quiet sibling, with the limitation that independent decimation prevents
calling this exact signed incision depth. Actual emission-off model views are
required for visual assessment.

## Native and saved-world evidence

The B1 flow passed 39 checks before and after, preserving 14 wood and 14 pine.
Separate partial/final restarts passed 30 checks each. The C4 flow passed 59 checks
and its separate partial/final restarts passed 46 each, preserving 28 ash wood.
The added isolated support floor belongs only to the movement fixture. Actual
controller movement stops at the original body, walks past below the crown and
stays grounded. Target rays use the native surface, and the crown adds no collider.

Both full no-grants paid workflows passed all 865 original assertions and walked
135.078 m with native input. Both fresh-process paid restores passed their eight
original assertions. Gathering/address selection remains harness-paced as in G1;
this is not a continuous human first-hour playthrough.

The complete retained probe matches across all 13,627 finite resource records,
full ownership and geography. The geography SHA-256 is
`550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70`.
The initial paid snapshots are also identical. The paid/final raw snapshots differ
only in one newly created forge's engine-generated scene name:
`@StaticBody3D@4310` / `@StaticBody3D@4311`. The native key
`station_forge_basic_474500_31000_447500`, built ownership, pose, rotation, upgrade
and every other saved field are equal. This raw difference is retained, not called
byte equality. No original native assertion or save code was changed.
See [ownership-equivalence.json](ownership-equivalence.json).

## Scope and source lineage

Worktree: `D:/project-wroughtwild-art07-r1`, branch `codex/art07-r1`, inspected base
`473ae7604b3841899c29629cf59f8836ed528424`. Wave 1 has no candidate predecessors.
The runtime remains `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`, with G1 manifest
`fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd`.
All original package contents were fully hashed before consumption. Publication
ancestry uses the checked main cherry-picks, not unmerged original worker tips.
The owner checkout, peer worktrees, ordinary saves and running jobs were preserved.

The only existing runtime edit is `G1Art.resource`: select `r1/native_tree` for
B1 wood/pine, retain its family choice and `b1` owner metadata. The R1 adapter
replaces the per-instance whole-tree squeeze with unit-scale pre-fitted meshes.
New review scenes are isolated under `game/r1/`. R2/R8 must reconcile resource
selection/loading overlap in that one function. R7 owns composition. Existing B1/C4
exit-leak diagnostics are retained; R4 owns cleanup work.

The selected recipe, controls, tolerances and reconstruction commands are in
`tools/wroughtwild-art07-repairs/r1/README.md` and `settings.json`. The final
receipt records the exact package manifest and checked commit SHAs.


## Actual visual evidence

The actual [Forward+ model pairs](forward_plus-canopy-pairs.jpg) and
[Compatibility pairs](gl_compatibility-canopy-pairs.jpg) show the restored spread.
Every supplied crown LOD is in the [Forward+ sheet](forward_plus-all-lods.jpg) and
[Compatibility sheet](gl_compatibility-all-lods.jpg). The broadleaf retains heavy,
blunt branch ends, pronounced lower-trunk flare and sparse foliage at LOD2. Both
renderers read dark in shade; Compatibility has a brighter bark/shadow response.
These source-art limits remain for owner assessment. Dimensions alone do not close
G2-V01. The altered trunk recess remains visible with emission off in
[Forward+](forward_plus-scar-off-on.jpg) and [Compatibility](gl_compatibility-scar-off-on.jpg).

Matched world sheets: [Forward+ home](forward_plus-home-player-height.jpg),
[Forward+ route](forward_plus-route-player-height.jpg),
[Compatibility home](gl_compatibility-home-player-height.jpg), and
[Compatibility route](gl_compatibility-route-player-height.jpg). Each has day,
shade and dusk rows, before/after columns. They show wider overlapping crowns at
unchanged native positions. All cameras are 1.68 m above actual rendered support,
1440 x 900, FOV 60. Home eye is `(468.5,32.68,431.5)`, target
`(460.5,33.69,445.5)`; route eye `(447.5,32.68,394.5)`, target
`(447.5,32.68,384.5)`. Pine eye is `(288.5,51.68,11.5)` and C4 eye
`(27.5,45.68,216.5)`. Before/after and both renderers have identical camera records.

Day/shade/dusk are controlled inspection presets: native mood, sun energy x0.12
for shade, or x0.35 and `d9bd91` for dusk. They do not add a world day/night cycle.
Final studio pairs use the symmetric camera `(0,6.5,24)`, target `(0,3.5,0)`, FOV 52.

| Camera, both renderers | Bounds before / after | Overlap pairs before / after | Median matched B1 width before / after |
| --- | ---: | ---: | ---: |
| Home | 108 / 114 | 250 / 895 | 2.594 / 9.528 m |
| Route | 55 / 57 | 38 / 180 | 1.099 / 8.007 m |
| Pine | 2 / 2 | 0 / 1 | 1.077 / 7.860 m |
| C4 regional view | 4 / 5 | 0 / 2 | C4 unchanged; background B1 crowns widen |

Widths follow the labelled camera's right axis. Only boxes entirely in front of
the camera are projected; overlaps are clipped AABB intersections, not opaque leaf
coverage or a resource census. [view-comparison.json](view-comparison.json) retains
per-resource widths, unchanged poses/bodies/visibility and overlap totals.

Lower geometry from 0 to 2.6 m is separate from the crown table above. Broadleaf
X/Z spans change from 0.943/0.945 m to 0.669/0.662 m; pine from 0.609/0.608 m to
0.666/0.673 m. The old fit used only the 0.6-1.9 m band, leaving wider projections
above it. C4 lower spans remain 0.392/0.480 m. Full min/max bounds are in the JSON.

Actual motion: [native Forward+ fall](forward_plus-native-fall.webp),
[Compatibility fall](gl_compatibility-native-fall.webp), and
[native input/controller route](native-route.webp). Fall playback uses recorded
physics-frame intervals. [Scar playback](forward_plus-scar-pulse.webp) steps the
existing shader clock at 12 Hz on the actual model; it is an illustrative effect
preview. No interpolated or generated scene frames are used. Original paths,
hashes, dimensions, pacing and presentation operations are retained in
[image-provenance.json](image-provenance.json).

## Isolated cost measurements

Actual machine: Ryzen 9 9950X3D (16 cores / 32 logical processors),
33,446,744,064 bytes RAM, NVIDIA GeForce RTX 5090 selected by both renderers;
Godot 4.5 stable (`876b29033`), Blender 4.5.9 LTS. Settings are 1440 x 900,
4x MSAA and VSync off. Each of four cameras and three lights has 120 settle frames
and 300 measured frames: 3,600 per mode/renderer, 14,400 total. Timing processes
perform no image writes, asset imports or model generation. Full light/view
aggregates are in [performance-comparison.json](performance-comparison.json).
These are single current-machine runs, not minimum-hardware acceptance.

Daylight subset, milliseconds:

| Renderer / view | Before wall p50 / p95 / worst | R1 wall p50 / p95 / worst | Before / R1 GPU p95 |
| --- | ---: | ---: | ---: |
| Forward+ / home | 3.353 / 3.816 / 4.900 | 3.421 / 3.863 / 4.041 | 1.909 / 2.427 |
| Forward+ / route | 2.657 / 3.023 / 3.210 | 2.716 / 3.180 / 3.944 | 1.411 / 1.645 |
| Compatibility / home | 5.958 / 6.730 / 7.824 | 6.057 / 6.915 / 8.183 | 3.375 / 3.925 |
| Compatibility / route | 4.491 / 5.023 / 5.522 | 4.815 / 5.475 / 6.054 | 1.402 / 1.544 |

At home/day, Forward+ loaded textures are 1,307.77 -> 1,313.11 MiB and buffers
210.02 -> 209.87 MiB. Compatibility textures are 1,288.49 -> 1,288.49 MiB and
buffers 207.82 -> 207.67 MiB. These backend totals include caches and non-geometry
buffers. Forward+ draw calls rise 1,128 -> 1,147 and visible primitives
6,974,387 -> 8,211,567 with wider crowns. Compatibility calls are 3,498 -> 3,580;
backend pass counts are not directly interchangeable. Full allocations are retained.

Selected broadleaf GLB is 11,689,044 bytes (source 11,477,088); pine 12,812,132
bytes (source 13,108,220). Both retain their two original 1024 x 1024 maps and
triangle counts. Serialization/vertex welding changes file sizes without adding
triangles or replacing maps.

Separate streaming runs follow the same 135.078 m native input route:

| Renderer / mode | Frames | Wall p50 / p95 / worst, ms |
| --- | ---: | ---: |
| Forward+ / before | 3,945 | 3.875 / 9.890 / 751.030 |
| Forward+ / after | 4,618 | 3.659 / 7.723 / 758.704 |
| Compatibility / before | 2,564 | 6.707 / 22.871 / 752.281 |
| Compatibility / after | 2,793 | 6.660 / 10.824 / 746.937 |

Loading hitches around 0.75 seconds remain. R2 owns cache/streaming policy.
Different frame counts and single-run variance prevent calling lower p95 values
proof of a general improvement. Route and native checks pass in every run.

## Retained diagnostics and remaining limits

The Blender multiple-image-node sampler warning is retained. The additional
[material audit](material-bindings.json) passes for all 19 exports: material
properties, decoded image bindings, sampler settings and triangle totals by
material match the source. Names/order may differ. B1 before/after and C4 flow
retain ObjectDB exit warnings; Compatibility retains its unsupported-SSAO warning.
No diagnostics are suppressed.

Rejected v01/v02 geometry attempts, unused-mask preservation failure, initial
studio parse error and non-finite first world cameras remain in the evidence
history. Final packed-master reopens and final `v02` camera outputs provide the
selected evidence. No receipt or output was relabelled as a new run.

Owner visual acceptance remains pending for the visible source-art limits above.
Signed incision depth is not established from independently decimated mesh-distance
measurements. Raw paid snapshots retain the disclosed generated forge-name
difference; every other saved field and all original native assertions match.
No missing body, seat or geography decision blocks this candidate and no such rule
was invented. All 273 legal pairs passed unchanged assertions in both renderers.

Final aggregation passed 596 checks against 56 actual recorded process receipts.
This includes nine parse checks and the four earlier exit-zero captures explicitly
rejected as visual evidence; only final v02 world/studio captures are selected.
The aggregation and real-frame encoding jobs also exited zero with fresh private
paths. The 15 final review artifacts include two 44-frame native falls, two
48-frame scar previews and a 78-frame native route. All derived media hashes were
verified. [visual-review.json](visual-review.json) records the candidate inspection
without claiming owner approval.

## Sealed candidate

Package: `D:\project-wroughtwild-art07-r1\build\art07-repairs\r1\v03\handoff`. Manifest SHA-256:
`9c0cd855d03cd5d88df1823538417da776775abd96a732eb7ad94f24a1f02c7e`. Exact manifest file set: 5,940 files,
5,622,031,314 bytes (manifest itself excluded from those totals).
The full size/hash/file-set verifier passed during sealing. The package includes
selected masters in `models/`, runtime delta in `changes.json`, original source
frames in `engine-evidence/` and all 15 encoded review artifacts in `review/`.
The receipt is outside the sealed package. Integration and push are publisher work.
