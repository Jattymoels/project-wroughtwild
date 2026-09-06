// Strange Frontier composition. The frozen base supplies bounded geology;
// broad regional masks are composed before the complete, finite rare sites.
// This file deliberately does not alter either older profile's generator.

int regionBiome(const tuning::WorldgenTable& table, const std::string& id) {
    for (size_t i = 0; i < table.biomes.size(); ++i)
        if (table.biomes[i].id == id) return static_cast<int>(i);
    throw std::runtime_error("worldgen: missing regional biome " + id);
}

void replaceSurface(WorldMap& map, const tuning::WorldgenTable& table,
                    int x, int z, int height) {
    auto& cell = map.cells[z * map.width + x];
    cell.height = std::clamp(height, 2, map.depth - 3);
    auto* column = &map.blocks[(static_cast<size_t>(z) * map.width + x) * map.depth];
    for (int y = 0; y < map.depth; ++y)
        column[y] = y == 0 ? kBedrock : y >= cell.height ? kAir :
            y == cell.height - 1 ? kSurface :
            y >= cell.height - 1 - table.strata.dirtDepth ? kDirt : kStone;
}

const PlacedRegion* regionAt(const WorldMap& map, int x, int z, double inset = 0) {
    for (const auto& r : map.regions) {
        const double radius = r.radiusM / map.cellSize - inset;
        if (distanceSquared(x, z, r.x, r.z) <= radius * radius) return &r;
    }
    return nullptr;
}

void composeRegions(WorldMap& map, const tuning::WorldgenTable& table) {
    auto definitions = table.regions;
    std::sort(definitions.begin(), definitions.end(), [](const auto& a, const auto& b) { return a.id < b.id; });
    const auto oldCells = map.cells;
    const double rotation = cellNoise(map.seed, 0, 0, 56001) * 6.283185307179586;
    for (size_t index = 0; index < definitions.size(); ++index) {
        const auto& def = definitions[index];
        const double angle = rotation + index * 6.283185307179586 / definitions.size();
        const double radius = def.radiusM / map.cellSize;
        const double transition = def.transitionM / map.cellSize;
        const int margin = static_cast<int>(std::ceil(radius + transition + 4));
        PlacedRegion r;
        r.id = def.id; r.biome = def.biome;
        r.x = std::clamp(static_cast<int>(map.width / 2 + std::cos(angle) * def.distanceM / map.cellSize), margin, map.width - margin - 1);
        r.z = std::clamp(static_cast<int>(map.height / 2 + std::sin(angle) * def.distanceM / map.cellSize), margin, map.height - margin - 1);
        r.radiusM = def.radiusM; r.transitionM = def.transitionM;
        const int biome = regionBiome(table, def.biome);
        const double phase = cellNoise(map.seed, r.x, r.z, def.salt) * 6.283185307179586;
        for (int z = r.z - margin + 2; z <= r.z + margin - 2; ++z)
            for (int x = r.x - margin + 2; x <= r.x + margin - 2; ++x) {
                const double d = std::sqrt(distanceSquared(x, z, r.x, r.z));
                if (d >= radius + transition) continue;
                // The starter clearing and its guaranteed nearby supplies stay
                // ordinary heartland even when a seed's spawn shifts off centre.
                const double spawnD = std::sqrt(distanceSquared(x, z, map.spawnX, map.spawnZ));
                if (spawnD < table.guarantees.nearRadiusM / map.cellSize + 3) continue;
                double blend = std::clamp((radius + transition - d) / transition, 0.0, 1.0);
                blend = blend * blend * (3 - 2 * blend);
                const double rolling = (std::sin((x - r.x) * 0.064 + phase) +
                    std::cos((z - r.z) * 0.057 - phase)) * 0.25 + 0.5;
                const double target = def.baseHeight + rolling * def.reliefCells;
                const int height = static_cast<int>(std::round(map.at(x, z).height * (1 - blend) + target * blend));
                replaceSurface(map, table, x, z, height);
                if (d <= radius + transition * 0.45)
                    map.cells[z * map.width + x].biomeIndex = biome;
            }
        r.y = map.topSolid(r.x, r.z);
        map.regions.push_back(std::move(r));
    }
    // Reground existing surface content after the broad mask changes. Interior
    // cave nodes whose supporting floor was replaced do not become buried loot.
    map.nodes.erase(std::remove_if(map.nodes.begin(), map.nodes.end(), [&](PlacedNode& n) {
        const auto& old = oldCells[n.z * map.width + n.x];
        if (n.y == old.height) n.y = map.topSolid(n.x, n.z);
        else if (map.blockAt(n.x, n.y, n.z) != kAir || map.blockAt(n.x, n.y - 1, n.z) == kAir) return true;
        const auto* r = regionAt(map, n.x, n.z);
        if (r) {
            const auto& biome = *table.findBiome(r->biome);
            if (!biome.nodeDensity.count(n.type)) return true;
        }
        n.resourceId = "wnv3_" + n.type + "_" + std::to_string(n.x) + "_" + std::to_string(n.y) + "_" + std::to_string(n.z);
        return false;
    }), map.nodes.end());
    map.packs.erase(std::remove_if(map.packs.begin(), map.packs.end(), [&](MobPack& p) {
        const auto& old = oldCells[p.z * map.width + p.x];
        if (p.y == old.height) p.y = map.topSolid(p.x, p.z);
        else if (map.blockAt(p.x, p.y, p.z) != kAir || map.blockAt(p.x, p.y - 1, p.z) == kAir) return true;
        const auto* r = regionAt(map, p.x, p.z);
        return r && p.biome != r->biome;
    }), map.packs.end());
}

void thinOuterPopulation(WorldMap& map, const tuning::WorldgenTable& table) {
    const auto& p = table.frontierPopulation;
    const double outer = p.outerDistanceM / map.cellSize;
    map.nodes.erase(std::remove_if(map.nodes.begin(), map.nodes.end(), [&](const auto& n) {
        return distanceSquared(n.x, n.z, map.spawnX, map.spawnZ) > outer * outer &&
            cellNoise(map.seed, n.x, n.z, 58001 ^ stableSalt(n.type)) > p.outerNodeKeep;
    }), map.nodes.end());
    map.packs.erase(std::remove_if(map.packs.begin(), map.packs.end(), [&](const auto& pack) {
        return distanceSquared(pack.x, pack.z, map.spawnX, map.spawnZ) > outer * outer &&
            cellNoise(map.seed, pack.x, pack.z, 58003) > p.outerPackKeep;
    }), map.packs.end());
}

void moveProgressionSites(WorldMap& map, const tuning::WorldgenTable& table) {
    const auto walk = surfaceWalk(map, 1);
    auto select = [&](const std::string& biomeId, double minimum, double target, uint32_t salt) {
        std::pair<double, int> best{1e30, -1};
        for (int z = 4; z < map.height - 4; z += 2)
            for (int x = 4; x < map.width - 4; x += 2) {
                if (!supportedFootprint(map, walk, x, z, 1)) continue;
                const double distance = std::sqrt(distanceSquared(x, z, map.spawnX, map.spawnZ)) * map.cellSize;
                if (distance < minimum || distance > target + 35) continue;
                const bool matching = table.biomes[map.at(x, z).biomeIndex].id == biomeId;
                const double score = (matching ? 0 : 10000) + std::abs(distance - target) + cellNoise(map.seed, x, z, salt) * 4;
                if (score < best.first) best = {score, z * map.width + x};
            }
        if (best.second < 0) throw std::runtime_error("worldgen: no reachable progression site " + biomeId);
        return best.second;
    };
    const int gate = select(table.guarantees.gateBiome, table.guarantees.gateMinDistanceM,
                            table.frontierPopulation.gateTargetDistanceM, 58021);
    map.gateX = gate % map.width; map.gateZ = gate / map.width;
    for (auto& l : map.landmarks) {
        const auto it = std::find_if(table.landmarks.begin(), table.landmarks.end(), [&](const auto& d) { return d.id == l.id; });
        if (it == table.landmarks.end()) continue;
        const int at = select(it->biome, it->minDistanceFromSpawnM,
            std::max(it->minDistanceFromSpawnM + 35, 125.0), stableSalt(l.id));
        l.x = at % map.width; l.z = at / map.width;
    }
}

void addRootvaultCave(WorldMap& map, const tuning::WorldgenTable& table) {
    for (auto& region : map.regions) {
        const auto def = std::find_if(table.regions.begin(), table.regions.end(), [&](const auto& d) { return d.id == region.id; });
        if (def == table.regions.end() || !def->cave) continue;
        // An ordinary-width stair descends under a wooded bank. Open ground
        // precedes a roofed chamber; no jump, class or excavation is required.
        const int startX = region.x - 38, z = region.z + 22;
        const int startY = map.topSolid(startX, z);
        for (int step = 0; step <= 20; ++step) {
            const int x = startX + step;
            const int floor = std::max(3, startY - step / 3);
            region.caveApproach.push_back({x, floor, z});
            for (int dz = -3; dz <= 3; ++dz) {
                auto* column = &map.blocks[(static_cast<size_t>(z + dz) * map.width + x) * map.depth];
                column[floor - 1] = kStone;
                const int roof = step < 8 ? map.depth : std::max(floor + 4, map.at(x, z + dz).height - 2);
                for (int y = floor; y < roof; ++y) column[y] = kAir;
                if (step >= 8 && roof < map.depth) column[roof] = kStone;
                if (step < 8) map.cells[(z + dz) * map.width + x].height = floor;
            }
        }
        const int endX = startX + 20, endY = region.caveApproach.back().y;
        for (int dx = -1; dx <= 6; ++dx) for (int dz = -5; dz <= 5; ++dz) {
            if (dx * dx + dz * dz > 38) continue;
            auto* column = &map.blocks[(static_cast<size_t>(z + dz) * map.width + endX + dx) * map.depth];
            column[endY - 1] = kStone;
            for (int y = endY; y < endY + 4; ++y) column[y] = kAir;
            column[endY + 4] = kStone;
        }
        map.nodes.erase(std::remove_if(map.nodes.begin(), map.nodes.end(), [&](const auto& n) {
            return n.x >= startX - 3 && n.x <= endX + 8 && std::abs(n.z - z) <= 8;
        }), map.nodes.end());
        map.packs.erase(std::remove_if(map.packs.begin(), map.packs.end(), [&](const auto& p) {
            return p.x >= startX - 4 && p.x <= endX + 9 && std::abs(p.z - z) <= 9;
        }), map.packs.end());
    }
}

void placeRareSites(WorldMap& map, const tuning::WorldgenTable& table) {
    auto definitions = table.rareSites;
    std::sort(definitions.begin(), definitions.end(), [](const auto& a, const auto& b) { return a.nodeType < b.nodeType; });
    std::set<int> reserved;
    for (const auto& h : map.habitats) reserveApproach(map, h.approach, reserved);
    for (const auto& r : map.regions) {
        reserveApproach(map, r.approach, reserved);
        reserveApproach(map, r.caveApproach, reserved);
    }
    int candidateCount = 0;
    auto place = [&](const tuning::RareSiteDef& def, int ordinal, bool exceptional) {
        const auto walk = surfaceWalk(map, 1);
        std::vector<std::pair<double, int>> candidates;
        for (const auto& r : map.regions) {
            if (std::find(def.regions.begin(), def.regions.end(), r.id) == def.regions.end()) continue;
            const int radius = static_cast<int>((r.radiusM - def.radiusM - 4) / map.cellSize);
            for (int z = r.z - radius; z <= r.z + radius; z += 2)
                for (int x = r.x - radius; x <= r.x + radius; x += 2) {
                    if (distanceSquared(x, z, r.x, r.z) > radius * radius || reserved.count(z * map.width + x) ||
                        !supportedFootprint(map, walk, x, z, 1)) continue;
                    if (table.biomes[map.at(x,z).biomeIndex].id != r.biome) continue;
                    bool occupied = distanceSquared(x, z, map.gateX, map.gateZ) < 225;
                    for (const auto& l : map.landmarks) if (distanceSquared(x,z,l.x,l.z) < 225) occupied = true;
                    for (const auto& h : map.habitats) if (distanceSquared(x,z,h.x,h.z) < (h.radiusM + def.radiusM + 5) * (h.radiusM + def.radiusM + 5)) occupied = true;
                    for (const auto& s : map.rareSites) if (distanceSquared(x,z,s.x,s.z) < def.minimumSpacingM * def.minimumSpacingM) occupied = true;
                    for (const auto& cave : r.caveApproach) if (distanceSquared(x,z,cave.x,cave.z) < 144) occupied = true;
                    if (occupied) continue;
                    // Alternate a resource's suitable regional homes before
                    // falling back, so shared resources cannot occupy every
                    // clearing needed by a region-specific capability.
                    const auto& preferred = def.regions[static_cast<size_t>(ordinal) % def.regions.size()];
                    const double score = (r.id == preferred ? 0 : 2) + cellNoise(map.seed, x, z,
                        def.salt ^ static_cast<uint32_t>(ordinal * 7919) ^ (exceptional ? 58171 : 0));
                    candidates.push_back({score, z * map.width + x});
                }
        }
        std::sort(candidates.begin(), candidates.end());
        candidateCount = static_cast<int>(candidates.size());
        for (const auto& candidate : candidates) {
            const int x = candidate.second % map.width, z = candidate.second / map.width;
            std::vector<SurfacePoint> approach;
            // Pick the working side that can be approached without stepping
            // through the specimen. A fixed western side breaks eastern walks.
            const int workX[] = {-3,0,3,0}, workZ[] = {0,-3,0,3};
            for(int direction=0;direction<4;++direction) {
                const int wx=x+workX[direction],wz=z+workZ[direction];
                if(!supportedFootprint(map,walk,wx,wz,1))continue;
                auto path=approachTo(map,walk,wx,wz);
                bool crosses=false;
                for(const auto& p:path)if(distanceSquared(p.x,p.z,x,z)<=2)crosses=true;
                if(!crosses&&(approach.empty()||path.size()<approach.size()))approach=std::move(path);
            }
            if(approach.empty())continue;
            const auto* region = regionAt(map, x, z);
            if (!region) continue;
            PlacedRareSite site;
            site.id = "rsv3_" + def.nodeType + "_" + (exceptional ? "exceptional_" : "primary_") + std::to_string(ordinal);
            site.resourceType = def.nodeType; site.regionId = region->id;
            site.x=x; site.y=walk.heights[candidate.second]; site.z=z;
            site.radiusM=def.radiusM; site.clueRadiusM=def.clueRadiusM;
            site.exceptional=exceptional;
            site.guarded=exceptional || (ordinal > 0 && cellNoise(map.seed,x,z,58121) > 0.5);
            site.approach=std::move(approach);
            for (auto it=site.approach.rbegin();it!=site.approach.rend();++it) {
                const double d=std::sqrt(distanceSquared(it->x,it->z,x,z));
                if (d>site.clueRadiusM) break;
                if (d>=7 && (site.cluePoints.empty() || distanceSquared(it->x,it->z,site.cluePoints.back().x,site.cluePoints.back().z)>=25))
                    site.cluePoints.push_back(*it);
            }
            std::reverse(site.cluePoints.begin(),site.cluePoints.end());
            if (site.cluePoints.size()<2) continue;
            // A finite work clearing also makes harvesting aftermath readable.
            map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
                return n.siteId.empty() && n.habitatId.empty() && distanceSquared(n.x,n.z,x,z)<def.radiusM*def.radiusM;
            }),map.nodes.end());
            PlacedNode node(def.nodeType,x,site.y,z);
            node.resourceId="wnv3_"+site.id+"_specimen";
            node.siteId=site.id;node.regionId=site.regionId;node.exceptional=exceptional;
            node.unitsOverride=exceptional?def.exceptionalUnits:table.nodeTypes.at(def.nodeType).units;
            map.nodes.push_back(std::move(node));
            reserveApproach(map,site.approach,reserved);
            map.rareSites.push_back(std::move(site));
            return true;
        }
        return false;
    };
    for (const auto& def : definitions) {
        const int count = def.minimumSites + std::min(def.maximumSites-def.minimumSites,
            static_cast<int>(cellNoise(map.seed,0,0,def.salt)*(def.maximumSites-def.minimumSites+1)));
        for (int ordinal=0;ordinal<count;++ordinal)
            if (!place(def,ordinal,false)) throw std::runtime_error("worldgen: no complete rare opportunity for "+def.nodeType+" site "+std::to_string(ordinal)+" candidates "+std::to_string(candidateCount));
    }
    const int exceptionalCount=std::min(table.frontierPopulation.exceptionalSiteMaximum,
        static_cast<int>(cellNoise(map.seed,0,0,58151)*(table.frontierPopulation.exceptionalSiteMaximum+1)));
    for(int ordinal=0;ordinal<exceptionalCount;++ordinal) {
        const size_t start=static_cast<size_t>(cellNoise(map.seed,ordinal,0,58159)*definitions.size())%definitions.size();
        bool placed=false;
        for(size_t offset=0;offset<definitions.size()&&!placed;++offset)
            placed=place(definitions[(start+offset)%definitions.size()],ordinal,true);
        if(!placed) throw std::runtime_error("worldgen: no complete exceptional composition");
    }
}

void protectDiscoveryRoutes(WorldMap& map, const tuning::WorldgenTable& table) {
    const double quiet=table.frontierPopulation.clueQuietRadiusM/map.cellSize;
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& pack) {
        for(const auto& site:map.rareSites) {
            if(distanceSquared(pack.x,pack.z,site.x,site.z)<quiet*quiet)return true;
            for(const auto& clue:site.cluePoints)
                if(distanceSquared(pack.x,pack.z,clue.x,clue.z)<quiet*quiet)return true;
        }
        return false;
    }),map.packs.end());
    // Some optional detours have ordinary biome guards. First opportunities
    // remain quiet; no resource demands an identical elite fight.
    for(const auto& site:map.rareSites) {
        if(!site.guarded)continue;
        const auto* region=regionAt(map,site.x,site.z);
        const auto* biome=region?table.findBiome(region->biome):nullptr;
        if(!biome||biome->packs.empty())continue;
        const auto walk=surfaceWalk(map,1);
        for(int direction=0;direction<4;++direction) {
            const int dx[]={0,1,0,-1},dz[]={1,0,-1,0};
            const int x=site.x+dx[direction]*12,z=site.z+dz[direction]*12;
            if(!map.inBounds(x,z)||!supportedFootprint(map,walk,x,z,1))continue;
            bool clue=false;
            for(const auto& other:map.rareSites) {
                if(distanceSquared(x,z,other.x,other.z)<quiet*quiet)clue=true;
                for(const auto& c:other.cluePoints)if(distanceSquared(x,z,c.x,c.z)<quiet*quiet)clue=true;
            }
            if(clue)continue;
            MobPack pack;pack.x=x;pack.y=map.topSolid(x,z);pack.z=z;
            pack.biome=biome->id;pack.enemies=biome->packs.front();
            if(pack.enemies.size()>3)pack.enemies.resize(3);
            pack.routeX=x;pack.routeZ=z;
            map.packs.push_back(std::move(pack));
            break;
        }
    }
}

void composeFrontierV3(WorldMap& map, const tuning::WorldgenTable& table) {
    if(table.regions.size()!=3||table.rareSites.size()!=5)
        throw std::runtime_error("worldgen: frontier_v3 needs its complete region and rare-site definitions");
    composeRegions(map,table);
    thinOuterPopulation(map,table);
    moveProgressionSites(map,table);
    placeHabitats(map,table);
    addRootvaultCave(map,table);
    const auto walk=surfaceWalk(map,1);
    for(auto& habitat:map.habitats) {
        if(walk.parent[habitat.z*map.width+habitat.x]<0)
            throw std::runtime_error("worldgen: cave interrupted a material habitat route");
        habitat.approach=approachTo(map,walk,habitat.x,habitat.z);
    }
    for(auto& region:map.regions) {
        if(!supportedFootprint(map,walk,region.x,region.z,1)) {
            bool found=false;
            for(int ring=1;ring<=12&&!found;++ring)for(int dz=-ring;dz<=ring&&!found;++dz)for(int dx=-ring;dx<=ring;++dx)
                if(supportedFootprint(map,walk,region.x+dx,region.z+dz,1)) {
                    region.approach=approachTo(map,walk,region.x+dx,region.z+dz);found=true;break;
                }
            if(!found)throw std::runtime_error("worldgen: no reachable regional clearing "+region.id);
        } else region.approach=approachTo(map,walk,region.x,region.z);
        if(!region.caveApproach.empty()) {
            const auto& entrance=region.caveApproach.front();
            if(walk.parent[entrance.z*map.width+entrance.x]<0)
                throw std::runtime_error("worldgen: rootvault cave approach is inaccessible");
            auto surface=approachTo(map,walk,entrance.x,entrance.z);
            surface.insert(surface.end(),region.caveApproach.begin()+1,region.caveApproach.end());
            region.caveApproach=std::move(surface);
        }
    }
    placeRareSites(map,table);
    protectDiscoveryRoutes(map,table);
}
