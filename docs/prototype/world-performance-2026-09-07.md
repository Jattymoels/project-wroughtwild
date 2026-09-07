# INT-07B — Faster preparation of the same frontier

Status: **Implemented; ordinary-play review pending.** Preserved baseline:
`f08806e`. Technical verification and matched presentation review pass.

The owner's "Yes continue" accepts the next measured performance slice after
INT-06A. The existing [V6 performance record](wide-frontier-intensive-2026-09-06.md#measured-cost-and-remaining-preparation-regression)
identifies synchronous native map composition and expensive nearby terrain
preparation. Improve those costs while retaining the exact accepted D-032 world.

## Outcome and plan

1. Preserve committed game/data and the matching native DLL. Measure native
   generation, chunk payload preparation and the existing Godot build stages;
   repeat the same V6 route with unchanged presentation settings.
2. Remove measured redundant native work without changing any resulting voxel,
   resource, route, structure, source identity or random-stream draw. Validate
   complete historical and V6 fingerprints against preserved results.
3. Improve the costly nearby preparation stages with bounded scheduling or
   equivalent computation. Keep exact collision ready before restore/teleport,
   publish complete chunks only, and preserve excavation, seams and retirement.
4. Verify exact mesh payloads, synchronous/staged equivalence, ordinary travel,
   return to edited ground, resource partial work/depletion and matching saves.
   Compare startup, median/p95 frames and preparation time in sequential rendered
   runs. Investigate any regression above 10%; retain honest residual limits.
5. Update specifications/queue and commit plus ordinary push to origin/main
   under the standing owner permission.

## Systems and assumptions

Affected systems are native generation and/or native chunk presentation,
Godot terrain preparation, focused diagnostic/review fixtures and documentation.
Accepted D-003/D-032 geography, D-010 authority and D-013 appearance remain.
Assume that the selected world size, view radius, nearby collision coverage and
visual detail should remain unchanged; optimisations must preserve their output.
No missing gameplay decision is needed for equivalent computation.

Do not introduce a new profile, resize worlds, change biome/population rules,
add gameplay tuning, migrate saves, lower detail or add external dependencies.
This is not infinite generation or a general asynchronous job framework.
The native full volume, exact edited chunks and finite resource records may
remain resident. Human exploration/combat review and the timber-demolition
conflict stay separate. The normal player save and playthrough are not used by
isolated checks. New diagnostic/scheduling values need plain-language purposes.

## Initial measurements and selected native work

An isolated Release profiler measured V6 seed 1 at approximately 5.4–5.7 seconds
of native generation. Cave voxel preparation accounts for 3.2–3.5 seconds;
initial heights take roughly 74–81 ms. Thirty-eight V6 surface-walk calls take
roughly 1.4 seconds, overlapping work in the base generator. The augmentation
field itself takes about 13 ms. These nested timings are not additive.

Two native changes follow that evidence. V6 can initialise its surface clearance
without running the older BFS whose parents it immediately discards; retain the
same final neighbour order. Its cave noise can reuse the existing lattice corners
and X interpolation along one column until the Y lattice cell changes. Keep the
six existing octave evaluations, exact arithmetic order, salts and thresholds.
Use bounded per-column storage rather than a world-sized noise cache. Scalar
noise comparisons and complete preserved-world fingerprints must establish exact
equivalence before integrating the new DLL. Older profile helpers stay untouched.

The Godot stage breakdown initially adds diagnostic samples only: native payload,
surface sampler, render meshes, ground/habitat cover, and collision plus refresh.
Each uses the existing 512-sample diagnostic window. This initial measurement
does not change scheduling, detail or collision; choose the host optimisation
only after the route identifies its expensive stages.

## Host work selected from the route

The unchanged runtime with nested diagnostics found collision setup and
Cataclysm trace refresh dominate the final stage. On the V6 seed-1 route,
collision face upload reached 3.96 ms p95, remaining body setup 6.13 ms,
and history refresh 9.47 ms; the complete stage reached 16.15 ms p95.
These are nested samples, not numbers to add or a baseline/current comparison.
Cover suppression and ordinary/rare-node refresh each stayed below 0.45 ms p95.

Set the collision backface flag before uploading the final triangle list.
For streamed leyline refresh, compare the exact identities of terrain chunks
over each tile's existing padded footprint and sampler halo. If those inputs
have not changed, retain the existing fissure mesh. Explicit building/full
refreshes still rebuild. Keep only integer identities, never retained chunk or
sampler objects. Verify cold arrival, retirement/return, excavation and building
refresh against the uncached geometry. No extra stages or reduced detail are
needed for these equivalent operations.

## Native equivalence and timing

Strict Release builds use WinLibs g++ 16.1.0, C++17, `-O3 -DNDEBUG
-Wall -Wextra -Werror`, with no fast-math. The preserved `f08806e` and current
executables produced matching complete-field fingerprints for all 64 accepted
Wide Frontier seeds, including collection ordering and floating-point bits.
Historical V1–V5 fingerprints (20 cases) and the existing focused V6/reordered
definition invariants passed 2,372,529 checks. The kernel oracle passed
3,539,052 checks: 3,538,944 exact noise results and 108 complete surface-walk
vector comparisons. Preserved/current tuning matches after normalising Git
line endings.

Separate fresh processes, with other engine/build work idle, measured three
baseline/current pairs per seed. The middle round reversed variant order.
Generation timing excludes tuning load and the fingerprint scan.

| Native generation | Baseline median | Current median | Reduction |
| --- | ---: | ---: | ---: |
| V6 seed 1 | 5,139.74 ms | 2,225.35 ms | 56.70% |
| V6 seed 77 | 4,874.81 ms | 2,031.89 ms | 58.32% |

The cave cache uses 528 bytes for the current column on this build; it does
not grow with the number of world cells. Generation remains synchronous and
retains the full voxel volume. The parallel 64-seed correctness run's durations
are deliberately excluded from this performance claim.

Local raw commands, compiler settings, all seed/hash pairs and timing samples:
`build/world-performance/native/evidence.json` and `equivalence.json`.
Reproducible native fixtures are `make worldgen-kernels` and
`make build/worldgen_performance` in `tests/sim`; the latter takes tuning path,
profile and explicit seed arguments. It can be built against preserved sources
for future comparisons.

The compiled Godot extension also passed 233 mesh equivalence checks against
the preserved DLL: all 84 complete payloads across V1–V6 match, including cubic
and faceted surfaces, blended colours, picking cells and edits at chunk seams.
The baseline/current reports are `build/world-performance/{baseline,current}-mesh.json`.

## Engine lifecycle verification

All checks below ran in isolated game copies with separate user-data roots and
the final compiled runtime. No normal player save was read or replaced.

| Fixture | Passing checks | Coverage |
| --- | ---: | --- |
| `terrain_preparation`, V5 and V6 | 90 each | Exact synchronous/staged mesh, cover, sampler, picking and collision; no early publication; restore flush; excavation cancels stale partial work. |
| `wide_terrain_stream`, V5 and V6 | 75 each | Distant retirement/return, physical support, cave collision, edited seams, finite depleted/part-work nodes and saved identity. |
| `terrain_stream_intensive` | 57,897 | Existing V3 horizon, terrain and regional dressing guarantees. |
| `faceted_terrain` / `weathered_save` | 66 / 21 | Picking, collision, seam rebuilding, saved excavation and historical restoration. |
| `new_world_startup` / `wide_frontier_pacing` | 101 / 319 | Real class chooser, Continue and world identity; V6 opening guarantees. |
| `cataclysm_intensive` | 170 | Existing V4 scenery, native identity and save lifecycle. |
| `trace_surface_cache` | 27 | Mesh reuse on unchanged/irrelevant arrivals, sampler release, relevant return, dig/restore, real native building suppression/removal and unchanged resource records. |
| `pressure_workshop`, V5 and V6 | 60 each | Existing finite source, paid kits, controls and exact saved firing. |
| Common headless world review | 12 | Full V6 setup and the existing normal save probe. |

The trace fixture uses a native registry footprint to exercise building
suppression; it does not claim a paid first-person construction playtest.
The compiled mesh comparison above is separate. Each rendered timing run also
passes 15 identity, route and capture checks. Imports and script checks pass.
The new lifecycle fixtures are included in `game/run_headless_checks.sh`.

## Matched rendered results

Godot 4.5-stable, Forward+, RTX 5090, 1440 × 900, V6 seed 1, FOV 75 and
1.65 m eye height. A common fixture runs in separate cold processes, with no
other engine/native benchmark workload. Two preserved runs establish baseline
variation; one final-current run measures the change. The identical native
Glasswind approach is followed at scripted 5 m/s for 30 seconds (150 m).
Player physics/combat and the world clock are disabled; normal terrain/resource
streaming and biome blending remain active. This is a timing route, not an
ordinary movement or combat playtest. The frame cap is 120 fps.

| Measure | Baseline A | Baseline B | Current A |
| --- | ---: | ---: | ---: |
| Complete world setup | 8,962.364 ms | 8,933.882 ms | 5,715.942 ms |
| Native map through engine binding | 5,537 ms | 5,492 ms | 2,373 ms |
| Initial exact terrain | 1,820 ms | 1,842 ms | 1,654 ms |
| Settled frame median / p95 | 8.338 / 8.434 ms | 8.333 / 8.435 ms | 8.335 / 8.426 ms |
| Travel frame median / p95 | 8.223 / 8.683 ms | 8.221 / 8.680 ms | 8.229 / 8.625 ms |
| Pending-work frame p95 | 12.242 ms | 11.958 ms | 9.261 ms |
| Preparation-stage p95 | 10.304 ms | 10.134 ms | 7.038 ms |

Against baseline B, complete setup improves **36.0%**, pending-work p95
**22.6%**, and aggregate preparation p95 **30.6%**. The ordinary travel median
is effectively unchanged; its p95 improves 0.6%. No matched startup or
median/p95 frame regression exceeds 10%. Nested stage diagnostics locate work;
their p95s must not be added. Moving the collision flag also moves its timer
category, so the body sub-timer alone is not an isolated speedup measurement.

Route fingerprint `153778956`, all three camera poses, 14,274 resource records,
937 pack records and final active-resource count match. Settled rendering stays
at 1,380 draws and 3,659,905 primitives. Daylight and dusk images retain the
same geometry and composition; foliage/shader time makes pixel equality an
inappropriate visual assertion. The timed route ends with slightly different
stream phases: current has 356 resident chunks plus one partial, baseline B
357 plus none. Current final engine static allocation is 995,041,119 bytes
versus 992,553,155 (+0.25%). This is not evidence of reduced memory use.

Evidence: `build/world-performance/index.html`,
`captures/baseline/frontier_v6-1-baseline-{a,b}/manifest.json` and
`captures/current/frontier_v6-1-current-a/manifest.json`, under that same root.
The report includes paired full-resolution images. Functional logs are under
`build/world-performance/logs/current/`. Builds, captures and caches are ignored.

To repeat from a preserved `game`/`data`/matching DLL copy, use
`tools/world_performance_checks.ps1 -Phase baseline -Rendered -ReviewName baseline-b`.
Prepare current with `-Phase current -Prepare -Import -NativeLibrary <isolated DLL>`,
then use `-Rendered -ReviewName current-a`. `-Scenes` selects focused checks;
`-Profile frontier_v5` selects historical stream checks. Never use current
preparation or a replacement DLL for the preserved baseline. The runner keeps
the owner's normal user data isolated and closes only its own failed processes.

## Limits and next candidate

No gameplay or visual tuning values were introduced. The existing 512-sample
diagnostic window now also bounds stage timings; cache reach is derived from
the existing fissure geometry and sampler footprint. World dimensions, nearby
radii, frame-stage budget, ingredients, yields and save schema are unchanged.

Generation remains synchronous, the full native voxel volume remains resident,
and edited chunks stay pinned. Worst measured travel frames remain about
54 ms (54.6 before, 54.4 after); this is not a hitch-free result. Some final
collision/history work still exceeds one 120 fps frame. The capped high-end
rendering run does not establish low-end performance, peak process/GPU memory,
long-session memory bounds or combat smoothness. Owner comfort review remains
pending while away.

The next candidate is a bounded long-session travel, built-home return and save
recovery soak using existing rules. Remaining travel spikes can be investigated
there when reproduced. This is a proposal, not a larger world, new content or
an automatic background run. The timber-demolition conflict remains excluded.
