# AI Agent Instructions

These instructions apply to every AI-assisted change in this repository.

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
