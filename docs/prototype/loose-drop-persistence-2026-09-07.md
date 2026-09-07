# INT-07A — Loose drops survive save and restore

Status: **Implemented; owner review deferred while away.** Baseline: `37a93f5`.

Published as `3229ab4` to origin/main on 7 September after the owner reconfirmed
ordinary pushes to that destination.

The owner asked to continue the next work while away from the local PC, after
the [first-hour intensive](first-hour-clarity-plan-2026-09-07.md) identified
loose-drop loss and duplication as the next reliability priority. This is the
bounded persistence fix from that [audit](loose-pickup-save-audit-2026-09-07.md).
INT-01 usability review remains pending; it does not block this work.

## Outcome and scope

Saving after gathering retains the uncollected yield. Loading an earlier save
replaces the old live drop set, so the restored resource cannot be combined with
a drop released after that save. Carried inventory, depleted resources, physical
drops and recoverable death packs must describe the same moment.

Include all existing `Pickup` kinds and `DroppedBundle` because leaving gear,
pages or death packs outside the replacement would retain the same stale-owner
problem. This is a save/ownership correction, without new drops, materials,
expiry rules, auto-collection, combat tuning or generation changes. The known
timber-demolition conflict and broader save-system redesign remain excluded.

## Implementation contract

- Add optional `world_drops: {version: 1, pickups: [...], bundles: [...]}` to the
  existing outer schema 2. No native economy schema change is needed.
- Record each uncollected amount and its position, velocity, floor, bounce/rest
  state, age and visual orientation/bob. Material chips retain their existing
  180-second lifetime; gear and pages retain their existing indefinite lifetime.
  Saving suspends time rather than advancing it while the game is closed.
- Gear retains enemy, kill seed, elite and its displayed preview. Serialize the
  full signed kill seed as decimal text so JSON cannot round a long sequence.
  Pages retain their already selected skill; restore never rerolls or teaches it.
  Death packs retain their position, orientation and exact material contents.
- Validate the entire drop payload before importing native state or changing
  live nodes. Reject unknown versions/kinds, malformed fields, nonfinite motion,
  invalid counts and invalid enemy/elite/skill identities. Material IDs follow
  the native open string-to-count inventory; do not invent a partial whitelist.
- On successful restore, replace all drops belonging to that world root.
  Do not merge them, reconstruct absent yields from depleted nodes, follow
  saved arbitrary node paths or affect unrelated worlds in the same scene tree.
  Identical legitimate chips may coexist. Claimed/queued nodes are not saved,
  and repeated collection callbacks cannot grant the same completed drop twice.
- Older saves lacking `world_drops` load as an empty recorded set, clearing stale
  live drops. Missing historical yields cannot be recovered from those files.
  A present malformed payload is an error, never treated as an empty legacy set.
- Trial loot stays entirely in `TrialSession`. Save world drops beside the paired
  checkpoint, without converting trial loot into physical chips or redepositing
  anything. While a trial is active, reject world-drop collection and material
  dropping before either can bypass the entrance/death contract. Ordinary world
  chip age/flight continues during the run. Cleared-floor suspension preserves
  its saved age along with the existing exact combat and run state.
- Successful explicit New World creation clears the old world's loose items.
  Save restoration installs its own set separately. Normal active-trial loading
  remains refused by both the player interface and native import.
- Keep atomic file replacement and the previous-good-file recovery behaviour.
  This slice adds no new post-import validation failure and does not promise a
  general rollback transaction for every pre-existing world-generation failure.

These choices preserve the current collection, death, trial and generation
contracts under D-006/D-010/D-016/D-028/D-032. The owner-approved reliability
continuation supplies the work scope; no new progression decision is required.

## Separate finding: gear at an era transition

The existing native preview and claim both roll using the player's current era,
in addition to enemy/seed/elite. Restoring a saved world therefore preserves the
same claim it would make without restarting, but a previously previewed item can
change if the era advances before collection. Freezing that original item/era is
a separate itemisation correction, not silently introduced by this save slice.

## Delivery and verification

1. Introduce the bounded snapshot/validation/restore helper and collection guards.
2. Integrate it before native import and after successful world/checkpoint restore.
3. Exercise both reproduced generated-world cases, including a separate process.
4. Check partial/full-pack collection, expiry, motion, gear/pages, death packs,
   repeated loads, legacy files, malformed late records and failed replacement.
5. Extend existing trial suspension and New World checks for separate ownership.
6. Run affected integration, save, world and workshop regressions in an isolated
   project with isolated APPDATA; preserve the owner's normal files and processes.

Use the existing `tools/first_hour_review.ps1 -Runtime loose-drops` runner. Evidence
lives under `build/first-hour/logs/loose-drops` and the copied project at
`build/first-hour/loose-drops/game`; generated saves/logs are not committed.
All new numeric checks protect existing engine/native serialization bounds;
no gameplay tuning values or external dependencies are introduced.

## Verified outcome

The original V6 seed-77 tree now releases and pays exactly **14 wood** after
rewinding and reharvesting, instead of 28. A separate process restoring the
after-release save finds all **14 wood still loose**, keeps the tree depleted,
and collects exactly 14. Neither operation auto-collects or changes the yield.

| Check | Passing result |
| --- | --- |
| `loose_drop_save` | 148 assertions for ownership, full/partial hauling, motion, expiry, gear/pages, death recovery, scope, legacy files, malformed late records and last-good-file preservation. |
| Fresh-process loose-drop writer / reader | 6 / 13 assertions; material, elite gear, selected page and death pack survive process exit and are granted once through normal collection. |
| Actual generated-tree writer / reader | 6 / 5 assertions; both original loss/duplication cases corrected using ordinary contextual work and pickup. |
| `trial_intensive` | 6,217 assertions, including paired suspension, old checkpoints, world-drop isolation, separate run loot and unchanged life/effect/run clocks. |
| `new_world_startup` | 101 assertions; failed generation preserves owned drops, successful explicit creation clears them, and another root is untouched. |

Logs are `loose_drop_save`, `loose_drop_write`, `loose_drop_read`,
`world_drop_write`, `world_drop_read`, `trial_intensive` and `new_world_startup`
under the evidence directory above. The committed headless pipeline includes
both restart pairs; the Windows helper preserves their separate process order.

Affected regressions also pass: integration **273**, pickup feel **17**,
gathering feedback **22**, loot-stream persistence **30**, weathered-world save
**21**, world intensive **5,957**, Strange Frontier **7,073**, pressure workshop
**60**, and the paid Warden first-home journey **274**. The main-scene smoke
launch passes in the isolated project. No native rule changes required a DLL
rebuild or a new generation calibration.

Verification caught and corrected JSON's conversion of death-pack counts into
floating values: restore now recreates integer contents after validation. An
initial trial fixture also left a zero-valued inventory key after removing its
injected probe; the fixture now removes that exact test stack through the native
inventory API before checkpointing. No existing checks were removed or weakened.

Ordinary saves and running game processes were not used. Headless fixtures
establish the save contract, not human comfort, combat balance or graphical
quality. No frame-time or V6 preparation improvement is claimed. Older saves
remain readable but cannot recover drops they never recorded. The separate
era-sensitive gear preview issue above remains open.
