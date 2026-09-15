# MOB-03 — crane rig and animation production

Work in `D:/Wroughtwild/work/mob03-crane`, branch `codex/mob03-crane`.
Read `build/mob03/SETUP.md`, current owner AGENTS.md and the
[parallel production boundary](mob-parallel-production-2026-09-15.md).
MOB-01 owns shared game integration while this work proceeds independently.

Deliver a weighted, animated runtime-ready crane for the existing `shrieker`
recruiting role from the approved ART-06C source. Preserve two long supporting
legs, a readable beak and ordinary eyes, folded attached wings, the expanded
supported throat resonator and deep throat/keel lifelines. It stays a grounded
bird, with no flight, sonic damage or new recruitment rule.

Selected inputs are `D:/Wroughtwild/source-art/mob03-crane/input-art06c/`, copied
from the original handoff's `sources/shrieker/`. Begin from
`shrieker-surface.blend`; author a new version without overwriting it.
Own only the MOB-03 paths listed in the parallel boundary and
`docs/prototype/mob03-crane-result-2026-09-15.md`.

Fit the actual two legs/feet, body, neck/head and beak. Keep folded wings rooted
to the shoulders and throat cavities visibly open. Provide `idle`, `walk`,
`windup`, `release` and `call`. A supported neck/throat expansion and beak opening
should make the call legible; a small peck represents the ordinary weak close
attack. Avoid a throat collapse, detached lower beak or wing motion that implies
takeoff. Fine feather and foot-IK polish can wait once gait and call read well.

Important integration fact: the current recruiter uses `Enemy._scream_timer` and
`Enemy.force_scream()`, separately from its melee windup/release. `force_scream()`
resets the timer, wakes living idle enemies in the current radius, then displays
the native ring; it currently emits no `attack_released` event for the call.
Do not pretend that wiring the `call` clip to ordinary melee release is correct.
Document a minimal observer/event hook at the actual call for the coordinator;
do not edit shared `enemy.gd` or invent a parallel recruitment timer here.
Ordinary current period/radius are 4 seconds/14 m, with native era adjustments.
Animation follows those rules and cannot delay or cause the recruitment effect.

Produce one useful export, species descriptor and short motion capture as defined
in the shared boundary. Reuse source evidence and report remaining limitations.
Return the checked production commit and precise normal-game wiring notes. This
is ready for sequential integration after porcupine/ram, not a claim that crane
gameplay is already installed. No extra owner approval is needed for the
coordinator to finish it.
