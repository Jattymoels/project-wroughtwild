# MOB-02 — checked ram production and integration handoff

The approved ram now has a weighted 23-bone rig, a four-beat walk, quiet idle,
braced guard pose and grounded forehead anticipation/follow-through. One skinned
runtime export and its original ART-06C maps are ready for the coordinator to
install as the existing stone_husk / guard enemy after MOB-01.

**Limits:** normal-game wiring and its short actual-role/Continue check remain
coordinator work. Owner playtesting is deferred under the 15 September standing
approval; this is not a claim of personal playtest acceptance. The existing
upright collider does not fit the long animal silhouette. Small foot sliding,
generated fur/fold detail, no terrain IK/facial articulation, later-era physical
additions and unmeasured hardware remain limits.

## Delivery

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

### Coordinator's remaining short check

Wire stone_husk in the shared MOB-01 path, then load/use it in its actual role:
facing aligns with native guard, stagger removes mitigation and cancels the
pose, the existing melee event samples the short strike, and ordinary Continue
loads with unchanged saves/ownership. Reuse this source/import evidence. Broader
combat balance, performance and owner playtesting remain later work.

## Commit/publication

The production commit contains only the owned paths listed above, on
codex/mob02-ram, based on 65faafed2ee179a71222c426c8947c9af224e9e8.
The final task response supplies its exact SHA and branch publication result.
Mainline adoption is still pending the coordinator's sequential integration.
