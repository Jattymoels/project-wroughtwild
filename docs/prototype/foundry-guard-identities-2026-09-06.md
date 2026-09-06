# Sixteen defensive Foundry identities

**Owner-approved continuation, 6 September 2026.** The owner asked to finish
distinct mechanics for every existing Kind/ingot input after melee playtesting
showed two differently named Quicksilver readings behaving alike. This work
completes the eight existing Bulwark Vanguard (`vanguard`) and eight Warding
Vanguard readings. It does not add a Kind, ingot, recipe, skill, progression gate
or save identifier. D-025 remains the routing and ownership contract.

Affected systems: Foundry form data, defensive spatial events, direct-hit and
incoming-hit hooks, and enemy projectile interception. The existing generic
armour seals, one-shot ward fields and small ingot-flavour modifiers are replaced
for these sixteen rows. Existing direct ingots, alloys, equipment, unrelated
forms and temporary trial boons keep their own rules. `FoundryGuard` implements
the defensive events; `PlayerCombat` supplies the actual cast and hit boundaries,
and `FoundryIdentity` arbitrates projectiles across the existing ward families.

## Bulwark Vanguard

| Ingot / existing name | Defensive decision and observable response |
| --- | --- |
| Ember — Furnace Bastion | Stand inside the casting brace to absorb up to 4 damage from one enemy hit. Its spent charge becomes a visible 0.45-second fuse, then vents once for 10% of the supported hit as fire. It cannot absorb again while waiting. |
| Frost — Rime Bastion | Place a boundary before pursuers arrive. Up to three new enemies crossing it receive 30 base chill and a 0.18-second interruption; occupants already inside at creation are excluded. Re-entering cannot trigger it twice. |
| Edge — Blade Bastion | Prepare a counter, take damage from a nearby attacker, then land a direct hit on that same attacker within 1.6 seconds. The answer delivers a 12% physical counter and a brief stagger. Hitting another enemy does not consume or pay it. |
| Reach — Broad Bastion | Commit a narrow crossbar ahead of the player. Up to three new enemies entering it are pushed 1.3 metres forward, opening retreat space. Rear flankers and enemies outside the strip are untouched. |
| Vigour — Living Bastion | Record up to 5 actual damage taken while inside. Remain there for one quiet second to recover it through ordinary healing. Another hit resets the wait; leaving forfeits the recovery. Casting alone supplies no life. |
| Plate — Bulwark | Settle near the casting position for 0.55 seconds to arm a finite 9-damage pool. Movement beyond 0.55 metres breaks the stance. The pool can cover several small hits but never refreshes with another cast. |
| Ward — Guardpost | Plant the post, then land a direct hit to designate one aggressor. Only that enemy's damage is reduced, by 20%, while the player remains inside. Other enemies and attacks received outside the post bypass it. |
| Haste — Quickbrace | Commit the casting direction for a short 0.5-second brace. A frontal enemy hit spends up to 5 absorption and returns 0.45 seconds to the longest running movement cooldown. Rear attacks and late hits do not trigger it. |

## Warding Vanguard

| Ingot / existing name | Defensive decision and observable response |
| --- | --- |
| Ember — Ember Veil | Intercept one shot, leaving a visible fuse at the crossing. After 0.6 seconds it bursts locally for 10% fire damage. The player can draw enemies toward the spent interception point. |
| Frost — Rime Veil | A small 0.65-metre interception front expands to 3 metres over 1.8 seconds. Its one caught shot releases 40 base chill near the crossing. Timing changes which flight path can meet the front. |
| Edge — Razor Veil | The first positive direct contact places a thin tripwire halfway between player and victim. A shot crossing that line snaps it into a 10% physical cut against enemies standing along it. Empty casts and triggered repeats do not lay wires. |
| Reach — Wide Veil | Project a broad screen 3.5 metres ahead, shortened by existing cover. It catches one shot travelling toward its front. Reverse travel, flanking shots beyond its width and shots above it pass. |
| Vigour — Living Veil | Interception leaves a recoverable life mote at the shot's crossing. The player must approach within one metre and have clear cover to receive 3 base life. It expires after 5 seconds without paying remotely. |
| Plate — Iron Veil | A caught shot leaves a mobile remnant for 3 seconds. The remnant absorbs up to 4 damage from one subsequent melee attacker; another ranged attacker does not spend it. |
| Ward — Aegis | Prepare a personal emergency ward for 4 seconds. It arms only once life falls below 40%, then follows the player until one projectile spends it or it expires. It does not heal or make the player invulnerable. |
| Haste — Fleeting Veil | A stationary decoy arms only after the player moves 2.5 metres away. A shot caught behind the departing player returns 0.4 seconds to the longest movement cooldown. Remaining at the origin grants no interception. |

## Safety and scaling

- Cast preparations come only from successful real inputs. Positive direct-hit
  hooks require the shared `practice_allowed` context, and commit one target
  per cast plus a player-wide cooldown. Linked, repeated and secondary events
  cannot manufacture counters, designations or wires.
- Each operation has a three-second preparation gate and cannot refresh an
  unspent instance. There are at most twelve live defensive event nodes per
  player, including spent-shot aftermath. Rejected events provide no payout.
- Interception queries return the first actual crossing on a world-limited
  segment. Shared integration compares it with other ward families before
  consuming the winner. Consumption changes mode or cancels immediately, so
  two shots in one frame cannot spend the same charge twice. Centre-to-crossing
  cover checks also prevent a ward shielding through a wall.
- Native rules resolve damage packets from the supported skill and its gear.
  These events request one explicit damage type and never generate another
  cast, link, mastery use or secondary defensive event. Chill resolves through
  native increased/more buildup and boss resistance without paying flat main-hit
  buildup twice. Boss stagger and shove use a 0.25 factor.
- Absorption consumes only positive enemy damage after ordinary mitigation.
  Living Bastion records actual life loss, not prevented damage. Ordinary heal
  scaling still applies. Environmental damage and dodges cannot spend these
  enemy-triggered charges. Aegis activation does not prevent the hit that
  lowered life enough to arm it.
- Charges use bounded physics clocks and no independent timers. Death and save
  application clear the `foundry_guard` group under the shared lifecycle; no
  charge or visual node introduces a new save field.

## Tuning and verification

`data/tuning/foundry.json` contains the sixteen replacement rows and their
numeric limits with plain-language purposes. The rows preserve `id`, `family`,
`kind`, `ingot` and pre-existing requirements. `data/tuning/items.json` supplies
their compiled reading modifier definitions; `game/scripts/foundry_guard.gd`
owns the runtime spatial events.

Thirty-five spatial/timing limits document lifetime and cooldown, shared population cap,
crossing dimensions, cast-to-screen distance, cover margin, settle/quiet timing,
boss control, collection range and small marker sizes. The individual form
effects above carry the payout and trigger values; seventeen further operation
ceilings bound combined copies. All fifty-two keys have plain-language purposes.
All are initial playtest
values; this pass establishes separate decisions, not equal defensive power.

`game/tests/foundry_guard_identity.tscn` prepares real legal routes through
normal skill input, then checks the sixteen roles and their refusal cases:
delayed/once-only aftermath, entry ownership, boss chill, targeted counters,
triggered-contact rejection, direction and cover, movement/quiet commitments,
collection, conditional arming, same-frame charges, non-refresh, death cleanup
and the shared node ceiling. Source checks confirm every referenced limit has
a supplied value/purpose and all sixteen form IDs are unique.

The isolated guard engine fixture passed **385 checks, zero failures** under
the coordinating task, including global-nearest projectile arbitration in both
family orders, preparation from an empty Heavy Strike and expired-pickup refusal.
No running game was
interrupted, game DLL replaced or normal user save written. The visible shapes distinguish a bodily
charge, boundary, directed bar and collectible; they remain modest prototype
effects. Normal melee/ranged encounter playtesting must judge timing,
readability and strength under combined builds.

The coordinated standalone native suite passed **195,279 checks, zero
failures**, compiled with `-Wall -Wextra -Werror`. It includes 4,608 base
Kind/ingot/alloy/skill combinations, 13,824 grade-alias combinations and 55,296
ordered Kind-pair/alloy/skill combinations. Thirty-six exact grade ownership
lifecycles preserve placement, save and paid lifting. Existing Ember, Frost,
Preserving, typed-gear, evolution and branch/reconvergence tests remain. New
operation signatures are independently enumerated, with typed-packet and
buildup scaling checks. These native checks establish data, ownership and
dispatch distinctions; the engine fixtures establish spatial response and
timing, and player testing remains the judge of feel.
