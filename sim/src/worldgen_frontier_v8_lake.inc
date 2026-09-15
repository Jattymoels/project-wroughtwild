// One basin at a home clearing's outward edge, before finite supply/routes.
double ease(double v);
void reseatSurface(WorldMap&,const tuning::WorldgenTable&,int,int,int);
void composeLake(WorldMap& map,const tuning::WorldgenTable& table) {
    const auto& t=table.lake;
    PlacedLake selected;double best=1e30;int spatial=0,cap=0;
    // First candidates vary angle/radius; the final four use the smallest
    // accepted basin directly outward from each home as deterministic fallback.
    for(int i=0;i<t.candidates+4;++i) {
        const bool fallback=i>=t.candidates;
        const int hi=fallback?i-t.candidates:(i/8+3)%4;
        const auto& home=map.homeSites[hi];
        const double outward=std::atan2(home.z-map.spawnZ,home.x-map.spawnX);
        const double angle=outward+(fallback?0:((i%8)-3.5)*.12);
        const double radius=fallback?t.radiusMinM:t.radiusMinM+(t.radiusMaxM-t.radiusMinM)*cellNoise(map.seed,i,0,85001);
        PlacedLake lake;lake.id="lakev8_0";lake.homeId=home.id;
        lake.angle=angle;lake.radiusM=radius;lake.aspect=t.aspect;lake.surfaceY=home.y-.6;
        lake.x=home.x+static_cast<int>(std::round(std::cos(angle)*(radius+home.radiusM+t.homeGapM)));
        lake.z=home.z+static_cast<int>(std::round(std::sin(angle)*(radius+home.radiusM+t.homeGapM)));
        const int extent=static_cast<int>(std::ceil(radius+t.blendM));
        bool safe=true;double change=0;
        for(const auto& other:map.homeSites)if(other.id!=home.id&&std::hypot(lake.x-other.x,lake.z-other.z)<radius+t.blendM+other.radiusM) safe=false;
        for(const auto& region:map.regions)if(std::hypot(lake.x-region.x,lake.z-region.z)<radius+t.blendM+region.radiusM+20)safe=false;
        for(const auto& mark:map.landmarks)if(std::hypot(lake.x-mark.x,lake.z-mark.z)<radius+t.blendM+12)safe=false;
        if(std::hypot(lake.x-map.gateX,lake.z-map.gateZ)<radius+t.blendM+15)safe=false;
        if(std::hypot(lake.x-map.spawnX,lake.z-map.spawnZ)<radius+t.blendM+30)safe=false;
        if(!safe){++spatial;continue;}
        for(int z=lake.z-extent;z<=lake.z+extent&&safe;++z)for(int x=lake.x-extent;x<=lake.x+extent;++x) {
            if(!map.inBounds(x,z)){safe=false;break;}
            const double d=std::hypot(x-lake.x,z-lake.z);
            if(d>radius)continue;
            const int old=map.at(x,z).height;
            // Do not bury any entrance, or break through a cave roof. Deep caves
            // below this narrow edited cap retain every original block.
            const int low=std::max(1,static_cast<int>(lake.surfaceY-t.depthM)-1);
            for(int y=std::min(low,old-1);y<old;++y)if(map.blockAt(x,y,z)==kAir){
                // A retained cave/opening away from the swimming line becomes
                // an uncarved island/bank, never a sealed entrance.
                const double u=(x-lake.x)*std::cos(angle)+(z-lake.z)*std::sin(angle);
                const double v=-(x-lake.x)*std::sin(angle)+(z-lake.z)*std::cos(angle);
                if(std::abs(v)<3 || d<6)safe=false;
                else change+=200;
                break;
            }
            if(!safe)break;
            if(d<radius)change+=std::abs(old-lake.surfaceY);
        }
        if(!safe)++cap;
        if(safe&&change<best){best=change;selected=lake;}
        if(fallback&&!selected.id.empty())break;
    }
    if(selected.id.empty())throw std::runtime_error("worldgen: no safe lake candidate or home fallback; spatial="+std::to_string(spatial)+" roof="+std::to_string(cap));
    auto& lake=selected;
    const int extent=static_cast<int>(std::ceil(lake.radiusM+t.blendM));
    lake.minX=lake.x-extent;lake.minZ=lake.z-extent;lake.width=extent*2+1;lake.height=lake.width;
    lake.beds.resize(lake.width*lake.height,255);
    const auto old=map.cells;
    const double cs=std::cos(lake.angle),sn=std::sin(lake.angle);
    for(int z=lake.minZ;z<lake.minZ+lake.height;++z)for(int x=lake.minX;x<lake.minX+lake.width;++x) {
        const double dx=x+.5-lake.x,dz=z+.5-lake.z,u=dx*cs+dz*sn,v=(-dx*sn+dz*cs)/lake.aspect;
        const double a=std::atan2(v,u);
        const double edge=lake.radiusM*(1+t.variation*std::sin(a*3+cellNoise(map.seed,0,0,85003)*6.2831853));
        const double d=std::hypot(u,v),inset=edge-d;
        if(inset < -t.blendM)continue;
        bool core=false;for(const auto& home:map.homeSites)if(std::hypot(x-home.x,z-home.z)<=home.radiusM+3)core=true;
        if(core)continue;
        // Surface at rim is dry and level with the adjacent home. A 10 m shelf
        // then descends into a shallow 4 m bowl, quantised only once.
        const double target=lake.surfaceY+.6-(t.depthM+.6)*ease(inset/(t.shoreM+8));
        const double blend=ease((inset+t.blendM)/t.blendM);
        const int height=static_cast<int>(std::round(old[z*map.width+x].height*(1-blend)+target*blend));
        // Preserve cave voids below the new top. Outside the basin, an existing
        // opening wins over shore blending rather than getting filled/sealed.
        bool opening=map.topSolid(x,z)!=old[z*map.width+x].height;
        for(int y=std::min(height,old[z*map.width+x].height)-1;y<old[z*map.width+x].height;++y)
            if(map.blockAt(x,y,z)==kAir)opening=true;
        if(opening)continue;
        auto* column=&map.blocks[(static_cast<size_t>(z)*map.width+x)*map.depth];
        const int oldHeight=old[z*map.width+x].height;
        for(int y=std::min(height,oldHeight);y<std::max(height,oldHeight);++y)column[y]=y>=height?kAir:kDirt;
        column[height-1]=kSurface;
        map.cells[z*map.width+x].height=height;
        if(inset>0 && height<lake.surfaceY)lake.beds[(z-lake.minZ)*lake.width+x-lake.minX]=height;
    }
    map.lakes.push_back(lake);
    // Remove only ordinary terrestrial rolls in the new footprint. Guaranteed
    // finite supplies/discoveries are composed afterward against dry routes.
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](auto& n){
        if(n.y!=old[n.z*map.width+n.x].height)return false;
        if(lake.bedAt(n.x,n.z)<lake.surfaceY)return true;
        n.y=map.topSolid(n.x,n.z);return false;
    }),map.nodes.end());
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](auto& p){
        if(p.biome=="cave")return false;
        if(lake.bedAt(p.x,p.z)<lake.surfaceY)return true;
        p.y=map.topSolid(p.x,p.z);return false;
    }),map.packs.end());
}
