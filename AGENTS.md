# AI Agent Instructions

These instructions apply to every AI-assisted change in this repository.

## Prototype work limits — owner correction, 14 September 2026

This is a spare-time game prototype. The owner rejected the multi-hour R9 review
and its repeated testing/analysis. These limits supersede older exhaustive evidence,
benchmark, packaging and publisher requirements throughout this repository.

- Default review/verification budget: **10 minutes total wall time per task**.
  For review-only tasks this includes reading, analysis, setup, imports, copies,
  hashing, tests, renders and reporting. For implementation tasks it covers the
  combined verification work. Retries, new versions, processes, compaction,
  delegation and publisher follow-up do not reset the budget or justify repeating
  the worker's passed checks. Track elapsed time and reserve time to report.
- Before checking, name the concrete risk and choose at most **three focused
  verification jobs**, on **one renderer** (Forward+ unless the change concerns
  Compatibility). A matrix hidden inside one job still counts as a matrix.
  Documentation-only work needs a small link/syntax/diff check, not game tests.
- Reuse applicable passed evidence for unchanged inputs. Do not default to
  rehashing/repacking multi-GB parents, rebuilding fresh copies, reopening all
  Blender masters, both-renderer matrices, every seed/material/light combination,
  repeated benchmarks, soak tests or recursive independent reviews.
- Run another check only for a concrete changed behavior or observed failure,
  within the same budget. Preserve failures; never weaken assertions, suppress
  diagnostics or claim an unrun check passed. Fixing a review harness does not
  justify restarting the whole review. Stop once there is enough evidence for
  the scoped prototype decision.
- If a necessary check cannot fit, **stop and report** the result available,
  exact unverified risk, proposed next check and estimated additional time.
  Obtain explicit owner approval before spending more time. An older prompt's
  blanket requirement is not approval to exceed this limit. Do not make every
  minor omission a question or blocker; label low-impact gaps and finish.
- At the deadline launch no more jobs and safely cancel only owned testing
  processes where possible. Preserve artifacts and report incomplete checks.
  Never leave background testing running after declaring the task stopped.
- Only reproducible gameplay/save failures or demonstrated unusable performance
  should be proposed as adoption blockers. Cosmetic gaps, exhaustive coverage,
  unmeasured hardware and hypothetical future risks are limitations by default.
  Prefer a playable iteration and owner feedback. No unsolicited repair waves.
- Handoffs should be concise: achieved behavior, checks actually run, real
  blockers/limits, and commit/push outcome. Review-only tasks reuse existing
  packages and need no new sealed runtime, source archive or exhaustive report.

For copied/older project worktrees, read this section from the current owner depot
at `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` before applying an old prompt.
The owner can explicitly choose a larger scope/budget for a particular task.

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
