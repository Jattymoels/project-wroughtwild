# PLAY-03 — shorter first creature arrival

The measured first boar arrival is **27% shorter: 443.144 ms → 324.445 ms**.
Finished boars, wolves and stags now use the existing authored bounds for their
hidden fitting envelope instead of rebuilding an unused skinned mesh. Their
adopted models, animation, collision, scale and labels remain. Arrival timings
are also available in the existing optional incident recorder.

**PLAY-03 remains open.** The selected boar still spends **307.916 ms** setting up
its finished presentation. The after trace also contains an unattributed
114.660 ms interval later, without another mob arrival. The earlier underground
connection is unproven. This slice is a measured partial improvement, not a claim
that all hitches are fixed. Owner playtesting remains deferred.

## Measured event

Worker `D:/Wroughtwild/work/play03-mob-arrival`, branch
`codex/play03-mob-arrival`, base `67061a916e902134c4557aade25846aa5bad4021`.
Current owner guidance, required project reading and the scoped worker brief
control this slice. No new gameplay decision or tuning value is introduced.

One ordinary **V8 seed-77** pack, index **176**, contains one `ember_whelp` (the
finished boar), den **(338.5, 39, 598.5)**. Each process starts recording before
world setup. The fixture discloses one placement at
**(368.9803, 30.1, 583.4351)**, **35.146 m** from the den, outside 28 m activation.
After 90 process frames at that position, normal controller movement approaches
the pack; no further position assignment occurs. Activation is at 27.288 m
before and 27.527 m after, physics frame 176 in both. The world clock, combat,
other packs, terrain/resources and quality remain active. No screenshot/readback
or trace-file writes occur in the sampling window.

Godot 4.5-stable, Forward+, RTX 5090, Ryzen 9 9950X3D, 1280×720, VSync disabled,
120 fps cap, Dummy audio. These are separate processes with first use of the
selected boar's assets. Spawn-area grazers already exist; they are not removed.
No system/driver caches were purged and no OS-cold claim is made. Setup is
separate: 39.791 s before, 51.138 s after. This is one bounded instrumented pair,
not a stable hardware benchmark or seed/species matrix.

| Observation | Before | After |
| --- | ---: | ---: |
| Arrival process interval | 443.144 ms | 324.445 ms |
| Activation scan, including construction | 435.495 ms | 315.042 ms |
| Whole pack construction | 435.401 ms | 314.966 ms |
| Scene instantiation | 0.122 ms | 0.092 ms |
| Member support | 0.047 ms | 0.035 ms |
| Enemy configure | 435.016 ms | 314.657 ms |
| Hidden recovered mesh | 125.855 ms | 0.049 ms |
| Finished presentation setup | 301.926 ms | 307.916 ms |
| Next interval, including first draw | 16.086 ms | 15.578 ms |
| First-draw pre/post wall observation | 4.342 ms | 3.992 ms |
| Following ~2 s median / p95 | 8.634 / 15.214 ms | 8.668 / 15.712 ms |
| Following ~2 s worst | 20.117 ms | 114.660 ms |

Nested spans overlap and must not be added. The arrival row closes physics work
and contains the **preceding** draw; the new actor's first draw is observed in
the **next** interval. Mesh-pipeline counts increase on creation; two more
specializations appear with the first draw in both runs. These observations are
not direct GPU execution times. The first boar AI callback before was 0.033 ms.
The removed 125.8 ms operation was not rescheduled: no queue/preload/background
work was added. Remaining first-presentation work is intentionally unresolved.

The after trace's later 114.660 ms row is frame 337. It contains no construction,
0.065 ms activation scanning, 2.195 ms observed physics callbacks, 2.692 ms chunk
work and 2.020 ms resource work; those spans do not explain the whole interval.
Do not attribute it to the removed mesh work, declare it fixed, or launch a new
review wave from this report.

## Change and preservation

`RecoveredActorArt` uses `visual_bounds` and `applied_visual_scale` already in the
manifest to create a two-point, hidden envelope for the three fitted A2 families.
It skips their unused old GLB, vertex/skin reconstruction and old texture loads.
`FinishedFauna` still installs the complete adopted visible model/material/rig.
LF visual aliases retain their channel material and tell. The six subsequent
replacement mobs keep their existing path: their older envelopes also append
procedural adornments, so this patch does not assume their manifest bounds alone
are sufficient. Their approved art is unchanged.

Pack construction remains synchronous and ordered at the existing activation
radius. There is no new reservation/cancellation mechanism or saved field.
Native population, elite/escort/finite-host selection, aggro, damage and rewards
are unchanged. RF-05 movement/shore guards, lakes, swimming, paid support and
floating recovery source are untouched. V1–V7/LF geography and save ownership
remain on the inherited native runtime. No native source, tuning, asset or
manifest is edited.

The optional recorder adds bounded arrival spans for activation scans, support,
instantiation, members/packs, configure, recovered mesh, presentation setup and
first actor physics. Events carry process/physics frame IDs and actor/role/pack
context; final code also tags draw process frames. Each existing 7,200-row ring
interval holds at most 128 events and explicitly counts overflow. Nothing is
written during sampling. Ordinary launch leaves the recorder off.

## Focused checks actually run

- **Before causal capture:** completed with the timings above; exit 1 for one
  overbroad test assertion that *all* creature caches must be empty. Ordinary
  startup grazers had already loaded. The full retained trace has exactly one
  boar setup, during the intended approach, so the measured first-boar evidence
  remains useful. The assertion was corrected to the selected boar, including a
  check immediately before walking; the before capture was not repeated.
- **After arrival:** **11/11**, exit 0, no reported engine errors; 60.34 s including
  setup. Same generated pack, start and movement route; exact boar envelope,
  fitted model transform and life match the before receipt. Mouse visibility,
  no-focus, active ordinary world processing and V8 lake presence pass.
- **Headless changed-behavior check:** **39/39**, exit 0, no reported errors,
  2.34 s. All three changed envelopes match original transformed GLB vertices
  (boar/wolf zero difference; stag at most 0.00000012 m floating-point difference).
  Visible adopted models, native life, unchanged capsules/spatial registration,
  repeated setup, fit/labels, one release listener, status on/off, elite labels,
  LF red-boar alias, exact native state through presentation, ordered two-member
  arrival, real once-only death claim, exact sleeping survivor and bounded/off
  recorder behavior pass. One initial fixture-only observer attachment omission
  failed a marker assertion; fixing that attachment made the same check pass.
- The initial import completed asset processing but reported a misplaced timing
  variable; the launcher stopped it. Corrected source was loaded by both scene
  checks. No separate final editor-import pass is claimed. The final scoped Git
  whitespace check passes using the repository's normal line-ending settings.

Reused RF-05 save/ownership/lake and unchanged mob evidence; no save copy,
Continue replay, renderer matrix, broad suite, native rebuild or R9 work.
The failed logs remain. All owned Godot jobs exited, the no-focus override was
removed, and no pointer automation was used. Generated import sidecars/caches
remain local and are excluded from the commit.

[Compact timings and verification receipt](../../tools/wroughtwild-play03-arrival/evidence/summary.json).
Raw traces/logs are under `build/play03-arrival/`. `summarize.py` reads those
completed files without launching another check. The runner's before/after names
label output directories; both run the currently checked-out source.

## Normal play and optional recorder

After coordinator integration, launch the normal game with seed 77:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game' -- --world-seed=77
```

Choose New World and Warden (this uses the normal save slot). From spawn near
(512,512), travel west-southwest toward (369,583), then continue toward the boar
den at (338.5,598.5). Walking within 28 m in 3D activates it. The automated test
only stages the initial pose; these are normal-play directions, not a new
teleport feature. Other world arrivals en route may also hitch. Existing Continue
uses the saved profile/seed and can encounter the same presentations without a
new-world migration. Before integration, substitute this worker's `game` path.

For an incident trace, add this argument after `--` to the usual launch:

```text
--play03-trace=D:/Wroughtwild/work/play03-mob-arrival/build/play03-arrival/player-traces
```

Keep the usual LF campaign flag if applicable. After an incident, wait a few
seconds and close normally soon enough to retain the window. Normal close writes
the local ring once; a crash/forced kill loses it. The existing recorder's save,
privacy and bounded-retention behavior remains as documented in the earlier
[PLAY-03 recorder result](play03-underground-result-2026-09-15.md).

## Native runtime and coordinator handoff

The checked slice is committed on `codex/play03-mob-arrival`; the worker's final
handoff supplies its SHA. **No merge or push was made**: coordinator integration
and publication are the next action, outside this worker's slice.

The inherited RF-05 DLL was verified unchanged:

`D:/Wroughtwild/work/play03-mob-arrival/game/bin/libwroughtwild_sim.windows.x86_64.dll`

SHA256: `fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b`

It is ignored, not committed. It already includes RF-04/RF-05; keep the matching
current coordinator DLL. No owner-depot DLL or source-art master was replaced.
The worker stops after this checked partial improvement; remaining hitch work
requires the coordinator/owner's next selected scope.

## Coordinator adoption and remaining priority

Worker `de0125f2062d9cd628b44bd23e76094676336d11` is adopted on main as
`87849bda32be28c0d52751979d8bebfba794354c`. The inherited RF-05 DLL matches the
reported hash and remains in place. The coordinator reused the worker's evidence
and ran one hidden headless import: 5.16 seconds, exit 0, zero reported errors.
No new rendered comparison or native rebuild was run; the check has exited.

The owner asked whether this result was simply accepting significant lag.
The 324 ms pause remains a significant player-experience defect. Passing the
functional checks verifies preservation, not acceptable frame pacing. The first
prompt permitted stopping after the smallest demonstrated improvement; that
stopping condition does not close the bug. The immediate next scope is the
[remaining 308 ms presentation setup](play03-presentation-hitch-worker-2026-09-15.md)
in the existing worker, without another owner reproduction as a prerequisite.
