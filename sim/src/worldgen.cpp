#include "wroughtwild/worldgen.h"

#include <algorithm>
#include <cmath>

namespace wroughtwild::worldgen {

namespace {

// SplitMix64-style integer hash: fast, well mixed, dependency-free.
uint64_t hashCoords(uint64_t seed, int x, int z, uint32_t salt) {
    uint64_t h = seed;
    h ^= 0x9E3779B97F4A7C15ull * (static_cast<uint64_t>(static_cast<uint32_t>(x)) + 1);
    h ^= 0xC2B2AE3D27D4EB4Full * (static_cast<uint64_t>(static_cast<uint32_t>(z)) + 1);
    h ^= 0x165667B19E3779F9ull * (static_cast<uint64_t>(salt) + 1);
    h ^= h >> 30;
    h *= 0xBF58476D1CE4E5B9ull;
    h ^= h >> 27;
    h *= 0x94D049BB133111EBull;
    h ^= h >> 31;
    return h;
}

double lattice(uint64_t seed, int x, int z, uint32_t salt) {
    return (hashCoords(seed, x, z, salt) >> 11) * (1.0 / 9007199254740992.0);
}

double smoothstep(double t) { return t * t * (3.0 - 2.0 * t); }

// Value noise: random values on an integer lattice, smoothly interpolated.
double valueNoise(uint64_t seed, double x, double z, uint32_t salt) {
    int x0 = static_cast<int>(std::floor(x));
    int z0 = static_cast<int>(std::floor(z));
    double tx = smoothstep(x - x0);
    double tz = smoothstep(z - z0);
    double a = lattice(seed, x0, z0, salt);
    double b = lattice(seed, x0 + 1, z0, salt);
    double c = lattice(seed, x0, z0 + 1, salt);
    double d = lattice(seed, x0 + 1, z0 + 1, salt);
    double ab = a + (b - a) * tx;
    double cd = c + (d - c) * tx;
    return ab + (cd - ab) * tz;
}

// Fractal (layered) noise in [0, 1): each octave adds finer detail.
double fbm(uint64_t seed, double x, double z, double frequency, int octaves, uint32_t salt) {
    double total = 0.0, amplitude = 1.0, sum = 0.0;
    for (int i = 0; i < octaves; ++i) {
        total += valueNoise(seed, x * frequency, z * frequency, salt + i * 101) * amplitude;
        sum += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return total / sum;
}

int biomeFor(const tuning::WorldgenTable& table, int height, double moisture) {
    for (size_t i = 0; i < table.biomes.size(); ++i) {
        const tuning::BiomeDef& biome = table.biomes[i];
        if (biome.heightMin >= 0 && height < biome.heightMin) continue;
        if (biome.heightMax >= 0 && height > biome.heightMax) continue;
        if (biome.moistureMin >= 0.0 && moisture < biome.moistureMin) continue;
        if (moisture > biome.moistureMax) continue;
        return static_cast<int>(i);
    }
    return static_cast<int>(table.biomes.size()) - 1;
}

double distance(int ax, int az, int bx, int bz) {
    return std::sqrt(static_cast<double>((ax - bx) * (ax - bx) + (az - bz) * (az - bz)));
}

} // namespace

double cellNoise(uint64_t seed, int x, int z, uint32_t salt) {
    return lattice(seed, x, z, salt);
}

int WorldMap::countNodesNear(const std::string& type, int cx, int cz, double radius) const {
    int count = 0;
    for (const auto& node : nodes)
        if (node.type == type && distance(node.x, node.z, cx, cz) <= radius) ++count;
    return count;
}

WorldMap generate(const tuning::Tuning& tuning, uint64_t seed) {
    const tuning::WorldgenTable& table = tuning.worldgen;
    const tuning::MapParams& params = table.map;
    const tuning::WorldgenGuarantees& g = table.guarantees;

    WorldMap map;
    map.seed = seed;
    map.width = params.widthCells;
    map.height = params.heightCells;
    map.cellSize = params.cellSizeM;
    map.cells.resize(static_cast<size_t>(map.width) * map.height);

    // 1. Terrain heights and biomes from layered noise.
    for (int z = 0; z < map.height; ++z) {
        for (int x = 0; x < map.width; ++x) {
            double h = fbm(seed, x, z, params.heightFrequency, params.heightOctaves, 1);
            double moisture = fbm(seed, x, z, params.moistureFrequency, 2, 2000);
            Cell& cell = map.cells[z * map.width + x];
            cell.height = params.baseHeight + static_cast<int>(std::floor(h * params.heightScale));
            cell.biomeIndex = biomeFor(table, cell.height, moisture);
        }
    }

    // 2. Spawn: the spawn-biome cell nearest the map centre; the clearing
    //    around it is flattened and forced to the spawn biome so every start
    //    is safe and readable.
    int spawnBiome = 0;
    for (size_t i = 0; i < table.biomes.size(); ++i)
        if (table.biomes[i].id == g.spawnBiome) spawnBiome = static_cast<int>(i);
    int cx = map.width / 2, cz = map.height / 2;
    map.spawnX = cx;
    map.spawnZ = cz;
    double best = 1e18;
    for (int z = 2; z < map.height - 2; ++z)
        for (int x = 2; x < map.width - 2; ++x)
            if (map.at(x, z).biomeIndex == spawnBiome) {
                double d = distance(x, z, cx, cz);
                if (d < best) { best = d; map.spawnX = x; map.spawnZ = z; }
            }
    int spawnHeight = map.at(map.spawnX, map.spawnZ).height;
    int clearR = static_cast<int>(std::ceil(g.spawnClearRadiusM / params.cellSizeM));
    for (int z = std::max(0, map.spawnZ - clearR); z <= std::min(map.height - 1, map.spawnZ + clearR); ++z)
        for (int x = std::max(0, map.spawnX - clearR); x <= std::min(map.width - 1, map.spawnX + clearR); ++x)
            if (distance(x, z, map.spawnX, map.spawnZ) <= clearR) {
                Cell& cell = map.cells[z * map.width + x];
                cell.height = spawnHeight;
                cell.biomeIndex = spawnBiome;
            }

    // 3. Trial gate: the farthest gate-biome cell from spawn (any farthest
    //    cell when the biome is absent), honouring the minimum distance.
    int gateBiome = -1;
    for (size_t i = 0; i < table.biomes.size(); ++i)
        if (table.biomes[i].id == g.gateBiome) gateBiome = static_cast<int>(i);
    double bestGate = -1.0;
    for (int z = 2; z < map.height - 2; ++z)
        for (int x = 2; x < map.width - 2; ++x) {
            if (gateBiome >= 0 && map.at(x, z).biomeIndex != gateBiome) continue;
            double d = distance(x, z, map.spawnX, map.spawnZ);
            if (d > bestGate) { bestGate = d; map.gateX = x; map.gateZ = z; }
        }
    if (bestGate < g.gateMinDistanceM / params.cellSizeM) {
        bestGate = -1.0;
        for (int z = 2; z < map.height - 2; ++z)
            for (int x = 2; x < map.width - 2; ++x) {
                double d = distance(x, z, map.spawnX, map.spawnZ);
                if (d > bestGate) { bestGate = d; map.gateX = x; map.gateZ = z; }
            }
    }

    // 4. Resource nodes: per-cell deterministic rolls against the biome's
    //    densities, keeping the clearing's centre and the gate approach open.
    for (int z = 1; z < map.height - 1; ++z) {
        for (int x = 1; x < map.width - 1; ++x) {
            if (distance(x, z, map.spawnX, map.spawnZ) < 3.0) continue;
            if (distance(x, z, map.gateX, map.gateZ) < 3.0) continue;
            const tuning::BiomeDef& biome = table.biomes[map.at(x, z).biomeIndex];
            uint32_t salt = 3000;
            for (const auto& [type, density] : biome.nodeDensity) {
                ++salt;
                if (lattice(seed, x, z, salt) < density) {
                    map.nodes.push_back({type, x, z});
                    break; // one node per cell
                }
            }
        }
    }

    // 5. Guarantee minimum nodes near spawn: when a seed comes up short,
    //    convert deterministic eligible cells inside the radius (critical
    //    progression resources cannot be absent from a valid seed).
    int nearR = static_cast<int>(g.nearRadiusM / params.cellSizeM);
    for (const auto& [type, minimum] : g.minNodesNear) {
        int have = map.countNodesNear(type, map.spawnX, map.spawnZ, nearR);
        for (int ring = clearR + 1; ring <= nearR && have < minimum; ++ring) {
            for (int z = map.spawnZ - ring; z <= map.spawnZ + ring && have < minimum; ++z) {
                for (int x = map.spawnX - ring; x <= map.spawnX + ring && have < minimum; ++x) {
                    if (!map.inBounds(x, z)) continue;
                    double d = distance(x, z, map.spawnX, map.spawnZ);
                    if (d < ring - 1 || d > ring) continue;
                    bool occupied = false;
                    for (const auto& node : map.nodes)
                        if (node.x == x && node.z == z) occupied = true;
                    if (occupied) continue;
                    if (lattice(seed, x, z, 7777) < 0.25) {
                        map.nodes.push_back({type, x, z});
                        ++have;
                    }
                }
            }
        }
    }

    // 6. Mob packs: sparse deterministic rolls on a coarse stride so packs
    //    keep natural spacing; never inside the spawn's protective radius.
    double packSafe = g.packMinDistanceFromSpawnM / params.cellSizeM;
    for (int z = 2; z < map.height - 2; z += 4) {
        for (int x = 2; x < map.width - 2; x += 4) {
            const tuning::BiomeDef& biome = table.biomes[map.at(x, z).biomeIndex];
            if (biome.packs.empty() || biome.packDensity <= 0.0) continue;
            if (distance(x, z, map.spawnX, map.spawnZ) < packSafe) continue;
            // The stride visits 1/16th of cells; scale the per-cell density up
            // so the tuned value keeps meaning "packs per cell".
            if (lattice(seed, x, z, 9100) < biome.packDensity * 16.0) {
                size_t pick = hashCoords(seed, x, z, 9200) % biome.packs.size();
                map.packs.push_back({biome.packs[pick], x, z});
            }
        }
    }

    return map;
}

} // namespace wroughtwild::worldgen
