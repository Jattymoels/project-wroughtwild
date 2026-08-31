// Headless regression tests for the engine-neutral simulation core.
// Run via `make` in tests/sim; exits non-zero on any failure.

#include <cmath>
#include <cstdio>
#include <string>

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/items.h"
#include "wroughtwild/save.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/trial.h"
#include "wroughtwild/tuning.h"

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
            for (const auto& d : t.items.propertyDefinitions)
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
    const auto* def = &t.items.propertyDefinitions[0];
    for (const auto& d : t.items.propertyDefinitions)
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

} // namespace

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
    testCombat(t);
    testTrialContracts(t);
    testSaveLoad(t);

    std::printf("%d checks, %d failures\n", checks, failures);
    return failures == 0 ? 0 : 1;
}
