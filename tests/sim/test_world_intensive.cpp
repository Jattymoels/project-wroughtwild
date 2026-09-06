#include "wroughtwild/worldgen.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <set>
#include <stdexcept>

using namespace wroughtwild;
namespace {
int checks = 0;
void check(bool ok, const std::string& message) {
    ++checks;
    if (!ok) throw std::runtime_error(message);
}
// Captured against the unmodified generator on 6 Sep 2026. Fields include
// every block, node, landmark, pack member, elite and patrol route.
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
void legacy(const tuning::Tuning& t) {
    const std::pair<uint64_t,uint64_t> snapshots[] = {
        {1,9567315995627226133ull},{7,5936621565493496066ull},
        {24,13276267164882187656ull},{91,9716464632784557402ull}};
    for (auto snapshot : snapshots) {
        auto map = worldgen::generateProfile(t,snapshot.first,"legacy_v1");
        check(fingerprint(map)==snapshot.second,"legacy geography changed at seed "+std::to_string(snapshot.first));
        check(map.habitats.empty(),"legacy save received new habitats");
        for (const auto& node : map.nodes)
            check(node.resourceId=="wn_"+node.type+"_"+std::to_string(node.x)+"_"+std::to_string(node.y)+"_"+std::to_string(node.z),"legacy resource ID changed");
    }
    auto edited=t;
    edited.worldgen.map.heightScale+=8;
    edited.worldgen.biomes.clear();
    edited.world.eliteModifiers.clear();
    check(fingerprint(worldgen::generateProfile(edited,1,"legacy_v1"))==snapshots[0].second,
          "live tuning changed frozen legacy generation");
    bool rejected=false;
    try { worldgen::generateProfile(t,1,"future_unknown"); } catch(const std::runtime_error&) {rejected=true;}
    check(rejected,"unknown profile must reject");
}
void habitats(const tuning::Tuning& t) {
    for (uint64_t sample=1;sample<=64;++sample) {
        // Sequential release seeds plus widely separated large identities.
        const uint64_t seed = sample <= 24 ? sample : sample * 2654435761ull;
        const auto map=worldgen::generateProfile(t,seed,"frontier_v2");
        check(map.habitats.size()==3,"three habitats at seed "+std::to_string(seed));
        std::set<std::string> identities;
        for(const auto& node:map.nodes) check(identities.insert(node.resourceId).second,"duplicate resource identity");
        for(const auto& habitat:map.habitats) {
            const auto& def=*std::find_if(t.frontierV2Worldgen.habitats.begin(),t.frontierV2Worldgen.habitats.end(),[&](const auto& h){return h.id==habitat.id;});
            check(!habitat.approach.empty(),"habitat has no approach");
            const auto& first=habitat.approach.front();
            const auto& last=habitat.approach.back();
            check(first.x==map.spawnX&&first.z==map.spawnZ&&last.x==habitat.x&&last.z==habitat.z,"approach endpoints incorrect");
            bool clearApproach=true;
            for(size_t i=0;i<habitat.approach.size();++i) {
                const auto& p=habitat.approach[i];
                check(map.blockAt(p.x,p.y,p.z)==worldgen::kAir&&map.blockAt(p.x,p.y-1,p.z)!=worldgen::kAir,"unsupported habitat approach");
                if(i){const auto& prev=habitat.approach[i-1];check(std::abs(p.x-prev.x)+std::abs(p.z-prev.z)==1&&std::abs(p.y-prev.y)<=1,"approach cannot be walked");}
                for(const auto& node:map.nodes) {
                    if(node.y!=map.at(node.x,node.z).height)continue;
                    const int dx=p.x-node.x,dz=p.z-node.z;
                    if(dx*dx+dz*dz<=1)clearApproach=false;
                }
            }
            check(clearApproach,"resource blocks habitat approach");
            for(const auto& resource:def.resources) {
                int count=0;
                for(const auto& node:map.nodes) if(node.habitatId==habitat.id&&node.type==resource.nodeType) {
                    ++count;
                    check(node.y==map.topSolid(node.x,node.z),"habitat resource not grounded");
                    const int dx=node.x-habitat.x,dz=node.z-habitat.z;
                    check(dx*dx+dz*dz<=def.radiusM*def.radiusM,"habitat resource escaped its footprint");
                }
                check(count==resource.count,"incomplete habitat resource set");
            }
            if(seed==1)std::cout<<"WORLD_SITE "<<habitat.id<<" "<<habitat.x<<","<<habitat.y<<","<<habitat.z<<" biome="<<habitat.biome<<"\n";
        }
        const auto& g=t.frontierV2Worldgen.guarantees;
        for(const auto& minimum:g.minNodesNear)check(map.countNodesNear(minimum.first,map.spawnX,map.spawnZ,g.nearRadiusM)>=minimum.second,"starter guarantee changed");
        for(const auto& minimum:g.minNodesFar)check(map.countNodesNear(minimum.first,map.spawnX,map.spawnZ,g.farRadiusM)>=minimum.second,"iron guarantee changed");
        if(seed==7){
            auto reordered=t;
            std::reverse(reordered.frontierV2Worldgen.habitats.begin(),reordered.frontierV2Worldgen.habitats.end());
            for(auto& h:reordered.frontierV2Worldgen.habitats)std::reverse(h.resources.begin(),h.resources.end());
            const auto again=worldgen::generateProfile(reordered,seed,"frontier_v2");
            check(fingerprint(map)==fingerprint(again),"definition ordering changes resource positions");
            for(size_t i=0;i<map.nodes.size();++i)check(map.nodes[i].resourceId==again.nodes[i].resourceId,"unstable resource ID");
        }
        std::cout<<"WORLD_SEED "<<seed<<" habitats="<<map.habitats.size()<<"\n";
    }
}
void materials(const tuning::Tuning& t) {
    const char* families[]={"slate","shellstone","rustclay_brick","woven_reed","resinheart","corkbark","vitrified_basalt","cinderglass"};
    const char* raw[]={"raw_slate","raw_shellstone","raw_clay","raw_reed","resinheart_log","raw_corkbark","furnace_slag","cinderglass_shard"};
    for(size_t i=0;i<8;++i){
        const std::string id=families[i];
        const auto* family=t.construction.findMaterial(id);
        const auto* recipe=t.crafting.findRecipe("refine_"+id);
        check(family&&recipe,"missing family or refining recipe "+id);
        check(family->source==id&&recipe->outputs.count(id),"recipe does not feed family "+id);
        check(!t.construction.findMaterial(raw[i]),"raw resource appears in building catalogue");
    }
    for(const auto* id:{"woven_reed","corkbark"}){
        const auto& family=*t.construction.findMaterial(id);
        for(const auto* shape:{"cube","door","chest"})check(!t.construction.shapeAllowsMaterial(*t.construction.findShape(shape),family),"cladding accepted structural object");
        for(const auto* shape:{"light_panel","codex_roof_slope","codex_roof_hip","codex_roof_valley"})check(t.construction.shapeAllowsMaterial(*t.construction.findShape(shape),family),"cladding rejected covering form");
    }
    const auto& glass=*t.construction.findMaterial("cinderglass");
    for(const auto& shape:t.construction.shapes)check(t.construction.shapeAllowsMaterial(shape,glass)==(shape.id=="glazed_window"),"glass accepted non-window or rejected window");
    for(const auto* id:{"wood","pine","bog_oak","ash_wood","iron","bronze","steel"})
        for(const auto* shape:{"codex_roof_slope","codex_roof_hip","codex_roof_valley"})
            check(t.construction.shapeAllowsMaterial(*t.construction.findShape(shape),*t.construction.findMaterial(id)),"old roof family lost eligibility");
}
} // namespace

int main(int argc,char** argv) {
    try {
        const std::string dir=argc>1?argv[1]:"data/tuning";
        tuning::Tuning t;
        t.worldgen=tuning::loadWorldgen(dir+"/worldgen.json");
        t.legacyWorldgen=tuning::loadWorldgen(dir+"/worldgen-legacy-v1.json");
        t.frontierV2Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v2.json");
        t.world=tuning::loadWorld(dir+"/world.json");
        t.construction=tuning::loadConstruction(dir+"/construction.json");
        t.crafting=tuning::loadCrafting(dir+"/crafting.json");
        legacy(t);habitats(t);materials(t);
        std::cout<<"WORLD_INTENSIVE "<<checks<<" checks passed\n";
    } catch(const std::exception& e) { std::cerr<<"FAIL world intensive: "<<e.what()<<"\n";return 1; }
}
