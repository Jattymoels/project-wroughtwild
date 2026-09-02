#include "wroughtwild/loot.h"

#include <algorithm>
#include <random>

namespace wroughtwild::loot {

std::map<std::string, int> rollEnemyLoot(const tuning::WorldTable& world,
                                         const std::string& enemyId,
                                         uint64_t seed) {
    std::map<std::string, int> drops;
    const tuning::EnemyDef* enemy = world.findEnemy(enemyId);
    if (!enemy) return drops;

    std::mt19937_64 rng(seed);
    std::uniform_real_distribution<double> roll(0.0, 1.0);
    for (const auto& entry : enemy->loot) {
        if (entry.kind != "item") continue; // gear and pages roll separately
        if (roll(rng) >= entry.chance) continue;
        std::uniform_int_distribution<int> count(entry.minCount, entry.maxCount);
        drops[entry.item] += count(rng);
    }
    return drops;
}

std::vector<items::ItemInstance> rollEnemyGear(const tuning::Tuning& tuning,
                                               const std::string& enemyId,
                                               uint64_t seed) {
    std::vector<items::ItemInstance> drops;
    const tuning::EnemyDef* enemy = tuning.world.findEnemy(enemyId);
    if (!enemy || tuning.items.itemBases.empty()) return drops;

    // A separate stream from the material roll, so adding a gear entry to a
    // table never changes which materials the same seed drops.
    std::mt19937_64 rng(seed ^ 0x9E3779B97F4A7C15ull);
    std::uniform_real_distribution<double> roll(0.0, 1.0);
    std::uniform_int_distribution<size_t> pickBase(0, tuning.items.itemBases.size() - 1);
    for (const auto& entry : enemy->loot) {
        if (entry.kind != "gear") continue;
        if (roll(rng) >= entry.chance) continue;
        const auto& base = tuning.items.itemBases[pickBase(rng)];
        drops.push_back(items::rollRarityItem(tuning.items, base.id, entry.gearRarity,
                                              entry.gearTier, rng()));
    }
    return drops;
}

std::string rollEnemySkillPage(const tuning::Tuning& tuning,
                               const std::string& enemyId,
                               uint64_t seed,
                               const std::vector<std::string>& knownSkills) {
    const tuning::EnemyDef* enemy = tuning.world.findEnemy(enemyId);
    if (!enemy) return "";

    // The pool: unknown skills with a positive drop weight.
    std::vector<const tuning::CombatSkillDef*> pool;
    double totalWeight = 0.0;
    for (const auto& def : tuning.skills.combatSkills) {
        if (def.dropWeight <= 0.0) continue;
        if (std::find(knownSkills.begin(), knownSkills.end(), def.id) != knownSkills.end()) continue;
        pool.push_back(&def);
        totalWeight += def.dropWeight;
    }
    if (pool.empty()) return "";

    // Its own stream again, so pages never disturb material or gear rolls.
    std::mt19937_64 rng(seed ^ 0xC2B2AE3D27D4EB4Full);
    std::uniform_real_distribution<double> roll(0.0, 1.0);
    for (const auto& entry : enemy->loot) {
        if (entry.kind != "skill_page") continue;
        if (roll(rng) >= entry.chance) continue;
        double pick = roll(rng) * totalWeight;
        for (const auto* def : pool) {
            pick -= def->dropWeight;
            if (pick < 0.0) return def->id;
        }
        return pool.back()->id; // rounding at the top of the range
    }
    return "";
}

} // namespace wroughtwild::loot
