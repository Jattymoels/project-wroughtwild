# INT-07F — Avoid coincident nearby-world refresh bursts

Status: implemented and checked; owner review remains deferred.

## Approved outcome and plan

The owner requested a quick slice/wave overview and continuation of the next
bounded performance slice after INT-07E. The first six intensives have implemented
review slices; INT-07A–E cover persistence, preparation, recovery and travel cost.
This continuation addresses the remaining periodic focus/retirement/loading
bursts. D-010, D-013 and D-032 retain authority; gameplay tuning, new geography,
broader automation and the timber-demolition conflict stay separate.

1. Preserve `b06da19` and the unchanged native DLL under the separate
   `build/focus-performance` directory. Use the same two seeded rendered routes
   and common frame observer to verify the remaining cost.
2. Separate periodic terrain and resource focus work from new preparation,
   retaining synchronous teleport/restore safety and finite-resource ownership.
3. Check coincident timers, starvation, interrupted work, slower simulated frame
   cadences, historical worlds, exact output and fresh-process restoration.
   Compare matched rendering and retain any unattributed frame gaps.
4. Record results and limitations, commit and ordinarily push to `origin/main`.

Affected systems: Terrain's nearby-world callback, TerrainChunkStream and
ResourceStream; existing scheduling values live in `game/art/strange_stream.gd`
and `.tres`. No new gameplay rule, save field, rendering distance or numerical
tuning is proposed. A short delay to distant preparation is acceptable only
while walking support, complete publication and eventual queue progress remain
verified. Missing decisions affecting those contracts will be reported before
dependent implementation.

## Implementation

Terrain now coordinates its two existing streams. A periodic terrain scan and
retirement pass owns its frame. A due resource scan follows, with resource
creation on a subsequent frame. The existing one-phase terrain slot and 2 ms
soft resource-creation budget continue to limit preparation work. No numerical
tuning, count, radius, geometry or source rule changes.

The transient order gives a deferred resource scan its turn, then reserves a
preparation turn even when timers remain overdue. A new world resets that order;
it is not part of saves. Terrain's synchronous teleport guard always runs, even
on a turn reserved for other work. Exact-area completion, immediate resource
materialisation, ordinary edit/build refreshes and finite-stock capture retain
their existing behaviour. Detail-mask updates still flush when preparation is
skipped.

The first implementation passed normal coincident-timer and paced-route checks
but failed an added repeated-debt case: with both timers forced overdue during
nearby movement, terrain scans could keep postponing both scene preparation and
resource creation. The `starvation-before` isolated log retains those two
failures. The revised ordering passes that same case, alongside stationary queue
completion and a teleport while a resource scan waits. This was corrected before
publication; it was not an existing-main failure.

The common observer calls the unmodified production operations. It now records
actual scene phases, whether each scan ran, and time spent releasing terrain
chunks. It also records the interval between the preceding post-draw event and
the next process signal. That interval includes frame waiting and unobserved
engine/physics work; it is not a GPU-only measurement. Observations have no
scheduling or game-state authority and remain bounded in the existing fixture.

## Matched rendered results

Reference: `b06da19`, preserved under `build/focus-performance/baseline`.
The archive manifest verifies 552 non-test production files byte-for-byte;
89 `.import` descriptors differ only in normalised line endings. Both phases use
the same native DLL, SHA-256
`a60442947833049ebbff7b715036b53679d571414a13f929b92bb1ecf5f24de6`.
Only common observation fixtures are copied into the reference.

Godot 4.5-stable, Forward+, RTX 5090, 1440 × 900, FOV 75, eye height 1.65 m,
120 fps cap; V6 seeds 1 and 77 follow the existing region-zero route at 5 m/s
for 30 seconds / 150 m. Each uses a fresh isolated process and user directory;
driver caches are not erased. Normal terrain, resources, biome and hidden HUD
callbacks run; player/combat physics and the world clock are disabled. No owned
heavy check runs concurrently with these rendered samples.

All times below are milliseconds. Final pairs use the same observer:
seed 1 `baseline/frontier_v6-1-before-b` versus `current/frontier_v6-1-after-a`;
seed 77 uses `frontier_v6-77-matched-a` in both phases.

| Route | Setup | Walking median | Walking p95 | Walking maximum | Settled maximum |
| --- | ---: | ---: | ---: | ---: | ---: |
| Seed 1 reference | 5,458.262 | 8.246 | 8.615 | 15.766 | 128.432 |
| Seed 1 current | 5,542.933 | 8.288 | 8.589 | 9.943 | 8.519 |
| Seed 77 reference | 5,431.617 | 8.245 | 8.612 | 13.529 | 8.502 |
| Seed 77 current | 5,153.829 | 8.264 | 8.591 | 10.351 | 8.500 |

Worst walking frames improve **36.9% and 23.5%**. Ordinary frames remain near
the cap; this is a reduction in bursts, not a general frame-rate increase.
Setup changes +1.6% and −5.1%. Pending-terrain p95 remains about 8.59 ms; that
subset's maxima rise from 9.036/9.529 to 9.841/10.351 ms, each below 10%.
No matched setup, median or p95 regression exceeds the review threshold.

The trace identifies the intended change directly:

| Per-route observation | Seed 1 reference → current | Seed 77 reference → current |
| --- | ---: | ---: |
| Both scans in one frame | 115 → 0 | 108 → 0 |
| Scan plus terrain/leyline preparation in one frame | 86 → 0 | 80 → 0 |
| Whole Terrain callback p95, ms | 3.830 → 3.243 | 3.456 → 2.821 |
| Whole Terrain callback maximum, ms | 13.076 → 7.722 | 11.291 → 8.657 |

Resource scans still run 116 → 117 times on each route; terrain scans remain
115/108. Work is separated rather than removed. Current whole-callback scan
maxima are 3.365/4.272 ms for terrain and 2.567/2.379 ms for resources. The
remaining current worst frames involve a whole resource creation or one leyline
tile; one tile accounts for 8.647 ms on seed 77. Terrain retirement maxima remain
0.796/1.021 ms. Splitting those individual operations is outside this slice.

**Keep the outlier visible:** the preserved seed-1 reference recorded a
128.432 ms gap during the 600-frame settled window. An earlier reference run
settled at 8.514 ms maximum; current and seed-77 samples settle near 8.5 ms.
This resembles the intermittent long gaps already recorded in INT-07E and
demonstrates that a settled pause can occur in pre-INT-07F code. Its cause is
still unknown. The new detailed interval observer covers the walking window,
not settling, so it cannot attribute this event. Walking post-draw/process gaps
remain below 7.49 ms in the final pairs. These observations do not establish
that all launches or hardware are free of stalls.

## Correctness and presentation

- `focus_scheduling`: **27 checks each for V6 and V5**. Coincident timers,
  finite-stock preservation, resource rediscovery without same-frame creation,
  stationary completion, continuously overdue timers, synchronous teleport
  collision and immediate restore all pass. The failed first-attempt starvation
  log is retained separately; it is not part of the accepted result.
- `stream_scheduling`: **5,654 V6 / 3,727 V5 checks**. Real queued work advances
  along 300 m / 196.21 m at simulated 30 and 60 fps cadences; periodic physical
  rays verify support. Maximum queues are 6/9 for V6 and 5/5 for V5. These are
  throughput checks, not measured low-end hardware or controller playtests.
- `terrain_preparation`: **105 checks**; `wide_terrain_stream`: **75 each for
  V6 and V5**; `terrain_stream_intensive`: **57,897**; `weathered_save`: **21**.
  These cover complete publication, interrupted work, collision, excavation,
  terrain-only callers, historical profiles and saved resource/building state.
- Four generated-home/workshop/save circuits pass **691 checks**; a fresh
  process passes **20** restoration checks. A paid 271-piece home, stored
  possessions, finite/partial harvesting, edits, cracks, loose loot and exact
  once-only recipe output survive. The fixture uses accelerated route ticks,
  relocations, frozen drop age and explicit machine time. It is not elapsed-hours
  playtesting. Reports remain separately saved as `session-soak.json` and
  `session-restart.json`; the runner's same-name console log contains the later
  fresh-process run. Headless elapsed times are not matched performance claims.
- Both presentation probes pass: **470 resource-state hashes** and **155
  leyline tile arrays/metadata** match the reference exactly. Three complete
  terrain signatures match, including cave floor/ceiling, regional cover and
  spawn mesh, collision, sampler and source cells.
- Matched seed-1 daylight and seed-77 dusk screenshots retain terrain/resource
  composition. Draw calls match at 1,380/1,323, active resources at 962/860,
  resident chunks at 358/348 and total built chunks at 461/459. Seed-77 primitive
  counts match at 3,691,623. The final seed-1 reference reports six more
  primitives than current's 3,659,905; an earlier reference matches current.
  That small frame-count difference is not attributed; static output hashes
  provide the exact-output comparison.

## Evidence and reproduction

`tools/world_performance_checks.ps1 -ReviewSuite focus` uses the isolated
`build/focus-performance` root. Prepare/import current before checks. Preserve
the reference archive and native DLL before invoking `-Phase baseline`; never
replace its production scripts with current code. The suite copies common
travel observation scenes into each phase. Existing performance roots and
ordinary player saves are unchanged.

Final headless logs live under `logs/current/frontier_v6-1-foundations-final`,
`frontier_v5-1-historical`, `frontier_v6-1-regressions` and the two phases'
`frontier_v6-1-equivalence` folders. Final rendered captures and frame JSON use
the pair names above. `preserved-source.json` records the reference source.
`compare_travel_presentations.py --kind resources` / `--kind leylines` compare
the respective equivalence JSON; `TERRAIN_PREPARATION_CASES` in the probe logs
provides the terrain signatures. The fixtures and runner are tracked; generated
logs, images, engine imports and saves remain ignored.

No new tuning parameters, dependencies, save fields, generation inputs, world
dimensions or gameplay rules were introduced. Owner comfort/visual review,
combat difficulty calibration and measurements on lower-end hardware remain
pending. The queue retains the intermittent settled pause as an unresolved
observation; routine coincident-scan bursts have been addressed by this slice.
