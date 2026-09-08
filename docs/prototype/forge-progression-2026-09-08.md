# INT-05C — earned power and the melee opening

**Status:** Implemented and checked; owner review pending. Owner difficulty/build-satisfaction review
remains pending. Starting production: `8b499c4`, clean `main` at `origin/main`.
This implements only the [INT-05C work item](playtest-iterations-2026-09-07.md).

## Scope and decisions

Keep the first arrangement expressive and make later equipment investment
visible. Diagnose duplicate recovery before lowering numbers. Preserve a usable
unmodified melee opening. D-010/ADR-0003 owns native numbers, D-012 retains
movement-only defence, and D-025/D-026 retain exact Kind identities, equipment
capacity and earned mastery. D-028 encounter pressure from INT-05B is the baseline.

Assumptions: the owner's exact two-ingot/catalyst arrangement, route and gear are
unknown. The cases below are explicitly representative, not a reconstruction of
their save. The plan was to preserve production, measure legal paired builds,
correct demonstrated faults, make one separately measured melee adjustment,
then run story attempts, tiers 1–10 and regressions. No missing architecture or
save decision was needed.

## Implementation

`PlayerCombat.deal` previously treated any dead target as a new kill. Calling it
twice on the same victim produced zero damage on the second call but another
kill result and one more life from an iron Vigour support. This also happened
through a real legal Ember/Haste Flashfire reaction: spending an existing burn
killed the victim in `apply_payload`, then the following ordinary packet paid
direct-kill recovery for that already-dead target.

The function now returns zero damage, no kill and no types before resolving
packets or recovery when the target is already dead. Fresh positive hits and
fresh kills still pay their ordinary recovery. Flashfire still spends the
existing burn and kills; it cannot claim a second direct kill. This closes a
demonstrated duplicate-credit path, not proof that it caused the owner's exact
overpowered build. Legal per-target Sipping/Vigour recovery is retained.

The sole numerical change is `prototype_heavy_strike.cooldown_seconds` in
`data/tuning/skills.json`: **1.4 → 1.2 seconds**. Its purpose is documented beside
the value. Base damage remains 28, stagger 0.4 s, shove 0.5 m, swing armour 12
for 0.5 s. The unmodified opening can recommit sooner; it does not need a
Foundry support to receive this improvement. No player-wide damage reduction,
enemy life/damage increase, new dash rule or change to catalyst budgets was
justified by the measured cases.

No persistent schema or owned item/skill/Kind/mastery value is rewritten. There
is no generator, geography, resource, inventory, currency, drop or reward change.
Ordinary skill recovery is runtime tuning; an in-flight saved cooldown remains
its saved remaining time. Existing D-025 operations and proliferation survive.

## Reproducible comparisons

`tools/home_review.ps1 -ReviewSet forge-progression` copies the project under
ignored `build/forge-progression/{baseline,current}` and gives each phase its
own APPDATA. Baseline production is preserved; only common review fixtures are
replayed onto it. Godot is hidden, bounded and uses Dummy audio. Tests never
launch the owner's normal project/save or stop an unrelated process. No native
extension rebuild/replacement is required by this slice.

The final comparison uses `--fixed-fps 240`, 240 physics ticks, time scale 8:
one process frame per 1/30 simulated-second physics step. This fixes process-owned
reserve clocks as well as physics. Earlier variable-process runs exposed large
bot outcome variation; those exploratory outcomes are not the final comparison.
These accelerated runs are functional measurements, not performance evidence.

Three classes keep their primary skill: Warden/Heavy Strike, Ranger/Bow Shot,
Kindler/Ember Bolt. Each has three arrangements, plus plain and ingot-only
controls at the starting stage. Every skill is at (1,1); iron supports at (1,0)
and (2,1); the exact compatible Kind at (2,0).

| Case | Ingots | Kind | Intended difference |
| --- | --- | --- | --- |
| Clear | Ember + Reach | Ember Catalyst | Kindling/Wildfire and burning-death proliferation |
| Single target | Edge + Haste | Ember Catalyst | Cinder Edge/Flashfire; existing burn can be spent early |
| Recovery | Vigour + Edge | Sipping Marrow | Ordinary hit/kill returns plus Deep Drink/Bloodletter obligations |

Starting builds have the real wooden weapon, no armour, and 100 normal maximum
life. Prepared equipment is Sound capacity with a Stable aimed craft; developed
is Excellent with Potent aimed crafting. The harness supplies documented fixture
resources, stations and smith XP, then uses native crafting/payment/equipping.
Physical/projectile/fire aiming follows the unchanged primary skill; the fire
cohort retains a Charred Brand instead of substituting a cold-specialist base.
Armour uses Vanguard aiming. All builds and resolved equipment are in the JSON
reports. Foundry pieces stay Faint iron arrangements across gear stages, isolating
equipment rather than silently upgrading both systems.

The old `trial_balance` benchmark calls its later cohorts prepared/developed but
crafts Rough, unaimed gear. It is retained unchanged as a historical tier control;
the new graded cases correct that limitation for progression comparisons.

* `progression_controlled`: 78 cases, one or six ordinary stationary whelps,
  real life/resistance, real skill deliveries/cooldowns and statuses. No incoming
  damage or enemy kindlers. Starts at 20 life to expose healing. Fixed contact
  positions are an upper bound, not player movement or boss difficulty. Each
  case has 20 seconds; timeout is not a clear.
* `power_progression_review`: 78 actual T1 pack/boss encounters, primary skill
  only, same native seed/offer and no temporary boons. Normal movement controller,
  30-second limit. Direct effective damage, coverage, payload thresholds, received
  damage, hit/kill/other healing, kills, exposure and tells are recorded separately.
  Residual enemy life loss includes enemies kindling their own allies; it is
  **not all player secondary damage**. Controlled cases provide that attribution.
* `progression_journey`: nine complete Forge Tyrant story combat attempts with
  full permanent class bars, all eight encounters available, first choices and
  no temporary boons. Life/cooldowns carry between rooms/floors; no forced kills,
  skipped fights or injected recovery. Travel is posed and excluded, so these
  cannot validate the provisional 20-minute story target. Death/90-second
  encounter timeout stops an attempt and never counts as completion.
* `trial_balance`: 180 actual encounter samples per version, three classes ×
  three historical gear cohorts × tiers 1–10 × pack/boss. Skipped stages only
  establish its isolated boss fixture; they are not claimed as full map clears.
  The provisional 10-minute map target remains unvalidated.

## Final measurements

The [retained machine-readable results](references/forge-progression-2026-09-08.json)
contain both versions' controlled, paired, story and tier rows, including healing,
coverage, direct payload thresholds and boss tells. Full resolved gear views and
logs remain in the isolated `build/forge-progression` reports.

The dead-target reproduction changes **1 duplicate life / true kill → 0 / false**,
both for replaying a dead victim and for the real Flashfire pre-payload kill.
The independent fresh-victim control still pays recovery. Final controlled
opening: one ordinary whelp takes **2.97 → 2.43 s** with the same three wooden
Heavy Strike contacts. In six targets, the plain opening still times out at
20 s, but deals **360.1 → 435.2** effective damage. That is a measurable opening
improvement without an additional damage multiplier or free kill.

Current six-whelp clear-arrangement times, with all 450 life actually removed:

| Class | Wooden/unarmoured | Sound/Stable | Excellent/Potent |
| --- | --- | --- | --- |
| Warden | 9.63 s | 9.63 s | 9.63 s |
| Ranger | 13.13 s | 8.47 s | 2.93 s |
| Kindler | 17.13 s | 16.07 s | 12.50 s |

Warden's small-target clear breakpoint does **not** improve further with grade
in this sample; claiming otherwise would overstate equipment's benefit. Its
single/recovery arrangements and full story expose different thresholds.
The starting clear arrangements retain **176.1 / 227.7 / 282.2** effective
secondary damage for Warden/Ranger/Kindler respectively. Before the melee
adjustment, Warden's clear arrangement finished at 11.77 s while the ingot-only
control timed out. This is evidence of a valuable propagation behaviour; it
does not justify deleting or globally reducing that behaviour.

Recovery is real but bounded in these samples: the six-target controlled
starting Warden recovery arrangement restores 6.5 on hits, 6 on kills and 7.5
from earned secondary opportunities. Its actual paired pack case restores
6.5 + 1 + 7.5 and still dies. In the 78 current primary-only T1 encounters,
starting has 0 clears/42 deaths, prepared 0/18, and developed 5 clears/12 deaths/
1 timeout. These policies are restrictive and cannot prove a human build weak;
they do not reproduce general early invincibility after INT-05B either.

Full-bar, whole-story combat attempts at the final fixed cadence:

| Cohort | Before: outcome, encounters attempted | After: outcome, encounters attempted |
| --- | --- | --- |
| Warden starting | Death, 4 | Death, 2 |
| Warden prepared | Death, 6 | Death, 6 |
| Warden developed | Complete, 8 | Complete, 8 |
| Ranger starting | Death, 2 | Death, 2 |
| Ranger prepared | Death, 6 | Death, 5 |
| Ranger developed | Complete, 8 | Complete, 8 |
| Kindler starting | Death, 4 | Death, 4 |
| Kindler prepared | Death, 1 | Death, 1 |
| Kindler developed | Death, 6 | Death, 5 |

Current developed Warden/Ranger combat sequences take 100.0/58.6 s, expose one
boss tell each, and reach minimum life fractions 0.11/0.90. They exclude travel
and do not validate run targets. Faster attacks change movement/cast sequences;
the dead-target fix also avoids consuming RNG packets for refused victims.
An individual bot attempt can worsen despite better controlled throughput.
Kindler's losses and Ranger's comfortable developed clear remain owner-review
questions, not grounds for another speculative global adjustment in this slice.

Across the historical **tiers 1–10** benchmark, baseline has **59 clears,
101 deaths, 20 timeouts**; current has **63 clears, 97 deaths, 20 timeouts**.
All 180 cases ran per version, including actual boss exposure. These remain
single pack/boss encounters on the older Rough-equipment cohorts; no complete
repeatable map run or higher-tier balance is claimed.

## Checks and limitations

All final checks pass:

* Native: **224,380**, including the full Foundry identity matrix, numeric
  scaling, costs, crafted capacity, persistence and revised bare/gear cooldown.
* Engine unit checks: **398**. The two old 1.4-second cooldown expectations were
  updated explicitly to the new 1.2-second value; tolerances were not relaxed.
* Foundry mutations **452**, offence **104**, guard **385**, sustain **273**,
  tempo **324**: identity behaviour, direct/secondary boundaries and once-only
  effects retained.
* Ranged fairness **53**, horde/movement/dash **43**, grammar **72**, graded
  Forge progression **58**, pressure invariants **24**, integration **273**.
* Trial lifecycle/economy **6,218**. Fresh-process restoration of the retained
  pre-05B boundary **7**: exact native ownership, checkpoint, life, combat clocks
  and continuation, without healing or recalculating owned equipment.
* Both versions: 78 controlled cases, 78 paired encounters, nine story attempts
  and 180 tier samples, zero setup errors. Current strict dead/reaction boundary
  assertions and the fresh-kill recovery control pass. `git diff --check` passes.

Run the review scenes through `tools/home_review.ps1 -ReviewSet forge-progression`
with `-Phase baseline` or `current`. `-Prepare` preserves a baseline only once;
`-Import` initializes a fresh copy. Scene names are listed above. Add
`--boundary-only --expect-fixed` through `-ExtraArguments` to run strict recovery
regressions against current production. Native tests use the ordinary sim suite.

The owner's exact first-upgrade spike remains unconfirmed. Automated contact,
throughput and bot results do not establish enjoyment, difficulty or mastery of
enemy tells. Higher tiers, alternate offers/seeds and all possible arrangements
are not certified by these representative samples. Single-target whelps are
throughput controls; live boss encounters separately supply tell exposure.
Native gear upgrades produce discrete breakpoints, not a guarantee that every
grade improves every target/time result. Owner review remains open.
