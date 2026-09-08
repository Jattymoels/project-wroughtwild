#include "wroughtwild/leyline.h"
#include "wroughtwild/json.h"
#include "wroughtwild/contraptions.h"
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
    const auto& white=config.sources.at(1);
    check(white.material=="white_mineral" && white.rareItem.empty() && white.rarePer10000==0,"White is useful raw only in Wave 1");
    for (int seed=0;seed<32;++seed) {
        auto oldConfig=config; oldConfig.sources.resize(1);
        leyline::World oldWorld(oldConfig,seed), migrated(config,seed);
        // Exact schema published in LF-1A/B, interrupted or holding a raw/rare claim.
        for (int i=0;i<1+seed%4;++i) oldWorld.work(source.id);
        auto v1=oldWorld.serialize(); v1.replace(v1.find("\"version\":2"),11,"\"version\":1");
        check(migrated.restore(v1),"published Red-only ledger migrates");
        check(migrated.state(source.id).outcomes==oldWorld.state(source.id).outcomes && migrated.state(source.id).work==oldWorld.state(source.id).work && migrated.state(source.id).claim==oldWorld.state(source.id).claim,"migration keeps exact Red work, rare rolls and claims");
        check(migrated.state(white.id).lot==0 && migrated.state(white.id).work==0,"migration introduces White once at its authored initial stock");
        const auto before=migrated.serialize();
        check(!migrated.restore(oldWorld.serialize()) && migrated.serialize()==before,"current schema missing White rejects without refilling");
        economy::PlayerEconomy holder(tuning);
        for (int lot=0;lot<white.lots;++lot) {
            for (size_t step=0;step<white.stages.size();++step) {
                check(migrated.work(white.id).ok,"White safe manual work");
                leyline::World reloaded(config,seed);
                check(reloaded.restore(migrated.serialize()) && reloaded.serialize()==migrated.serialize(),"White interruption restores exactly");
            }
            holder.inventory[white.material]=holder.carryCap(white.material);
            check(!migrated.collect(white.id,white.material,holder).ok,"full White family retains released output");
            holder.inventory[white.material]-=3;
            check(migrated.collect(white.id,white.material,holder).moved==3,"White partial claim transfers once");
            const auto partial=migrated.serialize();
            check(migrated.restore(partial) && migrated.serialize()==partial,"White partial claim survives reload");
            holder.inventory.clear();
            check(migrated.collect(white.id,white.material,holder).moved==white.units-3,"White remaining claim conserved");
            check(!migrated.collect(white.id,white.material,holder).ok,"White claim cannot duplicate");
        }
        migrated.advance(123,{});
        const auto spent=migrated.serialize();
        check(migrated.restore(spent) && migrated.state(white.id).formation==123,"spent White formation clock persists");
        migrated.advance(9999,{white.id});
        check(migrated.state(white.id).manifestation==0 && migrated.state(white.id).formation==white.formationSeconds,"blocked White caps one formation");
        migrated.advance(.1,{});
        check(migrated.state(white.id).manifestation==1 && migrated.state(white.id).lot==0,"White reforms once after active credit");
    }
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
    const auto* catalyst=tuning.crafting.findRecipe("forge_faint_ember");
    check(catalyst && catalyst->inputs==economy::Inventory{{"red_salt",96},{"iron_ingot",4},{"charcoal",8}} && catalyst->fuelCost==0,"costly ordinary Ember has its complete heat in explicit inputs");
    for (const auto& [item,count] : catalyst->inputs) check(count<=player.carryCap(item),"whole conversion fits permitted carried family: "+item);
    for (const auto& missing : catalyst->inputs) {
        player.inventory=catalyst->inputs; --player.inventory[missing.first];
        const auto before=player.inventory;
        check(!player.craft(catalyst->id).crafted && player.inventory==before,"missing ordinary input refuses without payment");
    }
    player.inventory=catalyst->inputs;
    check(player.craft(catalyst->id).crafted && player.held("ember_catalyst")==1 && player.held("red_salt")==0 && player.held("iron_ingot")==0 && player.held("charcoal")==0,"exact paid Faint manufacture");
    check(player.foundryPlaceSkill(1,1,"prototype_heavy_strike"),"ordinary known tablet fits first-era socket");
    player.foundryEvent("recipe:smelt_iron"); // native fixture; engine journey earns this by paid smelting
    check(player.foundryPlace(1,0,"ember") && player.foundryPlaceKind(2,0,"ember_catalyst") && player.held("ember_catalyst")==0,"manufactured existing Kind takes its normal persistent route");
    economy::PlayerEconomy restored(tuning); restored.importState(player.exportState());
    check(restored.foundry().plate.size()==player.foundry().plate.size(),"persistent Kind layout survives economy restoration");
    player.inventory={{"iron_ore",1},{"charcoal",2},{"wood",2}};
    check(!player.craft("distil_ember").crafted,"experiment closes replaced iron-only recipe");
    for (const auto& profile : {"legacy_v1","frontier_v6"}) {
        player.worldProfile=profile;
        check(!player.craft(catalyst->id).crafted && player.craft("distil_ember").crafted,"legacy keeps original acquisition");
        player.inventory={{"iron_ore",1},{"charcoal",2},{"wood",2}};
    }
    player.worldProfile=leyline::profile; player.inventory=catalyst->inputs;
    player.inventory["ember_catalyst"]=player.carryCap("ember_catalyst");
    check(player.craft(catalyst->id).crafted && player.held("ember_catalyst")==player.carryCap("ember_catalyst")+1,"full gathered family preserves existing uncapped crafted-output rule");
    restored.importState(player.exportState());
    check(restored.held("ember_catalyst")==player.held("ember_catalyst"),"above-gathering-cap forged output survives restore without loss");
    economy::PlayerEconomy grades(tuning); grades.worldProfile=leyline::profile;
    grades.addAvailableStation("forge_improved"); grades.grantSkillXp("blacksmithing",10000);
    for (const auto& era : tuning.eras.eras) if (!era.triggerWorldEffect.empty()) grades.recordWorldEffect(era.triggerWorldEffect);
    grades.grant("ember_catalyst",1); grades.grant("bog_iron",1); grades.grant("wood",5);
    check(grades.craft("refine_stable_ember_catalyst").crafted && grades.held("ember_catalyst")==0 && grades.held("stable_ember_catalyst")==1,"existing paid Stable refinement preserved");
    grades.grant("silver_ingot",1); grades.grant("steel_ingot",1);
    check(grades.craft("refine_potent_ember_catalyst").crafted && grades.held("stable_ember_catalyst")==0 && grades.held("potent_ember_catalyst")==1,"existing paid Potent refinement preserved");
    player.inventory={{"white_mineral",2},{"wood",2}}; player.addAvailableStation("workbench");
    check(player.craft("assemble_white_connection").crafted && player.held("white_connection_kit")==1 && player.held("white_mineral")==0 && player.held("wood")==0,"cheap White kit pays both ordinary ingredients");
    const auto machines=contraptions::Config::load(path+"/contraptions.json");
    contraptions::MachineWorld machine(machines,{leyline::profile,77,{}}), legacy(machines);
    check(!legacy.create("white","white_connection").ok,"legacy machine worlds reject experimental placement");
    for (const auto& entry : std::vector<std::pair<std::string,std::array<double,3>>>{{"stormglass_lever",{0,0,0}},{"white_connection",{6,0,0}},{"cargo_winch",{12,0,0}},{"winch_landing",{24,0,0}}})
        check(machine.create(entry.first,entry.first,entry.second).ok,"ordinary native fixture placement: "+entry.first);
    check(machine.link("cargo_winch","winch_landing",true).ok && machine.link("stormglass_lever","white_connection",true).ok,"connect landing and White input");
    check(!machine.pulse("stormglass_lever",true,true).ok,"disconnected White cannot request movement");
    check(!machine.link("white_connection","stormglass_lever",true).ok && !machine.link("white_connection","white_connection",true).ok,"bounded topology rejects cycles and self links");
    check(machine.link("white_connection","cargo_winch",true).ok,"White selects its one cargo drum");
    check(!machine.wind("white_connection").ok,"connection cannot store drive");
    check(!machine.pulse("stormglass_lever",true,true).ok && machine.state("cargo_winch")->energy==0 && machine.state("white_connection")->pulses==1,"empty drive receives visible request without motion or energy");
    auto idle=machine.serialize(); check(machine.restore(idle) && machine.serialize()==idle,"failed request is not a queued restart task");
    economy::Inventory cargo{{"red_salt",16}};
    check(machine.deposit("cargo_winch","red_salt",16,cargo).moved==16 && cargo.empty(),"real cargo has one drum owner");
    check(machine.wind("cargo_winch").ok,"manual winding supplies work");
    idle=machine.serialize();
    check(!machine.pulse("stormglass_lever",false,true).ok && machine.serialize()==idle,"blocked signal preserves exact drive, cargo and counters");
    check(!machine.pulse("stormglass_lever",true,false).ok && machine.state("cargo_winch")->energy==1,"blocked cargo span cannot spend winding");
    check(machine.pulse("stormglass_lever",true,true).ok && machine.state("cargo_winch")->energy==0 && machine.state("cargo_winch")->moving,"White request spends exactly the drum's one stored work");
    check(!machine.pulse("stormglass_lever",true,true).ok && machine.state("cargo_winch")->energy==0,"repeated signal cannot start a second trip");
    check(machine.advance("cargo_winch",.5,true).ok,"paid trip starts to travel");
    auto travelling=machine.serialize();
    check(!machine.advance("cargo_winch",100,false).ok && machine.serialize()==travelling,"blocked travelling cargo pauses intact");
    check(machine.link("white_connection","",true).ok && machine.state("cargo_winch")->moving,"disconnect does not recall or clone in-flight cargo");
    travelling=machine.serialize();
    check(machine.restore(travelling) && machine.serialize()==travelling,"mid-trip disconnect and cargo restore exactly");
    check(machine.advance("cargo_winch",100,true).ok && machine.state("cargo_winch")->atLanding && machine.state("cargo_winch")->completedTrips==1,"saved paid trip arrives once");
    check(!machine.withdraw("winch_landing","cargo","red_salt",16,0,cargo).ok,"full landing collection keeps drum cargo");
    check(machine.withdraw("winch_landing","cargo","red_salt",16,3,cargo).moved==3,"partial landing collection");
    const auto delivered=machine.serialize();
    check(machine.restore(delivered) && machine.withdraw("winch_landing","cargo","red_salt",16,40,cargo).moved==13 && cargo.at("red_salt")==16,"restart retains exact remaining landing cargo");
    check(!machine.withdraw("winch_landing","cargo","red_salt",16,40,cargo).ok,"delivered cargo cannot be collected twice");
    check(machine.erase("white_connection",cargo).ok && machine.state("stormglass_lever")->link.empty() && machine.state("cargo_winch")->completedTrips==1,"dismantling disconnects input while retaining delivered trip");
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
