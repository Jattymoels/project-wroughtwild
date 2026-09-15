# PLAY-03 follow-up — large hitches when nearby mobs appear

**Current status, 16 September:** the [full-roster continuation](play03-group-arrival-result-2026-09-15.md)
is integrated as `9dba2fd` from worker `43e7cf3`, in addition to the two earlier
fixes below. Its unchanged 30-mob/eight-pack arrival measured 900.999 to 13.050 ms
creation and 950.572 to 40.869 ms for the full frame. Preparation covers all
ordinary/LF bodies, variants and both distinct boss paths at real world/trial
entry and restore. Reused lifecycle/restore/boss evidence and main's 9.88-second
headless import support adoption. The worker is finished; no automatic continuation.

The short group frame, long world entry, old unassigned spike and underground
connection remain open. The separate pullstone/scenery omission is corrected by
[PLAY-07](play07-scenery-arrival-result-2026-09-16.md), adopted as `c5ceb9f`:
instrumented creation 154.202 to 2.174 ms, full arrival frame 178.281 to 8.656 ms.
This is a substantial creature-loading correction, not a claim of hitch-free
play. The owner parked PLAY-06 navigation on 16 September. Further non-blocking
findings belong to end-of-wave cleanup. [RF-06 fen/lakeside atmosphere](rf06-fen-lakeside-worker-2026-09-16.md)
is prepared next, returning to the original creative plan.
The previous scope and observations below are retained as history.

Earlier status: both arrival slices were integrated: partial `87849bd` and the
[selected presentation fix `1bc19e9`](play03-presentation-hitch-result-2026-09-15.md).
After the initial 443 to 324 ms improvement, preparing shared fitted-fauna
resources during real world entry reduced the selected first boar arrival from
324.760 to 7.529 ms, adding about 0.9 s to entry preparation. The worker is complete.
The owner describes a seemingly massive improvement. The original underground
connection and other lag observations remain open; this is not a whole-game
performance claim. The inspection and initial scope below are historical context.

## New group-arrival report after the selected boar fix

The owner reports "still some considerable lag when a lot of mobs spawn in at
once unfortunately" and identifies "turtle + archers + cinder wisps". The earlier
brief-hitch/recovery account remains context; they did not supply a new duration,
count or world identity with this report. No Godot process was still running when
the coordinator checked the launch path, so the exact reported checkout is not
established by a live process. Do not claim the owner used an old build.

Confirmed code mapping: `hollow_knight` -> TortoisePresentation;
`cinder_archer` -> PorcupinePresentation; `cinder_wisp` -> articulated moth.
None is covered by the previous `finished`-family preparation. The first two
still have lazy scene/material acquisition; the moth's visible skinned mesh and
rig path is distinct. Synchronous MobPacks member/pack construction can also
combine work. These are leads to time, not a completed diagnosis.

The [group-arrival worker](play03-group-arrival-worker-2026-09-15.md) was prepared
in the existing D: checkout at `039bccf`, ahead of PLAY-06, using the retained
runtime/evidence. Its completed adoption is recorded above.

## Owner expansion to the full roster

The owner then asked: "Sorry can we just make sure we fix all the creatures/mobs?
is that all of them?" The same current worker brief now explicitly covers every
current creature presentation and spawn entry, including passive fauna, both
wisps, five LF aliases, elite/era variants and existing bosses. Eleven ordinary
IDs use the ten familiar visual families; existing boss presentation paths are
additional. The reported trio starts causal measurement, not the scope boundary.
Resolve repeated known loading omissions consistently and account for distinct
per-instance/group costs. Bounded checks of each distinct path are authorised;
full species/seed/renderer/status combinations remain unnecessary. This is an
expanded implementation scope, not a claim that those paths are fixed already.

## Owner observation

The owner reported during playtesting on 15 September 2026:

> A definite finding from this play test is the big lag happens when mobs 'pop' into existence.
>
> That must have been what was happening underworld if i dropped a long distance and suddently the underground fellas spawned - but its noticeable in the overworld once mobs 'spawn' in nearby.
>
> Ill still start that lake worker though now

Confirmed owner observation: a large lag event coincides with nearby mobs visibly
appearing in the overworld. The proposed connection to the earlier long descent
and underground lag is plausible but not yet demonstrated. Do not label this
underground-only, claim a loading/AI/GPU cause, or close the earlier lag issue.
The owner then clarified: **"A brief hitch, then recovers"**. Prioritise activation,
construction and first-display cost rather than ongoing cost while mobs remain
nearby. The exact species, world identity/location and measured duration remain
unknown. The earlier underground incident may still have differed; do not rewrite
its historical observations to match this newer report.

This is the new playtest evidence requested when PLAY-03 was parked. It justifies
resuming that specific investigation after the active lake slice, not reopening
R9 or a general performance intensive. Preserve legitimate caves and digging.

## Source inspection, not measured attribution

At main `c52395e` (before this note), `MobPacks` checks nearby activation every
0.4 seconds using a 28 m three-dimensional range. `_physics_process` can activate
multiple qualifying packs in the same callback. `_spawn_pack` loops through its
members synchronously: instantiate the enemy, compute surface support where
applicable, add it to the scene and finish setup. Cave members use their interior
floor. Sleeping-survivor, noise and siege paths also matter if the observed event
uses them; do not investigate every path without a concrete reason.

Scene entry calls `Enemy._ready/configure`, including `CreatureMotion.attach`.
The adopted presentations load/cache their model and material resources on first
use and instantiate/configure each rig. Cached resources do not prove that later
instantiation, scene registration or first drawing is cheap. First-use loading,
batch construction, support queries, animation setup, first-render pipeline work
and the first active actor updates are alternatives to distinguish, not confirmed
causes. The reported recovery makes sustained actor cost a lower-priority lead.

The existing `play03_trace.gd` observes frame intervals, terrain/resource phases,
render setup/pipeline counters and an enemy count sampled once per second. It
does not separately timestamp pack activation or individual construction phases.
Its existing terrain observations cannot rule mob arrival in or out. Reuse the
recorder and the [earlier diagnostic result](play03-underground-result-2026-09-15.md);
do not repeat the old synthetic shaft test as the default reproduction.

## Next focused slice

The prepared worker incorporates RF-05's V8 water/ground eligibility changes.
First add bounded opt-in phase markers
around actual activation, per-member setup and first active frames. Capture one
ordinary nearby-pack arrival, beginning before the pack is activated. Preserve
the cold first encounter; do not preload away the trigger in the diagnostic.
Within that short session, distinguish first-use cost, a subsequent arrival and
the immediately following recovered frames if needed. The owner reports recovery,
so do not add a sustained-population benchmark. No all-species/seed matrix.

Choose the smallest correction supported by the timing: for example resource
preparation, distributing construction or avoiding duplicated setup only if that
phase is responsible. Do not lower mob counts, strip approved art/animation,
change activation/aggro or loot, suppress underground mobs, or defer first use
into another equally disruptive frame as an unmeasured workaround. If construction
is queued, preserve population reservations, exact survivors/finite hosts,
death/loot ownership, noise semantics and safe cancellation across save/world/trial
boundaries. Keep existing land and lake behavior intact.

Default to at most three focused jobs on one renderer: causal arrival capture,
the same short arrival after the justified correction, and focused lifecycle/
ownership checks for the behavior actually changed. Reuse unchanged evidence.
Use the verified mouse-capture opt-out and no-focus launcher, D: output and no
per-frame disk writes. End owned jobs. Report measured improvement and any
unresolved sustained slowdown separately; no broad baseline or review wave.
