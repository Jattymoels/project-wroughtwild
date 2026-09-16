# AI Agent Instructions

These instructions apply to every AI-assisted change in this repository.

## Prototype workflow — owner corrections, 14–15 September 2026

### Approved work belongs in the game

The owner clarified that requested art/features are intended for the normal
playable game. Once the owner approves the visuals/aesthetics or relevant
behavior, that approval also authorises ordinary game integration, checked
commits and ordinary pushes under the existing permission. Do not require a
separate adoption/rollout permission or leave approved work in an isolated
showcase/package as the final result. Use study-only delivery only when the owner
explicitly asks for a study or approval is still pending.

Do not require baseline comparisons, before/after renderer matrices, performance
benchmarks, minimum-hardware clearance or another independent review before
integrating approved work. Run only a short load/use smoke check and checks
directly needed for changed behavior or a concrete observed failure. The owner
will report lag during playtesting; investigate performance then, or when they
explicitly request it. End-to-end and broad regression work can wait for the
owner's selected playtest/final phase. Never conceal known breakage or mark
unfinished checks passed. Preserve saves, paid ownership and existing game rules;
do not invent unrelated mechanics to make an asset fit.

This supersedes earlier blanket ordinary-world rollout exclusions, baseline-
comparison requirements and target-device/performance gates for owner-approved
work. It does not retroactively mark every candidate visually approved. Record
the actual owner approval and integrate within that scope without asking again.

### Standing approval while owner playtesting is deferred

On 15 September 2026 the owner said: "assume I can't playtest right but approve
everything until I say otherwise." Treat the agreed prototype sequence and its
ordinary implementation, art/presentation choices, integration and checked pushes
as approved until the owner changes direction. Continue useful scoped work without
waiting for a playtest, another visual approval or a routine permission request.
Make reasonable choices within the existing design and report them with the slice.

Record owner playtesting as deferred; do not claim the owner has personally tried
or liked an unplayed result. Known bugs remain open until fixed, and unavailable
feedback is not evidence that an issue passed. Preserve saves, progression and
existing gameplay rules. A1/A2 and all six base replacement mobs are now adopted
on main, along with the scoped movement and canopy improvements. Consult the
current coordination sheet before scheduling work from older prompts. Reported
significant underground lag and useful playtest feedback remain open. Deferred owner station/campaign
feedback does not hold up this sequence. R9 remains stopped.

The owner clarified in the movement worker on 15 September that PLAY-03 is
significant lag underground, not difficulty or unintended access underground.
Preserve legitimate cave/digging behavior; do not invent an access restriction.

After the completed PLAY-03 diagnostic, the owner said they were happy to wait
for their next playthrough. Its opt-in recorder is integrated; the lag remains
unresolved. Do not resume underground sampling or speculative performance fixes
without new playtest evidence or an explicit request. See the current coordination
sheet for the next scoped work item.

New owner evidence on 15 September: the large lag also coincides with nearby mobs
visibly appearing in the overworld. The owner suspects the earlier underground
incident followed a long fall into newly activated mobs; that connection is not
yet confirmed. They clarified: "A brief hitch, then recovers"; focus on arrival
work rather than assuming sustained nearby-mob cost. The [PLAY-03 mob-arrival follow-up](docs/prototype/play03-mob-arrival-followup-2026-09-15.md)
records the evidence. RF-05 and both PLAY-03 arrival slices are integrated.
The first reduced a measured arrival from 443 to 324 ms; the owner questioned
accepting the remaining freeze. The [presentation correction](docs/prototype/play03-presentation-hitch-result-2026-09-15.md)
then reduced the selected first boar arrival from 324.760 to 7.529 ms. Shared
boar/wolf/stag resources now prepare during real New World and Continue entry
before controls release, adding roughly 0.9 seconds of preparation. The owner
describes this as seemingly a massive improvement. This closes the selected
measured presentation freeze, not all game lag or the unconfirmed underground
connection. Other mob pipelines, the separate non-arrival spike and long world
entry remain unmeasured/open; do not automatically start a broad repair wave.
Prototype pragmatism does not make a reproduced long freeze acceptable or make
passing functional checks proof of smooth movement. Continue an actionable
dominant cause instead of stopping after a minor saving; keep checks focused.
This meets the new-evidence condition above; do not keep the issue indefinitely
parked, restart the old shaft test by default, or assume a spawn/loading cause
without timing it. The owner's requested lake-first sequence is now complete.

Further owner evidence on 15 September: considerable lag remains when many mobs
appear together, specifically "turtle + archers + cinder wisps". These map to
Hollow Knight/tortoise, Cinder Archer/porcupine and Cinder Wisp/moth; they are outside
the previous fitted-fauna preparation path. The [group-arrival continuation](docs/prototype/play03-group-arrival-worker-2026-09-15.md)
was prioritised ahead of queued PLAY-06 navigation. Its completed adoption is
recorded below. The brief required measuring this actual mixed/group case, preserving the prior
boar fix without presenting it as closure of the broader reported issue. Diagnose
resource loading versus repeated construction/batch cost before choosing the fix.
The owner subsequently expanded this task explicitly to "all the creatures/mobs".
The current prompt covers all regular creatures, both wisps, passive fauna,
LF/elite/era variants and existing boss presentation/spawn paths, including groups.
The reported trio is the starting reproduction, not the completion boundary.
Resolve shared first-use omissions throughout; do not leave the same known issue
for another per-species report. A bounded pass over distinct current presentation/
resource and entry paths is authorised, without renderer/seed/camera/status
combinations or full campaign replay. The owner starts the worker; do not launch
it automatically.

On 16 September the coordinator adopted the completed full-roster continuation
as `9dba2fd`, from worker `43e7cf3`: [result and coverage](docs/prototype/play03-group-arrival-result-2026-09-15.md).
All current ordinary/LF bodies, elite/era variants and distinct boss paths now
share resource preparation during real world/trial entry and validated restore.
The unchanged 30-mob/eight-pack group measured 900.999 to 13.050 ms creation and
950.572 to 40.869 ms for its complete frame. This resolves the demonstrated large
creature-loading cost across the scoped roster; it does not establish hitch-free
play. The residual 40.869 ms group frame, a separately attributed 106.840 ms
pullstone/scenery arrival, long entry and the underground connection remain open.
Reused lifecycle/restore/boss evidence and main's short headless import support
adoption. The owner parked PLAY-06 compass/coordinates on 16 September; do not
prepare its worktree or start it until they return to it. The owner then agreed
to fixing the measured scenery stall, followed by fen/lakeside atmosphere and
later separate highland recovery. [PLAY-07 scenery arrival](docs/prototype/play07-scenery-arrival-worker-2026-09-16.md)
is now integrated as `c5ceb9f` from worker `29e90e4`: pullstone creation measured
154.202 to 2.174 ms; its full frame 178.281 to 8.656 ms. All five rare-source
families retain shared resources during actual entry. Main's short headless
import passed; residual Thrumroot construction, group-frame and loading-time
limits go to cleanup. [RF-06 fen/lakeside atmosphere](docs/prototype/rf06-fen-lakeside-worker-2026-09-16.md)
is integrated as `12238ce` with handoff `710a3c6`. Reused 60 focused worker checks;
main's hidden headless import passed in 4.91 s with zero errors. The owner called
the result "definitely underwhelming" on 16 September. Placement is delivered,
but convincing wetland atmosphere remains an unmet visual outcome. Record that
honestly rather than treating passing functional checks as aesthetic success.
The owner subsequently selected the focused [RF-06B fen art continuation](docs/prototype/rf06b-fen-art-worker-2026-09-16.md)
now, explicitly calling it a worthy tangent. It precedes highlands; a broader
all-environment image-to-3D/Blender intensive remains later, not automatically
authorised by this one-environment continuation.

RF-06B is now integrated as `f6131e4` / `046834d`: five authored wetland forms,
connected low/middle growth and seeded passages. Reused 62 passed worker checks;
main headless import passed in 4.87 s, zero errors. The coordinator inspected three
actual game pictures and finds a clear player-height improvement. This is not a
claim of owner aesthetic approval or full reference atmosphere. The owner asked
to record remaining improvements for cleanup and move on: broad bare clearances,
close patch repetition, tree silhouettes and shaded-bank/shore presentation stay
in the coordination sheet. [RF-07 highland recovery](docs/prototype/rf07-highland-recovery-worker-2026-09-16.md)
is now integrated as `1312c20`. Reused 61 passed worker checks; main headless
import passed in 4.87 s with zero errors. After the coordinator assessed its three
game pictures as useful groundwork but only partly achieving highland atmosphere,
the owner said "I agree, let's move on". Keep rock/ground definition, connected
growth transitions, outcrop/tree repetition and stronger outlook composition in
cleanup; do not record this as full aesthetic acceptance. [RF-08 impact and living-scar composition](docs/prototype/rf08-impact-scars-result-2026-09-16.md)
is now integrated as `ef9601b`. Reused 64 passed worker checks; main headless
import passed in 4.88 s with zero errors. The owner called it a good start and
explicitly approved merging, while asking for meatier cracks with different
coloured magic pulses deep inside. Record that desired direction as unmet, not
as final aesthetic acceptance. The selected
[RF-09 wave cleanup](docs/prototype/rf09-wave-cleanup-result-2026-09-16.md) is now
integrated as `e3a4967`: mineral/ground distinction, textured pocket joins and
local leaf response. Reused 38 passed worker checks; main headless import passed
in 5.08 s, zero errors. The coordinator inspected three actual game pictures:
rock definition is improved, while deep bank/impact shade and simple/repeated
large forms remain. This closes the selected first-pass wave, not its full
visual ambition. Scope the next landscape/biome/influence effort; do not open
another cleanup or treat functional checks as owner aesthetic acceptance.
A dedicated fissure-art production pass is a recommendation recorded in the
coordination sheet, not an automatically dispatched all-environment intensive.
Do not keep extending previous slices or resume R9.

After ram integration on 15 September, the owner said: "Everything looks great -
approved, I haven't done full performance impact yet though but that's fine".
Record the current delivered visuals as approved, including the integrated
porcupine, crane and ram. Full performance impact and broader gameplay feedback
remain unmeasured/incomplete; this does not create a new adoption gate or close
the reported underground-lag issue. Continue the agreed remaining mob sequence.

### Build the look, feel and atmosphere through playable iterations

This is a one-person, spare-time indie prototype. The owner clarified on
15 September 2026 that early slices should establish the game's look, feel and
atmosphere, get that work into play, and improve it over successive iterations.
Perfection and exhaustive technical proof are not completion criteria for these
slices. Give player experience and meaningful progress priority over minor polish.

The earlier ten-minute rule was intended to stop substantial end-to-end pipeline
reviews, repeated baseline comparisons and large live-camera test matrices.
**There is no hard ten-minute cutoff or permission gate for routine completion.**
Do not stop a nearly finished slice to request a few more minutes for a focused
diagnostic, small fix, Git check, commit, integration or push. This clarification
supersedes time caps, countdowns and remaining allowances in older prompts,
handoffs, SETUP files and copied worktrees. It does not authorise broad review waves.

- Before checking, name the concrete risk. Default to at most **three focused
  verification jobs**, on **one renderer** (Forward+ unless the change concerns
  Compatibility). A matrix hidden inside one job is still a matrix. Use a short
  load/use smoke and checks directly relevant to changed behavior. Documentation
  changes need a small link/syntax/diff check, not game tests.
- Reuse applicable passed evidence for unchanged inputs, including the worker's
  checks during coordinator integration. Do not default to rehashing/repacking
  multi-GB parents, rebuilding fresh copies, reopening all Blender masters,
  both-renderer matrices, every seed/material/light/camera combination, repeated
  benchmarks, soak tests or recursive independent reviews. R9 stays stopped.
- Run another focused check only for a concrete changed behavior or observed
  failure. Fixing a review harness or diagnostic-output issue does not justify
  restarting the review. Stop checking once there is enough evidence to deliver
  the scoped playable change. Never weaken assertions, suppress diagnostics or
  claim an unrun check passed.
- Keep small cosmetic issues in the backlog. For example, an odd-looking floor
  slab beneath a chest does not warrant an extended investigation or hold up
  an otherwise usable art slice. Record it and let owner playtesting establish
  its priority. Address minor polish in a later pass unless it is the requested
  focus or materially harms the intended look, feel or atmosphere.
- Only concrete gameplay/save failures or an observed inability to load/use the
  work should block integration. Preserve saves, ownership and game rules.
  Investigate reported movement discomfort and other real playtest problems;
  do not turn hypothetical performance risk or minor visual imperfections into
  new adoption gates. Unmeasured hardware and exhaustive coverage are limitations.
- If checking starts expanding into substantial new investigation, narrow it,
  report the actual uncertainty and deliver the usable slice. Seek direction for
  materially expanded scope or a missing consequential design decision, not
  merely because a clock expired. No unsolicited repair or review waves.
- Complete ordinary authorised commits, integration and pushes with a concise
  handoff: achieved gameplay, checks actually run, remaining issues and publication
  outcome. Do not require a new sealed runtime, source archive or exhaustive report.
  End owned test processes before handing back; leave no testing running silently.

For copied/older project worktrees, read this section from the current owner depot
at `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` before applying an old prompt.

### Protect the original plan — owner correction, 16 September 2026

The owner wants to "largely stick to the original plan" and make the default for
additions that "we note them and do a slice at the end to fix them up". They report
getting lost in tangents and losing the original intent. The coordinator should
raise additions, but take a firm stance toward the original slice breakdown.

- Keep the agreed original outcomes and slice sequence as the main schedule.
  Show which original outcome each new worker advances. Do not silently insert
  another feature, optimisation or polish pass whenever an issue is discovered.
- Record additions and non-blocking bugs in the current wave's end-of-wave cleanup
  backlog, with the observation, impact and any useful evidence. Briefly raise
  them with the owner and recommend deferral by default, explaining which planned
  slice would be delayed if handled now. A suggestion or playtest observation is
  not, by itself, a direction to reorder the plan. Standing approval is not a
  licence for the coordinator to keep expanding the sequence.
- Continue small fixes necessary to deliver the current agreed behavior. Flag a
  concrete blocker to that behavior, inability to load/play, or save/ownership
  risk promptly and explain why it needs attention now. Do not use hypothetical
  risk, missing exhaustive evidence or minor polish as an exception. The owner
  can explicitly reprioritise at any time; record that decision and its effect.
- At the end of the original wave, consolidate the recorded fixes into a bounded
  cleanup slice based on their actual player impact. Do not create a new task per
  note or an exhaustive final review/benchmark wave. Optional new features remain
  proposals; recording them does not automatically approve their implementation.
- Handoffs should identify original-plan progress, the next planned slice and
  additions deferred. Keep known issues open and honest without making each one
  the next automatic assignment. Preserve the original intent in future prompts.

PLAY-07 has now finished its approved scope and is integrated. Return to the
Reclaimed Frontier outcomes: fen/lakeside atmosphere, highland recovery, and remaining composition
around recovered impacts/living scars. Scope these as small playable iterations
of the original direction, then address the cleanup backlog. Compass/coordinates
remain parked. Do not extend completed PLAY-07 into another performance tangent.

### Creative briefs must deliver the intended look — owner correction, 16 September

After RF-06's underwhelming result, the owner approved continuing the fen now
and asked to fix prompting going forward. This is an explicit sequence exception:
RF-06B art/composition, then highlands, impact/scar composition and cleanup.

For art/atmosphere work, lead the brief with what the player should visibly see
and feel, the relevant reference qualities and a few concrete scene outcomes.
Distinguish these from technical safeguards. Functional checks establish usable
placement and preserved gameplay; they do not establish an appealing environment.
Do not label the requested visual outcome as incidental polish and defer it
merely because the implementation passes tests.

Build one representative ordinary in-game scene early, inspect it at player
height and revise the dominant visual weakness before expanding its seeded rules.
Reuse existing assets when they suit the result; permit a small purpose-made kit
when reuse falls short. Scope asset forms, grouping, ground transitions and
readability together. A concept, isolated model or dense scatter is not by itself
the delivered environment. No hardcoded showcase-only scenery as the final result.

This changes artistic focus, not the review burden: no new approval gate,
perfection requirement or camera/baseline matrix. Report achieved appearance,
remaining visual weaknesses and functional checks separately, with actual game
pictures. Keep the normal prototype limits and current worker-start workflow.

After RF-08 adoption, the owner emphasised "go big and graphically awe" for
future visual work, and raised world generation as a possible underlying issue.
Treat visual ambition as a requirement: lead with memorable landscape silhouettes,
scale, depth, strong landmarks and places that inspire exploration or a home.
A bounded task means a focused area/outcome, not a barely perceptible change.
Identify whether the dominant gap is landform generation, terrain rendering,
asset shape/material, or their composition before prescribing more scatter.
Keep the recovered, living landscape direction and useful quiet/buildable spaces;
dramatic scenery does not mean cliffs, bare craters or glowing surfaces everywhere.
This direction does not itself select a new generation profile, rewrite existing
saves or dispatch a broad art overhaul. Close the agreed wave with bounded
cleanup, then scope the proposed larger landscape work explicitly. Use one
convincing ordinary game area to establish the result and reusable seeded rules.

The owner then endorsed that sequence and requested more biome types, with
world generation tying the technology/magic colours to effects on areas, growth
and fauna. Carry this as a connected design requirement for the next landscape
effort, building on D-030 and the existing influence identities in
[world-premise.md](docs/world-premise.md). Different biomes and altered hosts need
recognisable forms and relationships, beyond colour swaps. Specific biome lists,
influence distribution/mixing and new gameplay rules remain to be scoped.
RF-09 cleanup is adopted; the next task is scoping that larger connected effort.
RF-09 is unrelated to the historical ART R9 review, which remains stopped.
The prepared [LAND-01 planning task](docs/prototype/land01-landscape-plan-worker-2026-09-16.md)
turns that direction into one recommended region, biome/influence design and a
concrete first implementation brief. It is planning only, with source/evidence
reuse and documentation checks; do not start a generator rewrite or another review
wave. The owner starts its D: worker. Proposed LAND-02 is not yet dispatched.

### Standard game development practices at prototype scale

The owner asked why established game-development techniques were not the default
after the mob-arrival fix. Use suitable existing engine facilities and established
patterns when implementing a slice; explain a custom approach when it is needed.
For heavier art integration, plan when shared scenes, textures and materials load
and how they are reused. Keep avoidable blocking resource loads out of active
movement/spawn callbacks, using a suitable loading/preparation point. Preloading
everything is not a universal rule: consider the slice's startup and memory cost.
When this path changes, include first use in the existing short load/use smoke,
not only an already-warmed showcase. This is routine implementation discipline,
not a new adoption gate, benchmark matrix, full-project audit or generic framework.
The PLAY-03 result supplies a concrete reusable example for fitted fauna.

## Storage discipline — owner cleanup request, 15 September 2026

Keep the active owner depot at `C:/Users/Matty/Dev/project-wroughtwild` and
preserve its Git metadata, task paths and remote-access tooling. Do not relocate
an active checkout or change app/remote settings as part of storage cleanup.

Use `D:/Wroughtwild/work/<slice>` for new explicitly prepared worker worktrees
and their large build/import/render outputs. Existing D: worktrees keep their
paths. Use `D:/Wroughtwild/source-art` for newly archived approved source art,
`D:/Wroughtwild/releases` for retained playable packages, and
`D:/Wroughtwild/archive` for compact historical records. These are local storage,
not an off-device backup. Do not copy the entire parent package for each review.

Keep approved editable masters, selected runtime assets, recipes/manifests,
current unresolved-issue evidence, and player saves. For future completed work,
retain a current playable package and one useful previous package plus selected
screenshots/clips and short reports. Remove confirmed disposable review copies,
failed scratch outputs and unused import caches after identifying their retained
source and checking that no active task uses them. Do not delete by age or file
extension alone; ignored build folders can contain unique art and Git worktrees.
Never prune registered worktrees or unique source packages as generic cache cleanup.

See `docs/prototype/storage-retention-2026-09-15.md` for the cleanup boundary and
retained archive. Historical publication reports may refer to disposable copies
that were removed; canonical handoffs remain at their original paths.

## Required reading order

Before planning or editing:

1. Read `README.md`.
2. Read `docs/DESIGN.md`.
3. Read `docs/decisions/registry.md`.
4. Read `docs/prototype/vertical-slice.md` and `docs/prototype/acceptance-criteria.md` for prototype work.
5. Read only the system specifications relevant to the task.

Do not load every document merely because it exists. Follow links from the active work item.

## Source-of-truth order

When instructions conflict, use this order:

1. The current human-approved work item.
2. Accepted decisions in `docs/decisions/registry.md` and accepted ADRs.
3. Prototype scope and acceptance criteria.
4. Relevant system specifications.
5. Master design.
6. Existing implementation.

If code contradicts an accepted design decision, stop and report the conflict. Do not silently make the document match the code or vice versa.

## Workflow

For every implementation task:

1. Restate the requested outcome.
2. Identify affected systems, decisions and tuning files.
3. List assumptions and unresolved design questions.
4. Propose a small implementation plan.
5. Wait for human direction when a missing decision materially changes player experience, save compatibility or architecture.
6. Implement the smallest complete behaviour.
7. Run relevant tests and checks.
8. Report the result, limitations and tuning parameters introduced.

For every completed slice, start the completion report with a short plain-language
summary of what the slice achieved. Include material remaining limits, followed by
verification and the actual commit/push outcome. The owner requested this ongoing
reporting format on 14 September 2026.

## Owner's commit workflow

The owner has given standing permission to commit completed, checked slices to
`main` and make ordinary non-force pushes without asking again. The confirmed
destination is `origin/main` at
`https://github.com/Jattymoels/project-wroughtwild.git`. On 7 September 2026 the
owner explicitly confirmed: "Yes, push to that repository and remember it for
future slices." Record results and limitations with each slice. This permission
covers this project's approved work, not unrelated changes, history rewrites,
remote changes or destructive Git operations.

Repository guidance does not override platform approval controls. If automatic
approval review rejects publication, explain the stated reason and obtain the
specific approval it requires; do not retry through another route. A local
commit and a successful remote push must be reported separately.

## Desktop comfort during automation

The owner reported on 14 September 2026 that automated art/game runs interfere
with moving the mouse across their monitors. Prefer background Blender jobs and
headless Godot checks whenever the check does not require rendered output.
For rendered captures, use a verified test-only mouse-capture opt-out and a
non-focusing window where supported; hidden or offscreen launch alone does not
prove that the cursor stays free. Prefer engine viewport captures and scripted
camera/input over moving the desktop pointer. Keep real mouse-control tests
explicit, and mention unavoidable foreground interaction before running them.
Preserve normal play controls, source seals, active peer jobs and benchmark
conditions; do not silently throttle measurements or edit running worktrees.
This is a workflow preference, not evidence that existing launchers implement it.

On Windows, write temporary Godot overrides as **BOM-free UTF-8**. MOB-06 caught
Godot ignoring a BOM-prefixed no-focus override. The corrected
`tools/wroughtwild-mob06-tortoise/run_checks.ps1` retains the process handle before
waiting, verifies its exit code and asserts capture comfort. Reuse that correction
for future captures; do not assume `Set-Content -Encoding utf8` behaves identically
across Windows PowerShell and PowerShell versions. Do not rerun old captures solely
to retrofit this launcher fix.

## Prototype boundaries

Unless a human-approved decision changes the boundary, do not introduce:

- multiplayer, networking, raids or shared-world persistence;
- infinite world generation;
- more than the minimum representative content needed by the vertical slice;
- complex structural-integrity simulation;
- controller-specific building UI;
- large-scale factory automation;
- a general framework for hypothetical future systems;
- production art dependencies when primitives or placeholders are sufficient.

## Design discipline

- Do not invent game rules to unblock code.
- Mark proposals as proposals; do not present them as accepted decisions.
- Put tunable numbers in engine-neutral data or engine resources rather than scattering constants through logic.
- Every tuning parameter needs a plain-language explanation of what player experience it controls.
- Prefer tags and composable rules over hard-coded skill/item exceptions.
- Keep persistent build effects distinguishable from temporary trial effects.
- Avoid duplicate currencies, materials or progression gates without a documented purpose.
- Update relevant documentation when approved behaviour changes.

## Code discipline

- Use deterministic seeds for systems that require repeatable tests.
- Separate simulation/domain rules from presentation and engine scene code.
- Write focused tests for crafting costs, skill XP, loot rules, boon interactions, death recovery and generation guarantees.
- Preserve save compatibility once a save schema is declared stable.
- Do not weaken or remove tests to accept generated behaviour.
- Do not add third-party packages, assets or network services without explicit approval.
- Never commit secrets, local credentials, generated builds, caches or imported engine artefacts.

## Completion standard

A task is complete only when:

- the requested behaviour works;
- relevant automated checks pass;
- new tuning values are documented;
- known limitations are reported;
- affected specifications or decisions are updated when required;
- no excluded prototype scope was introduced incidentally.
