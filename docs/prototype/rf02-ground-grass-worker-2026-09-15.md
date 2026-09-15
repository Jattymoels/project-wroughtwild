# RF-02 — ground materials and grass

Status: completed and integrated on main as `7c1e3a7`, 15 September 2026.
[Result, checked evidence and normal-game playtest](rf02-ground-grass-result-2026-09-15.md).
Worker `9180001` is adopted; the original work item follows.

Work in `D:/Wroughtwild/work/rf02-ground-grass`, branch
`codex/rf02-ground-grass`. Read `build/rf02/SETUP.md` for the exact main base,
available tools, retained B2 source and copied native DLL. RF-01 is already on
main as `66f3211`. This is its next art iteration, not a replacement game preview.

## Outcome and owner direction

Make the ground pleasant to look at while walking: established meadow turf
with believable soil showing through, and woodland litter/humus beneath the
existing trees. Pair this with fuller, curved, naturally varied grass that joins
the ground convincingly. The result belongs in ordinary New World and Continue.

The owner called the exposed ground texture "icky" and asked about proper grass
through Blender. After the coordinator recommended ground materials first and
grass to match, the owner requested this prompt/worktree. Standing approval
covers reasonable art choices and normal integration. Do not wait for another
concept, visual or performance approval. Do not claim the owner has played or
liked an unseen result. This is a solo indie prototype: prioritise its look,
feel and atmosphere, deliver a useful iteration, and report the remaining gaps.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and follow its
required reading order. Then read only the active dependencies:

- `docs/prototype/reclaimed-frontier-intensive-2026-09-14.md`, especially the
  ground/grass feedback; relevant world-generation sections and D-013/D-030/D-032.
- `docs/prototype/rf01-reclaimed-ground-result-2026-09-15.md`, its selected actual
  images/clip and verification receipt. Reuse this evidence for unchanged work.
- `docs/art/references/environment/2026-09-14-reclaimed-frontier/README.md` and
  `owner-intent.md`. Inspect the relevant meadow/forest originals, especially
  ENV-005/006/008. They convey years of life reclaiming old damage, not a literal
  rendering style or assets to copy. Preserve originals; never use their pixels
  as runtime textures. A labelled smaller inspection derivative is fine.
- `game/scripts/terrain.gd`, `game/art/wildland_look.gd`, `wildland_look.tres`,
  `wildland_terrain.gdshader`, `game/rf01/low_cover.gd`, `low_cover.tres`,
  `cover.gd`, and the R7 material/mesh paths actually consumed.
- B2's receipt and only the relevant grass authoring code/source. Historical
  sealed packages, source reopens and review matrices are evidence, not new tasks.

## Small production sequence

1. **Ground first.** Author a compact meadow turf/soil treatment and a woodland
   litter/humus treatment. Ground between the plants should carry believable
   small detail and broader natural variation, with restrained relief and useful
   joins to existing rock. Avoid obvious repeated tiles, oversized lumpy grain,
   muddy colour noise and embossed stripe patterns at walking height. Use actual
   authored surface maps where useful; choose a modest texture scale/resolution
   and mip handling. Blender baking, retained owned inputs and the available
   original-image authoring workflow are available choices. Apply the relevant
   skill if using image generation. No new paid service, package or third-party
   asset dependency is authorised or needed.
2. **Grass against that surface.** Use the existing Blender workflow to finish
   two useful forms: a fuller meadow clump and a lower asymmetric edge clump.
   Inspect the retained near/mid B2 versions once and reuse useful geometry;
   author new curves/blades where needed. A new pipeline is unnecessary. Avoid
   merely stacking more of the same thin LOD2 crown. Balance blade shape, colour,
   lighting response, quiet wind and rooted joins as a coherent small kit. Keep
   the adopted ferns, shrubs and canopy. Retain editable masters and recipes.
3. **Integrate and show the walk.** Wire the materials/meshes into the actual
   current game. Use the RF-01 seed-77 meadow/woodland route as the useful existing
   segment; its 76.42 m length and missing impact margin are already documented.
   Do not search for a perfect seed, relocate trees or force a new impact view.
   Show enough exposed ground and close grass to judge the requested change.

## Runtime and compatibility boundary

- Target ordinary `frontier_v6`, `living_frontier_wave1` and
  `living_frontier_wave3` geography (later LF policies reuse those identities),
  through the normal production material/cover path. No special showcase switch,
  new world profile, reseeding or migration. Preserve V1–V5 and other biomes.
- Modern ground currently comes from `Terrain._material_for` through
  `wildland_look.gd` into `wildland_terrain.gdshader`; it is a custom procedural
  surface, not a built-in Godot terrain asset. `wildland_look` is also shared by
  older worlds. Scope overrides to eligible profiles and surfaces; do not mutate
  global look resources and unintentionally recolour all worlds. Respect the
  existing world-space/vertex material blending and native augmentation mask.
- RF-01 uses `R7Cover.source` with shipped B2 LOD2 meshes and three crossed grass
  crowns. Change the RF grass source/material binding narrowly; do not globally
  promote every R7 plant or import a high-detail fern/shrub collection.
- Preserve RF-01 seed/profile/cell distribution, reservations, support sampling,
  chunk/edit lifecycle and paid building/station suppression. Prefer fitting the
  new clumps within its current width/height and sway-inclusive bounds. Small
  mesh/material controls are in scope; a new scatter algorithm or larger support
  footprint is not needed for this pass. Never weaken an existing assertion.
- Native heights/voxels/collision, resource/tree/site anchors, excavation, paid
  ownership, octagonal building support, finite stock, saves, progression and LF
  events remain unchanged. Material relief must not imply displaced walkable
  geometry. Keep real exposed soil/rock/cut surfaces readable after digging.
- Keep current streaming, visibility distances, batching and pause-aware wind.
  No new per-frame terrain scans, scheduler, native rebuild or engine upgrade.
  New artistic controls belong in resources/data with plain-language purposes.

Own new files under `game/rf02/` and `tools/wroughtwild-rf02/`, with narrow edits
to the existing material/cover integration points and directly affected docs.
Keep earlier approved assets and source packages unchanged. Retain new editable
source at `D:/Wroughtwild/source-art/rf02-ground-grass` and large scratch/import/
capture/private-save outputs inside this D: worktree. Track selected runtime
assets, recipes, a short source record and compact useful evidence; do not put
Blender builds, caches, credentials or player saves in Git. No parent-package copy.

## Focused verification and delivery

Name the concrete risk before each check. At most three focused jobs, one
renderer (Forward+), no hard ten-minute cutoff or routine permission gate.

1. Import the selected runtime assets and check the changed material/mesh bindings
   for missing dependencies, shader errors, valid rooted bounds and the intended
   eligible-profile selection. Check new maps' import/mip settings as relevant.
2. One short ordinary-world Forward+ walk on the recorded route, with real player
   physics and world work active, in one useful daylight condition. Inspect ground
   texture scale/joins, grass silhouette/rooting, wind and obvious shimmer. Keep
   up to three useful actual viewport stills and one short motion clip. Iterate
   only on concrete visible problems; no baseline/camera/lighting/seed matrix.
3. One short private Continue/load-use smoke through the same production path.
   Reuse RF-01's unchanged ownership/lifecycle evidence. Verify the new meshes
   stay within its checked moving envelope; if a binding/bounds change affects
   suppression, check just the affected paid octagonal floor/station area and
   excavation edge. Do not repeat the full paid economy or campaign fixture.

Use hidden headless jobs where possible. Render with the verified RF-01 no-mouse
capture path, BOM-free no-focus override and `Local\WroughtwildArtRender` mutex.
Keep private APPDATA/LOCALAPPDATA/TEMP on D:. Never seize the owner's mouse or
alter normal play controls. Stop all owned checks before handing back. R9 stays
stopped; PLAY-03 underground diagnosis stays parked for new owner evidence.

Deliver one checked worker commit (or a short clearly ordered set), a concise
result at `docs/prototype/rf02-ground-grass-result-2026-09-15.md`, selected evidence
and exact main-game New World/Continue playtest steps. Start with the achieved
player-visible change, then remaining limits, actual checks and commit/push
status. Embed the actual images/clip in the final chat using absolute paths so
the owner can see them without opening Markdown. Give the source-master paths.
The coordinator integrates/pushes and updates aggregate tracking. Do not start
landforms, other biomes, reviewers or another worker after finishing RF-02.
