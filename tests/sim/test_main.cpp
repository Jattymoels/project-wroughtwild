// Headless regression tests for the engine-neutral simulation core.
// Run via `make` in tests/sim; exits non-zero on any failure.

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <string>

#include <set>
#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/grammar.h"
#include "wroughtwild/items.h"
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

    // The trial's completion unlock gates the slab.
    const auto* slab = t.construction.findShape("stonecut_slab");
    check(slab != nullptr && slab->requiresWorldEffect == t.trial.completionUnlock,
          "construction: slab is gated by the trial completion unlock");
    check(slab->sizeM[1] < slab->sizeM[0], "construction: slab is half height");
    check(slab->anchor == "centre" && cube->anchor == "centre", "construction: anchor defaults to centre");
    const auto* panel = t.construction.findShape("wall_panel");
    check(panel != nullptr && panel->anchor == "face", "construction: wall panel anchors to a cell face");
    const auto* pillar = t.construction.findShape("pillar");
    check(pillar != nullptr && pillar->anchor == "corner", "construction: pillar anchors to a cell corner");
    player.inventory["wood"] = 10;
    check(!player.shapeUnlocked("stonecut_slab") && !player.canAffordPlacement("stonecut_slab", "wood"),
          "construction: slab locked before the boss falls");
    player.recordWorldEffect(t.trial.completionUnlock);
    check(player.shapeUnlocked("stonecut_slab") && player.payPlacement("stonecut_slab", "wood"),
          "construction: slab placeable after the unlock");
    check(t.crafting.basicTemper.property == "fire_resistance" && t.crafting.basicTemper.tier == 1,
          "crafting: basic temper config loads");
    check(t.construction.shapes.size() >= 6, "construction: prototype shape set has at least six shapes");
    int unlockedFromStart = 0;
    for (const auto& shape : t.construction.shapes)
        if (shape.requiresWorldEffect.empty()) ++unlockedFromStart;
    check(unlockedFromStart >= 5, "construction: most shapes are available before the trial");
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
    check(player.currency["trade_currency"] == 40, "order: currency reward granted");
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
    check(player.inventory["iron_chest_armour"] == 1, "spine: armour produced");
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
    player.currency["trade_currency"] = 30;
    player.inventory["iron_fittings"] = 6;
    check(player.buildStation("forge_improved"), "build: upgrade paid from currency + goods");
    check(player.currency["trade_currency"] == 0 && player.inventory["iron_fittings"] == 0,
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
        check(player.worldEffectActive(t.trial.completionUnlock),
              "trial: construction unlock granted");
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
    // The forge kit needs the workbench plus all three gathered families.
    auto blocked = player.craft("forge_kit");
    check(!blocked.crafted && blocked.failure.missingInputs, "kits: forge kit needs materials");
    player.inventory["wood"] = 12;
    player.inventory["stone"] = 8;
    player.inventory["iron_ore"] = 4;
    auto forge = player.craft("forge_kit");
    check(forge.crafted && player.inventory["forge_kit"] == 1, "kits: forge kit assembles at the bench");
    check(player.inventory["stone"] == 0, "kits: stone family consumed");
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
        if (drops.count("stone")) {
            ++stoneDrops;
            if (drops["stone"] < 2 || drops["stone"] > 4) boundsOk = false;
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
    check(t.worldgen.dangerMultiplierAt(30.0) <= t.worldgen.dangerMultiplierAt(200.0) &&
              t.worldgen.dangerMultiplierAt(200.0) > 1.0,
          "worldgen: danger rings scale pack density outward");
    check(t.worldgen.blockRules.count("stone") == 1 &&
              t.worldgen.blockRules.at("stone").yields.at("stone") == 1 &&
              t.worldgen.blockRules.at("stone").digSeconds > 0.0 &&
              !t.worldgen.blockRules.at("bedrock").breakable,
          "worldgen: block rules load (stone pays stone, bedrock never breaks)");

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
        double gateDistance = std::sqrt(
            static_cast<double>((map.gateX - map.spawnX) * (map.gateX - map.spawnX) +
                                (map.gateZ - map.spawnZ) * (map.gateZ - map.spawnZ)));
        if (gateDistance < g.gateMinDistanceM) {
            allGood = false; firstBad = "gate too close (seed " + std::to_string(seed) + ")";
        }
        for (const auto& pack : map.packs) {
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
        auto item = items::rollRarityItem(t.items, "ember_wand", "wrought", 1, seed);
        for (const auto& rolled : item.rolledProperties) {
            const auto* def = t.items.findModifier(rolled.propertyId);
            check(def && !def->isSelf(), "status: the wand rolls only skill modifiers (" + rolled.propertyId + ")");
        }
        auto maceRoll = items::rollRarityItem(t.items, "iron_mace", "wrought", 1, seed);
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
    check(taught.size() == 3, "drops: every learnable skill turns up on pages");
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
    check(loot::rollEnemyLoot(t.world, "stone_husk", 99).count("stone") == 1,
          "drops: materials still roll beside gear and pages");
}

} // namespace

// D-014 slice 1: one modifier pool, rarity by count, gear-driven grammar,
// pack items that save, and trial rooms that drop gear.
void testItemisation(const tuning::Tuning& t) {
    check(t.items.slots.size() == 3 && t.items.findRarity("wrought") != nullptr, "items: slots and rarities load");
    const auto* sceptre = t.items.findBase("frost_sceptre");
    check(sceptre != nullptr && sceptre->slot == "weapon" && !sceptre->implicitModifiers.empty(),
          "items: weapon base carries its slot and an implicit (never a skill, D-016)");
    check(t.items.findModifier("max_life")->isSelf() && !t.items.findModifier("deep_frost")->isSelf(),
          "items: self modifiers are told apart from skill modifiers");
    for (const auto& def : t.items.modifiers)
        check(!def.designPurpose.empty(), "items: every modifier states its design purpose (" + def.id + ")");

    // Rarity is a modifier count within the rarity's range, all distinct, all allowed.
    for (uint64_t seed = 0; seed < 40; ++seed) {
        auto item = items::rollRarityItem(t.items, "frost_sceptre", "wrought", 1, seed);
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

    // Gear drives the grammar: a plain sceptre's implicit fork doubles the orb.
    stats::Equipment worn;
    items::ItemInstance plainSceptre;
    plainSceptre.baseId = "frost_sceptre";
    worn.slots["weapon"] = plainSceptre;
    auto mods = grammar::gearMods(t.items, worn);
    check(mods.size() == 1 && mods.front().source == "weapon", "items: implicit modifier comes from the weapon slot");
    check(grammar::forkCount(t, mods, "prototype_frost_orb") == 2, "items: the sceptre's implicit fork counts");
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

    std::printf("%d checks, %d failures\n", checks, failures);
    return failures == 0 ? 0 : 1;
}
