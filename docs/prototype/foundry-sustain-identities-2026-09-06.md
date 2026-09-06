# Marrow and Sipping Marrow: sixteen sustain identities

**Status:** Implemented under the owner's 6 September approval to complete all
Foundry inputs. This is the sustain slice of that work, following D-025's specific
Kind/ingot grammar. The isolated runtime fixture passes **273 checks, 0 failures**;
the owner's running game was not interrupted.

## Outcome and boundary

The existing sixteen names and ownership IDs now describe sixteen different
ways to earn recovery. Their old shared recovery field or homing mote and the
small ingot-flavour additions are replaced. The Marrow and Sipping Marrow Kind
bases, ordinary direct ingots, alloy refinements, equipment and owned coordinates
remain unchanged. There is no new damage packet, currency, passive regeneration
or persistent combat charge.

Every base opportunity pays **2.5 life once**, capped at **5 base life** across
duplicate readings before the existing healing multiplier. Ironroot and Iron
Drink additionally limit base recoup to **half the actual post-mitigation damage
that triggered them**. They do not prevent that hit or revive a dead player.

| Existing route / name | Distinct action required |
| --- | --- |
| Marrow → Ember / Phoenix Bed | A direct kill leaves a seed. It ripens after 0.7 seconds; approach within 1.2 clear metres to collect it. |
| Marrow → Frost / Winterroot | Hit an already chilled living enemy, then stand within 2 clear metres of it for a continuous second. Moving more than 0.35 metres restarts the hold; losing the target or its chill ends the opportunity. |
| Marrow → Edge / Bloodroot | A real hit marks an already bleeding enemy. Directly execute that target within five seconds and four clear metres to collect its recovery. An already bleeding killing hit can both mark and execute. |
| Marrow → Reach / Harvest Ground | The first direct kill seeds a harvest. A second distinct direct kill within three clear metres ripens it; the player must then collect it physically. |
| Marrow → Vigour / Second Spring | A landed hit at or below half life stores recovery. Two seconds without positive incoming enemy damage release it; another hit restarts the quiet interval without refreshing the overall lifetime. |
| Marrow → Plate / Ironroot | A landed hit prepares recoup. The next damaging enemy hit fixes the recovery amount and position; hold that position for a second to receive the bounded recoup. |
| Marrow → Ward / Safe Harbour | A direct kill leaves a harbour. Spend 0.8 seconds within three clear metres with no living enemy sharing that space. Threats interrupt the wait. |
| Marrow → Haste / Fleet Harvest | A direct kill releases a pod moving away at 1.6 metres per second. After its 0.35-second head start, leave the original position by at least 0.6 metres and catch it. Cover stops its flight. |
| Sipping → Ember / Cinder Siphon | Hit an already burning enemy and keep a clear tether for 0.8 seconds while its burn survives. The earned cinder then physically returns at nine metres per second; new cover can still stop it before arrival. |
| Sipping → Frost / Cold Siphon | Hit an already chilled living enemy to store a charge. A successful real movement-skill cast spends it. Walking alone cannot. |
| Sipping → Edge / Bloodletter | Land three separate real casts on the same bleeding target inside the opportunity window. A fan, fork or repeated contact from one cast counts once. |
| Sipping → Reach / Long Drink | Hit from at least four metres, maintain a clear tether for one second, then retreat another metre from the source to draw recovery. Closing inside four metres or breaking cover loses it. |
| Sipping → Vigour / Deep Drink | Sample two different living enemies using separate real casts. The next successful real cast spends the filled reservoir. The synchronous melee cast that fills it cannot also spend it. |
| Sipping → Plate / Iron Drink | A successful real cast braces its position. Take an enemy hit there, then counterhit that actual attacker to receive bounded recoup. Another enemy cannot pay the debt. |
| Sipping → Ward / Ward Siphon | While rooted, harried or marked, land a real hit. Recovery waits until every affliction captured at that contact clears. It does not cleanse, shorten or prevent the affliction. |
| Sipping → Haste / Quick Sip | Land a real hit, then contact with a different real skill within two seconds. Repeating the same skill cannot spend it. |

## Event, cover and equipment contracts

- `contact` snapshots the pre-payload ailment state into the shared cast context.
  It cannot create a charge or healing by itself. `landed` consumes that snapshot
  only after positive direct damage to a living hostile. Both require the real
  input eligibility flag, excluding linked/echo casts and secondary packets.
- Contact progress uses `FoundryReactions._commit`: one eligible contact per
  operation per shared cast, including the first contact that creates a counter.
  New opportunities have a three-second player-wide gate per role. Progress
  contacts also have a 0.12-second minimum interval, preventing same-instant input
  duplication without replacing the chosen base skill's normal cooldown.
- One opportunity per role and at most sixteen total may be live for a player.
  Excess events are rejected without payout; duplicates cannot refresh a timer.
  Windows last five seconds, except Quick Sip's two-second window. Expiry is
  checked before collection, so a long late frame cannot revive an expired reward.
- Physical collection, stationary harvesting, execution return, nearby-kill
  joining and tethers check existing solid cover. Both tethers are limited to
  nine metres. Personal charges earned by a previous hit remain personal.
- Living bosses support the contact roles under the same life budget. No boss
  control, immunity, damage or ailment clock is changed. Kill-gated and multi-target
  roles intentionally need kills or multiple targets and do not manufacture
  substitutes in a solitary boss encounter.
- Payout consumes the event before calling `combat.heal`. That existing path
  applies healing investment and the maximum-life ceiling once. Healing cannot
  cast skills, create child damage, award mastery or generate another sustain
  event. Movement alone never fabricates a damaging contact.
- The `foundry_sustain` group joins the host's death/load cleanup. No transient
  timer, corpse opportunity, sample counter or unclaimed heal is saved. The new
  helper owns no native source, inventory or equipment state.

## Tuning and implementation

`data/tuning/foundry.json` contains the sixteen replacement form rows, 48 numeric
limits and their 48 plain-language purposes. `data/tuning/items.json` contains
the compiled reading modifier definitions. Each
`mutation_identity_<role>_life` is the form's amount; its matching unprefixed limit
is the native stacking ceiling. Remaining limits control the timing, distances,
counts and recoup share described above. `sustain_return_arrival` is the 0.15-metre
arrival tolerance, and `sustain_visual_radius` is a cosmetic 0.45-metre marker.

`game/scripts/foundry_sustain.gd` owns the terminal opportunities and their spatial
clocks. The host calls `cast`, `contact`, `landed`, `killed` and `damaged` at their
ordinary gameplay boundaries. `FoundryIdentity` supplies common geometry and
cover helpers. Ring, spike, bar and orb markers expose different object/memory
roles without introducing another effect framework or asset dependency.

`game/tests/foundry_sustain_identity.tscn` lays all sixteen legal native Foundry
routes, then exercises each role through the ordinary payload/deal entry points
with explicit shared real-cast contexts and controlled elapsed time. It also
checks a successful movement cast, first-contact deduplication, pre-damage refusal,
recoup bounds, cover, chilled-boss use, expiry, duplicate charges and death cleanup.
It also activates the retained native Brittle hook explicitly as a synthetic
compatibility composition: an immune direct packet can still execute its frozen,
bleeding target and damage a neighbour through the legacy nova, but it cannot
seed or pay new contact/kill sustain. A real direct packet kill still creates and
collects its one Phoenix seed. The host snapshots direct packet damage and kill
ownership before adding cascade feedback, preserving the established aggregate
damage and ordinary reap behaviour.
Those checks establish mechanics; human fight feel and combination balance remain
playtest work. Broader integration results are recorded by the shared work item.

The isolated run exposed one runtime correction: a dying enemy leaves the live
enemy group before Godot deletes its collision body. Harvest's immediate second-
kill joining ray therefore explicitly excludes both known corpse bodies while
still checking terrain and building cover. Bloodroot uses the same rule for its
execution return. Independent fixture cases now flush queued bodies before later
cover checks, and the death-cancellation assertion isolates the normal player
respawn callback, whose deliberate full heal is a separate established contract.
