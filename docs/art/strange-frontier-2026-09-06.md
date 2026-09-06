# The Strange Frontier implementation — 6 September 2026

The owner-approved [work item](../prototype/rare-world-intensive-2026-09-06.md)
is implemented in the normal Godot world. New worlds select `frontier_v3`;
existing saves retain their profile and geography. Normal human playtesting of
discovery, travel and practical usefulness is still outstanding.

## Playable changes

- A finite 512 × 512 m map with Rootvault Wildwood, Lantern Fen and Glasswind
  Uplands. Broad native region masks and approaches precede the local art and
  finite rare sites. The earlier quarry, fen and grove material habitats remain.
- Lanternheart, Thrumroot, Stormglass, Pullstone and Ventlung have visible clues,
  contextual work stages, finite first hauls, use previews and harvest aftermath.
  The inventory's Build guide → Wild finds tab explains properties and uses.
- Six workbench kits add lamps, cargo winches, ordinary landings, pulse levers,
  magnetic sorters and pressure bellows. Build placement, previews, contextual
  controls, contents, full rare-core refunds and saved state are connected.
- A wound winch responds to a linked lever, carries one basket between supported
  endpoints and pauses at blocked spans. Save/load preserves its cargo, energy
  and progress. Sorters use only hand-fed ordinary stacks. Bellows reuse the
  existing resource impact response. Devices pause during trials.
- Repeatable Forge boss completion adds one component previewed with the
  existing material target. It neither rerolls saved offers nor changes item
  quality. Failed runs and early extraction do not receive this completion haul.

## Compatibility and ownership

`worldgen_frontier_v2.inc` and `worldgen-frontier-v2.json` freeze the previous
profile alongside the existing legacy snapshots. Live v3 generation cannot move
their terrain, resources, pack positions or landmarks. Profile-less saves remain
legacy. Resource scenes are now a view of saved logical records in v3: unloaded
resources retain remaining units and partial work; depleted resources do not
return. Terrain queries retain profile identity and exact saved excavation.

Native contraption rules own each stack once, including baskets in transit.
The engine certifies support, span clearance and nearby work targets. Validation
precedes checkpoint mutation; the existing atomic file replacement retains the
last good save on failure. Dismantling includes contents and refunds in one
transaction. Purse entries and equipment instances cannot enter machine stacks.

## Verification

Run native checks from `tests/sim`: `make test world-intensive strange-frontier
contraptions`. On Windows, the existing Makefile requires a POSIX shell; use
the installed Git Bash shell with the local WinLibs compiler.

The final native build passed 36,589 main checks, 595,376 older-world checks
and 91 contraption checks. The new-world matrix below is separate from those
older-world assertions.

After rebuilding the pinned Godot 4.5 extension, run
`powershell -File tools/codex_visual_review.ps1 -Checks`. The regular pipeline
now includes `strange_frontier`, `terrain_stream_intensive`,
`contraption_intensive`, `strange_art_review` and `strange_frontier_review`
alongside previous regressions.
Rendered review fixtures write images and playback frames under the ignored
`build/strange-frontier/` directory; authored source and curated GLBs live in
the normal local Blender kit and `game/assets/authored/`.

The native 64-seed new-world matrix passed 2,201,784 assertions, including
reachability, work-space guarantees, finite population and both old profiles'
fingerprints. The generated Godot fixture passed 7,067 checks of actual resource
scenes, partial work across unload/restore, recipes and atomic save files. The
terrain fixture passed 49,837 checks, including excavation during a partial
creation job, exact collision after restoring a distant player position and
regional dressing before and after nearby chunks arrive. Contraption integration
passed 85 checks, including refusal of invalid item types and atomic core/cargo
refunds. The complete PowerShell headless pipeline passed after the final build,
including the original combat, building, Forge and save regressions. Isolated
art passed 60 headless checks and generated regional art passed six.

The full suite caught an optional-visual-metadata regression in resource
streaming. Restoring now fills only missing presentation fields from the exact
profile's generated definitions, retaining saved quantities, work and depletion.
The unchanged `weathered_save` regression passes all nine checks again.

## Performance and tuning

A matched 1920 × 1080 Forward+ terrain/resource route on the local RTX 5090
compared v2 and v3 at 5 m/s, 120 FPS cap and 30 seconds per profile. Median
frame time was 8.332 ms for both; p95 changed from 8.411 to 8.460 ms (+0.58%).
Terrain/resource startup was 9.267 s versus 4.183 s and measured static memory
1.282 GB versus 0.931 GB. These sequential runs share a process, so cache warmth
can favour the second startup. They exclude combat and regional decorative kits;
they are not full-game cold-start or low-end-hardware claims.

New ground creation still creates occasional travel hitches: v3 active-prefetch
frames had p95 15.853 ms and maximum 23.814 ms. Splitting exact chunk creation
into a native query and four smaller scene phases reduced the measured phase
p95 from the initial full-chunk 14.40 ms headless probe to 5.37 ms in the rendered route.
Aggregate p95 should not hide that remaining cost. Full JSON and screenshots:
`build/strange-frontier/terrain-stream/`.

The generated-world art review measured a separate matched-camera comparison
with regional dressing visible and hidden. At 1440 × 900, 150 settled samples
per view, dressing changed p95 by +0.52% in Glasswind, +0.79% in the Fen and
+1.68% in Rootvault. Full world setup in that run took 4.631 s. This isolates
static decorative cost; camera walks and captures are separate from the samples.
The report preserves the raw manifest and does not treat these short, capped,
high-end-hardware views as a lower-end travel benchmark.

Final canopy-attachment and pool-outline corrections followed these samples;
their captures were reviewed separately. The complete distant terrain remains
visible, but visited exact chunks stay cached, so memory can approach the full
finite map after extensive exploration.

Generation budgets, distances and population purposes are in `worldgen.json`.
`strange_stream.tres` controls 120 m resource activation, 32 m retirement margin,
12 resource creations per frame, and 128/144/176 m initial/detail/retention
terrain radii. Exact 32 m safety preparation protects teleports and restores.
All values have plain-language comments in the resource script.

`contraptions.json` documents the 128 fixture bound, 96-unit basket, 64-unit
sorter buffers, 16-unit sorting action, four-operation energy store, 32 m cargo
span, 24 m signal range and 3 m bellows range. Each hand wind/prime stores one
operation; travel consumes one operation at departure. Rare recipes and Forge
component mappings carry their purposes in their existing tuning files.

## Limits and next production slice

The 512 m map is finite. Rare cores do not regrow. There is no new weather or
water simulation, machinery catch-up while offline, free rope physics, riding
the basket, global logistics, new combat balance or extra architectural family.
The separate timber-demolition conflict is untouched. Existing Forge difficulty
and full-run duration acceptance still await the owner's combat playtest.

The next production proposal is one input container → one existing ordinary
material process → one output container. Manual crafting remains available at
its current costs and outcomes. A subsequent slice can choose one local power
source, then connect short bounded supply routes. Renewable common resources
and automation mastery policy need their own explicit decision.

## Authored presentation and review evidence

The local Blender recipe is `tools/wroughtwild-blender/scripts/build_strange.py`
with purpose-labelled controls in `strange.json`. It generated 22 deterministic
visual GLBs through the existing authoring conventions: applied transforms,
ground pivots, linear vertex colours, repeat-geometry validation and a retained
source blend/report under ignored `build/blender-study/strange-frontier-2026-09-06/`.
Only the curated GLBs in `game/assets/authored/` are runtime inputs. No external
asset service, package or additional production dependency was introduced.

`StrangeResourceArt` supplies the same articulated fixtures and flattened
catalogue/placement meshes. `StrangeSites` composes shared regional MultiMeshes,
open approaches, persistent empty housings and physical clue trails. Distant art
uses native profile heights until its exact chunk arrives, then only affected
instances reground. Loaded voids remain empty. Excavation and restore trigger a
coalesced full composition refresh. An unloaded resource never counts as depleted.

The first complete generated render passed 4,201 checks. The corrected review
passed 4,204, with three approximately 54 m walks at 1.65 m eye height, 132 saved
walk frames, matched day/dusk views, cave approaches, five intact/worked/empty
finds and the ordinary resinheart workshop. A final targeted pool capture passed
eight checks after replacing round disk edges with an irregular shallow bank.
The normal headless pipeline passed 60 authored-art checks and six generated-art
preflight checks. These include actual collider dimensions, persistent housings,
shared fixture meshes and compact, distinct sound streams.

Review caught and corrected unsupported distant art, a floating crown attachment,
hidden Thrumroot coils and an incorrect viewmodel camera transform in the fixture.
The actual hand meshes now retain their normal local pose at the review eye.
Supported fen pools are checked again after exact terrain is streamed. Rendering
still uses the prototype's deliberately faceted materials and existing daylight;
the captures are evidence for this slice, not a claim of final production art.

There was no existing sound generator to reuse. `strange_sound.gd` adds a bounded
cached set of short mono synthesized chimes, dry ticks, creaks and pressure tones.
Clue playback is local to 12 m, at most one nearby clue per nine seconds, with
lower ambient gain than work feedback. Contraptions reuse the same pulse/tick
helper. It supplies no state or rewards. `strange_look.gd` documents these controls,
regional budgets, canopy attachment, water support, quiet motion and warm light.
Audio stream generation and runtime calls are tested; a human listening/mix review
is still needed alongside the normal discovery playtest.

Reproduce the gallery with
`python tools/wroughtwild-blender/strange_review_gallery.py` after the two rendered
review scenes. The entry point is `build/strange-frontier/index.html`, with generated
region walks, the explicit water view, the lamp interior, the authoring study and
the actual contraption playback embedded together. The isolated art timing samples
precede the final canopy attachment and pool edge polish; the visual-only rerun
preserves those samples rather than measuring during the regression pipeline.
Rendered regional art coverage is seed 1; the 64-seed native matrix separately
proves generation and approach guarantees, not every seed's visual composition.
