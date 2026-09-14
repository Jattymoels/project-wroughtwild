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

Track four different kinds of remaining work: implementation, integration,
reported bugs and playtest questions. A checked implementation can be in the game
while feel/balance feedback remains open. Do not restart a completed intensive
merely because a historical checkbox still says human review pending.

## Repository inventory

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
| Existing normal-game art | Earlier authored environment/building/station assets and older articulated animal art load through the ordinary game. | This is not the complete R8/latest fauna kit. |
| R8 environment/placeables | All 26 original ART-07 deliveries and R1–R8 are published as source/handoff work. R8 combines nature, materials, resources, buildings, stations and devices. Owner approved integration with known issues. | **A1: install its production assets and adapters into ordinary game paths.** Publication alone did not do that. |
| Finished fauna | ART-01 boar and ART-03 wolf/stag are visually approved with rigs/clips; retain the liked moth. ART-05 supplies an existing native boar adapter example. R8 preserves the older actor set. | **A2: fit latest approved finished fauna to current native actors and clocks.** Reuse completed assets/adapter work; do not regenerate designs. ART-05's seed-77 route restriction is not a production policy. |
| Six replacement mobs | Approved ART-06C surfaces/models exist for porcupine Archer, ram Husk, crane Shrieker, beetle Crawler, six-legged nymph Lurker and tortoise Knight. | Real rigging, weighting, locomotion/attack presentation and runtime integration, one complete enemy role per slice. Static models are not playable replacements. |
| Later art/world ambition | Later-era physical augmentation, remaining boss/host art and Reclaimed Frontier references/direction are recorded. | Future scoped production/design. Reclaimed Frontier means living, rolling terrain years after impact, vegetation reclaiming damage and surviving pulsing cracks; no new generator/save rule is selected. |
| Broader game ambition | Class halls, substantial outpost/transport progression, larger production networks and richer late-game content remain longer-term design. | Choose only what the current prototype loop demonstrates it needs. Multiplayer, infinite generation and broad factory/trading systems remain outside scope. |

The older master design and sections of the intensive queue contain dated
snapshots (for example V5 world size and LF2 as the latest wave). Use accepted
successor work items and current implementation status above. Existing recorded
questions such as timber demolition policy and era-sensitive gear previews belong
to their own future decision/bug work; art adoption must not silently decide them.

## Immediate execution order

1. **A1 — R8 in the normal game.** Environment, building/resource materials,
   stations and devices, preserving current world/campaign/save rules and octagonal
   support. [Exact worker prompt and workspace](mainline-art-a1-worker-2026-09-15.md).
2. **A2 — finished fauna adoption.** Boar, wolf, stag and preserved moth; current
   enemy IDs, bodies, attack clocks, statuses, drops and passive habits remain.
   Complete the ready-art adoption before the six unfinished replacement rigs.
3. **PLAY-01/03 — movement comfort and underground access.** Diagnose ordinary
   frame spikes and the accidental below-terrain transition/worse lag. Preserve
   the owner's preview save. Use a short representative trace/reproduction;
   do not assume streaming, collision, shaders or geometry is the cause.
4. **PLAY-02 — canopy completeness.** Inspect the reported missing portions and
   distance transitions; fix the demonstrated geometry/material/detail fault.
5. **Focused owner playtest.** Try the new stations and one useful home/workshop
   task. Then choose a fresh campaign/combat session when wanted. Feed findings
   into the existing INT-01–08/LF backlog rather than commissioning blanket reviews.
6. **Remaining mob production**, then select a Reclaimed Frontier scope using
   the preserved references and actual playtest experience. Physical era variants
   and boss art retain explicit backlog entries.

R9 is stopped throughout this sequence. No additional visual approval, baseline
comparison, performance clearance or independent review is required for approved
art. PLAY-01–04 remain open until actual fixes/feedback establish otherwise.

## Handoffs and playtesting

Setup found about 400 MB free on C:. The attempted new checkout there failed
and Git removed it; A1 uses `D:/project-wroughtwild-mainline-art-a1` instead.
D: has ample space, but this linked worktree's Git objects and the owner main
checkout remain on C:. New asset staging/main integration may require more C:
space or a separately agreed depot relocation. Do not delete retained packages
or saves to make room automatically.

Every worker returns: what changed in play; material limits/open issues; checks
actually run and elapsed verification time; exact commits; and a short launch/
playtest recipe. The coordinator reuses that evidence, integrates only the slice,
and separately reports local main commit and successful origin/main push.
Combined worker/coordinator review stays within ten minutes and three focused
jobs on one renderer. No parent package reconstruction, broad matrices or R9 rerun.

Current normal-game entry is `game/project.godot` → `res://scenes/sandpit.tscn`.
Godot on this machine is `C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe`.
The existing R8 preview launcher is still only a preview:
`build/art-playtest/Play-Art-Preview.cmd`; its private state is
`build/art-playtest/user/ART07G1/`. Preserve that state for PLAY-01/03.

This coordination slice changes no gameplay and runs no engine/Blender jobs.
Its checks are repository/worktree state and patch equivalence, selected document/
runtime wiring inspection, and a small handoff link/diff/setup check. It does not
claim the adoption, performance fixes or replacement rigs are complete.
