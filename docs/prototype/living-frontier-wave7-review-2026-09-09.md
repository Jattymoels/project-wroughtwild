# Living Frontier Wave 7 — orchestrator review

9 September 2026. Reviewed baseline: `ebebc5d`, including LF-7A `afdb4bb`
and LF-7B `ebebc5d`, after the [Wave 6 clearance](living-frontier-wave6-review-2026-09-09.md).
Interleaved Green workshop art, active route art and pre-existing modified
Wave 6 captures are outside this review. This is a documentation-only review;
automated checks use isolated synthetic saves.

**Technical clearance:** LF-7A/B pass independent review with no new blocking
implementation defect found. Native rules, the complete live base run, physical
controls, pressure effects, return/recovery and earlier campaign regressions
pass. All seven planned implementation waves have now passed technical review.
Complete added-pressure victories, upper-tier balance, a continuous fresh
campaign and human presentation acceptance remain separate work below.

## Behaviour assessed

Captured Central now combines the existing saved offers and unlocked tiers
with no extra pressure, Crossfire or Relentless Boss. LF experiments stop at
tier ten. Previewing does not consume a batch or deposit goods. Successful
entry validates the selected offer, commits its pressure and consumes the
existing batch; remembered tier/pressure fields preserve old gate records.
Duplicate, overlapping and incompatible pressures refuse without rerolling.

Crossfire adds two projectiles over the existing committed fan. Relentless
shortens the existing boss recovery and attack interval while retaining full
warnings. The 24-enemy and two-major-hazard limits remain. The added pressure
multiplies only targeted cache/secret source material by 1.25, before rounding
down. General materials, the Kind purse, three gear rolls and one completion
core retain their stated rules. Previews explicitly precede temporary boons.
The LF equipment cache retains ordinary gear without guaranteeing a Catalyst;
legacy Forge shrine rewards remain intact.

The five-room creature experiment retains the defeated human, both terrain
ledgers and all three campaign eras. Its physical exit is reachable from the
entrance, unavailable during fights, and offers banking after the fourth
reward. The offering positions now allow return to the gallery across every
existing room module. No partial path or teleport is accepted as route proof.

Success, banking, abandonment and death checkpoint the already settled return.
Failed writes preserve the preceding disk checkpoint, show a retry action and
disable reconfiguration. Retry writes the current ownership without another
settlement. Ordinary and fresh-process loads retain rewards, offer state and
the owned world. Active experiments remain non-suspendable; a crash before a
successful return checkpoint restores the preceding save.

## Independent evidence

The current GDExtension rebuilt successfully. The nine native suites pass
**511,271 checks**, comprising 54,286 new configuration/settlement checks plus
456,985 earlier campaign, save, generation, extraction and workshop checks.
The engine matrix passes **16,637 checks across 39 counted invocations**, plus
one additional combat invocation with 12 live samples and zero setup failures.
Every counted suite reports zero failures. These are focused Living Frontier
and legacy regression checks, not a rerun of the entire repository pipeline.

| Wave 7 check | Independent result |
| --- | --- |
| Physical Central controls | 42 headless and 43 rendered checks; actual approach, E ray and Enter-key activation |
| Complete live run, settlement, bank/abandon and failed-write retry | 5,441 checks, zero failures; 320.1 m of physical approach/gallery travel |
| Separate-process completion, retry and death restore | 45 checks, zero failures |
| Room and exit geometry | 256 checks; 4,584.9 m across eight modules and five room positions |
| Pressure contacts and clocks | 107 checks at 20/60 Hz; actual Crossfire projectiles, damage, movement and cover |
| Isolated added-pressure combat | 12 live starter samples, zero setup failures: five wins and seven deaths |

The live full run uses tier one, saved offer two, with **no extra pressure**
and the rolled Warded Rares and Volatile Rares conditions. All five rooms fight
live: **87.87 seconds, 107 casts, 49 kills and 185.81 incoming damage**, with
recovery supplied by the build and a lowest life fraction of **22.94%**. The
boss takes 11.53 seconds. The run uses no forced enemy deaths, invulnerability
or between-room healing reset. Actual cache, optional secret, completion core,
separate material/purse stores and all three equipment rewards match their
previews. Repeated resolution pays nothing.

This is an archived, historically classless melee character with supplied
ordinary crafting inputs, facilities and earned-ingot events. It pays for the
iron mace, bronze mail, temper, three Marrows and Sipping Marrow exchange. Two
existing attacks share the prepared Vigour/Edge recovery route. Its separately
manufactured Ember stays owned and unused. This proves a prepared live base
run; it does not prove a fresh campaign or a complete added-pressure victory.
The per-frame assertion count and combat measurements differ from the author's
run, so the review records its own observations rather than copying that receipt.

The twelve isolated pressure samples use the named Warden, Ranger and Kindler
starter builds, paid wooden weapons and hide vests, supplied inputs and synthetic
campaign access. Crossfire boss samples win for all three classes; Kindler also
wins both pack samples. The remaining samples die. The pressures select
different compatible offers, so these are contact/feasibility checks rather
than a matched balance comparison. Four preceding rooms are forced only for
isolated boss setup.

The separate natural-death fixture takes **seven real hits, 135.62 damage in
3.53 seconds**, after four explicitly forced setup rooms. It loses unbanked
rewards, restores deposited goods/purse/equipment and saves the next usable
configuration. Banking and failed-write fixtures use forced outcomes to isolate
accounting and physical extraction; those outcomes are not counted as combat wins.

The current completion checkpoint takes **301 ms**. The rendered configuration
check measures **11,838 ms** for archived-world load and **214 ms** for entry.
These are review-machine workload observations, not isolated benchmarks.

### Earlier campaign and paid-world continuity

- LF5-R1 passes **24 + 15** actual-input and fresh-process recovery checks.
- LF3-R1 passes **59 / 61** checks for seeds 5 / 77: all 24 full routes walk
  successfully with zero capsule contacts against laboratory shells.
- The paid extraction-to-Catalyst/building journey passes **940 + 7** checks,
  including separate-process restore. It performs actual harvesting, all five
  ordinary Catalyst recipes and paid brick construction. Travel and active
  source-formation time are compressed; inventory, stock, stations and unlocks
  are not granted. This earlier-state journey is separate from the saved-ending
  repeat test that checks retention of existing paid work.
- Conservator combat and the Central ending, failed ending write, retry,
  natural death and restart checks all pass. The same dedicated human and
  once-only ending remain; Wave 7 changes only the availability of experiments.
- The older Pairing, second-resonance, saved campaign archives, save recovery,
  legacy Trial and Forge/Annex physical routes all pass. Together with LF5-R1,
  these 19 Wave 5 runner invocations pass **7,188 checks**. The ten selected
  Wave 6 combat/ending/return invocations pass **2,448 checks**. Four additional
  Wave 3 route/paid-journey invocations pass **1,067 checks**.

Physical publication still pauses synchronously: this matrix records
**15,201 ms** for the Pairing return, **15,564 ms** in the second-terrain fixture
and **13,773 ms** for the final Annex return. Different workloads and concurrent
local checks prevent comparison with the earlier approximately 21-second
observation. The performance limitation is not closed.

The exact run list and totals are retained locally in
`build/lf7-orchestrator/review-results.json`; runner logs remain under
`build/lf3`, `build/lf5`, `build/lf6` and `build/lf7`. After rebuilding the current
GDExtension, the review used:

```powershell
./tools/living_frontier_wave7_checks.ps1 -Native
./tools/living_frontier_wave7_checks.ps1 -Controls -Loop -Restart -Routes -Combat -Effects -Visuals
./tools/living_frontier_wave6_checks.ps1 -Native
./tools/living_frontier_wave6_checks.ps1 -Boss -Central -SaveFailure -Recovery
./tools/living_frontier_wave5_checks.ps1 -Native
./tools/living_frontier_wave5_checks.ps1 -Campaign -Legacy
./tools/living_frontier_wave3_checks.ps1 -Routes -Trail -TrailRestore
```

The rendered configuration and reward pages were independently inspected.
Current review captures are under `build/lf7-orchestrator/captures`; the two
committed screenshots overwritten by rendering were restored. The retained
author failed-save page was also inspected. Pre-existing modified Wave 6
captures and unrelated art files were preserved.

## Remaining acceptance work

1. **Complete added-pressure runs and balance.** The full live success uses
   no added pressure. Upper tiers and full Crossfire/Relentless runs have not
   been accepted for all builds. Compare the same offer and preparation before
   drawing conclusions about the cost or reward of adding a pressure. The
   Conservator's known Warden interrupt advantage also remains open.
2. **One continuous player campaign.** Component and archive tests cover the
   economy, terrain transitions, ending and repeats. A fresh, uncompressed
   journey from empty inventory through a postgame return has not been shown.
3. **Transition performance.** Ordinary archived restores still take seconds,
   and physical publication retains its known synchronous pause. Preserve the
   tested publication/ownership boundaries when addressing those costs.
4. **Clarity and presentation.** The controls work and fit the viewport, but
   the offer list needs scrolling and substantial text. Older HUD/world labels
   remain visible behind translucent panels. Human tell readability, the
   emotional pacing of the ending and overall difficulty remain unaccepted.

No gameplay or tuning changes are introduced by this review. Wave 7's selected
configuration remains in [`trial.json`](../../data/tuning/trial.json); the two
physical placement values remain in [`forge_look.gd`](../../game/art/forge_look.gd),
with purposes recorded in the [bounded Wave 7 contract](living-frontier-wave7-2026-09-09.md).

## Recommended next step

Wave 7 is the final implementation wave in the approved
[Living Frontier roadmap](living-frontier-roadmap-2026-09-08.md). There is no
automatically approved Wave 8. Continue **INT-18's economy, continuity and
whole-campaign proof** through bounded validation slices:

1. Complete added-pressure runs with comparable preparation, exact reward and
   restart evidence. This is the first gap left by the current live base run.
2. Trace one continuous fresh campaign through both protected region changes,
   the human ending and a configured repeat, preserving a paid home/workshop.
3. Profile the remaining publication/restore stalls and review the crowded
   controls before selecting a measured performance/readability change.

Preserve the seven-wave foundation while resolving the observed gaps; do not
expand the world, roster, eras or automation. The prompt below selects only
the first validation slice when the owner supplies it to a new session. This
review does not dispatch or implement that work.

### Suggested next-session prompt

```text
Work in C:\Users\Matty\Dev\project-wroughtwild. Continue Living Frontier
INT-18 with the first post-Wave-7 validation slice only.

Follow AGENTS.md's reading order, then read:
- docs/prototype/living-frontier-wave7-review-2026-09-09.md
- docs/prototype/living-frontier-wave7-2026-09-09.md
- docs/prototype/living-frontier-roadmap-2026-09-08.md

Close the missing complete added-pressure run evidence. Use a stable compatible
offer and comparable, ordinarily crafted preparation to attempt the entire five
rooms with Crossfire and Relentless Boss. Retain a matched no-extra-pressure
baseline. Every room must use live combat, actual movement and physical reward
interaction. Do not force kills, inject immunity, reset life between rooms or
weaken assertions to obtain a win. Label supplied inputs, earned-event fixtures
and scripted movement; distinguish completed victories from honest failures.

On completed attempts, verify the previewed rewards, separate Kind/material
ownership, exact saved configuration, ordinary/fresh-process restart and another
usable offer batch. Preserve both terrain ledgers, the once-only human ending,
paid construction, finite source/machine ownership and published saves.

Fix reproducible implementation defects within existing rules and verify them.
If combat preparation or tuning prevents completion, report the measured cause
and a concrete tuning proposal; do not silently rewrite combat or reward rules.
Do not add a new wave, era, currency, content roster or automation system.

Record results and remaining limits in a bounded validation report, commit and
ordinarily push checked scoped work under AGENTS.md, then stop for orchestrator
review. Keep unrelated art work intact. Full-campaign and performance follow-ups
remain separate subsequent slices.
```
