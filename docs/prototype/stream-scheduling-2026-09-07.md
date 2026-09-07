# INT-07E — Spread nearby loading work across frames

Status: implemented; owner review remains deferred.

## Approved outcome and small plan

The owner's “Perfect, continue” accepts the next measured optimisation after
INT-07D. Keep the same frontier, materials, streaming distances, finite sources
and save contract while reducing remaining terrain/scenery arrival bursts.
D-010, D-013 and D-032 remain authoritative. Combat calibration, generation
expansion and the timber-demolition conflict remain separate.

1. Preserve `e370970` and the existing native DLL under the separate
   `build/scheduling-performance` directory. Measure the same seeded rendered
   travel routes used by INT-07D, with common diagnostic fixtures.
2. Separate terrain collision preparation from publication. Queue only cosmetic
   leyline refreshes after streamed arrivals and share the existing terrain
   work slots; keep synchronous safety and explicit edit/build/load refreshes.
   Bound ordinary resource creation by elapsed work as well as node count.
3. Check complete output against synchronous/preserved oracles, interruption,
   collision, finite work and save restoration; compare matched rendered runs.
4. Record evidence and limitations, commit and ordinarily push to `origin/main`.

Affected systems: Terrain, TerrainChunkStream, CataclysmSites and ResourceStream.
Scheduling values belong to `game/art/strange_stream.gd` / `.tres`, with a plain
purpose for each. Simulation, world profiles and save schema do not change.

Assumptions: non-colliding leyline tiles can follow distant terrain publication
by a few frames; ground collision, resource grounding and ruin collision retain
their immediate handoff. Pending cosmetic work is bounded by existing tiles,
coalesces repeat arrivals and reads current terrain/buildings when executed.
Synchronous area preparation drains it. No additional player decision is needed
for these equivalent presentation changes; any conflicting requirement will be
reported before dependent implementation.

## Implementation and tuning

Collision faces now prepare in a separate terrain work slot. The hidden partial
chunk owns that shape without a physics body. Publication on the next slot adds
the body, suppresses cover under buildings and registers/shows the complete
chunk. Cancellation releases the shape with the partial meshes and sampler.
Synchronous construction executes all five scene phases before returning.

Ordinary publication still regrounds resources, rare scenery and solid ruin
pieces immediately. Only the non-colliding leyline tiles are queued. Each tile
has at most one pending integer identity/index, and re-requests retain FIFO
position. One whole tile consumes an existing terrain work slot, using current
terrain and buildings. No queued snapshot can overwrite a later excavation or
building action. Explicit area completion drains the queue; normal full/edit/
building refreshes reconcile it through their existing event boundaries.
Replacement scenery owns a fresh empty queue, with no retained old chunk nodes.

The one new production value is `resource_build_budget_ms = 2.0` in
`game/art/strange_stream.gd`: stop creating more resource scenes after that much
creation work in an ordinary frame. At least one complete node finishes, and the
existing 12-node cap still applies. This is a soft creation budget; a single node,
focus scan, retirement or entire frame can take longer. Explicit immediate setup
and restoration bypass it. `terrain_chunks_per_frame` remains 1, now covering
either a terrain phase or a complete queued tile. All radii and other values stay
the same. No simulation, native library, seed input or save-schema changes.

Diagnostics retain their bounded 512-sample windows. `collision_refresh` now
excludes face preparation and queued traces; their separate stages make this
scheduling change explicit. The common travel observer reports queued tile count
and observes the same production callbacks in both versions.

## Preserved reference and exact output

`build/scheduling-performance` is separate from normal saves and the earlier
INT-07B/C/D baselines. Its reference is `e370970`: 552 non-test production archive
files remain byte-identical; 89 engine import descriptors differ only in line
endings. The separately copied native DLL is also identical, SHA256
`a60442947833049ebbff7b715036b53679d571414a13f929b92bb1ecf5f24de6`.
Only common diagnostic fixtures cross into this preserved game.

The following exact comparisons pass against that reference:

- Three complete published terrain cases: regional cover, cave floor/ceiling
  and starting ground. Meshes, cover transforms, sampler data, source-cell
  picking, collision faces and collision flags match. The same output takes
  five scene steps after the native payload, versus four before.
- 94 native resource specimens in five states each: **470 matching** geometry,
  collision and effective-material hashes, with every serialized source record
  retained. States include hover, heat, cracking and cooling.
- Every native V6 seed-1 leyline tile: **155 matching** complete array/metadata
  hashes. Queued, synchronous, retired, edited and building-suppressed results
  also match forced rebuilds in the lifecycle fixture.

Evidence is under each phase's `captures/frontier_v6-1-equivalence` and matching
`logs` directory. `TERRAIN_PREPARATION_CASES` in the logs records the three
terrain hashes. `resource-presentation.json` and `leyline-meshes.json` retain the
full specimen sets. Generated evidence stays uncommitted.

## Matched rendered travel

Godot 4.5-stable, Forward+, RTX 5090, 1440×900, FOV 75, eye 1.65 m, 120 fps cap.
The native region[0] approach supplies 150 metres at 5 m/s over 30 seconds.
Terrain, resource, biome and hidden-HUD callbacks run normally. Player/combat
physics and world time are disabled for these camera-route measurements.
Processes and user data are isolated; shared driver caches are not erased.
No other agent-owned heavy check ran alongside the final rendered samples.

Final comparisons use seed 1 `baseline/before-b` and `current/after-b`, and seed
77 `baseline/before-b` and `current/after-a`, under the phase's
`captures/frontier_v6-SEED-NAME` directory. These use identical common observer
code. Earlier samples are retained as well, including the outlier below.

| Route/version | World setup ms | Frame median ms | Frame p95 ms | Worst frame ms |
| --- | ---: | ---: | ---: | ---: |
| Seed 1, preserved | 5,369.532 | 8.239 | 8.636 | 20.948 |
| Seed 1, updated | 5,334.437 | 8.239 | 8.609 | 16.271 |
| Seed 77, preserved | 5,136.463 | 8.249 | 8.626 | 18.188 |
| Seed 77, updated | 5,170.675 | 8.260 | 8.614 | 14.588 |

Worst frames improve **22.3% / 19.8%** in these final comparisons. Normal
median/p95 remain at the cap, with setup within 1%; this is not an ordinary FPS
increase. Settled draw calls/primitives match exactly per seed: 1,380 / 3,659,905
and 1,323 / 3,691,623. Final active resource counts also match: 962 and 860.
Resident chunks at the moving outer boundary differ by one or two because work
now lands on different frames; exact signatures and settled output remain equal.
Matched daylight and dusk seed-1 images were inspected. Foliage motion varies
with the capture instant; no detail or render distance was lowered.

Individual route-phase observations explain the improvement:

| Work | Seed 1 p95 / max ms | Seed 77 p95 / max ms |
| --- | ---: | ---: |
| Previous combined collision/refresh | 11.629 / 18.533 | 13.356 / 15.967 |
| New collision publication/grounding | 3.894 / 5.130 | 3.617 / 4.627 |
| Separate face preparation | 3.728 / 4.925 | 3.428 / 4.340 |
| Separate queued leyline tile | 6.080 / 7.496 | 7.077 / 7.697 |

At most four tiles were queued on either rendered route. Pending-terrain frame
p95 changes 8.837 → 8.588 ms and 8.672 → 8.597 ms. That subset uses the unchanged
fixture definition: a native/scene job or pending terrain origin before waiting
for the frame. It does not include every cosmetic-only frame, nor frames whose
focus scan discovers new work during the callback. Whole-route measurements
above include all of them. Per-phase p95 uses the fixture's sorted floor(N×.95)
index; aggregate windows can also include setup, so this table uses route rows.

### Unresolved early outlier

The first current seed-1 run (`after-a`) recorded a 128.705 ms settled-frame gap
and three 181–183 ms route gaps. On the worst 183.372 ms row, Terrain took
0.006 ms, CPU-to-draw 0.365 ms and draw work 0.972 ms; shader pipeline counts did
not change. These timers do not attribute the remaining gap. Without changing
production code, seed-1 repeat `after-b` returned to an 8.566 ms settled maximum
and 16.271 ms route maximum; current seed 77 also lacked those long gaps.
Both baseline repeats are retained. This investigation did not establish the
cause, so the outlier is explicitly excluded from the final repeat comparison,
not represented as fixed or silently deleted. First-process/system-level stalls
remain a limit of the evidence; the repeated result does not guarantee a maximum
frame time on every launch or machine.

## Lifecycle and compatibility checks

| Fixture | Passing checks | Evidence / contract |
| --- | ---: | --- |
| Stream scheduling, V6 | 5,654 | Coalescing, shared slots, current-state refresh, prepared-shape cancellation, finite partial/depleted sources, synchronous completion, replacement and paced coverage. `current/frontier_v6-1-regressions`. |
| Stream scheduling, V5 | 3,727 | Same lifecycle on historical geography. `current/frontier_v5-1-historical`. |
| Terrain preparation, V6 / V5 | 105 each | No premature visibility, sampler or physical collision; synchronous/staged equivalence and interrupted edits. |
| Wide terrain stream, V6 / V5 | 75 each | Real collision, bounded retirement/return, edited seams and saved partial/depleted resources. |
| Terrain-only entry / older profiles | 57,897 | Terrain scene startup, geography, skyline, dressing and streaming regression. |
| Faceted terrain | 66 | Physical support, source picking and excavation. |
| Weathered save | 21 | Historical terrain/resource restoration. |
| Cataclysm intensive | 170 | Ruin/leyline grounding, real footprints and discovery lifecycle. |
| Resource / leyline oracles | 2 each, plus hashes above | Exact preserved output. |
| Four session circuits | 691 | Paid 271-piece home, stored possessions, finite workshop, partial/depleted work, edits, loose ownership and repeated saves. `current/frontier_v6-1-session`. |
| Fresh-process session restore | 20 | Same checkpoint restores and finishes the existing workshop output once. |

The new fixture traverses 300 m at simulated 30 fps and 300 m at simulated 60 fps
on V6; V5 uses its complete 196.213 m native route at each cadence. Every walking
position finds a published exact surface, with periodic real physics rays after
synchronization. Maximum queue depth is 8/9 tiles on V6 and 5/5 on V5. This proves
scheduling throughput on those routes, not frame performance on lower hardware
or an actual player-controller playtest. The four-circuit run and fresh restart
take 33.02 s and 8.17 s respectively; these correctness checks overlapped other
headless checks and are not performance comparisons.

Reproduce using `tools/world_performance_checks.ps1 -ReviewSuite scheduling`.
Preserve the reference separately; use `-Prepare -Import` only for current.
Choose `-Scenes travel_performance_review -Rendered -Seed 1` or `-Seed 77` for
the rendered route, and the table's scene names for headless checks. Use the same
review name for `session_soak --soak-cycles=4` and the later `--soak-resume`
(arguments supplied through `-ExtraArguments`) to retain isolated user data.
`stream_scheduling.tscn` also joins the normal headless regression runner.
`tools/compare_travel_presentations.py` compares each phase's equivalence folder.

## Remaining work

The largest attributed frames now combine periodic focus/retirement work with
new payload/resource creation. Separating those coincident operations is the
next bounded optimisation candidate. Native payload generation and a complete
leyline tile remain indivisible main-thread work in this implementation. The
unattributed first-run gaps, lower hardware and owner comfort need further
review. No new world profile, resource rule, content or combat tuning is implied.
