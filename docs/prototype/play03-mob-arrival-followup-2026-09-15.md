# PLAY-03 follow-up — large hitches when nearby mobs appear

Status: new owner evidence; focused follow-up queued immediately after RF-05
adoption. The lake worker is already active and continues its selected scope.
No second runtime worker, rendered diagnostic or performance review was started
by this coordination update. Prepare the follow-up from adopted RF-05 main.

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

Prepare the implementation prompt/worktree after RF-05 adoption, incorporating
its V8 water/ground eligibility changes. First add bounded opt-in phase markers
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
