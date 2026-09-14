# ART-07R7 — fuller habitat at retained anchors

Candidate for integration review. Owner visual acceptance is pending; ordinary-world
rollout is outside scope. This repairs local plant composition within the delivered
anchors. It does not meet the reference's continuous ground cover, change R1's crown
geometry, or claim performance acceptance.

The delivered view uses isolated grass/fern meshes and a sparse procedural shrub.
G1's ordinary ground material override also masks the B4 per-surface wind material.
R7 groups two crossed B2 shrub forms with low fern or bramble, combines sparse/lush
fronds and low grasses, and exposes the intended rooted materials. Thin untextured
leaves gain diffuse backlighting and upward-biased normals so the existing habitat
light can reveal their faces. Ordinary foliage has no scar emission. Textured source
albedo and ORM are retained. The first darker/narrower R7 version was rejected; its
actual renders, settings and diagnostics remain in the package.

## Inspect the actual result

The selected [fullness reference](selected-fullness-reference.png) is the unchanged
ART-07A concept. It supplies layered understorey, canopy overlap and clear-work-area
intent; its mountain, river and home geography are not transferred into this world.

Each comparison sheet places the executed R1 parent on the left and V02 R7 on the
right. Rows are home, route, clearing and oldgrowth habitat, at matched eye/target,
60-degree FOV, 1440 x 900 and 4x MSAA. Eye height is 1.68 m above sampled rendered
terrain. BEFORE images are the actual fresh V01 R1-parent runs, reused byte-for-byte;
they are not described as new V02 runs. Raw PNGs, exact anchor records and execution
receipts are sealed. The light variants are controlled inspection settings, not a
new gameplay lighting rig or a simulation of a full natural day.

| Renderer | Day | Shade | Dusk | Near/middle/far |
| --- | --- | --- | --- | --- |
| Forward+ | [pairs](forward_plus-day-pairs.jpg) | [pairs](forward_plus-shade-pairs.jpg) | [pairs](forward_plus-dusk-pairs.jpg) | [pairs](forward_plus-distance-pairs.jpg) |
| Compatibility | [pairs](gl_compatibility-day-pairs.jpg) | [pairs](gl_compatibility-shade-pairs.jpg) | [pairs](gl_compatibility-dusk-pairs.jpg) | [pairs](gl_compatibility-distance-pairs.jpg) |

[Forward+ rooted motion](forward_plus-rooted-sway.webp),
[Compatibility rooted motion](gl_compatibility-rooted-sway.webp), and the
[actual controller route](native-route.webp) use captured engine frames, with no
interpolation. Live-sway playback follows recorded wall intervals, including capture
overhead. The route uses nominal 300 ms intervals for frames captured every 18 movement
physics ticks; it is not a timing benchmark. [Image provenance](image-provenance.json)
records every input hash, dimension, interval and resize/encoding operation.

Visual inspection: the near fern groups gain layered, recognizable fronds, while
fine shrub leaves replace the older broad cards. Uniform fitting makes some shrub
silhouettes smaller than the old mesh; this improves local form detail without
expanding occupied ground. Compatibility appears colder and less saturated, most
noticeably in shade. Cross-renderer colour balance and the size/detail tradeoff still
need owner visual review. Large bare middle-ground areas remain in every view.

The 2.5/18/72 m captures are horizontal stand-offs from the same existing shrub,
with terrain-sampled camera height. Small grass fades at the unchanged 55 m end/8 m
margin, habitat cover at 75/10 m, and regional fern/shrub at 100/12 m, measured from
the original batch centres. B2 LOD2 remains selected at every range; no new LOD
switch or distant replacement was added. The far view exposes the loss of small
cover. It is not evidence of continuous distant understorey.

## Retained state and gameplay

All four views in both renderers retain exact anchor IDs, counts, poses, building
masks, visibility distances and geography. Every static collision shape matches.
The only permitted raw capture difference is yaw of the upright inspector player's
round capsule; dimensions and position match and all differences remain recorded.
The actual R1 crown bounds, projected overlaps and resource bodies are identical.
These AABB overlaps are conservative geometry measurements, not opaque-leaf coverage.

| View | Anchors | R7 composed anchors | Sampled root contacts |
| --- | ---: | ---: | ---: |
| home-player-height | 25,190 | 16,379 | 15,689 |
| route-player-height | 22,373 | 14,523 | 13,833 |
| clearing-player-height | 22,373 | 14,523 | 13,833 |
| habitat-player-height | 22,424 | 14,855 | 14,165 |

Counts describe each loaded view, not sums of unique world roots. Sampled roots
retain the original 1.5–3.5 cm burial. The independent mesh test passes
73 assertions across 10 composed cases, scanning every
actual vertex at both wind extrema against its old envelope. The maximum measured
root-plane motion is 4.19e-12 m (floating-point
roundoff); there are no vertices outside the old envelope at either extremum.

The actual before/after paid save files are byte-identical (SHA-256
40dfe237742c9058b13098a522802160de1df221895129f6cd421dc86044074d),
and all three raw native snapshots match exactly. The before/after paid runs pass 865/865
original assertions. They walk 135.078/135.078 m
using the actual input/controller route. Gathering travel and placement address
selection are harness-paced; inventory, kit costs, partial work, finite depletion,
source claim transfer, failed-placement retention, chest contents and paid ownership
use native rules. Each has a separate-process restore with all original assertions.
The independent visual route begins at the actual retained paid checkpoint.

Both renderer catalogue cases exercise all 273 legal pairs, including chamfers,
triangles and octagonal roofs, with explicit inspection stock and the existing roof
reward. This stock is separate from the no-grants paid saves. Native physics rays
check ground contact and excavation restoration. Direct standalone startup of that
fixture reports resource preload diagnostics in this candidate; the accepted wrapper
loads the normal sandpit resource graph first, then executes the original fixture.
Both direct failures remain recorded; they are not claimed as passes. The unchanged historical ecology
assertions check real placement, demolition, floor clearing, save restore, chunk
rebuild, excavation and finite stock preservation. Its owned fixture adds an empty
typed history container because G1's C6 adapter expects one in a profile that predates
that subsystem; it adds no historical pieces or geometry. The first error remains
in the package. [Technical checks](technical-checks.json) preserve the raw results.

## Fullness that these anchors cannot supply

All [33 support roles](role-audit.md) are assessed; no all-assets-visible checklist is
used. Six unchanged B2 far sources supply the local groups. Existing sedge, moss,
deadwood, rocks, water, ruins, coloured sources and work states remain. Climber needs
its matching 3.316 m context deadfall, while the retained short deadfall is 1.472 m.
Lichen is a 2 mm sheet and litter about 23 mm thick across roughly 0.95 m; these root
anchors do not provide a fitted terrain surface for either. No floating carpet,
universal ivy, new fungus harvest, river bank or extra tree is introduced.

The union of all eligible original plant envelopes in a 32 x 32 m XZ window gives
this generous upper bound, even counting hidden and offscreen plants:

| View | Envelope intersections | Maximum footprint | Window percentage |
| --- | ---: | ---: | ---: |
| home-player-height | 305 | 62.67 m² | 6.12% |
| route-player-height | 322 | 73.00 m² | 7.13% |
| clearing-player-height | 285 | 64.01 m² | 6.25% |
| habitat-player-height | 305 | 88.91 m² | 8.68% |

This measures transformed AABB footprint, not visible leaf opacity or surface area.
The actual reference-like continuous floor cannot follow from filling these envelopes.
Ground tuft is only 0.300 x 0.158 x 0.296 m; ground fern is 0.520 x 0.246 x 0.389 m;
dry grass is 0.235 x 0.068 x 0.280 m before retained per-anchor scale. The local
shrubs and ferns gain leaf detail, while the middle ground remains sparse.

The [measured proposal](retained-coverage-limit.json) offers accepting this bounded
candidate, or separately authorizing a 2x render-envelope study at the same roots:
tuft at most 0.600 x 0.317 x 0.592 m and fern 1.040 x 0.492 x 0.778 m. That increases
each possible horizontal footprint fourfold before overlap and requires renewed
terrain, sightline, route and building/excavation checks. Another option is a separate
geography/save decision for more anchors or fitted surface dressing. These options
are proposals, not approved changes, and are not implemented here.

## Sources, tuning and costs

Both unchanged packed masters were freshly reopened: groundcover-master.blend
(253 mesh objects; packed 1254² floor and two 2048² images) and shrub-source.blend
(one mesh; two packed 2048² images). Source/master hashes and exact paths are in
[source lineage](source-lineage.json). No source GLB, packed master or map pixels
were edited. Original B2/G1/R1 package bytes remain preserved.

All numerical group fractions and local yaw angles are in [settings.json](settings.json).
Every part shares one root and uses a uniform scale. They are constrained to the old
mesh envelope, not merely its larger table cap. Regional composition occurs only at
batch submission after original placement/support decisions. The tuning controls are:

| Control | Value | Purpose |
| --- | --- | --- |
| lod | `2` | Reuse the published B2 far exports at all existing distances. No new LOD switching or loading policy; inspect near/middle/far views honestly. |
| wind_bend_per_m | `0.018` | Inherited B2/B4 gentle attached sway, 18 mm lateral motion per metre of local height; exactly zero at rooted base. |
| wind_period_s | `5.5` | Inherited B2/B4 5.5 second slow wind cycle, driven by the existing pause-aware environment clock. |
| envelope_inset_fraction | `0.025` | Reserve 2.5 percent on each side of the old anchor envelope for sway, keeping the full deformed visual within the retained clearance envelope. |
| leaf_colour_gain | `[0.85, 0.72, 0.6]` | Inherited B4 warm olive multiplier for untextured ordinary foliage; textured shrub retains its source albedo and linear roughness/metal channels. |
| leaf_normal_up_mix | `0.72` | Blend thin untextured foliage normals 72 percent toward world-up, retaining readable leaf faces in the existing dark habitat lighting without emissive fill or changing the world lights. |
| leaf_backlight | `0.22` | Reuse B4 canopy-style 0.22 diffuse backlighting for thin untextured leaves; no emission or magic on ordinary plants. |

The inherited wind vector is local (1,0,0.35), with phase from the original root
world X/Z. Root height is subtracted before bending. The 0.1 mm envelope comparison
tolerance and root tolerances are numerical verification allowances, not gameplay
clearance changes. Group row fractions are horizontal envelope/height budgets and
yaw in radians; the two existing habitat variants select the two silhouettes.

[Combined world costs](costs.md) report the R1 canopy plus R7 cover in the full paid
world, with before/after frame, geometry and texture costs. They include other loaded
G1 content and hidden resource stages; they are not asset-only budgets. RTX 5090
measurements do not establish minimum-hardware acceptance. R2 loading changes are
not included, and visual improvement grants no independent performance clearance.

Only four parent runtime files change: G1Environment.cover_mesh/_process,
HabitatLook.mesh_for, GroundCover's material binding, and StrangeSites._batch.
The rest of the own delta is the R7 presentation and inspection directory. R1's
105-file parent delta is listed separately. R2 repackages the unchanged consumed
sapling-shrub LOD2 image references; R8 must reconcile that asset packaging and alias
table once, then validate material bindings. No direct R1–R4 file overlap exists
with these four hooks. Exact before/after hashes and functions are in changes.json.

[Execution records](execution.md) identify actual logs and commands. The sealed
package and receipt give exact file count, bytes, manifest hash and reconstruction
commands. This candidate has no owner visual sign-off, combined R8/R9 acceptance,
minimum-device budget, ordinary rollout or new approved geography.
