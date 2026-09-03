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
the era's story when it changes. Not yet: the Foundry, item tiers,
mastery, the third era.

## Open questions

- The exact ore set and era triggers (defaults above).
- Whether ingots can be lost (no; re-forged only) or traded.
- How the class hall grants its ingots and whether it is an era trigger
  or an era-two landmark.
- Day and night as an era-two mob mechanic carrier, versus its own later
  iteration.
