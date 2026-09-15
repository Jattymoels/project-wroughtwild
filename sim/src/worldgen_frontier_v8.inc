// RF-05 independent lake successor; published V7 composition remains frozen.
// Reuse published discovery rules after changing physical land, not visual mesh offsets.
constexpr double tau=6.283185307179586;
double ease(double v) { v=std::clamp(v,0.0,1.0); return v*v*(3-2*v); }

// Keep deep caves intact. Only the changed roof/soil cap is reseated; openings
// outside this bounded heartland treatment retain the existing cave behaviour.
void reseatSurface(WorldMap& map,const tuning::WorldgenTable& table,int x,int z,int height) {
    const int old=map.at(x,z).height;
    height=std::clamp(height,2,map.depth-3);
    if(old==height)return;
    auto& cell=map.cells[z*map.width+x];cell.height=height;
    const int floor=std::max(1,std::min(old,height)-table.strata.dirtDepth-1);
    auto* column=&map.blocks[(static_cast<size_t>(z)*map.width+x)*map.depth];
    for(int y=floor;y<std::max(old,height);++y)
        column[y]=y>=height?kAir:y==height-1?kSurface:y>=height-1-table.strata.dirtDepth?kDirt:kStone;
}

void reground(WorldMap& map,const std::vector<Cell>& old) {
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](PlacedNode& n){
        if(n.y==old[n.z*map.width+n.x].height)n.y=map.topSolid(n.x,n.z);
        return map.blockAt(n.x,n.y,n.z)!=kAir||map.blockAt(n.x,n.y-1,n.z)==kAir;
    }),map.nodes.end());
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](MobPack& p){
        if(p.y==old[p.z*map.width+p.x].height)p.y=map.topSolid(p.x,p.z);
        return map.blockAt(p.x,p.y,p.z)!=kAir||map.blockAt(p.x,p.y-1,p.z)==kAir;
    }),map.packs.end());
}

void composeReclaimedLand(WorldMap& map,const tuning::WorldgenTable& table) {
    const auto old=map.cells;
    const auto& rf=table.reclaimedFrontier;
    const double phase=cellNoise(map.seed,0,0,73011)*tau;
    const auto woodland=std::find_if(map.regions.begin(),map.regions.end(),[](const auto& r){return r.id=="rootvault_wildwood";});
    const auto impact=std::find_if(map.impacts.begin(),map.impacts.end(),[](const auto& i){return i.regionId=="rootvault_wildwood";});
    for(int z=1;z<map.height-1;++z)for(int x=1;x<map.width-1;++x) {
        const auto& biome=table.biomes[map.at(x,z).biomeIndex].id;
        if(biome!="meadow"&&biome!="forest")continue;
        const double d=std::hypot(x-map.spawnX,z-map.spawnZ);
        const double heart=ease((table.wideFrontier.quietRadiusM+35-d)/45)*ease((d-24)/24);
        double delta=heart*rf.landformAmplitudeM*(.6*std::sin((x-map.spawnX)*tau/rf.landformWavelengthM+phase)+.4*std::cos((z-map.spawnZ)*tau/(rf.landformWavelengthM*1.3)-phase));
        if(woodland!=map.regions.end()&&impact!=map.impacts.end()&&d>table.wideFrontier.quietRadiusM) {
            const double ix=x-impact->x,iz=z-impact->z;
            const double dist=std::hypot(ix,iz),a=std::atan2(iz,ix);
            // A weathered, asymmetric shoulder, not another crater. Existing
            // primary scar and fen/upland geology use their original treatment.
            delta+=rf.impactShoulderM*std::exp(-std::pow((dist-impact->radiusM*1.7)/48,2))*(.55+.45*std::sin(a*2+phase))*ease((d-table.wideFrontier.quietRadiusM)/25);
        }
        if(std::abs(delta)>.05)reseatSurface(map,table,x,z,static_cast<int>(std::round(map.at(x,z).height+delta)));
    }
    reground(map,old);
}

// Twice-filter the underlying heights before quantising them once. Filtering
// after integer rounding leaves short two-step faces beside otherwise valid
// native paths (the RF-03 ordinary walk found one on the overlook approach).
void softenHomeMargins(WorldMap& map,const tuning::WorldgenTable& table) {
    const int radius=static_cast<int>(table.reclaimedFrontier.approachSmoothingM/map.cellSize);
    std::vector<double> levels;levels.reserve(map.cells.size());
    for(const auto& cell:map.cells)levels.push_back(cell.height);
    std::vector<uint8_t> changed(map.cells.size(),0);
    for(int pass=0;pass<2;++pass){
        auto next=levels;
        const int extent=static_cast<int>(table.wideFrontier.quietRadiusM+20);
        for(int z=map.spawnZ-extent;z<=map.spawnZ+extent;++z)for(int x=map.spawnX-extent;x<=map.spawnX+extent;++x){
            bool margin=false,core=false;
            for(const auto& home:map.homeSites){
                const double d=std::hypot(x-home.x,z-home.z)*map.cellSize;
                core|=d<=home.radiusM;
                margin|=d<home.radiusM+table.reclaimedFrontier.homeBlendM+table.reclaimedFrontier.extensionM+12;
            }
            if(!margin||core||std::hypot(x-map.spawnX,z-map.spawnZ)<26)continue;
            double sum=0;int weight=0;
            for(int dz=-radius;dz<=radius;++dz)for(int dx=-radius;dx<=radius;++dx){
                const int w=(radius+1-std::abs(dx))*(radius+1-std::abs(dz));
                sum+=levels[(z+dz)*map.width+x+dx]*w;weight+=w;
            }
            next[z*map.width+x]=sum/weight;changed[z*map.width+x]=1;
        }
        levels=std::move(next);
    }
    for(size_t i=0;i<levels.size();++i)if(changed[i])
        reseatSurface(map,table,i%map.width,i/map.width,static_cast<int>(std::round(levels[i])));
}

void composeReclaimedHomes(WorldMap& map,const tuning::WorldgenTable& table) {
    const auto& opening=table.wideFrontier;
    const auto& rf=table.reclaimedFrontier;
    map.starterQuietRadiusM=opening.quietRadiusM;
    map.hostileBoundaryM=opening.hostileBoundaryM;
    map.starterFirstSiegeNight=opening.firstSiegeNight;
    const auto woodland=std::find_if(map.regions.begin(),map.regions.end(),[](const auto& r){return r.id=="rootvault_wildwood";});
    const double turn=std::atan2(woodland->z-map.spawnZ,woodland->x-map.spawnX);
    const auto old=map.cells;
    for(int i=0;i<opening.homeCount;++i) {
        const double angle=turn+i*tau/opening.homeCount+(cellNoise(map.seed,i,0,73021)-.5)*2*rf.homeAngleJitter;
        const double distance=opening.homeDistanceM+(cellNoise(map.seed,i,0,73022)-.5)*2*rf.homeDistanceJitterM;
        const double nx=std::cos(angle),nz=std::sin(angle);
        PlacedHomeSite home;
        // Existing helper namespaces keep stable local IDs; the profile/seed
        // owns them, so no V6 save ever interprets these as its old positions.
        home.id="homev6_"+std::to_string(i);
        home.x=map.spawnX+static_cast<int>(std::round(nx*distance));
        home.z=map.spawnZ+static_cast<int>(std::round(nz*distance));
        home.y=map.topSolid(home.x,home.z)+(i==1?static_cast<int>(rf.overlookLiftM):i==2?2:0);
        home.radiusM=opening.homeRadiusM;
        const int extent=static_cast<int>(std::ceil(home.radiusM+rf.extensionM+rf.homeBlendM+16));
        for(int dz=-extent;dz<=extent;++dz)for(int dx=-extent;dx<=extent;++dx) {
            const int x=home.x+dx,z=home.z+dz;
            if(!map.inBounds(x,z)||std::hypot(x-map.spawnX,z-map.spawnZ)<26)continue;
            // u points to the enclosing bank; -u opens toward the valley.
            const double u=dx*nx+dz*nz,v=-dx*nz+dz*nx;
            const double bank=rf.bankHeightM*std::exp(-std::pow((u-32)/18,2)-std::pow(v/42,2));
            const double valley=rf.overlookLiftM*.7*std::exp(-std::pow((u+39)/25,2)-std::pow(v/39,2));
            double surrounding=map.at(x,z).height+(i==0||i==2?bank:0)-(i==1?valley:0);
            // Asymmetric elongated cores dissolve into smooth skirts. The full
            // radius-14 circle is level, with extra space in one useful direction.
            const double extension=(i==2?rf.extensionM: i==3?rf.extensionM*.8:rf.extensionM*.45)*(v>0?1:.35);
            const double effective=std::hypot(u,v*home.radiusM/(home.radiusM+extension));
            const double feather=rf.homeBlendM*(1+.12*std::sin(std::atan2(v,u)*3+angle));
            const double blend=ease((home.radiusM+feather-effective)/feather);
            const double target=surrounding*(1-blend)+home.y*blend;
            reseatSurface(map,table,x,z,static_cast<int>(std::round(target)));
            // A seeded woodland crescent encloses the pocket while its valley
            // entrance stays open. No extra biome or fixed decorative prefab.
            if(i==0&&std::hypot(u,v)<rf.woodlandRadiusM+5*std::sin(std::atan2(v,u)*3+angle)&&u>-12&&std::hypot(u,v)>home.radiusM+3)
                map.cells[z*map.width+x].biomeIndex=regionBiome(table,"forest");
        }
        map.homeSites.push_back(home);
    }
    softenHomeMargins(map,table);
    composeLake(map,table);
    reground(map,old);
    // Home grading preceded the lake, so finish regrounding before deciding
    // whether an ordinary surface roll stands in the new water volume.
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        for(const auto& lake:map.lakes)if(lake.bedAt(n.x,n.z)<lake.surfaceY&&n.y>=lake.bedAt(n.x,n.z))return true;
        return false;
    }),map.nodes.end());
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& p){
        for(const auto& lake:map.lakes)if(lake.bedAt(p.x,p.z)<lake.surfaceY&&p.y>=lake.bedAt(p.x,p.z))return true;
        return false;
    }),map.packs.end());
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(n.y!=map.at(n.x,n.z).height)return false;
        for(const auto& home:map.homeSites)if(std::hypot(n.x-home.x,n.z-home.z)<home.radiusM+3)return true;
        return false;
    }),map.nodes.end());
    // Frame the pocket with actual finite pine sources. Their mature adopted
    // canopy gives the opening height; core and approach remain reserved.
    const auto& pocket=map.homeSites.front();
    const int extent=static_cast<int>(rf.woodlandRadiusM+6);
    for(int z=pocket.z-extent;z<=pocket.z+extent;z+=2)for(int x=pocket.x-extent;x<=pocket.x+extent;x+=2) {
        if(table.biomes[map.at(x,z).biomeIndex].id!="forest"||std::hypot(x-pocket.x,z-pocket.z)<pocket.radiusM+9||cellNoise(map.seed,x,z,73030)>=rf.woodlandDensity*4)continue;
        bool occupied=false;
        for(const auto& n:map.nodes)if(distanceSquared(x,z,n.x,n.z)<36){occupied=true;break;}
        for(const auto& home:map.homeSites)if(distanceSquared(x,z,home.x,home.z)<(home.radiusM+7)*(home.radiusM+7))occupied=true;
        const int y=map.topSolid(x,z);
        if(occupied||y!=map.at(x,z).height)continue;
        map.nodes.push_back({"pine",x,y,z});
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

// Reuse the established finite discovery sequence after all home land edits.
void composeFrontierV6Landscape(WorldMap& map, const tuning::WorldgenTable& table) {
    if(table.regions.size()!=3||table.rareSites.size()!=5)
        throw std::runtime_error("worldgen: frontier_v6 needs its complete region and rare-site definitions");
    composeRegions(map,table);
    composeReclaimedLand(map,table);
    // Ordinary rolls follow the final region, at the same bounded outer density.
    repopulateRegionResources(map,table);
    composeReclaimedHomes(map,table);
    moveProgressionSites(map,table);
    placeWideHabitats(map,table);
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
