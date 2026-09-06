# Intensive: a world shaped by the cataclysm

**Status: approved for implementation, 6 September 2026.** The owner accepts this
intensive: “Yep let's do it”, identifying extreme augmentation as the Northstar
already expressed by the forge/bench/Foundry and now needed in the land. The
[world premise](../world-premise.md), regional interpretations, bounded art and
successor-generation scope below guide implementation under D-030. Future
leyline extraction and powered production remain follow-on design, as specified
below. Approval does not certify a completed visual finish.

The bounded runtime implementation and automated/rendered review are complete;
owner visual and playtest acceptance remains open. See the
[implementation and evidence](cataclysm-implementation-2026-09-06.md), including
the unresolved first-view performance limitation.

## Outcome

At walking height, a player can recognise what a place used to be, see how the
cataclysm changed it, follow evidence toward a desirable discovery, and bring
something home that visibly belongs in the same world. Quiet, beautiful places
remain worth protecting and building in. The player learns through the land,
creatures and making things; a compulsory lore quest or opening exposition is
unnecessary.

## What still needs work

The current `frontier_v3` already provides a finite 512 × 512 m world, three
broad discovery regions, material habitats, reachable finite rare sites, saved
harvest state and small useful contraptions. The latest art pass adds layered
vegetation, shared authored nature, improved surfaces and atmosphere. These
are working foundations, not acceptance of the visual finish.

The remaining gaps are composition and consistency: landforms still expose
the underlying voxel shapes; common resource props and actors lag behind the
new regional kit; places lack traces of everyday civilisation and a common
cause for their transformation. Biome transitions and journeys need stronger
relationships than adjacent areas of different dressing. Buildings, stations,
creatures and the Forge need the same material and augmentation language.

In particular, current v3 rotates three broad circular cores around the centre
and blends their terrain into height bands. Connected basins, drainage traces,
ridge lines and underground landmarks would make the landscape more convincing.
They can be authored terrain relationships without adding flowing-water physics.

Runtime audit correction during implementation: authored broadleaf/boulder and
furnishing studies were already in normal gameplay before this pass. The mob
skins were still study-only. Refine the existing paths and adopt the mob skins
without duplicating asset integration or claiming it was all new work.
The [last review](frontier-art-refinement-2026-09-06.md) also records early
streaming excursions around 120 ms whose cause remains unproven. Increasing
world size before density, journeys and those hitches are addressed would make
the current weaknesses more expensive.

## A visual rule for the whole game

**Surviving life and craft → violent impact → runaway augmentation → deliberate reuse.**

Each region exaggerates one recognisable underlying tendency.
Technology amplifies growth, light, pressure, motion or preservation according
to its host. An unnaturally flourishing place can be as threatening as an ash
field. Calm remnants show the original scale and make the altered places legible.

Use three readable layers in important compositions:

- **Before:** modest alien vernacular, worn paths, waterworks, field boundaries,
  domestic objects and naturally unusual plants. Establish that someone lived here.
- **Impact:** directional breakage, collapsed roofs, buried fragments, scorched
  faces and displaced ground. Damage has a source and a direction.
- **Augmentation:** repeated technological details embedded in roots, stone,
  shells, machinery and enemies. Their repetition teaches a relationship; subtle
  rhythm, sound and shape can identify inactive traces without constant emission.

Player craft supplies the fourth layer: useful local timber, masonry and reed
with recovered components deliberately braced, contained and connected. Late
craft should reveal control of the same force that distorted the wilderness.
Early materials remain desirable parts of advanced buildings.

### Approved regional interpretations

| Existing place | Former character | Amplified character and discoverable evidence |
| --- | --- | --- |
| Meadow and starter habitats | Modest farms, gathering places and low structures built from local materials | Survivable remnants, broken field walls and a distant impact scar. A strange horizon draws the player out; the home clearing retains daylight and breathing room. |
| Rootvault Wildwood | Shaded groves and low timber/reed dwellings | Growth and stored tension exceed their former scale. Roots pull through rooms, crowns bridge ruins and bowed trunks point toward Thrumroot chambers. Small untouched trees show the difference. |
| Lantern Fen | Reed settlements, clay banks and shallow managed water | Light and pressure concentrate in sheltered colonies. Flooded foundations and mineral vent cases lead to Lanternheart and Ventlung pockets, with dry approaches and quiet pools between them. Water stays shallow dressing. |
| Glasswind Uplands | Wind-worn grazing slopes, quarry shelters and stone paths | Charge and attraction leave fused scars, ringing tubes and iron grit climbing surfaces. Stormglass and Pullstone have distinct clues within a connected disturbed landscape. |
| Ember Wastes and the Forge threshold | Material culture and working structures consistent with the surviving world | Heat and compulsive industry consume the ruins. Reuse the impact motifs in existing Forge architecture, furnace mechanisms and boss tells; the Forge's precise origin stays open. |

These interpretations establish visual and sound themes, not new damage types,
environmental drain, forced waiting, resource gates or enemy powers. Regional
colour supports existing danger colours; a decorative pulse must not masquerade
as a projectile or a boss windup.

## Generation: compose causes and journeys

For the successor generation profile, retain the current finite extent
and region count initially. Compose a bounded set of impact anchors and connected
leyline traces within the geography. Use proximity and exposure to influence
local augmentation, ruin damage, scenery and existing encounter/resource placement.
Some traces break, disappear underground or lead to exhausted fragments; every
visible line need not terminate in a guaranteed jackpot.

Anchors and trace segments need stable IDs and independent deterministic seed
streams. Their distance/falloff fields can inform terrain and site scoring;
Godot receives the resulting geometry and presentation tags rather than rolling
a separate history for the same place.

Place regions and safe approaches first, then impacts/traces, authored ruin
footprints, rare compositions and ordinary population. Validate the relationships
as a whole before committing them: a vista, a readable route in, room to work or
fight, an optional discovery and a route home. Retry a bounded layout or use a
validated fallback composition when it fails. Do not scatter each layer independently.

Connect existing opportunities through these compositions. Rare resources stay
finite, physical finds with learnable clues; richer exceptional sites reward
attention. Preserve enough open ground for building, combat and clear views.
Alternate intimate passages with broad views and quiet ground with concentrated
threat, rather than raising density everywhere.

Vary the existing rare housings with their host geology/ecology. Exceptional
sites should have a recognisable composition as well as the existing richer
haul, without new efficiency grades or a different compulsory recipe component.

Initial authoring budget: one shared impact/technology kit, one small ruin kit
for each of the three discovery regions, and one integrated Forge threshold.
Reuse parts with terrain-aware foundations, damage and material variation.
Implemented defaults are three impacts, nine trace paths and six ruin sites in
`frontier_v4`. The [generation report](../art/cataclysm-generation-2026-09-06.md)
records the native layout, seed matrix and plain-language tuning purposes.

## Art: finish a place, then carry its quality across the game

Start with one short continuous route: a furnished survivor workshop in readable
daylight, a ruined dwelling at the woodland edge, an augmented grove and an
existing rare-resource discovery. Show the haul used back at the workshop. The
route is a review composition in real gameplay, not a separate visual-only demo.

Bring these elements to a common finish together:

- Terrain silhouette and transitions, exposed strata, rooted tree bases and
  grounded ruin foundations; no floating props or sharp material bands.
- Common harvestable trees and rocks as well as exceptional landmarks, with
  close detail, convincing aftermath and visual fit to their interaction bodies.
- Foliage structure, restrained movement, soft canopy gaps, wet margins and
  local sound; preserve gathering clearances and building vegetation suppression.
- Ordinary buildings and workstations, including edges, joinery, roof layers,
  interiors and contained recovered components. Use the shared material-art lookup.
- Existing creatures: readable remnants of origin, embedded augmentation and
  coherent motion through their current attack timings. Begin with the families
  on the reference route, then cover the remaining current roster. Preserve
  collision and combat contracts; review known Blender study body-fit issues.
- Light and effects across daylight, dusk, indoors and active combat. Keep
  rare-find clues visible by day, silhouettes clear and hostile tells dominant.

Set one attainable authored style with controlled facets, varied roughness and
strong shapes. Use the approved local Blender pipeline, shared meshes, instancing
and distance detail. More fog, bloom or grass alone cannot finish these places.

## The future extraction and automation connection

The lore gives the existing systems a reason to belong together:

| Player stage | Existing foundation or future proposal | Visible payoff |
| --- | --- | --- |
| Survive and rebuild | Existing common materials, habitats, shelter and stations | A practical home made from what survived. |
| Take power from the enhanced world | Existing enemy Kinds/catalysts and Foundry mutations | The creature's augmentation has a recognisable relationship to the recovered component and crafted effect. Lore does not change drop tables. |
| Learn to contain and apply it | Existing forging and five rare-component fixtures | The same property becomes a lamp, stored tension, signal, sorter or pressure response in a handmade housing. |
| Work a leyline | Future: one deliberate extraction process tied to an existing site and evolved facility | A sought-after material/property can be recovered under controlled conditions. Its source and required preparation are legible before it is workable. |
| Make the workshop act on it | Future: one input → one existing process → one output | A bounded source supplies energy; reusable components store, signal or deliver it. Existing manual work remains useful. |

The first three rows supply this intensive's playable discovery-to-home review.
The latter two receive a concrete follow-on recipe/site/energy proposal after
that review; they are not runtime automation scope in this aesthetic pass.
This refines the earlier automation roadmap with the owner's leyline direction.
A concrete [finite pressure-to-brick workshop proposal](leyline-extraction-proposal-2026-09-06.md)
records the source, recipe, energy budget and recovery decisions for separate
owner acceptance; none of it is implemented by this intensive.

Preserve the existing five cores and their roles. A Lanternheart remains light,
Stormglass a signal, Thrumroot stored tension, Pullstone attraction and Ventlung
stored/delivered pressure. None becomes an unexplained infinite power source.
Kinds retain their existing typed uses and quality; no duplicate generic tech
currency is needed. Additional ores should introduce properties or combinations,
not a straight replacement ladder for all previous materials.

Before implementing new extraction, settle the exact product and useful recipe,
facility/process requirement, finite stock, energy source and failure/recovery
contract. Ordinary contextual work and currently available recipes keep working;
skill properties improve work without becoming class-specific access gates.
Before powered production, also settle throughput, input/output ownership,
unloaded behaviour and personal mastery. The recommended first line grants no
automatic personal mastery and performs no offline catch-up, still proposals.

## Delivery and verification

1. **Record the premise and establish the target.** Use the current matched
   captures as baseline; develop the reference route and a compact material,
   form, creature and effect sheet from actual assets. Confirm the look at
   ordinary eye height before multiplying content.
2. **Finish that route end to end.** Integrate nature, ruin, current mob and
   resource, harvest aftermath and a furnished home. Review daylight/dusk and
   movement with active Foundry effects. Existing harvest/build rules apply.
3. **Compose the new geography.** Freeze v3 and its placement inputs before
   introducing the successor profile (`frontier_v4`), including the
   shared generation helpers v3 currently calls. Add bounded
   impacts, traces, ruin relationships and transition zones, then populate them.
4. **Carry the finish across the current world.** Complete the Fen/Uplands
   journeys, everyday resource/station assets and existing actor roster; carry
   the same material/augmentation language through the Forge threshold and
   existing trial rooms. This is art integration, not another trial arc.
5. **Review the actual game and cost.** Walk the connected routes, build in the
   regions, fight in the dressed spaces and review existing trial tells. Measure
   startup, settled and moving median/p95 plus largest hitches under matched
   settings. Investigate regressions over 10% and the unresolved early stalls.

Acceptance combines structural checks with visual judgment: deterministic
connected placements across seeds; grounded resources and ruin footprints;
clear mandatory paths, working spaces and combat sightlines; preserved finite
and partial harvest state; no scenic dressing inside player buildings; clear
distinction between old life, devastation and augmentation without a tooltip.
Show three region walks, one furnished home and a complete Forge presentation
review in daylight/dusk or its normal interior light. Do not present concept
renders or scripted camera captures as human playtest acceptance.

Use representative seeds with different region orientations and difficult
placement candidates for visual walks, alongside the broader deterministic
generation matrix. A polished seed-1 scene alone does not establish composition
quality across the generator.

Old worlds retain profile, terrain, resources, buildings, excavation and
depletion. Cosmetic refinements can reach old saves only with stable interaction
footprints; new topology, ruins, resources and encounters belong to the successor
profile. All profile-dependent caches and terrain queries include that identity.
Era changes still affect an existing world on the player's current milestones,
without adding a new era or regenerating geography.

Affected systems: world generation/profile snapshots and tuning, Godot terrain
and streaming, authored assets, resource/building/station/creature presentation,
biome light/audio, existing Forge presentation and save/review fixtures. New
values require plain-language purposes. D-010/D-013/D-017/D-019/D-021/D-025–029
continue to govern their respective rules.

The initial planning record changed no runtime behaviour. Implementation and
its evidence are recorded below as they land. Exact cultures and meteor origins
remain mysteries. Settlement NPCs,
territorial purification, a new enemy roster, infinite geography, production
networks and the reported timber-demolition conflict are outside this intensive.

## Implementation record

The accepted Northstar now reaches the land through native impact/trace/ruin
records, a terrain augmentation field, region-specific surviving architecture,
altered vegetation, common resource inlays and the same recovered material
language on workstations, current creatures and the Forge. New worlds select
`frontier_v4`; the legacy, v2 and v3 generators retain their historical inputs.

The bounded kit contains fourteen local Blender assets. The twelve reviewed
creature skins now use the normal motion and status paths. The broadleaf,
boulder and furnishing assets already in gameplay were retained and refined.
Finite rare ingredients still reach their existing recipes through ordinary
interaction, physical drops and collection. No new extraction recipe, currency,
enemy ability, damage type or powered production line has been added.

Evidence and remaining visual/performance review are consolidated in
[the implementation review](cataclysm-implementation-2026-09-06.md), with detailed
[generation](../art/cataclysm-generation-2026-09-06.md),
[asset](../art/cataclysm-kit-2026-09-06.md) and
[actor/craft](../art/cataclysm-actor-craft-2026-09-06.md) reports.
