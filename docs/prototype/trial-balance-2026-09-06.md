# Forge combat measurement — 6 September 2026

Latest human feedback: melee is tough but rewarding; the trial is understandable
but still feels too easy and does not yet demonstrate a convincing build identity.
The [playtest record](playtest-feedback-2026-09-06.md) distinguishes this observation
from proposed density/difficulty changes. The exact build, run and runtime version
are unknown. The cohort below predates the completed Foundry identity pass and
does not establish balance for all 96 current readings.

This is a bounded automated measurement pass for the
[approved Forge intensive](trial-intensive-2026-09-06.md). It measures actual
Godot enemy and boss physics, collision, projectiles, skill cooldowns, damage,
status effects and permanent Foundry configurations. It does not certify human
balance or the twenty-minute story and ten-minute repeatable-run targets.

## Reproduction

Run `game/tests/trial_balance.tscn` with a workspace log file and no other heavy
review processes. `--smoke` restricts the sample to three prepared builds at
tier one; `--boss-only` samples only final encounters. `--diagnostic --boss-only`
reproduces the Ranger starting-build tier-two Tyrant case used to investigate
movement and floor recovery. `--pack-diagnostic` reproduces the starting Ranger
tier-one pack case that found the unused gallery doorway. The full pass samples
an opening pack and a final boss for each of nine fixed build/progression
combinations at tiers one to ten.

`game/tests/trial_balance_config.tres` uses gate seed 741103 and offer zero at
each tier. This fixes the conditions and boss identity before testing. The
fixture runs 240 physics ticks per real second with time scale eight, giving a
reported simulation step of 1/30 second. The bot makes movement and skill
decisions every 0.12 simulated seconds. Each encounter ends on clear, death or
thirty simulated seconds; a timeout is never counted as a clear.

The bot fights through normal `PlayerCombat.use_skill` calls and ordinary
movement/dash physics. It targets warding/support enemies before bosses, holds
approximately 7.5 metres for ranged builds or 2.1 metres for melee, strafes and
responds to visible danger. It does not inject hits, remove enemy life or force
enemy deaths. Final-room setup skips the preceding four native encounters and
opens their matching physical gates; setup rewards and elapsed time are excluded.
It accepts no temporary boons in these isolated measurements.

## Fixed permanent builds

Every weapon and body item is made and equipped through the native crafting,
ingredient, station, skill and item-quality rules. Fixture supplies and progress
unlock legal actions; item statistics are not replaced with invented values.
All cases use the same Ash Tide map context. Starting builds receive map access
as a test fixture, not as a claim that they have completed the story arc.

| Progress | Ranger | Warden | Kindler | Shared preparation |
| --- | --- | --- | --- | --- |
| Starting | Simple bow | Wooden cudgel | Wooden focus | Hide vest; ordinary class skill bar |
| Prepared | Hunting bow | Iron mace | Charred brand | Iron chest armour; basic fire temper; primary skill at (1,1), Ember support at (1,0) |
| Developed | Bronze longbow | Iron mace | Bronze sceptre | Bronze mail; basic fire temper; prepared configuration plus Ember Kind at (2,0) and Frost support at (0,1) |

Prepared/developed crafting uses blacksmithing XP 225/300. These particular
native recipe rolls produce Rough items. The developed fixture therefore means
bronze equipment and a larger permanent Foundry configuration, not a maximised
endgame build. The JSON report retains each exact item, derived stat sheet,
skill bar and Foundry plate so the cohort can be reviewed without guessing.

## Findings and limits

Initial measurements exposed two separate problems. The boss fixture advanced
native stages without opening the corresponding earlier physical gates, so its
long-distance pursuit results were invalid as balance evidence. Independently,
the live floor safety check could send an out-of-bounds player all the way back
to the entry. The fixture now mirrors cleared gates, and live recovery selects
the nearest clear navigation cell. Navigation clearance now accommodates the
boss capsule, waypoint arrival avoids cutting cover corners, and the cistern
troughs leave their doorway aprons open. Hallway and connector rails now close
side gaps found by strafing probes; a gallery side with no room has no doorway.
Bosses remain grounded on the Forge's flat floor instead of attempting the
world-mob ledge hop against cover.

The final diagnostic Ranger/Tyrant sample cleared in 11.43 seconds with two
boss tells and 48.36 life damage received. Maximum player/boss separation was
11.0 metres, and there were no floor rescues. These values describe one scripted
encounter, not a run duration or a general Ranger success rate. Apparent
chase-stall time initially included
intentional boss recovery; the recorded metric now excludes recovery and earned
freeze/stagger before identifying a stopped chase.

## Final corrected cohort pass

The [raw final report](../../build/intensives/trial-balance-final.json) contains
180 encounter samples: **90 clears, 48 deaths and 42 timeouts**, with zero setup
errors and zero floor rescues. Bosses produced **322 heavy-attack tells**.
Earlier diagnostic files and partial passes in `build/intensives` are excluded
from these totals. Every row below contains ten opening-pack encounters and ten
boss encounters, one of each at every tier from one through ten. Times are
medians of successful clears only; timeouts are excluded from those medians.

| Fixed cohort | Pack clear / death / timeout | Pack clear median (s) | Boss clear / death / timeout | Boss clear median (s) | Median boss damage received | Boss tells |
| --- | --- | --- | --- | --- | --- | --- |
| Ranger starting | 2 / 1 / 7 | 19.0 | 3 / 4 / 3 | 13.3 | 47.3 | 42 |
| Ranger prepared | 2 / 1 / 7 | 19.7 | 4 / 4 / 2 | 11.9 | 70.8 | 40 |
| Ranger developed | 4 / 1 / 5 | 18.9 | 4 / 2 / 4 | 11.4 | 69.5 | 40 |
| Warden starting | 6 / 4 / 0 | 14.7 | 4 / 6 / 0 | 12.1 | 104.1 | 21 |
| Warden prepared | 8 / 2 / 0 | 10.0 | 4 / 6 / 0 | 11.4 | 110.6 | 20 |
| Warden developed | 8 / 1 / 1 | 9.8 | 5 / 4 / 1 | 11.4 | 96.1 | 24 |
| Kindler starting | 10 / 0 / 0 | 20.7 | 3 / 6 / 1 | 18.4 | 105.1 | 47 |
| Kindler prepared | 7 / 0 / 3 | 20.9 | 3 / 2 / 5 | 11.4 | 54.9 | 46 |
| Kindler developed | 9 / 0 / 1 | 19.0 | 4 / 4 / 2 | 11.4 | 75.2 | 42 |

This cohort exposes a real distinction between clearing and boss survival.
The Warden policy clears ordinary packs quickly but receives substantial boss
damage; the ranged policies more often reach the thirty-second encounter limit.
The prepared/developed gear and Foundry configurations do not improve every
result, so these measurements must not be presented as a class ranking or a
validated progression curve. They provide concrete cases for the owner's
combat/class playtest, without adjusting monster life to fit one bot policy.

Six Kindler boss samples accumulated 3.1–5.3 seconds of stopped pursuit outside
claw range after excluding recovery, freeze and stagger. The snapshots place
support-backed bosses in the central gallery with valid paths; actor congestion
is a possible cause, not yet established by this fixture. The bosses continued
to produce attacks, and there were no floor rescues or remote entrance resets.
This remains a specific movement observation for review rather than a claim
that all pursuit behaviour has been certified.

This review uses one deterministic offer per tier, one combat policy and one
opening/final encounter. It cannot establish all condition combinations,
temporary-boon combinations, full-run endurance, exploration duration or human
execution difficulty. Final difficulty calibration remains provisional pending
the owner's combat/class playtest. Tiers above ten are unverified.
