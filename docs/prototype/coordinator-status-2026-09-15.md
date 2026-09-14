# Wroughtwild current coordination sheet

Updated 15 September 2026, Adelaide. This is a lightweight inventory and dispatch
plan, not a new acceptance gate. The owner wants a solo indie prototype developed
through playable iterations. Current AGENTS.md and the owner's approved work
outrank historical review, packaging and rollout requirements.

## Working rhythm

Build a small playable improvement, integrate it, run a short check, then use
the owner's experience to choose the next improvement. Keep one integration
worker active at a time. The owner starts worker sessions from supplied prompts;
the coordinator brings completed, checked commits into main and pushes normally.
Do not automatically launch workers, independent reviewers or repair waves.

The owner cannot currently playtest and on 15 September granted standing approval
for the agreed prototype work until told otherwise. Continue ordinary implementation,
presentation choices, integration and checked pushes without another visual approval.
Owner playtesting is deferred feedback, not a gate; never record unplayed work as
personally tested by the owner. The worker-start workflow above remains available.

Track four different kinds of remaining work: implementation, integration,
reported bugs and playtest questions. A checked implementation can be in the game
while feel/balance feedback remains open. Do not restart a completed intensive
merely because a historical checkbox still says human review pending.

## Repository inventory

Current adoption update: A1 is integrated on main as `35cee73` and successfully
pushed to `origin/main`. The [result and normal-game playtest steps](mainline-art-a1-result-2026-09-15.md)
record the reused worker checks and the short headless main asset import.
A2 is integrated and pushed on main as `27e742d`.
The [A2 result](mainline-fauna-a2-result-2026-09-15.md)
records the finished fauna, native checks and the small missing C3 shader repair.
The inventory below preserves the original coordination inspection.

At inspection, local main, origin/main and the live GitHub main all point to
`1ec453f6ecbb4fc42a018cd7547de530b36461da`. This is the starting point before
this coordination document's own commit, not a reset target.

- Thirty local ART-07 branches appear unmerged by ancestry: B1–B4, C1–C6,
  D1–D6, E1–E3, F1–F5 and R1/R3/R4/R5/R6/R7. `git cherry main <branch>`
  reports **zero unique patches for every one**: their equivalent changes are
  already on main through publication/cherry-picks. Do not merge them again.
- Other retained local branches, including G1/G2/R2/R8/R9 and the old gameplay
  waves, are ancestors of main. The advertised remote branches also match
  already-contained refs. No missing committed branch work was found.
- All 37 registered worktrees were inspected. Before this task's edits, only
  the owner depot and R9 had non-ignored changes. The depot has 38 status entries:
  five modified LF6 captures and untracked captures, test saves/probes and UID/
  import sidecars. Preserve them. R9 has untracked review evidence and tools;
  its review remains stopped and incomplete. The other 35 worktrees are clean.
- Ignored local build/package contents were not exhaustively inventoried. The
  selected R8, ART-01, ART-03 and ART-05 handoff paths exist. Generated deliverables
  under build/ can still be local-only even when their recipes are published.
- A scoped Git comparison found **no tracked differences in game/, sim/ or
  data/** between main and R8's frozen pin
  `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. This simplifies the current port;
  current main remains authoritative if it changes before implementation.

## What is actually built, and what remains

| Area | Current state | Remaining work |
| --- | --- | --- |
| Core sandbox | Gathering, processing, building, storage, exploration, combat, death recovery and saves are implemented. Normal new worlds use finite V6 geography with seed/Continue controls. | Judge whether the first half-hour creates useful ambitions and whether travel/building feel good. |
| Foundry, gear and trials | Classes, skill discovery, Kind/ingot interactions, crafting quality/mastery, Forge story and repeatable tiers are implemented. | Human build satisfaction, class balance, progression explanation, encounter tells and run length. Full Crossfire completion and upper-tier balance remain open evidence/feel questions. |
| Living Frontier | Waves 1–7 and INT-18A are implemented on main: four-colour extraction/devices, laboratories, two protected terrain changes, human finale and captured challenges. | Still uses the existing opt-in campaign launch/policy. A continuous fresh campaign and ordinary-startup adoption decision remain distinct from this art port. Do not schedule LF3–7 again from older queue text. |
| INT-01–08 improvements | Clarity, home placement/hauling, audio, workshop usability, combat feedback, save recovery, streaming, controls and portable export have implementation records. | Targeted owner feedback; investigate reported defects. Other-machine play and broad final regression wait for the chosen playtest phase. |
| Existing normal-game art | A1 supplies the R8 environment, resources, buildings, stations and devices; A2 supplies the finished boar/wolf/stag with existing moths preserved. All use normal world/Continue entry. | Reported movement, underground and canopy issues remain open; owner playtesting is deferred. |
| R8 environment/placeables | All 26 original ART-07 deliveries and R1–R8 are published as source/handoff work; their selected production runtime is now adopted on main. | **A1 integrated and pushed as `35cee73`.** [Result and playtest](mainline-art-a1-result-2026-09-15.md). |
| Finished fauna | A2 adopts ART-01 boar and ART-03 wolf/stag, including existing LF visual aliases, on native actor clocks. Moths retain their earlier art/motion. | **A2 integrated and pushed as `27e742d`.** Mid detail, foot sliding and no terrain IK/distance switching are recorded limits. [Result](mainline-fauna-a2-result-2026-09-15.md). |
| Six replacement mobs | Approved ART-06C surfaces/models exist for porcupine Archer, ram Husk, crane Shrieker, beetle Crawler, six-legged nymph Lurker and tortoise Knight. | Real rigging, weighting, locomotion/attack presentation and runtime integration, one complete enemy role per slice. Static models are not playable replacements. |
| Later art/world ambition | Later-era physical augmentation, remaining boss/host art and Reclaimed Frontier references/direction are recorded. | Future scoped production/design. Reclaimed Frontier means living, rolling terrain years after impact, vegetation reclaiming damage and surviving pulsing cracks; no new generator/save rule is selected. |
| Broader game ambition | Class halls, substantial outpost/transport progression, larger production networks and richer late-game content remain longer-term design. | Choose only what the current prototype loop demonstrates it needs. Multiplayer, infinite generation and broad factory/trading systems remain outside scope. |

The older master design and sections of the intensive queue contain dated
snapshots (for example V5 world size and LF2 as the latest wave). Use accepted
successor work items and current implementation status above. Existing recorded
questions such as timber demolition policy and era-sensitive gear previews belong
to their own future decision/bug work; art adoption must not silently decide them.

## Immediate execution order

1. **A1 — completed on main and pushed.** Environment, building/resource materials,
   stations and devices, preserving current world/campaign/save rules and octagonal
   support. [Exact worker prompt and workspace](mainline-art-a1-worker-2026-09-15.md).
2. **A2 — completed on main and pushed.** Boar, wolf, stag and preserved moth; current
   enemy IDs, bodies, attack clocks, statuses, drops and passive habits remain.
   [Worker result](mainline-fauna-a2-result-2026-09-15.md); integrate and push the returned commit before the six unfinished replacement rigs.
   [Prepared worker prompt and D: workspace](mainline-fauna-a2-worker-2026-09-15.md).
3. **PLAY-01/03 — movement comfort and underground access.** Diagnose ordinary
   frame spikes and the accidental below-terrain transition/worse lag. Preserve
   the owner's preview save. Use a short representative trace/reproduction;
   do not assume streaming, collision, shaders or geometry is the cause.
   [Prepared movement worker and D: workspace](play01-movement-worker-2026-09-15.md).
4. **PLAY-02 — canopy completeness.** Inspect the reported missing portions and
   distance transitions; fix the demonstrated geometry/material/detail fault.
5. **Remaining mob production**, one existing enemy role per rig/animation/runtime
   slice. Deferred owner playtesting does not hold this up. Physical era variants
   and boss art retain explicit backlog entries.
6. **Owner playtest when available.** Try the new stations and a useful home/workshop
   task, then a fresh campaign/combat session. Feed findings into the existing
   INT-01–08/LF backlog. Keep Reclaimed Frontier references for a later scoped
   landscape iteration; do not launch blanket reviews while awaiting feedback.

R9 is stopped throughout this sequence. No additional visual approval, baseline
comparison, performance clearance or independent review is required for approved
art. PLAY-01–04 remain open until actual fixes/feedback establish otherwise.

The retained preview log also records three signal-lifetime errors in
`chest_panel.gd` refresh/store. This is a separate concrete UI diagnostic for the
bug backlog; no evidence links it to the reported movement stutter. The preview's
configured `user/ART07G1/g1-play.json` was absent at this inspection, while
`runtime/game/g1/paid-home.json` exists. The owner's exact underground location
is unavailable; do not invent it or block scoped diagnosis awaiting playtesting.

## Handoffs and playtesting

Setup found about 400 MB free on C:. The attempted new checkout there failed
and Git removed it; A1 uses `D:/project-wroughtwild-mainline-art-a1` instead.
That capacity warning is historical: subsequent owner cleanup reports about
42 GB free on C: and 1.18 TB on D:. Git metadata and the owner depot stay on C:;
A1 retains its prepared D: path. Follow current storage guidance without moving
active worktrees or deleting retained packages/saves.

Every worker returns: what changed in play; material limits/open issues; checks
actually run and elapsed verification time; exact commits; and a short launch/
playtest recipe. The coordinator reuses that evidence, integrates only the slice,
and separately reports local main commit and successful origin/main push.
Current owner guidance removes the hard time cutoff for routine completion.
Reuse passed evidence, keep checks focused (normally three jobs and one renderer),
and finish ordinary commits/integration/pushes. No parent package reconstruction,
broad matrices or R9 rerun.

Current normal-game entry is `game/project.godot` → `res://scenes/sandpit.tscn`.
Godot on this machine is `C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe`.
The existing R8 preview launcher is still only a preview:
`build/art-playtest/Play-Art-Preview.cmd`; its private state is
`build/art-playtest/user/ART07G1/`. Preserve that state for PLAY-01/03.

The original coordination setup used repository/worktree inspection and a small
handoff check. A1 now has [passed production import and gameplay checks](mainline-art-a1-result-2026-09-15.md)
from its worker, reused during completed main integration. Main's assets were
prepared with one 31-second hidden headless import. A2's worker evidence was
also reused, followed by a six-second headless import on main. Both adoption
slices are integrated and pushed; movement/terrain fixes, canopy completeness
and replacement rigs remain the next work.
