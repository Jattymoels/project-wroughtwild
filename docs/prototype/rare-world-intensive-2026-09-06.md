# The Strange Frontier: rare finds and the first useful contraptions

**Status:** Approved for implementation, 6 September 2026. Owner: “Love it -
let's go”. D-029 accepts the five rare-resource loops, three larger regional
identities and bounded connected contraption below. World size and population
counts are initial tuning targets. Later production stages remain a roadmap,
not additional implementation scope. Review evidence is recorded as slices land.

[Implementation, verification and current limits](../art/strange-frontier-2026-09-06.md).

## The experience

You see pale branching glass along a distant ridge. Following its fragments
leads to an old lightning scar. The intact tube rings when worked. Back home,
you mount it beside a lever and watch a pulse travel to a receiver. Suddenly
the glass is more than something to collect: you can imagine a gate, a warning
chime, and eventually a workshop that responds to what you put into it.

Three kinds of excitement should coexist:

- **A place:** “I want to see what is over there, and build somewhere like this.”
- **A find:** “I recognise that clue; there might be something valuable here.”
- **A possibility:** “Now that I have this, I can make something behave differently.”

The rare resource should have a physical identity and a useful first creation.
Its value does not depend on becoming another equipment rank, currency or
ingredient required in every recipe.

## A larger world with composed regions

Before this intensive the world was 320 x 320 metres, with 48 vertical block levels and 400
terrain chunks. There are five underlying biomes. The recent quarry, fen and
grove additions are three guaranteed gathering sites with 12-13 metre radii;
they are not large new biomes. Terrain, collision and resource scenes are
were created up front at that baseline.

**Target: 512 x 512 metres**, keeping the metre construction grid and initial
vertical block budget. This is 2.56 times the ground area and 1,024 chunks, not
a proven performance result. First establish one excellent region on a smaller
review map, then expand with staged creation and distance activation where
measurements require it. Do not multiply every resource and enemy count by 2.56.

Keep starter supplies, the existing material habitats and the Forge approach
near their current travel distances. Put the additional journey in optional
outer country. A straight 512 metre crossing at the current 5 m/s speed takes
about 102 seconds: terrain dimensions alone do not establish expedition length.
Discovery, winding routes, vistas, cave detours and encounters make the journey.

Compose three substantial discovery regions within the existing ecological
palette. Each needs a contiguous core, a transition, a clear ordinary approach,
an optional detour, a memorable skyline and somewhere appealing to build.

| Region | What makes it worth entering | Discoveries |
| --- | --- | --- |
| **Rootvault Wildwood** | Old trees rise over root arches, slanted trunks and shaded chambers. Fern clearings and shafts of daylight break up the canopy. A few authored cave mouths connect the surface composition to the underground. | Thrumroot coils in braced deadfall; Lanternhearts in damp sheltered pockets. |
| **Lantern Fen** | Broad shallow pools, raised reed islands, hollow trunks and papery hanging growths. Warm pinpoints appear under cover without turning the whole swamp into neon. Dry banks offer workshop sites and readable walking routes. | Lanternhearts; Ventlung colonies at isolated breathing mineral vents. |
| **Glasswind Uplands** | Pale eroded shelves, leaning stone ribs, old lightning scars and open grass corridors. Dark iron grit clings to overhangs. Wind and dry chimes give this place an identity beyond its colour. | Stormglass, Pullstone and occasional vent pockets. |

These are biome-sized variations, not colour swaps or extra small circles of
props. Use broad spatial masks to compose regions first, then local terrain,
resources and dressing. Do not obtain an exotic region guarantee by dropping
its rare node into ordinary meadow. Reserve a suitable footprint and repair its
approach, or deterministically retry that region's layout before accepting it.

Keep meadow daylight and existing danger colours. Improve depth through distant
landforms, the middle layer of trunks/arches/reeds, and close working detail.
Ordinary resources belong in beds, fallen clusters and outcrops. Leave clearings
and bare space between them. Decorative silhouettes, sounds and motion should
remain distinct from enemy tells.

Use the existing local Blender authoring/export pipeline and shared art lookup.
Start with a small reusable kit per region, with a few exceptional compositions.
Water remains shallow dressing; vents are authored local phenomena. This does
not need a weather simulator, flowing-water system or new enemy roster.

## Five rare resources with different physical jobs

Names are working names. These are raw specimens/components, not five additional
wall-material families. Retain the eight existing architectural families and use
them for the housings, frames and workshops that display the new finds.

| Find | Learnable clue and gathering interaction | Useful first creation | Later automation role |
| --- | --- | --- | --- |
| **Lanternheart** | Papery empty husks and muted light inside hollow trunks lead to an intact luminous heart. Contextual work folds the layers back and lifts it. It is visible in shaded daylight; there is no nighttime waiting requirement. | A mounted cave or household lamp, with a warm, softly moving interior. A first find supplies a small useful set of lights. Portable equipment lighting can follow if it fits the existing equipment interface. | A readable machine-status light. It is not an industrial power source. |
| **Thrumroot** | Bowed branches and taut, creaking roots reveal a coiled knot inside a fallen trunk. Brace and release it with contextual work; no reflex test. | A hand-wound cargo winch between two fixed endpoints, useful at a cave mouth or ledge. The mechanism visibly stores and releases tension. No new carrying penalty is added to justify it. | Return springs, clutches and bounded stores of mechanical energy. A crank or future drive supplies that energy. |
| **Stormglass** | Pale ribbed tubes follow old lightning scars; loose splinters make a dry ringing sound. Expose and separate an intact tube. Deposits exist from generation, so finding one never requires waiting for a storm. | A strike-chime/lever and linked receiver: operate it and see a pulse travel to a lamp, chime or latch. A first haul includes enough for a complete small experiment. | Triggers, pulse transmission and simple timing. A signal requests work; it does not power machinery. Its milky surface differs from smoky architectural Cinderglass. |
| **Pullstone** | Iron grit clings sideways to nodules beneath an overhang. Contextual bracing and ordinary wedges separate one; compatible impact saves work. | A hand-fed magnetic chute that separates ferrous ingredients from a mixed batch into two small trays. The attraction is visible. | Sorting by a material property. Begin with an explicit ferrous set; it cannot sort every item magically or pull from unopened containers, death bundles, intact nodes or enemies. |
| **Ventlung** | Empty mineralised cases surround a flexing bladder above a local vent. Open a side seam, release pressure and lift the finite intact membrane. Harvesting never depends on a resistance or damage type. | Hand-primed bellows that supply the existing impact response to a wedge or seam. The pulse and the worked resource show the benefit directly. | Pressure storage and actuators. A later vent installation supplies energy; the rare membrane stores/delivers it. It does not create fuel or power from nothing. |

Preserve D-021: ordinary contextual interaction is sufficient. Skill properties
may shorten stages or improve ordinary yield, but no class is required. Harvest
stages teach what the material does rather than becoming five unrelated minigames.
The guaranteed intact specimen cannot be destroyed by using the wrong spell.

The first reward should have enough intact material for a complete useful recipe,
with a small allowance for experimentation. Do not scatter one recipe across
many tiny random drops. Show a short use preview before spending the specimen.
Recipes can be inspected before possession; observation is information, not a
new recipe-unlock token. Assembly uses existing stations and familiar common
inputs, with at most one intermediate component stage.

## How rare finds populate the world

Rarity belongs to the place and the specimen, not a tiny jackpot probability
on every ordinary rock or tree.

1. Generate region footprints and walkable connections.
2. Place ordinary material fields and existing progression guarantees.
3. Select a bounded set of suitable rare sites using separate deterministic seeds.
4. Validate the whole composition: clue trail, reachable work area, intact specimen,
   aftermath and a route out. Reserve space against other sites and structures.
5. Add optional exceptional compositions and ordinary regional population.

Recommended initial tuning, all subject to experience in play:

| Setting | Initial tuning target | Purpose |
| --- | --- | --- |
| Region core width | Roughly 80-140 m, adjusted for geography | Gives each place enough continuous identity to explore rather than cross in a few steps. |
| Primary rare sites | 2-4 per resource in the bounded world | Keeps intact finds scarce while allowing another expedition or recovery from a poor first choice. |
| Capability guarantee | At least one reachable intact opportunity per resource | Prevents a seed from silently excluding a supported contraption. Guarantees presence, not safety or a minimap marker. |
| Clue approach | Roughly 15-35 m around a site | Lets the player learn to hunt from fragments, sound and growth patterns. Provide a visual equivalent for audio clues. |
| First complete haul | One useful creation plus a small experiment | Makes the discovery pay off promptly instead of starting an ingredient grind. |
| Exceptional sites | 0-2 additional sites per world | Provides lucky discoveries without withholding the basic capability. |

Exceptional finds should be an unusually grand composition, a richer intact
cluster or a visibly unusual specimen suitable for display. Begin with
appearance/haul variation, not random machine-efficiency grades that make an
ordinary first find feel obsolete. Basic machinery must not require one.

Resources are visible from the start, including ones the player does not yet
understand or feel safe pursuing. Do not change existing era-gated ore behaviour
incidentally. A rare-resource sighting should reveal its observed property and
possible uses in the existing guide/work-panel language. Exact locations are
learned by visiting; automatic cross-world quest markers would spoil the hunt.

Vary population by place: peaceful clue approaches, ordinary guards on some
detours, richer sites beyond readable danger, and spacious recovery routes.
Reuse existing enemy families and preserve the quiet heartland. Every find
should not terminate in an identical elite fight. Higher danger can yield a
richer haul without being required for the first intact specimen.

Once harvested, sites stay depleted and leave a recognisable shell, relaxed root,
empty scar or vent casing. No reload rerolls or automatic rare-node respawns.
Rare machine components are reusable capital: dismantling returns the intact
core, while ordinary frame materials follow their existing refund rules.
Machines spend common supplies, not a fresh rare core every few minutes.

Forge replenishment provides one component on repeatable boss completion,
previewed alongside the existing material target. Slate/shellstone return
Pullstone; clay returns Ventlung; reed returns Lanternheart; resinheart/cork
return Thrumroot; slag/glass shards return Stormglass. Ordinary target rolls
and saved offer seeds stay unchanged. Death and early extraction give no boss
component. No currency, Kind family or equipment-quality rule is added.

## Automation grows out of discoveries

The approved scope includes the standalone objects above and **one small
connected demonstration** in this intensive. This is a bounded
extension of the current exclusion on production networks. Broad automation is
future work; the first machines should be entertaining and useful on their own.

**The first connected experiment:** wind the Thrumroot drum, load a basket of
supplies, then trigger the fixed-endpoint winch through a Stormglass lever. The
signal passes visibly; the basket moves; a receiver shows completion. It stops
when energy is empty, the endpoint is blocked or the basket arrives. An ordinary
local crank remains usable without Stormglass. Lanternheart can mark the landing,
but the device does not demand all five rare resources.

Limit the winch to cargo, two supported endpoints, one unobstructed fixed span
and a discrete container transfer. No riding, free rope physics, moving bases,
global cable network or new inventory-weight system. Removing an endpoint or
saving mid-trip must recover/preserve one authoritative cargo inventory. The
winch cannot move items out of trial deposits or suspended runs.

Then grow the production vocabulary in this order:

| Stage | What the player gains | What still matters |
| --- | --- | --- |
| **This intensive: light, handling and response** | Lamps, hand-assisted work, the small sorter and the triggered winch. | Exploration brings home reusable capabilities. Most building materials remain familiar. |
| **Next: one useful workshop line** | One input container -> one existing common-material process -> one output container. Thrumroot stores drive; Stormglass requests a cycle; Pullstone can divert ferrous inputs. | Manual crafting remains available with its existing outcomes. Machinery removes repeated handling; it does not justify slowing manual recipes. |
| **Later: harness a place** | A wind drive or vent installation powers that workshop. Choose one source and finish it before adding another. | Outpost position matters. Source capacity bounds throughput. Components transmit/store energy rather than generate it. |
| **Later: link a small settlement** | Short item routes, buffer limits and visible stop/start conditions connect two useful processes. | Common resources and existing recipe costs remain real inputs. Full output, missing input and insufficient power stop cleanly. |
| **Eventually: reliable common supply** | Deliberate tree cultivation, ordinary crops or finite-deposit extraction support a larger home. | Renewable common production is a separate explicit design change. Rare wild cores, unusual sites, combat rewards and new knowledge remain expedition goals. |

Do not build future simulation machinery now. Record the minimal contracts:
signals and energy are separate; items have one owner during transfer; processing
uses the existing recipe transaction; core properties are tags; unloaded/offline
machines do not produce catch-up output in the first version. Existing Kind,
item-quality and personal mastery rules remain authoritative. Automatic work
does not grant personal mastery in the recommended first production slice; that
is a proposed answer to the crafting spec's open automation-XP question.

## Implementation order and compatibility

1. **Preserve the worlds that already exist.** Freeze the current `frontier_v2`
   generator, habitat placement behaviour and all placement inputs. It currently
   reads live `worldgen.json`; changing that data in place would alter these saves.
   Add a new profile such as `frontier_v3`. Keep `legacy_v1` unchanged as well.
2. **Finish one discovery.** Author a Lantern Fen pocket, its clue approach,
   Lanternheart gathering and the lamp payoff. Review it at player height in
   daylight and dusk in normal gameplay, including a furnished home.
3. **Make the world worth walking.** Compose the larger region layout and the
   Rootvault/Glasswind identities. Add staged scene creation/distance activation
   as needed, then establish the three full regional journeys and cave entrances.
4. **Finish the other finds.** Complete each clue -> interaction -> finite haul ->
   useful object loop. Add the simple connected winch experiment after the
   standalone drum and pulse receiver work.
5. **Populate and review.** Tune primary and exceptional site budgets, aftermath,
   ordinary supply and local danger. Capture full approaches and practical uses.
   Finish the small Forge replenishment route only after the world hauls work.

The new geography is for new worlds. Loading an older world retains its profile,
terrain, resources, depletion, excavation and buildings; it does not resize or
retrofit the map. Keep recipes/objects available where compatible, but do not
silently insert new deposits into existing saves. Any later migration is separate.

Repeated habitats need a stable site-instance ID in addition to profile, seed,
habitat type and resource ID. IDs must not depend on scene load order or mutable
array positions. Save generated/depleted/partially harvested state separately
from whether a nearby scene is loaded. Current restore logic removes resource
nodes absent from its saved list, so streaming cannot treat an unloaded node as
a depleted one. Profile identity belongs in every terrain/generation cache.

The sim owns quantities, property responses, resource/contraption state and
atomic transfers; Godot owns geometry, interaction timing, animation and nearby
scene activation. New saves use the existing validated atomic save path, including
cargo, stored energy and partial harvesting. No offline timers or new service.

Affected systems: generation and saves; resource interactions; material tags;
construction fixtures and storage; recipe previews; region art/audio; a small
trial reward table extension. Preserve D-017's lattice and D-019/D-021's property
grammar, D-026's equipment economy and D-027/D-028's existing content contracts.
The reported timber-demolition conflict remains outside this work.

## What demonstrates success

- Every accepted seed has the three recognisable regions and reachable complete
  opportunities for the five basic finds. Exact sites, detours and exceptional
  compositions vary. No required resource appears under a building or in sealed
  unreachable geometry.
- A first haul makes the promised object immediately through existing stations.
  Common materials pay most expansion costs; dismantling does not destroy a
  scarce core. Every class can gather each specimen with ordinary interaction.
- Old-world fingerprints and player modifications survive unchanged. New-world
  depletion, partial work, scene unloading, cargo transfers and save/load cannot
  reroll sites, duplicate cores or lose contents.
- Gameplay captures show broad vistas, continuous first-person approaches, close
  clue recognition, harvest aftermath and the objects inside actual buildings.
  A recording shows the small contraption responding to player action.
- Measure startup, memory and median/p95 frame times on matched views plus the
  dense new regions. Investigate regressions over 10%; the 512 m target remains
  provisional until measurements support it. Separate cold startup from travel
  activation hitches and do not claim performance from screenshot quality.
- Automated routes can establish reachability and operation while the owner is
  away. Discovery excitement, winch usefulness and enjoyable travel still need
  a later normal play session; those are not certified by scripted captures.

## Source context

- [Current world generation](../systems/world-generation.md)
- [Current material intensive](world-intensive-2026-09-06.md)
- [Crafting and the long-term production arc](../systems/crafting-and-skills.md)
- [Loot and resource economy](../systems/loot-and-currency.md)
- [Weathered frontier art](../art/art-direction.md)
- [Generation review and measured baseline](../art/world-habitat-intensive-2026-09-06.md)
- [Accepted decisions and separate proposals](../decisions/registry.md)
