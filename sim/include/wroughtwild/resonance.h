#pragma once
#include "wroughtwild/worldgen.h"
#include "wroughtwild/json.h"

namespace wroughtwild::resonance {
inline constexpr const char* campaign = "living_frontier_wave4";
struct Config {
    int maxRise = 2, blend = 3, minimumColumns = 32, oreCount = 4, oreUnits = 8;
    double ownershipMargin = 3, resourceMargin = 2, oreSpacing = 6;
    static Config load(const std::string& path);
};
// Entire vertical columns are retained, including underground structures.
struct Bounds { double minX, minZ, maxX, maxZ; };
struct Column { int x, z, before, after; };
struct State {
    std::string phase = "dormant";
    uint64_t seed = 0;
    std::vector<Column> columns;
    std::vector<worldgen::SurfacePoint> ore;
    int oreUnits = 0;
    bool hasHost = false, campaignAward = false;
    worldgen::SurfacePoint host;
    std::string toJson() const;
    static State fromJson(const json::Value& value);
};
State prepare(const worldgen::WorldMap& base, const Config& config, const std::vector<Bounds>& ownership);
// Validates against immutable geography before touching any live block.
void validate(const worldgen::WorldMap& base, const State& state);
void apply(worldgen::WorldMap& map, const State& state);
}
