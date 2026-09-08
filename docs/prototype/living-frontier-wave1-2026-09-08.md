# Living Frontier Wave 1 — implementation and handoff

**Owner-authorised 8 September 2026. LF-1A, LF-1B and LF-1C implemented.** Baseline `8401b1a`.
Scope: LF-1A, LF-1B, LF-1C, in that order. Wave 2 requires separate review.
The independent wolf/image-to-3D study is outside this change.
The [per-slice changed-file manifest](living-frontier-wave1-files-2026-09-08.md)
lists every implementation, specification, test, tool and capture changed.
LF-1A `e6feb0b` and LF-1B `42ee83d` are committed and pushed to `origin/main`.

## Selected contract and small plan

Affected systems: native extraction ownership, world identity, ordinary crafting,
hauling, Godot source interaction/save restoration, and existing signal fixtures.
D-006/D-010/D-017/D-021/D-025/D-026/D-029/D-031/D-032 remain authoritative;
D-033 below selects only this bounded opt-in exception. No unresolved design
decision blocks the selected implementation. Pacing and visual finish are initial
tuning for owner playtests, not acceptance of the rest of the roadmap.

1. LF-1A: one reachable Red host, safe manual work, fixed rare lots, owned claims,
   bounded formation, useful paid brick variant, restart and legacy checks.
2. LF-1B: substantial ordinary raw-to-Faint recipe, normal catalogue, carried
   capacity and existing persistent Foundry/refinement proof.
3. LF-1C: White host, cheap placed connection, fully acquired/paid lever, drum,
   landing and cargo; disconnected, blocked, empty-drive and restart checks.

The opt-in `living_frontier_wave1` profile reuses the exact V6 base generator and
inputs. Normal new games remain V6; no saved V1–V6 world receives sources or
recipe changes. Launch with `-- --living-frontier --world-seed=77`. The existing
class/seed chooser remains, while Continue/F5/F9 and trial suspension use
`user://living_frontier_wave1.json`, separate from the normal save. This is an
experiment, not the default successor campaign; future laboratories/terrain
transforms are not approved or reserved by it. Existing mob, Trial and peddler
acquisition stays in place during this partial economy rollout.

## LF-1A — selected behaviour and tuning

`data/tuning/leyline.json` owns one Red Salt inclusion on a guaranteed V6 home
clearing's margin (home 0, +8 m X). The existing native home approach supplies
reachable geography; short Red surface clues lead out from the starter valley.
The host leaves the central home space free. Rendering owns no stock.

Each manifestation contains **8 lots × 16 Red Salt = 128 raw units**. Four safe
manual actions expose, vent, settle and draw each lot. All classes use the same
actions without a Catalyst, attack property, tool, research or lesson. A released
lot remains physically in the host's exposed tray; collection transfers it to
the player's ordinary carried family. Raw and rare claims have one native owner,
do not expire, and block the next draw until fully collected. Full families keep
the remainder; partial collections and repeated requests cannot duplicate it.
Faint Ember remains its existing material category and open-world death rule.

**4% per fixed Red lot** yields one existing Faint Ember as a bonus. Independent
stable source/seed/manifestation/lot hashing fixes outcomes at formation, and the
native snapshot retains them. Work presses, panel visits and claim splits never
roll. Eight opportunities leave about 72.1% of manifestations without a find;
24 opportunities leave about 37.5% without one. Useful raw output does not depend
on these odds. All values are initial playtest tuning.

After every lot and claim is taken, **600 seconds of active overworld play**
forms one new manifestation. Ready stock stores no time credit. Obstructed or
unsupported hosts cap credit at one formation and wait for their workspace.
There is no offline/paused/Trial growth. Distant active overworld time counts;
ordinary deposits, rare fixture cores and D-031 pressure remain finite.

`fire_red_brick` is an ordinary basic-forge recipe visible only in the experiment:
**8 raw clay + 2 Red Salt → 4 Rustclay Brick**, immediate, zero mastery XP and
no added skill/era gate. Its two Salt replace the original recipe's one heat.
`refine_rustclay_brick` remains 8 clay + 1 ordinary fuel heat → 4 bricks. Red Salt
is absent from the global fuel table and supplies no mechanical work. Its
128-unit carrying allowance in `world.json` fits a full manifestation and the
planned costly conversion without remote chest access.

Outer save schema 2 gains an optional opaque `leylines` field for historical
worlds, mandatory and versioned for LF-1. The native payload validates world
identity, complete source set, work, outcomes, formation and claims before any
player/world mutation. Whole-checkpoint restoration replaces state. Missing or
malformed LF ledgers cannot initialize a fresh source. Existing saves need no
migration and retain owned Kinds, gear, progression, loose drops and machinery.

## LF-1B — ordinary manufacture and persistent use

`forge_faint_ember`: **96 Red Salt + 4 iron ingots + 8 charcoal → one Faint
Ember**, immediately at the basic forge, Blacksmithing 1, era 1, 2 base XP.
Charcoal is paid as an ingredient, with zero additional fuel. Six lots are a
deliberate purchase; one full Red manifestation leaves 32 Salt for brick firing
(30 after the LF-1A demonstration). Input caps are checked independently and
the engine journey carries the entire recipe together. No additional progression
state or processing timer exists.

The experiment hides/refuses `distil_ember` only after its useful raw route and
replacement exist. Normal V1–V6 retain the original recipe, loot and trade.
Stable and Potent refinement are unchanged paid transformations of owned
Catalysts. Crafting retains the existing uncapped forged-output rule; gathering
and collection still respect family caps. No owned stock is clamped on reload.

The paid journey earns its Ember ingot by smelting, places the known Heavy Strike
tablet at row 2 / column 2, Ember at row 2 / column 1 and the manufactured
Catalyst at row 3 / column 1 using ordinary Foundry controls. Native readings
produce existing **Kindling**, retained by checkpoint and fresh-process saves.
These are human-facing one-based coordinates. Stable/Potent tests use separate
native progression fixtures; the paid era-one journey does not grant later eras.

LF-1B verification: **81,794 native checks**, **310 paid journey checks**, **5
fresh-process checks**, all passing. The seven affected engine regressions listed
below passed again. The catalogue and Kindling plate captures (`ember-recipe.png`,
`ember-foundry.png`) were rendered at 1280×720 and visually inspected. Exact
three-input payment, each missing ingredient, carried capacity, uncapped crafted
output/reload, legacy distillation and both paid grade refinements are covered.
Recipe cost versus extraction effort remains an owner pacing playtest.

## LF-1C — first constructed connection

The second guaranteed home clearing has one **White Mineral inclusion**, at
home 1 +8 m X, with White surface clues. Its **8 lots × 16 units**, four safe
manual steps, 128-unit carried family, exact claim ownership and **600 active
overworld seconds** of capped renewal use the same native rules as Red. White
has **no rare Catalyst pool in Wave 1**; no additional Kind identity is introduced.
Its stages are expose, brace, settle the impulse, and draw. Neither material
creates mechanical drive or a universal fuel.

At the workbench, **2 White Mineral + 2 wood → one White Connection Kit**,
immediately, era 1, no skill gate, zero XP/fuel. One White lot therefore makes
eight connections. B's normal kit catalogue/preview places a compact supported
post. Select one cargo drum from its E panel, then select this White post from
a Stormglass lever's E panel. The panel describes disconnected output, blocked
signal/cargo spans, an unwound drum, a travelling basket and available winding.

The bounded topology is **lever → one White connection → one cargo drum → its
one landing**. Each signal segment uses the existing **24 m** range. The cargo
span retains **32 m**, **96 units**, **3 m/s**, minimum **0.5 s**, and the existing
**4-work capacity / 1 work per winding / 1 work per trip**. These are inherited
`contraptions.json` values, not a new drive. Both signal segments require clear
rays and supported endpoints; the basket uses its existing volume sweep.
Existing direct lever receivers remain compatible, including saved experimental
fixtures. No conversion of old wiring, delay, branch, loop, signal queue, loader,
automatic gathering or manufacturing network is added.

A signal synchronously requests departure. The drum owns and spends its existing
work, and owns its basket's cargo at every point; a landing never owns a copy.
White stores only its output link and a presentation pulse count. Requests made
against an empty drive or a travelling basket cannot become future work. Loading
or collecting requires the basket at that endpoint. Blocked cargo pauses intact;
only nearby active machine time advances it, with no offline catch-up. Disconnecting
or dismantling White stops later requests but preserves a departed paid trip.
White uses the ordinary half-frame refund: **1 White Mineral + 1 wood**; no
rare-core full-refund exception. Existing core refunds are unchanged.

Source payload **version 2** adds White. Published **version 1** checkpoints
must contain the exact Red-only source set: migration preserves all Red work,
outcomes, claims and formation and introduces White at its initial stock. Current
version-2 checkpoints must contain both sources. A missing White or Red ledger
rejects before any player/world mutation. There is no global save reset or cap
clamp, and old V1–V6 save payloads remain valid without any leyline field.

## Wave 1 verification

Final native LF checks: **128,078 passing**, covering both hosts, interrupted and
partial/full claims, fixed rarity over 2,048 Red lots, source renewal, version-1
migration, malformed version-2 refusal, exact recipes, old acquisition and grades,
bounded links, full cargo, obstruction, repeated requests, disconnect/dismantle,
in-flight saves and once-only delivery. The complete native suite was rebuilt
against Wave 1 and again passes **224,380 checks**.

The published LF-1B player checkpoint was also loaded by the LF-1C engine and
used to acquire/place/connect/run the paid workshop: **420 checks passed** after
the final route-readout/capture polish. This tested actual outer-save migration rather
than only native fixtures. The complete empty-pack rendered journey passes
**733 checks**, with **15 more fresh-process checks**, including resumed cargo
delivery. Both runs have zero failures. All seven affected engine regressions
passed again: catalogue 52, contraptions 85, pressure workshop 60, loose drops
148, save recovery 175, weathered save 21, wide-frontier pacing 319. Corrupt-save
fixtures deliberately emit JSON warnings while their refusal checks pass.

Rendered 1280×720 evidence in `captures/lf1/` was visually inspected: Red
work/released claims/bricks, the costly Ember recipe, the Kindling plate, White
claims, the connected lever's winding readout, the whole placed workshop,
in-flight basket and collected cargo. The elevated workshop review camera and
accelerated travel are harness views; the interaction panels are the normal UI.

Build the GDExtension and import the pinned Godot project as described in
`game/README.md`, then run from the repository root:

```powershell
./tools/living_frontier_checks.ps1 -Native
./tools/living_frontier_checks.ps1 -Flow -Rendered -Restore -Regression
```

`-ContinueFrom1B` is an optional historical-migration replay, requiring the actual
published LF-1B journey checkpoint at `build/lf1/lf1b.json`; normal verification
does not require it. Unix `make -C tests/sim` runs both the original rules suite
and LF checks; `make -C tests/sim leyline` runs just LF. The engine's standard
`run_headless_checks.sh` includes the complete LF flow followed by fresh restart.
The shell runner passed `bash -n`; a Make dry run confirmed the default test
target retains the original suite and adds LF. The post-cleanup fresh-process
delivery passed all 15 checks again. Generated builds/imports are not committed.

The scripted player journey uses ordinary finite-resource work/pickup, catalogue
buttons, camera/input placement, aimed E, Foundry cells, fixture connections,
hand winding, cargo loading and landing collection. It supplies no material,
core, station, kit, unlock, drive or cargo. Separate temporary collider probes
block each of the three spans; they grant no resources or paid constructions.
The full-pack landing check gathers timber to the real 240 cap, spends it through
ordinary hand crafting, and collects only the available room before save/reload.
Fresh-process verification resumes the separately saved moving basket and collects
its exact ten wood once; later ticks cannot repeat the trip.

### Reproduce as a player

1. Launch the normal game with `-- --living-frontier --world-seed=77`; choose a
   class. Continue/F5/F9 use the separate experiment save.
2. Follow Red scars to its inclusion. Press E, perform four work actions, then
   collect 16 Salt. Make/place your normal bench, mason yard and basic forge.
   Gather eight clay and select **Fire Rustclay Brick with Red Salt** in the forge's
   ordinary catalogue: spend eight clay and two Salt for four bricks without a
   Catalyst. The original ordinary-fuel brick recipe remains available.
3. Work six more Red lots and carry the costly Ember recipe's full inputs to
   the forge: **96 Salt, 4 iron ingots, 8 charcoal**. Make the Faint Ember. The
   first smelt earns Ember; use the Foundry coordinates described under LF-1B.
4. Follow White clues to the other inclusion and collect one lot. Acquire actual
   Thrumroot and Stormglass from their finite sites. At the workbench assemble:

   | Fixture | Paid inputs |
   | --- | --- |
   | White Connection | 2 White Mineral, 2 wood |
   | Stormglass Lever | 1 Stormglass, 3 wood, 1 iron ingot |
   | Cargo Winch | 1 Thrumroot, 8 wood, 2 iron ingots |
   | Winch Landing | 6 wood, 1 iron ingot |

5. Place all four with B and the normal preview/click. At the drum choose its
   landing; at White choose the drum; at the lever choose White. On seed 77 the
   verified ground placements are drum **(504.5,31,506.5)**, landing
   **(518.5,31,506.5)**, White **(504.5,31,511.5)** and lever
   **(500.5,31,510.5)**. Equivalent clear supported local layouts also work.
6. Load wood at the drum, wind it once, and strike the lever. Observe the basket
   travel and collect at the landing. Save during travel and restart to finish
   the same trip. Wind again for a return. An unwound or disconnected route
   explains its refusal and spends no stored work.

### Limitations and owner review

This is an opt-in experiment on V6 geography, using primitive source/post art and
retaining pre-existing acquisition elsewhere. Existing direct wiring remains
usable; the new paid demonstration explicitly uses White. There are no unresolved
architecture or ownership decisions blocking Wave 1. No new tuning constitutes
owner acceptance of pacing or visual quality.

Owner playtests remain: discover both hosts without harness travel, judge four-step
effort and the 96-Salt price, spend raw material versus hoarding it, assess droughts
and the ten-minute formation cadence, build the circuit without test guidance,
and assess connection/post visibility with hostile AI active. The automated paid
journey uses the Warden and accelerated travel/work with hostile AI held; native
baseline forge routes cover all three classes. It does not establish time-to-fun
or ordinary human usability. Native fixtures and scripted player proof are separate.
The separate wolf/image-to-3D study is untouched. **Stop here: Wave 2 has not been
implemented or cleared; its review is separate.**

### Earlier slice evidence

LF-1A verification: `test_leyline` passes 81,776 checks, including 2,048 lots
over 256 seeds (77 winning lots, 188 initial manifestations without an Ember),
partial/full raw and rare claims, work interruption, bounded/blocked formation,
malformed/wrong-world restore, exact recipes and three generated source anchors.
The complete native rules suite passes **224,380 checks**. Affected engine
regressions pass: catalogue 52, contraptions 85, pressure workshop 60, loose drops
148, save recovery 175, weathered save 21, and wide-frontier pacing 319.

The final paid generated journey passes **250 checks**, with four further exact
fresh-process checks, including missing-ledger refusal and repeated binding. It
begins with an empty pack, gathers all ordinary inputs, crafts/places the bench,
yard and forge through their existing interfaces, extracts a Red lot, fires
4 paid bricks with zero Catalysts and restores its whole checkpoint. Rendered
1280×720 captures in `captures/lf1/` have been inspected: source work/released
claims and ordinary brick catalogue are legible after layout settles. The
reproducible runner is `tools/living_frontier_checks.ps1` (`-Native`, `-Flow`,
`-Rendered`, `-Restore`, `-Regression`); Unix native entry: `make -C tests/sim leyline`.

Native seeded checks are separate from paid player-flow and rendered review.
Travel/work in the scripted journey is accelerated
and hostile AI is held; it does not measure expedition pacing or certify enjoyment.

Owner review remains: discovery readability, four-step extraction effort, useful
raw spending versus Catalyst hoarding, rarity/formation cadence and visual finish.
No creature replacement, new campaign trigger, research/perfection system,
mandatory processing timer or Wave 2 component is part of this work.
