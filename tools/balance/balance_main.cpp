// Balance simulator: plays the economy and the boss fight thousands of times
// headless and reports the numbers a designer needs — how long progression
// takes, and how much each gear step actually changes survival.
// Usage: balance [path-to-data/tuning]

#include <cstdio>
#include <string>
#include <vector>

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/items.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/trial.h"
#include "wroughtwild/tuning.h"

using namespace wroughtwild;

namespace {

// --- economy pacing ---------------------------------------------------------

void reportSkillPacing(const tuning::Tuning& t) {
    std::printf("== Blacksmithing pacing ==\n");

    // Useful-work policy: smelt, craft fittings for the order, fulfil it,
    // then keep doing order-quality work (bulk fittings for construction).
    {
        economy::PlayerEconomy player(t);
        player.inventory["wood"] = 100000;
        player.inventory["iron_ore"] = 100000;
        player.inventory["iron_ingot"] = 100000;
        int crafts = 0;
        bool orderDone = false;
        int level = player.skillLevel("blacksmithing");
        std::printf("useful-work route (order first, then order-quality work):\n");
        player.addAvailableStation("forge_basic");
        while (player.skillLevel("blacksmithing") < 5 && crafts < 100000) {
            if (!orderDone && player.inventory["iron_fittings"] >= 24) {
                player.fulfillOrder("reinforce_old_mine");
                orderDone = true;
            }
            player.craft("iron_fittings", /*forOrder=*/true);
            ++crafts;
            if (player.skillLevel("blacksmithing") > level) {
                level = player.skillLevel("blacksmithing");
                std::printf("  level %d after %d crafts (%d xp)\n", level, crafts,
                            player.skillXp("blacksmithing"));
            }
        }
        std::printf("  iron ingots consumed: %d\n\n", crafts * 2);
    }

    // Spam policy: repeat the cheapest recipe with no useful destination.
    {
        economy::PlayerEconomy player(t);
        player.addAvailableStation("forge_basic");
        player.inventory["wood"] = 1000000;
        player.inventory["iron_ore"] = 1000000;
        int crafts = 0;
        int level = 1;
        std::printf("spam route (cheapest recipe, decay applies):\n");
        while (player.skillLevel("blacksmithing") < 5 && crafts < 1000000) {
            player.craft("smelt_iron");
            ++crafts;
            if (player.skillLevel("blacksmithing") > level) {
                level = player.skillLevel("blacksmithing");
                std::printf("  level %d after %d crafts (%d xp)\n", level, crafts,
                            player.skillXp("blacksmithing"));
            }
        }
        if (level < 5) std::printf("  gave up before level 5 after %d crafts\n", crafts);
        std::printf("\n");
    }
}

// --- combat outcomes --------------------------------------------------------

struct GearStage {
    std::string name;
    double armour;
    double fireResistance;
};

stats::DerivedStats statsFor(const tuning::Tuning& t, const GearStage& stage) {
    stats::Equipment equipment;
    if (stage.armour > 0.0 || stage.fireResistance > 0.0) {
        items::ItemInstance chest;
        chest.baseId = "iron_chest_armour";
        chest.implicitProperties["armour"] = stage.armour;
        if (stage.fireResistance > 0.0)
            chest.rolledProperties.push_back({"fire_resistance", 2, stage.fireResistance});
        equipment.slots["chest"] = chest;
    }
    return stats::deriveStats(t.world.playerBase, equipment);
}

void reportBossOutcomes(const tuning::Tuning& t) {
    std::printf("== Boss outcomes (auto policy, %s) ==\n", t.trial.boss.displayName.c_str());

    // Tier-1 midpoint = the deterministic basic temper; the catalyst floor and
    // ceiling come from the tier-2 range and Proposal C's floor fraction.
    const auto* process = t.crafting.findCatalystProcess("ember_catalyst_tempering");
    double t1mid = 10.0, t2min = 13.0, t2max = 20.0;
    for (const auto& def : t.items.modifiers) {
        if (def.id != "fire_resistance") continue;
        for (const auto& tier : def.tiers) {
            if (tier.tier == 1) t1mid = (tier.minimum + tier.maximum) / 2.0;
            if (tier.tier == 2) { t2min = tier.minimum; t2max = tier.maximum; }
        }
    }
    double catalystFloor =
        t2min + (process ? process->minimumRollFractionAtSkill : 0.0) * (t2max - t2min);

    std::vector<GearStage> stages = {
        {"bare (no armour)", 0.0, 0.0},
        {"iron armour, untempered", 20.0, 0.0},
        {"armour + basic temper", 20.0, t1mid},
        {"armour + catalyst (floor roll)", 20.0, catalystFloor},
        {"armour + catalyst (best roll)", 20.0, t2max},
    };

    const int trials = 2000;
    for (const auto& stage : stages) {
        auto playerStats = statsFor(t, stage);
        int wins = 0;
        long long roundsTotal = 0;
        double lifeTotal = 0.0;
        for (int seed = 0; seed < trials; ++seed) {
            auto result = combat::runEncounter(t, playerStats, combat::CombatMods{},
                                               {t.trial.boss.id}, 100000 + seed,
                                               combat::autoPolicy);
            if (result.victory) {
                ++wins;
                roundsTotal += result.rounds;
                lifeTotal += result.playerLifeRemaining;
            }
        }
        std::printf("  %-32s win %5.1f%%", stage.name.c_str(), 100.0 * wins / trials);
        if (wins > 0)
            std::printf("  (avg %4.1f rounds, %4.1f life left on wins)",
                        static_cast<double>(roundsTotal) / wins, lifeTotal / wins);
        std::printf("\n");
    }
    std::printf("\n");
}

void reportFullTrialRuns(const tuning::Tuning& t) {
    std::printf("== Full trial runs (rooms + boons + boss, auto policy) ==\n");
    boons::BuildTags tags = {"attack", "physical", "area", "single_target", "movement"};

    struct RunStage {
        std::string name;
        double fireResistance;
    };
    std::vector<RunStage> stages = {
        {"armour + basic temper", 10.0},
        {"armour + catalyst floor", 16.5},
    };

    const int trials = 500;
    for (const auto& stage : stages) {
        auto playerStats = statsFor(t, {stage.name, 20.0, stage.fireResistance});
        int completions = 0, deaths = 0;
        for (int seed = 0; seed < trials; ++seed) {
            economy::PlayerEconomy player(t);
            trial::TrialSession session(t, player, tags, 500000 + seed);
            while (!session.finished()) {
                const auto& stageChoices = session.currentStage().choices;
                int choice = static_cast<int>(seed) % static_cast<int>(stageChoices.size());
                auto outcome = session.enterRoom(choice, playerStats, combat::autoPolicy);
                if (!outcome.boonOffer.empty())
                    session.acceptBoonFromOffer(outcome.boonOffer.front()->id);
                if (!outcome.offeredWeakness.empty()) session.acceptOfferedWeakness();
            }
            if (session.bossDefeated()) ++completions;
            if (session.playerDied()) ++deaths;
        }
        std::printf("  %-28s completed %5.1f%%, died %5.1f%%\n", stage.name.c_str(),
                    100.0 * completions / trials, 100.0 * deaths / trials);
    }
    std::printf("\n");
}

void reportCatalystRolls(const tuning::Tuning& t) {
    const auto* process = t.crafting.findCatalystProcess("ember_catalyst_tempering");
    if (!process) return;
    std::printf("== Catalyst temper rolls (skill 5, Proposal C) ==\n");
    double minRoll = 1e9, maxRoll = -1e9, total = 0.0;
    const int samples = 5000;
    for (int seed = 0; seed < samples; ++seed) {
        items::ItemInstance armour;
        armour.baseId = "iron_chest_armour";
        auto result = items::catalystTemper(t.items, *process, armour, 5, seed);
        minRoll = std::min(minRoll, result.rolledValue);
        maxRoll = std::max(maxRoll, result.rolledValue);
        total += result.rolledValue;
    }
    std::printf("  fire resistance roll: min %.2f, mean %.2f, max %.2f\n\n", minRoll,
                total / samples, maxRoll);
}

} // namespace

int main(int argc, char** argv) {
    std::string tuningDir = argc > 1 ? argv[1] : "../../data/tuning";
    tuning::Tuning t;
    try {
        t = tuning::loadAll(tuningDir);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "cannot load tuning from %s: %s\n", tuningDir.c_str(), e.what());
        return 2;
    }

    reportSkillPacing(t);
    reportCatalystRolls(t);
    reportBossOutcomes(t);
    reportFullTrialRuns(t);
    return 0;
}
