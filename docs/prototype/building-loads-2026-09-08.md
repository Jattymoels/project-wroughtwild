# INT-03D — A useful building load

Status: **Implemented and checked; owner comfort review pending.**
Owner: Matty. Delivery: Codex. Baseline: `d6d528a`.
The owner's “Okay continue with next” selects this next bounded slice after
INT-03C, following the [playtest plan](playtest-iterations-2026-09-07.md).

## Scope and initial candidate

Make common-resource loads useful for a small home and workshop. Preserve
D-005/D-006 storage and death ownership, D-017 placement costs, D-021 refinement,
D-029/D-031 finite stock and machine buffers, and D-032 saved geography.
The clean starting tree includes the separate creature-model commit; it is not
part of this change. Isolated projects and APPDATA live under ignored
`build/building-loads/`; normal saves and running playtests are not used.

Before changing production tuning, the existing paid 6 × 6 m home fixture and
its recorded manifest establish **188 wood**: 36 cubes × 2, 70 wall panels,
36 roof slabs, a two-unit door, two-unit stair and six-unit chest. Its three
station recipes add 28 wood (bench 8, two frames 20), six fieldstone, sixteen
split stone dressed into eight stone, and four iron ore. Wedges cost additional
wood; one bench bundle costs three and supplies eight. Including a separate
six-wood staging chest gives a **225-wood** collection target. The smaller
2 × 2 m first-home fixture costs 46 wood but does not house the whole workshop.

Candidate comparison, chosen before tuning edits:

| Wood cap | Loads for 188 / 225 wood | Consequence |
| --- | --- | --- |
| 60 (baseline) | 4 / 4 | Repeated trips during one small build. |
| 120 | 2 / 2 | Better, but still splits the same project. |
| 240 (selected) | 1 / 1 | One timber project plus modest spare material. |

Set explicit **240-unit caps** on ordinary building timber, field/split/dressed
stone, the eight habitat ingredients and their eight finishes. The cap controls
ground pickup and chest withdrawal; crafting still preserves every output even
above it. Keep the default 40, wedges 40, hide/ores 30, curios 1, rare components,
metal ingots, charcoal and equipment behaviour unchanged. Avoid changing the
default because it also applies to special items. All four timber species share
the same selected cap. Six habitat recipes turn eight sources into four units;
reed and resinheart turn four into four. Thus a 240-unit mineral haul becomes
120 finished units, while the two light-source hauls become 240.

Set **960 shared units per chest**, enough for four selected full stacks rather
than allowing a single timber haul to fill the former 240-unit chest. This is
ordinary storage only; machine hoppers, trays, cargo and rare-source budgets
retain their current limits. Saved quantities must never be clamped to tuning.

## Implementation and checks planned

1. Preserve the baseline and reproduce the four-load constraint using actual
   finite gathering, physical pickups and paid chest transfers.
2. Complete the same paid home/workshop and habitat refinement/building in both
   versions. Record work presses, sources, quantities and hauling interruptions;
   accelerated travel does not measure minutes or player comfort.
3. Change only the selected hauling values and their plain-language purpose.
4. Check full/partial pickups, shared chest limits, old and over-cap quantities,
   death/trial ownership, repeated restoration and a fresh process. Run affected
   native and engine checks; update the work item/queue and publish this slice.

Capacity reduces trips, not trees or refinement losses. Report the measured
house cost and gathering demand separately; no yield, recipe, progression,
generator, combat, ambient sound or automation revision is selected here.
Human building comfort and the owner's original kit disappearance remain open.

## Measured outcome

The same deterministic V6 seed-77 route starts with no materials, stations or
unlock grants. It harvests a staging chest, collects the timber project into
that chest, crafts and places a bench/yard/forge, pays for the six-metre timber
home, and dresses quarry stock for a 6 × 6 m upper platform. This verifies a
useful next building increment, not a second finished house. Station recipes
run through the actual catalogue action and real station instances; building
uses ordinary palette selection, refusal and payment. The three stations stand
near the starter site; the existing full-home regression separately verifies
three stations inside each completed home.

| Measured operation | Baseline | Selected tuning |
| --- | --- | --- |
| Timber deliveries to the staging chest | 4 | 1 |
| Timber withdrawals for workshop/building phases | 5 | 2 |
| Raw shellstone deliveries / refinement withdrawals | 4 / 4 | 1 / 1 |
| Trees / released wood / contextual work presses | 17 / 238 / 102 | 17 / 238 / 102 |
| Quarry deposits worked / raw shellstone / work presses | 6 / 144 / 144 | 6 / 144 / 144 |
| Finished shellstone / paid platform cost | 72 / 72 | 72 / 72 |
| Paid timber pieces, including both chests | 194 wood | 194 wood |
| Bench, two frames and one wedge bundle | 31 wood | 31 wood |
| Timber remaining after the whole project | 13 | 13 |

The exact source IDs, work counts, released quantities and paid-piece ledger
match between versions. Fieldstone remains six units/six presses; iron ore four
units/two presses; sixteen split stone require forty presses and eight wedges,
then dress into eight stone. All eight habitat recipes retain their original
input/output ratios and fuel rules. There is no simulated travel
duration claim: movement between sites and pickup time are accelerated, and
hostiles are disabled. Deliveries count trips to store loads, not the separate
journeys between different resource habitats or stations.

The 17-tree requirement is still substantial for this home and workshop. The
capacity fix removes six repeated timber/quarry deliveries, but none of the
felling or quarry work. That cost/yield question remains a separate measured
follow-up; this slice does not assume the larger pack resolves all building
frustration. Finite resources and the need to find further supplies remain.

## Verification record

Godot **4.5-stable**, isolated copies and separate APPDATA, using
`tools/home_review.ps1 -ReviewSet building-loads`. Runtime/compiler launches
required platform escalation; the normal playtest and its save were untouched.
The original native DLL is reused because production changes only tuning.
The native rules suite was rebuilt from current source with the installed
compiler using C++17, `-Wall -Wextra -Werror -O1`.

| Check | Result |
| --- | --- |
| Final common drivers on preserved baseline | Boundaries: 201 passing assertions. Generated route: 1,317 assertions with exactly two expected failures, for the insufficient timber/quarry loads; all paid-building and restoration checks pass. |
| `building_load_review`, current | 1,299 passing assertions: real finite work/pickups, storage, workshop crafting, full paid home and platform, exact restoration. |
| Completed current project in a fresh process | 14 passing assertions, including two complete replacements of native inventory, finite resource state, all paid pieces and three owned stations. |
| `building_load_boundaries`, current | 201 passing assertions: all 23 common families, unchanged special caps, shared chest fullness, refused/partial transfers, complete crafted outputs above cap, old and over-cap saves, death recovery and trial-deposit settlement. |
| Boundary checkpoint in a fresh process | 6 passing assertions for exact carried/stored resources, equipment/progression, loose remainder and death pack. |
| Actual baseline world checkpoint loaded by current tuning | 14 passing assertions; no loss, replacement or re-payment of the older world's owned quantities and structures. |
| Native rules suite | 224,377 passing assertions, including hauling, crafting, equipment, death/trials and historical generation. |
| Engine unit / material / loose drop / save recovery | 398 / 158 / 148 / 175 passing assertions. |
| Pressure workshop / contraptions / full trial lifecycle | 60 / 85 / 6,218 passing assertions. |
| Legacy integration / two complete indoor workshops | 273 / 1,027 passing assertions. |
| Pickup feel / original Warden first-home journey | 17 / 290 passing assertions, including actual first-home entry. |

The baseline route reproduces the insufficient-load assertions while retaining
the paid construction and ownership checks. Its completed checkpoint also passes
14 fresh-process checks. Early fixture iterations exposed an unflushed manifest,
and comparisons of in-memory integer dictionaries against JSON's floating-number
representation. Closing the file before reading and comparing both sides in the
same JSON representation corrected the test drivers; no fields or equality
requirements were dropped. Boundary crafting checks use the native `crafted`
result, not an assumed return type. These were test defects, not game fixes.

The unchanged legacy integration driver also failed on both versions when
several physics steps occurred before the process-owned trial controller could
publish its reward. Both runners now give that particular numbered-step driver
`--fixed-fps 60`, ensuring a process turn between its physics steps. All 273
assertions remain unchanged and pass on both versions. This controls a test
clock; it neither forces a reward nor alters normal game timing. The independent
full trial lifecycle suite passes with its existing scheduling.

Evidence: `build/building-loads/logs/{baseline,current}/`, each copied game's
`building-load-manifest.json` and explicit checkpoints, and
`build/building-loads/native/sim-tests.log`. Test scripts and restart pairs are
registered in the ordinary headless pipeline. Generated projects, logs, saves
and binaries remain ignored. No frame-time improvement is claimed for this
data-only capacity change.

## Remaining review and publication

The initial capacity candidate still needs the owner's ordinary building review.
Other seeds, larger settlements and full expedition travel times are not measured
by this route. No new save field, migration, package, generator profile, yield,
recipe price, machine buffer or combat/ambient rule is introduced. Normal play
must restart to reload the tuning; already owned quantities stay exact.

Publication target: an ordinary checked commit to `main` and non-force push to
`origin/main` at the confirmed project repository. The delivery message records
the actual local commit and remote push separately. INT-04C is the next queued
slice; it is not implemented here.
