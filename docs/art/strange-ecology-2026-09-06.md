# Strange Frontier: ecological composition refinement

Approved continuation: [make the concepts feel inhabited](../prototype/frontier-art-refinement-2026-09-06.md).
The owner found the first screenshots barren and amateurish. This pass changes
the relationship between the regional landmarks, their vegetation and their
ground-level surroundings. It does not change native generation or finite stock.

## Regional composition

Rootvault uses irregular groves with several tree heights, overlapping crowns,
saplings, fern interiors, moss and short deadfall. Six large elders punctuate
that forest. Their crowns are baked into the shared grounded bole meshes, so
streaming moves the whole tree together and never separates a crown from its
support. The other trees retain the imported shared mesh and its LODs.

The Fen begins with supported shallow pools, each with a different radius,
aspect and irregular shoreline. Taller sedge bands follow those edges. Dry
islands hold smaller trees, broken hollows, scrub and moss. Water stays shallow
visual dressing without collision or resource production.

Glasswind uses larger low shelves in aligned groups, with smaller eroded ribs
used sparingly. Scree and taller dry sedge gather in lee-side crescents around
the shelves. These placements have wider support and clearance checks than
small plants; rejected shelves are not forced onto paths or unsupported slopes.

Seed 1's final bounded composition is:

| Region | Composition | Tiled mesh batches |
| --- | --- | --- |
| Rootvault | 21 groves; 6 elders, 106 supporting trees, 14 saplings; 418 ferns, 132 moss beds, 119 shrubs, 28 deadfalls | 78 |
| Lantern Fen | 19 dry patches and 11 pools; 13 trees, 5 hollows; 1,001 sedge groups, 250 shrubs, 104 moss beds | 51 |
| Glasswind | 24 clusters; 7 eroded ribs, 31 broad low shelves; 118 scree groups and 344 dry-sedge groups | 39 |

These are decorative objects, separate from generated harvestable trees, stones,
materials and rare specimens. Each region still has openings. Native gathering
spaces, clue trails, complete rare-site work areas, and approaches to both the
regions and their caves are reserved before placement. Elder roots also check
their four protruding ends for support and route clearance.

The first intermediate refinement had 57 smaller Glasswind outcrops, 129 scree
groups and 363 short sedge groups. The final pass deliberately uses broader
shelves with larger clear footprints rather than retaining that count. The
Fen's intermediate 786 sedge groups became 1,001 in tighter, taller shore and
island bands. Rootvault's accepted composition stayed the same.

Final review caught a small rib variant whose support radius understated its
visible width. Ribs, hollow trunks and shelves now reserve their complete
transformed horizontal mesh bounds, with the established one-metre minimum.
The stronger test checks the actual authored footprint as well as that minimum.
This excludes five hollows and two shelves accepted by the preceding art pass;
their edges are not allowed to spill into native gathering or route clearances.

## Rendering and editable-world behavior

All meshes are shared. Batches cover 32-metre tiles so smaller growth retires
before the regional skyline. Understory, middle-sized forms and canopy have
separate 100/155/240-metre visibility ranges. Small ground vegetation does not
cast individual shadows. Its modest movement is visual only.

The source controls live in `game/art/strange_ecology.gd` and its resource.
Counts, cluster widths, spacing, height bands, support tolerances, visibility,
buried bases and building clearance each explain their visual purpose. Authored
negative root bounds remain buried; meshes are not lifted by their lowest vertex.

Exact chunk activation re-grounds existing poses. A deferred dig/save refresh
does the same across the existing composition instead of rolling placement
again. Unsupported instances collapse out of the renderer while their original
horizontal position remains available for a later restoration of that ground.

Ordinary placement and removal query the current simulation lattice pieces.
Their rotated bounds suppress only intersecting decorative instances, with a
small clearance margin. Stored poses remain intact. Removing a piece restores
growth only when the terrain still supports it. Bulk placement queues one
refresh per frame; save restoration flushes after rebuilding the structure.
Harvestable nodes, quantities, partial work and depleted records are untouched.

The rendered workshop review also exposed ordinary terrain grass protruding
through its floor. V3 ground cover and the existing habitat-cover batches now
retain their exact original transforms and colours for the same reversible
clearing. Newly streamed or rebuilt chunks clear those instances before becoming
visible. Aggregate batch bounds skip distant cover quickly. Legacy and v2 worlds
do not retain this extra cover metadata or enter the new clearing path.

## Verification and review

`ecology_buildings.tscn` passes **102 headless checks** through the actual Sandpit,
GridPlacement and SaveManager paths. It verifies ordinary placement, removal,
restoration with and without the piece, collapsed/restored renderer submissions,
unchanged finite node stock, exact grounding after excavation, and unchanged
horizontal positions after the deferred terrain refresh. The dummy headless
renderer does not retain MultiMesh buffers, so the test records the exact
submitted matrices. The same fixture also passed **113 checks rendered with
Forward+ on the RTX 5090**, including actual engine-buffer comparisons. Ordinary
grass is tested under a real floor slab, after removal, save restoration and
chunk rebuilding. Separate legacy/v2 guards verify that clearing does not change
their appearance. The final logs are `build/frontier-polish/ecology-cover-headless.log`
and `build/frontier-polish/ecology-cover-rendered.log`.

The final terrain-stream fixture passes **58,221 checks** with no failures.
Its reservation checks identify tiled batches by their `mesh_kind`, include all
three elder variants and low shelves, and test actual transformed footprint
bounds for ribs, hollows and shelves. The fixture still covers exact regrounding,
native-derived horizons, excavation cancellation and restoration.
After the ordinary-cover hook, that same **58,221-check** fixture passed again,
along with **21 weathered-save checks**. The final targeted logs are
`build/frontier-polish/terrain-stream-cover-final.log` and
`build/frontier-polish/weathered-save-cover-final.log`.

Machine-readable seed-1 counts are in
`build/frontier-polish/ecology-counts.json`. Matched views and frame measurements
are owned by the integrated review at `build/frontier-polish/before/` and
`build/frontier-polish/after/`; this composition report does not infer performance
from the screenshots. The owner still needs to judge the final visual quality.
