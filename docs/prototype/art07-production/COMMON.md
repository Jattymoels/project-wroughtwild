# ART-07 session contract

The owner requested a sliced execution plan and prompts for separate sessions
after the ART-07 design delivery. This document accompanies every worker prompt.
The boards are the selected production direction; future generated meshes still
need actual visual and technical review. This planning delivery launches no jobs.

## Before work

1. Locate `C:/Users/Matty/Dev/project-wroughtwild` and inspect the actual checkout,
   branch, status, recent history and origin URL. Read `AGENTS.md`, then follow
   its required order: README → DESIGN → registry → vertical slice/acceptance →
   only the relevant specifications and reports listed in the assigned prompt.
2. Read the assigned prompt, this contract, [PROCESS.md](PROCESS.md), the
   [ART-07 work item](../world-and-placeable-art-2026-09-09.md) and its selected
   concept/catalogue entries. Documents describe intent; inspect actual sources.
3. Restate the bounded result, affected presentation systems and assumptions.
   Plan the smallest complete handoff. Do not implement another slice.
4. Verify prerequisite receipts, commits, local package paths and hashes before
   consuming them. Do not assume that a scheduled predecessor has delivered.
   Missing dependencies permit independent concept/source inspection, not an
   invented completed handoff. Report an actual missing input precisely.

## Worktree and file ownership

Use a separate checkout for every concurrent worker. Prefer the app-created
worktree if already present; otherwise create an isolated `codex/art07-<id>`
worktree from an inspected, published main revision. Do not reset or clean the
owner's checkout, switch its branch under another session, stash unrelated work
or remove other worktrees. Current normal saves, captures and playtest processes
are unrelated work and must remain intact.

Each worker owns only its assigned paths:

- `tools/wroughtwild-art07/<ID>/`: reproducible source recipes, slice-specific
  settings/checks, manifest and standalone review source.
- `docs/art/leyline-studies/2026-09-09/art07/<ID>/`: versioned single-asset inputs,
  exact prompts, selected actual model evidence and concise result report.
- `docs/prototype/art07-production/receipts/<ID>.md`: technical receipt.
- `build/art07/<ID>/<fresh-version>/`: ignored raw GLBs, packed Blender masters,
  generated runtime assets, isolated projects, logs, test saves and handoffs.

In the paths above, ID is lower case, for example `b1`. New output directories
must not overwrite any approved source, earlier candidate or hand-edited master.
Existing ART-01–06 code and packages are read-only references. If borrowing a
recipe, create a minimal task-local derivative and record its source; do not
refactor the shared original. Shared helpers are not a prerequisite for all
workers and must not become a general framework for future systems.

Only the publication/integration session updates shared queue/roadmap files.
Workers do not change `game/`, `sim/`, `data/tuning/`, the ART-07 catalogue or
another worker's directories. G1 may modify a **copied isolated game**, not the
normal checkout's game. Any eventual ordinary-world adoption is a separately
reviewed step. Stop and report a material accepted-design/code conflict; do not
silently repair an unrelated gameplay rule.

## Concurrent work and publication

Parallel source editing is allowed in separate worktrees. There is **one GPU
work slot per machine**: TRELLIS generation, Blender GPU rendering/baking and
Godot capture/benchmark jobs must be scheduled serially. The named mutex example
in PROCESS is cooperative coordination; inspect existing Studio/game jobs too.
Never kill another session or the owner's playtest to free the GPU. A benchmark
with competing load is labelled diagnostic and cannot clear the performance gate.

Workers commit checked work to their own `codex/` branch and report the commit
and cleanly scoped diff. They do not concurrently push or cherry-pick onto main.
The included `PUBLISH.md` prompt gives one publisher responsibility for integrating
checked commits and making the ordinary non-force push to the already approved
origin/main. Standing owner permission covers routine checked commits/pushes;
do not ask again. Platform approval controls still apply. An automatic rejection
must be reported with its stated reason; do not route around it.

This worktree arrangement coordinates publication; it does not revoke the
owner's standing permission or add a mandatory human approval for routine work.

## Art and gameplay boundaries

- Preserve the fuller ENV-002-inspired canopy/ground composition, earthy
  materials, recognisable hosts and deep structural magic scars. Do not replace
  organic hero assets with crude primitive approximations to declare completion.
- Most ordinary vegetation and construction stays unlit. Scars have real depth
  and visible energy inside damage; ambient life, source/work state and attack
  tells remain distinct. No new healing, element or influence rule is inferred.
- Preserve the approved animals and ART-04 Red/White/Blue/Green families. No new
  species/AI, enemy cap, dash invulnerability, era, generator profile, currency,
  recipe, resource stock or broad production system. The timber-demolition
  conflict remains outside this art work.
- Existing geometry, finite identities, saved depletion, resource ownership,
  inventory, progress, body sizes, costs and material trait gates are constraints.
  Adapt visual details inside them; never ignore a real collision to fit art.
- Failed placement retains the kit; success gives exactly one usable object.
  Native contents, requests, drive, heat, escrow and refunds remain authoritative.
  A signal is not energy. The forge upgrade is in place, not another kit.
- No new paid service, model download, package, global install, driver change or
  asset licence is needed. Existing local dependencies and source packages are
  reused. Missing tools are a specific prerequisite issue, not permission to
  replace the pipeline or purchase a subscription.

## Completion and handoff

Deliver one packed editable source set, selected runtime candidates with a
manifest, an isolated review, actual rendered evidence and a receipt following
[the template](receipts/TEMPLATE.md). Record near/middle/far counts and texture
costs, pivots/scale, source hashes, state mappings and exact commands. A clone
does not contain ignored local packages: give their absolute path and hash, plus
reconstruction steps. Do not commit raw generation, caches, dependency bundles,
normal saves or working builds. Follow the repo's established convention of
versioning recipes, original input PNGs and curated evidence. Runtime-source
adoption and any deliberately selected shipped asset require their own record.

Relevant checks must pass without relaxed assertions. Reopen the delivered
Blender master and import a fresh copy of the handoff; do not certify only the
working directory. For stateful objects, verify real native state and a separate
process reload. Static study scenes must say which interactions are not present.
Use actual Godot views in both Forward+ and Compatibility where the asset has
engine material/motion; report device, settings and measured limitations.

Show the principal actual model renders and pulse/motion evidence directly in
chat using absolute local media paths, so the owner can review remotely. Compare
against the concept and name shortcomings candidly. Technical completion is not
owner visual approval, and a raw GLB import is not game readiness. Finish with
implementation, checks, limitations, local commit and publication status stated
separately. Stop after the assigned slice.
