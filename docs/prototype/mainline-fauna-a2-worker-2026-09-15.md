# A2 worker — finished fauna in ordinary Wroughtwild

The owner starts this worker from the prepared prompt. Do not create another
worker or reviewer. Owner standing approval covers this slice; playtesting is
currently deferred. Complete the integration without another visual approval.

## Workspace and source inputs

- Owner depot: `C:/Users/Matty/Dev/project-wroughtwild`, branch `main`.
- Prepared worker checkout: `D:/Wroughtwild/work/mainline-fauna-a2`.
- Worker branch: `codex/mainline-fauna-a2`, based on current main with A1 adopted.
- Read `D:/Wroughtwild/work/mainline-fauna-a2/build/a2/SETUP.md` for the actual
  base commit and native DLL setup. Reuse this checkout; do not reconstruct it.
- Engine: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe`.
- Put logs, private APPDATA/LOCALAPPDATA, imports and temporary asset preparation
  in the D: worker, normally `build/a2/`. Main and shared Git metadata remain on
  C: for current task/remote-access continuity; check space before large staging.

Preserve these existing local inputs and use only their required runtime parts:

| Input | Path under `C:/Users/Matty/Dev/project-wroughtwild/` |
| --- | --- |
| Approved ART-01 boar rigs, clips, maps and material | `build/boar-art01/boar-handoff/review/` |
| Approved ART-03 wolf | `build/fauna-art03/fauna-handoff/wolf/review/` |
| Approved ART-03 stag | `build/fauna-art03/fauna-handoff/stag/review/` |
| Existing ART-05 boar runtime adapter and cooked assets | `build/art05/red-route-handoff/game/art05/` |

ART-03 review folders contain `wolf-near/mid/far.glb` or
`stag-near/mid/far.glb`, their maps, rig reports and material bindings. ART-05's
`route_art.gd` already demonstrates manual native-clock sampling, visual fitting
and status priority for `lf_red_boar`; reuse the relevant implementation and cook
where applicable. Its seed-77 route filter, paid checkpoint, old frozen gameplay,
world changes and other ART-05 art are not part of this port. Do not run/rebuild
the old pilot or overwrite A1's environment/station/device integration.

## Outcome and affected systems

Read the current owner depot's AGENTS.md, then the worker's README, DESIGN,
decision registry, vertical slice and acceptance criteria in their required
order. Reuse prior reading where applicable. Then read only the relevant sections
of `docs/prototype/boar-living-scars-2026-09-09.md`,
`docs/prototype/fauna-art-2026-09-09.md`,
`docs/prototype/world-route-art-2026-09-09.md` and the referenced runtime recipes.
Historical isolated-study exclusions, exhaustive review steps and time countdowns
are superseded by current owner instructions.

Put the latest completed boar, wolf and stag into the normal game's existing
actor families, including supported existing LF visual aliases. Preserve the liked
moth. Current catalog entries include `ember_whelp` (boar), `ash_hound` (wolf),
`valley_elk` (stag), and `marsh_wisp`/`cinder_wisp` (moths). Inspect actual current
`enemy_id`/`visual_id` mappings rather than selecting by a single old route ID.

Relevant integration points include `game/art/recovered_actor_art.gd`,
`game/art/creature_motion.gd`, `game/assets/authored/mobs/manifest.json`,
`game/scripts/enemy.gd` and their existing host/status hooks. Use the existing
actors as the owners of movement, attacks, hit effects and saved state. Restate
the outcome and make the smallest complete presentation port.

- Adopt finished rigs/clips/materials; do not regenerate approved designs or
  reopen all Blender masters. Normal new-world and Continue entry must use them.
- Fit art to existing body/visual envelopes; preserve actor IDs, collider sizes,
  reach, damage, attack clocks, tells, loot, population and passive stag behavior.
  The silver-blue wolf appearance does not confer new Frost/Retention mechanics.
- Drive pose and stride from native state/travel; retain native freeze, stagger,
  death, hit/burn/bleed and pause priority. A cosmetic scar pulse never drives
  combat or rewards. Avoid running old procedural motion and a new rig together.
- Share reusable mesh/texture resources while keeping individual pose/material
  state independent. Reuse the existing asset cook where useful; retain only the
  production dependencies, with deliberate art settings and plain-language purposes.
  Respect delivered animation import needs without repeating exhaustive pose audits.
- Keep all runtime paths inside tracked `game/` resources. No C:/D: source-package
  dependencies, copied preview bootstrap, fixed production seed or save override.
  Keep editable masters and generated caches out of the production commit.
- Preserve A1, current campaign/save rules and current owner guidance. The six
  ART-06C replacement mobs need separate rig/animation/runtime slices; do not
  bundle them here. PLAY-01–04 remain open and R9 stays stopped.

## Focused checks and delivery

Concrete risks: missing imported rigs/materials, pose/state changes that obscure
native behavior, and failed restoration/streaming of existing actor ownership.
Default to three focused jobs, one rendered backend (Forward+):

1. Import/load the actual worker game and selected new actor resources. Reuse
   source-package rig/clip evidence; do not rehash/repackage the parent handoffs.
2. A short representative actual-actor check: each adopted family loads and moves;
   one native attack/status transition retains its tell and timing; stag remains
   passive and moth remains unchanged. A single useful short rendered view is
   sufficient for presentation. Use the verified `--r8-no-mouse-capture` path and
   a disposable no-focus test override; remove the override before manual delivery.
   Prefer headless checks for state assertions. Never seize the owner's pointer.
3. One representative save/Continue or existing streaming-restore check for the
   changed actor binding, with private test state. Verify finite ownership/death
   persistence and no duplicate visuals, spawns or rewards. Reuse unchanged A1
   construction/station evidence; no broad campaign regression or camera matrix.

There is no hard ten-minute stop or extension request. Fix a concrete encountered
load/behavior issue and finish delivery; do not grow this into a pipeline review.
Document small cosmetic limits for later iteration. Owner playtest is deferred,
not an approval gate or a claim of human validation. Stop all owned test processes.

Write a concise A2 result with actual in-game change, checked behavior, remaining
limits, art settings and exact manual launch/playtest steps. Update the current
coordination sheet/queue. Commit only the completed checked slice on
`codex/mainline-fauna-a2`; return the SHA to the coordinator for integration and
ordinary push to `origin/main`. Do not stage unrelated saves/captures or generated
engine/import products. Do not copy your older AGENTS.md over current main.

After adoption, the next scoped work is diagnosing the reported stutter and
accidental underground access/worse lag, then canopy completeness. Do not start
those jobs or a replacement review wave inside this worker.
