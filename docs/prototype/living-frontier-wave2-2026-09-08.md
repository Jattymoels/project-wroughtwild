# Living Frontier Wave 2 — bounded implementation

**Completed and checked: 9 September 2026. Wave 3 requires a separate review.**

**Orchestrator review, 9 September:** [technical all-clear](living-frontier-wave2-review-2026-09-09.md).
LF1-R1 and all four Wave 2 slices pass independent checks. A bounded Wave 3
work item can start; owner pacing and comfort playtests remain separate.

Owner authorization: 8 September 2026. Repair LF1-R1 and verify it before
implementing LF-2A, LF-2B, LF-2C and LF-2D, in order. Stop before Wave 3;
Wave 3 needs a separate orchestrator review. Preserve the independent wolf study.

## Outcome, affected systems and plan

Restore use of a physically repaired source at its existing anchor, then add
Blue delay, Green branching, paid Red heat storage and ordinary manufacture of
the five existing offensive Catalysts in one useful paid workshop.

Affected systems: source geometry and native ledgers; existing contraption
signals, winding, firing escrow and saves; recipe catalogue and carried materials.
D-006/D-010/D-017/D-021/D-025/D-026/D-029/D-031/D-032/D-033 continue to apply.
The current owner work item extends D-033 only through Wave 2. Tuning belongs
in `leyline.json`, `contraptions.json`, `crafting.json`, `world.json` and existing
presentation resources. No new campaign, acquisition replacement, art dependency,
automatic mining, offline work or general factory framework is selected.

1. LF1-R1: retain terrain support, additionally recognize actual paid block
   support at the fixed anchor, then perform the unchanged workspace check.
   Exercise both hosts' interrupted work, claims and formation through repeated
   obstruction/repair and fresh-process saves, including saved undermining.
2. LF-2A: inspect and record bounded delay state/migration, then add Blue's
   source and inexpensive placed delay through the ordinary player systems.
3. LF-2B: record two-output propagation/deduplication, add Green source/junction
   and prove independently paid receivers.
4. LF-2C: record exact thermal ownership/cancellation, connect a small paid Red
   buffer to the existing feeder's brick process, preserving mechanical drive.
5. LF-2D: inspect actual offensive identities, record recipes, complete a paid
   combined workshop and publish reproduction and verification evidence.

Assumptions: the existing opt-in profile and save filename remain stable, so
published Wave 1 worlds continue in place. Source and machine payloads receive
explicit additive version migrations. Existing stock, hidden outcomes, claims,
partial work, machine contents and ordinary-world policies must remain exact.
Routine component costs, delay and capacity are initial tuning within this work
item; material design/compatibility conflicts will be reported before proceeding.

## LF1-R1 — physical support repair

The source first tests its original terrain-height allowance, then accepts an
actual upward-facing `PlacedBlock` surface at that same anchor. Both paths run
the original workspace overlap check. It never moves the host or changes stock.
`leyline_source_look.gd` names the existing 0.4 m contact allowance and a 0.7
minimum upward normal for repair contact (exclude side contact). No save field
or gameplay extraction tuning changes.

`tools/living_frontier_checks.ps1 -Repair` passes **154 checks** and **64
fresh-process checks**, zero failures. Each of Red and White retains partial
work, released claims and formation across repeated unsupported refusal, paid
timber repair, paid workspace obstruction/removal and restart. Eight complete
checkpoints cover undermined partial work, repaired partial work, released
claims and undermined capped formation. Saved undermined hosts can be repaired
without resetting. Original anchors remain `(469.5,31,438.5)` and
`(594.5,32,461.5)` at seed 77. The test runner uses isolated
`build/lf1/appdata`; no ordinary player save is touched.

These are scripted physical/native player-system regressions. The support
predicate is isolated with paid native-registered construction; it does not
claim human camera-placement or discovery acceptance. The independent review's
terrain-only reproduction remains the before evidence. The repair gate passed
before Wave 2 implementation began.

Repair commit: `51ce129`, pushed successfully to `origin/main`.
The complete repository engine pipeline subsequently passed, including its
main-scene smoke run. Rebuilt native suites passed 128,078 LF checks and
224,380 original rules checks. Log: `build/lf1/full-engine.log`.

## LF-2A — selected contract before implementation

Blue Flakes occupy home margin 2 (+8 m X), with the existing eight 16-unit lots,
four safe work actions, 128-unit carrying allowance and capped 600 seconds of
active overworld formation. A fixed lot has a 4% bonus Faint Frost opportunity.
At the workbench, 2 Blue Flakes + 2 wood make a Blue Delay Kit with zero XP,
fuel, skill or additional era gates. It uses ordinary half-frame refunds.

One Blue holds one request for **3 seconds** of nearby active machine time.
The visible countdown and explicit Pause/Resume/Cancel controls expose this
state. A second request refuses without restarting or queuing. Missing support
or a blocked output signal span pauses the countdown; leaving the active radius,
game pause, trials and closed games add no time. At expiry, consume the request
once and ask the receiver to operate; missing winding or a blocked cargo span
refuses that operation without retaining a later request. Already paid trips
continue independently. Rewiring/disconnecting/removing an upstream or downstream
part of this pending route cancels it; reconnecting never restores a request.

The selected A topology is lever → optional White → optional Blue → cargo drum;
existing direct lever receivers remain valid. White cannot link another White;
Blue cannot link Blue, White or a lever. The order bounds traversal without a
general circuit engine. Each existing 24 m signal span needs physical clearance
and supported endpoints; the drum retains its own landing, cargo and winding.

Source payload **3** explicitly migrates payloads 1 (Red) and 2 (Red/White),
preserving every old record and introducing only missing newly approved hosts.
Machine payload **3**, only in the experiment, adds mandatory pending/delay/pause
fields; published payload 2 defaults those new fields to empty. Normal machine
schemas 1/2 remain unchanged. Malformed current payloads reject before mutation.

LF-2A is implemented. Native checks: **170,780 LF regression checks** and
**194 Wave 2 checks**, zero failures. The actual published Wave 1 checkpoint
was migrated and continued through paid Blue extraction, catalogue crafting,
camera placement at `(508.5,31,510.5)`, White wiring, winding and ten-wood
delivery: **182 checks passed**. Fresh processes restore paused and running
requests, complete the remaining delay and collect the same cargo once:
**26 checks passed**, including refusal of a future machine format without
rewinding to `.previous`. A disk-only version guard found during testing now
recognizes source version 3; native validation remains authoritative.

After this correction, LF1-R1 again passed 154 + 64 checks; the original paid
Wave 1 journey passed 733 + 15. Seven affected engine regressions passed:
catalogue 52, contraptions 85, pressure 60, loose drops 148, save recovery 175,
weathered save 21 and wide-frontier pacing 319. Expected malformed-save warning
fixtures remain. Rendered 1280×720 Blue source, paused/held panel and workshop
captures are in `captures/lf2/`; the held panel was visually inspected.

Reproduce A after the Wave 1 walkthrough: collect one Blue lot, make its kit
at the bench, place it near the existing White post and drum. At Blue choose
the drum; at White choose Blue. Return/empty the basket if needed, load ten
actual wood and wind once. Strike the lever, then move toward the landing.
Blue waits three active nearby seconds before the drum spends its winding.
Its E panel can pause, resume or cancel; F5/restart retains the exact delay.

Commands: `tools/living_frontier_wave2_checks.ps1 -Native` and
`-Blue -Rendered -Restore -Regression`. `-Bootstrap` first supplies the complete
paid Wave 1 journey from empty inventory when no checkpoint exists. For explicit
historical migration, retain the published checkpoint at `build/lf2/wave1.json`.
No test materials are granted. Travel and work are accelerated and hostile AI
is held by the harness; ordinary discovery, timing feel and construction
visibility remain owner playtests. The full engine pipeline includes the new
journey and fresh restart; test saves stay isolated under `build/lf2`.

LF-2A commit: `4718317`, pushed successfully to `origin/main`.
The complete engine pipeline also passed through its final main-scene smoke
run (`build/lf2/full-engine-a.log`), including every Foundry identity suite.

## LF-2B — selected contract before implementation

Green Resin uses home margin 3 (+8 m X), eight 16-unit lots, four safe manual
steps, 128 carried units and the same capped 600 active-second formation.
A fixed lot has a 4% bonus Faint Preserving opportunity. Its ordinary workbench
kit costs 2 Resin + 2 wood, zero fuel/XP/skill gate, with half-frame refunds.

Green has exactly two selected ports to distinct existing cargo drums or
pressure feeders. Each branch independently checks its signal span and receiver;
one refusal does not consume that receiver's winding, clay or fuel or undo a
successful other branch. Green copies a request, never ownership or energy.
The paid demonstration uses the acquired existing winch plus a newly acquired
Ventlung/Thrumroot feeder and the existing eight-clay/one-fuel brick firing.

The fixed grammar is lever → optional White → optional Blue → optional Green
→ receivers. A Green cannot target any signal component; Blue cannot target
Blue/White/lever; White cannot target White/lever. No path exceeds four signal
edges. Duplicate Green destinations refuse at linking and save validation, so
neither loops nor reconvergence can duplicate a request. Each new lever press
remains a new request. Green stores no pending work. A held Blue request still
cancels if its selected Green ports are rewired or removed before release.

Source payload **4** introduces only Green during migrations from 1/2/3.
Experimental machine payload **4** adds the second link/span, with empty values
for published earlier machines. Existing ledgers, partial work, claims, winding,
cargo and pending Blue state are preserved exactly. No ordinary world changes.

### LF-2B result and verification

Implemented Green extraction, affordable paid placement, two visible cables,
separate port selection/disconnection, independent physical branch inspection
and native receiver payment. The fourth approach exposed an infinite-height
cosmetic marker sample; markers now use the existing terrain query and skip
voids. Fixed anchors and source ledgers never move.

Native source checks: **213,482**, Wave 2 checks: **427**, all passing. The paid
rendered journey passed **129** checks and its fresh process passed **9**.
It loaded the actual published schema-3 paused Blue checkpoint before continuing
the paid A completion, gathered Green plus finite Ventlung/Thrumroot/iron/timber,
made and placed both kits, attached the owned forge, and linked both ports.
A physical first-span wall left the drum's winding untouched while the feeder
spent eight clay, one wood and one hand stroke to make four bricks. A later
delayed request operated both receivers; cargo and eight total bricks had real
owners across restart. Native corruption, loops, duplicate ports, cancellation
and schemas 1–3 migration also passed. LF1-R1 again passed **154 + 64**.

Reproduce B: after A, harvest a Green lot and craft the two-resin/two-wood kit.
Gather the existing feeder recipe's rare cores and ordinary frame ingredients;
place it within eight metres of your built forge and attach that forge. Point
Blue at Green; choose the drum and feeder as Green's distinct outputs. Load clay
and ordinary wood fuel into the feeder and wind it separately. Load/wind the
drum. Strike the lever: after three seconds each receiver attempts its own work.
Keep signal cables, basket route, feeder/forge connection and feet clear.

Commands: `tools/living_frontier_wave2_checks.ps1 -Native`,
`-Green -Rendered -GreenRestore`, `-Regression`, and
`tools/living_frontier_checks.ps1 -Repair`. Green source, port panel and workshop
captures are in `captures/lf2/`; the two-port panel was visually inspected.
Travel/work acceleration and held hostile AI remain harness limitations.
The seven affected ordinary-world regressions passed again (52/85/60/148/175/
21/319 checks). Blue's paid journey and restart passed **182 + 26** after Green.
The complete engine pipeline passed (`build/lf2/full-engine-b.log`).
LF-2B commit **`4bda377`** was pushed successfully to `origin/main`.

## LF-2C — selected contract before implementation

The ordinary workbench makes a Red Heat Buffer Kit for 4 Red Salt, 4 wood and
2 iron ingots. Its four-unit thermal store accepts one deliberate **2 Red Salt
→ 1 heat** charge at a time, only with physical support. This matches the
accepted Red brick variant's thermal payment without changing the global fuel
table. Conversion is immediate; it grants neither winding nor personal XP.

One buffer attaches to one existing feeder within eight metres; a feeder can
select only one buffer. Its short visible thermal connection is separate from
the Green signal and any pressure source. An attached feeder uses one heat per
firing instead of ordinary fuel, still reserving all eight clay, one mechanical
stroke and space for four existing bricks. Empty/blocked heat refuses or pauses;
there is no fallback that silently consumes a different fuel. Detaching an idle
buffer restores the feeder's existing ordinary-fuel operation.

Heat reserved by an active firing retains its return slot in the buffer.
Cancellation returns the exact heat once plus clay and mechanical work. Changing
thermal attachments or dismantling the buffer refuses while its feeder owns a
firing: finish or cancel first. Dismantling a feeder returns its reserved heat to
the buffer and recovers ingredients/output under existing rules. Dismantling an
idle buffer explicitly vents unused heat; spent charge salt never returns as a
material. The ordinary kit-frame refund remains separate from thermal contents.
This avoids silently converting thermal energy back into raw material.

Experimental machine payload **5** adds heat, heat owner and reserved heat.
Versions 1–4 default to no heat attachment/content and retain every existing
ledger field, including Green ports and Blue requests. Source payload remains 4.
No passive heat loss, offline production, universal fuel or new crafting timer.

### LF-2C result and verification

The paid rendered heat journey passed **303** checks; fresh restart passed
**14**, all with zero failures. It migrated the published Green pending save,
preserved every prior machine field and source, then continued its actual paid
completion. The bench consumed the buffer frame; normal B placement put it at
`(515.5,31,520.5)`, 2.8 metres from the feeder. Four deliberate charges consumed
eight more acquired Red Salt. One firing reserved heat independently of winding
and clay, survived a physical thermal-span obstruction and a paused 2.25-second
save, cancelled exactly, then made four existing bricks. Capacity, active
removal refusal, idle venting and active feeder dismantling passed. Its saved
completion retains 3 heat and 12 actual feeder bricks for the combined workshop.

Native source **213,482** and Wave 2 **471** checks pass. Zero-count entries in
the crafting inventory required an assertion correction; exact kit debits and
thermal conservation remained the acceptance criteria. The buffer uses only
the existing small fixture/inventory rules, without adding an economy link
dependency to the standalone contraption target.

Reproduce C after B: craft the Red Heat Buffer Kit, place it beside the feeder,
choose that feeder at the buffer, and pay two Salt per stored heat. Load eight
clay and wind the feeder separately. Start a firing or strike its linked lever.
Inspect Drive / connections to see the selected Red heat source. Pause/cancel
at the feeder; finish/cancel before detaching or removing the buffer. F5/restart
retains stored and held heat. Dismantling the idle buffer vents unused heat and
refunds only the ordinary frame share.

Commands: `tools/living_frontier_wave2_checks.ps1 -Native`,
`-Heat -Rendered -HeatRestore`, and `-Regression`. Store/firing panel captures
are in `captures/lf2/`; the thermal store panel was visually inspected.

LF-2C commit: `75ae963`, pushed successfully to `origin/main` after the
complete repository engine pipeline passed, including main-scene smoke.
Log: `build/lf2/full-engine-c.log`. The full fresh-bootstrap run also passed
324 heat-journey checks and 14 restart checks (the historical schema-4
migration run above has 303, because it compares fewer pre-existing fields).
Standalone contraptions passed 602. The interruption's incomplete run was
replaced by this complete successful run on 9 September; it is not counted
as a pass.

## LF-2D — selected contract before implementation

Actual mechanics were inspected in `data/tuning/foundry.json`,
`game/scripts/foundry_offence.gd`, `foundry_cold.gd`, `foundry_ember.gd`,
`foundry_echo.gd` and the existing identity tests. Keep all canonical IDs,
grade refinement, ordered interactions and combat effects unchanged:

| Source/process | Existing identity | Mechanical fit checked |
| --- | --- | --- |
| Red heat pattern | Ember | Kindling attaches its authored delayed ignite fuse; the obsolete shared ignite-spread operation stays zero |
| Blue binding | Frost | Chill/control; Whiteout slows each crossing shot once, not a generic damage bonus |
| Green carried pattern | Preserving | Emberbed transfers existing burn budget; Cold Reservoir holds chill; Wound Memory holds existing bleed; newcomer/return effects retain their own rules |
| White compression | Impact | Firebreak's delayed rear crescent, Glacier Break's conditional shove and the other distinct contact/release events |
| White through-flow | Piercing | Cinder Lance, Throughline and the existing passage/contact operations |

Each recipe is immediate at the basic forge, Blacksmithing 1 / era 1, with 2
base XP and zero extra fuel. Charcoal is already its explicit thermal cost.
Ember remains **96 Red + 4 iron + 8 charcoal**. Add Frost **96 Blue + 4 iron +
8 charcoal**, Preserving **96 Green + 4 iron + 8 charcoal**, Piercing **96 White
+ 4 iron + 8 charcoal**, and Impact **96 White + 6 iron + 4 charcoal**. The last
two are distinct ordinary recipes using the same medium; compression uses more
iron and less charcoal. No sixth identity, new grade, lesson, research,
perfection step, recipe timer or new acquisition restriction is selected.

All full inputs fit carried family limits. Two-unit signal parts and the
four-unit buffer frame remain affordable beside the 96-unit Catalyst debit.
Existing Faint → Stable → Potent recipes and their actual station/skill/era/fuel
costs stay exact. These remain additional opt-in manufacture routes; encounter,
trial and peddler acquisition changes belong to a later separately reviewed wave.

The useful combined workshop will continue the paid A/B/C checkpoints: lever →
White → Blue → Green requests a loaded cargo trip and a Red-heated brick firing.
Each winding is supplied separately, the clay comes from finite gathering,
the heat is already paid Salt, and the cargo is the workshop's real fired bricks.
Delivered bricks then pay for ordinary building pieces. Manufacture uses actual
manual lots plus normal gathered/smelted iron and charcoal, retaining rare finds
as optional separately owned bonuses. Two White Catalysts need one already
accepted capped source reformation; that source clock is not a recipe timer.


## Paid owner walkthrough — Wave 2

Launch `godot --path game -- --living-frontier --world-seed=77`. Continue an
existing experimental save or choose a class and gather in a new world. The
profile and `user://living_frontier_wave1.json` filename are unchanged. F5/F9
and restart keep this world separate from ordinary saves. Published Wave 1
worlds acquire only their missing Blue/Green introductions during migration.

1. Gather finite wood/ore and build your ordinary bench and basic forge. Smelt
   iron at that forge; this also earns the existing Ember ingot. Follow the
   coloured scars around the home opportunities. At each supported source,
   aim and press E, perform its four named work steps, then collect the raw
   material and any separately released rare claim. Each lot yields 16 raw;
   eight lots exhaust a manifestation. Restore excavated ground with actual
   paid construction touching the existing anchor and leave its workspace clear.
2. Craft the inexpensive parts at the bench. Acquire Stormglass from its real
   seam, Thrumroot and Ventlung from their existing contextual-work hosts,
   and reeds from finite gathering. Rare finds are not required for any part.
   All listed ingredient quantities are paid once; place each owned kit with B
   and a normal click on a supported, unobstructed footprint.

| Placed component | Bench payment |
| --- | --- |
| Stormglass lever | 1 Stormglass, 3 wood, 1 iron ingot |
| Cargo winch | 1 Thrumroot, 8 wood, 2 iron ingots |
| Fixed landing | 6 wood, 1 iron ingot |
| White connection | 2 White Mineral, 2 wood |
| Blue delay | 2 Blue Flakes, 2 wood |
| Green junction | 2 Green Resin, 2 wood |
| Pressure feeder | 1 Ventlung, 1 Thrumroot, 8 wood, 2 iron ingots, 2 reeds |
| Red heat buffer | 4 Red Salt, 4 wood, 2 iron ingots |

3. At seed 77, the checked workshop places lever `(500.5,31,510.5)`, White
   `(504.5,31,511.5)`, Blue `(508.5,31,510.5)`, Green `(512.5,31,508.5)`,
   drum `(504.5,31,506.5)`, landing `(518.5,31,506.5)`, feeder
   `(517.5,31,518.5)` and buffer `(515.5,31,520.5)`. These are examples,
   not required coordinates. Keep the feeder beside your own forge, with
   clear visible spans and support under every fixture.
4. Choose the landing at the drum. Choose White at the lever, Blue at White,
   Green at Blue, drum at Green's first port and feeder at its second. At the
   feeder, use **Drive / connections → Choose forge / pocket → Attach forge ·
   hand-wound**. At the buffer, **Choose heat receiver** selects that feeder.
   The short thermal pipe is separate from the two Green signal branches.
5. At the buffer, pay 2 Salt per heat, up to 4 available plus held heat. At the
   feeder, load 8 clay and wind by hand once. At the drum, load actual materials
   from your pack and wind once. Strike the lever: Blue holds one request for
   3 seconds, then Green attempts both operations. The basket spends its own
   winding; the feeder separately reserves 8 clay, 1 winding, 1 paid heat and
   room for 4 bricks. After the existing 8-second firing, collect the bricks.
6. Pause/resume/cancel the delay at Blue. F5 during its countdown and restart
   resumes only its remainder; leaving the active area or obstructing Blue's
   output holds it. Rewiring the selected route cancels it, and reconnecting
   requires a new lever strike. A blocked Green branch or unpaid receiver can
   refuse while the other operates. No receiver repeats from that same request.
7. Feed the newly made bricks into the actual cargo basket on its return.
   A further paid lever request can deliver the bricks while firing the next
   batch. Collect at the landing and use B to build with Rustclay Brick. Each
   ordinary cube consumes 2 delivered bricks. The saved automated walkthrough
   delivers 16 existing bricks, builds four cubes from 8, leaves 8 in the pack,
   makes a further 4 in the feeder and retains 2 paid heat in the buffer.
8. Manufacture the five offensive Catalysts at the basic forge using the selected
   Catalyst costs: 96 of its colour, 4 iron and 8 charcoal; Impact instead uses
   6 iron and 4 charcoal. Gather the whole displayed debit into your own pack; the forge never
   silently withdraws from a chest or hopper. Each raw family holds up to 128.
   Two White recipes plus the connection need more than the first 128 White:
   exhaust and collect that manifestation, spend ten minutes of active overworld
   play doing other work, then manually extract the one reformed manifestation.
   Ready stock never banks additional formations. No recipe has a timer.
9. In F, use your earned Ember ingot beside Heavy Strike and invest each crafted
   Catalyst at the same adjoining Kind cell. The existing forms are Kindling,
   Smoulder, Emberbed, Firebreak and Cinder Lance. Lifting a Kind uses the
   unchanged one-iron payment and returns that owned Kind. Stable and Potent
   remain the existing ordinary refinement routes with their existing forge,
   skill, era, material and fuel requirements.

For the Red buffer, cancel a firing at the feeder to return its exact reserved
clay, winding and heat once. Finish or cancel before detaching/removing the
buffer. Removing an idle buffer vents its unused heat and returns only the
ordinary half-frame refund (2 Salt, 2 wood, 1 iron); charge Salt never reappears.
Removing the feeder returns its held heat to the still-present buffer, along
with its actual ingredients/output to the player, and vents unused drive.


## LF-2D result and verification

The actual rendered journey passed **488 checks**, then a fresh process passed
**10**, all with zero failures. It loaded the paid C completion without changing
any existing source/machine field, then manually extracted 96 Red, 96 Blue,
96 Green and 192 White in total. Every released claim was collected. The source
clock formed exactly one new Red and White manifestation after 600 active
seconds; it did not assign stock or alter saved outcomes. The new Red lots
happened to release two bonus Ember Catalysts and Green one bonus Preserving;
these remain separately owned and are not counted as manufactured outputs.

Nine ordinary six-ore trips paid for 27 smelts. Those smelts and 18 charcoal
batches consumed 54 gathered ore and 153 wood, leaving the starting wood stock
217 → 64. Twenty-two of the real iron ingots and all 36 charcoal paid for one
of each offensive Catalyst; five further iron paid the existing Kind lifts.
The initial harness attempt tried to gather 54 ore before smelting and stopped
at the existing 30-ore carrying cap. The successful journey uses normal smaller
hauls; neither the cap nor a recipe was relaxed.

Each manufactured identity was placed through the actual Foundry controls beside
the earned Ember ingot and Heavy Strike, producing the existing named form. The
native fixture separately checks the actual operation values, recipe deficits,
normal-world refusal, exact save ownership and unchanged Stable/Potent costs,
including consuming the actual manufactured Faint through both grades. The
obsolete shared Ember ignite-spread assertion was corrected to the current
Kindling fuse; combat tuning and runtime identity code were not changed.

The combined lever → White → Blue → Green route held one request for three
seconds, moved 16 real bricks and started one independently paid Red-heated
firing. Its final ledger owns 8 carried bricks, four cubes built from 8 delivered
bricks, 4 new feeder bricks and 2 unused paid heat. The drum is empty; all
winding is spent. Pending-request and completed-construction checkpoints both
survive fresh-process restoration exactly, with no duplicate trip or firing.

Final native checks pass: source **213,482**, Wave 2 **601**, standalone
contraptions **602**. Commands and final full-suite receipt are below. Rendered
captures include all five recipe panels, all five manufactured Foundry forms,
the connected workshop and the paid brick foundation. Impact's actual cost
panel, Cinder Lance's reading, the workshop's separate branches/thermal pipe
and the finished brick construction were visually inspected.

## Final automated receipt — 9 September 2026

The complete `game/run_headless_checks.sh` passed with **zero failures**, ending
in `All headless checks passed.` and its 120-frame main-scene smoke run. The
final log has no `FAIL`, `SCRIPT ERROR` or `ERROR:` entries. Runtime/tuning stayed
unchanged for this full run. Log: `build/lf2/full-engine-d.log`.

| Final check actually run | Result |
| --- | --- |
| Original native rules, rebuilt with `-Wall -Wextra -Werror` | 224,380 / 0 failures |
| Native source/save/seed suite | 213,482 / 0 failures |
| Native Blue/Green/Red/Catalyst suite | 601 / 0 failures |
| Standalone native contraptions | 602 / 0 failures |
| Red/White support repair + fresh restart | 154 + 64 / 0 failures |
| Full paid Wave 1 bootstrap + fresh restart | 733 + 15 / 0 failures |
| Final full-run Blue + restart | 216 + 26 / 0 failures |
| Final full-run Green + restart | 129 + 9 / 0 failures |
| Final full-run Red heat + restart | 324 + 14 / 0 failures |
| Paid all-Catalyst workshop + restart (rendered and full-run headless) | 488 + 10 / 0 failures |
| Ordinary catalogue, contraptions, pressure workshop, loose-drop save, save recovery, weathered save, wide-frontier pacing | 52 / 85 / 60 / 148 / 175 / 21 / 319; all 0 failures |
| Final Markdown local-link check | 6 changed documents, 0 missing targets |

The complete pipeline also retains all its terrain, building, trial, identity,
combat and save fixtures. Blue/heat full-run totals exceed their historical
migration journeys because those compare fewer fields in published older
payloads; both forms passed. Native logs use `build/lf2/*-final.log`; the paid
rendered/restart logs use `build/lf2/workshop-*.{out,err}.log`.

## Verification commands and compatibility ledger

From the repository root, after building the existing GDExtension:

```powershell
powershell -ExecutionPolicy Bypass -File tools/living_frontier_checks.ps1 -Repair
powershell -ExecutionPolicy Bypass -File tools/living_frontier_wave2_checks.ps1 -Native
powershell -ExecutionPolicy Bypass -File tools/living_frontier_wave2_checks.ps1 -Bootstrap -Blue -Restore -Green -GreenRestore -Heat -HeatRestore -Workshop -WorkshopRestore -Rendered
powershell -ExecutionPolicy Bypass -File tools/living_frontier_wave2_checks.ps1 -Regression
```

The PowerShell runners use isolated `build/lf1/appdata` and `build/lf2/appdata`.
`game/run_headless_checks.sh` includes the repair, all four paid Wave 2 scenes
and each restart, plus all existing engine checks. Point `GODOT` at the pinned
Godot 4.5-stable binary. `make -C tests/sim` includes the original rules, source
and Wave 2 native targets; `make -C tests/sim contraptions` checks the standalone
contraption target. Tests supply native boundary fixtures where explicitly
commented; the paid engine chain contains no inventory/core/drive grants.

| Saved payload | Published versions retained | Current addition |
| --- | --- | --- |
| Source ledger | Red 1, Red/White 2, Blue 3 | Green 4; older existing hosts retain exact lots, partial work, claims, outcomes and formation |
| Experimental machines | Original/White 1–2, Blue 3, Green 4 | Red 5; add zero-default thermal fields and preserve all prior fields |
| Ordinary machines | Existing 1–2 | No new fields or version promotion |
| Player/world save and identity | Existing profile, seed, filename, inventory and earned Foundry state | No reset, relocation or acquisition/campaign migration |

Future source/machine payloads refuse before mutation and without silently
recovering an older `.previous` ledger. Missing state already mandatory in a
published version refuses; only later source introductions initialize. One
Blue request and two terminal Green ports are fixed bounds, enforced during
linking and loading. There is no arbitrary signal graph or generated job queue.

## Limits and remaining owner playtests

- The harness accelerates travel, finite gathering/pickup dispatch and active
  machine/source time, and holds enemy AI during the paid route. It verifies
  actual payments, controls, collision and saved ownership; it does not measure
  ten minutes of human play, source discovery, combat pressure or novice comfort.
- Sources remain one fixed host per colour on existing home margins. Four safe
  work steps, eight 16-unit lots, 128 raw carrying limits, 4% optional Red/Blue/
  Green finds and the existing capped 600-second reformation are initial tuning.
  White has no new rare pool. No core or Catalyst is required for manual work.
- Delay is fixed at 3 seconds; Green supports two distinct drum/feeder terminals
  in the selected ordered route. Requests never provide drive or ingredients.
  No adjustable timers, cascaded junctions, general routing or automatic mining.
- Red has four total available/held heat, two Salt per charge and one feeder.
  Its charge, delivery, loading and winding are deliberate player operations.
  Machines keep the existing nearby/live-overworld rule and no offline work.
- Owner playtests: find all four hosts without coordinates; repair a dug host
  through ordinary B placement; judge work repetition and the 96-raw Catalyst
  cost; verify the three-second move-into-position window; read both Green
  branches and the thermal pipe in a personal workshop; compare hand firing
  with Red heat storage; play save/restart/disconnect/removal in a real session.
  Grade/Foundry combat regressions pass, but long-term balance remains an owner
  judgement. The experiment is still opt-in and is not a default-world rollout.
- **Wave 3 is not implemented or authorized by this completion.** Its inhabitants,
  reward/campaign changes, labs, eras and later factory ambitions require the
  separately requested orchestrator review. The wolf/TRELLIS/art session's
  commits and working files are outside these slices and are preserved.


## Scoped file manifest
Each prior slice lists only its committed paths. D lists its own final files;
concurrent wolf/art planning changes are excluded.

### LF1-R1 — `51ce129`
- `docs/decisions/registry.md`
- `docs/prototype/living-frontier-wave1-review-2026-09-08.md`
- `docs/prototype/living-frontier-wave2-2026-09-08.md`
- `docs/systems/construction.md`
- `game/art/leyline_source_look.gd`
- `game/run_headless_checks.sh`
- `game/scripts/leyline_source.gd`
- `game/tests/leyline_support_repair.gd`
- `game/tests/leyline_support_repair.gd.uid`
- `game/tests/leyline_support_repair.tscn`
- `tools/living_frontier_checks.ps1`

### LF-2A — `4718317`
- `captures/lf2/blue-held.png`
- `captures/lf2/blue-paused.png`
- `captures/lf2/blue-source.png`
- `captures/lf2/blue-workshop.png`
- `data/tuning/contraptions.json`
- `data/tuning/crafting.json`
- `data/tuning/leyline.json`
- `data/tuning/world.json`
- `docs/prototype/acceptance-criteria.md`
- `docs/prototype/living-frontier-wave2-2026-09-08.md`
- `docs/systems/construction.md`
- `docs/systems/crafting-and-skills.md`
- `docs/systems/world-generation.md`
- `game/art/contraption_look.gd`
- `game/art/leyline_source_look.gd`
- `game/extensions/wroughtwild_sim/src/strange_frontier_bindings.inc`
- `game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp`
- `game/extensions/wroughtwild_sim/src/wroughtwild_sim.h`
- `game/run_headless_checks.sh`
- `game/scripts/contraption_panel.gd`
- `game/scripts/contraption_site.gd`
- `game/scripts/leyline_source.gd`
- `game/scripts/save_manager.gd`
- `game/scripts/strange_resource_art.gd`
- `game/tests/living_frontier_flow.gd`
- `game/tests/living_frontier_wave2_flow.gd`
- `game/tests/living_frontier_wave2_flow.gd.uid`
- `game/tests/living_frontier_wave2_flow.tscn`
- `sim/include/wroughtwild/contraptions.h`
- `sim/include/wroughtwild/leyline.h`
- `sim/src/contraptions.cpp`
- `sim/src/leyline.cpp`
- `tests/sim/Makefile`
- `tests/sim/test_leyline.cpp`
- `tests/sim/test_living_frontier_wave2.cpp`
- `tools/living_frontier_wave2_checks.ps1`

### LF-2B — `4bda377`
- `captures/lf2/green-ports.png`
- `captures/lf2/green-source.png`
- `captures/lf2/green-workshop.png`
- `data/tuning/crafting.json`
- `data/tuning/leyline.json`
- `data/tuning/world.json`
- `docs/prototype/living-frontier-wave2-2026-09-08.md`
- `docs/systems/construction.md`
- `docs/systems/crafting-and-skills.md`
- `game/art/contraption_look.gd`
- `game/art/leyline_source_look.gd`
- `game/extensions/wroughtwild_sim/src/strange_frontier_bindings.inc`
- `game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp`
- `game/extensions/wroughtwild_sim/src/wroughtwild_sim.h`
- `game/run_headless_checks.sh`
- `game/scripts/contraption_panel.gd`
- `game/scripts/contraption_site.gd`
- `game/scripts/leyline_source.gd`
- `game/scripts/save_manager.gd`
- `game/scripts/strange_resource_art.gd`
- `game/tests/living_frontier_green_flow.gd`
- `game/tests/living_frontier_green_flow.gd.uid`
- `game/tests/living_frontier_green_flow.tscn`
- `sim/include/wroughtwild/contraptions.h`
- `sim/include/wroughtwild/leyline.h`
- `sim/src/contraptions.cpp`
- `sim/src/leyline.cpp`
- `tests/sim/test_living_frontier_wave2.cpp`
- `tools/living_frontier_wave2_checks.ps1`

### LF-2C — `75ae963`
- `captures/lf2/red-heat-firing.png`
- `captures/lf2/red-heat-store.png`
- `data/tuning/contraptions.json`
- `data/tuning/crafting.json`
- `docs/prototype/living-frontier-wave2-2026-09-08.md`
- `docs/systems/construction.md`
- `docs/systems/crafting-and-skills.md`
- `game/art/contraption_look.gd`
- `game/extensions/wroughtwild_sim/src/strange_frontier_bindings.inc`
- `game/run_headless_checks.sh`
- `game/scripts/contraption_panel.gd`
- `game/scripts/contraption_site.gd`
- `game/scripts/feeder_readout.gd`
- `game/scripts/feeder_readout.gd.uid`
- `game/scripts/save_manager.gd`
- `game/scripts/strange_resource_art.gd`
- `game/tests/living_frontier_heat_flow.gd`
- `game/tests/living_frontier_heat_flow.gd.uid`
- `game/tests/living_frontier_heat_flow.tscn`
- `sim/include/wroughtwild/contraptions.h`
- `sim/src/contraptions.cpp`
- `tests/sim/test_living_frontier_wave2.cpp`
- `tools/living_frontier_wave2_checks.ps1`

### LF-2D — recipes, paid workshop and handoff
- `README.md`
- `data/tuning/crafting.json`
- `docs/prototype/leyline-catalyst-extraction-2026-09-08.md`
- `docs/prototype/living-frontier-roadmap-2026-09-08.md`
- `docs/prototype/living-frontier-wave2-2026-09-08.md`
- `docs/systems/crafting-and-skills.md`
- `game/README.md`
- `game/run_headless_checks.sh`
- `game/tests/living_frontier_workshop_flow.gd`
- `game/tests/living_frontier_workshop_flow.gd.uid`
- `game/tests/living_frontier_workshop_flow.tscn`
- `tests/sim/test_living_frontier_wave2.cpp`
- `tools/living_frontier_wave2_checks.ps1`
- `captures/lf2/catalyst-{ember,frost,impact,piercing,preserving}.png`
- `captures/lf2/manufactured-{ember,frost,impact,piercing,preserving}.png`
- `captures/lf2/complete-paid-workshop.png` and `paid-brick-foundation.png`
