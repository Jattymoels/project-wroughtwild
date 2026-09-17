// One forced Blue-host fallback and its protected geography. Ordinary two-seed
// determinism lives in generation.gd; published source/device rules are reused.
#include "wroughtwild/worldgen.h"
#include <cmath>
#include <iostream>
#include <set>
using namespace wroughtwild;
namespace {
int checks=0,failures=0;
void check(bool ok,const std::string& label){++checks;if(!ok){++failures;std::cerr<<"FAIL LAND04 native: "<<label<<'\n';}}
bool same(worldgen::SurfacePoint a,worldgen::SurfacePoint b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
}
int main(int argc,char** argv){
 try {
 const auto tuning=tuning::loadAll(argc>1?argv[1]:"data/tuning");
 const auto before=worldgen::generateProfile(tuning,77,"frontier_v11");
 auto forced=tuning;
 // In-memory search-budget exhaustion exercises production fallback; this
 // does not add a game runtime switch or publish changed V12 tuning.
 forced.frontierV12Worldgen.forceJourneys.primarySearchM=0;
 const auto map=worldgen::generateProfile(forced,77,"frontier_v12");
 check(map.forceJourneys.size()==4,"three primary journeys plus Green low-host contrast");
 bool blueFallback=false,roles=true;
 int secondary=0;
 std::set<std::string> owners,hostIds;
 for(const auto& j:map.forceJourneys){
  if(j.channel=="blue")blueFallback=j.fallback;
  if(j.secondary){++secondary;roles=roles&&j.channel=="green"&&j.sourceId.empty()&&j.hostId.empty();}
  else {roles=roles&&!j.sourceId.empty()&&!j.hostId.empty();owners.insert(j.sourceId);}
 }
 check(blueFallback,"zero primary search enters genuine bounded Blue fallback");
 check(roles&&secondary==1&&owners.size()==3,"secondary Green has no stock owner or duplicated finite host");
 const auto dry=[&](int x,int z){if(!map.inBounds(x,z))return false;for(const auto& lake:map.lakes)if(lake.bedAt(x,z)<lake.surfaceY)return false;return true;};
 bool homes=map.homeSites.size()==4;
 for(size_t i=0;i<map.homeSites.size();++i){const auto& h=map.homeSites[i];const auto& old=before.homeSites[i];
  homes=homes&&h.id==old.id&&h.x==old.x&&h.y==old.y&&h.z==old.z;
  for(int dz=-14;dz<=14;++dz)for(int dx=-14;dx<=14;++dx)if(dx*dx+dz*dz<=196)
   homes=homes&&dry(h.x+dx,h.z+dz)&&map.topSolid(h.x+dx,h.z+dz)==h.y;
 }
 check(homes,"fallback preserves four original dry level radius-fourteen home cores");
 bool water=map.lakes.size()==before.lakes.size();
 for(size_t i=0;i<map.lakes.size();++i){const auto& a=map.lakes[i];const auto& b=before.lakes[i];water=water&&a.id==b.id&&a.minX==b.minX&&a.minZ==b.minZ&&a.surfaceY==b.surfaceY&&a.beds==b.beds;}
 check(water,"fallback leaves original fixed lake identity, surface and beds exact");
 bool caveAir=true;
 for(int z=0;z<map.height&&caveAir;++z)for(int x=0;x<map.width&&caveAir;++x)
  for(int y=1;y<before.at(x,z).height-3;++y)
   if(before.blockAt(x,y,z)==worldgen::kAir&&map.blockAt(x,y,z)!=worldgen::kAir){caveAir=false;break;}
 check(caveAir,"fallback does not fill inherited underground cave air");
 check(map.scarwater.size()==1&&map.drySteppe.size()==1&&same(map.drySteppe[0].redSource,before.drySteppe[0].redSource)&&same(map.drySteppe[0].redHost,before.drySteppe[0].redHost),"Scarwater and Steppe places survive; Red source and finite host unchanged");
 bool anchors=map.leylineSourceSites.size()==4;
 std::set<std::string> sourceIds;
 for(const auto& source:map.leylineSourceSites){sourceIds.insert(source.sourceId);anchors=anchors&&dry(source.at.x,source.at.z)&&map.topSolid(source.at.x,source.at.z)==source.at.y;}
 check(anchors&&sourceIds==std::set<std::string>{"red_home_margin","white_home_margin","blue_home_margin","green_home_margin"},"exact four supported dry source anchors retain stable owners");
 const auto validRoute=[&](const std::string& name,const std::vector<worldgen::SurfacePoint>& route){
  if(route.size()<2){std::cerr<<"LAND04_ROUTE_BAD "<<name<<" points="<<route.size()<<'\n';return false;}
  for(size_t i=0;i<route.size();++i){const auto p=route[i];
   const bool isDry=dry(p.x,p.z),supported=map.topSolid(p.x,p.z)==p.y;
   const int rise=i?std::abs(p.y-route[i-1].y):0;
   if(!isDry||!supported||rise>1){
    std::cerr<<"LAND04_ROUTE_BAD "<<name<<" index="<<i<<" point="<<p.x<<','<<p.y<<','<<p.z
             <<" top="<<map.topSolid(p.x,p.z)<<" dry="<<isDry<<" rise="<<rise<<'\n';
    return false;
   }
  }
  return true;
 };
 bool routes=true,stances=true;
 for(const auto& j:map.forceJourneys)if(!j.secondary){
  const bool approachOk=validRoute(j.id+"/approach",j.approach);
  const bool hostOk=validRoute(j.id+"/hostRoute",j.hostRoute);
  routes=routes&&approachOk&&hostOk;
  const double d=std::hypot(j.at.x-j.workStance.x,j.at.z-j.workStance.z);
  stances=stances&&d>=1.7&&d<=4.5&&!j.approach.empty()&&same(j.approach.back(),j.workStance);
 }
 check(routes,"forced fallback supplies dry supported bounded-step source and host approaches");
 check(stances,"source approaches end in reachable space outside solid source centres");
 bool separate=map.frontierHosts.size()==4;
 for(const auto& h:map.frontierHosts){hostIds.insert(h.id);separate=separate&&std::hypot(h.at.x-map.spawnX,h.at.z-map.spawnZ)>=170;
  auto source=map.leylineSourceSites.begin();while(source!=map.leylineSourceSites.end()&&source->sourceId!=h.sourceId)++source;
  if(source==map.leylineSourceSites.end())separate=false;else{const double d=std::hypot(h.at.x-source->at.x,h.at.z-source->at.z);separate=separate&&d>=65&&d<=130;}
  for(const auto& other:map.frontierHosts)if(h.id!=other.id)separate=separate&&std::hypot(h.at.x-other.at.x,h.at.z-other.at.z)>=60;
 }
 check(separate&&hostIds.size()==4,"four existing finite hosts keep source, start and mutual separation");
 check(map.regions.size()==3&&map.rareSites.size()==14&&map.pressurePockets.size()==1&&map.laboratories.empty()&&map.futureTransformations.empty(),"finite discoveries and separate smithy pressure persist without LF campaign adoption");
 }catch(const std::exception& e){check(false,std::string("unexpected exception: ")+e.what());}
 std::cout<<"LAND04 native: "<<checks<<" checks, "<<failures<<" failures\n";
 return failures?1:0;
}