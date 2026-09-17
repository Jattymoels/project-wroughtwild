// LAND-03 acquisition/identity and one forced generation-fallback check. No renderer/campaign replay.
#include "wroughtwild/leyline.h"
#include "wroughtwild/contraptions.h"
#include "wroughtwild/worldgen.h"
#include <cmath>
#include <iostream>
#include <tuple>
using namespace wroughtwild;
namespace {
int checks=0, failures=0;
void check(bool ok,const std::string& message) { ++checks; if(!ok){++failures;std::cerr<<"FAIL LAND03 acquisition: "<<message<<'\n';} }
std::string replaceOne(std::string value,const std::string& before,const std::string& after) {
    const auto at=value.find(before); if(at==std::string::npos)throw std::runtime_error("test fixture missing "+before);
    value.replace(at,before.size(),after);return value;
}
std::string withoutSource(std::string value,const std::string& id) {
    auto begin=value.find('"'+id+"\":{"); if(begin==std::string::npos)throw std::runtime_error("missing fixture source");
    auto end=value.find('{',begin);int depth=0;
    do {if(value[end]=='{')++depth;else if(value[end]=='}')--depth;++end;} while(depth>0);
    if(value[end]==',')++end;else if(begin>0&&value[begin-1]==',')--begin;
    value.erase(begin,end-begin);return value;
}
}
int main(int argc,char** argv) {
    try {
    const std::string path=argc>1?argv[1]:"data/tuning";
    const auto tuning=tuning::loadAll(path);
    const auto config=leyline::Config::load(path+"/leyline.json");
    check(leyline::supports("frontier_v11")&&!leyline::supports("frontier_v10"),"acquisition capability scoped to fresh V11");
    leyline::World world(config,77,"frontier_v11"), same(config,77,"frontier_v11"), lf(config,77,"living_frontier_wave3");
    economy::PlayerEconomy player(tuning);player.worldProfile="frontier_v11";
    check(player.campaignPolicy=="legacy","ordinary economy keeps legacy campaign");
    world.work("red_home_margin");
    for(int i=0;i<4;++i)world.work("white_home_margin");
    for(int lot=0;lot<8;++lot){
        for(int step=0;step<4;++step)world.work("blue_home_margin");
        const auto claim=world.state("blue_home_margin").claim;
        for(const auto& [item,count]:claim){(void)count;world.collect("blue_home_margin",item,player);}
    }
    world.advance(12.5,{});
    const auto saved=world.serialize();
    check(world.state("red_home_margin").work==1&&world.state("white_home_margin").claim.at("white_mineral")==16&&world.state("blue_home_margin").formation==12.5,"partial work, outstanding claim and depletion clock coexist");
    check(same.restore(saved)&&same.serialize()==saved,"complete ordinary ledger restores exactly");
    for(const auto& corrupt:std::vector<std::string>{
        replaceOne(saved,"frontier_v11","living_frontier_wave1"),
        replaceOne(saved,"\"seed\":\"77\"","\"seed\":\"78\""),
        withoutSource(saved,"green_home_margin"),
        replaceOne(saved,"\"sources\":{","\"sources\":{\"unknown_owner\":{},"),
        replaceOne(saved,"\"version\":4","\"version\":1")})
        check(!same.restore(corrupt)&&same.serialize()==saved,"wrong/missing/extra/historical source payload rejects atomically");
    check(!lf.restore(saved),"same-seed LF world rejects ordinary ledger");
    const auto lfSaved=lf.serialize();
    check(lfSaved.find("\"profile\":\"living_frontier_wave1\"")!=std::string::npos&&lf.restore(lfSaved),"published LF payload tag remains exact");
    check(!same.restore(lfSaved)&&same.serialize()==saved,"same-seed V11 rejects old LF ledger");
    auto historicalConfig=config;historicalConfig.sources.resize(1);
    leyline::World oldRed(historicalConfig,77);oldRed.work("red_home_margin");
    const auto historical=replaceOne(oldRed.serialize(),"\"version\":4","\"version\":1");
    check(lf.restore(historical)&&lf.state("red_home_margin").work==1&&lf.state("white_home_margin").lot==0,"published Red-only LF migration retains work and introduces later sources once");

    same.advance(587.5,{"blue_home_margin"});
    check(same.state("blue_home_margin").formation==600&&same.state("blue_home_margin").manifestation==0,"blocked renewal banks only one eligible manifestation");
    same.advance(.1,{});
    check(same.state("blue_home_margin").manifestation==1&&same.state("blue_home_margin").lot==0,"eligible unblocked renewal follows unchanged contract");
    check(same.state("white_home_margin").claim==world.state("white_home_margin").claim&&same.state("white_home_margin").formation==0,"outstanding claim never reforms stock");

    player.addAvailableStation("workbench");
    for(const auto* id:{"assemble_white_connection","assemble_blue_delay","assemble_green_junction","assemble_red_heat_buffer"}) {
        const auto* recipe=tuning.crafting.findRecipe(id);
        check(recipe&&recipe->availableIn("frontier_v11")&&!recipe->availableIn("frontier_v10"),std::string("recipe capability ")+id);
        if(!recipe)continue;
        player.inventory=recipe->inputs;
        check(player.craft(id).crafted,std::string("paid recipe ")+id);
        for(const auto& [item,count]:recipe->inputs){(void)count;check(player.held(item)==0,std::string("exact ingredient consumed ")+item);}
    }
    auto machines=contraptions::Config::load(path+"/contraptions.json");
    const auto* bricks=tuning.crafting.findRecipe("refine_rustclay_brick");
    machines.feederRecipeInputs=bricks->inputs;machines.feederRecipeOutputs=bricks->outputs;
    machines.feederFuelCost=bricks->fuelCost;machines.feederFuels=tuning.crafting.fuels;
    const contraptions::WorldIdentity identity{"frontier_v11",77,{{"ordinary_pressure",{10,0,0},24}}};
    contraptions::MachineWorld device(machines,identity);
    for(const auto& [key,kind,x]:std::vector<std::tuple<std::string,std::string,double>>{
        {"lever","stormglass_lever",0},{"white","white_connection",2},{"blue","blue_delay",4},
        {"green","green_junction",6},{"drum","cargo_winch",8},{"landing","winch_landing",20},
        {"feeder","pressure_feeder",10},{"red","red_heat_buffer",12}})
        check(device.create(key,kind,{x,0,0}).ok,"ordinary placement "+key);
    check(device.attachFeeder("feeder","ordinary_pressure","forge",{10,0,2},true).ok,"pressure remains separate native owner");
    check(device.link("lever","white",true).ok&&device.link("white","blue",true).ok&&device.link("blue","green",true).ok&&device.link("green","drum",true).ok&&device.linkSecond("green","feeder",true).ok&&device.link("drum","landing",true).ok&&device.link("red","feeder",true).ok,"four-force paid workshop grammar connects");
    economy::Inventory supplies{{"red_salt",2},{"raw_clay",8},{"wood",4}};
    check(device.chargeHeat("red",supplies,true).ok&&supplies.count("red_salt")==0,"Red stores paid heat");
    check(device.deposit("drum","wood",4,supplies).moved==4&&device.deposit("feeder","raw_clay",8,supplies).moved==8,"receivers hold distinct paid material");
    device.wind("drum");device.wind("feeder");
    check(device.pulse("lever",true,true).ok&&device.advanceDelay("blue",.75,{}).ok,"White requests and Blue holds active delay");
    const auto pending=device.serialize();
    contraptions::MachineWorld restored(machines,identity);
    check(restored.restore(pending)&&restored.serialize()==pending,"paid heat and partial request Continue exact");
    for(const auto& corrupt:std::vector<std::string>{
        replaceOne(pending,"frontier_v11","frontier_v10"),
        replaceOne(pending,"\"ordinary_pressure\":24","\"wrong_pressure\":24"),
        replaceOne(pending,"\"sources\":{\"ordinary_pressure\":24}","\"sources\":{}"),
        replaceOne(pending,"\"sources\":{","\"sources\":{\"extra_pressure\":1,"),
        replaceOne(pending,"\"schema\":"+std::to_string(contraptions::saveSchema),"\"schema\":1")})
        check(!restored.restore(corrupt)&&restored.serialize()==pending,"device wrong/missing/extra/source identity rejects atomically");
    check(restored.advanceDelay("blue",2.25,{}).moved==2,"Green branches one delayed request to two useful receivers");
    check(restored.state("drum")->moving&&restored.state("drum")->energy==0&&restored.state("feeder")->escrowHeat==1&&restored.state("red")->heat==0&&restored.state("feeder")->escrowDrive==1,"each receiver pays its own drive and Red heat is separate");
    check(!restored.advanceDelay("blue",3,{}).ok,"consumed request cannot replay after Continue");
    restored.advance("feeder",100,true);
    check(restored.state("feeder")->output==machines.feederRecipeOutputs&&restored.sourceRemaining("ordinary_pressure")==24,"paid heat makes real bricks without recreating/consuming unrequested pressure stock");
    contraptions::MachineWorld old(machines,{"frontier_v10",77,{{"ordinary_pressure",{10,0,0},24}}});
    check(!old.create("red","red_heat_buffer").ok&&old.restore(old.serialize()),"V10 retains no-coloured-device policy and restore");
    {
        auto exhausted=tuning;
        // Fault injection in this test only: -16 exhausts the initial
        // candidateCount+16 loop, exercising its actual deterministic grid
        // fallback. The production JSON loader still rejects counts below 8;
        // no invalid tuning file or runtime test switch is introduced.
        exhausted.frontierV11Worldgen.drySteppe.candidateCount=-16;
        const auto map=worldgen::generateProfile(exhausted,77,"frontier_v11");
        check(map.drySteppe.size()==1&&map.drySteppe.front().fallback,"forced candidate exhaustion delivers the real fallback place");
        const auto dry=[&](int x,int z) {
            if(!map.inBounds(x,z))return false;
            for(const auto& lake:map.lakes)if(lake.bedAt(x,z)<lake.surfaceY)return false;
            return true;
        };
        bool homes=map.homeSites.size()==4;
        for(const auto& home:map.homeSites)for(int dz=-14;dz<=14;++dz)for(int dx=-14;dx<=14;++dx) {
            if(dx*dx+dz*dz>196)continue;
            homes=homes&&dry(home.x+dx,home.z+dz)&&map.topSolid(home.x+dx,home.z+dz)==home.y;
        }
        check(homes,"fallback retains all four full level dry home cores");
        const auto validRoute=[&](const std::vector<worldgen::SurfacePoint>& route) {
            if(route.empty())return false;
            for(size_t i=0;i<route.size();++i) {
                const auto& at=route[i];
                if(!dry(at.x,at.z)||map.topSolid(at.x,at.z)!=at.y)return false;
                if(i&&std::abs(at.y-route[i-1].y)>1)return false;
            }
            return true;
        };
        bool anchors=map.leylineSourceSites.size()==4;
        for(const auto& source:map.leylineSourceSites) {
            anchors=anchors&&validRoute(source.approach);
            for(int dz=-2;dz<=2;++dz)for(int dx=-2;dx<=2;++dx)
                anchors=anchors&&dry(source.at.x+dx,source.at.z+dz)&&map.topSolid(source.at.x+dx,source.at.z+dz)==source.at.y;
        }
        check(anchors,"fallback has four supported dry flat work anchors and real approaches");
        const auto& place=map.drySteppe.front();
        bool different=place.ridgeRoute.size()!=place.lowRoute.size();
        if(!different)for(size_t i=0;i<place.ridgeRoute.size();++i)
            if(place.ridgeRoute[i].x!=place.lowRoute[i].x||place.ridgeRoute[i].z!=place.lowRoute[i].z){different=true;break;}
        check(different&&validRoute(place.ridgeRoute)&&validRoute(place.lowRoute),"fallback retains two distinct usable dry approaches");
        const double separation=std::hypot(place.redHost.x-place.redSource.x,place.redHost.z-place.redSource.z);
        check(map.frontierHosts.size()==1&&map.frontierHosts.front().enemyId=="lf_red_boar"&&separation>=65&&separation<=130&&std::hypot(place.redHost.x-map.spawnX,place.redHost.z-map.spawnZ)>=170,"fallback retains one finite Red host beyond quiet start and away from source work");
        check(map.regions.size()==3&&map.rareSites.size()==14&&map.pressurePockets.size()==1&&map.laboratories.empty()&&map.futureTransformations.empty(),"fallback preserves finite discovery owners without importing LF campaign");
    }
    } catch(const std::exception& e){check(false,std::string("unexpected exception: ")+e.what());}
    std::cout<<"LAND03 acquisition: "<<checks<<" checks, "<<failures<<" failures\n";
    return failures?1:0;
}
