# INT-03B — Reliable placement and returning home

Status: **Implemented, owner comfort review pending.** Baseline: `8ffc542`.

The owner approved the next slice after the INT-03A results. This resolves the
three concrete placement/save findings recorded there, using the existing
catalogue and contracts. Ordinary commits remain authorised; publication remains
subject to platform approval controls. Standing workflow guidance is recorded
in `AGENTS.md` and cannot override a rejected publication action.

## Outcome and scope

An otherwise free anchor must not hide a blocked far end of a long/tall piece.
A held station must fit beneath the player's built ceiling. Saving an open door
must restore the same leaf and collision pose, without closing it onto the player.

Preserve D-017's element-based piece overlaps, mine-wall lining and surface
contacts, existing station dimensions, payment/refunds, shelter with doors open
or closed, old world profiles, and native inventory ownership. Do not delete or
revalidate old buildings against stricter new-placement checks during loading.
Old saves without a door-state field retain their historical closed-door default.
New state is optional, validated before any live mutation and applied once.

No new construction form, recipe, material, structural support, furnishing,
automation, generation profile, movement ability or combat tuning is included.
The known D-018 timber-demolition conflict remains outside this work item.

## Small implementation plan

1. Preserve the current production baseline and reproduce terrain-footprint,
   built-ceiling station and door-restore failures with isolated test fixtures.
2. Check each actual native footprint element against the edited terrain using
   the existing per-element exposure rule. Keep full/fine/off-grid and long/tall
   addressing authoritative; avoid duplicating native footprint rules in GDScript.
3. Apply ordinary station body checks to intersecting player-built geometry,
   preserving intended floor contact, neighbouring pieces and kit payment.
   Station kits are physical props, not a new construction lattice rule.
4. Capture and validate optional door-open state; restore leaf/physics together
   through an explicit state setter. Cover both hinges, repeated loads, legacy
   snapshots, malformed state rejection and a player saved in the doorway.
5. Run focused and affected building/save/workshop regressions, review physical
   refusal and restored door states, update specifications and commit the slice.

## Systems, decisions and verification

GridPlacement owns spatial refusal; the native lattice remains the footprint
authority. PlacedBlock owns door presentation/collision and SaveManager owns
validated world restoration. D-017, D-027, D-029/D-031 and existing schema-2 saves
remain authoritative. No new gameplay tuning is expected; any tolerance must
reuse the existing contact convention or have its purpose documented.

Use copied projects and isolated APPDATA beneath ignored `build/home-reliability/`.
Do not read ordinary saves, stop unrelated processes, overwrite the INT-03A
baseline or commit generated evidence. Tests must establish exact payment on
success, no spending on refusal, edited terrain after save restoration, saved
door collision and unchanged shelter/inventory. Automated checks do not replace
the owner's later building comfort review.

## Implemented result

The GDExtension exposes the existing native lattice footprint; GridPlacement
applies its original terrain-exposure rule to each element instead of just the
anchor. Edited soil and rock remain authoritative. Volume burial is refused,
while exposed faces/edges still support mine lining and ground contact.

Ordinary station kits now refuse intersecting built walls, beams and ceilings.
Horizontal floor skins at the station's supporting plane remain valid, including
half-grid placement. The existing body dimensions and 0.9 fit-query scale remain:
that scale permits intended touching surfaces instead of making adjacent props
reject each other. No new tolerance or tuning value was added.

Schema-2 building entries optionally record boolean `door_open`. The complete
payload validates before any live mutation, then restoration assigns leaf and
collision pose together. Repeated loads never toggle a door. Old records without
the field retain the closed default; existing saved buildings and stations are
reconstructed directly without applying stricter new-placement refusals.

The complete-home inspection caught a real old fixture overlap: its forge body
clipped a wall. Both comparison fixtures now place it half a cell inward and one
cell forward through ordinary placement; chest approaches were moved to the
clear side. The same 302 pieces, six stations and paid material quantities remain.

## Verification

Godot 4.5 stable ran in isolated `build/home-reliability/{baseline,current}/`
copies with separate APPDATA. The pre-edit baseline retains `8ffc542` production
and receives only the common test fixtures. Normal saves and running playtests
were not used. The rebuilt local extension is installed in ignored `game/bin/`;
the normal CMake output path is restored after the isolated build.

| Check | Current result | Baseline reproduction |
| --- | --- | --- |
| `home_terrain_placement` | 174 passing checks: full/fine/off-grid and negative-boundary footprints; long/tall pieces; exposed-face/edge controls; exact payment; real dig and saved excavation; repeated old buried-building loads. | 33 failed assertions; 125 total because the old extension has no footprint-query checks. |
| `home_station_clearance` | 84 passing checks: all three station kits, four rotations, full/half-grid floor contact, wall/ceiling/beam refusal, clear neighbours, stale-preview refusal, D-017 overlaps and old saved station placement. | 24 failed assertions, including consequences of wrongly accepted obstructions. |
| `home_door_persistence` | 467 passing checks: eight paid axis/hinge/state combinations, real E, atomic write/read, repeated restore, exact ray/capsule/leaf pose, legacy defaults and seven malformed late-record values rejected before mutation. | Same 467 checks reproduce 123 failed assertions. |
| `home_workshop_review` | 1,027 headless / 1,049 rendered checks pass. Two complete paid homes retain actual station/chest interaction, stairs, shelter, storage and exact restoration. | Same corrected layout passes 1,049 rendered checks. |
| `first_hour_journey` | 290 passing checks each for Ranger, Warden and Kindler in V6 seed 77. All physically enter the first paid shelter. | This reuses the already corrected INT-03A fixture. |

Affected regressions pass: engine unit **398**, integration **273**, materials
**158**, build usability **39**, prior station placement **98**, material joins
**141**, pressure workshop **60**, feeder presentation **22**, contraptions **85**,
loose-drop saves **148**, trial lifecycle **6,217**, new-world startup **101**.
The three new regression scenes are registered in the headless pipeline. The
native extension build and isolated import pass; no simulation tuning changed.

`tools/home_review.ps1 -ReviewSet home-reliability -Prepare -Import` prepares the
current copy. Select the three new scene basenames with `-Scenes`. A first
baseline preparation must precede production edits; the helper refuses to
overwrite a preserved baseline. Expected baseline failures are evidence of the
original bugs, not passing regressions. Use `-Scenes home_workshop_review
-Rendered -ExtraArguments '--home-capture'` for the ten home captures, or
`-Scenes home_terrain_placement -Rendered -ExtraArguments '--placement-timing'`
for active preview measurement. Run baseline and current serially.

Logs live under `build/home-reliability/logs/`. Each phase's `captures/home/`
contains matched day/dusk interiors, exteriors and real station ghosts plus its
manifest. The current developed interior and early timber station ghost were
visually inspected. Door assertions check physical state independently of the
authored showcase; the normal checkpoint file is retained in ignored evidence.

## Measured cost and remaining review

The common active-preview fixture uses a real camera, matching physics floor and
authored Terrain field, plus a normally paid beam for empty-air extension. Both
versions verify actual trace/extension targets and unchanged inventory. Forward+
at 1280 x 720, VSync disabled, 90 warmup and 600 sampled frames per view:

| Active preview | Baseline CPU median/p95, microseconds | Current CPU median/p95, microseconds | Baseline frame median/p95, ms | Current frame median/p95, ms |
| --- | --- | --- | --- | --- |
| Direct ground cube | 70 / 93 | 98 / 122 | 0.339 / 0.544 | 0.339 / 0.540 |
| Empty-air beam extension | 850 / 887 | 881 / 920 | 1.063 / 1.175 | 1.085 / 1.157 |

The direct preview's CPU time increases by 28 microseconds (40% median): a full
cube now checks eight native fine-grid elements instead of one anchor. This is
bounded extra validation, not a claimed optimisation. Total frame measurements
remain within the ten percent review threshold. The matching eight home
day/dusk views also remain within it (largest increases: median 2.4%, p95 6.4%).
Timing JSON and actual preview images live in each phase's `captures/`.

These are isolated authored-scene measurements on this machine, not a startup,
streaming, all-seeds or large-settlement certification. Existing V6 preparation
cost remains tracked separately. Inspection inventory and accelerated class
journeys establish behaviour, not gathering pace or combat balance. Human
building comfort review remains deferred while the owner is away. The next
queued slice is INT-04's local sound and interaction-feedback brief.
