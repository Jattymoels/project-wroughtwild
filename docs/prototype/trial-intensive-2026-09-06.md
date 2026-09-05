# Trials worth mastering — Forge intensive

Status: owner approved for implementation, 6 September 2026. Author: Codex.
Decision D-028. This explicitly brings forward a bounded repeatable endgame loop;
it does not approve an Atlas, consumable maps, more eras or a trading economy.

Playable foundations, story floors, suspension and repeatable tiers are
implemented. See the [combined implementation review](intensives-review-2026-09-06.md)
and [fixed-build measurement method](trial-balance-2026-09-06.md). Full-run
pacing and final combat difficulty remain pending the owner's playtest.

## Outcome and content

One coherent Forge complex uses eight authored spatial modules: threshold
gallery, loading yard, fuel chamber, kiln hall, ward gallery, cistern, secret
crucible and heart forge. Physical branches preview rewards and threats; local
encounter triggers and built-in trial navigation replace the single arena loop.

The Tyrant, Deeper Forge/Warden and Ash Tide capstone each occupy two floors,
targeting twenty minutes with a prepared familiar build. Keep the first two
curios and their landmark era changes. The capstone requires ash_tide and grants
forge_arc_complete, without creating era four. Its furnace encounter reuses the
Warden rig, combining vent lanes, ward conduits and vulnerability windows.

Four boon opportunities per story run, three compatible choices per offer,
twelve boons and three optional weaknesses support the persistent build. Two
secret variants share one optional secret opportunity per run. Ordinary life and
defence remain the failure system. Initial story groups contain six to ten mobs;
reinforcements respect a twenty-four living-enemy limit and two major hazards.

## Repeatable runs

After forge_arc_complete, choose an unlocked tier and one of three seeded offers.
Each offer previews pack, rare, boss and reward conditions. A clear at T unlocks
T+1; extraction/failure never removes access. Gate reopening, tier changes and
reloads preserve the offer batch; successful entry advances it atomically.

Eight conditions: crowded packs, roaming reinforcements, warded rares, volatile
rare-death eruptions, ranged crossfire, reinforced guards, shorter boss recovery,
and furnace hazards. Roll two at tiers 1–3, three at 4–7 and four thereafter;
exclude duplicates/incompatible combinations. One-floor routes target ten minutes
and two boon offers. Population and complexity remain bounded as numerical tier
scaling continues. Tiers 1–10 are the calibration target; higher balance is
unverified. Targeted source-material hauls join existing gear and Kind rewards.

## State, suspension and verification

Simulation owns structure, run conditions, offers, rewards and progression;
Godot owns geometry, navigation, encounter timing and hit detection. Keep existing
trial entry IDs compatible. Explicit encounter/boss IDs prevent unrelated kills
or cleanup from granting completion.

At a cleared story-floor boundary: continue, bank and leave, or suspend and quit.
Checkpoint the complete deposit, at-risk rewards, run/route/RNG state, temporary
effects, build and life, with the matching world/player save. Restore through a
validating factory rather than a new deposit. Atomic saves retain the prior good
file on failure. Suspension grants no heal, extraction or duplicate reward.
One-floor maps have no intermediate suspension. Existing Ember/death protection
and permanent equipment remain intact.

Test routes, navigation, optional-room independence, rewards, deposits, failure,
stable offers, progression and checkpoint restoration. Actual-build fixtures for
Ranger/Warden/Kindler measure survival, duration and boss exposure; scripted
auto-kills are regression tests only. Capture player-height traversal and tells
under Foundry effects and compare frame timings. Numerical balance remains
provisional pending the owner's combat/class playtest.
