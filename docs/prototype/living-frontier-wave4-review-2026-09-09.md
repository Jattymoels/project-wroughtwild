# Living Frontier Wave 4 — orchestrator review

9 September 2026. Reviewed implementation: `91567ce`, including LF3-R1
`0c5f270`, LF-4A `ec8d22e`, LF-4B `0ba9be5` and LF-4C `91567ce`.
Interleaved ART-03 and active ART-04 work are separate. This review changes
documentation only and introduces no gameplay tuning.

**Verdict: technical all-clear for LF-4 and the next bounded LF-5 wave.**
No new blocking defect was found in the reviewed implementation. LF3-R1 is
independently closed below. Automated verification does not close the remaining
combat, readability and transition-comfort playtests.

The [Wave 4 implementation record](living-frontier-wave4-2026-09-09.md)
contains the selected contract, tuning, implementation evidence and remaining
owner playtests. The [roadmap](living-frontier-roadmap-2026-09-08.md) remains
the source for the next bounded wave.

## LF3-R1 closure

The wall-crossing finding in the
[Wave 3 review](living-frontier-wave3-review-2026-09-09.md) is repaired in the
implementation reviewed here. The original review card reported a defect;
it did not itself change the routes. Commit `0c5f270` supplies that correction.

The final laboratory shells now participate in the derived walk mask, with
clearance for the ordinary player capsule and a supported neighbouring band.
The corrected paths are derived after site placement, preserving the published
terrain, laboratory locations, source/host positions and resource identities.

Independent engine reruns pass all twelve complete paths for each of seeds
**5 and 77**: the collection trail, three laboratory approaches, four host
approaches and four source-to-host routes. These use ordinary controller
movement and jumping along the paths, rather than teleporting between their
waypoints. The historical paid-save fixtures for both seeds also pass.
The native regression retains the pre-repair world fingerprints and tests
the corrected routes across 37 deterministic seeds.

## Behaviour reviewed

- The saved `living_frontier_wave4` campaign policy reuses the published
  `living_frontier_wave3` geography. Older policies retain their existing
  acquisition, curio progression and owned state; loading does not silently
  convert them to this campaign.
- The existing Collection Annex provides the physical entrance. Its Trial
  teaches existing Red and Blue specimens separately, includes inspectable
  evidence of human intervention and foreshadows the return-circuit failsafe.
  The inherited containment warden is not the later human antagonist battle.
- First victory records one campaign receipt, awards the first-clear trophy
  and queues resonance. The trophy is optional remembrance, not the era key.
  The publisher saves the pending return before deferring for nearby combat,
  prepares and validates an isolated candidate, then saves the applied state
  before publishing the geometry and era-two milestone together.
- Retained Fen gains actual raised, traversable ground, four finite copper/tin
  lots and one additional existing Blue host. The ore supports the ordinary
  charcoal-heated work and bronze recipe. This is a bounded region change,
  not a completed global biome/ecology simulation.
- Protection covers paid construction, doors and supports, stations, machine
  connections/cargo, excavation, return/recovery locations and existing finite
  nodes and sites. Restart replays the stored transformation; depleted ore,
  defeated hosts and spent rewards retain their ownership.
- Native and engine checks cover failed/abandoned runs, repeat victory,
  pending/applied restart and invalid mixed terrain/milestone saves. These
  paths must not pay, transform or advance the era twice.

## Independent verification

The current GDExtension was built successfully before the engine reruns.
Native tests link the current simulation objects from that CMake build, using
the repository's test sources and `data/tuning`. Engine runs use isolated
`build/lf3/appdata` and `build/lf4/appdata` saves, not normal user saves.

| Check | Independently observed result |
| --- | --- |
| Native resonance, protected geometry and saved event | 373 checks across 37 seeds, zero failures |
| Native laboratory and first-clear settlement | 55 checks, zero failures |
| Native LF3 generation, immutable geography and physical route mask | 17,311 checks across 37 seeds, zero failures |
| Native core simulation | 224,380 checks, zero failures |
| Native leyline/source rules | 213,482 checks, zero failures |
| Native Wave 2 machine rules | 601 checks, zero failures |
| Actual LF3 routes, seeds 5 / 77 | 59 / 61 checks, zero failures |
| Historical paid LF3 saves, seeds 5 / 77 | 35 / 37 checks, zero failures |
| Protected physical transformation / pending restart / applied restart | 96 / 22 / 8 checks, zero failures |
| Collection Annex, first safe return and useful era-two resources | 172 checks, zero failures; 824.5 m actual movement |
| Campaign pending restart / applied restart | 4 / 6 checks, zero failures |
| Existing save recovery / Trial intensive | 175 / 6,221 checks, zero failures |
| Existing Forge traversal | 122 checks, zero failures; 814.9 m actual movement |

All six native executables and thirteen engine invocations exited successfully:
**456,202 native checks and 7,018 engine checks, zero failures.**

Engine commands:

```powershell
./tools/living_frontier_wave3_checks.ps1 -Routes
./tools/living_frontier_wave4_checks.ps1 -Terrain -Campaign -Legacy
```

Native sources rerun: `test_resonance`, `test_laboratory`,
`test_living_frontier_wave3`, `test_main`, `test_leyline` and
`test_living_frontier_wave2` under `tests/sim/`. Local logs are
`build/lf4/orchestrator-test_*.log`, `build/lf4/orchestrator-build.log`,
`build/lf3/routes-*.out.log` and the named terrain, laboratory, restart and
legacy logs in `build/lf4/`.

Malformed-save refusal warnings are expected negative fixtures. The author's
119 engine runs and four Foundry identity runs remain implementation evidence;
this review independently reruns the focused checks above, not that entire
pipeline. Unrelated working files and art changes are outside this review.

## Limits carried forward

- **Publication pauses the game.** The independent first-return publication
  took **21,099 ms**; pending-load publication took **20,708 ms** on this host.
  This confirms the implementation record's roughly 14–21 second synchronous
  pause. Save correctness is checked; a comfortable transition is not yet
  demonstrated. Measure the second transformation and address player feedback
  and performance before treating campaign presentation as finished.
- **Combat/readability acceptance remains open.** The laboratory harness moves
  the real controller, interacts with records and exercises encounter/reward
  state, but disables player damage and forces encounter outcomes. It does not
  establish novice comprehension, satisfying difficulty or a complete human
  combat playthrough. New hybrid combat in Wave 5 needs direct encounter proof.
- **The new ore proof uses declared fixtures.** The test actually heats, works,
  collects and spends new finite copper/tin. It supplies ordinary fuel, forge
  access and other inputs to isolate that path; it is not another full
  acquisition-from-zero campaign.
- **The campaign remains opt-in and incomplete.** Pairing laboratory, era three,
  a dedicated human boss and captured challenge controls remain later work.
  Existing LF4 terrain/event saves must remain loadable when that work arrives.

## Next-session boundary — LF-5

Read the repository's required design/decision documents, this review, the
[Wave 4 contract and evidence](living-frontier-wave4-2026-09-09.md), the
[roadmap's LF-5 slices](living-frontier-roadmap-2026-09-08.md#lf-5--forced-combinations-and-a-more-extreme-world)
and the [extraction/economy proposal](leyline-catalyst-extraction-2026-09-08.md).
Read only the relevant combat, Trial, progression, world-generation and save
specifications. Record a bounded Wave 5 work item before changing behaviour.

1. **LF-5A — First combined specimen.** Teach Blue-held charge followed by a
   warned Red release as one ordered encounter decision. Reuse the existing
   single-influence lessons; do not stack two complete simultaneous kits.
   Demonstrate tells, escape/counterplay and recovery with ordinary starting
   equipment and skills, without a lucky Catalyst or invulnerability.
2. **LF-5B — Pairing laboratory.** Open the second lab at its existing physical
   site, advance the human experimenter's story and make the combination matter
   to a playable Trial. Give useful rewards and a readable reason to enter;
   preserve complete approaches and avoid lucky-Catalyst entry/win gates.
3. **LF-5C — Era three.** Its first-clear failsafe activates the second planned
   physical amplification in Excited Uplands, with changed fauna capabilities
   or distribution and useful opportunities. Extend the tested protected
   transformation and safe-return transaction, preserving the first event,
   buildings, excavations, finite stock and all saved ownership.

The second event needs an explicit compatibility contract for dormant, pending
and applied LF4 saves. Do not replace the first event's ledger, replay its
rewards, silently reseed a world or grant era three before the second physical
publication succeeds. Preserve the existing five Catalyst manufacture routes,
useful raw media, separate signal/work/heat costs and source repair/renewal.

Verify real hybrid combat, physical lab routes, both transformations together,
deterministic seeds, paid construction/stock preservation, death and incomplete
or repeated settlements, and fresh-process pending/applied restarts. Report
fixture shortcuts and measured publication time separately from human evidence.
Keep unrelated animal/workshop art work intact; reuse suitable existing assets
or placeholders. No new production art dependency is required.

Commit and ordinarily push each checked slice under the standing owner workflow,
record receipts and limitations, then stop after LF-5A/B/C for orchestrator
review. The dedicated human uber-boss, captured controls and optional Heat remain
LF-6/7. Do not start those waves or broaden into additional hybrids, global
ecology or factory automation.
