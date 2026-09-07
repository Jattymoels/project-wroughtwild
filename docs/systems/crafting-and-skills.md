# Crafting and Skills

**INT-04A action feedback, 7 September 2026:** successful manual crafting now
confirms once at the actual active station, with a short local sound and small
temporary work flecks. Field recipes confirm at the player. Recipe quantities,
equipment grade, Kind potency, fuel, XP and native RNG remain unchanged. A batch
does not create repeated per-item effects. Browsing, failed transactions, save
restoration and remote knowledge do not animate a station. These are cosmetic
events, not additional crafting timers or automatic production. See the
[interaction-feedback work item](../prototype/interaction-feedback-2026-09-07.md).

**Implemented INT-01 clarity update, 7 September 2026:** current-station
membership, craftable-first ordering and exact native craft validation remain
unchanged. Ingredient references and the optional pack guide explain the early
home/workshop chain using native recipe producers, consumers and previews, plus
bounded source/work prose for twelve early entries. Fieldstone, split stone and
dressed stone stay distinct; a recipe naming ordinary wood does not accept other
timber species. Contextual resource work remains available to every class with
its existing consumables and work responses; compatible skills provide the
existing shortcuts. Harvesting frees drops before collection, and stored stock
must be carried before crafting.

A session-only Make pin tracks the selected recipe, batch, grade and Kind/potency,
including fuel left after reserving ingredients. Ingredient Back restores the
parent operation and its choices. Recipe links expose requirements without
bypassing the physical station. Concise primary information keeps the selected
effect, costs and consequences visible; exhaustive explanations remain available
through Details. **Guides → Getting established** offers home, stone and forge
ambitions without prescribing a compulsory order. No recipe, cost, yield, skill
or era gate, work timing, save field or automatic objective is added. See
[INT-01](../prototype/first-hour-clarity-plan-2026-09-07.md) and the current
[interface contract](interface.md); earlier crafting history below is retained.

**Pressure workshop, D-031 (6 September 2026):** one workbench recipe,
`assemble_pressure_feeder`, consumes 1 Ventlung, 1 Thrumroot, 8 wood, 2 iron
ingots and 2 raw reed to make a kit, with no skill/fuel/XP gate. It feeds only
the existing `refine_rustclay_brick` recipe: 8 clay plus 1 ordinary fuel heat
become 4 bricks. The bridge copies the existing recipe and fuel table; native
selection removes recipe inputs first, then uses ascending heat value and item
ID, matching manual crafting. Pressure supplies motion, not heat or quality.

One local start requests four 8-second firings, spending one stored stroke each.
The player explicitly loads the 64-item hopper and collects the 32-brick tray.
The pocket holds 24 nonrenewable strokes; a four-stroke store includes reserved
drive. Hand winding works without a source, including in old profiles. No
equipment crafting, auto mastery, remote inventory search or offline production.
Missing supplies/full output stop before the next reservation. Cancellation
recovers exact inputs, selected fuel and drive once; saved escrow also reserves
its hopper return space and output tray space. [Contract and purposes](../prototype/leyline-extraction-proposal-2026-09-06.md).

**The Strange Frontier, D-029 (6 September 2026):** five finite wild components
assemble into useful fixtures at the existing workbench. Recipes are visible
before discovery and need no skill, fuel, currency or era gate. Each makes one
kit and grants no mastery XP. The ordinary landing needs no rare component.

| Recipe output | Inputs |
| --- | --- |
| Lanternheart Lamp | 1 Lanternheart, 2 wood, 2 raw reed |
| Cargo Winch | 1 Thrumroot, 8 wood, 2 iron ingots |
| Winch Landing | 6 wood, 1 iron ingot |
| Stormglass Lever | 1 Stormglass, 3 wood, 1 iron ingot |
| Magnetic Sorter | 1 Pullstone, 4 wood, 1 iron ingot |
| Ventlung Bellows | 1 Ventlung, 3 wood, 2 raw reed |

These six devices establish light, handling, signals and stored energy. D-031
above adds one finite source and one workshop recipe, with zero automatic
mastery. Renewable common production and broader automation remain future
decisions in the [roadmap](../prototype/rare-world-intensive-2026-09-06.md).
Manual crafting costs, item quality, Kind and personal mastery remain unchanged.

Owner-approved update, 6 September 2026 (D-026): New equipment crafts use selected workpiece quality and Kind potency. Starter bench gear, expedition-backed refining, atomic material batches and slower meaningful-use mastery are now installed. Earlier universal Keen targeting and use-count mastery descriptions are historical. See the [forge implementation record](../prototype/forge-clarity-and-early-pacing-2026-09-06.md#implemented-outcome--6-september-2026) for tuning, sources and save compatibility.

**Status:** Accepted direction; economy provisional  
**Related decisions:** D-002, D-007

## Purpose and player fantasy

Owner-approved world material expansion, 6 September 2026: eight finished building
families use one existing station refinement step and no new discovery or recipe
gate. `refine_slate`, `refine_shellstone` and `refine_vitrified_basalt` dress source
stone/slag at the mason's yard; `refine_woven_reed`, `refine_resinheart` and
`refine_corkbark` use the workbench; `refine_rustclay_brick` and
`refine_cinderglass` fire source clay/shards at the basic forge. Each batch yields
four finished units. Reed and logs cost four source units; the other six cost
eight. Fired batches use one heat; other batches use no fuel. This decorative
work does not supply fast blacksmith mastery. Trials return these same raw source
ingredients for normal refinement, with no separate material currency. See the
[world work item](../prototype/world-intensive-2026-09-06.md).

The player becomes capable through useful practice, material knowledge and increasingly sophisticated infrastructure. Repetition is not automatically a problem: it becomes satisfying when the output supports trade, construction, transport or a larger project.

## Four gates

1. **Knowledge:** material discovery, blueprint, specialist teaching or recovered technology.
2. **Skill:** minimum personal or specialist competence.
3. **Facility:** station, tools, processing chain and eventual power requirement.
4. **Resources:** sufficient physical inputs and catalysts.

Passing one gate does not automatically bypass the others. Lucky loot may create a shortcut, but infrastructure remains the dependable progression route.

## Prototype scope

- Blacksmithing levels 1–5;
- iron gathering and smelting;
- a basic forge and one upgrade;
- simple fittings, mine reinforcement components and one armour base;
- one order that consumes useful bulk output;
- one catalyst-assisted tempering operation;
- no unattended production network.

## Productive progression rules

- Craft XP is based on useful transformation, recipe complexity and relevant demand.
- Repeating trivial recipes receives diminishing XP.
- A bulk order can preserve normal XP because the destination genuinely consumes the output.
- Orders must have a world rationale: mine expansion, settlement supply, machinery, transport or defence.
- Practice outputs should be salvageable when they are not consumed elsewhere.
- Advanced projects should require larger quantities of standardised components, creating legitimate reasons to master production.

## Long-term production arc

> Manual processing → mechanical assistance → basic power → linked processing → automation → industrial abundance.

Automation should make the player appreciate earlier scarcity, but common-resource abundance must not eliminate the need for exploration. Rare catalysts and new knowledge continue to come from world and trial activity.

## System relationships

| System | Crafting receives | Crafting supplies |
| --- | --- | --- |
| World | Raw materials, specialists and technology | Tools, infrastructure and resource demand |
| Trials | Catalysts, equipment and unusual knowledge | Prepared gear and consumables |
| Construction | Bulk demand and facility space | Shapes, fittings and stations |
| Trade | Orders, blueprints and currency | Finished goods and fulfilled demand |
| Character build | Desired properties and defensive requirements | Controlled baseline equipment and optimisation |

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| XP curve | Time required to reach craft gates |
| Recipe XP | Which work is attractive |
| Repetition decay | Resistance to cheap-item spam |
| Order quantity | Length and material demand of useful grind |
| Smelting yield | Value of raw gathering |
| Processing duration | Hands-on pace and perceived machinery benefit |
| Salvage return | Cost of experimentation and failed items |
| Station upgrade cost | Strength of infrastructure gate |
| Craft property control | Determinism versus loot excitement |

## Failure cases

- Four gates can feel like redundant locks rather than complementary progression.
- Generated orders can feel artificial if they have no visible destination.
- XP optimisation may replace creative or useful production.
- Automation may grant mastery without player learning.
- Deterministic crafting may make dropped equipment irrelevant.
- Excessive currencies may turn physical crafting into menu bookkeeping.

## Prototype acceptance

- The mine order consumes an output the player understands.
- Blacksmithing progression changes what the player can make.
- The forge upgrade gives controlled access to baseline fire resistance.
- A catalyst produces a more exciting result without replacing material and skill gates.

## Open questions

- Whether automation grants personal craft XP, engineering XP or neither.
- Whether craft skills belong to the player, recruited specialists or both.
- Exact anti-spam rule for repeated recipes.
- How trade demand is generated without feeling infinite and artificial.


## The mason's yard (3 Sep 2026, D-021)

Presentation correction, 5 Sep 2026: the roof-workshop study's workbench,
stone-topped mason's yard and open-hearth forge now render through the normal
`StationSite` used by crafted kits and restored stations. Improved forges add
a taller hood and iron bands. `game/art/station_look.tres` controls timber,
leg, stone, iron and ember colours; `hearth_energy` (1.2) and `hearth_range`
(3.5 m) control decorative forge illumination, not fuel storage or heat rules.
Existing costs, recipes, upgrades, one-cell collision and saves are unchanged.
The surrounding furnished workshop and experimental roof pieces remain a lab.
The correction passed the full engine headless suite and 4,628 native checks;
the station review checks normal kit consumption, all three models after save
restoration, and the distinct improved forge (12 headless / 13 rendered checks,
including screenshot export). Reproduce with the review helper's `-Stations`.

A third kit station beside the bench and the forge: `mason_yard_kit`
(timber and fieldstone at the bench) founds the **Mason's Yard**, whose
recipe `dress_stone` turns two split stones into one block of the stone
family. Timber wedges (`timber_wedge`, one timber makes two) are hand-made
and spent per split at a seam. Masonry is dearer and slower than timber on
purpose; the forge kit's eight stone is the first masonry ambition.

**The bench kept alive (4 Sep 2026, Wave 5 item 11):** the bench bundles
eight wedges from three timber (`timber_wedges_bulk`), and joints the
**timber frame** (`timber_frame`, ten timber) that the forge's and the
yard's kits are now built on (`forge_kit`: a frame, eight stone, four
iron ore; `mason_yard_kit`: a frame, six fieldstone), so the bench stays
in the chain for every station the valley founds. The owner (4 Sep) is
unsure wedges should be a big thing to craft and would like the bench to
make world and nature pieces - decorations, farming aids; the roadmap
carries that as the next bench slice.

## Implemented: the world a beat ahead (4 Sep 2026, Wave 7 slice 2)

The owner: "it's so easy to get to a level 2 forge with crafting items
good enough to feel this power." The rule now: every spike is fetched
from the next denser place. The improved forge's upgrade wants three
**bog iron** on top of the Vanguards and the fittings, and only the fen
drops it (`world.json`: the lurkers most kills, the wisps sometimes) - so
the quench, the catalyst temper and the iron chest armour all sit behind
a walk into the fen, which is dense from day one and patrols at night.
Catalysts come mostly off the crowned: every elite modifier carries a
`bounty` rolled once per crowned kill (an Ember Catalyst six times in
ten, a Preserving Catalyst four); the families keep their own rare
catalyst drops because the typed currency needs a family's kind to fall
from the family. The peddler and the orders are unchanged.
