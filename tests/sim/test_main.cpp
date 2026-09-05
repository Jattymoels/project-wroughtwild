// Headless regression tests for the engine-neutral simulation core.
// Run via `make` in tests/sim; exits non-zero on any failure.

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <string>

#include <set>
#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/daycycle.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/foundry.h"
#include "wroughtwild/grammar.h"
#include "wroughtwild/items.h"
#include "wroughtwild/lattice.h"
#include "wroughtwild/loot.h"
#include "wroughtwild/save.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/trial.h"
#include "wroughtwild/tuning.h"
#include "wroughtwild/worldgen.h"

namespace {

int failures = 0;
int checks = 0;

void check(bool condition, const std::string& label) {
    ++checks;
    if (!condition) {
        ++failures;
        std::fprintf(stderr, "FAIL: %s\n", label.c_str());
    }
}

void checkNear(double actual, double expected, double tolerance, const std::string& label) {
    check(std::fabs(actual - expected) <= tolerance,
          label + " (actual " + std::to_string(actual) + ", expected " + std::to_string(expected) + ")");
}

using namespace wroughtwild;

void testTuningLoads(const tuning::Tuning& t) {
    check(t.crafting.findRecipe("iron_fittings") != nullptr, "crafting: iron_fittings recipe loads");
    check(t.crafting.findStation("forge_improved") != nullptr, "crafting: improved forge loads");
    check(t.crafting.findOrder("reinforce_old_mine") != nullptr, "crafting: mine order loads");
    check(t.skills.findCraftSkill("blacksmithing") != nullptr, "skills: blacksmithing loads");
    check(t.items.findBase("iron_chest_armour") != nullptr, "items: armour base loads");
    check(t.boons.findBoon("expanding_echo") != nullptr, "boons: expanding_echo loads");
    check(t.boons.offerRules.optionsPerOffer == 3, "boons: offer rules load");
    check(t.construction.findShape("cube") != nullptr, "construction: cube shape loads");
    check(t.construction.gridSizeMetres > 0.0 && t.construction.placementRangeMetres > 0.0,
          "construction: grid and range load");
}

void testOrderDemandAndStationChecks(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    check(!player.canBuildStation("forge_basic"), "station check: unaffordable when empty");
    player.inventory["wood"] = 15;
    player.inventory["iron_ore"] = 4;
    check(player.canBuildStation("forge_basic"), "station check: affordable with build_cost");
    check(player.inventory["wood"] == 15, "station check: checking pays nothing");
    check(!player.canBuildStation("forge_improved"), "station check: upgrade needs the base station");
    check(player.buildStation("forge_basic"), "station check: build after check succeeds");
    check(!player.canBuildStation("forge_basic"), "station check: already built is not buildable");

    check(player.recipeFeedsOpenOrder("iron_fittings"), "order demand: fittings feed the open mine order");
    check(!player.recipeFeedsOpenOrder("smelt_iron"), "order demand: ingots feed no order directly");
    check(!player.orderFulfilled("reinforce_old_mine"), "order demand: order starts open");
    player.inventory["iron_fittings"] = 24;
    check(player.fulfillOrder("reinforce_old_mine").fulfilled, "order demand: order fulfilled");
    check(player.orderFulfilled("reinforce_old_mine"), "order demand: order recorded as fulfilled");
    check(!player.recipeFeedsOpenOrder("iron_fittings"), "order demand: no open demand after fulfilment");
}

void testCombatNumbers(const tuning::Tuning& t) {
    // Real-time tunables load and the behaviour keys match the enemy roster.
    check(t.realtime.roundSeconds > 0.0, "realtime: round_seconds loads");
    for (const auto& enemy : t.world.enemies)
        check(t.realtime.findBehaviour(enemy.behaviour) != nullptr,
              "realtime: behaviour tunables exist for " + enemy.id);
    check(t.realtime.boss.breathTelegraphSeconds > 0.0, "realtime: boss telegraph loads");
    check(t.realtime.findBehaviour("fast")->aggroRangeM > 0.0, "realtime: aggro range loads");
    check(t.world.findSite("old_mine")->ambushRemovedByWorldEffect == "old_mine_reinforced",
          "world: mine ambush is removed by the reinforcement effect");
    check(t.world.findSite("valley_forest")->ambushRemovedByWorldEffect.empty(),
          "world: forest has no ambush removal effect");

    const tuning::CombatSkillDef* heavy = nullptr;
    const tuning::CombatSkillDef* area = nullptr;
    for (const auto& def : t.skills.combatSkills) {
        if (def.id == "prototype_heavy_strike") heavy = &def;
        if (def.id == "prototype_area_strike") area = &def;
    }
    check(heavy != nullptr && area != nullptr, "hit stream: prototype skills present");

    // Same seed, same calls, same numbers: the engine can replay a fight.
    combat::CombatMods none;
    combat::HitStream a(42), b(42);
    bool identical = true;
    for (int i = 0; i < 20; ++i)
        if (a.playerHit(*heavy, none, false) != b.playerHit(*heavy, none, false)) identical = false;
    check(identical, "hit stream: deterministic per seed");

    // Variance stays inside the round model's band.
    combat::HitStream c(7);
    bool inBand = true;
    for (int i = 0; i < 200; ++i) {
        double d = c.playerHit(*heavy, none, false);
        if (d < 28.0 * 0.9 - 1e-9 || d > 28.0 * 1.1 + 1e-9) inBand = false;
    }
    check(inBand, "hit stream: damage within +/-10% of base_damage");

    // concentrated_force: isolated targets take the damage multiplier.
    boons::RunState run;
    run.activeBoons.push_back("concentrated_force");
    combat::CombatMods focused = combat::buildMods(t.boons, run);
    check(focused.isolatedDamageMultiplier > 1.0 && focused.isolatedAreaMultiplier < 1.0,
          "mods: concentrated_force scales isolated damage up and area down");
    combat::HitStream d1(3), d2(3);
    checkNear(d1.playerHit(*area, focused, true) / d2.playerHit(*area, focused, false),
              focused.isolatedDamageMultiplier, 1e-9, "hit stream: isolation multiplier applied");

    // expanding_echo: every nth hit of the stream carries the repeat bonus.
    boons::RunState echoRun;
    echoRun.activeBoons.push_back("expanding_echo");
    combat::CombatMods echo = combat::buildMods(t.boons, echoRun);
    combat::HitStream e1(11), e2(11);
    double plain = 0.0, echoed = 0.0;
    for (int i = 0; i < echo.repeatHitCount; ++i) {
        plain = e1.playerHit(*heavy, none, false);
        echoed = e2.playerHit(*heavy, echo, false);
    }
    checkNear(echoed - plain, 28.0 * echo.repeatDamageMultiplier, 1e-9,
              "hit stream: nth hit adds the echo bonus");

    // Enemy hits go through the same mitigation the round model uses.
    stats::Equipment bare;
    stats::DerivedStats stats = stats::deriveStats(t.world.playerBase, bare);
    combat::HitStream f(5);
    double taken = f.enemyHit(40.0, "fire", stats, t.world.playerBase);
    check(taken >= 36.0 - 1e-9 && taken <= 44.0 + 1e-9, "hit stream: unresisted fire lands in band");
}

void testShapePlacement(const tuning::Tuning& t) {
    const auto* cube = t.construction.findShape("cube");
    economy::PlayerEconomy player(t);
    check(!player.canAffordPlacement("cube", "wood"), "construction: empty inventory cannot place");
    check(!player.payPlacement("cube", "wood"), "construction: unpaid placement refused");
    check(player.inventory["wood"] == 0, "construction: refused placement consumes nothing");

    player.inventory["wood"] = cube->materialCost * 2;
    check(player.canAffordPlacement("cube", "wood"), "construction: affordable with enough of the family");
    check(player.payPlacement("cube", "wood"), "construction: placement paid");
    check(player.inventory["wood"] == cube->materialCost, "construction: cost consumed once");

    const int expectedRefund =
        static_cast<int>(std::floor(cube->materialCost * t.construction.removalRefundFraction));
    check(player.refundRemoval("cube", "wood") == expectedRefund,
          "construction: refund follows removal_refund_fraction");
    check(player.inventory["wood"] == cube->materialCost + expectedRefund,
          "construction: refund returned to the same family");

    check(!player.payPlacement("no_such_shape", "wood"), "construction: unknown shape refused");
    check(player.refundRemoval("no_such_shape", "wood") == 0, "construction: unknown shape refunds nothing");

    // The trial's completion unlock gates the roof wedge; the floor slab is
    // free from the start (a roof is what makes a shelter).
    const auto* wedge = t.construction.findShape("roof_wedge");
    check(wedge != nullptr && wedge->requiresWorldEffect == t.trial.completionUnlock,
          "construction: roof wedge is gated by the trial completion unlock");
    check(wedge->form == "wedge" && wedge->oriented && wedge->element == "block",
          "construction: the wedge is an oriented block with its own form");
    const auto* slab = t.construction.findShape("floor_slab");
    check(slab != nullptr && slab->requiresWorldEffect.empty(), "construction: floor slab is available from the start");
    check(slab->sizeM[1] < slab->sizeM[0], "construction: slab is thinner than it is wide");
    check(slab->element == "floor" && cube->element == "block", "construction: slab lies on a face, cube fills a cell");
    const auto* panel = t.construction.findShape("wall_panel");
    check(panel != nullptr && panel->element == "wall" && !panel->oriented,
          "construction: wall panel stands on a vertical face and never turns");
    const auto* pillar = t.construction.findShape("pillar");
    check(pillar != nullptr && pillar->element == "post", "construction: pillar stands on a vertical edge");
    const auto* beam = t.construction.findShape("beam");
    check(beam != nullptr && beam->element == "beam", "construction: beam runs along a horizontal edge");
    check(std::abs(panel->sizeM[2] - slab->sizeM[1]) < 1e-9, "construction: wall and floor share one thickness");
    const auto* door = t.construction.findShape("door");
    check(door != nullptr && door->element == "wall" && door->form == "door" && door->cellsTall == 2 &&
              std::abs(door->sizeM[1] - 2.0) < 1e-9,
          "construction: the door is a two-cell-tall wall piece");
    const auto* stairs = t.construction.findShape("stairs");
    check(stairs != nullptr && stairs->form == "stairs" && stairs->oriented && cube->form == "box" && cube->cellsTall == 1,
          "construction: stairs are an oriented block; the cube defaults to a plain box");
    check(t.construction.latticeDivisions == 2, "construction: the registry runs at half cells");
    // Fine mode: every full-size basic shape has a half-scale twin of the
    // same element kind at half its size.
    int twins = 0;
    for (const auto& shape : t.construction.shapes) {
        if (!shape.fine) continue;
        const auto* full = t.construction.findShape(shape.fineOf);
        bool half = full != nullptr && full->element == shape.element;
        for (int i = 0; i < 3 && half; ++i)
            half = std::abs(shape.sizeM[i] - full->sizeM[i] * 0.5) < 1e-9;
        if (half) ++twins;
    }
    check(twins == 5 && t.construction.findShape("half_pillar")->fineOf == "pillar",
          "construction: five fine twins at exactly half their full-size shape");
    check(t.construction.findShape("half_cube")->materialCost * 8 > cube->materialCost,
          "construction: detail costs more than bulk - eight half cubes outprice a cube");
    player.inventory["wood"] = 10;
    check(!player.shapeUnlocked("roof_wedge") && !player.canAffordPlacement("roof_wedge", "wood"),
          "construction: wedge locked before the boss falls");
    check(player.shapeUnlocked("floor_slab") && player.canAffordPlacement("floor_slab", "wood"),
          "construction: slab placeable before the boss falls");
    player.recordWorldEffect(t.trial.completionUnlock);
    player.inventory["stone"] = 10;
    check(player.shapeUnlocked("roof_wedge") && !player.payPlacement("roof_wedge", "wood") &&
              player.payPlacement("roof_wedge", "stone"),
          "construction: wedge placeable after the unlock");
    check(t.crafting.basicTemper.property == "fire_resistance" && t.crafting.basicTemper.tier == 1,
          "crafting: basic temper config loads");
    check(t.construction.shapes.size() >= 9, "construction: prototype shape set has at least nine shapes");
    // Building families: paid in their source, gated by traits.
    const auto* timber = t.construction.findMaterial("wood");
    const auto* stone = t.construction.findMaterial("stone");
    const auto* iron = t.construction.findMaterial("iron");
    check(timber && stone && iron && iron->source == "iron_ingot" && stone->source == "stone",
          "materials: three families with their source items");
    check(timber->hasTrait("joinery") && !stone->hasTrait("joinery") && iron->hasTrait("metal"),
          "materials: traits load");
    check(player.shapeAllowsFamily("door", "wood") && player.shapeAllowsFamily("door", "iron") &&
              !player.shapeAllowsFamily("door", "stone"),
          "materials: a door takes joinery - timber or iron, never stone");
    check(!player.shapeAllowsFamily("roof_wedge", "wood") && player.shapeAllowsFamily("roof_wedge", "stone"),
          "materials: the cut stone wedge is masonry only");
    const auto* girder = t.construction.findShape("girder");
    check(girder && girder->cellsLong == 2 && player.shapeAllowsFamily("girder", "iron") &&
              !player.shapeAllowsFamily("girder", "wood"),
          "materials: the two-cell girder needs metal");
    player.inventory["stone"] = 4;
    player.inventory["iron_ingot"] = 4;
    check(player.canAffordPlacement("cube", "stone") && player.payPlacement("cube", "stone") &&
              player.inventory["stone"] == 4 - cube->materialCost,
          "materials: a stone cube is paid in stone");
    check(!player.canAffordPlacement("door", "stone"), "materials: a stone door cannot be paid for at all");
    check(player.payPlacement("girder", "iron") && player.inventory["iron_ingot"] == 4 - girder->materialCost,
          "materials: a girder is paid in ingots");
    player.refundRemoval("girder", "iron");
    check(player.inventory["iron_ingot"] > 4 - girder->materialCost, "materials: refunds return the source item");
    check(!player.canAffordPlacement("cube", "no_such_family"), "materials: an unknown family is refused");
    int unlockedFromStart = 0;
    for (const auto& shape : t.construction.shapes)
        if (shape.requiresWorldEffect.empty()) ++unlockedFromStart;
    check(unlockedFromStart >= 7, "construction: all but the wedge are available before the trial");
}

void testSkillCurve(const tuning::Tuning& t) {
    const auto* bs = t.skills.findCraftSkill("blacksmithing");
    check(economy::levelForXp(*bs, 0) == 1, "skills: level 1 at 0 xp");
    check(economy::levelForXp(*bs, 49) == 1, "skills: level 1 just below threshold");
    check(economy::levelForXp(*bs, 50) == 2, "skills: level 2 at 50 xp");
    check(economy::levelForXp(*bs, bs->xpRequiredByLevel.back()) == 5,
          "skills: level 5 at the curve's final threshold");
    check(economy::levelForXp(*bs, 10000) == 5, "skills: clamped to prototype maximum");
}

void testCraftingGates(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    player.inventory["iron_ingot"] = 2;
    player.inventory["wood"] = 50; // fuel for the forge

    // No forge yet: the facility gate must block on its own.
    auto result = player.craft("iron_fittings");
    check(!result.crafted && result.failure.stationUnavailable, "craft: station gate blocks");

    player.addAvailableStation("forge_basic");
    result = player.craft("iron_fittings");
    check(result.crafted, "craft: succeeds with station, skill and inputs");
    check(player.inventory["iron_ingot"] == 0, "craft: inputs consumed");
    check(player.inventory["iron_fittings"] == 4, "craft: outputs produced");
    check(result.xpGranted == 8, "craft: base xp granted");
    check(player.skillXp("blacksmithing") == 8, "craft: xp recorded on skill");

    // Armour needs the improved forge AND blacksmithing 4; both gates report.
    player.inventory["iron_ingot"] = 12;
    result = player.craft("iron_chest_armour");
    check(!result.crafted && result.failure.stationUnavailable && result.failure.skillTooLow,
          "craft: independent gates both report");

    result = player.craft("nonexistent_recipe");
    check(!result.crafted && result.failure.unknownRecipe, "craft: unknown recipe refused");
}

void testRepetitionDecay(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    player.addAvailableStation("forge_basic");
    player.inventory["iron_ingot"] = 2000;
    player.inventory["wood"] = 5000; // fuel

    // First full_xp_repetitions (5) crafts grant full XP.
    for (int i = 0; i < 5; ++i) {
        auto r = player.craft("iron_fittings");
        checkNear(r.xpMultiplier, 1.0, 1e-9, "decay: full xp within grace repetitions");
    }
    // Sixth non-order craft decays (provisional harmonic rule: 5/6).
    auto sixth = player.craft("iron_fittings");
    checkNear(sixth.xpMultiplier, 5.0 / 6.0, 1e-9, "decay: sixth craft decays");
    check(sixth.xpGranted < 8, "decay: granted xp reduced");

    // Multiplier never falls below the tuned minimum.
    for (int i = 0; i < 200; ++i) player.craft("iron_fittings");
    auto late = player.craft("iron_fittings");
    check(late.xpMultiplier >= t.crafting.repetitionDecay.minimumMultiplier - 1e-9,
          "decay: floored at minimum multiplier");

    // Order-directed crafting ignores decay and does not advance the counter.
    auto forOrder = player.craft("iron_fittings", /*forOrder=*/true);
    checkNear(forOrder.xpMultiplier, 1.0, 1e-9, "decay: order crafting keeps full xp");
}

void testOrderFulfilment(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    player.addAvailableStation("forge_basic");
    player.inventory["iron_ingot"] = 12; // 6 crafts x 2 ingots -> 24 fittings
    player.inventory["wood"] = 20;        // fuel

    for (int i = 0; i < 6; ++i) {
        auto r = player.craft("iron_fittings", /*forOrder=*/true);
        check(r.crafted, "order: craft toward order succeeds");
    }
    check(player.inventory["iron_fittings"] == 24, "order: 24 fittings produced");
    int xpBefore = player.skillXp("blacksmithing");

    auto result = player.fulfillOrder("reinforce_old_mine");
    check(result.fulfilled, "order: fulfilment succeeds");
    check(player.inventory["iron_fittings"] == 0, "order: output genuinely consumed");
    check(player.currency["vanguard"] == 3, "order: the mine pays three Vanguards, the kind of its work");
    check(player.skillXp("blacksmithing") == xpBefore + 60, "order: xp reward feeds skill");
    check(player.worldEffectActive("old_mine_reinforced"), "order: world effect recorded");

    auto again = player.fulfillOrder("reinforce_old_mine");
    check(!again.fulfilled && again.alreadyFulfilled, "order: cannot fulfil twice");
}

void testSalvage(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    player.addAvailableStation("forge_basic");
    player.inventory["iron_ingot"] = 2;
    player.inventory["wood"] = 1; // exactly the fuel, so salvage maths stay exact
    player.craft("iron_fittings");

    // One fitting embodies 0.5 ingot; salvage returns floor(0.5 * 0.5) = 0.
    check(player.salvage("iron_fittings"), "salvage: consumes one output unit");
    check(player.inventory["iron_fittings"] == 3, "salvage: output count reduced");
    check(player.inventory["iron_ingot"] == 0, "salvage: sub-unit return floors to zero");
}

void testItemRolls(const tuning::Tuning& t) {
    auto a = items::rollItem(t.items, "iron_chest_armour", 1, 2, 12345);
    auto b = items::rollItem(t.items, "iron_chest_armour", 1, 2, 12345);
    check(a.rolledProperties.size() == b.rolledProperties.size(), "items: same seed, same count");
    for (size_t i = 0; i < a.rolledProperties.size(); ++i) {
        check(a.rolledProperties[i].propertyId == b.rolledProperties[i].propertyId,
              "items: same seed, same property");
        checkNear(a.rolledProperties[i].value, b.rolledProperties[i].value, 0.0,
                  "items: same seed, same value");
    }

    // Allowed tags: armour permits defence/life/resistance, never offence.
    for (int seed = 0; seed < 50; ++seed) {
        auto item = items::rollItem(t.items, "iron_chest_armour", 1, 3, seed);
        for (const auto& rolled : item.rolledProperties) {
            check(rolled.propertyId != "area_size", "items: offence tag excluded from armour");
            const tuning::PropertyDef* def = nullptr;
            for (const auto& d : t.items.modifiers)
                if (d.id == rolled.propertyId) def = &d;
            check(def != nullptr, "items: rolled property is defined");
            for (const auto& tier : def->tiers)
                if (tier.tier == rolled.tier)
                    check(rolled.value >= tier.minimum && rolled.value <= tier.maximum,
                          "items: value within tier bounds");
        }
    }

    check(items::propertyTotal(a, "armour") == 20.0, "items: implicit armour preserved");
}

void testBoons(const tuning::Tuning& t) {
    boons::BuildTags areaBuild = {"attack", "physical", "area"};
    boons::BuildTags noAreaBuild = {"attack", "physical", "single_target"};
    boons::RunState run;

    // Tag compatibility.
    const auto* echo = t.boons.findBoon("expanding_echo");
    check(boons::isCompatible(*echo, areaBuild, run), "boons: area boon fits area build");
    check(!boons::isCompatible(*echo, noAreaBuild, run), "boons: area boon refused without tag");

    // Weakness-gated boon requires the weakness to be active first.
    const auto* harvest = t.boons.findBoon("pressure_harvest");
    check(!boons::isCompatible(*harvest, areaBuild, run), "boons: weakness gate blocks");
    run.acceptWeakness("hastened_enemies");
    check(boons::isCompatible(*harvest, areaBuild, run), "boons: weakness gate opens");

    // Offers are deterministic, compatible-only, and never duplicate owned boons.
    auto offer1 = boons::generateOffer(t.boons, areaBuild, run, 777);
    auto offer2 = boons::generateOffer(t.boons, areaBuild, run, 777);
    check(offer1.size() == offer2.size(), "boons: same seed, same offer size");
    for (size_t i = 0; i < offer1.size(); ++i)
        check(offer1[i]->id == offer2[i]->id, "boons: same seed, same offer");
    for (const auto* boon : offer1)
        check(boons::isCompatible(*boon, areaBuild, run), "boons: offered boons are compatible");

    check(boons::acceptBoon(t.boons, "expanding_echo", areaBuild, run), "boons: accept succeeds");
    check(!boons::acceptBoon(t.boons, "expanding_echo", areaBuild, run), "boons: no duplicate accept");
    auto offer3 = boons::generateOffer(t.boons, areaBuild, run, 777);
    for (const auto* boon : offer3)
        check(boon->id != "expanding_echo", "boons: owned boon not re-offered");

    checkNear(boons::rewardMultiplier(t.boons, run), 1.15, 1e-9, "boons: weakness reward multiplier");

    // Persistent vs temporary separation: clearing the run removes every
    // trial effect while the persistent economy is untouched by RunState.
    run.clear();
    check(run.activeBoons.empty() && run.activeWeaknesses.empty(), "boons: run clear removes all");
    checkNear(boons::rewardMultiplier(t.boons, run), 1.0, 1e-9, "boons: multiplier resets");
}

// The vertical-slice economy spine end to end: gather -> craft -> order ->
// level up -> upgrade forge -> craft armour. Proves the loop is completable
// with current tuning numbers alone.
void testVerticalSliceSpine(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    player.addAvailableStation("forge_basic");
    player.inventory["iron_ingot"] = 12;
    player.inventory["wood"] = 6000; // fuel for the whole spine

    for (int i = 0; i < 6; ++i) player.craft("iron_fittings", /*forOrder=*/true);
    player.fulfillOrder("reinforce_old_mine");
    // 6 crafts x 8 xp + 60 order xp = 108 xp -> level 2.
    check(player.skillLevel("blacksmithing") == 2, "spine: order work reaches level 2");

    // Continue useful crafting until blacksmithing 4 unlocks the armour recipe.
    player.inventory["iron_ingot"] = 2000;
    int guard = 0;
    while (player.skillLevel("blacksmithing") < 4 && guard++ < 10000)
        player.craft("iron_fittings", /*forOrder=*/true);
    check(player.skillLevel("blacksmithing") == 4, "spine: blacksmithing reaches 4");

    player.addAvailableStation("forge_improved"); // the forge upgrade
    player.inventory["iron_ingot"] = 12;
    auto armour = player.craft("iron_chest_armour");
    check(armour.crafted, "spine: armour craftable after upgrade and levelling");
    check(player.inventory["iron_chest_armour"] == 0 && player.packItems.size() == 1 &&
              player.packItems.front().baseId == "iron_chest_armour",
          "spine: armour produced as rolled gear in the pack (D-019)");
}

void testStatsAndMitigation(const tuning::Tuning& t) {
    stats::Equipment bare;
    auto base = stats::deriveStats(t.world.playerBase, bare);
    check(base.maxLife == 100.0, "stats: base life from world.json");
    checkNear(stats::mitigateDamage(40.0, "fire", base, t.world.playerBase), 40.0, 1e-9,
              "stats: no resistance, full fire damage");

    stats::Equipment armoured;
    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    armour.implicitProperties["armour"] = 20.0;
    armour.rolledProperties.push_back({"fire_resistance", 2, 20.0});
    armour.rolledProperties.push_back({"max_life", 1, 10.0});
    armoured.slots["chest"] = armour;

    auto derived = stats::deriveStats(t.world.playerBase, armoured);
    check(derived.maxLife == 110.0, "stats: life property adds");
    checkNear(derived.fireResistancePercent, 20.0, 1e-9, "stats: fire resistance sums");
    checkNear(stats::mitigateDamage(40.0, "fire", derived, t.world.playerBase), 32.0, 1e-9,
              "stats: fire damage reduced by resistance");
    checkNear(stats::mitigateDamage(12.0, "physical", derived, t.world.playerBase),
              12.0 * (1.0 - 20.0 / 120.0), 1e-9, "stats: armour formula");

    stats::Equipment stacked = armoured;
    stacked.slots["chest"].rolledProperties.push_back({"fire_resistance", 2, 200.0});
    auto capped = stats::deriveStats(t.world.playerBase, stacked);
    checkNear(capped.fireResistancePercent, t.world.playerBase.resistanceCapPercent, 1e-9,
              "stats: resistance capped");
}

void testCatalystTemper(const tuning::Tuning& t) {
    const auto* process = t.crafting.findCatalystProcess("ember_catalyst_tempering");
    check(process != nullptr, "temper: catalyst process loads");

    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    armour.implicitProperties["armour"] = 20.0;

    auto low = items::catalystTemper(t.items, *process, armour, 4, 1);
    check(!low.applied && low.skillTooLow, "temper: skill gate holds");

    // Domain guaranteed, magnitude bounded, floor raised by skill.
    const auto* def = &t.items.modifiers[0];
    for (const auto& d : t.items.modifiers)
        if (d.id == "fire_resistance") def = &d;
    double t2min = 0, t2max = 0;
    for (const auto& tier : def->tiers)
        if (tier.tier == 2) { t2min = tier.minimum; t2max = tier.maximum; }
    double floorValue = t2min + process->minimumRollFractionAtSkill * (t2max - t2min);

    for (uint64_t seed = 0; seed < 50; ++seed) {
        items::ItemInstance fresh = armour;
        auto result = items::catalystTemper(t.items, *process, fresh, 5, seed);
        check(result.applied, "temper: applies at required skill");
        check(result.rolledValue >= floorValue - 1e-9 && result.rolledValue <= t2max + 1e-9,
              "temper: roll within skill floor and tier maximum");
        check(items::propertyTotal(fresh, "fire_resistance") == result.rolledValue,
              "temper: property landed on the item");
    }

    // Preservation: an existing better roll is never downgraded.
    items::ItemInstance blessed = armour;
    blessed.rolledProperties.push_back({"fire_resistance", 2, t2max});
    auto preserved = items::catalystTemper(t.items, *process, blessed, 5, 3);
    check(preserved.applied && items::propertyTotal(blessed, "fire_resistance") >= t2max - 1e-9,
          "temper: never downgrades an existing roll");

    auto a = items::catalystTemper(t.items, *process, armour, 5, 99);
    items::ItemInstance again;
    again.baseId = "iron_chest_armour";
    auto b = items::catalystTemper(t.items, *process, again, 5, 99);
    checkNear(a.rolledValue, b.rolledValue, 0.0, "temper: deterministic per seed");
}

void testStationConstruction(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    check(!player.buildStation("forge_basic"), "build: cannot build without materials");
    player.inventory["wood"] = 15;
    player.inventory["iron_ore"] = 4;
    check(player.buildStation("forge_basic"), "build: basic forge built");
    check(player.inventory["wood"] == 0 && player.inventory["iron_ore"] == 0,
          "build: materials consumed");
    check(player.stationAvailable("forge_basic"), "build: station available");

    check(!player.buildStation("forge_improved"), "build: upgrade needs payment");
    player.currency["vanguard"] = 2;
    player.inventory["iron_fittings"] = 6;
    check(!player.buildStation("forge_improved"), "build: upgrade wants the fen's bog iron too (Wave 7)");
    player.inventory["bog_iron"] = 3;
    check(player.buildStation("forge_improved"), "build: upgrade paid from the purse + goods");
    check(player.currency["vanguard"] == 0 && player.inventory["iron_fittings"] == 0 && player.inventory["bog_iron"] == 0,
          "build: upgrade cost consumed");
}

void testCombat(const tuning::Tuning& t) {
    stats::Equipment bare;
    auto baseStats = stats::deriveStats(t.world.playerBase, bare);
    combat::CombatMods noMods;

    // Determinism: identical inputs replay identically.
    auto a = combat::runEncounter(t, baseStats, noMods, {"ember_whelp", "ember_whelp"}, 42,
                                  combat::autoPolicy);
    auto b = combat::runEncounter(t, baseStats, noMods, {"ember_whelp", "ember_whelp"}, 42,
                                  combat::autoPolicy);
    check(a.victory == b.victory && a.rounds == b.rounds &&
              a.playerLifeRemaining == b.playerLifeRemaining,
          "combat: deterministic per seed");
    check(a.victory, "combat: bare player clears two whelps");
    check(a.rounds >= 5, "combat: and it takes a while (D-020 long fights, " + std::to_string(a.rounds) + " rounds)");
    {
        const auto* whelp = t.world.findEnemy("ember_whelp");
        const auto* heavy = t.skills.findCombatSkill("prototype_heavy_strike");
        check(whelp && heavy && whelp->maxLife > 2.0 * heavy->numbers.at("base_damage"),
              "combat: a day-one whelp takes three heavy blows, not two");
        for (const auto& e : t.world.enemies)
            check(e.damage <= 8.0, "combat: no ordinary mob hits harder than eight (" + e.id + ")");
    }

    // Hastened enemies (weakness) make the same fight strictly more painful.
    combat::CombatMods hastened;
    hastened.enemySpeedMultiplier = 1.2;
    auto fast = combat::runEncounter(t, baseStats, hastened,
                                     {"ash_hound", "ash_hound", "ash_hound"}, 7,
                                     combat::autoPolicy);
    auto slow = combat::runEncounter(t, baseStats, noMods,
                                     {"ash_hound", "ash_hound", "ash_hound"}, 7,
                                     combat::autoPolicy);
    check(fast.playerLifeRemaining <= slow.playerLifeRemaining,
          "combat: hastened enemies deal at least as much damage");

    // Concentrated force speeds up a lone-target fight.
    combat::CombatMods concentrated;
    concentrated.isolatedDamageMultiplier = 1.45;
    auto focused = combat::runEncounter(t, baseStats, concentrated, {"ember_whelp"}, 11,
                                        combat::autoPolicy);
    auto normal = combat::runEncounter(t, baseStats, noMods, {"ember_whelp"}, 11,
                                       combat::autoPolicy);
    check(focused.rounds <= normal.rounds, "combat: isolated damage boon kills faster");

    check(combat::buildMods(t.boons, boons::RunState{}).enemySpeedMultiplier == 1.0,
          "combat: empty run state builds neutral mods");
    boons::RunState run;
    run.acceptWeakness("hastened_enemies");
    auto mods = combat::buildMods(t.boons, run);
    checkNear(mods.enemySpeedMultiplier, 1.2, 1e-9, "combat: weakness speed op interpreted");
    checkNear(mods.rewardQuantityMultiplier, 1.15, 1e-9, "combat: weakness reward op interpreted");
}

void testTrialContracts(const tuning::Tuning& t) {
    stats::Equipment bare;
    auto baseStats = stats::deriveStats(t.world.playerBase, bare);
    boons::BuildTags tags = {"attack", "physical", "area", "single_target", "movement"};

    // Death contract: deposited inventory always comes home; run materials
    // are lost, recovered catalysts are kept; boons never persist.
    {
        economy::PlayerEconomy player(t);
        player.inventory["wood"] = 9;
        trial::TrialSession session(t, player, tags, 5);
        check(player.inventory.empty(), "trial: inventory deposited at the gate");

        auto alwaysDie = [](const combat::CombatView&) { return combat::Action{-1, 0}; };
        session.enterRoom(0, baseStats, alwaysDie);
        check(session.finished() && session.playerDied(), "trial: standing still gets you killed");
        check(player.inventory["wood"] == 9, "trial: deposited inventory restored after death");
        check(session.runState().activeBoons.empty(), "trial: no boons survive the run");
    }

    // Full successful run driven by the auto policy, tempered armour equipped.
    {
        economy::PlayerEconomy player(t);
        player.inventory["wood"] = 3;

        // Gear up exactly the way a player would: craft-equivalent armour,
        // then catalyst-temper it with the real process at skill 5.
        stats::Equipment geared;
        items::ItemInstance armour;
        armour.baseId = "iron_chest_armour";
        armour.implicitProperties["armour"] = 20.0;
        const auto* process = t.crafting.findCatalystProcess("ember_catalyst_tempering");
        check(process != nullptr, "trial: temper process available");
        check(items::catalystTemper(t.items, *process, armour, 5, 77).applied,
              "trial: armour tempered for the attempt");
        geared.slots["chest"] = armour;
        auto gearedStats = stats::deriveStats(t.world.playerBase, geared);

        trial::TrialSession session(t, player, tags, 1234);
        // Stage 0: take the boon room, accept the first offered boon.
        auto outcome = session.enterRoom(0, gearedStats, combat::autoPolicy);
        check(outcome.combat.victory, "trial: stage 0 cleared");
        check(outcome.rewardType == "boon_offer" && !outcome.boonOffer.empty(),
              "trial: boon offer presented");
        check(session.acceptBoonFromOffer(outcome.boonOffer.front()->id),
              "trial: offered boon accepted");
        // Stage 1: materials room pays out.
        outcome = session.enterRoom(1, gearedStats, combat::autoPolicy);
        check(outcome.combat.victory && outcome.rewardType == "materials",
              "trial: materials room cleared");
        // Stage 2: catalyst shrine.
        outcome = session.enterRoom(0, gearedStats, combat::autoPolicy);
        check(outcome.catalystRecovered, "trial: catalyst recovered");
        check(session.canBankAndExit(), "trial: bank-out point reached");
        // Push to the boss anyway.
        outcome = session.enterRoom(0, gearedStats, combat::autoPolicy);
        check(outcome.combat.victory, "trial: tempered build defeats the boss");
        check(session.bossDefeated() && session.finished(), "trial: completion recorded");
        check(player.inventory["wood"] == 3, "trial: deposit restored after victory");
        check(player.inventory[t.trial.catalystItem] == 1, "trial: catalyst banked");
        check(player.inventory["iron_ingot"] >= 4, "trial: materials banked");
        // The curio and the lock (Wave 8 slice 2): the Tyrant's fall leaves
        // its heart, not the era; the cairn on the hill takes it.
        check(player.inventory["tyrant_heart"] == 1 && !player.worldEffectActive(t.trial.completionUnlock),
              "trial: the Tyrant's heart banked, the deep still asleep");
        check(player.landmarkWants("hill_cairn") == "tyrant_heart" && player.curioHints().size() == 1 &&
                  !player.setCurio("drowned_altar") && player.setCurio("hill_cairn"),
              "trial: the cairn takes the heart, the altar does not");
        check(player.worldEffectActive(t.trial.completionUnlock) && player.inventory["tyrant_heart"] == 0 && player.curioHints().empty(),
              "trial: set in the cairn, the deep wakes and the heart is spent");
    }
}

void testTrialRealtimeHost(const tuning::Tuning& t) {
    boons::BuildTags tags = {"attack", "physical", "area", "single_target", "movement"};

    // beginRoom/resolveRoom drive the same session as enterRoom, but the
    // host fights in between.
    economy::PlayerEconomy player(t);
    player.inventory["wood"] = 4;
    trial::TrialSession session(t, player, tags, 99);

    auto start = session.beginRoom(0);
    check(start.started && start.roomId == "ember_nests" && start.encounter.size() == 2,
          "host trial: beginRoom hands back the room's encounter");
    check(start.seed != 0 && session.roomInProgress(), "host trial: room in progress with a seed");
    check(!session.beginRoom(1).started, "host trial: cannot begin a second room mid-fight");

    auto outcome = session.resolveRoom(true);
    check(outcome.rewardType == "boon_offer" && !outcome.boonOffer.empty(),
          "host trial: victory prepares the room's reward");
    check(!session.roomInProgress() && session.currentStageIndex() == 1,
          "host trial: stage advances after resolution");
    check(session.acceptBoonFromOffer(outcome.boonOffer.front()->id), "host trial: boon accepted");
    check(session.currentMods().repeatHitCount > 0 || session.currentMods().isolatedDamageMultiplier > 1.0,
          "host trial: accepted boon changes the mods the host reads");

    check(session.beginRoom(1).started, "host trial: materials room begun");
    outcome = session.resolveRoom(true);
    check(outcome.rewardType == "materials" && outcome.materials.count("iron_ingot") == 1,
          "host trial: materials room pays into run loot");

    // Defeat resolved by the host applies the death contract.
    check(session.beginRoom(0).started, "host trial: shrine room begun");
    outcome = session.resolveRoom(false);
    check(session.finished() && session.playerDied(), "host trial: host-reported defeat ends the run");
    check(player.inventory["wood"] == 4 && player.inventory.count("iron_ingot") == 0,
          "host trial: deposit restored, run materials lost on death");

    // Abandoning mid-run is a failure with the same contract.
    economy::PlayerEconomy quitter(t);
    quitter.inventory["wood"] = 2;
    trial::TrialSession quitRun(t, quitter, tags, 5);
    quitRun.beginRoom(0);
    quitRun.abandon();
    check(quitRun.finished() && quitRun.playerDied() && quitter.inventory["wood"] == 2,
          "host trial: abandon applies the death contract and returns the deposit");
}

void testSaveLoad(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    player.inventory["wood"] = 15;
    player.inventory["iron_ore"] = 4;
    player.buildStation("forge_basic");
    player.inventory["iron_ingot"] = 4;
    player.craft("iron_fittings");
    player.recordWorldEffect("old_mine_reinforced");

    save::SaveGame game;
    game.economy = player.exportState();
    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    armour.implicitProperties["armour"] = 20.0;
    armour.rolledProperties.push_back({"fire_resistance", 2, 17.25});
    game.equipment.slots["chest"] = armour;
    game.extra["location"] = "camp";

    save::SaveGame loaded = save::fromJson(save::toJson(game));
    check(loaded.economy.inventory == game.economy.inventory, "save: inventory round-trips");
    check(loaded.economy.skillXp == game.economy.skillXp, "save: skill xp round-trips");
    check(loaded.economy.craftCounts == game.economy.craftCounts,
          "save: repetition counters round-trip");
    check(loaded.economy.availableStations == game.economy.availableStations,
          "save: stations round-trip");
    check(loaded.economy.worldEffects == game.economy.worldEffects,
          "save: world effects round-trip");
    check(loaded.extra.at("location") == "camp", "save: extra fields round-trip");

    const auto& item = loaded.equipment.slots.at("chest");
    check(item.baseId == "iron_chest_armour", "save: equipment base round-trips");
    checkNear(items::propertyTotal(item, "fire_resistance"), 17.25, 1e-12,
              "save: rolled values round-trip exactly");

    economy::PlayerEconomy restored(t);
    restored.importState(loaded.economy);
    check(restored.skillXp("blacksmithing") == player.skillXp("blacksmithing"),
          "save: imported economy matches");
    check(restored.stationAvailable("forge_basic"), "save: imported station usable");
}


void testFuelGate(const tuning::Tuning& t) {
    check(t.crafting.fuels.at("wood") == 1 && t.crafting.fuels.at("charcoal") == 4,
          "fuel: fuel values load");

    economy::PlayerEconomy player(t);
    player.addAvailableStation("forge_basic");
    // Smelting needs 2 ore + 1 wood as inputs AND 2 fuel; exactly the input
    // wood is not enough - committed inputs cannot double as fuel.
    player.inventory["iron_ore"] = 2;
    player.inventory["wood"] = 1;
    check(!player.fuelMet("smelt_iron"), "fuel: input wood does not double as fuel");
    auto starved = player.craft("smelt_iron");
    check(!starved.crafted && starved.failure.missingFuel, "fuel: craft blocked without fuel");
    check(player.inventory["iron_ore"] == 2 && player.inventory["wood"] == 1,
          "fuel: blocked craft consumes nothing");

    player.inventory["wood"] = 3; // 1 input + 2 fuel
    check(player.fuelMet("smelt_iron"), "fuel: met with input plus fuel wood");
    auto smelted = player.craft("smelt_iron");
    check(smelted.crafted, "fuel: craft succeeds with fuel");
    check(player.inventory["wood"] == 0, "fuel: fuel burned");
    check(player.inventory["iron_ingot"] == 1, "fuel: output produced");

    // Charcoal covers fuel at 4x value; wood burns first when both are held.
    player.inventory["iron_ore"] = 4;
    player.inventory["wood"] = 2;     // covers input 1 + fuel 1
    player.inventory["charcoal"] = 1; // covers the remaining fuel
    auto mixed = player.craft("smelt_iron");
    check(mixed.crafted, "fuel: mixed fuels accepted");
    check(player.inventory["wood"] == 0, "fuel: cheap wood burned first");
    check(player.inventory["charcoal"] == 0, "fuel: charcoal burned for the remainder");

    // Charcoal alone: one unit over-covers a 2-fuel smelt (furnace wastes heat).
    player.inventory["iron_ore"] = 2;
    player.inventory["wood"] = 1;
    player.inventory["charcoal"] = 1;
    auto rich = player.craft("smelt_iron");
    check(rich.crafted && player.inventory["charcoal"] == 0,
          "fuel: charcoal alone covers the burn");
}

void testHandCraftingAndKits(const tuning::Tuning& t) {
    economy::PlayerEconomy player(t);
    // The workbench kit is hand-craftable with no station at all.
    player.inventory["wood"] = 8;
    auto bench = player.craft("workbench_kit");
    check(bench.crafted, "kits: workbench kit hand-crafts with no station");
    check(player.inventory["workbench_kit"] == 1, "kits: kit lands in the pack");

    // Placing the kit founds the station (the engine consumes the item and
    // calls addAvailableStation; here we exercise the mapping).
    const auto* station = t.crafting.findStationForKit("workbench_kit");
    check(station != nullptr && station->id == "workbench", "kits: workbench kit maps to workbench");
    check(t.crafting.findStationForKit("forge_kit") != nullptr &&
              t.crafting.findStationForKit("forge_kit")->id == "forge_basic",
          "kits: forge kit maps to basic forge");
    check(t.crafting.findStationForKit("iron_ingot") == nullptr, "kits: non-kit items map to nothing");

    player.addAvailableStation(station->id);
    // The forge kit needs the workbench, a timber frame jointed there
    // (the bench kept alive, Wave 5 item 11) and the two stone families.
    auto blocked = player.craft("forge_kit");
    check(!blocked.crafted && blocked.failure.missingInputs, "kits: forge kit needs materials");
    player.inventory["wood"] = 12;
    player.inventory["stone"] = 8;
    player.inventory["iron_ore"] = 4;
    check(!player.craft("forge_kit").crafted, "kits: timber alone is no frame - the bench joints one first");
    check(player.craft("timber_frame").crafted && player.inventory["timber_frame"] == 1 && player.inventory["wood"] == 2,
          "kits: a timber frame from ten timber at the bench");
    auto forge = player.craft("forge_kit");
    check(forge.crafted && player.inventory["forge_kit"] == 1 && player.inventory["timber_frame"] == 0, "kits: forge kit assembles on the frame at the bench");
    check(player.inventory["stone"] == 0, "kits: stone family consumed");
    check(player.craft("timber_wedges_bulk").crafted == false, "kits: a bundle of wedges wants three timber");
    player.inventory["wood"] = 3;
    check(player.craft("timber_wedges_bulk").crafted && player.inventory["timber_wedge"] == 8, "kits: the bench bundles eight wedges from three timber");
}

void testEnemyLoot(const tuning::Tuning& t) {
    // Determinism: the same kill seed always drops the same loot.
    auto a = loot::rollEnemyLoot(t.world, "stone_husk", 99);
    auto b = loot::rollEnemyLoot(t.world, "stone_husk", 99);
    check(a == b, "loot: deterministic per seed");
    check(loot::rollEnemyLoot(t.world, "nobody", 1).empty(), "loot: unknown enemy drops nothing");

    // Bounds and rates over many kills: guaranteed entries always drop,
    // counts stay in [min, max], chances land near their tuned values.
    int husks = 2000, stoneDrops = 0, ironDrops = 0;
    bool boundsOk = true;
    for (int seed = 0; seed < husks; ++seed) {
        auto drops = loot::rollEnemyLoot(t.world, "stone_husk", seed);
        if (drops.count("split_stone")) {
            ++stoneDrops;
            if (drops["split_stone"] < 2 || drops["split_stone"] > 4) boundsOk = false;
        }
        if (drops.count("iron_ore")) ++ironDrops;
    }
    check(stoneDrops == husks, "loot: certain drops always arrive");
    check(boundsOk, "loot: counts stay inside min..max");
    double ironRate = static_cast<double>(ironDrops) / husks;
    check(ironRate > 0.30 && ironRate < 0.40, "loot: chance drops near their tuned rate");
}

void testWorldgen(const tuning::Tuning& t) {
    // Determinism: one seed, one world.
    auto a = worldgen::generate(t, 7);
    auto b = worldgen::generate(t, 7);
    check(a.cells.size() == b.cells.size() && a.nodes.size() == b.nodes.size() &&
              a.packs.size() == b.packs.size() && a.spawnX == b.spawnX && a.gateX == b.gateX,
          "worldgen: deterministic per seed");
    bool sameCells = true;
    for (size_t i = 0; i < a.cells.size(); ++i)
        if (a.cells[i].height != b.cells[i].height || a.cells[i].biomeIndex != b.cells[i].biomeIndex)
            sameCells = false;
    check(sameCells, "worldgen: identical terrain per seed");

    auto c = worldgen::generate(t, 8);
    bool differs = c.spawnX != a.spawnX || c.gateX != a.gateX || c.nodes.size() != a.nodes.size();
    if (!differs)
        for (size_t i = 0; i < a.cells.size() && !differs; ++i)
            if (a.cells[i].height != c.cells[i].height) differs = true;
    check(differs, "worldgen: different seeds differ");

    // The block field (Wave 3 world slice 1): bedrock floor, strata under a
    // surface block, caves carved strictly underground with a few breach
    // entrances, and every node standing on real ground.
    check(a.depth == t.worldgen.map.worldDepth &&
              a.blocks.size() == static_cast<size_t>(a.width) * a.height * a.depth,
          "worldgen: block field sized to the map");
    check(a.blocks == b.blocks, "worldgen: identical blocks per seed");
    bool bedrockGood = true;
    int columns = 0, caveCells = 0, breaches = 0, tallest = 0;
    for (int z = 0; z < a.height; ++z) {
        for (int x = 0; x < a.width; ++x) {
            ++columns;
            int hgt = a.at(x, z).height;
            tallest = std::max(tallest, hgt);
            if (a.blockAt(x, 0, z) != worldgen::kBedrock) bedrockGood = false;
            if (a.topSolid(x, z) != hgt) ++breaches;
            for (int y = 1; y < hgt - 1; ++y)
                if (a.blockAt(x, y, z) == worldgen::kAir) ++caveCells;
        }
    }
    check(bedrockGood, "worldgen: bedrock everywhere at y 0");
    check(caveCells > 500, "worldgen: caves carved underground");
    check(breaches > 0 && breaches < columns / 4,
          "worldgen: some breach entrances, a mostly intact surface");
    check(tallest > t.worldgen.map.baseHeight + t.worldgen.map.heightScale,
          "worldgen: mountains rise above the rolling base");
    bool nodesGrounded = true;
    int caveNodes = 0;
    for (const auto& node : a.nodes) {
        if (a.blockAt(node.x, node.y, node.z) != worldgen::kAir ||
            a.blockAt(node.x, node.y - 1, node.z) == worldgen::kAir)
            nodesGrounded = false;
        if (node.y < a.at(node.x, node.z).height) ++caveNodes;
    }
    check(nodesGrounded, "worldgen: every node stands in air on solid ground");
    check(caveNodes > 0, "worldgen: iron runs underground (cave-floor nodes exist)");
    int clearR = static_cast<int>(t.worldgen.guarantees.spawnClearRadiusM / t.worldgen.map.cellSizeM);
    bool clearingIntact = true;
    for (int dz = -clearR; dz <= clearR; ++dz)
        for (int dx = -clearR; dx <= clearR; ++dx) {
            int x = a.spawnX + dx, z = a.spawnZ + dz;
            if (!a.inBounds(x, z) || dx * dx + dz * dz > clearR * clearR) continue;
            if (a.topSolid(x, z) != a.at(x, z).height) clearingIntact = false;
        }
    check(clearingIntact, "worldgen: the spawn clearing is never carved beneath");
    // Wave 7 slice 1: density is the biome's own; the rings only give teeth.
    auto density = [&](const std::string& id) {
        for (const auto& b : t.worldgen.biomes)
            if (b.id == id) return b.packDensity;
        return -1.0;
    };
    check(density("meadow") > 0.0 && density("meadow") < density("forest") && density("forest") < density("fen") &&
              density("fen") <= density("ember_wastes") && density("meadow") * 8.0 < density("fen"),
          "worldgen: density is the biome's - the meadow a straggler, the fen and the wastes dense (Wave 7)");
    check(t.worldgen.dangerRingAt(30.0) != nullptr && t.worldgen.dangerRingAt(30.0)->packSizeBonus == 0 &&
              t.worldgen.dangerRingAt(30.0)->eliteChance == 0.0 && t.worldgen.dangerRingAt(300.0)->packSizeBonus > 0,
          "worldgen: the rings give teeth by distance, not density");
    check(t.world.shelter.maxRoomCells >= 300, "shelter: the room cap is a hall, not a hut (owner playtest 3 Sep)");
    check(t.realtime.hordeMaxLiveMobs > 0 && t.realtime.hordeSleepRangeM > 28.0 && t.realtime.hordeSleepAfterSeconds > 0.0,
          "population: a live-mob cap and a sleep range beyond the wake range");
    {
        const auto* fast = t.realtime.findBehaviour("fast");
        check(fast && fast->moveSpeedMps > 5.0 && fast->moveSpeedMps <= 5.6,
              "population: hounds run faster than you, but only just (owner 3 Sep)");
    }
    {
        // Grazers: placed from the biome's grazer list, flagged, never
        // hostile-listed; hostile packs keep off the doorstep.
        int herds = 0, hostileNear = 0;
        const auto& g2 = t.worldgen.guarantees;
        for (const auto& pack : a.packs) {
            if (pack.grazer) {
                ++herds;
                for (const auto& id : pack.enemies)
                    check(id == "valley_elk", "worldgen: herds are grazers (" + id + ")");
                check(pack.eliteMemberIndex < 0, "worldgen: herds are never crowned");
            } else {
                double d = std::sqrt(double((pack.x - a.spawnX) * (pack.x - a.spawnX) + (pack.z - a.spawnZ) * (pack.z - a.spawnZ)));
                if (d < g2.packMinDistanceFromSpawnM) ++hostileNear;
                for (const auto& id : pack.enemies)
                    check(id != "valley_elk", "worldgen: hostile packs never carry grazers");
            }
        }
        check(herds > 0, "worldgen: the meadow has herds");
        check(hostileNear == 0, "worldgen: no hostile pack within the doorstep radius");
    }
    check(t.worldgen.blockRules.count("stone") == 1 &&
              t.worldgen.blockRules.at("stone").yields.at("split_stone") == 1 &&
              t.worldgen.blockRules.at("stone").digSeconds > 0.0 &&
              !t.worldgen.blockRules.at("bedrock").breakable,
          "worldgen: block rules load (strata pay split stone, bedrock never breaks)");

    // D-020 fire-setting: soil digs by hand, stone must be cracked by a
    // wood fire and cold, bedrock never; the alloy ores want charcoal.
    check(t.worldgen.blockRules.at("surface").byHand && t.worldgen.blockRules.at("dirt").byHand &&
              !t.worldgen.blockRules.at("stone").byHand && t.worldgen.blockRules.at("stone").heatToCrack == 1 &&
              !t.worldgen.blockRules.at("bedrock").byHand && t.worldgen.blockRules.at("bedrock").heatToCrack == 0,
          "fire-setting: hands dig soil; stone cracks at heat one; bedrock never");
    check(t.worldgen.fireSetting.fuelHeat("wood") == 1 && t.worldgen.fireSetting.fuelHeat("charcoal") == 2 &&
              t.worldgen.fireSetting.fuelHeat("stone") == 0 && t.worldgen.fireSetting.fuels.at("wood").burnSeconds > 0.0 &&
              t.worldgen.fireSetting.reachCells >= 1 && t.worldgen.fireSetting.hotSeconds > t.worldgen.fireSetting.soakSeconds &&
              t.worldgen.fireSetting.quenchRadiusM > 0.0,
          "fire-setting: timber burns at heat one, charcoal at two, stone is no fuel");
    check(t.worldgen.nodeTypes.at("tree").heatToWork == 0 && t.worldgen.nodeTypes.at("boulder").heatToWork == 0 &&
              t.worldgen.nodeTypes.at("iron_vein").heatToWork == 0 && t.worldgen.nodeTypes.at("copper_vein").heatToWork == 2 &&
              t.worldgen.nodeTypes.at("silver_vein").heatToWork == 2,
          "fire-setting: trees, fieldstone and iron by hand; the alloy ores want a charcoal fire");

    // D-021 masonry is the unlock, not stone: boulders pay fieldstone that
    // lays only footings and dry walls; seams pay split stone through a
    // timber wedge; the yard dresses split stone into the stone family.
    {
        const auto& seam = t.worldgen.nodeTypes.at("stone_seam");
        check(seam.materialFamily == "split_stone" && seam.toolItem == "timber_wedge" && seam.drivePresses >= 2 &&
                  seam.unitsPerHarvest >= 1 && seam.era == 1,
              "seams: a stone seam is worked with a timber wedge over several presses");
        check(t.worldgen.nodeTypes.at("boulder").materialFamily == "fieldstone" && t.worldgen.nodeTypes.at("boulder").toolItem.empty(),
              "seams: boulders are fieldstone by hand");
        check(t.worldgen.guarantees.minNodesNear.count("stone_seam") && t.worldgen.guarantees.minNodesNear.at("stone_seam") >= 1,
              "seams: seams are guaranteed near spawn");
        check(t.worldgen.blockRules.at("stone").yields.count("split_stone") == 1 && !t.worldgen.blockRules.at("stone").yields.count("stone"),
              "seams: cracked strata pay split stone, never dressed stone");
        const auto* wedge = t.crafting.findRecipe("timber_wedge");
        const auto* yardKit = t.crafting.findRecipe("mason_yard_kit");
        const auto* dress = t.crafting.findRecipe("dress_stone");
        check(wedge && wedge->station.empty() && wedge->inputs.count("wood") && wedge->outputs.at("timber_wedge") >= 1,
              "seams: wedges are hand-made from timber");
        check(yardKit && yardKit->station == "workbench" && yardKit->inputs.count("fieldstone") && yardKit->inputs.count("timber_frame"),
              "seams: the yard's kit costs fieldstone and a timber frame at the bench");
        check(dress && dress->station == "mason_yard" && dress->inputs.at("split_stone") >= 2 && dress->outputs.at("stone") == 1,
              "seams: the yard dresses two split stones into one stone");
        const auto* yard = t.crafting.findStationForKit("mason_yard_kit");
        check(yard && yard->id == "mason_yard", "seams: the yard is founded from its kit");
        const auto* forgeKit = t.crafting.findRecipe("forge_kit");
        check(forgeKit && forgeKit->inputs.count("stone") && !forgeKit->inputs.count("fieldstone"),
              "seams: the forge kit wants dressed stone - masonry gates the forge");
        const auto* field = t.construction.findMaterial("fieldstone");
        const auto* footing = t.construction.findShape("foundation");
        const auto* dryWall = t.construction.findShape("dry_wall");
        const auto* cube = t.construction.findShape("cube");
        const auto* wall = t.construction.findShape("wall_panel");
        check(field && footing && dryWall && field->onlyForTrait == "rough" && footing->form == "low" && dryWall->form == "low" &&
                  footing->element == "block" && dryWall->element == "wall" && footing->sizeM[1] < 1.0,
              "seams: fieldstone and its two low shapes exist");
        check(t.construction.shapeAllowsMaterial(*footing, *field) && t.construction.shapeAllowsMaterial(*dryWall, *field) &&
                  !t.construction.shapeAllowsMaterial(*cube, *field) && !t.construction.shapeAllowsMaterial(*wall, *field) &&
                  !t.construction.shapeAllowsMaterial(*footing, *t.construction.findMaterial("wood")),
              "seams: fieldstone lays a footing and a dry wall, never a cube or a wall; timber lays no footing");
        for (const auto& e : t.world.enemies)
            for (const auto& entry : e.loot)
                check(entry.item != "stone", "seams: no creature drops dressed stone (" + e.id + ")");
        bool milestone = false;
        for (const auto& src : t.foundry.sources)
            if (src.event == "work:strike_split") milestone = true;
        check(milestone, "seams: the first strike-driven split is a Foundry milestone");
    }
    for (const auto& [id, node] : t.worldgen.nodeTypes)
        check(node.heatToWork <= 2, "fire-setting: no node wants more heat than charcoal gives (" + id + ")");
    {
        const auto* fire = t.construction.findShape("campfire");
        const auto* charcoal = t.construction.findMaterial("charcoal");
        const auto* wood = t.construction.findMaterial("wood");
        const auto* cube = t.construction.findShape("cube");
        check(fire && charcoal && wood && cube && fire->form == "fire" && fire->element == "block",
              "fire-setting: the campfire is a block-cell piece of form fire");
        check(t.construction.shapeAllowsMaterial(*fire, *wood) && t.construction.shapeAllowsMaterial(*fire, *charcoal),
              "fire-setting: timber and charcoal both lay a campfire");
        check(!t.construction.shapeAllowsMaterial(*cube, *charcoal) && t.construction.shapeAllowsMaterial(*cube, *wood),
              "fire-setting: charcoal is fuel, never a wall (only_for_trait)");
        check(!t.construction.shapeAllowsMaterial(*fire, *t.construction.findMaterial("stone")),
              "fire-setting: stone does not burn");
        for (const auto& [family, fuel] : t.worldgen.fireSetting.fuels)
            check(t.construction.findMaterial(family) != nullptr && t.construction.findMaterial(family)->hasTrait("fuel"),
                  "fire-setting: every fuel is a building family with the fuel trait (" + family + ")");
    }

    // The guarantees hold across many seeds (D-003: critical progression
    // resources cannot be absent from a valid seed). 24 seeds: the 3D world
    // costs real time to generate, and two dozen distinct worlds still
    // catch a broken guarantee.
    const auto& g = t.worldgen.guarantees;
    int spawnBiome = -1;
    for (size_t i = 0; i < t.worldgen.biomes.size(); ++i)
        if (t.worldgen.biomes[i].id == g.spawnBiome) spawnBiome = static_cast<int>(i);
    bool allGood = true;
    std::string firstBad;
    for (uint64_t seed = 1; seed <= 24 && allGood; ++seed) {
        auto map = worldgen::generate(t, seed);
        if (map.at(map.spawnX, map.spawnZ).biomeIndex != spawnBiome) {
            allGood = false; firstBad = "spawn biome (seed " + std::to_string(seed) + ")";
        }
        for (const auto& [type, minimum] : g.minNodesNear)
            if (map.countNodesNear(type, map.spawnX, map.spawnZ, g.nearRadiusM) < minimum) {
                allGood = false;
                firstBad = type + " shortfall (seed " + std::to_string(seed) + ")";
            }
        // Iron is a walk (Wave 6 slice 2): guaranteed within the far ring.
        for (const auto& [type, minimum] : g.minNodesFar)
            if (map.countNodesNear(type, map.spawnX, map.spawnZ, g.farRadiusM) < minimum) {
                allGood = false;
                firstBad = type + " far shortfall (seed " + std::to_string(seed) + ")";
            }
        double gateDistance = std::sqrt(
            static_cast<double>((map.gateX - map.spawnX) * (map.gateX - map.spawnX) +
                                (map.gateZ - map.spawnZ) * (map.gateZ - map.spawnZ)));
        if (gateDistance < g.gateMinDistanceM) {
            allGood = false; firstBad = "gate too close (seed " + std::to_string(seed) + ")";
        }
        for (const auto& pack : map.packs) {
            if (pack.grazer) continue; // herds may graze by the door (D-020)
            double d = std::sqrt(
                static_cast<double>((pack.x - map.spawnX) * (pack.x - map.spawnX) +
                                    (pack.z - map.spawnZ) * (pack.z - map.spawnZ)));
            if (d < g.packMinDistanceFromSpawnM) {
                allGood = false; firstBad = "pack at the spawn door (seed " + std::to_string(seed) + ")";
            }
        }
        if (map.nodes.empty() || map.packs.empty()) {
            allGood = false; firstBad = "empty world (seed " + std::to_string(seed) + ")";
        }
        // Every node type and pack enemy must be defined in tuning.
        for (const auto& node : map.nodes)
            if (!t.worldgen.nodeTypes.count(node.type)) {
                allGood = false; firstBad = "unknown node type " + node.type;
            }
        for (const auto& pack : map.packs)
            for (const auto& enemy : pack.enemies)
                if (!t.world.findEnemy(enemy)) {
                    allGood = false; firstBad = "unknown pack enemy " + enemy;
                }
    }
    check(allGood, "worldgen: guarantees hold across 24 seeds" +
                       (firstBad.empty() ? "" : " - first failure: " + firstBad));
}


void testGrammar(const tuning::Tuning& t) {
    // Tables load.
    check(t.grammar.chill.buildupMax == 100.0, "grammar: chill threshold loads");
    check(t.items.findModifier("forked_lattice") != nullptr, "grammar: mods load from the item pool");
    check(t.grammar.shatter.novaRadiusM > 0.0, "grammar: shatter hook loads");
    check(t.realtime.skillSpatials.count("prototype_frost_orb") == 1,
          "grammar: orb spatials load");

    grammar::ActiveMods none;
    auto toggled = [&](std::initializer_list<const char*> ids) {
        grammar::ActiveMods mods;
        for (const char* id : ids)
            mods.push_back(grammar::modAt(t.items, id, grammar::defaultValue(*t.items.findModifier(id)), "test"));
        return mods;
    };
    grammar::ActiveMods all = toggled({"forked_lattice", "deep_frost", "wide_shatter"});

    // Fork resolution: base 1, +1 flat from the lattice; tag-gated.
    check(grammar::forkCount(t, none, "prototype_frost_orb") == 1, "grammar: base fork count");
    check(grammar::forkCount(t, all, "prototype_frost_orb") == 2, "grammar: lattice adds a fork");
    check(grammar::forkCount(t, all, "prototype_heavy_strike") == 0,
          "grammar: fork mod ignores non-projectile skills");

    // Fork damage decays per generation.
    checkNear(grammar::forkDamageFraction(t, "prototype_frost_orb", 0), 1.0, 1e-9,
              "grammar: the cast keeps full damage");
    checkNear(grammar::forkDamageFraction(t, "prototype_frost_orb", 2), 0.49, 1e-9,
              "grammar: second-generation forks keep 0.7^2");

    // Chill: base 40; Deep Frost = 50% increased -> 60. The breakpoint the
    // mod is FOR: three hits to freeze becomes two (skill-grammar.md).
    checkNear(grammar::chillApplied(t, none, "prototype_frost_orb", false), 40.0, 1e-9,
              "grammar: base chill buildup");
    checkNear(grammar::chillApplied(t, all, "prototype_frost_orb", false), 60.0, 1e-9,
              "grammar: deep frost crosses the two-hit-freeze breakpoint");
    check(2.0 * grammar::chillApplied(t, all, "prototype_frost_orb", false) >=
              t.grammar.chill.buildupMax,
          "grammar: two modded hits reach the freeze threshold");
    check(3.0 * grammar::chillApplied(t, none, "prototype_frost_orb", false) >=
              t.grammar.chill.buildupMax &&
          2.0 * grammar::chillApplied(t, none, "prototype_frost_orb", false) <
              t.grammar.chill.buildupMax,
          "grammar: unmodded freeze takes exactly three hits");
    check(grammar::chillApplied(t, none, "prototype_heavy_strike", false) == 0.0,
          "grammar: non-chill skills apply nothing");

    // Boss status resistance from day one.
    checkNear(grammar::chillApplied(t, none, "prototype_frost_orb", true), 10.0, 1e-9,
              "grammar: bosses resist chill buildup");

    // Shatter hook: triggered by tag (every attack), never by skill id;
    // spells set up, attacks cash in. Radius honours mods.
    auto plain = grammar::shatterFor(t, none, "prototype_area_strike");
    check(plain.enabled && plain.executesFrozen, "grammar: cone strike carries shatter");
    check(!plain.executesBoss, "grammar: shatter novas a frozen boss but does not execute it");
    check(grammar::shatterFor(t, none, "prototype_heavy_strike").enabled,
          "grammar: heavy strike carries shatter too (attack tag)");
    check(grammar::shatterFor(t, none, "prototype_rend").enabled,
          "grammar: a learned attack joins the shatter combo by its tag");
    check(!grammar::shatterFor(t, none, "prototype_frost_orb").enabled &&
              !grammar::shatterFor(t, none, "prototype_frost_nova").enabled,
          "grammar: cold spells do not shatter");
    check(!grammar::shatterFor(t, none, "nobody").enabled, "grammar: unknown skills carry nothing");
    auto wide = grammar::shatterFor(t, all, "prototype_area_strike");
    checkNear(wide.novaRadiusM, plain.novaRadiusM * 1.4, 1e-9,
              "grammar: wide shatter is 40% increased radius");

    // The increased-vs-more rule: two increased mods sum, a more multiplies.
    grammar::ActiveMods stacked = toggled({"deep_frost"});
    stacked.push_back({"test_inc", {"chill"}, "increased_chill_buildup", 0.5, "test"});
    stacked.push_back({"test_more", {}, "more_chill_buildup", 0.5, "test"});
    // 40 * (1 + 0.5 + 0.5) * 1.5 = 120: increased sums, more multiplies.
    checkNear(grammar::chillApplied(t, stacked, "prototype_frost_orb", false), 120.0, 1e-9,
              "grammar: increased sums additively, more multiplies");
}

// The Wave 2 grammar intensive (D-016): ignite and bleed beside chill, flat
// payload mods, proliferate, and skills with their own delivery.
void testStatusGrammar(const tuning::Tuning& t) {
    const auto* bolt = t.skills.findCombatSkill("prototype_ember_bolt");
    const auto* rend = t.skills.findCombatSkill("prototype_rend");
    const auto* nova = t.skills.findCombatSkill("prototype_frost_nova");
    check(bolt && bolt->delivery == "projectile" && !bolt->starting && bolt->dropWeight > 0.0,
          "status: ember bolt is a learned projectile");
    check(rend && rend->delivery == "strike" && nova && nova->delivery == "cone",
          "status: rend strikes, nova is a ring");
    check(t.skills.findCombatSkill("prototype_dash")->delivery == "dash" &&
              t.skills.findCombatSkill("prototype_area_strike")->delivery == "cone",
          "status: starting skills carry their deliveries");
    check(t.realtime.skillSpatials.count("prototype_ember_bolt") == 1 &&
              t.realtime.skillSpatials.at("prototype_frost_nova").at("cone_degrees") == 360.0,
          "status: new skills have their space-and-time entries");
    check(t.grammar.ignite.durationS > 0.0 && t.grammar.bleed.movingMultiplier > 1.0 &&
              t.grammar.proliferate.enabled,
          "status: ignite, bleed and proliferate load");

    grammar::ActiveMods none;
    auto at = [&](const char* id, double value) {
        return grammar::modAt(t.items, id, value, "test");
    };
    auto tierOneMax = [&](const char* id) {
        return at(id, grammar::defaultValue(*t.items.findModifier(id)));
    };

    // Ignite: three bolts bare, two with Kindling at tier-1 maximum.
    double igniteBare = grammar::igniteApplied(t, none, "prototype_ember_bolt", false);
    check(igniteBare > 0.0 && 3.0 * igniteBare >= t.grammar.ignite.buildupMax &&
              2.0 * igniteBare < t.grammar.ignite.buildupMax,
          "status: bare ignite takes three bolts");
    grammar::ActiveMods kindled = {tierOneMax("kindling")};
    check(2.0 * grammar::igniteApplied(t, kindled, "prototype_ember_bolt", false) >=
              t.grammar.ignite.buildupMax,
          "status: kindling crosses to a two-bolt ignite");
    checkNear(grammar::igniteApplied(t, none, "prototype_ember_bolt", true),
              igniteBare * t.grammar.ignite.bossBuildupMultiplier, 1e-9,
              "status: bosses resist ignite");
    check(grammar::igniteApplied(t, kindled, "prototype_frost_orb", false) == 0.0,
          "status: kindling gives the orb no ignite (increased needs a base)");
    check(grammar::chillApplied(t, none, "prototype_ember_bolt", false) == 0.0,
          "status: the bolt carries no chill");

    // Bleed: two rends bare, one with Serration at tier-1 maximum.
    double bleedBare = grammar::bleedApplied(t, none, "prototype_rend", false);
    check(bleedBare > 0.0 && 2.0 * bleedBare >= t.grammar.bleed.buildupMax &&
              bleedBare < t.grammar.bleed.buildupMax,
          "status: bare bleed takes two rends");
    grammar::ActiveMods serrated = {tierOneMax("serration")};
    check(grammar::bleedApplied(t, serrated, "prototype_rend", false) >= t.grammar.bleed.buildupMax,
          "status: serration opens a wound in one rend");
    check(grammar::bleedApplied(t, serrated, "prototype_heavy_strike", false) == 0.0,
          "status: the heavy strike has no bleed to increase");

    // Flat payload mods give a skill a status it lacks: Frostbite chills
    // attacks, Smouldering ignites spells - and only those.
    grammar::ActiveMods frostbite = {at("frostbite", 25.0)};
    checkNear(grammar::chillApplied(t, frostbite, "prototype_area_strike", false), 25.0, 1e-9,
              "status: frostbite gives the cone strike chill");
    checkNear(grammar::chillApplied(t, frostbite, "prototype_frost_orb", false), 40.0, 1e-9,
              "status: frostbite leaves spells alone");
    grammar::ActiveMods frostbiteAndDeepFrost = {at("frostbite", 25.0), tierOneMax("deep_frost")};
    checkNear(grammar::chillApplied(t, frostbiteAndDeepFrost, "prototype_area_strike", false), 25.0, 1e-9,
              "status: deep frost scales chill skills, not a chilling attack");
    grammar::ActiveMods smouldering = {at("smouldering", 20.0)};
    checkNear(grammar::igniteApplied(t, smouldering, "prototype_frost_orb", false), 20.0, 1e-9,
              "status: smouldering gives the orb ignite");
    checkNear(grammar::igniteApplied(t, smouldering, "prototype_ember_bolt", false), igniteBare + 20.0, 1e-9,
              "status: flat adds before increased (bolt + smouldering)");
    check(grammar::igniteApplied(t, smouldering, "prototype_heavy_strike", false) == 0.0,
          "status: smouldering ignores attacks");

    // Status parameters honour their tags: burn damage and duration, bleed damage.
    auto burnBare = grammar::igniteStatus(t, none);
    checkNear(burnBare.damagePerS, t.grammar.ignite.damagePerS, 1e-9, "status: base burn per second");
    grammar::ActiveMods burning = {at("burn_damage", 0.5), at("lingering_flame", 0.25)};
    auto burn = grammar::igniteStatus(t, burning);
    checkNear(burn.damagePerS, t.grammar.ignite.damagePerS * 1.5, 1e-9, "status: burn damage increases the tick");
    checkNear(burn.durationS, t.grammar.ignite.durationS * 1.25, 1e-9, "status: lingering flame lengthens the burn");
    check(burn.buildupMax == t.grammar.ignite.buildupMax && burn.decayPerS == t.grammar.ignite.decayPerS,
          "status: ignite thresholds pass through");
    grammar::ActiveMods bleeding = {at("hemorrhage", 0.6)};
    auto wound = grammar::bleedStatus(t, bleeding);
    checkNear(wound.damagePerS, t.grammar.bleed.damagePerS * 1.6, 1e-9, "status: hemorrhage increases the bleed tick");
    checkNear(wound.movingMultiplier, t.grammar.bleed.movingMultiplier, 1e-9, "status: bleed keeps its moving multiplier");
    checkNear(grammar::igniteStatus(t, bleeding).damagePerS, t.grammar.ignite.damagePerS, 1e-9,
              "status: bleed mods leave the burn alone");

    // Proliferate: radius honours Wildfire Reach; buildup is the hook's.
    auto spread = grammar::proliferateFor(t, none);
    check(spread.enabled && spread.radiusM == t.grammar.proliferate.radiusM &&
              spread.spreadBuildup == t.grammar.proliferate.spreadBuildup,
          "status: proliferate base parameters");
    grammar::ActiveMods reach = {at("wildfire_reach", 0.4)};
    checkNear(grammar::proliferateFor(t, reach).radiusM, t.grammar.proliferate.radiusM * 1.4, 1e-9,
              "status: wildfire reach widens proliferate");

    // Damage by element: fire damage scales the bolt's hit, not its burn.
    grammar::ActiveMods fiery = {at("fire_damage", 0.2)};
    checkNear(grammar::skillDamage(t, fiery, "prototype_ember_bolt"), 8.0 * 1.2, 1e-9,
              "status: fire damage scales the bolt");
    checkNear(grammar::skillDamage(t, fiery, "prototype_frost_orb"), 9.0, 1e-9,
              "status: fire damage leaves the orb alone");
    checkNear(grammar::igniteStatus(t, fiery).damagePerS, t.grammar.ignite.damagePerS, 1e-9,
              "status: fire damage is the hit, not the burn");

    // Forks are a projectile thing: a Forks roll teaches the bolt to split.
    check(grammar::forkCount(t, none, "prototype_ember_bolt") == 0, "status: the bolt does not fork bare");
    grammar::ActiveMods lattice = {tierOneMax("forked_lattice")};
    check(grammar::forkCount(t, lattice, "prototype_ember_bolt") == 1, "status: forks teach the bolt to split");

    // The wand: implicit Kindling, pool is the fire line; never resistance.
    const auto* wand = t.items.findBase("ember_wand");
    check(wand && wand->slot == "weapon" && wand->implicitModifiers.size() == 1 &&
              wand->implicitModifiers.front().id == "kindling",
          "status: the ember wand carries kindling");
    for (uint64_t seed = 0; seed < 40; ++seed) {
        auto item = items::rollRarityItem(t.items, "ember_wand", "wrought", 2, seed);
        for (const auto& rolled : item.rolledProperties) {
            const auto* def = t.items.findModifier(rolled.propertyId);
            check(def && !def->isSelf(), "status: the wand rolls only skill modifiers (" + rolled.propertyId + ")");
        }
        auto maceRoll = items::rollRarityItem(t.items, "iron_mace", "wrought", 2, seed);
        for (const auto& rolled : maceRoll.rolledProperties)
            check(rolled.propertyId != "deep_frost" && rolled.propertyId != "kindling",
                  "status: the mace never grows spell-line mods");
    }
    check(t.crafting.findRecipe("ember_wand") != nullptr, "status: the wand has a recipe");
}

// D-016: skills are learned, not worn. The loadout lives in the economy
// and saves; the round model fights with the starting bar.
void testSkillLoadout(const tuning::Tuning& t) {
    auto starting = t.skills.startingSkillIds();
    check(starting.size() == 4 && starting[0] == "prototype_area_strike" &&
              starting[1] == "prototype_heavy_strike" && starting[2] == "prototype_frost_orb" &&
              starting[3] == "prototype_dash",
          "loadout: four starting skills in bar order");

    economy::PlayerEconomy player(t);
    check(player.knownSkills() == starting, "loadout: a fresh character knows the starting skills");
    check(player.skillBar().size() == economy::kSkillBarSize && player.skillBar() == starting,
          "loadout: the starting skills fill the bar in order");
    check(player.knowsSkill("prototype_frost_orb") && !player.knowsSkill("prototype_ember_bolt"),
          "loadout: learned skills are known, pages are not");

    check(!player.learnSkill("nobody"), "loadout: unknown skills cannot be learned");
    check(!player.learnSkill("prototype_frost_orb"), "loadout: a known skill is not learned twice");
    check(player.learnSkill("prototype_ember_bolt") && player.knowsSkill("prototype_ember_bolt"),
          "loadout: a page teaches its skill");
    check(player.knownSkills().size() == 5 && player.skillBar() == starting,
          "loadout: a full bar stays as it was; the new skill waits");
    check(!player.setBarSlot(4, "prototype_ember_bolt") && !player.setBarSlot(-1, "prototype_ember_bolt"),
          "loadout: bar slots are bounded");
    check(!player.setBarSlot(0, "prototype_rend"), "loadout: an unknown skill cannot go on the bar");
    check(player.setBarSlot(1, "prototype_ember_bolt") && player.skillBar()[1] == "prototype_ember_bolt",
          "loadout: a known skill takes a slot");
    check(player.setBarSlot(3, "prototype_ember_bolt") && player.skillBar()[3] == "prototype_ember_bolt" &&
              player.skillBar()[1].empty(),
          "loadout: moving a skill vacates its old slot");
    check(player.setBarSlot(3, "") && player.skillBar()[3].empty(), "loadout: a slot can be cleared");
    check(player.learnSkill("prototype_rend") && player.skillBar()[1] == "prototype_rend",
          "loadout: a new skill takes the first empty slot");

    // Save round-trip keeps the loadout; a pre-D-016 save starts fresh.
    save::SaveGame game;
    game.economy = player.exportState();
    save::SaveGame loaded = save::fromJson(save::toJson(game));
    check(loaded.economy.knownSkills.size() == 6 && loaded.economy.skillBar == player.skillBar(),
          "loadout: known skills and bar round-trip");
    economy::PlayerEconomy restored(t);
    restored.importState(loaded.economy);
    check(restored.knownSkills() == player.knownSkills() && restored.skillBar() == player.skillBar(),
          "loadout: import restores the loadout");
    economy::PlayerEconomy::State old;
    restored.importState(old);
    check(restored.knownSkills() == starting && restored.skillBar() == starting,
          "loadout: an old save falls back to the starting bar");
    economy::PlayerEconomy::State stale;
    stale.knownSkills = {"prototype_frost_orb", "retired_skill", "prototype_rend"};
    stale.skillBar = {"retired_skill", "prototype_rend", "", "prototype_dash"};
    restored.importState(stale);
    check(restored.knowsSkill("prototype_rend") && !restored.knowsSkill("retired_skill") &&
              restored.knowsSkill("prototype_area_strike"),
          "loadout: import drops retired skills and never loses a starting one");
    check(restored.skillBar()[0].empty() && restored.skillBar()[1] == "prototype_rend" &&
              restored.skillBar()[3] == "prototype_dash",
          "loadout: the bar keeps what is still known, slot by slot");

    // The round model (balance oracle) fights with the starting bar only.
    boons::BuildTags tags = {"attack", "physical", "area", "single_target", "movement"};
    stats::Equipment bare;
    auto derived = stats::deriveStats(t.world.playerBase, bare, t.items);
    std::vector<std::string> log;
    auto result = combat::runEncounter(t, derived, combat::CombatMods{}, {"ember_whelp", "ember_whelp"},
                                       5, combat::autoPolicy, &log);
    bool learnedUsed = false;
    for (const auto& line : log)
        if (line.find("Rend") != std::string::npos || line.find("Ember Bolt") != std::string::npos ||
            line.find("Frost Nova") != std::string::npos)
            learnedUsed = true;
    check(result.victory && !learnedUsed, "loadout: the round model never swings a learned skill");
}

// Mob drops beyond materials (D-016): gear pieces and skill pages, each on
// its own random stream so adding one never moves the others.
void testMobGearAndPages(const tuning::Tuning& t) {
    auto a = loot::rollEnemyGear(t, "stone_husk", 4);
    auto b = loot::rollEnemyGear(t, "stone_husk", 4);
    check(a.size() == b.size(), "drops: gear is deterministic per seed");
    check(loot::rollEnemyGear(t, "nobody", 4).empty(), "drops: unknown enemies drop no gear");

    const int kills = 4000;
    int gearDrops = 0;
    bool wellFormed = true;
    for (uint64_t seed = 0; seed < kills; ++seed) {
        for (const auto& item : loot::rollEnemyGear(t, "stone_husk", seed)) {
            ++gearDrops;
            if (item.rarity != "keen" || !t.items.findBase(item.baseId) || item.rolledProperties.empty())
                wellFormed = false;
        }
    }
    double gearRate = static_cast<double>(gearDrops) / kills;
    check(gearRate > 0.04 && gearRate < 0.08, "drops: husk gear lands near its 6% chance");
    check(wellFormed, "drops: dropped gear is keen, on a real base, with modifiers");

    // Pages teach only unknown skills, weighted, and dry up once all are known.
    std::vector<std::string> known = t.skills.startingSkillIds();
    std::set<std::string> taught;
    int pages = 0;
    for (uint64_t seed = 0; seed < kills; ++seed) {
        auto page = loot::rollEnemySkillPage(t, "stone_husk", seed, known);
        if (page.empty()) continue;
        ++pages;
        taught.insert(page);
        check(t.skills.findCombatSkill(page) && !t.skills.findCombatSkill(page)->starting,
              "drops: a page never teaches a known skill");
    }
    double pageRate = static_cast<double>(pages) / kills;
    check(pageRate > 0.035 && pageRate < 0.07, "drops: husk pages land near their 5% chance");
    check(taught.size() == 6, "drops: every learnable skill turns up on pages (the pages, the bow shot and the sweep)");
    check(loot::rollEnemySkillPage(t, "stone_husk", 1, known) ==
              loot::rollEnemySkillPage(t, "stone_husk", 1, known),
          "drops: pages are deterministic per seed");

    std::vector<std::string> everything;
    for (const auto& def : t.skills.combatSkills) everything.push_back(def.id);
    bool dry = true;
    for (uint64_t seed = 0; seed < 500; ++seed)
        if (!loot::rollEnemySkillPage(t, "stone_husk", seed, everything).empty()) dry = false;
    check(dry, "drops: no pages once every skill is known");
    std::vector<std::string> allButNova = everything;
    allButNova.erase(std::find(allButNova.begin(), allButNova.end(), "prototype_frost_nova"));
    bool onlyNova = true;
    for (uint64_t seed = 0; seed < 500; ++seed) {
        auto page = loot::rollEnemySkillPage(t, "stone_husk", seed, allButNova);
        if (!page.empty() && page != "prototype_frost_nova") onlyNova = false;
    }
    check(onlyNova, "drops: the last unknown skill is the only page left");
    check(loot::rollEnemySkillPage(t, "nobody", 1, known).empty(), "drops: unknown enemies drop no pages");

    // Material rolls are untouched by the gear and page entries.
    check(loot::rollEnemyLoot(t.world, "stone_husk", 99).count("split_stone") == 1,
          "drops: materials still roll beside gear and pages");
}

} // namespace

// D-014 slice 1: one modifier pool, rarity by count, gear-driven grammar,
// pack items that save, and trial rooms that drop gear.
void testItemisation(const tuning::Tuning& t) {
    check(t.items.slots.size() == 4 && t.items.findRarity("wrought") != nullptr, "items: slots (the offhand among them) and rarities load");
    const auto* sceptre = t.items.findBase("frost_sceptre");
    check(sceptre != nullptr && sceptre->slot == "weapon" && !sceptre->implicitModifiers.empty(),
          "items: weapon base carries its slot and an implicit (never a skill, D-016)");
    check(t.items.findModifier("max_life")->isSelf() && !t.items.findModifier("deep_frost")->isSelf(),
          "items: self modifiers are told apart from skill modifiers");
    for (const auto& def : t.items.modifiers)
        check(!def.designPurpose.empty(), "items: every modifier states its design purpose (" + def.id + ")");

    // Rarity is a modifier count within the rarity's range, all distinct, all allowed.
    for (uint64_t seed = 0; seed < 40; ++seed) {
        auto item = items::rollRarityItem(t.items, "frost_sceptre", "wrought", 2, seed);
        check(item.rarity == "wrought", "items: rarity recorded");
        check(item.rolledProperties.size() >= 3 && item.rolledProperties.size() <= 4, "items: wrought rolls 3-4 modifiers");
        std::set<std::string> seen;
        for (const auto& rolled : item.rolledProperties) {
            check(seen.insert(rolled.propertyId).second, "items: rolled modifiers are distinct");
            const auto* def = t.items.findModifier(rolled.propertyId);
            check(def != nullptr && def->id != "physical_damage" && def->id != "max_life",
                  "items: sceptre rolls only its allowed tags");
        }
        auto plain = items::rollRarityItem(t.items, "iron_mace", "plain", 1, seed);
        check(plain.rolledProperties.empty() && plain.rarity == "plain", "items: plain rolls nothing");
    }
    auto high = items::rollRarityItem(t.items, "ember_charm", "wrought", 2, 9);
    check(high.rolledProperties.size() >= 3, "items: higher tiers fall back to defined tiers");

    // D-020 the era-one pool: a tier-one roll never carries an interaction
    // modifier; tier two (era two, or an elite in era one) opens the pool.
    {
        bool interactionAtOne = false, interactionAtTwo = false;
        for (uint64_t seed = 0; seed < 60; ++seed) {
            for (const char* base : {"frost_sceptre", "ember_wand", "iron_mace", "ember_charm"}) {
                for (const auto& rolled : items::rollRarityItem(t.items, base, "wrought", 1, seed).rolledProperties)
                    if (t.items.findModifier(rolled.propertyId)->fromTier > 1) interactionAtOne = true;
                for (const auto& rolled : items::rollRarityItem(t.items, base, "keen", 2, seed).rolledProperties)
                    if (t.items.findModifier(rolled.propertyId)->fromTier > 1) interactionAtTwo = true;
            }
        }
        check(!interactionAtOne, "pool: tier-one rolls are defensive or small adds, never interactions");
        check(interactionAtTwo, "pool: tier two opens the interactions");
        check(t.items.findModifier("forked_lattice")->fromTier == 2 && t.items.findModifier("hemorrhage")->fromTier == 2 &&
                  t.items.findModifier("max_life")->fromTier == 1 && t.items.findModifier("physical_damage")->fromTier == 1,
              "pool: forks and bleeds wait for tier two; life and a small damage add do not");
        const auto* phys = t.items.findModifier("physical_damage");
        check(phys->findTier(1)->maximum <= 0.1 && phys->findTier(3)->maximum <= 0.5,
              "pool: damage adds start small and stay inside the threefold budget");
        const auto* sceptre = t.items.findBase("frost_sceptre");
        check(sceptre->implicitModifiers.size() == 1 && sceptre->implicitModifiers.front().id == "cold_damage",
              "pool: the sceptre's implicit is no longer a fork");
    }

    // Gear drives the grammar: a plain sceptre's implicit fork doubles the orb.
    stats::Equipment worn;
    items::ItemInstance plainSceptre;
    plainSceptre.baseId = "frost_sceptre";
    worn.slots["weapon"] = plainSceptre;
    auto implicitOnly = grammar::gearMods(t.items, worn);
    check(implicitOnly.size() == 1 && implicitOnly.front().source == "weapon" &&
              implicitOnly.front().id == "cold_damage",
          "items: the sceptre's implicit is a small cold add, not a fork (D-020)");
    check(grammar::forkCount(t, implicitOnly, "prototype_frost_orb") == 1, "items: a plain sceptre does not fork");
    plainSceptre.rolledProperties.push_back({"forked_lattice", 2, 1.0});
    worn.slots["weapon"] = plainSceptre;
    auto mods = grammar::gearMods(t.items, worn);
    check(grammar::forkCount(t, mods, "prototype_frost_orb") == 2, "items: a rolled fork counts");
    check(grammar::forkCount(t, mods, "prototype_area_strike") == 0, "items: fork ignores the cone strike");

    // Damage and cooldown modifiers resolve by tag.
    items::ItemInstance mace;
    mace.baseId = "iron_mace";
    mace.rolledProperties.push_back({"swift_hands", 1, 0.25});
    stats::Equipment maced;
    maced.slots["weapon"] = mace;
    auto maceMods = grammar::gearMods(t.items, maced);
    checkNear(grammar::skillDamage(t, maceMods, "prototype_heavy_strike"), 28.0 * 1.1, 1e-9,
              "items: mace implicit is 10% increased physical damage");
    checkNear(grammar::skillDamage(t, maceMods, "prototype_frost_orb"), 9.0, 1e-9,
              "items: physical damage leaves the cold orb alone");
    checkNear(grammar::skillCooldownSeconds(t, maceMods, "prototype_heavy_strike"), 1.4 / 1.25, 1e-9,
              "items: cooldown recovery shortens the cooldown");
    checkNear(grammar::skillCooldownSeconds(t, maceMods, "prototype_dash"), 2.5, 1e-9,
              "items: recovery is attack/spell only, never movement");

    // Character stats read modifiers by effect key, not by id.
    items::ItemInstance chest;
    chest.baseId = "iron_chest_armour";
    chest.implicitProperties["armour"] = 20.0;
    chest.rolledProperties.push_back({"armour_plating", 1, 10.0});
    chest.rolledProperties.push_back({"max_life", 1, 12.0});
    items::ItemInstance charm;
    charm.baseId = "ember_charm";
    stats::Equipment kitted;
    kitted.slots["chest"] = chest;
    kitted.slots["charm"] = charm;
    auto derived = stats::deriveStats(t.world.playerBase, kitted, t.items);
    checkNear(derived.armour, 30.0, 1e-9, "items: armour plating adds to implicit armour");
    checkNear(derived.maxLife, 112.0, 1e-9, "items: life modifier adds");
    checkNear(derived.fireResistancePercent, 5.0, 1e-9, "items: the charm's implicit resistance counts");

    // Sentences a tester can read.
    check(items::modifierSentence(*t.items.findModifier("max_life"), 12.0) == "+12 Maximum Life", "items: flat sentence");
    check(items::modifierSentence(*t.items.findModifier("deep_frost"), 0.5) ==
              "50% increased Chill Buildup for chill skills",
          "items: percent sentence names its tags");

    // Save round-trip keeps pack items with their rarity and modifiers.
    economy::PlayerEconomy player(t);
    player.packItems.push_back(items::rollRarityItem(t.items, "frost_sceptre", "keen", 1, 3));
    save::SaveGame game;
    game.economy = player.exportState();
    save::SaveGame loaded = save::fromJson(save::toJson(game));
    check(loaded.economy.packItems.size() == 1 && loaded.economy.packItems.front().rarity == "keen",
          "items: pack items round-trip with rarity");
    check(loaded.economy.packItems.front().rolledProperties.size() == player.packItems.front().rolledProperties.size(),
          "items: pack item modifiers round-trip");

    // Trial rooms hand out gear; banking lands it in the pack, dying loses it.
    stats::Equipment geared;
    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    armour.implicitProperties["armour"] = 20.0;
    const auto* process = t.crafting.findCatalystProcess("ember_catalyst_tempering");
    items::catalystTemper(t.items, *process, armour, 5, 77);
    geared.slots["chest"] = armour;
    auto gearedStats = stats::deriveStats(t.world.playerBase, geared, t.items);
    boons::BuildTags tags = {"attack", "physical", "area", "single_target", "movement"};
    {
        economy::PlayerEconomy runner(t);
        trial::TrialSession session(t, runner, tags, 1234);
        auto outcome = session.enterRoom(0, gearedStats, combat::autoPolicy);
        check(outcome.combat.victory && outcome.items.empty(), "items: the boon room drops no gear");
        session.acceptBoonFromOffer(outcome.boonOffer.front()->id);
        outcome = session.enterRoom(1, gearedStats, combat::autoPolicy);
        check(outcome.combat.victory && outcome.items.size() == 1 && outcome.items.front().rarity == "keen",
              "items: the materials room drops a keen item");
        check(session.runLootItems().size() == 1, "items: dropped gear waits in run loot");
        outcome = session.enterRoom(0, gearedStats, combat::autoPolicy);
        check(outcome.items.size() == 1 && outcome.items.front().rarity == "wrought", "items: the shrine drops wrought gear");
        session.bankAndExit();
        check(runner.packItems.size() == 2, "items: banked gear lands in the pack");
    }
    {
        economy::PlayerEconomy runner(t);
        trial::TrialSession session(t, runner, tags, 1234);
        auto outcome = session.enterRoom(0, gearedStats, combat::autoPolicy);
        session.acceptBoonFromOffer(outcome.boonOffer.front()->id);
        session.enterRoom(1, gearedStats, combat::autoPolicy);
        auto alwaysDie = [](const combat::CombatView&) { return combat::Action{-1, 0}; };
        session.enterRoom(0, gearedStats, alwaysDie);
        check(session.playerDied() && runner.packItems.empty(), "items: dying loses unbanked gear like other run loot");
    }
}

void testElitesAndFamilies(const tuning::Tuning& t) {
    // Wave 3 mobs: the new families and behaviours load.
    check(t.world.findEnemy("shrieker") != nullptr && t.world.findEnemy("gloom_crawler") != nullptr,
          "mobs: the shrieker and the cave dweller exist");
    const auto* shrieker = t.realtime.findBehaviour("shrieker");
    check(shrieker != nullptr && shrieker->screamRadiusM > 0.0 && shrieker->screamPeriodSeconds > 0.0,
          "mobs: shrieker behaviour carries its scream");
    check(t.realtime.findBehaviour("melee")->screamRadiusM == 0.0,
          "mobs: only the shrieker screams");

    // Elite modifiers: named prefixes interacting with the status grammar.
    check(t.world.eliteModifiers.size() == 4 && t.world.findEliteModifier("unfreezable") != nullptr,
          "elites: four modifiers load");
    const auto* cinder = t.world.findEliteModifier("cinder_blooded");
    check(cinder != nullptr && cinder->deathBurstDamage > 0.0 &&
              std::find(cinder->immuneStatuses.begin(), cinder->immuneStatuses.end(),
                        "ignite") != cinder->immuneStatuses.end(),
          "elites: cinder-blooded bursts on death and will not burn");
    check(t.world.findEliteModifier("nobody") == nullptr, "elites: unknown ids are nothing");

    // Danger rings: packs grow and elites appear only farther out.
    check(t.worldgen.dangerRingAt(200.0)->packSizeBonus > 0 &&
              t.worldgen.dangerRingAt(200.0)->eliteChance > 0.0 &&
              t.worldgen.dangerRingAt(30.0)->eliteChance == 0.0,
          "elites: rings crown elites only beyond the heartland");

    // Generated packs: cave dens exist, elite assignments are valid, and
    // every enemy id resolves.
    auto map = worldgen::generate(t, 7);
    bool cavePack = false;
    int elites = 0;
    bool valid = true;
    for (const auto& pack : map.packs) {
        if (pack.y < map.at(pack.x, pack.z).height) cavePack = true;
        if (pack.eliteMemberIndex >= 0) {
            ++elites;
            if (pack.eliteMemberIndex >= static_cast<int>(pack.enemies.size()) ||
                t.world.findEliteModifier(pack.eliteModifierId) == nullptr)
                valid = false;
        }
        for (const auto& id : pack.enemies)
            if (!t.world.findEnemy(id)) valid = false;
    }
    check(cavePack, "elites: cave packs den underground");
    check(elites > 0 && valid, "elites: far packs carry valid elite crowns");

    // Elite loot: strictly more materials (extra passes only add), and
    // pages drop noticeably more often (the tripled chance).
    const auto* eliteMod = t.world.findEliteModifier("unfreezable");
    auto plainLoot = loot::rollEnemyLoot(t.world, "stone_husk", 99);
    auto eliteLoot = loot::rollEnemyLoot(t.world, "stone_husk", 99, eliteMod);
    bool superset = true;
    int plainTotal = 0, eliteTotal = 0;
    for (const auto& [item, count] : plainLoot) {
        plainTotal += count;
        auto it = eliteLoot.find(item);
        if (it == eliteLoot.end() || it->second < count) superset = false;
    }
    for (const auto& [item, count] : eliteLoot) eliteTotal += count;
    check(superset && eliteTotal > plainTotal,
          "elites: an elite kill pays a strict superset of the plain kill");
    int plainPages = 0, elitePages = 0;
    for (uint64_t s = 0; s < 300; ++s) {
        if (!loot::rollEnemySkillPage(t, "stone_husk", s, {}).empty()) ++plainPages;
        if (!loot::rollEnemySkillPage(t, "stone_husk", s, {}, eliteMod).empty()) ++elitePages;
    }
    check(elitePages > plainPages, "elites: pages concentrate on elite kills");
}


// Wave 4 building lattice: pieces address elements (volume, face, edge) and
// placement is "the nearest free element of the piece's kind".
void testLattice(const tuning::Tuning& t) {
    using namespace lattice;
    const double g = t.construction.gridSizeMetres;
    check(std::abs(g - 1.0) < 1e-9, "lattice: tests assume the 1 m grid from construction.json");

    bool threw = false;
    try {
        slotFromName("roof");
    } catch (const std::exception&) {
        threw = true;
    }
    check(threw, "lattice: unknown element names are rejected at load");
    check(slotFromName("wall") == Slot::Wall && std::string(slotName(Slot::Beam)) == "beam",
          "lattice: slot names round-trip");

    // Poses: faces sit on their plane, edges on their line, volumes in the cell.
    const Element faceX{ElementKind::Face, 0, Cell{10, 12, 10}};
    const Element faceZ{ElementKind::Face, 2, Cell{10, 12, 10}};
    const Element edgeY{ElementKind::Edge, 1, Cell{10, 12, 10}};
    const Element edgeX{ElementKind::Edge, 0, Cell{10, 12, 10}};
    const Element edgeZ{ElementKind::Edge, 2, Cell{10, 12, 10}};
    const Element cube{ElementKind::Volume, 0, Cell{10, 12, 10}};
    auto near = [](const Vec3& a, double x, double y, double z) {
        return std::abs(a.x - x) < 1e-9 && std::abs(a.y - y) < 1e-9 && std::abs(a.z - z) < 1e-9;
    };
    check(near(centre(faceX, g), 10.0, 12.5, 10.5) && yawTurns(faceX) == 1, "lattice: x-face pose");
    check(near(centre(faceZ, g), 10.5, 12.5, 10.0) && yawTurns(faceZ) == 0, "lattice: z-face pose");
    check(near(centre(edgeY, g), 10.0, 12.5, 10.0) && yawTurns(edgeY) == 0, "lattice: vertical edge pose");
    check(near(centre(edgeX, g), 10.5, 12.0, 10.0) && yawTurns(edgeX) == 0, "lattice: x-edge pose");
    check(near(centre(edgeZ, g), 10.0, 12.0, 10.5) && yawTurns(edgeZ) == 1, "lattice: z-edge turns a quarter");
    check(near(centre(cube, g), 10.5, 12.5, 10.5), "lattice: volume pose");
    check(slotAccepts(Slot::Wall, faceX) && !slotAccepts(Slot::Wall, Element{ElementKind::Face, 1, Cell{}}) &&
              slotAccepts(Slot::Floor, Element{ElementKind::Face, 1, Cell{}}) && slotAccepts(Slot::Post, edgeY) &&
              !slotAccepts(Slot::Post, edgeX) && slotAccepts(Slot::Beam, edgeX) && slotAccepts(Slot::Block, cube),
          "lattice: slots accept only their element kind");

    // A wall aimed at the ground stands ON the ground, in the nearest plane.
    auto walls = candidates(Slot::Wall, Vec3{10.4, 12.0, 10.3}, Vec3{0, 1, 0}, g);
    check(walls.size() == 4, "lattice: four vertical planes box a ground hit in");
    check(walls[0] == faceZ, "lattice: the nearest plane wins (z = 10, closest to the crosshair)");
    check(walls[0].cell.y == 12, "lattice: a wall on the ground rises from it, not below it");
    // ...and aimed at a ceiling hangs from it.
    auto hanging = candidates(Slot::Wall, Vec3{10.4, 15.0, 10.3}, Vec3{0, -1, 0}, g);
    check(hanging[0].cell.y == 14, "lattice: a wall aimed at a ceiling hangs below it");

    // One face, one address: the wall's two sides resolve to the same element.
    auto fromPlusX = candidates(Slot::Wall, Vec3{10.125, 12.5, 10.5}, Vec3{1, 0, 0}, g);
    auto fromMinusX = candidates(Slot::Wall, Vec3{9.875, 12.5, 10.5}, Vec3{-1, 0, 0}, g);
    check(fromPlusX[0] == faceX && fromMinusX[0] == faceX, "lattice: a face has one address from either side");

    // Blocks: the cell on the open side of what you hit, and only that.
    auto onTop = candidates(Slot::Block, Vec3{10.5, 13.0, 10.5}, Vec3{0, 1, 0}, g);
    check(onTop.size() == 1 && onTop[0] == Element{ElementKind::Volume, 0, Cell{10, 13, 10}},
          "lattice: a block aimed at a cube's top stacks on it");
    auto besideWall = candidates(Slot::Block, Vec3{10.125, 12.5, 10.5}, Vec3{1, 0, 0}, g);
    auto behindWall = candidates(Slot::Block, Vec3{9.875, 12.5, 10.5}, Vec3{-1, 0, 0}, g);
    check(besideWall[0].cell == Cell{10, 12, 10} && behindWall[0].cell == Cell{9, 12, 10},
          "lattice: a wall's two sides offer the two cells it divides");

    // Posts: aim at a post's top and the next one stacks; aim at its side
    // and, the post's own edge being taken, the edge beside it comes next.
    // The registry runs at half cells: a full-size piece anchors at the
    // scaled element and covers a footprint of registry elements.
    const int div = t.construction.latticeDivisions;
    auto piece = [&](const Element& coarse, Slot slot, const char* shape, int tall = 1) {
        Piece p;
        p.anchor = scaled(coarse, div);
        p.slot = slot;
        p.footprint = footprint(p.anchor, div, tall);
        p.shapeId = shape;
        p.family = "wood";
        return p;
    };
    Structure s;
    check(s.place(piece(edgeY, Slot::Post, "pillar")), "lattice: post placed");
    check(s.occupied(scaled(edgeY, div)) && s.occupied(Element{ElementKind::Edge, 1, Cell{20, 25, 20}}) &&
              !s.occupied(Element{ElementKind::Edge, 1, Cell{20, 26, 20}}),
          "lattice: a full-size post covers two registry edges, no more");
    auto stacked = candidates(Slot::Post, Vec3{10.0, 13.0, 10.05}, Vec3{0, 1, 0}, g);
    check(stacked[0] == Element{ElementKind::Edge, 1, Cell{10, 13, 10}}, "lattice: a post on a post stacks");
    auto beside = candidates(Slot::Post, Vec3{10.15, 12.5, 10.02}, Vec3{1, 0, 0}, g);
    check(beside.size() == 4 && beside[0] == edgeY && s.occupied(scaled(beside[0], div)) &&
              !s.occupied(scaled(beside[1], div)) && beside[1] == Element{ElementKind::Edge, 1, Cell{11, 12, 10}},
          "lattice: the taken edge ranks first, the free edge beside it second");

    // Beams: the top of a wall offers the wall plate along it first.
    auto plate = candidates(Slot::Beam, Vec3{10.5, 13.0, 10.0}, Vec3{0, 1, 0}, g);
    check(plate.size() == 8 && plate[0] == Element{ElementKind::Edge, 0, Cell{10, 13, 10}},
          "lattice: a beam aimed at a wall's top runs along it");

    // Footprints and poses.
    check(footprint(scaled(cube, div), div, 1).size() == 8 && footprint(scaled(faceX, div), div, 1).size() == 4 &&
              footprint(scaled(edgeY, div), div, 1).size() == 2 && footprint(scaled(edgeX, div), div, 1).size() == 2,
          "lattice: a cube covers eight fine volumes, a wall four faces, a post or beam two edges");
    check(footprint(scaled(faceX, div), div, 2).size() == 8, "lattice: a two-cell door covers eight fine faces");
    {
        // Interiors (owner playtest 3 Sep: a cube straddling a wall): a block
        // owns the faces and edges inside it, a wall the edges inside it.
        auto cubeAll = withInterior(footprint(scaled(cube, div), div, 1));
        int faces = 0, edges = 0;
        for (const auto& e : cubeAll) { if (e.kind == ElementKind::Face) ++faces; if (e.kind == ElementKind::Edge) ++edges; }
        check(cubeAll.size() == 8 + 12 + 6 && faces == 12 && edges == 6,
              "lattice: a full block owns its 12 interior faces and 6 interior edges");
        auto wallAll = withInterior(footprint(scaled(faceX, div), div, 1));
        check(wallAll.size() == 4 + 4, "lattice: a full wall owns the 4 edges between its fine faces");
        Structure s2;
        Piece block;
        block.anchor = scaled(cube, div);
        block.footprint = cubeAll;
        check(s2.place(block), "lattice: the block places");
        Element midFace = block.anchor;
        midFace.kind = ElementKind::Face; midFace.axis = 0; midFace.cell.x += 1;
        check(s2.occupied(midFace), "lattice: the plane through the block's middle is taken");
        Piece wall;
        wall.anchor = midFace;
        wall.footprint = withInterior(footprint(midFace, div, 1));
        check(!s2.place(wall), "lattice: a wall cannot stand through the middle of a block");
        Element sideFace = block.anchor;
        sideFace.kind = ElementKind::Face; sideFace.axis = 0;
        Piece beside;
        beside.anchor = sideFace;
        beside.footprint = withInterior(footprint(sideFace, div, 1));
        check(s2.place(beside), "lattice: a wall on the block's own side face still stands");
        check(s2.remove(midFace) && !s2.occupied(block.anchor), "lattice: removing by an interior element removes the block");
    }
    check(footprint(scaled(edgeX, div), div, 1, 2).size() == 4 &&
              near(footprintCentre(scaled(edgeX, div), div, 1, g / div, 2), 11.0, 12.0, 10.0),
          "lattice: a two-cell girder covers four fine edges and is posed at their middle");
    const double fine = g / div;
    check(near(footprintCentre(scaled(cube, div), div, 1, fine), 10.5, 12.5, 10.5) &&
              near(footprintCentre(scaled(faceX, div), div, 1, fine), 10.0, 12.5, 10.5) &&
              near(footprintCentre(scaled(faceX, div), div, 2, fine), 10.0, 13.0, 10.5) &&
              near(footprintCentre(scaled(edgeY, div), div, 1, fine), 10.0, 12.5, 10.0) &&
              near(footprintCentre(scaled(edgeZ, div), div, 1, fine), 10.0, 12.0, 10.5),
          "lattice: a footprint's centre is the full-size element's centre");
    Element fineCube{ElementKind::Volume, 0, Cell{20, 24, 20}};
    check(footprint(fineCube, 1, 1).size() == 1 && near(footprintCentre(fineCube, 1, 1, fine), 10.25, 12.25, 10.25),
          "lattice: a fine piece is one registry element");

    // Occupancy is a set: one piece per element, and any covered element
    // finds (and removes) the whole piece.
    check(!s.place(piece(edgeY, Slot::Post, "pillar")), "lattice: a taken element refuses a second piece");
    check(s.at(Element{ElementKind::Edge, 1, Cell{20, 25, 20}})->shapeId == "pillar",
          "lattice: every covered element finds its piece");
    check(s.remove(Element{ElementKind::Edge, 1, Cell{20, 25, 20}}) && !s.occupied(scaled(edgeY, div)) &&
              !s.remove(scaled(edgeY, div)),
          "lattice: removing through any covered element frees the whole piece once");
    // A door straddles a wall's cell and the one above: it refuses a wall there.
    check(s.place(piece(faceX, Slot::Wall, "door", 2)), "lattice: door placed");
    check(!s.place(piece(Element{ElementKind::Face, 0, Cell{10, 13, 10}}, Slot::Wall, "wall_panel")),
          "lattice: the face above a door is the door's");
    check(s.place(piece(Element{ElementKind::Face, 0, Cell{10, 14, 10}}, Slot::Wall, "wall_panel")),
          "lattice: the face above that is free");
    // A fine cube shares a cell with nothing full-size, but two fit side by side.
    s.clear();
    Piece half;
    half.anchor = fineCube;
    half.slot = Slot::Block;
    half.footprint = footprint(fineCube, 1, 1);
    half.shapeId = "half_cube";
    check(s.place(half), "lattice: a fine cube takes one registry volume");
    check(!s.place(piece(cube, Slot::Block, "cube")), "lattice: a full cube cannot share the cell");
    Piece other = half;
    other.anchor = Element{ElementKind::Volume, 0, Cell{21, 24, 20}};
    other.footprint = footprint(other.anchor, 1, 1);
    check(s.place(other), "lattice: two fine cubes share the cell");

    // Corner trims (at registry resolution: a full-size wall's end is two
    // stacked fine edges): a lone panel gets posts at both ends, a straight
    // run only at its ends, an L at the corner too, and a real post replaces one.
    s.clear();
    s.place(piece(faceX, Slot::Wall, "wall_panel"));
    check(s.trimEdges().size() == 4, "trim: a lone panel is framed at both ends");
    s.place(piece(Element{ElementKind::Face, 0, Cell{10, 12, 11}}, Slot::Wall, "wall_panel"));
    auto run = s.trimEdges();
    check(run.size() == 4, "trim: a straight run stays a wall between its ends");
    s.place(piece(Element{ElementKind::Face, 2, Cell{10, 12, 12}}, Slot::Wall, "wall_panel"));
    auto corner = s.trimEdges();
    const Element cornerEdge{ElementKind::Edge, 1, Cell{20, 24, 24}};
    check(corner.size() == 6 && std::find(corner.begin(), corner.end(), cornerEdge) != corner.end(),
          "trim: walls meeting at an angle grow a corner post");
    check(s.wallsAt(cornerEdge).size() == 2, "trim: the corner edge sees both walls");
    s.place(piece(Element{ElementKind::Edge, 1, Cell{10, 12, 12}}, Slot::Post, "pillar"));
    check(s.trimEdges().size() == 4, "trim: a placed post takes over its corner");
    // A door in a run is a wall for trims: no post grows between them.
    s.clear();
    s.place(piece(faceX, Slot::Wall, "wall_panel"));
    s.place(piece(Element{ElementKind::Face, 0, Cell{10, 12, 11}}, Slot::Wall, "door", 2));
    // Wall end (2), door's far edge (4), and the door's upper half where it
    // rises past the one-cell wall (2): no post grows in the seam itself.
    check(s.trimEdges().size() == 8, "trim: a door continues the run at the seam and is framed where it rises past it");

    // Touching: a piece counts as near the structure when its footprint's
    // box, grown by the margin, holds any placed element.
    s.clear();
    s.place(piece(Element{ElementKind::Edge, 0, Cell{10, 13, 10}}, Slot::Beam, "beam")); // registry (20,26,20)-(21,26,20)
    check(s.near(footprint(scaled(Element{ElementKind::Edge, 0, Cell{11, 13, 10}}, div), div, 1), 0),
          "near: the beam continuing along the same line touches");
    check(s.near(footprint(scaled(Element{ElementKind::Volume, 0, Cell{10, 12, 10}}, div), div, 1), 0),
          "near: the cube under the beam touches");
    check(!s.near(footprint(scaled(Element{ElementKind::Edge, 0, Cell{14, 13, 10}}, div), div, 1), 1),
          "near: a beam three cells on does not");

    // Enclosure (slice 3): a hut is a shelter, a hut with a wall missing is
    // not, a door keeps it one, and a hall past the cap is outside.
    check(t.world.shelter.regenLifePerRound > 0.0 && t.world.shelter.maxRoomCells > 0 &&
              t.world.shelter.settleRounds >= 0.0,
          "shelter: tunables load from world.json");
    // World: solid ground below y = 0, open sky above registry y = 40, edges far away.
    auto ground = [](const Cell& c) {
        if (c.y < 0) return WorldCell::Solid;
        if (c.y >= 40) return WorldCell::Outside;
        return WorldCell::Open;
    };
    s.clear();
    const int cap = t.world.shelter.maxRoomCells * div * div * div;
    const Element inside{ElementKind::Volume, 0, Cell{1, 1, 1}}; // registry cell inside build cell (0,0,0)
    check(!enclosure(s, inside, cap, ground).enclosed, "shelter: open ground is no shelter");
    // Walls two tall around build cell (0, 0..1, 0), roof slab at y = 2.
    auto wall = [&](int axis, int x, int y, int z) {
        s.place(piece(Element{ElementKind::Face, axis, Cell{x, y, z}}, Slot::Wall, "wall_panel"));
    };
    for (int y = 0; y < 2; ++y) {
        wall(0, 0, y, 0);
        wall(0, 1, y, 0);
        wall(2, 0, y, 0);
        wall(2, 0, y, 1);
    }
    check(!enclosure(s, inside, cap, ground).enclosed, "shelter: four walls with no roof is a yard");
    s.place(piece(Element{ElementKind::Face, 1, Cell{0, 2, 0}}, Slot::Floor, "floor_slab"));
    auto hut = enclosure(s, inside, cap, ground);
    check(hut.enclosed && hut.volumes == 2 * div * div * div, "shelter: walls, ground and a roof make a two-cell hut");
    // Swap the front wall for a door: still a shelter, open or shut.
    s.remove(scaled(Element{ElementKind::Face, 2, Cell{0, 0, 0}}, div));
    s.remove(scaled(Element{ElementKind::Face, 2, Cell{0, 1, 0}}, div));
    check(!enclosure(s, inside, cap, ground).enclosed, "shelter: a missing wall lets the fill out");
    s.place(piece(Element{ElementKind::Face, 2, Cell{0, 0, 0}}, Slot::Wall, "door", 2));
    check(enclosure(s, inside, cap, ground).enclosed, "shelter: a door seals the hut");
    // A dug-out hollow: solid rock all round, one open cell, a slab over it.
    auto rock = [](const Cell& c) {
        const bool hollow = c.x >= 10 && c.x < 12 && c.y >= 0 && c.y < 2 && c.z >= 10 && c.z < 12;
        const bool shaft = c.x >= 10 && c.x < 12 && c.y >= 2 && c.y < 40 && c.z >= 10 && c.z < 12;
        if (hollow || shaft) return c.y >= 40 ? WorldCell::Outside : WorldCell::Open;
        return c.y >= 40 ? WorldCell::Outside : WorldCell::Solid;
    };
    const Element hollowCell{ElementKind::Volume, 0, Cell{10, 0, 10}};
    check(!enclosure(s, hollowCell, cap, rock).enclosed, "shelter: a hollow open to the sky is a pit");
    s.place(piece(Element{ElementKind::Face, 1, Cell{5, 1, 5}}, Slot::Floor, "floor_slab")); // registry (10, 2, 10)
    check(enclosure(s, hollowCell, cap, rock).enclosed, "shelter: a slab over the mouth makes the hollow a den");
    // Too big: a room past the cap reads as outside.
    check(!enclosure(s, hollowCell, 3, rock).enclosed, "shelter: a room past the cap is not a shelter");
}

// Eras (D-019): the world's state follows milestones, in order.
void testEras(const tuning::Tuning& t) {
    check(t.eras.eras.size() >= 2 && t.eras.eras.front().triggerWorldEffect.empty(), "eras: load in order from the start");
    economy::PlayerEconomy player(t);
    check(player.currentEra() == 1 && player.era().id == "valley", "eras: a new game is era one");
    check(player.era().mechanic("ash_hound", "pack_size_bonus") == nullptr, "eras: era one has no mechanics");
    player.recordWorldEffect(t.eras.eras[1].triggerWorldEffect);
    check(player.currentEra() == 2 && player.era().id == "deep_wakes", "eras: the Tyrant's fall wakes the deep");
    const auto* bonus = player.era().mechanic("ash_hound", "pack_size_bonus");
    check(bonus != nullptr && bonus->at("value") == 1.0, "eras: hounds gain a pack member");
    const auto* burn = player.era().mechanic("ember_whelp", "burning_ground");
    check(burn != nullptr && burn->at("seconds") > 0.0 && burn->at("damage_per_round") > 0.0,
          "eras: whelps burn where they die");
    // Era nodes: copper and tin surface in the deep, and the world map places them.
    const auto* copper = t.worldgen.nodeTypes.count("copper_vein") ? &t.worldgen.nodeTypes.at("copper_vein") : nullptr;
    check(copper != nullptr && copper->era == 2 && t.worldgen.nodeTypes.at("iron_vein").era == 1,
          "eras: copper is an era-two node type");
    auto map = worldgen::generate(t, 3);
    int copperNodes = 0, tinNodes = 0;
    for (const auto& n : map.nodes) {
        if (n.type == "copper_vein") ++copperNodes;
        if (n.type == "tin_vein") ++tinNodes;
    }
    check(copperNodes > 0 && tinNodes > 0, "eras: the map holds era-two veins from the seed");
    // Bronze: the alloy needs the new ores and is malleable.
    check(t.crafting.findRecipe("smelt_bronze") != nullptr, "eras: bronze recipe loads");
    const auto* bronze = t.construction.findMaterial("bronze");
    check(bronze != nullptr && bronze->hasTrait("malleable") && bronze->source == "bronze_ingot",
          "eras: bronze is the malleable family");
    check(player.shapeAllowsFamily("arch", "bronze") && !player.shapeAllowsFamily("arch", "iron"),
          "eras: the arch is worked from bronze, not iron");
}

// The Foundry (D-019, D-023): ingots from milestones on the frame the era
// has forged; sockets take tablets; supports, backing and pairs are the
// build.
void testFoundry(const tuning::Tuning& t) {
    const auto& f = t.foundry;
    check(f.ingots.size() >= 8 && f.pairs.size() >= 6 && f.sources.size() >= 8, "foundry: ingots, pairs and sources load");
    check(f.frameRows == 4 && f.frameCols == 4 && f.sockets.size() == 2 && f.rowsByEra.size() == 3,
          "foundry: a 4x4 frame, two sockets, three eras of rows");
    check(f.findPair("ember", "reach") != nullptr && f.findPair("reach", "ember") != nullptr, "foundry: pairs are unordered");
    check(f.findIngot("reach") != nullptr && f.findIngot("reach")->supportModifier() == "reach" &&
              f.findIngot("frost")->supportModifier() == "cold_damage",
          "foundry: reach speaks its own modifier beside a skill; the rest speak their base");
    economy::PlayerEconomy player(t);
    auto plate = player.plate();
    check(plate.rows == 4 && plate.cols == 4 && plate.firstRow == 1 && plate.lastRow == 2 && plate.forgedRows() == 2,
          "foundry: era one forges rows one and two of the frame");
    check(plate.isSocket(1, 1) && plate.isSocket(2, 2) && !plate.isSocket(1, 2), "foundry: the sockets sit on the diagonal");
    check(plate.forged(1, 0) && plate.forged(2, 3) && !plate.forged(0, 0) && !plate.forged(3, 3) && !plate.forged(1, 4),
          "foundry: forged means inside the frame and in a forged row");
    check(player.foundryEvent("first_kill:ember_whelp") == std::vector<std::string>{"ember"}, "foundry: a first kill forges its ingot");
    check(player.foundryEvent("first_kill:ember_whelp").empty(), "foundry: each source grants once");
    check(player.foundryEvent("era:2").empty(), "foundry: an era-two source waits for its era");
    check(player.foundryEvent("first_kill:cinder_archer") == std::vector<std::string>{"reach"}, "foundry: another family, another ingot");
    check(foundry::unplacedCount(player.foundry(), "ember") == 1, "foundry: owned but unplaced");
    // Placement rules: forged cells only, never a socket, one thing per cell.
    check(!player.foundryPlace(0, 0, "ember") && !player.foundryPlace(3, 0, "ember"), "foundry: an unforged row is refused");
    check(!player.foundryPlace(1, 1, "ember") && !player.foundryPlace(2, 2, "ember"), "foundry: a socket takes no ingot");
    check(!player.foundryPlace(1, 0, "frost"), "foundry: an unowned ingot is refused");
    check(player.foundryPlace(1, 0, "ember") && !player.foundryPlace(1, 0, "reach"), "foundry: a cell holds one ingot");
    check(!player.foundryPlace(2, 0, "ember"), "foundry: an ingot places once");
    check(player.foundryPlace(2, 0, "reach"), "foundry: reach below ember");
    auto effects = foundry::effects(t, player.foundry(), plate);
    int ingots = 0, pairs = 0, others = 0;
    for (const auto& e : effects) {
        if (e.kind == "ingot") ++ingots;
        else if (e.kind == "pair") ++pairs;
        else ++others;
    }
    check(ingots == 2 && pairs == 1 && others == 0 && effects.back().label == "Wildfire",
          "foundry: two ingots and the Wildfire pair, nothing else");
    check(effects.front().cellRow == 1 && effects.front().cellCol == 0, "foundry: an effect names the cell it comes from");
    // The plate speaks in modifiers: fire damage up, proliferate reach up.
    auto mods = grammar::foundryMods(t, player.foundry(), player.currentEra());
    bool fire = false, wildfire = false;
    for (const auto& m : mods) {
        if (m.id == "fire_damage" && m.source == "foundry:ingot") fire = true;
        if (m.id == "wildfire_reach" && m.source == "foundry:pair") wildfire = true;
    }
    check(fire && wildfire, "foundry: effects resolve through the item modifier pool");
    check(grammar::resolve(mods, {"fire", "spell"}, "damage", 100.0) > 100.0, "foundry: an ember ingot raises fire damage");

    // D-022 skills on the plate, D-023 sockets: a known skill's tablet goes
    // in a socket; the ingots beside it support it, alone, at
    // support_multiplier; a verb that cannot read the skill does nothing
    // yet; tablets lift free; the save keeps it.
    {
        economy::PlayerEconomy sup(t);
        sup.foundryEvent("first_kill:ember_whelp");   // ember (fire)
        sup.foundryEvent("recipe:workbench_kit");     // vigour (self)
        check(!sup.foundryPlaceSkill(1, 1, "prototype_ember_bolt"), "plate: an unknown skill has no tablet");
        check(!sup.foundryPlaceSkill(1, 0, "prototype_frost_orb") && !sup.foundryPlaceSkill(0, 1, "prototype_frost_orb"),
              "plate: a tablet goes in a socket, on a forged row");
        check(sup.foundryPlaceSkill(1, 1, "prototype_frost_orb"), "plate: a known skill lays its tablet in a socket");
        check(!sup.foundryPlaceSkill(1, 1, "prototype_heavy_strike") && !sup.foundryPlaceSkill(2, 2, "prototype_frost_orb"),
              "plate: one tablet per socket, one per skill");
        check(!sup.foundryPlace(1, 1, "ember"), "plate: an ingot cannot take a tablet's socket");
        // A frost ingot through whichever source grants one.
        std::string frostSource;
        for (const auto& src : t.foundry.sources) if (src.ingot == "frost" && src.era <= 1) { frostSource = src.event; break; }
        check(!frostSource.empty() && !sup.foundryEvent(frostSource).empty(), "plate: an era-one source grants frost");
        check(sup.foundryPlace(1, 0, "frost") && sup.foundryPlace(2, 1, "ember") && sup.foundryPlace(1, 2, "vigour"),
              "plate: frost, ember and vigour laid around the orb's socket");
        auto fx = foundry::effects(t, sup.foundry(), sup.plate());
        int supports = 0, added = 0;
        bool frostSupport = false, emberSupport = false, vigourSheet = false, vigourWeak = false, emberAdded = false;
        for (const auto& e : fx) {
            if (e.kind == "added") {
                ++added;
                if (e.modifier == "added_fire" && e.skill == "prototype_frost_orb" && e.cellRow == 2 && e.cellCol == 1) emberAdded = true;
            }
            if (e.kind != "support") continue;
            ++supports;
            check(e.skill == "prototype_frost_orb" && e.row == 1 && e.col == 1 && e.cellRow == 1 &&
                      (e.cellCol == 0 || e.cellCol == 2),
                  "plate: a support names its skill, its socket and its cell");
            if (e.modifier == "cold_damage") frostSupport = true;
            if (e.modifier == "fire_damage") emberSupport = true;
            if (e.modifier == "max_life") vigourSheet = true;
            if (e.modifier == "life_on_kill") vigourWeak = true;
        }
        // Slice 2 (owner, 4 Sep 2026): every ingot reads every skill.
        check(supports == 2 && frostSupport && !emberSupport && added == 1 && emberAdded && vigourWeak && !vigourSheet,
              "plate: frost supports the cold orb, ember adds fire to it, vigour reads it weakly");
        for (const auto& e : fx)
            if (e.kind == "support" && e.modifier == "cold_damage")
                checkNear(e.value, t.foundry.findIngot("frost")->value * t.foundry.supportMultiplier, 1e-9,
                          "plate: a support is the ingot's value times support_multiplier");
        auto supMods = grammar::foundryMods(t, sup.foundry(), sup.currentEra());
        double orb = grammar::resolve(supMods, t.skills.findCombatSkill("prototype_frost_orb")->resolveTags(), "damage", 100.0);
        double nova = grammar::resolve(supMods, t.skills.findCombatSkill("prototype_frost_nova")->resolveTags(), "damage", 100.0);
        check(orb > nova && nova > 100.0, "plate: the orb gets the support on top of what the frost ingot gives every cold skill");
        check(sup.foundryRemove(1, 1) && foundry::tabletFor(sup.foundry(), "prototype_frost_orb") == nullptr,
              "plate: a tablet lifts for free");
        check(sup.foundryPlaceSkill(1, 1, "prototype_frost_orb"), "plate: and can be laid again");
        // Save round trip keeps the tablet.
        save::SaveGame gs;
        gs.economy = sup.exportState();
        auto back = save::fromJson(save::toJson(gs));
        check(foundry::tabletFor(back.economy.foundry, "prototype_frost_orb") != nullptr, "plate: the tablet rides in the save");
        bool sourceMasonry = false;
        for (const auto& src : t.foundry.sources) if (src.event == "recipe:dress_stone") sourceMasonry = true;
        check(sourceMasonry, "plate: the first dressed block is a milestone");
    }
    // Reach reads area, projectile and strike skills (owner, 4 Sep 2026):
    // a wider area, a further-flying projectile, a longer strike - one
    // 'reach' multiplier the engine applies to the delivery it owns.
    {
        economy::PlayerEconomy reacher(t);
        reacher.foundryEvent("first_kill:cinder_archer"); // reach
        check(reacher.foundryPlace(1, 0, "reach") && reacher.foundryPlaceSkill(1, 1, "prototype_frost_orb"),
              "reach: an ingot beside the orb's socket");
        auto fx = foundry::effects(t, reacher.foundry(), reacher.plate());
        bool reachSupport = false;
        for (const auto& e : fx) if (e.kind == "support" && e.modifier == "reach" && e.skill == "prototype_frost_orb") reachSupport = true;
        check(reachSupport, "reach: the ingot supports the projectile through the reach modifier");
        auto rm = grammar::foundryMods(t, reacher.foundry(), reacher.currentEra());
        checkNear(grammar::skillReach(t, rm, "prototype_frost_orb"), 1.0 + t.foundry.findIngot("reach")->value * t.foundry.supportMultiplier,
                  1e-9, "reach: the orb flies further by the ingot's value times support_multiplier");
        checkNear(grammar::skillReach(t, rm, "prototype_dash"), 1.0, 1e-9, "reach: a movement skill is untouched");
        checkNear(grammar::skillReach(t, rm, "prototype_frost_nova"), 1.0, 1e-9, "reach: a skill not in the socket is untouched");
        check(reacher.foundryRemove(1, 1) && reacher.foundryPlaceSkill(1, 1, "prototype_heavy_strike"), "reach: the strike takes the socket");
        rm = grammar::foundryMods(t, reacher.foundry(), reacher.currentEra());
        check(grammar::skillReach(t, rm, "prototype_heavy_strike") > 1.15, "reach: a strike reaches further");
        check(reacher.foundryRemove(1, 1) && reacher.foundryPlaceSkill(1, 1, "prototype_area_strike"), "reach: the area strike takes the socket");
        rm = grammar::foundryMods(t, reacher.foundry(), reacher.currentEra());
        check(grammar::skillReach(t, rm, "prototype_area_strike") > 1.15, "reach: an area grows wider");
        // The base stays a sheet stat: area_size on the sheet, from anywhere on the plate.
        bool sheet = false;
        for (const auto& m : rm) if (m.id == "area_size" && m.source == "foundry:ingot") sheet = true;
        check(sheet, "reach: the ingot's base is still area size on the sheet");
    }
    // Backing replaces lines (owner, 4 Sep 2026): a matching ingot touching a
    // support from any side but the socket's makes the support count once
    // more. Two touching ingots, any direction, instead of three in a line.
    {
        economy::PlayerEconomy backer(t);
        int frosts = 0;
        for (const auto& src : t.foundry.sources)
            if (src.ingot == "frost" && src.era <= 1 && !backer.foundryEvent(src.event).empty()) ++frosts;
        check(frosts >= 2, "backing: era one forges two frosts");
        check(backer.foundryPlaceSkill(1, 1, "prototype_frost_orb") && backer.foundryPlace(1, 0, "frost"), "backing: the orb and its frost support");
        auto lone = grammar::foundryMods(t, backer.foundry(), backer.currentEra());
        const double alone = grammar::resolve(lone, t.skills.findCombatSkill("prototype_frost_orb")->resolveTags(), "damage", 100.0);
        check(backer.foundryPlace(2, 0, "frost"), "backing: a second frost below the support");
        auto fx = foundry::effects(t, backer.foundry(), backer.plate());
        int supports = 0, backings = 0;
        for (const auto& e : fx) {
            if (e.kind == "support") ++supports;
            if (e.kind == "backing") {
                ++backings;
                check(e.skill == "prototype_frost_orb" && e.modifier == "cold_damage" && e.cellRow == 2 && e.cellCol == 0 &&
                          std::abs(e.value - t.foundry.findIngot("frost")->value * t.foundry.supportMultiplier) < 1e-9,
                      "backing: names the skill, the backing cell, and counts the support once more");
            }
            check(e.kind != "line", "backing: the line rule is gone");
        }
        check(supports == 1 && backings == 1, "backing: one support, one backing");
        auto backed = grammar::foundryMods(t, backer.foundry(), backer.currentEra());
        const double withBacking = grammar::resolve(backed, t.skills.findCombatSkill("prototype_frost_orb")->resolveTags(), "damage", 100.0);
        check(withBacking > alone + 1.0, "backing: the orb hits harder for the second frost");
        // A matching ingot that does not touch the support (across the socket) backs nothing.
        backer.inventory["iron_ingot"] = 1;
        check(backer.foundryRemove(2, 0) && backer.foundryPlace(1, 2, "frost"), "backing: the second frost moved beside the socket");
        fx = foundry::effects(t, backer.foundry(), backer.plate());
        supports = 0; backings = 0;
        for (const auto& e : fx) { if (e.kind == "support") ++supports; if (e.kind == "backing") ++backings; }
        check(supports == 2 && backings == 0, "backing: two supports that do not touch back nothing");
    }
    // Era two forges the row above; the plate grows without moving anything.
    economy::PlayerEconomy liner(t);
    liner.foundryEvent("first_kill:ember_whelp");
    liner.foundryEvent("recipe:smelt_iron");
    liner.foundryPlace(1, 0, "ember");
    liner.recordWorldEffect("stonecut_blocks"); // ward - and it wakes era two, era:2 grants reach
    check(liner.currentEra() == 2 && liner.plate().firstRow == 0 && liner.plate().lastRow == 2 && liner.plate().forged(0, 0),
          "foundry: era two forges the row above");
    check(foundry::at(liner.foundry(), 1, 0) != nullptr && foundry::at(liner.foundry(), 1, 0)->ingot == "ember",
          "foundry: what was placed stays where it was");
    check(liner.foundryEvent("era:2").empty() && foundry::unplacedCount(liner.foundry(), "reach") == 1,
          "foundry: the era transition granted its ingot itself");
    liner.foundryEvent("first_kill:ember_whelp"); // no double grant
    check(liner.foundryPlace(0, 0, "ember") && foundry::unplacedCount(liner.foundry(), "ember") == 0, "foundry: the new row takes an ingot");
    // Re-forging pays metal.
    check(!liner.foundryRemove(0, 0) && liner.foundry().plate.size() == 2, "foundry: lifting an ingot needs the metal");
    liner.inventory["iron_ingot"] = 1;
    check(liner.foundryRemove(0, 0) && liner.inventory["iron_ingot"] == 0 && foundry::unplacedCount(liner.foundry(), "ember") == 1,
          "foundry: re-forging spends the metal and frees the ingot");
    check(!liner.foundryRemove(2, 3), "foundry: an empty cell lifts nothing");
    // Saves carry the plate.
    save::SaveGame game;
    game.economy = player.exportState();
    auto text = save::toJson(game);
    auto back = save::fromJson(text);
    check(back.economy.foundry.plate.size() == 2 && back.economy.foundry.owned.at("ember") == 1 &&
              back.economy.foundry.milestones.size() == 2,
          "foundry: the plate, the ingots and the milestones round-trip through the save");
    economy::PlayerEconomy restored(t);
    restored.importState(back.economy);
    check(restored.foundry().plate.size() == 2 && restored.foundryEvent("first_kill:ember_whelp").empty(),
          "foundry: a restored save remembers what it already granted");
    // A save the frame cannot hold is lifted free on load (D-023): an
    // unforged row, a tablet outside a socket, an ingot inside one, a second
    // thing on a cell. Nothing is lost - the ingots return to the tray.
    {
        economy::PlayerEconomy::State stale = player.exportState();
        stale.foundry.plate.clear();
        stale.foundry.owned = {{"ember", 2}, {"frost", 2}};
        stale.foundry.plate.push_back({0, 0, "ember", ""});                      // unforged in era one
        stale.foundry.plate.push_back({1, 0, "", "prototype_frost_orb"});        // a tablet outside a socket
        stale.foundry.plate.push_back({1, 1, "ember", ""});                      // an ingot in a socket
        stale.foundry.plate.push_back({1, 2, "frost", ""});                      // fine
        stale.foundry.plate.push_back({1, 2, "frost", ""});                      // a second thing on the cell
        stale.foundry.plate.push_back({2, 2, "", "prototype_heavy_strike"});     // fine
        economy::PlayerEconomy loaded(t);
        loaded.importState(stale);
        const auto& kept = loaded.foundry().plate;
        check(kept.size() == 2 && foundry::at(loaded.foundry(), 1, 2) != nullptr && foundry::tabletFor(loaded.foundry(), "prototype_heavy_strike") != nullptr,
              "foundry: a stale plate keeps only what the frame holds");
        check(foundry::unplacedCount(loaded.foundry(), "ember") == 2 && foundry::unplacedCount(loaded.foundry(), "frost") == 1,
              "foundry: lifted ingots are back in the tray");
        foundry::State again = loaded.foundry();
        check(foundry::validate(again, loaded.plate()) == 0, "foundry: a valid plate lifts nothing");
    }
}

// Items as mechanics (D-019): tiers carry breakpoints, bases cap tiers,
// held-back rolls speak at the cap, transfers unleash them, eras raise
// drop tiers.
void testItemsAsMechanics(const tuning::Tuning& t) {
    const auto* cold = t.items.findModifier("cold_damage");
    check(cold && cold->findTier(3) != nullptr && !cold->findTier(2)->breakpoints.empty(),
          "items: cold damage has a third tier and a tier-two breakpoint");
    const auto* iron = t.items.findBase("frost_sceptre");
    const auto* bronze = t.items.findBase("bronze_sceptre");
    check(iron && iron->tierCap == 2 && bronze && bronze->tierCap == 3 && bronze->slot == "weapon",
          "items: iron holds two tiers, bronze three");
    // A tier-three cold roll on iron is held back to tier two's best.
    items::ItemInstance sceptre;
    sceptre.baseId = "frost_sceptre";
    sceptre.rarity = "keen";
    sceptre.rolledProperties.push_back({"cold_damage", 3, 0.45});
    const auto eff = items::effectiveRoll(t.items, sceptre, sceptre.rolledProperties.front());
    check(eff.heldBack && eff.tier == 2 && std::abs(eff.value - cold->findTier(2)->maximum) < 1e-9,
          "items: a roll above the cap speaks at the cap tier's best value");
    check(items::breakpointsFor(*cold, 2).size() == 1 && items::breakpointsFor(*cold, 3).size() == 2,
          "items: breakpoints accumulate up the tiers");
    stats::Equipment worn;
    worn.slots["weapon"] = sceptre;
    auto mods = grammar::gearMods(t.items, worn);
    bool chill = false, deeper = false;
    double coldValue = 0.0;
    for (const auto& m : mods) {
        if (m.id == "cold_damage") coldValue = m.value;
        if (m.effectKey == "increased_chill_buildup") chill = true;
        if (m.effectKey == "add_chill_buildup") deeper = true;
    }
    check(std::abs(coldValue - cold->findTier(2)->maximum) < 1e-9 && chill && !deeper,
          "items: worn gear speaks the held-back value and only tier two's breakpoint");
    // Transfer onto bronze: the roll is unleashed, and the third breakpoint comes.
    items::ItemInstance bronzeSceptre;
    bronzeSceptre.baseId = "bronze_sceptre";
    check(items::catalystTransfer(t.items, sceptre, bronzeSceptre) && bronzeSceptre.rolledProperties.size() == 1 &&
              bronzeSceptre.rarity == "keen",
          "items: the transfer carries the rolls and the rarity");
    const auto unleashed = items::effectiveRoll(t.items, bronzeSceptre, bronzeSceptre.rolledProperties.front());
    check(!unleashed.heldBack && unleashed.tier == 3 && std::abs(unleashed.value - 0.45) < 1e-9,
          "items: on bronze the roll speaks in full");
    worn.slots["weapon"] = bronzeSceptre;
    deeper = false;
    for (const auto& m : grammar::gearMods(t.items, worn))
        if (m.effectKey == "add_chill_buildup") deeper = true;
    check(deeper, "items: tier three's breakpoint arrives with the base that holds it");
    items::ItemInstance mail;
    mail.baseId = "iron_chest_armour";
    check(!items::catalystTransfer(t.items, sceptre, mail), "items: a transfer needs the same slot");
    // Stat breakpoints reach the sheet: tier-two life adds armour.
    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    armour.rolledProperties.push_back({"max_life", 2, 10.0});
    const auto totals = items::statTotals(t.items, armour);
    check(std::abs(totals.maxLife - 10.0) < 1e-9 && std::abs(totals.armour - 4.0) < 1e-9,
          "items: a tier-two life roll also armours (+4 on a bare instance)");
    // Era-bound drop tiers: the same kill rolls higher in era two, and an elite one more.
    const tuning::EnemyDef* whelp = t.world.findEnemy("ember_whelp");
    check(whelp != nullptr, "items: whelp def");
    int maxTierEra1 = 0, maxTierEra2 = 0, maxTierElite = 0;
    const auto* elite = t.world.findEliteModifier("hastened");
    for (uint64_t seed = 1; seed < 400; ++seed) {
        for (const auto& item : loot::rollEnemyGear(t, "ember_whelp", seed, nullptr, 1))
            for (const auto& r : item.rolledProperties) maxTierEra1 = std::max(maxTierEra1, r.tier);
        for (const auto& item : loot::rollEnemyGear(t, "ember_whelp", seed, nullptr, 2))
            for (const auto& r : item.rolledProperties) maxTierEra2 = std::max(maxTierEra2, r.tier);
        for (const auto& item : loot::rollEnemyGear(t, "ember_whelp", seed, elite, 2))
            for (const auto& r : item.rolledProperties) maxTierElite = std::max(maxTierElite, r.tier);
    }
    check(maxTierEra1 == 1 && maxTierEra2 == 2 && maxTierElite == 3, "items: drop tiers rise with the era and with elites");
    check(t.crafting.findCatalystProcess("preserving_transfer") != nullptr &&
              t.crafting.findCatalystProcess("preserving_transfer")->process == "catalyst_transfer",
          "items: the preserving transfer process loads without a guaranteed property");
    check(t.crafting.findRecipe("bronze_sceptre") != nullptr, "items: bronze bases are craftable");
}

// Mastery and crafted rolls (D-019): uses unlock per-skill perks; crafts roll.
void testMasteryAndCraftRolls(const tuning::Tuning& t) {
    const auto* orb = t.skills.findCombatSkill("prototype_frost_orb");
    check(orb && orb->mastery.size() == 2 && orb->resolveTags().back() == "skill:prototype_frost_orb",
          "mastery: perks load and skills carry their own tag");
    check(t.skills.findCombatSkill("prototype_shatter") != nullptr, "mastery: the Shatter spell exists");
    economy::PlayerEconomy player(t);
    std::vector<std::string> unlocked;
    for (int i = 0; i < orb->mastery.front().uses; ++i) {
        auto got = player.noteSkillUse("prototype_frost_orb");
        unlocked.insert(unlocked.end(), got.begin(), got.end());
    }
    check(unlocked.size() == 1 && unlocked.front() == orb->mastery.front().text,
          "mastery: the first perk unlocks exactly at its use count");
    check(player.masteryUnlocked("prototype_frost_orb").size() == 1 && player.masteryUnlocked("prototype_frost_nova").empty(),
          "mastery: one perk on the orb, none on the nova");
    auto mods = grammar::masteryMods(t, player.exportState().skillUses);
    check(mods.size() == 1 && mods.front().appliesToTags == std::vector<std::string>{"skill:prototype_frost_orb"},
          "mastery: a perk targets its own skill only");
    const double orbChill = grammar::chillApplied(t, mods, "prototype_frost_orb", false);
    const double novaChill = grammar::chillApplied(t, mods, "prototype_frost_nova", false);
    const double orbBase = grammar::chillApplied(t, {}, "prototype_frost_orb", false);
    const double novaBase = grammar::chillApplied(t, {}, "prototype_frost_nova", false);
    check(orbChill > orbBase && std::abs(novaChill - novaBase) < 1e-9,
          "mastery: the orb chills deeper, the nova is untouched");
    save::SaveGame game;
    game.economy = player.exportState();
    auto back = save::fromJson(save::toJson(game));
    check(back.economy.skillUses.at("prototype_frost_orb") == orb->mastery.front().uses, "mastery: uses ride in the save");
    // Crafted gear rolls: a forge at level 5 makes keen or wrought more often than plain.
    economy::PlayerEconomy smith(t);
    smith.addAvailableStation("forge_improved");
    int keenOrBetter = 0;
    for (int i = 0; i < 30; ++i) {
        smith.inventory["iron_ingot"] += 12;
        smith.inventory["wood"] += 10; // the forge burns fuel
        smith.grantSkillXp("blacksmithing", 1000);
        auto r = smith.craft("iron_chest_armour");
        check(r.crafted, "craft: armour crafts");
        if (smith.packItems.back().rarity != "plain") ++keenOrBetter;
    }
    check(smith.packItems.size() == 30 && keenOrBetter >= 15, "craft: most level-five crafts roll modifiers");
    bool anyRolled = false;
    for (const auto& item : smith.packItems) anyRolled = anyRolled || !item.rolledProperties.empty();
    check(anyRolled, "craft: crafted gear carries rolled modifiers");
}

// The bigger world (3 Sep 2026): 224 cells, a fen that owns its own packs.
void testBiggerWorld(const tuning::Tuning& t) {
    check(t.worldgen.map.widthCells == 320 && t.worldgen.map.heightCells == 320, "world: 320 cells a side (Wave 6 slice 3)");
    check(t.worldgen.findBiome("fen") != nullptr, "world: the fen exists");
    auto map = worldgen::generate(t, 9);
    int fenCells = 0, fenPacks = 0;
    const int fenIndex = static_cast<int>(t.worldgen.findBiome("fen") - &t.worldgen.biomes.front());
    for (const auto& cell : map.cells)
        if (cell.biomeIndex == fenIndex) ++fenCells;
    for (const auto& pack : map.packs)
        for (const auto& id : pack.enemies)
            if (id == "bog_lurker" || id == "marsh_wisp") { ++fenPacks; break; }
    check(fenCells > 200 && fenPacks > 0, "world: the fen covers ground and fields lurkers and wisps");
    check(t.world.findEnemy("hollow_knight") != nullptr && t.world.findEnemy("cinder_wisp") != nullptr &&
              t.world.findEnemy("hollow_knight")->sizeScale > 1.0,
          "world: the wastes gained a knight and a wisp");
    check(t.realtime.findBehaviour("lurker") != nullptr && t.realtime.findBehaviour("knight") != nullptr,
          "world: new behaviours are data");
}

// Era three, the deeper floor, the grazer and the peddler (3 Sep 2026).
void testEraThreeAndLife(const tuning::Tuning& t) {
    const auto* floor = t.trial.findFloor("deep_forge");
    check(floor && floor->boss.id == "ash_warden" && floor->stages.size() == 3 && floor->completionUnlock == "ash_tide" &&
              floor->completionCurio == "warden_eye",
          "floor: the deeper forge loads with its own boss, stages, completion and curio");
    economy::PlayerEconomy player(t);
    check(player.currentEra() == 1, "era3: a new game is era one");
    player.recordWorldEffect("ash_tide");
    check(player.currentEra() == 1, "era3: the ash tide alone does not skip the deep (eras are ordered)");
    player.recordWorldEffect("stonecut_blocks");
    check(player.currentEra() == 3 && player.era().id == "ash_tide" && player.plate().firstRow == 0 && player.plate().lastRow == 3,
          "era3: with the deep awake the tide wakes era three and the plate is 4x4");
    const auto* scream = player.era().mechanic("shrieker", "scream_radius_bonus");
    check(scream && scream->at("value") > 0.0 && player.era().eliteChanceBonus > 0.0 &&
              player.era().packEscorts.count("ash_hound") == 1,
          "era3: shriekers call further, elites are commoner, hounds run with wisps");
    // A session on the deeper floor uses that floor's stages and boss.
    boons::BuildTags tags;
    trial::TrialSession deeper(t, player, tags, 5, floor);
    check(deeper.stages().size() == 3 && deeper.boss().id == "ash_warden" && deeper.floor() == floor,
          "floor: a session on the deeper floor fights its rooms and its warden");
    trial::TrialSession first(t, player, tags, 5);
    check(first.stages().size() == t.trial.stages.size() && first.boss().id == "forge_tyrant",
          "floor: the first floor is unchanged");
    // Era-three ground and work.
    check(t.worldgen.nodeTypes.at("ember_iron_vein").era == 3 && t.worldgen.nodeTypes.at("silver_vein").era == 3,
          "era3: ember-iron and silver surface in the third era");
    check(t.crafting.findRecipe("smelt_steel") != nullptr && t.construction.findMaterial("steel")->hasTrait("resilient") &&
              t.construction.findMaterial("silver")->hasTrait("warding"),
          "era3: steel and silver are families");
    // The grazer flees; the peddler sells.
    check(t.realtime.findBehaviour("grazer") != nullptr && t.realtime.findBehaviour("grazer")->flees &&
              !t.realtime.findBehaviour("melee")->flees && t.world.findEnemy("valley_elk") != nullptr,
          "life: the valley elk is a grazer that flees");
    economy::PlayerEconomy buyer(t);
    check(!buyer.buy("charcoal"), "peddler: no kind, no sale");
    buyer.currency["marrow"] = 2;
    check(buyer.buy("charcoal") && buyer.inventory["charcoal"] == 4 && buyer.currency["marrow"] == 1,
          "peddler: charcoal for a Marrow");
    check(!buyer.buy("iron_ore") && !buyer.buy("preserving_catalyst") && !buyer.buy("no_such_thing"),
          "peddler: the wrong kind, or not for sale");
    // An order's world effect now goes through the recording path: the mine
    // milestone reaches the Foundry.
    economy::PlayerEconomy miner(t);
    miner.takeFoundryNotices();
    miner.recordWorldEffect("old_mine_reinforced");
    check(!miner.takeFoundryNotices().empty(), "order: the mine reinforced forges its ingot");
}

// D-023 slice 2 (owner, 4 Sep 2026): every ingot reads every skill. An
// element ingot beside a skill of its own element scales it; beside any
// other skill it adds its element to the hit as a second typed packet at
// the same fraction, scaled by that type's own modifiers; the self ingots
// read a skill weakly. The hit is a list of packets now.
void testEveryIngotReadsEverySkill(const tuning::Tuning& t) {
    const std::string orb = "prototype_frost_orb";
    const std::string strike = "prototype_heavy_strike";
    const double fraction = t.foundry.findIngot("ember")->value * t.foundry.supportMultiplier; // the support fraction
    const double emberBase = t.foundry.findIngot("ember")->value;
    const double frostBase = t.foundry.findIngot("frost")->value;
    auto scoped = [&](const std::string& modifier, double value, const std::string& skill) {
        grammar::ActiveMod mod = grammar::modAt(t.items, modifier, value, "test");
        mod.requiresTags = {"skill:" + skill};
        return mod;
    };

    // Data: the packet types, the readings the ingots name, and modifiers
    // that never roll on gear.
    check(t.grammar.damageTypes == std::vector<std::string>{"physical", "fire", "cold"}, "packets: three damage types, physical first");
    check(t.foundry.findIngot("ember")->addedModifier == "added_fire" && t.foundry.findIngot("frost")->addedModifier == "added_cold" &&
              t.foundry.findIngot("edge")->addedModifier == "added_physical" && t.foundry.findIngot("reach")->addedModifier.empty(),
          "packets: the element ingots name what they add; the rest add nothing");
    check(t.foundry.findIngot("vigour")->supportModifier() == "life_on_kill" && std::abs(t.foundry.findIngot("vigour")->supportValue() - 0.5) < 1e-9 &&
              t.foundry.findIngot("plate")->supportModifier() == "armour_on_cast" && t.foundry.findIngot("ward")->supportModifier() == "status_ward" &&
              std::abs(t.foundry.findIngot("ember")->supportValue() - emberBase) < 1e-9,
          "packets: the self ingots name a weak reading with its own number; an element ingot reads at its base value");
    check(t.foundry.castArmourSeconds > 0.0, "packets: the Plate reading has a duration");
    bool poolClean = true;
    for (const auto& base : t.items.itemBases)
        for (const auto& tag : base.allowedModifierTags)
            if (tag == "added" || tag == "reading") poolClean = false;
    check(poolClean, "packets: no base rolls the plate's readings");
    check(items::modifierSentence(*t.items.findModifier("added_fire"), fraction) == "adds 24% of the hit as fire damage" &&
              items::modifierSentence(*t.items.findModifier("life_on_kill"), 1.0) == "a kill restores 1 life",
          "packets: a reading says its whole sentence");

    // A bare skill is one packet of its own element; a movement skill none.
    grammar::ActiveMods none;
    auto bare = grammar::skillHit(t, none, orb);
    check(bare.size() == 1 && bare[0].type == "cold" && !bare[0].added && std::abs(bare[0].damage - 9.0) < 1e-9,
          "packets: a bare orb is one cold packet");
    check(grammar::skillHit(t, none, strike).size() == 1 && grammar::skillHit(t, none, strike)[0].type == "physical",
          "packets: the strike is physical");
    check(grammar::skillHit(t, none, "prototype_dash").empty() && grammar::skillHit(t, none, "no_such_skill").empty(),
          "packets: a movement skill and an unknown skill have no hit");

    // The two lanes trade the same number: +24% of the hit added as fire
    // is the same hit as +24% increased cold, but it is its own type.
    grammar::ActiveMods addedLane = {scoped("added_fire", fraction, orb)};
    grammar::ActiveMods sameLane = {scoped("cold_damage", fraction, orb)};
    checkNear(grammar::skillDamage(t, addedLane, orb), grammar::skillDamage(t, sameLane, orb), 1e-9,
              "lanes: the added lane and the same-element lane are the same total");
    check(grammar::skillHit(t, addedLane, orb).size() == 2 && grammar::skillHit(t, sameLane, orb).size() == 1,
          "lanes: the added lane is two packets, the same-element lane one");
    check(grammar::skillHit(t, addedLane, "prototype_frost_nova").size() == 1, "lanes: a reading scoped to the orb leaves the nova alone");

    // Ember west of the orb's socket: an added fire packet, not a support.
    economy::PlayerEconomy p(t);
    p.foundryEvent("first_kill:ember_whelp");   // ember
    p.foundryEvent("recipe:smelt_iron");        // ember
    p.foundryEvent("first_kill:gloom_crawler"); // frost
    check(p.foundryPlaceSkill(1, 1, orb) && p.foundryPlace(1, 0, "ember"), "added: ember west of the orb");
    auto fx = foundry::effects(t, p.foundry(), p.plate());
    int added = 0, supports = 0;
    for (const auto& e : fx) {
        if (e.kind == "support") ++supports;
        if (e.kind != "added") continue;
        ++added;
        check(e.modifier == "added_fire" && e.skill == orb && e.row == 1 && e.col == 1 && e.cellRow == 1 && e.cellCol == 0 &&
                  std::abs(e.value - fraction) < 1e-9 && e.label == "Frost Orb <- Ember Ingot",
              "added: names its modifier, skill, socket and cell, at the support fraction");
    }
    check(added == 1 && supports == 0, "added: an ember beside a cold orb adds fire and does not support");
    auto mods = grammar::foundryMods(t, p.foundry(), p.currentEra());
    bool scopedMod = false;
    for (const auto& m : mods)
        if (m.source == "foundry:added" && m.id == "added_fire" && m.requiresTags == std::vector<std::string>{"skill:" + orb} &&
            m.appliesToTags == t.items.findModifier("added_fire")->appliesToTags)
            scopedMod = true;
    check(scopedMod, "added: the reading keeps its modifier's applies_to and requires the orb's tag");
    auto hit = grammar::skillHit(t, mods, orb);
    check(hit.size() == 2 && hit[0].type == "cold" && !hit[0].added && hit[1].type == "fire" && hit[1].added,
          "added: the orb is a cold-and-fire bolt");
    checkNear(hit[0].damage, 9.0, 1e-9, "added: the cold packet is untouched by the ember");
    // The fire packet is scaled by every fire modifier, the ember's own base among them.
    checkNear(hit[1].damage, 9.0 * fraction * (1.0 + emberBase), 1e-9, "added: the fire packet is the fraction of the base hit, scaled by fire");
    checkNear(grammar::skillDamage(t, mods, orb), hit[0].damage + hit[1].damage, 1e-9, "packets: skillDamage is the packets summed");
    // Fire gear scales the fire packet alone; cold gear the cold alone.
    auto fiery = mods;
    fiery.push_back(grammar::modAt(t.items, "fire_damage", 0.5, "test"));
    auto geared = grammar::skillHit(t, fiery, orb);
    checkNear(geared[0].damage, 9.0, 1e-9, "added: fire gear leaves the cold packet alone");
    checkNear(geared[1].damage, 9.0 * fraction * (1.0 + emberBase + 0.5), 1e-9, "added: fire gear scales the fire packet");
    auto chilly = mods;
    chilly.push_back(grammar::modAt(t.items, "cold_damage", 0.5, "test"));
    checkNear(grammar::skillHit(t, chilly, orb)[1].damage, hit[1].damage, 1e-9, "added: cold gear leaves the fire packet alone");
    // A Frost support beside the same orb scales its cold and never the added fire (the conjunction).
    check(p.foundryPlace(1, 2, "frost"), "added: frost east of the orb");
    mods = grammar::foundryMods(t, p.foundry(), p.currentEra());
    hit = grammar::skillHit(t, mods, orb);
    check(hit.size() == 2, "added: still two packets with a frost support");
    checkNear(hit[0].damage, 9.0 * (1.0 + frostBase + fraction), 1e-9, "added: the frost support scales the cold packet");
    checkNear(hit[1].damage, 9.0 * fraction * (1.0 + emberBase), 1e-9, "added: the frost support never scales the fire packet");
    // Backing an added reading: the second ember south of the first counts it once more.
    check(p.foundryPlace(2, 0, "ember"), "added: a second ember below the first");
    fx = foundry::effects(t, p.foundry(), p.plate());
    int backings = 0;
    for (const auto& e : fx)
        if (e.kind == "backing" && e.modifier == "added_fire" && e.skill == orb && e.cellRow == 2 && e.cellCol == 0) ++backings;
    check(backings == 1, "added: a matching ingot backs an added reading");
    mods = grammar::foundryMods(t, p.foundry(), p.currentEra());
    checkNear(grammar::skillHit(t, mods, orb)[1].damage, 9.0 * 2.0 * fraction * (1.0 + 2.0 * emberBase), 1e-9,
              "added: backed, the fire packet is twice the fraction, scaled by both embers' bases");

    // Ember beside a fire skill scales it and adds nothing.
    economy::PlayerEconomy k(t);
    k.learnSkill("prototype_ember_bolt");
    k.foundryEvent("first_kill:ember_whelp");
    check(k.foundryPlaceSkill(1, 1, "prototype_ember_bolt") && k.foundryPlace(1, 0, "ember"), "same: ember beside the bolt");
    added = 0; supports = 0;
    for (const auto& e : foundry::effects(t, k.foundry(), k.plate())) {
        if (e.kind == "added") ++added;
        if (e.kind == "support" && e.modifier == "fire_damage") ++supports;
    }
    check(added == 0 && supports == 1, "same: an ember beside a fire skill supports it and adds nothing");
    auto bolt = grammar::skillHit(t, grammar::foundryMods(t, k.foundry(), k.currentEra()), "prototype_ember_bolt");
    check(bolt.size() == 1 && bolt[0].type == "fire", "same: the bolt stays one fire packet");
    checkNear(bolt[0].damage, 8.0 * (1.0 + emberBase + fraction), 1e-9, "same: scaled by the base and the support");

    // Edge beside a physical strike supports; frost beside it adds cold.
    economy::PlayerEconomy s(t);
    s.foundryEvent("work:strike_split");       // edge
    s.foundryEvent("first_kill:gloom_crawler"); // frost
    check(s.foundryPlaceSkill(1, 1, strike) && s.foundryPlace(1, 0, "edge") && s.foundryPlace(1, 2, "frost"),
          "strike: edge west, frost east of the strike");
    auto blow = grammar::skillHit(t, grammar::foundryMods(t, s.foundry(), s.currentEra()), strike);
    check(blow.size() == 2 && blow[0].type == "physical" && blow[1].type == "cold" && blow[1].added, "strike: a physical-and-cold blow");
    checkNear(blow[0].damage, 28.0 * (1.0 + emberBase + fraction), 1e-9, "strike: the edge support scales the physical packet");
    checkNear(blow[1].damage, 28.0 * fraction * (1.0 + frostBase), 1e-9, "strike: the added cold is scaled by the frost's own base");
    check(grammar::skillHit(t, grammar::foundryMods(t, s.foundry(), s.currentEra()), "prototype_area_strike").size() == 1,
          "strike: the area strike, not in the socket, is untouched");

    // The self ingots read a skill weakly: life on kill, armour on cast,
    // less damage from enemies carrying the skill's status.
    economy::PlayerEconomy self(t);
    self.foundryEvent("recipe:workbench_kit");     // vigour
    self.foundryEvent("first_kill:stone_husk");    // plate
    self.recordWorldEffect("stonecut_blocks");     // ward; wakes era two, forging row 0
    check(self.plate().forged(0, 1), "self: era two forged the row above");
    check(self.foundryPlaceSkill(1, 1, orb) && self.foundryPlace(1, 0, "vigour") && self.foundryPlace(0, 1, "plate") &&
              self.foundryPlace(1, 2, "ward"),
          "self: vigour, plate and ward around the orb");
    int weak = 0;
    for (const auto& e : foundry::effects(t, self.foundry(), self.plate())) {
        if (e.kind != "support") continue;
        ++weak;
        if (e.modifier == "life_on_kill") checkNear(e.value, 1.0, 1e-9, "self: vigour reads as one life on kill");
        else if (e.modifier == "armour_on_cast") checkNear(e.value, 4.0, 1e-9, "self: plate reads as four armour on cast");
        else if (e.modifier == "status_ward") checkNear(e.value, 0.05, 1e-9, "self: ward reads as five percent less");
        else check(false, "self: an unexpected support " + e.modifier);
    }
    check(weak == 3, "self: three weak readings, nothing inert");
    auto selfMods = grammar::foundryMods(t, self.foundry(), self.currentEra());
    checkNear(grammar::skillLifeOnKill(t, selfMods, orb), 1.0, 1e-9, "self: a kill with the orb restores one life");
    checkNear(grammar::skillLifeOnKill(t, selfMods, "prototype_frost_nova"), 0.0, 1e-9, "self: the nova restores nothing");
    checkNear(grammar::skillCastArmour(t, selfMods, orb), 4.0, 1e-9, "self: casting the orb grants four armour");
    checkNear(grammar::skillCastArmour(t, selfMods, strike), 12.0, 1e-9, "self: the strike grants only its own swing armour (melee, Wave 5 item 11)");
    checkNear(grammar::wardMultiplier(t, selfMods, {"chill"}), 0.95, 1e-9, "self: a chilled enemy deals five percent less");
    checkNear(grammar::wardMultiplier(t, selfMods, {"ignite", "bleed"}), 1.0, 1e-9, "self: the orb's ward ignores statuses it does not apply");
    checkNear(grammar::wardMultiplier(t, selfMods, {}), 1.0, 1e-9, "self: nothing carried, nothing warded");
    checkNear(grammar::wardMultiplier(t, none, {"chill"}), 1.0, 1e-9, "self: no ward reading, no ward");
    // The sheet is untouched by a weak reading: the ingots' bases still land there.
    bool lifeOnSheet = false, wardOnSkill = false;
    for (const auto& m : selfMods) {
        if (m.id == "max_life" && m.source == "foundry:ingot") lifeOnSheet = true;
        if (m.id == "status_ward" && m.source == "foundry:support") wardOnSkill = true;
    }
    check(lifeOnSheet && wardOnSkill, "self: the base stays on the sheet and the reading goes to the skill");
    checkNear(grammar::skillHit(t, selfMods, orb)[0].damage, 9.0, 1e-9, "self: the weak readings do not touch the hit");

    // Mob resistance by packet type loads for the engine to apply (owner,
    // 4 Sep: heavily reduced, not immune).
    check(t.world.findEnemy("hollow_knight")->damageTaken.at("fire") < 0.5 && t.world.findEnemy("hollow_knight")->damageTaken.at("fire") > 0.0 &&
              t.world.findEnemy("cinder_wisp")->damageTaken.at("fire") < 0.5 && t.world.findEnemy("ember_whelp")->damageTaken.empty(),
          "resistance: a hollow suit and a cinder wisp take a small share of a fire packet, never nothing; a whelp takes every packet whole");

    // The hit stream rolls packets as it rolls a number: one draw per hit,
    // so packets and the single number stay in step from the same seed.
    combat::HitStream one(11), two(11);
    combat::CombatMods plain;
    const auto& orbDef = *t.skills.findCombatSkill(orb);
    for (int i = 0; i < 3; ++i) {
        const double number = one.playerHit(orbDef, plain, false);
        auto packets = two.playerHit(grammar::skillHit(t, none, orb), plain, false);
        check(packets.size() == 1, "stream: a bare orb rolls one packet");
        checkNear(packets[0].damage, number, 1e-9, "stream: a packet takes the same draw as the number");
    }
    combat::HitStream three(11), four(11);
    const auto resolved = grammar::skillHit(t, mods, orb);
    for (int i = 0; i < 3; ++i) {
        const double number = three.playerHit(orbDef, plain, true);
        auto packets = four.playerHit(resolved, plain, true);
        check(packets.size() == 2, "stream: a cold-and-fire orb rolls two packets");
        checkNear(packets[0].damage, number * resolved[0].damage / 9.0, 1e-9,
                  "stream: the cold packet is the bare number scaled as the resolver says, isolated or not");
        checkNear(packets[1].damage / packets[0].damage, resolved[1].damage / resolved[0].damage, 1e-9,
                  "stream: both packets take the one draw, so their ratio is the resolver's");
    }
}

// D-023 slice 3 (owner, 4 Sep 2026: "go ahead"): typed currency. Four kinds
// replace the coin: families pay them, elites one more, the peddler
// changes them, a kind aims a craft, rare metal casts one.
void testTypedCurrency(const tuning::Tuning& t) {
    const auto& c = t.crafting;
    check(c.currencies == std::vector<std::string>{"vanguard", "warding_vanguard", "marrow", "quicksilver"} && !c.isCurrency("trade_currency"),
          "kinds: the purse holds the four cast kinds and the coin is gone");
    check(c.currencyKinds.size() == 6 && c.findKind("vanguard") && c.findKind("vanguard")->family == "defence" &&
              c.findKind("marrow")->family == "life" && c.findKind("quicksilver")->family == "speed" &&
              c.findKind("ember_catalyst")->family == "offence" && c.findKind("preserving_catalyst")->family == "offence" &&
              !c.findKind("trade_currency"),
          "kinds: six kinds in four families");
    check(c.exchangeRate == 3 && c.exchangeKinds.size() == 5 &&
              std::find(c.exchangeKinds.begin(), c.exchangeKinds.end(), "ember_catalyst") == c.exchangeKinds.end(),
          "kinds: the peddler changes five kinds at three to one; the ember catalyst stays the trial's");
    check(c.aimedMinimumRarity == "keen", "kinds: an aimed craft is at least keen");
    bool coinAnywhere = false;
    for (const auto& enemy : t.world.enemies) {
        check(c.findKind(enemy.currencyKind) != nullptr, "kinds: " + enemy.id + " pays a known kind");
        bool paysKind = false;
        for (const auto& entry : enemy.loot) {
            if (entry.item == "trade_currency") coinAnywhere = true;
            if (entry.item == enemy.currencyKind) paysKind = true;
        }
        check(paysKind, "kinds: " + enemy.id + "'s loot table carries its kind");
    }
    for (const auto& offer : c.market) if (offer.currency == "trade_currency") coinAnywhere = true;
    for (const auto& order : c.orders) if (order.rewards.count("trade_currency")) coinAnywhere = true;
    check(!coinAnywhere, "kinds: nothing pays or prices in the coin");
    check(t.world.findEnemy("hollow_knight")->currencyKind == "vanguard" && t.world.findEnemy("ash_hound")->currencyKind == "quicksilver" &&
              t.world.findEnemy("valley_elk")->currencyKind == "marrow" && t.world.findEnemy("ember_whelp")->currencyKind == "ember_catalyst",
          "kinds: families pay by their nature");

    // Loot: a family pays its kind now and then; an elite pays one more every time.
    int knightsPaying = 0, whelpsPaying = 0;
    for (uint64_t seed = 1; seed <= 200; ++seed) {
        if (loot::rollEnemyLoot(t.world, "hollow_knight", seed).count("vanguard")) ++knightsPaying;
        if (loot::rollEnemyLoot(t.world, "ember_whelp", seed).count("ember_catalyst")) ++whelpsPaying;
    }
    check(knightsPaying > 10 && knightsPaying < 100, "loot: a knight pays a Vanguard now and then (" + std::to_string(knightsPaying) + " of 200)");
    check(whelpsPaying > 0 && whelpsPaying < 40, "loot: a whelp pays an Ember Catalyst rarely (" + std::to_string(whelpsPaying) + " of 200)");
    tuning::EliteModifierDef elite;
    elite.id = "test_elite";
    bool eliteAlways = true;
    for (uint64_t seed = 1; seed <= 50; ++seed)
        if (loot::rollEnemyLoot(t.world, "hollow_knight", seed, &elite)["vanguard"] < 1) eliteAlways = false;
    check(eliteAlways, "loot: an elite knight always pays a Vanguard on top");

    // The purse and the pack: grant routes a kind to the purse, a catalyst
    // to the pack; held reads both.
    economy::PlayerEconomy p(t);
    p.grant("vanguard", 2);
    p.grant("preserving_catalyst", 1);
    p.grant("wood", 3);
    check(p.currency["vanguard"] == 2 && p.inventory.count("vanguard") == 0 && p.inventory["preserving_catalyst"] == 1 &&
              p.inventory["wood"] == 3 && p.held("vanguard") == 2 && p.held("preserving_catalyst") == 1 && p.held("nothing") == 0,
          "kinds: a cast kind lands in the purse, a catalyst in the pack, and held reads both");

    // The exchange: three of one for one of another, among the listed kinds.
    check(!p.canExchange("vanguard", "marrow"), "exchange: two Vanguards are not enough");
    p.grant("vanguard", 1);
    check(p.canExchange("vanguard", "marrow") && !p.canExchange("vanguard", "vanguard") && !p.canExchange("vanguard", "ember_catalyst") &&
              !p.canExchange("vanguard", "wood"),
          "exchange: three Vanguards change for a Marrow; never for the same kind, the ember catalyst or a material");
    check(p.exchange("vanguard", "marrow") && p.currency["vanguard"] == 0 && p.currency["marrow"] == 1, "exchange: paid and received");
    p.inventory["preserving_catalyst"] = 3;
    check(p.exchange("preserving_catalyst", "quicksilver") && p.inventory["preserving_catalyst"] == 0 && p.currency["quicksilver"] == 1,
          "exchange: catalysts from the pack change like any kind");
    p.currency["marrow"] = 3;
    check(p.exchange("marrow", "preserving_catalyst") && p.inventory["preserving_catalyst"] == 1, "exchange: a Preserving Catalyst is three kinds away");
    check(!p.exchange("marrow", "vanguard"), "exchange: spent, no change");

    // A kind aims a craft: spent, the first modifier from its family, never plain.
    economy::PlayerEconomy smith(t);
    smith.addAvailableStation("forge_basic");
    smith.addAvailableStation("forge_improved");
    smith.grantSkillXp("blacksmithing", 1000);
    smith.inventory["iron_ingot"] = 12;
    smith.inventory["wood"] = 10;
    auto refused = smith.craft("iron_chest_armour", false, "marrow");
    check(!refused.crafted && refused.failure.missingKind && smith.inventory["iron_ingot"] == 12, "aim: no Marrow in hand, nothing spent");
    check(!smith.craft("iron_chest_armour", false, "no_such_kind").crafted, "aim: an unknown kind is refused");
    int lifeFirst = 0, plainAimed = 0;
    for (int i = 0; i < 20; ++i) {
        smith.inventory["iron_ingot"] = 12;
        smith.inventory["wood"] = 10;
        smith.grant("marrow", 1);
        auto r = smith.craft("iron_chest_armour", false, "marrow");
        check(r.crafted && smith.currency["marrow"] == 0, "aim: the Marrow is spent on the craft");
        const auto& item = smith.packItems.back();
        if (item.rarity == "plain" || item.rolledProperties.empty()) ++plainAimed;
        else {
            const auto* def = t.items.findModifier(item.rolledProperties.front().propertyId);
            if (def && std::find(def->tags.begin(), def->tags.end(), "life") != def->tags.end()) ++lifeFirst;
        }
    }
    check(plainAimed == 0 && lifeFirst == 20, "aim: every Marrow-aimed armour is at least keen with a life modifier first");
    smith.inventory["iron_ingot"] = 6;
    smith.inventory["wood"] = 4;
    smith.grant("quicksilver", 1);
    check(smith.craft("iron_mace", false, "quicksilver").crafted && !smith.packItems.back().rolledProperties.empty(),
          "aim: a Quicksilver aims a mace");
    const auto* first = t.items.findModifier(smith.packItems.back().rolledProperties.front().propertyId);
    check(first && std::find(first->tags.begin(), first->tags.end(), "speed") != first->tags.end(), "aim: the mace's first modifier is speed");
    smith.inventory["iron_ingot"] = 12;
    smith.inventory["wood"] = 10;
    check(smith.craft("iron_chest_armour").crafted, "aim: an unaimed craft still works");
    // A kind on a recipe that makes no gear is ignored and kept.
    smith.grant("vanguard", 1);
    smith.inventory["wood"] = 8;
    check(smith.craft("charcoal", false, "vanguard").crafted && smith.currency["vanguard"] == 1, "aim: a non-gear recipe ignores the kind and spends nothing");

    // Rare metal casts a kind into the purse.
    economy::PlayerEconomy caster(t);
    caster.addAvailableStation("forge_basic");
    caster.addAvailableStation("forge_improved");
    caster.grantSkillXp("blacksmithing", 1000);
    caster.inventory["steel_ingot"] = 2;
    caster.inventory["wood"] = 10;
    check(caster.craft("cast_vanguard").crafted && caster.currency["vanguard"] == 1 && caster.inventory.count("vanguard") == 0,
          "cast: two steel make a Vanguard, in the purse");
    caster.inventory["silver_ingot"] = 3;
    caster.inventory["hide"] = 2;
    check(caster.craft("cast_marrow").crafted && caster.craft("cast_quicksilver").crafted && caster.currency["marrow"] == 1 &&
              caster.currency["quicksilver"] == 1,
          "cast: silver and hide make a Marrow, silver alone a Quicksilver");
    check(!t.crafting.findRecipe("cast_ember_catalyst") && !t.crafting.findRecipe("cast_preserving_catalyst"),
          "cast: catalysts are never cast");

    // The trial's loot room pays a spread of kinds; the purse rides in the save.
    check(t.trial.materialsReward.count("vanguard") && t.trial.materialsReward.count("marrow") && t.trial.materialsReward.count("quicksilver"),
          "trial: the loot room pays a spread of the kinds");
    save::SaveGame game;
    game.economy = p.exportState();
    auto back = save::fromJson(save::toJson(game));
    check(back.economy.currency.at("quicksilver") == 1, "kinds: the purse rides in the save");
}

// D-023, the flow (owner, 4 Sep 2026): only a skill sits in a socket. A
// kind rests where it cannot touch one, gives its base forward while a
// chain of placed pieces leads inward to a laid tablet, and works every
// support it touches into a FORM that feeds the skill. Ingots are base;
// Catalysts are offensive creativity; Vanguards defensive.
void testKindsInCorners(const tuning::Tuning& t) {
    const auto& f = t.foundry;
    check(f.kinds.size() == 6 && f.findKindOnPlate("vanguard") && f.findKindOnPlate("vanguard")->modifier == "armour_plating" &&
              std::abs(f.findKindOnPlate("vanguard")->value - 4.0) < 1e-9 && f.findKindOnPlate("ember_catalyst") &&
              f.findKindOnPlate("ember_catalyst")->modifier.empty() && f.findKindOnPlate("ember_catalyst")->family == "offence" &&
              !f.findKindOnPlate("nothing") && f.familyName("offence") == "Catalyst" && f.familyName("nothing").empty(),
          "flow: six kinds on the plate in four named families; the Vanguard has a base, the Catalyst none");
    check(f.forms.size() >= 20 && f.hasteAfterHitSeconds > 0.0, "flow: the first forms load");
    bool poolClean = true;
    for (const auto& base : t.items.itemBases)
        for (const auto* def : items::eligibleModifiers(t.items, base))
            for (const auto& tag : def->tags)
                if (tag == "reading" || tag == "added") poolClean = false;
    check(poolClean && t.items.findModifier("damage_vs_ignite"), "flow: the reactions exist and never roll on gear");

    // Depth, and where a kind may rest (era one: rows 1 and 2, sockets (1,1) and (2,2)).
    economy::PlayerEconomy p(t);
    const auto plate = p.plate();
    check(foundry::depth(plate, 1, 1) == 0 && foundry::depth(plate, 1, 0) == 1 && foundry::depth(plate, 1, 2) == 1 &&
              foundry::depth(plate, 2, 0) == 2 && foundry::depth(plate, 1, 3) == 2 && foundry::depth(plate, 0, 3) == 3,
          "flow: depth is the distance to the nearest socket");
    check(!foundry::kindMayRest(plate, 1, 1) && !foundry::kindMayRest(plate, 1, 0) && !foundry::kindMayRest(plate, 2, 1) &&
              foundry::kindMayRest(plate, 2, 0) && foundry::kindMayRest(plate, 1, 3) && !foundry::kindMayRest(plate, 0, 3),
          "flow: a kind rests only where it cannot touch a socket, on a forged row");

    // Placement: from the purse, only where it may rest.
    p.foundryEvent("first_kill:gloom_crawler"); // frost
    p.foundryEvent("first_kill:ash_hound");     // haste
    check(!p.foundryPlaceKind(2, 0, "vanguard"), "flow: none in the purse, none set");
    p.grant("vanguard", 2);
    check(!p.foundryPlaceKind(1, 1, "vanguard") && !p.foundryPlaceKind(1, 0, "vanguard") && !p.foundryPlaceKind(0, 0, "vanguard") &&
              !p.foundryPlaceKind(2, 0, "wood") && p.currency["vanguard"] == 2,
          "flow: a socket, a support cell, an unforged row and a material are refused, nothing spent");
    check(p.foundryPlaceKind(2, 0, "vanguard") && p.currency["vanguard"] == 1, "flow: set in the corner, taken from the purse");
    check(!p.foundryPlace(2, 0, "frost") && !p.foundryPlaceKind(2, 0, "vanguard"), "flow: the cell is taken");
    auto onSheet = [&](const economy::PlayerEconomy& who) {
        std::vector<stats::ExtraEffect> extra;
        for (const auto& m : grammar::foundryMods(t, who.foundry(), who.currentEra())) extra.push_back({m.effectKey, m.value});
        return stats::deriveStats(t.world.playerBase, {}, t.items, extra);
    };
    auto count = [&](const economy::PlayerEconomy& who, const std::string& kind) {
        int n = 0;
        for (const auto& e : foundry::effects(t, who.foundry(), who.plate()))
            if (e.kind == kind) ++n;
        return n;
    };
    // Nothing flows until a chain leads to a laid tablet.
    check(!foundry::flowsToSkill(p.foundry(), p.plate(), 2, 0) && count(p, "augment") == 0 && std::abs(onSheet(p).armour) < 1e-9,
          "flow: alone in a corner, a kind gives nothing");
    check(p.foundryPlace(1, 0, "frost") && !foundry::flowsToSkill(p.foundry(), p.plate(), 2, 0),
          "flow: a support with no tablet beside it is not a chain");
    check(p.foundryPlaceSkill(1, 1, "prototype_frost_orb") && foundry::flowsToSkill(p.foundry(), p.plate(), 2, 0),
          "flow: the orb laid, the chain closes");
    check(count(p, "augment") == 1 && std::abs(onSheet(p).armour - 4.0) < 1e-9, "flow: the Vanguard's base counts, four armour on the sheet");
    // The form: Frost beside the orb, touched by a Vanguard, is Frost Leech; the Frost keeps its support.
    int forms = 0, supports = 0;
    for (const auto& e : foundry::effects(t, p.foundry(), p.plate())) {
        if (e.kind == "support" && e.skill == "prototype_frost_orb" && e.modifier == "cold_damage") ++supports;
        if (e.kind == "form") {
            ++forms;
            check(e.skill == "prototype_frost_orb" && e.modifier == "life_on_kill" && std::abs(e.value - 4.0) < 1e-9 && e.cellRow == 1 &&
                      e.cellCol == 0 && e.row == 1 && e.col == 1 && e.subject == "defence" && e.label.rfind("Frost Leech", 0) == 0,
                  "flow: Frost Leech names its skill, its support cell, its socket and its family");
        }
    }
    check(forms == 1 && supports == 1, "flow: one form, and the Frost still supports the orb");
    auto mods = grammar::foundryMods(t, p.foundry(), p.currentEra());
    checkNear(grammar::skillLifeOnKill(t, mods, "prototype_frost_orb"), 4.0, 1e-9, "flow: a kill with the orb restores four life");
    checkNear(grammar::skillHit(t, mods, "prototype_frost_orb")[0].damage, 9.0 * (1.0 + 0.12 + 0.24), 1e-9, "flow: the orb keeps its +24% cold");
    checkNear(grammar::skillLifeOnKill(t, mods, "prototype_frost_nova"), 0.0, 1e-9, "flow: the nova, in no socket, gets nothing");
    // A shared support feeds both skills: Haste south of the orb, touched by
    // the same corner, with the strike in the second socket.
    check(p.foundryPlace(2, 1, "haste") && p.foundryPlaceSkill(2, 2, "prototype_heavy_strike"),
          "flow: haste in the shared support, the strike in the second socket");
    int quicksteps = 0;
    for (const auto& e : foundry::effects(t, p.foundry(), p.plate()))
        if (e.kind == "form" && e.modifier == "haste_after_hit") ++quicksteps;
    check(quicksteps == 2 && std::abs(onSheet(p).hasteAfterHit - 0.32) < 1e-9, "flow: Quickstep feeds both skills the shared support serves");
    // Lifting pays metal and returns the kind; lifted, nothing flows.
    check(!p.foundryRemove(2, 0), "flow: lifting needs the metal");
    p.inventory["iron_ingot"] = 1;
    check(p.foundryRemove(2, 0) && p.currency["vanguard"] == 2 && count(p, "form") == 0 && std::abs(onSheet(p).armour) < 1e-9,
          "flow: lifted for one iron, back in the purse, the forms gone");

    // The Catalyst: the same lane sharpens, the added lane reacts.
    economy::PlayerEconomy c(t);
    c.foundryEvent("first_kill:gloom_crawler"); // frost
    c.foundryEvent("first_kill:ember_whelp");   // ember
    c.grant("ember_catalyst", 1);
    c.grant("preserving_catalyst", 1);
    check(c.foundryPlaceSkill(1, 1, "prototype_frost_orb") && c.foundryPlace(1, 0, "ember") && c.foundryPlaceKind(2, 0, "ember_catalyst"),
          "catalyst: ember west of the orb, a catalyst in the corner below it");
    check(count(c, "augment") == 0 && foundry::flowsToSkill(c.foundry(), c.plate(), 2, 0), "catalyst: no base of its own, but it flows");
    bool scald = false;
    int reactionEffects = 0;
    for (const auto& e : foundry::effects(t, c.foundry(), c.plate())) {
        if (e.kind != "form") continue;
        ++reactionEffects;
        if (e.label.rfind("Scald", 0) == 0) scald = true;
        if (e.modifier == "damage_vs_ignite") check(e.packet == "cold", "catalyst: Scald's more damage is on the orb's own cold");
    }
    check(scald && reactionEffects == 2, "catalyst: Ember beside a cold orb, worked, is Scald: two effects");
    auto cm = grammar::foundryMods(t, c.foundry(), c.currentEra());
    checkNear(grammar::igniteApplied(t, cm, "prototype_frost_orb", false), 15.0, 1e-9, "catalyst: the scalded orb ignites");
    checkNear(grammar::igniteApplied(t, cm, "prototype_frost_nova", false), 0.0, 1e-9, "catalyst: the nova does not");
    auto plain = grammar::skillHit(t, cm, "prototype_frost_orb");
    auto burning = grammar::skillHit(t, cm, "prototype_frost_orb", {"ignite"});
    auto chilled = grammar::skillHit(t, cm, "prototype_frost_orb", {"chill"});
    check(plain.size() == 2 && burning.size() == 2, "catalyst: the orb is still a cold-and-fire bolt");
    checkNear(burning[0].damage, plain[0].damage * 1.2, 1e-9, "catalyst: an ignited enemy takes 20% more of the orb's cold");
    checkNear(burning[1].damage, plain[1].damage, 1e-9, "catalyst: and no more of its fire");
    checkNear(chilled[0].damage, plain[0].damage, 1e-9, "catalyst: a merely chilled enemy takes the plain hit");
    // The same lane: a Frost beside the orb worked by a catalyst is Deep Frost.
    c.inventory["iron_ingot"] = 1;
    check(c.foundryRemove(1, 0) && c.foundryPlace(1, 0, "frost"), "catalyst: frost in the ember's place");
    bool deep = false;
    for (const auto& e : foundry::effects(t, c.foundry(), c.plate()))
        if (e.kind == "form" && e.label.rfind("Deep Frost", 0) == 0 && e.modifier == "deep_frost") deep = true;
    check(deep, "catalyst: Frost beside a cold orb, worked, is Deep Frost");
    cm = grammar::foundryMods(t, c.foundry(), c.currentEra());
    check(grammar::chillApplied(t, cm, "prototype_frost_orb", false) > grammar::chillApplied(t, {}, "prototype_frost_orb", false) * 1.29,
          "catalyst: the orb chills deeper");
    check(c.foundryPlaceKind(1, 3, "preserving_catalyst") && !foundry::flowsToSkill(c.foundry(), c.plate(), 1, 3),
          "catalyst: any catalyst is the offence kind; this one touches no support yet");

    // The far cell (era two): a kind at depth three flows through a corner kind.
    economy::PlayerEconomy far(t);
    far.recordWorldEffect("stonecut_blocks"); // era two forges row 0
    far.foundryEvent("work:strike_split");    // edge
    far.grant("vanguard", 1);
    far.grant("ember_catalyst", 1);
    check(far.plate().forged(0, 3) && foundry::kindMayRest(far.plate(), 0, 3), "far: the far cell is forged and rests a kind");
    check(far.foundryPlaceSkill(2, 2, "prototype_heavy_strike") && far.foundryPlace(1, 2, "edge") && far.foundryPlaceKind(0, 3, "vanguard"),
          "far: the strike, its edge support, a Vanguard on the far cell");
    check(!foundry::flowsToSkill(far.foundry(), far.plate(), 0, 3) && std::abs(onSheet(far).armour) < 1e-9, "far: no piece between, no flow");
    check(far.foundryPlaceKind(1, 3, "ember_catalyst") && foundry::flowsToSkill(far.foundry(), far.plate(), 0, 3) &&
              std::abs(onSheet(far).armour - 4.0) < 1e-9,
          "far: a catalyst in the corner between carries the Vanguard's base inward");
    bool serration = false;
    for (const auto& e : foundry::effects(t, far.foundry(), far.plate()))
        if (e.kind == "form" && e.label.rfind("Serration", 0) == 0 && e.skill == "prototype_heavy_strike") serration = true;
    check(serration, "far: the catalyst works the edge into Serration for the strike");

    // The save carries a corner kind; a stale kind touching a socket goes back to the purse on load.
    save::SaveGame game;
    game.economy = c.exportState();
    auto back = save::fromJson(save::toJson(game));
    bool cornerRides = false;
    for (const auto& pl : back.economy.foundry.plate)
        if (pl.isCurrency() && pl.currency == "ember_catalyst" && pl.row == 2 && pl.col == 0) cornerRides = true;
    check(cornerRides, "flow: the kind rides in the save");
    economy::PlayerEconomy::State stale = p.exportState();
    stale.foundry.plate.clear();
    foundry::Placement bad;
    bad.row = 1;
    bad.col = 0;
    bad.currency = "vanguard"; // a support cell
    foundry::Placement good;
    good.row = 1;
    good.col = 3;
    good.currency = "vanguard"; // a corner
    stale.foundry.plate = {bad, good};
    stale.currency["vanguard"] = 0;
    economy::PlayerEconomy loaded(t);
    loaded.importState(stale);
    check(loaded.foundry().plate.size() == 1 && loaded.currency["vanguard"] == 1,
          "flow: a kind beside a socket is lifted back to the purse on load");
}

// D-023 slice 6 (owner, 4 Sep 2026, later): a family is a list of
// variants, each with its own base; catalysts have none and do the
// mechanical transformations, now with their hook halves as sim numbers.
void testVariantsAndHooks(const tuning::Tuning& t) {
    const auto& f = t.foundry;
    // The Warding Vanguard: a second variant of the defence family, reachable from the peddler.
    const auto* warding = f.findKindOnPlate("warding_vanguard");
    check(warding && warding->family == "defence" && warding->modifier == "all_resistance" && std::abs(warding->value - 5.0) < 1e-9 &&
              warding->shortName == "Warding" && t.crafting.isCurrency("warding_vanguard") &&
              t.crafting.findKind("warding_vanguard") && t.crafting.findKind("warding_vanguard")->family == "defence" &&
              std::find(t.crafting.exchangeKinds.begin(), t.crafting.exchangeKinds.end(), "warding_vanguard") != t.crafting.exchangeKinds.end(),
          "variants: the Warding Vanguard is a defence kind with its own base, in the purse and the exchange");
    check(f.findKindOnPlate("marrow") && f.findKindOnPlate("marrow")->modifier == "max_life" &&
              f.findKindOnPlate("quicksilver") && f.findKindOnPlate("quicksilver")->modifier == "swift_hands",
          "variants: Marrow and Quicksilver have small bases of their own");
    auto onSheet = [&](const economy::PlayerEconomy& who) {
        std::vector<stats::ExtraEffect> extra;
        for (const auto& m : grammar::foundryMods(t, who.foundry(), who.currentEra())) extra.push_back({m.effectKey, m.value});
        return stats::deriveStats(t.world.playerBase, {}, t.items, extra);
    };
    economy::PlayerEconomy w(t);
    w.foundryEvent("first_kill:gloom_crawler"); // frost
    w.grant("warding_vanguard", 1);
    check(w.foundryPlaceSkill(1, 1, "prototype_frost_orb") && w.foundryPlace(1, 0, "frost") && w.foundryPlaceKind(2, 0, "warding_vanguard"),
          "variants: a Warding Vanguard in the corner below the orb's frost");
    auto sheet = onSheet(w);
    check(std::abs(sheet.fireResistancePercent - 5.0) < 1e-9 && std::abs(sheet.coldResistancePercent - 5.0) < 1e-9 && std::abs(sheet.armour) < 1e-9,
          "variants: its base is five to every resistance, not armour");
    bool leech = false;
    for (const auto& e : foundry::effects(t, w.foundry(), w.plate()))
        if (e.kind == "form" && e.label.rfind("Frost Leech (Warding Vanguard", 0) == 0) leech = true;
    check(leech, "variants: it works the family's forms all the same, and the form names the variant");

    // The hooks as sim numbers, each from its form.
    auto laid = [&](const std::string& skill, const std::string& ingot, const std::string& event) {
        economy::PlayerEconomy e(t);
        e.learnSkill(skill);
        e.foundryEvent(event);
        e.grant("ember_catalyst", 1);
        check(e.foundryPlaceSkill(1, 1, skill) && e.foundryPlace(1, 0, ingot) && e.foundryPlaceKind(2, 0, "ember_catalyst"),
              "hooks: " + ingot + " beside " + skill + ", a catalyst in the corner");
        return e;
    };
    // Echo: Haste beside any skill, worked, repeats every fourth cast.
    auto echo = laid("prototype_frost_orb", "haste", "first_kill:ash_hound");
    auto em = grammar::foundryMods(t, echo.foundry(), echo.currentEra());
    check(grammar::skillEchoEvery(t, em, "prototype_frost_orb") == 4 && grammar::skillEchoEvery(t, em, "prototype_frost_nova") == 0,
          "hooks: Echo repeats the orb every fourth cast and no other skill");
    // Quench: Frost beside a fire skill, worked.
    auto quench = laid("prototype_ember_bolt", "frost", "first_kill:gloom_crawler");
    auto qm = grammar::foundryMods(t, quench.foundry(), quench.currentEra());
    check(grammar::skillQuenches(t, qm, "prototype_ember_bolt") && !grammar::skillQuenches(t, qm, "prototype_frost_orb"),
          "hooks: Quench belongs to the bolt alone");
    checkNear(grammar::chillApplied(t, qm, "prototype_ember_bolt", false), 15.0, 1e-9, "hooks: the quenching bolt chills");
    auto boltPlain = grammar::skillHit(t, qm, "prototype_ember_bolt");
    auto boltVsChilled = grammar::skillHit(t, qm, "prototype_ember_bolt", {"chill"});
    checkNear(boltVsChilled[0].damage, boltPlain[0].damage * 1.2, 1e-9, "hooks: a chilled enemy takes 20% more of the bolt's fire");
    // Rime: Frost beside a physical skill, worked: the novas chill.
    auto rime = laid("prototype_heavy_strike", "frost", "first_kill:gloom_crawler");
    auto rm = grammar::foundryMods(t, rime.foundry(), rime.currentEra());
    checkNear(grammar::skillNovaChill(t, rm, "prototype_heavy_strike"), 30.0, 1e-9, "hooks: Rime's novas chill by thirty");
    checkNear(grammar::skillNovaChill(t, rm, "prototype_area_strike"), 0.0, 1e-9, "hooks: and no other skill's");
    // Sear: Edge beside a fire skill, worked: bleeds, more against the bleeding, a faster burn while moving.
    auto sear = laid("prototype_ember_bolt", "edge", "work:strike_split");
    auto sm = grammar::foundryMods(t, sear.foundry(), sear.currentEra());
    checkNear(grammar::skillSear(t, sm, "prototype_ember_bolt"), 0.5, 1e-9, "hooks: Sear's burn ticks half again as fast while moving and bleeding");
    checkNear(grammar::bleedApplied(t, sm, "prototype_ember_bolt", false), 20.0, 1e-9, "hooks: the searing bolt bleeds");
    // Brittle: Edge beside a cold skill, worked: bleeds, and a frozen bleeder shatters from the spell's hit.
    auto brittle = laid("prototype_frost_orb", "edge", "work:strike_split");
    auto bm = grammar::foundryMods(t, brittle.foundry(), brittle.currentEra());
    check(grammar::skillBrittle(t, bm, "prototype_frost_orb") && !grammar::skillBrittle(t, bm, "prototype_heavy_strike"),
          "hooks: Brittle belongs to the orb alone");
    checkNear(grammar::bleedApplied(t, bm, "prototype_frost_orb", false), 20.0, 1e-9, "hooks: the brittle orb bleeds");
    // Serration: Edge beside a physical skill, worked: its hits bleed and its bleeds build faster.
    auto serration = laid("prototype_heavy_strike", "edge", "work:strike_split");
    auto srm = grammar::foundryMods(t, serration.foundry(), serration.currentEra());
    checkNear(grammar::bleedApplied(t, srm, "prototype_heavy_strike", false), 20.0 * 1.3, 1e-9, "hooks: Serration bleeds twenty, thirty percent faster");
    // Nothing of these on a bare plate.
    grammar::ActiveMods none;
    check(grammar::skillEchoEvery(t, none, "prototype_frost_orb") == 0 && !grammar::skillQuenches(t, none, "prototype_ember_bolt") &&
              !grammar::skillBrittle(t, none, "prototype_frost_orb") && std::abs(grammar::skillSear(t, none, "prototype_ember_bolt")) < 1e-9,
          "hooks: a bare plate has none of them");
}

// D-023 slice 7: links re-homed to the flow - a Catalyst in a corner
// touching a support shared by two sockets links the two skills, each
// casting the other on its own trigger - and Arc.
void testLinksAndArc(const tuning::Tuning& t) {
    const auto& f = t.foundry;
    check(f.linkFamily == "offence", "links: the Catalyst family links");
    bool arcForm = false;
    for (const auto& form : f.forms) if (form.displayName == "Arc" && form.ingot == "reach" && form.skillTag == "single_target") arcForm = true;
    check(arcForm && t.items.findModifier("arc"), "arc: the form and its modifier load");

    economy::PlayerEconomy p(t);
    p.learnSkill("prototype_shatter");
    p.foundryEvent("first_kill:gloom_crawler"); // frost
    p.foundryEvent("first_kill:ember_whelp");   // ember
    p.grant("ember_catalyst", 2);
    p.grant("vanguard", 1);
    check(p.foundryPlaceSkill(1, 1, "prototype_frost_orb") && p.foundryPlaceSkill(2, 2, "prototype_shatter") && p.foundryPlace(1, 2, "frost"),
          "links: the orb, Shatter, and a frost in the support they share");
    check(foundry::links(t, p.foundry(), p.plate()).empty(), "links: no kind in the corner, no link");
    check(p.foundryPlaceKind(2, 0, "vanguard") && foundry::links(t, p.foundry(), p.plate()).empty(),
          "links: a Vanguard in a corner links nothing");
    check(p.foundryPlace(1, 0, "ember") && p.foundryPlaceKind(2, 0, "ember_catalyst") == false, "links: the corner is taken");
    p.inventory["iron_ingot"] = 1;
    check(p.foundryRemove(2, 0) && p.foundryPlaceKind(2, 0, "ember_catalyst") && foundry::links(t, p.foundry(), p.plate()).empty(),
          "links: a catalyst touching a support of one skill alone links nothing");
    check(p.foundryPlaceKind(1, 3, "ember_catalyst"), "links: a catalyst in the corner beyond the shared support");
    auto links = foundry::links(t, p.foundry(), p.plate());
    check(links.size() == 1 && links[0].first == "prototype_frost_orb" && links[0].second == "prototype_shatter" &&
              links[0].row == 1 && links[0].col == 3 && links[0].supportRow == 1 && links[0].supportCol == 2,
          "links: the orb and Shatter are linked through the frost they share");
    bool linkEffect = false, deepFrost = false;
    for (const auto& e : foundry::effects(t, p.foundry(), p.plate())) {
        if (e.kind == "link" && e.skill == "prototype_frost_orb" && e.cellRow == 1 && e.cellCol == 2 && e.subject == "offence") linkEffect = true;
        if (e.kind == "form" && e.label.rfind("Deep Frost", 0) == 0 && e.skill == "prototype_frost_orb") deepFrost = true;
    }
    check(linkEffect && deepFrost, "links: the link is an effect on the shared support, and the catalyst still works the frost");
    auto mods = grammar::foundryMods(t, p.foundry(), p.currentEra());
    // The other corner's catalyst works the ember west of the orb into Scald, so the orb ignites too: two triggers.
    check(grammar::skillTriggers(t, mods, "prototype_frost_orb") == std::vector<std::string>{"freeze", "ignite"} &&
              grammar::skillTriggers(t, mods, "prototype_shatter").empty() && grammar::skillTriggers(t, mods, "prototype_heavy_strike").empty(),
          "links: the scalded orb's triggers are a freeze and an ignite; Shatter and a plain strike have none");
    check(grammar::linkedCasts(t, mods, p.foundry(), p.plate(), "prototype_frost_orb", "freeze") == std::vector<std::string>{"prototype_shatter"} &&
              grammar::linkedCasts(t, mods, p.foundry(), p.plate(), "prototype_frost_orb", "ignite") == std::vector<std::string>{"prototype_shatter"},
          "links: on the orb's freeze or its ignite, Shatter casts itself");
    check(grammar::linkedCasts(t, mods, p.foundry(), p.plate(), "prototype_frost_orb", "bleed").empty() &&
              grammar::linkedCasts(t, mods, p.foundry(), p.plate(), "prototype_shatter", "freeze").empty() &&
              grammar::linkedCasts(t, mods, p.foundry(), p.plate(), "prototype_heavy_strike", "bleed").empty(),
          "links: a trigger the skill cannot fire, or a skill with none, casts nothing");
    // A bleed skill linked to a fire skill runs both ways.
    economy::PlayerEconomy b(t);
    b.learnSkill("prototype_rend");
    b.learnSkill("prototype_ember_bolt");
    b.foundryEvent("first_kill:ash_hound"); // haste
    b.grant("ember_catalyst", 1);
    check(b.foundryPlaceSkill(1, 1, "prototype_rend") && b.foundryPlaceSkill(2, 2, "prototype_ember_bolt") && b.foundryPlace(2, 1, "haste") &&
              b.foundryPlaceKind(2, 0, "ember_catalyst"),
          "links: Rend and Ember Bolt share a haste, a catalyst in the corner by it");
    auto bm = grammar::foundryMods(t, b.foundry(), b.currentEra());
    check(grammar::linkedCasts(t, bm, b.foundry(), b.plate(), "prototype_rend", "bleed") == std::vector<std::string>{"prototype_ember_bolt"} &&
              grammar::linkedCasts(t, bm, b.foundry(), b.plate(), "prototype_ember_bolt", "ignite") == std::vector<std::string>{"prototype_rend"},
          "links: a bleed skill linked to a fire skill runs both ways");

    // Arc: Reach worked by a catalyst beside a strike sweeps; beside a projectile it splits instead.
    economy::PlayerEconomy a(t);
    a.foundryEvent("first_kill:cinder_archer"); // reach
    a.grant("ember_catalyst", 1);
    check(a.foundryPlaceSkill(1, 1, "prototype_heavy_strike") && a.foundryPlace(1, 0, "reach") && a.foundryPlaceKind(2, 0, "ember_catalyst"),
          "arc: reach beside the strike, worked by a catalyst");
    auto am = grammar::foundryMods(t, a.foundry(), a.currentEra());
    checkNear(grammar::skillArc(t, am, "prototype_heavy_strike"), 1.5, 1e-9, "arc: the strike sweeps a metre and a half either side");
    checkNear(grammar::skillArc(t, am, "prototype_area_strike"), 0.0, 1e-9, "arc: the area strike has no arc");
    check(grammar::forkCount(t, am, "prototype_heavy_strike") == 0, "arc: Split does not land on a strike");
    a.inventory["iron_ingot"] = 1;
    check(a.foundryRemove(1, 1) && a.foundryPlaceSkill(1, 1, "prototype_frost_orb"), "arc: the orb takes the socket");
    am = grammar::foundryMods(t, a.foundry(), a.currentEra());
    check(grammar::forkCount(t, am, "prototype_frost_orb") == grammar::forkCount(t, {}, "prototype_frost_orb") + 1 &&
              std::abs(grammar::skillArc(t, am, "prototype_frost_orb")) < 1e-9,
          "arc: beside the orb the same reach and catalyst are Split, not Arc");
}

// D-023 slice 8: the Marrow's sustain forms and the Quicksilver's tempo
// forms, each a corner kind working a support beside a skill; the Dash's
// forms land on the sheet because the Dash sits on no socket.
void testMarrowAndQuicksilverForms(const tuning::Tuning& t) {
    const auto& f = t.foundry;
    int life = 0, speed = 0;
    for (const auto& form : f.forms) {
        if (!form.metal.empty()) continue; // the compound forms of slice 10 sit on top
        if (form.family == "life") ++life;
        if (form.family == "speed") ++speed;
    }
    check(life == 8 && speed == 8, "marrow: eight forms each for the Marrow and the Quicksilver");
    for (const char* id : {"life_on_hit", "refund_on_kill", "haste_on_kill", "heal_more", "dash_reach", "life_on_dash", "armour_on_dash", "dash_recovery"})
        check(t.items.findModifier(id) != nullptr, std::string("marrow: the modifier ") + id + " loads");
    auto onSheet = [&](const economy::PlayerEconomy& who) {
        std::vector<stats::ExtraEffect> extra;
        for (const auto& m : grammar::foundryMods(t, who.foundry(), who.currentEra())) extra.push_back({m.effectKey, m.value});
        return stats::deriveStats(t.world.playerBase, {}, t.items, extra);
    };
    // A working with one kind in each corner: the Marrow below the west
    // support, the Quicksilver beyond the east one.
    auto laid = [&](const std::string& west, const std::string& westEvent, const std::string& east, const std::string& eastEvent) {
        economy::PlayerEconomy e(t);
        e.foundryEvent(westEvent);
        if (eastEvent != westEvent) e.foundryEvent(eastEvent);
        e.grant("marrow", 1);
        e.grant("quicksilver", 1);
        check(e.foundryPlaceSkill(1, 1, "prototype_frost_orb") && e.foundryPlace(1, 0, west) && e.foundryPlace(1, 2, east) &&
                  e.foundryPlaceKind(2, 0, "marrow") && e.foundryPlaceKind(1, 3, "quicksilver"),
              "marrow: the orb with " + west + " west and " + east + " east, a Marrow and a Quicksilver in the corners");
        return e;
    };
    // Frost (Cold Blood for the Marrow), Ember (Hot Hands for the Quicksilver).
    auto a = laid("frost", "first_kill:gloom_crawler", "ember", "first_kill:ember_whelp");
    auto am = grammar::foundryMods(t, a.foundry(), a.currentEra());
    bool coldBlood = false, hotHands = false;
    for (const auto& e : foundry::effects(t, a.foundry(), a.plate())) {
        if (e.kind == "form" && e.label.rfind("Cold Blood (Marrow", 0) == 0 && e.skill == "prototype_frost_orb") coldBlood = true;
        if (e.kind == "form" && e.label.rfind("Hot Hands (Quicksilver", 0) == 0 && e.skill == "prototype_frost_orb") hotHands = true;
    }
    check(coldBlood && hotHands, "marrow: Cold Blood and Hot Hands are worked on the orb's supports");
    checkNear(grammar::wardMultiplier(t, am, {"chill"}), 0.85, 1e-9, "marrow: Cold Blood - a chilled enemy deals 15% less to you");
    checkNear(grammar::skillHasteOnKill(t, am, "prototype_frost_orb"), 0.16, 1e-9, "marrow: Hot Hands - a kill with the orb quickens you");
    checkNear(grammar::skillHasteOnKill(t, am, "prototype_frost_nova"), 0.0, 1e-9, "marrow: and no other skill");
    auto sheetA = onSheet(a);
    check(std::abs(sheetA.maxLife - (t.world.playerBase.maxLife + 6.0)) < 1e-9 && std::abs(sheetA.armour) < 1e-9,
          "marrow: the Marrow's own six life on the sheet, and the Quicksilver's base is no armour");
    // Ember west (Cauterise) and Frost east (Cold Snap).
    auto b = laid("ember", "first_kill:ember_whelp", "frost", "first_kill:gloom_crawler");
    auto bm = grammar::foundryMods(t, b.foundry(), b.currentEra());
    checkNear(grammar::skillLifeOnHit(t, bm, "prototype_frost_orb"), 1.0, 1e-9, "marrow: Cauterise - a hit with the orb restores one life");
    checkNear(grammar::skillRefundOnKill(t, bm, "prototype_frost_orb"), 0.25, 1e-9, "marrow: Cold Snap - a kill refunds a quarter of the orb's cooldown");
    // Haste west (Lifeline) and Reach east (Long Step): both on the sheet.
    auto c = laid("haste", "first_kill:ash_hound", "reach", "first_kill:cinder_archer");
    auto sheetC = onSheet(c);
    check(std::abs(sheetC.healMore - 0.15) < 1e-9 && std::abs(sheetC.dashReachM - 1.0) < 1e-9,
          "marrow: Lifeline amplifies every heal by 15%, Long Step adds a metre to the Dash");
    // Vigour west (Hale) and Plate east (Braced Step); then swapped kinds: Scar Tissue and Second Breath.
    auto d = laid("vigour", "recipe:workbench_kit", "plate", "first_kill:stone_husk");
    auto sheetD = onSheet(d);
    check(std::abs(sheetD.maxLife - (t.world.playerBase.maxLife + 6.0 + 12.0 + 24.0)) < 1e-9 && std::abs(sheetD.armourOnDash - 8.0) < 1e-9,
          "marrow: Hale's 24 life on the sheet with the ingot's 12 and the Marrow's 6; Braced Step's 8 armour on a Dash");
    d.inventory["iron_ingot"] = 2;
    check(d.foundryRemove(2, 0) && d.foundryRemove(1, 3) && d.foundryPlaceKind(2, 0, "quicksilver") && d.foundryPlaceKind(1, 3, "marrow"),
          "marrow: the kinds swap corners");
    auto sheetD2 = onSheet(d);
    check(std::abs(sheetD2.lifeOnDash - 4.0) < 1e-9 && std::abs(sheetD2.armourOnDash) < 1e-9 &&
              std::abs(grammar::skillCastArmour(t, grammar::foundryMods(t, d.foundry(), d.currentEra()), "prototype_frost_orb") - (4.0 + 4.0)) < 1e-9,
          "marrow: swapped, the vigour is Second Breath and the plate Scar Tissue on top of its weak reading");
    // Ward (Warded Blood) and Haste (Fleet).
    auto e = laid("ward", "world_effect:stonecut_blocks", "haste", "first_kill:ash_hound");
    auto sheetE = onSheet(e);
    // The Ward ingot's own base is ten fire resistance, and its weak reading (5%) stacks with Warded Blood's 10%.
    check(std::abs(sheetE.fireResistancePercent - 15.0) < 1e-9 && std::abs(sheetE.coldResistancePercent - 5.0) < 1e-9 &&
              std::abs(sheetE.dashRecovery - 0.16) < 1e-9,
          "marrow: Warded Blood's five to every resistance on the ward's ten, Fleet's faster Dash");
    checkNear(grammar::wardMultiplier(t, grammar::foundryMods(t, e.foundry(), e.currentEra()), {"chill"}), 0.85, 1e-9,
              "marrow: Warded Blood's 10% on the Ward's own 5% - a chilled enemy deals 15% less");
    // Edge: Bloodletting and Quick Cut.
    auto g = laid("edge", "work:strike_split", "frost", "first_kill:gloom_crawler");
    g.inventory["iron_ingot"] = 3;
    check(g.foundryRemove(1, 3) && g.foundryRemove(1, 2) && g.foundryPlace(1, 2, "edge") == false, "marrow: one edge only");
    auto gm = grammar::foundryMods(t, g.foundry(), g.currentEra());
    checkNear(grammar::skillLifeOnKill(t, gm, "prototype_frost_orb"), 3.0, 1e-9, "marrow: Bloodletting - a kill with the orb restores three life");
    check(g.foundryRemove(2, 0) && g.foundryPlaceKind(2, 0, "quicksilver"), "marrow: the Quicksilver takes the edge's corner");
    gm = grammar::foundryMods(t, g.foundry(), g.currentEra());
    checkNear(grammar::skillRefundOnKill(t, gm, "prototype_frost_orb"), 0.15, 1e-9, "marrow: Quick Cut refunds 15% on a kill");
    checkNear(grammar::bleedApplied(t, gm, "prototype_frost_orb", false), 20.0, 1e-9, "marrow: and the orb bleeds");
    // Bare: none of it.
    grammar::ActiveMods none;
    check(std::abs(grammar::skillLifeOnHit(t, none, "prototype_frost_orb")) < 1e-9 && std::abs(grammar::skillRefundOnKill(t, none, "prototype_frost_orb")) < 1e-9 &&
              std::abs(stats::deriveStats(t.world.playerBase, {}, t.items, {}).healMore) < 1e-9,
          "marrow: a bare plate has none of it");
}

// D-023 slice 9: rails, the plate's surround. A class is chosen before
// play begins and its two patterns go in the rails from era one; the
// first trial's completion offers a specialisation that says what each
// pattern becomes; manners the world teaches join them.
void testRails(const tuning::Tuning& t) {
    const auto& rails = t.foundry.rails;
    check(rails.byEra == std::vector<int>{1, 2, 3} && rails.specialiseOnWorldEffect == "stonecut_blocks" && rails.classes.size() == 3 &&
              rails.specialisations.size() == 6 && rails.patterns.size() == 20 && rails.findClass("ranger") &&
              rails.findClass("ranger")->patterns == std::vector<std::string>{"volley", "quarry"} &&
              rails.findClass("ranger")->specialisations == std::vector<std::string>{"sharpshooter", "fletcher"} &&
              rails.findSpecialisation("sharpshooter") && rails.findSpecialisation("sharpshooter")->classId == "ranger" &&
              rails.findSpecialisation("sharpshooter")->becomes.at("volley") == "fusillade" && rails.findPattern("hounds_manner") &&
              rails.findPattern("hounds_manner")->isManner() && rails.findPattern("hounds_manner")->taughtByEnemy == "ash_hound" &&
              rails.allowed(1) == 1 && rails.allowed(2) == 2 && rails.allowed(3) == 3 && rails.allowed(9) == 3,
          "rails: three classes of two patterns and two specialisations, twenty patterns, one rail in era one, two, then three");
    const auto* fusillade = rails.findPattern("fusillade");
    const auto* volley = rails.findPattern("volley");
    check(fusillade && volley && fusillade->isGrown() && fusillade->from == "volley" && fusillade->axis == "column" &&
              fusillade->condition.allPlacedAre == volley->condition.allPlacedAre && fusillade->condition.holdsSkillTag == "projectile" &&
              fusillade->condition.minimumPlaced == 1 && fusillade->conditionText == volley->conditionText && fusillade->effects.size() == 2 &&
              !volley->isGrown(),
          "rails: a grown pattern inherits its base's axis, condition and words, and changes the rule");
    for (const char* id : {"extra_projectiles", "pierce", "armour_vs_elements", "barbs_more", "stagger_on_hit", "proliferate_on_hit",
                           "burning_ground_heal", "damage_vs_approaching", "still_armour"})
        check(t.items.findModifier(id) != nullptr, std::string("rails: the modifier ") + id + " loads");
    auto onSheet = [&](const economy::PlayerEconomy& who) {
        std::vector<stats::ExtraEffect> extra;
        for (const auto& m : grammar::foundryMods(t, who.foundry(), who.currentEra())) extra.push_back({m.effectKey, m.value});
        return stats::deriveStats(t.world.playerBase, {}, t.items, extra);
    };
    auto railEffects = [&](const economy::PlayerEconomy& who) {
        std::vector<foundry::Effect> out;
        for (const auto& e : foundry::effects(t, who.foundry(), who.plate()))
            if (e.kind == "rail") out.push_back(e);
        return out;
    };
    auto statusOf = [&](const economy::PlayerEconomy& who, const std::string& axis, int index) {
        const auto* rail = foundry::railAt(who.foundry(), axis, index);
        return rail ? foundry::railStatus(t, who.foundry(), who.plate(), *rail) : foundry::RailStatus{};
    };

    // Before play begins: the class. Until it is chosen the rails hold nothing.
    economy::PlayerEconomy p(t);
    p.inventory["iron_ingot"] = 20;
    check(p.canChooseClass() && !p.canSpecialise() && p.railsAllowed() == 1 && p.foundryPatterns().empty() && p.foundry().chosenClass.empty() &&
              !p.foundrySetRail("column", 1, "volley") && !p.foundryChooseClass("nothing") && !p.foundrySpecialise("sharpshooter"),
          "rails: no class yet - a rail allowed in era one but nothing to set, an unknown class refused, no specialising");
    check(p.foundryChooseClass("ranger") && !p.canChooseClass() && !p.foundryChooseClass("warden") && p.foundry().chosenClass == "ranger" &&
              p.foundryPatterns() == std::vector<std::string>{"volley", "quarry"} && !p.canSpecialise() && !p.foundrySpecialise("sharpshooter"),
          "rails: a Ranger, once - Volley and Quarry from the first era, no specialising before the trial");
    check(!p.foundrySetRail("row", 1, "volley") && !p.foundrySetRail("column", 1, "shield_wall") && !p.foundrySetRail("column", 7, "volley") &&
              !p.foundrySetRail("column", 1, "fusillade") && !p.foundrySetRail("column", 1, "nothing"),
          "rails: a column pattern refuses a row; another class's, a grown and an unknown pattern are refused; so is a slot off the frame");
    // Era one Volley: the bolt's socket in column 1 and one Reach below it - the socket's column has a single free cell.
    p.learnSkill("prototype_ember_bolt");
    p.foundryEvent("first_kill:cinder_archer"); // reach
    check(foundry::unplacedCount(p.foundry(), "reach") == 1 && p.foundryPlaceSkill(1, 1, "prototype_ember_bolt") && p.foundryPlace(2, 1, "reach") &&
              p.foundrySetRail("column", 1, "volley") && p.foundry().rails.size() == 1,
          "rails: the bolt laid with a Reach below it, Volley set in era one");
    auto status = statusOf(p, "column", 1);
    check(status.holds && status.placed == 1 && status.minimum == 1 && status.breaking.empty() && !status.missingSkill &&
              status.skills == std::vector<std::string>{"prototype_ember_bolt"},
          "rails: Volley holds in era one - the socket is the commitment, one Reach lights it");
    auto pm = grammar::foundryMods(t, p.foundry(), p.currentEra());
    check(grammar::skillProjectiles(t, pm, "prototype_ember_bolt") == 3 && grammar::skillProjectiles(t, pm, "prototype_frost_orb") == 1 &&
              grammar::skillPierce(t, pm, "prototype_ember_bolt") == 0,
          "rails: the bolt fires three projectiles, the orb one; nothing pierces yet");
    checkNear(grammar::skillReach(t, pm, "prototype_ember_bolt"), 1.0 + t.foundry.findIngot("reach")->supportValue() * t.foundry.supportMultiplier, 1e-9,
              "rails: the Reach keeps its plain reading under the rail");
    auto re = railEffects(p);
    check(re.size() == 1 && re[0].label == "Volley (column 2)" && re[0].skill == "prototype_ember_bolt" && re[0].modifier == "extra_projectiles" &&
              re[0].col == 1 && re[0].row == -1 && re[0].subject == "volley",
          "rails: the rule is one effect, named for its line, on the bolt");
    check(!p.foundrySetRail("row", 1, "quarry") && !p.foundrySetRail("column", 0, "volley"), "rails: era one allows one rail; one rail per pattern");
    // Break it: an Ember where the Reach was.
    p.foundryEvent("first_kill:ember_whelp"); // ember
    check(p.foundryRemove(2, 1) && p.foundryPlace(2, 1, "ember"), "rails: the Reach swapped for an Ember");
    status = statusOf(p, "column", 1);
    check(!status.holds && status.placed == 1 && status.breaking.size() == 1 && status.breaking[0].row == 2 && status.breaking[0].col == 1,
          "rails: the Ember breaks Volley, and the status names its cell");
    pm = grammar::foundryMods(t, p.foundry(), p.currentEra());
    check(grammar::skillProjectiles(t, pm, "prototype_ember_bolt") == 1 && railEffects(p).empty(), "rails: a broken rail bends nothing");
    check(p.foundryRemove(2, 1) && p.foundryPlace(2, 1, "reach") && statusOf(p, "column", 1).holds, "rails: the Reach back, the rail lit again");
    check(p.foundryRemove(1, 1) && statusOf(p, "column", 1).missingSkill && !statusOf(p, "column", 1).holds &&
              p.foundryPlaceSkill(1, 1, "prototype_ember_bolt"),
          "rails: no projectile skill in the column, Volley waits");

    // The trial: era two, a second rail, and the specialisation offered - a view of what the rails become.
    p.recordWorldEffect("stonecut_blocks");
    check(p.currentEra() == 2 && p.railsAllowed() == 2 && p.canSpecialise() && !p.foundrySpecialise("bulwark") && !p.foundrySpecialise("nothing") &&
              p.foundry().specialisation.empty() && statusOf(p, "column", 1).holds,
          "rails: the Tyrant's forge passed - a second rail and the choice offered; a Warden's specialisation is refused to a Ranger");
    p.foundryEvent("work:strike_split");                // edge
    p.foundryEvent("world_effect:old_mine_reinforced"); // edge
    check(p.foundryPlace(0, 0, "edge") && p.foundryPlace(0, 3, "edge") && p.foundrySetRail("row", 0, "quarry") && p.foundry().rails.size() == 2 &&
              statusOf(p, "row", 0).holds,
          "rails: Quarry set on row 1 with Edge at both ends");
    pm = grammar::foundryMods(t, p.foundry(), p.currentEra());
    check(grammar::skillPierce(t, pm, "prototype_ember_bolt") == 1 && grammar::skillPierce(t, pm, "prototype_frost_orb") == 1 &&
              grammar::skillPierce(t, pm, "prototype_heavy_strike") == 0,
          "rails: Quarry - every projectile pierces one more, the strike none");
    checkNear(grammar::bleedApplied(t, pm, "prototype_frost_orb", false), 20.0, 1e-9, "rails: and the orb's hits bleed");
    checkNear(grammar::bleedApplied(t, pm, "prototype_heavy_strike", false), 0.0, 1e-9, "rails: the strike does not");
    re = railEffects(p);
    check(re.size() == 3 && re[1].label == "Quarry (row 1)" && re[1].skill.empty() && re[1].packet == "projectile",
          "rails: Quarry's two effects are scoped by tag, not by the line");
    check(p.foundrySetRail("row", 0, "quarry") && !p.foundrySetRail("row", 2, "quarry") && !p.foundrySetRail("column", 0, "volley"),
          "rails: a set rail takes its pattern again; the same pattern on a second slot is refused");
    // Specialise: the rails become what the view showed.
    check(p.foundrySpecialise("sharpshooter") && !p.canSpecialise() && !p.foundrySpecialise("fletcher") && p.foundry().specialisation == "sharpshooter" &&
              p.foundryPatterns() == std::vector<std::string>{"fusillade", "deep_quarry"} &&
              foundry::railAt(p.foundry(), "column", 1)->pattern == "fusillade" && foundry::railAt(p.foundry(), "row", 0)->pattern == "deep_quarry",
          "rails: a Sharpshooter, once - Volley and Quarry become Fusillade and Deep Quarry, and the rails holding them become with them");
    pm = grammar::foundryMods(t, p.foundry(), p.currentEra());
    check(grammar::skillProjectiles(t, pm, "prototype_ember_bolt") == 3 && grammar::skillPierce(t, pm, "prototype_ember_bolt") == 3 &&
              grammar::skillPierce(t, pm, "prototype_frost_orb") == 2 && grammar::skillPierce(t, pm, "prototype_heavy_strike") == 0,
          "rails: Fusillade pierces once for the bolt in its column, Deep Quarry twice for every projectile");
    checkNear(grammar::bleedApplied(t, pm, "prototype_frost_orb", false), 30.0, 1e-9, "rails: Deep Quarry cuts deeper");
    re = railEffects(p);
    check(re.size() == 4 && re[0].label == "Fusillade (column 2)" && re[2].label == "Deep Quarry (row 1)" && !p.foundrySetRail("column", 3, "volley"),
          "rails: the rules carry the grown names, and the base pattern is no longer the Ranger's to set");
    // Manners: twelve hounds teach theirs; era three allows a third rail.
    p.takeFoundryNotices(); // the world effects' ingots
    for (int i = 0; i < 11; ++i) p.foundryEvent("first_kill:ash_hound");
    check(p.foundry().kills.at("ash_hound") == 11 && p.foundryPatterns().size() == 2 && p.takeFoundryNotices().empty(),
          "rails: eleven hounds have taught nothing yet");
    p.foundryEvent("first_kill:ash_hound");
    auto notices = p.takeFoundryNotices();
    check(p.foundryPatterns() == std::vector<std::string>{"fusillade", "deep_quarry", "hounds_manner"} &&
              notices == std::vector<std::string>{"manner:hounds_manner"} && p.takeFoundryNotices().empty(),
          "rails: the twelfth hound teaches the Hound's Manner, announced once");
    check(!p.foundrySetRail("row", 2, "hounds_manner"), "rails: era two's two rails are taken");
    p.recordWorldEffect("ash_tide");
    p.foundryEvent("recipe:smelt_bronze"); // a third edge
    check(p.currentEra() == 3 && p.railsAllowed() == 3 && statusOf(p, "column", 1).holds && p.foundryPlace(3, 0, "edge") &&
              p.foundrySetRail("row", 3, "hounds_manner") && p.foundry().rails.size() == 3,
          "rails: era three allows three - the manner set on the fourth row, Fusillade still lit down the longer column");
    status = statusOf(p, "row", 3);
    check(!status.holds && status.placed == 1 && status.breaking.empty() && std::abs(onSheet(p).damageVsApproaching) < 1e-9,
          "rails: one Edge is under the minimum; the manner waits");
    check(foundry::unplacedCount(p.foundry(), "haste") == 1 && p.foundryPlace(3, 2, "haste") && statusOf(p, "row", 3).holds &&
              std::abs(onSheet(p).damageVsApproaching - 0.25) < 1e-9,
          "rails: Edge, Haste alternates - enemies moving toward you take 25% more");
    check(p.foundryRemove(0, 0) && p.foundryPlace(3, 3, "edge") && statusOf(p, "row", 3).holds && !statusOf(p, "row", 0).holds,
          "rails: Edge, Haste, Edge alternates too - the Deep Quarry row gave up an Edge for it and waits");
    check(p.foundryRemove(3, 2) && p.foundryRemove(0, 3) && p.foundryPlace(3, 2, "edge") && !statusOf(p, "row", 3).holds &&
              statusOf(p, "row", 3).breaking.size() == 2 && statusOf(p, "row", 3).breaking[0].col == 2,
          "rails: Edge, Edge, Edge does not alternate; each repeat breaks it");
    check(p.foundryRemove(3, 2) && p.foundryRemove(3, 3) && p.foundryPlace(0, 0, "edge") && p.foundryPlace(0, 3, "edge") &&
              p.foundryPlace(3, 2, "haste") && statusOf(p, "row", 0).holds && statusOf(p, "row", 3).holds && statusOf(p, "column", 1).holds,
          "rails: the Edges back on row 1 - Deep Quarry, the manner and Fusillade all lit");
    // The save carries the surround, and a fresh economy validates it.
    save::SaveGame game;
    game.economy = p.exportState();
    auto back = save::fromJson(save::toJson(game));
    check(back.economy.foundry.chosenClass == "ranger" && back.economy.foundry.specialisation == "sharpshooter" && back.economy.foundry.rails.size() == 3 &&
              back.economy.foundry.rails[2].pattern == "hounds_manner" && back.economy.foundry.kills.at("ash_hound") == 12,
          "rails: the class, the specialisation, the rails and the kills round-trip through the save");
    economy::PlayerEconomy restored(t);
    restored.importState(back.economy);
    check(restored.foundry().chosenClass == "ranger" && restored.foundry().specialisation == "sharpshooter" && restored.foundry().rails.size() == 3 &&
              !restored.canChooseClass() && !restored.canSpecialise() &&
              grammar::skillPierce(t, grammar::foundryMods(t, restored.foundry(), restored.currentEra()), "prototype_ember_bolt") == 3,
          "rails: restored, the class stands and the rails still bend their rules");
    auto doctored = back;
    doctored.economy.foundry.specialisation = "bulwark"; // a Warden's
    doctored.economy.foundry.rails.push_back({"column", 3, "shield_wall"}); // a Warden's pattern
    economy::PlayerEconomy d1(t);
    d1.importState(doctored.economy);
    check(d1.foundry().chosenClass == "ranger" && d1.foundry().specialisation.empty() && d1.canSpecialise() && d1.foundry().rails.size() == 1 &&
              d1.foundry().rails[0].pattern == "hounds_manner" && d1.foundryPatterns() == std::vector<std::string>{"volley", "quarry", "hounds_manner"},
          "rails: a save with another class's specialisation forgets it, drops the grown rails and the foreign one, keeps the manner, and offers the choice again");
    doctored.economy.foundry.chosenClass = "nothing";
    economy::PlayerEconomy d2(t);
    d2.importState(doctored.economy);
    check(d2.foundry().chosenClass.empty() && d2.foundry().specialisation.empty() && d2.canChooseClass() && d2.foundry().rails.size() == 1,
          "rails: a save with an unknown class starts the choice over, keeping only the manner");

    // The Warden: Shield Wall in era one, Riposte after the trial, then a Sentinel.
    economy::PlayerEconomy w(t);
    w.inventory["iron_ingot"] = 20;
    w.foundryEvent("first_kill:stone_husk");            // plate
    w.foundryEvent("recipe:workbench_kit");             // vigour
    w.foundryEvent("work:strike_split");                // edge
    w.foundryEvent("world_effect:old_mine_reinforced"); // edge
    w.grant("vanguard", 1);
    check(w.foundryChooseClass("warden") && w.foundryPatterns() == std::vector<std::string>{"shield_wall", "riposte"} &&
              w.foundryPlace(1, 0, "plate") && w.foundryPlace(1, 2, "vigour") && w.foundrySetRail("row", 1, "shield_wall"),
          "rails: a Warden lays Plate and Vigour along row 2 and sets Shield Wall in era one");
    status = statusOf(w, "row", 1);
    check(!status.holds && status.missingKind && status.breaking.empty(), "rails: no Vanguard in the row, Shield Wall waits");
    check(w.foundryPlaceKind(1, 3, "vanguard") && statusOf(w, "row", 1).holds, "rails: a Vanguard resting at the row's far cell lights it");
    auto ws = onSheet(w);
    const double plainFire = stats::mitigateDamage(100.0, "fire", stats::deriveStats(t.world.playerBase, {}, t.items, {}), t.world.playerBase);
    const double walledFire = stats::mitigateDamage(100.0, "fire", ws, t.world.playerBase);
    check(std::abs(ws.armourVsElements - 1.0) < 1e-9 && ws.armour > 0.0 && walledFire < plainFire - 1.0 &&
              std::abs(walledFire - 100.0 * (1.0 - ws.fireResistancePercent / 100.0) * (1.0 - ws.armour / (ws.armour + t.world.playerBase.armourReductionScale))) < 1e-9,
          "rails: Shield Wall - the armour counts against fire in full, after the resistance");
    stats::DerivedStats half = ws;
    half.armourVsElements = 0.5;
    check(stats::mitigateDamage(100.0, "cold", half, t.world.playerBase) > walledFire && stats::mitigateDamage(100.0, "cold", half, t.world.playerBase) < plainFire,
          "rails: half the armour counts for half the answer");
    w.recordWorldEffect("stonecut_blocks");
    check(w.canSpecialise() && w.railsAllowed() == 2 && w.foundryPlace(0, 0, "edge") && w.foundryPlace(2, 0, "edge") && w.foundrySetRail("column", 0, "riposte") &&
              statusOf(w, "column", 0).holds,
          "rails: after the trial, Riposte - Edge at both ends of column 1 in era two");
    ws = onSheet(w);
    check(std::abs(ws.barbsMore - 1.0) < 1e-9 && std::abs(ws.barbsStagger - 0.5) < 1e-9 && std::abs(ws.stillArmour) < 1e-9,
          "rails: the Barbs bleed for twice and stagger half a second");
    check(w.foundrySpecialise("sentinel") && foundry::railAt(w.foundry(), "row", 1)->pattern == "bastion" &&
              foundry::railAt(w.foundry(), "column", 0)->pattern == "counterstroke" && statusOf(w, "row", 1).holds && statusOf(w, "column", 0).holds,
          "rails: a Sentinel - Shield Wall becomes Bastion and Riposte Counterstroke, both still lit");
    ws = onSheet(w);
    check(std::abs(ws.armourVsElements - 1.0) < 1e-9 && std::abs(ws.stillArmour - 16.0) < 1e-9 && std::abs(ws.barbsMore - 1.0) < 1e-9 &&
              std::abs(ws.barbsStagger - 1.0) < 1e-9 && std::abs(ws.hasteAfterHit - 0.16) < 1e-9,
          "rails: Bastion rewards stillness, Counterstroke staggers a full second and quickens you after a hit");
    w.recordWorldEffect("ash_tide");
    status = statusOf(w, "column", 0);
    check(!status.holds && status.breaking.empty() && std::abs(onSheet(w).barbsMore) < 1e-9,
          "rails: era three forges a fourth row - the column's end moved and Counterstroke waits for an Edge there");
    check(w.foundryRemove(2, 0) && w.foundryPlace(3, 0, "edge") && statusOf(w, "column", 0).holds,
          "rails: the middle Edge moved to the new end - rows 1 and 4 - and Counterstroke is lit again");

    // The Kindler: Pyre in era one, then a Pyromancer's Conflagration and Ash Walker; the Husk's Manner.
    economy::PlayerEconomy k(t);
    k.inventory["iron_ingot"] = 20;
    k.foundryEvent("recipe:smelt_iron");      // ember
    k.foundryEvent("first_kill:ember_whelp"); // ember
    k.foundryEvent("first_kill:ash_hound");   // haste
    check(k.foundryChooseClass("kindler") && k.foundryPlace(2, 0, "ember") && k.foundryPlace(2, 3, "ember") && k.foundrySetRail("row", 2, "pyre") &&
              statusOf(k, "row", 2).holds && std::abs(onSheet(k).proliferateOnHit - 0.5) < 1e-9,
          "rails: Pyre in era one - two Ember along row 3, ignites proliferate on the hit at half");
    k.recordWorldEffect("stonecut_blocks");
    check(k.foundrySpecialise("pyromancer") && foundry::railAt(k.foundry(), "row", 2)->pattern == "conflagration" &&
              std::abs(onSheet(k).proliferateOnHit - 1.0) < 1e-9,
          "rails: a Pyromancer - Pyre becomes Conflagration, the full spread on the hit");
    check(k.foundryPlace(0, 3, "haste") && k.foundrySetRail("column", 3, "ash_walker") && statusOf(k, "column", 3).holds &&
              std::abs(onSheet(k).burningGroundHeal - 4.0) < 1e-9 && std::abs(onSheet(k).dashReachM - 1.0) < 1e-9 && !k.foundrySetRail("column", 0, "ashen_step"),
          "rails: Ash Walker - Haste at the top of column 4 and Ember at the bottom; the base Ashen Step is no longer the Kindler's");
    check(k.foundryRemove(0, 3) && k.foundryRemove(2, 0) && k.foundryPlace(0, 3, "ember") && !statusOf(k, "column", 3).holds &&
              statusOf(k, "column", 3).breaking.size() == 2,
          "rails: Ember at both ends is not Ember and Haste; either end could be the wrong one, so both are named");
    k.takeFoundryNotices();
    for (int i = 0; i < 8; ++i) k.foundryEvent("first_kill:stone_husk");
    check(k.foundryPatterns() == std::vector<std::string>{"conflagration", "ash_walker", "husks_manner"} &&
              k.takeFoundryNotices() == std::vector<std::string>{"manner:husks_manner"},
          "rails: eight husks teach theirs to a Kindler too");
    check(foundry::unplacedCount(k.foundry(), "plate") == 1, "rails: the first husk's plate");
    // A bare plate and no class: nothing on the sheet.
    const auto bare = stats::deriveStats(t.world.playerBase, {}, t.items, {});
    check(std::abs(bare.armourVsElements) < 1e-9 && std::abs(bare.stillArmour) < 1e-9 && std::abs(bare.damageVsApproaching) < 1e-9 &&
              grammar::skillProjectiles(t, {}, "prototype_frost_orb") == 1 && grammar::skillPierce(t, {}, "prototype_frost_orb") == 0,
          "rails: bare, none of it");
}

// D-023 slice 10: the metal of an ingot. Every ingot is cast in a metal,
// iron by default; the forge re-casts one in the era's alloy, which widens
// how far its backing and pairs are read; elites and the deeper forge
// pay ingots already cast in alloy; compound forms need the metal.
void testMetal(const tuning::Tuning& t) {
    const auto& f = t.foundry;
    check(f.metals.size() == 3 && f.defaultMetal() == "iron" && f.metalReach("iron") == 1 && f.metalReach("bronze") == 2 &&
              f.metalReach("steel") == 3 && f.metalReach("") == 1 && f.metalReach("nothing") == 1 && f.maxReach() == 3 &&
              f.findMetal("bronze")->era == 2 && f.findMetal("bronze")->recastCost.at("bronze_ingot") == 1 && f.findMetal("iron")->recastCost.empty() &&
              f.alloyForEra(1) == "iron" && f.alloyForEra(2) == "bronze" && f.alloyForEra(3) == "steel" && f.alloyForEra(9) == "steel" &&
              f.recastStation == "forge_basic",
          "metal: iron, bronze and steel reach one, two and three; the era's alloy; re-casting at the forge");
    int alloySources = 0, compound = 0;
    for (const auto& s : f.sources)
        if (s.metal == "alloy") ++alloySources;
    for (const auto& form : f.forms)
        if (!form.metal.empty()) ++compound;
    check(alloySources == 4 && compound == 8, "metal: four alloy-cast sources, eight compound forms");
    auto pairs = [&](const economy::PlayerEconomy& who, const std::string& name) {
        int n = 0;
        for (const auto& e : foundry::effects(t, who.foundry(), who.plate()))
            if (e.kind == "pair" && e.label == name) ++n;
        return n;
    };
    auto count = [&](const economy::PlayerEconomy& who, const std::string& kind) {
        int n = 0;
        for (const auto& e : foundry::effects(t, who.foundry(), who.plate()))
            if (e.kind == kind) ++n;
        return n;
    };
    auto hasForm = [&](const economy::PlayerEconomy& who, const std::string& prefix) {
        for (const auto& e : foundry::effects(t, who.foundry(), who.plate()))
            if (e.kind == "form" && e.label.rfind(prefix, 0) == 0) return true;
        return false;
    };

    // Every milestone's ingot is iron; a placement carries its metal.
    economy::PlayerEconomy p(t);
    p.inventory["iron_ingot"] = 20;
    p.foundryEvent("first_kill:ember_whelp");   // ember
    p.foundryEvent("first_kill:cinder_archer"); // reach
    p.foundryEvent("first_kill:gloom_crawler"); // frost
    p.foundryEvent("first_kill:shrieker");      // frost
    check(foundry::castCount(p.foundry(), "ember", "iron") == 1 && foundry::castCount(p.foundry(), "ember", "bronze") == 0 &&
              foundry::unplacedCountOf(f, p.foundry(), "ember", "iron") == 1 && foundry::castCount(p.foundry(), "frost", "iron") == 2,
          "metal: a milestone's ingot is cast in iron");
    check(!p.foundryPlace(1, 0, "ember", "bronze") && !p.foundryPlace(1, 0, "ember", "nothing") && p.foundryPlace(1, 0, "ember") &&
              foundry::at(p.foundry(), 1, 0)->metal == "iron" && foundry::unplacedCountOf(f, p.foundry(), "ember", "iron") == 0,
          "metal: placed in the only metal in hand, iron; a metal not in hand is refused");
    // Re-casting: the era, the forge, the alloy, and an ingot in hand.
    check(!p.canRecast("ember", "bronze") && !p.foundryRecast("ember", "bronze") && !p.canRecast("ember", "iron") && !p.canRecast("ember", "nothing"),
          "metal: era one casts nothing in bronze; iron is never re-cast into");
    p.recordWorldEffect("stonecut_blocks");
    check(p.currentEra() == 2 && !p.canRecast("ember", "bronze"), "metal: era two, but no forge");
    p.addAvailableStation("forge_basic");
    check(!p.canRecast("ember", "bronze"), "metal: a forge, but no bronze");
    p.inventory["bronze_ingot"] = 2;
    check(!p.canRecast("ember", "bronze") && !p.foundryRecast("ember", "bronze"), "metal: bronze in the pack, but the Ember is on the plate");
    check(p.foundryRemove(1, 0) && p.canRecast("ember", "bronze") && p.foundryRecast("ember", "bronze") && p.inventory["bronze_ingot"] == 1 &&
              foundry::castCount(p.foundry(), "ember", "bronze") == 1 && foundry::castCount(p.foundry(), "ember", "iron") == 0 &&
              foundry::unplacedCountOf(f, p.foundry(), "ember", "bronze") == 1 && p.foundry().owned.at("ember") == 1,
          "metal: lifted and re-cast in bronze for one bronze ingot; still one Ember owned");
    check(!p.canRecast("ember", "bronze") && !p.canRecast("ember", "steel"), "metal: nothing narrower left to re-cast, and steel waits for era three");
    // A pair read two cells out: the bronze Ember at (0,0) pairs with a Reach at (0,2), the gap ignored.
    check(p.foundryPlace(0, 0, "ember") && foundry::at(p.foundry(), 0, 0)->metal == "bronze" && p.foundryPlaceSkill(1, 1, "prototype_frost_orb") &&
              p.foundryPlace(0, 2, "reach") && pairs(p, "Wildfire") == 1,
          "metal: the bronze Ember pairs with the Reach two cells out (Wildfire), the gap ignored");
    check(p.foundryPlace(0, 3, "frost") && pairs(p, "Deep Frost") == 1, "metal: the iron Frost beside the Reach still pairs");
    check(p.foundryRemove(0, 3) && p.foundryRemove(0, 2) && p.foundryPlace(0, 3, "reach") && pairs(p, "Wildfire") == 0,
          "metal: three cells out is beyond bronze");
    check(p.foundryRemove(0, 0) && p.foundryRemove(0, 3) && p.foundryPlace(1, 0, "ember") && p.foundryPlace(1, 2, "reach") && pairs(p, "Wildfire") == 0,
          "metal: the orb's socket between them stops the reading - nothing is read through a socket");
    check(p.foundryRemove(1, 0) && p.foundryRemove(1, 2) && p.foundryPlace(1, 0, "ember") && p.foundryPlace(0, 2, "frost"),
          "metal: the Ember back beside the orb, the Frost up on the first row");
    // Backing read two cells out, never through the socket.
    p.learnSkill("prototype_ember_bolt");
    check(p.foundryRemove(0, 2) && p.foundryPlaceSkill(2, 2, "prototype_ember_bolt") && p.foundryPlace(2, 3, "frost") && p.foundryPlace(0, 3, "frost") &&
              count(p, "backing") == 0,
          "metal: two iron Frosts two cells apart do not back");
    p.inventory["bronze_ingot"] = 1;
    check(p.foundryRemove(0, 3) && p.foundryRecast("frost", "bronze") && p.foundryPlace(0, 3, "frost") && foundry::at(p.foundry(), 0, 3)->metal == "bronze" &&
              count(p, "backing") == 1,
          "metal: the bronze Frost two cells up backs the Frost beside the bolt");
    check(p.foundryRemove(0, 3) && p.foundryRemove(2, 3) && p.foundryPlace(2, 1, "frost", "bronze") && p.foundryPlace(2, 3, "frost", "iron") &&
              count(p, "support") + count(p, "added") >= 2 && count(p, "backing") == 0,
          "metal: Frosts on both sides of the bolt's socket are two supports, never each other's backing");
    // A compound form: the Catalyst's Kindling on a bronze Ember beside the bolt.
    p.grant("ember_catalyst", 1);
    check(p.foundryRemove(2, 1) && p.foundryRemove(1, 0) && p.foundryPlace(2, 1, "ember", "bronze") && p.foundryPlaceKind(3, 1, "ember_catalyst") == false,
          "metal: the Ember moved beside the bolt; the fourth row is not forged yet");
    check(p.foundryPlaceKind(2, 0, "ember_catalyst") && hasForm(p, "Kindling (") && hasForm(p, "Bronze Kindling ("),
          "metal: a bronze Ember worked by a Catalyst is Kindling and Bronze Kindling both");
    p.inventory["iron_ingot"] = 20;
    check(p.foundryRemove(2, 1) && p.foundryPlace(2, 1, "frost", "bronze") && hasForm(p, "Deep Frost (") && hasForm(p, "Bronze Deep Frost ("),
          "metal: the bronze Frost there is Deep Frost and Bronze Deep Frost");
    check(p.foundryRemove(2, 1) && p.foundryRemove(2, 3) && p.foundryPlace(2, 1, "frost", "iron") && !hasForm(p, "Bronze Deep Frost (") && hasForm(p, "Deep Frost ("),
          "metal: an iron Frost there is Deep Frost alone");
    // Era three: steel, and the alloy-cast sources.
    economy::PlayerEconomy k(t);
    check(k.foundryEvent("elite_kill:ash_hound").empty() && k.foundryEvent("first_kill:ash_hound") == std::vector<std::string>{"haste"},
          "metal: an elite hound pays nothing in era one; the first hound pays iron Haste");
    k.recordWorldEffect("stonecut_blocks");
    check(k.foundryEvent("elite_kill:ash_hound") == std::vector<std::string>{"haste"} && foundry::castCount(k.foundry(), "haste", "bronze") == 1 &&
              foundry::castCount(k.foundry(), "haste", "iron") == 1 && k.foundryEvent("elite_kill:ash_hound").empty(),
          "metal: in era two the first elite hound pays a Haste cast in bronze, once");
    k.recordWorldEffect("ash_tide");
    check(foundry::castCount(k.foundry(), "frost", "steel") == 1 && k.foundryEvent("elite_kill:hollow_knight") == std::vector<std::string>{"ward"} &&
              foundry::castCount(k.foundry(), "ward", "steel") == 1,
          "metal: the deeper forge pays a steel Frost, the first elite knight a steel Ward");
    k.addAvailableStation("forge_basic");
    k.inventory["steel_ingot"] = 1;
    check(k.canRecast("haste", "steel") && k.foundryRecast("haste", "steel") && foundry::castCount(k.foundry(), "haste", "steel") == 1 &&
              foundry::castCount(k.foundry(), "haste", "iron") == 0 && foundry::castCount(k.foundry(), "haste", "bronze") == 1,
          "metal: steel re-casts the narrowest casting first - the iron Haste, not the bronze");
    check(k.foundryPlace(0, 0, "haste") && foundry::at(k.foundry(), 0, 0)->metal == "steel" && k.foundryPlace(3, 0, "frost") &&
              foundry::at(k.foundry(), 3, 0)->metal == "steel",
          "metal: placing takes the widest casting in hand");
    k.foundryEvent("first_kill:ember_whelp");
    k.inventory["iron_ingot"] = 5;
    check(k.foundryPlace(3, 3, "ember") && pairs(k, "Lingering Flame") == 0 && k.foundryRemove(3, 3) && k.foundryPlace(0, 3, "ember") &&
              pairs(k, "Lingering Flame") == 1,
          "metal: steel Haste at one end of the row reaches the Ember three cells along; a column apart and three down it does not");
    // The save carries the metals; an older save is all iron; a doctored one is brought back to what is owned.
    save::SaveGame game;
    game.economy = k.exportState();
    auto back = save::fromJson(save::toJson(game));
    check(back.economy.foundry.metals.at("haste").at("steel") == 1 && back.economy.foundry.metals.at("haste").at("bronze") == 1 &&
              back.economy.foundry.plate[0].metal == "steel",
          "metal: the castings and a placement's metal round-trip through the save");
    economy::PlayerEconomy restored(t);
    restored.importState(back.economy);
    check(foundry::castCount(restored.foundry(), "haste", "steel") == 1 && foundry::at(restored.foundry(), 0, 0)->metal == "steel" &&
              pairs(restored, "Lingering Flame") == 1,
          "metal: restored, the steel Haste still reads three cells");
    auto older = back;
    older.economy.foundry.metals.clear();
    for (auto& placement : older.economy.foundry.plate) placement.metal.clear();
    economy::PlayerEconomy old(t);
    old.importState(older.economy);
    check(foundry::castCount(old.foundry(), "haste", "iron") == 2 && foundry::castCount(old.foundry(), "haste", "steel") == 0 &&
              foundry::at(old.foundry(), 0, 0)->metal == "iron" && pairs(old, "Lingering Flame") == 0,
          "metal: a save from before the metals is all iron");
    auto doctored = back;
    doctored.economy.foundry.metals["haste"]["steel"] = 5;
    doctored.economy.foundry.metals["haste"]["gold"] = 2;
    economy::PlayerEconomy fixed(t);
    fixed.importState(doctored.economy);
    check(foundry::castCount(fixed.foundry(), "haste", "steel") + foundry::castCount(fixed.foundry(), "haste", "bronze") +
                      foundry::castCount(fixed.foundry(), "haste", "iron") == fixed.foundry().owned.at("haste") &&
              foundry::castCount(fixed.foundry(), "haste", "steel") >= 1 && foundry::castCount(fixed.foundry(), "haste", "gold") == 0,
          "metal: a doctored save's castings sum to what is owned, the placed steel kept, an unknown metal dropped");
}

// The class kits (owner, 4 Sep 2026): a class chosen before play starts
// with its own skills, on the bar in order; the base four stay the kit of
// a character with no class (tests), and become pages for the rest.
void testClassKits(const tuning::Tuning& t) {
    const auto& rails = t.foundry.rails;
    const auto* ranger = rails.findClass("ranger");
    const auto* warden = rails.findClass("warden");
    const auto* kindler = rails.findClass("kindler");
    check(ranger && warden && kindler && ranger->startingSkills.size() == 4 && ranger->startingSkills[0] == "prototype_bow_shot" &&
              warden->startingSkills[0] == "prototype_heavy_strike" && kindler->startingSkills[0] == "prototype_ember_bolt" &&
              kindler->startingSkills[1] == "prototype_cinder_sweep" && t.skills.findCombatSkill("prototype_bow_shot") &&
              t.skills.findCombatSkill("prototype_cinder_sweep") && t.skills.findCombatSkill("prototype_bow_shot")->delivery == "projectile" &&
              t.skills.findCombatSkill("prototype_cinder_sweep")->delivery == "cone",
          "kits: each class starts with four, a bow shot for the Ranger, a strike for the Warden, a bolt and a sweep for the Kindler");
    check(t.skills.findCombatSkill("prototype_frost_orb")->dropWeight > 0.0 && t.skills.findCombatSkill("prototype_area_strike")->dropWeight > 0.0 &&
              t.skills.findCombatSkill("prototype_dash")->dropWeight == 0.0 && t.skills.startingSkillIds().size() == 4,
          "kits: the orb and the strikes are pages for the classes without them; the Dash is everyone's; the base four stand for no class");
    economy::PlayerEconomy p(t);
    check(p.knownSkills() == t.skills.startingSkillIds() && p.skillBar()[0] == "prototype_area_strike",
          "kits: no class yet - the base four, the strike first");
    check(p.learnSkill("prototype_shatter") && p.foundryPlaceSkill(1, 1, "prototype_frost_orb"), "kits: a page learned and the orb laid before the choice");
    check(p.foundryChooseClass("ranger") && p.knownSkills() == std::vector<std::string>{"prototype_bow_shot", "prototype_rend", "prototype_area_strike", "prototype_dash", "prototype_shatter"} &&
              p.skillBar() == std::vector<std::string>{"prototype_bow_shot", "prototype_rend", "prototype_area_strike", "prototype_dash"} &&
              !p.knowsSkill("prototype_frost_orb") && !p.knowsSkill("prototype_heavy_strike") && p.foundry().plate.empty(),
          "kits: a Ranger - the bow shot first on the bar, the orb and the heavy strike gone, the page kept, the orb's tablet lifted");
    check(p.learnSkill("prototype_frost_orb") && p.knowsSkill("prototype_frost_orb"), "kits: the orb comes back as a page");
    economy::PlayerEconomy w(t);
    check(w.foundryChooseClass("warden") && w.skillBar() == std::vector<std::string>{"prototype_heavy_strike", "prototype_area_strike", "prototype_frost_nova", "prototype_dash"} &&
              !w.knowsSkill("prototype_frost_orb"),
          "kits: a Warden - strikes and a nova, no orb");
    economy::PlayerEconomy k(t);
    check(k.foundryChooseClass("kindler") && k.skillBar()[0] == "prototype_ember_bolt" && k.knowsSkill("prototype_cinder_sweep") && k.knowsSkill("prototype_frost_orb") &&
              !k.knowsSkill("prototype_area_strike"),
          "kits: a Kindler - the bolt, the sweep, the orb for the scald, no strikes");
    // The save carries the kit through the class.
    save::SaveGame game;
    game.economy = p.exportState();
    auto back = save::fromJson(save::toJson(game));
    economy::PlayerEconomy restored(t);
    restored.importState(back.economy);
    check(restored.knownSkills()[0] == "prototype_bow_shot" && restored.skillBar()[0] == "prototype_bow_shot" && !restored.canChooseClass(),
          "kits: restored, the Ranger keeps the bow");
}

// The class gear pass (owner, 4 Sep 2026: "items to accommodate the
// classes, i.e. bows that enhance projectile attacks"): an offhand slot,
// bows and projectile modifiers for the Ranger, shields for the Warden, a
// brand and a lantern for the Kindler, at the bench and the forge.
void testClassGear(const tuning::Tuning& t) {
    const auto* bow = t.items.findBase("hunting_bow");
    const auto* longbow = t.items.findBase("bronze_longbow");
    const auto* quiver = t.items.findBase("hide_quiver");
    const auto* timber = t.items.findBase("timber_shield");
    const auto* shield = t.items.findBase("iron_shield");
    const auto* brand = t.items.findBase("charred_brand");
    const auto* lantern = t.items.findBase("cinder_lantern");
    check(bow && longbow && quiver && timber && shield && brand && lantern && bow->slot == "weapon" && quiver->slot == "offhand" &&
              timber->slot == "offhand" && shield->slot == "offhand" && lantern->slot == "offhand" && brand->slot == "weapon" &&
              bow->tierCap == 2 && longbow->tierCap == 3 && timber->tierCap == 1 && t.items.itemBases.size() == 14,
          "gear: seven new bases in their slots - the offhand is the fourth - with their metals' caps");
    for (const char* id : {"projectile_damage", "fletching", "barbed_heads"})
        check(t.items.findModifier(id) != nullptr && !t.items.findModifier(id)->isSelf(), std::string("gear: the modifier ") + id + " loads");
    check(t.items.findModifier("fletching")->fromTier == 2 && t.items.findModifier("barbed_heads")->fromTier == 2 &&
              t.items.findModifier("projectile_damage")->fromTier == 1,
          "gear: the fan and the pierce wait for tier two; the damage line rolls from one");
    for (const char* id : {"hunting_bow", "bronze_longbow", "hide_quiver", "timber_shield", "iron_shield", "charred_brand", "cinder_lantern"})
        check(t.crafting.findRecipe(id) != nullptr, std::string("gear: a recipe makes ") + id);
    check(t.crafting.findRecipe("hide_quiver")->station == "workbench" && t.crafting.findRecipe("timber_shield")->station == "workbench" &&
              t.crafting.findRecipe("hunting_bow")->station == "forge_basic" && t.crafting.findRecipe("bronze_longbow")->minimumSkill.at("blacksmithing") == 3,
          "gear: the quiver and the timber shield at the bench, the bow at the forge, the longbow behind Blacksmithing 3");

    // The bow's implicit speaks to projectiles alone: the Bow Shot and the orb, never the strike.
    auto bare = [&](const std::string& skill) { return grammar::skillDamage(t, {}, skill); };
    stats::Equipment worn;
    worn.slots["weapon"] = items::rollRarityItem(t.items, "hunting_bow", "plain", 1, 1);
    auto mods = grammar::gearMods(t.items, worn);
    checkNear(grammar::skillDamage(t, mods, "prototype_bow_shot") / bare("prototype_bow_shot"), 1.1, 1e-9, "gear: the bow's implicit is +10% for the Bow Shot");
    checkNear(grammar::skillDamage(t, mods, "prototype_frost_orb") / bare("prototype_frost_orb"), 1.1, 1e-9, "gear: and for the orb - any projectile");
    checkNear(grammar::skillDamage(t, mods, "prototype_heavy_strike") / bare("prototype_heavy_strike"), 1.0, 1e-9, "gear: never the strike");
    check(grammar::skillProjectiles(t, mods, "prototype_bow_shot") == 1 && grammar::skillPierce(t, mods, "prototype_bow_shot") == 0,
          "gear: a plain bow fans and pierces nothing");
    // A wrought bow at tier two may roll Fletching and Barbed Heads, never a self stat.
    bool fanned = false, barbed = false, selfStat = false;
    for (uint64_t seed = 0; seed < 80; ++seed) {
        auto item = items::rollRarityItem(t.items, "hunting_bow", "wrought", 2, seed);
        for (const auto& rolled : item.rolledProperties) {
            if (rolled.propertyId == "fletching") fanned = true;
            if (rolled.propertyId == "barbed_heads") barbed = true;
            if (t.items.findModifier(rolled.propertyId)->isSelf()) selfStat = true;
        }
    }
    check(fanned && barbed && !selfStat, "gear: a wrought bow rolls the fan and the pierce, never life or armour");
    // Fletching and Barbed Heads worn: the Bow Shot fans and pierces; the quiver stacks a second Fletching.
    items::ItemInstance fletched = items::rollRarityItem(t.items, "hunting_bow", "plain", 2, 3);
    fletched.rolledProperties.push_back({"fletching", 2, 1.0});
    fletched.rolledProperties.push_back({"barbed_heads", 2, 1.0});
    worn.slots["weapon"] = fletched;
    items::ItemInstance quiverItem = items::rollRarityItem(t.items, "hide_quiver", "plain", 2, 4);
    quiverItem.rolledProperties.push_back({"fletching", 2, 1.0});
    worn.slots["offhand"] = quiverItem;
    mods = grammar::gearMods(t.items, worn);
    check(grammar::skillProjectiles(t, mods, "prototype_bow_shot") == 3 && grammar::skillPierce(t, mods, "prototype_bow_shot") == 1 &&
              grammar::skillProjectiles(t, mods, "prototype_heavy_strike") == 1 && grammar::skillPierce(t, mods, "prototype_ember_bolt") == 1,
          "gear: Fletching on the bow and the quiver make three arrows, Barbed Heads one pierce, for projectiles alone");
    checkNear(grammar::skillDamage(t, mods, "prototype_bow_shot") / bare("prototype_bow_shot"), 1.15, 1e-9,
              "gear: the bow's and the quiver's projectile implicits add - 15% together");
    // The shields on the sheet: the offhand and the chest both count.
    stats::Equipment warden;
    warden.slots["offhand"] = items::rollRarityItem(t.items, "iron_shield", "plain", 1, 5);
    warden.slots["chest"] = items::rollRarityItem(t.items, "iron_chest_armour", "plain", 1, 6);
    const auto sheet = stats::deriveStats(t.world.playerBase, warden, t.items);
    check(std::abs(sheet.armour - (10.0 + 20.0)) < 1e-9, "gear: the iron shield's ten armour with the chest's twenty");
    // The brand and the lantern: fire for the sweep and the bolt, burns harder.
    stats::Equipment kindler;
    kindler.slots["weapon"] = items::rollRarityItem(t.items, "charred_brand", "plain", 1, 7);
    kindler.slots["offhand"] = items::rollRarityItem(t.items, "cinder_lantern", "plain", 1, 8);
    mods = grammar::gearMods(t.items, kindler);
    checkNear(grammar::skillDamage(t, mods, "prototype_cinder_sweep") / bare("prototype_cinder_sweep"), 1.1, 1e-9, "gear: the brand is +10% fire for the sweep");
    checkNear(grammar::skillDamage(t, mods, "prototype_ember_bolt") / bare("prototype_ember_bolt"), 1.1, 1e-9, "gear: and for the bolt");
    checkNear(grammar::skillDamage(t, mods, "prototype_bow_shot") / bare("prototype_bow_shot"), 1.0, 1e-9, "gear: never the arrow");
    check(grammar::igniteStatus(t, mods).damagePerS > grammar::igniteStatus(t, {}).damagePerS, "gear: the lantern's burns bite harder");
    // Crafting: the quiver at a bench from hide, the bow at the forge.
    economy::PlayerEconomy p(t);
    p.addAvailableStation("workbench");
    p.inventory["hide"] = 3;
    p.inventory["wood"] = 12;
    check(p.craft("hide_quiver").crafted && !p.packItems.empty() && p.packItems.back().baseId == "hide_quiver" && p.inventory["hide"] == 0,
          "gear: a quiver sewn at the bench lands in the pack as a rolled piece");
    check(p.craft("timber_shield").crafted == false, "gear: the timber shield wants a hide strap too");
    p.inventory["hide"] = 1;
    check(p.craft("timber_shield").crafted && p.packItems.back().baseId == "timber_shield" && p.packItems.back().rarity == "plain",
          "gear: a timber shield lashed at the bench, plain at Blacksmithing 1");
    check(!p.craft("hunting_bow").crafted, "gear: the bow wants the forge");
    p.addAvailableStation("forge_basic");
    p.inventory["iron_ingot"] = 2;
    p.inventory["wood"] = 8;
    check(p.craft("hunting_bow").crafted && p.packItems.back().baseId == "hunting_bow" && p.inventory["iron_ingot"] == 0,
          "gear: a bow strung at the forge for two iron and a stave");
    // Loot never picks an unknown slot: every base's slot is one of the table's.
    for (const auto& base : t.items.itemBases)
        check(std::find(t.items.slots.begin(), t.items.slots.end(), base.slot) != t.items.slots.end(), "gear: " + base.id + " sits in a known slot");
}

// Melee's space control (Wave 5 item 11): a strike staggers and shoves the
// mob it hits and braces the swinger; bosses take their fractions.
void testMelee(const tuning::Tuning& t) {
    const auto& m = t.grammar.melee;
    check(std::abs(m.bossStaggerMultiplier - 0.5) < 1e-9 && std::abs(m.bossPushMultiplier) < 1e-9, "melee: a boss takes half the stagger and none of the push");
    checkNear(grammar::skillStagger(t, {}, "prototype_heavy_strike", false), 0.4, 1e-9, "melee: the heavy strike staggers 0.4 s");
    checkNear(grammar::skillStagger(t, {}, "prototype_heavy_strike", true), 0.2, 1e-9, "melee: half of it on a boss");
    checkNear(grammar::skillPush(t, {}, "prototype_area_strike", false), 1.2, 1e-9, "melee: the area strike shoves 1.2 m");
    checkNear(grammar::skillPush(t, {}, "prototype_area_strike", true), 0.0, 1e-9, "melee: and never a boss");
    checkNear(grammar::skillPush(t, {}, "prototype_heavy_strike", false), 0.5, 1e-9, "melee: the heavy strike shoves half a metre");
    checkNear(grammar::skillStagger(t, {}, "prototype_frost_orb", false), 0.0, 1e-9, "melee: the orb staggers nothing");
    checkNear(grammar::skillPush(t, {}, "prototype_bow_shot", false), 0.0, 1e-9, "melee: an arrow shoves nothing");
    checkNear(grammar::skillCastArmour(t, {}, "prototype_heavy_strike"), 12.0, 1e-9, "melee: the heavy strike's swing braces twelve");
    checkNear(grammar::skillSwingSeconds(t, "prototype_heavy_strike"), 0.5, 1e-9, "melee: for half a second");
    checkNear(grammar::skillCastArmour(t, {}, "prototype_cinder_sweep"), 6.0, 1e-9, "melee: the sweep braces six");
    checkNear(grammar::skillSwingSeconds(t, "prototype_frost_orb"), 0.0, 1e-9, "melee: a spell has no swing");
    // The Plate reading adds to the swing: a strike beside a Plate ingot.
    economy::PlayerEconomy p(t);
    p.foundryEvent("first_kill:stone_husk");
    check(p.foundryPlaceSkill(1, 1, "prototype_heavy_strike") && p.foundryPlace(1, 0, "plate"), "melee: the strike laid with a Plate beside it");
    checkNear(grammar::skillCastArmour(t, grammar::foundryMods(t, p.foundry(), p.currentEra()), "prototype_heavy_strike"), 12.0 + 4.0, 1e-9,
              "melee: the reading's four on top of the swing's twelve");
    // A gear or plate modifier can grow the stagger and the push through the resolver.
    grammar::ActiveMods heavy;
    heavy.push_back(grammar::ActiveMod{"test", {"attack"}, "add_push", 1.0, "test"});
    heavy.push_back(grammar::ActiveMod{"test2", {"attack"}, "add_stagger", 0.2, "test"});
    checkNear(grammar::skillPush(t, heavy, "prototype_heavy_strike", false), 1.5, 1e-9, "melee: a push modifier adds to the blow");
    checkNear(grammar::skillStagger(t, heavy, "prototype_rend", false), 0.5, 1e-9, "melee: a stagger modifier adds to the cut");
}

// The world made whole (owner, 4 Sep 2026): the slices that slow the game
// through the world rather than the numbers. Slice 1: trees fall as one,
// boulders crack chunk by chunk.
void testWorldMadeWhole(const tuning::Tuning& t) {
    const auto& tree = t.worldgen.nodeTypes.at("tree");
    const auto& boulder = t.worldgen.nodeTypes.at("boulder");
    check(tree.units == 14 && tree.unitsPerHarvest == 14 && tree.drivePresses == 6 && tree.toolItem.empty(),
          "whole: a tree is six presses and fourteen wood at once, no tool");
    check(boulder.units == 9 && boulder.unitsPerHarvest == 3 && boulder.drivePresses == 3, "whole: a boulder is three chunks of three, three presses each");
    check(t.worldgen.nodeTypes.at("iron_vein").drivePresses == 0 && t.worldgen.nodeTypes.at("stone_seam").drivePresses == 4,
          "whole: a vein is still hands' work per press; the seam keeps its wedge and four presses");
    for (const auto& biome : t.worldgen.biomes)
        if (biome.id == "meadow")
            check(biome.nodeDensity.at("tree") < 0.01 && biome.nodeDensity.at("tree") > 0.0, "whole: the meadow's trees are sparser, and bigger");
    // Slice 2: iron is a walk - none guaranteed near, three within the far ring.
    const auto& g = t.worldgen.guarantees;
    check(!g.minNodesNear.count("iron_vein") && g.farRadiusM > g.nearRadiusM && g.minNodesFar.at("iron_vein") == 3,
          "whole: iron leaves the near guarantee for a ring of ninety metres");
    // Cave veins under the meadow still count as near (iron runs richer
    // underground, the reason to go down); what the surface no longer
    // promises is a vein at the door.
    int farOk = 0;
    for (uint64_t seed = 1; seed <= 12; ++seed) {
        auto map = worldgen::generate(t, seed);
        if (map.countNodesNear("iron_vein", map.spawnX, map.spawnZ, g.farRadiusM) >= 3) ++farOk;
    }
    check(farOk == 12, "whole: every seed has its three veins within the walk");
    // Slice 4: the rim - the land climbs toward every edge, ridged, never a wall.
    const auto& mtn = t.worldgen.mountains;
    check(mtn.rimWidthCells > 0 && mtn.rimExtraScale > 0, "whole: the rim is tuned");
    {
        auto map = worldgen::generate(t, 3);
        double rimSum = 0.0, midSum = 0.0;
        int rimN = 0, midN = 0;
        int rimMax = 0, rimMin = 999;
        for (int z = 0; z < map.height; ++z)
            for (int x = 0; x < map.width; ++x) {
                const int edge = std::min({x, z, map.width - 1 - x, map.height - 1 - z});
                const int h = map.at(x, z).height;
                if (edge < 6) { rimSum += h; ++rimN; rimMax = std::max(rimMax, h); rimMin = std::min(rimMin, h); }
                else if (edge > mtn.rimWidthCells + 20 && edge < mtn.rimWidthCells + 60) { midSum += h; ++midN; }
            }
        check(rimN > 0 && midN > 0 && rimSum / rimN > midSum / midN + 6.0, "whole: the outer band stands well above the country inside the rim");
        check(rimMax - rimMin >= 4, "whole: the rim is ridged, not a wall");
        check(map.at(map.spawnX, map.spawnZ).height < 30, "whole: the spawn clearing is not on the rim");
    }
}

void testDayAndNight(const tuning::Tuning& t) {
    // Wave 6 slice 5 (the owner, 4 Sep 2026: "imperative there is almost
    // like a forced - go back and continue your shelter, and get lost in
    // that for a bit"): the world keeps a clock; the night is dark, cold out
    // in the open and wider awake, and a shelter mends you faster through it.
    const auto& d = t.world.day;
    check(d.lengthSeconds >= 600.0 && d.lengthSeconds <= 900.0, "day: a day is ten to fifteen minutes");
    check(d.dawnEnd < d.dayEnd && d.dayEnd < d.duskEnd && d.duskEnd < 1.0, "day: dawn, day, dusk and night in order");
    check(1.0 - d.duskEnd >= 0.3, "day: the night is at least three tenths of the day - long enough to build through");
    check(d.startFraction >= d.dawnEnd && d.startFraction < d.dayEnd * 0.5, "day: a new game starts early in the day, the first day the longest");
    check(d.exposureLifePerRound == 0.0,
          "day: owner disabled nighttime exposure for now");
    check(d.nightAggroMultiplier > 1.0 && d.nightSleepRangeMultiplier > 1.0 && d.shelterNightRegenMultiplier > 1.0,
          "day: the night is wider awake and the shelter mends faster through it");

    auto at = [&](double fraction, int day) { return daycycle::info(d, (fraction - d.startFraction + day) * d.lengthSeconds); };
    const auto start = daycycle::info(d, 0.0);
    check(start.index == 1 && start.phase == "day" && start.daylight == 1.0 && !start.night, "day: a new game starts in the morning of day one");
    check(std::abs(start.fraction - d.startFraction) < 1e-9, "day: start_fraction into day one");
    const auto dawnMid = at(d.dawnEnd * 0.5, 1);
    const auto duskMid = at((d.dayEnd + d.duskEnd) * 0.5, 0);
    const auto nightMid = at((d.duskEnd + 1.0) * 0.5, 0);
    check(dawnMid.phase == "dawn" && duskMid.phase == "dusk" && nightMid.phase == "night", "day: the phases fall where the fractions say");
    check(dawnMid.daylight > d.nightLight && dawnMid.daylight < 1.0 && duskMid.daylight > d.nightLight && duskMid.daylight < 1.0,
          "day: dawn and dusk sit between night and day");
    check(nightMid.night && std::abs(nightMid.daylight - d.nightLight) < 1e-9, "day: the dead of night keeps night_light");
    check(!duskMid.night && duskMid.secondsToNight > 0.0 && duskMid.secondsToNight < (d.duskEnd - d.dayEnd) * d.lengthSeconds,
          "day: dusk is the warning, not the night, and counts down to it");
    checkNear(nightMid.secondsToDawn, (1.0 - (d.duskEnd + 1.0) * 0.5) * d.lengthSeconds, 1e-6, "day: the night counts down to dawn");
    check(at(0.2, 1).index == 2 && at(0.2, 1).phase == "day", "day: a day later is day two");
    bool monotone = true;
    for (int i = 1; i <= 20; ++i) {
        const double a = d.dayEnd + (d.duskEnd - d.dayEnd) * (i - 1) / 20.0;
        const double b = d.dayEnd + (d.duskEnd - d.dayEnd) * i / 20.0;
        if (at(b, 0).daylight > at(a, 0).daylight + 1e-9) monotone = false;
        const double c = d.dawnEnd * (i - 1) / 20.0;
        const double e = d.dawnEnd * i / 20.0;
        if (at(e, 1).daylight < at(c, 1).daylight - 1e-9) monotone = false;
    }
    check(monotone, "day: dusk only darkens, dawn only brightens");
    // Exposure: the cold takes life at its rate and stops at the floor.
    const double round = t.realtime.roundSeconds;
    checkNear(daycycle::exposed(d, round, 100.0, 100.0, 1e6), 100.0, 1e-9, "day: disabled exposure preserves full life through a whole night");
    checkNear(daycycle::exposed(d, round, 60.0, 100.0, 1e6), 60.0, 1e-9, "day: disabled exposure preserves injured life through a whole night");
    checkNear(daycycle::exposed(d, round, 10.0, 100.0, 60.0), 10.0, 1e-9, "day: life already under the floor is left alone - the cold never kills");
    // Preserve the optional mechanic's floor/rate contract in an explicit fixture.
    auto enabled = d;
    enabled.exposureLifePerRound = 0.4;
    checkNear(daycycle::exposed(enabled, round, 100.0, 100.0, 10.0), 100.0 - 4.0 / round, 1e-9, "day: explicitly enabled exposure follows its configured rate");
    checkNear(daycycle::exposed(enabled, round, 100.0, 100.0, 1e6), enabled.exposureFloorFraction * 100.0, 1e-9, "day: explicitly enabled exposure still stops at its floor");
    // The clock is the economy's, only runs forward, and survives a save.
    economy::PlayerEconomy player(t);
    player.advanceTime(100.0);
    player.advanceTime(-5.0);
    check(std::abs(player.dayClock() - 100.0) < 1e-9, "day: the clock only runs forward");
    save::SaveGame game;
    game.economy = player.exportState();
    save::SaveGame loaded = save::fromJson(save::toJson(game));
    economy::PlayerEconomy restored(t);
    restored.importState(loaded.economy);
    check(std::abs(restored.dayClock() - 100.0) < 1e-9, "day: the clock round-trips through a save");
    tuning::DayDef none;
    check(daycycle::info(none, 5000.0).phase == "day" && daycycle::info(none, 5000.0).daylight == 1.0, "day: no day rules means endless day");
}

void testHauling(const tuning::Tuning& t) {
    // Wave 6 slice 6 (the owner, 4 Sep 2026: "would definitely need
    // chests/storage solutions"): the pack takes from the ground up to a
    // cap per family; a chest holds a bounded store; forged goods and gear
    // are never capped.
    const auto& h = t.world.hauling;
    check(h.carryCapDefault > 0 && h.chestUnits > 0, "haul: a cap and a chest size are tuned");
    check(h.carryCap.count("wood") && h.carryCap.at("wood") >= 40 && h.carryCap.count("iron_ore") &&
              h.carryCap.at("iron_ore") < h.carryCap.at("wood"),
          "haul: timber carries further than iron");
    const auto* chest = t.construction.findShape("chest");
    check(chest != nullptr && chest->form == "chest" && chest->element == "block" && chest->materialCost >= 4 &&
              std::find(chest->requiresTraits.begin(), chest->requiresTraits.end(), "joinery") != chest->requiresTraits.end(),
          "haul: the chest is a jointed block piece with a form of its own");
    economy::PlayerEconomy player(t);
    const int woodCap = player.carryCap("wood");
    check(woodCap == h.carryCap.at("wood") && player.carryCap("copper_ore") == h.carryCap.at("copper_ore"), "haul: caps read per family");
    check(player.carryCap("preserving_catalyst") == h.carryCapDefault, "haul: an unlisted material takes the default cap");
    check(player.carryCap("iron_chest_armour") == 0 && player.carryRoom("iron_chest_armour") > 1000000, "haul: gear is never capped");
    check(player.haul("wood", 25) == 25 && player.inventory["wood"] == 25, "haul: the pack takes what it has room for");
    check(player.haul("wood", woodCap) == woodCap - 25 && player.inventory["wood"] == woodCap, "haul: and no more than the cap");
    check(player.haul("wood", 3) == 0 && player.carryRoom("wood") == 0, "haul: a full family takes nothing");
    player.inventory["wood"] = woodCap + 10; // a recovered pack may sit over the cap
    check(player.carryRoom("wood") == 0 && player.haul("wood", 1) == 0, "haul: over the cap the room is nought, not negative");
    player.inventory["wood"] = woodCap;
    // The chest.
    const std::string key = "block:0:3,4,5";
    check(player.storeRoom(key) == h.chestUnits && player.storeContents(key).empty(), "haul: an untouched chest is empty with its whole room");
    check(player.storeDeposit(key, "wood", 20) == 20 && player.inventory["wood"] == woodCap - 20 && player.storeContents(key).at("wood") == 20,
          "haul: a deposit moves timber from the pack to the chest");
    check(player.storeDeposit(key, "wood", 999) == woodCap - 20 && player.inventory.count("wood") == 0, "haul: a deposit stops at what you hold");
    check(player.storeDeposit(key, "iron_ore", 5) == 0, "haul: nothing to deposit, nothing moves");
    const int room = player.storeRoom(key);
    player.inventory["fieldstone"] = 1000;
    check(player.storeDeposit(key, "fieldstone", 1000) == room && player.storeRoom(key) == 0 && player.storeUnits(key) == h.chestUnits,
          "haul: a chest fills to chest_units, all families together");
    player.inventory["iron_ore"] = 5;
    check(player.storeDeposit(key, "iron_ore", 5) == 0, "haul: a full chest takes nothing");
    check(player.storeWithdraw(key, "wood", 10) == 10 && player.inventory["wood"] == 10 && player.storeContents(key).at("wood") == woodCap - 10,
          "haul: a withdrawal moves back to the pack");
    player.inventory["wood"] = woodCap - 3;
    check(player.storeWithdraw(key, "wood", 50) == 3 && player.inventory["wood"] == woodCap, "haul: a withdrawal stops at the pack's room");
    check(player.storeWithdraw(key, "silver_ore", 5) == 0 && player.storeWithdraw("no-such-chest", "wood", 1) == 0,
          "haul: nothing there, nothing moves");
    // The save carries the stores.
    save::SaveGame game;
    game.economy = player.exportState();
    save::SaveGame loaded = save::fromJson(save::toJson(game));
    economy::PlayerEconomy restored(t);
    restored.importState(loaded.economy);
    check(restored.storeContents(key) == player.storeContents(key) && restored.storeUnits(key) == player.storeUnits(key),
          "haul: the chest's contents round-trip through a save");
    // Breaking the chest hands back everything it held.
    const int units = player.storeUnits(key);
    const auto spilled = player.storeRemove(key);
    int spilledUnits = 0;
    for (const auto& [family, count] : spilled) spilledUnits += count;
    check(spilledUnits == units && units > 0 && player.storeContents(key).empty() && player.stores().count(key) == 0,
          "haul: a broken chest spills all it held and is gone");
    check(player.storeRemove(key).empty(), "haul: removing nothing spills nothing");
}

void testDensityAndFear(const tuning::Tuning& t) {
    // Wave 7 slice 1 (the owner, 4 Sep 2026: "the problem is navigating
    // where those improvements are seen/felt" - density by ring made here
    // and there the same): density is the biome's, the deep biomes patrol
    // toward the heartland at night, and noise carries.
    const auto& g = t.worldgen.guarantees;
    check(g.patrolLengthM >= 40.0 && g.patrolLengthM <= 120.0, "fear: a patrol is a real walk, not a stroll");
    bool fenPatrols = false, meadowPatrols = false;
    for (const auto& b : t.worldgen.biomes) {
        if (b.id == "fen" || b.id == "ember_wastes") fenPatrols = fenPatrols || b.patrols;
        if (b.id == "meadow") meadowPatrols = b.patrols;
    }
    check(fenPatrols && !meadowPatrols, "fear: the deep biomes patrol, the meadow does not");
    auto map = worldgen::generate(t, 7);
    std::map<std::string, int> cellsByBiome, packsByBiome;
    for (const auto& cell : map.cells) ++cellsByBiome[t.worldgen.biomes[static_cast<size_t>(cell.biomeIndex)].id];
    int patrolPacks = 0, routeBad = 0, cavePatrols = 0, unnamed = 0;
    const double packSafe = g.packMinDistanceFromSpawnM;
    for (const auto& pack : map.packs) {
        if (pack.grazer) continue;
        if (pack.biome.empty()) ++unnamed;
        ++packsByBiome[pack.biome];
        if (pack.biome == "cave" && pack.patrols) ++cavePatrols;
        if (!pack.patrols) continue;
        ++patrolPacks;
        const double denToSpawn = std::hypot(double(pack.x - map.spawnX), double(pack.z - map.spawnZ));
        const double routeToSpawn = std::hypot(double(pack.routeX - map.spawnX), double(pack.routeZ - map.spawnZ));
        const double walk = std::hypot(double(pack.routeX - pack.x), double(pack.routeZ - pack.z));
        if (walk > g.patrolLengthM + 1.5 || walk < 4.0 || routeToSpawn >= denToSpawn || routeToSpawn < packSafe - 0.5 ||
            pack.routeX < 0 || pack.routeZ < 0 || pack.routeX >= map.width || pack.routeZ >= map.height)
            ++routeBad;
    }
    check(unnamed == 0, "fear: every hostile pack knows the biome it dens in");
    check(cavePatrols == 0, "fear: cave packs keep to the dark");
    check(patrolPacks > 5 && routeBad == 0,
          "fear: every patrol walks toward the heartland, no further than its length, never onto the doorstep (" +
              std::to_string(patrolPacks) + " patrols)");
    auto perCell = [&](const std::string& id) {
        return cellsByBiome[id] > 0 ? double(packsByBiome[id]) / cellsByBiome[id] : 0.0;
    };
    check(cellsByBiome["meadow"] > 0 && cellsByBiome["fen"] > 0 && perCell("meadow") * 4.0 < perCell("fen") &&
              perCell("meadow") * 4.0 < perCell("ember_wastes"),
          "fear: on the ground the fen and the wastes are many times the meadow's density");
    // Noise: the rules carry, and a felled tree is heard further than a press.
    const auto& n = t.realtime.noiseRadiusM;
    check(n.count("work") && n.count("tree_fall") && n.count("rock_crack") && n.count("fight") && n.count("strike") && n.count("horn"),
          "fear: every noise the world makes has a radius");
    check(n.at("tree_fall") > n.at("work") && n.at("rock_crack") > n.at("work") && n.at("horn") > n.at("tree_fall") &&
              t.realtime.noiseMuffle > 0.0 && t.realtime.noiseMuffle < 0.5,
          "fear: a falling tree carries further than a press, the horn furthest, and walls keep most of it in");
}

void testWorldABeatAhead(const tuning::Tuning& t) {
    // Wave 7 slice 2 (the owner, 4 Sep 2026: "it's so easy to get to a
    // level 2 forge with crafting items good enough to feel this power"):
    // every spike is fetched from the next denser place, early hits are
    // deadlier, armour has the era's ceiling, and a pack's bites stack.
    const auto* improved = t.crafting.findStation("forge_improved");
    check(improved != nullptr && improved->upgradeCost.count("bog_iron") && improved->upgradeCost.at("bog_iron") > 0,
          "ahead: the second forge wants bog iron");
    bool fenDrops = false, elsewhere = false;
    for (const auto& e : t.world.enemies)
        for (const auto& entry : e.loot)
            if (entry.kind == "item" && entry.item == "bog_iron") {
                if (e.id == "bog_lurker" || e.id == "marsh_wisp") fenDrops = true;
                else elsewhere = true;
            }
    check(fenDrops && !elsewhere, "ahead: only the fen drops bog iron");
    // Catalysts ride on the crowned.
    for (const auto& m : t.world.eliteModifiers) check(!m.bounty.empty(), "ahead: every elite carries a bounty (" + m.id + ")");
    int bountyPaid = 0, plainPaid = 0;
    for (uint64_t seed = 1; seed <= 40; ++seed) {
        auto crowned = loot::rollEnemyLoot(t.world, "ash_hound", seed, &t.world.eliteModifiers.front());
        if (crowned.count("ember_catalyst") || crowned.count("preserving_catalyst")) ++bountyPaid;
        auto plain = loot::rollEnemyLoot(t.world, "ash_hound", seed);
        if (plain.count("ember_catalyst") || plain.count("preserving_catalyst")) ++plainPaid;
    }
    check(bountyPaid >= 24 && plainPaid == 0,
          "ahead: a crowned hound pays a catalyst most kills (" + std::to_string(bountyPaid) + "/40), a plain one never");
    // The heartland's mobs hit harder.
    check(t.world.findEnemy("ember_whelp")->damage >= 6.0 && t.world.findEnemy("ash_hound")->damage >= 4.0 &&
              t.world.findEnemy("stone_husk")->damage >= 8.0,
          "ahead: the heartland's mobs hit harder - fewer, deadlier");
    // The era's ceiling on armour.
    const auto& eras = t.eras.eras;
    check(eras.size() >= 3 && eras[0].armourReductionCap <= 0.3 && eras[1].armourReductionCap > eras[0].armourReductionCap &&
              eras[2].armourReductionCap > eras[1].armourReductionCap,
          "ahead: armour's ceiling rises with the eras");
    stats::Equipment heavy;
    items::ItemInstance plate;
    plate.baseId = "iron_chest_armour";
    plate.implicitProperties["armour"] = 100.0;
    heavy.slots["chest"] = plate;
    auto derived = stats::deriveStats(t.world.playerBase, heavy);
    auto capped = t.world.playerBase;
    capped.armourReductionCap = eras[0].armourReductionCap;
    checkNear(stats::mitigateDamage(10.0, "physical", derived, capped), 10.0 * (1.0 - eras[0].armourReductionCap), 1e-9,
              "ahead: in the valley armour takes no more than its ceiling, however much you wear");
    checkNear(stats::mitigateDamage(10.0, "physical", derived, t.world.playerBase), 5.0, 1e-9,
              "ahead: with no ceiling the formula stands");
    // The train.
    const auto& rt = t.realtime;
    check(rt.hordeTrainWindowSeconds > 0.0 && rt.hordeTrainBonusPerHit > 0.0 && rt.hordeTrainMaxBonus >= rt.hordeTrainBonusPerHit,
          "ahead: the train is tuned");
    checkNear(combat::trainMultiplier(0, rt), 1.0, 1e-9, "ahead: a lone bite is a bite");
    checkNear(combat::trainMultiplier(1, rt), 1.0 + rt.hordeTrainBonusPerHit, 1e-9, "ahead: a second mouth adds its bonus");
    checkNear(combat::trainMultiplier(50, rt), 1.0 + rt.hordeTrainMaxBonus, 1e-9, "ahead: and the train caps");
}

void testHornAndSiege(const tuning::Tuning& t) {
    // Wave 7 slice 3: the shrieker's horn is density on the player's terms;
    // the siege is the night testing the house.
    bool hornDrops = false;
    for (const auto& entry : t.world.findEnemy("shrieker")->loot)
        if (entry.kind == "item" && entry.item == "shrieker_horn" && entry.chance >= 0.4) hornDrops = true;
    check(hornDrops, "horn: a shrieker's kill may leave its horn");
    check(t.world.hauling.carryCap.count("shrieker_horn") && t.world.hauling.carryCap.at("shrieker_horn") == 1,
          "horn: the pack carries one horn");
    check(t.realtime.noiseHornCooldownSeconds >= 30.0 && t.realtime.noiseRadiusM.at("horn") >= 60.0,
          "horn: it carries far and rings a while between blows");
    const auto& s = t.world.siege;
    check(s.firstNight >= 2 && s.chancePerNight > 0.0 && s.chancePerNight < 1.0 && s.arriveSecondsIntoNight > 0.0 &&
              s.spawnRadiusM > 10.0 && s.homeRadiusM > s.spawnRadiusM && s.timberBreakHits >= 6,
          "siege: tuned - never the first night, a chance each night after, arriving once the night is old");
    check(!daycycle::siegeTonight(s, 7, 1) && !daycycle::siegeTonight(s, 99, s.firstNight - 1),
          "siege: never before the first night");
    int nights = 0;
    bool same = true;
    for (int day = s.firstNight; day < s.firstNight + 200; ++day) {
        if (daycycle::siegeTonight(s, 7, day)) ++nights;
        if (daycycle::siegeTonight(s, 7, day) != daycycle::siegeTonight(s, 7, day)) same = false;
    }
    check(same && nights > 60 && nights < 140, "siege: rolled per night from the seed, about the tuned chance (" + std::to_string(nights) + "/200)");
    int differ = 0;
    for (int day = s.firstNight; day < s.firstNight + 50; ++day)
        if (daycycle::siegeTonight(s, 7, day) != daycycle::siegeTonight(s, 8, day)) ++differ;
    check(differ > 5, "siege: another world has other nights");
    check(daycycle::siegePack(s, 1).size() == 2 && daycycle::siegePack(s, 2).size() >= 3 &&
              std::find(daycycle::siegePack(s, 2).begin(), daycycle::siegePack(s, 2).end(), "stone_husk") != daycycle::siegePack(s, 2).end() &&
              daycycle::siegePack(s, 9).size() >= daycycle::siegePack(s, 3).size() && daycycle::siegePack(s, 0).empty(),
          "siege: the pack grows with the era - hounds in the valley, a husk once the deep wakes");
    check(t.eras.eras[0].mechanic("stone_husk", "breaks_timber") == nullptr && t.eras.eras[1].mechanic("stone_husk", "breaks_timber") != nullptr,
          "siege: timber holds in the valley; the deep's husks break it");
}

void testVerbs(const tuning::Tuning& t) {
    // Wave 8 slice 1 (the owner, 4 Sep 2026: Hades-style - "this mob is
    // different enough in mechanics" - and "danger levels get the same
    // feel"): one verb per family, and every family in one threat band.
    const auto& rt = t.realtime;
    auto verb = [&](const std::string& behaviour) { const auto* b = rt.findBehaviour(behaviour); return b ? b->verb : std::string("missing"); };
    check(verb("fast") == "harry" && verb("guard") == "guard" && verb("ranged") == "mark" && verb("lurker") == "root" &&
              verb("skirmisher") == "kindle" && verb("swarm") == "swarm" && verb("knight") == "ward" && verb("shrieker") == "recruit" &&
              verb("melee").empty() && verb("grazer").empty(),
          "verbs: one verb per behaviour, the whelp the baseline, the elk none");
    check(t.world.findEnemy("stone_husk")->behaviour == "guard" && t.world.findEnemy("gloom_crawler")->behaviour == "swarm",
          "verbs: the husk guards, the crawler swarms");
    const auto* harry = rt.findBehaviour("fast");
    const auto* guard = rt.findBehaviour("guard");
    const auto* mark = rt.findBehaviour("ranged");
    const auto* root = rt.findBehaviour("lurker");
    const auto* kindle = rt.findBehaviour("skirmisher");
    const auto* swarm = rt.findBehaviour("swarm");
    const auto* ward = rt.findBehaviour("knight");
    check(harry->verbSeconds > 0.0 && harry->verbStrength > 0.0 && harry->verbStrength <= 0.6, "verbs: the harry is a slow you feel, not a stop");
    check(guard->verbStrength >= 0.3 && guard->verbStrength <= 0.8 && guard->verbArcDegrees >= 60.0 && guard->verbArcDegrees <= 180.0,
          "verbs: the guard covers a front, not the whole mob");
    check(mark->verbSeconds > 0.0 && mark->verbStrength > 1.0, "verbs: a mark makes the hunters faster, for a while");
    check(root->verbSeconds >= 0.6 && root->verbSeconds <= 2.0, "verbs: a root is a moment, not a cage");
    check(kindle->verbSeconds > 0.0 && kindle->verbRadiusM > 0.0 && kindle->verbStrength > 0.0, "verbs: the kindle has a period, a reach and a bonus");
    check(swarm->verbRadiusM > 0.0 && swarm->verbStrength > 0.0 && swarm->verbCap >= swarm->verbStrength, "verbs: the swarm adds per ally, to a cap");
    check(ward->verbRadiusM > 0.0 && ward->verbStrength > 0.0 && ward->verbStrength <= 0.5, "verbs: the ward shields, it does not make allies immune");
    // The band: every hostile family's threat within [0.55, 1.6] of the
    // median, the shrieker aside - its threat is who it invites.
    std::vector<double> scores;
    std::map<std::string, double> byFamily;
    for (const auto& e : t.world.enemies) {
        const auto* b = rt.findBehaviour(e.behaviour);
        if (!b || b->flees || b->verb == "recruit") continue;
        const double s = combat::threatScore(e, *b);
        byFamily[e.id] = s;
        scores.push_back(s);
    }
    std::sort(scores.begin(), scores.end());
    const double median = scores[scores.size() / 2];
    std::string outside;
    for (const auto& [id, s] : byFamily)
        if (s < 0.55 * median || s > 1.6 * median) outside += id + " ";
    check(scores.size() >= 8 && outside.empty(), "verbs: every family sits in the threat band (outside: " + outside + ")");
    check(byFamily["bog_lurker"] < byFamily["ash_hound"] * 1.6 && byFamily["hollow_knight"] < byFamily["ember_whelp"] * 1.6,
          "verbs: the slow heavy hitters are no tier above the fast biters");
    // Packs by biome: the fen's packs are no tier above the forest's; the
    // biomes' mean pack threat stays in one band (the meadow's straggler aside).
    std::map<std::string, double> meanByBiome;
    for (const auto& b : t.worldgen.biomes) {
        if (b.packs.empty() || b.id == "meadow") continue;
        double sum = 0.0;
        for (const auto& pack : b.packs) sum += combat::packThreat(t.world, rt, pack);
        meanByBiome[b.id] = sum / static_cast<double>(b.packs.size());
    }
    double overall = 0.0;
    for (const auto& [id, m] : meanByBiome) overall += m;
    overall /= static_cast<double>(std::max<size_t>(1, meanByBiome.size()));
    std::string offBand;
    for (const auto& [id, m] : meanByBiome)
        if (m < 0.7 * overall || m > 1.45 * overall) offBand += id + " ";
    check(meanByBiome.size() >= 4 && offBand.empty(), "verbs: every biome's packs sit in one band (off: " + offBand + ")");
    check(meanByBiome["fen"] <= meanByBiome["forest"] * 1.15, "verbs: the fen is a different shape, not a tier above the forest");
}

void testCurioAndLock(const tuning::Tuning& t) {
    // Wave 8 slice 2 (the owner, 4 Sep 2026): the trial is the test that
    // sends you out; its curio is the key; a landmark in another biome is
    // the lock; and the biome you cross is where its timber is.
    const auto& trial = t.trial;
    check(trial.completionCurio == "tyrant_heart" && trial.curios.size() >= 2 && trial.findCurio("warden_eye") != nullptr,
          "lock: the Tyrant leaves its heart, the Warden its eye");
    for (const auto& curio : trial.curios) {
        bool landmarkExists = false;
        std::string biome;
        for (const auto& def : t.worldgen.landmarks)
            if (def.id == curio.landmark) { landmarkExists = true; biome = def.biome; }
        check(landmarkExists && !curio.unlock.empty() && !curio.reading.empty(), "lock: " + curio.id + " names a landmark, an unlock and a reading");
        check(biome != t.worldgen.guarantees.gateBiome || curio.id != "tyrant_heart", "lock: the heart's lock is not in the gate's biome");
    }
    check(trial.curioForLandmark("hill_cairn") && trial.curioForLandmark("hill_cairn")->unlock == t.eras.eras[1].triggerWorldEffect &&
              trial.curioForLandmark("drowned_altar") && trial.curioForLandmark("drowned_altar")->unlock == t.eras.eras[2].triggerWorldEffect &&
              trial.curioForLandmark("wastes_rift") == nullptr,
          "lock: the cairn turns era two, the altar era three, the rift waits");
    // Landmarks on the ground: every def placed, in its biome, far enough
    // out, on the surface, off the nodes; the same twice.
    auto map = worldgen::generate(t, 7);
    auto again = worldgen::generate(t, 7);
    check(map.landmarks.size() == t.worldgen.landmarks.size() && again.landmarks.size() == map.landmarks.size(),
          "lock: every landmark stands (" + std::to_string(map.landmarks.size()) + ")");
    for (const auto& placed : map.landmarks) {
        const tuning::LandmarkDef* def = nullptr;
        for (const auto& d : t.worldgen.landmarks)
            if (d.id == placed.id) def = &d;
        bool same = false;
        for (const auto& other : again.landmarks) same = same || (other.id == placed.id && other.x == placed.x && other.z == placed.z);
        bool onNode = false;
        for (const auto& node : map.nodes) onNode = onNode || (node.x == placed.x && node.z == placed.z);
        const double d = std::hypot(double(placed.x - map.spawnX), double(placed.z - map.spawnZ));
        check(def && t.worldgen.biomes[static_cast<size_t>(map.at(placed.x, placed.z).biomeIndex)].id == def->biome &&
                  d >= def->minDistanceFromSpawnM - 0.5 && map.topSolid(placed.x, placed.z) == map.at(placed.x, placed.z).height && !onNode && same,
              "lock: " + placed.id + " stands in its biome, far enough out, on the surface, off the nodes, the same twice");
    }
    // The key and the lock through the economy.
    economy::PlayerEconomy player(t);
    check(!player.setCurio("hill_cairn") && player.currentEra() == 1, "lock: nothing to set, nothing turns");
    player.grant("tyrant_heart", 1);
    check(player.curioHints().size() == 1 && player.curioHints().front().find("cairn") != std::string::npos, "lock: the heart's reading names the cairn");
    check(!player.setCurio("drowned_altar") && player.setCurio("hill_cairn") && player.currentEra() == 2 && !player.curioHeld("tyrant_heart"),
          "lock: the cairn takes the heart and the deep wakes");
    player.grant("warden_eye", 1);
    check(player.setCurio("drowned_altar") && player.currentEra() == 3, "lock: the altar takes the eye and the tide rises");
    // Trial one is the test that sends you out: the starting kit fails the
    // Tyrant most times, the second forge's tempered armour passes it.
    stats::Equipment bare;
    auto bareStats = stats::deriveStats(t.world.playerBase, bare);
    stats::Equipment geared;
    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    armour.implicitProperties["armour"] = 20.0;
    const auto* process = t.crafting.findCatalystProcess("ember_catalyst_tempering");
    check(process && items::catalystTemper(t.items, *process, armour, 5, 77).applied, "lock: the tempered armour of the second forge");
    geared.slots["chest"] = armour;
    auto gearedStats = stats::deriveStats(t.world.playerBase, geared);
    combat::CombatMods none;
    int bareWins = 0, gearedWins = 0;
    for (uint64_t seed = 1; seed <= 12; ++seed) {
        if (combat::runEncounter(t, bareStats, none, {"forge_tyrant"}, seed, combat::autoPolicy).victory) ++bareWins;
        if (combat::runEncounter(t, gearedStats, none, {"forge_tyrant"}, seed, combat::autoPolicy).victory) ++gearedWins;
    }
    check(bareWins <= 3, "lock: the starting kit fails the Tyrant most times (" + std::to_string(bareWins) + "/12)");
    check(gearedWins >= 9, "lock: the second forge's tempered armour passes it (" + std::to_string(gearedWins) + "/12)");
    // Biomes as material: the forest's pine, the fen's bog oak, the wastes' snag.
    check(t.worldgen.nodeTypes.count("pine") && t.worldgen.nodeTypes.at("pine").materialFamily == "pine" &&
              t.worldgen.nodeTypes.at("bog_oak").materialFamily == "bog_oak" && t.worldgen.nodeTypes.at("ash_snag").materialFamily == "ash_wood" &&
              t.worldgen.nodeTypes.at("pine").drivePresses == 6,
          "timber: three biome trees, felled like any tree, paying their own timber");
    std::map<std::string, const tuning::BiomeDef*> biomes;
    for (const auto& b : t.worldgen.biomes) biomes[b.id] = &b;
    check(biomes["forest"]->nodeDensity.count("pine") && !biomes["forest"]->nodeDensity.count("tree") &&
              biomes["fen"]->nodeDensity.count("bog_oak") && biomes["ember_wastes"]->nodeDensity.count("ash_snag") &&
              biomes["meadow"]->nodeDensity.count("tree"),
          "timber: each biome grows its own, the meadow the plain tree");
    for (const std::string family : {"pine", "bog_oak", "ash_wood"}) {
        const auto* material = t.construction.findMaterial(family);
        check(material && material->hasTrait("timber") && material->hasTrait("joinery") && !material->tint.empty(),
              "timber: " + family + " builds like timber in its own colour");
        check(t.world.hauling.carryCap.count(family) && t.world.hauling.carryCap.at(family) == t.world.hauling.carryCap.at("wood"),
              "timber: " + family + " hauls like timber");
    }
    int pines = 0;
    for (const auto& node : map.nodes)
        if (node.type == "pine") ++pines;
    check(pines > 20, "timber: the forest stands in pines (" + std::to_string(pines) + ")");
}

void testMingling(const tuning::Tuning& t) {
    // Wave 8 slice 3 (the owner, 4 Sep 2026): on the turn the world changes
    // shape - foreign families join each biome's packs, the night's patrols
    // cross into other biomes, and the verbs transform.
    const auto& eras = t.eras.eras;
    check(eras.size() >= 3 && eras[0].mingle.empty() && !eras[0].patrolsCrossBiomes, "mingle: the valley keeps its families to their biomes");
    for (size_t i = 1; i < eras.size(); ++i) {
        const auto& era = eras[i];
        check(!era.mingle.empty() && era.mingleChance > 0.0 && era.mingleChance <= 1.0 && era.patrolsCrossBiomes,
              "mingle: " + era.id + " mingles, at a chance, and its patrols cross");
        for (const auto& [biome, list] : era.mingle) {
            bool biomeExists = false;
            for (const auto& b : t.worldgen.biomes) biomeExists = biomeExists || b.id == biome;
            check(biomeExists && !list.empty(), "mingle: " + era.id + " names a real biome (" + biome + ")");
            for (const auto& id : list) check(t.world.findEnemy(id) != nullptr, "mingle: " + id + " is a real family");
        }
    }
    check(eras[2].mingle.size() > eras[1].mingle.size() && eras[2].mingleChance >= eras[1].mingleChance,
          "mingle: the tide mingles more than the deep");
    // The pick: deterministic, sometimes nothing, sometimes the family.
    int some = 0, none = 0;
    bool same = true;
    for (unsigned long long salt = 1; salt <= 40; ++salt) {
        const std::string a = eras[1].minglePick("meadow", salt);
        if (a.empty()) ++none;
        else ++some;
        if (a != eras[1].minglePick("meadow", salt)) same = false;
        if (!a.empty() && a != "ash_hound") same = false;
    }
    check(same && some >= 8 && none >= 8 && eras[0].minglePick("meadow", 3).empty() && eras[1].minglePick("nowhere", 3).empty(),
          "mingle: the deep sends hounds into some meadow packs, deterministically, and the valley none");
    // Foreign routes: most patrol packs know a den of another biome within reach.
    auto map = worldgen::generate(t, 7);
    int patrols = 0, foreign = 0, bad = 0;
    const double reach = t.worldgen.guarantees.patrolLengthM * 1.5;
    for (const auto& pack : map.packs) {
        if (!pack.patrols) continue;
        ++patrols;
        if (!pack.hasForeign) continue;
        ++foreign;
        const double d = std::hypot(double(pack.foreignX - pack.x), double(pack.foreignZ - pack.z));
        if (pack.foreignBiome == pack.biome || pack.foreignBiome == "cave" || pack.foreignBiome.empty() || d > reach + 0.5 || d <= 4.0) ++bad;
    }
    check(patrols > 5 && foreign * 2 >= patrols && bad == 0,
          "mingle: most patrols know a foreign den within reach, always another biome's (" + std::to_string(foreign) + "/" + std::to_string(patrols) + ")");
    // The verbs transform.
    check(eras[1].mechanic("stone_husk", "guard_arc_bonus") && eras[1].mechanic("stone_husk", "guard_arc_bonus")->at("value") > 0.0 &&
              eras[1].mechanic("marsh_wisp", "kindle_two") && eras[0].mechanic("stone_husk", "guard_arc_bonus") == nullptr,
          "mingle: the deep's husks guard wider and its wisps light two");
    check(eras[2].mechanic("bog_lurker", "root_bonus_seconds") && eras[2].mechanic("bog_lurker", "root_bonus_seconds")->at("value") > 0.0 &&
              eras[2].mechanic("hollow_knight", "ward_bonus") && eras[2].mechanic("hollow_knight", "ward_bonus")->at("value") > 0.0,
          "mingle: the tide's lurkers hold longer and its knights ward harder");
}

// Codex: partial-volume air must work in every orientation, while placement
// remains conservative and a real hole still defeats enclosure.
void testCornerEnclosure() {
    using namespace wroughtwild::lattice;
    for (int rotation = 0; rotation < 4; ++rotation) {
        Structure structure;
        for (int x=0; x<5; ++x) for (int y=0; y<5; ++y) for (int z=0; z<5; ++z) {
            if (x!=0 && x!=4 && y!=0 && y!=4 && z!=0 && z!=4) continue;
            Piece wall;
            wall.anchor = {ElementKind::Volume,0,{x,y,z}};
            wall.footprint = footprint(wall.anchor,1,1);
            structure.place(wall);
        }
        Piece corner;
        corner.anchor = {ElementKind::Volume,0,{1,1,1}};
        corner.footprint = withInterior(footprint(corner.anchor,2,1));
        corner.cornerSpan = 2;
        corner.rotationStep = rotation;
        check(structure.place(corner), "Codex corner: prism places inside the test room");
        const Vec3 air[] = {{2.8,1.5,1.2},{1.2,1.5,1.2},{1.2,1.5,2.8},{2.8,1.5,2.8}};
        const Vec3 free = air[rotation], solid = air[(rotation+2)%4];
        auto elementAt = [](const Vec3& v) { return Element{ElementKind::Volume,0,
            {int(std::floor(v.x)),int(std::floor(v.y)),int(std::floor(v.z))}}; };
        auto world = [](const Cell&) { return WorldCell::Sky; };
        check(structure.occupied(elementAt(free)), "Codex corner: empty half remains reserved for placement");
        check(enclosure(structure,elementAt(free),100,world,&free).enclosed,
              "Codex corner: empty half connects to shelter at rotation " + std::to_string(rotation));
        check(!enclosure(structure,elementAt(solid),100,world,&solid).enclosed,
              "Codex corner: solid half is not air at rotation " + std::to_string(rotation));
        const Vec3 partial[] = {{1.8,1.5,1.7},{1.8,1.5,2.1},{1.7,1.5,1.8},{2.1,1.5,1.95}};
        const Vec3 edgeAir = partial[rotation];
        check(enclosure(structure,elementAt(edgeAir),100,world,&edgeAir).enclosed,
              "Codex corner: a partly filled fine cell still shelters its air");
        structure.remove({ElementKind::Volume,0,{3,4,3}});
        check(!enclosure(structure,elementAt(free),100,world,&free).enclosed,
              "Codex corner: a roof hole remains a leak");
    }
}

void testLandformProfile(const tuning::Tuning& source) {
    auto t = source;
    t.worldgen.map.baseHeight = 7;
    t.worldgen.map.heightScale = 20;
    t.worldgen.map.heightFrequency = 0.025;
    t.worldgen.map.heightWarpMetres = 24;
    t.worldgen.map.heightWarpFrequency = 0.018;
    for (int seed : {1,7,29}) {
        auto map = worldgen::generate(t,seed);
        auto repeated = worldgen::generate(t,seed);
        auto original = worldgen::generate(source,seed);
        check(map.blocks == repeated.blocks, "Codex landform: repeated generation agrees");
        check(map.blocks != original.blocks, "Codex landform: opt-in profile changes relief");
        bool grounded = true;
        for (const auto& node : map.nodes)
            grounded = grounded && map.blockAt(node.x,node.y,node.z) == worldgen::kAir &&
                map.blockAt(node.x,node.y-1,node.z) != worldgen::kAir;
        check(grounded, "Codex landform: resources remain grounded on regenerated terrain");
        const auto& g = t.worldgen.guarantees;
        for (const auto& node : g.minNodesNear)
            check(map.countNodesNear(node.first,map.spawnX,map.spawnZ,g.nearRadiusM / map.cellSize) >= node.second,
                  "Codex landform: near resource guarantee survives: " + node.first);
        for (const auto& node : g.minNodesFar)
            check(map.countNodesNear(node.first,map.spawnX,map.spawnZ,g.farRadiusM / map.cellSize) >= node.second,
                  "Codex landform: distant resource guarantee survives: " + node.first);
        check(map.blockAt(map.gateX,map.topSolid(map.gateX,map.gateZ)-1,map.gateZ) != worldgen::kAir,
              "Codex landform: trial entrance has solid ground");
    }
}

int main(int argc, char** argv) {
    std::string tuningDir = argc > 1 ? argv[1] : "../../data/tuning";
    tuning::Tuning t;
    try {
        t = tuning::loadAll(tuningDir);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "FATAL: cannot load tuning from %s: %s\n", tuningDir.c_str(), e.what());
        return 2;
    }

    testTuningLoads(t);
    testSkillCurve(t);
    testCraftingGates(t);
    testRepetitionDecay(t);
    testOrderFulfilment(t);
    testSalvage(t);
    testItemRolls(t);
    testBoons(t);
    testVerticalSliceSpine(t);
    testStatsAndMitigation(t);
    testCatalystTemper(t);
    testStationConstruction(t);
    testShapePlacement(t);
    testOrderDemandAndStationChecks(t);
    testCombatNumbers(t);
    testCombat(t);
    testTrialContracts(t);
    testTrialRealtimeHost(t);
    testSaveLoad(t);
    testFuelGate(t);
    testHandCraftingAndKits(t);
    testEnemyLoot(t);
    testWorldgen(t);
    testGrammar(t);
    testItemisation(t);
    testStatusGrammar(t);
    testSkillLoadout(t);
    testMobGearAndPages(t);
    testElitesAndFamilies(t);
    testLattice(t);
    testCornerEnclosure();
    testLandformProfile(t);
    testEras(t);
    testFoundry(t);
    testEveryIngotReadsEverySkill(t);
    testTypedCurrency(t);
    testKindsInCorners(t);
    testVariantsAndHooks(t);
    testLinksAndArc(t);
    testMarrowAndQuicksilverForms(t);
    testRails(t);
    testMetal(t);
    testClassKits(t);
    testClassGear(t);
    testMelee(t);
    testWorldMadeWhole(t);
    testDayAndNight(t);
    testHauling(t);
    testDensityAndFear(t);
    testWorldABeatAhead(t);
    testHornAndSiege(t);
    testVerbs(t);
    testCurioAndLock(t);
    testMingling(t);
    testItemsAsMechanics(t);
    testMasteryAndCraftRolls(t);
    testBiggerWorld(t);
    testEraThreeAndLife(t);

    std::printf("%d checks, %d failures\n", checks, failures);
    return failures == 0 ? 0 : 1;
}
