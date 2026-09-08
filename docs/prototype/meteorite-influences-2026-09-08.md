# Meteorite influences: places, creatures and recoverable capabilities

Status: **Owner-approved direction; detailed rules proposed, not implemented.**
8 September 2026. Source baseline: `d466256`.

The owner's subsequent requests are developed in the
[initial INT-09 system map](meteorite-leyline-intensive-2026-09-08.md) and the
newer [Living Frontier roadmap](living-frontier-roadmap-2026-09-08.md).
The four broad influence proposals now have owner support as foundations.
The roadmap supersedes the moth-first sequence: useful magical raw materials,
rare intact Catalysts and perfected manufacture connect to laboratory
failsafes, physically transforming eras, a human uber-boss and captured
difficulty controls. [Extraction and process design](leyline-catalyst-extraction-2026-09-08.md).
Exact outputs, odds, recipes, transforms, campaign count and migration remain
proposed; the owner requested planning before implementation.

## Owner direction

Different meteorites carry different magic/technology. Their influence travels
through leylines, changes the land and augments ordinary animals. The owner
identifies the existing white-coloured smithy example and imagines red, blue and
green influences with different functions, present in seed-generated worlds.
Affected mobs should produce different combat experiences; extracting the
different influences should enable different useful augmentations. Players
choose exploration/collection goals according to the capabilities they need.

This extends D-030 and the owner's 7 September coloured-leyline direction. It
informs the [wolf/woodland art study](leyline-art-studies-2026-09-08.md) without
expanding that study into implementing all meteorite families.

**Meteorite influence → local leyline network → altered hosts and encounters →
recovered capability → player crafting/build choices.**

Animal ancestry and influence are separate dimensions. A wolf remains visibly
canine, while the influence changes its growth, scars/currents, movement or attack
character. The same influence should be recognisable in rock, roots, animals and
the materials/devices made from it. A distinct encounter means a different player
response, not merely a tint or a larger damage number.

## Existing implementation, checked separately

- Native impacts/traces have stable seed-derived identities and regional
  property/history data. The current augmentation field guides presentation;
  it does not apply a colour-selected combat transformation to a mob.
- The shared leyline material uses cool-white `c4e3ec` light. That shared visual
  does **not** establish every existing trace as a typed white meteorite family.
- The struck old smithy supplies one finite pressure pocket. Pressure moves the
  player's feeder; ordinary fuel supplies heat for the existing brick recipe.
  The old smithy predates the accidental impact and was not built to extract it.
- Existing creature families recover particular Kinds/catalysts. Their selected
  appearance associations are not a procedural animal-by-meteorite variant system.
- The Ash Hound retains its Quicksilver association. Its silver-blue scars do
  not currently grant Frost attacks or identify a future blue family.

Evidence: [world generation](../systems/world-generation.md),
[pressure contract](leyline-extraction-proposal-2026-09-06.md),
[creature adoption](augmented-beasts-2026-09-07.md),
`sim/include/wroughtwild/worldgen.h`,
`sim/src/worldgen_frontier_v6_pressure.inc`,
`game/art/leyline_look.gd`, and `data/tuning/world.json`.

## Working identities — direction supported, details proposed

The owner subsequently supports these broad colour/process directions as
foundations to tune. The specific attacks, outputs and recipes remain examples,
not an accepted implementation catalogue.

| Colour | Candidate principle | Example creature expression | Example recovered use |
| --- | --- | --- | --- |
| White | Stored pressure and impulse, developing the smithy motif | Visible compression before a committed burst; respond to release timing | Mechanical drive or controlled force/release augmentation |
| Red | Heat accumulation and release | Heat builds before a venting attack; respond to the vent and recovery | Heat handling, ignition or release effects |
| Blue | Binding, preservation and slowed motion | A telegraphed binding effect constrains movement; break position before it takes hold | Preservation or control effects |
| Green | Growth and propagation | Living growth changes reach or propagates an effect; manage spacing or interrupt its source | Growth, transfer or propagation effects |

Colour should be supported by characteristic scar branching, host growth, motion
and attack tells. Environmental currents stay distinguishable from immediate
combat warnings. These examples preserve interest in catalyst/proliferation
behaviours without specifying damage, sustain or new invulnerability rules.

## Design questions before implementation

1. **Generation:** which influences must every world contain, which may vary,
   and how do counts, siting, spread and biome overlap depend on the seed?
   Seeded variety is accepted; these guarantees remain unselected.
2. **Encounters:** which ancestry/influence combinations merit authoring, and
   which distinct player response does each require? Do not assume every animal
   needs a version for every influence.
3. **Recovery:** what does extraction produce, and how does it feed existing
   Kinds, catalysts, equipment crafting and the Foundry? Combat recovery and
   extraction need useful roles without duplicate currencies or obsolete loot.
4. **Extraction:** what device, work, finite stock, depletion and ownership
   contract applies? A source's visual glow is not evidence of available stock.
5. **Persistence:** select a bounded work item and compatible generation strategy
   before changing placement/influence identity. Preserve existing geography,
   depleted stock, owned builds and progression.

Overlap, mixed influences, dynamic exposure/transformation, purification,
renewability and broader automation remain undecided. No new generator profile,
spawn system, recipe or save schema is implemented or selected here.

## Original first gameplay recommendation — superseded by the roadmap

The original recommendation below is retained as history. The owner now asks
for extraction/campaign foundations before the moth; use the Living Frontier
roadmap above for the current sequence.

After the visual standard is established, choose one additional influence and
one existing animal. Trace one complete example from seeded impact and habitat
through an encounter with a distinct player response to one useful recovered
augmentation. Judge that loop before expanding the palette/roster. Keep the
pressure workshop as existing evidence of one source-to-use loop, not proof
that the broader system already works.
