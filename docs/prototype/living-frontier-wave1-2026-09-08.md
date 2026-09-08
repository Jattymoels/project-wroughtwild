# Living Frontier Wave 1 — implementation and handoff

**Owner-authorised 8 September 2026. LF-1A/B implemented; LF-1C next.** Baseline `8401b1a`.
Scope: LF-1A, LF-1B, LF-1C, in that order. Wave 2 requires separate review.
The independent wolf/image-to-3D study is outside this change.

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

## Evidence and limitations

### LF-1B — ordinary manufacture and persistent use

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
