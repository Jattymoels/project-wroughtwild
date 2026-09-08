#pragma once

// LF-1: finite lots at fixed hosts, with one saved claim owner. No scene, menu,
// offline clock or global loot RNG can create material or another rare roll.
#include "wroughtwild/economy.h"
#include "wroughtwild/worldgen.h"
#include <set>

namespace wroughtwild::leyline {
inline constexpr const char* profile = "living_frontier_wave1";
inline bool supports(const std::string& id) { return id == profile || id == "living_frontier_wave3"; }
inline constexpr int saveVersion = 4;
struct Source {
    std::string id, label, material, rareItem;
    int homeIndex = 0, lots = 8, units = 16, rarePer10000 = 0;
    int introducedVersion = 1;
    double offsetX = 0, offsetZ = 0, formationSeconds = 600;
    std::vector<std::string> stages;
};
struct Config {
    std::vector<Source> sources;
    static Config load(const std::string& path);
};
struct State {
    int manifestation = 0, lot = 0, work = 0;
    double formation = 0;
    std::string outcomes; // hidden, fixed once at formation; one bit per lot
    economy::Inventory claim;
};
struct Result { bool ok = false; int moved = 0; std::string message; };
class World {
public:
    World(Config config, uint64_t seed);
    const Config& config() const { return config_; }
    uint64_t seed() const { return seed_; }
    const State& state(const std::string& id) const;
    const Source& source(const std::string& id) const;
    // Anchor geography reuses a guaranteed reachable, clear V6 home margin.
    static worldgen::SurfacePoint anchor(const Source&, const worldgen::WorldMap&);
    Result work(const std::string& id);
    Result collect(const std::string& id, const std::string& item, economy::PlayerEconomy& player);
    // Host passes active overworld time only. Ready stock never banks credit.
    void advance(double seconds, const std::set<std::string>& blocked);
    std::string serialize() const;
    bool restore(const std::string& text, std::string* reason = nullptr);
private:
    Config config_;
    uint64_t seed_;
    std::map<std::string, State> states_;
    void form(const Source&, State&);
};
} // namespace wroughtwild::leyline
