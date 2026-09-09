# Repeatable Trial Runs

**LF-7A/B captured experiments:** after the saved human ending, Central's physical
E controls expose the existing three stable offers and unlocked tiers, bounded
at ten for LF policy. One optional Crossfire or Relentless Boss supplements the
rolled conditions; duplicate/shared/incompatible effects and a third major
hazard refuse without rerolling. Successful entry validates the offered ID,
deposits once, advances the existing batch and remembers tier/pressure using
optional version-one gate fields. The run freezes those settings. Old offer
seeds, targets, conditions and modules are unchanged. Existing creature bosses
operate in five reused chambers; the human cannot return. The extra pressure
multiplies only targeted cache/secret material by 1.25; fixed gear, general
iron/purse Kinds and one completion core retain their rules. The LF equipment
cache pays the old shrine's gear without its guaranteed Catalyst. Legacy
policies retain that Catalyst. Current [contract and evidence](../prototype/living-frontier-wave7-2026-09-09.md)
supersede the historical Wave 6 experiment closure below.

Captured experiments place offerings on the open entrance apron and the exit
beside the initial controls. Exit is unavailable during fights; between fights
it allows abandonment, or banking after the equipment cache before the boss.
Normal return saves the settled material bag, separate Kind purse, earned gear,
gate batch and remembered configuration with the complete owned world. A failed
write retains live ownership and disables re-entry until a visible retry or
ordinary save succeeds. Retrying writes the settlement without awarding again.
Successful restore clears transient retry state only after installing the world.
No mid-fight checkpoint is added; a crash before the return checkpoint restores
the preceding save. Roll-tier previews describe modifiers on random bases,
which retain their existing effective-tier limits.

**LF-6A/B continuation:** after both physical awards, the existing Central site
opens a scoped capstone copy with the same two floors, eight stages and rewards.
The final chamber contains the dedicated human Conservator and two physical
emergency releases. Central suspension uses revision three; Annex/Pairing retain
their published revisions. Under LF policy, `forge_arc_complete` resolves the
human story once and prevents re-entry before deposit; legacy capstone/maps
retain their existing rules. Final return writes the settled haul, story and
world together before presenting the transfer as saved. A failed write leaves
the live settlement and an explicit save-retry action; it never repeats native
settlement. The existing exterior derives its quiet lights, released handle
and control page from that receipt on return/load. Death before victory still
returns deposits and loses unbanked loot; world death after completion retains
the ending and uses the usual material death pack. No new era or configurable
experiment is added.
[Contract and evidence](../prototype/living-frontier-wave6-2026-09-09.md).

**LF-5B continuation:** the existing Pairing Hall front body opens the second
laboratory only after the first physical campaign award. It retains Deep Forge's
two floors, eight stages, Warden, encounter counts and ordinary rewards. Blue/Red
reminders precede the ordered paired specimen in stages 2–6. Three gallery
records reveal the human operator's imposed combinations and second failsafe;
three teaching chambers receive solid apparatus with checked approaches.
Revision-two Pairing suspension remains distinct from revision-one Annex saves.
First Pairing victory pays one Eye/receipt, without replacing a spent trophy.
LF-5C queues its second event on first victory; safe return publishes Excited
Uplands and era three together. Pending load resumes to the restored save path;
blocked returns offer retry at either laboratory. Central/maps stay closed.
[Contract and evidence](../prototype/living-frontier-wave5-2026-09-09.md).

**LF-4B (9 September 2026):** only saved `living_frontier_wave4` campaigns enter
the first Trial through the existing Collection Annex shell. A scoped Tyrant
copy retains eight stages/two floors, deposits, temporary boons and ordinary
rewards; the first two stages introduce separate existing Red/Blue specimens.
Solid apparatus and inspectable human-intervention/failsafe records complete
the bounded laboratory treatment. Later story/map entry is closed under this
policy; legacy worlds retain the published Forge catalogue and curio gates.
Laboratory suspension carries an explicit policy/revision. LF-4C now queues
one resonance event and awards one Heart on the first victory. Publication runs
after the normal safe return, retaining the loaded world path; pending restart
resumes that boundary. Repeat clears keep ordinary run loot without repeating
the trophy or terrain event. Death and bank-out retain their original settlement
rules and cannot queue the event. [Contract and checks](../prototype/living-frontier-wave4-2026-09-09.md).

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

[INT-05B](../prototype/forge-pressure-2026-09-08.md) concentrates mixed arrivals
around the existing entry lanes and cover. Ordinary story encounters contain
12/14/16 enemies in Tyrant/Deep/Capstone respectively, ordered into groups of at
most six. Boss rosters and all eight module geometries remain unchanged. The
normal interval is six seconds, including a two-second HUD warning; map-specific
intervals still apply. Clearing early also allows the full warning before the
next group. At most 24 enemies and two major hazards remain live.

`trial.json.engine_rules` documents arrival area, front/rear/side offsets,
1.7 m spacing and 5 m player clearance. Spawn selection uses current navigable
floor cells and surviving body positions, alternates the group's preferred
side and never falls back into blocked space. Unplaced enemies remain queued;
a full/blocked arrival retries after the notice interval. The boss keeps its
central position when clear, otherwise uses a checked room point. There is no
new lock-in: existing retreat, optional routes, rewards and lift rules remain.
The native encounter arrays also drive previews. Cleared-boundary checkpoints
store route/ownership rather than enemy arrays, so old boundaries restore
exactly and the next uncleared encounter uses current tuning without a schema
or content-revision change.

The [INT-05A presentation pass](../prototype/forge-readability-2026-09-07.md)
exposes current route plaques inside the gallery approach with the same solid
body represented in navigation clearance. Available plaques preview the native
reward and enemy names in three compact world-text lines; aiming retains the
full preview. Selected routes say Chosen. Five shared stone/iron fixture shapes
distinguish route seals, offerings, lifts, secret catches and ward conduits.
Future routes suppress distant text; secrets use matte catches and words only
within interaction reach. Final-floor gallery markers offer no fictional descent.

Current solid fixtures also participate in navigation. Adding/removing offerings
or ward conduits coalesces an update to the same floor map/region, restoring old
clear cells and excluding live collider poses. Existing enemy path refresh and
attack reach remain; this corrects the reproduced Warden/conduit obstruction
without changing collision or introducing continuous rebaking.
Fixed floor/cover eligibility is cached once per floor; event updates filter
that same ordered candidate set against live fixture bodies before rebuilding
the existing polygons. It adds no persistent navigation state.

Boss and furnace warnings retain their native cones, discs and lanes. A dark
inward perimeter remains visible beneath a warm stroke whose progress follows
the existing warning clock, including pauses. Depth-tested outlines remain
occluded by cover. FIRE, SWEEP and RECOVERING name actual boss phases; they do
not alter attacks, guard protection or recovery duration. Burning-ground opacity
fades over its existing lifetime while its affected radius remains visible at
full size. The presentation adds no new hit checks, save fields or gameplay RNG.

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
