# INT-06A — Understand and operate the pressure workshop

Status: **Implemented, owner review pending.** Baseline: `d485c8c`.

The owner's "Continue" accepts the next queued workshop-usability slice. The
existing [D-031 pressure workshop](pressure-workshop-2026-09-06.md) supplies the
complete rules contract: one finite pocket, a player-built forge/feeder, the
existing brick recipe, explicit loading/collection and exact saved escrow.
This pass makes those existing operations and stops understandable while the
owner is away. Broader production, renewable supply and combat tuning stay separate.

## Selected outcome and audit

The current Start button checks physical connection readiness only; it can look
available without drive, ingredients, fuel or tray space. Long explanations and
input/output actions compete in one scrolling list. Each active refresh replaces
all controls, losing focus and potentially interrupting a press. A fuel-only
hopper also shows the clay representative.

Show one truthful current state and next action, make completed output prominent,
and group detailed hopper, drive/attachment and recovery operations into short
pages. Clearly distinguish carried stock, hopper contents, reserved firing inputs,
stored drive and completed output. An exhausted pocket must not suggest stored
drive or hand-winding stopped working. Keep compact first-person inspection and
separate physical clay/fuel loads, preserving existing bodies and work areas.

## Small implementation plan

1. Preserve the committed source and existing DLL in an isolated baseline. Capture
   normal first-person workshop and panel states before changing the presentation.
2. Add a bounded read-only native feeder inspection using the existing transaction
   paths. Actions and accepted load amounts preview exact current refusal/order,
   including escrow capacity. Godot continues to certify physical support/space.
3. Build concise feeder pages with stable machine/page/action identities. Retain
   focused controls, scroll and expanded details during live progress; revalidate
   every actual operation. Correct fuel-only visuals and short aimed/source text.
4. Verify native purity and preview/action parity, actual controls and physical
   blockers, source exhaustion, exact save/pause/cancel/collection and ownership.
   Capture matched 720p/1080p states and a real source-to-brick-building handoff;
   compare bounded rendering/UI cost and investigate regressions above 10%.
5. Record evidence, update affected specifications/queue and commit/push through
   the owner's standing ordinary `origin/main` workflow.

## Systems, assumptions and boundaries

Affected: native contraption inspection and bridge; Godot feeder readout, local
panel/interaction presentation, optional keyed custom-panel updates and review
resources/tests. D-010's authority boundary, D-013's restrained frontier mood,
D-030's accidental-impact premise and D-031's exact ownership remain.

Assume the existing operations benefit from a short main page with opt-in supply,
connection and recovery details. No missing decision changes the rules: recipe,
fuel ordering, source budget, stroke capacity, cycle duration, buffers, trials,
save schema, world profiles and refunds stay unchanged. Read-only inspection
must not reserve work, grant items, draw pressure or consume RNG. Presentation
tuning receives a plain-language purpose. No package, external asset service,
new machine, production graph or generation scope is introduced. The known
timber-demolition conflict remains outside this item.

Human usefulness, layout comfort and sound/art acceptance remain pending while
away. Seeded supplies and scripted clock advances verify behaviour and ownership,
not discovery pacing, balance or enjoyment.

## Implemented behaviour

The overview leads with current readiness, the completed tray, Start/Pause/Resume
and links to supplies, drive and recovery. Start stays open and requests **up to
four firings**; the panel does not promise four without their supplies. Loading
shows only compatible carried ingredients and each exact accepted amount. Hopper
capacity includes both held recipe inputs and held fuel. Source stock, available
drive and the current firing's held stroke are separate.

`contraption_feeder_inspect` previews each existing native operation independently
on a copied bounded ledger. A charge preview cannot make Start appear ready, and
a loading preview cannot spend the pack or occupy space for another preview.
Trial ownership disables inspection actions as it disables real transactions.
All real actions retain their existing final validation.

Stable machine/page/row identities retain live controls, focus, scroll and Details.
They also invalidate removed or closed callbacks immediately. Old custom pages
do not need IDs; pending layout work cannot resize a newly opened crafting page.
The attachment picker remains live and unavailable while a firing is held.

The existing hopper now has separate clay and fuel representatives. Two matte
connection finishes distinguish forge feed from pocket pressure. Aimed status
uses the half-second cache; the active work tick and visuals reuse one actual
physical readiness sample. Source inspection keeps three concise topics with
optional lore/cost/connection detail.

## Tuning and compatibility

No engine-neutral tuning or save field changed. Presentation resource
`game/art/contraption_look.gd` keeps the existing half-second refresh interval;
its purpose now also includes cached aimed inspection. The clay and new fuel
shares use centres `(-0.14, 1.24, -0.26)` and `(0.14, 1.24, -0.26)`, each sized
`(0.23, 0.12, 0.4)` metres, so both fit inside the existing hopper. Fuel uses
`#494337`, forge feed `#986c4b` and pressure casing `#697f78` to distinguish
stock and connections without emissive flow, lights or new collision.

The 24-stroke pocket, four-stroke store, four requested firings, eight-second
cycle, 64-item hopper and 32-brick tray retain D-031's purposes and values. Exact
fuel selection, cancellation, save restoration, source depletion and ordinary
construction refunds remain unchanged. The timber-demolition conflict is not
part of this implementation.

## Verification record

Fresh strict C++17 native builds: **602 contraption checks** and **224,377 core
simulation/save checks**, zero failures. The inspection cases compare exact
preview/action results, independent previews, repeated-read purity, partial
escrow, full and one-slot hoppers, exhausted sources and old hand-driven worlds.
Logs and binaries remain under ignored `build/workshop-usability/native/`.

Isolated Godot checks passed: custom-panel identity/focus/layout 38,
physical load/cache/source presentation 59, feeder support/ownership 22,
panel-density 60, generated pressure-workshop lifecycle 60 in each of V5 and V6,
existing contraptions 85, manual workshop feedback 328 and home/workshop 1,027.
These include fractional saves, repeated cancellation, trial deposit protection
and using paid output in ordinary masonry. The rendered **195-check actual-control
fixture** exercises Attach, Back, Wind, exact Load, Start, Pause/Resume, Cancel and
Collect buttons. It verifies the 63-to-64 item transfer beside both escrow owners,
disabled/stale controls, physical blockers, focus retention and twenty repeated
readouts during a real native trial deposit without changing either save stream.
The custom-panel fixture also passes its 38 checks rendered. The visual fixture
initially printed success but stalled during immediate renderer shutdown; explicit
test-scene teardown and frame settling now pass all 59 checks and exit normally.

The common baseline/current `workshop_readability_review` fixture passes **114
baseline / 116 current checks at each resolution**, producing **72 actual Godot
captures**. Both versions use the same V6 seed 77, paid kit placement, supported
forge/pocket choices and real panel buttons. Explicitly supplied clay/fuel fire
sixteen bricks; collection pays for three normal masonry pieces. Empty, fuel-only,
ready, firing, paused and completed states are matched at 1280×720 and 1920×1080,
with collapsed/expanded supply and drive pages. The overview fits both; expanded
longer pages scroll with Close outside their scroll area. These are held real
first-person inspection poses, not a claim of walked discovery or playtest pacing.

`python tools/workshop_usability_gallery.py` validates the manifests/images and
builds the local review at `build/workshop-usability/index.html`. Preserved project
copies, DLLs, isolated user data, screenshots and logs remain ignored. The normal player save
and running playthrough are not used by these fixtures.

## Matched performance

Final measurements ran sequentially with no concurrent test engine, at uncapped
Forward+ on the local RTX 5090. Each world-view sweep and live-panel sample warms
for three seconds, then records five seconds of actual elapsed frames while one
real feeder advances. Screenshots happen outside these samples. These short
local measurements do not certify low-end hardware or a large factory.

| Resolution / sample | Baseline median / p95 ms | Current median / p95 ms |
| --- | --- | --- |
| 720p world view | 0.831 / 1.176 | 0.789 / 1.000 |
| 720p live panel | 0.851 / 1.207 | 0.820 / 1.026 |
| 1080p world view | 0.813 / 1.124 | 0.815 / 1.056 |
| 1080p live panel | 0.855 / 1.122 | 0.876 / 1.217 |

Synchronous world setup was 8,365 → 8,334 ms at 720p and 7,867 → 7,898 ms at
1080p. No measured regression exceeds 10%; the largest is the 1080p live-panel
p95 increase of 8.5%. Timing monitors in the raw report are diagnostic engine
samples; elapsed-frame distributions above are the comparison used here.
The prior V6 terrain-preparation regression remains a separate queue item.

Reproduction examples (from the repository root, isolated `build/` projects):

```powershell
./tools/home_review.ps1 -ReviewSet workshop-usability -Phase current -Prepare -Import -Scenes feeder_controls,feeder_visuals,custom_panel_refresh -Rendered
./tools/home_review.ps1 -ReviewSet workshop-usability -Phase current -Scenes pressure_workshop -ExtraArguments '--pressure-profile=frontier_v6'
./tools/home_review.ps1 -ReviewSet workshop-usability -Phase current -Scenes workshop_readability_review -Rendered -ExtraArguments '--review-height=720'
```

The last command writes inside the isolated project's `captures/workshop` unless
an absolute `--review-output` is supplied. Use height 1080 for the second layout.
The preserved baseline replays only the common review fixture against unchanged
production at `d485c8c`; it is not overwritten by `-Prepare`.

Owner review remains about finding the supply/drive actions, diagnosing a stopped
firing and understanding the finite pressure payoff. No further playtest input
is needed to keep the separately tracked performance work moving.
