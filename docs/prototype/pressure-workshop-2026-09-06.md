# Pressure workshop: recovering work from an accidental impact

**Human-approved implementation work item, 6 September 2026; D-031.** The owner
accepted the current visual finish for now, clarified that empowered ruins
predate the catastrophe, and asked to continue the proposed extraction loop.
Further graphical refinement is deferred; combat and discovery feel still need
ordinary player testing.

## Outcome and assumptions

Discover an asteroid-struck old blacksmith's ruin, inspect its finite pressure,
build a new forge and pressure feeder, and use the resulting bricks in a home.
The destroyed smithy was never designed to harness the impact. All functioning
containment and feeding machinery belongs to the player's reconstruction.

The [accepted proposal](leyline-extraction-proposal-2026-09-06.md) is the rules
contract. One source, one kit, one existing brick recipe and small local buffers
are the complete scope. Manual winding remains useful when pressure is spent.
No recipe discovery gate, automatic mastery, renewable source, offline work,
equipment-quality shortcut or general transport network is introduced.

## Implementation order and affected systems

1. Freeze V4 inputs and generation; add a reachable old smithy, accidental impact
   and stable pressure-source identity to the finite V5 successor.
2. Extend the native contraption ledger with finite source ownership, forge
   attachment, brick recipe planning, exact cycle escrow and cancellation.
3. Integrate local controls, visible progress, support/obstruction checks and
   pause behavior; persist the ledger with matching world and player state.
4. Exercise the complete crafting/building loop and review the site in daylight
   and dusk, plus regression checks for old worlds and contraptions.

Affected decisions: D-001/D-029's bounded automation exception, D-030's premise
clarification and D-031. Existing crafting, itemisation, construction refund,
trial deposit and save contracts retain authority. The timber-demolition
conflict remains outside this item.

Tuning lives in `data/tuning/contraptions.json`, `crafting.json` and versioned
world-generation data; every new number includes its player-facing purpose.
Godot certifies actual local geometry and runs active time; simulation owns
materials, source depletion, energy, attachment bounds and once-only work.

## Acceptance

- V1–V4 terrain, deposits and placement inputs remain unchanged. V5 has one
  reachable source at an old smithy with a direct accidental impact.
- Source transfer cannot replenish, move or duplicate stock across reloads.
- The existing clay recipe's inputs, fuel ordering and yield match manual work.
- Escrow, drive, progress, input and output survive saving exactly. No offline
  catch-up, double completion, double refund or trial-inventory access.
- Unsupported, obstructed, unloaded or absent-forge machinery pauses safely;
  missing supplies/full output stop before the next reservation.
- Cancellation and dismantling recover exact owned contents once; rare cores
  return intact, common frames use existing refunds, unused drive is vented.
- Normal interaction presents source inspection, attaching a player-built forge,
  loading, charging/winding, local/lever starts and output collection.
- A rendered review demonstrates bricks from the loop used in construction.

## Status

**Implemented and verified, 6 September 2026.** Current visual finish was accepted
by the owner; this implementation does not claim a new graphical-quality pass.

The normal generated-world route crafts both kits at the bench, pays placement,
inspects the old hearth, attaches a physically owned forge and feeder, transfers
four strokes, explicitly loads clay/fuel, and saves at 2.375 seconds into a
firing. Restoring through the normal atomic file path preserves the exact ledger.
Four firings produce sixteen bricks; three masonry blocks are then paid from
that tray. A later hand-wound cycle survives trial entry and cancellation without
redeposit or duplication. Repeated collection, cancel, dismantle, world binding,
empty legacy loads and invalid/missing source ledgers cannot grant extra stock.

| Verification | Result |
| --- | --- |
| Native pressure source/generation, 64 seeds | 16,831,577 checks, zero failures; all 16 historical profile/seed fingerprints exact. |
| Frozen V4 generation, 64 seeds | 25,959,555 checks, zero failures; prior geography preserved. |
| Native contraption transactions | 244 checks, zero failures, C++17 with strict compiler warnings. |
| Physical feeder fixture | 22 checks, zero failures: actual support, obstruction, moved/owned forge, manual and Stormglass starts, visible ports. |
| Whole-world workshop | 60 headless / 66 rendered checks, zero failures, including normal placement, crafting, save/load, trials and building. |
| Existing headless pipeline | Passed, including 398 unit, 6,189 trial, 5,957 world, 58,221 terrain-stream, 85 prior-contraption and 170 V4 integrated checks. |

Native transaction checks cover finite/shared source ownership, full buffers,
exact fuel ordering, insufficient inputs, counter/pack overflow, partial progress,
source/identity/escrow corruption, core refunds and old-profile hand operation.
The native brick planner reads the existing recipe and fuel table from tuning.
No new skill gain, equipment roll, currency or era was added. The only new kit
increases the existing fixture catalogue from six to seven, alongside the same
three station kits. Both new engine scenes are in the normal check pipeline.

Six actual daylight/dusk images live in `build/pressure-workshop/index.html`.
The close working view reveals the hopper, drum, output tray and short physical
connections; the wider views retain the ruin and new masonry in context.
Regenerate using `tools/cataclysm_review.ps1 -Scene pressure_workshop -Rendered`,
then `python tools/pressure_workshop_gallery.py`. Saves and logs remain under
`build`, separate from the player's normal save. [Native generation report](../art/pressure-generation-2026-09-06.md).

## Tuning and remaining limits

`contraptions.json` adds source strokes (24), hopper (64 items), tray (32 bricks),
batch length (four firings), firing duration (eight active seconds) and attachment
reach (8 m). Every entry explains its purpose. Existing four-operation storage
includes a reserved stroke, and escrow retains cancellation room in the hopper.
`worldgen.json` documents the bounded smithy offsets, small strike, pocket radius
and accidental trace. `contraption_look.gd` documents collider, support, connection,
inspection and visible work controls. The approved kit inputs live in the
ordinary crafting table.

There is one pressure pocket per V5 world and no retrofit to older saves. Older
station saves lacking physical ownership metadata retain their crafting access;
a newly placed forge is required for the feeder. This is deliberately one small
recipe loop, not renewable production or a general factory. The source can drive
96 bricks before exhaustion; manual winding remains available afterward.

Review supplies were seeded and active ticks scripted. Discovery pacing,
workshop enjoyment and the 24-stroke budget still need a human playtest. These
checks do not recalibrate combat, claim a new graphics finish, or claim to fix
the previously recorded first-view/streaming hitches. No fresh matched frame-time
benchmark was made for this bounded machinery slice. No generated build or
imported cache is intended for version control; review output remains local.
