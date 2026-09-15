# RF-07: highland recovery and places worth exploring

## Selected original-plan outcome

On 16 September the owner requested assessment/adoption of RF-06B, remaining
improvements recorded for cleanup, and progression to the next original slice.
RF-07 is that next slice: highland character and recovery. Follow it with the
remaining recovered-impact/living-scar composition, then bounded cleanup. Do not
continue fen/tree/shore polish here or reopen the completed arrival fixes.

Workspace: `D:/Wroughtwild/work/rf07-highland-recovery`.
Branch: `codex/rf07-highland-recovery`. Exact base/runtime: `build/rf07/SETUP.md`.
The owner starts the worker. No automatic parallel workers or next task.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, then this owner-depot prompt. Read the presentation sections of
[world generation](../systems/world-generation.md), the original outcome in
[Reclaimed Frontier](reclaimed-frontier-intensive-2026-09-14.md), and the
[RF-06B result](rf06b-fen-art-result-2026-09-16.md) for the reusable workflow.
Inspect the actual owner reference **ENV-007** in the
[gallery](../art/references/environment/2026-09-14-reclaimed-frontier/README.md)
alongside its caveat and [owner wording](../art/references/environment/2026-09-14-reclaimed-frontier/owner-intent.md).
The mountain reference feels too close to the original catastrophe: carry forward
its scale/rock relationships, but make the place feel weathered and inhabited by
established vegetation years later. Do not copy smoke, fresh craters, a snow line,
enormous new cliffs or exact art style. Existing game geography is the canvas.

## What the player should see

At normal walking height, the highlands should read as a distinct recovered rocky
landscape: worn shelves and settled smaller debris, vegetation collected in
sheltered ground, and open rocky outlooks. The setting should suggest somewhere
to explore or build using existing mechanics, without becoming meadow grass
painted onto cliffs or another scattered-prop field.

Deliver three connected visual outcomes:

1. **Weathered rock with age:** relate existing outcrop/rib forms, smaller rubble
   and restrained surface variation into groups that follow actual shelves and
   slopes. Tie debris to its parent outcrop; keep bare rock faces and exposed
   ground legible. Avoid isolated identical boulders, evenly sprinkled pebbles
   or noisy material detail pretending to be erosion.
2. **Life in suitable pockets:** low tough grass/tussocks, restrained scrub and
   moss/lichen-like surface transitions where ground supports them. Give groups
   clear edges and varied scale, with more exposed rock outside sheltered pockets.
   Adapt visual context from actual local slope/support and existing outcrops;
   no live ecology or weather simulation. Do not transplant the fen reed kit or
   blanket every high slope in lush grass.
3. **An inviting outlook and route:** frame one real, accessible bench or clearing
   with rock/vegetation, preserving open views and usable ground that suggests
   a lookout home or sheltered workshop. Demonstrate an ordinary approach and
   an existing legal paid building/station there. Do not give away a structure,
   add a designated plot/bonus, create a new generated home or grade the terrain.

## Scene-first art iteration

Select one representative supported area in the actual seed-77 V8 Rocky Hills /
Glasswind Uplands, from the generated map rather than assumed coordinates. State
the intended visible change briefly. Establish the material, asset silhouettes
and grouping together in normal gameplay. Inspect one early player-height view
and address the dominant visual weakness before building extensive evidence.

Use the adopted weathered-rock/scree/vegetation kit where it suits the result.
Author a small original Blender addition or local surface treatment if needed
for convincing low growth, rock transitions or complementary shapes. A few
purposeful forms are preferable to an asset catalogue. Reuse does not mean
accepting an inadequate scene; new assets alone do not make a scene convincing.
Retain editable masters/recipes and selected exports under the setup's D: source
location. Use direct modelling or the established local image-to-3D/Blender route
where useful; no new service, dependency installation or external asset purchase.
Follow the imagegen skill if generating a concept/texture, label concepts clearly
and keep actual game evidence unretouched. A concept/gallery is not the delivery.

Generalise the representative treatment into deterministic biome-directed rules
for ordinary New World and Continue. No hardcoded capture-coordinate scenery.
Use actual `rocky_hills` surfaces, including its `glasswind_uplands` region, in
V6/V7/V8 and the existing LF profiles. Altitude alone must not repaint another
biome: region-forced Rocky Hills can occur below the default height threshold.
Keep V1–V5, meadow/forest/fen/ember surfaces and the adopted RF-06B treatment intact.
Local transition dressing must retain that eligibility and not leak into caves.

## Implementation leads and preservation

Already inspected leads, not a requirement for a new framework:

- `game/scripts/strange_sites.gd::_uplands` already groups stone ribs, low outcrops,
  scree and dry sedge around regional shelves. `game/art/strange_ecology.gd` and
  `.tres` hold its composition settings. Refine/reuse those anchors instead of
  stacking a second unrelated set on top. Preserve existing resource/site identity.
- `game/scripts/ground_cover.gd` has sparse Rocky Hills tufts; `HabitatCover` has
  no general rocky-hill shrub/fern layer. `game/rf01/cover.gd` supplies reservations
  and seeded placement; RF-06B demonstrates larger actual-footprint support and
  paid clearing. Reuse applicable pieces without broadening fen eligibility.
- `game/scripts/terrain.gd`, `game/art/wildland_terrain.gdshader` and RF-02/RF-06
  show derived surface masks, chunk refresh and scoped cosmetic ground binding.
  Prefer a small `game/rf07/` module/tuning set and existing hooks. Do not grow a
  generic world-decoration framework or copy every preceding test suite.

This is art and composition on existing geography, not a new terrain-generation
contract. Preserve native heights/voxels/collision, caves and digging, water,
finite nodes and yields, encounters, progression, world identity and save schema.
No new profile, reseeding, saved decoration owner, mountain uplift, cliff carving,
snow biome, ambient weather, enemy or progression/resource rule. Retain existing
physical scars and site cues; the separate impact/scar slice follows this one.

New shallow decorative accents follow actual support. They must not imply a
standable shelf above empty air, bridge a hole, obstruct resource approaches or
survive through paid floors/stations. Preserve octagonal support and both LF
terrain publication boundaries using current refresh paths. Keep ordinary legal
building space open. Do not globally reduce reservations to get a fuller picture.
Keep global lighting, camera/exposure and unrelated trees/materials unchanged.

Prepare/reuse shared meshes/textures/materials at real world entry; preserve the
mob/scenery arrival improvements. Use existing chunk batches/lifetimes and
bounded placement queries, rather than per-frame whole-world scans or blocking
resource loads during movement. Document new tuning by its visible purpose.

## Focused delivery checks

Concrete risks: unsupported cosmetic shelves/growth, blocked access or paid work,
leakage to other biomes/caves, and refresh/Continue changing owned state. Reuse
unchanged RF-06B/RF-05/arrival evidence. Default to three focused jobs on Forward+:

1. Changed placement/support and paid clearing: actual new footprints, local
   excavation and rebuild, one affected octagonal floor/station and biome
   boundaries. One inexpensive seed-variation/determinism spot check can sit here;
   no seed/renderer/material matrix or full native regression suite.
2. One fresh-process Continue with unchanged native world identity, finite-source
   work, possessions/structures/stations and restored cosmetic treatment. Reuse
   applicable campaign evidence instead of replaying LF.
3. One short actual player-height walk through the rock/vegetation transition to
   the selected outlook, including ordinary access/use. Retain roughly three
   useful game pictures and a short motion clip. Inspect the pictures yourself
   against the three visible outcomes. Make an early look during art development;
   replace it with final evidence after meaningful edits, not a camera matrix.

First import of this fresh worktree is setup, not a reason to copy/rebuild a
parent package. Keep logs/import/temp/private saves on D:. Use background Blender,
hidden headless checks and verified no-focus/mouse opt-out for rendered work.
Write temporary overrides BOM-free, retain process handles and end owned checks.
Do not seize the owner's mouse or run their normal save in automation.

Deliver a meaningful highland visual iteration, not perfection. Describe the
achieved appearance and remaining weaknesses separately from functional checks;
never infer aesthetic approval or smoothness from a test count. Record incidental
improvements for the end-of-wave cleanup and stop after RF-07.

Return checked commit SHA(s), a concise result at
`docs/prototype/rf07-highland-recovery-result-2026-09-16.md`, actual game pictures
embedded in chat using absolute paths, editable source/recipe paths, remaining
limits and the exact private playtest command using
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...`.
The launcher must preserve existing private progress and ordinary owner saves.
Coordinator integrates/pushes main. Do not start impact/scar work automatically.
