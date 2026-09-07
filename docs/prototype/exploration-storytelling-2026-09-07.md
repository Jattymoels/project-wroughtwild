# INT-02A — Read the remains, follow the find

Status: **Implemented; owner discovery review deferred while away.**
Baseline: `3229ab4` (pushed).

The owner asked to continue after INT-07A and reconfirmed ordinary pushes to
the existing main branch. Playtesting remains deferred while away. This is the
first bounded slice of INT-02 in the [intensive queue](intensive-queue.md).

## Outcome and assumptions

An existing ruin should suggest its old purpose and accidental destruction;
nearby remains should lead toward a recognisable intact resource. Gathering
should communicate the next physical action and make the resource's existing
uses easy to inspect. Empty sites must stop promising another intact find.

Use the accepted [Northstar](../world-premise.md), D-013/D-029/D-030/D-031/D-032,
and the current authored kit. The representative route is the V5/V6 blacksmith
ruin, its accidental strike and linked Ventlung opportunity. Five rare families
share the clue, harvest-description and material-guide corrections so the same
presentation contract holds elsewhere. No new history about the meteor sender,
civilisation names, enemy ancestry or the player's origin is selected.

The native profile, seed, routes, source IDs, finite stock, work counts, recipes
and pressure ledger remain authoritative. No new generator, terrain edits,
colliders, resource gate, reward, station, discovery currency, quest or persistent
objective is introduced. Existing player construction remains the only working
pressure machinery. The broader graphical target and timber-demolition conflict
stay separate.

## Findings and delivery

1. **Capture matched baseline and current routes.** Copy the untouched game and
   tuning into isolated projects; fixed seed, camera, daylight/dusk and warm
   frame samples. Normal saves and the owner's processes are not review inputs.
2. **Make the old smithy route readable.** Recompose a small number of existing
   noncolliding authored remnants and worn paving using its native approach,
   damage and discovery direction. Preserve existing walls, the impact breach,
   central walking strip, source work area and terrain/building suppression.
   Existing ruin bodies may provide one short neutral observational target line;
   no action prompt or lore panel is needed.
3. **Make clues truthful.** Existing clue points receive empty shells, broken
   scars or displaced host material, distinguishable from gatherable cores.
   The existing periodic rare-site cue reads finite resource records, including
   unloaded stock; an exhausted site becomes quiet without creating new stock.
4. **Connect work to usefulness.** Consume existing native `rare_stages` in the
   compact work display, preserving authoritative work progress and costs.
   All five gathered components gain the existing opt-in Source/use handoff to
   native recipe consumers. Keep normal panels and crosshair text short.
5. **Verify and publish.** Check actual visible text and interactions, read-only
   inspection, all five work/resource states, save/revisit, building/excavation
   suppression and ordinary route clearance. Run affected regressions; inspect
   matched captures and investigate frame regressions above ten percent.

## Affected files and boundaries

- Presentation: `CataclysmSites`, `StrangeSites`, local rare sound, their art
  resources and the existing player target label.
- Work/use: `ResourceNode`, `MaterialGuide`, existing native read-only metadata.
- Verification: focused discovery fixtures, a reproducible isolated review and
  current world/save/workshop checks.
- Documentation: this item, queue, accepted continuation record and affected
  world/interface specifications.

Each new art number has a plain-language purpose in its resource. Use shared
existing meshes/materials and distance culling, without per-frame rebuilds or
new external dependencies. Runtime composition of curated exports follows the
existing `AuthoredAssets` path; no new asset service or production-art pipeline.

## Delivered behaviour

The existing accidentally struck smithy receives at most seven noncolliding
remnants: a fallen old work surface, two displaced roof pieces and up to two
worn paving fragments on each native arrival/departure margin. Exact mesh
bounds retain the three-metre central strip, footprint and source clearance.
Thin evidence uses height-aware burial and support checks; invalid candidates
are omitted, with the opposite paving margin tried where necessary. Existing
walls and pressure-source interactions retain their original collision.
An aimed old wall offers one neutral observation, with no action or loot prompt.

Clue points retain their native locations and deterministic yaw. Empty husks,
slack root shells, spent scars, displaced grit and empty casings replace miniature
intact specimens, with no glow, breathing, collision or extra yield. Periodic
audio checks the site's existing saved resource identities; a stocked but
unloaded resource remains eligible, while a missing or exhausted record does
not recreate stock or advertise another find.

The compact work line now reads the native stage appropriate to existing press
progress. Refusals, tools, work counts, yields and collection remain unchanged.
All five rare components have the existing opt-in Source/use page, with native
properties, purpose and real recipe links. Longer work instructions stay
collapsed; reading a station recipe does not enable remote crafting.

The new presentation parameters live in `cataclysm_look.gd/.tres` (bounded
smithy offsets, fit, tilt, clearance and support) and `discovery_look.gd/.tres`
(five clue sizes). Every value has its visual purpose beside the declaration.
No engine-neutral gameplay tuning, native library or generation profile changed.

## Verification and evidence

All checks ran on copied game/data with separate APPDATA beneath ignored
`build/exploration/`. Ordinary saves and running game processes were not inputs.

| Check | Passing result |
| --- | --- |
| `discovery_clarity` | 249 assertions: five native work sequences, optional/saved metadata, partial work restore, unchanged RNG/possessions, actual HUD text, opt-in details, exact recipe consumers and finite contextual payout. |
| `discovery_sites` | 183 assertions: all five inert clue meshes, native anchors, shared material, support/building refresh, unloaded/partial/depleted stock, save records, missing resources and unchanged pressure/economy. |
| `smithy_story` | 122 assertions each on V6 seeds 77 and 1, and V5 seed 1: actual ray/source interaction, original three walls, new remnant bounds, visible support, route capsule, paid construction, saved suppression and excavation/restore. |
| `exploration_review` | Baseline 102 / current 111 assertions: eight matched grounded cameras, native fingerprints, stock/ledger invariants and all 38 points along the native smithy-to-discovery route. |
| Rendered `discovery_clarity --discovery-capture` | 274 assertions including 25 additional checks of actual 720p/1080p work and Source/use layouts, ray targeting, panel suppression and saved image size. |

Affected regressions pass: gathering **22**, establishment guide **138**, panel
density **60**, crafting catalogue **52**, paid Warden first-home journey **274**,
Strange Frontier **7,073**, Cataclysm intensive **170**, pressure workshop **60**,
ecology/buildings **102**, loose-drop save **148**. New focused fixtures are in
the standard headless scene pipeline. Godot import and `git diff --check` pass.

Verification caught and corrected packed-array resource inference during fresh
import and an initial thin-paving burial error. New evidence now measures its
rotated mesh bottom and keeps a visible top at its supporting corners. No test
was removed or weakened to accept these defects.

Reproduce current world evidence with
`tools/exploration_review.ps1 -Prepare -Import -Rendered`.
For UI evidence use `-Scenes discovery_clarity -Rendered` with
`-ExtraArguments '--discovery-capture'`. The helper uses hidden,
bounded processes and isolated save paths. The preserved baseline was copied
from `3229ab4` before production edits and receives only the shared review scene;
`-Phase baseline` replays it, and preparation refuses to overwrite it.

World evidence: `build/exploration/{baseline,current}/captures/seed-77/` has
eight views in day/dusk (32 paired-source PNGs total) and per-run manifests.
Interface evidence: `build/exploration/current/captures/discovery-ui/` has four
PNGs against an explicitly controlled backdrop. A local side-by-side gallery
is at `build/exploration/index.html`; generated evidence is not committed.

## Matched performance

Godot 4.5 stable, Forward+, 1440 × 900, FOV 75, 1.65 m grounded eye, uncapped
with VSync disabled. Windows review windows are placed offscreen. Hostiles and
player simulation are disabled; chunks/resources settle before each fixed view.
Each timed view has 90 warm frames then 600 process-frame intervals; screenshot
readback is outside timing. These are matched presentation samples, not live
combat/travel FPS or lower-end hardware certification.

| View | Baseline median / p95 ms | Current median / p95 ms |
| --- | --- | --- |
| Smithy arrival, daylight | 0.803 / 0.977 | 0.816 / 0.933 |
| Smithy arrival, dusk | 0.782 / 0.928 | 0.781 / 0.907 |
| Ventlung clue, daylight | 0.882 / 1.294 | 0.807 / 0.939 |
| Ventlung clue, dusk | 0.843 / 1.015 | 0.798 / 0.934 |

Full fixture world setup: **7,955 → 7,927 ms**; terrain portion **7,263 →
7,190 ms**. Active resources and loaded chunks match. Smithy draws change
**687 → 693**, Ventlung view **734 → 715**. No measured startup/median/p95
regression exceeds ten percent. Run-to-run variation prevents claiming a
performance improvement; the existing V6 preparation cost remains an INT-07
follow-up. No broader optimisation was undertaken in this slice.

## Remaining review

This is a modest environmental-readability pass using the existing art kit;
the landscape's broader graphical finish remains as previously accepted for
now. Native generation is unchanged, and the explicit V5/V6 cases above are
not an exhaustive visual certification of every seed. The automated route
uses supported ground/capsule samples, not a continuous human walk or discovery
playtest. The owner can later judge whether the old purpose, accidental strike
and useful resource handoff are understandable during ordinary exploration.
No combat calibration, new civilisation history or larger automation follows
from this evidence. INT-03 home/workshop usability is the next queued brief.
