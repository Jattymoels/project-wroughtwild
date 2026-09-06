# Repeatable Trial Runs

**D-029 replenishment addition, 6 September 2026:** each existing repeatable
material target previews one rare contraption component in the gate offer. Its
once-only final boss reward banks that component with the completed run. The
mapping is `trial.json.map_rules.completion_components`; it adds no random draw,
new offer target, discovery gate or separate currency. Reloading old saved offer
batches retains their original IDs, conditions and material emphasis. Death and
early extraction cannot award the boss component. See [loot rules](loot-and-currency.md).

**Status:** Forge intensive approved for implementation, 6 September 2026
**Related decisions:** D-001, D-006, D-010, D-028

The [approved Forge intensive](../prototype/trial-intensive-2026-09-06.md)
supersedes the earlier one-short-trial content boundary below. It permits one
three-run Forge story arc, eight authored modules, twelve temporary boons and
single-floor repeatable expeditions. It does not add a map item economy, Atlas,
new era, discovery currency or another player failure meter. The reported timber
demolition conflict remains outside this work item.

## Implemented rules and host contract

`TrialSession` remains the one rules authority. The original four-stage
`trial_start` entry remains available for the vertical-slice economy regression
fixture. Normal gameplay uses `trial_start_story(seed, run_id)` with
`forge_tyrant`, `deep_forge` and `forge_capstone` from `trial.json.expeditions`.
Every story has eight encounters across two traversable floors, two physical
branch junctions and four three-choice boon opportunities. A chosen room's
encounter belongs to its stage and route; optional secrets never enter mandatory
completion checks. Godot owns room geometry, navigation, triggers, arrivals,
boss commitment, hazards and timing; the simulation owns offer eligibility,
modifiers, rewards and once-only settlement.

The Tyrant returns `tyrant_heart`, which the hill cairn converts to the existing
`stonecut_blocks` milestone. The Warden returns `warden_eye`, which the drowned
altar converts to `ash_tide`. The capstone requires `ash_tide` and directly grants
`forge_arc_complete`. This separate flag opens expeditions without advancing an
era. Every active run exposes its explicit boss through `sim.boss()`.

After the fourth encounter, `awaiting_floor` blocks further encounters until a
floor decision. The native stage now identifies the next floor (index one),
while the host still displays the cleared first floor (index zero). Continue
carries life, boons and loot forward. Banking settles the existing deposit and
loot contract. Suspension requires a cleared, settled story boundary and performs
no healing, extraction or deposit. Repeatable expeditions cannot suspend.

`trial_checkpoint` serializes the chosen route, deposited inventory, unbanked
ingredients and item instances, accepted boons/weaknesses, claimed secret,
encounter seed sequence and hit RNG/counter. The host pairs it with the world,
player pose, exact combat life/timers and permanent economy/build in one atomic
save. `trial_checkpoint_matches(checkpoint, sim_json)` validates the pairing
before import; `trial_restore_checkpoint` validates the already-imported state
again and refuses an active run. Restoring never deposits inventory. Content
revision, floor boundary, route indices, seeds, item bases and temporary choices
must validate before a session becomes live. Native save numbers retain full
binary64 round-trip precision. The host pairs its readable JSON combat fields
with an object-disabled binary companion because the Godot JSON parser can
shift a float by one ULP even when written with full precision; life and timers
restore from the validated exact companion. A repeated resolution or secret
interaction awards nothing.

The host writes full-precision JSON and an exact binary companion for combat
life/timers. Godot 4.5's JSON parser can still shift particular binary64 values
by one ULP; the companion preserves their bits. Decode uses
[`Marshalls.base64_to_variant`](https://docs.godotengine.org/en/4.5/classes/class_marshalls.html#class-marshalls-method-base64-to-variant)
with object decoding disabled, validates the same bounded combat fields and
requires agreement with the readable representation before any import.
Older boundary records without the companion still load through validation.

The paired host save also retains the world's loose drops and death packs
([INT-07A](../prototype/loose-drop-persistence-2026-09-07.md)). They remain
separate physical owners, never a second trial deposit or reward payout. Active
trials block their collection and material dropping; ordinary world-drop age
and flight continue. Cleared-floor suspension restores the saved world-drop
state with the run. Missing drop records in an older checkpoint mean an empty
world set; they do not alter its recorded trial loot.

`GateState` lives in the native save's `extra.trial_gate`. Three offers derive
from the saved batch seed and selected unlocked tier. Reopening, changing tier
and reloading cannot change those offers. Only successful map entry advances the
batch, and only a boss clear at tier T unlocks T+1. Failure and banking preserve
all unlocked tiers. Offers contain two conditions at tiers 1–3, three at 4–7 and
four thereafter. Selection rejects repeated effect keys, explicit incompatible
conditions and more than two major-hazard definitions; the host also caps live
major hazards at two and living enemies at 24.

The gate previews the boss, conditions, material source and haul multiplier.
Its three target pools offer quarry, living-material and Forge rarity ambitions.
Caches and secrets return the same source ingredients used in gathering and
one-step crafting. They do not unlock recipes. The map's selected ingredient
uses `target_haul_units`, multiplied by its visible tier/condition reward and
accepted weaknesses. Equipment rolls still use the current item reward rules;
there is no hidden item-quality multiplier for map tiers.

The native checks in `tests/sim/trial_intensive.h` cover all stories, exact
boundary restore, future randomness, curio/era separation, stable tiers/offers,
bounded condition composition, targeted source yields, repeated reward calls,
the Ember death exception and three compatible offers for each fixed class.
These state-machine checks do not certify movement difficulty or 20/10-minute
durations. Real-time build measurements and presentation/performance evidence
belong to the intensive's engine review; tiers above ten remain unverified.

## Intensive tuning

All new numbers live in `trial.json` or `boons.json`, with plain-language
purposes next to their definitions. `map_rules.life_per_tier` and
`damage_per_tier` add linear enemy scaling without increasing modifier count;
`reward_per_tier` and `reward_per_condition` increase useful haul.
`target_haul_units`, `haul_units` and `secret_units` control ingredient volume.
`engine_rules` bounds arrival waves/live populations and sets telegraph, active,
tick, damage and radius values for hazards; boss guard/recovery, vent cadence,
conduit shielding/rearm and elite multipliers express readable combat windows.
Story and map duration are playtest targets, never enforced timers.

## Purpose and player fantasy

Trials repeatedly test a persistent build under varying routes, boons, weaknesses and mechanics. The player should return from failure understanding what happened and imagining how the next attempt could succeed.

“Dungeon” describes a trial structure, not necessarily an underground place. A trial may be a temple, tower, corrupted forest, mine or fortress.

## Prototype scope

- one trial theme;
- a short branching room graph;
- three enemy behaviours;
- one boss;
- approximately 12–20 boons;
- three weaknesses or curses;
- one secret or rare event;
- entrance inventory deposit;
- no procedural room geometry requirement—authored rooms may be rearranged.

## Run sequence

1. Deposit ordinary carried inventory at the entrance.
2. Review known trial information and select any starting preparation.
3. Enter with the persistent build intact.
4. Choose between room routes, rewards or risks.
5. Acquire temporary boons and weaknesses.
6. Fight a boss that exposes build and run trade-offs.
7. Succeed and secure rewards, or die and return without permanent build loss.

## Temporary adaptation rules

- Boons interact with persistent skill tags and mechanics.
- A boon may amplify a strength, compensate for a weakness or create a risky interaction.
- A run must not replace the active skill set or permanent tree.
- Boons should interact with one another so players can recognise emerging combinations.
- Poor synergy may make a run harder, but generation should provide redirection or salvage choices.

Example for an area-focused build:

- echo area effects to improve clearing further;
- concentrate area against isolated enemies to improve boss damage;
- accept faster enemies for greater area and rewards;
- acquire a second boon that benefits from the enemy-speed weakness.

## Failure categories

- **Execution:** mechanics were misplayed.
- **Persistent power:** equipment or build is underdeveloped.
- **Run adaptation:** temporary choices failed to form sufficient synergy.
- **Build trade-off:** the build excelled at clearing but exposed weak single-target damage, defence or sustain.

Boss pressure may ramp through mechanics or attrition. Burst builds shorten exposure; defensive builds survive longer; clear-oriented builds may need compensating run choices.

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Room count | Run duration and investment |
| Branch frequency | Decision density |
| Boon offer count | Control versus randomness |
| Boon weighting | Compatibility and replay variety |
| Weakness reward multiplier | Risk appetite |
| Boss pressure ramp | Value of single-target damage and sustain |
| Secured reward timing | Tension around death |
| Secret frequency | Discovery and anticipation |

## Failure cases

- The best boon is always obvious.
- Tag-aware weighting becomes so generous that every run assembles the same synergy.
- Bad luck creates visibly unwinnable attempts.
- The permanent build trivialises all room decisions.
- Runs become repetitive because room ordering changes without meaningful context.
- Zero loss makes abandoning a weak run optimal.

## Prototype acceptance

- Two attempts with the same build present meaningfully different choices.
- The player can explain why the boss attempt failed.
- At least one boon pair creates a discoverable interaction.
- Death encourages preparation or re-entry rather than save reloading.

## Floors (D-019, 3 Sep 2026)

A trial may have deeper floors (`trial.json` `floors`): each is a run
with its own stages, boss, bank-out point and completion effect, offered
by the gate once its `requires_world_effect` is active. Completing a floor
is one of the milestones that advance the world's era.

## Open questions

- Treatment of loot found after trial entry but before death.
- Universal versus trial-specific boon pools.
- Weighting by current build tags.
- Exact persistent-to-temporary power budget.
