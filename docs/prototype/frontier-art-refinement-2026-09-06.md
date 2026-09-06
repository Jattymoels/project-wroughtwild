# Strange Frontier: make the concepts feel inhabited

**Approved continuation, 6 September 2026:** the owner loves the concepts but
finds the screenshots “very barren and amateurish” and invites continued work.
This is an art/composition correction under D-013/D-029. The concepts and useful
resource interactions remain; their visual presentation has not been accepted.

## Outcome and diagnosis

The three regions should read as continuous natural places at walking height.
Rootvault needs connected trunks, heavy irregular roots and a layered canopy;
the Fen needs reed beds, wet margins and sheltered luminous pockets; Glasswind
needs eroded shelves, broken outcrops and wind-shaped vegetation. Landmarks
should emerge from those settings instead of appearing as isolated display props.

The previous pass left too much empty middle ground, repeated nearly identical
hoops and spikes, sparse triangular crowns, flat terrain colour and a blank sky.
The new pass addresses geometry, placement and lighting together. A fuller scene
must still retain clear paths, recognisable danger and open gathering space.

## Small implementation plan

1. Capture matched seed-1 views with actual regional lighting and fixed camera
   positions, clock, renderer and resolution. Preserve the previous art evidence.
2. Refine a compact local Blender kit: organic roots/trunks/crowns, worn layered
   stone and a few reusable understory forms. Keep deterministic source, shared
   meshes and import LODs; no new external art dependency.
3. Compose clustered canopy, understory, shoreline and scree using bounded tiled
   instances. Ground them on actual rendered terrain, retain clear approaches,
   and suppress decorative vegetation inside player-built structures.
4. Improve v3 terrain surface variation, sky and ambient/direct light balance.
   Preserve readable meadow daylight and established threat colours.
5. Review the matched images and walks; measure static and streaming costs,
   investigate regressions above 10%, and run affected gameplay/save checks.

## Assumptions and boundaries

This pass develops existing places. It does not move native terrain, seeds,
resource/site IDs, finite quantities, deposits, packs or saved player edits.
It adds no recipes, currency, combat/class rules, weather physics or production
line. Both old generator profiles remain frozen. New-world presentation may
improve when a v3 save is loaded. Automation's next workshop slice remains
recorded in the prior work item, following this presentation correction.

Affected implementation: local authored asset source and manifest;
`StrangeSites` and its presentation resources; v3 terrain shaders and
`BiomeMood`; placement/save refresh hooks; fixed-camera review fixtures.
Every new density, distance, size, colour and lighting control states its purpose.

## Review standard

Show before/after daylight and dusk with the same camera and seed, plus close
rare-resource approaches. Check finite and grounded transforms, unobstructed
routes/work areas, exact regrounding after streaming/excavation, and vegetation
suppression/restoration around placed and removed buildings. Keep new décor
separate from harvestable stock. Automated checks establish those contracts;
the owner decides whether the final look feels convincing.

## Implemented refinement

The normal v3 world now uses a 31-asset curated local kit, including three
irregular old boles, connected crowns, supporting trees, broken hollow trunks,
layered stone and shared fern/sedge/moss/scree forms. Rootvault has 21 groves
with 112 canopy trees; the Fen has 11 shallow pools with planted margins;
Glasswind has 24 rock-and-grass communities. Counts are bounded attempts, with
unsupported and reserved placements rejected. [Exact composition and tuning](../art/strange-ecology-2026-09-06.md).

New v3 surface and atmosphere resources add broad loam/moss patches, continuous
material relief, matte stone, closer contact shading and restrained clouds.
Existing day/era rules still drive the light. The first review exposed a
triangle-grid artifact; isolated shader checks traced it to pixel-derivative
height reconstruction. Analytic world-space gradients removed it. Work for
fully faded distant grain is now skipped. [Material and lighting evidence](../art/wildland-material-light-2026-09-06.md).

Placement and removal clear intersecting decorative growth using the current
lattice pieces. Original poses remain available for removal and save restore;
an unsupported plant stays hidden. Digging re-grounds existing placements
without reshuffling neighbouring vegetation. The route tests also found and
corrected an understated small-rock clearance: ribs, hollows and shelves now
reserve their actual authored horizontal footprint.

All 52 native rule and tuning files captured before this art pass retain their
SHA-256 hashes. No geography, finite stock, progression, recipes or machine
rules changed. Older-profile sky, fog, contact settings and material caches are
restored when switching between actual v3/v2 saves in one live scene.

## Reproducing the review

Run Godot with `--path game --resolution 1440x900` and
`res://tests/frontier_polish_review.tscn`. It writes the current matched day/dusk
and five source approaches to `build/frontier-polish/after/`. The archived
`before/` set was captured before editing the art; do not regenerate it from
current assets. `-- --polish-perf-check` records extra Uplands timing windows
separately, preserving the primary comparison.

`res://tests/frontier_polish_walk.tscn` records three approximately 54-metre
approaches at 5 m/s and 1.65 m eye height. Each route is timed without image
readback, then captured separately at four images per second. The review
includes a shoreline view and a normal lattice-built material workshop.
`-- --polish-interior-only` repeats just that interior under `interior/`.
Run `python tools/wroughtwild-blender/frontier_polish_gallery.py` to build
`build/frontier-polish/index.html`; it verifies the matched camera identities
and required images. The gallery includes a before/after slider and walk player.

These are rendered gameplay spaces, but the camera walks do not perform a
human playtest. The art remains deliberately faceted. Existing voxel geography,
older common-resource meshes and the small demonstration workshop still show
the prototype's limits; this pass does not claim final production art.

## Completed checks and measured cost

Every fixture in the regular Godot checks pipeline passed across the full run
and focused reruns after the defects above were corrected. The final affected
checks passed: terrain/streaming **58,221**; ecology/build/save **102 headless and
113 rendered**, including actual MultiMesh buffers; weathered save/profile
lifecycle **21**; contraptions **85**; authored art **60**. The unchanged combat,
construction, material, trial and other engine fixtures passed as well. Logs
are under `build/frontier-polish/` and `build/codex-aesthetic/logs/`.

The final matched renderer passed **17 checks**, the complete walks **33,841**,
and the corrected ordinary-workshop interior **24**, with no failures. The
gallery verifies camera identities and required images; its generated
JavaScript passes `node --check`. `git diff --check` is clean. The final native
rule/tuning comparison remains **52/52 identical files**.

1440 × 900 Forward+, RTX 5090, uncapped, 90 warmup and 600 measured frames per
settled view; each primary before/after result is retained:

| View | Median before → after | p95 before → after | p95 change |
| --- | --- | --- | --- |
| Glasswind | 1.108 → 1.171 ms | 1.357 → 1.446 ms | +6.6% |
| Lantern Fen | 1.349 → 1.600 ms | 1.807 → 2.223 ms | +23.0% |
| Rootvault | 1.508 → 1.584 ms | 2.054 → 2.053 ms | approximately unchanged |

World setup was 4,669 → 4,550 ms. Sequential runs can have different cache
state, so this does not establish a startup improvement. Ordinary-cover pose
retention adds about 8–15 MB across these progressively loaded views.

The threshold investigations are retained rather than replacing inconvenient
primary samples. An earlier Uplands increase repeated at about 15%; skipping
zero-contribution distant grain reduced four same-pose windows to
**1.340–1.387 ms p95**, followed by the final primary sample above. The Fen's
2.223 ms sample did not repeat: eight shown windows measured **1.814–1.852 ms**.
Alternating the same scene's dressing shown/hidden measured approximately
**0.069 ms p95 / 0.066 ms median** composition cost, with 109 additional draws
and approximately 373,000 additional primitives. The isolated high Fen sample's
exact cause is unproven. See `perf-check/`, `perf-investigation/` and
`fen-perf/manifest.json` under the comparison directory.

The separate live-streaming walks measured median/p95 of 1.217/3.658 ms in
Glasswind, 1.503/4.150 ms in the Fen and 1.758/4.928 ms in Rootvault. They are
different routes from the previous terrain benchmark and are not a matched
before/after streaming comparison. One 114.7 ms frame prompted a focused
Uplands trace: it recorded 121–124 ms excursions within the first 9.2 metres,
then no frame above 16.667 ms for the rest of the approximately 54-metre route.
The trace preserves frame indices and distances in `walk-perf/manifest.json`.
The precise source of those early approach hitches remains unresolved; they
must not be hidden behind the otherwise low median/p95. Lower-end hardware,
human discovery enjoyment and ordinary-play visual judgment remain unverified.

Follow-up: the [Cataclysm review](cataclysm-implementation-2026-09-06.md#the-earlier-v3-hitch-was-investigated-not-declared-fixed)
retains matched full-scan/bounded-scan v3 controls and a separate initial-view
probe with its streaming queue held fixed. The 120 ms excursion was not fixed
by scenery scan rejection. The review distinguishes first-view cost from warm
route samples and preserves all contradictory samples rather than claiming a
general streaming improvement.
