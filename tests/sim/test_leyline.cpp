#include "wroughtwild/leyline.h"
#include "wroughtwild/json.h"
#include <iostream>
#include <cmath>
#include <limits>

using namespace wroughtwild;
int checks=0, failures=0;
void check(bool ok,const std::string& label) { ++checks; if (!ok) { ++failures; std::cerr << "FAIL LF1: " << label << '\n'; } }
int main(int argc,char** argv) {
    const std::string path=argc>1 ? argv[1] : "data/tuning";
    const auto tuning=tuning::loadAll(path);
    const auto config=leyline::Config::load(path+"/leyline.json");
    const auto& source=config.sources.front();
    int winners=0, lots=0, droughts=0;
    for (int seed=0;seed<256;++seed) {
        leyline::World world(config,seed), other(config,seed);
        economy::PlayerEconomy player(tuning);
        check(world.serialize()==other.serialize(),"formation is deterministic");
        const auto fixed=world.state(source.id).outcomes;
        if (fixed.find('1')==std::string::npos) ++droughts;
        for (int lot=0;lot<source.lots;++lot) {
            for (size_t step=0;step<source.stages.size();++step) {
                check(world.work(source.id).ok,"safe manual work");
                check(other.restore(world.serialize()),"interruption restores whole source");
                check(other.serialize()==world.serialize() && world.state(source.id).outcomes==fixed,"partial work cannot reroll");
            }
            ++lots;
            if (fixed[lot]=='1') ++winners;
            const auto saved=world.serialize();
            check(!world.work(source.id).ok && world.serialize()==saved,"uncollected claim cannot produce another lot");
            player.inventory[source.material]=player.carryCap(source.material);
            check(!world.collect(source.id,source.material,player).ok && world.serialize()==saved,"full pack retains exact claim");
            player.inventory[source.material]-=3;
            check(world.collect(source.id,source.material,player).moved==3,"partial raw transfer");
            check(other.restore(world.serialize()) && other.state(source.id).claim.at(source.material)==source.units-3,"partial collection survives restart");
            player.inventory.clear();
            check(world.collect(source.id,source.material,player).moved==source.units-3,"remaining raw transfers once");
            if (fixed[lot]=='1') {
                player.inventory[source.rareItem]=player.carryCap(source.rareItem);
                check(!world.collect(source.id,source.rareItem,player).ok,"full rare family retains intact find");
                player.inventory.clear();
                check(world.collect(source.id,source.rareItem,player).moved==1 && !world.collect(source.id,source.rareItem,player).ok,"rare claim once only");
            }
            check(!world.collect(source.id,source.material,player).ok,"claimed raw cannot duplicate");
        }
        check(!world.work(source.id).ok,"spent manifestation has no stock");
        world.advance(123,{});
        check(other.restore(world.serialize()) && other.state(source.id).formation==123,"fractional formation restarts");
        world.advance(100000,{source.id});
        check(world.state(source.id).formation==source.formationSeconds && world.state(source.id).manifestation==0,"blocked host caps credit");
        world.advance(.01,{});
        check(world.state(source.id).manifestation==1 && world.state(source.id).lot==0,"one fresh manifestation only");
        const auto ready=world.serialize();
        world.advance(100000,{});
        check(world.serialize()==ready,"ready stock banks no credit");
        leyline::World wrong(config,seed+1);
        check(!wrong.restore(ready),"wrong seed rejected");
        auto bad=ready; bad.replace(bad.find("\"work\":0"),8,"\"work\":99");
        check(!world.restore(bad) && world.serialize()==ready,"malformed restore refuses atomically");
    }
    check(winners>40 && winners<130 && droughts>150,"measured rarity and drought remain bonus scale");
    economy::PlayerEconomy player(tuning);
    player.addAvailableStation("forge_basic"); player.inventory={{"raw_clay",8},{"red_salt",2}};
    check(!player.craft("fire_red_brick").crafted,"legacy cannot use experimental recipe");
    player.worldProfile=leyline::profile;
    check(player.craft("fire_red_brick").crafted && player.inventory.at("rustclay_brick")==4 && player.inventory.at("raw_clay")==0 && player.inventory.at("red_salt")==0,"paid zero-Catalyst bricks retain clay/output");
    check(!tuning.crafting.fuels.count("red_salt"),"Red is not universal fuel");
    const auto* original=tuning.crafting.findRecipe("refine_rustclay_brick");
    check(original && original->inputs==economy::Inventory{{"raw_clay",8}} && original->outputs==economy::Inventory{{"rustclay_brick",4}} && original->fuelCost==1,"original bricks unchanged");
    for (int seed : {1,77,2026}) {
        const auto map=worldgen::generateProfile(tuning,seed,leyline::profile);
        check(map.profileId==leyline::profile && map.homeSites.size()==4,"opt-in world has existing guaranteed approaches");
        for (const auto& s : config.sources) {
            const auto at=leyline::World::anchor(s,map);
            check(map.topSolid(at.x,at.z)==at.y && !map.homeSites[s.homeIndex].approach.empty(),"source on reachable supported home margin");
            for (const auto& n : map.nodes) check(std::hypot(n.x-at.x,n.z-at.z)*map.cellSize>2,"source clear of finite resource bodies");
        }
    }
    std::cout << "LF1_NATIVE " << checks << " checks, " << failures << " failures; " << winners << '/' << lots << " winning lots, " << droughts << "/256 first-manifestation droughts\n";
    return failures ? 1 : 0;
}
