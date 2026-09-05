# World and Forge intensive review

This records the playable D-027/D-028 implementation and separates automated
regressions, visual evidence and provisional combat tuning. The two approved
work items are [world](world-intensive-2026-09-06.md) and
[trials](trial-intensive-2026-09-06.md).

## Playable changes

New `frontier_v2` worlds contain quarry, fen and oldgrowth resource habitats.
Eight one-step refined materials have distinct shared construction art, with
light wall panels and fixed framed windows. Prior saves select `legacy_v1` and
keep the frozen terrain and placement inputs. Depletion, harvesting progress,
excavation and structures restore with the corresponding profile and seed.

The gate opens three two-floor Forge stories with authored connected rooms,
physical branching previews and rewards, local encounter ownership and trial
navigation. Four boon opportunities, one optional secret and three possible
weaknesses augment the permanent build. Warden support enemies and the capstone
conduits reward target priority; committed sweeps, recovery and bounded vent
patterns reward positioning. The existing two curios still drive world eras.

After the capstone, a separate arc flag opens selectable repeatable tiers.
Three stable offers preview conditions, boss behavior, target ingredients and
haul multipliers. Successful entry advances the saved batch; only a clear
unlocks the next tier. Numeric scaling continues without growing the bounded
condition count, live population or hazard count.

The cleared first-floor lift offers continue, extraction or suspension. The
paired native/engine checkpoint retains deposit, loot, choices, combat RNG,
life and temporary-effect clocks. It is validated before restore. Saves use a
pending file and previous-good backup; the normal launch offers resume.

## Verification and evidence

The standard headless helper includes the world, material and trial intensive
fixtures alongside the existing suites. Native tests independently exercise
generation fingerprints, finite resources, recipes/form restrictions, offer
stability and trial state transitions. The spatial fixture uses forced kills
only for lifecycle regression; it also checks actual enemy/boss movement around
cover, every selected room's connected route, committed tells, hazards,
suspension, failed writes and rejection of mismatched checkpoints.

Final command: `powershell -NoProfile -ExecutionPolicy Bypass -File
tools/codex_visual_review.ps1 -Checks` — **passed, exit 0**. This includes all
existing regression suites plus 5,957 world, 158 material and 6,189 trial
headless checks. The pre-existing dummy-renderer teardown diagnostics in the
unit fixture are unchanged; the helper reports no failed checks or script errors.

Review outputs are generated under `build/intensives/`:

- `world/index.html`: matched habitat views, first-person walks and resource detail.
- `materials/`: three material demonstration buildings and palette checks.
- `forge/index.html`: accelerated three-story visual recording with live AI and Foundry effects (579 checks, 516 recorded frames). Fixture immunity and forced clears are explicitly labelled.
- `forge/boss/index.html`: updated grounded boss cycles under Foundry effects (171 checks, 108 recorded frames).
- `trial-balance-initial.json`: diagnostic samples before navigation and fixture corrections. Its isolated boss setup left earlier route gates closed; those boss results are not valid balance evidence.
- `trial-balance-final.json` (also `trial-balance.json`): corrected actual fixed-build encounter samples across Ranger, Warden and Kindler, starting/prepared/developed equipment and tiers 1–10. No forced kills in measured encounters; consult its recorded scope and cohort count.

The initial ranged-boss samples exposed corner sticking: the boss capsule was
wider than the navigation clearance and waypoint lookahead cut solid corners.
The Forge clearance and arrival distance now accommodate the boss. A cistern
trough was shortened to leave an actual doorway turning apron. These are spatial
corrections, not hidden damage or speed bonuses. Exact-width gallery rails now
close the gaps beside corridor floor slabs. A floor rescue returns a knocked
capsule to nearby navigable ground. The corrected isolated boss fixture also
opens the physical gates for the earlier stages it skips.

Native simulation/material/trial checks: **32,110 passed**. Independent native
world verification: **595,376 passed** across 64 seeds, retaining exact legacy
fingerprints for seeds 1, 7, 24 and 91. Final rendered world verification:
**6,043 passed**, including malformed-save rejection and 49 gameplay captures.
The dedicated spatial trial fixture passes **6,189 checks**, including collision
rays along every external floor boundary, actual enemy and boss path following,
all story/map room routes and exact suspension/reward behavior. Material review
passes **165 rendered checks** and presents seven building/catalogue captures.

The final combat matrix completed **180 samples**, with zero setup errors or
floor rescues: **90 clears, 48 deaths and 42 thirty-second timeouts**, exposing
**322 boss tells**. These are isolated encounter outcomes under one scripted
policy, not human success rates. Six Kindler boss samples recorded 3.1–5.3
seconds of interrupted chase with nearby support enemies; actor congestion is
a possible cause, and these pursuit pauses remain an AI review item. See the [full cohort report](trial-balance-2026-09-06.md)
for legal equipment, conditions, clear times, survival and measurement limits.

Matched legacy field-route measurement before the final Forge pass: startup
8.902 → 8.974 s (+0.8%); walk median +2.1%, p95 −1.2%; combat median −0.5%,
p95 +1.7%. Both runs traversed 142.97 m, cast 26 times and recorded 49 damaged
frames with 32 peak enemies. Matched dense-grove median was 6.942 → 6.946 ms
(+0.06%) and p95 7.490 → 7.626 ms (+1.82%); terrain startup was 9.674 → 9.357 s.
Draw calls rose 2.51% and primitives 30.48%, so lower-spec canopy performance is
unverified. Final dense-Forge evidence is recorded in its manifest.

The quiet dense encounter comparison uses 24 enemies, eight ignites and four
Foundry fields, with 120 warmup frames and 600 measured frames per scene and no
screenshot readbacks during timing. Legacy arena → complete Forge floor:
median **8.308 → 9.607 ms (+15.64%)**, p95 **10.204 → 10.653 ms (+4.40%)**.
The final median exceeds the investigation threshold and remains a reported
regression. An earlier 33.7% result overlapped another test process; quiet
repeats showed Forge medians consistently around 9.60 ms, while legacy medians
varied with the 120fps cap. Investigation identified unshared box meshes:
caching repeated dimensions reduced Forge draw calls from 1,959 to about 1,105.
A static cohort showed no render-time regression; live physics rose from
2.376 to 3.113 ms (about 0.74 ms) with trial navigation. Collision, navigation
and content were retained. These Forward+ measurements describe the review
machine, not a lower-spec hardware guarantee. Earlier lower percentage results
do not replace this final sealed-geometry comparison.

## Tuning and remaining acceptance

Numbers and their purposes live in `data/tuning/trial.json`, `boons.json`,
`construction.json`, `crafting.json`, `world.json` and `worldgen.json`.
Frozen legacy placement inputs live separately in `worldgen-legacy-v1.json`.
Presentation dimensions, navigation clearance/arrival and distance detail live
in the named Godot art resources with inline purpose comments. The measurement
bot has a separate documented configuration and does not alter gameplay tuning.

The twenty-minute story and ten-minute repeatable durations remain targets.
Isolated encounter samples and accelerated visual recordings do not verify
whole-run pacing or human difficulty. Tiers 1–10 have measurement fixtures and
initial data-driven defaults; acceptance follows the owner's combat/class
playtest. Balance above tier ten remains unverified. Final visual acceptance
also belongs to the owner; the existing weathered-frontier identity is retained.

No external packages/services, multiplayer, map-item economy, new era,
structural simulation or broad automation were added. The reported D-018
timber-demolition conflict remains outside both work items. Pre-existing local
Blender studies and unrelated edits were preserved.
