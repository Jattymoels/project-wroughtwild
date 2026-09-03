# Progression: Eras, the Foundry, and Ores as Properties

**Status:** Accepted direction (owner, 3 Sep 2026); implementation begins with the first era transition  
**Related decisions:** D-002, D-007, D-014, D-016, D-018, D-019

## Purpose and player fantasy

A persistent build in a procedural open world has nothing to push
against: there is no campaign ramp for a talent tree to climb, so power
leaks into item decimals and progression becomes "50% increased cold
versus 45%". This spec answers that with three locked-together ideas:

1. **Eras are the campaign.** The world never adds a zone; it changes
   state when the player hits milestones they wanted anyway.
2. **The Foundry, not a tree.** Points are ingots placed on a forged plate;
   power comes from arrangement, not from the ingot's number.
3. **Ores are properties, not ranks; items and skills carry mechanics,
   not decimals.** One trait vocabulary runs through building materials,
   item bases and Foundry ingots, so "all things come together" is
   mechanical.

The owner's frame: Minecraft's undercurrent of overworld, then the nether,
then the end, then back to the overworld's hard content, but delivered by a
world that changes around you rather than by portals; Hades' pact, where
the difficulty rises because your own capability and choices rose.

## Eras

An era is a story beat the world passes through. Each era changes three
things at once:

| Axis | What changes |
| --- | --- |
| What mobs **do** | Each family gains one mechanic, not a level: hounds hunt in wider packs, whelps leave burning ground, the shrieker's call carries further. Modest numbers ride along. |
| What the ground **offers** | New ores surface where the strata crack; old veins may flood; the wastes' rifts open. Places already exist (valley, the deep, the wastes, the mountains); eras change their state. |
| What you can **work** | New alloys, processes and forms; the Foundry plate is forged a row wider. |

**Triggers are milestones the player chooses to hit**, never time or a
level: the Forge Tyrant's fall, the mine reinforced, the far gate reached,
the class hall found, the first alloy smelted. The player may sit in an era
as long as they like, but the goals that make them stronger are the same
goals that wake the world. Mobs scale **per era, never per player**: a
fresh area in era three is dangerous because the world is in era three, not
because it read the sheet.

The base is a stake: each era's threat is aimed at the claim. Encroachment
(nests on the fringe of home, `world.json` `encroachment`) is era two's
expression of "the mobs organise" and is off in era one; it needs mob
behaviour to organise with before it is more than scope.

Proposed first three eras (defaults, owner to confirm):

| Era | Story | Ground | Work | Mobs |
| --- | --- | --- | --- | --- |
| 1 · The Valley | Arrive with nothing | wood, stone, iron | timber, stone, iron; the Foundry's 3×3 plate | the day-one families |
| 2 · The Deep Wakes (the Tyrant falls) | its kin stir below | copper and tin surface in the deep; strata crack | bronze (copper + tin): malleable, tough; the first curved form; plate 3×4; encroachment on | hounds hunt in wider packs; whelps leave burning ground; nests |
| 3 · The Ash Tide (the gate reached, the mine reinforced) | the wastes spill | ember-iron in the rifts; silver in the mountains | steel (iron + charcoal): hard, resilient; ember-iron: fire; silver: warding; plate 4×4 | shriekers call further; elites common beyond the heartland |

Era four is the return: the mountains and the trial's true form, once
steel can be worked. It is out of prototype scope.

## The Foundry

The point system's plate is a made thing: its size and metal come from
the player's ores, so the ceiling is forged, not granted.

- **Ingots** are the points. Each has a **verb** (chill, fire, projectile,
  area, ward...) and a flat, small number that never changes. Ingots come
  from milestones and knowledge, not kills: the first smelt, each family's
  first kill in each era, landmarks, orders, era transitions. The total
  available is capped per era; the cap rises when the world does.
- **Placement is the build.** Adjacency pairs are the first mechanic: a fire
  ingot beside a projectile ingot means bolts leave burning ground. Lines
  of three are set effects. An ingot enclosed on four sides becomes its
  **wrought form**, a rule-bending effect (the uniques deferred in
  [items-and-modifiers.md](items-and-modifiers.md) live here too).
- **Refinement widens reach, never the verb.** An ingot re-forged from a
  higher metal in place counts further: iron chill reads its neighbours,
  steel chill reads two out.
- **Respec is re-forging** at the forge: pull ingots, pay a little metal,
  place again. Cheap early, meaningful late.

The curve: early, a 3×3 plate and two or three ingots, no space pressure,
one pairing felt in the next fight. Mid, the plate widens with the era,
lines appear, space pressure makes layout a real choice. Late, refinement
and wrought forms; the whole plate rearranged around a keystone.

## Ores as properties; items and skills as mechanics

Minecraft's tiers are strict replacements, so iron makes stone trash. Here
each metal has a **trait profile**, the same vocabulary building uses
(`construction.json` `materials`): copper is malleable and conductive; iron
is hard and joins; bronze is malleable and tough; steel is hard and
resilient; ember-iron carries fire; silver wards.

- **An item's base sets what it can hold, not how hard it hits.** A copper
  wand carries chill at tier one; bronze holds tier two and one conductive
  mechanic. The number spread between metals over the whole game is small
  (a third or so). Power is what the item can do.
- **Old ores never become trash**: alloys consume them and building keeps
  using them. Steel needs iron forever.
- **Modifier tiers are breakpoints with mechanics**, three or four per
  modifier: tier-one chill slows; tier two also slows their attacks; tier
  three lets shatter chain. Bases and tier ranges are era-bound, so the
  stat race resets per era instead of inflating across the game.
- **Held-back modifiers** are the early taste: a drop may roll a high tier,
  but a copper base expresses only tier one, showing the rest greyed
  ("held back by copper: bronze or better unleashes it"). The
  preservation catalyst (ADR-0002) moves a loved modifier to a better
  base, so the first good find is never thrown away.
- **Every big mechanic has three doors**: an item tier, a Foundry line, a
  skill mastery perk. Any one gives the small version; all three give the
  full one. Skills scale by **mastery**, a few use-milestones each
  unlocking one perk; supports remain the tag grammar (D-016).

**Power budget:** numbers across all three axes stay within roughly
threefold over the whole game; the count of interactions is what
multiplies. The felt jump at an era is the world's, not the sheet's.

## System relationships

| Receives from | Receives | Supplies |
| --- | --- | --- |
| World generation | strata, veins and rifts per era; landmarks as milestones | which nodes surface, mood shifts, threat state |
| Combat and grammar | tags and hooks | ingot verbs, mastery perks, mob era mechanics |
| Items | bases and modifiers | tier breakpoints, held-back display, era-bound ranges |
| Crafting | alloys, processes, catalysts | trait profiles per metal, re-forging |
| Construction | material families and traits | the same families as item bases; plate metal |

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Era triggers (world effects) | Pace of the campaign; which ambitions wake the world |
| Per-era mob mechanics and number nudges | How an era reads as danger, not a level |
| Ores per era, vein density | Exploration pull after a transition |
| Plate size per era, ingots per era | The Foundry's ceiling and space pressure |
| Adjacency, line and wrought effects | Build expression and discoverability |
| Re-forge cost | Experimentation versus commitment |
| Modifier tier breakpoints, base capacity per metal | Item power as mechanics; the held-back taste |
| Mastery milestones | How fast a skill's perks arrive |
| Global number budget | The threefold ceiling |

## Failure cases

- Eras read as difficulty spikes rather than a changed world (the fix is
  always a new mechanic and a new resource together, never numbers alone).
- The Foundry collapses into a best layout everyone copies; adjacency must
  stay legible but combinatorially wide.
- Held-back modifiers feel like a tease with no route: every held-back
  item must name the base that unleashes it, and that base must be
  reachable in the next era.
- Old metals become trash despite alloys; watch recipe demand.
- A player parks in era one forever because era two only threatens; each
  era must also offer (ore, form, plate row) more than it threatens.
- Mastery and ingots both scale a skill until numbers creep; hold the
  threefold budget.

## Prototype acceptance

- One era transition, on the boss kill, changes what mobs do, what the
  ground offers and what can be worked, and the player can say which is
  which.
- A copper find shows a held-back modifier and names what unleashes it.
- Two Foundry layouts of the same ingots play differently.
- A tester can say why they got stronger without quoting a number.

## Implemented: the first era transition (3 Sep 2026)

`data/tuning/eras.json` lists the eras in order; the current era is the
last whose `trigger_world_effect` is active, stopping at the first unmet
one (`PlayerEconomy::currentEra`). Era two, *The Deep Wakes*, triggers on
the Forge Tyrant's fall (`stonecut_blocks`) and changes the three axes:

- **Mobs do:** `mob_mechanics` per enemy id. Ash hounds gain a pack
  member (`pack_size_bonus`, applied when a pack spawns); ember whelps
  leave `burning_ground` where they die (`burning_ground.gd`: a patch that
  pays fire through the sim's mitigation for a few seconds). The engine
  asks `era_mechanic(enemy, name)` and never carries the numbers.
- **Ground offers:** node types carry an `era` (`worldgen.json`): copper
  and tin veins are placed on cave floors from the seed like everything
  else, but the terrain holds them back until `reveal_era` brings their
  era, with a notice ("the strata have cracked") and a light shift
  (`BiomeMood.set_era`).
- **Work:** `smelt_bronze` at the forge (copper, tin, flux wood;
  Blacksmithing 2); **bronze** as the first malleable family; the **arch**,
  a wall piece with a half-round opening, requiring `malleable` - the first
  form a material's property unlocks. Iron lost `malleable`: curved forms
  wait for bronze.
- **Encroachment** is gated by the era's `encroachment` flag: era one has
  no nests even with a home.

The HUD names the era; the sandpit polls the sim once a second and tells
the era's story when it changes.

## Implemented: the Foundry (3 Sep 2026)

`data/tuning/foundry.json` and `sim/foundry.h`:

- **Ingots** are eight verbs (ember, frost, edge, reach, vigour, plate,
  ward, haste), each one `items.json` modifier at a flat value. **Sources**
  map a milestone event to one ingot, each granted once and only from its
  era on: the first workbench and the first smelt (`recipe:`), each
  family's first kill (`first_kill:`, reported by the engine), the mine
  reinforced and the Tyrant's fall (`world_effect:`), the era itself
  (`era:2`), the first bronze. The economy raises its own events from
  crafts and world effects and queues notices for the HUD; kills come in
  through `foundry_event`.
- **The plate** is `plate_by_era` (3x3, 3x4, 4x4). `foundry::effects`
  lists what the plate does: every placed ingot's verb, every orthogonal
  adjacency that matches a **pair** (Ember beside Reach is Wildfire, Frost
  beside Edge is Wide Shatter, Vigour beside Plate is Bulwark...), and every
  straight **line** of three matching ingots, which adds the verb again.
  `grammar::foundryMods` turns those into modifiers in the same pool gear
  uses, so skill numbers, statuses and hooks read the plate with no new
  resolver; stat ingots reach the sheet through `deriveStats`' extra
  effects. **Re-forging** (lifting an ingot) pays `reforge_cost`, one iron
  ingot.
- **The panel** (`foundry_panel.gd`) opens from a built forge's work panel:
  the plate as a grid, the ingots in hand as a tray, the effects as a
  list; a tray click picks an ingot, an empty cell sets it, a filled cell
  lifts it. The plate, the ingots and the milestones ride in the sim's
  save.

Not yet: refinement (reach) and wrought forms.

## Implemented: items as mechanics (3 Sep 2026)

- **Tiers are breakpoints.** A modifier tier may carry `breakpoints`
  (`items.json`): extra effects the roll brings at that tier and every
  tier above it, in the same effect vocabulary the grammar already
  resolves. Tier-two cold builds chill faster; tier three chills deeper.
  Tier-two fire burns harder; tier three burns longer. Tier-two life also
  armours. Seven modifiers gained a third tier.
- **Bases cap tiers.** `tier_cap` on an item base is the highest tier its
  metal can express: iron holds two, the new bronze sceptre and bronze
  mail hold three (craftable at the forge from era two's bronze).
- **Held back.** A roll above the cap speaks at the cap tier's best value
  (`items::effectiveRoll`) and the pack screen shows the full sentence
  greyed with what unleashes it. Gear mods and stat totals both read the
  effective roll and its breakpoints.
- **Era-bound drops.** `rollEnemyGear` rolls the table's tier plus one per
  era past the first, and one more for an elite's kill, so era two's
  elites drop the tier-three rolls an iron base holds back: the taste.
- **Preserving Transfer.** The preservation class of ADR-0002 does its
  first job: at the forge, a Preserving Catalyst (a rare drop from stone
  husks and shriekers) moves the worn item's rolled modifiers, whole, onto
  a base of the same slot in the pack; the old base is spent with the
  catalyst. The forge panel lists one row per target.

## Implemented: skill mastery, crafted rolls, the pack (3 Sep 2026)

- **Mastery.** Every combat skill lists use-milestones (`skills.json`
  `mastery`); each unlocks one perk, a modifier at a flat value that
  applies to that skill alone. The grammar tags every skill with
  `skill:<id>` (`CombatSkillDef::resolveTags`) so a perk can target it
  without touching its siblings: the orb chills deeper at thirty casts,
  forks once more at a hundred and twenty; the nova widens; Shatter
  reaches further. The sim counts casts that fired (`noteSkillUse`),
  uses ride in the save, the HUD announces a perk, and the pack screen
  shows progress under each skill. This is the third door.
- **Shatter.** The owner's missing verb: a ring spell whose own damage is
  a whisper and whose tag triggers the shatter hook (`grammar.json`
  `trigger_tags` now include `shatter`), so every frozen enemy in the ring
  shatters and the novas cascade. It arrives as a page.
- **Crafted gear rolls** (`crafting.json` `craft_rolls`): a recipe whose
  output is an item base makes a rolled item in the pack, keen or wrought
  by Blacksmithing level, at the era's tier, seeded by the craft count.
  The base is certain, the roll is the excitement.
- **The pack**: Drop on a material tile puts the stack at your feet as
  pickups; Discard on a gear card throws it away.

## Implemented: era three and the deeper floor (3 Sep 2026)

- **The trial has floors** (`trial.json` `floors`): a deeper run the gate
  offers once its `requires_world_effect` is active, with its own stages,
  boss, bank-out point and completion effect. *The Deeper Forge* opens
  when the Tyrant has fallen, is fought with the new families (wisps,
  hollow knights, lurkers, a shrieking stair), and ends at the Ash
  Warden. The gate presents a choice of floors; the session carries the
  floor and everything reads it (`TrialSession::stages/boss/exitAfterStage/
  completionUnlock`).
- **Era three, The Ash Tide**, triggers on the Warden's fall (`ash_tide`).
  Ember-iron surfaces in the wastes and silver in the high crags (era-3
  node types); steel (iron and charcoal at the improved forge) and silver
  join the families; the plate is 4×4; shriekers call further
  (`scream_radius_bonus`), hounds and husks run with cinder wisps
  (`pack_escorts`), and every pack rolls an extra chance of an elite
  (`elite_chance_bonus`). Eras stay ordered: the tide alone does not skip
  the deep.
- A fix found on the way: an order's world effect now goes through the
  recording path, so reinforcing the mine forges its Foundry ingot and
  can wake an era.

Not yet: wrought forms and refinement, the wider modifier vocabulary
(attack and cast speed, stuns) the owner asked for.

## Open questions

- The exact ore set and era triggers (defaults above).
- Whether ingots can be lost (no; re-forged only) or traded.
- How the class hall grants its ingots and whether it is an era trigger
  or an era-two landmark.
- Day and night as an era-two mob mechanic carrier, versus its own later
  iteration.


## Implemented: the pacing pass (3 Sep 2026, D-020)

The owner's full-arc verdict was that power arrived too fast. The numbers
said something sharper: the floor sat at the ceiling. A day-one Heavy
Strike (28) two-shot every era-one mob (16–45 life), and the first Keen
mace made that one shot. There was nothing to grow into. Four changes,
all data plus one verb:

- **Long fights.** `world.json` mob life ×2.5 and mob damage ×0.7; the
  player's numbers, the bosses and the trial rooms untouched (the oracle's
  boss and trial rates held: 33 / 100 %, 59.6 / 85.6 %). A whelp is three
  heavy blows; a pack is a half-minute where the sweep and spacing matter.
- **The quiet heartland.** `worldgen.json` first danger ring at 0.35
  density, hostile packs no nearer than 40 m; **grazers** (`biomes[].grazers`,
  `grazer_density`) are placed by their own pass outside the danger rules,
  flagged `grazer` on the pack so the engine never crowns or escorts them.
  The first hour is a world with elk in it, not a fight.
- **The era-one pool.** `items.json` modifiers carry `from_tier`; every
  interaction modifier (forks, deep frost, wide shatter, frostbite,
  kindling, burn, lingering flame, wildfire reach, smouldering, serration,
  hemorrhage) is `from_tier: 2`, so a tier-one roll — what era one's mobs
  drop — is life, armour, resistance, reach or a small damage add
  (5–10 %). Elites roll a tier higher, so the lucky drop still exists and
  reads as luck; era two opens the pool to everyone. The sceptres' implicit
  is a small cold add, not a fork.
- **Fire-setting** (below): the first "not yet" the world says.

### Fire-setting: the capability gate that is a verb

The owner found the survival-game pickaxe played out. The gate is
therefore a technique, and it is the game's own grammar: **heat cracks
stone; cold shatters what is hot.** Real pre-industrial quarrying.

- `worldgen.json block_rules` gain `by_hand` (soil yes, stone no, bedrock
  no) and `heat_to_crack` (stone 1). Hands dig soil and *cracked* rock.
- `worldgen.json fire_setting`: fuels by building family (`wood` heat 1,
  45 s; `charcoal` heat 2, 60 s), `reach_cells` 1, `soak_seconds` 4,
  `hot_seconds` 45, `quench_radius_m` 2.5.
- `construction.json`: the **campfire** shape (form `fire`, requires the
  `fuel` trait; timber has it, and a **charcoal** family exists with
  `only_for_trait: fuel` so nobody builds a charcoal wall). A campfire is
  a piece that burns out: it occupies its cell while it burns, heats the
  rock and nodes within reach, and is gone — no refund, the wood is ash.
- Nodes carry `heat_to_work`: trees 0, boulders and iron 1, the alloy and
  era-three ores 2. A soaked node quenched by cold is cracked for good and
  works on E.
- The engine (`terrain.gd`) keeps hot cells (heat, expiry) and cracked
  cells (saved), draws an ember shell over hot rock and a dark one over
  cracked; `placed_block.gd` burns the fire; the Frost Orb (and Ember
  Bolt) now stop on the world — cold quenches within the radius, fire
  heats the struck block; the Frost Nova quenches the ring around you.
  Refusals under the crosshair are the tutorial: "Stone will not yield to
  hands · fire against it, then cold" → "Stone glows · cold will crack it".

The chain a fresh player walks: wood by hand → a campfire against a
boulder or cliff → the Frost Orb → stone and iron → the forge → charcoal →
the alloy ores. Every rung is a verb they already have.

## Direction: skills on the plate (accepted 3 Sep 2026, to build next)

The support category the owner asked for, without copying gems. **A skill
tablet is laid on the Foundry plate, and the ingots touching it are that
skill's supports.** Frost Orb beside Reach is a wider orb; beside Ember it
leaves burning shards; the same ingot between two tablets serves both.
Tags must still match (a projectile ingot does nothing for a strike), so
D-016's grammar stays the rule book. The plate widening with the era is
more tablets and more neighbours: the support ceiling is forged, not
granted, and rearranging is respec. Later supports come from **manners
learned from mobs**: each family teaches one way of fighting after enough
of them have fallen (the hound's manner hunts, the wisp's casts on the
retreat, the husk's staggers), so the world advancing is the support pool
growing. Together they take the burden off items, which is the point.
