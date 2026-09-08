# Living Frontier Wave 3 — bounded implementation contract

Owner authorization: 9 September 2026. Implement LF-3A → LF-3B → LF-3C only,
after the [Wave 2 review](living-frontier-wave2-review-2026-09-09.md).
Recorded before behaviour edits. Baseline: `73ed215`.

## Outcome and boundaries

Connect recognisable animals, four useful influences and a visible artificial
field trail to the existing paid extraction/manufacture foundation. Complete
each slice with focused evidence and a checked commit, then stop for orchestrator
review. The [roadmap](living-frontier-roadmap-2026-09-08.md),
[extraction proposal](leyline-catalyst-extraction-2026-09-08.md),
[Wave 2 contract](living-frontier-wave2-2026-09-08.md) and
[animal/scar direction](leyline-asset-roadmap-2026-09-09.md) bound this selection.
D-006/D-010/ADR-0003/D-012/D-013/D-017/D-019/D-021/D-025/D-026/D-028–033 apply.

Affected systems: native enemy/real-time tuning, population generation, material
loot, source and machine profile eligibility, engine animal presentation,
world identity and saves, and contextual discovery information. Numbers belong
in `combat_realtime.json`, `world.json` and a bounded `living_frontier.json`
generation/presentation contract; ordinary recipes retain their Wave 2 inputs.

## Selected sequence

1. **LF-3A:** two boars reuse the existing articulated `ember_whelp` skin.
   Red plants its feet, warns a circular nearby heat release, then recovers.
   Blue plants its feet with aim committed, holds, then charges straight and
   recovers. Red asks for distance; Blue asks for a lateral move or solid cover.
   Each replaces the basic bite with one attack, with the existing 75-life /
   6-damage boar budget, no elemental immunity, compulsory Catalyst or new status.
   Stagger/freeze/death cancel an attack; cover blocks contact; no paid building
   damage is added. Initial timing/range values are measured tuning, not final
   difficulty acceptance. Compare all three starting classes without Catalysts.
2. **LF-3B:** one small sample around each of the four existing source margins:
   the two taught boars, one White stag and one Green moth. Stag and moth flee
   and never attack. Rooting, grazing and visiting connected growth precede
   danger; narrow local scars match the source influence while ancestry remains
   visible. Each host pays a small guaranteed matching raw-material drop through
   ordinary physical loot, alongside its selected ordinary material. No animal
   by colour matrix, simulated ecology or source-refilling kill is introduced.
   Separate Red and Blue encounters; preserve source workplaces, home clearings
   and a quiet starting valley. Use existing skins and local placeholders;
   concurrent TRELLIS/boar production files are outside this task.
3. **LF-3C:** connect these useful drops and all five paid manufacture recipes
   to one recognisable trail of later clamps, repeated marks and straight feed
   sections leading to an outer laboratory. Establish three visible exterior
   sites and their approaches; define two future physical transformation regions
   without performing any transformation. The old smithy remains accidental and
   pre-cataclysm. The laboratories are readable sealed ambitions, not playable
   encounters or renamed Forge bosses. Existing curio campaign remains usable.

## Save and acquisition contract

The incomplete successor remains explicitly opt-in as `living_frontier_wave3`,
using `--living-frontier-wave3` and a separate default save. Its immutable base
terrain is V6; native generation adds only this bounded sample and later visible
sites. Normal startup stays V6. `--living-frontier` and published Wave 1–2 saves
remain `living_frontier_wave1`, with their exact geography, population, source
payloads 1–4, machine payloads 1–5 and selected acquisition policy. No automatic
conversion, reseeding or insertion of scenery into an old experimental world.
Loading retains the saved profile regardless of launch defaults.

Wave 3 inherits exact source lots, outcomes, claims, repairs, capped active-time
renewal, ordinary recipes, owned grades and separate signal/work/heat ledgers.
Host drops use existing death, expiry, capacity and save ownership; killing or
streaming a host never replenishes a source. Unknown profiles/payloads refuse.

**Acquisition remains the published policy during Wave 3.** The owner's current
request requires a no-luck progression proof before policy changes; it does not
require removing the coherent current Forge reward paths while laboratory
encounters remain later work. Prove an opening with zero found Catalysts and
paid access to all five identities, and document every replacement path still
needed before activating a new policy. New host material rewards ship now.
Do not silently remove the current elite bounties, peddler, earned Trial rewards,
ordinary-world distillation, refinement, refunds or saved reward ownership.

## Future geography protection

All laboratory exteriors must exist visibly before any normal successor choice.
Only their actual physical geometry occupies space: no invisible blanket building
exclusions. Future transformation regions are declared envelopes for later work,
not present hazards or permission to overwrite construction. Later transforms
must preserve paid occupied/support space, doors, station workspace, excavation,
stored/loose ownership, attached sources and an ordinary approach. They blend
locally around current construction; placing one block cannot freeze a region.
No transform is enabled until those later physical/restart tests pass.

## Assumptions, checks and open review

The current request selects this bounded creature/habitat/trail work; provisional
names, cadence, drop amounts and site sizes are tunable implementation choices.
No new currency, laboratory encounter, hybrid, failsafe, era transition, human
boss, configurable Heat, external asset/package or broad factory is included.
Any conflict affecting accepted gameplay, architecture or owned saves is surfaced
before dependent work. Human art acceptance, discovery comprehension and final
combat/economy pacing remain separate from automated results.

Checks: real engine release/contact/cover/cancellation across starting classes;
native loot and deterministic seed/source/approach guarantees; paid zero-found-
Catalyst manufacture and useful construction; kill/drop/death/restart ownership;
historical profiles, source/machine migrations and affected combat/save/payment
regressions. Run the repository engine pipeline before game commits. Record
commands, exact outcomes, limitations, local commits and remote pushes below.

## Results

Implementation in progress. No completion or player acceptance claimed yet.

### LF-3A implementation and measured tuning

`excited_boar` warns one 3.2 m circle for one second, releases once and rests
for 1.1 seconds. `retained_boar` holds one second, travels at most six metres
over 0.4 seconds with a 1.1 m contact half-width, then rests for 1.5 seconds.
Both use 3.5 m/s pursuit, 10 m ordinary aggro and 26 m disengagement distance;
the existing night/escape clocks remain. Neither has additional damage, life,
status immunity or a new status payload. Six base damage retains native variance
and mitigation. The charge's swept contact and physical body both stop at cover.

The 1.1 m width was selected after a 0.9 m candidate missed moving capsule
contact at 20 physics ticks. The warning uses that same width. The initial
render also exposed back-face culling on the warning ribbon; its two-sided
surface now reads from player height. New hosts are excluded from the native
ordinary roster, so existing eleven-family reward and catalogue checks remain
unchanged. No new Kind was invented to satisfy those legacy assertions.

The existing boar mesh, rig and scar mask are reused. An additive local mask
adapter supplies Red/Blue light without changing source assets. Ambient light
varies smoothly over 3.5 seconds between 0.35 and 0.8 strength; the separate
0.07 m warning stroke follows the actual attack state. These are prototype
presentation values, not owner acceptance of finished animal art.

Focused engine evidence: **222 checks, zero failures**. At both 20 and 60 physics
ticks, standing takes a single hit; a late retreat escapes Red but meets Blue;
a late sidestep escapes Blue but remains inside Red. Solid cover, stagger and
freeze prevent contact; aim and maximum travel remain bounded. Six actual
starting-class fights use paid fixture wooden weapons, no armour, no Foundry
pieces and real class casts. All succeed in 2.9–5.2 simulated seconds with
100 life remaining under the scripted evasion policy. This establishes an
available baseline answer, not novice reaction time or satisfying difficulty.

Commands: `tools/living_frontier_wave3_checks.ps1 -Hosts -Visuals`.
Data: `build/lf3/hosts.json`; rendered and visually inspected comparison:
[boar tells](../../captures/lf3/boar-tells.png). The fixture grants only ordinary
weapon ingredients for combat isolation; Wave 3's paid acquisition proof follows
in LF-3C. Regression command: `tools/living_frontier_wave3_checks.ps1 -Full`:
107 ordered engine invocations plus four Foundry identity scenes, all exit zero.
This includes combat, physical loot, generation, paid source/workshop flows,
restart and historical-profile coverage. Native command `-Native`: Wave 3
409; main 224,380; Wave 1 213,482; Wave 2 601 checks, all zero failures.
After isolating the opt-in native roster, rebuilt the extension and repeated
the 222-check host fixture successfully; the full pipeline preceded that final
roster-only correction. Logs are under `build/lf3/`. LF-3A remains a comparison
fixture until LF-3B ships the new world identity.
