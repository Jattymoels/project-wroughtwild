# Combat direction and presentation — 5 September 2026

Author and implementer: Codex (OpenAI). The owner approved completing incoming-hit
direction and existing weapon/cast presentation after ranged fairness. The larger
skill-vocabulary task remains separate.

## Player-visible changes

A brief arc and outward pointer show the bearing of a hit that actually damaged
the player. Front is above the crosshair, rear below, with left and right at the
sides. Turning rotates the remembered bearing relative to the camera; moving
the attacker afterward does not move the marker. Enemy projectiles supply their
incoming flight direction, including after the shooter disappears. Damage with
no known planar source, such as burning ground, produces a faint complete ring
instead of an invented direction. Repeated bearings merge, the count is bounded,
and the display clears on death and expires normally. It never captures mouse
input. Existing source-name notices remain.

Equipped weapon bases now have procedural first-person models: bows, the flanged
iron mace, frost/bronze sceptres and the ember wand/charred brand. The observer
reads equipped items and refreshes after changes; it never grants a weapon or
requires one to cast a skill. The bow sits in the left hand; other weapons in the
right. Models withdraw with the hands and hide near cover, during ordinary
harvesting, in building mode, menus and third-person view.

The existing skill delivery and tags select the gesture: downward strike,
diagonal Rend, lateral sweep, outward nova, bow release, cupped frost cast and
one-handed ember flick. A brief strike trace or area rim accompanies committed
melee/area casts, including misses. It appears at the existing hit instant and
fades; it is not a delayed attack or a new damage field. Area size reads the
existing radius, Reach, area bonus, isolated multiplier and cone angle.

Actual player projectile nodes now carry arrows with shafts/fletching, elongated
embers with tapered tails, or frost cores with rotating satellites. Their flight,
collision, pierce, forks and payload rules are untouched. Long life/defence/status
text wraps inside the left panel instead of running across the skill bar.

## Tuning and boundaries

`game/art/combat_feel.tres` uses the defaults in `combat_feel.gd`. All values are
cosmetic; no native combat tuning, damage, cooldown, movement or save fields change.

| Setting | Default | Controls |
| --- | --- | --- |
| hit_seconds | 1.15 s | How long a remembered incoming bearing remains visible |
| hit_radius_fraction | 0.20 | Compass radius as a fraction of the shorter viewport side |
| hit_arc_degrees / hit_width | 32° / 5 px | Direction arc span and line thickness |
| max_hit_directions | 6 | Maximum simultaneous bearings; nearby hits refresh one |
| hit_colour / unknown_colour | d78970 / b3a596 | Directional hit and non-directional damage colours |
| strike_seconds / sweep_seconds | 0.34 / 0.42 s | Strike/Rend and sweep hand recovery after the instant cast |
| nova_seconds / bow_seconds / spell_seconds | 0.48 / 0.40 / 0.38 s | Nova, bow and other cast recovery |
| swing_metres | 0.22 m | Hand displacement scale for the principal strike/cast gestures |
| effect_seconds / max_cast_effects | 0.25 s / 12 | Cast aftermath fade and simultaneous effect budget |
| weapon_scale | 0.72 | Held mesh size in camera space |
| equipment_refresh_seconds | 0.20 s | Maximum idle delay before reflecting equipment changes |
| physical / fire / cold / bleed colour | b7aea0 / d99152 / 95c5d2 / a97267 | Restrained effect palettes |

Existing hand position, walking sway and wall avoidance remain in
`first_person_look.tres`. Geometry dimensions and pose rotations are authored art
in `combat_visuals.gd` and `first_person_hands.gd`, rather than combat tuning.

These are prototype procedural meshes, not a full animation/asset library.
Offhand and third-person held equipment, bespoke audio and additional skills are
not included. The flat area rim is cosmetic and can intersect uneven terrain;
it does not claim to show occlusion or a delayed wavefront. Skills remain usable
without matching equipment, as before. A visually narrow arrow keeps the existing
projectile collision clearance.

## Reproduction and validation

`tools/codex_visual_review.ps1 -CombatFeel` runs focused checks and seven real
Godot captures: incoming damage at 720p/1080p, strike, sweep, bow, nova and a
side-on inspection of the actual projectile nodes. The review equips fixture
items and pauses actors/effects for inspection; it never writes the owner save.

The focused fixture exercises source bearings, camera turns/pitch, deleted
shooters, rejected/zero hits, environmental hits, merging/caps/expiry/death,
distinct profiles, cooldown refusals, effect cleanup, every current weapon base,
unequipping and projectile visual alignment. It verifies that cosmetic sampling
does not move the camera, player or projectile, or mutate the native save state.
Additional checks cover status wrapping and compass sizing at both resolutions.

Final validation: all 65 combat-presentation checks and the complete Godot
headless suite passed. All seven rendered captures were visually reviewed, and
the local aesthetic gallery includes the completed pass.
