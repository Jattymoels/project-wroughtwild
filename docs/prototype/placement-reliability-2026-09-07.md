# INT-03C — Placement stalls, corner fit and fixture ownership

Status: **Implemented, owner review pending.** Publication is recorded separately.
Baseline: `80dde32`, clean `main`. The owner explicitly selected this one slice
from the [eight-slice plan](playtest-iterations-2026-09-07.md). Normal saves and
playtests are excluded; Godot copies, separate APPDATA, checkpoints and captures
are under ignored `build/placement-reliability/{baseline,current}`.

## Scope and plan

Reproduce click/deferred stalls, seat existing station bodies legally in the
reported type of corner, and audit all seven fixture kits through actual
placement, interaction, restoration and removal. Relevant contracts are
D-010/D-017/D-029/D-031/D-032, construction and world generation. Existing
geography, finite stock, progression, costs, station dimensions and save schema
remain authoritative. No other queued slice or timber-demolition change belongs
to this work.

The screenshot's seed, location and exact floor are unknown. The kit called
“glassstone” is unidentified. Representative cases must not be presented as an
exact replay of the owner's session, and missing possessions are not refunded
without establishing their saved ownership.

## Reproduction and implementation

The first matched timing driver reproduced approximately **234–262 ms** median
deferred scenery refresh per ceiling placement, versus **0.5–2.2 ms** in the
click handler. It retained progressively larger construction in full V6 seed 77
scenery. The dominant path unconditionally refreshed every regional decoration
and rebuilt every leyline tile after each placement. These initial diagnostic
numbers precede the final completed-home fixture below; one short rendered
diagnostic overlapped this initial baseline run, so final comparisons run serially.

GridPlacement now retains the actual changed piece bounds (including the existing
0.3 m scenery clearance), coalesces adjoining rapid edits, and passes them to
the deferred refresh. Regional batches, individual instances, terrain cover,
ruin pieces and leyline tiles outside those bounds keep their existing output.
Batch bounds include authored overhang; trace bounds include branches, twigs and
chipped edges. Collision and native registration remain immediate; ruin visibility
and collision still change together on the established deferred refresh.
Explicit generation/save/audit refreshes remain complete. Cheap terrain-reference
checks also refresh tiles whose support changed before construction. Geometry
definitions and trim materials are read once per shape/family within a refresh;
they are reread on the next refresh so live material changes remain visible.

The old station anchor puts a 0.96 m body into a wall skin extending 0.125 m
inside its cell. Eight full/half-grid corner cases reproduce refusal on baseline.
The new shared preview/placement pose seats the unchanged body against actual
wall faces, choosing the nearest clear horizontal offset within half a registry
cell. This usually moves the anchor **0.107 m** away from each wall. Full body
width, original vertical contact tolerance, genuine obstructions and kit payment
remain. Saved station positions already support these offsets; no new save field
or migration is needed. The old single-wall regression now puts its wall through
the body centre, preserving a genuine obstruction beyond the seating range;
independent full-body overlap and player-motion checks verify legal corners.

Only one presentation parameter is introduced:

| Resource value | Default | Player effect |
| --- | --- | --- |
| `station_look.gd: placement_contact_gap_m` | 0.002 m | Keeps a two-millimetre gap between a seated station and a wall, avoiding exact-contact physics noise without shrinking either body. |

## Fixture investigation

The native placement transaction already creates the machine before consuming
one kit. All seven types (lamp, cargo drum, landing, Stormglass lever, magnetic
sorter, bellows and pressure feeder) are tested at four rotations and at raised,
far-from-origin positions. Catalogue/camera/click tests also place every kind
on actual generated V6 terrain. Baseline and current create visible, interactable
fixtures with matching native/preview/scene poses. Duplicate/refused placement
retains the next kit, and X removes the aimed machine once.

An initial generated interaction test falsely reported four unreachable fixtures:
SpringArm's internal update moved the camera after the driver aimed it. Actual
captures showed intact visible fixtures. Aiming from the settled eye corrected
that harness error; it is **not a game fix or a disappearance reproduction**.
The owner's disappearance remains unreproduced on this baseline. This slice
does not change native fixture ownership, grant replacement kits or certify the
unknown reported save. Exact fixture/source/possession restoration is checked
in separate process invocations as well as repeated loads.

## Verification and remaining limits

Final serial Forward+ measurements use Godot 4.5 stable, the NVIDIA RTX 5090,
V6 seed 77, 1440 × 900, VSync off and a 120 fps cap. Each of six homes samples
24 paid roof placements and the following four process-frame intervals. The
floors/walls use fixed inspection stock and direct native construction setup;
the remaining roof is paid and each completed home proves native enclosure.
The excavated case asserts actual accepted terrain edits. Baseline and current
both pass **415 checks**. No other review process runs during final sampling.

The first interval starts at click dispatch and includes deferred work. The
three later intervals remain separately present in each raw timing JSON.

| Ground / home width | Pieces at sample end | Baseline median / p95 / worst ms | Current median / p95 / worst ms |
| --- | ---: | --- | --- |
| Flat / 6 m | 131 | 242.21 / 248.83 / 251.54 | 9.30 / 10.97 / 15.83 |
| Flat / 10 m | 386 | 246.28 / 256.39 / 256.93 | 12.16 / 15.76 / 16.70 |
| Hill / 6 m | 593 | 249.20 / 259.04 / 260.62 | 12.77 / 18.17 / 18.48 |
| Hill / 10 m | 848 | 255.35 / 268.95 / 271.07 | 15.28 / 24.16 / 24.35 |
| Excavated / 6 m | 1,055 | 265.68 / 267.74 / 267.93 | 16.94 / 29.54 / 31.79 |
| Excavated / 10 m | 1,310 | 273.51 / 293.69 / 295.18 | 21.29 / 32.85 / 34.80 |

Deferred refresh medians fall **235.86–262.22 → 4.04–9.73 ms**. Click-handler
medians remain **0.51–2.33 → 0.47–2.23 ms**; native/terrain validation, piece
creation and trim work are inside this interval. The unchanged-body seating
does not affect ordinary block validation. Raw rows retain separate trim,
validation, deferred-refresh, process/physics and four-frame samples.

The residual **34.80 ms** worst placement interval and **22.46 ms** worst
deferred refresh occur in the densest excavated comparison. Streaming/support
updates and the remaining structure scan still share work with rendering. This
is a substantial removal of the repeated quarter-second interruption, **not**
a claim that all large-settlement frames meet 16.7 ms or that every hill/seed is
covered. The previously documented unrelated intermittent pause is not diagnosed
by this experiment. Normal saves and processes were never used for comparison.

| Functional evidence | Result |
| --- | --- |
| `placement_transactions` | **470 passing checks** in the final rendered driver: seven kits × four rotations, actual click/E/X, raised distant poses, visible art, duplicate-kit refusal, repeated saves, full/half-grid corners, actual corner ghosts, full horizontal body clearance, real capsule collision and exact saved offsets. Baseline reproduces eight corner refusals. |
| Fresh `placement_transactions --placement-restore-only` process | **60 passing checks**: 28 scenes, exact native poses, fixture/source ledger, inventory and progression. |
| `placement_generated_fixtures` | **44 passing checks** on baseline and current V6 terrain, with actual catalogue, camera preview, click, E and rendered captures for every kit. |
| Fresh generated fixture process | **25 passing checks**: exact V6 save, all seven visible/interactable fixtures and no duplicate native/scene owner. |
| `placement_scenery` | **3,190 passing checks** against full-reference geometry, transforms, visibility and collision after rapid distant edits, removal and save replacement. Finite resource and machine/source state remain exact. |
| Existing complete homes | **1,027 passing checks**: two fully paid homes, real use, movement, shelter, storage and restoration. |

Affected regression results: engine unit **398**, art **11**, integration **273**,
station placement **98**, station obstruction **84**, terrain placement **174**,
door persistence **467**, material joins **141**, contraptions **85**, pressure
workshop **60**, feeder presentation **22**, ecology/buildings **102**, cataclysm
integration **170**, smithy story **122**, loose-drop saves **148**, and save
recovery **175**, trial lifecycle **6,218**, terrain streaming **57,897** and
stream scheduling **5,654**, all passing. A generated V6 seed-77 home with
excavation, finite resources, storage and an in-progress feeder also passes
**659 checks** through two travel/return circuits and **20 checks** on a fresh
process restart. The latter restores the exact state and resumes its existing
operation. Fresh imports and `git diff --check` pass.

The new fixtures are `placement_transactions`, `placement_generated_fixtures`,
`placement_scenery` and the opt-in rendered `placement_performance_review`.
Scenery verification compares submitted instance transforms, mesh arrays,
visibility and collision against a complete refresh after rapid distant edits,
removal and save replacement, once existing terrain-arrival work has completed.
The common driver freezes timed background streaming during this comparison:
otherwise terrain publication between snapshots compares different support.
Explicit synchronous arrivals still run; existing streaming regressions remain
separate. No failing equality assertion was removed.

Reproduce with `tools/home_review.ps1 -ReviewSet placement-reliability -Prepare
-Import -Scenes placement_transactions,placement_generated_fixtures,placement_scenery`.
Run the two transaction scenes again with `-ExtraArguments
'--placement-restore-only'` for fresh processes. Add `-Rendered` for the saved
corner and all-fixture captures. `-Phase baseline` replays only the common test
drivers against the preserved production copy; expected corner failures are
reproduction evidence. `placement_performance_review -Rendered` writes
`captures/placement/placement-timing.json` within each phase. Run timing processes
serially. The helper preserves the baseline and stops only its own processes.

The normal headless pipeline includes all three functional drivers and their
fresh-process fixture checks. Rendered timing stays opt-in. No native library,
generation input, production asset or third-party package changed.

These engineering checks establish behaviour on this machine and controlled
seeds. The exact reported save and unidentified kit are not inspected. Owner
building comfort and the original disappearance remain open observations; no
additional playtest is required to begin this work. The separate carry, sound,
Foundry, combat, population and landscape slices remain unimplemented here.

## Publication

The checked slice is prepared for an ordinary commit on `main` and non-force
push to the owner's confirmed `origin/main`. Unrelated art/reference and
world-premise work appeared during this task, including neighbouring README and
registry additions. Only INT-03C files/hunks belong to this commit; that work
is preserved separately. Local commit and remote publication are reported
separately in the delivery message.
