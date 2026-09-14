# ART-07R2 measurement method

The unchanged comparison is `v01`, prepared and fully hashed from the pinned G1
companion. `v02` is a diagnostic copy with inclusive timing wrappers around the
original method bodies. `v03` is the R2 candidate, prepared independently from the
same common runtime. None starts from a peer repair or a newer game/data revision.
The benchmark derivative is generated from the same original G1 `review.gd` in
all three versions; every original camera, resource selection and assertion stays.

## Timing boundaries

- Import is a separate fresh editor process. Its runner wall duration is not a
  startup/setup sample and is not mixed into the min/median/max setup tables.
- Setup is the engine clock through initial world creation and the paid checkpoint
  restore, before per-view terrain/resource focus and warmup. The world construction
  and restore spans are also retained. A runner's whole-process wall duration is
  longer because it includes all later camera measurements and shutdown.
- Each already-imported startup is a fresh process with fresh private user paths.
  These are process-cold observations, not a claim that Windows file caches or
  global GPU driver caches were flushed or that the device was rebooted.
- The synchronous first-focus call and every one of the following 120 warmup wall
  intervals are retained separately per camera/light. Their maxima expose first-use
  stalls instead of hiding them in a settled median.
- Each of four paid-world cameras has day and dusk observations: 300 settled wall
  intervals after those 120 warmup frames. Raw intervals and min/median/max across
  fresh processes remain available, along with p95 and worst-frame values.
- Traversal uses the original G1 input/controller route and its existing 45-physics-
  frame settling period. Process wall intervals are recorded only while that input
  is held. It has no capture calls enabled. This is separate from camera sampling;
  traversal maxima are not described as settled frame costs.
- Matched visual/geometry capture uses separate processes at a fixed 60-frame
  presentation cadence. It is never included in benchmark timing. Actual source
  state/motion captures likewise are technical/visual evidence, not performance runs.

The cost comparison includes three fresh art-on and three fresh art-off processes
per backend both before and after. Pairing is by the same paid checkpoint, trial
index, camera, lighting, viewport, resource IDs and chunk count. The groups were
collected sequentially, not randomly interleaved. Original groups, candidate art-on,
and later candidate controls are identified by their actual log timestamps. No
other imports, art generation, captures or engine/compiler processes may overlap
an accepted benchmark; the unchanged runner records the process checks and mutex.

## Actual settings and hardware

Both Forward+ and Compatibility use 1440 x 900, 4x MSAA, vsync disabled, max_fps 0,
120 warmup and 300 settled samples per camera/light. Every report records the engine,
backend, API, adapter, CPU and OS. The initial machine is NVIDIA GeForce RTX 5090 /
AMD Ryzen 9 9950X3D / Windows 10.0.26200, using Godot 4.5 stable official
`876b290332ec6f2e6d173d08162a02aa7e6ca46d`. Forward+ reports Vulkan 1.4.325;
Compatibility reports OpenGL 3.3.0 NVIDIA 591.86. This is not target-device or
minimum-hardware acceptance. No minimum budget has been invented.

## Resource accounting

The renderer reports total loaded texture, buffer and video allocations. These
are actual backend counters, not PNG file lengths. Buffer bytes include internal
renderer buffers and caches as well as geometry. The comparison also preserves
G1's unique live-scene mesh/triangle counts, including hidden resource stages and
MultiMesh references, without multiplying shared base geometry by instance count.

The separate capture inventory expands that geometry union with retained B3 source
meshes and the explicit AuthoredAssets, D1-D3, E1-E3, G1 cover and C6 LOD caches.
It records the unique base vertices, triangles, surfaces and meshes reachable there.
Alternate importer index-LOD triangles are not added to the base-triangle count;
backend buffer allocations separately include renderer internals. Every captured
resource records its exact ID, pose, stock, work and each visible or hidden part's
transform and complete surface-array digest. Per-process auto-generated node-name
counters are excluded from comparison; all ordered actual part data is compared.

The scene-material texture path/size/reference inventory is an attribution aid,
not an enumeration of every renderer-owned texture. The loaded allocation counters
remain the authoritative total. Disk accounting is independent: 1,221 PNG files
form 398 exact byte groups, giving 823 redundant copies / 1,061,048,169 redundant
disk bytes. Only 723 duplicates also match every import parameter and are eligible
for aliasing. All original PNG files remain in the candidate. No disk-byte count
is presented as predicted GPU savings.

## Attribution and scope

The unchanged diagnostic Forward+ setup was 92.682 seconds: 52.356 seconds in world
construction and 37.931 seconds in paid restore. The largest inclusive span was
B3 `reproject`: 68.63 seconds over 366 calls. B1 `_apply_visual` was 12.74 seconds
over 804 calls. Existing scene/texture loads and other material creation were much
smaller. These nested inclusive spans overlap and must not be summed. The
uninstrumented repeated `v01` runs, not this one diagnostic run, are the performance
comparison baseline.

The diagnostic process also recorded the following inclusive spans. These cover
its setup and subsequent view/focus work; repeated cached lookups count as calls.
All raw load paths and counters remain in the v02 report.

| Original method/resource | Calls | Inclusive seconds |
| --- | --- | --- |
| B3 `reproject` | 366 | 68.630 |
| B1 `_apply_visual` | 804 | 12.740 |
| G1 colours `add_model` | 5 | 1.126 |
| C6 `mesh_for` (mostly existing cache hits) | 856,814 | 0.895 |
| B3 `own_materials` | 2,188 | 0.306 |
| G1 materials `material_for` | 256 | 0.039 |
| C6 `material_for` | 134 | 0.001 |
| B1 broadleaf far-scene `load` | 718 | 0.373 |
| B3 full/worked/remnant scene `load`, each | 625 | 0.301 / 0.221 / 0.205 |

The hidden stages and near/far caches are retained and inventoried. Their removal
was not used to produce the improvement. Texture allocation changed through exact
resource reuse; the final complete shader-input cache keys prevent that sharing
from conflating different colours, ORM maps or work presentation.

R2 keeps B3 terrain results only for one synchronous projection, using the exact
Float64 query coordinates and original reference height/reach. Its differential
check repeatedly replaces the surface sampler, including supported and cut-out
surfaces, and compares every vertex/normal/UV/index array and the native grounded triangle picking faces, pose, enabled state and masks against the unchanged G1 adapter. B1 caches only the unchanged
radius result for a fixed source kind/burial; per-instance materials and work remain
separate. Equivalent textures retain their original PNG bytes, complete import
settings and material colour-space declarations. Complete material cache keys
retain tint, ORM and other actual shader inputs after sharing texture objects.

Source review replays are additive copies of the original scripts. Changes are
unique evidence output paths/directory setup and 1440 x 900 inspection dimensions;
an inverse-substitution check verifies all original assertions and logic remain.
The full-world paid and Living Frontier checks inherit their original scripts
and configure 1440 x 900, 4x MSAA and vsync off before the deferred original flow.
Those checks use Forward+ and fixed 60-frame inspection cadence, not the dummy
headless renderer and not benchmark timing.
Original source reports are not overwritten. G1 paid acquisition is harness-paced,
while actual route movement uses the native controller. Other source inspections
may explicitly supply stock or time-step native work; their original scope labels
are retained. None claims a continuous human first-hour play session.

The new cost summary uses the ASCII range separator ` to `. The sealed G2 report
and its original encoding remain untouched. There are no new presentation tuning
values, body/seat/geography decisions or ordinary-world rollout changes.

## Reload comparison oracle

Reload checks use the exact original G1 post-restore snapshot, not raw numeric
Variant types or a pre-restore engine-generated name. JSON roundtripping normalizes
only persisted number types. Every value of `sim`, `leylines`, `contraptions`,
`blocks`, `stations` and `resource_nodes` is compared, and the geography JSON hash
is checked separately. Actual partial/exhausted saves come from native work in
private user paths. Original source assertions remain inherited.

The successful flow allows actual rendered frame boundaries between visits.
The separate immediate-retirement stress attempts remain failed diagnostics.
Three cycles expose initial cache growth and subsequent allocations; they are
not a long-duration residency budget. See `CHECKS.md` and `DIAGNOSTICS.md`.
