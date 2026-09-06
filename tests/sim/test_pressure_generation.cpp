#define main previous_frontier_test_main
#include "test_strange_frontier.cpp"
#undef main

namespace {
#include "worldgen_history.inc"

void frozenPressureProfiles(tuning::Tuning t) {
 const uint64_t seeds[]={1,7,24,91};
 const uint64_t expected[][4]={
  {1899602153114217418ull,736845089599793829ull,7709451517322904450ull,2672371686718130021ull},
  {5430446987841818078ull,3258464633623945865ull,10270373463809211055ull,15565090014744201037ull},
  {12362207930465321087ull,14231361409912523888ull,4253842255980360217ull,8552760223992271840ull},
  {2777892313851358114ull,3704407159615029765ull,74627671584911170ull,16539691791317643557ull}};
 const std::string profiles[]={"legacy_v1","frontier_v2","frontier_v3","frontier_v4"};
 t.worldgen.map.widthCells=999;t.worldgen.biomes.clear();t.worldgen.regions.clear();
 t.worldgen.rareSites.clear();t.worldgen.habitats.clear();t.worldgen.cataclysm.ruinWidthM=0;
 t.worldgen.pressureSite.workLateralCells=1000;t.world.eliteModifiers.clear();
 for(int p=0;p<4;++p)for(int i=0;i<4;++i){
  const auto m=worldgen::generateProfile(t,seeds[i],profiles[p]);
  check((p==3?historyFingerprint(m):completeFingerprint(m))==expected[p][i],"frozen profile changed "+profiles[p]+" seed "+std::to_string(seeds[i]));
  check(m.pressurePockets.empty(),"old geography silently gained pressure stock/source");
 }
}

uint64_t pressureFingerprint(const worldgen::WorldMap& m) {
 uint64_t h=historyFingerprint(m);
 auto add=[&](const std::string& s){for(unsigned char c:s)h=(h^c)*1099511628211ull;h=(h^255)*1099511628211ull;};
 auto point=[&](const auto& p){add(std::to_string(p.x));add(std::to_string(p.y));add(std::to_string(p.z));};
 for(const auto& p:m.pressurePockets){add(p.id);add(p.ruinId);add(p.impactId);add(p.leylineId);add(p.linkedSiteId);add(p.origin);add(std::to_string(p.radiusM));add(std::to_string(p.accidental));point(p);point(p.workPosition);for(const auto& q:p.approach)point(q);}
 return h;
}

void pressureComposition(const tuning::Tuning& t,uint64_t seed) {
 const auto old=worldgen::generateProfile(t,seed,"frontier_v4");
 const auto m=worldgen::generateProfile(t,seed,"frontier_v5");
 check(m.profileId=="frontier_v5"&&m.width==512&&m.height==512&&m.depth==48,"pressure successor changed finite extent");
 check(completeFingerprint(m)==completeFingerprint(old),"pressure composition changed existing terrain, resources, caves, progression or approaches");
 check(m.pressurePockets.size()==1,"pressure source count is not exactly one");
 check(m.impacts.size()==4&&m.leylines.size()==10&&m.ruins.size()==6,"pressure event escaped bounded history budget");
 const auto& p=m.pressurePockets.front();
 check(p.id=="ppv5_old_blacksmith"&&p.origin=="pre_cataclysm_blacksmith"&&p.accidental,"source was not accidental empowerment of an old blacksmith ruin");
 const auto ruin=std::find_if(m.ruins.begin(),m.ruins.end(),[&](const auto& r){return r.id==p.ruinId;});
 const auto impact=std::find_if(m.impacts.begin(),m.impacts.end(),[&](const auto& a){return a.id==p.impactId;});
 const auto trace=std::find_if(m.leylines.begin(),m.leylines.end(),[&](const auto& l){return l.id==p.leylineId;});
 const auto source=std::find_if(m.rareSites.begin(),m.rareSites.end(),[&](const auto& s){return s.id==p.linkedSiteId;});
 check(ruin!=m.ruins.end()&&impact!=m.impacts.end()&&trace!=m.leylines.end()&&source!=m.rareSites.end(),"pressure source refers to missing history/discovery");
 check(ruin->kind=="pre_cataclysm_blacksmith"&&ruin->impactId==p.impactId&&ruin->leylineId==p.leylineId,"ruin does not preserve old-smithy accident identity");
 check(impact->kind=="blacksmith_strike"&&impact->regionId==ruin->regionId,"wrong strike at source ruin");
 check(source->resourceType=="ventlung"&&!source->exceptional&&ruin->linkedSiteId==source->id,"pressure source displaced the ordinary Ventlung opportunity");
 check(std::abs(p.x-ruin->x)<=ruin->widthM*.5&&std::abs(p.z-ruin->z)<=ruin->depthM*.5,"pocket is outside the old smithy");
 check(std::abs(impact->x-ruin->x)<=ruin->widthM*.5&&std::abs(impact->z-ruin->z)<=ruin->depthM*.5,"asteroid did not strike the smithy");
 check(p.y==ruin->y&&m.topSolid(p.x,p.z)==p.y&&m.topSolid(impact->x,impact->z)==impact->y,"source or strike floats");
 check(trace->fromImpactId==impact->id&&trace->points.size()==2&&trace->exposure.size()==1&&trace->exposure.front()==2,"accidental connection is not exposed at the struck hearth");
 check(trace->points.front().x==impact->x&&trace->points.front().z==impact->z&&trace->points.back().x==p.x&&trace->points.back().z==p.z,"trace does not physically join strike and pressure source");
 const int lateral=ruin->rotationQuarters%2==0?p.workPosition.x-ruin->x:p.workPosition.z-ruin->z;
 check(std::abs(lateral)<=1&&std::hypot(p.x-p.workPosition.x,p.z-p.workPosition.z)<=3,"source cannot be worked from the clear central strip");
 for(const auto& s:m.rareSites)check(std::hypot(p.x-s.x,p.z-s.z)>s.radiusM+p.radiusM,"pressure device obstructs a finite rare workplace");
 route(m,p.approach);
 check(p.approach.back().x==p.workPosition.x&&p.approach.back().z==p.workPosition.z,"source approach ends away from interaction");
 for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx){const int x=p.workPosition.x+dx,z=p.workPosition.z+dz;
  check(m.topSolid(x,z)==p.y&&m.blockAt(x,p.y,z)==worldgen::kAir&&m.blockAt(x,p.y+1,z)==worldgen::kAir,"source work area lacks full ordinary footprint");}
 check(m.augmentationField.size()==m.cells.size(),"v5 lost native augmentation field");
 for(auto value:m.augmentationField)check(std::isfinite(value)&&value>=0&&value<=1,"source field became unbounded");
 check(m.augmentationField[p.z*m.width+p.x]>0.5,"native accident lacks visible local influence");
 if(seed==1||seed==7){auto reordered=t;std::reverse(reordered.worldgen.regions.begin(),reordered.worldgen.regions.end());std::reverse(reordered.worldgen.rareSites.begin(),reordered.worldgen.rareSites.end());std::reverse(reordered.worldgen.habitats.begin(),reordered.worldgen.habitats.end());
  check(pressureFingerprint(m)==pressureFingerprint(worldgen::generateProfile(reordered,seed,"frontier_v5")),"definition order rerolled pressure identity");}
 std::cout<<"PRESSURE_SEED "<<seed<<" source="<<p.x<<","<<p.y<<","<<p.z<<" work="<<p.workPosition.x<<","<<p.workPosition.y<<","<<p.workPosition.z<<" approach="<<p.approach.size()<<" hash="<<pressureFingerprint(m)<<std::endl;
}
}

int main(int argc,char** argv){try{
 const std::string dir=argc>1?argv[1]:"data/tuning";tuning::Tuning t;
 t.worldgen=tuning::loadWorldgen(dir+"/worldgen.json");t.legacyWorldgen=tuning::loadWorldgen(dir+"/worldgen-legacy-v1.json");
 t.frontierV2Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v2.json");t.frontierV3Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v3.json");t.frontierV4Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v4.json");
 frozenPressureProfiles(t);
 for(uint64_t sample=1;sample<=64;++sample)pressureComposition(t,sample<=32?sample:sample*2654435761ull);
 std::cout<<"PRESSURE_GENERATION "<<checks<<" checks passed"<<std::endl;return 0;
}catch(const std::exception& e){std::cerr<<"FAIL pressure generation: "<<e.what()<<std::endl;return 1;}}
