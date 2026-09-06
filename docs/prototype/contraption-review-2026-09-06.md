# Strange Frontier: useful finds and the connected experiment

Implementation evidence for the owner-approved
[rare-world intensive](rare-world-intensive-2026-09-06.md), 6 September 2026.
This records the small fixture slice; generation, regional presentation and
world performance have their separate review evidence.

## Implemented behaviour

The existing workbench crafts one kit for each of six placed fixtures. The normal
building selector exposes held kits, checks the full authored footprint and
places their existing lattice-aligned ground pivot. Every fixture opens the
existing work panel through ordinary interaction.

| Find | Working fixture | Player action and result |
| --- | --- | --- |
| Lanternheart | `lantern_lamp` | Open or shutter its warm local light. A Stormglass receiver can switch it too. |
| Thrumroot | `cargo_winch` | Wind a drum, load ordinary carried ingredients and send the basket across one fixed supported span. |
| Common frame materials | `winch_landing` | The other endpoint accepts and returns that same basket, including a return haul. |
| Stormglass | `stormglass_lever` | Select a nearby drum or lamp and send a visible pulse. A signal requests work; it supplies no winding. |
| Pullstone | `magnetic_sorter` | Hand-feed a mixed input. Iron ingredients follow the magnet into one tray; other inputs enter the other tray. |
| Ventlung | `ventlung_bellows` | Prime the chamber by hand and release pressure onto a nearby prepared wedge or responsive seam using its existing impact response. |

The action panel closes when a basket departs, a lever pulses, a sorting batch
tips or pressure is released so the player can see the operation. Winding and
priming remain available in the panel. Ordinary gathering and crafting are not
slowed or made heavier to justify these objects.
The same locally synthesized cue helper used by wild discoveries supplies a
restrained pulse chime and quieter hand-operation ticks; no external audio asset
or service is required. Receiver choices describe direction and height from the
player rather than showing internal placement coordinates.

## Authority and persistence

`sim/include/wroughtwild/contraptions.h` and `sim/src/contraptions.cpp` own fixture
identity, poses, links, energy, exact travelling progress, pulse/trip counters
and all container inventories. The host consumes one crafted kit only after
creation succeeds. Godot owns support tests, swept basket clearance, nearby
elapsed time, authored art and interaction presentation.

- A basket's only inventory belongs to its drum. A landing exposes that inventory
  only when the basket is stationary there. Inputs and outputs never receive a
  speculative copy while it travels.
- Energy is spent once at departure. A blocked span pauses without spending more
  or dropping cargo. Clearing it resumes the same trip.
- Removing a landing recalls its basket to the drum, even mid-trip. Removing the
  drum or sorter returns all contents once. Recovery may exceed an ordinary
  gathering cap; dismantling cannot silently destroy stored possessions.
- Dismantling refunds the intact rare core in full. Common recipe inputs use the
  existing construction refund fraction. Repeating removal cannot refund again.
  Refunds and contents are checked against a temporary pack together: even a
  maximum-count restored pack cannot remove the machine and then overflow its
  recovered core. Refusal preserves the fixture, cargo and pack exactly.
- Saved native JSON retains exact progress and quantities. Restore validates a
  complete temporary state before swapping it in: kinds, keys, finite poses,
  integer counts, capacities, permitted input IDs, energy, output properties,
  active-trip state, link distance, receiver types and exclusive landing ownership.
- Scene restoration recreates bodies from the validated native poses. It never
  consumes another kit, redeposits cargo or advances elapsed time. The master
  save includes this native state beside the corresponding player inventory.
- Unloaded/distant fixtures do not accumulate catch-up time. The native extension
  rejects machine mutations inside a trial. No trial deposit, death bundle,
  intact resource node, enemy or unopened container is a machine input.

## Initial tuning

Every field in `data/tuning/contraptions.json` has a plain-language purpose. The
starting budgets are 128 fixtures per world, 96 basket units, 64 sorter input
units, 64 units per output tray and 16 units sorted per hand operation. Four
operations fit in either energy store; each winding/priming action supplies one,
and each trip or pressure release spends one.

A winch spans at most 32 metres; a Stormglass signal reaches 24 metres; bellows
work within 3 metres. The basket travels at 3 metres per second, with a minimum
half-second trip. The explicit ferrous set is `iron_ore`, `iron_ingot`,
`iron_fittings` and `bog_iron`.

`game/art/contraption_look.gd` describes authored collision bounds, cable height,
swept basket room, support probes, nearby activation, lamp/receiver feedback and
brief sorting/pressure animation. The 64-metre active distance pauses remote
machines; it does not simulate autonomous production. These are initial local
handling defaults, not a claim of balanced workshop throughput.

## Verification and recording

- **91 native checks, zero failures:** conserved cargo, aggregate capacities,
  explicit hand-fed sorting, separate signal/energy, pressure validation,
  once-only collection/removal, failed restores leaving the last good state,
  exact mid-trip round trips and rejection of malformed/corrupt records.
- **85 final Godot checks, zero failures:** all six workbench recipes and the
  normal kit placement path, actual raised-endpoint support and swept clearance,
  a newly built obstruction pausing travel, native plus scene restoration,
  landing collection, physical signal/lamp behaviour, the real work panel,
  finite existing seam impact and intact core refunds. Additional regressions
  reject currency/equipment cargo and verify that an overflowing core refund
  refuses atomically. The complete existing gameplay check pipeline also passed.
- **83 rendered checks, zero failures at recording time:** the earlier 78-check
  fixture plus a recorded loaded return haul driven through the real connected
  lever and drum. The seven refund/filter regressions above were added afterward
  and passed in the final full pipeline. The
  recording contains 100 Godot frames. Screen review found and corrected a cable
  transform error; a regression now verifies both mesh ends reach their actual
  anchors on a sloped span.

Reproduce native checks with `make contraptions` from `tests/sim`. Run
`godot --path game --headless res://tests/contraption_intensive.tscn` for the
engine fixture. Add `-- --contraption-record` in a rendered run to recreate
`build/strange-frontier/contraptions/index.html`, its playback frames and the
Lanternheart close-up. Generated review files remain outside version control.

The recording is an operation test stage. It establishes real transfers and
presentation, not discovery excitement, human outpost usefulness, cross-biome
travel performance or production balance. Those questions still need a normal
play session and the separate world review. There is no riding, free rope
physics, conveyor graph, automatic crafting, new mastery reward, fuel generator
or renewable rare-node rule in this slice.

The next automation step remains the approved future direction: one explicit
input container, one existing common-material process and one output container.
Signals and energy stay separate; each item has one owner; processing retains
the existing recipe transaction. A later source of wind or vent power can make
outpost position meaningful without inventing an unattended network now.
