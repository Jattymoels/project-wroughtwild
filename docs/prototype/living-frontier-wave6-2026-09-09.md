# Living Frontier Wave 6 — repair gate, bounded contract and evidence

Owner authorization: 9 September 2026. Repair LF5-R1 first; only after its
regression passes implement LF-6A and LF-6B, publish checked slices, then stop
for orchestrator review. The [Wave 5 review](living-frontier-wave5-review-2026-09-09.md)
and [roadmap](living-frontier-roadmap-2026-09-08.md) supply the handoff.
Independent source/workshop art and generated local evidence remain outside
these commits. Optional Heat and configured rewards remain Wave 7; no new era.

## LF5-R1 contract, recorded before verification

Restore normal movement after publication installation and rollback both fail,
followed by a successful ordinary load. Failed loads must retain the recovery
stop. D-006 ownership, D-019/D-028 settlement and D-032 frozen geography remain
authoritative. Affected code is the publisher, player and complete save restore;
there are no tuning, schema, recipe or gameplay changes.

The stop remembers whether physics was enabled before publication failed and
releases only after complete physical restoration. Repeated stop requests keep
that original state. An unrelated disabled controller remains disabled. This is
a local transient lifecycle, never a persisted player or world property.

Plan: add that lifecycle; begin the regression with a moving ordinary controller;
inject both host failures; reject missing and physically failed loads; recover
through the normal load action and measure actual input movement without a
physics-enabling traversal helper. Preserve the existing both-event ownership,
rollback/retry, compatibility and separate-process checks. No missing design
decision blocks this repair.

### LF5-R1 result

The new actual-input regression passes **24 checks**, followed by **15 checks**
in a fresh process, zero failures. Before failure, 30 physics frames of ordinary
backward input move **2.4164 m**. Both publication host failures stop movement;
missing-file and physical-load failures retain that stop. Successful ordinary
`player.load_game` restores **2.4987 m** movement in the same session and
**2.4143 m** on separate-process recovery. Neither measurement calls the old
physics-enabling traversal helper. Repeated normal loads and deliberately
disabled presentation controllers also pass. The independent review's original
0 m reproduction is retained in its historical report.

The existing protected second-terrain suite passes **133 checks**, including
one-host-failure rollback, pending save/retry, actual collision walking across
both changes, exact paid construction/source/machine/recovery ownership and
depleted first-event stock. Second publication measured **14,570 ms**. Pairing
route/suspended restart pass **155 / 4**, Annex **172**, legacy Forge traversal
**122**, save recovery **175**, Trial lifecycle **6,221**, and native Annex/Pairing
settlement **55 / 72**, all zero failures. The remaining historical matrix
continues as additional compatibility evidence; it does not substitute for the
new actual-control regression. Repair gate passed before Wave 6 implementation.

Reproduction: `tools/living_frontier_wave5_checks.ps1 -Recovery` and
`-Campaign -Legacy -TrialNative`. Logs and synthetic saves are isolated under
`build/lf5`; the standard headless runner includes both new invocations. No
tuning or save field was introduced. Injected host faults are deterministic
recovery evidence, not a claim of spontaneous failure during human play.
The existing synchronous publication pause remains unchanged.

Repair publication: local commit **9036a12**, ordinary push to `origin/main`
succeeded. The full historical matrix also completed: double-host recovery 8;
second pending/applied/real-return 13/22/13; six frozen archives
15/23/23/13/23/14, all zero failures.

## Wave 6 bounded implementation contract

Recorded while the repair matrix runs; gameplay implementation remains gated
on LF5-R1 passing. This selects the roadmap's requested dedicated encounter
and control handoff under the current owner authorization. D-010/ADR-0003 own
the number/time split, D-006 Trial deposits and rewards, D-019/D-028 the three-era
campaign, D-025 existing build interactions, and D-032/D-033 geography and source
ownership. Relevant specifications are combat/builds, dungeon runs, progression
eras and the retained-world sections of world generation.

1. **LF-6A:** expose the existing Central Laboratory front body after the second
   physical award. Reuse the capstone's two floors, eight stages, choices,
   ordinary rewards and suspension. A separate policy-scoped treatment teaches
   the known channels before one dedicated human boss, the Conservator, in the
   final chamber. The human has an articulated primitive body, a scarred harness,
   committed gestures and its own attack state machine. It does not use the
   Warden's claw, breath, ward protection or ambient furnace-vent schedule.
2. The boss cycles three understandable tests: **White impulse** along one
   committed lane; **Blue retention then Red release** at a fixed marked player
   position; **Green propagation** branching a committed White direction into
   two lanes with a safe gap. Only one sequence runs at once (at most two major
   marked areas). Each release can hit once. Walk out, use actual cover, interrupt
   with existing stagger/freeze, or use the local apparatus; no element or
   Catalyst is an access requirement. Warnings and recovery remain stationary.
3. Two solid emergency-release pedestals, reachable by ordinary E interaction,
   cancel a channel and extend its recovery. They cool before reuse, grant no
   items, do no automatic player damage and do not affect workshop energy or
   sources. The fight's disposable apparatus belongs only to the active Trial.
   Pedestal use is optional; different builds may attack from range, interrupt,
   move through the gap or close during recovery.
4. **LF-6B:** tune the actual battle with different ordinary crafted builds and
   no found Catalyst. Final victory settles the existing completion haul and
   `forge_arc_complete` once. Under LF policy this one existing receipt also
   owns story resolution and captured control; there is no second trophy,
   currency or era. Central cannot resurrect the human or repay completion.
   The existing outer door visibly changes from hostile operation to a quiet,
   player-controlled release panel. Its E page confirms that both region changes
   remain and future configurable experiments are unavailable until Wave 7.

### Saves and intermediate slices

Keep `living_frontier_wave4` policy and LF3 geography. No source, stock, recipe,
machine, building, resource or terrain record changes. Annex revision one and
Pairing revision two remain; Central gets revision three using the same cleared
floor checkpoint codec. Native construction and restoration both enforce the
second physical award and refuse a resolved Central story before depositing
inventory. Validate that an LF completion receipt requires that award. Old saves
without completion remain unfinished; legacy capstone/maps retain their rules.

LF-6A may write the same final completion receipt through its normal Trial
settlement. LF-6B derives visible captured state from that receipt, so an
intermediate save needs no replayed victory or reward migration. Once the final
room settles, its normal return writes the full world/reward/ending checkpoint
before presenting the capture as saved. A failed ending write must explicitly
retain the live settlement for save retry and must not pay it again. Abrupt
termination before a successful checkpoint retains the preceding checkpoint;
active fights are not resumable. Death/abandon before victory preserve ordinary
Trial deposits/builds and cannot claim the ending. A completed story remains
completed through later world death, repeated loads and restart.

### Initial tuning and checks

Use `central_laboratory.json` for context, dedicated boss numbers, move geometry,
timings and apparatus positions/cooldown, each with a plain-language purpose.
Initial target: 600 life; 14 physical impulse damage; 20 fire paired damage;
1.1-second White warning; one-second Blue hold plus one-second Red warning;
1.3-second Green warning; 12 m lanes 1.4 m wide, branching 25 degrees each side;
3.2 m paired circle; 1.5-second ordinary and 3-second apparatus recovery;
12-second apparatus cooling. These are measured prototype tuning, not human
difficulty acceptance. No third-party art/package/service is introduced.

Verify live releases, committed marks, movement, cover, cancellation, recovery,
pedestal collision/use and damage at 20/60 Hz. Prove real wins for melee, bow
and spell builds, including live incoming damage and no forced boss death.
Separately label forced route/settlement tests: full physical entrance/floors,
records and apparatus; exact deposits/loot, death/abandon/retry, Central suspended
restart, ending-save failure/retry and fresh-process completion. Preserve the
Wave 5 legacy/pending/applied matrix and source/machine/recipe native checks.
Inspect rendered tells and captured controls; record actual combat outcomes,
checkpoint timings and remaining human readability/difficulty limits.

No missing decision blocks this bounded selection. The eventual configured
experiment fiction/rewards and Heat rules stay unselected for Wave 7. No extra
hybrid roster, era, world transformation, broad automation or unrelated art
adoption is part of Wave 6.

## LF-6A author evidence

Dedicated `Conservator` script/scene, native Central treatment, existing physical
door and two emergency releases implemented. It uses Boss ancestry for existing
damage/status classification only; its configuration, movement, channel loop,
gesture mesh, tells and recovery are separate. White commits one lane, Blue
holds the player's original position before Red releases there, and Green
branches White into two damaging lanes. Actual cover blocks each release.
Stagger/freeze cancel channels; both apparatus pedestals cool together after E.
The ordinary floor modules and rewards remain those of the legacy capstone.
Only hostile boar specimens occupy preceding rooms; passive White/Green
wildlife are not turned into required kills.

`tools/living_frontier_wave6_checks.ps1 -Boss -Central -Native -Visuals` covers:

- **1,867 combat checks**, zero failures: live contact, committed marks, actual
  side stepping, both Green branches and safe gap, cover, stagger/freeze,
  apparatus cancellation and recovery at 20/60 Hz. No physics immunity or
  forced boss defeat is used for the three build wins. All use paid ordinary
  starter weapons and an empty Foundry, with synthetic campaign access only.
- Warden **13.78 s / 36 casts / 100 life / 0 releases**; Ranger
  **36.13 s / 41 casts / 100 life / 12 releases**; Kindler
  **36.17 s / 68 casts / 100 life / 12 releases**. Warden interrupts all
  channels; the ranged bots evade live releases. Separate contact tests take
  real damage. These are deterministic feasibility tests, not human difficulty
  approval; melee's interrupt advantage is a known tuning limitation.
- **173 route checks**, **834.5 m actual walking** through the existing entrance,
  eight stages, records, module links, apparatus and exact return. Earlier
  encounters use forced outcomes/invulnerability for route coverage; only the
  final chamber uses live casts and damage (**11.22 s / 23 casts / 100 life /
  1 release**, retained route boons). Do not use this as a full-Trial balance run.
- Separate-process Central boundary **4** and ending **4** checks; native
  ownership/settlement **47**, all zero failures. Boundary revision three
  retains exact deposits/build/loot and cannot resurrect a resolved human.
  A save-decoder omission of empty earned-mastery lists was exposed by real
  practice, repaired without changing perks, and covered by exact round trip.
- Existing native main **224,380**, source **213,482**, machine **601**, frozen
  generation **17,716**, dual-resonance **632**, Annex **55**, Pairing **72**;
  live hybrid **2,801** and single-source **234**, all zero failures. The final
  empty-mastery codec repair then passed the Central native/restart checks.
- **9 rendered checks** with inspected White, Blue, Red and Green captures
  under `captures/lf6`. The articulated human and major warning geometry are
  distinct primitive placeholders. These observer views prove rendering, not
  first-person human readability in a busy chamber.

Logs, synthetic checkpoints and diagnostics are isolated in `build/lf6` (older
regressions in `build/lf5`). The standard native/headless runners include Central.
All new numeric rules live in `central_laboratory.json` with their player-facing
purpose; no extra tuning was scattered into combat logic. No geography,
transformation, recipe, finite stock, paid construction, source or machine
ownership was changed. Unrelated art work remains outside this slice.

LF-6A publication: local commit **f552c3c**, ordinary push to `origin/main`
succeeded. The subsequent LF-6B slice below completes the visible panel,
automatic ending checkpoint and recovery evidence using the same receipt.

## LF-6B author evidence and review handoff

The normal final reward/return now checkpoints the full settled world before
the finale claims that ownership is saved. `forge_arc_complete` remains the
only persistent receipt. The existing Central exterior changes its Blue/Red
feeds to quiet lights, releases its handle, labels control as yours and offers
inspection instead of re-entry. A failed write leaves that live ownership,
adds **SAVE NEEDED** and exposes **Retry ending save**; successful ordinary save
or the retry button clears the transient warning. Successful complete restore
clears the warning only after all physical ownership is installed. The ending
page explains both lasting region changes and future unavailable experiments.

Current author checks, all zero failures:

| Evidence | Result and boundary |
| --- | --- |
| Final actual combat | 1,867 checks repeated with final integration; all three no-Catalyst starter wins retain the LF-6A measurements above |
| Central complete return | 186 checks; 834.5 m walked; prior encounters forced, final human live; exact automatic ending/haul checkpoint |
| Separate-process cleared boundary | 4 checks; exact suspended ownership and dedicated human identity |
| Separate-process ending | 36 checks; exact native rewards/world/loot stream, visible control, repeated ordinary save/load, no story replay or payout |
| Later world death restart | 30 checks; every positive material quantity belongs to one recoverable pack, equipment/pack items/ending remain owned; fatal open-world hit is injected to isolate ownership |
| Failed ending write and retry | 194 checks; same actual final fight, preserved preceding checkpoint, visible retry, one settlement, then separate-process ending/death recovery |
| Natural final-human death and retry | 47 checks; six actual released hits cause one ordinary Trial death; 304.6 m actual floor-two route; deposit/build, finite world ownership and both ledgers survive ordinary retry and boundary reload |
| Separate-process Trial death | 18 checks; exact returned ownership, locked controls and available Central retry |
| Rendered control pages | 13 checks, including actual E ray and settled viewport bounds; before/after door and finale inspected |
| Native save/economy after codec repair | 224,380 main checks and 47 Central checks; no perk, currency or reward rule was changed |

The failed-write route separately completes the same live final fight. A real
unwritable destination leaves the preceding boundary bytes intact. Repeated
failed ordinary save retains the unsaved indicator; actual retry-button use
writes the ending without another native settlement. The measured checkpoint
and panel action was **258–372 ms** on this machine across the two checked runs. A fresh process then recovers
the retried ending and later death pack with the same ownership checks above.
This exercises file-open failure and the existing staged writer; it does not
claim exhaustive OS power-loss/filesystem fault injection. A crash before a
successful checkpoint retains the preceding save; active fights are not resumable.

Exact world comparisons include seed/profile, loot stream, placed blocks,
stations, excavation, finite resource records, source/machine state and loose
drop/death-pack ownership. Loose-drop cosmetic clocks are frozen immediately
when restored for these comparisons; spatial float32 round trips use the
existing 1e-6 tolerance, while counts, identities, ages and seeds stay exact.
Inventory zero-count spent IDs are not physical quantities in a death pack.

Final compatibility reruns include LF5-R1 **24 + 15**, Pairing **155 + 4**,
protected second terrain **133**, double-host recovery **8**, pending/applied/
real-return **13/22/13**, six published archives **15/23/23/13/23/14**, save
recovery **175**, Trial lifecycle **6,221**, legacy Forge traversal **122** and
Annex **172**, all zero failures. The final editor registration and 120-frame
fresh `--living-frontier-wave6 --world-seed=77` smoke also pass without script
or engine errors. Concurrent-run publication measured **19,270 ms** for Pairing
and **20,938 ms** for Annex, preserving the known synchronous pause.
The source/machine/recipe and frozen-generation suites recorded under LF-6A
also pass. Expected corrupt-input warnings in those recovery suites are labelled
fault inputs, not ignored failures.

Reproduce from the current native build:

```powershell
./tools/living_frontier_wave6_checks.ps1 -Boss -Central -SaveFailure -Recovery -Native -Visuals -Controls
./tools/living_frontier_wave5_checks.ps1 -Campaign -Legacy
```

The standard native and headless runners include Central and recovery. Isolated
synthetic checkpoints/logs remain in `build/lf6` and `build/lf5`. Inspected
captures are retained for review: [White](../../captures/lf6/white.png),
[Blue](../../captures/lf6/blue.png), [Red](../../captures/lf6/red.png),
[Green](../../captures/lf6/green.png), [locked exterior](../../captures/lf6/control-before.png),
[captured exterior](../../captures/lf6/control-captured.png),
[entrance page](../../captures/lf6/control-before-page.png),
[saved controls](../../captures/lf6/control-captured-page.png) and
[finale](../../captures/lf6/finale-page.png). Human tell images are observer views;
control images use the actual first-person camera after ordinary saved-world load.

### Remaining limits and stop

- Human full-Trial acceptance remains open. The Warden interrupts every channel
  in the isolated starter test; ranged bots evade all releases. This is proof
  that lucky Catalysts are unnecessary, not proof of an accepted difficulty curve.
- The human, harness and apparatus remain authored primitives. Silhouette,
  close-view gestures, crowded-HUD readability and narrative pacing need human
  review. Earlier Trial-room outcomes are forced only in route/ownership tests.
- Terrain publication retains its synchronous pause. No geography, second-event
  performance, construction, stock, recipe, source/machine or unrelated art
  redesign is included. LF-6B adds no combat tuning or save schema.
- Optional Heat, configured challenge selection/rewards and any related tuning
  remain Wave 7. There is no third transformation or fourth era.

Author work stops here for orchestrator review after checked publication. This
record does not claim independent review or human acceptance.
