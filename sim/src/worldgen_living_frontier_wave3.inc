// Frozen LF-3 composition. No terrain/node/source-stock edits. The ordinary
// V6 base is finished first; only four finite hosts and visible exteriors follow.
using frozen_frontier::SurfaceWalk;
using frozen_frontier::distanceSquared;
using frozen_frontier::approachTo;

SurfaceWalk rootedWalk(const WorldMap& map, const SurfaceWalk& base, int x, int z) {
    auto walk = base;
    std::fill(walk.parent.begin(), walk.parent.end(), -1);
    const int start = z*map.width+x;
    if (!walk.clear[start]) throw std::runtime_error("LF3: blocked route origin");
    walk.parent[start]=start;
    std::queue<int> todo; todo.push(start);
    while (!todo.empty()) {
        const int at=todo.front(); todo.pop();
        for (const auto& d : std::vector<std::pair<int,int>>{{1,0},{0,1},{-1,0},{0,-1}}) {
            const int nx=at%map.width+d.first, nz=at/map.width+d.second;
            if (!map.inBounds(nx,nz)) continue;
            const int next=nz*map.width+nx;
            if (walk.parent[next]>=0 || !walk.clear[next] || std::abs(walk.heights[at]-walk.heights[next])>1) continue;
            walk.parent[next]=at; todo.push(next);
        }
    }
    return walk;
}

bool clearSite(const WorldMap& map, const SurfaceWalk& walk, int x, int z, int radius, int variation) {
    if (!map.inBounds(x-radius,z-radius) || !map.inBounds(x+radius,z+radius)) return false;
    const int centre=z*map.width+x;
    if (walk.parent[centre]<0) return false;
    for (int dz=-radius;dz<=radius;++dz) for (int dx=-radius;dx<=radius;++dx) {
        const int at=(z+dz)*map.width+x+dx;
        if (!walk.clear[at] || std::abs(walk.heights[at]-walk.heights[centre])>variation) return false;
    }
    for (const auto& h:map.homeSites) if (std::hypot(x-h.x,z-h.z)<h.radiusM+20) return false;
    for (const auto& h:map.habitats) if (std::hypot(x-h.x,z-h.z)<h.radiusM+8) return false;
    for (const auto& r:map.ruins) if (std::hypot(x-r.x,z-r.z)<std::max(r.widthM,r.depthM)+12) return false;
    for (const auto& r:map.rareSites) if (std::hypot(x-r.x,z-r.z)<r.radiusM+12) return false;
    for (const auto& p:map.pressurePockets) if (std::hypot(x-p.x,z-p.z)<p.radiusM+20) return false;
    for (const auto& l:map.landmarks) if (std::hypot(x-l.x,z-l.z)<20) return false;
    return std::hypot(x-map.gateX,z-map.gateZ)>20;
}

void compose(WorldMap& map, const tuning::LivingFrontierTable& rules) {
    const auto walk=frozen_frontier::surfaceWalk(map,1);
    for (const auto& def:rules.hosts) {
        const auto& home=map.homeSites.at(def.homeIndex);
        // Frozen published sources lie eight metres along each clear home margin.
        const int sx=home.x+8, sz=home.z;
        const auto sourceWalk=rootedWalk(map,walk,sx,sz);
        std::pair<double,int> best{1e30,-1};
        const int reach=static_cast<int>(rules.hostSourceMaximumM);
        for (int z=sz-reach;z<=sz+reach;z+=2) for (int x=sx-reach;x<=sx+reach;x+=2) {
            const double ds=std::hypot(x-sx,z-sz), spawn=std::hypot(x-map.spawnX,z-map.spawnZ);
            if (ds<rules.hostSourceMinimumM || ds>rules.hostSourceMaximumM || spawn<rules.hostMinimumSpawnM) continue;
            if (!clearSite(map,sourceWalk,x,z,2,0)) continue;
            bool occupied=false;
            for (const auto& h:map.frontierHosts) if (std::hypot(x-h.at.x,z-h.at.z)<rules.hostSeparationM) occupied=true;
            if (occupied) continue;
            const double score=ds+(spawn-rules.hostMinimumSpawnM)*.3+cellNoise(map.seed,x,z,frozen_frontier::stableSalt(def.id));
            if (score<best.first) best={score,z*map.width+x};
        }
        if (best.second<0) throw std::runtime_error("LF3: no clear isolated host for "+def.id);
        PlacedFrontierHost h;
        h.id=def.id; h.sourceId=def.sourceId; h.enemyId=def.enemyId; h.influence=def.influence;
        h.at={best.second%map.width,walk.heights[best.second],best.second/map.width};
        h.approach=approachTo(map,walk,h.at.x,h.at.z);
        h.sourceRoute=approachTo(map,sourceWalk,h.at.x,h.at.z);
        h.habits={{h.at.x-2,h.at.y,h.at.z},{h.at.x+2,h.at.y,h.at.z}};
        map.frontierHosts.push_back(h);
    }
    for (const auto& def:rules.labs) {
        const auto region=std::find_if(map.regions.begin(),map.regions.end(),[&](const auto& r){return r.id==def.regionId;});
        if (region==map.regions.end()) throw std::runtime_error("LF3: missing lab region");
        const double distance=std::hypot(region->x-map.spawnX,region->z-map.spawnZ);
        const int tx=region->x+static_cast<int>((map.spawnX-region->x)*region->radiusM/distance);
        const int tz=region->z+static_cast<int>((map.spawnZ-region->z)*region->radiusM/distance);
        std::pair<double,int> best{1e30,-1};
        const int reach=static_cast<int>(rules.labSearchM);
        for (int z=tz-reach;z<=tz+reach;z+=2) for (int x=tx-reach;x<=tx+reach;x+=2) {
            if (std::hypot(x-tx,z-tz)>reach || std::hypot(x-map.spawnX,z-map.spawnZ)<rules.hostMinimumSpawnM || !clearSite(map,walk,x,z,4,1)) continue;
            bool occupied=false;
            for (const auto& h:map.frontierHosts) if (std::hypot(x-h.at.x,z-h.at.z)<rules.encounterClearRadiusM+12) occupied=true;
            for (const auto& l:map.laboratories) if (std::hypot(x-l.at.x,z-l.at.z)<40) occupied=true;
            if (occupied) continue;
            const double score=distanceSquared(x,z,tx,tz)+cellNoise(map.seed,x,z,frozen_frontier::stableSalt(def.id));
            if (score<best.first) best={score,z*map.width+x};
        }
        if (best.second<0) throw std::runtime_error("LF3: no supported laboratory for "+def.id);
        PlacedLaboratory lab;
        lab.id=def.id;lab.label=def.label;lab.regionId=def.regionId;
        lab.at={best.second%map.width,walk.heights[best.second],best.second/map.width};
        lab.widthM=rules.labWidthM;lab.depthM=rules.labDepthM;lab.heightM=rules.labHeightM;
        // The exterior approach ends outside the sealed front wall (+Z).
        lab.approach=approachTo(map,walk,lab.at.x,lab.at.z+4);
        map.laboratories.push_back(lab);
        if (def.regionId!="rootvault_wildwood")
            map.futureTransformations.push_back({def.regionId=="lantern_fen"?"retained_fen":"excited_uplands",def.regionId,{region->x,region->y,region->z},rules.transformRadiusM});
    }
    // LF3-R1: placement above is published and must not consume corrected
    // routes. Only after every shell is final can we derive physical walks.
    // Include the existing ruin margins, then the full sealed lab footprint
    // (foundation/door trim included) inflated for an ordinary player capsule.
    auto physical=wide_frontier::surfaceWalk(map,1);
    // A centre-height path can skim a cave lip or the side of a steep shelf.
    // Retain a supported neighbouring band so a normal body can turn at each
    // metre waypoint without falling off the authored walking surface.
    for (int z=1;z<map.height-1;++z) for (int x=1;x<map.width-1;++x) {
        const int at=z*map.width+x;
        if (!physical.clear[at]) continue;
        for (int dz=-1;dz<=1;++dz) for (int dx=-1;dx<=1;++dx) {
            const int n=(z+dz)*map.width+x+dx;
            if (physical.heights[n]!=map.at(x+dx,z+dz).height || std::abs(physical.heights[n]-physical.heights[at])>1)
                physical.clear[at]=false;
        }
    }
    for (const auto& shell:map.laboratories) {
        const double rx=(shell.widthM*.5+rules.labRouteClearanceM)/map.cellSize;
        const double rz=(shell.depthM*.5+rules.labRouteClearanceM)/map.cellSize;
        for (int dz=-static_cast<int>(std::ceil(rz));dz<=std::ceil(rz);++dz)
            for (int dx=-static_cast<int>(std::ceil(rx));dx<=std::ceil(rx);++dx)
                if (std::abs(dx)<=rx && std::abs(dz)<=rz && map.inBounds(shell.at.x+dx,shell.at.z+dz))
                    physical.clear[(shell.at.z+dz)*map.width+shell.at.x+dx]=false;
    }
    physical=rootedWalk(map,physical,map.spawnX,map.spawnZ);
    const auto route=[&](const SurfaceWalk& from,int x,int z) {
        if (from.parent[z*map.width+x]<0) throw std::runtime_error("LF3: no physical approach");
        return approachTo(map,from,x,z);
    };
    for (auto& shell:map.laboratories) shell.approach=route(physical,shell.at.x,shell.at.z+4);
    for (size_t i=0;i<map.frontierHosts.size();++i) {
        auto& h=map.frontierHosts[i];
        const auto& home=map.homeSites.at(rules.hosts[i].homeIndex);
        h.approach=route(physical,h.at.x,h.at.z);
        h.sourceRoute=route(rootedWalk(map,physical,home.x+8,home.z),h.at.x,h.at.z);
    }
    const auto& source=map.homeSites.at(0);
    const auto trailWalk=rootedWalk(map,physical,source.x+8,source.z);
    const auto& lab=map.laboratories.front();
    map.laboratoryTrail=route(trailWalk,lab.at.x,lab.at.z+4);
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& p){
        for (const auto& h:map.frontierHosts)
            if (std::hypot(p.x-h.at.x,p.z-h.at.z)<rules.encounterClearRadiusM) return true;
        for (const auto& l:map.laboratories)
            if (std::hypot(p.x-l.at.x,p.z-l.at.z)<rules.encounterClearRadiusM) return true;
        return false;
    }),map.packs.end());
    for (const auto& h:map.frontierHosts) {
        MobPack p; p.frontierHostId=h.id; p.enemies={h.enemyId}; p.x=h.at.x;p.y=h.at.y;p.z=h.at.z;
        p.grazer=h.influence=="white" || h.influence=="green";
        p.biome="living_frontier_habitat"; map.packs.push_back(p);
    }
}
