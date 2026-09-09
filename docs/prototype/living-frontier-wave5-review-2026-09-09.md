# Living Frontier Wave 5 — orchestrator review

Subsequent independent closure, 9 September 2026: the
[Wave 6 review](living-frontier-wave6-review-2026-09-09.md#lf5-r1-closure)
verifies repair `9036a12` on `58822e8`. The original diagnostic now recovers
ordinary movement, and actual-input, failed-load and fresh-process regressions
pass. **LF5-R1 is closed.** The findings below remain the historical baseline.

9 September 2026. Reviewed baseline: `71dad88`, containing LF-5A `0482211`,
LF-5B `e92561a` and LF-5C `71dad88`. Interleaved ART-04 and active White
workshop art are separate. This review changes documentation only; the local
diagnostic does not change gameplay, saves belonging to the owner or tuning.

**Original verdict on `71dad88`: repair and verify LF5-R1 before starting LF-6.** One P2 recovery
defect prevents an unconditional all-clear. The live hybrid, complete Pairing
route and protected second transformation pass their checks, but the new
publication-failure recovery does not restore ordinary movement after loading.
All rerun committed suites pass. The additional ordinary-load diagnostic below
reproduces the missing control recovery that their traversal helper conceals.

The [Wave 5 contract and evidence](living-frontier-wave5-2026-09-09.md) records
the selected behaviour and author receipts. The
[Wave 4 review](living-frontier-wave4-review-2026-09-09.md) remains the prior
clearance; its laboratory-route blocker stays closed.

## LF5-R1 — Successful recovery load leaves movement disabled

Priority: **P2**. The trigger is failure of both physical installation and its
host rollback, the explicitly supported fault path added in LF-5C. This was
reproduced with deterministic host-failure injection; the review does not claim
that both failures occurred spontaneously during an ordinary playthrough.

[ResonanceEvent.publish](../../game/scripts/resonance_event.gd#L87) restores the
prior native era, calls `player.set_physics_process(false)` and tells the player
to reload. The ordinary [player load action](../../game/scripts/player.gd#L471)
successfully installs the saved applied world and era three, but neither it nor
the successful save-restore path releases that movement stop. The player sees
a successful load while WASD and jumping remain disabled in that session.

Independent reproduction on the reviewed build:

1. Load the frozen `lf5b-published-clear.json.gz` through the existing migration
   path, yielding a pending second event with the original first ledger intact.
2. Enable ordinary movement and walk for 30 physics frames at 60 Hz. The player
   moves **2.4164 m**, establishing an initially working controller.
3. Set the existing test host's `reject_publication` counter to two, then invoke
   the real publisher into a separate synthetic save. Both installation and
   rollback refuse as in the committed recovery fixture. Live era remains two,
   movement stops and the complete applied checkpoint remains on disk.
4. Use `player.load_game(path)`, the normal F9 entry point, without a movement
   helper. Loading succeeds and the live era becomes three, but player physics
   remains disabled. The same walking input for 30 frames moves **0 m**.
5. Only as a diagnostic positive control, re-enable player physics and repeat
   the walking input. The player now moves **2.4987 m** on that restored world.
   This distinguishes the persistent movement stop from a wall or bad terrain.

```text
LF5_RECOVERY_BASELINE physics=true moved_m=2.4163818359375
LF5_RECOVERY_FAILURE physics=false reason=Resonance is saved; reload to finish physical publication. world generation profile could not be restored
LF5_RECOVERY_RELOAD ok=true era=3 physics=false moved_m=0.0
LF5_RECOVERY_CONTROL physics=true moved_m=2.49871826171875
LF5_RECOVERY_PROBE reproduced=true fixture_checks=4 fixture_failures=0
```

The committed double-failure test checks successful load, era and payout, then
calls `physical_bank()`. That helper calls
[`walk_route()`](../../game/tests/living_frontier_routes.gd#L90), which explicitly
re-enables player physics before measuring traversal. It therefore conceals
the missing recovery of normal controls. Its initial `quiet()` also disables
movement before the failure, so that flag assertion alone is insufficient.

Required repair and proof:

- Give the publication recovery stop an explicit lifecycle. A successful
  ordinary load must restore normal control only after the complete physical
  world is installed; a failed load must retain the necessary stop.
- Add a regression starting with a working controller, injecting both host
  failures and using the normal load action. Verify actual movement afterward
  without a helper that enables physics. Keep the pending/applied terrain,
  era, first-event, reward and ownership checks intact.
- Retain one-failure rollback/retry, double-failure disk recovery and normal
  loads, including fresh-process restart. Do not unconditionally enable a
  deliberately stopped controller in unrelated test or presentation contexts.

Local ignored diagnostic: `game/tmp/lf5_recovery_probe.gd`, its `.tscn`, and
`build/lf5-orchestrator/recovery-probe.out.log`. It extends the committed second
terrain fixture and changes only the diagnostic sequence described above.
Its saves use `build/lf5-orchestrator/appdata`. No gameplay repair is included
in this review commit.

## Independent checks

The current GDExtension built successfully before the reruns. All native tests
link that build's current simulation objects. Engine suites use their isolated
`build/lf3/appdata` and `build/lf5/appdata` directories.

| Check | Independent result |
| --- | --- |
| Live ordered hybrid, 20/60 Hz contact cases and all three starting builds | 2,801 checks, zero failures |
| Existing single-influence combat | 234 checks, zero failures |
| Complete Pairing controller route / separate suspended restart | 155 / 4 checks, zero failures; 824.9 m actual movement |
| Protected second publication / injected double-host recovery fixture | 133 / 8 checks, zero failures; control-recovery gap identified separately above |
| Second pending / applied / actual-return restart | 13 / 22 / 13 checks, zero failures |
| Six frozen LF4/LF5B compatibility cases | 15 / 23 / 23 / 13 / 23 / 14 checks, zero failures |
| Native immutable geography and host rules, 37 seeds | 17,716 checks, zero failures |
| Native Annex / Pairing settlement | 55 / 72 checks, zero failures |
| Native coupled transformations, 37 seeds | 632 checks, zero failures |
| Native core / leyline-source / Wave 2 machines | 224,380 / 213,482 / 601 checks, zero failures |
| All 24 complete LF3 physical routes, seeds 5 / 77 | 59 / 61 checks, zero failures; historical paid-save assertions included |
| Existing save recovery / Trial lifecycle | 175 / 6,221 checks, zero failures |
| Existing Forge traversal / Annex journey | 122 / 172 checks, zero failures; 814.9 / 824.5 m actual movement |
| Independent ordinary-load recovery diagnostic | LF5-R1 reproduced; control works only after diagnostic re-enabling |

All **seven native executables and 21 committed engine invocations** exit
successfully: **456,938 native checks and 10,304 engine checks, zero failures**.
Those passing results do not close the independently reproduced LF5-R1.
The four review/context documents' 55 local links resolve and scoped whitespace
checks pass. No reviewed gameplay source changed during the verification.

Commands after building the extension:

```powershell
./tools/living_frontier_wave5_checks.ps1 -Native
./tools/living_frontier_wave5_checks.ps1 -Hybrid -Campaign -Legacy
./tools/living_frontier_wave3_checks.ps1 -Routes
```

Logs: the named suite `.out.log` / `.err.log` files and native `test_*.log`
under `build/lf5/`, `build/lf3/routes-*.out.log`, and the independent recovery
diagnostic directory above. The current source build receipt is
`build/lf5/orchestrator-build.log`. Expected malformed-save refusal fixtures
are distinct from failed assertions.

The hybrid uses real Enemy physics, native player casts and live incoming-damage
processing. Warden/Ranger/Kindler win with ordinary paid starting weapons in
**3.90 / 3.70 / 3.78 s**, using **5 / 5 / 8 casts** and one enemy release each.
They finish at 100 life through counterplay. The contact cases separately show
that standing in, or returning to, the mark takes damage. Workbench access and
craft ingredients are explicit fixtures, not a from-zero acquisition proof.

The laboratory route deliberately forces encounter outcomes and disables
damage. Its movement, door/record interactions, deposits, rewards and suspended
return checks are useful evidence, but do not establish full-Trial difficulty.
The finite transformed host's injected death likewise tests reward ownership,
not combat. These distinctions are preserved in the review.

## Behaviour and limits retained

- The saved campaign remains `living_frontier_wave4` on immutable LF3 geography.
  Missing second ledgers migrate explicitly: ordinary LF4 states gain a dormant
  event, while the retained intermediate Pairing first-clear receipt queues the
  second event without another Eye. The first ledger is preserved and replayed
  before the second.
- The ordered specimen teaches a fixed Blue-held mark, separate Red warning,
  one release and exposed recovery. Pairing Hall uses the existing second site
  and advances the human operator's experiments; its inherited Warden is not
  the dedicated human finale required next.
- Excited Uplands adds real stone shelves, finite iron/silver and one paired
  host. The changed ground preserves paid work, excavation, first-event stock
  and source/machine ownership. Ordinary cold iron and charcoal-heated silver
  work feed paid existing recipes; supplied fuel/access are declared fixtures.
- Author Blue/Red tell and matched before/after terrain captures under
  `captures/lf5/` were visually inspected. These are observer views, and the
  independent engine reruns are headless. Human first-person tell recognition,
  narrative discovery, full-Trial difficulty and art acceptance remain open.
- Publication still blocks the game synchronously. Independent Pairing return,
  protected second transaction and pending restart measured **18,891 / 18,920 /
  18,981 ms** under concurrent review load. These are not controlled benchmarks.
  The author's roughly 14-second lighter-load receipts and preparing notice
  do not establish a comfortable transition. No broad ecology or extra era
  is implied by these two bounded regional changes.

## Conditional next-session boundary — LF-6

Repair LF5-R1 and pass its ordinary-control recovery regression first. The
repair must retain both event ledgers, saved ownership and existing campaign
settlement. This review is not an unconditional permission to skip that gate.

Then follow the [roadmap's LF-6 slices](living-frontier-roadmap-2026-09-08.md#lf-6--fight-the-human-behind-it):

1. **LF-6A — Central installation and human boss kit.** Complete the third
   laboratory at its existing physical site and build the actual corrupted
   human encounter from the learned influences and ordered combinations.
   Prototype distinct moves, tells, apparatus interactions, counterplay and
   recovery. A renamed or recoloured existing Warden is insufficient.
2. **LF-6B — Finale and captured apparatus.** Deliver the tuned battle,
   once-only story resolution and a visible, saved transfer of control.
   Demonstrate viable different builds without a lucky-Catalyst gate. The
   captured controls can explain the later configurable experiments; their
   difficulty/reward implementation remains Wave 7.

Read AGENTS.md in its required order, this review, the Wave 5 contract and the
original roadmap/extraction context. Record the bounded work item before
implementation and surface materially missing gameplay, architecture or save
decisions. Preserve published sites, both physical transformations, finite
stock, construction, all five Catalyst recipes and separate signal/work/heat
costs. Existing LF4/LF5 saves and suspended laboratory identities must survive.

Prove the real boss fight, physical approaches/apparatus collision, victory,
death/abandon/retry, once-only reward/control ownership and fresh-process
restart around the ending. Clearly separate real combat evidence from forced
settlement fixtures. Preserve unrelated art work and use suitable existing
assets or placeholders; no external production-art dependency is required.

Commit and ordinarily push each checked repair/slice under the standing owner
workflow, retain results and limitations, then stop after LF-6A/B for
orchestrator review. Optional Heat, configured rewards, additional hybrids,
further eras and wider automation remain outside this wave.
