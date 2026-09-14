# Art mainline adoption and owner playtest follow-up

Status: owner-authorised coordinator handoff, 14 September 2026. Runtime adoption
and fixes are not implemented by this document.

## Owner direction

After manually playing the combined R8 preview, the owner said it was fun and
asked for all the completed art work to go into mainline with the observed
problems recorded. This authorises adoption of the delivered art, including the
R8 candidate with its known visual/performance limitations. It supersedes old
"owner visual acceptance pending", ordinary-world exclusions and R9 clearance
requirements for that adoption. Do not ask the owner to approve the same
integration again. This is acceptance for prototype integration, not a claim
that every asset is flawless or every station has been playtested.

The requested next step in this task is a prompt for a new coordinator. Do not
start the runtime merge, new workers or another R9 review as part of writing it.

## Actual playtest feedback

| ID | Owner observation | Follow-up |
| --- | --- | --- |
| PLAY-01 | Very laggy through repeated little interruptions/judder, rather than delayed input. Stuttering was too much for comfortable play. | Highest-priority performance follow-up after adoption. Investigate frame-time spikes during ordinary movement; average FPS alone does not describe the complaint. Cause is unconfirmed. |
| PLAY-02 | Tree canopies look as though some parts have not been created. | Inspect the apparent missing/incomplete canopy portions at player height and across distance changes. Geometry, material visibility and detail switching are possibilities to inspect, not diagnosed causes. |
| PLAY-03 | The player accidentally went underground; lag immediately became much worse. | Investigate unintended below-terrain access and the additional stuttering there. Exact location/reproduction and cause are unknown. Preserve the player's save; do not assume normal intended underground travel. |
| PLAY-04 | Most new stations were not interacted with yet; the owner intends to try them in a later playtest. | Station usability remains unreviewed by the owner. Existing automated evidence is not a substitute for that feedback. |

These are reports from a human playtest, not independently reproduced findings.
The owner explicitly requests mainline adoption with these issues noted; they
are not new pre-merge performance or cosmetic gates. A concrete new save-loss,
gameplay corruption or inability-to-load defect should be reported precisely.

The playtest used the local launcher
`C:/Users/Matty/Dev/project-wroughtwild/build/art-playtest/Play-Art-Preview.cmd`.
Its copied runtime is under the sibling `runtime/`, and its private saves and
preferences are under `user/ART07G1/`. The scene is `res://g1/play.tscn`, using
the prepared paid-home checkpoint and Forward+. These local files may be useful
for reproducing the report; do not overwrite the owner's playtest state.

## Starting points and actual completion state

- Current owner checkout: `C:/Users/Matty/Dev/project-wroughtwild`, branch `main`.
  At handoff preparation its HEAD was `4ac1c3a952b4d87181820a36ed2a6aae3c5c32fd`.
  Inspect current Git state on arrival; that hash is context, not a reset target.
- All 26 original ART-07 slices and R1–R8 are delivered/published as source and
  handoff work. Publication of those tools/receipts is not adoption of the full
  art kit into the ordinary `game/` project.
- The combined selected runtime is
  `D:/project-wroughtwild-art07-r8/build/art07-repairs/r8/v01/handoff-final/runtime`.
  The parent package's `runtime-files.json` and `changes.json` describe its files
  and presentation changes. Read the [R8 publication](art07-repairs/2026-09-14/publication-r8.md)
  and [receipt](art07-repairs/2026-09-14/receipts/r8.md) selectively for relevant
  implementation details and retained limitations. Preserve this source package.
- That runtime uses an older frozen game baseline,
  `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. Port the relevant assets and
  presentation adapters into current main. Do not replace current game/data/native
  code wholesale with the preview, or make its fixed-seed paid-home scene the
  normal game entry point. Retain current campaign, new-world and Continue flows.
- [ART-01 boar](boar-living-scars-2026-09-09.md),
  [ART-03 wolf/stag/moth](fauna-art-2026-09-09.md),
  [ART-02 grove](affected-grove-2026-09-09.md) and
  [ART-04 sources/devices](source-workshop-art-2026-09-09.md) have approved
  handoffs. Check what R8 already consumes and what normal game still loads;
  adopt the latest approved finished versions without duplicate integration.
- The six [ART-06C mobs](roster-lifelines-2026-09-09.md) are generated, surface
  finished and visually approved. Rigs, deformation/movement, runtime preparation
  and normal enemy-role integration remain real implementation work. Record
  these separately and finish them in small slices; do not call static source
  models playable replacements or regenerate approved designs by default.

| Existing role | Approved replacement |
| --- | --- |
| `cinder_archer` | Porcupine |
| `stone_husk` | Bighorn ram |
| `shrieker` | Crane |
| `gloom_crawler` | Ground beetle |
| `bog_lurker` | Six-legged dragonfly nymph |
| `hollow_knight` | Tortoise |

R9 is stopped, with existing results preserved and its final audit incomplete.
Its task was `01a09f75-3a3c-7cf0-aae7-797bbfc194ce`, worktree
`D:/project-wroughtwild-art07-r9`. Uncommitted R9 work is not a sealed replacement
for R8. Consult a specific useful existing result when needed; do not resume its
matrix, demand completion of its audit, or indiscriminately merge its test tools.

Later-era physical variants, remaining boss art and the
[Reclaimed Frontier intensive](reclaimed-frontier-intensive-2026-09-14.md) are
future work, not already-built assets to merge. Preserve the six landscape
references and their owner caveats: years-after green recovery, undulating living
terrain and old impacts with surviving pulsing cracks. They are influences,
not literal scene/style targets, and do not authorise a new generator/save rule.

## Coordinator outcome and execution order

1. Produce a brief inventory of delivered assets already in normal gameplay,
   ready for adoption, and needing real finishing. Follow the selected handoffs;
   do not re-audit every historical file. Give each delivery a clear in-game
   outcome, a small scope and any dependency that actually matters.
2. First deliver mainline adoption of the completed R8 art and relevant finished
   fauna/device handoffs in manageable commits. The result must be available
   through the normal game launcher, new world and Continue flows, not just a
   showcase. Preserve current saves, ownership, game rules, octagonal building
   support and existing later campaign work. Keep PLAY-01–04 visible.
3. After adoption, prioritise PLAY-01 stuttering and PLAY-03 underground access/
   worsening lag, then PLAY-02 canopy completeness. Investigate only what the
   owner observed; use one brief representative capture if needed to identify
   the responsible work. Do not lower the approved visual target or remove
   content merely to make a performance number pass.
4. Complete and adopt the six remaining mob rigs/movement in bounded slices,
   retaining existing enemy roles, attacks and gameplay. Do not let their
   unfinished animation hold up the ready environment/station integration.
5. After every slice, give a short summary of what it achieved in the game,
   actual checks, remaining issues, commit and push, and exact playtest steps.
   Maintain this inventory as deliveries land. Station feedback can be added
   when the owner has tried them.

The coordinator should prepare the first bounded implementation prompt and
workspace setup immediately, then coordinate completed work into main. Do not
turn the handoff into another approval or review queue. The owner retains the
existing pattern of starting worker sessions from supplied prompts; do not
automatically create visible worker tasks or message completed sessions just to
announce progress. Do not create a new multi-wave repair programme up front.

## Working limits

Read current owner [AGENTS.md](../../AGENTS.md), including from older D: worktrees.
Use its required reading order, then only the specifications for the active
slice. The current owner approval outranks historical exclusion boilerplate.

- Owner clarification, 15 September: no hard ten-minute cutoff or permission
  gate for routine diagnostics, small fixes or finishing delivery. Prioritise
  playable look, feel and atmosphere, then iterate. Default to three focused
  jobs on one renderer; broad pipeline, baseline and camera matrices remain
  out of scope. Minor visual polish should not delay an otherwise usable slice.
- Reuse passed evidence for unchanged code. Short load/use checks and directly
  relevant changed-behaviour checks suffice for adoption. No pre-adoption baseline
  comparisons, both-renderer matrices, all-seed/material checks, exhaustive
  hashing/repacking, soak tests or independent R9 clearance.
- Performance investigation is now justified by actual PLAY-01/03 feedback.
  Keep it focused and separate from an adoption approval gate. Broad end-to-end
  work waits for the owner's chosen phase. Stop expanding checks once there is
  enough evidence for the playable slice; report limits and leave no tests running.
- Use headless/background engine and Blender processes when appropriate, and
  the existing no-focus/mouse-capture opt-out for automated rendered checks.
  Do not seize the owner's cursor or foreground while they use their computer.
  Manual play retains normal mouse capture and Escape release. No background
  benchmarks/imports should compete with their playtest.
- Preserve unrelated dirty captures, local saves, sources and other worktrees.
  Do not stage build folders, imported caches, engines, evidence dumps or secrets.
  Commit only the slice's required code/runtime assets and relevant documents.
- Standing permission covers checked commits to `main` and ordinary non-force
  pushes to `origin/main` at `https://github.com/Jattymoels/project-wroughtwild.git`.
  Report commit and successful push separately; respect platform controls and
  report any actual publication rejection. No repeated permission request for
  ordinary authorised integration.

Completion means the finished assets actually appear in the normal playable
game, the owner can launch it easily, and unfinished assets/issues are honestly
tracked. This handoff does not claim the runtime changes or fixes are done.
