# Reclaimed Frontier — terrain and biome composition

**Status: RF-01 through RF-08, including RF-06B, integrated on main, 16 September 2026.
Playable iterations are adopted; the full reference atmosphere remains open.**
[RF-01 meadow and woodland recovery](rf01-reclaimed-ground-result-2026-09-15.md)
adds supported low cover in ordinary V6/LF play. The recovered floor remains
visibly patchy. [RF-02 ground materials and grass](rf02-ground-grass-result-2026-09-15.md)
is now adopted as `7c1e3a7`: finer authored turf/litter surfaces and two original
Blender grass forms respond to the owner's ground feedback. [RF-03 landforms and
inspiring home sites](rf03-landforms-homes-result-2026-09-15.md) is adopted as
`d4aa817`, with four distinct useful settings in fresh normal V7 worlds.
RF-04's local ground correction is adopted as `27fc34d`; RF-05 lakes with simple
swimming are adopted as `5e5de06`. The selected mob-arrival presentation hitch is
now corrected on main as `1bc19e9`; the original underground connection remains
unconfirmed. The owner's subsequent full-roster arrival correction is adopted as
`9dba2fd` on 16 September: [group result](play03-group-arrival-result-2026-09-15.md).
The remaining short group frame is recorded; PLAY-07's pullstone/scenery loading
correction is adopted as `c5ceb9f`: [result](play07-scenery-arrival-result-2026-09-16.md).
[PLAY-06 navigation](play06-navigation-worker-2026-09-15.md) was parked by the
owner on 16 September. [RF-06 fen/lakeside foundation](rf06-fen-lakeside-result-2026-09-16.md)
is integrated as `12238ce` / `710a3c6`: cosmetic planting around existing fen and
V8 lake geography, with no new native generation or save rule. The owner finds
it "definitely underwhelming"; the wetland atmosphere target remains open.
The owner subsequently selected [RF-06B fen art/composition](rf06b-fen-art-worker-2026-09-16.md)
now as a worthy tangent. Highlands and remaining impact/scar composition follow.
A broader all-environment intensive remains later; this continuation addresses
the fen with a small authored kit and a convincing ordinary game composition.
RF-06B is now integrated as `f6131e4` / `046834d`, with a visibly stronger low/middle
layer. The owner requests remaining refinements be recorded for cleanup and
progression to [RF-07 highland recovery](rf07-highland-recovery-worker-2026-09-16.md).
Its scoped brief carries the scene-first workflow forward; full reference
atmosphere and personal owner aesthetic acceptance are not claimed.
RF-07 is now integrated as `1312c20`. The owner agrees with the coordinator that
its atmosphere is only partly achieved and requests moving on. Rock/ground
definition and growth/outlook composition remain cleanup priorities. [RF-08 impact
and living-scar composition](rf08-impact-scars-result-2026-09-16.md) is adopted as
`ef9601b`. Reused 64 passed worker checks; main headless import passed in 4.88 s,
zero errors. The owner approves this good start for merging, while requesting
meatier cracks with different coloured magic pulses deep inside. That physical
depth/colour direction remains unmet; a focused fissure-art production pass is
recommended separately. Bounded cleanup is next in the original sequence;
neither a wider art intensive nor a new worker is automatically dispatched.
R9 stays stopped.

The owner subsequently selected [RF-09 wave cleanup](rf09-wave-cleanup-worker-2026-09-16.md)
and endorsed the next landscape/art direction. They want **more biome types**,
with world generation linking the technology/magic colours to effects on areas,
growth and fauna. This is a connected requirement for the next landscape effort,
recorded in [world premise](../world-premise.md#biome-variety-and-generation-linked-influences--owner-direction-16-september).
Specific biome choices and new influence/gameplay rules need scoping; they are
not added to this cleanup. RF-09 addresses rock/ground distinction, planting
transitions and shaded readability. Its D: worker is started by the owner.

## Sequence protection — owner correction, 16 September

The owner wants the original intent and slice breakdown to remain the main plan.
Raise new ideas/findings, but recommend logging additions and non-blocking bugs
for one bounded end-of-wave cleanup slice. Do not let every new observation
replace the next planned creative outcome. A concrete blocker or explicit owner
reprioritisation can change that; speculative risk and minor polish cannot.

PLAY-07 is integrated. Return to:

1. RF-06 fen/lakeside foundation (adopted; atmosphere target still open).
2. RF-06B fen art/composition (adopted; remaining refinements recorded for cleanup).
3. RF-07 highland character and recovery (adopted; visual weaknesses in cleanup).
4. RF-08 reclaimed impacts and living scars (adopted; deeper fissure art remains open).
5. RF-09 bounded cleanup (selected; owner starts the prepared D: worker).

These are the remaining original landscape outcomes, to be broken into small
playable implementations using the completed RF foundations. Do not retroactively
reopen RF-01–05 or make new generation/feature decisions through scheduling alone.
See the [current cleanup notes](coordinator-status-2026-09-15.md#original-plan-sequence-and-end-of-wave-cleanup).
Compass remains parked; it is not automatically included as a cleanup fix.

## Ground continuity and water — owner feedback, 15 September

After RF-03 the owner dislikes the small bumps between grass in the same biome,
which feel too wavy and unnatural. Preserve the intended broad hills and home
settings; investigate the local surface instead of treating all undulation as
unwanted. [RF-04](rf04-ground-continuity-result-2026-09-15.md) is now integrated as
`27fc34d`: upward faces use their averaged corners to remove extra face-centre
peaks/hollows, a confirmed local geometry cause. Native heights and side contacts
remain. This improves continuity without claiming all steep terracing has gone.

The owner now calls water a must and selected **lakes with simple swimming**.
[RF-05](rf05-lakes-swimming-scope-2026-09-15.md) follows RF-04 with shallow wading,
surface swimming, easy shore exits and dry lakeside places that suggest appealing
bases. Real basins require a separate fresh-world profile; preserve existing
saved worlds and their ownership. Small seas remain a later option. This advances
water from a vague future idea to the required next feature after continuity.

## RF-03 selection — 15 September

The owner agreed to proceed with the landform scope and specifically wants world
generation that creates excitement and creativity about building a base there.
Compose useful, distinctive home settings through outlook, enclosure, natural
edges, approach and extension space. A sheltered woodland pocket, meadow overlook
and gentle terrace can invite different layouts using the existing building kit.
These are ordinary places in the world, not new compulsory plots, bonuses or
prebuilt homes. Preserve the four useful starter cores and supply/opening rules.

The selected implementation boundary is a separate `frontier_v7` generator for
normal fresh random/chosen-seed worlds, at the same 1 km scale. Existing Continue
worlds keep their saved profile/seed/edits/ownership. Keep V1-V6 algorithms and
inputs unchanged, including `worldgen.json` which also supplies the existing LF
tables. Add V7 inputs separately; existing LF launch flags and campaign terrain
events retain their current geography. A future fresh-LF successor is outside
RF-03. V7 uses all applicable adopted art and existing normal-world gameplay.

RF-03 focuses on rolling meadow/woodland landforms, useful connections and
weathered old-impact surroundings. It does not enlarge the world, add hydrology,
live erosion/regrowth, new biomes/resources or a general generator framework.
The worker returns a playable native/Godot change, short home visit/build/Continue
evidence and the matching native DLL. Worker `b8d884c` at
`D:/Wroughtwild/work/rf03-landforms-homes` is complete and adopted as `d4aa817`.
The original brief is retained as history; no RF-03 worker should be restarted.

## Ground and grass feedback — 15 September

After RF-01 the owner asked whether proper grass needs the Blender pipeline and
described the actual ground texture as "icky", asking whether it is native Godot
art and whether it can be improved. Do not record this as visual approval of the
current floor or reopen RF-01's already checked placement work by default.

Inspection found two relevant presentation layers:

- The plants already come from the B2 Blender kit. RF-01 uses R7's shipped LOD2
  (far-detail) mesh, making three progressively smaller crossed crowns for grass.
  Thin silhouettes, colour and bounded cell placement all deserve consideration;
  the distant mesh alone is not a proven explanation of every visible gap.
- `Terrain._material_for` uses `wildland_look.tres` for modern geography, whose
  `wildland_look.gd` selects `wildland_terrain.gdshader`. This is project-authored
  world-space colour/noise, simulated grain and relief. Its augmentation map is
  an influence mask, not an authored turf/soil texture. It is not a stock Godot
  landscape asset. The adopted C1 forest-floor image dresses separate assets and
  does not replace this continuous terrain surface.

**RF-02 scope, requested by the owner:** first improve one meadow turf/
soil surface and one woodland leaf-litter/humus surface, including restrained
apparent relief, texture scale and natural joins to existing rock. Then refine a
small near-view grass kit through the existing Blender workflow: inspect useful
retained near/mid assets, author fuller curved clumps where needed, and tune their
colour, wind and rooting with the new ground beneath them. Keep both in ordinary
play, with retained editable source on D:. No new pipeline infrastructure or
third-party asset dependency is implied.

Preserve native terrain/collision, excavation, resource/site anchors, RF-01's
paid footprint handling, saved worlds and gameplay. Reuse the useful RF-01 route
for a short walking-height visual check and the unchanged gameplay evidence;
target only concrete changed behavior with further checks. No broad camera,
seed or performance matrix. Surface art will not supply the later physical rises
and dips. Give the ground/grass pass priority before proposing those landforms.

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
| RF-01: meadow/woodland recovery | Integrated as `66f3211`; supported low-cover composition, focused lifecycle/use/Continue evidence and a real 76.42 m walk. Still patchy; no impact margin on that route. |
| RF-02: ground and grass art | Integrated as `7c1e3a7`; two authored surface treatments and two Blender grass forms, ordinary V6/LF play and Continue. Clumped cover/hardware cost remain limitations. |
| RF-03: landforms and inspiring home sites | Integrated as `d4aa817`: fresh normal-world V7, rolling land and four distinctive useful home settings. Existing V1–V6/LF saves keep their geography. Small-bump feedback remains open. |
| RF-04: ground continuity | Integrated as `27fc34d`; removes extra V7 top-face bumps, preserving broad landforms, saved native geography and ledge contacts. Steep terracing remains. |
| RF-05: lakes and simple swimming | Integrated as `5e5de06`: one lake per fresh V8 world, wading/surface swimming, easy exits, floating recovery and dry lakeside home space. Static/angular shore edges and no dedicated swim animation remain limits. |
| RF-06: fen/lakeside atmosphere | Foundation adopted as `12238ce` / `710a3c6`. Supported planting delivered; owner finds it underwhelming and visual target remains open. Native terrain/water/saves unchanged. |
| RF-06B: fen art/composition | Adopted as `f6131e4` / `046834d`. Five original Blender forms, joined low growth, distinct rush/fern layers and seeded passages. Broader scene limits in cleanup; owner requests moving on. |
| RF-07: highland recovery | Adopted as `1312c20`. Rock/debris/growth on existing Rocky Hills; useful prototype but atmosphere partial. Owner agrees to move on; refinements recorded for cleanup. |
| RF-08: recovered impacts/living scars | Adopted as `ef9601b`. Recovered margins, supported exposed scars/pulses and actual-game route. Owner approves this start; meatier fractures and recessed coloured magic remain an art follow-up. |
| Remaining original work | Bounded cleanup selected from recorded player-impact notes. Dedicated fissure-art production is a separate recommendation; larger native landforms/all-asset production remain future decisions. |

Scoping evidence: all six owner references and their caveats were inspected,
with image 6 read through a smaller inspection derivative after the image reader
failed on the full-size file. Originals are untouched. Current cover, surface
sampler hooks and building-mask code were read; R7's retained coverage limitation
and PLAY-01's projection finding were reused. No new engine/Blender run, runtime
visual capture, benchmark or source-package reconstruction was needed to scope.
That was scoping evidence; RF-01's delivered images and limits are now in its result.

Worker location: `D:/Wroughtwild/work/rf01-reclaimed-ground`, branch
`codex/rf01-reclaimed-ground`; setup is `build/rf01/SETUP.md`. Worker `85d3ece`
is complete and adopted as `66f3211`. Current standing approval covers ordinary
prototype delivery and main adoption without another visual/benchmark gate.
RF-02 worker `9180001` at `D:/Wroughtwild/work/rf02-ground-grass`, branch
`codex/rf02-ground-grass`, is complete and adopted as `7c1e3a7`.
RF-03 worker `b8d884c` is adopted as `d4aa817`, including the matching native DLL.
RF-04 worker `5c421b3` is adopted as `27fc34d`, including the matching native DLL.
[RF-05's result](rf05-lakes-swimming-result-2026-09-15.md) is adopted from worker
`c3867bf` at `D:/Wroughtwild/work/rf05-lakes-swimming`, including the matching DLL.
Next is the owner's [mob-arrival hitch follow-up](play03-mob-arrival-worker-2026-09-15.md).
Broader biome and coastal ambitions remain backlog; no new landscape wave is dispatched.
Earlier informal references to RF-02 as landform work are superseded by this
ground/grass priority; physical terrain now belongs to the scoped RF-03 above.

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

The original backlog approval preserved this sentiment without selecting new
generation. The later RF-03 work item above now selects a bounded V7 successor;
larger maps, live growth, all-biome production and density targets remain unselected.

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
