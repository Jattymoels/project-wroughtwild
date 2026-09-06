# Tap a pressure pocket, fire a small building haul

**Approved for implementation, 6 September 2026.** The owner's “Continue” accepts
this follow-on with the accidental, pre-cataclysm blacksmith siting correction.
[D-031](../decisions/registry.md) records the bounded exception; the
[implementation work item](pressure-workshop-2026-09-06.md) tracks delivery.

## One source and one useful result

Build beside a **finite pressure pocket at an asteroid-struck old blacksmith's
ruin**, linked to one Ventlung discovery, where an exposed trace enters mineral
casing. The smithy predates the catastrophe; the overlap is accidental, and the
player builds the working forge and feeder. Augmentation concentrated pressure in this host;
other traces supply no energy. Inspection previews remaining pressure and the
required device. Ordinary core harvesting remains unchanged.

Contain pressure to feed **one existing basic-forge recipe**:
`8 raw_clay + 1 fuel heat → 4 rustclay_brick`. Pressure moves the feeder; ordinary
fuel supplies heat. The bricks build existing warm masonry. Ingredients, fuel
selection, yields, access and manual crafting retain their [current rules](../systems/crafting-and-skills.md).
No new ore, intermediate item, currency, quality tier or mastery reward.

Add one bench-built **pressure feeder kit**: 1 Ventlung, 1 Thrumroot, 8 wood,
2 iron ingots and 2 raw reed; no skill, fuel or XP requirement. This is a new
approved recipe. Attach it to one player-built basic forge and one pocket within
8 m, keeping the gathering circle open. One input hopper holds clay and fuel;
one tray receives bricks. No general pipe, cable or transport network.

## Components and bounded operation

Ventlung contains pressure; Thrumroot stores its work as tension. Neither creates
energy. An existing Stormglass lever may request a batch; the local handle needs
no such core. Lanternheart illuminates the workplace. Pullstone retains ferrous
sorting and is unnecessary for clay. The line does not require all five finds.

| Initial tuning | Purpose |
| --- | --- |
| 24 strokes per pocket, no replenishment | Enough drive for 96 bricks; exhaustion encourages relocating reusable machinery. |
| Four stored strokes total; one per cycle | Retain the current small-store scale. Pocket-to-store transfer debits one owner and credits the other once. |
| Four cycles per start, 8 seconds each | A visible task while building nearby; manual batches remain instant. |
| 64 input items / 32 output bricks | Small physical buffers with clear full/empty stops; clay and allowed fuel share the input owner. |

Unloading, entering a trial or quitting pauses exactly; no offline catch-up.
Pressure/drive are site/device state, not inventory currency. Automatic work
grants no personal mastery; this decorative recipe already grants zero XP.

## Ownership and failure

The player loads the hopper and takes output. No pulling from other chests,
death bundles, trial deposits, suspended runs or intact nodes. Each cycle
reserves its exact inputs, fuel items, drive and output space in one simulation
transaction. In-flight escrow owns them; saves preserve that transaction and
progress. Completion commits once. Missing supplies, full output or obstruction
stops before another reservation.

Cancellation returns escrow once; unsupported machinery pauses. Dismantling
returns inventory and intact rare cores, applies existing ordinary-frame refunds,
and visibly vents unused drive. It never refills the pocket. Completed bricks
remain bricks. No explosion, resistance test, random breakage or new death penalty.

## Accepted boundary

The approval covers **finite pressure, this kit/recipe, budgets, zero automatic
mastery and pause/escrow/recovery rules**. One reachable pocket appears in the
frozen successor profile `frontier_v5`, linked to a Ventlung composition;
V4 traces stay decorative and existing saves receive no retrofitted stock.
Hand-winding can still drive the feeder after depletion. No extra era, renewable
supply or broader factory belongs to this proposal.
