// Frozen frontier_v2 habitat composition captured 6 September 2026.
// Together with worldgen_legacy_v1.inc and worldgen-frontier-v2.json, this preserves existing saves.


uint32_t stableSalt(const std::string& text) {
    uint32_t hash = 2166136261u;
    for (unsigned char ch : text) hash = (hash ^ ch) * 16777619u;
    return hash;
}

double distanceSquared(int ax, int az, int bx, int bz) {
    const double dx = ax - bx, dz = az - bz;
    return dx * dx + dz * dz;
}

std::string legacyNodeId(const PlacedNode& node) {
    return "wn_" + node.type + "_" + std::to_string(node.x) + "_" +
           std::to_string(node.y) + "_" + std::to_string(node.z);
}

struct SurfaceWalk {
    std::vector<int> heights;
    std::vector<bool> clear;
    std::vector<int> parent;
};

// A conservative surface route: supported, open to the sky, at most one
// block of rise per metre, and no resource trunk/rock in the walking lane.
SurfaceWalk surfaceWalk(const WorldMap& map, int maxStep) {
    const int size = map.width * map.height;
    SurfaceWalk walk;
    walk.heights.resize(size);
    walk.clear.resize(size, false);
    walk.parent.resize(size, -1);
    for (int z = 1; z < map.height - 1; ++z) {
        for (int x = 1; x < map.width - 1; ++x) {
            const int at = z * map.width + x;
            const int y = map.topSolid(x, z);
            walk.heights[at] = y;
            walk.clear[at] = y == map.at(x, z).height && y > 0 && y + 2 < map.depth;
        }
    }
    for (const auto& node : map.nodes) {
        if (node.y != map.at(node.x, node.z).height) continue;
        for (int dz = -1; dz <= 1; ++dz) for (int dx = -1; dx <= 1; ++dx) {
            if (dx * dx + dz * dz > 1) continue;
            const int x = node.x + dx, z = node.z + dz;
            if (map.inBounds(x, z)) walk.clear[z * map.width + x] = false;
        }
    }
    const int start = map.spawnZ * map.width + map.spawnX;
    walk.clear[start] = true;
    walk.parent[start] = start;
    std::queue<int> todo;
    todo.push(start);
    const int dx[] = {1, 0, -1, 0}, dz[] = {0, 1, 0, -1};
    while (!todo.empty()) {
        const int at = todo.front(); todo.pop();
        const int x = at % map.width, z = at / map.width;
        for (int direction = 0; direction < 4; ++direction) {
            const int nx = x + dx[direction], nz = z + dz[direction];
            if (!map.inBounds(nx, nz)) continue;
            const int next = nz * map.width + nx;
            if (!walk.clear[next] || walk.parent[next] >= 0 ||
                std::abs(walk.heights[at] - walk.heights[next]) > maxStep) continue;
            walk.parent[next] = at;
            todo.push(next);
        }
    }
    return walk;
}

bool supportedFootprint(const WorldMap& map, const SurfaceWalk& walk, int x, int z, int maxStep) {
    const int centre = z * map.width + x;
    if (walk.parent[centre] < 0) return false;
    for (int dz = -1; dz <= 1; ++dz) for (int dx = -1; dx <= 1; ++dx) {
        if (!map.inBounds(x + dx, z + dz)) return false;
        const int at = (z + dz) * map.width + x + dx;
        if (!walk.clear[at] ||
            std::abs(walk.heights[at] - walk.heights[centre]) > maxStep) return false;
    }
    return true;
}

std::vector<SurfacePoint> approachTo(const WorldMap& map, const SurfaceWalk& walk, int x, int z) {
    std::vector<SurfacePoint> path;
    int at = z * map.width + x;
    while (at >= 0) {
        path.push_back({at % map.width, walk.heights[at], at / map.width});
        if (walk.parent[at] == at) break;
        at = walk.parent[at];
    }
    std::reverse(path.begin(), path.end());
    return path;
}

void reserveApproach(const WorldMap& map, const std::vector<SurfacePoint>& path,
                     std::set<int>& reserved) {
    for (const auto& point : path)
        for (int dz = -1; dz <= 1; ++dz) for (int dx = -1; dx <= 1; ++dx)
            if (map.inBounds(point.x + dx, point.z + dz))
                reserved.insert((point.z + dz) * map.width + point.x + dx);
}

// Validate the entire cluster before committing. Failed candidates never
// leave half a habitat, duplicate identities or resources across its approach.
std::vector<PlacedNode> resourceCluster(const WorldMap& map, const SurfaceWalk& walk,
                                       const tuning::HabitatDef& def, int cx, int cz,
                                       const std::set<int>& reserved) {
    std::vector<PlacedNode> nodes;
    auto resources = def.resources;
    std::sort(resources.begin(), resources.end(), [](const auto& a, const auto& b) {
        return a.nodeType < b.nodeType;
    });
    const int radius = static_cast<int>(std::floor(def.radiusM / map.cellSize));
    const double spacing = def.minimumSpacingM / map.cellSize;
    const double orientation = cellNoise(map.seed, cx, cz, def.salt) * 6.283185307179586;
    for (size_t index = 0; index < resources.size(); ++index) {
        const auto& resource = resources[index];
        const double angle = orientation + 6.283185307179586 * index / resources.size();
        const double targetX = cx + std::cos(angle) * radius * 0.48;
        const double targetZ = cz + std::sin(angle) * radius * 0.48;
        std::vector<std::pair<double, int>> candidates;
        for (int z = cz - radius; z <= cz + radius; ++z)
            for (int x = cx - radius; x <= cx + radius; ++x) {
                const double distance = distanceSquared(x, z, cx, cz);
                const int at = z * map.width + x;
                if (!map.inBounds(x, z) || distance > radius * radius || distance < 9 ||
                    reserved.count(at) || !supportedFootprint(map, walk, x, z, def.maximumSurfaceStep)) continue;
                const double dx = x - targetX, dz = z - targetZ;
                const double score = dx * dx + dz * dz +
                    cellNoise(map.seed, x, z, def.salt ^ stableSalt(resource.nodeType)) * 4;
                candidates.push_back({score, at});
            }
        std::sort(candidates.begin(), candidates.end());
        int made = 0;
        for (const auto& candidate : candidates) {
            const int x = candidate.second % map.width, z = candidate.second / map.width;
            bool crowded = false;
            for (const auto& placed : nodes)
                if (distanceSquared(x, z, placed.x, placed.z) < spacing * spacing) { crowded = true; break; }
            if (crowded) continue;
            PlacedNode node(resource.nodeType, x, walk.heights[candidate.second], z);
            node.resourceId = "wnv2_" + def.id + "_" + resource.nodeType + "_" + std::to_string(made);
            node.habitatId = def.id;
            nodes.push_back(std::move(node));
            if (++made == resource.count) break;
        }
        if (made != resource.count) return {};
    }
    return nodes;
}

void placeHabitats(WorldMap& map, const tuning::WorldgenTable& table) {
    auto definitions = table.habitats;
    std::sort(definitions.begin(), definitions.end(), [](const auto& a, const auto& b) { return a.id < b.id; });
    std::set<int> reserved;
    for (const auto& def : definitions) {
        const auto walk = surfaceWalk(map, def.maximumSurfaceStep);
        const int radius = static_cast<int>(std::ceil(def.radiusM / map.cellSize));
        const double minimum = std::max(def.minimumDistanceM,
            table.guarantees.nearRadiusM + def.radiusM + 3) / map.cellSize;
        const double maximum = def.maximumDistanceM / map.cellSize;
        std::vector<std::pair<double, int>> candidates;
        for (int z = radius + 2; z < map.height - radius - 2; z += 2)
            for (int x = radius + 2; x < map.width - radius - 2; x += 2) {
                const double distance = distanceSquared(x, z, map.spawnX, map.spawnZ);
                if (distance < minimum * minimum || distance > maximum * maximum ||
                    !supportedFootprint(map, walk, x, z, def.maximumSurfaceStep)) continue;
                const auto& biome = table.biomes[map.at(x, z).biomeIndex].id;
                if (biome != def.biome && biome != def.fallbackBiome) continue;
                bool occupied = distanceSquared(x, z, map.gateX, map.gateZ) < (radius + 8) * (radius + 8);
                for (const auto& landmark : map.landmarks)
                    if (distanceSquared(x, z, landmark.x, landmark.z) < (radius + 8) * (radius + 8)) occupied = true;
                for (const auto& habitat : map.habitats) {
                    const double separation = (def.radiusM + habitat.radiusM + 8) / map.cellSize;
                    if (distanceSquared(x, z, habitat.x, habitat.z) < separation * separation) occupied = true;
                }
                if (occupied) continue;
                double score = biome == def.biome ? 0 : 10000;
                if (def.id == "quarry_escarpment") score -= walk.heights[z * map.width + x] * 5;
                if (def.id == "fen_hollow") score += walk.heights[z * map.width + x] * 5;
                score += cellNoise(map.seed, x, z, def.salt) * 12 + distance * 0.0005;
                candidates.push_back({score, z * map.width + x});
            }
        std::sort(candidates.begin(), candidates.end());
        bool placed = false;
        for (const auto& candidate : candidates) {
            const int x = candidate.second % map.width, z = candidate.second / map.width;
            auto approach = approachTo(map, walk, x, z);
            auto trialReserved = reserved;
            reserveApproach(map, approach, trialReserved);
            auto nodes = resourceCluster(map, walk, def, x, z, trialReserved);
            if (nodes.empty()) continue;
            PlacedHabitat habitat;
            habitat.id = def.id;
            habitat.biome = table.biomes[map.at(x, z).biomeIndex].id;
            habitat.x = x; habitat.y = walk.heights[candidate.second]; habitat.z = z;
            habitat.radiusM = def.radiusM;
            habitat.approach = std::move(approach);
            map.habitats.push_back(std::move(habitat));
            map.nodes.insert(map.nodes.end(), nodes.begin(), nodes.end());
            reserved = std::move(trialReserved);
            placed = true;
            break;
        }
        if (!placed) throw std::runtime_error("worldgen: no reachable complete site for " + def.id);
    }
}
