// V6 habitat composition keeps the frozen V2 rules, adding only home reservations.
void placeWideHabitats(WorldMap& map, const tuning::WorldgenTable& table) {
    auto definitions = table.habitats;
    std::sort(definitions.begin(), definitions.end(), [](const auto& a, const auto& b) { return a.id < b.id; });
    std::set<int> reserved;
    for(const auto& home:map.homeSites) reserveApproach(map,home.approach,reserved);
    for (const auto& def : definitions) {
        const auto walk = frozen_frontier::surfaceWalk(map, def.maximumSurfaceStep);
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
                // Reserve each complete build pad, not only its centre. The
                // habitat circle contains all finite cluster nodes and its art.
                for(const auto& home:map.homeSites) {
                    const double separation=(def.radiusM+home.radiusM+3)/map.cellSize;
                    if(distanceSquared(x,z,home.x,home.z)<separation*separation)occupied=true;
                }
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
            auto nodes = frozen_frontier::resourceCluster(map, walk, def, x, z, trialReserved);
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

// Native V6 home choices and complete hostile-route buffer. Nothing is timed immunity.
void composeHomeSites(WorldMap& map,const tuning::WorldgenTable& table) {
    const auto& opening=table.wideFrontier;
    map.starterQuietRadiusM=opening.quietRadiusM;
    map.hostileBoundaryM=opening.hostileBoundaryM;
    map.starterFirstSiegeNight=opening.firstSiegeNight;
    const double turn=cellNoise(map.seed,0,0,61031)*6.283185307179586;
    for(int i=0;i<opening.homeCount;++i) {
        const double angle=turn+i*6.283185307179586/opening.homeCount;
        PlacedHomeSite home;
        home.id="homev6_"+std::to_string(i);
        home.x=map.spawnX+static_cast<int>(std::round(std::cos(angle)*opening.homeDistanceM/map.cellSize));
        home.z=map.spawnZ+static_cast<int>(std::round(std::sin(angle)*opening.homeDistanceM/map.cellSize));
        home.y=map.topSolid(home.x,home.z);home.radiusM=opening.homeRadiusM;
        const int extent=static_cast<int>(std::ceil((opening.homeRadiusM+opening.homeSkirtM)/map.cellSize));
        for(int dz=-extent;dz<=extent;++dz)for(int dx=-extent;dx<=extent;++dx) {
            const double radius=std::hypot(dx,dz)*map.cellSize;
            if(radius>opening.homeRadiusM+opening.homeSkirtM)continue;
            double weight=std::clamp((opening.homeRadiusM+opening.homeSkirtM-radius)/opening.homeSkirtM,0.0,1.0);
            weight=weight*weight*(3-2*weight);
            const int x=home.x+dx,z=home.z+dz;
            const int level=static_cast<int>(std::round(map.at(x,z).height*(1-weight)+home.y*weight));
            replaceSurface(map,table,x,z,level);
        }
        map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](PlacedNode& n){
            const double d=std::hypot(n.x-home.x,n.z-home.z)*map.cellSize;
            if(d<home.radiusM+2)return true;
            if(d<home.radiusM+opening.homeSkirtM)n.y=map.topSolid(n.x,n.z);
            return false;
        }),map.nodes.end());
        for(auto& p:map.packs)if(std::hypot(p.x-home.x,p.z-home.z)*map.cellSize<home.radiusM+opening.homeSkirtM)p.y=map.topSolid(p.x,p.z);
        map.homeSites.push_back(std::move(home));
    }
    // Compose finite supply at supported edges, leaving each building centre free.
    // No dedicated item, discovery gate, station or new gathering rule is added.
    const auto walk=surfaceWalk(map,1);
    std::set<int> reserved;
    for(auto& home:map.homeSites) {
        if(!supportedFootprint(map,walk,home.x,home.z,1))throw std::runtime_error("worldgen: home is unreachable "+home.id);
        home.approach=approachTo(map,walk,home.x,home.z);
        reserveApproach(map,home.approach,reserved);
    }
    const std::vector<std::pair<std::string,int>> needs={{"tree",opening.homeTrees},{"boulder",opening.homeBoulders},{"stone_seam",opening.homeStone},{"iron_vein",opening.homeIron}};
    for(const auto& home:map.homeSites)for(const auto& need:needs)for(int slot=0;slot<need.second;++slot) {
        std::pair<double,int> best{1e30,-1};
        const int radius=static_cast<int>(home.radiusM+opening.homeSkirtM+8);
        for(int z=home.z-radius;z<=home.z+radius;z+=2)for(int x=home.x-radius;x<=home.x+radius;x+=2) {
            const double d=std::hypot(x-home.x,z-home.z)*map.cellSize;
            if(d<home.radiusM+7 || d>radius || std::hypot(x-map.spawnX,z-map.spawnZ)*map.cellSize>opening.quietRadiusM-4)continue;
            if(reserved.count(z*map.width+x)||!supportedFootprint(map,walk,x,z,1))continue;
            bool blocked=false;
            for(const auto& n:map.nodes)if(distanceSquared(x,z,n.x,n.z)<9){blocked=true;break;}
            for(const auto& h:map.homeSites)if(distanceSquared(x,z,h.x,h.z)<(h.radiusM+3)*(h.radiusM+3))blocked=true;
            if(blocked)continue;
            const double score=cellNoise(map.seed,x,z,stableSalt(home.id+need.first+std::to_string(slot)))+d*.002;
            if(score<best.first)best={score,z*map.width+x};
        }
        if(best.second<0)throw std::runtime_error("worldgen: missing homeward supply "+home.id+need.first);
        PlacedNode node{need.first,best.second%map.width,walk.heights[best.second],best.second/map.width};
        node.resourceId="wnv6_"+home.id+"_"+need.first+"_"+std::to_string(slot);
        map.nodes.push_back(std::move(node));
    }
}

double segmentSpawnDistance(const WorldMap& map,int ax,int az,int bx,int bz) {
    const double dx=bx-ax,dz=bz-az,denominator=dx*dx+dz*dz;
    const double t=denominator>0?std::clamp(((map.spawnX-ax)*dx+(map.spawnZ-az)*dz)/denominator,0.0,1.0):0;
    return std::hypot(ax+t*dx-map.spawnX,az+t*dz-map.spawnZ)*map.cellSize;
}

void finishWideFrontier(WorldMap& map,const tuning::WorldgenTable& table) {
    const double boundary=table.wideFrontier.hostileBoundaryM;
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& p){
        return !p.grazer&&std::hypot(p.x-map.spawnX,p.z-map.spawnZ)*map.cellSize<boundary;
    }),map.packs.end());
    // A den outside the valley is insufficient: diagonal foreign routes can
    // cut through it. Query local buckets, then validate each complete segment.
    const double reach=table.guarantees.patrolLengthM*1.5/map.cellSize;
    const int side=std::max(1,static_cast<int>(std::ceil(reach)));
    std::map<std::pair<int,int>,std::vector<size_t>> buckets;
    for(size_t i=0;i<map.packs.size();++i)buckets[{map.packs[i].x/side,map.packs[i].z/side}].push_back(i);
    for(auto& p:map.packs) {
        p.hasForeign=false;p.foreignX=0;p.foreignZ=0;p.foreignBiome.clear();
        if(!p.patrols||p.grazer)continue;
        if(segmentSpawnDistance(map,p.x,p.z,p.routeX,p.routeZ)<boundary){p.patrols=false;p.routeX=p.x;p.routeZ=p.z;continue;}
        double best=reach;size_t bestIndex=map.packs.size();
        const int cx=p.x/side,cz=p.z/side;
        for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx) {
            const auto bucket=buckets.find({cx+dx,cz+dz});if(bucket==buckets.end())continue;
            for(const auto i:bucket->second){const auto& other=map.packs[i];
                if(&other==&p||other.grazer||other.biome==p.biome||other.biome=="cave")continue;
                const double distance=std::hypot(p.x-other.x,p.z-other.z);
                if(distance<=4 || distance>best || (distance==best&&i>=bestIndex))continue;
                if(segmentSpawnDistance(map,p.x,p.z,other.x,other.z)<boundary)continue;
                best=distance;bestIndex=i;
            }
        }
        if(bestIndex<map.packs.size()){const auto& other=map.packs[bestIndex];p.hasForeign=true;p.foreignX=other.x;p.foreignZ=other.z;p.foreignBiome=other.biome;}
    }
    // Final geography already includes caves, ruins and trace shoulders. Read
    // fresh routes after every edit; no later terrain pass may invalidate them.
    const auto walk=surfaceWalk(map,1);
    for(auto& home:map.homeSites) {
        if(!supportedFootprint(map,walk,home.x,home.z,1))throw std::runtime_error("worldgen: final home route lost support "+home.id);
        home.approach=approachTo(map,walk,home.x,home.z);
    }
    for(const auto& n:map.nodes)if(n.resourceId.rfind("wnv6_homev6_",0)==0) {
        bool usable=false;
        for(const auto& offset:std::vector<std::pair<int,int>>{{2,0},{-2,0},{0,2},{0,-2}}) {
            const int x=n.x+offset.first,z=n.z+offset.second;
            if(map.inBounds(x,z)&&walk.parent[z*map.width+x]>=0&&std::abs(walk.heights[z*map.width+x]-n.y)<=1)usable=true;
        }
        if(!usable)throw std::runtime_error("worldgen: home supply lacks a reachable work position "+n.resourceId);
    }
}
