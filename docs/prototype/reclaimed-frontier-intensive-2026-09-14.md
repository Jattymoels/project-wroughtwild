# Reclaimed Frontier — terrain and biome composition

**Status: first slice scoped at the owner's request, 15 September 2026.**
The owner agreed with Reclaimed Frontier as the next creative wave and asked to
scope it. [RF-01 meadow and woodland recovery](rf01-reclaimed-ground-worker-2026-09-15.md)
is the prepared first worker. Implementation has not started; later terrain and
biome work remains proposed. This is separate from the stopped R9 review.

## RF-01 selection — 15 September

The previous adoption wave is complete on main through `dc6a8c0`: the environment,
placeables, finished fauna and six replacement mobs, plus scoped movement,
canopy and chest improvements. Underground investigation is parked for the
owner's next playthrough; it does not hold up this separate creative work.

The first outcome is connected low meadow/woodland growth around existing old
damage, using the current B2/R7 assets and existing tree/shrub canopy. One roughly
80–150 m ordinary route provides a useful visual slice; it is not a new map or a
fixed acceptance distance. The dressing applies naturally to eligible meadow/
forest chunks in current V6/LF geography, rather than only one staged corridor.

RF-01 is presentation-only: existing eligible saves can receive the cosmetic
change without reseeding, migration, new stock or moved buildings. Terrain
height/voxels/collision, native resource/tree/site anchors, campaign events and
old-world identities remain unchanged. V1–V5 and other biomes keep their existing
presentation. Cosmetic plant roots/footprints may change; grounding, excavation
and actual paid-building suppression must remain correct. Larger vegetation
footprints must not leave grass over holes or inside octagonal buildings.

This resolves the first slice's compatibility boundary. It does not claim that
cover alone will deliver all the desired landform undulation. The worker records
that visible limitation if present. Native terrain changes need a later scoped
contract, with existing saves kept intact; no new generator profile is selected.

| Milestone | Present scope/status |
| --- | --- |
| RF-01: meadow/woodland recovery | Plan and worker ready; normal-game low-cover composition, one useful walk, focused edit/build/Continue checks. |
| Later landform slice | Proposed after RF-01: old-impact surroundings, rises/dips and routes. Decide whether a new-world-only successor is needed; never silently reshape existing saves. |
| Later biome expansion | Proposed: fen and mountain recovery based on what works in RF-01 and any landform decision. No all-biome production batch is dispatched now. |

Scoping evidence: all six owner references and their caveats were inspected,
with image 6 read through a smaller inspection derivative after the image reader
failed on the full-size file. Originals are untouched. Current cover, surface
sampler hooks and building-mask code were read; R7's retained coverage limitation
and PLAY-01's projection finding were reused. No new engine/Blender run, runtime
visual capture, benchmark or source-package reconstruction was needed to scope.
The expected visual improvement remains to be demonstrated by RF-01.

Worker location: `D:/Wroughtwild/work/rf01-reclaimed-ground`, branch
`codex/rf01-reclaimed-ground`; setup is `build/rf01/SETUP.md`. The owner starts
the worker, which returns a checked commit and inline images/clip. Current
standing approval covers ordinary prototype delivery and main adoption without
another visual/benchmark gate. Only this first slice is prepared.

**Later owner workflow clarification, 14 September:** when the owner approves
the result visually, integrate it into the game without separate rollout approval
or baseline/benchmark gates. Current AGENTS.md prototype limits govern this future
work too. Use a short load/use check and necessary changed-behavior checks;
performance tuning and broad end-to-end review follow owner playtesting. No
exhaustive evidence package or second art-review matrix is required.

## Intended result

At walking height, the world feels undulating, inhabited and years beyond the
meteorite catastrophe. Established grass, woodland, wetland plants and mountain
vegetation have grown across much of the old disruption. Large impacts still
shape memorable basins, ridges and routes; exposed veins/cracks carry pulsing
augmentation through the recovered landscape. Surrounding life is as important
as the impact itself. Biomes should differ in how they recover.

The six owner references are influences, not exact output targets. Read the
[annotated originals](../art/references/environment/2026-09-14-reclaimed-frontier/README.md)
and [owner wording](../art/references/environment/2026-09-14-reclaimed-frontier/owner-intent.md)
before planning, generating concepts or changing terrain. Image order, original
bytes, source caveats and checksums are kept with them. Do not rely on temporary
attachments, a chat summary or a contact sheet alone to recover this direction.

## Existing foundations and the remaining gap

| Foundation | Already recorded | What this intensive must add or assess |
| --- | --- | --- |
| [Wide Frontier / D-032](wide-frontier-intensive-2026-09-06.md) | Random/chosen seeds, finite 1 km rolling worlds, regional interiors, building clearings and saved identity | Convincing ground-level undulation and ecological composition across varied seeds, beyond a technical elevation check |
| [Cataclysm / D-030](cataclysm-world-intensive-2026-09-06.md) | Related impacts, traces, terrain, ruins and discoveries | The age and recovery of surrounding land; large impacts with varied landform consequences rather than repeated exposed bowls |
| [ART-07 direction](world-and-placeable-art-2026-09-09.md) | Layered canopy, ground/bank/rock transitions and biome-specific asset roles | Compose the accepted kit into connected ground cover and living spaces across terrain |
| [Living scars](leyline-asset-roadmap-2026-09-09.md) | Embedded damage and narrow moving light; ordinary/work/danger meanings remain distinct | Review visible ground pulses among vegetation, with physical dark scars still readable when emission is disabled |
| [R7](art07-repairs/2026-09-14/receipts/r7.md) and [R8](art07-repairs/2026-09-14/publication-r8.md) | Fuller local groups inside retained placement envelopes; combined art and measured costs | Continuous undergrowth remains unmet. Existing eligible envelopes cover at most 6.12–8.68% of four measured windows; this is not a world-wide vegetation measurement |

## Position in the work queue

Follow the [owner's mainline adoption handoff](art-mainline-adoption-2026-09-14.md):
integrate the delivered ART-07 kit with known limitations recorded, then address
the actual playtest reports of stuttering, incomplete-looking canopies and
accidental underground access/worse lag. R9 is stopped and is not a prerequisite.
Then scope this terrain/ecology intensive using the integrated kit and relevant
available findings. This is not an extra condition for current art integration.
The six separate ART-06C rig/adoption items remain their own work; they need not
hold up environment planning.

The user has approved adding this future work and its sentiment to the durable
backlog. They have not selected a new generator profile, map size, live growth
system, density target or implementation schedule by doing so.

## Qualities to carry into the design

- Make local rises, dips, banks and sheltered pockets legible at player height.
  Continuous grassy ground and varied trees should connect ordinary spaces;
  preserve useful paths, combat sightlines, gathering access and building ground.
- Let old impacts influence surrounding slopes, broken ridges, basins and exposed
  strata. Soften and reclaim much of the damage. Do not reproduce a field of similar
  raw crater bowls or require an impact to dominate every camera view.
- Use established forest layers and undergrowth; open country retains broad
  grassy space. Fen recovery can use wet margins, reeds and roots. Mountain
  recovery can use weathered shelves, settled debris and vegetation in appropriate
  pockets. These are proposed translations into existing biome roles, not new
  biomes, drainage physics, universal grass coverage or fixed snow rules.
- Keep selected pulsating veins/cracks connected to host material and impact
  history, with other stretches covered or buried. Readable scars survive
  emission-off review. Light does not imply replenished stock, extraction
  readiness or immediate danger unless the native state actually says so.
- Preserve the earthier Wroughtwild art direction. Images 1–2 are highly styled
  influences; 3 is closer in feel but too crater-focused; 4–5 carry the same
  recovery correction into other biomes; 6 supplies undulation and everyday life.
  None selects exact silhouettes, UI, weapons, creatures, weather or map layouts.

## Retained broader approach — beyond the RF-01 boundary above

1. Inspect the then-current main game and available R9 findings. Use ordinary
   walking views with the adopted kit. Separate asset
   deficiencies from terrain shape, coverage and placement problems.
2. Prepare a small terrain-and-vegetation target: a grassy walk through an old
   disturbance into woodland, plus a representative mountain view. Review
   walking-height motion, open ground and recovered scars with the owner before
   reproducing the treatment across biomes. References remain influences.
3. Specify deterministic terrain/vegetation relationships and compatibility
   before implementation. Establish which changes are presentation-only and
   which alter generated geography or collision. Preserve existing worlds and
   ownership; name a successor profile only if a later approved plan requires it.
4. Carry the accepted relationships into representative seeded biome routes.
   Reuse the finished assets; set distances, coverage and pulse controls from
   visual review and practical use. Investigate runtime cost when the owner's
   playtesting identifies a problem. Document what each tuning value
   changes for the player.
5. Validate new-world variation and meaningful gameplay, save/reload, terrain
   edits, paid building, all legal forms including octagonal uses, resources,
   historical profiles only where the behavior changes. Use one renderer by
   default and stay within the prototype check budget. Publish the approved
   playable result with known limitations; no performance comparison is required.

These are broader planning checkpoints, not a requirement to perform them all in
RF-01 or a fixed count of repair waves. The first-slice work item above narrows
them to one route, one lighting condition and the changed behavior. Later biome,
landform and varied-world work requires its own scope; it does not become a new
review matrix for this slice.

## Review questions and decisions still open

No clarification is required to preserve the owner's current intent. A later
implementation plan must resolve terrain/placement ownership, legacy-save
compatibility and representative biome scope before
dependent changes. Crater size/frequency, erosion/cover proportions, pulse timing,
vegetation density and draw distances remain untuned. The exact elapsed years
can stay unspecified unless a concrete feature requires a number.

The intended starting landscape can be generated already reclaimed. A live
growth/regrowth or ecology simulation is not necessary to express its age and
has not been requested. The setting's original catastrophe remains distinct
from the existing later Living Frontier campaign transformations; their saved
timings, protected terrain and progression are not rewritten by this art brief.

Evaluate the future result with actual varied-seed, player-height day/shade/dusk
views and native walking, including terrain away from hero landmarks. Check
vegetation coverage/transition, mountain recovery, readable exposed scars with
emission off/on and approach/building clearances using a few useful views.
Performance comparisons belong to a later owner-requested investigation.
Owner acceptance concerns the sentiment
and game feel, not pixel matching to these references. Technical tests alone do
not close visual acceptance. Unmeasured hardware does not block approved art adoption.
