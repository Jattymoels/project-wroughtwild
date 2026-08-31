#pragma once

// Seed-generated bounded sandpit world (D-003). In plain terms: given one
// number (the seed) and the rules in worldgen.json, this produces the same
// world every time — terrain heights, biome per cell, where every tree,
// boulder, iron vein and mob pack stands, where the player starts and where
// the trial gate waits. The engine renders this data; it never invents
// terrain of its own, so tests can hold every world to the guarantees.

#include <cstdint>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::worldgen {

struct Cell {
    int height = 0;      // terrain height in whole blocks
    int biomeIndex = 0;  // index into WorldgenTable::biomes
};

struct PlacedNode {
    std::string type; // key into WorldgenTable::nodeTypes
    int x = 0;
    int z = 0;
};

struct MobPack {
    std::vector<std::string> enemies;
    int x = 0;
    int z = 0;
};

struct WorldMap {
    uint64_t seed = 0;
    int width = 0;
    int height = 0;
    double cellSize = 1.0;
    std::vector<Cell> cells; // row-major, index = z * width + x
    std::vector<PlacedNode> nodes;
    std::vector<MobPack> packs;
    int spawnX = 0, spawnZ = 0;
    int gateX = 0, gateZ = 0;

    const Cell& at(int x, int z) const { return cells[z * width + x]; }
    bool inBounds(int x, int z) const { return x >= 0 && x < width && z >= 0 && z < height; }
    int countNodesNear(const std::string& type, int cx, int cz, double radius) const;
};

// Deterministic: the same tuning and seed always produce the same map, and
// every map satisfies WorldgenGuarantees (safe spawn clearing, minimum
// nodes in reach, gate distance) by construction.
WorldMap generate(const tuning::Tuning& tuning, uint64_t seed);

// Deterministic per-cell hash in [0, 1); exposed for tests.
double cellNoise(uint64_t seed, int x, int z, uint32_t salt);

} // namespace wroughtwild::worldgen
