# PLAY-02 worker - complete-looking tree canopies

Use `D:/Wroughtwild/work/play02-canopies`, branch `codex/play02-canopies`.
Read `build/play02/SETUP.md` for the prepared current-main base and native DLL.
Reuse that checkout; it contains A1, A2 and the PLAY-01 seam-projection fix.
Current owner depot: `C:/Users/Matty/Dev/project-wroughtwild`. Put new large
outputs, private application data and any edited source copies on D:.
The owner starts this worker; do not launch other workers or reviewers.

## Intended result

The owner reported that tree canopies look as though portions were never created.
Make the affected crowns read as complete, coherent trees in ordinary gameplay,
preserving the established art direction and natural gaps between branches.
Diagnose the visible cause, then fix the smallest relevant asset/material/adapter
problem. Do not simply increase forest density or regenerate the environment.
Owner standing approval applies; human playtesting is deferred, not a gate.

Read current owner AGENTS.md and the required project/design/prototype documents,
reusing prior reading where applicable. Then read the PLAY-02 observation in
`docs/prototype/art-mainline-adoption-2026-09-14.md`, the current
`docs/prototype/coordinator-status-2026-09-15.md`, A1's
`docs/prototype/mainline-art-a1-result-2026-09-15.md`, and only relevant R1 notes.
Old sealed-package, visual-clearance, benchmark and exhaustive-review instructions
are superseded. There is no hard ten-minute cutoff for routine completion.

## Actual starting points

- `game/g1/art.gd` routes existing wood/pine resource families to
  `game/r1/native_tree.gd`. That adapter currently loads
  `res://r1/assets/<broadleaf|pine>-a-lod2.glb` even for close active resources.
  `game/r1/settings.json` records the inherited LOD2 selection, lower trunk fit
  and burial. This is an inspection lead, not a diagnosis that LOD is the cause.
- `game/scripts/resource_canopies.gd` supplies separate distant broadleaf pictures
  from `broadleaf_tree_far`, the resource ledger and terrain detail mask. Inspect
  its transition only if the symptom changes with distance or active streaming.
  Preserve depletion, era and landmark eligibility; do not repopulate felled trees.
- Bog oak, resinheart and ash families have separate C1/C3/C4 adapters. Identify
  the actual affected family and render path before changing them. Avoid a blanket
  tree rewrite if the observed problem is in the common R1 broadleaf/pine crowns.
- Existing representative main-game image: the A1 worker's
  `D:/project-wroughtwild-mainline-art-a1/build/a1/ordinary.png`.
  Use applicable existing evidence before generating more captures.
- Selected R1 source handoff:
  `D:/project-wroughtwild-art07-r1/build/art07-repairs/r1/v03/handoff`.
  Packed masters are `models/broadleaf/broadleaf-master.blend` and
  `models/pine/pine-master.blend`; selected exports and original source copies
  are retained alongside them. Both masters exist. The package is about 5.6 GB:
  do not copy or rehash it in full. Current main is the runtime authority.
- Recipes are under `tools/wroughtwild-art07-repairs/r1/`; provenance and useful
  limits are in `docs/prototype/art07-repairs/2026-09-14/receipts/r1.md`.
  Inspect/copy only a selected master or export if the diagnosed correction needs
  it. Do not rerun the receipt's old full verifier, 19-export audit or camera grid.

## Scope and implementation

Restate which visible crown/family is affected and what appears missing. Inspect
the rendered surfaces and source hierarchy for omitted geometry, sparse selection,
material visibility, culling or transition behavior as relevant. Do not assume an
alpha, normal or LOD fault without evidence. Reuse a suitable delivered model/detail
level if it solves the issue; edit only the necessary source if it does not.

Preserve resource IDs, native spawn locations, counts, work/stock, trunk collision,
targeting, heights, fall and stump behavior, save/Continue and A1/A2 gameplay.
Retain R1's lower-trunk walking clearance while correcting crown presentation.
Keep existing scars/material identity and intentionally broken/dead tree variants.
No new scattering, world generation, player-body change or growth mechanic.
Document any changed art setting in plain language and keep runtime dependencies
inside tracked `game/` paths. Preserve editable source originals; retain any new
editable version on D: with a concise provenance note.

Keep PLAY-01's shared resource-work budget intact. Use shared meshes/textures
where applicable; avoid introducing expensive repeated per-tree/per-frame work.
Do not set up a performance clearance or baseline matrix for this art fix.
If an actual load/use failure or visible new stall occurs, address that concrete
failure. Small unrelated furniture/floor polish remains backlog work.

## Proportionate verification and delivery

Default to three focused jobs, one rendered backend (Forward+):

1. Inspect and demonstrate the reported crown issue in one small representative
   scene/view at player height; include only a short distance transition if it is
   implicated. A useful view or brief clip is enough. No light/seed/camera matrix.
2. Import/load the changed runtime assets and view the corrected crown in ordinary
   game context. Record the actual correction and remaining aesthetic limits.
3. A focused changed-tree lifecycle check: native body/targeting, partial work,
   fall/stump/depletion and restoration as affected. Use one representative per
   changed family; reuse unchanged save/ownership, A1/A2 and PLAY-01 evidence.

For rendered automation use the verified `--r8-no-mouse-capture` path and a
disposable `display/window/size/no_focus=true` override. Assert a visible mouse
and unfocusable window; use scripted camera/input, not the desktop pointer.
Prefer headless checks for state. Remove the override and stop owned processes
before handoff. No new sealed runtime, parent reconstruction or portable build.

Commit the completed checked slice on `codex/play02-canopies`. Return the SHA,
actual in-game change, useful existing/new evidence, remaining issues and exact
normal-main launch/playtest steps to the coordinator for integration and ordinary
push. Update the current coordination sheet/queue and add a concise result.
Do not stage unrelated captures/saves, generated caches or source-package dumps.

PLAY-03 is significant lag underground, not an access defect. Its cause remains
open; do not claim this canopy work resolves it or alter legitimate cave access.
Owner station/campaign playtests remain deferred. The six approved replacement
mob rigs are the next production sequence, one existing role per complete slice.
Keep Reclaimed Frontier landscape references in the future backlog. R9 stays stopped.
