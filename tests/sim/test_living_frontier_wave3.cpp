#include "wroughtwild/tuning.h"
#include "wroughtwild/loot.h"
#include "wroughtwild/worldgen.h"
#include "wroughtwild/leyline.h"
#include <cmath>
#include <iostream>

using namespace wroughtwild;
int checks = 0, failures = 0;
void check(bool ok, const std::string& label) {
    ++checks;
    if (!ok) { ++failures; std::cerr << "FAIL LF3: " << label << '\n'; }
}
void routeCheck(const worldgen::WorldMap& map, const std::vector<worldgen::SurfacePoint>& path) {
    check(!path.empty(), "ordinary approach exists");
    bool supported=true, connected=true;
    for (size_t i=0;i<path.size();++i) {
        const auto& p=path[i];
        supported &= map.inBounds(p.x,p.z) && map.topSolid(p.x,p.z)==p.y && map.at(p.x,p.z).height==p.y;
        if (i>0) connected &= std::abs(p.x-path[i-1].x)+std::abs(p.z-path[i-1].z)==1 && std::abs(p.y-path[i-1].y)<=1;
    }
    check(supported && connected,"entire approach uses supported single steps, no jump skill");
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
    std::vector<int> seeds={42,77,256,1337,2147483647};
    for (int seed=0;seed<32;++seed) seeds.push_back(seed);
    for (const auto seed: seeds) {
        const auto map=worldgen::generateProfile(t,seed,"living_frontier_wave3");
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
