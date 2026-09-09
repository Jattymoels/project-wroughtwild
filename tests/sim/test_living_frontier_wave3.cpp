#include "wroughtwild/tuning.h"
#include "wroughtwild/loot.h"
#include "wroughtwild/worldgen.h"
#include "wroughtwild/leyline.h"
#include "wroughtwild/contraptions.h"
#include <cmath>
#include <tuple>
#include <iostream>
#include <type_traits>
#include <map>

using namespace wroughtwild;
#include "worldgen_fingerprint.inc"
#include "living_frontier_published.inc"
uint64_t publishedFingerprint(const worldgen::WorldMap& map) {
    ExactWorldFingerprint hash;
    hash.world(map);
    for (const auto& p:map.packs) hash.add(p.frontierHostId);
    for (const auto& h:map.frontierHosts) {
        hash.fields(h.id,h.sourceId,h.enemyId,h.influence); hash.point(h.at); hash.path(h.habits);
    }
    for (const auto& l:map.laboratories) {
        hash.fields(l.id,l.label,l.regionId,l.widthM,l.depthM,l.heightM); hash.point(l.at);
    }
    for (const auto& r:map.futureTransformations) { hash.fields(r.id,r.regionId,r.radiusM); hash.point(r.at); }
    return hash.value;
}
int checks = 0, failures = 0;
void check(bool ok, const std::string& label) {
    ++checks;
    if (!ok) { ++failures; std::cerr << "FAIL LF3: " << label << '\n'; }
}
void routeCheck(const worldgen::WorldMap& map, const std::vector<worldgen::SurfacePoint>& path) {
    check(!path.empty(), "ordinary approach exists");
    bool supported=true, connected=true, shellsClear=true;
    for (size_t i=0;i<path.size();++i) {
        const auto& p=path[i];
        supported &= map.inBounds(p.x,p.z) && map.topSolid(p.x,p.z)==p.y && map.at(p.x,p.z).height==p.y;
        if (i>0) connected &= std::abs(p.x-path[i-1].x)+std::abs(p.z-path[i-1].z)==1 && std::abs(p.y-path[i-1].y)<=1;
        // Independent bounds from the engine shell: the foundation projects
        // .4 m beyond nominal walls, and the ordinary body radius is .42 m.
        for (const auto& lab:map.laboratories)
            if (std::abs(p.x-lab.at.x)*map.cellSize < lab.widthM*.5+.4+.42 &&
                std::abs(p.z-lab.at.z)*map.cellSize < lab.depthM*.5+.4+.42) shellsClear=false;
    }
    check(supported && connected,"entire approach uses supported single steps, no jump skill");
    check(shellsClear,"entire capsule corridor avoids final solid laboratory footprints");
}
void wave3Machines(const tuning::Tuning& tuning, contraptions::Config config) {
    const auto* recipe=tuning.crafting.findRecipe("refine_rustclay_brick");
    config.feederRecipeInputs=recipe->inputs; config.feederRecipeOutputs=recipe->outputs;
    config.feederFuelCost=recipe->fuelCost; config.feederFuels=tuning.crafting.fuels;
    contraptions::MachineWorld m(config,{"living_frontier_wave3",77,{}});
    for (const auto& [key,kind,x]:std::vector<std::tuple<std::string,std::string,double>>{
        {"red","red_heat_buffer",0},{"feeder","pressure_feeder",4},{"lever","stormglass_lever",6},
        {"white","white_connection",8},{"blue","blue_delay",10},{"green","green_junction",12},
        {"drum","cargo_winch",14},{"landing","winch_landing",24}})
        check(m.create(key,kind,{x,0,0}).ok,"new profile accepts inherited fixture: "+key);
    check(m.attachFeeder("feeder","","forge",{4,0,2},true).ok && m.link("red","feeder",true).ok,"heat keeps its own attached receiver");
    check(m.link("lever","white",true).ok && m.link("white","blue",true).ok && m.link("blue","green",true).ok &&
          m.link("green","drum",true).ok && m.linkSecond("green","feeder",true).ok && m.link("drum","landing",true).ok,"complete inherited signal path under new identity");
    economy::Inventory pack{{"red_salt",2},{"raw_clay",8},{"wood",10}};
    check(m.chargeHeat("red",pack,true).ok && !pack.count("red_salt") && m.state("red")->heat==1,"thermal input is actually paid");
    check(m.deposit("feeder","raw_clay",8,pack).moved==8 && m.deposit("drum","wood",10,pack).moved==10,"actual inputs transfer to separate consumers");
    check(!m.wind("red").ok && !m.wind("blue").ok && !m.start("feeder",true).ok,"heat and a signal cannot replace mechanical work");
    check(m.wind("drum").ok && m.wind("feeder").ok,"each receiver separately wound");
    check(m.request("lever",{}).ok && m.advanceDelay("blue",1,{}).ok,"one held request before restart");
    auto saved=m.serialize();
    contraptions::MachineWorld legacy(config,{"living_frontier_wave1",77,{}});
    check(!legacy.restore(saved),"machine payload cannot cross world profiles");
    check(m.restore(saved) && m.serialize()==saved,"new identity restores pending signal, inputs and exact heat");
    check(m.advanceDelay("blue",2,{}).ok && m.state("drum")->moving && m.state("drum")->energy==0 &&
          m.state("feeder")->escrowDrive==1 && m.state("feeder")->escrowHeat==1 && m.state("red")->heat==0,"one release pays each work budget and only the thermal consumer's heat");
    saved=m.serialize();
    check(m.restore(saved) && !m.advanceDelay("blue",100,{}).ok && m.serialize()==saved,"restart cannot replay a consumed signal");
    check(m.advance("drum",100,true).ok && m.advance("feeder",8,true).ok,"paid work completes");
    check(m.withdraw("landing","cargo","wood",10,40,pack).moved==10 && m.state("feeder")->output==config.feederRecipeOutputs,"real delivered cargo and useful bricks retain their distinct owners");
}
int main(int argc, char** argv) {
    const auto t = tuning::loadAll(argc > 1 ? argv[1] : "data/tuning");
    check(t.world.enemies.size() == 11, "published ordinary population and reward pool stay intact");
    for (const auto& host : t.world.frontierEnemies) {
        check(host.worldProfile == "living_frontier_wave3", "new hosts are explicitly scoped");
        check(t.world.findEnemy(host.id) == &host, "native contact/loot resolves the authored host");
        const auto* b = t.realtime.findBehaviour(host.behaviour);
        check(b != nullptr, "native delivery definition exists");
        for (int seed = 0; seed < 100; ++seed) {
            const auto drops = loot::rollEnemyLoot(t.world, host.id, seed);
            check(!drops.empty(), "every host has useful ordinary loot");
            for (const auto& [id, quantity] : drops)
                check(quantity > 0 && id.find("catalyst") == std::string::npos, "new host reward needs no lucky Catalyst");
        }
    }
    const auto& red = *t.world.findEnemy("lf_red_boar");
    const auto& blue = *t.world.findEnemy("lf_blue_boar");
    check(red.visualId == blue.visualId && red.maxLife == blue.maxLife && red.damage == blue.damage,
          "influence spends one shared animal budget rather than adding a full second kit");
    check(red.damageTaken.empty() && blue.damageTaken.empty() && red.immuneStatuses.empty() && blue.immuneStatuses.empty(),
          "ordinary damage and control remain valid for every class");
    for (const auto& r:t.crafting.recipes)
        check(r.availableIn("living_frontier_wave3")==r.availableIn("living_frontier_wave1"),"published recipe policy inherited: "+r.id);
    const auto sources=leyline::Config::load(std::string(argc>1?argv[1]:"data/tuning")+"/leyline.json");
    wave3Machines(t,contraptions::Config::load(std::string(argc>1?argv[1]:"data/tuning")+"/contraptions.json"));
    std::vector<int> seeds={42,77,256,1337,2147483647};
    for (int seed=0;seed<32;++seed) seeds.push_back(seed);
    for (const auto seed: seeds) {
        const auto map=worldgen::generateProfile(t,seed,"living_frontier_wave3");
        check(publishedFingerprint(map)==publishedLF3.at(seed),"published terrain, resources, packs, sites and all owned anchors remain byte exact: "+std::to_string(seed));
        check(map.frontierHosts.size()==4 && map.laboratories.size()==3 && map.futureTransformations.size()==2,"all bounded geography exists from first save");
        routeCheck(map,map.laboratoryTrail);
        for (size_t i=0;i<map.frontierHosts.size();++i) {
            const auto& h=map.frontierHosts[i];
            routeCheck(map,h.approach); routeCheck(map,h.sourceRoute);
            const auto source=leyline::World::anchor(sources.sources[i],map);
            check(source.x==h.sourceRoute.front().x && source.z==h.sourceRoute.front().z,"cue walk starts at its owned source");
            check(std::hypot(h.at.x-map.spawnX,h.at.z-map.spawnZ)>=170,"quiet valley retained even with night aggro");
            const auto drops=loot::rollEnemyLoot(t.world,h.enemyId,seed);
            check(drops.at(sources.sources[i].material)==4,"four useful guaranteed raw units through ordinary loot");
            for (size_t j=0;j<i;++j) check(std::hypot(h.at.x-map.frontierHosts[j].at.x,h.at.z-map.frontierHosts[j].at.z)>=60,"influences taught separately");
        }
        for (const auto& lab:map.laboratories) routeCheck(map,lab.approach);
        for (const auto& region:map.futureTransformations) check(region.radiusM==40,"two bounded future envelopes; no present transform");
        int hosts=0;
        for (const auto& p:map.packs) if (!p.frontierHostId.empty()) {
            ++hosts;check(p.enemies.size()==1 && p.eliteMemberIndex<0 && !p.patrols && !p.hasForeign,"finite host has no forced companion or night patrol");
        }
        check(hosts==4,"one population owner per host");
        std::cout << "LF3_SEED " << seed << " four hosts, three labs, all approaches supported\n";
        if (seed==77) {
            const auto legacy=worldgen::generateProfile(t,seed,"living_frontier_wave1");
            check(map.blocks==legacy.blocks && map.nodes.size()==legacy.nodes.size(),"new composition changes no terrain or resource stock");
            for (size_t n=0;n<map.nodes.size();++n) check(map.nodes[n].resourceId==legacy.nodes[n].resourceId,"source/resource ownership remains stable");
            check(legacy.frontierHosts.empty() && legacy.laboratories.empty(),"old experimental profile receives no new geography");
            const auto again=worldgen::generateProfile(t,seed,"living_frontier_wave3");
            for (size_t i=0;i<map.frontierHosts.size();++i) check(map.frontierHosts[i].at.x==again.frontierHosts[i].at.x && map.frontierHosts[i].at.z==again.frontierHosts[i].at.z,"host layout repeats from identity");
            for (size_t i=0;i<map.laboratories.size();++i) check(map.laboratories[i].at.x==again.laboratories[i].at.x && map.laboratories[i].at.z==again.laboratories[i].at.z,"lab layout repeats from identity");
        }
    }
    std::cout << "LF3_NATIVE " << checks << " checks, " << failures << " failures\n";
    return failures ? 1 : 0;
}
