#include "wroughtwild/worldgen.h"

#include <algorithm>
#include <cmath>
#include <queue>
#include <set>
#include <stdexcept>

namespace wroughtwild::worldgen {

bool knownProfile(const std::string& profileId) {
    return profileId == "legacy_v1" || profileId == "frontier_v2" || profileId == "frontier_v3" || profileId == "frontier_v4" || profileId == "frontier_v5" || profileId == "frontier_v6" || profileId == "living_frontier_wave1" || profileId == "living_frontier_wave3";
}

const tuning::WorldgenTable& profileTable(const tuning::Tuning& tuning,
                                        const std::string& profileId) {
    if (profileId == "legacy_v1") return tuning.legacyWorldgen;
    if (profileId == "frontier_v2") return tuning.frontierV2Worldgen;
    if (profileId == "frontier_v3") return tuning.frontierV3Worldgen;
    if (profileId == "frontier_v4") return tuning.frontierV4Worldgen;
    if (profileId == "frontier_v5") return tuning.frontierV5Worldgen;
    if (profileId == "frontier_v6") return tuning.worldgen;
    if (profileId == "living_frontier_wave1") return tuning.livingFrontierWorldgen;
    if (profileId == "living_frontier_wave3") return tuning.livingFrontierWave3Worldgen;
    throw std::runtime_error("worldgen: unknown generation profile " + profileId);
}

namespace {
namespace frozen_frontier {
#include "worldgen_frontier_v2.inc"
#include "worldgen_frontier_v3.inc"
}
namespace cataclysm_frontier {
using frozen_frontier::stableSalt;
using frozen_frontier::distanceSquared;
using frozen_frontier::supportedFootprint;
using frozen_frontier::approachTo;
using frozen_frontier::reserveApproach;
using frozen_frontier::placeHabitats;
#include "worldgen_frontier_v4.inc"
}
namespace pressure_frontier {
#include "worldgen_frontier_v5.inc"
}
namespace frontier_v6_base {
#include "worldgen_frontier_v6_base.inc"
}
namespace wide_frontier {
using frozen_frontier::stableSalt;
using frozen_frontier::distanceSquared;
using frozen_frontier::supportedFootprint;
using frozen_frontier::approachTo;
using frozen_frontier::reserveApproach;
using frozen_frontier::placeHabitats;
#include "worldgen_frontier_v6_landscape.inc"
#include "worldgen_frontier_v6_opening.inc"
}
namespace wide_pressure {
#include "worldgen_frontier_v6_pressure.inc"
}

namespace living_frontier_wave3 {
#include "worldgen_living_frontier_wave3.inc"
}

} // namespace

WorldMap generateProfile(const tuning::Tuning& tuning, uint64_t seed, const std::string& profileId) {
    const auto& table = profileTable(tuning, profileId);
    if (table.generationProfile != profileId)
        throw std::runtime_error("worldgen: generation inputs do not match profile " + profileId);
    // Only these inputs participate in frozen generation. Combat numbers may
    // change without silently moving legacy packs, resources or terrain.
    tuning::Tuning generationInputs;
    generationInputs.worldgen = table;
    for (const auto& id : table.generationEliteIds) {
        tuning::EliteModifierDef modifier;
        modifier.id = id;
        generationInputs.world.eliteModifiers.push_back(modifier);
    }
    const bool wide = profileId == "frontier_v6" || profileId == "living_frontier_wave1" || profileId == "living_frontier_wave3";
    WorldMap map = wide ? frontier_v6_base::generate(generationInputs, seed) : generate(generationInputs, seed);
    map.profileId = profileId;
    for (auto& node : map.nodes) node.resourceId = frozen_frontier::legacyNodeId(node);
    if (profileId == "frontier_v2") frozen_frontier::placeHabitats(map, table);
    if (profileId == "frontier_v3") frozen_frontier::composeFrontierV3(map, table);
    if (profileId == "frontier_v4") cataclysm_frontier::composeFrontierV4(map, table);
    if (profileId == "frontier_v5") pressure_frontier::composeFrontierV5(map, table);
    if (wide) {
        wide_pressure::composeFrontierV6Pressure(map,table);
        wide_frontier::finishWideFrontier(map,table);
    }
    if (profileId == "living_frontier_wave3") living_frontier_wave3::compose(map,tuning.livingFrontier);
    return map;
}

} // namespace wroughtwild::worldgen
