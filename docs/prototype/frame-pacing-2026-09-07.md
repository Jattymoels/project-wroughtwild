# INT-07G — Trace intermittent pauses and test constrained rendering

Status: implemented and checked; owner playtesting remains deferred.

## Approved outcome

The owner's “Yep go ahead with that remaining” continues INT-07F's recorded
limits: investigate intermittent long pauses and test weaker rendering hardware.
The existing D-010/D-013/D-032 rules, finite world, visual output, collision,
stock and save identity remain authoritative. This is a bounded reliability
investigation, not approval for new gameplay or a graphics-quality overhaul.

## Plan and assumptions

1. Preserve `f493328` and the existing native DLL in `build/pacing-performance`.
   Extend common test observation into the settled window that previously had
   aggregate timing only. Keep frame samples in bounded memory until measurement
   finishes, and identify process/draw/physics boundaries and shader activity.
2. Reproduce the pause with isolated, sequential rendered runs. Make a runtime
   correction only if evidence identifies a project cause; retain unresolved
   observations explicitly rather than claiming a fix from a clean repeat.
3. Check the available Radeon integrated GPU as a real weaker renderer. Compare
   the same existing route and record the actual selected device. Separately
   exercise delayed/low-cadence streaming and physical support; a frame cap or
   artificial delay is not an older-CPU benchmark.
4. Verify affected contracts, record measurements and limits, update the queue,
   and commit/push checked work using standing main-branch authorisation.

Affected systems initially: the existing world/travel review fixtures and their
isolated PowerShell runner. Streaming budgets remain in `strange_stream.gd` and
`.tres`; no production tuning changes are assumed. Review-only sample counts,
frame caps and selected GPU must be labelled in evidence. Only the test process
receives launch overrides; normal game settings and player saves stay intact.

No older physical CPU is available in this workspace. The host reports a Ryzen
9 9950X3D, RTX 5090 and Radeon integrated graphics. The renderer check can cover
that GPU if Godot enumerates it; it cannot certify a general minimum PC spec.
Usability, listening and actual combat calibration still require owner feedback.

## Reproduced sparse-update fault

The full-scenery check passes all three 300 m routes at 15 simulated updates per
second, then reaches missing completed support at **228 m on the fen route at
10 updates per second**. The preserved failing console output is under
`logs/current/frontier_v6-1-capacity-before`; the runner stopped only its owned
failed test. This reproduces a main-version fault, not a new implementation bug.

The old teleport guard measures movement from the most recent focus scan. At
slow cadences those scans still move regularly even when terrain preparation
falls behind. A scan's position therefore cannot prove that nearby ground is
complete. The correction checks published chunks across the existing 32 m safety
area after a moving scan and uses the existing synchronous completion path when
necessary. Complete geometry, colliders and scenery remain the unit of publication.
The existing radius controls the same walking-safety purpose; no new tuning or
save field is introduced. A transient refill counter makes this fallback visible
to tests. This prevents missing support under overload; it does not promise smooth
frames when a machine cannot keep up.

## Observation contract

The common fixture records 90 warmup frames and up to 7,200 settled frames,
followed by the existing bounded 30-second route. Three event intervals partition
elapsed time: process signal to pre-draw, pre-draw to post-draw, and post-draw to
the next process signal. Late-priority physics observation subdivides the last
interval; Terrain's existing observer locates its own callback inside process
work. These overlapping values must not be summed as independent costs.

The engine's process/physics monitors are period maxima, not timings of the
current script callback. Frame waiting and physics-server work also occur
outside scene callbacks; see the pinned [Godot 4.5 main loop](https://github.com/godotengine/godot/blob/4.5-stable/main/main.cpp#L4345).
The post-draw gap alone therefore cannot distinguish OS scheduling, frame-cap
waiting or engine work. A draw wall timer may include GPU waiting, and a graphics
API call made inside a script may wait as well. No individual wall timer proves
CPU execution time or a GPU-only cost.

`summarize_frame_pacing.py` checks that the three event intervals describe the
same complete frame and extracts intervals above a labelled inspection threshold
(100 ms by default). It excludes the first interval at each window boundary,
where untimed setup/capture work can overlap; raw evidence is retained. JSON and
images are written outside timed windows. Review frame caps, resolution, GPU and
artificial-delay overrides apply only to the isolated process and are recorded
in manifests or launch receipts. These controls do not alter normal settings.

## Save-probe correction

The first post-fix session soak failed its no-offline-production assertion.
Its diagnostic shows the ledger was unchanged throughout streaming, then its
explicit 60-second machine tick completed four bricks. At that moment the player
was **31.552 m from the feeder**, inside the existing **64 m activity radius**.
The old test incorrectly called that position distant.

A diagnostic run of preserved `f493328` confirms the same position, but missing
support for the feeder/forge made geometry readiness false, so that version
passed the assertion for the wrong reason. Corrected ground preparation exposes
the test assumption; no workshop rule or stock mutation is needed to fix it.

The soak now retains every regional travel step, checks that streaming alone
does not advance the explicitly frozen ledger, and moves to an actual native
route point beyond the machine's activity radius before the explicit tick. It
asserts that distance and retains the original exact-ledger, extraction and
fresh-process recipe assertions. This strengthens the old oracle rather than
removing the failure condition. Earlier INT-07C–F soak results remain valid for
their ownership/restoration assertions, but their fen no-offline assertion did
not independently establish the distance contract. The diagnostic logs are
`current/frontier_v6-1-lifecycle-diagnostic` and
`baseline/frontier_v6-1-activity-baseline`.

## Rendered results

The preserved archive verifies 552 non-test production files byte-for-byte;
89 `.import` descriptors differ only in normalised line endings. Both phases
use native DLL SHA-256
`a60442947833049ebbff7b715036b53679d571414a13f929b92bb1ecf5f24de6`.
Only common test fixtures cross into the reference. No native, tuning, material
or mesh-authoring source changes in this slice.

All ordinary runs use Godot 4.5-stable Forward+, V6 seed 1's existing region-zero
approach, FOV 75, 1.65 m eye height and a 120 fps cap. Each is a fresh isolated
process; driver/import caches are retained. Player/combat physics and the world
clock are disabled, while normal terrain/resource processing and biome blending
remain active. Owned heavy checks run sequentially. These are scripted world
routes, not combat benchmarks or a minimum-spec certification.

Times are milliseconds; the matched RTX pair uses `frontier_v6-1-trace-b` in
both phases and 7,200 settled frames. The Radeon pair uses
`frontier_v6-1-radeon-1440` and 180 settled frames. `current/...-radeon-720`
changes only the test window resolution; its wider aspect also changes framing.

| GPU / phase | Resolution | Setup | Walk median | Walk p95 | Walk maximum |
| --- | --- | ---: | ---: | ---: | ---: |
| RTX 5090 reference | 1440 × 900 | 5,355.859 | 8.321 | 8.604 | 11.323 |
| RTX 5090 current | 1440 × 900 | 5,391.756 | 8.308 | 8.605 | 10.161 |
| Radeon integrated reference | 1440 × 900 | 5,392.607 | 38.547 | 42.481 | 50.832 |
| Radeon integrated current | 1440 × 900 | 5,396.182 | 35.935 | 40.241 | 46.940 |
| Radeon integrated current | 1280 × 720 | 5,423.328 | 32.858 | 36.877 | 44.562 |

No matched setup/median/p95 regression exceeds 10%. The safety fallback runs
zero times on every ordinary rendered route, so lower maxima are not claimed
as an optimisation caused by that fallback. Normal RTX p95 remains effectively
unchanged. The integrated GPU delivers about **28 fps at 1440 × 900 / 30 fps
at 1280 × 720** in the corrected-build route. The manifest confirms Vulkan
device 1, `AMD Radeon(TM) Graphics`. Both GPUs still use the host's Ryzen 9
9950X3D, so an older
CPU remains unmeasured. The current scene is not verified for a steady 60 fps on
this integrated GPU. A future quality/detail policy would be a separate choice.

**Intermittent pause remains unattributed.** None of the six ordinary runs'
recorded warmup, stationary or walking frame intervals reproduces the earlier
100+ ms gap. The extra reference `frontier_v6-1-trace-a` includes 2,400 settled
frames; its settled/walking maxima are 8.670/11.724 ms. The final matched RTX
settled maxima are 8.553/8.642 ms. Earlier INT-07E/F outliers remain preserved,
not erased or marked fixed. A rare OS/engine/driver cause is possible but not
established by a clean repeat. The new trace will locate the interval if it
recurs; it does not assert a universal worst frame or a root cause.

Current RTX and Radeon images retain the existing terrain, resources, shadows
and atmosphere; no graphics features were disabled. The matched RTX settled
counts agree at 1,382 draw calls / 3,659,929 primitives. Radeon counts differ
slightly between runs, so screenshots are not presented as byte-identical
output. Terrain publication/equivalence and historical save checks below verify
the unchanged geometry and ownership contracts.

## Verification

| Check | Result | Scope |
| --- | ---: | --- |
| Sparse capacity, V6 | 10,199 passing checks | All three full-scenery regional routes, 300 m each at 15 fps, 10 fps and irregular 30 fps; 2,700 m of simulated travel with periodic physical rays. |
| Sparse capacity, V5 | 7,526 passing checks | Same three cadences and regional routes on historical geography; 1,985.74 m total. |
| Focus scheduling, V6 / V5 | 27 each | Coincident timers, eventual progress, finite records, teleport and immediate restoration. |
| Terrain preparation | 105 | Exact synchronous/staged output, hidden partials, collision and interruption. |
| Wide terrain, V6 / V5 | 75 each | Retirement/return, actual support, excavation and saved partial/depleted sources. |
| Terrain-only / historical entry | 57,897 | Existing complete geometry, skyline and streaming regression. |
| Historical weathered save | 21 | Existing V3 save and scene restoration. |
| Four corrected home/save circuits | 723 | Paid 271-piece home, finite/partial resources, edits, loose loot, storage and actual out-of-range workshop checks. |
| Fresh-process resume | 20 | Exact 2.375-second unfinished recipe and once-only four-brick completion. |
| Headless review fixture | 12 | Updated hardware/report observation works without a renderer and preserves its isolated save restoration. |

V6 safety refills per 300 m route are 2/13/6 at 15 fps and 13/30/22 at 10 fps
(uplands/fen/grove); irregular 30 fps needs none. These counts expose the cost
of overload recovery rather than disguising it as smooth low-end performance.
Capacity checks preserve all finite source records; queued scenery finishes on
explicit arrival and resident geometry stays within existing retention bounds.
The home fixture uses accelerated route ticks, relocations, frozen drop age and
explicit machine time; it is not an elapsed-hours test. Its 39.01-second run and
8.17-second fresh restore are headless checks, not matched performance claims.

## Reproduction and limits

The suite is `tools/world_performance_checks.ps1 -ReviewSuite pacing`. Preserve
`f493328` in the baseline first; the runner refuses to prepare baseline from
current source. Prepare/import current once, then run `stream_capacity`,
`focus_scheduling`, `wide_terrain_stream` or the existing lifecycle scenes using
separate review names. `-Profile frontier_v5` selects the historical test.

For rendering use `-Rendered -Scenes travel_performance_review -GpuIndex 0`
or `1`, checking the selected device in the manifest. Review-only
`--review-settle-frames=7200` lengthens the stationary observation;
`--review-resolution=1280x720` tests smaller output;
`--review-fps` selects a 15–240 fps cap. `-FrameDelayMs` supplies a known
0–100 ms delay for attribution checks, not a simulated CPU model. All values
and their purpose belong to the review, not production tuning.

Evidence lives under `build/pacing-performance`: preserved source/DLL hashes,
per-run manifests, `settled-frames.json`, `travel-frames.json`, images and
`pacing-summary.json`. Run `python tools/summarize_frame_pacing.py <capture-dir>`
to validate event partitions and list long intervals. A deliberately corrupted
partition is rejected. The corrected four-circuit console log is retained as
`session_soak-circuits.*` before the same user directory's fresh-process run;
`session-soak.json` and `session-restart.json` remain separate reports.
Generated captures, imports, logs, caches and saves remain untracked.

The only production change is the existing-area walking guard and its diagnostic
counter. No new gameplay tuning, generation input, save field, workshop rule,
dependency or normal graphics setting was introduced. Owner usability/listening
and combat calibration remain deferred; a physical older-CPU measurement and
the cause of the rare earlier pause remain open limits.

The separate `current/frontier_v6-1-injected-delay` control uses a known
100 ms engine frame delay, 30 fps cap and 60 settled frames on the RTX. It
deliberately produces 106.384 ms median / 110.959 ms p95 walking frames.
The analyser locates a 101.373 ms median post-draw interval, flags all 280 scored
walking intervals above 100 ms, and verifies the complete event partition within
floating-point rounding. All 17 scene checks pass, with no safety refill needed
on this 150 m route. This validates attribution of a known delay; it is excluded
from ordinary performance comparisons and does not explain the earlier pause.
