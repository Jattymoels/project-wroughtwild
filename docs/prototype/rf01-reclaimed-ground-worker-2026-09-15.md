# RF-01 — meadow and woodland recovery

Status: implemented, checked and integrated on main as `66f3211`, 15 September
2026. See the [result](rf01-reclaimed-ground-result-2026-09-15.md)
for the achieved coverage, retained checks and limits. The original scope follows.
The owner agreed to scope the first Reclaimed Frontier slice after the completed
art/adoption and PLAY-05 batch. Standing prototype approval applies; the owner
starts this worker from the prepared prompt. Do not automatically launch workers.

Work in `D:/Wroughtwild/work/rf01-reclaimed-ground`, branch
`codex/rf01-reclaimed-ground`. Read `build/rf01/SETUP.md` for the actual main base
and unchanged native DLL. The coordinator integrates and pushes the checked result.

## Player-visible outcome

An ordinary walk from grassy open ground toward woodland feels like established
life has recovered around old impact damage. Connected low growth carries the
eye between existing trees and shrubs. Open ground, gathering access and exposed
old scars remain legible. Deliver this first visual treatment in the normal game,
with a short existing route to show it, then improve it through later playtests.

Use the six original owner references and their caveats, not a literal image copy.
Images 1–2 suggest layers and open space but are too styled to copy. Images 3–5
need more recovery and less fresh/exposed crater emphasis. Image 6 supplies
ground-level undulation and life. Most plants stay unlit; existing scars keep
their native meanings. No fresh meteor shower, universal smoke or new wildlife.

## Scope settled for this first slice

| In RF-01 | Boundary |
| --- | --- |
| Low meadow grass and forest-floor fern/grass composition | Reuse the shipped B2/R7 assets and materials; change decorative coverage, distribution and grouping where needed. |
| Ground-level transitions around existing old damage | Use supported grass/forest-floor surfaces, adjacent clear ground and existing trees/scars. Do not grow a meadow over exposed bedrock or fill a hole visually. |
| One small visual treatment, one representative walk | About 80–150 m is a useful target, not an exact distance gate. One seed, meadow/woodland and an existing impact margin; no camera/seed search programme. |
| Normal playable adoption | Apply deterministic meadow/forest dressing in eligible current-world chunks, not only in a showcase, a hard-coded camera corridor or one privileged seed. |
| Native geography and ownership | No height/voxel edits, collision changes, relocated harvestable trees/resources, moved impact/lab/home sites, yields, spawns or save migration. |

Do not add or relocate canopy trees, large rocks, ruins or collision props in this
slice. Existing shrubs/canopies provide the upper layers. Fen, mountain and ash
biome treatments, new crater shapes, terrain undulation algorithms, erosion,
live regrowth, distant terrain replacement, era creature forms and boss art stay
outside RF-01. Do not enlarge this into the whole Reclaimed Frontier intensive.
No engine upgrade, new package, external asset generation or native rebuild.

## Read before implementation

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and follow its
required order; reuse unchanged prior reading. Then read:

- `docs/prototype/reclaimed-frontier-intensive-2026-09-14.md`, especially the new
  RF-01 selection; D-013/D-030/D-032 and the relevant world-generation sections.
- `docs/art/references/environment/2026-09-14-reclaimed-frontier/README.md` and
  `owner-intent.md`, and inspect all six originals. Preserve them unchanged. If a
  large original cannot be displayed, a labelled inspection-size derivative is
  fine; retain the original, and never put reference pixels into runtime assets.
- Current `GroundCover`, `HabitatCover`, `Terrain`, `StrangeSites`, `SurfaceSampler`,
  `game/art/frontier_look.gd`, `game/art/wildland_look.tres`, `game/r7/cover.gd` and
  the few B2 roles actually reused. Read only their relevant paths.
- The R7 receipt's coverage limitation and PLAY-01's expensive projection finding;
  reuse those findings, not their historical review/package programmes.

R9 stays stopped. PLAY-03 underground investigation is parked for the owner's
next playthrough. Unavailable human station/campaign feedback is not a blocker.

## Why this scope is useful and feasible

R7 explicitly fits fuller plants inside the old narrow envelopes and creates no
new anchors. Its retained evidence says continuous cover was not achieved;
6.12–8.68% describes four historical windows, not current world-wide coverage.
`GroundCover` selects individual eligible surface cells, then fits small meshes;
`HabitatCover` adds sparse shrub/fern patches with clearances. Filling out each
old tuft alone cannot establish the connected lower layer in the references.

RF-01 may add/change **cosmetic** plant roots and their supported footprints for
the selected meadow/forest treatment. Native resource anchors remain frozen.
Keep R7's old envelope assertions valid for unchanged R7 uses; do not weaken
them to accept new RF footprints. Use a narrow RF settings/helper path or an
explicit per-profile input to the existing cover builder. Do not mutate shared
global look resources in a way that changes unrelated biomes/worlds.

Reuse `game/b2/assets/grass-meadow-lod2.glb`, `grass-edge-lod2.glb`,
`fern-sparse-lod2.glb` and, if useful, `fern-lush-lod2.glb`; keep the existing
runtime material bindings. No need to reopen/repack every editable source.

## Compatibility and placement contract

- Enable the new presentation for `frontier_v6`, `living_frontier_wave1` and
  `living_frontier_wave3` geography. Later LF campaign policies reuse those
  geography identities: use actual terrain profile, not a guessed policy name.
  Keep V1–V5 and other biomes' presentation paths unchanged. This is not a new
  generator profile or a change to the normal campaign selection.
- Existing eligible saves receive updated cosmetic dressing on load/streaming.
  Their seed, heights, edits, collision, paid structures, finite/depleted resources,
  source/machine ledgers and campaign events stay authoritative. No extra saved
  cover array, schema field, refund or clearing payment. A new-world test and a
  Continue test must use the same ordinary production path.
- Derive placement deterministically from existing seed/profile/cell coordinates
  and a dedicated visual salt. Do not consume gameplay RNG or rely on camera/time
  to decide which plants exist. Rebuilding an unchanged chunk restores the same
  dressing. Cache by all relevant inputs and clear transient state on world change.
- Root plants to existing sampled surface triangles. Check the footprint of any
  enlarged/grouped plants at ledges and voids; avoid long repeated terrain scans.
  Excavation must remove unsupported cover, not make a grass lid over a hole or
  project cover onto a cave floor. No shader displacement that changes perceived
  ground height away from actual player support.
- Keep existing clearings, home/ruin/lab approaches, source/harvesting work areas
  and combat sightlines useful. Reuse reservations and actual saved building
  footprints, including octagonal pieces and stations; a point/root-only mask is
  insufficient for a larger plant group. Support and suppression bounds must
  cover the displayed footprint, allowing for existing sway.
- Keep the existing chunk publication, retirement and local edit/build refresh
  path. Retain the `terrain_cover` transforms/bounds metadata used by
  `StrangeSites` so paid building hides overlapping cover, removal can restore it,
  and Continue reapplies ownership before cover becomes visible. Do not add a
  permanent vegetation scan or a new scheduling framework.

## Small execution sequence

1. Select one existing current-main seed/route using native map/site information.
   Start with seed 77 (existing home/scenery evidence) and choose a useful nearby
   meadow/forest/old-impact margin. Record actual seed, coordinates, route and
   normal-game directions. If those qualities are not all adjacent, use the best
   single nearby representative segment and state the missing visual beat; do
   not reshape the world or search many seeds to produce a perfect composition.
2. Implement the low-cover treatment with a few meaningful controls: patch scale,
   sparse/dense coverage, plant width/height and meadow/forest mix. Start from
   current draw distances and the reused assets. Put changed values and each
   player-facing purpose in RF settings/resources. No numerical coverage quota,
   minimum-hardware target or artificial count of plants defines visual success.
3. Finish the production placement/edit/Continue behavior and show the achieved
   walking-height result. If terrain shape still limits the desired undulation,
   name that limit for RF-02; do not silently change geometry or hold this usable
   vegetation slice for a new generator. No human review gate before adoption
   under standing approval; distinguish deferred feedback from actual acceptance.

## Three focused verification groups

Name the concrete risk before checking. No hard ten-minute cutoff, no broad
baseline or renderer matrix, and no repeated package reconstruction.

1. **Placement/lifecycle:** one small fixture spanning ordinary slope/edge and a
   chunk boundary verifies deterministic rebuild, supported footprints, a real
   excavation, and local hide/restore for one paid octagonal footprint plus a
   station/work area. Reuse existing `scenery_grounding` / `placement_scenery`
   helpers; do not rerun their entire historical world/shape catalogue. Check a
   representative excluded-profile/biome selection at helper level if modified.
2. **One Forward+ walk and visual check:** short real controller movement along
   the recorded current-world route, in one useful natural lighting condition.
   Native physics/world work stays active. Keep up to three stills and one short
   motion clip, show them inline in chat. Record visible gaps/limits; no 24-camera
   programme or before/after benchmark. Diagnose only an observed load/use failure
   or obvious regression encountered here. Unmeasured hardware is a limitation.
3. **Ordinary use/Continue smoke:** one focused paid build/resource use and saved
   reload checks changed cover placement and exact existing ownership through the
   normal game path. Reuse one prepared private world; no full campaign, broad
   save matrix or replay of all fauna. Import/setup belongs to these checks,
   not a reason to launch extra review groups.

Default to hidden/headless for nonvisual checks. A rendered job holds
`Local\WroughtwildArtRender`, uses verified `--r8-no-mouse-capture` and no-focus
behavior, and writes temporary overrides as BOM-free UTF-8. Reuse the corrected
MOB-06 runner's process-handle/exit pattern. No desktop mouse automation. End
owned processes and remove only owned temporary overrides before handoff.

## Delivery

Own scoped cover integration and `game/rf01/` settings/helpers if needed,
`game/tests/rf01/`, `tools/wroughtwild-rf01/`, and
`docs/prototype/rf01-reclaimed-ground-result-2026-09-15.md`. Keep imports, clips,
logs and private APPDATA/LOCALAPPDATA/TEMP/saves on D:. Commit only needed runtime
code/assets, compact selected evidence and the result; preserve unrelated work.

Return the checked worker SHA with what changes in ordinary play, the actual
route, tuning purposes, checks run, visible/technical limits and commit/push
status. Show the selected images/clip directly in chat. Give exact New World and
Continue playtest instructions, including existing LF launch options if relevant.
The coordinator owns main integration, aggregate queue updates and ordinary push.
Do not start RF-02, mountain/fen production, era mobs or another reviewer afterward.
