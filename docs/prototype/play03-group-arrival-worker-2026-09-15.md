# PLAY-03: arrival fixes across the full current creature roster

## Owner expansion: all current creatures and mobs

The owner explicitly asked: "Sorry can we just make sure we fix all the
creatures/mobs? is that all of them?" This expands the existing task. The reported
turtle/archer/wisp group remains the first causal reproduction, not the delivery
boundary. Apply the shared correction throughout the current roster and address
distinct measured creation/batch stalls. Do not wait for one owner report per
species or stop with an identical known loading omission elsewhere.

Derive a coverage list from native definitions and actual runtime dispatch, not
only definitions containing `finished`. Coordinator inventory at main `8015564`:

| Family | Current ordinary IDs | Presentation |
| --- | --- | --- |
| Boar, wolf, stag | `ember_whelp`, `ash_hound`, `valley_elk` | FinishedFauna; preserve the prior fix |
| Porcupine | `cinder_archer` | PorcupinePresentation |
| Crane | `shrieker` | CranePresentation |
| Ram | `stone_husk` | RamPresentation |
| Beetle | `gloom_crawler` | BeetlePresentation |
| Nymph | `bog_lurker` | NymphPresentation |
| Tortoise | `hollow_knight` | TortoisePresentation |
| Both moth/wisp variants | `marsh_wisp`, `cinder_wisp` | RecoveredActorArt + articulated CreatureMotion |

All five current LF aliases are also included: `lf_white_stag`, `lf_green_moth`,
`lf_paired_boar`, `lf_red_boar`, `lf_blue_boar`. Resolve visual_id dependencies
once while retaining separate actor materials, scar/status behavior and finite
ownership. Include elite/era variants using these bodies. Include existing bosses:
Boss/Forge Tyrant and the shared Warden/capstone body contract, plus Conservator's
separate procedural human/harness path. Inspect live definitions for any additional
reachable ID. This covers existing presentations, not production of new boss art.

Account for real entry points: normal New World and validated Continue, passive
fauna, surface/cave packs, noise recruitment, sleeping reactivation, sieges,
resource-site defenders, trial initial groups/reinforcements/bosses and restored
campaign/trial entry. Start with MobPacks, Enemy.spawn, player.gd site spawns,
TrialController, Boss.spawn_boss and Conservator.configure. Shared entry points
can cover several contexts, but a Sandpit-only helper is not proof of trial/boss
coverage. Prepare resources before interactive first use at the appropriate
lifecycle point without creating/activating dormant actors early.

Deliver a compact coverage table for every current ID/family and entry path:
shared implementation, relevant evidence and residual limitation. If a path is
already safe, retain it and record why. If per-instance work still creates a
substantial group pause, measure/fix it; cached textures alone do not close that.
Do not declare full-roster arrival work complete while known actionable stalls
or unaccounted-for presentation paths remain. Keep unrelated performance open
separately; this does not authorise new gameplay rules, art or a general framework.

The owner's all-roster request authorises one bounded coverage pass through each
distinct live resource/presentation and shared entry path, with first-use and
grouped creation. Include it in the after/lifecycle jobs below where practical;
an extra focused job is justified for a distinct affected path. Do not exclude a
family solely to satisfy the earlier three-job default. Reuse unchanged alias/
elite evidence, but account for both wisp resource variants. This supersedes the
old exclusion of species coverage for this task. It does not require species x
seed x camera x renderer x status combinations, full boss fights or campaign
replays. Keep one renderer and the normal mouse-comfort protections.

## Reported reproduction and retained implementation guidance

The owner reports "still some considerable lag when a lot of mobs spawn in at
once unfortunately", then identifies "turtle + archers + cinder wisps".
This takes priority over queued PLAY-06 navigation. Earlier arrival feedback was
a brief hitch then recovery; this follow-up supplies creatures, not a new count,
duration, seed or trace. Do not require another owner reproduction before work.

Resume `D:/Wroughtwild/work/play03-mob-arrival`, branch `codex/play03-mob-arrival`,
at completed worker `039bccf49e6c99c1d40ec78102ccf6cc31efcc0e`. Read
`build/play03-group/SETUP.md` and this current owner-depot brief. Prior worker
commits are already adopted; commit only the continuation. No new checkout/reset.

## Outcome and known paths

Remove substantial arrival pauses across the full roster while preserving the
complete encounters/art. The prior first boar result, 324.760 to 7.529 ms, remains
valid but does not establish full-roster or group coverage. The reported trio is:

- Turtle: `hollow_knight`, `TortoisePresentation`, knight/ward behavior.
- Archers: `cinder_archer`, `PorcupinePresentation`, ranged/mark behavior.
- Cinder Wisp: `cinder_wisp`, authored moth and generic articulated CreatureMotion.

None takes the `finished` branch prepared by `FinishedFauna.prepare_world()`.
Tortoise/porcupine still load scenes/textures/material templates lazily, with
retained legacy mesh construction in RecoveredActorArt. The wisp uses its visible
skinned mesh/rig path. These are inspected leads, not timing conclusions. Never
replace the visible moth or later mobs' adorned envelopes with the fitted fauna's
two-point hidden envelope without proving the actual contract is preserved.

MobPacks checks every 0.4 s and synchronously creates qualifying packs/members.
Distinguish first-use resource loading, repeated actor setup, same-frame batch
work, first draw and active updates. Do not assume pooling/queuing is required.

## Reproduce and correct

Read current owner AGENTS.md and follow its required reading order. Reuse both
arrival results, retained traces, opt-in recorder and real entry fixture. Read
only relevant actor/population/save specifications; no old baseline reconstruction.

Start with one normal mixed/group arrival containing the reported creatures.
Use V8 seed 77 unless owner world information arrives. Its Ember Wastes pool has
`hollow_knight + cinder_wisp`, `cinder_archer + ember_whelp`, and
`cinder_wisp + cinder_wisp + ash_hound` packs. Choose a useful generated cluster,
disclose exact composition/count and initial pose, then activate through ordinary
movement or a real existing noise action. No clone army, density changes, repeated
teleports during timing or single-boar substitute. If all three cannot naturally
arrive in one callback, disclose the actual short window through the normal packs.

Record from entry through first asset use, preparation/approach, all members,
first draw and short recovery. Extend bounded markers around expensive paths.
Count actors per frame/pack; distinguish resource acquisition and mesh/rig work.
Nested timings overlap; draw wall time is not GPU execution time. Keep ordinary
world/AI/streaming/quality active. No readback, per-frame disk writes or OS/driver
cache purge. Retain initial relocation costs separately and do not hide preparation
inside settling. Preserve old traces; write new output under `build/play03-group/`.

Follow the measured critical path to a complete correction. If these adapters
repeat the same first-use loading pattern, use a consistent preparation contract
for adopted adapters sharing it instead of leaving each identical known omission
for a separate worker. Keep this a small resource-management change, not an art
rewrite or generic streaming framework. Resource-only preparation must happen in
real New World and validated Continue before controls release, or be bounded/
asynchronous with readiness checked. Report startup/residency tradeoffs and where
time moved; fixture-only warming or moving the freeze earlier in the walk fails.

If cached per-member work still creates a large burst, address that measured work
with justified preparation/reuse/scheduling. Do not stop after a minor percentage
gain while an actionable dominant pause remains. Aim for ordinary frame-sized
arrival work (~16.7 ms at 60 fps); report worst interactive preparation, full group
arrival, first draw and recovery. A remaining substantial pause needs its measured
blocker and concrete remedy, not a prototype exemption.

Preserve models/animation/tells, counts, 28 m activation and existing population,
aggro/damage/loot rules. No invisible active enemies, reduced art/quality/counts,
or hidden driver changes. If scheduling changes, reserve population once and keep
ordered members, exact sleeping survivors, defeated finite hosts, elite/escort/
noise behavior and once-only death claims. Check affected world/Continue/trial
cancellation so pending work cannot duplicate or leak. Keep RF-05 lakes/swimming,
shore/recovery behavior, old geography, campaign and save ownership intact.

## Focused checks and handoff

Default to three jobs on Forward+: (1) one causal group capture, (2) the same
group/route after correction including production preparation and all first
displays, (3) headless checks of changed resource/material/rig or scheduling
lifecycle, including real entry/Continue when preparation changes. Reuse earlier
boar, mob and RF-05 evidence for unchanged behavior. Concrete changes/failures
justify focused reruns; no hard ten-minute cutoff or species/seed/renderer matrix.
Keep the old unrelated 115 ms event and underground link separate unless evidence
connects them. If the group hitch does not reproduce, report that honestly with
useful targeted recording instead of an assumed fix. R9 stays stopped.

Reuse current D: imports and RF-05 DLL; native changes are not currently expected.
Use verified mouse opt-out, BOM-free no-focus override and render mutex; never
move the pointer or stop owner processes. End owned tests. No automatic interactive
playtest or new package. Write `docs/prototype/play03-group-arrival-result-2026-09-15.md`
with cause/fix, actual group counts, full roster/entry-path coverage, timings, checks,
remaining limits, tuning if any and native/commit status. Supply a private playtest
approach facing the group, without relying on the missing compass. Use process-
scoped PowerShell Bypass in launcher instructions and disclose the save slot.
Commit the checked continuation, report its SHA for coordinator adoption/push,
and stop. Do not implement PLAY-06 in this task.
