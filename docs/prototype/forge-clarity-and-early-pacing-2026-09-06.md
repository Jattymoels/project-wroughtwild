# Forge clarity and early progression

**Status: owner approved for implementation, 6 September 2026 ("Okay enact the proposal").**

The sections below preserve the reviewed proposal. The implementation record
at the end states the installed tuning and the limits of verification; tentative
phrases in the original proposal are historical, not additional pending approvals.

The owner is satisfied with the early itemisation direction, wants crafting and
forge clarity to follow the building catalogue, and asks for easier basic gear,
more gradual early item grades, and more time/tension before equipment and
mastery combine into a large power spike. This proposal changes acquisition and
pacing; it does not expand the affix pool or postpone the first creative Foundry
mutation.

**Owner clarification:** the player should be able to make a weak early item
using an early catalyst, while seeing that better ingot/catalyst grades yield
stronger modifiers. Input quality is therefore the primary proposed strength
ladder. Extra item-rarity names are a secondary option, not a substitute for it.
The grade names and ranges below remain proposals, not accepted tuning.

## What the current rules do

- `game/scripts/work_panel.gd` lists recipes, then another action row for every
  held Kind on every gear recipe. Station upgrades, tempering, transfers and
  Foundry recasting share the long work screen. This multiplies text as the pack
  grows. Building already separates catalogue, selection, preview and action.
- `data/tuning/items.json` has Plain (0 rolled modifiers), Keen (1–2), Wrought
  (3–4). These are modifier-count bands, separate from modifier strength tiers
  and from the base's material/tier capacity.
- `data/tuning/crafting.json` starts crafts at 35% Keen. Each required
  Blacksmithing level above one adds ten percentage points. Wrought rolls first:
  15% at level 4, 30% at level 5; a failed Wrought roll then tests Keen. At level
  5 that means 30% Wrought, 52.5% Keen and 17.5% Plain for a qualifying recipe.
  A supplied Kind raises a Plain result to Keen and aims its first modifier.
- The Iron Mace costs six ingots and two wood; the Hunting Bow costs two ingots
  and four wood. Both need the basic forge. The ordinary Charred Brand also
  needs the forge. Timber Shield and Hide Quiver already work at the bench.
- Blacksmithing thresholds are 0 / 50 / 125 / 225 / 300 total XP. The mine's 24
  fittings require six batches, yielding 48 recipe XP while feeding the order,
  plus its 60 completion XP, before smelting. Raising this curve alone would
  risk exhausting the slice's useful demand and encouraging spare-item spam.
- Most original skills have mastery at 30/120 uses. Bow Shot grants +15%
  physical damage, then +1 pierce. At its 0.9 s base cooldown those take roughly
  27/108 seconds of continuous firing, excluding movement and other interruptions.
  Projectile mastery records the cast firing, regardless of whether it hits.
  The six newer skills use 40/140 milestones; slower skills also take longer to
  reach equal use counts. These are mechanical lower bounds, not measured player
  session times.

The concern is supported by the rules: basic access has several preparation
steps, while multiple power rewards can arrive close together once play starts.
Changing only item colours or adding a long forge timer would leave that intact.

## 1. Use the building catalogue's selection flow

At a station, show a compact category rail and item cards, with the selected
item's preview and details beside them. Keep close and the primary action fixed
outside scrolling content, at both 720p and 1080p.

Suggested categories: **Equipment / Materials / Stations & upgrades**. Selecting
equipment exposes **Make / Improve / Transfer**, with only relevant operations.
The Foundry remains a clearly separate shortcut; recasting a Foundry ingot does
not interrupt browsing ordinary weapon recipes.

Each card shows the item model/icon, name, equipment role, and one availability
line. Locked items remain inspectable. The detail panel shows, in this order:

1. What it is and a short comparison against the equipped item. Random results
   show their permitted range/chances; the preview never predicts an unseen roll.
2. Guaranteed base, possible rarity and supported modifier families, followed by
   the selected material quality and catalyst potency with their modifier ranges.
3. Ingredient **have / need**, plus fuel and any required station/skill.
4. One precise next action, e.g. "Smelt 2 more Iron Ingots at this forge".
5. Optional Kind selection and its exact effect. Incompatible choices are
   disabled with a reason, rather than spending a Kind for no benefit.
6. **Make 1**, with quantity controls for ordinary stackable materials/components.

Clicking a missing component selects its recipe and preserves a back path to
the intended item. A pinned recipe lists its remaining requirements during play.
Materials and fuel are totalled together for the chosen batch; actions recheck
the live inventory before spending anything. No hidden recursive crafting.

Reuse the building theme and preview conventions and the equipment-comparison
rules. Keep all costs, eligibility and outcome previews in native sim views.

## 2. Make a functional first kit easier

Give each starting combat preference an inexpensive bench-made baseline:
**Wooden Cudgel, Simple Bow and Wooden Focus** are candidate names. Use existing
wood/hide supplies and modest implicits, around +5% to their relevant damage
lane. They supply equipment, not skills. A thin Hide Vest is the one proposed
basic chest option before the current iron armour; it should provide modest
survival without solving the trial's resistance requirement.

The existing Timber Shield and Hide Quiver already serve this stage. Keep the
bench and masonry/forge ambition, while allowing a player to equip something
useful before completing the entire metal-working chain. The better metal bases
retain their roles and material properties. Review the mace's six-ingot cost
against the two-ingot bow rather than applying a blanket recipe-cost reduction.

The base is always successfully made when the displayed requirements are paid.
Random craft quality remains a source of pleasant surprises, in line with the
owner's earlier preference; poor luck must not prevent obtaining the basic item.
No new resource family, durability tax or compulsory crafting minigame.

## 3. Input quality controls modifier strength

The present ordinary gear-craft path takes the roll tier from the current world
era. An added Kind selects a modifier family and raises the minimum rarity; it
does not offer a player-selected weak/strong potency grade. The separate
Ember-Tempering process instead has its fixed tier-two result. Item bases already
limit expressed modifier tiers, and Foundry ingots already have alloy refinements,
but that does not yet form the visible crafting progression the owner describes.

Proposed responsibilities:

- **Material identity** keeps its traits and compatible uses: iron, bronze and
  other materials remain meaningful choices rather than universal replacements.
- **Material/workpiece quality** determines how strong an imprint the resulting
  base can express. Better-worked iron remains useful. Candidate quality labels
  are Rough / Sound / Excellent, shown separately from the metal's name.
- **Catalyst Kind** determines the family being worked; **catalyst potency**
  controls the available modifier band. Candidate labels: Faint / Stable / Potent.
- **Forge process** determines which material/potency grades can be handled.
  Blacksmithing improves consistency inside an eligible band; it cannot turn a
  Faint catalyst into a Potent result just through higher skill.
- **Item rarity** describes how many rolled modifiers an item carries. More
  modifiers need not mean that each modifier is strong.

Illustrative ranges for one compatible increased-fire-damage modifier:

| Catalyst potency | Example roll band | What the player should understand |
| --- | --- | --- |
| Faint | 3–6% | An inexpensive first fire improvement; worth using now. |
| Stable | 7–12% | A stronger imprint from better resources and processing. |
| Potent | 13–20% | A later investment with stronger rolls and eligible advanced properties. |

These values are illustrative proposals, not the current damage tiers or a
universal formula for every modifier. Each affix needs its own authored bands
and any mechanical breakpoint. A Potent reagent allows its stronger range; it
does not guarantee the maximum roll or add arbitrary extra affixes.

The ordinary crafting preview should show:

> Ember Catalyst — Faint · Tier 1
>
> This craft: one fire-family modifier. Increased Fire Damage, if selected:
> 3–6%. Other eligible fire properties can be inspected before crafting.
>
> Next potency: Stable · Tier 2 · 7–12% for this modifier.
> Requires a compatible improved process and a base that can express Tier 2.
> Show the known source or refinement recipe for a Stable catalyst.

A property-specific temper can say it guarantees that property. Ordinary aimed
crafting must distinguish its guaranteed family from the exact property it might
roll. The preview never implies every Ember craft guarantees fire damage.

Let players inspect locked grades from the first craft. Show the next useful
step, its stronger potential and the exact missing capability. Expand to the
full ladder on request, so the normal screen remains as clear as building.
Examples should use actual recipe/drop data once sources are authored, not
invented destinations or a vague "requires higher level".

A better blank with a Faint catalyst still receives a Faint-range new modifier.
A potent modifier on a weaker base keeps the existing held-back-modifier
contract: show both its usable value and stored potential before consumption,
and suggest a suitable base. Do not silently waste potency or erase a stored
roll. Raw roll tier and currently expressed tier must remain distinguishable.

Early catalysts should be sufficiently accessible that using one on a starter
item feels reasonable; stronger versions come from harder resource expeditions
and suitable refining processes. Exact sources, refining yields and conversion
costs still need authoring and pacing tests. Avoid making infinite safe farming
of Faint catalysts alone bypass the later resource/facility step.

Retain early Foundry creativity: a Faint Ember/Frost catalyst still provides its
recognisable early mutation when used on the plate. This craft-strength proposal
does not reduce all early Foundry effects to stat additions. Later potency-based
Foundry evolutions require explicit authored rules rather than automatic damage
multipliers. Existing catalyst IDs, items and plate effects need a deliberate
compatibility mapping before any quality system is installed.

## 4. Optional finer rarity bands, with the existing top ceiling

Recommended names are provisional. Each rung adds one normal rolled modifier;
the grade itself adds no hidden damage, defence or multiplier.

| Grade | Rolled modifiers | Intended acquisition role |
| --- | --- | --- |
| Plain | 0 | Dependable baseline; a useful item immediately. |
| Worked | 1 | A modest first refinement. Small era-one property pool. |
| Keen | 2 | A first deliberate pair of supporting properties. |
| Refined | 3 | A developed item from better forging or a fortunate drop. |
| Wrought | 4 | The existing upper modifier-count budget, earned later. |

This splits the existing 1–2 and 3–4 bands into visible steps. It does not
introduce a new tier above Wrought or pretend every new colour is a new mechanic.
Modifier-strength tiers and material capacity remain separate, clearly explained
only when they affect the selected item. Ordinary iron remains useful later.

Suggested initial **untargeted craft** distributions for testing:

| Process | Plain | Worked | Keen | Refined | Wrought |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bench starter equipment | 85% | 15% | 0% | 0% | 0% |
| Basic forge | 65% | 30% | 5% | 0% | 0% |
| Improved forge | 20% | 40% | 35% | 5% | 0% |

These are starting hypotheses, not a tested balance. Later forging can produce
Wrought; a rare existing drop can still bypass the ordinary crafting steps.
Preserve existing drop rolls and numerical properties when classifying their
modifier counts; do not globally weaken the early loot pool in this pass.

These rarity distributions concern modifier count only. The selected inputs in
section 3 determine modifier strength; a four-modifier item made from weak inputs
must not secretly receive four late-tier rolls.

Craft skill should improve eligible processes and roll consistency rather than
rapidly granting a large global Wrought chance. An early targeted craft would
guarantee at least Worked and aim its one modifier; improved targeting can
guarantee Keen. The panel states this before payment. That explicitly revises
the current universal "Kind craft is at least Keen" rule and needs approval.

## 5. Move mastery rewards apart

Preserve the skill's responsive baseline and let the first Foundry Kind remain
creative early. Mastery should then reward sustained use of that chosen skill.

- Award practice for a real cast that affects a live hostile: damage or an
  applicable ailment/control effect. Credit once per input cast, shared across
  fans, forks, delayed impacts and bursts; no extra credit from echoes, linked
  skills, ticks or overkill. Shooting empty ground cannot train an attack.
- Movement skills earn their practice through real use while threatened, using
  the existing engagement/threat state. They do not need to deal damage or force
  the player to take a hit. Empty safe-area dash spam gives no combat mastery.
- Weight credit by the skill's authored base cooldown, so fast spamming and
  cooldown equipment do not determine how quickly a skill is learned. A proposed
  starting conversion is base cooldown / 1.5 practice points per qualifying cast.
  UI displays mastery progress, not an explanation of this internal formula.
- Start tests at **180 / 720 practice points**: about 4.5 / 18 minutes of nominal
  continuous qualifying use, with real encounter time longer. These replace the
  old 30/120-use speed; they are not enforced wall-clock waits.
- First reward: a modest handling/control improvement, usually around 5–8%,
  checked against actual ailment breakpoints. Avoid early +15–25% blanket damage
  or buildup and the immediate extra fork/pierce. Preserve interesting mechanical
  masteries for the second milestone rather than deleting them.

An early Foundry mutation, a useful crafted upgrade and a major mastery perk
should each have room to be noticed. They should not routinely unlock during
the same short gathering/combat outing. Do not take attack responsiveness away
and sell it back as mastery.

## 6. Put tension in preparation and expeditions

Initial fresh-character playtest targets, **not time locks**:

| Moment | Target session window | Desired experience |
| --- | --- | --- |
| First useful crafted equipment | 5–10 minutes | "I can prepare for the next fight." |
| First small mastery reward / early Foundry experiment | 10–20 minutes, separated by ordinary play | "This skill is becoming mine." |
| Deliberate Keen item and improved workshop | 25–40 minutes | "That trip brought back what I needed." |
| Major mastery interaction / increasingly specialised kit | 35–60 minutes | "The setup now works together." |

Use the existing mine fittings and bog-iron expedition as meaningful preparation.
Make basic gear more accessible, then preserve the need to carry back a useful
resource and turn it into improved capability. Keep repeated work tied to
components, a building or the existing order. Do not increase Blacksmithing XP
requirements globally until a timed route shows that useful work supports them.

Short forge action feedback and batch controls can make production feel physical;
long idle bars, repeated menu clicks and compulsory disposable crafts should not
be the main source of the extra time. No new production automation is proposed.
The existing 20–40 minute slice completion target remains a benchmark: the larger
mastery reward can follow the first completed loop, rather than gating it.

## Compatibility, authority and implementation order

This proposal would refine D-014's rarity bands, D-019's mastery pacing and the
crafting portion of D-023. D-002's useful-work requirement and D-025's early
Foundry creativity remain. Nothing here is an accepted replacement yet.

Keep all existing items and their modifier values. If grades are split, derive
their new display classification without rerolling them. Preserve already
earned mastery perks explicitly before changing thresholds: current saves store
use counts, and simply editing threshold data would otherwise remove perks on
reload. New progress follows the new curve. No forced character restart.

Recommended implementation sequence after approval:

1. Forge catalogue/selected-item UI, comparison, costs and ingredient navigation;
   retain current economy to isolate usability feedback.
2. Minimal starter kit and visible material/catalyst quality, with input-specific
   modifier bands and honest locked-grade previews. Preserve existing loot values;
   decide whether the optional five rarity names still improve clarity afterward.
3. Meaningful-use mastery, slower rewards and explicit legacy-perk migration.
4. Timed fresh Warden, Ranger and Kindler routes with the same world seeds.
   Record first equipment, first Keen, first mastery, improved forge and first
   trial readiness. Adjust the pacing values before adding more gates.

Affected data: `crafting.json`, `items.json`, `skills.json`, with a small UI look
resource following the building catalogue. Affected rules: crafting outcome
preview, input quality/potency, rarity selection, mastery credit and save migration. Verification must
cover cost/fuel batches, previews without spending, compatible Kind selection,
quality distribution, weak-input ceilings, held-back strong rolls, previews of
future grades, real-use credit, legacy rewards and the existing full
economy/loot/combat/save suites. Inspect the interface at 720p and 1080p.

## Implemented outcome — 6 September 2026

The owner approved the proposal including the clarification that input quality,
not extra rarity names, is the strength ladder. D-026 records the revision.

### Catalogue and starter equipment

The ordinary work panel now uses recipe cards, category/search selection and a
scrolling detail pane, with Close, payment totals, next action and Make outside
the detail scroll. Equipment has Make, Improve and Transfer views; Foundry is a
separate shortcut. Recipe links retain a back path. Pins show live remaining
requirements during play; pins are session UI state rather than save data.
Material batches reserve every ingredient and then check total fuel before any
payment; batch size is 1–20. Gear is made one item at a time. The native preview
also returns the guaranteed base versus worn equipment, modifier-count chances,
all compatible family rolls, each potency band, held-back values and grade gates.
Selecting a locked grade never spends resources. Incompatible Kind/potency
choices cannot be paid. Hand crafting still works without a station.

Four bench recipes use existing resources:

| Item | Cost | Guaranteed base |
| --- | --- | --- |
| Wooden Cudgel | 4 wood | +5% physical damage |
| Simple Bow | 4 wood, 1 hide | +5% projectile damage |
| Wooden Focus | 4 wood | +5% fire damage |
| Hide Vest | 3 hide, 1 wood | 4 armour |

The four new starters are recipe-only, so they do not dilute or reseed the
existing fourteen-base drop pool. The existing shield and quiver remain. Iron Mace and Iron Shield now need three
iron ingots and two wood, with their existing fuel/skill gates. Bench assembly
does not award Blacksmithing XP; the result message reports actual awarded XP.

### Concrete input ladder

Quality is chosen for the workpiece being made. One extra graded iron ingot
reinforces its fittings/bindings without replacing the base's material or its
implicit properties. This works for wooden and metal bases alike, allowing a
favourite material to keep growing. There is no duplicate ore family.

| Grade | Extra input when making gear | Refinement recipe | Process gate |
| --- | --- | --- | --- |
| Rough / tier 1 | none | normal recipe materials | original recipe gate |
| Sound / tier 2 | 1 Sound Iron Ingot | 2 Iron Ingots + 1 bog iron + 2 fuel | Improved Forge, Blacksmithing 3 |
| Excellent / tier 3 | 1 Excellent Iron Ingot | 1 Sound Iron Ingot + 1 Steel Ingot + 1 Silver Ingot + 3 fuel | Improved Forge, Blacksmithing 5, Era 3 |

Each of the twelve current Kinds has Faint, Stable and Potent crafting grades.
Existing IDs mean Faint; `stable_<id>` and `potent_<id>` are separate owned stocks.
Stable costs one Faint Kind, one bog iron and two fuel at the Improved Forge /
Blacksmithing 3. Potent costs one Stable Kind, one silver ingot, one steel ingot
and three fuel at the Improved Forge / Blacksmithing 5 / Era 3. Refinement yields
one Kind. Later resources and facilities cannot be replaced by an arbitrarily
large pile of Faint Kinds. Distil Faint Ember at the basic forge from one iron ore,
two charcoal and two fuel, so an early Ember gear experiment need not consume a
unique trial reward. Other existing hunt/exchange sources remain.

An ordinary unaimed craft rolls Faint strength even on Excellent ironwork. An
aimed craft uses the selected Kind's potency. Capacity controls the expressed
tier; stronger raw rolls remain stored for a later Preserving Transfer. Each
rollable modifier has explicit `craft_tiers` in `items.json`, separate from its
unchanged drop/legacy tiers. Fire, physical and cold damage use 3–6%, 7–12% and
13–20%. Life uses 3–6 / 7–12 / 13–20; armour uses 2–4 / 5–8 / 9–14. Advanced
properties retain their minimum tier. Mechanical affixes have authored integer
bands; additional craft breakpoints generally wait for Potent expression.
Blacksmithing raises the roll floor by 6% of band width per level beyond one,
capped at 24%. It cannot change the upper bound or potency.

Modifier-count probabilities use the proposal's bench/basic/improved profiles.
Era-three improved forging uses Plain 5%, Worked 15%, Keen 35%, Refined 35%,
Wrought 10%. Aimed bench/basic crafts guarantee one roll; an improved-forge
recipe guarantees two. Counts are capped by the eligible pool, and previews
combine probabilities after that cap. Existing drop distributions, rarity IDs
and rolled values remain; new crafts use the five exact count names. There is
no new modifier budget above four.

Property-specific Ember-Tempering keeps its established 25–40% resistance roll
and skill floor, but now consumes a **Stable Ember**. It is a separate guaranteed
resistance process, not an ordinary family roll. Rough bases can hold that
stronger roll back; the item shows usable and stored values. Quenching and
Preserving Transfer retain their established non-destructive-value rules.

### Foundry and save compatibility

A grade aliases its original Kind only while resolving the plate. Placement,
ownership, lifting and saved data retain the actual grade ID. All grades keep
the existing early mutation, including ordered Smoulder/Steam Plume routes;
this pass adds no automatic Foundry potency damage multiplier. The tray includes
graded stocks. Stored gear adds optional `workpiece_tier` and per-roll `crafted`
markers; older gear defaults to its original material cap and original bands.
Transfers preserve each roll's band identity and use the receiving workpiece's
capacity. The craft RNG counter is now saved so reloads retain its position. Payment
consumes the actual validated stock even when an imported Kind sits in the
material pack instead of the pouch, preventing negative currency balances.

Mastery adds optional versioned practice and earned-perk snapshots within the
existing save schema. Old use counts unlock exactly the perks already earned
under `legacy_mastery`, retaining their original modifiers and values. Unearned
effort carries into the new curve without awarding an extra old perk. Subsequent
loads use the snapshots and cannot reapply migration. No save reset is needed.

### Mastery and pacing

New rewards occur at 180 / 720 practice. Each qualifying cast pays base cooldown
/ 1.5; the original diagnostic use counter remains separate. First rewards are
6% spatial reach or dash recovery, scoped to that skill. Existing later perks
remain. Credit is shared by reference across each input's fan, forks and delayed
bursts. Empty shots, invulnerable/no-effect targets, dead targets, grazers,
automatic echoes, linked casts and secondary ticks do not independently train.
Dash earns practice while a live hostile is chasing or winding up within its
existing engagement/vertical reach. A hit can qualify through actual damage or
changed ailment/control state, including a frozen target consumed by shatter.

The 5–10 / 10–20 / 25–40 / 35–60 minute session windows remain **playtest targets**,
not measured human completion times or enforced waits. Automated seeded resource
and economy checks demonstrate viable costs and gates. Fresh Warden, Ranger and
Kindler resource-budget routes each reach a bench weapon, the mine order and an
improved forge at Blacksmithing 3 through useful fittings; expedition pickups
and facility placement are explicit fixture inputs. These checks cannot establish
human travel, discovery, combat and menu time. Blacksmithing XP thresholds were
therefore not raised. There is no new mandatory timer or disposable XP grind.

### Verification and limits

Native tests cover starter costs, total fuel reservation, atomic batches,
incompatible targeting, Faint ceilings at high skill, locked grades, held-back
and transferred rolls, grade persistence, craft RNG replay and legacy mastery.
The existing native suite and full Godot regression suite pass. The new
`forge_progression.tscn` checks the actual catalogue at 720p/1080p, links, pins,
selected inputs, graded saves, delayed-cast identity, echoes and threatened dash.
Runtime screenshots are generated by the same scene with `-- --capture` and
listed in `build/codex-aesthetic/index.html`.

Remaining tuning work is owner playtesting of the session-time targets, resource
yields and roll bands. The catalogue uses code-owned representative silhouettes;
these are UI icons, not a new production-art dependency. Rare build-defining
item modifiers and potency-specific Foundry evolutions remain separate future
work. Normal crafting routes exclusively through `ForgeCatalogue`; the old duplicated
long-list renderer was removed.

Final verification: **31,301 native checks, zero failures**. The repository's
Godot suites pass, including the unchanged 50,000-kill audit of the fourteen
original loot bases (1,997 gear drops, 294 bows). The added forge suite passes
35 checks headlessly and 39 with its four runtime captures. All three scripted
class resource routes reach the improved forge at Blacksmithing 3. Screenshots
were inspected at 720p and 1080p. The compiled local DLL is installed.
