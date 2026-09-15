# PLAY-07: remove the measured scenery arrival stall

**Completed and adopted:** worker `29e90e4` is integrated as `c5ceb9f` on
16 September. See the [result and remaining limits](play07-scenery-arrival-result-2026-09-16.md).
This brief is historical; return to RF-06 rather than restart a performance task.

## Approved outcome and workspace

On 16 September the owner parked compass/coordinates and agreed to the sequence:
fix the measured scenery-loading hitch, then return to fen/lakeside atmosphere,
with highland character as a later separate slice. This worker owns the first
step only. Deliver the correction into normal play, preserving the complete
approved scenery, finite resources, saves and the completed creature fixes.

Continue the existing idle task **Diagnose mob arrival hitch** in
`D:/Wroughtwild/work/play03-mob-arrival`, branch `codex/play03-mob-arrival`, starting
at `43e7cf3f24933999630fefe65d505104cda31188`. The directory name is historical;
do not create another checkout or reset/merge the branch. Read
`build/play07-scenery/SETUP.md` and the current owner-depot AGENTS.md, following its
required reading order. This owner-depot brief controls over older copied docs.
Prior worker commits are already adopted on main; return only new commit(s).
The owner starts this worker. Do not start another task, navigation or biome work.

## Evidence and concrete question

Reuse the [full-roster result](play03-group-arrival-result-2026-09-15.md) and its
[compact evidence](../../tools/wroughtwild-play03-group/evidence/summary.json).
The final mixed-group run's approach frame 113 measured **106.840 ms**, with
**99.276 ms** in `resource_arrival_visual = pullstone` and **99.289 ms** in the
resource tick. Physics callbacks were 1.299 ms, chunk tick 2.246 ms and observed
draw wall 1.970 ms. These nested spans are not additive. Full trace:

`D:/Wroughtwild/work/play03-mob-arrival/build/play03-group/after/play03-2026-09-15T23-04-23-66220-1957084.json`

The earlier before-group recovery also contained 104.571 ms pullstone creation;
its 237.240 ms full frame included other work. The retained synthetic relocation
and settling costs are separate. Do not use them as ordinary walking evidence.
This establishes an expensive resource arrival, not whether loading, conversion,
material binding, source-state lookup, repeated construction or first draw causes
it. Time the actual path before selecting a remedy. No new owner reproduction is
required and no whole-group baseline reconstruction is needed.

Useful inspected starting points:

- `game/scripts/resource_stream.gd`: `materialise()` retains the ResourceNode
  PackedScene, creates a G1Art resource, applies saved fields, adds it to the tree
  and refreshes work state. Existing ordinary scheduling has a 2 ms soft build
  budget; it cannot interrupt one expensive node. Reducing the node cap alone is
  not a correction for one 99 ms creation.
- `game/scripts/resource_node.gd`, `game/scripts/strange_resource_art.gd` and
  `game/g1/art.gd`: actual resource/visual dispatch and scene-entry behavior.
- `game/f3/visuals.gd`: pullstone/ventlung source attachment, near/middle/far GLB
  acquisition, material binding and source state. Its source and crafted fixture
  paths share helpers. F1 supplies lanternheart/stormglass and F2 thrumroot; inspect
  these only as needed to account for the same demonstrated loading pattern.
- `game/scripts/authored_assets.gd` if the resource's fallback/shared mesh path is
  involved; locate actual resources before assuming obsolete adapters are active.

These are inspection leads, not a predetermined diagnosis or an instruction to
rewrite all scenery. Consult the relevant resource/world specification and the
small scheduling contract in [INT-07E](stream-scheduling-2026-09-07.md), not its
historical large evidence matrix. Keep the existing safety/ownership boundaries.

## Small complete implementation

1. Reuse the existing route, retained trace and bounded recorder. Add narrow
   opt-in subspans sufficient to identify the expensive resource phase. Capture
   first use in a fresh process through real New World or validated Continue,
   then ordinary movement; disclose any initial staging and keep it outside
   measured travel. Include the resource's first display and a short recovery.
   Keep normal streaming, world simulation and approved quality enabled.
2. Correct the demonstrated cost using existing engine/resource practices.
   Retain reusable PackedScenes/meshes/material templates where appropriate,
   prepare suitable shared resources during actual loading before control release,
   or use bounded asynchronous preparation with readiness where justified.
   Do not hide warming in a test fixture or move the same freeze earlier in play.
   Inspect both first and repeated attachment when deciding what can be reused.
3. Apply the same fix to sibling scenery paths that demonstrably share the cause.
   Account for the five rare-source families and the shared F1/F2/F3 helper paths
   in a compact coverage note. Existing safe paths can reuse evidence. Do not
   knowingly leave an identical omission for a separate one-specimen worker, but
   do not expand into every tree, station, resource, seed or renderer without an
   observed shared cause. Preserve the 13.050 ms creature group creation result.

Aim to remove the roughly 100 ms source-creation stall, keeping ordinary arrival
work within the existing stream budget where practical. Measure any residual;
do not stop after a small saving while an actionable dominant cause remains.
Report full-frame cost honestly; resource timing alone is not a smoothness claim.
If batching remains the issue after shared work is removed, justify any scheduling
change and preserve cancellation, once-only creation and immediate safety paths.

Report where work moved: actual entry/preparation duration, repeat-call behavior,
retained resource set and startup/residency tradeoff. No mandatory RAM/VRAM sweep,
generic asset manager, hidden quality downgrade or new gameplay tuning is needed.
Do not introduce script-time preload cycles; ResourceStream documents one already.

## Preservation and focused checks

The concrete risks are altered rare-source geometry/state, shared materials
leaking between specimens, saved partial work/depletion being overwritten, and
startup/restore exposing unprepared resources. Preserve IDs, positions, LODs,
visibility distances, collision, harvest stages, tool/heat/work requirements,
finite quantities, source depletion, paid devices/buildings and native ownership.
Keep the same world profiles, RF-05 lakes/swimming and all three creature fixes.
No reduced scenery or mob counts, no changed activation ranges and no save fields.

Default to three focused jobs on Forward+: (1) causal first-use diagnosis using
the retained route/evidence, (2) the corrected ordinary approach/first display and
short recovery, (3) a compact changed-resource lifecycle check including partial
work, unload/reload, depletion and fresh Continue as relevant. If caching changes
source/device helpers, check independent animated/work materials and one affected
crafted fixture. If preparation changes world entry, verify its real New World/
Continue placement. Reuse existing creature, lake and unchanged native evidence.
Do not rerun old broad resource-presentation, campaign or matrix suites by default.
Another focused check needs a concrete change/failure, not a new review phase.

Follow current AGENTS.md: no hard ten-minute stop, no exhaustive matrix and R9
stays stopped. Keep tests hidden/headless where possible. For rendered work reuse
the verified `--r8-no-mouse-capture`, BOM-free UTF-8 no-focus override, retained
process handle and `Local\WroughtwildArtRender` mutex. Never move the pointer,
seize focus, stop owner processes or leave owned tests running. No per-frame disk
writes/readbacks during timing; preserve explicit recorder overflow reporting.

## Delivery

Use `build/play07-scenery/` for all new reports, private state, logs and captures.
Keep existing imports and `build/play03-*` evidence. Reuse the inherited RF-05 DLL;
no native build/package reconstruction is expected. Commit only source, small
useful evidence and the result at
`docs/prototype/play07-scenery-arrival-result-2026-09-16.md`. Report the cause,
actual change, covered shared paths, timings/cost transfer, checks, remaining
limits and exact new commit SHA(s). Do not claim an unrun check passed.

Provide a private owner-invoked launcher if the existing approach is insufficient,
with process-scoped PowerShell Bypass and simple visible directions; compass is
parked. Name the save slot and any fixture-only items/pose. Never overwrite owner
saves or existing private progress. The coordinator will adopt/check/push the
completed continuation; do not merge or push main from this worker. Stop after
this slice. The residual mixed-group frame, underground correlation and unrelated
world-entry cost remain separate unless evidence directly connects them.
