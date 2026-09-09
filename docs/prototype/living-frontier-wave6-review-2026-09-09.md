# Living Frontier Wave 6 — orchestrator review

9 September 2026. Reviewed implementation: `58822e8`, including movement
recovery repair `9036a12`, LF-6A `f552c3c` and LF-6B `58822e8`. Interleaved
White/Blue workshop art and active Green work are separate. This review changes
documentation only; diagnostics use isolated synthetic saves.

**Verdict: Wave 6 passes independent technical review; proceed to bounded
LF-7A and LF-7B.** LF5-R1 is independently closed, LF3-R1 remains closed, and
no new blocking defect was found in the reviewed implementation. Human
full-Trial difficulty/readability acceptance and the known publication pause
remain open; this clearance does not claim they are resolved.

## LF5-R1 closure

The [Wave 5 review](living-frontier-wave5-review-2026-09-09.md) found that failure
of both physical publication and its rollback left movement disabled after a
successful ordinary load. Repair `9036a12` now gives that stop an explicit
transient owner. A complete physical restore releases it; failed loads do not.
Repeated stops retain the original controller state, including an unrelated
deliberately disabled controller. No save field or gameplay tuning was added.

The original independent diagnostic was copied into an ignored Wave 6 probe,
retaining its failure injection and normal `player.load_game` entry point.
Only its expected result and output/save names changed. On this build:

- Before failure, 30 physics frames move the player **2.4164 m**.
- Both injected host failures stop physics and retain the prior live era.
- Ordinary load restores the applied world, era three and enabled physics;
  the next 30 frames move the player **2.4154 m**, with no helper enabling
  physics after the load. The later positive control moves **2.4994 m**.
- The probe passes four fixture checks and reports `recovered=true`.
- The committed actual-input regression independently passes **24 + 15 checks**,
  including missing/physically failed loads, fresh-process recovery, repeated
  requests and intentionally disabled presentation controllers.

**LF5-R1 is independently closed.** The historical Wave 5 reproduction remains
in its report; reporting that defect did not itself implement this repair.

## Behaviour reviewed

Central opens at its existing physical door only after the second physical
campaign award. Its two floors, eight stages, ordinary deposits, rewards and
cleared-floor suspension are retained. The teaching rooms reuse known hosts;
the final chamber contains the dedicated human Conservator alone.

The human has its own movement/channel loop: a committed White lane, a
Blue-held position followed by a Red release, and Green's two diverging lanes.
The shared boss ancestry supplies damage/status classification. It does not
run the old Warden attack cycle, conduit protection or ambient furnace vents.
Movement, actual cover, stagger/freeze and the two physical emergency releases
work. A successful release cools both pedestals together and creates recovery
without producing items or affecting home circuits.

The existing `forge_arc_complete` receipt owns the once-only ending and control
handoff. Final return checkpoints the haul and returned world before describing
them as saved. An unwritable destination retains live settlement and visibly
asks for a save retry; retry does not resolve or pay the fight again. Completed
Central entry and boundary restoration are refused before another deposit.
The outer door, handle and inspection page show the captured apparatus.

The campaign stays on `living_frontier_wave4` with `living_frontier_wave3`
geography. Both terrain-event ledgers, three eras, finite resources, paid
construction, source/machine ownership and ordinary Catalyst recipes remain.
No third resonance, additional currency, Heat selection or repeatable
configured reward system is included in Wave 6. The small mastery codec fix
preserves empty earned-perk lists exactly; it does not grant a perk.

## Independent evidence

The current GDExtension rebuilt successfully before these checks. All eight
native suites (**456,985 checks**) and 32 committed engine invocations
(**9,769 checks**) pass, plus the separate four-check recovery diagnostic.
All rerun logs are current, with zero check failures or engine/script errors.
Expected corrupt-input warnings come from the labelled save-failure fixtures.

| Area | Independent result |
| --- | --- |
| Eight native suites | **456,985 checks**, zero failures: Central 47; generation/routes 17,716; Annex 55; Pairing 72; both resonance events 632; main save/economy/Trials 224,380; extraction/Catalysts 213,482; circuits/workshop 601 |
| Dedicated human contact and three live build fights | 1,867 checks at 20/60 Hz, including fixed marks, cover, interrupts, branches and damage |
| Central physical route and live final chamber | 186 checks; 834.5 m of actual controller travel |
| Fresh Central boundary / ending / later world death | 4 / 36 / 30 checks |
| Failed automatic ending write and retry | 194 checks; fresh retried ending / later death 36 / 30 checks |
| Natural human death / fresh restart and retry | 47 / 18 checks; six real releases cause one Trial death; 304.6 m of actual second-floor travel |
| Rendered physical controls and ending pages | 13 checks through ordinary E interaction; panels fit the 1280 × 720 viewport |
| LF5-R1 committed actual-input recovery | 24 / 15 checks, plus the separate four-check independent diagnostic above |
| Pairing route / cleared-floor restart | 155 / 4 checks; 824.9 m of controller travel, with forced encounter outcomes |
| Second physical transformation | 133 checks, including paid ownership, both changed regions and actual movement/resource work |
| Double-host recovery / pending / applied / real return | 8 / 13 / 22 / 13 checks |
| Six frozen LF4 and intermediate LF5 archives | 15 / 23 / 23 / 13 / 23 / 14 checks |
| Save recovery / legacy Trial lifecycle | 175 / 6,221 checks |
| Legacy Forge traversal / Annex campaign | 122 / 172 checks; 814.9 / 824.5 m of actual controller travel, with forced encounter outcomes |
| Full LF3 routes and historical paid saves, seeds 5 / 77 | 59 / 61 checks; all 24 routes walked; zero capsule contacts with laboratory shells |

The seed 5 Annex trail and seed 77 Central approach from the old screenshot
both clear their final solid walls. **LF3-R1 remains closed.** Saved paid work
and frozen geography match after loading the original archived saves.

The failed-save retry button completes its checkpoint and panel action in
**349 ms** in this rerun. The second physical publication takes **20,699 ms**
in the protected-terrain fixture and **19,694 ms** on Pairing's actual return.
The later Annex return measures **13,783 ms**. These differing workload timings
are not isolated latency benchmarks.

| Starter build | Actual fight | Casts | Human releases | Player life at victory |
| --- | --- | --- | --- | --- |
| Warden, paid wooden cudgel | 13.78 s | 36 | 0 | 100 |
| Ranger, paid simple bow | 36.13 s | 41 | 12 | 100 |
| Kindler, paid wooden focus | 36.17 s | 68 | 12 | 100 |

These isolated fights use synthetic campaign access and supplied crafting
inputs, then pay the ordinary recipes. Casts, contact, mitigation, statuses and
boss deaths are real; the Foundry is empty and incoming damage is enabled.
The movement bot reads the encounter state. Zero damage taken demonstrates
successful scripted counterplay, not representative human difficulty.

The complete Central traversal covers **834.5 m**. Earlier room outcomes are
forced for physical route and ownership coverage. Its final human encounter is
live: **11.22 seconds, 23 casts, one release**, with retained route rewards.
This is not a claim of an unassisted full-Trial combat playthrough.

The rerendered entrance, captured-control and finale pages were inspected,
alongside the four retained observer views of the human's tells. Current review
captures are retained under `build/lf6-orchestrator/captures`; the author's
committed captures were restored after rendering. These checks do not replace
human acceptance of combat readability.

The original recovery log remains under `build/lf5-orchestrator`. Its closure
probe and the additional physical route logs are under `build/lf6-orchestrator`;
current Central and compatibility logs are under `build/lf6` and `build/lf5`.
These ignored diagnostics and synthetic saves are not publication artefacts.
The checked invocation/count manifest is
`build/lf6-orchestrator/review-results.json`. This is the focused matrix above,
not a claim of rerunning the entire project headless pipeline.

Reproduce the committed checks after rebuilding the current extension:

```powershell
./tools/living_frontier_wave6_checks.ps1 -Boss -Central -SaveFailure -Recovery -Controls -Native
./tools/living_frontier_wave5_checks.ps1 -Campaign -Legacy -Native
```

The additional route checks use `res://tests/living_frontier_routes.tscn` with
`--route-seed=5` and `--route-seed=77`, without the restore-only switch. The
source under review remains unchanged from `58822e8` after the reruns.

## Remaining limits

- **Boss balance needs human acceptance.** Warden can interrupt every channel
  in the isolated starter test. Ranged bots evade all releases. The dedicated
  mechanics and baseline access work; an accepted uber-boss difficulty curve
  has not been demonstrated. Keep that distinction when tuning optional Heat.
- **Human readability and pacing remain open.** Authored primitives provide a
  human silhouette and channel gestures. Observer tell images and first-person
  control panels do not establish close-combat readability or the emotional
  weight of the finale. The HUD can be crowded by older campaign messages.
- **Terrain publication still pauses synchronously.** Concurrent review timings
  are around 21 seconds and are not isolated performance benchmarks.
- **Failure evidence is bounded.** The ending test uses an unwritable path and
  the staged writer; it does not simulate every OS crash or power-loss point.
  A crash before a successful ending checkpoint returns to the preceding save;
  active fights are not resumable. Later open-world death is an injected fatal
  hit for ownership coverage; the separate human-death test uses real releases.

No new tuning or gameplay behaviour is introduced by this review. The selected
combat values and their player-facing purposes remain in
[`central_laboratory.json`](../../data/tuning/central_laboratory.json) and the
[Wave 6 contract](living-frontier-wave6-2026-09-09.md).

## Next-session handoff — Wave 7 only

```text
Work in C:\Users\Matty\Dev\project-wroughtwild. Implement Living Frontier
Wave 7 only, LF-7A then LF-7B, and stop for orchestrator review.

Follow AGENTS.md's reading order. After the required repository reading, read
docs/prototype/living-frontier-wave6-review-2026-09-09.md for its final verdict
and handoff, then the relevant context in:
- docs/prototype/living-frontier-roadmap-2026-09-08.md, especially sections 8–12
- docs/prototype/living-frontier-wave6-2026-09-09.md
- docs/systems/dungeon-runs.md and the relevant progression/loot specifications.

Wave 6 has independent technical clearance. Preserve the completed repair,
both terrain events, paid world ownership, published saves and the once-only
human ending. Human balance/readability acceptance remains separate.

LF-7A: Make captured apparatus usable for one bounded, repeatable laboratory
experiment with a clear difficulty and reward preview. Extend the existing
saved Trial offers/tiers through one interface. Record the small configuration
contract before editing: selectable pressures, their compatibility and limits,
how they combine with rolled conditions, the repeat opponent and exact reward
effects. Reuse known content and existing settlement. The human stays defeated.
Keep unopened offers stable across reopening/reloading and commit the selected
configuration at successful entry. Keep the live-enemy and major-hazard limits.

LF-7B: Complete the configured run, deliver the previewed rewards once and
choose another configuration. Prove useful field extraction, ordinary crafting
and building still have a purpose. Difficulty does not silently increase item
grade, guarantee Catalysts, refill finite sources or multiply every reward axis.
Keep campaign eras, voluntary run difficulty and Red crafting heat separate.
Do not introduce another world transformation, new currency, research ladder,
offline production, infinite world, broad factory system or unrelated art work.

Verify actual physical control use and combat, selected-setting and reward
identity, death/abandon/bank/retry, repeated resolution, ordinary and fresh-process
loads, old offers/saves, both terrain ledgers and paid construction/source/machine/
recovery ownership. Label forced encounters and synthetic access explicitly.
Carry forward LF5-R1 actual-movement recovery and the seed 5/77 route regressions.
Measure repeat-loop and full-campaign transition performance; do not claim the
known publication pause or Warden interrupt advantage is fixed without evidence.

Put tuning in data with plain-language purposes. Update the bounded work record,
acceptance evidence and relevant specifications. Ask only if an unresolved
decision materially changes player experience, save compatibility or architecture.
Commit checked scoped slices to main and make ordinary pushes to the confirmed
origin/main under AGENTS.md; preserve unrelated work. Report local commits and
successful remote pushes separately, then stop for this orchestrator's review.
```
