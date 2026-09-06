#define main previous_frontier_test_main
#include "test_strange_frontier.cpp"
#undef main
#include <chrono>
#include <unordered_set>

namespace {
#include "worldgen_history.inc"
uint64_t pressureHash(const worldgen::WorldMap& m) {
    uint64_t h=historyFingerprint(m);
    auto add=[&](const std::string& s){for(unsigned char c:s)h=(h^c)*1099511628211ull;h=(h^255)*1099511628211ull;};
    auto point=[&](const auto& p){add(std::to_string(p.x));add(std::to_string(p.y));add(std::to_string(p.z));};
    for(const auto& p:m.pressurePockets){add(p.id);add(p.ruinId);add(p.impactId);add(p.leylineId);add(p.linkedSiteId);add(p.origin);add(std::to_string(p.radiusM));add(std::to_string(p.accidental));point(p);point(p.workPosition);for(const auto& q:p.approach)point(q);}
    return h;
}
uint64_t wideHash(const worldgen::WorldMap& m) {
    uint64_t h=pressureHash(m);
    auto add=[&](const std::string& s){for(unsigned char c:s)h=(h^c)*1099511628211ull;h=(h^255)*1099511628211ull;};
    add(std::to_string(m.starterQuietRadiusM));add(std::to_string(m.hostileBoundaryM));add(std::to_string(m.starterFirstSiegeNight));
    for(const auto& home:m.homeSites){add(home.id);add(std::to_string(home.x));add(std::to_string(home.y));add(std::to_string(home.z));add(std::to_string(home.radiusM));for(const auto& p:home.approach){add(std::to_string(p.x));add(std::to_string(p.y));add(std::to_string(p.z));}}
    return h;
}
void historical(tuning::Tuning t) {
    const uint64_t seeds[]={1,7,24,91};
    const uint64_t expected[][4]={
        {1899602153114217418ull,736845089599793829ull,7709451517322904450ull,2672371686718130021ull},
        {5430446987841818078ull,3258464633623945865ull,10270373463809211055ull,15565090014744201037ull},
        {12362207930465321087ull,14231361409912523888ull,4253842255980360217ull,8552760223992271840ull},
        {2777892313851358114ull,3704407159615029765ull,74627671584911170ull,16539691791317643557ull},
        {5479175655291314931ull,14276052722601302738ull,6663142495560963078ull,16852491459354940353ull}};
    const std::string profiles[]={"legacy_v1","frontier_v2","frontier_v3","frontier_v4","frontier_v5"};
    t.worldgen.map.widthCells=999;t.worldgen.regions.clear();t.worldgen.habitats.clear();t.worldgen.biomes.clear();t.worldgen.rareSites.clear();t.worldgen.wideFrontier.quietRadiusM=999;
    for(int p=0;p<5;++p)for(int i=0;i<4;++i){const auto m=worldgen::generateProfile(t,seeds[i],profiles[p]);
        const auto hash=p==4?pressureHash(m):p==3?historyFingerprint(m):completeFingerprint(m);
        check(hash==expected[p][i],"historical profile changed "+profiles[p]+" seed "+std::to_string(seeds[i]));
        check(m.homeSites.empty()&&m.starterQuietRadiusM==0&&m.starterFirstSiegeNight==0,"V6 opening retrofitted into old geography");
    }
    std::cout<<"WIDE_HISTORY 20 complete profile/seed fingerprints preserved"<<std::endl;
}
int64_t nodeKey(const worldgen::WorldMap& m,int x,int y,int z){return (static_cast<int64_t>(z)*m.width+x)*m.depth+y;}
void clearRoute(const worldgen::WorldMap& m,const std::vector<worldgen::SurfacePoint>& path,const std::unordered_set<int64_t>& occupied,bool fromSpawn=true,bool cave=false){
    check(!path.empty(),"missing route");
    if(fromSpawn)check(path.front().x==m.spawnX&&path.front().z==m.spawnZ,"route starts away from spawn");
    for(size_t i=0;i<path.size();++i){const auto& p=path[i];
        check(m.inBounds(p.x,p.z)&&m.blockAt(p.x,p.y-1,p.z)!=worldgen::kAir&&m.blockAt(p.x,p.y,p.z)==worldgen::kAir&&m.blockAt(p.x,p.y+1,p.z)==worldgen::kAir,"unsupported route");
        if(!cave)check(m.topSolid(p.x,p.z)==p.y,"surface path enters roof");
        if(i)check(std::abs(p.x-path[i-1].x)+std::abs(p.z-path[i-1].z)==1&&std::abs(p.y-path[i-1].y)<=1,"route needs jump");
        for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)if(dx*dx+dz*dz<=1)
            check(!occupied.count(nodeKey(m,p.x+dx,p.y,p.z+dz)),"resource blocks a route");
    }
}
double segmentDistance(const worldgen::WorldMap& m,int ax,int az,int bx,int bz){
    const double vx=bx-ax,vz=bz-az,length=vx*vx+vz*vz;
    const double t=length>0?std::clamp(((m.spawnX-ax)*vx+(m.spawnZ-az)*vz)/length,0.0,1.0):0;
    return std::hypot(ax+vx*t-m.spawnX,az+vz*t-m.spawnZ)*m.cellSize;
}
void wide(const tuning::Tuning& t,uint64_t seed,bool repeat) {
    const auto begin=std::chrono::steady_clock::now();
    const auto m=worldgen::generateProfile(t,seed,"frontier_v6");
    const double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-begin).count();
    check(m.width==1024&&m.height==1024&&m.depth==96&&m.cellSize==1,"V6 escaped accepted volume");
    check(m.homeSites.size()==4&&m.starterQuietRadiusM==150&&m.hostileBoundaryM>=190&&m.starterFirstSiegeNight==3,"quiet starter metadata");
    check(m.regions.size()==3&&m.habitats.size()==3&&m.ruins.size()==6&&m.pressurePockets.size()==1,"missing existing world loop");
    check(m.impacts.size()==4&&m.leylines.size()==10,"history content multiplied");
    check(std::hypot(m.gateX-m.spawnX,m.gateZ-m.spawnZ)*m.cellSize>=t.worldgen.guarantees.gateMinDistanceM,"gate fallback moved progression into the opening");
    std::set<std::string> ids;
    std::unordered_set<int64_t> occupied;
    for(const auto& n:m.nodes){
        check(ids.insert(n.resourceId).second,"duplicate resource ID");
        check(m.blockAt(n.x,n.y,n.z)==worldgen::kAir&&m.blockAt(n.x,n.y-1,n.z)!=worldgen::kAir,"buried/floating resource "+n.resourceId);
        occupied.insert(nodeKey(m,n.x,n.y,n.z));
    }
    // Independently flood the quiet valley, excluding actual source footprints.
    // Every home supply must be workable from this connected starter ground.
    std::vector<uint8_t> reached(m.cells.size(),0);
    std::queue<int> frontier;frontier.push(m.spawnZ*m.width+m.spawnX);reached[frontier.front()]=1;
    while(!frontier.empty()) {
        const int current=frontier.front();frontier.pop();const int cx=current%m.width,cz=current/m.width;
        const int previous=m.topSolid(cx,cz);
        for(const auto& step:std::vector<std::pair<int,int>>{{1,0},{-1,0},{0,1},{0,-1}}){const int x=cx+step.first,z=cz+step.second;
            if(!m.inBounds(x,z)||std::hypot(x-m.spawnX,z-m.spawnZ)>m.starterQuietRadiusM)continue;
            const int cell=z*m.width+x;if(reached[cell])continue;const int y=m.topSolid(x,z);
            if(std::abs(y-previous)>1||m.blockAt(x,y+1,z)!=worldgen::kAir)continue;
            bool blocked=false;for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)if(dx*dx+dz*dz<=1&&occupied.count(nodeKey(m,x+dx,y,z+dz)))blocked=true;
            if(!blocked){reached[cell]=1;frontier.push(cell);}
        }
    }
    for(const auto& home:m.homeSites){
        clearRoute(m,home.approach,occupied);
        check(home.approach.back().x==home.x&&home.approach.back().z==home.z,"home arrival mismatch");
        for(int dz=-int(home.radiusM);dz<=int(home.radiusM);++dz)for(int dx=-int(home.radiusM);dx<=int(home.radiusM);++dx)if(dx*dx+dz*dz<=home.radiusM*home.radiusM){
            check(m.topSolid(home.x+dx,home.z+dz)==home.y,"home build ground not supported/level");
            check(!occupied.count(nodeKey(m,home.x+dx,home.y,home.z+dz)),"resource occupies home building ground");
        }
        const std::map<std::string,int> supply={{"tree",4},{"boulder",3},{"stone_seam",2},{"iron_vein",1}};
        for(const auto& [type,count]:supply){int found=0;
            for(const auto& n:m.nodes)if(n.type==type&&n.resourceId.rfind("wnv6_"+home.id+"_",0)==0){++found;check(std::hypot(n.x-m.spawnX,n.z-m.spawnZ)<m.starterQuietRadiusM,"home supplies outside quiet valley");
                bool usable=false;for(const auto& step:std::vector<std::pair<int,int>>{{2,0},{-2,0},{0,2},{0,-2}}){const int x=n.x+step.first,z=n.z+step.second;if(reached[z*m.width+x]&&std::abs(m.topSolid(x,z)-n.y)<=1)usable=true;}
                check(usable,"guaranteed supply has no reachable gathering position");
            }
            check(found==count,"missing finite home supply "+home.id+type);
        }
    }
    for(const auto& p:m.packs)if(!p.grazer){
        check(std::hypot(p.x-m.spawnX,p.z-m.spawnZ)*m.cellSize>=m.hostileBoundaryM,"hostile den inside opening");
        if(p.patrols)check(segmentDistance(m,p.x,p.z,p.routeX,p.routeZ)>=m.hostileBoundaryM,"ordinary patrol crosses quiet valley");
        if(p.hasForeign)check(segmentDistance(m,p.x,p.z,p.foreignX,p.foreignZ)>=m.hostileBoundaryM,"later-era patrol crosses quiet valley");
    }
    for(const auto& r:m.regions){
        check(r.radiusM>=125&&r.radiusM<=160,"small biome island survived");
        clearRoute(m,r.approach,occupied);if(!r.caveApproach.empty())clearRoute(m,r.caveApproach,occupied,true,true);
        int low=m.depth,high=0,cells=0,typed=0;
        for(int z=r.z-int(r.radiusM*.85);z<=r.z+int(r.radiusM*.85);z+=2)for(int x=r.x-int(r.radiusM*.85);x<=r.x+int(r.radiusM*.85);x+=2)if(std::hypot(x-r.x,z-r.z)<r.radiusM*.85){
            ++cells;if(t.worldgen.biomes[m.at(x,z).biomeIndex].id==r.biome)++typed;
            low=std::min(low,m.topSolid(x,z));high=std::max(high,m.topSolid(x,z));
        }
        check(typed>cells*.9,"elevation replaced regional biome identity");
        check(high-low>=18,"regional relief remains flat "+r.id);
        std::map<std::string,int> supplies;
        const auto& biome=*t.worldgen.findBiome(r.biome);
        for(const auto& n:m.nodes)if(n.resourceId.rfind("wnv6_region_"+r.id+"_",0)==0) {
            check(biome.nodeDensity.count(n.type)>0,"regional supply uses an incompatible source");
            check(n.unitsOverride==0&&n.siteId.empty()&&n.habitatId.empty(),"regional source changes finite yield or discovery ownership");
            ++supplies[n.type];
        }
        for(const auto& [type,density]:biome.nodeDensity)if(density>=.004)
            check(supplies[type]>0,"composed biome lacks its ordinary gathering supply "+r.id+" "+type);
        int total=0;for(const auto& [type,count]:supplies)total+=count;
        check(total>=20,"large region has too little real gathering supply "+r.id);
        std::cout<<" relief_"<<r.id<<"="<<high-low<<" supplies_"<<r.id<<"="<<total;
    }
    for(const auto& h:m.habitats){clearRoute(m,h.approach,occupied);
        for(const auto& home:m.homeSites)check(std::hypot(h.x-home.x,h.z-home.z)*m.cellSize>=h.radiusM+home.radiusM+3,"habitat overlaps a complete home pad");
    }
    std::map<std::string,int> primary;
    for(const auto& s:m.rareSites){clearRoute(m,s.approach,occupied);if(!s.exceptional)++primary[s.resourceType];}
    for(const auto& type:{"lanternheart","thrumroot","stormglass","pullstone","ventlung"})check(primary[type]>=2&&primary[type]<=4,"missing/duplicated rare family");
    for(const auto& r:m.ruins){clearRoute(m,r.approach,occupied);clearRoute(m,r.discoveryRoute,occupied,false);
        if(r.kind=="forge_threshold")check(std::hypot(r.x-m.gateX,r.z-m.gateZ)*m.cellSize<=t.worldgen.cataclysm.thresholdSearchM,"threshold is detached from its Forge gate");
    }
    clearRoute(m,m.pressurePockets.front().approach,occupied);
    check(m.pressurePockets.front().id=="ppv6_old_blacksmith","V6 pressure identity");
    check(m.augmentationField.size()==m.cells.size(),"missing field");
    for(float value:m.augmentationField)check(std::isfinite(value)&&value>=0&&value<=1,"invalid field");
    if(repeat){auto other=t;std::reverse(other.worldgen.regions.begin(),other.worldgen.regions.end());std::reverse(other.worldgen.habitats.begin(),other.worldgen.habitats.end());std::reverse(other.worldgen.rareSites.begin(),other.worldgen.rareSites.end());
        check(wideHash(m)==wideHash(worldgen::generateProfile(other,seed,"frontier_v6")),"V6 is not deterministic under definition reordering");
    }
    std::cout<<"\nWIDE_SEED "<<seed<<" seconds="<<seconds<<" nodes="<<m.nodes.size()<<" packs="<<m.packs.size()<<" hash="<<wideHash(m)<<std::endl;
}
uint64_t sampleSeed(int index) {
    if(index<=32)return static_cast<uint64_t>(index);
    if(index==33)return 0;
    if(index==34)return 2147483647ull;
    if(index==35)return 111486301962ull; // Complete gate/ruin-pair regression.
    return (static_cast<uint64_t>(index-35)*2654435761ull)&2147483647ull;
}
}
int main(int argc,char** argv){try{
    const std::string dir=argc>1?argv[1]:"data/tuning";
    tuning::Tuning t;t.worldgen=tuning::loadWorldgen(dir+"/worldgen.json");
    t.legacyWorldgen=tuning::loadWorldgen(dir+"/worldgen-legacy-v1.json");t.frontierV2Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v2.json");
    t.frontierV3Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v3.json");t.frontierV4Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v4.json");t.frontierV5Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v5.json");
    const int count=argc>2?std::stoi(argv[2]):8;
    const int start=argc>4?std::stoi(argv[4]):1;
    if(argc<4||std::string(argv[3])!="skip-history")historical(t);
    for(int i=start;i<start+count;++i)wide(t,sampleSeed(i),i==1||i==7||i==33||i==34);
    std::cout<<"WIDE_FRONTIER "<<checks<<" checks passed"<<std::endl;return 0;
}catch(const std::exception& e){std::cerr<<"FAIL wide frontier: "<<e.what()<<std::endl;return 1;}}
