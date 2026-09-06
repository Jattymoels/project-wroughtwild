// Cataclysm successor composition. Frozen v3 remains separate;
// broad regional masks are composed before the complete, finite rare sites.
// This file deliberately does not alter either older profile's generator.

frozen_frontier::SurfaceWalk surfaceWalk(const WorldMap& map,int maxStep) {
    auto walk=frozen_frontier::surfaceWalk(map,maxStep);
    // Authored walls line the margins. All native paths use the same central
    // three-metre strip as the Godot ruin kit, including unvisited ruins.
    for(const auto& ruin:map.ruins){
        const int half=static_cast<int>(std::ceil(std::max(ruin.widthM,ruin.depthM)*0.5/map.cellSize));
        for(int dz=-half;dz<=half;++dz)for(int dx=-half;dx<=half;++dx){
            const int lateral=(ruin.rotationQuarters%2==0)?dx:dz;
            if(std::abs(lateral)<2)continue;
            walk.clear[(ruin.z+dz)*map.width+ruin.x+dx]=false;
        }
    }
    std::fill(walk.parent.begin(),walk.parent.end(),-1);
    const int start=map.spawnZ*map.width+map.spawnX;
    walk.clear[start]=true;walk.parent[start]=start;
    std::queue<int> pending;pending.push(start);
    const int dx[]={1,0,-1,0},dz[]={0,1,0,-1};
    while(!pending.empty()){
        const int at=pending.front();pending.pop();
        for(int d=0;d<4;++d){
            const int x=at%map.width+dx[d],z=at/map.width+dz[d];
            if(!map.inBounds(x,z))continue;
            const int next=z*map.width+x;
            if(!walk.clear[next]||walk.parent[next]>=0||std::abs(walk.heights[next]-walk.heights[at])>maxStep)continue;
            walk.parent[next]=at;pending.push(next);
        }
    }
    return walk;
}

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

std::string regionalProperty(const std::string& id) {
    return id == "rootvault_wildwood" ? "growth_tension" :
        id == "lantern_fen" ? "light_pressure" : "charge_attraction";
}

double segmentDistance(double x, double z, const SurfacePoint& a, const SurfacePoint& b) {
    const double dx=b.x-a.x, dz=b.z-a.z, length=dx*dx+dz*dz;
    const double t=length>0?std::clamp(((x-a.x)*dx+(z-a.z)*dz)/length,0.0,1.0):0;
    return std::hypot(x-a.x-t*dx,z-a.z-t*dz);
}

void addTrace(WorldMap& map, const tuning::WorldgenTable& table, const PlacedImpact& from,
              const SurfacePoint& end, const std::string& toId, const std::string& id, double bend) {
    PlacedLeyline line;
    line.id=id; line.fromImpactId=from.id; line.toImpactId=toId;
    line.regionId=from.regionId; line.property=regionalProperty(from.regionId);
    line.widthM=table.cataclysm.traceWidthM; line.influenceRadiusM=table.cataclysm.traceInfluenceM;
    const double dx=end.x-from.x, dz=end.z-from.z, distance=std::max(1.0,std::hypot(dx,dz));
    double nx=-dz/distance,nz=dx/distance;
    if(nx*((from.x+end.x)*0.5-map.spawnX)+nz*((from.z+end.z)*0.5-map.spawnZ)<0){nx=-nx;nz=-nz;}
    const int count=std::max(3,static_cast<int>(std::ceil(table.cataclysm.traceSegments*std::min(1.0,distance/220))));
    for(int i=0;i<=count;++i){
        const double t=static_cast<double>(i)/count, arc=std::sin(t*3.141592653589793)*bend;
        const int x=std::clamp(static_cast<int>(std::round(from.x+dx*t+nx*arc)),2,map.width-3);
        const int z=std::clamp(static_cast<int>(std::round(from.z+dz*t+nz*arc)),2,map.height-3);
        line.points.push_back({x,map.topSolid(x,z),z});
        if(i<count){const double roll=cellNoise(map.seed,i,0,stableSalt(id));line.exposure.push_back(roll<0.16?0:roll<0.44?1:2);}
    }
    map.leylines.push_back(std::move(line));
}

void composeTraces(WorldMap& map,const tuning::WorldgenTable& table) {
    for(size_t i=0;i<map.impacts.size();++i){
        const auto& a=map.impacts[i]; const auto& b=map.impacts[(i+1)%map.impacts.size()];
        addTrace(map,table,a,{b.x,b.y,b.z},b.id,"lyv4_"+a.regionId+"_"+b.regionId,table.cataclysm.traceBendM);
    }
    // Exposed traces leave shallow broad drainage/fused channels. No physics,
    // damage or infinite resource is implied by these geographical scars.
    std::vector<float> cuts(map.cells.size(),0);
    for(const auto& line:map.leylines)for(size_t i=1;i<line.points.size();++i){
        if(line.exposure[i-1]!=2)continue;
        const auto& a=line.points[i-1];const auto& b=line.points[i];
        const int spread=static_cast<int>(std::ceil(line.influenceRadiusM/map.cellSize));
        for(int z=std::max(1,std::min(a.z,b.z)-spread);z<=std::min(map.height-2,std::max(a.z,b.z)+spread);++z)
            for(int x=std::max(1,std::min(a.x,b.x)-spread);x<=std::min(map.width-2,std::max(a.x,b.x)+spread);++x){
                if(std::hypot(x-map.spawnX,z-map.spawnZ)*map.cellSize<table.guarantees.farRadiusM+5)continue;
                const double d=segmentDistance(x,z,a,b)*map.cellSize;
                const float value=static_cast<float>(std::max(0.0,1-d/line.influenceRadiusM));
                cuts[z*map.width+x]=std::max(cuts[z*map.width+x],value);
            }
    }
    for(int z=1;z<map.height-1;++z)for(int x=1;x<map.width-1;++x)
        if(cuts[z*map.width+x]>0.55f && map.topSolid(x,z)==map.at(x,z).height)
            replaceSurface(map,table,x,z,map.at(x,z).height-1);
}

void updateAugmentation(WorldMap& map,const tuning::WorldgenTable& table) {
    map.augmentationField.assign(map.cells.size(),0);
    auto mark=[&](int x,int z,double value){
        const double calm=std::clamp((std::hypot(x-map.spawnX,z-map.spawnZ)*map.cellSize-table.guarantees.nearRadiusM-3)/20,0.0,1.0);
        auto& cell=map.augmentationField[z*map.width+x];
        cell=std::max(cell,static_cast<float>(std::clamp(value*calm,0.0,1.0)));
    };
    for(auto& a:map.impacts){
        a.y=map.topSolid(a.x,a.z);const int radius=static_cast<int>(std::ceil(a.influenceRadiusM/map.cellSize));
        for(int z=std::max(0,a.z-radius);z<=std::min(map.height-1,a.z+radius);++z)
            for(int x=std::max(0,a.x-radius);x<=std::min(map.width-1,a.x+radius);++x){
                const double d=std::hypot(x-a.x,z-a.z)*map.cellSize;
                mark(x,z,std::pow(std::max(0.0,1-d/a.influenceRadiusM),0.65));
            }
    }
    for(auto& line:map.leylines){
        for(auto& p:line.points)p.y=map.topSolid(p.x,p.z);
        for(size_t i=1;i<line.points.size();++i){
            const auto& a=line.points[i-1];const auto& b=line.points[i];
            const int spread=static_cast<int>(std::ceil(line.influenceRadiusM/map.cellSize));
            const double strength=line.exposure[i-1]==0?0.18:line.exposure[i-1]==1?0.35:0.7;
            for(int z=std::max(0,std::min(a.z,b.z)-spread);z<=std::min(map.height-1,std::max(a.z,b.z)+spread);++z)
                for(int x=std::max(0,std::min(a.x,b.x)-spread);x<=std::min(map.width-1,std::max(a.x,b.x)+spread);++x)
                    mark(x,z,strength*std::max(0.0,1-segmentDistance(x,z,a,b)*map.cellSize/line.influenceRadiusM));
        }
    }
}

void composeRegions(WorldMap& map, const tuning::WorldgenTable& table) {
    auto definitions = table.regions;
    std::sort(definitions.begin(), definitions.end(), [](const auto& a, const auto& b) { return a.id < b.id; });
    const auto oldCells = map.cells;
    const double rotation = cellNoise(map.seed, 0, 0, 56001) * 6.283185307179586;
    for (size_t index = 0; index < definitions.size(); ++index) {
        const auto& def = definitions[index];
        const double angle = rotation + index * 6.283185307179586 / definitions.size() +
            (cellNoise(map.seed,0,0,def.salt^63001)-0.5)*table.cataclysm.regionAngleJitter*2;
        const double radius = def.radiusM / map.cellSize;
        const double transition = def.transitionM / map.cellSize;
        const int margin = static_cast<int>(std::ceil(radius + transition + 4));
        PlacedRegion r;
        r.id = def.id; r.biome = def.biome;
        r.x = std::clamp(static_cast<int>(map.width / 2 + std::cos(angle) * def.distanceM / map.cellSize), margin, map.width - margin - 1);
        r.z = std::clamp(static_cast<int>(map.height / 2 + std::sin(angle) * def.distanceM / map.cellSize), margin, map.height - margin - 1);
        r.radiusM = def.radiusM; r.transitionM = def.transitionM;
        r.impactId="imv4_"+r.id; r.augmentationProperty=regionalProperty(r.id);
        PlacedImpact impact;
        impact.id=r.impactId;impact.regionId=r.id;
        impact.kind=r.id=="glasswind_uplands"?"primary_scar":"buried_fragment";
        impact.x=r.x+static_cast<int>(std::cos(angle)*table.cataclysm.impactOffsetM/map.cellSize);
        impact.z=r.z+static_cast<int>(std::sin(angle)*table.cataclysm.impactOffsetM/map.cellSize);
        impact.radiusM=impact.kind=="primary_scar"?table.cataclysm.majorRadiusM:table.cataclysm.secondaryRadiusM;
        impact.influenceRadiusM=table.cataclysm.influenceRadiusM;
        impact.impactDirection={std::cos(rotation+0.7),-0.7,std::sin(rotation+0.7)};
        const int biome = regionBiome(table, def.biome);
        const double phase = cellNoise(map.seed, r.x, r.z, def.salt) * 6.283185307179586;
        for (int z = r.z - margin + 2; z <= r.z + margin - 2; ++z)
            for (int x = r.x - margin + 2; x <= r.x + margin - 2; ++x) {
                const double azimuth=std::atan2(z-r.z,x-r.x);
                const double d = std::sqrt(distanceSquared(x, z, r.x, r.z)) -
                    std::sin(azimuth*3+phase)*table.cataclysm.regionWarpM/map.cellSize;
                if (d >= radius + transition) continue;
                // The starter clearing and its guaranteed nearby supplies stay
                // ordinary heartland even when a seed's spawn shifts off centre.
                const double spawnD = std::sqrt(distanceSquared(x, z, map.spawnX, map.spawnZ));
                if (spawnD < table.guarantees.nearRadiusM / map.cellSize + 3) continue;
                double blend = std::clamp((radius + transition - d) / transition, 0.0, 1.0);
                blend = blend * blend * (3 - 2 * blend);
                const double rolling = (std::sin((x - r.x) * 0.064 + phase) +
                    std::cos((z - r.z) * 0.057 - phase)) * 0.25 + 0.5;
                const double impactD=std::hypot(x-impact.x,z-impact.z)*map.cellSize;
                const double bowl=std::pow(std::max(0.0,1-impactD/impact.radiusM),2)*table.cataclysm.craterDepthM;
                const double rim=std::exp(-std::pow((impactD-impact.radiusM)/(impact.radiusM*0.42),2))*
                    table.cataclysm.rimHeightM*(0.65+0.35*std::cos(azimuth-angle));
                const double ridge=std::sin((x-r.x)*std::cos(angle)*0.045+(z-r.z)*std::sin(angle)*0.045+phase);
                const double target = def.baseHeight + rolling * def.reliefCells + ridge*1.5 - bowl + rim;
                const int height = static_cast<int>(std::round(map.at(x, z).height * (1 - blend) + target * blend));
                replaceSurface(map, table, x, z, height);
                if (d <= radius + transition * 0.45)
                    map.cells[z * map.width + x].biomeIndex = biome;
            }
        r.y = map.topSolid(r.x, r.z);
        map.regions.push_back(std::move(r));
        map.impacts.push_back(std::move(impact));
    }
    composeTraces(map,table);
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
        n.resourceId = "wnv4_" + n.type + "_" + std::to_string(n.x) + "_" + std::to_string(n.y) + "_" + std::to_string(n.z);
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

bool ruinFootprint(const PlacedRuin& ruin,int x,int z,double extra=0) {
    return std::abs(x-ruin.x)<=ruin.widthM*0.5+extra && std::abs(z-ruin.z)<=ruin.depthM*0.5+extra;
}

void placeRuinFoundations(WorldMap& map,const tuning::WorldgenTable& table) {
    auto definitions=table.rareSites;
    std::sort(definitions.begin(),definitions.end(),[](const auto& a,const auto& b){return a.nodeType<b.nodeType;});
    for(size_t ordinal=0;ordinal<=definitions.size();++ordinal){
        // Reserve the gate's more constrained near-neighbour first; regional
        // dwellings then select among thousands of valid core cells.
        const bool threshold=ordinal==0;
        const std::string resource=threshold?"forge":definitions[ordinal-1].nodeType;
        const PlacedRegion* region=nullptr;
        if(threshold){
            for(const auto& r:map.regions)if(!region||distanceSquared(r.x,r.z,map.gateX,map.gateZ)<distanceSquared(region->x,region->z,map.gateX,map.gateZ))region=&r;
        }else for(const auto& r:map.regions)if(r.id==definitions[ordinal-1].regions.front())region=&r;
        if(!region)throw std::runtime_error("worldgen: ruin lacks host "+resource);
        const auto walk=surfaceWalk(map,1);
        std::pair<double,int> best{1e30,-1};
        const int half=static_cast<int>(std::ceil(std::max(table.cataclysm.ruinWidthM,table.cataclysm.ruinDepthM)*0.5/map.cellSize));
        const int skirt=static_cast<int>(std::ceil(table.cataclysm.ruinSkirtM/map.cellSize));
        const int cx=threshold?map.gateX:region->x,cz=threshold?map.gateZ:region->z;
        const int radius=threshold?static_cast<int>(table.cataclysm.thresholdSearchM/map.cellSize):static_cast<int>(region->radiusM*0.78/map.cellSize);
        for(int z=std::max(half+skirt+2,cz-radius);z<=std::min(map.height-half-skirt-3,cz+radius);z+=2)
            for(int x=std::max(half+skirt+2,cx-radius);x<=std::min(map.width-half-skirt-3,cx+radius);x+=2){
                const double radial=std::hypot(x-cx,z-cz)*map.cellSize;
                if(radial>radius || !supportedFootprint(map,walk,x,z,1))continue;
                if(!threshold&&table.biomes[map.at(x,z).biomeIndex].id!=region->biome)continue;
                if(std::hypot(x-map.spawnX,z-map.spawnZ)*map.cellSize<table.guarantees.farRadiusM+half+skirt)continue;
                bool blocked=distanceSquared(x,z,map.gateX,map.gateZ)<(half+skirt+3)*(half+skirt+3);
                for(const auto& h:map.habitats)if(std::hypot(x-h.x,z-h.z)<h.radiusM+half+skirt+3)blocked=true;
                for(const auto& l:map.landmarks)if(std::hypot(x-l.x,z-l.z)<half+skirt+5)blocked=true;
                for(const auto& r:map.ruins)if(std::hypot(x-r.x,z-r.z)<2*(half+skirt)+5)blocked=true;
                for(const auto& r:map.regions)for(const auto& p:r.caveApproach)
                    if(std::abs(x-p.x)<=half+skirt+7&&std::abs(z-p.z)<=half+skirt+7)blocked=true;
                if(blocked)continue;
                int low=map.depth,high=0;
                for(int dz=-half-skirt;dz<=half+skirt&&!blocked;++dz)for(int dx=-half-skirt;dx<=half+skirt;++dx){
                    const int at=(z+dz)*map.width+x+dx;
                    if(walk.heights[at]!=map.at(x+dx,z+dz).height){blocked=true;break;}
                    if(std::abs(dx)<=half&&std::abs(dz)<=half){low=std::min(low,walk.heights[at]);high=std::max(high,walk.heights[at]);}
                }
                if(blocked||high-low>table.cataclysm.foundationReliefCells)continue;
                const double towardHome=((x-cx)*(map.spawnX-cx)+(z-cz)*(map.spawnZ-cz))/std::max(1.0,std::hypot(map.spawnX-cx,map.spawnZ-cz));
                const double score=std::abs(radial-(threshold?table.cataclysm.thresholdDistanceM:table.cataclysm.regionalRuinDistanceM))*0.4-towardHome*0.08+(high-low)*0.6+
                    cellNoise(map.seed,x,z,stableSalt("ruv4_"+resource))*3;
                if(score<best.first)best={score,z*map.width+x};
            }
        if(best.second<0)throw std::runtime_error("worldgen: no complete ruin foundation "+resource);
        PlacedRuin ruin;
        ruin.id="ruv4_"+resource;ruin.regionId=region->id;
        ruin.kind=threshold?"forge_threshold":resource=="thrumroot"?"root_dwelling":
            resource=="lanternheart"?"reed_homestead":resource=="ventlung"?"pressure_cistern":
            resource=="stormglass"?"quarry_shelter":"herder_waystation";
        ruin.augmentation=regionalProperty(region->id);ruin.impactId=region->impactId;
        ruin.linkedSiteId=threshold?"":"rsv4_"+resource+"_primary_0";
        ruin.x=best.second%map.width;ruin.z=best.second/map.width;
        ruin.widthM=table.cataclysm.ruinWidthM;ruin.depthM=table.cataclysm.ruinDepthM;
        ruin.y=map.topSolid(ruin.x,ruin.z);
        const auto impact=std::find_if(map.impacts.begin(),map.impacts.end(),[&](const auto& p){return p.id==ruin.impactId;});
        const double vx=ruin.x-impact->x,vz=ruin.z-impact->z,length=std::max(1.0,std::hypot(vx,vz));
        ruin.damageDirection={vx/length,0,vz/length};
        const int hx=map.spawnX-ruin.x,hz=map.spawnZ-ruin.z;
        ruin.rotationQuarters=std::abs(hz)>=std::abs(hx)?(hz>=0?0:2):(hx>=0?1:3);
        const int ex[]={0,1,0,-1},ez[]={1,0,-1,0};
        ruin.entrance={ruin.x+ex[ruin.rotationQuarters]*(half-1),ruin.y,ruin.z+ez[ruin.rotationQuarters]*(half-1)};
        const auto before=map.cells;
        for(int dz=-half-skirt;dz<=half+skirt;++dz)for(int dx=-half-skirt;dx<=half+skirt;++dx){
            const int x=ruin.x+dx,z=ruin.z+dz;
            const double outside=std::max(0,std::max(std::abs(dx),std::abs(dz))-half);
            double blend=std::clamp(1-outside/skirt,0.0,1.0);blend=blend*blend*(3-2*blend);
            replaceSurface(map,table,x,z,static_cast<int>(std::round(map.at(x,z).height*(1-blend)+ruin.y*blend)));
            if(std::abs(dx)<=half&&std::abs(dz)<=half)ruin.foundation.push_back({x,ruin.y,z});
        }
        map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](PlacedNode& n){
            if(ruinFootprint(ruin,n.x,n.z,2))return n.habitatId.empty()&&n.siteId.empty();
            if(n.y==before[n.z*map.width+n.x].height)n.y=map.topSolid(n.x,n.z);
            return map.blockAt(n.x,n.y,n.z)!=kAir||map.blockAt(n.x,n.y-1,n.z)==kAir;
        }),map.nodes.end());
        map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](MobPack& p){
            if(ruinFootprint(ruin,p.x,p.z,3))return true;
            if(p.y==before[p.z*map.width+p.x].height)p.y=map.topSolid(p.x,p.z);
            return map.blockAt(p.x,p.y,p.z)!=kAir||map.blockAt(p.x,p.y-1,p.z)==kAir;
        }),map.packs.end());
        ruin.leylineId="lyv4_branch_"+resource;
        addTrace(map,table,*impact,{ruin.x,ruin.y,ruin.z},"",ruin.leylineId,table.cataclysm.traceBendM*0.15);
        map.ruins.push_back(std::move(ruin));
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
    for(const auto& ruin:map.ruins)reserveApproach(map,ruin.approach,reserved);
    for(const auto& impact:map.impacts)reserveApproach(map,impact.approach,reserved);
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
                    for (const auto& ruin : map.ruins) if(ruinFootprint(ruin,x,z,def.radiusM+2))occupied=true;
                    for (const auto& impact : map.impacts) if(std::hypot(x-impact.x,z-impact.z)<impact.radiusM+def.radiusM)occupied=true;
                    if (occupied) continue;
                    // Alternate a resource's suitable regional homes before
                    // falling back, so shared resources cannot occupy every
                    // clearing needed by a region-specific capability.
                    const auto& preferred = def.regions[static_cast<size_t>(ordinal) % def.regions.size()];
                    double composition=0;
                    if(ordinal==0&&!exceptional)for(const auto& ruin:map.ruins)
                        if(ruin.linkedSiteId=="rsv4_"+def.nodeType+"_primary_0")
                            composition=std::abs(std::hypot(x-ruin.x,z-ruin.z)*map.cellSize-table.cataclysm.discoveryDistanceM)*0.1;
                    const double influence=map.augmentationField.empty()?0:map.augmentationField[z*map.width+x];
                    const double score = (r.id == preferred ? 0 : 20) + composition - influence*0.25 + cellNoise(map.seed, x, z,
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
            site.id = "rsv4_" + def.nodeType + "_" + (exceptional ? "exceptional_" : "primary_") + std::to_string(ordinal);
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
            node.resourceId="wnv4_"+site.id+"_specimen";
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

std::vector<SurfacePoint> localRoute(const WorldMap& map,const frozen_frontier::SurfaceWalk& walk,
                                      const SurfacePoint& from,const SurfacePoint& to) {
    std::vector<int> parent(map.cells.size(),-1);
    const int start=from.z*map.width+from.x,goal=to.z*map.width+to.x;
    std::queue<int> pending;pending.push(start);parent[start]=start;
    const int dx[]={1,0,-1,0},dz[]={0,1,0,-1};
    while(!pending.empty()&&parent[goal]<0){
        const int at=pending.front();pending.pop();
        for(int d=0;d<4;++d){
            const int x=at%map.width+dx[d],z=at/map.width+dz[d];
            if(!map.inBounds(x,z))continue;
            const int next=z*map.width+x;
            if(!walk.clear[next]||parent[next]>=0||std::abs(walk.heights[next]-walk.heights[at])>1)continue;
            parent[next]=at;pending.push(next);
        }
    }
    if(parent[goal]<0)throw std::runtime_error("worldgen: ruin discovery route disconnected");
    std::vector<SurfacePoint> result;
    for(int at=goal;;at=parent[at]){result.push_back({at%map.width,walk.heights[at],at/map.width});if(at==start)break;}
    std::reverse(result.begin(),result.end());return result;
}

void finishHistoryRoutes(WorldMap& map,const tuning::WorldgenTable& table) {
    const auto walk=surfaceWalk(map,1);
    for(auto& ruin:map.ruins){
        if(walk.parent[ruin.entrance.z*map.width+ruin.entrance.x]<0)
            throw std::runtime_error("worldgen: inaccessible ruin "+ruin.id);
        ruin.approach=approachTo(map,walk,ruin.entrance.x,ruin.entrance.z);
        SurfacePoint target{map.gateX,map.topSolid(map.gateX,map.gateZ),map.gateZ};
        if(!ruin.linkedSiteId.empty()){
            const auto site=std::find_if(map.rareSites.begin(),map.rareSites.end(),[&](const auto& s){return s.id==ruin.linkedSiteId;});
            if(site==map.rareSites.end())throw std::runtime_error("worldgen: ruin linked find absent");
            target=site->approach.back();
        }
        ruin.discoveryRoute=localRoute(map,walk,ruin.entrance,target);
    }
    // Remove only unprotected ordinary props from the actual final walking
    // strips. Finite rare specimens and starter/habitat supplies keep their IDs.
    const double clearance=table.cataclysm.pathClearanceM*0.5+1;
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(!n.siteId.empty()||!n.habitatId.empty()||std::hypot(n.x-map.spawnX,n.z-map.spawnZ)*map.cellSize<=table.guarantees.farRadiusM)return false;
        for(const auto& r:map.ruins)for(const auto& p:r.discoveryRoute)
            if(std::hypot(n.x-p.x,n.z-p.z)*map.cellSize<clearance)return true;
        return false;
    }),map.nodes.end());
    for(auto& n:map.nodes)if(n.siteId.empty()&&n.habitatId.empty())
        n.resourceId="wnv4_"+n.type+"_"+std::to_string(n.x)+"_"+std::to_string(n.y)+"_"+std::to_string(n.z);
    for(auto& r:map.regions)r.y=map.topSolid(r.x,r.z);
    updateAugmentation(map,table);
}

void composeFrontierV4(WorldMap& map, const tuning::WorldgenTable& table) {
    if(table.regions.size()!=3||table.rareSites.size()!=5)
        throw std::runtime_error("worldgen: frontier_v4 needs its complete region and rare-site definitions");
    composeRegions(map,table);
    thinOuterPopulation(map,table);
    moveProgressionSites(map,table);
    placeHabitats(map,table);
    addRootvaultCave(map,table);
    placeRuinFoundations(map,table);
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(!n.habitatId.empty())return false;
        for(const auto& a:map.impacts)if(distanceSquared(n.x,n.z,a.x,a.z)<64)return true;
        return false;
    }),map.nodes.end());
    const auto walk=surfaceWalk(map,1);
    for(auto& ruin:map.ruins){
        if(walk.parent[ruin.entrance.z*map.width+ruin.entrance.x]<0)
            throw std::runtime_error("worldgen: ruin foundation has no ordinary entrance "+ruin.id);
        ruin.approach=approachTo(map,walk,ruin.entrance.x,ruin.entrance.z);
    }
    for(auto& impact:map.impacts){
        int selected=-1;
        for(int ring=0;ring<=12&&selected<0;++ring)for(int dz=-ring;dz<=ring&&selected<0;++dz)for(int dx=-ring;dx<=ring;++dx){
            if(supportedFootprint(map,walk,impact.x+dx,impact.z+dz,1)){selected=(impact.z+dz)*map.width+impact.x+dx;break;}
        }
        if(selected<0)throw std::runtime_error("worldgen: impact has no reachable reveal");
        impact.approach=approachTo(map,walk,selected%map.width,selected/map.width);
    }
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
    updateAugmentation(map,table);
    placeRareSites(map,table);
    protectDiscoveryRoutes(map,table);
    finishHistoryRoutes(map,table);
}
