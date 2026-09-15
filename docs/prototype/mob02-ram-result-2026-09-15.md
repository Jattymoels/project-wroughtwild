# MOB-02 — ram integrated into the normal game

The approved ram now has a weighted 23-bone rig, a four-beat walk, quiet idle,
braced guard pose and grounded forehead anticipation/follow-through. One skinned
runtime export and its original ART-06C maps now appear on the existing
stone_husk / guard enemy in ordinary worlds and Continue. Production is adopted
as `fb9fe9d`; native runtime integration is `5493470`. Both were successfully
pushed to origin/main on 15 September 2026.

**Limits:** Owner playtesting is deferred under the 15 September standing
approval; this is not a claim of personal playtest acceptance. The existing
upright collider does not fit the long animal silhouette. Small foot sliding,
generated fur/fold detail, no terrain IK/facial articulation, later-era physical
additions and unmeasured hardware remain limits.

## Completed native integration

`RamPresentation` supplies the selected rig and ART-06C scar/status material.
Normal Stone Husks walk with actual movement, brace while stationary and alert,
and use the existing windup and melee event for the forehead strike. Guard
eligibility, 110-degree facing arc, mitigation, health, damage, movement, reach,
era rules and collision remain native. No Enemy, save schema or gameplay tuning
was changed. Successful ordinary restoration uses the existing presentation
reset group to discard an unsaved cosmetic strike.

The adapter compensates the legacy 0.76 humanoid reduction once, giving 0.85 m
per source unit before family/elite scaling; it preserves proportions and faces
the forehead along native forward. The source's 0.32-second recovery is sampled
inside the existing 0.22-second cosmetic release window. An explicit 1.5 m
cosmetic stride accepts foot sliding to avoid frantic steps at native speed.
The descriptor documents a 0.12-second stationary idle/brace blend; it never
delays movement, damage or guard eligibility. Source cull margin remains 0.65.

Focused coordinator checks, with no baseline or renderer matrix:

- Main headless import: **4.02 seconds**, exit 0, no reported errors.
- Native actor with one Forward+ capture: **29 assertions passed**, **2.91
  seconds**. Actual pursuit/melee, guard front/rear/arc and stagger, native
  collider/numbers, material binding, freeze/status priority, pause, rebind and
  death passed. [Actual native actor capture](../../game/tests/mob02/evidence/native-ram.png).
- One ordinary seed-77 Stone Husk pack and SaveManager/Continue: **10 assertions
  passed**, **39.68 seconds**. World identity, exact progression and finite-source
  ownership survived; the rig/observer remained singular and the old strike cleared.

The worker's selected-master validation, **83 import assertions** and **4 capture
assertions** were reused. Source work was not rebuilt or reopened. The first main
import reported that Godot cannot import the animated WebP documentation clip.
The evidence directory now has `.gdignore`; runtime assets remain imported. The
original failure and final passing logs are retained in
`D:/Wroughtwild/work/mob02-ram/build/mob02/integration/`; compact final results are
also beside the selected native capture. No assertion was weakened or removed.

The rendered check asserted a visible pointer and unfocusable window and held
the shared renderer mutex. All owned check processes exited and the temporary
`game/override.cfg` was removed. No testing remains running.

To play later:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

Choose Continue or a new world and encounter a Stone Husk. Approach to see pursuit
and its forehead attack; circle its rear and use stagger to exercise the existing
guard rules. Try Save/Continue and pause. No art or showcase flag is needed.
The earlier animation preview below is the exported-model fixture; the native
capture above shows the integrated actor. Owner feedback, significant underground
lag and the remaining beetle/nymph/tortoise work stay open. R9 remains stopped.

## Production delivery and original integration handoff

- [Runtime model and descriptor](../../game/assets/authored/roster/stone_husk/asset.json):
  model.glb, base.png, orm.png and scar-mask.png.
- [Recipe and reproduction](../../tools/wroughtwild-mob02-ram/README.md);
  [joint/animation controls](../../tools/wroughtwild-mob02-ram/rig.json).
- Editable selected master:
  D:/Wroughtwild/source-art/mob02-ram/rig-v05/stone_husk-rigged.blend.
  Its rig-report.json and rig.json are retained beside it.
- Immutable inputs and checked setup receipt remain at
  D:/Wroughtwild/source-art/mob02-ram/input-art06c/.
- [Idle](../../game/tests/mob02/evidence/ram-idle.png),
  [forehead windup](../../game/tests/mob02/evidence/ram-windup.png),
  [11-second motion clip](../../game/tests/mob02/evidence/ram-motion.webp).

Source geometry: 293,246 triangles. Selected export: **109,998 triangles**,
54,353 Blender vertices / 108,351 imported vertices including UV/normal splits,
one surface, 23 bones and at most four weights. Automatic simplification retains
the long legs, tucked belly, open horn curls and physical lifelines; this is not
hand quad retopology. Two duplicate triangles found after collapse are removed
before skinning/export. The original dense source stays unchanged.

Both horns, ears and skull follow the head as supported structures. The uneven
neck skin deforms; the rear torso remains independent. Hooves are fitted to the
actual asymmetric source. No charging run, root motion, horn hitbox, additional
attack, guard state or movement restriction is introduced.

## Verification

Concrete risks were detached/deformed horns and legs, torso pulling, unreachable
hooves, lost clips/maps, cross-instance posing and stale action poses.

Three focused job groups were used, with corrections only for observed problems:

1. **Source/rig/export:** fitted weights and meaningful pose assertions pass.
   Maximum evaluated hoof-target error is 0.000000180 studio units; four weights
   maximum, with sum error below 0.000001. Final saved v05 reopens with a valid
   mesh, 23 bones, all five clips and all three required images packed.
   [Saved source check](../../game/tests/mob02/evidence/source-checks.json).
2. **Selected-asset headless import:** **83 passed, zero failed**, checking the
   actual GLB's skeleton, clips/durations, grounded sampled skin, torso stability,
   no root motion/gameplay tracks, loop endpoints, windup/release continuity,
   independent instances and interruption reset.
   [Import checks](../../game/tests/mob02/evidence/import-checks.json).
3. **Forward+ capture:** **4 passed, zero failed**, 264 actual exported-model
   frames at 24 fps (11 seconds). The mouse remained visible and the offscreen
   window unfocusable. The shared render mutex was held until process exit.
   [Capture checks](../../game/tests/mob02/evidence/capture-checks.json);
   [media details](../../game/tests/mob02/evidence/media.json).

The first rendered candidate exposed reversed action pitch; the lowered pose
then exposed skull weights reaching into the rear torso. Both are corrected in
v05 and the torso check was added for that actual failure. Initial fixture issues
(null shader-default read, lazy packed-image detection and one extra shutdown
frame) are corrected; final logs contain no script/shader errors. A stale v03
capture occurred after a rejected v04 build and is explicitly excluded from
final evidence. The selected evidence is only evidence-v05.

Unchanged ART-06C identity, deep-incision and original texture evidence is reused.
The copied runtime maps match the five-file setup receipt's map hashes. No
parent rehash/package copy, baseline, benchmark, renderer matrix, native rules
rebuild, game save write or broad regression run was performed. R9 remains stopped.

## Exact integration handoff

MOB-01 is now on main at f0349c2. Cherry-pick this production commit onto that
line and reuse its PorcupinePresentation / FinishedFauna pattern and shared
manifest dispatch. No extra owner approval is needed. This worker changed only
species-owned tools/assets/tests and this result file.

### Load, fit and materials

Load res://assets/authored/roster/stone_husk/model.glb. Paths relative to its root:

| Component | Path |
| --- | --- |
| Skeleton3D | RamRig/Skeleton3D |
| AnimationPlayer | AnimationPlayer |
| Skinned mesh | RamRig/Skeleton3D/RamSkin |

Use the imported Skeleton3D with manual animation sampling; retire the old
procedural skin driver for this enemy so two drivers do not compete. Duplicate
per-instance pose/material state. Keep existing status priority and native
labels/tells.

MOB-01's porcupine setup filters mesh names containing runtime_host and treats
other surfaces as separate face attachments. Bind the scar material directly to
this ram's single RamSkin surface; do not copy that name filter. Its eyes remain
ordinary atlas pixels outside the emitting mask. Add the ram dispatch/config in
CreatureMotion and the aggregate mob manifest without changing enemy.gd.

The GLB is Y-up and **+Z forward**. Turn it **180 degrees around Y** to match
Enemy's -Z facing. Start with uniform **0.85 metres per source unit** in Enemy
local space before family/elite scale, floor offset (0,0,0), and 0.65 source-unit
extra cull margin. Preserve aspect ratio. If attached beneath the existing mesh,
account for its legacy **0.76** humanoid reduction exactly once (0.85/0.76 local
scale before other family scaling); do not fit/squash the animal into the old
upright mesh envelope. Existing collider radius 0.35 m, height 1.3 m, hit reach
and native contacts remain authoritative.

Bind the three descriptor maps using the MOB-01 ART-06C shader route. The older
FinishedFauna flat scar_edge formula is not equivalent: darkening is
mix(base, base * damage_tint, scar.g), with damage_tint=(0.16,0.14,0.12).
Keep base as sRGB; ORM and scar are linear data. Scar RGB is core/damage/travel.
Core colour is the directly tested Godot Color(0.57,0.76,0.91) uniform (the fixture
does not apply an extra linear_to_srgb conversion), period 4 s, peak 2.4, residual 0.32,
crest width 0.20, travelling mode 3. Use explicit pause-aware scar_clock and
instance phase_offset. Apply existing status presentation after the host/scar
calculation. No normal map is required. The GLB's neutral fallback needs this
binding; it does not reproduce the living channels by itself.

### Clips and native timing

| Clip | Authored seconds | Intended loop | Use |
| --- | ---: | --- | --- |
| idle | 4.0 | Yes | Quiet breathing while unalert |
| walk | 1.4 | Yes | Four-beat in-place locomotion |
| windup | 0.6 | No | Sample native normalized windup progress |
| release | 0.32 | No | Cosmetic follow-through after native release |
| guard | 2.8 | Yes | Stationary alert brace or upper-body blend |

Godot's plain GLB import defaults these loops to none. Manually wrap sample time,
as the existing adapter does, or set LOOP_LINEAR on the three intended loops.
There are no method/event tracks.

The end of windup matches release time zero. The release's small follow-through
peak is at 0.0736 s and it returns to the guard pose at 0.32 s. Resample it into
the existing CreatureMotion visual release window (currently 0.22 s); do not
create a gameplay timer or delay damage to the authored clip's peak. Ordinary
windup remains 0.6 s and must continue to use the actor's actual timing.

Actual stance travel is **0.38 studio units over 66% of the cycle**, so the
source cycle represents **0.5757576 units**, or **0.4893939 m at scale 0.85**.
Touchdown/liftoff phases are in asset.json. Exact distance sampling at the native
2.8 m/s gives very rapid leg cycles; the descriptor suggests the existing fauna
**1.5 m cosmetic stride** as a starting cadence, explicitly accepting sliding.
Apply family/elite scaling once. This is a presentation choice, not a speed change.

**Guard has no separate native state.** It remains eligible by verb, facing,
life and stagger: 110-degree arc / 0.6 mitigation; era two retains its +40-degree
arc and timber-breaking behavior. Show walk during movement and sample/blend
guard only when appropriate for stationary alert presentation. The inherited
FinishedFauna sampler needs a ram-specific stationary chase/alert clip choice;
its existing windup, release, movement and status priorities should stay first. Do not stop the
actor to finish the guard clip. Freeze holds the pose; stagger/death interrupts
the action through the existing native path.

### Original coordinator check request — now completed above

Wire stone_husk in the shared MOB-01 path, then load/use it in its actual role:
facing aligns with native guard, stagger removes mitigation and cancels the
pose, the existing melee event samples the short strike, and ordinary Continue
loads with unchanged saves/ownership. Reuse this source/import evidence. Broader
combat balance, performance and owner playtesting remain later work.

## Original production publication boundary

The production commit contains only the owned paths listed above, on
codex/mob02-ram, based on 65faafed2ee179a71222c426c8947c9af224e9e8.
The worker commit is `cac53672cf08e1029f274756c0ff6065a8c32939`. The coordinator
cherry-picked it as `fb9fe9d` and completed normal-game adoption in `5493470`.
The ordinary `84c89b8..5493470` push to origin/main succeeded, including both
production and tested runtime integration. The status documentation was updated
after that successful publication; tested runtime values were not changed.
