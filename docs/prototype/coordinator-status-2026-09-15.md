# Wroughtwild current coordination sheet

Updated 16 September 2026, Adelaide. This is a lightweight inventory and dispatch
plan, not a new acceptance gate. The owner wants a solo indie prototype developed
through playable iterations. Current AGENTS.md and the owner's approved work
outrank historical review, packaging and rollout requirements.

## Current adoption and next worker

[RF-05 lakes and surface swimming](rf05-lakes-swimming-result-2026-09-15.md) is
integrated on main as `5e5de06` from worker `c3867bf`, with its matching native DLL
installed locally. Fresh normal worlds use V8; V1–V7/LF Continue keeps its saved
geography and ownership. The 94 focused generation, lake use/recovery, Continue
and 100.13 m Forward+ route checks were reused. Main's hidden headless import
passed in 6.54 seconds, exit 0 and zero reported errors; no test remains running.
Static water edges and the lack of dedicated swim animation remain limitations.
Owner lake feel/performance feedback is deferred; R9 stays stopped.

Both PLAY-03 arrival slices are integrated. The first, `87849bd` from `de0125f`,
removed unused hidden mesh construction and reduced the selected freeze from
443 to 324 ms. The [presentation correction](play03-presentation-hitch-result-2026-09-15.md),
`1bc19e9` from worker `039bccf`, addresses the remaining dominant cost: first-use
texture/material acquisition. The measured first boar arrival fell from 324.760
to 7.529 ms; the next interval including first draw was 10.530 ms. Boar, wolf
and stag shared resources now prepare during ordinary New World and Continue
before controls release. The directly measured preparation cost is about 0.9 s.
Art, encounter rules, saves and RF-05 behavior remain; native DLL unchanged.

Reused continuation checks: 11 diagnostic, 12 arrival, 22 Continue/lifecycle,
plus applicable earlier evidence. Main's hidden headless import passed in 4.68 s,
exit 0 and zero reported errors; all owned checks are finished. The owner says
the result seems a massive improvement and asks that established game-development
practice be the default. AGENTS.md records proportionate resource/first-use
discipline without adding an exhaustive review gate.

**Full-roster arrival work is now adopted as `9dba2fd` from worker `43e7cf3`.**
The [result and coverage](play03-group-arrival-result-2026-09-15.md) account for
all 11 ordinary IDs, five LF aliases, elite/era variants and both distinct boss
paths, through world/cave/noise/siege/site/trial/Continue entry. The reported trio
is included in an unchanged 30-mob, eight-pack native encounter. Synchronous
arrival work fell from 900.999 to 13.050 ms; its full frame from 950.572 to
40.869 ms. The next interval was 12.468 ms. Resource loading and shared mesh
construction now happen during actual entry, without creating dormant actors.
The previous boar fix, art, full encounters, native rules, saves and lakes remain.
Full-roster preparation measured roughly 2.2–2.5 seconds, including prior fauna
preparation; the final small Conservator cache's additional entry cost was not
separately timed. Memory residency impact remains unmeasured.

The worker is idle and finished at `43e7cf3`. Reused checks: 120 Continue/LF/trial/
material lifecycle, eight fresh suspended-trial restore and nine boss checks.
Its final rendered run was 37/38: a fixture teardown failure was corrected and
verified by the later focused jobs; do not call that original run failure-free.
Main's hidden headless import passed in 9.88 s, exit 0, zero reported errors.
The RF-05 DLL is unchanged. No owned test remains running. Raw evidence and the
private horn/group playtest launcher remain in the existing D: worktree.

The large demonstrated creature-loading freeze is fixed; broader lag is open.
Retain the short combined group frame, older unassigned spike, long world entry
and unconfirmed underground connection.
The pullstone/scenery arrival is addressed by PLAY-07 below. Owner playtesting of
this continuation is deferred; do not claim owner confirmation of smoothness.

**Parked by the owner, 16 September: [PLAY-06 bearings and optional coordinates](play06-navigation-worker-2026-09-15.md).**
Its worktree has not been created and implementation has not started. Keep its
brief for later; do not prepare or dispatch it now. RF-01–05 and original art/base-
mob adoption are complete.

**[PLAY-07 scenery arrival](play07-scenery-arrival-result-2026-09-16.md) is integrated
as `c5ceb9f`, from completed worker `29e90e4`.** Pullstone creation measured
154.202 to 2.174 ms and its full frame 178.281 to 8.656 ms. F1/F2/F3 now retain
the five rare-source families' shared scenes through real entry/Continue, adding
0.934 s preparation in the rendered entry. Art, stages, stock, saves and RF-05 DLL
remain. Reused 28 final route checks, zero-error retirement probe and 97 passed
lifecycle checks; its two bellows harness failures were corrected and the affected
paid-device check passed 6/6. The original 97/99 run is not relabelled clean.
Main hidden headless import passed in 5.36 s, exit 0, zero errors. All owned tests
ended. The existing D: scenery task is idle at `29e90e4` and retains private playtest
state. Remaining costs belong to cleanup, not another immediate lag worker.

**Next prepared: [RF-06 fen/lakeside atmosphere](rf06-fen-lakeside-worker-2026-09-16.md).**
Workspace `D:/Wroughtwild/work/rf06-fen-lakeside`, branch `codex/rf06-fen-lakeside`,
base `c5ceb9f`, with `build/rf06/SETUP.md` and the current owner-depot prompt.
Only the required native DLL was copied/verified; no package, imports or player
saves were copied. The owner starts it; no worker/game was launched automatically.
This original-plan slice covers existing fen and actual V8 lake margins: cosmetic
wet margins, reeds/roots, dry approaches and
appealing nearby home space, building on existing water and the reclaimed-landscape
references. Highland recovery can follow separately, with weathered rock shelves
and appropriate vegetation pockets, then the remaining original composition
around recovered impacts and living scars. New water geography, generation profiles and
collision changes still need a scoped choice; none is selected by this agreement.
Later-era creature forms and boss art remain separate production backlog. Station/
campaign feel still needs useful owner playtest notes, not a new verification wave.

## Original-plan sequence and end-of-wave cleanup

On 16 September the owner asked the coordinator to hold firmly to the original
slice breakdown, raise additions but default to recording them for a cleanup
slice at the end. This supersedes making each new finding the immediate next job.
PLAY-07 is now integrated; return to the original creative outcomes.

| Order | Work | Relationship to the original plan |
| --- | --- | --- |
| Done | PLAY-07 scenery arrival and normal integration | Approved additional fix, now adopted as `c5ceb9f` |
| Next prepared | RF-06 fen/lakeside atmosphere | Original wetland recovery: planted margins, roots, dry approaches and appealing living/building spaces |
| Then | Highland recovery | Original mountain character: weathered shelves, settled debris and vegetation pockets |
| Then | Remaining impact/scar composition | Original reclaimed-catastrophe identity: vegetation reconnects old damage while selected physical scars/pulses remain legible |
| End | Bounded cleanup slice | Consolidate deferred issues by player impact; no exhaustive review wave |

The three creative outcomes need small worker scopes using existing assets and
delivered RF-01–05 foundations; this schedule does not select new world/save rules
or promise all-biome production. RF-01–05 stay delivered. Keep original outcomes
separate from refinements rather than restarting them for minor remaining polish.

Initial cleanup notes: residual short group hitch (34.621 ms full frame in PLAY-07),
Thrumroot construction (8.790 ms first / 4.238 ms repeat), older unassigned lag/underground
correlation, long world entry, angular shore/steep-bank polish and missing dedicated
swim animation. Preserve each item's existing evidence and uncertainty; none is
claimed fixed or newly blocking. New findings join these notes by default. The
large scenery loading omission is fixed in PLAY-07, not another immediate
follow-up. Grass/impact composition that directly delivers the original creative
outcomes stays in those scopes; incidental cosmetic refinements wait for cleanup.

Compass/coordinates remain a parked optional feature, not an automatically approved
cleanup fix. Station/campaign feel remains a feedback question until concrete
issues are known. Later-era creature forms and boss art are separate backlog.
When raising an addition, explain its benefit/impact, recommend deferral and name
the core slice it would displace. Escalate only concrete current-slice blockers or
save/ownership risks, or follow an explicit owner reprioritisation. No new worker
is launched by recording this queue.

## Working rhythm

Build the next agreed original-plan improvement, integrate it and run a short
check. Use owner feedback to inform the cleanup backlog; change sequence when the
owner explicitly reprioritises or a concrete blocker requires attention. Keep one worker responsible
for shared runtime integration at a time. The owner-requested parallel ram/crane
production and subsequent playable beetle/nymph/tortoise slices are now complete.
All six regular replacements are integrated on main. For future work, independent
production may use separate D: worktrees and file namespaces; source readiness
alone does not mean that a role is already playable on main.
See the [parallel production boundary](mob-parallel-production-2026-09-15.md).
The owner starts worker sessions from supplied prompts;
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

## Current deliveries and remaining playtest feedback

**[RF-01 meadow and woodland recovery](rf01-reclaimed-ground-result-2026-09-15.md)
is integrated on main as `66f3211`.** Seeded low grass/fern patches now respect
actual support, excavation and paid building/station footprints in ordinary V6/LF
play and Continue. Native terrain, resource/site anchors and saves are unchanged.
Reuse the worker's placement, paid-use, corrected ownership and real 76.42 m
Forward+ walk evidence. Main's hidden headless import passed in 4.68 seconds,
exit 0, no reported errors. Its private logs/state are on D:; no test remains running.

The owner reports that the ground texture looks unpleasant and asks whether the
grass needs proper Blender production. RF-01 reused simplified B2 LOD2 grass;
coverage is still patchy and its route did not reach an impact margin. It is an
implemented placement iteration, not a claim of final visual acceptance.
**[RF-02 ground materials and grass](rf02-ground-grass-result-2026-09-15.md)
is integrated on main as `7c1e3a7`.** Worker `9180001` is finished. Authored turf/
soil and woodland litter maps now replace coarse procedural grain on eligible
V6/LF surfaces, and two original Blender grass forms replace RF-01's stacked
LOD2 crowns. Native terrain, saves, placement and paid footprints are preserved.
Reuse the 29 asset checks, 23 final Continue/use checks and successful 76.42 m
Forward+ walk. Main's hidden headless import passed in 5.06 seconds, exit 0,
zero reported errors; its private logs/state are on D: and no test remains running.
New editable source remains at `D:/Wroughtwild/source-art/rf02-ground-grass`.

The grass is still clumped, with gaps at shelves/reserved areas. Hardware cost,
other lighting and personal owner acceptance remain unmeasured/deferred.
**[RF-03 landforms and inspiring home sites](rf03-landforms-homes-result-2026-09-15.md)
is integrated on main as `d4aa817`.** Worker `b8d884c` is finished. Normal fresh
worlds now select V7 with rolling land and woodland-pocket, overlook, bank-terrace
and clearing home settings. Existing V1–V6/LF saves retain geography and ownership.
The matching native DLL is installed locally. Reused evidence includes native
generation/legacy identity, 31 paid-build and 19 V7 Continue checks, and a real
202.64 m Forward+ walk. Main's hidden headless import passed in 4.89 seconds,
exit 0, zero reported errors; its private logs/state are on D:. No test is running.
Only two seeds and one rendered route were covered; owner feel remains feedback.

**[RF-04 ground continuity](rf04-ground-continuity-result-2026-09-15.md) is integrated on main as `27fc34d`.**
The V7-only upward-face correction removes extra face-centre peaks/hollows while
preserving native saved geography and the RF-03 home settings. A discovered side
contact regression was fixed by retaining side/underside fans. Final geometry/dig
checks, the exact corner-contact walk and a 60.32 m Forward+ walk pass; reuse the
private paid-home Continue evidence as described in the result. Worker `5c421b3`
and its matching DLL are adopted. Main's hidden headless import passed in 6.76 s,
exit 0 and zero reported errors. Private output stays on D: and no test is running.
V7 New World/Continue receive the correction; V1–V6/LF remain unchanged. Steep
terracing and personal owner feel remain limitations. The RF-04 worker is finished.

**RF-05 is delivered on main as `5e5de06`, as recorded above.** It includes one
lake per fresh V8 world, wading/surface swimming, easy shore exits, useful dry home
space and floating recovery under existing ownership. Its separate private
playtest launcher remains in `D:/Wroughtwild/work/rf05-lakes-swimming`; do not
restart the completed worker. Small seas, fen/mountain redesign and a fresh-LF
successor remain later possibilities.

**PLAY-03 diagnostic delivery is integrated as `cbc6f67`.** The staged drop did
not reproduce the owner's continuing slowdown; no causal fix is claimed. The
[result and optional recording instructions](play03-underground-result-2026-09-15.md)
provide a bounded local recorder for the next real incident. The owner said:
"happy to wait for my next playthrough". That waiting condition is now met:
the owner reports large lag coinciding with nearby mobs visibly appearing in the
overworld and suspects the earlier underground incident had the same trigger.
They clarified **"A brief hitch, then recovers"**. The correlation and recovery are
observed; shared underground cause and exact costly phase are unconfirmed.
[PLAY-03 mob-arrival follow-up](play03-mob-arrival-followup-2026-09-15.md) now has
a selected presentation fix on main as `1bc19e9`, following partial `87849bd`.
First-use texture/material acquisition explained most of that selected pause;
the real entry paths now prepare those resources before controls release.
The underground connection still needs evidence; do not infer all lag is fixed.
No independent reviewer or parallel runtime repair worker is launched.

Reuse the worker's 7 transition and 19 recorder checks. Main's one hidden headless
import passed in 6.8 seconds with exit 0 and no reported errors. Normal launch
leaves recording off; saves, controls, art and streaming behavior remain unchanged.

**[PLAY-05 chest transfer reliability](play05-chest-result-2026-09-15.md) is
integrated as `66c9ff9`.** Worker `ffa1451` reproduced the original signal-emitter
error through a real Store button. Old controls are now disabled/disconnected
immediately, with deletion queued until the signal finishes. Counts/messages and
transfers remain synchronous; retired buttons cannot affect another chest.
Native capacities, exact ownership, saved paid chests and art remain unchanged.
The worker is finished; its local import outputs are preserved on D: and excluded
from integration. Reuse its 196 transfer/lifecycle and 45 fresh-process Continue
checks. Main's hidden headless import passed in 4.66 seconds, exit 0, no errors.
No new worker or review wave was started during adoption.

PLAY-04 station/home and campaign feel remain owner playtest questions. They are
not failed acceptance tests, and PLAY-05 does not close them. Later-era creature
growth and boss art remain longer-term scoped choices. Reclaimed Frontier now
has RF-01–05 integrated; fen/mountain recovery and broader biome ambitions remain
future work. The original implementation sequence below is retained as history.

## Repository inventory

Current adoption update: A1 is integrated on main as `35cee73` and successfully
pushed to `origin/main`. The [result and normal-game playtest steps](mainline-art-a1-result-2026-09-15.md)
record the reused worker checks and the short headless main asset import.
A2 is integrated and pushed on main as `27e742d`.
The [A2 result](mainline-fauna-a2-result-2026-09-15.md)
records the finished fauna, native checks and the small missing C3 shader repair.
PLAY-01's causal seam-projection improvement is integrated and pushed as `d396d9e`.
The [movement result](play01-movement-result-2026-09-15.md) records the measured
short-route benefit, delayed decoration tradeoff and still-open underground lag.
PLAY-02 is integrated and pushed as `870159e`: fuller R1 active crowns and
restored missing C1 runtime dependencies. The owner has seen its captures in chat.
[Canopy result, evidence and launch steps](play02-canopy-result-2026-09-15.md).
MOB-01's rigged porcupine Cinder Archer is integrated and pushed as `f0349c2`.
[Motion, preserved native behavior and limits](mob01-porcupine-result-2026-09-15.md).
MOB-03's crane Shrieker is integrated and pushed as `d9e6b90`, using the checked
production assets plus native call/melee wiring and Continue cleanup.
[Crane result and focused integration checks](mob03-crane-result-2026-09-15.md).
MOB-02's ram Stone Husk is integrated and pushed as `5493470`: native guard/melee
presentation, pause/status priority and ordinary Continue are complete.
[Ram result, native capture and playtest](mob02-ram-result-2026-09-15.md).
The owner subsequently approved the current visual results: "Everything looks
great - approved", while explicitly leaving full performance impact untested.
This covers the delivered art, not a claim of full gameplay/performance clearance.
MOB-04's beetle Gloom Crawler is integrated and pushed as `a524870`, including
native swarm/melee presentation and ordinary Continue.
[Beetle result, motion and playtest](mob04-beetle-result-2026-09-15.md).
MOB-05's six-legged nymph Bog Lurker is integrated and pushed as `0d552ba`.
[Nymph result, root/dash checks and playtest](mob05-nymph-result-2026-09-15.md).
The owner praised the nymph and confirmed continuation to MOB-06 tortoise.
**MOB-06 is now integrated and pushed as `5c1b360`**, preserving native Hollow
Knight ward/melee behavior. [Tortoise result and roster completion](mob06-tortoise-result-2026-09-15.md).
Its nymph dependency was already adopted; only the new tortoise commit was brought
in. **All six base replacement mobs are complete on main.** No regular-mob worker
is still running and no duplicate/new art-review wave is needed.
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
| Existing normal-game art | A1 supplies the R8 kit; A2 supplies boar/wolf/stag with moths preserved. PLAY-01 reduces demonstrated seam-arrival stalls; PLAY-02 improves active broadleaf/pine crowns. All use normal world/Continue entry. | Significant underground lag remains unresolved. Movement comfort and canopy feel await hands-on feedback; blunt limb ends remain visual polish. |
| R8 environment/placeables | All 26 original ART-07 deliveries and R1–R8 are published as source/handoff work; their selected production runtime is now adopted on main. | **A1 integrated and pushed as `35cee73`.** [Result and playtest](mainline-art-a1-result-2026-09-15.md). |
| Finished fauna | A2 adopts ART-01 boar and ART-03 wolf/stag, including existing LF visual aliases, on native actor clocks. Moths retain their earlier art/motion. | **A2 integrated and pushed as `27e742d`.** Mid detail, foot sliding and no terrain IK/distance switching are recorded limits. [Result](mainline-fauna-a2-result-2026-09-15.md). |
| Six replacement mobs | All six are rigged, animated and integrated on main: porcupine (`f0349c2`), crane (`d9e6b90`), ram (`5493470`), beetle (`a524870`), nymph (`0d552ba`) and tortoise (`5c1b360`). | Base adoption is complete. Foot sliding/collider mismatches, unmeasured performance and human combat feel remain; later-era physical forms and boss art are separate. |
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
   [Published result](mainline-fauna-a2-result-2026-09-15.md); finished-fauna adoption is complete.
   [Prepared worker prompt and D: workspace](mainline-fauna-a2-worker-2026-09-15.md).
3. **PLAY-01 — causal improvement integrated and pushed.** Stone-seam decoration
   now shares the resource work budget; the representative worst walking frame
   fell from 188 to 45 ms. **PLAY-03 — underground lag remains open.** The owner
   clarified that access is not the issue. A current-code cave sample did not
   reproduce sustained lag. [Checks, limits and handoff](play01-movement-result-2026-09-15.md).
   [Prepared movement worker and D: workspace](play01-movement-worker-2026-09-15.md).
4. **PLAY-02 — completed on main and pushed as `870159e`.** Common broadleaf/pine
   use delivered middle-detail crowns with fuller leaf surfaces; native tree
   lifecycle remains intact. The forest smoke also repaired missing C1 settings
   and shader dependencies. [Result and remaining visual limits](play02-canopy-result-2026-09-15.md).
   Owner saw the corrected captures; hands-on playtesting remains deferred.
5. **MOB-01 — porcupine integrated and pushed as `f0349c2`.**
   Fitted rig, native movement/shot animation and ordinary Continue are complete.
   [Result, limits and checks](mob01-porcupine-result-2026-09-15.md).
   [Exact prompt and D: workspace](mob01-porcupine-worker-2026-09-15.md).
   **MOB-03 crane is integrated and pushed as `d9e6b90`.** Its native call is
   separate from pecking and keeps the legs walking; Continue clears transient poses.
   **[MOB-02 ram](mob02-ram-result-2026-09-15.md) is integrated and pushed as `5493470`.**
   Its stationary brace, walk and forehead strike preserve native guard and combat.
   **[MOB-04 beetle](mob04-beetle-result-2026-09-15.md)** is integrated and pushed
   as `a524870`. **[MOB-05 nymph](mob05-nymph-result-2026-09-15.md)** is integrated
   and pushed as `0d552ba`. **[MOB-06 tortoise](mob06-tortoise-result-2026-09-15.md)**
   is integrated and pushed as `5c1b360`. All six regular replacements are complete.
   Do not dispatch further base-mob rig/adoption work from historical prompts.
   This is a production
   order, not new game rules; no extra visual approval is required at integration.
   Physical era variants and boss art retain explicit backlog entries.
6. **Owner playtest when available.** Try the new stations and a useful home/workshop
   task, then a fresh campaign/combat session. Feed findings into the existing
   INT-01–08/LF backlog. Keep Reclaimed Frontier references for a later scoped
   landscape iteration; do not launch blanket reviews while awaiting feedback.

R9 is stopped throughout this sequence. No additional visual approval, baseline
comparison, performance clearance or independent review is required for approved
art. PLAY-01 has a published causal improvement awaiting owner
comfort feedback; PLAY-02 is published with known visual limits and deferred
hands-on feedback. PLAY-03/04 remain open. PLAY-03 is lag underground, not access.

The retained preview log's three signal-lifetime errors in `chest_panel.gd`
refresh/store were reproduced and corrected by PLAY-05 on main as `66c9ff9`.
No evidence links this UI error to the reported movement stutter. The preview's
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
slices and the demonstrated PLAY-01 seam-stall fix are integrated and pushed.
PLAY-02 is also integrated and pushed; its 70 worker checks were reused and one
5.01-second hidden headless main import passed. Underground lag remains unresolved.
MOB-01 is integrated and pushed as `f0349c2`, reusing 60 native actor/lifecycle
checks and source evidence. Main's 5.48-second headless import passed. MOB-03 is
also integrated/pushed, reusing source evidence with 29 native and 10 Continue
checks plus the asset import. MOB-02 is integrated/pushed as `5493470`, reusing
source evidence with 29 native and 10 Continue assertions plus a 4.02-second main
import. MOB-04 is integrated/pushed as `a524870`, reusing 10 rig, 45 native and
14 Continue checks with one 5.23-second main import. Full performance impact and
hands-on beetle feedback remain deferred. MOB-05 is integrated/pushed as `0d552ba`,
reusing 11 source, 42 native and 14 Continue checks plus a 7.94-second main import.
Nymph visuals are approved; broader gameplay/performance feedback remains open.
MOB-06 is integrated/pushed as `5c1b360`, reusing its selected rig, native ward/
melee, corrected capture and Continue evidence with one 5.05-second main import.
All six regular replacement mobs are now playable. Remaining near-term work is
the reported underground lag and useful owner combat/station/campaign feedback,
with broad performance testing deferred to the owner's chosen playtest phase.
Physical era variants, boss art and Reclaimed Frontier direction remain backlog;
completion of this batch does not automatically start those larger art projects.
