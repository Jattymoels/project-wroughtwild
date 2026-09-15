# MOB-02 — ram rig and animation production

Work in `D:/Wroughtwild/work/mob02-ram`, branch `codex/mob02-ram`.
Read `build/mob02/SETUP.md`, current owner AGENTS.md and the
[parallel production boundary](mob-parallel-production-2026-09-15.md).
MOB-01 owns shared game integration while this work proceeds independently.

Deliver a weighted, animated runtime-ready bighorn ram for the existing
`stone_husk` / `guard` role from the approved ART-06C source. The original
armadillo direction was rejected; retain the selected upright lean ram, visible
long legs, tucked belly, open mineralised horn curls and uneven neck/horn growth.
Keep the torso visibly animal and unarmoured, with deep connected lifelines.

Selected inputs are `D:/Wroughtwild/source-art/mob02-ram/input-art06c/`, copied
from the original handoff's `sources/stone_husk/`. Begin from
`stone_husk-surface.blend`; author a new version without overwriting it.
Own only the MOB-02 paths listed in the parallel boundary and
`docs/prototype/mob02-ram-result-2026-09-15.md`.

Fit the actual four legs/hooves, spine, neck and head; horns follow the head as
supported structures, not independently waving growth. Provide `idle`, `walk`,
`windup`, `release` and a `guard` stance. A braced forehead and grounded short
head strike communicate the existing guard/melee behavior. Preserve silhouette
and horn clearance through the important poses. No charging run, rush movement,
horn contact hitbox or additional attack. The guard clip can blend/switch during
integration; it must not create guard state or lock the actor's movement.

Reference current `enemy.gd` and `combat_realtime.json`: guard depends on native
facing, its arc/mitigation and interruption by stagger. The ordinary current
windup is 0.6 seconds; clips are sampled to the native timing, not a new clock.
Read existing era adjustments without designing new physical era forms here.

Produce one useful export, species descriptor and short motion capture as defined
in the shared boundary. Reuse source evidence, keep small cosmetic limitations
honest, and preserve the current native body/save/gameplay contract. Return the
checked production commit and precise normal-game wiring notes. This is ready
for sequential integration after porcupine, not a claim that ram gameplay is
already installed. No extra owner approval is needed for the coordinator to finish it.
