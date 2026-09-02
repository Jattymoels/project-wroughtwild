#pragma once

// Mob loot: what a slain enemy drops, rolled deterministically from its
// loot table in world.json. The engine passes a per-kill seed so replays
// and tests get identical drops. A table carries three kinds of entry:
// material stacks, gear (a rarity and a chance, rolled on any base) and
// skill pages (D-016: a page teaches one skill the player does not know).

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "wroughtwild/items.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::loot {

// Rolls every material entry of the enemy's loot table: each entry drops
// with its chance, at a uniform count in [min, max]. Empty map for an
// unknown enemy or an all-miss roll. Gear and page entries are skipped.
// An elite modifier (nullable) adds its extraLootRolls as further whole
// passes of the table on salted streams - elites only ever pay more.
std::map<std::string, int> rollEnemyLoot(const tuning::WorldTable& world,
                                         const std::string& enemyId,
                                         uint64_t seed,
                                         const tuning::EliteModifierDef* elite = nullptr);

// Rolls the enemy's gear entries: each drops with its chance as one item of
// its rarity and tier, on a base drawn from every base in items.json.
// Deterministic per seed; independent of the material roll above. An elite
// modifier multiplies each entry's chance by gearChanceMultiplier.
std::vector<items::ItemInstance> rollEnemyGear(const tuning::Tuning& tuning,
                                               const std::string& enemyId,
                                               uint64_t seed,
                                               const tuning::EliteModifierDef* elite = nullptr);

// Rolls the enemy's skill-page entries: each drops with its chance as one
// skill the player does not yet know, weighted by drop_weight (so a page
// never teaches a known skill and never drops once every skill is known).
// Returns the skill id, or "" for no page. Independent of the rolls above.
// An elite modifier multiplies each entry's chance by pageChanceMultiplier.
std::string rollEnemySkillPage(const tuning::Tuning& tuning,
                               const std::string& enemyId,
                               uint64_t seed,
                               const std::vector<std::string>& knownSkills,
                               const tuning::EliteModifierDef* elite = nullptr);

} // namespace wroughtwild::loot
