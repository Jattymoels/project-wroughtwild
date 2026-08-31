#include "wroughtwild/loot.h"

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
        if (roll(rng) >= entry.chance) continue;
        std::uniform_int_distribution<int> count(entry.minCount, entry.maxCount);
        drops[entry.item] += count(rng);
    }
    return drops;
}

} // namespace wroughtwild::loot
