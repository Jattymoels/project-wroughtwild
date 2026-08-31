#pragma once

// Mob loot: what a slain enemy drops, rolled deterministically from its
// loot table in world.json. The engine passes a per-kill seed so replays
// and tests get identical drops.

#include <cstdint>
#include <map>
#include <string>

#include "wroughtwild/tuning.h"

namespace wroughtwild::loot {

// Rolls every entry of the enemy's loot table: each entry drops with its
// chance, at a uniform count in [min, max]. Empty map for an unknown enemy
// or an all-miss roll.
std::map<std::string, int> rollEnemyLoot(const tuning::WorldTable& world,
                                         const std::string& enemyId,
                                         uint64_t seed);

} // namespace wroughtwild::loot
