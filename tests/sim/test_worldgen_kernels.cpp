// Compile without a separate worldgen_profiles.cpp. Including this translation
// unit keeps private V6 kernels testable without adding a production API.
#include "../../sim/src/worldgen_profiles.cpp"
#include <cstring>
#include <iostream>
using namespace wroughtwild;

namespace {
uint64_t checks=0;
void check(bool ok,const std::string& message){++checks;if(!ok)throw std::runtime_error(message);}
void caveNoise(){
    const uint64_t seeds[]={0,1,7,2147483647ull,111486301962ull,~uint64_t{0}};
    const int positions[]={-11,-1,0,1,63,511,1023,2048};
    const double frequencies[]={.001,.045,.05,.055,.08,.125,.5,1.25};
    const uint32_t salts[]={4000,4200,4400};
    for(auto seed:seeds)for(int x:positions)for(int z:positions)
    for(auto frequency:frequencies)for(auto salt:salts){
        worldgen::frontier_v6_base::CaveColumnNoise column(seed,x,z,frequency,salt);
        // Cavern tests can skip y values; reuse must also survive revisiting a
        // prior lattice cell. Negative positions exercise floor/hash semantics.
        for(int direction=0;direction<3;++direction)for(int ordinal=0;ordinal<128;++ordinal){
            const int y=direction==0?ordinal-8:direction==1?ordinal*3-9:119-ordinal;
            const double expected=worldgen::frontier_v6_base::fbm3(seed,x,y,z,frequency,2,salt);
            const double actual=column.sample(y);
            check(std::memcmp(&actual,&expected,sizeof(actual))==0,"cave noise bits changed at seed "+std::to_string(seed));
        }
    }
    std::cout<<"CAVE_COLUMN_NOISE "<<checks<<" exact double comparisons; three_field_bytes="
             <<sizeof(worldgen::frontier_v6_base::CaveColumnNoise)*3<<"\n";
}

worldgen::frozen_frontier::SurfaceWalk previousWalk(const worldgen::WorldMap& map,int maxStep){
    // Original V6 wrapper, retained only as an independent equivalence oracle.
    auto walk=worldgen::frozen_frontier::surfaceWalk(map,maxStep);
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
void surfaceRoutes(){
    for(int fixture=0;fixture<12;++fixture){
        worldgen::WorldMap map;
        map.width=64;map.height=48;map.depth=24;map.spawnX=32;map.spawnZ=24;
        map.cells.resize(map.width*map.height);
        map.blocks.resize(map.cells.size()*map.depth,worldgen::kAir);
        for(int z=0;z<map.height;++z)for(int x=0;x<map.width;++x){
            const int index=z*map.width+x;
            const int height=8+(x+fixture)/9+(z/11)%2;
            map.cells[index].height=height;
            for(int y=0;y<height;++y)map.blocks[index*map.depth+y]=y==0?worldgen::kBedrock:worldgen::kStone;
            if((x*13+z*31+fixture)%53==0)map.blocks[index*map.depth+height-1]=worldgen::kAir;
        }
        for(int n=0;n<80;++n){
            const int x=(n*17+fixture)%map.width,z=(n*23+fixture)%map.height;
            map.nodes.push_back({"tree",x,map.at(x,z).height-(n%3==0?2:0),z});
        }
        worldgen::PlacedRuin ruin;
        ruin.x=40;ruin.z=30;ruin.widthM=6;ruin.depthM=8;ruin.rotationQuarters=fixture%4;
        map.ruins.push_back(ruin);
        for(int step=0;step<=2;++step){
            const auto previous=previousWalk(map,step),current=worldgen::wide_frontier::surfaceWalk(map,step);
            check(previous.heights==current.heights,"walk support heights changed");
            check(previous.clear==current.clear,"walk obstacle/border mask changed");
            check(previous.parent==current.parent,"walk reachability or ordered route parents changed");
        }
    }
}
}
int main(){try{caveNoise();surfaceRoutes();std::cout<<"WORLDGEN_KERNELS "<<checks<<" checks, 0 failures\n";return 0;}
catch(const std::exception& e){std::cerr<<"FAIL worldgen kernels: "<<e.what()<<"\n";return 1;}}
