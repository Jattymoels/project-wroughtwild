# INT-18A — matched complete-pressure attempts

9 September 2026. Owner-selected first validation slice from the
[Wave 7 review](living-frontier-wave7-review-2026-09-09.md), based on `4f0886b`.
No later campaign, performance, interface or art slice is included.

**Result: Relentless Boss has complete five-room live victories with matched
baselines. Crossfire attempts end in natural deaths; a complete Crossfire
victory remains unproven.** Do not mark all added-pressure acceptance complete.
The eight retained final attempts include four victories and four deaths.
This is measured validation, not human balance acceptance.

Subsequent [independent review](living-frontier-int18-pressure-review-2026-09-09.md)
clears this slice and reproduces four victories/four deaths with exact ownership
and recovery checks. Its combat traces and assertion counts differ in places;
the review records its own measurements without replacing the receipts below.
Complete Crossfire victory and human balance acceptance remain open.

## Scope and contract

Affected systems are D-006 ownership, D-010 engine combat, D-025/D-026 prepared
builds, D-028 saved offers and D-032/D-033 campaign/world continuity. The accepted
[Wave 7 configuration](living-frontier-wave7-2026-09-09.md) remains authoritative.
Relevant tuning is `trial.json`, `crafting.json`, `foundry.json`, `skills.json`
and `combat_realtime.json`. **None is changed.** No production script, native
rule, save schema, geography, published fixture or art asset is changed.

The recorded plan was to select one compatible saved offer before combat,
prepare comparable builds through ordinary transactions, fight every reached
room and physically collect its rewards, then check settlement and fresh-process
recovery. A death ends the attempt; later rooms are not fabricated or force-cleared.
No missing decision was required to run this validation. Any balance selection
remains a proposal for the orchestrator/owner.

## Fixtures and reproducibility

All attempts load the existing compressed `lf6-published-ending.json.gz` into
isolated project-local test saves. This **supplies synthetic campaign access**,
including both applied terrain ledgers and the captured human ending. It is not
a continuous campaign from an empty inventory. The archived character is
historically classless, with Heavy Strike, Area Strike, Frost Nova and Dash.
Existing unequipped items, buildings, machines, sources, excavation and drops
remain owned; the new weapon and chest are equipped through the normal API.

The first saved tier-one offer compatible with **both** pressures is slot two:
`map_6823397602735278268`, seed `6823397602735278268`, targeting raw clay,
with Forge Tyrant and rolled Warded Rares / Volatile Rares. Its module order is
ward gallery, kiln hall, fuel chamber, cistern, heart forge. The base reward
multiplier is 1.2. Every comparison retains those identities, equipment reward
rules and rolled conditions; only the selected pressure changes.

Recipe ingredients and forge facilities are **supplied fixtures**. The recorded
eight historical Foundry events supply the earned-ingot fixture; no new XP or
equipment roll is injected. Crafts pay their actual costs, roll once, and equip
that result without selection among rerolls. The preparation receipts retain
exact material/purse differences, equipment rolls, stats, bar and plate.

| Ordinary preparation | Cost paid |
| --- | --- |
| Iron Mace | 3 iron ingots + 2 wood + 2 heat |
| Bronze Mail | 10 bronze ingots + 3 heat |
| Basic temper | Existing deterministic fire-resistance operation |
| Faint Ember | 96 Red Salt + 4 iron ingots + 8 charcoal |
| Three Marrows | 3 silver ingots + 6 hide + 6 heat |
| Sipping Marrow | Ordinary three-Marrows-for-one exchange |

The supplied carried wood pays the eleven recipe heat units through the existing
fuel selection. Across these crafts the total is 7 iron, 10 bronze, 13 wood,
3 silver, 6 hide, 96 Red Salt and 8 charcoal. Supplies left over remain owned.
Recovery uses Vigour at `(1,0)`, Edge at `(2,1)` and Sipping Marrow at `(2,0)`,
feeding the two attacks at `(1,1)` and `(2,2)`. The simpler cohort leaves its
manufactured Ember unused. It has 112 maximum life, 27.531 armour and 11.5% fire
resistance before temporary effects. Identical native preparation SHA256s are
required within each matched trio, not inferred from similar-looking equipment.

The second matched cohort uses that same paid gear and manufacture, places one
Faint Ember at `(3,1)`, and uses already-owned Frost `(3,2)`, Plate `(1,2)` and
Ward `(0,1)` supports. This tests existing chill/Steambrand and defensive readings.
It does not grant a lucky Catalyst or increase enemy/player tuning.

An additional Sound-grade diagnostic pays two ordinary Sound Iron recipes,
then the existing reinforcement on the mace/mail. Its unchanged rolled stats
illustrate that workpiece capacity alone does not guarantee stronger rolls.
An Ember-only diagnostic places the manufactured Ember without the three extra
supports. These two Crossfire diagnostics are not separate matched balance trios.

## Live-combat and ownership evidence

The harness drives the actual player capsule, navigation, committed skill casts,
projectiles, enemy/hazard ticks and first-person E rays at 60 physics ticks/second,
with time scale one and a fixed combat seed of 741103. It takes the first offered
boon consistently. Combat clocks continue during gallery/reward travel. Every
next-room life equals the previous reward's life; no heal/reset is injected.
Normal trial-entry and settled-return restoration are retained as game rules.
Immunity is asserted absent throughout the active attempt, including Dash.

Initial overworld travel is compressed to the last Central approach points.
The remaining approach and all trial movement are physical. World simulation,
ambient spawning and loose-drop age/flight are frozen for exact archived ownership
comparison. This does not disable trial combat or its incoming damage. The bot
reads enemy state and navigation; it is neither human input nor a reaction-time
acceptance test. Single seeded attempts cannot establish win rates.

The retained [machine-readable receipts](evidence/int18-pressure-2026-09-09.json)
contain per-room life, casts, kills, incoming damage, elapsed combat time, live
caps, boon offers, actual rewards, preparation, saved offers and restart results.
The local full receipts additionally retain individual hit events and entire
owned item arrays. They live under `build/int18-a`; local saves remain beneath
that directory's isolated APPDATA.

| Final preparation / pressure | Outcome | Combat seconds | Incoming damage | Casts / kills | Lowest life |
| --- | --- | ---: | ---: | ---: | ---: |
| Recovery / none | Five-room victory | 69.75 | 135.61 | 111 / 49 | 75.73% |
| Recovery / Crossfire | Death in room 4 | 57.87 | 235.02 | 105 / 45 | 0% |
| Recovery / Relentless | Five-room victory | 69.75 | 141.27 | 111 / 49 | 75.73% |
| Added Foundry / none | Five-room victory | 83.28 | 109.02 | 92 / 49 | 81.07% |
| Added Foundry / Crossfire | Death in room 3 | 47.58 | 183.44 | 66 / 34 | 0% |
| Added Foundry / Relentless | Five-room victory | 83.22 | 108.74 | 92 / 49 | 81.07% |
| Sound gear diagnostic / Crossfire | Death in room 4 | 57.87 | 235.02 | 105 / 45 | 0% |
| Ember-only diagnostic / Crossfire | Death in room 3 | 48.42 | 200.68 | 72 / 33 | 0% |

The simpler Crossfire attempt enters rooms at **112.00 → 80.58 → 42.57 →
26.73 life**, then dies with nine of the fourth room's twelve enemies killed.
Its last live tick sees 72.20 total enemy life before ordinary death cleanup.
The added Foundry Crossfire attempt kills ten of the third room's twelve enemies;
its last live tick sees 42.00 enemy life. These are real failures, not bank-outs.

The simpler paired boss samples both last 11.55 seconds: baseline takes zero
boss damage, Relentless takes 5.67. The added Foundry samples take 5.05 versus
4.77 damage. These single samples do not establish a difficulty ordering; the
unchanged first-four-room traces within each baseline/Relentless pair provide
the matched context. Complete entry-to-return time including gallery travel is
131.13–144.45 simulated seconds for the victories. This does not certify the
prototype's ten-minute player run target.

The eight final attempts pass **200,392 assertions**, mostly continuous
life/clock/population invariants rather than independent scenarios. Normal
return checkpoint observations are **249–347 ms**, under the local test workload.
Native configuration/settlement adds **54,286 checks** and live pressure effects
add **107 checks** at 20/60 Hz, all with zero failures. Those existing native
fixtures use forced rule outcomes; they are not additional live victories.
The sixteen separate-process recovery invocations pass **448 checks** (29 per
settled return and 27 per pre-entry recovery), and the independent receipt
collector passes **362 checks**. Godot editor registration also passes without
errors. All validation saves/preferences are isolated from the owner's saves.

For successful returns, the actual secret, cache, final component and all three
equipment rolls match the native previews. Materials and the separate Kind
purse are checked independently. The equipment cache awards no guaranteed
Catalyst. Modifier tiers are checked against the preview and allowed definitions.
Repeated post-return resolve/secret/end calls change nothing; they do not kill
an enemy or generate a second payout.

| Full-run reward | No added pressure | Relentless Boss |
| --- | --- | --- |
| Raw clay cache + optional secret | 28 + 28 = **56** | 36 + 36 = **72** |
| General materials | 4 iron ingots | 4 iron ingots |
| Separate purse | 1 Vanguard, 1 Marrow, 1 Quicksilver | Same |
| Equipment | Keen tier 1, wrought tier 1, wrought tier 2 | Same |
| Completion component | 1 Ventlung | 1 Ventlung |

The selected 1.25 factor is applied before rounding the target haul; the rounded
56-to-72 comparison is not an extra general reward multiplier. Crossfire exposes
and pays the same 36-unit secret/cache into unbanked ownership when reached,
then correctly loses those rewards on death. **No Crossfire boss payout is
claimed from live combat.** The separate native suite covers that settlement rule.

All final attempts checkpoint their settled result automatically. Ordinary loads
retain exact native rewards, owned world and configuration. Separate fresh
processes compare the saved native hash and next batch, reopen physical Central,
enter a next tier-one offer and physically abandon that unused run into a
disposable continuation. Another fresh process loads each retained pre-entry
checkpoint and verifies the original offer/seed without consuming or rerolling it.
An attempted active-run save is refused and leaves the preceding bytes unchanged.
This checks the non-suspendable recovery contract; it does not simulate a power
cut or claim mid-fight resumption.

Both exact native terrain ledgers, era three, the once-only human ending,
blocks/stations, broken/cracked terrain, contraptions, leyline source payloads,
finite resource nodes, seed/profile, loot counter and physical drop ownership
survive these returns/reloads. New gear and mastery earned by the actual fights
remain saved. Death restores deposits and previously owned equipment, loses
unbanked loot/gear and does not unlock a tier. Victory alone unlocks tier two.

## Defects, failed probes and limits

No reproducible production implementation defect was found. The new harness
initially compared JSON-parsed seed numbers and packed arrays directly against
native values, and tried to activate a disabled current-tier button. The final
receipt stores 64-bit seeds as decimal text and normalises comparison-only
records while leaving live integer reward dictionaries untouched. Full saved
native hashes independently verify exact restoration. The corrected checks
pass; no assertion was removed to turn a combat death into success.

Earlier local probes are not victories: simpler recovery and Sound gear died in
room three; Ember-only reached room four. A discarded ranged-tell sidestep policy
died in room one (8.72 seconds, five kills, 132.80 damage); extra dodging did not
solve simultaneous melee pressure. That policy is not shipped in the final
harness. Its receipt is retained under `build/int18-a/diagnostics`. These exploratory
outcomes and the failed receipt comparisons are separate from the final matrix.
Real-time traces changed during harness refinement; only the final matched
cohorts should be compared numerically.

Crossfire remains the material gap. The final simpler build loses life through
successive packs; the extra Foundry arrangement also dies before the boss.
This does not prove Crossfire is unwinnable or that the extra supports are worse
for a human. The bot uses a fixed melee approach, knows hazard state and may
choose poorly around simultaneous shooters, melee and death eruptions. All-class,
upper-tier, unseen-offer and human difficulty acceptance remain open.

**Balance proposal, not an accepted change:** run a matched Crossfire-only
comparison with ranged warning duration multiplied by 1.2, retaining the three
shots, projectile speed/damage, boss clocks and reward contract. Record dodged
fans, incoming damage and full-attempt outcomes with the same preparation, then
seek human judgement before selecting it. The present evidence motivates a
warning-time experiment, not an automatic nerf or reward increase.

This slice introduces no gameplay tuning parameters. Its test-only 180-second
room budget bounds unattended execution; timeout is not a clear. The inherited
movement policy and supplied/earned fixtures remain explicit. Publication/restore
timings are workload observations, not a performance improvement. A continuous
fresh campaign, transition performance, crowded controls and unrelated art
remain separate tasks. Stop here for orchestrator review.

## Reproduce and publication

```powershell
cmake --build build/gdext -j 4
foreach ($kit in @('rough','control')) {
    foreach ($case in @('baseline','crossfire','relentless_boss')) {
        ./tools/living_frontier_int18_checks.ps1 -Case $case -Kit $kit
        ./tools/living_frontier_int18_checks.ps1 -Case $case -Kit $kit -Restart
        ./tools/living_frontier_int18_checks.ps1 -Case $case -Kit $kit -Preentry
    }
}
foreach ($kit in @('sound','ember')) {
    ./tools/living_frontier_int18_checks.ps1 -Case crossfire -Kit $kit
    ./tools/living_frontier_int18_checks.ps1 -Case crossfire -Kit $kit -Restart
    ./tools/living_frontier_int18_checks.ps1 -Case crossfire -Kit $kit -Preentry
}
./tools/living_frontier_wave7_checks.ps1 -Native -Effects
python tools/living_frontier_int18_report.py --output docs/prototype/evidence/int18-pressure-2026-09-09.json
```

The runners throw on engine/assertion failures; combat deaths are explicit valid
outcomes. The report collector independently checks matched native preparations,
offers, reward rules, recipe payment and both recovery modes. Existing reviewed
Wave 7/earlier campaign regressions remain distinct from this focused rerun.

The checked slice is limited to this report, its evidence/index links and the
reproducible test harness/collector. Standing permission covers its main-branch
commit and ordinary push to `origin/main`; local commit and remote publication
results are reported separately in the handoff. Unrelated modified Wave 6
captures, untracked art/tools and other existing local diagnostics are excluded.
