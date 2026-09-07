# INT-07C — Leave home, explore, return safely

Status: **Implemented, owner review pending.** Baseline: `7cfd781`.

The owner's "Yep continue" accepts INT-07B's proposed extended travel,
built-home return and save-recovery slice. Exercise the existing game for
repeated expeditions and restores, then correct reproduced lifecycle failures.
No new gameplay decision is needed to preserve existing ownership and geometry.

## Plan and scope

1. Preserve the committed game/data and matching runtime in an isolated copy.
2. Use a generated V6 world with a complete paid home, storage and stations.
   Carry finite partial/depleted harvesting, excavation and loose ownership
   through repeated distant visits, staged travel and returns. Check actual
   home collision/entry and bound retained terrain, resources and live objects.
3. Repeat normal save/write/read and fresh-process restoration. Probe missing,
   truncated and malformed files, failed replacement, and the retained previous
   save. Rejected loads must not consume or duplicate possessions.
4. Fix the smallest reproduced failures, retain focused regressions, and run
   affected historical-world, home, workshop and trial checks. Measure any changed
   hot path under the same conditions; investigate regressions above 10%.
5. Record evidence, exact test duration/acceleration and remaining limits, update
   the queue, then commit and ordinarily push to origin/main under standing
   permission.

Affected systems are SaveManager, generated-world/terrain/resource lifetimes,
placed structures and their native stores, existing workshop state and focused
review fixtures. D-010/D-017/D-027–D-032 and schema-2 compatibility remain
authoritative. Reuse the current world, save and construction specifications.
Preserve exact world identity, deposits, finite source state and authored geometry.

Tests may seed supplies and use scripted travel to exercise repeated lifetimes;
label those separately from paid placement, physical walking and actual elapsed
time. They are not owner playtesting or difficulty calibration. Use isolated
user-data directories, never the normal player save. Keep the finite full voxel
volume and pinned excavations; do not claim constant total memory.

No world size/profile change, new content, combat tuning, recipe change, offline
production, external service or broad save framework is included. The reported
timber-demolition conflict and era-dependent gear-preview issue remain separate.
Any new tuning value must explain its purpose; none is planned.

## Reproduced failures and changes

The final recovery fixture produces **36 failed assertions out of 175** against
the preserved baseline and **175/175 passing** against the implementation.
These are failed assertions across related cases, not 36 distinct bugs.

- Parseable damaged player/rules fields blocked recovery even when the previous
  checkpoint was intact. Missing and truncated files could recover, but callers
  could not distinguish that result from loading the current save.
- Unknown shapes and overlapping building records could return success after
  omitting pieces. Invalid lattice slots and wrapped large coordinates also
  escaped the complete-candidate check.
- Saving after recovery rotated the damaged current file over the good backup.
  A successful write retry could retain an earlier failure message.

SaveManager now separates validation from application. An independent instance
of the existing native sim validates the opaque rules and all saved structure
footprints before live changes. It uses the established lattice, never current
terrain exposure, payment or unlock checks. Existing valid buildings remain
loadable. A validating read can select the intact previous checkpoint, clears
stale errors and reports **"Recovered previous save."** Future schemas and
unknown profiles refuse automatic rewind. A failed preflight changes no live
inventory, pieces or player pose; a failure after application starts never
attempts to merge in another candidate.

The live player retains only the path successfully recovered, outside saved
rules/state. A subsequent normal save, even through a new SaveManager instance,
rechecks the damaged candidate before replacing it and keeps the good previous
file. This extra check runs only after recovery. Staging is flushed before
replacement, failed staging preserves the existing bytes, and successful saves
clear the recovery marker. Reads never rewrite a file or load pending staging.

No generator, rendering, native DLL, content, gameplay tuning or save-schema
changes accompany these fixes.

## Generated home and repeated-session evidence

`session_soak.tscn` constructs a **10 × 8 m, 271-piece timber home** on an actual
V6 home clearing. Review supplies are seeded; every piece and the two indoor
stations still use ordinary placement/refusal/payment. The real player
controller climbs its stairs and opens the door with E. Its chest retains
17 timber, both stations retain their physical keys, and the completed room
provides native shelter before travel, after repeated loads and after restart.

At the generated struck smithy, paid forge/feeder kits attach to the real finite
source. Charging spends four source strokes; one firing retains clay, fuel,
drive and exactly **2.375 seconds** of active work in escrow. Remote ticks
produce nothing. Fresh-process restoration preserves that exact state; returning
to the streamed workshop completes four bricks, collectable once.

Each circuit visits the three generated region approaches, performs staged
stream ticks along their last 64 steps, returns home and saves/reloads. One
boulder retains an unfinished work press, another stays depleted, its released
yield remains loose, a death pack retains its contents, seam excavation stays
open, an unfinished crack stays marked, and the loot RNG counter stays at 23.
Comparisons retain all serialized ownership fields and opaque native strings.
They exclude regenerated resource presentation Y and sanitized automatic station
names; those exclusions never remove source quantity, pose, keys or build data.

Matched seed-1 runs each complete **12 circuits / 883 checks**, with **22.59 km
of direct relocations** and **2.42 km of accelerated staged route samples**.
Actual scene elapsed time is **84.04 seconds baseline / 85.19 seconds current**.
Those distances are test travel, not hours of actual player walking. Loose-drop
age/motion and hostile combat are disabled in this fixture; separate regressions
cover ordinary expiry, pickup and trial ownership. The final current checkpoint
also passes **20 checks in a fresh process** (8.40 seconds).

At all twelve home samples, both versions retain 4,744 scene nodes, 758 active
resources, 14,273 finite resource records and 28 resident terrain chunks, with
zero orphan nodes. Warm object count remains 10,775. Every replaced door/feeder
set is freed; distant unedited terrain is released while actual edits stay
pinned. Both traces grow by the same 282,636 bytes in Godot's reported static
allocation, including the fixture's accumulating report and existing timing
windows. Current ends at 712,230,089 bytes; baseline at 712,071,521.
This establishes no observed scene-node accumulation on this repeated route,
not a constant bound on total process/GPU memory.

### Matched headless timing

Same seed/profile, fixture, DLL and sequential isolated runs. Twelve samples;
p95 uses nearest rank, so it is the maximum of this small sample.

| Operation | Baseline | Current | Change |
| --- | ---: | ---: | ---: |
| Whole populated-world load, median | 1,039.08 ms | 1,047.14 ms | +0.78% |
| Whole populated-world load, p95 | 1,053.09 ms | 1,057.86 ms | +0.45% |
| Capture and atomic write, median | 260.59 ms | 262.39 ms | +0.69% |
| Capture and atomic write, p95 | 284.18 ms | 300.26 ms | +5.66% |
| Terrain setup, one startup sample | 4,476 ms | 4,643 ms | +3.73% |

No measured changed-path regression exceeds 10%. These are save/load and
headless setup timings, not rendered frame-time or combat-smoothness claims.
Normal populated-world loads still take about a second and generation remains
synchronous.

## Repeating the evidence

Use `tools/session_reliability_checks.ps1`. It preserves the baseline production
copy, gives each phase/profile/seed/review its own user-data directory, runs
Godot hidden and closes only its owned failed processes. The baseline is the
archived `game`/`data` at `7cfd781`, plus its matching unchanged runtime DLL.
Only the common test fixtures are copied into it.

```powershell
./tools/session_reliability_checks.ps1 -Phase baseline -Scenes save_recovery -ReviewName recovery-final
./tools/session_reliability_checks.ps1 -Phase current -Prepare -Import -Scenes save_recovery -ReviewName recovery-final
./tools/session_reliability_checks.ps1 -Phase baseline -Scenes session_soak -ReviewName matched -ExtraArguments '--soak-cycles=12'
./tools/session_reliability_checks.ps1 -Phase current -Scenes session_soak -ReviewName matched -ExtraArguments '--soak-cycles=12'
./tools/session_reliability_checks.ps1 -Phase current -Scenes session_soak -ReviewName matched -ExtraArguments '--soak-resume'
```

The baseline recovery command intentionally fails. Normal recovery checks also
join `game/run_headless_checks.sh`; the longer circuit remains an explicit
review command. Reports are under
`build/session-reliability/captures/{baseline,current}/frontier_v6-1-matched/`.
Logs are under the corresponding `logs/` tree, including `recovery-final`.
The two-process check must reuse the same phase, seed and review name. Its
fixture-only expected-state file is independent of the normal save file.
Builds, test saves, captures and engine caches remain ignored.

## Limits and next candidate

No new tuning parameters. Circuit count and width/depth are fixture inputs,
not player-facing difficulty or world-size settings. This is a bounded repeated
route test, not an overnight session, owner comfort review, balance calibration
or power-loss test. It does not simulate disk exhaustion, OS crashes, arbitrary
engine failure or every semantically plausible alteration to a JSON save.
The old schema cannot detect missing records that otherwise form a valid save.
The ordinary last-good-file protocol remains; no general transactional save
framework or new backup service was added.

## Final verification

**9,188 passing assertions** across the final current-version runs below.
The baseline recovery failures above are intentional reproduction evidence.
Parser/import checks and `git diff --check` pass. The normal, preserved baseline
and isolated current DLLs all retain SHA-256
`A60442947833049EBBFF7B715036B53679D571414A13F929B92BB1ECF5F24DE6`.

| Check | Passing assertions |
| --- | ---: |
| Damaged/current/previous recovery and failed staging | 175 |
| V6 seed 1, twelve circuits and fresh restart | 883 + 20 |
| V6 seed 77, four circuits and fresh restart | 691 + 20 |
| Door persistence / loose-drop ownership | 467 + 148 |
| Actual new-world chooser and identity restoration | 101 |
| Complete trial lifecycle and exact suspension | 6,218 |
| Generated pressure workshop, V6 and historical V5 | 60 + 60 |
| Historical V3 weathered save / building terrain footprints | 21 + 174 |
| V6 and V5 streamed collision, caves, partial work and excavation | 75 + 75 |

Seed 77 completes its four circuits in 35.08 seconds, with 7.58 km of direct
relocations and 0.80 km of staged route samples. Its fresh-process check takes
8.28 seconds. All four home samples retain 4,911 nodes, 788 active resources,
13,648 finite records and 38 resident chunks, with zero orphan nodes. The
second seed is a functional cross-check, not another baseline comparison.
Its reports are in `captures/current/frontier_v6-77-second-seed/`; final
compatibility logs use `frontier_v6-1-regressions-final` and
`frontier_v5-1-historical-final` beneath the same review root.

Owner review can wait: later, revisit a built home after an expedition, operate
its stored supplies and workshop, and judge whether ordinary loading feels
acceptable. These technical checks do not establish comfort or enjoyment.

The previous pass's occasional approximately 54 ms rendered travel spikes
remain unverified by this headless slice. Investigating those remaining stream
publication spikes is the next technical candidate under the existing world
and visual rules. New content and broader production still need their own
bounded decisions. Owner playtesting remains pending while away.
