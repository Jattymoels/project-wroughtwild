# Creature motion and next priorities

Owner-authorised non-environment continuation, 5 September 2026.
Implemented by **Codex (OpenAI)** from `ec5efed` on local main.

## Direction

The next priority is readable living actors: movement, anticipation and release.
Then first-person hands/skill feedback and equipment comparison would address
two other visible prototype gaps. These are proposed follow-ups, not completed
features or new gameplay decisions.

The owner's environment note is retained in the art direction: trees and stones
alone leave the world barren even when their materials improve. The proposed
next landscape slice adds a limited middle layer—brush, fern beds, deadfall and
stumps—in habitat patches separated by clearings, with occasional landmarks.
Large harvestable-looking timber should be considered alongside the existing
wood interaction rather than silently becoming an unrelated resource. Placement,
interaction and yields need a concrete follow-up; this motion slice adds none.

## Implemented

The existing procedural character mesh is bound to six or eight bones, with one
rigid influence per authored part. Meshes remain shared and single-surface;
status flashes, ice, elite scaling and the boss telegraph keep their existing
materials. Bind poses preserve the existing authored geometry exactly.

Beasts trot with diagonal legs, crawlers alternate two tripods, and humanoids
counter-swing arms and legs. Wisps hover; the peddler has a restrained idle.
Gait phase follows actual horizontal displacement, corrected for visual scale,
so blocked bodies stop walking. Airborne enemies stop advancing the gait;
teleports do not spin it. Stable positional phase offsets avoid lockstep packs.

Wind-up reads the existing enemy timer; the boss's inhale reads its own timer.
A presentation-only `attack_released` signal fires at the existing attack instant,
including misses. It starts a short follow-through, never delays or deals damage.
Freeze holds every bone exactly; stagger cancels follow-through and shows a
backward recoil. Neither rig nor sampler writes body transforms, collision,
health, attack timing, AI decisions or save data. Dead actors retain the existing
immediate removal; no ragdolls or death rules were added.

## Tuning

`game/art/creature_motion.tres` uses documented exports in
`creature_motion_tuning.gd`:

| Control | Default | Visual effect |
| --- | --- | --- |
| `gaits` | beast 1.6 m / 28°, crawler 1.1 m / 22°, humanoid 1.35 m / 24° | Travel per full cycle and limb swing |
| `idle_hz`, `idle_metres` | 0.28 Hz, 0.008 m | Gentle settled breathing |
| `step_lift` | 0.025 m | Small body rise while stepping |
| `settle_rate` | 8/s | Fade gait weight after stopping |
| `release_seconds` | 0.22 s | Follow-through recovery after the real hit instant |
| `windup_radians`, `strike_radians`, `stagger_radians` | 0.13, 0.17, 0.19 | Bounded body lean |
| `lunge_metres` | 0.12 m | Visual forward reach, without collision movement |
| `hover_metres` | 0.055 m | Wisp idle height variation |
| `teleport_metres` | 2 m/frame | Reject teleports as walking |
| `cull_margin` | 0.4 m | Keep posed limbs in renderer bounds |

These distances are in authored mesh space unless explicitly world travel.
Pivots and small relative limb offsets are authored pose geometry, not combat
tuning. No engine-neutral tuning, generation or save schema changed.

## Reproduction and evidence

Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Motion`.
It imports scripts, checks mesh/material/motion contracts and renders 72 frames.
Open `build/codex-aesthetic/creature-motion/index.html` to play or scrub them.
The capture uses actual rigs with AI paused and stretched pose timing for
inspection; it is not a demonstration of normal attack cadence. `-FieldRoute`
separately drives the real controller, skills, AI and normal generated world.

The full headless pipeline passed: unit 397, art 11, integration 265, horde 43,
grammar 68, feel 17, faceted terrain 66, traversal 23, roof workshop 768,
woodland 16, save compatibility 9, presentation 29, material transitions 74,
and the new motion suite 100. Unit retains its known off-tree/dummy-renderer
diagnostics; the other suites and rendered review were clean. Motion checks
cover every vertex's binding, exact rest geometry, frozen pose preservation,
stopping when stationary, event-only follow-through, cancellation and rig replacement.

The 34-second live field route passed all 7 checks with the same 142.97 m,
32 peak enemies, 26 casts and 49 damage frames as `ec5efed`. On the RTX 5090,
1920×1080 Forward+, capped at 120 fps, walking median/p95 frame intervals were
8.007/9.332 ms (previously 7.811/9.331), combat 7.541/11.866 ms (7.663/11.606).
The sampled combat physics median rose from 5.673 to 6.509 ms with the rigs.
Terrain startup was 8.530 s versus 8.437 s. This short paced route includes
fixture healing and is not a balance verdict or an isolated GPU benchmark.

The skinning implementation uses Godot 4.5's documented
[Skeleton3D](https://docs.godotengine.org/en/4.5/classes/class_skeleton3d.html)
and [Skin](https://docs.godotengine.org/en/4.5/classes/class_skin.html) APIs.

## Limits

Rigid part binding leaves a mechanical quality to knees and elbows. Feet are
not planted with inverse kinematics on uneven terrain. This is a first motion
pass, not finished creature animation. Player hands, first-person skill motion,
death animation, model redesign and the environment middle layer remain ahead.
