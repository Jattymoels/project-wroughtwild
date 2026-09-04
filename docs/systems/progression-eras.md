# Progression: Eras, the Foundry, and Ores as Properties

**Status:** Accepted direction (owner, 3 Sep 2026); implementation begins with the first era transition  
**Related decisions:** D-002, D-007, D-014, D-016, D-018, D-019, D-022, D-023

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
- **The plate** was `plate_by_era` (3x3, 3x4, 4x4) until D-023 slice 1
  forged the frame (see *Implemented: the frame*, below). `foundry::effects`
  lists what the plate does: every placed ingot's verb, every orthogonal
  adjacency that matches a **pair** (Ember beside Reach is Wildfire, Frost
  beside Edge is Wide Shatter, Vigour beside Plate is Bulwark...), and,
  since slice 1, each working's supports and their backing (the line of
  three is gone).
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

## Implemented: skills on the plate (3 Sep 2026, D-022)

The support category, without gems. A known skill may be laid on a plate
cell as a **tablet** (`foundry_place_skill`; `Placement.skill`). Every
ingot orthogonally beside a tablet **supports** that skill alone: its
modifier applies to that skill at `support_multiplier` (2.0) times the
ingot's value, on top of what the ingot does for everyone, and only when
the modifier can apply to the skill's tags at all (Reach beside Frost Orb
widens the orb; Ember beside it does nothing, and the effects list says
so; a self ingot never supports). `foundry::effects` lists supports with
the skill id, and `grammar::foundryMods` scopes them with a `skill:<id>`
tag, the same way mastery does. An ingot between two tablets serves both.
Tablets lift for free (they are knowledge); ingots still re-forge for
metal. The plate widening with the era is more tablets and more
neighbours. **F** opens the Foundry anywhere (the forge is where the metal
comes from, not where the plate lives); the first dressed block is a
milestone (`recipe:dress_stone` → Plate) beside the first bench, first
kills and the first smelt.

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


## Two rules (3 Sep 2026, D-021)

**Materials have responses, skills have properties.** A skill is not a
list of bespoke things it does; it carries tags (D-016: attack, spell,
projectile, area, cold, fire, impact...). Enemies answer those tags
(chill, ignite, bleed, shatter) and so does the world: cold on hot rock
cracks it, fire on rock heats it, an impact on a set wedge drives it.
Whenever a combat behaviour is introduced, ask what in the world should
answer it. Not everything needs an answer; enough should that players
start asking "can I ignite this, can I freeze that, can this blow move
that."

**Baseline, Exploit, Synergy.** Every world interaction has a contextual
E route that always works, slower but complete. A skill property can
shortcut it (the exploit). Two properties together do substantially
better (the synergy). Exploits buy time or yield; they never buy access,
so nobody is punished for a build they did not pick. The action bar stays
the ARPG's: there is no tool hotbar.

## Implemented: seams and the yard (3 Sep 2026, D-021)

The gate is masonry, not stone. You can touch rock from the first
minute; you cannot yet build a house with it.

- **Fieldstone** — boulders by hand. A building family with the `rough`
  trait and `only_for_trait: rough`, so it lays the **footing** (a
  half-height course on the cell floor) and the **dry wall** (a knee-high
  wall on a face), and nothing else. The first house is timber on a stone
  footing.
- **Stone seams** — a node (`stone_seam`, three guaranteed near spawn,
  denser in the hills) worked with a `tool_item`, the hand-made **timber
  wedge** (one timber makes two). E sets a wedge, E drives it over
  `drive_presses`; the last press splits two stone and spends the wedge.
  A heavy blow on a set wedge splits at once. A hot seam splits twice
  over under one blow.
- **The mason's yard** — a kit station (timber and fieldstone at the
  bench) whose one recipe dresses two split stones into one of the stone
  family. The forge kit's eight stone is now the first real masonry
  ambition; husks and crawlers pay split stone, not masonry; cracked
  strata pay split stone.
- **Fire-setting reframed** — hot rock is softened: an impact cracks a hot
  block, cold cracks every hot block in reach, and the alloy ores are
  worked while hot (or once cracked). Iron is hands' work.
- **The click is a milestone** — the first strike-driven split raises
  `work:strike_split`, which the Foundry pays with an ingot.

The chain: wood → wedges and a bench → a seam → split stone; boulders →
fieldstone → the yard's kit → dressed stone → the forge. Every rung is a
verb the player already has. Playtest question: did you build a wooden
home and feel clever when you finally worked stone, and did Heavy Strike
driving the wedge produce the click that your combat ability works on the
world.

## Direction: the plate as a working (3 Sep 2026, D-023)

The owner accepted the plate as the progression mechanic ("it limits the
amount of spells you can optimise, it also allows creativity in placement
to optimise joins") and set its next shape: the thing being worked (a
skill, or a defensive **vanguard** currency) sits in a designated socket;
the four orthogonal cells are its supports, and what a support means is
decided by what it touches; the diagonal cells hold more ingots or typed
currency that augments the supports beside them (an augmented fire ingot
beside a frost skill is **Scald**); class lives in row and column effects
at the plate's edge. Trade currency splits into kinds (catalysts,
vanguards, and their like for life and speed) that aim a craft or sit on
the plate. The full proposal, the reading tables, worked plates, the open
questions and the slice order are in [foundry.md](foundry.md). One
conflict is on record there: "Reach beside Frost Orb widens the orb"
above describes what the code does not do; Reach is a self stat and never
supports.

Owner answers (4 Sep 2026): sockets fixed for now; era one's plate is two
rows by four with two sockets (the spec proposes a 4x4 frame whose rows
the eras forge, so the plate grows without moving anything); the coin is
retired for now; Reach is to read area and projectile skills, which
settles the conflict above in this document's favour once implemented.

## Implemented: the frame (4 Sep 2026, D-023 slice 1)

`data/tuning/foundry.json` (schema 2) and `sim/foundry.h`:

- **The frame.** The plate is a `frame` of four rows by four columns whose
  rows the eras forge: `rows_by_era` names the first and last forged row
  per era (rows 1 and 2 in era one, the owner's two-row plate; row 0 joins
  in era two, row 3 in era three). Nothing on the plate ever moves when it
  grows, and a save needs no migration. `foundry::Plate` carries the
  frame, the forged rows and the sockets; `foundry::plate(def, era)`
  forges it.
- **Sockets** (`sockets`, at (1,1) and (2,2), the recommended layout the
  owner took) are the only cells that take a tablet, and take nothing
  else: `foundryPlaceSkill` refuses any other cell, `foundryPlace` refuses
  a socket, and both refuse an unforged row. A working is a socket, the
  ingots orthogonally beside it (supports) and the diagonals (corners).
- **Backing replaces lines.** A matching ingot touching a support from any
  side but the socket's makes that support count once more
  (`Effect.kind == "backing"`, scoped to the skill like a support). The
  line-of-three rule, `line_length` and `line_bonus` are gone.
- **Reach reads skills.** An ingot may name a `skill_modifier` it speaks
  beside a skill in place of its base; Reach speaks the new `items.json`
  modifier `reach` (`increased_reach`, applying to area, projectile and
  single-target skills, and tagged so no gear pool rolls it). The sim
  resolves it as one multiplier, `grammar::skillReach`, and the engine
  applies it to the delivery it owns: an area's radius, a projectile's
  flight, a strike's reach. Reach's base stays area size on the sheet.
- **Every reading on its cell.** `Effect` names the cell a support or
  backing comes from (`cellRow`, `cellCol`); the panel draws the whole
  frame with unforged rows as its unworked edge, marks sockets, rims a
  laid tablet's supports, and writes each cell's readings in its tooltip.
  A refused placement says why ("A tablet goes in a socket.", "A socket
  takes a tablet, not an ingot.", "The era has not forged this row.").
- **A stale save is lifted free.** `foundry::validate` runs on import:
  anything in an unforged row, a tablet outside a socket, an ingot inside
  one, or a second thing on a cell is lifted, and ingots return to the
  tray.

Tests: sim 3216 (the frame per era, sockets, placement refusals, supports
and their cells, Reach on the orb, the strike and the area strike, backing
and its absence across a socket, era two forging the row above without
moving anything, re-forging, save round-trip, a stale plate on load); the
engine's unit and integration tests were rewritten to the frame but not
run in this session (no Godot binary here).

Not yet: every ingot reading every skill (added elements, slice 2), the
typed currencies, the Vanguard, corner augments, links, rails, the metal
of an ingot.

## Implemented: every ingot reads every skill (4 Sep 2026, D-023 slice 2)

The owner's rule of 4 Sep ("I don't think we need to restrict 'cold damage
incr' to only cold spells ... adding a cold damage on the spell means you
might pursue different builds"): nothing on the plate is inert.
`data/tuning/foundry.json` (schema 3), `items.json`, `grammar.json`,
`world.json`; `sim/grammar.h`, `sim/foundry.h`, `sim/combat.h`:

- **The hit is typed packets.** `grammar::skillHit` returns a skill's hit
  as a list of `HitPacket`s (type, damage, added): its own element first
  (the first `grammar.json` `damage_types` entry among its tags), then one
  packet per element the plate adds. A packet resolves its damage against
  the skill's tags with the element swapped for its own, so cold gear
  scales the cold packet, fire gear the fire one, and a spell's modifiers
  both. `skillDamage` is the packets summed. The hit stream rolls a hit of
  packets with one variance draw and one place in the echo count, so a
  hit asked for as packets sits where a hit asked for as one number would.
- **The added-element lane.** An element ingot beside a skill of its own
  element supports it as before (+24% cold on Frost Orb). Beside any other
  skill its `added_modifier` speaks instead (`added_fire`, `added_cold`,
  `added_physical`, effect `add_as_<type>`), and the skill gains a packet
  of that type equal to the same fraction of its base hit (`Effect.kind ==
  "added"`, written on its cell like a support). +24% increased and +24%
  of the hit added are the same total; the added packet is its own type,
  scaled by that type's gear (the ingot's own base among it), refused by a
  mob immune to it, and is what a Catalyst will later turn into a status
  and a reaction. Backing counts an added reading once more as it counts a
  support. A Frost ingot beside Ember Bolt is a fire-and-cold bolt.
- **A reading keeps its type.** `grammar::ActiveMod` gains `requiresTags`
  (every one must be present, beside `appliesToTags` where any one may):
  a support, an added element and a backing keep their modifier's own
  `applies_to` and require the socket's `skill:<id>` tag, so a Frost
  support scales the orb's cold packet and never the fire an Ember support
  adds to the same orb.
- **The self ingots read a skill weakly.** Vigour, Plate and Ward name a
  `skill_modifier` and a `skill_value` of their own, spoken at
  `support_multiplier` like every reading: `life_on_kill` (a kill with the
  skill restores 1 life; `grammar::skillLifeOnKill`, the engine heals on
  the kill, shatter kills counting for the skill that cashed them),
  `armour_on_cast` (casting the skill grants 4 armour for
  `cast_armour_seconds`; `grammar::skillCastArmour`, the engine runs the
  clock and hands the armour to mitigation through `enemy_hit_damage`) and
  `status_ward` (an enemy carrying the status the skill applies deals 5%
  less to you; `grammar::wardMultiplier` over the statuses the mob carries,
  wards multiplying). The bases stay on the sheet. Haste read every attack
  and spell already; Reach read area, projectile and strike skills from
  slice 1.
- **Resistance by packet type.** `world.json` enemies and elite prefixes
  may name `damage_taken`, a multiplier per packet type (a prefix's
  multiplies onto the family's; 0 would be immunity, and nothing is
  immune); the engine deals a hit packet by packet (`Enemy.take_typed`)
  and a mob takes its share of each. The Hollow Knight, whose purpose
  already read "fire does nothing to a hollow suit", and the Cinder Wisp
  take a quarter of fire - the owner, on seeing full immunity: "heavy
  reduced damage taken by fire, not completely fire immune" - so a
  fire-and-cold bolt lands its cold on them whole and a little of its
  fire. Shatter novas and the burn and bleed ticks go the same way.
- **Tells and sentences.** The hitmarker takes the hit's types: white for
  a plain blow, the element's tint for one element, a doubled mark in the
  blended tint for a two-element hit. A modifier may carry its own
  `sentence` in `items.json` (`{n}` for the magnitude) for readings that
  are mechanics rather than stats ("adds 24% of the hit as fire damage",
  "a kill restores 1 life"); a tray ingot's tooltip says what it reads as
  beside a skill. The plate's readings carry the tags `added` and
  `reading`, which no base allows, so none rolls on gear.

Tests: sim 3294 (the damage types; the readings the ingots name; the pool
clean; the sentences; a bare skill one packet and a movement skill none;
the two lanes the same total; ember beside the orb adding fire at the
support fraction, scaled by fire gear and the ember's own base and never
by cold; a frost support scaling the cold packet and never the added
fire; backing an added reading; ember beside a fire skill scaling and
adding nothing; a strike carrying cold; the three weak readings and their
numbers, the ward by carried status, the sheet untouched; the fire shares
loading; the hit stream rolling packets in step with the number). Engine:
unit 342 (packets rolled as the number, a dash's empty hit, armour
granted by the engine counting in mitigation, the ward silent bare, the
knight's fire share, the Plate reading beside the orb through the door);
integration 217 (six effects with the ember adding fire to
the strike, the strike a physical-and-fire blow, a cast of the area strike
bracing the player for four armour and passing).

Not yet: the Dash tablet reads nothing (no reading speaks to a movement
skill; the Quicksilver is its subject), Ward beside a skill that applies
no status waits for one, a mastery perk still scopes to its whole skill
(every packet) rather than its modifier's type, the added packet has no
tell on the mob beyond the hitmarker, and everything after slice 2 in the
slice order: the typed currencies, the Vanguard, corner augments and the
reactions, links, rails, the metal of an ingot.

## Implemented: typed currency (4 Sep 2026, D-023 slice 3)

The owner: "Lets do it - i think there is definitely some real razorblade
tuning of drop rates etc, and whether they can also be crafted if enough
rare resources are found etc. Anyway dont overthink it, go ahead." The
coin is retired and four kinds take its place. `data/tuning/crafting.json`,
`world.json`, `trial.json`; `sim/economy.h`, `items.h`, `loot.h`:

- **The kinds.** `currency_kinds` names five ids in four families: the
  Ember and Preserving Catalysts (offence), the Vanguard (defence), the
  Marrow (life) and the Quicksilver (tempo), each with the `items.json`
  modifier tag it aims a craft at. The three cast kinds live in the purse
  (`currencies`); the catalysts stay pack materials because tempering
  consumes them there. `PlayerEconomy::grant`, `take` and `held` route an
  id to the purse or the pack and read both, and the trial banks its loot
  through `grant` too.
- **Families pay by their nature.** Every enemy names a `currency_kind`
  and carries one loot entry for it, one at a chance of its own (the fire
  families the Ember Catalyst at 6 to 8%, husks and knights the Vanguard
  at 12 and 20%, hounds and crawlers the Quicksilver, the living the
  Marrow); an elite pays one more of its family's kind on every kill
  (`loot::rollEnemyLoot`). The reinforced mine pays three Vanguards, the
  trial's loot room a spread of one each, and the forge upgrade costs two
  Vanguards with the fittings. Every rate is a first guess for the
  razor-blade pass.
- **The peddler changes kinds.** Survival goods are priced in a Marrow or
  a Quicksilver; `market.exchange` changes three of one kind for one of
  another among four (the Ember Catalyst stays the trial's), so a surplus
  is never dead and a Preserving Transfer is always three kinds away
  (`PlayerEconomy::exchange`).
- **A kind aims a craft.** `craft(recipe, forOrder, aimKind)`: a kind
  added to a gear recipe is spent, the roll's first modifier is drawn from
  the kind's family among what the base allows (`items::rollItem`'s
  `firstFamilyTag`), and a plain result is lifted to
  `craft_rolls.currency_weighting.aimed_minimum_rarity` (keen). A family
  the base cannot hold aims nothing and the kind is still spent; a recipe
  that makes no gear ignores the kind and spends nothing. The forge panel
  offers one aimed row per kind held under every gear recipe.
- **Rare metal casts a kind.** Three recipes: two steel make a Vanguard,
  silver and hide a Marrow, two silver a Quicksilver, on era three's metals
  so the route exists without outpacing the hunt. Catalysts are never cast.
- **The engine.** The HUD's purse line and the pack's tiles show the
  kinds; the peddler's stall lists the offers and one exchange row per
  kind held enough of, per other kind; the work panel names the family an
  aimed craft draws first.

Tests: sim 3367 (the kinds and their families; nothing paying or
pricing in the coin; a knight paying a Vanguard now and then and an elite
always one more; grant, take and held across purse and pack; the exchange
and its refusals; a Marrow-aimed armour always keen with a life modifier
first, a Quicksilver-aimed mace speed first, an unaimed craft unchanged, a
non-gear recipe keeping the kind; the three cast recipes; the trial's
spread; the purse in the save). Engine: unit 345 (the order in
Vanguards, a kind's loot to the purse, the exchange through the door);
integration 217 (the order, the save and death keeping the
purse, charcoal for a Marrow).

Not yet: currency on the plate (a kind lifts for the re-forge cost once it
can sit there, slices 4 and 5), a tell when a kind drops beyond the
material chip, and the tuning itself.

## Implemented: the Vanguard (4 Sep 2026, D-023 slice 4)

The owner: "okay go next slice". The first currency on the plate.
`data/tuning/foundry.json` (schema 4), `items.json`; `sim/foundry.h`,
`stats.h`, `economy.h`, `save.cpp`:

- **A kind is a placement.** `foundry::Placement` gains `currency`: a
  kind from the purse set on a forged cell. In a socket it is a
  **subject** (`subjects` in foundry.json: the Bulwark Vanguard, base +8
  armour, its trigger recorded for links); on any other forged cell it is
  an **augment**. `PlayerEconomy::foundryPlaceSubject` takes it from the
  purse; lifting pays `reforge_cost` and returns it; a kind the frame
  cannot hold goes back to the purse on load; the save carries it.
- **The Vanguard working.** Every ingot beside a Vanguard's socket reads as
  defence through its `vanguard_modifier` at `vanguard_value` times
  `support_multiplier` (the self ingots read their base doubled), backing
  counting once more, exactly as a skill working reads with the subject
  deciding: Ember +10 fire resistance, Frost +10 cold resistance, Edge
  Barbs (25 bleed buildup on the striker), Reach Answer Reach (the answers
  reach every enemy within 2.5 m), Vigour +24 life, Plate +16 armour, Ward
  +5 to every resistance, Haste 16% faster for `haste_after_hit_seconds`
  after a hit. No skill reading fires beside a Vanguard.
- **The corner.** A kind on a non-socket cell gives `corner_base_fraction`
  of its base (+4 armour) and lends its readings to every ingot it touches
  that supports a skill's socket, at `corner_lending_multiplier` (x1, the
  ingot's value, not doubled): the Frost support beside your orb is still
  +24% cold, and with a Vanguard in the corner it is also +5 cold
  resistance. This is how an offence working carries defence.
- **The sheet.** `DerivedStats` gains cold resistance (a second
  resistance, capped like fire, `mitigateDamage` honouring "cold"),
  `all_resistance` feeding both, and the answers as numbers: `barbs`,
  `answer_reach_m`, `haste_after_hit`. New self modifiers
  `cold_resistance`, `all_resistance`, `barbs`, `answer_reach`,
  `haste_after_hit`, tagged `reading` so none rolls on gear.
- **The engine.** After a hit lands, `PlayerCombat` answers it: Barbs
  bleed the striker and, with Answer Reach, every enemy within reach;
  Haste quickens walking for a moment. The panel gains a "Kinds to set"
  tray, draws a socketed kind in brackets and a corner kind in braces,
  names a Vanguard working's supports and corners, and writes lendings on
  their cells; the HUD shows cold resistance once something gives it.

Tests: sim 3409 (the subject and its readings; the readings never on
gear; cold resistance mitigating and capped, all resistance feeding both,
the answers on the sheet; a Vanguard from the purse in the socket with
frost, ember and edge beside it, no skill reading firing, the numbers on
the sheet, backing, lifting for iron back to the purse; a corner Vanguard's
half base and lending, the orb keeping its support, a touched support lent
and an untouched one not; the save and a stale kind back to the purse).
Engine: unit 348 (a Vanguard through the door, the view and stats);
integration 220 (Barbs through a real hit: the whelp that
strikes you bleeds).

Fixed on the way: the slice 2 readings (`life_on_kill`, `armour_on_cast`,
`status_ward`) carried a `defence` tag, which every armour base allows, so
they had been rolling on crafted and dropped armour; every reading now
carries only `reading`, and the test checks each base's actual pool.

Not yet: the second Vanguard (Warding, +5 to every resistance as a base),
the readings' second halves (ignite on you burning shorter, chill building
slower, regeneration after a hit, armour against fire at half, statuses
decaying faster) which need player-side statuses that do not exist, boss
resistance to Barbs, Marrow and Quicksilver as subjects (slice 8), the
Catalyst in a corner (slice 5), links on the trigger (slice 6).

## Implemented: the flow - kinds in the detached cells, the first forms (4 Sep 2026, D-023 slice 5)

The owner, on seeing the socketed Vanguard: "we just don't allow the
non-skills to be placed in the main subject of the foundry tablet ...
vanguards and catalysts can only go into the edge cases where they give
forward their base to the flow of the tablet, but also transform/mutate
along the way the ingots ... until it hits the skill. We can leave scaling
defenses to itemisation." This supersedes the socketed Vanguard of slice 4
the same day. `data/tuning/foundry.json` (schema 5), `items.json`;
`sim/foundry.h`, `grammar.h`:

- **Only a skill sits in a socket.** `foundry::depth` is a cell's distance
  to the nearest socket; `kindMayRest` is depth 2 or more on a forged row.
  `PlayerEconomy::foundryPlaceKind` refuses a socket and a support cell;
  `validate` lifts a stale kind touching a socket back to the purse.
- **The flow.** `flowsToSkill` walks a chain of placed pieces, each one
  step nearer a socket, from the kind to a support beside a laid tablet.
  Only then does the kind's family base count (`kinds` in foundry.json:
  the Vanguard +4 armour, the Catalyst none, Marrow and Quicksilver small
  placeholders) and only then does it work anything. A far kind flows
  through a corner kind.
- **Forms.** `forms` in foundry.json, keyed by family, ingot, lane and an
  optional skill tag, each with one or more effects (a modifier, a value,
  and for a reaction the packet it speaks to, "native" for the skill's
  own element). A kind works every support it touches; the ingot keeps
  its plain reading; the form's effects feed the skill the support serves,
  both skills for a shared support (`Effect.kind == "form"`). A form
  speaks to the whole skill whatever its modifier's applies_to says, so
  Scald's ignite lands on a cold orb.
- **Reactions.** The Catalyst's same lane sharpens (Deep Frost, Kindling,
  Serration, Split for projectiles; Quickening a placeholder for Echo);
  its added lane reacts: the added element also applies its status, and
  the skill deals 20% more of its own element to an enemy carrying it
  (Scald, Temper, Quench, Rime; Brittle and Sear as the "more against"
  half only). `grammar::skillHit` takes the struck mob's statuses and
  multiplies each packet by the resolved `damage_vs_<status>` (new
  modifiers `damage_vs_ignite`, `damage_vs_chill`, `damage_vs_bleed`);
  the engine passes what the enemy carries. Reap, Bracing and Aegis are
  the sharpened self readings.
- **The Vanguard's forms**, proposed from the owner's two examples: Frost
  Leech (4 life on a kill), Quickstep (16% faster after a hit), Barbs,
  Far Answer, Stand Fast (8 armour on cast), Cinder Guard and Cold Ward
  (+10 resistance while the flow holds), Second Wind. Marrow and
  Quicksilver rows wait for slice 8.
- **The panel** draws a kind in braces, dim until it flows, says what it
  flows to or that it flows to nothing yet, writes forms on the support
  cells they work, lists every kind held in "Kinds to set", and refuses a
  socket or a support cell in words.

Tests: sim 3418 (the families and forms; the pools clean; depth and
where a kind rests; refusals; a kind alone giving nothing, a support with
no tablet not a chain, the chain closing; Frost Leech named and felt, the
Frost keeping its support, the nova untouched; Quickstep through a shared
support feeding both skills; lifting; the Catalyst without a base that
still flows; Scald as two effects on the orb's cold, the ignite, 20% more
against the burning and nothing more against the chilled; Deep Frost on
the same lane; a Preserving Catalyst as the offence kind; the far cell
flowing through a corner kind and Serration for the strike; the save; a
stale kind beside a socket back to the purse). Engine: unit 349 (a
kind refusing the socket and support, flowing to nothing, then the chain
closing with Stand Fast); integration 220 (Barbs through a
real hit from a corner Vanguard).

Not yet: compound forms (a kind worked by another kind; metal and rarity
as conditions), the reactions' hook halves (Quench's burst, Rime's novas,
Brittle's shatter), Arc, Linger, Echo, links re-homed, Marrow and
Quicksilver forms.

## Implemented: kinds as variants; the reactions' hooks (4 Sep 2026, D-023 slice 6)

The owner: a Vanguard "is a list of various defensives - + armor, +
dodge, + resistances"; Marrow "+life, +leach, +recoup"; Quicksilver "+
move speed, + attack speed, + cast speed"; catalysts "dont have a base,
but they do cooler transformations", a fire catalyst an "augment fire".
`data/tuning/foundry.json` (schema 6), `crafting.json`, `items.json`;
`sim/grammar.h`:

- **Kinds are variants.** `kinds` is per currency id: its family, the
  name a cell shows, and its own base. The Bulwark Vanguard (+4 armour),
  the Warding Vanguard (+5 to every resistance; the first extra variant,
  from the peddler's exchange until a family pays it), the Marrow of life
  (+6), the Quicksilver of hands (+4% cooldown recovery). The forms are
  the family's; a form may name a `kind` to narrow to one variant, the
  slot for "augment fire". Waiting for their stats: the Vanguard of
  dodge, the Marrows of leech and recoup, the Quicksilvers of move, attack
  and cast speed.
- **The reactions' hooks**, each a sim number the engine reads
  (`grammar::skillEchoEvery`, `skillQuenches`, `skillNovaChill`,
  `skillSear`, `skillBrittle`; modifiers `echo_every`, `quench`,
  `nova_chill`, `sear`, `brittle`, `laceration`): Echo (Haste worked by a
  Catalyst: every fourth cast repeats, free of the cooldown; the engine
  counts casts), Quench (a burning enemy the skill freezes takes the rest
  of its burn at once, on the mob's freeze), Rime (the skill's shatter
  novas chill the mobs they reach), Sear (the burn the skill lights ticks
  50% faster while the mob walks and bleeds; snapshotted at ignition like
  the tick), Brittle (a frozen, bleeding enemy shatters from the spell's
  own hit, through the cascade with the hook's plain rules). Serration,
  Brittle and Sear now bleed (+20) through `laceration`.

Tests: sim 3447 (the variants, the Warding Vanguard's base and forms;
each hook from its form, scoped to its skill, silent on a bare plate);
engine unit 349; integration 220; grammar 52
(Sear's snapshot, Quench's burst on a real freeze, Rime's chilling nova,
Echo's fifth hit from four casts through the plate).

Not yet: Arc and Linger (new delivery shapes), compound forms, the
variants waiting on stats, links re-homed, Marrow and Quicksilver forms.

## Implemented: links, re-homed to the flow; Arc (4 Sep 2026, D-023 slice 7)

The owner: "Keep going for now ... Continue to be creative with
interactions." `data/tuning/foundry.json` (schema 7), `items.json`;
`sim/foundry.h`, `grammar.h`:

- **The link.** `foundry::links`: a kind of `links.family` (the
  Catalyst) resting in a corner that touches a support serving two
  sockets links the two skills laid there (`Effect.kind == "link"` on
  that support). `grammar::skillTriggers` names what a skill's payload can
  fire on an enemy: a freeze when it applies chill, an ignite, a bleed,
  its own or a modifier's. `grammar::linkedCasts(skill, trigger)` is
  every skill linked to it when the trigger is one of its own, so a bleed
  skill linked to a fire skill runs both ways. The Catalyst still works
  the shared support into its form.
- **The engine.** `PlayerCombat.apply_payload` reports the thresholds a
  hit crossed; `fire_links` casts every linked skill at that enemy (a
  projectile flies at it; a cone or strike casts as the player would),
  with its own cooldown, whether or not it sits on the bar, never firing
  another link in turn (a depth guard). The HUD says who cast itself and
  why; `linked_cast` is a signal for tests and later tells.
- **Arc.** Reach worked by a Catalyst beside a single-target skill: the
  strike sweeps every enemy within its reach and `arc` metres either side
  of the line (`grammar::skillArc`; `_enemies_in_front`). Beside a
  projectile the same corner is Split. The skill keeps its tags; reading
  area modifiers from then on is not done.

Tests: sim 3469 (who links; a Vanguard and a one-skill support link
nothing; the link as an effect beside the form; the triggers; casts on the
orb's freeze and not on a trigger it cannot fire; Rend and Ember Bolt both
ways; Arc on the strike and Split on the orb from the same corner); engine
unit 350; integration 220; grammar 56 (the orb
freezes a whelp through the plate and Shatter casts itself, spending its
own cooldown).

Not yet: the bar marking a linked skill, Linger, compound forms, rails,
Marrow and Quicksilver forms, the variants waiting on stats.

## Implemented: the Marrow's and the Quicksilver's forms (4 Sep 2026, D-023 slice 8)

Taken before rails, which need the class choice and the class hall of
D-004. `data/tuning/foundry.json` (schema 8), `items.json`;
`sim/stats.h`, `grammar.h`:

- **The Marrow's forms**, sustain twists feeding the skill: Cauterise
  (Ember: a hit restores 1 life), Cold Blood (Frost: an enemy carrying
  the skill's chill deals 15% less to you, the spec's reading),
  Bloodletting (Edge: a kill restores 3), Far Leech (Reach: hits 1 and
  kills 2), Hale (Vigour: +24 life), Scar Tissue (Plate: +12 life and 4
  armour on a cast), Warded Blood (Ward: +5 to every resistance and 10%
  less from an enemy carrying the status), Lifeline (Haste: life restored
  from any source is 15% more, the spec's reading).
- **The Quicksilver's forms**, tempo twists: Hot Hands (Ember: a kill
  quickens you 16% for a moment), Cold Snap (Frost: a kill refunds a
  quarter of the cooldown), Quick Cut (Edge: the hits bleed and a kill
  refunds 15%), Long Step (Reach: the Dash goes 1 m further), Second
  Breath (Vigour: a Dash restores 4 life), Braced Step (Plate: 8 armour
  for a moment after a Dash), Sure Step (Ward: 2 life and 4 armour on a
  Dash), Fleet (Haste: the Dash recovers 16% faster). The Dash sits on no
  socket, so its forms land on the sheet.
- **The hooks.** `grammar::skillLifeOnHit`, `skillRefundOnKill`,
  `skillHasteOnKill` per skill; `DerivedStats` gains `healMore`,
  `dashReachM`, `lifeOnDash`, `armourOnDash`, `dashRecovery`. The engine
  heals as a hit lands, pays a kill back in life, cooldown and speed,
  multiplies every heal (kills, hits, the Dash, the shelter) by the
  sheet's healing, and gives the Dash its extra reach, life and armour
  and a faster recovery.

Tests: sim 3511 (eight forms each; every modifier; Cold Blood and Hot
Hands worked on the orb; the Marrow's base; Cauterise and Cold Snap;
Lifeline and Long Step on the sheet; Hale and Braced Step, then swapped
corners Second Breath and Scar Tissue on top of the Plate's weak reading;
Warded Blood and Fleet; Bloodletting and Quick Cut; a bare plate silent);
engine unit 351; integration 220; grammar 56.

Not yet: the readings needing player statuses or ground hooks (a Dash
leaving burning ground, dashing through enemies chilling them, a Dash
cleansing a status, armour against burns and bleeds, the Marrow's
regeneration), the rest of the variants, rails, Linger, compound forms.

## Implemented: rails, the plate's exterior (4 Sep 2026, D-023 slice 9)

The owner's answer on class (4 Sep, later): no class at the start, "base
tablet setups for the base class coming from nothing"; the first class
hall test's completion offers a specialisation that "changes the exterior
of the rows/columns upgrades". `data/tuning/foundry.json` (schema 9,
`rails`), `items.json`; `sim/foundry.h`, `economy.h`, `stats.h`,
`grammar.h`, `save.cpp`:

- **The test and the choice.** The class hall is not built (D-004), so
  the Tyrant's forge stands in: recording its completion effect
  (`rails.specialise_on_world_effect`) offers the choice in the Foundry
  panel - Ranger (Volley, Quarry), Warden (Shield Wall, Riposte), Kindler
  (Pyre, Ashen Step) - once. The trial's completion line says so.
- **Rails.** One outside every row and column. `rails.by_era` allows
  none in era one, one in era two, two in era three; one rail per
  pattern; a row rail only on a forged row; set and cleared in the panel
  for free. A pattern's condition reads the line's placed cells
  (`all_placed_are`, `alternating`, `ends_are`, `minimum_placed`,
  `holds_skill_tag`, `holds_kind_family`); the panel's rail button is lit
  while it holds and says which cell breaks it when it does not. The rule
  speaks to the line's skills, to every skill with a tag, or to the sheet.
- **Manners.** The kills the engine already reports count per family;
  twelve hounds teach the Hound's Manner, eight husks the Husk's, to any
  specialisation, announced on the HUD.
- **The engine's half.** `grammar::skillProjectiles` fans a cast out ten
  degrees apart (Volley); `skillPierce` keeps a projectile flying through
  that many enemies, forking on its last stop (Quarry); `DerivedStats`
  gains `armourVsElements` (mitigation applies it after resistance),
  `barbsMore` and `barbsStagger` (the Barbs' answer doubled, the striker
  halted half a second with its wind-up lost), `proliferateOnHit` (an
  ignite a hit lights spreads at once at half the death-spread),
  `burningGroundHeal` (the ground heals instead of burning),
  `damageVsApproaching` (a hit on a mob whose velocity points at you) and
  `stillArmour` (a second of stillness, gone on the first step).
- **The save** carries the specialisation, the rails and the kills; a
  load drops a rail its patterns no longer cover or the era does not
  allow, and forgets an unknown specialisation.

Tests: sim 3578 (the tuning; from nothing; the offer after the test; a
Ranger once; Volley lit, broken by an Ember, waiting under the minimum
and without a projectile skill; era three's second rail; Quarry scoped by
tag; the twelfth hound; alternating; the save round trip and a doctored
save; the Warden's Shield Wall waiting for its Vanguard and its
mitigation, Riposte and the ends moving with the era; the Kindler's Pyre
and Ashen Step, the eighth husk); engine unit 356; integration 220;
grammar 62 (a bolt through two whelps, three orbs from one cast).

Not yet: the class hall as a place, later halls' exterior options, a
manner per family, the readings needing player statuses, Linger, compound
forms.
