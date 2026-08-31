#pragma once

// Trial boon and weakness offers. Temporary run effects are kept in RunState,
// entirely separate from the persistent build, so ending a run cannot leak
// trial modifiers into permanent progression (design pillar: persistent build
// enters trials intact and is only temporarily altered).

#include <cstdint>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::boons {

// The tags that describe the persistent build's current identity, e.g. the
// tags of its equipped combat skills ("area", "single_target", ...).
using BuildTags = std::vector<std::string>;

struct RunState {
    std::vector<std::string> activeBoons;
    std::vector<std::string> activeWeaknesses;

    bool hasBoon(const std::string& id) const;
    bool hasWeakness(const std::string& id) const;
    void acceptWeakness(const std::string& id) { activeWeaknesses.push_back(id); }

    // Ending a run (victory or death) discards every temporary effect.
    void clear();
};

// A boon is compatible when its requires_any_tags intersect the build's tags
// (unconditional when empty) and its required weakness, if any, is active.
bool isCompatible(const tuning::BoonDef& boon, const BuildTags& buildTags, const RunState& run);

// Deterministically generates one offer of up to options_per_offer distinct
// boons the player does not already have. When allow_incompatible_options is
// false, only compatible boons are offered. The same seed and state always
// produce the same offer.
std::vector<const tuning::BoonDef*> generateOffer(const tuning::BoonTable& table,
                                                  const BuildTags& buildTags,
                                                  const RunState& run,
                                                  uint64_t seed);

// Accepts a boon into the run; returns false when it is unknown, already
// active or incompatible.
bool acceptBoon(const tuning::BoonTable& table,
                const std::string& boonId,
                const BuildTags& buildTags,
                RunState& run);

// Product of base_reward_multiplier for each active weakness (1.0 when none).
double rewardMultiplier(const tuning::BoonTable& table, const RunState& run);

} // namespace wroughtwild::boons
