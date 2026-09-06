# Blender mob meshes, rigs and hitbox review

Owner continuation, 6 September 2026: "After that - mobs", following building,
land/nature and furnishing studies. This pass covers the existing roster: ten
hostile families, the Forge Tyrant and passive Valley Elk. It adds an authoring
recipe to the local Blender MCP, not new enemies or normal-game integration.

**Later integration, 6 September 2026:** the approved cataclysm intensive now
uses these twelve reviewed skins in normal actor configuration, adapted to the
existing combat-driven sampler and body contracts. See the
[runtime integration and checks](cataclysm-actor-craft-2026-09-06.md). The study
findings and source review below remain the record of the original art pass.

## Outcome

Twelve editable Blender rigs export as one skinned mesh and one vertex-colour
material per actor. Silhouettes distinguish stockier whelps, lean hounds,
six-legged plated crawlers, antlered elk, small suspended wisps, a bow-carrying
archer, shield guards, a flared-throat shrieker and the crowned, clawed Tyrant.
The armour was darkened after the first render to better suit the revised
weathered frontier direction. These remain visibly faceted prototype models.

The source reads existing family colours/scales, actor capsules and combat
timing. D-010/ADR-0003 retain engine time/space and simulation-owned numbers;
D-012 retains the first-person threat/readability context; revised D-013 supplies
the visual direction. Existing committed ranged aim, mob verbs, status rules,
elite mechanics, attack ranges, damage, loot, spawning and saves are untouched.

The rig follows CharacterLook's current body/head/paired-part arrangement: six
bones normally, eight for crawlers. One rigid weight per part keeps this within
the existing prototype approach. Family visual scale is applied into vertices
and joint rest positions, with unit object/root scale. A metre in the GLB is a
Godot world metre, facing -Z. The ground origin is retained.

| Actor | Role | Triangles | Bones | Clips |
| --- | --- | ---: | ---: | ---: |
| Ember Whelp | melee | 1,574 | 6 | 4 |
| Ash Hound | harry | 1,518 | 6 | 4 |
| Cinder Archer | ranged mark | 1,214 | 6 | 4 |
| Stone Husk | guard | 1,504 | 6 | 4 |
| Shrieker | recruit | 1,244 | 6 | 4 |
| Gloom Crawler | swarm | 2,124 | 8 | 4 |
| Bog Lurker | root | 2,124 | 8 | 4 |
| Marsh Wisp | kindle | 478 | 6 | 4 |
| Cinder Wisp | kindle | 478 | 6 | 4 |
| Hollow Knight | ward | 1,524 | 6 | 4 |
| Valley Elk | passive grazer | 1,690 | 6 | 2 |
| Forge Tyrant | claw / breath | 1,670 | 6 | 5 |

The 47 presentation clips are idle/walk for all actors, windup/release for
hostiles, plus boss inhale. Windup and inhale lengths come from the current
combat table. Release uses CreatureMotion's 0.22-second recovery. Idle is a
two-second inspection loop; walking is a one-second in-place stride. Neither
is an AI clock. The elk has no attack clips. Clips carry bone transforms only,
with no damage events or actor-root motion. They are separated through NLA tracks
using the installed Blender 4.5 exporter; each GLB contains only its own clips.

## Review artifacts

Reviewed output, ignored by Git:
`build/blender-study/90bcf4757796420fb8a292277d964158/`.

- `mobs-study.blend`: all editable rigs in hidden SOURCE, plus visible humanoid
  display copies. Isolate one SOURCE actor to edit it; all source roots are at zero.
- `mobs-beasts.png`, `mobs-humanoids.png`: Blender group renders at actual scale.
- Twelve actor GLBs and twelve `_collision.glb` capsule-envelope exports.
- `godot-review/mobs-roster.png`: labelled imported roster.
- `godot-review/mobs-collision.png`: existing capsules in green.
- `godot-review/mobs-motion.html`: local play/pause/scrub reel of 24 actual Godot
  frames, showing walking followed by the existing windup lengths and release.
- `report.json`: dimensions, bones, clips, source scales, primitive contracts,
  geometry hashes, attack range/muzzle data and visible collision discrepancies.

Repeat build:
`build/blender-study/1e543371c3b14f33bef3184c531dbefe/`.
All twelve animated visual GLBs matched byte for byte. Capsule proxy attributes
and triangles also match; Blender changes triangle ordering in some proxy files,
so their byte streams are not all identical. The imported CapsuleShape3D values
are exact and deterministic in both runs.

## Hitbox findings

The current Enemy scene uses one upright capsule, radius **0.35 m**, total height
**1.3 m**, centred at **(0, 0.65, 0)**. The boss uses radius **0.9 m**, height
**3.2 m**, centred at **(0, 1.6, 0)**. Family and 1.3x elite visual enlargement
do not resize the existing bodies. This study keeps that compatibility contract.

The art therefore exposes real mismatch instead of claiming a fitted hurtbox:

- Both wisps have about **0.694 m of empty capsule above the visible model**.
- Crawler legs and larger silhouettes extend outside their capsule. The bog
  lurker's furthest horizontal point exceeds the central cylinder radius by
  about **0.736 m**; tails/muzzles and shields also contribute visual overhang.
- Antlers, horns, weapons and posed extremities do not become extra hurt shapes.
- Attack reach is a separate gameplay distance, not the mesh bound. Ranged
  projectile launch height is also independent: the wisp's current 0.9 m origin
  sits above its small visible core. No launch point was moved by the art pass.

`mobs_collision_import.gd` recreates each source primitive as a CharacterBody3D
with a CapsuleShape3D, keeping the exact type, dimensions and offset. It does
not substitute Godot's approximate convex generation. The export checker also
invalidates only the relevant generated scene when adding a post-import script;
this fixes a same-second import-cache case found during the first fresh review.

Choosing per-family movement/hurt shapes is a separate combat decision. It
changes which shots count, gaps actors can cross and crowd contact. The current
study supplies the measurable discrepancy and retained baseline; it does not
approve or install those gameplay changes. Passing tests below establishes
compatibility, not that the current capsules fit every silhouette.

## Verification

**855 Godot checks pass** against the final review assets:

- one mesh, one material and the expected six/eight named joints per actor;
- independent comparison with the actual CharacterLook pivot function and actor
  scene capsule dimensions;
- normalized vertex weights, inverse-bind reconstruction of every rest vertex,
  exact imported rest bounds and valid joint origins;
- all 47 clip names/durations, finite changing skinned poses, no gameplay track
  types and stable actor roots; elk exports no attack clips;
- windup duration checked independently against `combat_realtime.json`;
- player-capsule and projectile-sphere contact/miss checks at four rotations;
- visual elite enlargement leaves the existing capsule unchanged.

A second project imported from scratch passed the 843-check version before the
additional twelve direct CharacterLook-source comparisons were added. The final
855-check suite then passed on the reviewed project. Both builds' visual GLBs
are byte-identical. Seeded geometry/colour/weight generation is compared twice
inside Blender; non-finite vertices and degenerate triangles fail the build.

Shared-tool regressions passed: 34 building checks, 90 nature checks, 302
furnishing checks, five MCP protocol tests and the plugin manifest validator.
The final Blender group views, Godot roster/capsule overlays and walking/attack
frames were inspected. The preview's screenshot export returned zero.

Godot emitted the same sandbox-only global-settings, shader-cache and Windows
certificate-store diagnostics as earlier studies. Local imports, physics and
rendered outputs completed. No simulation/gameplay code was changed, so the
native combat/economy suites were outside this authoring pass.

## Tuning and integration limits

[`mobs.json`](../../tools/wroughtwild-blender/mobs.json) documents seed, facet
variation, mesh resolution, roughness, family-colour mixing, armour colours,
preview loop lengths and sampling resolution. Geometry proportions are described
there separately from gameplay numbers. The recipe is available as
`build_mobs_study`, or `run_study.py --mobs`; see the
[`bridge README`](../../tools/wroughtwild-blender/README.md#mobs-and-creature-rigs).

Normal game actors still use their current meshes and CreatureMotion. An adapter
must account for the already-applied family scales and scaled rest pivots; blindly
reapplying Enemy's mesh scale or rebuilding an unscaled skeleton would be wrong.
Family colour is already baked into exported linear vertex colours, so it also
must not be multiplied in twice. The one-surface layout supports status material
replacement, but actual freeze/burn/elite/boss-telegraph material wiring is untested.

Runtime clips must follow actual travel and existing attack events, hold on
freeze, cancel on stagger and retain committed ranged aim. Do not run the old
procedural sampler and a new AnimationPlayer over the same bones simultaneously.
No clip owns hit timing or damage. The staged reel is not an AI or live-combat
playtest, and it does not exercise navigation, boss breath damage or save loading.

Rigid limb weights still look mechanical. Smooth knee/elbow deformation, feet
planted on slopes, IK, weapon contact poses, death animation, LOD and a crowd
performance review remain ahead. These are editable prototype studies, not a
finished production creature set or a change to combat balance.
