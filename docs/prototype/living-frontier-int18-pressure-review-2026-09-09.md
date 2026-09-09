# INT-18A — independent pressure validation review

9 September 2026. Reviewed slice: `f5b69e4`, following the
[Wave 7 review](living-frontier-wave7-review-2026-09-09.md). The submitted
[validation record](living-frontier-int18-pressure-validation-2026-09-09.md)
and its retained receipts describe two matched cohorts and two diagnostics.
Unrelated creature art, its decision/queue changes and pre-existing local
captures and diagnostics are outside this review.

**Technical clearance for INT-18A:** the submitted validation slice passes
independent review, with no new blocking implementation defect found. All eight
attempts and their sixteen fresh-process recovery checks pass. Four victories
and four Crossfire deaths reproduce the submitted outcome pattern. Complete
Crossfire victory and human balance acceptance remain open; this clearance
does not mark those outcomes achieved.

## Scope and source audit

The submitted commit changes test harnesses, evidence and documentation only.
Production scripts, native rules, tuning and published save fixtures are
unchanged from the cleared Wave 7 baseline. D-006 ownership, D-010 combat,
D-025/D-026 crafting and Foundry, and D-028 configured Trial rules remain intact.
No gameplay repair or tuning selection is introduced by this review.

The new harness overrides the inherited forced encounter fixtures. Its live
path does not call their forced clears, immunity or life-reset setup. Every
entered room uses actual casts, incoming damage, capsule movement and physical
reward interaction. Combat stays enabled through gallery travel; trial clocks
are advanced once per physics frame. The next room checks its life against
the preceding reward. A natural death ends the attempt and is retained as a
death. The duplicate-reward probe runs only after completed settlement.

The comparisons use the same saved tier-one offer and exact prepared native
hash within each three-attempt cohort. Both pressures are compatible with that
offer before the attempts start. Rolled conditions, modules, target, boss,
equipment and base reward rules remain matched. The Sound-grade and Ember-only
Crossfire probes are separately labelled diagnostics.

The author clearly labels supplied campaign access, recipe inputs, facilities
and earned-ingot events. The character is an archived classless melee build.
The new gear, manufactured Catalyst and recovery Kind use ordinary paid
transactions; this is preparation evidence rather than proof of gathering
those supplies in one new campaign. World spawning and loose-drop clocks are
frozen for exact ownership checks; active Trial damage is not frozen. The bot
reads enemy state and aims directly, so it does not establish human balance.

## Independent evidence

The current GDExtension rebuild passes. Native configuration and settlement
pass **54,286 checks**; live pressure contacts and clocks pass **107 checks**
at 20/60 Hz. The broader Wave 7 campaign matrix remains the earlier reviewed
evidence; production code has not changed in this validation slice.

The eight attempts pass **207,252 assertions**, mostly continuous invariants
rather than distinct scenarios. Sixteen separate-process checks add **448**
assertions, and the receipt collector passes **362 checks**. Including the
pressure-effects scene, the 25 engine invocations pass **207,807 assertions**.
Every suite reports zero failures; no engine error was emitted.

| Independent preparation / pressure | Outcome | Combat seconds | Incoming damage | Casts / kills | Lowest life |
| --- | --- | ---: | ---: | ---: | ---: |
| Recovery / none | Five-room victory | 89.48 | 154.43 | 110 / 49 | 65.18% |
| Recovery / Crossfire | Death in room 4 | 56.15 | 216.26 | 93 / 36 | 0% |
| Recovery / Relentless | Five-room victory | 69.75 | 141.27 | 111 / 49 | 75.73% |
| Added Foundry / none | Five-room victory | 88.75 | 111.46 | 91 / 49 | 78.89% |
| Added Foundry / Crossfire | Death in room 3 | 47.58 | 183.44 | 66 / 34 | 0% |
| Added Foundry / Relentless | Five-room victory | 88.68 | 111.18 | 91 / 49 | 78.20% |
| Sound gear diagnostic / Crossfire | Death in room 4 | 56.15 | 216.26 | 93 / 36 | 0% |
| Ember-only diagnostic / Crossfire | Death in room 3 | 48.42 | 200.68 | 72 / 33 | 0% |

The collector confirms identical native preparations within each cohort and
exact saved offer identities, decimal-text seeds, conditions, reward rules and
recipe payments. Successful runs pay 56 targeted clay without extra pressure
and 72 with Relentless; general materials, the separate Kind purse, three gear
rolls and the Ventlung retain their rules. Crossfire deaths lose unbanked
rewards and retain deposits, existing gear and campaign/world ownership.
Both ordinary and fresh-process restores retain the result; the next offer
physically enters and abandons in a disposable continuation. Pre-entry recovery
retains the original unopened offer, and an active attempt cannot overwrite it.

**Reproducibility limit:** exact combat traces differ from the author's retained
receipts despite the same source, preparation, offer and combat seed. In this
rerun, the recovery baseline's pre-boss rooms three/four also differ from its
Relentless counterpart. The added Foundry pair retains matched pre-boss traces.
These observations do not establish that Relentless makes the run faster or
easier, or identify the cause of the trace variation. Preserve repeated samples
and control runtime variation before using small numerical differences to select
tuning. The qualitative outcomes, accounting and ownership checks all reproduce.

Automatic return checkpoints measure **278–406 ms** in these local concurrent
runs. This is not an isolated performance benchmark. No extra rendered or human
playtest acceptance is claimed by this review.

The author receipts were copied to
`build/int18-a-orchestrator/author-receipts` before rerunning. The committed
author evidence remains unchanged. Independent receipts and logs use the
existing `build/int18-a` runner directory and isolated test APPDATA. The collected
independent receipt is `build/int18-a-orchestrator/evidence.json`; build output
is beside it. This review does not access or alter the owner's game saves.

Reproduce the attempt/recovery matrix with the commands in the submitted
validation record, then collect review output without overwriting author evidence:

```powershell
python tools/living_frontier_int18_report.py --output build/int18-a-orchestrator/evidence.json
```

## What remains open

- **Crossfire completion.** Its full victory is not established by a native
  forced settlement check or by a natural death with correct accounting.
- **Balance beyond these fixtures.** One offer, one combat seed and two related
  melee preparations cannot establish win rates, all-class balance, upper-tier
  difficulty or the ten-minute player run target. The known Conservator/Warden
  interrupt advantage remains separate.
- **Continuous campaign.** These runs begin at an archived ending. Gathering,
  paid construction, both terrain changes, the human ending and another
  experiment still need one continuous fresh-world ownership history.
- **Performance and clarity.** This slice changes no publication or restore
  scheduling and adds no interface or art acceptance. Concurrent local timing
  observations cannot establish a performance improvement.

The proposed Crossfire warning multiplier of 1.2 remains **unselected tuning**.
The inherited melee bot reacts to nearby hazards and boss inhale, but does not
specifically read ordinary ranged windups. Its pursuit can also prioritise a
nearby target over maintaining distance from shooters. Ranged damage is useful
diagnostic evidence; it does not isolate warning duration as the cause. A later
warning-time experiment should measure whether the chosen movement policy can
actually use the added warning, alongside matched existing-rule counterplay.

## Proposed next validation slice

Continue with the proposed **INT-18B: one continuous fresh campaign**. Retain
Crossfire's open completion/balance item. This closes a
different remaining foundation gap without selecting a combat nerf from one
scripted policy. Crossfire balance, transition performance and interface work
remain separate follow-ups.

Start one fresh Living Frontier world with a recorded seed and an existing
starting class. Carry that same save through paid preparation, a usable home
and workshop, the Collection Annex, Pairing Hall, both physical terrain
publications, the Conservator ending and a configured repeat. Use the base
configuration or the already demonstrated Relentless setting for that repeat.
Ordinary deaths, re-preparation and save/restart segments are valid parts of
the journey; an archived milestone or supplied inventory is not evidence of
earning that segment.

### Suggested next-session prompt

```text
Work in C:\Users\Matty\Dev\project-wroughtwild.

Follow AGENTS.md's reading order, then read:
- docs/prototype/living-frontier-int18-pressure-review-2026-09-09.md
- docs/prototype/living-frontier-int18-pressure-validation-2026-09-09.md
- docs/prototype/living-frontier-wave7-review-2026-09-09.md
- docs/prototype/living-frontier-roadmap-2026-09-08.md

Execute only INT-18B: one continuous fresh Living Frontier campaign. Select and
record one existing starting class and fixed seed. Begin through the ordinary
new-world path and preserve the same character, world and ownership history.

Gather and pay for useful equipment, a usable home/workshop and at least one
ordinary costly Catalyst. Complete the Collection Annex, Pairing Hall, both
protected physical terrain changes, the human Conservator ending and one
configured repeat using no extra pressure or Relentless Boss.

Use live combat, physical travel and reward interactions. Do not supply
inventory, facilities, earned events, unlocks or archived campaign milestones;
do not force kills, inject immunity or reset life. Preserve normal game clocks
and finite-resource work in the primary evidence. Label scripted controls and
any separate diagnostic fixtures. Honest deaths and ordinary re-preparation
remain part of the journey.

Check meaningful ordinary and fresh-process save boundaries, including paid
construction/storage, source and machine ownership, both terrain ledgers,
once-only rewards, the ending and another usable offer batch. Segmented runs
may continue ordinary checkpoints; they must not replace unfinished progress
with a prepared archive.

Fix reproducible implementation defects within accepted rules and verify them.
If the journey cannot progress, report the concrete blocker and propose a
bounded next change without inventing progression or balance rules. Leave
Crossfire tuning, performance changes and art as separate follow-ups.

Record evidence, player journey and limitations, commit and ordinarily push
checked scoped work under AGENTS.md, then stop for orchestrator review.
Preserve unrelated work. Do not add another implementation wave or new content.
```
