# Ranged counterplay and X removal — 5 September 2026

Author and implementer: Codex (OpenAI). Owner-approved combat priority following
the gathering and building passes, plus the reported X removal regression.

## Diagnosis and behaviour

Archers and wisps previously entered the generic melee windup, then applied a
hit whenever the player remained within their large attack radius. There was
no enemy projectile or aim direction to evade. Moving sideways inside the
radius could not work. The new behaviour commits the player's position at the
start of the existing windup, gathers a visible shot, and releases it in a
straight line. It never leads or homes toward a moving target.

The projectile sweeps its sphere through the entire frame's travel. A separate
initial-overlap probe prevents a muzzle inside cover from firing through it.
Solid terrain, resources, building colliders and other bodies stop a shot;
there is no friendly-fire damage. Range bounds missed shots. Stagger cancels
an unreleased shot; freeze pauses the existing windup and its visual charge.
Released shots continue independently of the shooter's movement or deletion.

On player contact, the existing PlayerCombat/sim path resolves mitigation,
train pressure and the surviving shooter's verb/status interactions. Raw damage
and damage type are captured on release. A deleted shooter cannot be dereferenced;
its shot still carries damage and name, but has no live-source status/verb or
retaliation interaction. Projectiles are temporary world effects, not saved.

Damage, cooldowns, windup durations, player speed and dash invulnerability did
not change. The engine still owns time and spatial contact under D-010 / ADR-0003;
the native tuning loader validates the new optional behaviour data and exposes
it through the existing realtime view. The round-based balance oracle remains
unchanged and does not model dodging or cover.

X matched both `remove_block` and `blow_horn`; the horn branch ran first. X now
belongs to removal in build mode, including when the aim misses. Outside build
mode it retains the horn. Open interactive panels block both. Removal still
uses the ordinary aimed-piece path, partial material refund and chest spill.

## Tuning

`data/tuning/combat_realtime.json`, optional `behaviours.*.projectile`:

| Field | Archer | Wisp | Player effect |
| --- | --- | --- | --- |
| speed_mps | 10 | 8 | Flight time; about 0.7 / 0.75 seconds at preferred distance |
| radius_m | 0.14 | 0.19 | Physical clearance needed to avoid contact |
| max_range_m | 14 | 12 | Distance before a missed shot disappears |
| muzzle_height_m | 1.05 | 0.9 | Launch/tell height above enemy origin |
| trail_length_m | 0.85 | 0.55 | Visible travel direction |
| colour | e8a060 | c7cc8c | Warm ember versus pale kindler mote |
| glow_energy | 1.2 | 1.0 | Shot centre brightness, without a dynamic point light |

`game/art/enemy_shot_look.tres` controls the cosmetic charge scale from 0.35 to
1.0 of the shot size. The shader softens the sphere's rim and brightens its
centre so the tell does not become an opaque disc over the creature's face.

## Verification and limits

Validation completed: 4,630 native checks, all existing engine regression
suites, and 53 focused ranged/input checks passed. The extension was rebuilt
and installed after the owner closed the running game. Final charge and flight
captures were rendered and visually reviewed; the gallery now links them.
The existing unit harness still prints its known invalid-input/tree/RID cleanup
warnings; no new errors appeared in the combat or rendered checks.

`tools/codex_visual_review.ps1 -Combat` runs deterministic checks and captures
charge/flight in the generated meadow. AI and projectile motion are paused only
for those inspection screenshots. The normal game uses continuous physics.

The focused fixture checks all three affected enemy families: release is not
instant damage; stationary targets take one hit; windup and post-release
sidesteps evade; walking at the actual player speed works at 20 and 60 update
steps per second; thin cover survives a long-frame sweep; initial overlap is
blocked; stagger removes the tell; deleted sources are safe. Physical X is
tested through both action bindings, including removal/refund while carrying a
horn, empty ground, an open inventory and horn use outside build mode.

This is the ranged-fairness part of combat feel. Incoming-hit direction,
held-weapon/cast presentation and the separately deferred skill-vocabulary
design are still outstanding. Pack overlap and perceived difficulty need owner
playtesting now that individual shots can miss. No new skills, rewards,
progression gates, external assets or save fields were introduced.
