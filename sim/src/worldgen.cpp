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

// --- 3D noise (caves) --------------------------------------------------------

uint64_t hashCoords3(uint64_t seed, int x, int y, int z, uint32_t salt) {
    uint64_t h = seed;
    h ^= 0x9E3779B97F4A7C15ull * (static_cast<uint64_t>(static_cast<uint32_t>(x)) + 1);
    h ^= 0xC2B2AE3D27D4EB4Full * (static_cast<uint64_t>(static_cast<uint32_t>(z)) + 1);
    h ^= 0xD6E8FEB86659FD93ull * (static_cast<uint64_t>(static_cast<uint32_t>(y)) + 1);
    h ^= 0x165667B19E3779F9ull * (static_cast<uint64_t>(salt) + 1);
    h ^= h >> 30;
    h *= 0xBF58476D1CE4E5B9ull;
    h ^= h >> 27;
    h *= 0x94D049BB133111EBull;
    h ^= h >> 31;
    return h;
}

double lattice3(uint64_t seed, int x, int y, int z, uint32_t salt) {
    return (hashCoords3(seed, x, y, z, salt) >> 11) * (1.0 / 9007199254740992.0);
}

// Trilinear value noise: the 2D lattice idea with a vertical axis, so cave
// fields wind through the ground instead of stamping every level the same.
double valueNoise3(uint64_t seed, double x, double y, double z, uint32_t salt) {
    int x0 = static_cast<int>(std::floor(x));
    int y0 = static_cast<int>(std::floor(y));
    int z0 = static_cast<int>(std::floor(z));
    double tx = smoothstep(x - x0);
    double ty = smoothstep(y - y0);
    double tz = smoothstep(z - z0);
    double c000 = lattice3(seed, x0, y0, z0, salt);
    double c100 = lattice3(seed, x0 + 1, y0, z0, salt);
    double c010 = lattice3(seed, x0, y0 + 1, z0, salt);
    double c110 = lattice3(seed, x0 + 1, y0 + 1, z0, salt);
    double c001 = lattice3(seed, x0, y0, z0 + 1, salt);
    double c101 = lattice3(seed, x0 + 1, y0, z0 + 1, salt);
    double c011 = lattice3(seed, x0, y0 + 1, z0 + 1, salt);
    double c111 = lattice3(seed, x0 + 1, y0 + 1, z0 + 1, salt);
    double x00 = c000 + (c100 - c000) * tx;
    double x10 = c010 + (c110 - c010) * tx;
    double x01 = c001 + (c101 - c001) * tx;
    double x11 = c011 + (c111 - c011) * tx;
    double y0v = x00 + (x10 - x00) * ty;
    double y1v = x01 + (x11 - x01) * ty;
    return y0v + (y1v - y0v) * tz;
}

double fbm3(uint64_t seed, double x, double y, double z, double frequency, int octaves,
            uint32_t salt) {
    double total = 0.0, amplitude = 1.0, sum = 0.0;
    for (int i = 0; i < octaves; ++i) {
        total += valueNoise3(seed, x * frequency, y * frequency, z * frequency, salt + i * 101) *
                 amplitude;
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

int WorldMap::topSolid(int x, int z) const {
    for (int y = depth - 1; y >= 0; --y)
        if (blockAt(x, y, z) != kAir) return y + 1;
    return 0;
}

WorldMap generate(const tuning::Tuning& tuning, uint64_t seed) {
    const tuning::WorldgenTable& table = tuning.worldgen;
    const tuning::MapParams& params = table.map;
    const tuning::WorldgenGuarantees& g = table.guarantees;

    WorldMap map;
    map.seed = seed;
    map.width = params.widthCells;
    map.height = params.heightCells;
    map.depth = params.worldDepth;
    map.cellSize = params.cellSizeM;
    map.cells.resize(static_cast<size_t>(map.width) * map.height);

    // 1. Terrain heights and biomes from layered noise: a rolling base plus
    //    localized craggy massifs where the cragginess field runs high, so
    //    the world has real verticality without turning every walk into a
    //    climb.
    const tuning::MountainParams& m = table.mountains;
    for (int z = 0; z < map.height; ++z) {
        for (int x = 0; x < map.width; ++x) {
            double h = fbm(seed, x, z, params.heightFrequency, params.heightOctaves, 1);
            double moisture = fbm(seed, x, z, params.moistureFrequency, 2, 2000);
            Cell& cell = map.cells[z * map.width + x];
            cell.height = params.baseHeight + static_cast<int>(std::floor(h * params.heightScale));
            if (m.extraScale > 0) {
                double crag = fbm(seed, x, z, m.cragginessFrequency, 2, 1500);
                if (crag > m.cragginessThreshold) {
                    double t = smoothstep((crag - m.cragginessThreshold) /
                                          (1.0 - m.cragginessThreshold));
                    double ridge = fbm(seed, x, z, m.frequency, 3, 1600);
                    cell.height += static_cast<int>(std::floor(t * ridge * m.extraScale));
                }
            }
            cell.height = std::min(cell.height, map.depth - 2);
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

    // 4. The block field: strata per column (bedrock, stone, dirt, the
    //    biome surface block), then carved caves — two intersecting 3D
    //    noise level-sets wind tunnels, a third opens caverns low down.
    //    Some columns are breach columns: a tunnel there may carve all the
    //    way up through the surface, leaving a natural entrance. The spawn
    //    clearing and the gate's ground are never carved.
    const tuning::CaveParams& caves = table.caves;
    map.blocks.assign(static_cast<size_t>(map.width) * map.height * map.depth, kAir);
    for (int z = 0; z < map.height; ++z) {
        for (int x = 0; x < map.width; ++x) {
            int hgt = map.at(x, z).height;
            uint8_t* column = &map.blocks[(static_cast<size_t>(z) * map.width + x) * map.depth];
            for (int y = 0; y < hgt && y < map.depth; ++y) {
                if (y == 0) column[y] = kBedrock;
                else if (y == hgt - 1) column[y] = kSurface;
                else if (y >= hgt - 1 - table.strata.dirtDepth) column[y] = kDirt;
                else column[y] = kStone;
            }
            if (!caves.enabled) continue;
            if (distance(x, z, map.spawnX, map.spawnZ) <= clearR + 1) continue;
            if (distance(x, z, map.gateX, map.gateZ) <= 3.0) continue;
            bool breach = lattice(seed, x, z, 4600) < caves.breachChance;
            int roof = breach ? 0 : caves.surfaceMargin + 1;
            for (int y = caves.minY; y <= hgt - 1 - roof; ++y) {
                double t1 = std::abs(fbm3(seed, x, y, z, caves.tunnelFrequency, 2, 4000) - 0.5);
                double t2 = std::abs(fbm3(seed, x, y, z, caves.tunnelFrequency, 2, 4200) - 0.5);
                bool carve = t1 + t2 < caves.tunnelWidth;
                if (!carve && y < hgt * caves.cavernMaxYFraction &&
                    fbm3(seed, x, y, z, caves.cavernFrequency, 2, 4400) > caves.cavernThreshold)
                    carve = true;
                if (carve) column[y] = kAir;
            }
        }
    }

    // The deepest roofed cave floor of a column (-1 when it has none):
    // where underground nodes stand and cave packs den.
    auto caveFloorY = [&](int x, int z) -> int {
        int hgt = map.at(x, z).height;
        for (int y = caves.minY + 1; y < hgt - 2; ++y) {
            if (map.blockAt(x, y, z) != kAir || map.blockAt(x, y - 1, z) == kAir) continue;
            for (int above = y + 1; above < hgt; ++above)
                if (map.blockAt(x, above, z) != kAir) return y;
            return -1; // open to the sky: an entrance shaft, not a den
        }
        return -1;
    };

    // 5. Cave-floor nodes: the deepest roofed floor of each carved column
    //    may hold a node (iron runs richer underground — the reason to go
    //    down). One node per column, cave before surface.
    std::vector<bool> columnHasNode(static_cast<size_t>(map.width) * map.height, false);
    if (caves.enabled && !caves.nodeDensity.empty()) {
        for (int z = 1; z < map.height - 1; ++z) {
            for (int x = 1; x < map.width - 1; ++x) {
                int floorY = caveFloorY(x, z);
                if (floorY < 0) continue;
                uint32_t salt = 5000;
                for (const auto& [type, density] : caves.nodeDensity) {
                    ++salt;
                    if (lattice(seed, x, z, salt) < density) {
                        map.nodes.push_back({type, x, floorY, z});
                        columnHasNode[static_cast<size_t>(z) * map.width + x] = true;
                        break;
                    }
                }
            }
        }
    }

    // 6. Surface resource nodes: per-cell deterministic rolls against the
    //    biome's densities, keeping the clearing's centre and the gate
    //    approach open. Breached columns (a cave entrance) get nothing.
    for (int z = 1; z < map.height - 1; ++z) {
        for (int x = 1; x < map.width - 1; ++x) {
            if (distance(x, z, map.spawnX, map.spawnZ) < 3.0) continue;
            if (distance(x, z, map.gateX, map.gateZ) < 3.0) continue;
            if (columnHasNode[static_cast<size_t>(z) * map.width + x]) continue;
            if (map.topSolid(x, z) != map.at(x, z).height) continue;
            const tuning::BiomeDef& biome = table.biomes[map.at(x, z).biomeIndex];
            uint32_t salt = 3000;
            for (const auto& [type, density] : biome.nodeDensity) {
                ++salt;
                if (lattice(seed, x, z, salt) < density) {
                    map.nodes.push_back({type, x, map.at(x, z).height, z});
                    break; // one node per cell
                }
            }
        }
    }

    // 7. Guarantee minimum nodes near spawn: when a seed comes up short,
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
                    if (map.topSolid(x, z) != map.at(x, z).height) continue;
                    bool occupied = false;
                    for (const auto& node : map.nodes)
                        if (node.x == x && node.z == z) occupied = true;
                    if (occupied) continue;
                    if (lattice(seed, x, z, 7777) < 0.25) {
                        map.nodes.push_back({type, x, map.at(x, z).height, z});
                        ++have;
                    }
                }
            }
        }
    }

    // Rounds a rolled pack off with the danger ring's rules: extra members
    // drawn from the pack's own kind, and perhaps one member crowned with
    // an elite modifier (Wave 3: elites are why you hunt the far rings).
    auto finishPack = [&](std::vector<std::string> enemies, int x, int y, int z) {
        MobPack pack;
        double distanceM = distance(x, z, map.spawnX, map.spawnZ) * params.cellSizeM;
        const tuning::DangerRing* ring = table.dangerRingAt(distanceM);
        if (ring != nullptr && !enemies.empty()) {
            for (int i = 0; i < ring->packSizeBonus; ++i)
                enemies.push_back(
                    enemies[hashCoords(seed, x, z, 9300 + static_cast<uint32_t>(i)) % enemies.size()]);
            const auto& elites = tuning.world.eliteModifiers;
            if (!elites.empty() && ring->eliteChance > 0.0 &&
                lattice(seed, x, z, 9400) < ring->eliteChance) {
                pack.eliteMemberIndex =
                    static_cast<int>(hashCoords(seed, x, z, 9500) % enemies.size());
                pack.eliteModifierId =
                    elites[hashCoords(seed, x, z, 9600) % elites.size()].id;
            }
        }
        pack.enemies = std::move(enemies);
        pack.x = x;
        pack.y = y;
        pack.z = z;
        map.packs.push_back(std::move(pack));
    };

    // 8. Surface mob packs: sparse deterministic rolls on a coarse stride
    //    so packs keep natural spacing; never inside the spawn's protective
    //    radius, never over a cave entrance, and denser the farther out the
    //    cell sits (danger rings: leaving the heartland is a choice).
    double packSafe = g.packMinDistanceFromSpawnM / params.cellSizeM;
    for (int z = 2; z < map.height - 2; z += 4) {
        for (int x = 2; x < map.width - 2; x += 4) {
            const tuning::BiomeDef& biome = table.biomes[map.at(x, z).biomeIndex];
            if (biome.packs.empty() || biome.packDensity <= 0.0) continue;
            double fromSpawn = distance(x, z, map.spawnX, map.spawnZ);
            if (fromSpawn < packSafe) continue;
            if (map.topSolid(x, z) != map.at(x, z).height) continue;
            double danger = table.dangerMultiplierAt(fromSpawn * params.cellSizeM);
            // The stride visits 1/16th of cells; scale the per-cell density up
            // so the tuned value keeps meaning "packs per cell".
            if (lattice(seed, x, z, 9100) < biome.packDensity * 16.0 * danger) {
                size_t pick = hashCoords(seed, x, z, 9200) % biome.packs.size();
                finishPack(biome.packs[pick], x, map.at(x, z).height, z);
            }
        }
    }

    // 9. Cave packs: dens on roofed cave floors, on the same coarse stride.
    //    The dark has its own residents (and its own elites).
    if (caves.enabled && !caves.packs.empty() && caves.packDensity > 0.0) {
        for (int z = 2; z < map.height - 2; z += 4) {
            for (int x = 2; x < map.width - 2; x += 4) {
                if (distance(x, z, map.spawnX, map.spawnZ) < packSafe) continue;
                int floorY = caveFloorY(x, z);
                if (floorY < 0) continue;
                if (lattice(seed, x, z, 9700) < caves.packDensity * 16.0) {
                    size_t pick = hashCoords(seed, x, z, 9800) % caves.packs.size();
                    finishPack(caves.packs[pick], x, floorY, z);
                }
            }
        }
    }

    return map;
}

} // namespace wroughtwild::worldgen
