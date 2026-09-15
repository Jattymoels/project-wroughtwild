# RF-04 — natural ground continuity

Status: worker `5c421b3` integrated on main as `27fc34d`, 15 September 2026; see the [RF-04 result](rf04-ground-continuity-result-2026-09-15.md). Retain this brief as history; do not restart RF-04.
Worktree: `D:/Wroughtwild/work/rf04-ground-continuity`.
Branch: `codex/rf04-ground-continuity`. Read `build/rf04/SETUP.md` for the exact
base, inherited native DLL and build inputs. The coordinator adopts the finished
checked commit and matching DLL into main and pushes under standing permission.

## Outcome and reading

The owner reports that the bumps between grass of the same biome feel too wavy
and unnatural. Make the nearby meadow/woodland ground read and walk as a coherent
surface while retaining RF-03's broad hills, enclosing banks, outlooks and useful
home settings. This is the requested visual/feel correction, not a polish audit.
Do not flatten the landscape or claim that RF-03's earlier steep approach fix
already resolved this feedback. Owner playtesting remains deferred.

Read the current owner depot's `AGENTS.md`, follow its required reading order,
then read the RF-03 result, current coordination sheet and only relevant terrain,
movement, building and save specifications. Keep the reclaimed-landscape references
and owner sentiment in view. RF-01/RF-02 art and RF-03 gameplay are already adopted.

## Diagnose one patch, then fix the actual cause

Start with the seed-77 meadow approach between the woodland pocket `(503,420)`
and overlook `(607,508)` in the [RF-03 result](rf03-landforms-homes-result-2026-09-15.md).
Separate native height variation, derived surface geometry/collision, and apparent
relief from normals/materials. Inspect a small adjacent-cell patch at walking
height and correlate it with the local native heights and triangles. Do not
rebuild the whole RF-03 route or run a seed/camera matrix to find perfection.

One concrete lead is `build_world_chunk` in
`game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp`: the faceted surface
fans triangles between averaged corner vertices and a face centre kept on the
original voxel plane. On quantised slopes this may create local scallops.
It is a hypothesis, not a confirmed diagnosis. Check `Terrain`, `SurfaceSampler`,
`wildland_terrain.gdshader` and RF-02 ground relief only as needed to distinguish
geometry from shading. Report what was actually responsible and what remains.

Implement the smallest useful correction in the current normal V7 surface path:

- Keep native V7 heights, blocks, seed/profile identity and resource/site anchors
  unchanged. Preserve the RF-03 broad landforms and four level home cores.
- Mesh and collision must agree. Preserve triangle-to-source-cell mapping for
  digging, chunk joins, actual holes and edit refresh. Do not hide a geometry
  defect by making collision diverge from the visible ground.
- Keep paid floors, triangular octagonal corners, stations and player movement
  supported. Ground sampling and RF grass roots/paid-footprint clearance must
  still follow the usable surface. Handle any concrete changed contact locally.
- Preserve V1–V6/LF behavior; scope a new mesh/material mode explicitly to V7
  where needed. Do not silently reshape old saved worlds through a global edit.
  Existing V7 Continue receives the compatible surface correction without
  changing its native geography or paid ownership.
- If the remaining cause needs different native geography, record that finding
  for the fresh lake successor rather than mutate V7 generation under saves.
  Deliver a useful safe surface correction if possible; be candid if the
  underlying diagnosis prevents one. Do not invent a fake visual success.
- Retain the existing bounded chunk/streaming work. No world-wide scan, new
  framework, speculative performance repair or unrelated controller rewrite.
  Put any new controls in the relevant tuning resource and explain their feel.

## Focused verification and delivery

Name the concrete risk before each job. Default to these three focused jobs,
one renderer (Forward+), reusing unchanged RF-03 evidence:

1. A small cause/continuity fixture for adjacent cells, a chunk boundary and one
   local dig; confirm native identity and the surface/source-cell relationship
   for the changed path. Do not repeat full legacy runtime-map comparisons when
   their source/input paths remain unchanged.
2. One short ordinary walking-height Forward+ pass through the affected patch,
   showing the broad landform and local surface in a few screenshots and a short
   motion clip. Assert the established test-only mouse-capture opt-out and use
   a non-focusing window; no desktop pointer automation.
3. Reuse a private RF-03 paid-home save for a focused Continue/use check of actual
   floor/station support, movement, local dig and cover clearance. Preserve
   ownership; reuse unchanged gathering/cost/generator evidence.

Imports/build setup belong within this focused work. There is no hard ten-minute
cutoff and no permission gate for ordinary completion, fixes, commit or handoff.
Do not reopen R9, baseline packages, Blender masters or broad renderer/seed
reviews. Keep outputs, imports and private test state on D:. Do not touch owner
saves, the C: runtime DLL, app settings, remote access or another task's process.

Build the native DLL only if native code changes; otherwise retain the inherited
RF-03 DLL. Use the existing Godot ABI inputs recorded in SETUP; no dependency
rebuild or new third-party asset. Commit source, tuning and selected evidence,
not binaries/caches. Report the source commit and matching DLL hash/path.

Write `docs/prototype/rf04-ground-continuity-result-2026-09-15.md` with achieved
gameplay, diagnosed cause, remaining limits, checks actually run, tuning and
exact ordinary New World/Continue playtest steps. Embed selected images/clip in
the final chat using absolute paths. End owned jobs, commit the checked slice,
and stop for coordinator adoption. [RF-05 lakes and simple swimming](rf05-lakes-swimming-scope-2026-09-15.md)
is next; do not start it in this worker.
