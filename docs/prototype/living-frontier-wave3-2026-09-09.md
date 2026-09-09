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

All three slices are implemented and checked. Wave 3 remains opt-in and awaits
orchestrator review. No owner playtest or orchestrator acceptance is claimed.

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

Local commit `df5a0c1`; ordinary push to `origin/main` succeeded.

### LF-3B placement selection, recorded before implementation

Four finite hosts use a small sample, not a biome-wide recolouring. Their source
links extend out from the four existing home margins to clear supported ground
at least 170 m from spawn; the 150 m quiet valley and home/source workplaces
remain calm. Red and Blue have independent approaches, no escorts or elites.
Each host yields four matching raw units plus hide (boars one, stag two) or two
raw reeds (moth). These drops supply the raw input for two White/Blue/Green
utility kits or two Red brick batches, alongside ordinary inputs; they do not
replace bulk extraction. Death is remembered by stable host identity in the
existing saved world-effect ledger; no source or reward rerolls on streaming.

The new profile establishes all three exterior laboratory footprints in this
slice: Collection Annex near Rootvault Wildwood, Pairing Hall near Lantern Fen,
and Central Laboratory near Glasswind Uplands. Each is a visible sealed shell
on supported ground with a connected exterior approach. No interior encounter
or progression gate is enabled. Two declared future envelopes, **Retained Fen**
and **Excited Uplands**, use their respective region centres and 40 m radii.
Their eventual changes are held water/bridges and heat-fused ground/vent channels;
these remain future selections subject to the construction protection contract.
No present terrain transformation or invisible building exclusion is installed.
LF-3C adds non-blocking trail details to these existing sites, so a Wave 3 save
never acquires a new laboratory underneath a paid home.

LF-3B focused engine results: **76 habitat/payment/save checks + 18 fresh-process
checks, zero failures**; LF-3A's 222 combat checks still pass. The fixture observes
ordinary host habits, passive flight, physical loot, duplicate death callbacks,
save-before-collection, exact source non-interference, death-pack recovery and
actual laboratory collision. It gathers real timber and pays for blocks inside
both future regions, then reloads them. Killing is dispatched directly for loot
isolation; the separate LF-3A class fights supply combat evidence.

The first placement candidate required a nine-cell-wide perfectly level clearing
and rejected seed 0. The final search requires five-cell-wide level clear ground
for hosts and nine-cell-wide ground within one level for shells. Terrain and
resource arrays remain untouched. The extended **37-seed** sweep passes:
0–31, 42, 77, 256, 1337 and 2147483647, **16,809 checks, zero failures**.
The main native suite passes 224,380 checks; Wave 1 213,482; Wave 2 601.
Full engine run: **109 ordered invocations plus four Foundry identity scenes,
all exit zero**. Published paid source/workshop, loot, save, generation and
combat regressions pass. The final controlled habitat rerun also passes 76 + 18.
Source routes begin at the exact four existing +8 m home anchors. Native source
payloads retain the published Wave 1 format tag; the outer world profile and
machine identity distinguish the new world. No source-format conversion occurs.

Habits move between two points two metres from the host centre, pausing five
seconds between visits. Quiet boar/stag heads use 0.22/0.48 radian prototype
rooting/grazing poses; moth wings retain their existing authored gait. Source
cues appear every 12 walking cells. Colour stays local to the retained scar mask.
The Green moth flees at 4 m/s inside six metres and settles beyond eighteen;
the White stag retains the existing grazer rules. All four hosts are finite.

Rendered and inspected: [Red](../../captures/lf3/habitat-red.png),
[Blue](../../captures/lf3/habitat-blue.png),
[White](../../captures/lf3/habitat-white.png),
[Green](../../captures/lf3/habitat-green.png),
[Collection Annex](../../captures/lf3/lf3_collection_annex.png),
[Pairing Hall](../../captures/lf3/lf3_pairing_hall.png),
[Central Laboratory](../../captures/lf3/lf3_central_laboratory.png).
Shells are deliberately simple 6 × 5 × 4 m placeholders with distinct roof
counts, sealed framed doors and the same triple-cut emblem. They establish
visible physical ownership, not final architecture or owner visual acceptance.

Commands: `tools/living_frontier_wave3_checks.ps1 -Hosts -Habitat -HabitatRestore`,
`-HabitatVisuals`, `-Native`, `-FocusedNative` and `-Full`. Logs:
`build/lf3/final-ai-b.log`, `final-habitat-b.log`, `native-full-b.log`,
`extended-seeds-b.log`, `visual-b.log` and `full-engine-b.log`.
The final habitat movement lives in the enemy controller; the scar adapter only
poses and renders the animal. Repeated the 222 + 76 + 18 focused checks after that
separation; all pass. The full pipeline's host scenes preceded this final move.

Local LF-3B commit `0cec19f`; ordinary push to `origin/main` succeeded. Concurrent
ART-01 commits were retained; later grove work and planning edits remain separate.

### LF-3C selected proof and trail

After LF-3B's checked commit, use a fresh seed-77 Wave 3 economy with no supplied
inventory, stations or unlocks. Gather timber, build a bench and pay for an
ordinary cudgel; fight the actual Red boar. Its four Salt fund two brick batches.
Build the ordinary masonry yard/forge and place paid bricks. Draw seven Red lots,
six Blue lots and six Green lots; seed 77 has no rare result in those particular
lots. Manufacture all five Faint identities using the existing exact recipes.
White needs twelve lots across two manifestations; exhaust its first eight,
spend the accepted 600 active-world seconds and draw four further lots. No rare
find, inventory grant, raised odds, source reset or trial reward funds the proof.
Time and travel may be accelerated, with that limitation recorded explicitly.

The single artificial trail follows the native reserved walk from the Red source
to the Collection Annex. Repeated triple-cut marks, metal clamps and short
straight feed sections distinguish later collection work from natural scars.
These details have no collision, resource yield or reward interaction. They
yield locally to paid construction and do not change saved lab footprints.
Source inspection connects observed animal behaviour, useful raw drops and the
existing ordinary manufacture costs. No discovery gate or laboratory encounter
is introduced. Current Forge/curio rewards remain coherent until later waves.

### LF-3C measured result

The fresh paid journey passes **940 checks**, followed by **seven fresh-process
checks**, zero failures. Five real casts with the actually crafted wooden cudgel
defeat the generated Red boar, with 100 life remaining under scripted evasion.
The four dropped Salt plus 16 gathered clay pay eight ordinary bricks; four
bricks pay two placed cubes before any Catalyst is owned. The ordinary bench,
masonry yard and forge are gathered, crafted and placed through existing input.

The same economy smelts 22 ingots and makes 36 charcoal, then pays every input
of all five current manufacture recipes. Seven Red, six Blue, six Green and
twelve White lots contain no rare result in this journey. White's last four
lots come after its existing 600-second active-world formation. No stock reset,
Catalyst grant, raised chance, free station or Trial payout is used. A manufactured
Ember is placed into the existing persistent Kindling layout; the other four
remain owned. Source, gear, XP, host death, paid buildings and manufactured
ownership survive restart. The published importer drops empty **unearned**
mastery lists; the probe normalizes only those empty lists while comparing all
actual earned entries and practice values. No save rule changed to fit the test.

Following the repeated marks reaches the Collection Annex without granting any
stock, campaign progress, heat or mechanical work. A paid block can occupy a
mark's space; its cosmetic dressing hides and the block survives restart. The
trail leaves LF-3B's three actual shells and future envelopes exactly in place.
The 1.3 m posts, 0.75 m clamp heads, triple cut and two-cell short feeds are local
placeholder geometry; nine walking cells between marks is the exposed spacing
control. The dark metal and repeated cuts visibly distinguish the later apparatus
from local animal/source scars. Source **Details** show the actual native costs.

Rendered/inspected: [source and trail origin](../../captures/lf3/trail-origin.png),
[field feed](../../captures/lf3/trail-middle.png),
[laboratory terminus](../../captures/lf3/trail-laboratory.png),
[contextual reading](../../captures/lf3/field-reading.png) and
[expanded manufacture details](../../captures/lf3/field-manufacture.png).
Commands: `tools/living_frontier_wave3_checks.ps1 -Trail -TrailRestore`,
`-TrailVisuals`, `-FocusedNative` and `-Full`. Receipts:
`build/lf3/paid-trail.json`, `paid-trail-restart.json`, `final-trail-c.log`,
`native-c.log`, `visual-details-c.log` and `full-engine-c.log`.

Final native Wave 3 suite: **16,830 checks, zero failures**. In addition to the
37-seed geography/loot/recipe checks, a complete new-profile White → Blue → Green
chain preserves a held request across restart, then spends each receiver's
winding separately and one paid Red thermal unit only at the feeder. Cargo and
bricks have distinct owners; the consumed request cannot replay. A Wave 1 machine
world refuses this Wave 3 payload rather than importing a different identity.

The final complete engine run passes **111 ordered invocations and all four
Foundry identity scenes**, every exit zero. This includes the final 222 combat,
76 + 18 habitat/restart and 940 + 7 paid journey/restart checks, plus the existing
combat, loot, source/workshop payments, generation, terrain, building, save and
Foundry regressions. The final expanded source-panel capture also passes its
separate rendered run. No new package, production art or later-wave behaviour
was introduced. Stop here for orchestrator review; publication receipts and
remaining human questions are in the [handoff](living-frontier-wave3-handoff-2026-09-09.md).

Local LF-3C commit `118bded`; ordinary push to `origin/main` succeeded, advancing
the confirmed remote from `0cec19f` to `118bded`. The final handoff records all
three checked slices. Concurrent art changes and unrelated fixtures remain
outside these commits. No Wave 4 work was started.
