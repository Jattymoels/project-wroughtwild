#include "wroughtwild/boons.h"

#include <algorithm>
#include <random>

namespace wroughtwild::boons {

namespace {
bool contains(const std::vector<std::string>& list, const std::string& value) {
    return std::find(list.begin(), list.end(), value) != list.end();
}
} // namespace

bool RunState::hasBoon(const std::string& id) const { return contains(activeBoons, id); }
bool RunState::hasWeakness(const std::string& id) const { return contains(activeWeaknesses, id); }

void RunState::clear() {
    activeBoons.clear();
    activeWeaknesses.clear();
}

bool isCompatible(const tuning::BoonDef& boon, const BuildTags& buildTags, const RunState& run) {
    if (!boon.requiresAnyTags.empty()) {
        bool anyTag = std::any_of(boon.requiresAnyTags.begin(), boon.requiresAnyTags.end(),
                                  [&](const std::string& tag) { return contains(buildTags, tag); });
        if (!anyTag) return false;
    }
    if (!boon.requiresWeakness.empty() && !run.hasWeakness(boon.requiresWeakness)) return false;
    return true;
}

std::vector<const tuning::BoonDef*> generateOffer(const tuning::BoonTable& table,
                                                  const BuildTags& buildTags,
                                                  const RunState& run,
                                                  uint64_t seed) {
    std::vector<const tuning::BoonDef*> pool;
    for (const auto& boon : table.boons) {
        if (run.hasBoon(boon.id)) continue;
        if (!table.offerRules.allowIncompatibleOptions && !isCompatible(boon, buildTags, run))
            continue;
        pool.push_back(&boon);
    }

    std::mt19937_64 rng(seed);
    std::vector<const tuning::BoonDef*> offer;
    int wanted = table.offerRules.optionsPerOffer;
    while (static_cast<int>(offer.size()) < wanted && !pool.empty()) {
        std::uniform_int_distribution<size_t> pick(0, pool.size() - 1);
        size_t index = pick(rng);
        offer.push_back(pool[index]);
        pool.erase(pool.begin() + index);
    }
    return offer;
}

bool acceptBoon(const tuning::BoonTable& table,
                const std::string& boonId,
                const BuildTags& buildTags,
                RunState& run) {
    const tuning::BoonDef* boon = table.findBoon(boonId);
    if (!boon || run.hasBoon(boonId) || !isCompatible(*boon, buildTags, run)) return false;
    run.activeBoons.push_back(boonId);
    return true;
}

double rewardMultiplier(const tuning::BoonTable& table, const RunState& run) {
    double multiplier = 1.0;
    for (const auto& weakness : table.weaknesses)
        if (run.hasWeakness(weakness.id)) multiplier *= weakness.baseRewardMultiplier;
    return multiplier;
}

} // namespace wroughtwild::boons
