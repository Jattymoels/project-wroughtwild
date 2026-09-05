#pragma once

// Seed-generated bounded sandpit world (D-003). In plain terms: given one
// number (the seed) and the rules in worldgen.json, this produces the same
// world every time — a full 3D block field (terrain, strata, carved caves),
// the biome per column, where every tree, boulder, iron vein and mob pack
// stands, where the player starts and where the trial gate waits. The
// engine renders this data; it never invents terrain of its own, so tests
// can hold every world to the guarantees.

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::worldgen {

// The block palette. A block at level y occupies [y, y+1); a column of
// height h is solid from 0 to h-1 (surface block at h-1) minus whatever the
// caves carved, and the walking surface sits at y = h.
enum Block : uint8_t {
    kAir = 0,
    kSurface = 1, // the biome-textured top block
    kDirt = 2,
    kStone = 3,
    kBedrock = 4, // y = 0, never carved (and never breakable, come slice 2)
};

struct Cell {
    int height = 0;      // walking-surface level in whole blocks
    int biomeIndex = 0;  // index into WorldgenTable::biomes
};

struct PlacedNode {
    PlacedNode() = default;
    PlacedNode(std::string inType, int inX, int inY, int inZ)
        : type(std::move(inType)), x(inX), y(inY), z(inZ) {}
    std::string type; // key into WorldgenTable::nodeTypes
    int x = 0;
    int y = 0; // level the node stands on: the surface, or a cave floor
    int z = 0;
    std::string resourceId; // persistent identity, independent of scene naming
    std::string habitatId;  // empty for ordinary scattered resources
};

struct SurfacePoint { int x = 0, y = 0, z = 0; };
struct PlacedHabitat {
    std::string id;
    std::string biome;
    int x = 0, y = 0, z = 0;
    double radiusM = 0;
    std::vector<SurfacePoint> approach; // connected, clear surface walk from spawn
};

// A landmark placed by worldgen (Wave 8 slice 2): the lock a curio opens.
struct PlacedLandmark {
    std::string id;
    int x = 0;
    int z = 0;
};

struct MobPack {
    std::vector<std::string> enemies;
    int x = 0;
    int y = 0; // the level the pack stands on: the surface, or a cave floor
    int z = 0;
    // Danger rings may crown one member with an elite modifier (Wave 3).
    int eliteMemberIndex = -1;   // -1 = no elite in this pack
    std::string eliteModifierId;
    bool grazer = false;         // life, not threat: placed outside the danger rules
    // Wave 7 slice 1: the biome the pack dens in ("cave" underground), and
    // for a deep biome's pack the route it patrols at night - from the den
    // toward the heartland, stopping short of the doorstep, back by dawn.
    std::string biome;
    bool patrols = false;
    int routeX = 0;
    int routeZ = 0;
    // The mingling (Wave 8 slice 3): the nearest den of another biome
    // within reach; once an era's patrols cross biomes, the night's route.
    bool hasForeign = false;
    int foreignX = 0;
    int foreignZ = 0;
    std::string foreignBiome;
};

struct WorldMap {
    std::string profileId;
    uint64_t seed = 0;
    int width = 0;
    int height = 0;
    int depth = 0;       // vertical block levels (y in [0, depth))
    double cellSize = 1.0;
    std::vector<Cell> cells;     // row-major, index = z * width + x
    std::vector<uint8_t> blocks; // column-contiguous: (z * width + x) * depth + y
    std::vector<PlacedNode> nodes;
    std::vector<MobPack> packs;
    std::vector<PlacedLandmark> landmarks;
    std::vector<PlacedHabitat> habitats;
    int spawnX = 0, spawnZ = 0;
    int gateX = 0, gateZ = 0;

    const Cell& at(int x, int z) const { return cells[z * width + x]; }
    bool inBounds(int x, int z) const { return x >= 0 && x < width && z >= 0 && z < height; }
    uint8_t blockAt(int x, int y, int z) const {
        if (!inBounds(x, z) || y < 0 || y >= depth) return kAir;
        return blocks[(static_cast<size_t>(z) * width + x) * depth + y];
    }
    // The topmost solid level + 1 for a column (the level you stand at);
    // equals at(x, z).height unless a cave breached the surface there.
    int topSolid(int x, int z) const;
    int countNodesNear(const std::string& type, int cx, int cz, double radius) const;
};

// Deterministic: the same tuning and seed always produce the same map, and
// every map satisfies WorldgenGuarantees (safe spawn clearing, minimum
// nodes in reach, gate distance) by construction.
WorldMap generate(const tuning::Tuning& tuning, uint64_t seed);

// Runtime generation uses a named immutable identity. The historical generate
// entry point remains the tuning-driven base for existing probes and tests.
bool knownProfile(const std::string& profileId);
const tuning::WorldgenTable& profileTable(const tuning::Tuning& tuning,
                                        const std::string& profileId);
WorldMap generateProfile(const tuning::Tuning& tuning, uint64_t seed,
                         const std::string& profileId);

// Deterministic per-cell hash in [0, 1); exposed for tests.
double cellNoise(uint64_t seed, int x, int z, uint32_t salt);

} // namespace wroughtwild::worldgen
