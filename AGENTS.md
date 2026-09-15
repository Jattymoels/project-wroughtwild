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
existing gameplay rules. The current priorities are finished fauna adoption,
reported stuttering/significant underground lag, canopy completeness, then the
remaining replacement-mob rigs in small playable slices. Deferred owner station/campaign
feedback does not hold up this sequence. R9 remains stopped.

The owner clarified in the movement worker on 15 September that PLAY-03 is
significant lag underground, not difficulty or unintended access underground.
Preserve legitimate cave/digging behavior; do not invent an access restriction.

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
