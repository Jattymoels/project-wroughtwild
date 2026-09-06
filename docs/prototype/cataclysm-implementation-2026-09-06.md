# Cataclysm implementation and review — 6 September 2026

The owner's accepted Northstar—extreme augmentation of an existing alien
world—now shapes new-world geography and the current game's material language.
This implements the bounded [intensive](cataclysm-world-intensive-2026-09-06.md)
under D-030. Visual acceptance and human combat/discovery playtests remain open.

## What is playable

New worlds use `frontier_v4`, retaining the finite 512 × 512 m extent. Three
impact basins connect through nine technological trace paths. Six supported
ruin sites link surviving vernacular architecture to existing finite finds.
Rootvault emphasises runaway growth and stored tension, Lantern Fen light and
pressure, and Glasswind Uplands charge and attraction. Broken/buried traces
leave quieter stretches instead of promising a reward at every visible seam.

A native augmentation field subtly alters terrain surfaces, exaggerates
vegetation near affected sites and determines where common resources show
embedded recovered technology. Fourteen original local Blender assets provide
timber dwellings, fen waterworks, upland masonry, directed impact fragments and
shared metal details. Existing broadleaf, boulder and furnishing integration
was retained; it was already in normal gameplay before this work.

The twelve reviewed creature skins now use normal movement, attack/status and
collision paths. Workstations, the trial gate and existing Forge rooms reuse
the same restrained recovered-material vocabulary. The gate retains its exact
interaction and collision; boss tells remain stronger than decorative inlays.

Rare ingredients still come from finite specimens through contextual work and
physical pickups. The existing Thrumroot → cargo winch recipe demonstrates
bringing an exaggerated natural property home. New construction hides
intersecting ruin geometry and collision; dismantling restores supported
remnants. Unsupported walls disappear after excavation, while buried meteor
fragments use an appropriate low foundation and exposed-crown check.

## Compatibility and rules

Legacy, v2 and v3 generation inputs and helper behaviour are frozen. Saves with
no profile remain legacy saves. Profile and seed identify terrain queries,
generation caches and restored worlds. This pass adds no resources to an old
world and moves none of its deposits, terrain or structures.

No new extraction gate, currency, era, enemy power, damage type or automated
production line is installed. Existing finite stock, rare cores, crafting
costs, Kinds/catalysts, loot and trial rules remain authoritative. The reported
timber-demolition conflict is outside this intensive.

## Verification

- Native v4 matrix: **25,959,555 checks**, zero failures, across 64 seeds.
  Full historical fingerprints cover 12 legacy/v2/v3 cases, including deliberately
  changed live v4 tuning. Existing native suites add **2,833,749** passing checks.
- Actual v4 lifecycle: **170 checks**, zero failures. Ordinary interaction rays, physical pickup absorption,
  useful crafting, paid building placement, aimed removal, valid ruin passage,
  atomic save/restore, depletion and partial work are exercised in
  `game/tests/cataclysm_intensive.gd`.
- Final imported/runtime art: **455 checks**; actor/craft: **200**; presentation/gate: **33**, all zero failures. The existing Godot gameplay suite also passes. The full sequence was completed with targeted final-asset reruns after replacing the exported kit.
  The render review caught a real export failure that metadata tests missed:
  Blender's material inference emitted white primary vertex colours. Explicit
  named-colour export and checks against the authored palette address that
  failure; loader tests also preserve instance material overrides.

Detailed evidence: [generation](../art/cataclysm-generation-2026-09-06.md),
[authored kit](../art/cataclysm-kit-2026-09-06.md), and
[actor/craft](../art/cataclysm-actor-craft-2026-09-06.md).

## Presentation and performance review

The reproducible runner is `tools/cataclysm_review.ps1`; the gallery builder is
`tools/wroughtwild-blender/cataclysm_gallery.py`. Local review output lives in
`build/cataclysm/`, with per-scene stdout/stderr logs. Generated builds and
captures are review artifacts, not source assets for committing.

The completed [local gallery](../../build/cataclysm/index.html) contains **63
stills, 86 walking frames and a linked 518-frame Forge recording**. Seeds 1, 7
and 24 cover different region orientations; seed 1 includes all three continuous
discovery walks and a separate timing pass. The frontal gate view is in seed 24.
The Forge review passed **584 checks**, the three world reviews passed with
zero failures, and the final isolated actor/craft render passed **207 checks**.
Gallery scripts and every image/record link were checked.

World captures use actual generated scenery, 1440 × 900 Forward+, ordinary
1.65 m eye height and matched daylight/dusk positions. Scripted camera travel
and isolated actor studies are labelled accordingly. The Forge review follows
the three real story-session paths with live AI, choices and Foundry effects,
but uses immunity and forced clears: it does not verify difficulty or duration.

The archived v3 gallery is historical visual context, not a matched comparison
against different v4 geography. The old v3 moving route has a controlled
bounded/unbounded scenery-refresh comparison. V4 route timings exclude image
readback; settled shown/hidden scenery samples use the same camera and chunks.

Measured on this Windows desktop / RTX 5090 with other owned test/compiler
processes stopped:

| Measurement | Result | Interpretation |
| --- | --- | --- |
| V4 world setup, seeds 1/7/24 | 4.715 / 5.041 / 4.893 s | Full normal-world setup; new geography is not a like-for-like v3 startup comparison. |
| V4 Fen / Uplands / Rootvault moving median | 1.557 / 1.459 / 1.805 ms | Separate 34–36 m, 5 m/s walks after their views were already presented. |
| Same moving p95 / maximum | 5.553 / 4.797 / 6.114 ms p95; largest 21.935 ms | No image readbacks during timing; does not prove every journey stays within these values. |
| Nine settled shown/hidden comparisons, 600 samples per state | +1.59–6.35% median; +0.76–8.99% p95 | Same pose and visible chunk/resource set for each pair. Includes a longer seed-1 repeat after a short 150-sample woodland result exceeded 10%. |
| Dense Forge: 24 enemies, 8 ignites, 4 Foundry fields | 9.607 ms median / 10.723 ms p95 | +1.74% / +4.31% versus the existing arena with the same cohort, camera and effects; 600 samples, no readbacks. |

### The earlier v3 hitch was investigated, not declared fixed

The unchanged 54 m v3 route was measured with the former full scenery scan and
with the new distant-batch rejection. Results were effectively unchanged:
1.244/1.247 ms median and 3.692/3.701 ms p95. Their frame-2 maxima were
120.946/115.845 ms. Thus the full scan does **not** explain that large spike;
the small spatial rejection remains a bounded-work improvement, not a hitch fix.

The old fixture settles the player while its camera remains at the origin;
the first timed step aims the route camera. A separate diagnostic presented
that exact view for 60 frames with terrain processing paused. The pending
streaming queue stayed at 58 and the chunk job stayed idle throughout warmup.
The 111.731 ms cost occurred during view warmup; the subsequent unchanged
route measured 1.246 ms median, 3.650 ms p95 and 18.683 ms maximum.
An earlier warmup with streaming left active still produced another 124.419 ms
excursion later in travel; its report is retained too. These probes implicate
view/streaming presentation state, but do not identify a particular renderer
operation or establish a runtime fix. First-view excursions remain a known
limitation. The already-presented v4 walks are not evidence of a 120 ms
streaming improvement over a cold v3 camera.

Raw evidence: `render-costs.json`, `cost-1/manifest.json`, each seed manifest,
`v3-perf-{unbounded,bounded,warmed}/manifest.json`,
`v3-warmup-with-streaming.json` and `forge/manifest.json` under the local output.

## Tuning and limits

Native impact counts, dimensions, falloffs, ruin supports and route clearance
are documented in `data/tuning/worldgen.json` and the generation report. The
new `game/art/cataclysm_look.gd` resource explains each presentation control:
ground tint, augmentation growth, visibility distance, wall support tolerance,
burial, fragment scale/exposure, trace width, faceting and quiet regional colours.
`tools/wroughtwild-blender/cataclysm.json` explains authored grain, edge wear,
impact lean, emission and palette. Actor/craft tuning is described in its report.

This is a bounded authored style with controlled facets, not a declaration that
the visual finish is complete. Terrain still reveals its editable voxel origin
in steep places. Six ruin sites and fourteen reusable assets do not imply full
civilisations. Human review must establish whether the relationships read
without captions, the finds feel exciting and the remaining quiet spaces feel
intentional. Existing combat/class and full-run pacing playtests remain needed.
