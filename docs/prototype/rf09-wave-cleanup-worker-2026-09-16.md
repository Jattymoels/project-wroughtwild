# RF-09: Reclaimed Frontier wave cleanup

## Selected outcome and setup

The owner selected the proposed single cleanup after RF-01–08 adoption on
16 September: "But let's do the clean up". Finish the current wave by making its
existing landscape treatments read more clearly and form more connected places.
The next major landscape effort will address dramatic landforms/landmarks, more
biome types and colour-influenced terrain, growth and fauna. Record those as next
work; this cleanup does not implement that expansion.

Workspace: `D:/Wroughtwild/work/rf09-wave-cleanup`.
Branch: `codex/rf09-wave-cleanup`. Exact base/runtime: `build/rf09/SETUP.md`.
The owner starts the worker. Do not launch other tasks or subagents.
**RF-09 is this Reclaimed Frontier cleanup, not the stopped ART R9 review.**

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, then this owner-depot prompt and SETUP. Read the RF-06B, RF-07 and
RF-08 assessment/cleanup entries in [the coordination sheet](coordinator-status-2026-09-15.md),
their linked result notes and the relevant presentation sections of
[world generation](../systems/world-generation.md). Use the existing
[art direction](../art/art-direction.md) and [reclaimed landscape references](../art/references/environment/2026-09-14-reclaimed-frontier/README.md)
for intent, not a reason to reopen every source asset or historical review.

## Player-visible target

The owner wants future visual changes to "go big and graphically awe". This is a
bounded cleanup, but the selected changes must be readily visible at ordinary
player height. Prioritise the dominant scene weakness over tiny decorative fixes.
Be honest that cleanup will not supply the future dramatic terrain or deep
fissure artwork. Aim for a coherent improvement across these three related areas:

1. **Readable rock against living ground.** Highland rock faces should have a
   distinct mineral character and visible form against soil, lichen and plant
   pockets. Break the current grey-green merging with deliberate values,
   material definition and restrained weathering. Preserve earthy cohesion and
   variation across faces; avoid uniformly white rocks or new repetitive stripes.
2. **Connected growth and ground transitions.** Soften abrupt planted/bare joins
   at selected existing highland pockets and fen/impact margins using the adopted
   low-growth kits and ground/litter treatment. Identify whether the cause is
   cosmetic spacing, actual access reservations, support rejection or material
   masking before changing it. Preserve usable openings and visibly exposed rock.
   More uniform scatter or simply raising all density values is insufficient.
3. **Readable material in shade.** Leaves and weathered mineral surfaces should
   retain useful shape and colour under ordinary canopy/bank shade. Inspect
   authored colour, normals, material response and local composition. Keep real
   shadow depth, day/night identity and ordinary work/danger cues. Do not turn
   plants/rock emissive or globally flatten exposure to brighten the screenshots.

Use one real V8 seed-77 highland scene as the primary composition, with an existing
fen/bank location to check shared growth/shading changes. Existing RF-08 evidence
can be reused unless the cleanup changes its materials or cover path. Establish
an early actual-game view, correct the most visible cause, then finish the shared
rules. Do not spend the slice selecting perfect cameras. The final result must
apply in ordinary eligible New World and Continue using deterministic existing
biome/context data, never hardcoded capture coordinates.

## Inspected implementation leads

- `game/rf07/stone.gdshader` and `ground.gdshaderinc` currently use similar
  grey-green stone/lichen/soil ranges. `game/rf07/cover.gd` supplies the rock and
  plant materials and derives pocket/rock-edge context. Inspect the actual
  large-outcrop binding as well as shingle; a small debris-only recolour cannot
  solve the dominant rock/ground merge. Colour-space/normal handling are possible
  causes to inspect, not diagnosed defects to assert without evidence.
- `game/rf06/cover.gd` now uses RF-06B meshes/settings. Its footprint checks,
  `regional_clear`, low fringe fallback and passages determine the fen groups.
  `game/rf06b/plant.gdshader` is also shared with highland and impact plants;
  preserve that reuse and audit the affected consumers when altering defaults.
- `game/rf01/cover.gd` supplies common reservation/support handling;
  `game/scripts/strange_sites.gd::_reservations` mixes resource/ruin/route
  protection with cosmetic siting. RF-08 already replaced only its low-cover
  impact blanket with real fragment footprints. Do not undo that correction or
  shrink every reservation. Cosmetic margins may be adjusted only after their
  role is identified; real source/work, route, paid-building and fragment
  clearances remain. Ground-material transitions can join areas where upright
  plants cannot safely fit.
- `game/rf08/context.gd`, `ground.gdshaderinc` and its original creeping mat are
  available for compatible existing impact margins. Preserve the newly fixed
  rejection of unsupported scar geometry after digging. Recessed multi-coloured
  fissures need their own later art/terrain fit; do not expand into that here.

Prefer edits to existing scoped shaders, material bindings and composition
settings. Small asset/material adjustments are allowed where needed for these
outcomes; keep editable source/recipes. Do not create a replacement environment
catalogue, generic graphics framework or overlapping duplicate vegetation pass.
Document new tuning in plain language. Shared heavy resources still prepare at
world entry; no blocking load or unbounded search in movement/spawn callbacks.

## Preservation and exclusions

Preserve native heights/voxels/collision, caves/digging, water/swimming, source
stock/yields, encounters, progression, profile/seed and save schema. No native
DLL rebuild should be needed. Keep V1–V5 presentation and the current eligible
V6/V7/V8/LF boundaries, paid octagonal buildings/stations, native exposed-only
scars, deferred per-tile refresh and existing mob/scenery arrival preparation.
Supported dressing must disappear over excavation and clear actual paid footprints.

The following stay recorded rather than becoming additional cleanup assignments:
new biome catalogue, typed influence distribution or fauna rules, landscape
generation/terrain-mesh redesign, new trees/landmark production, deep coloured
fissure art, physical shoreline changes, dedicated swim animation, floor-slab
cosmetics, compass/coordinates, broad performance investigation and old unassigned
lag. Known residual group/Thrumroot/entry costs stay open. If an actual new
regression appears in the changed path, address it within scope; do not declare
the historic lag solved or launch another benchmark wave.

## Focused verification and delivery

Name the concrete risks before checking: shared materials damaging another
adopted biome, unsupported cover/blocked paid use if placement changes, and
restored worlds losing identity or presentation. Reuse applicable RF-06B/07/08
evidence; do not run all of their suites. Default to at most three focused jobs:

1. Visual development and final short ordinary walk on **Forward+**, with the
   highland as the main scene and one brief fen/bank check of changed shared
   materials. Include an impact still only if a changed path affects it. Retain
   at most three useful final game pictures across the affected settings. Keep
   normal world systems/HUD/lighting; no seed/time/camera/renderer combinations,
   regenerated baseline gallery or performance matrix. Inspect the pictures
   yourself and describe the achieved visible difference honestly.
2. If support/placement/clearance changes, one focused local dig/rebuild and paid
   floor/station/source-access check in the affected path. Preserve full moving
   footprints and actual native identity. Reuse unchanged support evidence when
   changes are purely material; do not manufacture a new test suite for recolours.
3. One short fresh-process Continue/load/use check of the changed presentation,
   with existing paid possessions and saved geography retained. Reuse native lake,
   LF/campaign and generation evidence. No full campaign or all-biome matrix.

Keep all new logs/imports/private state on D:. Reuse the corrected RF-08 launcher
patterns: retained process handle, verified exit code, BOM-free no-focus override
and test-only mouse-capture opt-out. Prefer hidden headless checks where rendering
is unnecessary. Never control the desktop mouse or auto-launch the owner's game.
End owned processes and remove only owned temporary overrides before handing back.
No hard ten-minute cutoff; also no expanding review wave or pursuit of perfection.

Return checked commit SHA(s),
`docs/prototype/rf09-wave-cleanup-result-2026-09-16.md`, actual gameplay pictures
embedded in chat using absolute paths, the remaining limitations and the exact
private PowerShell play command with `-NoProfile -ExecutionPolicy Bypass -File`.
Provide a launcher under `tools/wroughtwild-rf09/` with separate persistent private
slots for the useful retained views; never overwrite owner or prior worker saves.
Use copied test fixtures in this worktree, not live writes to a previous worker.
State what visibly changed, checks actually run, and unresolved visual goals.

Update the coordination sheet to distinguish fixes delivered from notes carried
into the later landscape work. Return the worker commit for coordinator adoption
and ordinary push to main. Stop after this one cleanup. Do not launch the next
landscape/biome intensive, an independent review or the historical ART R9.
