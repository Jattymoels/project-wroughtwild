#include "wroughtwild/worldgen.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <queue>
#include <set>
#include <stdexcept>
using namespace wroughtwild;
namespace {
int checks=0;
void check(bool ok,const std::string& message){++checks;if(!ok)throw std::runtime_error(message);}
uint64_t fingerprint(const worldgen::WorldMap& m) {
    uint64_t h = 1469598103934665603ull;
    auto byte = [&](uint8_t v) { h = (h ^ v) * 1099511628211ull; };
    auto number = [&](int v) { for (int i=0;i<4;++i) byte(static_cast<uint8_t>(static_cast<uint32_t>(v)>>(8*i))); };
    auto text = [&](const std::string& s) { number(static_cast<int>(s.size())); for(auto c:s) byte(static_cast<uint8_t>(c)); };
    number(m.width);number(m.height);number(m.depth);number(m.spawnX);number(m.spawnZ);number(m.gateX);number(m.gateZ);
    for(auto c:m.cells){number(c.height);number(c.biomeIndex);}for(auto v:m.blocks)byte(v);
    number(static_cast<int>(m.nodes.size()));for(const auto& n:m.nodes){text(n.type);number(n.x);number(n.y);number(n.z);}
    number(static_cast<int>(m.packs.size()));for(const auto& p:m.packs){number(p.x);number(p.y);number(p.z);number(p.eliteMemberIndex);text(p.eliteModifierId);number(p.grazer);text(p.biome);number(p.patrols);number(p.routeX);number(p.routeZ);number(p.hasForeign);number(p.foreignX);number(p.foreignZ);text(p.foreignBiome);number(static_cast<int>(p.enemies.size()));for(auto e:p.enemies)text(e);}
    number(static_cast<int>(m.landmarks.size()));for(const auto& l:m.landmarks){text(l.id);number(l.x);number(l.z);}
    return h;
}

void route(const worldgen::WorldMap& m,const std::vector<worldgen::SurfacePoint>& path,bool cave=false) {
    check(!path.empty(),"missing complete approach");
    check(path.front().x==m.spawnX&&path.front().z==m.spawnZ,"approach does not begin at spawn");
    for(size_t i=0;i<path.size();++i){const auto& p=path[i];
        check(m.inBounds(p.x,p.z)&&m.blockAt(p.x,p.y-1,p.z)!=worldgen::kAir&&m.blockAt(p.x,p.y,p.z)==worldgen::kAir&&m.blockAt(p.x,p.y+1,p.z)==worldgen::kAir,"route lost grounded headroom");
        if(!cave)check(p.y==m.topSolid(p.x,p.z),"surface route enters roof");
        if(i){const auto& a=path[i-1];check(std::abs(a.x-p.x)+std::abs(a.z-p.z)==1&&std::abs(a.y-p.y)<=1,"route needs jump or teleport");}
        bool blocked=false;
        for(const auto& n:m.nodes){if(n.y!=p.y)continue;const int dx=n.x-p.x,dz=n.z-p.z;if(dx*dx+dz*dz<=1)blocked=true;}
        check(!blocked,"resource blocks approach");
    }
}
void frozen(tuning::Tuning t){
 const uint64_t seeds[]={1,7,24,91};
 const uint64_t old[]={9567315995627226133ull,5936621565493496066ull,13276267164882187656ull,9716464632784557402ull};
 const uint64_t previous[]={18023770114133595108ull,18150026021804392173ull,5053789636092139205ull,18363030457363895559ull};
 t.worldgen.map.heightScale+=7;t.worldgen.biomes.clear();t.worldgen.habitats.clear();t.worldgen.regions.clear();t.world.eliteModifiers.clear();
 for(int i=0;i<4;++i){
  check(fingerprint(worldgen::generateProfile(t,seeds[i],"legacy_v1"))==old[i],"legacy terrain changed");
  const auto m=worldgen::generateProfile(t,seeds[i],"frontier_v2");
  check(fingerprint(m)==previous[i],"frontier_v2 terrain or population changed");
  check(m.regions.empty()&&m.rareSites.empty(),"rare sites retrofitted an existing profile");
 }
}
void generated(const tuning::Tuning& t,uint64_t seed){
 const auto m=worldgen::generateProfile(t,seed,"frontier_v3");
 check(m.width==512&&m.height==512&&m.depth==48,"bounded region size");
 check(m.regions.size()==3&&m.habitats.size()==3,"missing region or material habitat");
 std::set<std::string> ids,sites;
 for(const auto& n:m.nodes){check(ids.insert(n.resourceId).second,"duplicate resource identity");check(m.blockAt(n.x,n.y,n.z)==worldgen::kAir&&m.blockAt(n.x,n.y-1,n.z)!=worldgen::kAir,"buried or floating resource "+n.type);}
 for(const auto& r:m.regions){
  route(m,r.approach);
  int area=0;const int radius=static_cast<int>(r.radiusM);
  for(int z=r.z-radius;z<=r.z+radius;++z)for(int x=r.x-radius;x<=r.x+radius;++x)
   if((x-r.x)*(x-r.x)+(z-r.z)*(z-r.z)<=radius*radius&&t.worldgen.biomes[m.at(x,z).biomeIndex].id==r.biome)++area;
  check(area>8000,"regional core is not a broad continuous place "+r.id);
  if(!r.caveApproach.empty()){
   route(m,r.caveApproach,true);const auto& p=r.caveApproach.back();
   check(m.topSolid(p.x,p.z)>p.y+2,"authored cave never reaches underground");
  }
 }
 for(const auto& h:m.habitats)route(m,h.approach);
 int exceptions=0;
 for(const auto& s:m.rareSites){
  check(sites.insert(s.id).second,"duplicate repeated site identity");
  route(m,s.approach);check(s.cluePoints.size()>=2,"missing clue approach");
  const auto ri=std::find_if(m.regions.begin(),m.regions.end(),[&](const auto& r){return r.id==s.regionId;});
  check(ri!=m.regions.end(),"rare site has no region");
  const auto di=std::find_if(t.worldgen.rareSites.begin(),t.worldgen.rareSites.end(),[&](const auto& d){return d.nodeType==s.resourceType;});
  check(di!=t.worldgen.rareSites.end(),"rare type absent");
  check(std::find(di->regions.begin(),di->regions.end(),ri->id)!=di->regions.end(),"rare in wrong regional identity");
  const int dx=s.x-ri->x,dz=s.z-ri->z;
  check(dx*dx+dz*dz<ri->radiusM*ri->radiusM,"rare outside composed core");
  check(t.worldgen.biomes[m.at(s.x,s.z).biomeIndex].id==ri->biome,"rare node fell back to ordinary meadow");
  int specimens=0;
  for(const auto& n:m.nodes)if(n.siteId==s.id){++specimens;check(n.type==s.resourceType&&n.unitsOverride>=t.worldgen.nodeTypes.at(n.type).units,"first haul incomplete");check(n.exceptional==s.exceptional,"exceptional source mismatch");}
  check(specimens==1,"site lacks exactly one intact finite haul");
  for(const auto& p:s.cluePoints)check(m.blockAt(p.x,p.y-1,p.z)!=worldgen::kAir&&p.y==m.topSolid(p.x,p.z),"floating clue");
  if(s.exceptional)++exceptions;
 }
 check(exceptions<=2,"exceptional budget escaped");
 for(const auto& d:t.worldgen.rareSites){
  int count=0;bool quiet=false;
  for(const auto& s:m.rareSites)if(s.resourceType==d.nodeType&&!s.exceptional){++count;if(!s.guarded)quiet=true;}
  check(count>=2&&count<=4,"primary site budget missing capability "+d.nodeType);check(quiet,"no quiet first opportunity");
  const auto& n=t.worldgen.nodeTypes.at(d.nodeType);check(n.era==1&&n.heatToWork==0&&n.toolItem.empty(),"class or era gated rare resource");
  check(n.harvestStages.size()>=2&&!n.properties.empty()&&!n.usePreview.empty(),"rare purpose missing");
 }
 const auto& g=t.worldgen.guarantees;
 for(const auto& q:g.minNodesNear)check(m.countNodesNear(q.first,m.spawnX,m.spawnZ,g.nearRadiusM)>=q.second,"starter supply erased");
 for(const auto& q:g.minNodesFar)check(m.countNodesNear(q.first,m.spawnX,m.spawnZ,g.farRadiusM)>=q.second,"progression supply erased");
 const double gate=std::hypot(m.gateX-m.spawnX,m.gateZ-m.spawnZ)*m.cellSize;
 check(gate>=160&&gate<=215,"Forge moved to the expanded map edge");
 // Reordering definitions cannot reroll complete sites or their depleted IDs.
 if(seed==7){auto other=t;std::reverse(other.frontierV3Worldgen.regions.begin(),other.frontierV3Worldgen.regions.end());std::reverse(other.frontierV3Worldgen.rareSites.begin(),other.frontierV3Worldgen.rareSites.end());std::reverse(other.frontierV3Worldgen.habitats.begin(),other.frontierV3Worldgen.habitats.end());
  const auto again=worldgen::generateProfile(other,seed,"frontier_v3");check(fingerprint(m)==fingerprint(again),"definition ordering moved terrain/resources");
  check(m.rareSites.size()==again.rareSites.size(),"definition ordering moved site count");
  for(size_t i=0;i<m.nodes.size();++i)check(m.nodes[i].resourceId==again.nodes[i].resourceId,"resource identity depends on mutable order");
  for(size_t i=0;i<m.rareSites.size();++i)check(m.rareSites[i].id==again.rareSites[i].id,"site identity depends on mutable order");
 }
 std::cout<<"STRANGE_SEED "<<seed<<" nodes="<<m.nodes.size()<<" packs="<<m.packs.size()<<" rare_sites="<<m.rareSites.size()<<" exceptional="<<exceptions<<" gate_m="<<gate<<"\n";
}
}
int main(int argc,char** argv){try{
 const std::string dir=argc>1?argv[1]:"data/tuning";tuning::Tuning t;
 t.frontierV3Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v3.json");
 t.worldgen=t.frontierV3Worldgen;t.legacyWorldgen=tuning::loadWorldgen(dir+"/worldgen-legacy-v1.json");t.frontierV2Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v2.json");
 frozen(t);for(uint64_t sample=1;sample<=64;++sample)generated(t,sample<=32?sample:sample*2654435761ull);
 check(t.worldgen.nodeTypes.at("copper_vein").era==2&&t.worldgen.nodeTypes.at("silver_vein").era==3,"existing era ore gate changed");
 std::cout<<"STRANGE_FRONTIER "<<checks<<" checks passed\n";return 0;
}catch(const std::exception& e){std::cerr<<"FAIL strange frontier: "<<e.what()<<"\n";return 1;}}
