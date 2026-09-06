// Reuse the established full geometry fingerprint; its encoding is frozen by
// the pre-V4 baseline and also guards the earlier intensive's regression test.
#define main previous_frontier_test_main
#include "test_strange_frontier.cpp"
#undef main

namespace {
#include "worldgen_history.inc"
void historical(tuning::Tuning t) {
 const uint64_t seeds[]={1,7,24,91};
 const uint64_t expected[][4]={
  {1899602153114217418ull,736845089599793829ull,7709451517322904450ull,2672371686718130021ull},
  {5430446987841818078ull,3258464633623945865ull,10270373463809211055ull,15565090014744201037ull},
  {12362207930465321087ull,14231361409912523888ull,4253842255980360217ull,8552760223992271840ull}};
 const std::string profiles[]={"legacy_v1","frontier_v2","frontier_v3"};
 t.worldgen.map.widthCells=999;t.worldgen.biomes.clear();t.worldgen.regions.clear();t.worldgen.rareSites.clear();t.worldgen.habitats.clear();t.world.eliteModifiers.clear();
 for(int p=0;p<3;++p)for(int i=0;i<4;++i){
  const auto m=worldgen::generateProfile(t,seeds[i],profiles[p]);
  check(completeFingerprint(m)==expected[p][i],"historical geography/resource IDs/routes changed "+profiles[p]);
  check(m.impacts.empty()&&m.ruins.empty()&&m.leylines.empty()&&m.augmentationField.empty(),"history retrofitted into old save");
 }
}
void cataclysm(const tuning::Tuning& t,uint64_t seed) {
 const auto m=worldgen::generateProfile(t,seed,"frontier_v4");
 check(m.profileId=="frontier_v4"&&m.width==512&&m.height==512&&m.depth==48,"successor extent escaped approved bounds");
 check(m.regions.size()==3&&m.impacts.size()==3&&m.ruins.size()==6&&m.leylines.size()==9&&m.habitats.size()==3,"incomplete native history composition");
 std::set<std::string> ids;std::set<int> blocked;
 for(const auto& n:m.nodes){
  check(ids.insert(n.resourceId).second,"duplicate persistent resource identity");
  check(m.blockAt(n.x,n.y,n.z)==worldgen::kAir&&m.blockAt(n.x,n.y-1,n.z)!=worldgen::kAir,"floating or buried resource "+n.resourceId);
  if(n.y==m.topSolid(n.x,n.z))for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)if(dx*dx+dz*dz<=1)blocked.insert((n.z+dz)*m.width+n.x+dx);
 }
 auto path=[&](const auto& points,const worldgen::SurfacePoint& from,bool cave=false){
  check(!points.empty(),"missing recorded route");
  check(points.front().x==from.x&&points.front().z==from.z,"route begins at wrong place");
  for(size_t i=0;i<points.size();++i){const auto& p=points[i];
   check(m.inBounds(p.x,p.z)&&m.blockAt(p.x,p.y-1,p.z)!=worldgen::kAir&&m.blockAt(p.x,p.y,p.z)==worldgen::kAir&&m.blockAt(p.x,p.y+1,p.z)==worldgen::kAir,"route lost support or headroom");
   if(!cave)check(m.topSolid(p.x,p.z)==p.y,"surface route requires excavation");
   if(i)check(std::abs(points[i-1].x-p.x)+std::abs(points[i-1].z-p.z)==1&&std::abs(points[i-1].y-p.y)<=1,"route requires jump or teleport");
   if(!cave)check(!blocked.count(p.z*m.width+p.x),"finite specimen blocks approach");
   for(const auto& r:m.ruins){const int dx=p.x-r.x,dz=p.z-r.z;const int lateral=r.rotationQuarters%2==0?dx:dz;
    check(!(std::abs(dx)<=r.widthM*.5&&std::abs(dz)<=r.depthM*.5&&std::abs(lateral)>=2),"route collides with authored ruin margin");}
  }
 };
 const worldgen::SurfacePoint spawn{m.spawnX,m.topSolid(m.spawnX,m.spawnZ),m.spawnZ};
 check(m.augmentationField.size()==m.cells.size(),"augmentation field has wrong indexing extent");
 for(size_t i=0;i<m.augmentationField.size();++i){const float a=m.augmentationField[i];
  check(std::isfinite(a)&&a>=0&&a<=1,"unbounded augmentation value");
  if(std::hypot(static_cast<int>(i%m.width)-m.spawnX,static_cast<int>(i/m.width)-m.spawnZ)<t.worldgen.guarantees.nearRadiusM)
   check(a==0,"starter clearing lost quiet native state");
 }
 std::set<std::string> impacts,lines,links;
 for(const auto& r:m.regions){path(r.approach,spawn);if(!r.caveApproach.empty())path(r.caveApproach,spawn,true);check(!r.impactId.empty()&&!r.augmentationProperty.empty(),"region lost its cause");}
 for(const auto& h:m.habitats)path(h.approach,spawn);
 for(const auto& a:m.impacts){check(impacts.insert(a.id).second,"duplicate impact ID");path(a.approach,spawn);check(a.y==m.topSolid(a.x,a.z),"impact anchor floats");check(m.augmentationField[a.z*m.width+a.x]>=.99,"impact lacks local influence");}
 int connected=0;
 for(const auto& l:m.leylines){
  check(lines.insert(l.id).second&&impacts.count(l.fromImpactId),"trace lacks stable origin");
  check(l.points.size()>=4&&l.points.size()<=33&&l.exposure.size()+1==l.points.size(),"unbounded or malformed trace");
  if(!l.toImpactId.empty()){check(impacts.count(l.toImpactId),"trace leads to nonexistent impact");++connected;}
  for(const auto& p:l.points)check(m.inBounds(p.x,p.z)&&p.y==m.topSolid(p.x,p.z),"trace detached from terrain");
  for(auto e:l.exposure)check(e<=2,"invalid broken/buried/exposed state");
 }
 check(connected==3,"regional trace network disconnected");
 size_t longest=0;
 for(const auto& r:m.ruins){
  check(impacts.count(r.impactId)&&lines.count(r.leylineId),"ruin history points to missing cause");
  check(r.widthM>=10&&r.depthM>=10&&r.foundation.size()>=100,"ruin lacks a complete foundation");
  for(const auto& p:r.foundation)check(p.y==r.y&&m.topSolid(p.x,p.z)==p.y,"authored room has unsupported uneven foundation");
  for(const auto& n:m.nodes)check(!(std::abs(n.x-r.x)<=r.widthM*.5+1&&std::abs(n.z-r.z)<=r.depthM*.5+1),"resource collides with ruin footprint");
  path(r.approach,spawn);path(r.discoveryRoute,r.entrance);
  check(r.discoveryRoute.size()<=160,"short ruin discovery became a world-length detour");longest=std::max(longest,r.discoveryRoute.size());
  if(!r.linkedSiteId.empty())check(links.insert(r.linkedSiteId).second,"duplicate guaranteed discovery linkage");
  check(std::abs(std::hypot(r.damageDirection.x,r.damageDirection.z)-1)<.00001,"damage direction has no physical orientation");
 }
 int exceptional=0;std::map<std::string,int> counts;
 for(const auto& s:m.rareSites){
  path(s.approach,spawn);check(s.cluePoints.size()>=2,"rare clue sequence disappeared");
  const auto def=std::find_if(t.worldgen.rareSites.begin(),t.worldgen.rareSites.end(),[&](const auto& d){return d.nodeType==s.resourceType;});
  check(def!=t.worldgen.rareSites.end(),"new unapproved rare capability");
  if(s.exceptional)++exceptional;else ++counts[s.resourceType];
  int specimens=0;
  for(const auto& n:m.nodes){if(n.siteId==s.id){++specimens;check(n.unitsOverride==(s.exceptional?def->exceptionalUnits:t.worldgen.nodeTypes.at(s.resourceType).units),"rare stock or haul changed");}
   else if(n.y==s.y)check(std::hypot(n.x-s.x,n.z-s.z)>=s.radiusM,"rare workplace obstructed by other stock");}
  check(specimens==1,"site lacks exactly one intact finite source");
 }
 check(exceptional<=2&&links.size()==5,"finite exceptional or discovery budget changed");
 for(const auto& def:t.worldgen.rareSites){check(counts[def.nodeType]>=2&&counts[def.nodeType]<=4,"missing bounded primary opportunities");check(links.count("rsv4_"+def.nodeType+"_primary_0"),"first capability lacks inhabited evidence");}
 for(const auto& q:t.worldgen.guarantees.minNodesNear)check(m.countNodesNear(q.first,m.spawnX,m.spawnZ,t.worldgen.guarantees.nearRadiusM)>=q.second,"starter supply erased");
 for(const auto& q:t.worldgen.guarantees.minNodesFar)check(m.countNodesNear(q.first,m.spawnX,m.spawnZ,t.worldgen.guarantees.farRadiusM)>=q.second,"progression supply erased");
 const double gate=std::hypot(m.gateX-m.spawnX,m.gateZ-m.spawnZ)*m.cellSize;
 check(gate>=160&&gate<=215,"Forge travel goal changed");
 if(seed==7){auto other=t;std::reverse(other.frontierV4Worldgen.regions.begin(),other.frontierV4Worldgen.regions.end());std::reverse(other.frontierV4Worldgen.rareSites.begin(),other.frontierV4Worldgen.rareSites.end());std::reverse(other.frontierV4Worldgen.habitats.begin(),other.frontierV4Worldgen.habitats.end());check(historyFingerprint(m)==historyFingerprint(worldgen::generateProfile(other,seed,"frontier_v4")),"history changes with definition ordering");}
 if(seed==1)check(historyFingerprint(m)==historyFingerprint(worldgen::generateProfile(t,seed,"frontier_v4")),"same identity rerolls history");
 std::cout<<"CATACLYSM_SEED "<<seed<<" nodes="<<m.nodes.size()<<" rare_sites="<<m.rareSites.size()<<" longest_discovery_cells="<<longest<<" hash="<<historyFingerprint(m)<<std::endl;
}
}
int main(int argc,char** argv){try{
 const std::string dir=argc>1?argv[1]:"data/tuning";tuning::Tuning t;
 t.frontierV4Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v4.json");t.worldgen=t.frontierV4Worldgen;t.legacyWorldgen=tuning::loadWorldgen(dir+"/worldgen-legacy-v1.json");t.frontierV2Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v2.json");t.frontierV3Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v3.json");
 historical(t);
 for(uint64_t sample=1;sample<=64;++sample)cataclysm(t,sample<=32?sample:sample*2654435761ull);
 check(t.worldgen.nodeTypes.at("copper_vein").era==2&&t.worldgen.nodeTypes.at("silver_vein").era==3,"existing era ore gate changed");
 std::cout<<"CATACLYSM_WORLD "<<checks<<" checks passed"<<std::endl;return 0;
}catch(const std::exception& e){std::cerr<<"FAIL cataclysm: "<<e.what()<<std::endl;return 1;}}
