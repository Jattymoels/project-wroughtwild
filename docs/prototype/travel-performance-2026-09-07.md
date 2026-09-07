# INT-07D — Smoother travel through the same frontier

Status: implemented; owner review pending.

## Approved outcome and scope

The owner's “Yep keep going with optimisation” accepts investigation and repair
of the rendered travel spikes left by INT-07B. Preserve terrain, finite resource
state, scenery detail, streaming distances and save compatibility. D-010,
D-013 and D-032 remain authoritative; no generation or gameplay rule changes
are proposed. Combat calibration and the known timber-demolition issue remain
outside this work item.

## Small implementation plan

1. Preserve `2500db8` and its native library in an isolated review directory.
   Use the existing 1440×900, 120 fps, 5 m/s route with common diagnostic test
   code to attribute slow frames to actual work.
2. Remove the measured unnecessary work or bound its publication while
   preserving the same geometry, collision and finite-resource state.
3. Compare matched rendered runs and exact presentation/state fixtures; run
   affected historical, streaming, harvest and save checks.
4. Record results and limitations, commit and ordinarily push to `origin/main`.

Affected systems are Godot's terrain/resource streaming and scenery assembly.
Existing tuning lives in `game/art/strange_stream.gd` and the material/landscape
art resources; the first measurement introduces no production tuning changes.
The investigation assumes visual output can remain identical. A missing design
decision that would change that contract will be reported before dependent work.

## Implementation and diagnosis

Three bounded changes implement the existing behaviour:

- Resource nodes prepare their common material's emission feature at creation.
  Cold nodes use zero glow energy; hover, heat and cooling change uniforms while
  retaining the existing colours and cracked tint. Each node owns its material.
  The five rare-resource shader presentations keep their existing effects.
- ResourceStream retains one PackedScene after its first runtime load. A direct
  script preload was rejected during verification: the terrain-only entry path
  exposed a ResourceNode → Terrain → ResourceStream dependency cycle. Loading
  lazily fixes that entry path while keeping subsequent arrivals cached.
- Leyline assembly batches the same six unindexed vertices per quad. Ground
  samples, row order, normals, colour/UV values, topology, materials, gaps and
  cache invalidation remain identical. No new rendering or gameplay tuning.

The first two full baseline journeys reproduced 56.411 ms and 53.132 ms frames.
Frame attribution isolated approximately 49.9 ms of the latter to renderer
preparation, while the Terrain callback took 0.005 ms. Pipeline compilation
counts did not change on that frame. A diagnostic run disabling hidden HUD
processing removed that excursion. Normal HUD processing was restored for all
matched final runs; the final baseline identifies the hovered resource as
`wnv6_tree_537_29_514`, at roughly 30.6 m along the route. Keeping the emission
feature prepared removes this interaction-triggered renderer pause.

Godot's [4.5 renderer source](https://github.com/godotengine/godot/blob/4.5/servers/rendering/rendering_server_default.cpp)
places scene and dirty-material work inside the measured preparation interval;
its pipeline counters are not a complete account of shader-feature work.
The attribution above is based on the local timings and controlled comparisons.
No engine patch or renderer-setting change was needed.

## Verification and evidence

`build/travel-performance` is isolated from normal user saves and the earlier
INT-07B/C baselines. The preserved production reference is `2500db8`; its 553
non-test source/asset/DLL files match the archive exactly. The other 89 import
text descriptors differ only in engine-normalised line endings. Native library
SHA256 remains `a60442947833049ebbff7b715036b53679d571414a13f929b92bb1ecf5f24de6`.

`resource_presentation_review` compares 94 native specimens across all present
visual/biome categories, five states each: initial, hovered, heated, cracked and
hovered, and cold again. All **470** geometry/collision/effective-material hashes
match the preserved game. Every serialized finite source record is unchanged.
The serializer comparison deliberately treats the loaded node's StringName
item ID like the source definition's String ID, as the actual save does.

`leyline_mesh_equivalence` compares all **155** V6 seed-1 tiles, including 96
nonempty tiles. Every vertex/normal/colour/UV array and all branch, exposure and
fragment metadata match exactly. Tile assembly total falls from 241.597 to
198.877 ms in the sequential complete-network CPU probes (17.7%); median nonempty
tile 2.233 → 1.873 ms, p95 4.480 → 3.778 ms. This CPU probe supplements the
rendered route and is not an FPS claim.

Useful evidence directories below `build/travel-performance/captures`:

- `baseline/frontier_v6-1-attribution-a` and `-attribution-b`: diagnosis.
- `baseline/frontier_v6-1-no-hover`: diagnostic variant, excluded from final comparisons.
- `baseline/frontier_v6-1-resource-equivalence-final` and
  `current/frontier_v6-1-final-regressions`: resource-state oracles.
- Each phase's `frontier_v6-1-leyline-final`: exact tile oracles and final sequential CPU probes.
- Each phase's `frontier_v6-1-final-a` / `frontier_v6-77-final-a`, plus `current/frontier_v6-1-final-b`: matched routes and daylight/dusk captures.

The new common fixture observes `Terrain._process` by calling its unchanged
production implementation. It stores at most 6,000 frame rows in memory, then
writes them after the 30-second sample. Last-phase timing is explicitly stale
on idle frames. Process/physics engine monitors are sampled values; the direct
Terrain and renderer timers provide per-frame attribution. The separate 32-call
stationary focus probes run after all timing windows and captures.

## Matched rendered results

Final evidence uses unchanged fixture/settings and ordinary HUD callbacks. The
seed-1 repeat includes the final lazy scene-retention correction. No benchmark
ran concurrently with another benchmark or heavy regression process.

| Route / version | World setup ms | Frame median ms | Frame p95 ms | Worst frame ms | Worst renderer preparation ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Seed 1, preserved final-a | 5,395.031 | 8.236 | 8.635 | 36.435 | 33.313 |
| Seed 1, updated final-a | 5,425.999 | 8.245 | 8.641 | 21.269 | 0.228 |
| Seed 1, updated final-b | 5,335.800 | 8.234 | 8.630 | 20.554 | 0.189 |
| Seed 77, preserved final-a | 5,211.002 | 8.248 | 8.633 | 34.932 | 31.314 |
| Seed 77, updated final-a | 5,134.218 | 8.250 | 8.622 | 18.243 | 0.183 |

The final worst-frame reduction is **43.6%** on seed 1 and **47.8%** on seed 77.
The 120 fps cap keeps ordinary median/p95 frame times effectively unchanged;
there is no claim of a doubled ordinary frame rate. World-setup differences are
within 2%. Settled draw calls and primitive counts match per seed: 1,380 /
3,659,905 for seed 1, and 1,323 / 3,691,623 for seed 77. Daylight/dusk images were
inspected at the matched seed-1 camera positions; the exact state/mesh probes
provide the stronger geometry and material-output comparison.

Rolling history-refresh samples on seed 1 improve from p95 7.222 / max 16.865 ms
to p95 6.383 / max 14.686 ms. These rolling per-stage windows may retain setup
samples, so they are kept separate from individual route-frame attribution.
The pending-terrain frame p95 is effectively unchanged (9.314 → 9.311 ms);
frame/refresh alignment still varies. Matched world setup and whole-route /
settled median and p95 metrics remain within the 10% regression threshold.

## Automated checks

| Fixture / profile | Passing checks | Contract exercised |
| --- | ---: | --- |
| Resource highlight | 264 | Cold/hover/heat/quench states, exact glow/tint, neighbouring material independence and unchanged stock/work. |
| Resource presentation, V6 | 2 plus 470 matching state hashes | 94 generated specimens; every serialized finite source record retained. |
| Leyline equivalence, V6 | 2 plus 155 matching tile hashes | Full network geometry and metadata identical. |
| Trace surface cache, V6 | 27 | Unrelated arrivals, sampled retirement/return, excavation and building suppression. |
| Terrain preparation, V6 | 90 | Staged/synchronous equivalence, hidden incomplete chunks, collider publication and interrupted preparation. |
| Wide terrain stream, V6 | 75 | Real collision, bounded retirement/return, edited seams and saved partial/depleted resources. |
| Faceted terrain | 66 | Physical mesh support and excavation. |
| Weathered save | 21 | Historical geography and saved presentation/state restoration. |
| Cataclysm intensive | 170 | Generated history, grounding, population and saved identity. |
| Interaction feedback | 417 | Real gathering, rare resources, native collection and silent restore. |
| Terrain stream intensive, V3/V2 | 57,897 | Eager/streamed historical entry, exact horizon, terrain/cover lifecycle and repeated creation. |

Historical V5 also passes **75** wide-stream, **27** cache-invalidation and
**90** staged-preparation checks. Final Godot import and script checks pass;
`git diff --check` is clean. There are no new dependencies or tuning values.
Initial failed diagnostic fixtures are retained in the logs: the test method
name conflicted with its inherited method, then direct Variant-container
comparison treated StringName and String IDs differently. Correcting the oracle
to compare the actual serialized records resolved that mismatch in both the
unchanged and changed game. No existing assertion was relaxed. The genuine
scene-preload cycle was corrected in production and its failing entry fixture
then passed all 57,897 checks.

Reproduce with `tools/world_performance_checks.ps1 -ReviewSuite travel`, using
`-Phase baseline` for the separately preserved `2500db8` copy, `-Prepare` for the
current copy, and `-Scenes travel_performance_review -Rendered` for frames.
`-Seed 77` selects the second timed route. Correctness fixtures derived from
`wide_terrain_stream` deliberately use their fixed seed 1. Use
`tools/compare_travel_presentations.py BASELINE CURRENT --kind resources` or
`--kind leylines` to reject any missing, additional or changed IDs/hashes.

## Remaining limits

These are scripted journeys on the RTX 5090 host, Godot 4.5 Forward+, at
1440×900, FOV 75, 1.65 m eye height and a 120 fps cap. The ordinary terrain,
resource, biome and hidden-HUD callbacks stay active; player/combat physics and
the world clock are disabled. The native region[0] approach supplies 150 metres
at 5 m/s. No gameplay difficulty or physical walking claim follows from them.
Processes and user-data directories are isolated, but shared driver caches are
not erased between runs. Setup time is world construction, not the whole
application launch or a guarantee about first-ever shader compilation.

Median/p95 frames remain near the frame cap. Terrain collision publication,
resource materialisation and remaining leyline refresh still create occasional
long frames. A future bounded slice can spread that work over frames while
preserving collision-before-publication, synchronous restore safety and the
same detail distances. Larger worlds, new content and combat-number calibration
remain separate. Human play/visual comfort and lower-end hardware need later
review.
