// Headless regression tests for the engine-neutral simulation core.
// Run via `make` in tests/sim; exits non-zero on any failure.

#include <cmath>
#include <cstdio>
#include <string>

#include "wroughtwild/boons.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/items.h"
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
}

void testSkillCurve(const tuning::Tuning& t) {
    const auto* bs = t.skills.findCraftSkill("blacksmithing");
    check(economy::levelForXp(*bs, 0) == 1, "skills: level 1 at 0 xp");
    check(economy::levelForXp(*bs, 49) == 1, "skills: level 1 just below threshold");
    check(economy::levelForXp(*bs, 50) == 2, "skills: level 2 at 50 xp");
    check(economy::levelForXp(*bs, 350) == 5, "skills: level 5 at 350 xp");
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

    std::printf("%d checks, %d failures\n", checks, failures);
    return failures == 0 ? 0 : 1;
}
