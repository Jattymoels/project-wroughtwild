# LAND-00 — A world shaped by what happened to it

**Creative discovery and planning, 16 September 2026. Status: recommendations for owner/coordinator assessment, not accepted design or implementation.**

This session turns the owner's lore-first correction into a proposed world vision, compares three genuinely different approaches, and supplies a researched roadmap and a concrete replacement brief for LAND-01. No game behavior or accepted decision changes here.

## Recommendation for the owner

**Build a reclaimed world in which the player learns the same forces that shaped the landscape, then uses them to make a home and a working frontier.** The production unit should be a complete place: its history, large forms, habitats, inhabitants, approaches and useful discovery.

Begin with **Scarwater Basin**: a glancing old impact has displaced a long ridge, interrupted a valley and left a lake. Established growth occupies sheltered ground; exposed fractures carry the force that transformed it. A pre-cataclysm smithy happens to lie across the damage. From a wooded approach, the player sees the broken ridge, understands two ways toward the smithy, and notices a dry shelf where a veranda and workshop would belong. At the source, they can eventually build the existing finite pressure workshop. The place joins awe, discovery and making in one visible loop.

Choose Direction A below, **The Inherited Landscape**, as the foundation. Borrow a limited vocabulary of observable host responses from C, and the existing local workshop interactions from B. Do not import B's regional controls or C's live ecosystem. First deliver one outstanding ordinary seeded place; then a contrasting dry biome and usable four-influence connections. This prioritises finished environmental experiences over separate terrain, asset and scatter deliveries.

The key decisions are: choose this place-first direction; favour two convincing new biomes before four shallow ones; and select whether the later new-world successor should gain the existing LF extraction/device vocabulary without importing its campaign. My recommendation is yes to all three, with source acquisition scheduled after the first White workshop place. None is marked accepted.

## What the latest correction means

The owner says current work feels like a bare sandpit with sporadic assets rather than a true game world. The required change is causal and spatial:

> Pre-cataclysm place → impact and influence → changed host → years of survival/recovery → present opportunity → deliberate player reuse.

For example, White does not merely make a cliff white. Impulse passes through layered stone, exaggerates displacement and opens a wound; surviving roots brace exposed edges; a pressure-bearing remnant intersects an old workshop; the player contains that motion to do useful work. The exact landscape expression is a proposal, grounded in the accepted force and accidental-workshop lore.

Every important place needs an answer to four player questions: **What happened here? What is happening now? Why go there? What could I make here?** Lore should answer through shape, action and practical connections before a text panel explains it.

“Game world” here means memorable silhouettes, consistent material scale, connected ground and vegetation, activity with a location and purpose, legible choices, and a payoff when a landmark is reached. It does not require photorealism. It retains the accepted self-directed sandbox, first-person ARPG combat and construction; it does not replace D-011 with a linear campaign.

## Grounding: accepted facts, observed gaps, proposals

Read current owner-depot AGENTS, README, master design, decision registry and prototype scope/acceptance before the relevant premise, references, coordination and world-generation material. The newer LAND-00 brief takes precedence over LAND-01's provisional starting region and outline.

**Accepted foundations.** An alien world had modest biome/civilisation differences and ordinary animal ancestors before meteor-borne augmentation exaggerated existing properties. It is now years after the impacts. The sender, purpose, exact elapsed years and civilisation identities remain mysteries. Old smithies predate the catastrophe and were struck accidentally; the player's apparatus is deliberate. Later Conservator laboratories are a different history. Do not turn the planet into a designed ancient machine or assume the meteorites intended ecological repair. Sources: [world premise](../world-premise.md), [D-013/D-030/D-031/D-032](../decisions/registry.md), [owner reference wording](../art/references/environment/2026-09-14-reclaimed-frontier/owner-intent.md).

**What the retained pictures establish.** I inspected RF-09's [highland](rf09-evidence-2026-09-16/01-highland.png), [bank](rf09-evidence-2026-09-16/02-shaded-bank.png) and [impact](rf09-evidence-2026-09-16/03-impact-growth.png), plus owner ENV-003, ENV-005 and ENV-007 originals. The highland has readable mineral patches but repetitive tree crowns and broad simple faces; the bank has a continuous water focal area but repetitive far vegetation and very dark near growth; the fragment and fine scar are difficult to read in the impact view. These are retained staged game views, not a new playthrough or all-seed diagnosis. The gallery's recorded Valheim qualities inform this report; its ENV-008 original failed the viewing tool's decode, so I do not claim a fresh visual inspection of it.

**Interpretation.** The dominant gap spans landform composition, silhouette art and the middle distance joining features. Local ground and shadow readability compound it. Adding vegetation density or exposure alone cannot establish the missing relationship between destinations. Current generation already contains impact, ruin, route and home composition; calling the implementation entirely random would be inaccurate. The proposal strengthens and unifies that structure.

| Implemented boundary | Consequence for this plan |
| --- | --- |
| Normal fresh play selects V8; LF flags select separate geography and, for later waves, a separate campaign policy. | Four-colour LF sources, teaching hosts, laboratories and its two physical era events are not ordinary V8 features. |
| V8 is finite 1,024 × 1,024 × 96 one-metre cells, with four radius-14 m home cores and a 150 m quiet starter area. | Compose within this extent. Preserve usable home ground and opening safety; the concept's relief must fit actual height headroom. |
| One lake uses fixed original footprint/bed limits with wading/swimming; caves retain priority. | The basin uses a lake and old drainage forms. Rivers, waterfalls, tides and fluid simulation are not promised. |
| Current V8 composer expects three discovery regions and five rare-site definitions. | New ecological biomes are not automatically new discovery regions, rare sources or rewards. A successor contract is needed, not just extra JSON entries. |
| Ordinary augmentation is a scalar field plus regional property strings; it is not four typed channel fields. | Typed influence and host relationships throughout new ordinary geography are proposed work. Existing cool-white seams are not all White resources. |
| Current fissures are cosmetic, surface-supported meshes; their vertices sit above terrain. | A deep wound needs a real native recess and matching contact, with art inside it. A wider emissive strip cannot supply depth. |

Exact [source notes](#source-backed-implementation-boundaries) below distinguish verified implementation from design assumptions. Older prose in the premise/roadmaps sometimes describes then-future LF work; current dispatch, specs and source take precedence. No material accepted-design/source conflict was established in this bounded inspection.

## Research that changes the recommendation

Sources accessed 16 September 2026. Facts below describe the sources; adaptations and tradeoffs are our proposals. No videos were watched, no external art is imported, and source availability is not a licence to reuse assets. This is a selected set of principles, not a claim that another game's scale or pipeline fits this project.

### R1 — Give a route a visible reason

**Read:** full developer interview, Alex Beachum/Mobius, [The Intentionality of Wandering](https://www.mobiusdigitalgames.com/news/the-intentionality-of-wandering), 18 August 2016.

**Documented:** players sometimes chose paths arbitrarily when they could not infer destinations. The team revised pathing to communicate where paths lead, preferably visually, while retaining surprise.

**Adaptation:** at Scarwater's first fork, show the same wounded ridge through two different approaches: shaded useful woodland and an open shoulder with broader views. Later, reveal a second ambition from the source.

**Tradeoff:** canopy and relief must preserve these information windows. Random placement cannot be allowed to erase the choice. This does not require a waypoint, compulsory route or the parked compass.

### R2 — Make the landscape structure first

**Read:** abstract, introduction and algorithm overview of Génevaux, Galin, Guérin, Peytavie and Beneš, [Terrain Generation Using Procedural Models Based on Hydrology](https://cs.purdue.edu/homes/bbenes/papers/Genevaux13ToG.pdf), ACM TOG 32(4), 2013, DOI 10.1145/2461912.2461996.

**Documented:** the method constructs a hierarchical drainage network, derives watersheds, then combines terrain and river primitives.

**Adaptation:** define a ridge, interrupted catchment, basin and dry outlet relationship before detailed elevation and vegetation. Let the impact modify an existing place.

**Tradeoff:** borrow the ordering and controllability, not the complete research system. A few bounded curves and landform operations are a plausible start; implementing an erosion solver or live rivers would delay the place.

### R3 — Compose habitats across presentation systems

**Read:** official presentation summary only, Jaap van Muijden/Guerrilla, [GPU-Based Procedural Placement in Horizon Zero Dawn](https://www.guerrilla-games.com/read/gpu-based-procedural-placement-in-horizon-zero-dawn), 1 March 2017. The slide deck and full talk were not reviewed.

**Documented:** artist-authored procedural rules assemble environments including wildlife, sounds, effects and gameplay elements.

**Adaptation:** one habitat description should govern canopy mass, ground transitions, middle growth, suitable fauna locations, sound and clear passages. Separate random lists are a poor production boundary.

**Tradeoff:** use a small local recipe vocabulary and the existing engine paths. This summary does not justify a custom GPU placement framework, memory budget or performance claim.

### R4 — A landmark promises something when reached

**Read:** Charlie Cleveland's developer account, [Theme-Mechanics Seesaw, Part 2](https://www.charliecleveland.com/theme-mechanics-seesaw-part-2/), 4 June 2021.

**Documented:** Subnautica players immediately tried to reach the prominent Aurora, initially a scenery billboard. The team developed it into an explorable place with useful progression connections.

**Adaptation:** the major scar must lead to inspectable physical evidence, a reachable source/workplace and a practical return loop. Its significance cannot end at the camera angle.

**Tradeoff:** use existing gathering, combat and machinery before inventing a gate. A conspicuous set piece with no payoff would repeat the scenery problem.

### R5 — Derive a creature from its role in a place

**Read:** Guerrilla developer/designer article, Bo de Vries with Blake Politeski and Maxim Fleury, [(Re)building the awe-inspiring machines of Horizon Forbidden West](https://blog.playstation.com/2021/11/08/rebuilding-the-awe-inspiring-machines-of-horizon-forbidden-west/), 8 November 2021.

**Documented:** ecological zones, machine roles and interactions inform design. Resource-searching machines can lead observant players to supplies; solar collection gives Sunwings a particular vulnerability.

**Adaptation:** an altered animal should demonstrate a host relationship that helps a player understand a habitat or source. Reuse LF's selected Red/Blue boars, White stag and Green moth before creating new families.

**Tradeoff:** Horizon's multidisciplinary production is substantial. We adopt the causal method, not mechanical dinosaurs, removable weak-point systems or its creature budget.

### R6 — Show activity that is not waiting to attack

**Read:** Joar Jakobsson/Videocult, [Rain World: Surviving in a Living Ecosystem](https://blog.playstation.com/2017/01/16/rain-world-surviving-in-a-living-ecosystem/), 16 January 2017.

**Documented:** creatures pursue food and shelter independently of the player, and learning their preferences creates opportunities.

**Adaptation:** choose one local, observable source-visiting routine with tracks or disturbed growth explaining its location. The player can watch, hunt or detour. LF already offers a bounded foundation.

**Tradeoff:** preserve Wroughtwild's ARPG pressure and progression. A persistent food web, offscreen population simulation and knowledge-only progression would be a major different game.

### R7 — Readable stylisation still requires authored work

**Read:** Wesley Martin/Mobius, [Our New Style](https://www.mobiusdigitalgames.com/news/our-new-style), 30 March 2018.

**Documented:** an earlier painterly approach conflicted with precise walkable geometry, near/far scale and iteration. Sharper forms and broad gradients helped; the new style still required more art production.

**Adaptation:** spend first on the ridge's silhouette, tree crowns, banks and broad light/value separation. Fine textures support these forms.

**Tradeoff:** a stylised target is achievable without photorealism, but an automatic mesh or shader pass is not equivalent to finished art direction.

### R8 — Recovery leaves a mosaic, not uniform greenery

**Read:** National Park Service, [Plant Succession, Rocky Mountain National Park](https://www.nps.gov/romo/plant_succession.htm), updated 31 March 2012.

**Documented:** succession varies by ecosystem and disturbance; canopy shade changes which seedlings survive, browsing can hold back tree establishment, and disturbed ground supports different stages of recovery.

**Adaptation:** mix surviving mature stands, dense younger margins, open browsed ground and exposed rock. Mature trees need not have grown from nothing since the impact; some survived.

**Tradeoff:** this is ecological inspiration, not a literal Earth timetable or a demand for live growth simulation. Alien augmentation can exaggerate host form while the physical patterns remain readable.

A useful counterargument comes from Mobius's [Alex & The Nomai!](https://www.mobiusdigitalgames.com/news/alex-the-nomai), 20 April 2016: Beachum describes moving away from procedural levels to carefully authored curiosity. Our response is not to claim unrestricted generation will do both jobs. Author the relationships and payoff, vary their geometry and arrangement. Wroughtwild retains random seeds; it needs constrained composition.

## Three substantially different directions

All names, new landforms, routines and mechanics in this section are proposals. “Smallest demonstration” means a future playable slice, not work performed here. Effort ranges are rough solo-production judgments in focused working days, assuming existing tools/assets; they are not measured estimates or commitments.

### A — The Inherited Landscape

**Promise:** become a skilled inhabitant of a beautiful, wounded world. Understand its history well enough to choose where to travel, what to take and where to build.

Its three signature ideas are **landscapes with a legible cause**, **the same augmentation visible in several hosts**, and **homes placed at useful relationships**. The impact is a change to a pre-existing place, rather than a circular decoration added to a generic biome. Technology is encountered as a force within stone, roots and animals; the player's craft makes it purposeful.

**First journey.** Leave calm meadow through a shaded gallery. Its narrowing view makes the eventual lake-and-ridge reveal memorable. The two routes show different costs: open visibility and distance around one shore, or enclosed timber-rich ground on the other. At the old smithy, the displaced masonry and fracture continue the ridge's story. Inspect the finite pressure source and the existing feeder's requirements. Return for clay, fuel and paid machinery; build a work outpost or carry the results home. On later expeditions, recognise related evidence in another biome.

**Example: Scarwater Basin.** Gallery trees follow moist low ground, mature surviving stands occupy sheltered banks, rock faces expose the wound, and ordinary fauna occupies suitable routes and feeding spaces. White impulse is expressed in displaced stone and braced plant forms; it is not renamed wind magic. A nearby stag can share the force's visual anatomy only where its actual identity supports it. Importing LF's White teaching host/routine is later proposed work, not an invented rule for every stag.

**Choice, return, building.** Build on the dry outlook for the view and room to extend, or at the grove edge for enclosure and timber access. Neither site grants a buff. The source is an outpost motive; a previously glimpsed dry upland becomes the next expedition. After finite stock is consumed, the home, routes, ordinary crafting and wider trial loop remain useful. Do not claim the source renews in normal play.

**Minimum complete demonstration.** One roughly 250–350 m composed area within a full playable 1 km seed: a recognisable ridge, lake, real dry fissure, one new Gallery Woodland habitat, two legible approaches, an existing functional pressure workshop opportunity, and two appealing home candidates among the four retained cores. New terrain and art must ship together.

**Work/cost.** New-profile composition, bounded native fissure, a small substantial tree/rock/edge kit, and careful ordinary-world integration. About 8–15 focused days is a planning allowance, with terrain/art contact the largest uncertainty. No new global AI or machinery is necessary for its first payoff.

**Failure mode.** Beautiful scenery with an unchanged dull walk. The remedy is to design the reveal, routes, source use and return before broadening the asset set.

### B — The Wild Circuit

**Promise:** learn to inhabit and eventually redirect a landscape whose augmentation is still actively doing work.

Its signatures are **observable environmental rhythms**, **route choices around those rhythms**, and **small player interventions with a visible local consequence**. The land has become machine-like accidentally; this does not establish that an ancient civilisation or the meteor sender designed a planetary machine.

**First journey.** From shelter, see one White impulse move through a fractured reach: loose host plates shift, reeds respond and an altered animal braces in the same sequence. A safe viewpoint exposes the pattern. Take a longer protected way now, or observe the interval and use a shorter exposed crossing. A later paid device could divert one local pulse to an existing workshop. Return to alter the route/device arrangement for an expedition.

**Example: The Breathing Reach.** Tall ribs of split bedrock frame a narrow dry valley. White displacements dominate the corridor; Red excitation accumulates in one different host beneath a sheltered shoulder. Blue retention could hold a release long enough for passage; Green could distribute a request. These are proposed environmental applications of the verbs, not confirmation that existing devices can control terrain.

**Choice, return, building.** A protected workshop in the lee exchanges source proximity for a constricted approach. An overlook is less convenient but lets the player read the rhythm. Later routing lets a player choose movement convenience versus useful work. Buildings must remain undamaged; there is no random storm that demolishes paid construction.

**Minimum complete demonstration.** One observable reach, two paths, one clear safe interval, one existing animal response, and one paid local diversion that changes a route or workshop outcome. A purely cosmetic pulse would be an atmosphere study, not this direction's full promise.

**Work/cost.** Approximately 15–30 focused days for one convincing intervention: new environmental state, clear cues, collision/traversal behavior, save semantics and art/animation/audio coordination. Unknowns include what energy pays for the event and how changes interact with excavation.

**Required departures.** New environmental timing/hazard/control rules and ownership. White requests are not free mechanical energy; Green branching cannot duplicate material; Blue cannot simply freeze all time. These require explicit design approval.

**Why not lead with it.** It could become Wroughtwild's strongest later signature, but risks postponing the missing world in favour of another isolated machine prototype. Keep one local intervention as a future stretch, after places and four-force craft are convincing.

### C — The Living Inheritance

**Promise:** read the behavior of altered life to discover the world, then build at the edge of its habits.

Its signatures are **animals as clues to useful hosts**, **ecological traces that explain vegetation patterns**, and **changing access through local routines**. Augmentation propagates through particular physical relationships, not a rule that any coloured creature can mutate anything it touches.

**First journey.** Find three signs together: rubbed roots, repeatedly clipped growth and a worn track. Wait and see an altered grazer visit the host. Follow at a distance to an unusual growth pocket; decide whether to fight now, gather after it leaves, or make the longer route. Later, a player-built observation/work outpost makes this circuit convenient. Another animal expresses the same force differently, teaching the relationship rather than a colour key.

**Example: The Rootwake Groves.** Connected root fans divide sheltered basins and raised dry paths. Green propagation exaggerates branching in an appropriate host; a moth visits the connected growth. Blue-retaining tissue in a separate grove carries persistent layered structures. Fauna use should explain openings and ground wear. A quiet recovery patch with ordinary forms supplies comparison.

**Choice, return, building.** Build near a predictable route for access or farther away for quiet work. Knowledge changes how the player approaches a resource/encounter, without a research XP gate. A full version could offer a bounded, paid way to encourage growth along one edge, but this is a new mechanic rather than a free resource generator.

**Minimum complete demonstration.** One connected habitat, two existing creatures with complementary local routines, visible traces, one discovery those routines reliably reveal, and a real siting tradeoff. A repeated idle animation beside a glowing bush is insufficient.

**Work/cost.** Approximately 12–25 focused days for the demonstration; a persistent ecology would be much larger. Art must communicate anatomy and effects; AI needs bounded behavior, navigation and interruption. Knowledge may become unreliable if procedural relationships are weak.

**Required departures.** New interactions between creature routine, habitat and resource discovery; any gardening, migration, reproduction or supply renewal requires separate rules. Preserve existing hostility, rewards and source owners unless specifically changed.

**Why not lead with it.** It addresses lifelessness directly but cannot fix an unconvincing landform or empty middle distance by itself. Adopt one locally readable habit later; defer a food web.

### Comparison and choice

These are qualitative creative judgments, not test scores.

| Criterion | A: Inherited Landscape | B: Wild Circuit | C: Living Inheritance |
| --- | --- | --- | --- |
| Distinctive promise | Read history and make it useful | Understand/control active environmental machinery | Learn ecology through observation |
| Immediate exploration appeal | Strong silhouette and destination payoff | Strong spectacle and systemic mystery | Strong close observation; weaker skyline by itself |
| Building appeal | Strong from first home | Strong once interventions work | Strong if habitat knowledge changes siting |
| Lore fit | Directly expresses accident, augmentation, recovery, reuse | Strong, but must avoid invented intentional world-machine lore | Strong host emphasis; inheritance/exposure rules remain open |
| Seed variety | Landform and route relationships vary readily | Rhythm/collision layouts must remain fair | Relationships must remain learnable across arrangements |
| Authored burden | Moderate kit, demanding composition | Kit plus animation/audio/state coordination | Kit plus anatomy, habits and evidence |
| Solo risk | Lowest of the three; art and terrain remain substantial | Highest gameplay/save burden | High AI/readability burden |
| Expansion | New host biomes and useful outposts | Additional local interventions | Additional relationships/routines |
| Recommended role | Foundation and first place | Later stretch intervention | Selective living evidence |

**Disciplined synthesis:** A supplies the world structure. Existing workshop/device uses supply practical agency. A small amount of observable host behavior supplies life. This is not approval for B and C in full.

## The recommended world grammar

Treat four dimensions separately:

- **Biome:** physical conditions and living architecture—land, moisture, soil, canopy and passages.
- **Influence:** which augmentation verb affects a particular compatible host.
- **Host:** the stone, tissue, animal or worked material through which the force acts.
- **History/state:** what was damaged, what survived, what recovered, and any actual campaign change.

A biome is not a colour territory. A Green-influenced dry steppe and an ordinary wet gallery can both be green in the everyday sense. An animal's anatomy should remain recognisable without emission. Decorative presence is not proof of available source stock, an attack type or a collectible.

### Four forces expressed through hosts

The verbs and existing LF functions are established foundations. The proposed land/growth expressions below are art/ecology interpretations to assess, not new physics.

| Force | Proposed land/rock expression | Proposed living-host expression | Current usable foundation and boundary |
| --- | --- | --- | --- |
| **White / Impulse** | Offset stone laminations, directional fractures and compression scars; a short travelling pulse deep inside | Braced roots and stressed forks; existing LF White stag demonstrates the selected animal case | Existing ordinary finite pressure workshop is the first reuse opportunity. LF White sends a request; it does not supply free work energy. |
| **Red / Excitation** | Swollen mineral seams, locally altered/vitrified faces and vent-like cavities, amid recovered ground | Thickened conductive growth or concentrated release organs; existing LF Red rooting boar | LF Red media, paid heat and costly Ember production exist. Red does not mean blanket lava, fire damage everywhere or a new fuel economy here. |
| **Blue / Retention** | Nested fracture pockets and retained layered deposits; protected wet pockets where physical terrain also supports water | Persistent sheaths, compact layered buds and held deformation; existing LF Blue boar is a separate taught expression | LF delay and Frost-related source pool exist. Blue is not universal ice, frozen water or an automatic time-stop. |
| **Green / Propagation** | Forking seams following susceptible host contacts, with interruptions at unsuitable substrate | Connected root fans, repeated growing nodes and branched anatomical traces; existing LF Green moth visits connected growth | LF branching and Preserving-related source pool exist. Branching requests does not multiply matter or grant free growth. |

A recognisable grammar needs **shape + timing + location**, with colour as reinforcement. White can travel and stop; Blue can linger; Green can fork; Red can accumulate and release locally. Those pulse animations are proposed presentation, and must never imitate a damage tell that has no corresponding hazard. Non-emissive fracture depth, host structure and usable-source models carry information when colour is hard to distinguish.

Initially permit only one dominant influence per teaching place. Leave quiet breaks between them. Consider one deliberately authored mixed-host encounter later using existing LF combinations; do not generate arbitrary four-way blends or multiply the creature roster by four.

### A broader biome vocabulary

These are four candidates, not four automatic work assignments. Within a 1 km map, differences should follow moisture, exposure and substrate, not implausible continent-scale climate bands. “Gallery Woodland” and “Dry Steppe” enter the recommended wave. The others remain reserve directions.

| Candidate | Physical structure, growth and transition | Fauna, sound/motion, play and settlement | New art / decision |
| --- | --- | --- | --- |
| **Gallery Woodland** — first | Elongated moist bands around fixed lake margins and old drainage swales; tall narrow crowns, rooted banks and shaded passages. Progresses from open meadow through shrub edge to canopy. Distinct from broad Deep Forest and low fen. | Existing suitable passive fauna and woodland encounters; branch movement and occasional leaf/water textures with quiet gaps. Timber access and sheltered work ground; see the ridge through deliberate canopy openings. Deep water uses existing rules. | Two complementary tall tree forms, roots/bank joins and one middle-growth family. Do not draw a flowing river merely because the habitat resembles a floodplain. |
| **Dry Steppe** — second | Broad dry undulation, shallow erosion cuts, tall seed-grass masses, low spreading shrubs and sparse resistant groves. Pale mineral or clay exposures interrupt continuous ground. Distinct from barren/ember wasteland. | Ram/porcupine roster fits are proposals subject to existing encounter data; dry rustle and exposed sightlines. Easy long-range reading, vulnerable approaches, generous building space; existing mineral/clay opportunities. Transitions through increasingly open woodland, not a painted border. | One grass/seed-head family, a low branching shrub/tree form and weathered cut-bank/rock variants. Local Red alteration affects selected hosts, not the entire biome's temperature. |
| **Wind Heath** — reserve | Low crest vegetation, mats, cushion shrubs and wind-shaped scrub separated by exposed stone ribs; sheltered moist hollows. A structural low-growth biome rather than Rocky Hills with another tint. | Existing ram/beetle candidates; intermittent wind and stem motion. Outlook homes trade exposure for enclosed working pockets below the crest. No new wind penalty. | Distinct shrub/mat structure and credible hill-scale silhouette. Add only if the first two places leave capacity; not part of this wave by default. |
| **Sinkwood** — stretch reserve | Weathered enclosed depressions, daylight shafts, sloping entries and root-dominated grove interiors; dry ledges around damp low ground. Connects to existing forest/caves. | Existing moth/nymph habitat candidates where rules fit; close occlusion and sparse drips, useful sheltered workshops with constrained expansion. Current cave hazards remain. | Most expensive candidate: real depression/cave contact, large root forms and shadow readability. No automatic huge roofed caverns, new swimming depths or underground performance work. |

The existing meadow, forest, fen, rocky hills and wastes remain useful contrasts. Discovery names such as Rootvault, Lantern Fen and Glasswind are not interchangeable with this biome catalogue. New biomes can host existing finite discoveries without duplicating their stock.

## Compose random worlds as connected places

This is a proposed generation order, not a replacement algorithm implemented in this session.

1. **Establish the old country.** Choose a compact arrangement of ridge, low ground, substrate and surviving settlement use. Keep the finite extent and adequate vertical headroom. These simple shared descriptions explain natural home terraces and former travel/work sites.
2. **Apply the catastrophe to that country.** Choose bounded impact position, direction and affected host. Deform a ridge/valley relationship and connect selected traces; retain a mix of buried, broken and exposed evidence. The smithy survives where old access and the later accident intersect. It was not built to serve a meteorite.
3. **Compose the present catchment and recovery.** Position the fixed lake consistently with the basin and preserve legitimate cave openings. Old dry swales can imply interrupted drainage without adding active rivers. Use shelter, moisture, slope and surviving soil to produce vegetation masses and transitions.
4. **Place promises and useful space.** Reserve the approach reveal, reachable source, two routes, useful home cores and source work access before vegetation. Resolve source/ruin/cave conflicts rather than covering them with cosmetic art.
5. **Attach influence to compatible hosts.** Carry explicit channel identity separately from strength, exposure and history. Use existing impact/trace/site relationships as anchors. Influence shapes a few concentrated places and paths between them, with quiet recovery and interruptions; it is not uniform colour noise.
6. **Place resources and encounters with their habitat.** Reground existing finite owners after terrain, preserve economy guarantees and opening safety. Choose suitable existing bodies and data. Later selected teaching hosts receive source-linked routes; they do not appear simply wherever a matching colour occurs.
7. **Fit the authored kit and readable light.** Orient rock strata and root forms to the actual landform. Place connected canopy/middle growth with material continuity and clear feet-level paths. Keep both near bank and distant landmark readable under ordinary lighting.
8. **Use bounded fallback composition.** A candidate that cannot fit lake/cave/home/source constraints switches to a simpler authored basin arrangement. It must not silently delete the source payoff or turn the hero region into generic scatter. LAND-01 specifies that fallback and its tunables.

**What varies:** basin orientation and asymmetry, shoulder silhouette chosen from a small family, shoreline indentations, which approach is enclosed, home position, surviving grove distribution, minor source exposure and secondary biome adjacency. Later, compatible influence-host pairings can vary from a curated list.

**What stays meaningful:** one approachable focal place; a clear visual cause; usable source/work area; dry exits; four useful home cores globally; calm starter supplies; ordinary completion paths; finite ownership; at least two distinct base-setting choices. A fresh seed should present a new arrangement to understand, not a different answer to every learned rule.

A first scene should be composed at player height immediately, then expressed through reusable parameters. It must be generated through the ordinary seed/profile path from the start. An artist may author a relationship template and reusable kit; fixed screenshot-coordinate scenery is not the product.

### Three signature experiences to carry into briefs

**The view becomes home.** A framed reveal gives the player a destination and a potential address. After the first expedition, looking back from the source lets them identify where their workshop will stand. Building expresses a spatial decision, using current parts and costs. Return value comes from repeated useful travel, storage and expanding architecture.

**The wound becomes a workshop.** Offset rock, damaged old masonry and an exposed usable source form a continuous explanation. The player brings real clay, fuel, a forge and the paid feeder; the force becomes useful through their work. Source UI distinguishes remaining finite pressure from decorative living pulse. Nothing at the ruin is free completed machinery.

**The host teaches the force.** After the first place, a Red boar's existing LF source-related habit and a visibly altered plant/mineral host share one understandable relationship. Later Blue and Green demonstrations show different verbs. The player can seek a source for a current craft ambition. Observation supports equipment/building progression rather than replacing it with a compulsory journal, research meter or new mastery ladder.

The first two belong in the initial playable place. The third enters only when selected LF host/acquisition behavior is deliberately adapted to the successor. Ordinary fauna provides immediate life without falsely implying that adaptation is already done.

## Two planning visuals

![Concept target: recovered Scarwater Basin, not a game screenshot](land00-visuals-2026-09-16/01-scarwater-concept.png)

**Concept board:** generated with the built-in image tool from an original text brief. It communicates enclosure, a singular displaced skyline, established recovery, dry home ground and a small usable ruin. It is neither evidence of current rendering nor an asset source. Its rich foliage/material finish is aspirational; the existing Godot style should use simpler authored forms with the same hierarchy.

The image's tiny clamp sketch is an illustrative containment idea, not a new item or approved recipe. Furniture on the home shelf represents later player construction, not free starting structures. Its large ridge must be fitted to the 96 m world-height envelope; literal proportions are not a generator specification. The White pulse is visually restrained here; in production the exposed mouth needs more readable depth and host detail at close range. Do not reproduce the image by hiding an unusable landform behind art.

![Annotated proposed routes, home choices and physical fissure section](land00-visuals-2026-09-16/02-scarwater-layout.png)

**Layout:** an original diagram, not surveyed terrain or a game capture. It specifies the functional relationships behind the concept. Marker 6 denotes existing suitable fauna first; source-visiting routines are later proposed work. The section requires a real dry recess separated from the lake, a visible floor/escape approach and honest terrain contact. Dashed white lines reserve views, not paths through water.

The approximate 250–350 m composition span and 20–35 m relief are initial design targets, not tested values. Four radius-14 m home cores and the quiet starter boundary are existing constraints; two illustrated home candidates are part of those four, not new compulsory plots. The exact source/home layout must preserve existing progression and opening protections.

[Visual provenance and production caveats](land00-visuals-2026-09-16/README.md) include the [exact image prompt](land00-visuals-2026-09-16/image-prompt.txt). Original owner references remain in their library. No external image licences or runtime reuse rights are assumed.

## Source-backed implementation boundaries

This inspection answers consequential planning questions only. It is not a full source audit or feasibility measurement. Paths/line numbers refer to the worker base `c7f20f77a20fe6875cafad34adca10cf91b3fa82`.

| Inspected source | Relevant fact and next action |
| --- | --- |
| [sandpit.gd](../../game/scripts/sandpit.gd), lines 18 and 38–44 | Normal V8 and LF geography/campaign are distinct. Keep new-world geography and acquisition/campaign policy explicit. |
| [V8 tuning](../../data/tuning/worldgen-frontier-v8.json), lines 14–17 and 861–865 | Finite dimensions, home and quiet-area constraints. New physical geography uses separate versioned inputs. |
| [V8 composer](../../sim/src/worldgen_frontier_v8.inc), lines 194–251 | Existing region, land, home, resource, route and ruin composition; three regions/five rare-site assumptions. Extend with a bounded place description rather than a general framework. |
| [worldgen.h](../../sim/include/wroughtwild/worldgen.h), lines 53–108 and 202 | Existing impact direction, trace topology, linked ruins/approaches and scalar augmentation field. Explicit typed channel/host/history metadata is proposed. |
| [V8 landscape](../../sim/src/worldgen_frontier_v8_landscape.inc), lines 79–160 | Regional property strings and surface trace shaping. A typed world design cannot be achieved by tinting this scalar alone. |
| [V8 lake](../../sim/src/worldgen_frontier_v8_lake.inc), lines 16–83 | Original lake bed/footprint and cave protection. Keep the dry fissure outside lake contact. |
| [fissure builder](../../game/scripts/leyline_fissures.gd), lines 3–4 and 134–165; [RF-08 look](../../game/rf08/fissure.tres) | Cosmetic supported strips with no physical recess. Generate actual terrain depth, then fit art and recessed light to it. Preserve excavation and paid overlap handling. |
| [native surface mesh](../../game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp), lines 3065–3074 and 3200–3225; [terrain edit path](../../game/scripts/terrain.gd), lines 409–474 | Render, collision, sampling and picking share established terrain behavior. Explicitly opt the successor into the corrected surface branch; do not mask contact errors with a static decorative shell. |
| [profile dispatch](../../sim/src/worldgen_profiles.cpp), lines 11–27 and 95–124; [SaveManager](../../game/scripts/save_manager.gd), lines 185–195 and 290–306 | Continue restores validated saved identity before owner state. Extend allowlists deliberately; freeze old inputs and never reseed existing worlds. |
| [leyline tuning](../../data/tuning/leyline.json), lines 4–73; [LF tuning](../../data/tuning/living_frontier.json), lines 17–40 | Four LF source owners and four selected teaching hosts already exist. Reuse semantics if adopted; ordinary finite pressure remains a separate owner. |
| [current world-generation spec](../systems/world-generation.md), LF era-event section | Retained Fen and Excited Uplands are selected LF events, not global ecological simulation. Preserve both and the existing three-era campaigns. |

**Normal/LF recommendation.** First ship the new geography with ordinary acquisition/progression and the ordinary pressure pocket. The White influence interpretation does not merge that finite pressure ledger with LF's White mineral source. Then, if selected, bring LF's already implemented materials, costly recipes, request/delay/branch devices and paid heat into fresh successor worlds under an explicit acquisition policy. Preserve their exact costs, caps, work stages and active-overworld-only source renewal. Keep finite ordinary resources/rare cores/pressure separate. Do not automatically import laboratory locations, the Conservator campaign or terrain events.

This is a real adoption decision because it changes how normal new worlds acquire capabilities. It is more coherent than inventing another four-colour economy, but it is not accomplished by a presentation flag. LAND-01 must trace the minimal dependencies and state what can ship independently.

**Published geography stays frozen.** Each subsequent slice that changes generated physical geography needs a new saved generation revision/profile, or must finish before that geography is published. Prefer playable incremental successors; do not reuse a profile name with changed terrain. Old V8, earlier successors and LF Continue retain their original worlds. Safe presentation improvements can be shared when they respect actual support/ownership. No new default is switched by this planning session.

## Art production that can actually deliver the place

The first kit should change the silhouette and joins, rather than multiply decorative pebbles:

| Kit role | Minimum proposed authored work | Reuse |
| --- | --- | --- |
| Ridge and scar | Three modular fracture/strata forms with large/middle detail; two mouth/lip joins and an inset pulse surface | Existing material vocabulary and terrain; real recess owns collision/contact |
| Gallery canopy | Two complementary tree forms with connected crowns and exposed bank/root variants | Existing rig-free vegetation pipeline; existing resource identity where used as a harvestable |
| Ground joins | Root/soil bank pieces, one shrub/fern edge family and continuous turf/litter transition | RF-02 ground maps, RF-06B low/middle growth, RF-09 mineral treatment |
| Human history | One small re-composed ruin using the existing practical craft vocabulary | Old smithy/ruin parts, ordinary paid forge/feeder/construction |
| Life and motion | Existing appropriate fauna and restrained wind; later one source-linked teaching host per selected force | Approved creature masters, animations and LF habits before new species |

Keep major forms manually controllable in Blender. Use the existing local image-to-3D route only when it saves work on a specific form; it is optional, and must still be edited for silhouette, contact, UVs/materials and game scale. No new service, asset pack or dependency is selected.

Production order: block the basin and first-person approach with representative large forms; inspect the dominant weakness; author the small kit; export through existing runtime paths; assemble one ordinary seeded area; revise form/ground/light together; only then broaden the recipe. The concept is guidance for relationships, not a promise to generate a whole finished environment from an image.

Address the retained dark-bank failure as part of the scene: canopy openings, value separation, readable host surfaces and restrained ambient balance should reveal the wound and working area. Universal emission and global brightness would erase the useful contrast.

Prepare reusable scenes/materials during actual New World/Continue entry, following the established mob/scenery preparation pattern. Do not add first-encounter blocking loads. Startup/memory costs remain a design tradeoff, not proof that preloading everything is free. First use belongs in the eventual short smoke; no benchmark matrix is proposed.

## Revised prioritised roadmap

The earlier outline separated landscape structure, landmark art and biome dressing. That risks another chain of technically completed pieces whose combination remains underwhelming. Replace it with **one planning handoff, three complete place/capability outcomes, then one bounded closeout**. These are proposed assignments for later selection; none is launched.

| Order | Visible/playable outcome | Original ambition advanced | Scope and dependencies |
| --- | --- | --- | --- |
| **LAND-01 — Commit the place contract** | A concrete Scarwater implementation brief, kit specification and chosen successor/policy boundary | Connected landscape, lore and production plan | Assess this recommendation; resolve terrain/fissure contact, full scene budget, new-biome data and LF adoption dependency. Planning only; no second ideation round by default. |
| **LAND-02 — Make Scarwater real** | Walk from ordinary starter country into a memorable basin; choose between two approaches and home settings; reach and use the existing finite pressure workshop opportunity | Awe, recovered impacts, home-building desire, first new biome, deep living scar | New saved geography, Gallery Woodland, terrain and substantial art together. Current ordinary rules. A complete seeded place, not a greybox followed by an indefinitely deferred art task. |
| **LAND-03 — A contrasting country with a reason to go** | A Dry Steppe place with different visibility, growth, landform and base choices; understand a Red host and seek its usable material | More biome variety; technology changes area, growth and fauna; useful discovery | Depends on LAND-02's composition language. If acquisition adoption is selected, deliberately reuse the relevant LF Red source/recipe/host behavior in a fresh successor. Preserve current costs and owners. Without that decision, this capability outcome stays pending rather than being marked complete through red decoration. |
| **LAND-04 — Read and use all four forces** | Connected optional excursions demonstrate Blue retention, Green propagation and White requests; bring useful materials/devices into the player's actual workshop | Lore-to-crafting/automation relationship and meaningful reasons to return | Complete selected LF acquisition/device reuse in the successor; use existing habitats plus small host-form additions. No new biome, campaign, broad factory or all-animal colour matrix is required. Distinguish ordinary pressure from White material/request semantics. |
| **LAND-05 — Bounded world closeout** | The delivered places join coherently during one chosen ordinary expedition and home return; fix recorded problems that materially weaken those outcomes | One world rather than isolated demonstrations | Consolidate seam/readability/access issues from this wave. Use applicable prior evidence; no new biome, performance wave, full campaign replay or automatic catalogue of separate bug tasks. Stop and choose the next ambition. |

LAND-02 is the first playable demonstration and primary investment. Do not start a cheap placeholder version of all later places alongside it. The two added biomes become genuinely different habitat structures; Blue/Green can transform hosts within them and existing fen/forest. Wind Heath and Sinkwood remain outside this initial wave.

**Effort expectation:** the first place's 8–15 focused-day allowance includes substantial art and integration. LAND-03 and LAND-04 might each need roughly 6–10 days; closeout 2–4. These are uncertain creative-production allowances, roughly 22–39 focused days for the implementation wave, not calendar deadlines. LAND-01 should revise them after the fissure/kit/policy choices. If that burden is too high, deliver LAND-02 well and pause breadth; do not dilute every place until none achieves the goal.

**Eventual checks remain focused.** Each implementation slice names its concrete risk and uses at most three focused jobs by default: relevant deterministic/ownership checks, one ordinary Forward+ load/use/first-use route with player-height inspection, and a targeted Continue check when changed state requires it. Reuse unchanged evidence. A second ordinary seed can examine the specific new composition rule without a seed/camera/renderer matrix. Functional success and achieved appearance must be reported separately. No such game checks ran in LAND-00.

## Consequential owner decisions

These are recommendations to assess with the coordinator after this session, not blockers to completing this planning record.

| Decision | Recommendation and consequence | Alternative |
| --- | --- | --- |
| **1. What should organise the world?** | Select A: Inherited Landscape, beginning at Scarwater. Lore supplies a shared place history; exploration and building realise it. Spend on one full scene before further breadth. | Select B for active terrain intervention first, accepting new gameplay/save work and later environmental breadth; or C for ecology-led discovery with greater AI work. |
| **2. What breadth belongs in the first wave?** | Two substantial additions: Gallery Woodland and Dry Steppe. Show all four influences through selected hosts, not four copies of every biome. Keep the 1 km world. | Build four biomes now, with substantially more authored kit and integration, or stop after Scarwater if the first place consumes the available effort. |
| **3. Should normal new worlds learn the existing LF source/device vocabulary?** | Yes, as an explicitly scoped fresh-successor acquisition adoption after the first ordinary pressure place. Reuse costs/renewal/ownership and host rules; leave LF campaign geography/events intact. | Retain normal acquisition throughout; magic remains useful through pressure, combat loot and current crafting, while four-colour source/device play remains LF-only. LAND-03/04 must then be rewritten rather than claim that payoff. |

No decision about the meteor sender, exact age, human origin or ancient civilisation name is needed. No lore canon should be invented to justify a mesh.

## Concrete LAND-01 handoff

The ready-to-use proposed continuation is [LAND-01 brief from this discovery](land00-land01-recommended-brief-2026-09-16.md). It supersedes the old highland-first suggestion only **if the owner/coordinator selects this recommendation**. The previously prepared LAND-01 task remains on hold until that assessment; this session does not dispatch it.

It must produce the previously named landscape plan and LAND-02 implementation brief, with actual choices rather than another prompt to scope the scope. Its central technical question is a physically honest dry fissure and landform composition that can fit the present terrain. Its central creative question is whether the approach, working ruin and home view feel like one compelling place.

## Deliberately deferred

- B's player-directed regional pulse routing, moving terrain and environmental traversal hazards.
- C's persistent ecosystem, migration, reproduction, gardening and resource-affecting habitat engineering.
- Wind Heath, Sinkwood, new creature ancestries, further era/boss model production and arbitrary mixed influences.
- Rivers, waterfalls, seas, boats, diving, dynamic fluid simulation, world-size expansion and engine migration.
- Automatic LF campaign adoption, new labs/eras, source currencies, research/mastery gates and broad automation.
- Unrelated Thrumroot/group-frame/long-entry costs, the unconfirmed underground connection, parked compass/coordinates, historical ART R9 and earlier broad review waves.
- Small inherited cosmetics unless they concretely prevent the selected place from working.

These remain proposals/backlog, not automatic next tasks. Requested deep fissure form, connected growth, convincing silhouettes and useful home outlooks are central to LAND-02 and cannot be dismissed as optional polish.

## Delivery and verification record

**Achieved:** a recommended lore-driven world vision, three alternatives, selected primary-source research, two annotated planning visuals, a bounded biome/influence proposal, revised roadmap and concrete LAND-01 handoff. The coordination sheet records the recommendation as awaiting assessment.

**Limits:** no feasibility build, new game capture, runtime import, benchmark, save fixture, package reconstruction or owner playtest. Estimates and target dimensions are unmeasured. The concept is not current game quality. Gameplay departures and acquisition adoption remain proposals. Retained RF-09 evidence is reused only for observations, not as proof that proposed work succeeds.

**Planning checks completed:** nine cited primary-source pages/paper references checked with review depth disclosed; 35 local link/anchor targets resolved; both selected PNGs decoded and were visually inspected; scoped whitespace/diff and repository status checked. No game checks were run. The checked commit is returned in chat for coordinator integration. Only planning documents and selected visuals belong in it. No main integration or remote push is performed by this worker. No follow-on implementation task or LAND-01 task is launched; stop after this handoff.
