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
