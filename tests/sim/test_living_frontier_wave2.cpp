#include "wroughtwild/leyline.h"
#include "wroughtwild/contraptions.h"
#include "wroughtwild/grammar.h"
#include <iostream>
#include <limits>
#include <tuple>
using namespace wroughtwild;
int checks=0, failures=0;
void check(bool ok,const std::string& label) { ++checks; if (!ok) { ++failures; std::cerr<<"FAIL LF2: "<<label<<'\n'; } }
void replaceAll(std::string& text,const std::string& old,const std::string& next) {
    size_t at=0; while ((at=text.find(old,at))!=std::string::npos) { text.replace(at,old.size(),next); at+=next.size(); }
}
void blue(const tuning::Tuning& tuning,const leyline::Config& sources,contraptions::Config config) {
    check(sources.sources.at(2).material=="blue_flake","Blue has actual raw material");
    for (int version : {1,2,3}) for (int seed=0;seed<16;++seed) {
        auto old=sources; old.sources.resize(version);
        leyline::World previous(old,seed),next(sources,seed);
        for (const auto& source : old.sources) for (int i=0;i<1+seed%4;++i) previous.work(source.id);
        auto payload=previous.serialize(); replaceAll(payload,"\"version\":"+std::to_string(leyline::saveVersion),"\"version\":"+std::to_string(version));
        check(next.restore(payload),"published version "+std::to_string(version)+" migrates");
        for (const auto& source : old.sources) {
            const auto& a=previous.state(source.id); const auto& b=next.state(source.id);
            check(a.outcomes==b.outcomes && a.work==b.work && a.claim==b.claim && a.lot==b.lot && a.formation==b.formation,"migration preserves original source ledger");
        }
        const auto complete=next.serialize();
        check(next.restore(complete) && next.serialize()==complete,"current migration result reloads exactly");
        check(!next.restore(previous.serialize()) && next.serialize()==complete,"current missing host refuses atomically");
    }
    economy::PlayerEconomy player(tuning); player.worldProfile=leyline::profile; player.addAvailableStation("workbench");
    leyline::World world(sources,77);
    const auto& source=sources.sources.at(2);
    for (int i=0;i<4;++i) check(world.work(source.id).ok,"Blue safe manual work");
    player.inventory[source.material]=player.carryCap(source.material);
    check(!world.collect(source.id,source.material,player).ok,"full Blue pack retains claim");
    player.inventory[source.material]-=3;
    check(world.collect(source.id,source.material,player).moved==3,"partial Blue claim");
    auto saved=world.serialize(); check(world.restore(saved) && world.serialize()==saved,"partial Blue collection saved");
    player.inventory.clear(); check(world.collect(source.id,source.material,player).moved==13,"Blue remainder once");
    player.grant("wood",2);
    check(player.craft("assemble_blue_delay").crafted && player.held("blue_flake")==11 && player.held("blue_delay_kit")==1,"actual Blue pays cheap kit");
    contraptions::MachineWorld m(config,{leyline::profile,77,{}}), normal(config);
    check(!normal.create("blue","blue_delay").ok,"normal worlds reject Blue placement");
    for (const auto& [key,kind,x] : std::vector<std::tuple<std::string,std::string,double>>{
        {"lever","stormglass_lever",0},{"white","white_connection",2},{"blue","blue_delay",4},{"drum","cargo_winch",6},{"landing","winch_landing",18}})
        check(m.create(key,kind,{x,0,0}).ok,"placed native "+key);
    check(m.link("lever","white",true).ok && m.link("white","blue",true).ok && m.link("blue","drum",true).ok && m.link("drum","landing",true).ok,"ordered paid signal path");
    for (const auto* target : {"lever","white","blue"}) check(!m.link("blue",target,true).ok,"Blue rejects loop/backwards target");
    check(!m.wind("blue").ok,"Blue cannot create mechanical work");
    economy::Inventory pack{{"wood",10}};
    check(m.deposit("drum","wood",10,pack).moved==10 && m.wind("drum").ok,"cargo and independent drive paid");
    check(m.pulse("lever",true,true).ok && m.state("blue")->pendingRequest && !m.state("drum")->moving,"one request held before departure");
    check(m.advanceDelay("blue",.75,true,true).ok,"fractional Blue progress");
    saved=m.serialize();
    check(!m.pulse("lever",true,true).ok && m.serialize()==saved,"repeat request cannot reset or queue");
    check(!m.advanceDelay("blue",100,false,true).ok && m.serialize()==saved,"blocked output retains exact countdown");
    check(m.pause("blue",true).ok,"explicit pause");
    saved=m.serialize();
    check(!m.advanceDelay("blue",100,true,true).ok && m.serialize()==saved,"paused request banks no time");
    check(m.restore(saved) && m.serialize()==saved && m.pause("blue",false).ok,"restart preserves explicit pause and fraction");
    check(m.advanceDelay("blue",config.delaySeconds-.8,true,true).ok && !m.state("drum")->moving,"receiver waits full selected delay");
    check(m.advanceDelay("blue",.051,true,true).ok && m.state("drum")->moving && m.state("drum")->energy==0 && !m.state("blue")->pendingRequest,"release spends one winding once");
    saved=m.serialize(); check(m.restore(saved) && !m.advanceDelay("blue",100,true,true).ok && m.serialize()==saved,"delivered request cannot replay after restart");
    check(m.advance("drum",100,true).ok && m.withdraw("landing","cargo","wood",10,40,pack).moved==10,"delayed cargo delivered once");
    check(m.pulse("lever",true,true).ok && !m.advanceDelay("blue",100,true,true).ok && !m.state("blue")->pendingRequest,"unwound receiver rejects release without retaining future work");
    check(m.wind("drum").ok && !m.advanceDelay("blue",100,true,true).ok && !m.state("drum")->moving,"later winding cannot resurrect failed request");
    for (const auto& [from,to] : std::vector<std::pair<std::string,std::string>>{{"lever","white"},{"white","blue"},{"blue","drum"}}) {
        check(m.pulse("lever",true,true).ok,"prepare pending disconnect case");
        check(m.link(from,"",true).ok && !m.state("blue")->pendingRequest,"upstream/downstream disconnect cancels pending request");
        check(m.link(from,to,true).ok && !m.advanceDelay("blue",100,true,true).ok,"reconnect cannot replay");
    }
    check(m.pulse("lever",true,true).ok && m.cancel("blue").ok && !m.cancel("blue").ok,"cancel once only");
    check(m.pulse("lever",true,true).ok && !m.advanceDelay("blue",100,true,false).ok && m.state("drum")->energy==1 && !m.state("blue")->pendingRequest,"blocked cargo refuses at release without consuming drive");
    check(m.pulse("lever",true,true).ok,"prepare saved corruption");
    saved=m.serialize(); auto bad=saved; replaceAll(bad,"\"delay_seconds\":0","\"delay_seconds\":-1");
    check(!m.restore(bad) && m.serialize()==saved,"malformed countdown refuses before mutation");
    check(m.erase("blue",pack).ok && m.state("white")->link.empty() && m.state("drum")->energy==1,"dismantling pending delay preserves receiver resources");
    // Preserve an actual old-machine shape, including its winding and cargo.
    saved=m.serialize(); auto v2=saved;
    replaceAll(v2,"\"schema\":"+std::to_string(contraptions::saveSchema),"\"schema\":2");
    replaceAll(v2,",\"pending_request\":false,\"delay_paused\":false,\"delay_seconds\":0","");
    replaceAll(v2,",\"second_link\":\"\",\"second_span_length\":0","");
    replaceAll(v2,",\"heat\":0,\"heat_key\":\"\",\"escrow_heat\":0","");
    check(m.restore(v2) && m.serialize()==saved,"published Wave 1 machine payload migrates without reset");
}
void green(const tuning::Tuning& tuning,const leyline::Config& sources,contraptions::Config config) {
    const auto* recipe=tuning.crafting.findRecipe("refine_rustclay_brick");
    config.feederRecipeInputs=recipe->inputs; config.feederRecipeOutputs=recipe->outputs;
    config.feederFuelCost=recipe->fuelCost; config.feederFuels=tuning.crafting.fuels;
    check(sources.sources.at(3).material=="green_resin","Green has a real raw source");
    for (const auto& source : sources.sources) if (source.introducedVersion>=3) {
        leyline::World w(sources,77); economy::PlayerEconomy p(tuning);
        int total=0;
        const auto outcomes=w.state(source.id).outcomes;
        for (int lot=0;lot<source.lots;++lot) {
            for (int step=0;step<4;++step) check(w.work(source.id).ok,"safe coloured work");
            auto items=w.state(source.id).claim;
            for (const auto& [item,n] : items) {
                p.inventory.clear(); check(w.collect(source.id,item,p).moved==n,"source claim transfers exactly");
                if (item==source.material) total+=n;
            }
            check(w.state(source.id).outcomes==outcomes,"claim handling never rerolls");
        }
        check(total==128,"one full new-colour manifestation supplies 128 real units");
        w.advance(123,{}); auto saved=w.serialize();
        check(w.restore(saved) && w.serialize()==saved,"new colour retains formation fraction");
        w.advance(1000,{source.id}); check(w.state(source.id).formation==600 && w.state(source.id).manifestation==0,"blocked renewal capped");
        w.advance(.01,{}); check(w.state(source.id).manifestation==1,"one earned new-colour renewal");
    }
    economy::PlayerEconomy maker(tuning); maker.addAvailableStation("workbench"); maker.worldProfile=leyline::profile;
    maker.inventory={{"green_resin",2},{"wood",2}};
    check(maker.craft("assemble_green_junction").crafted && maker.held("green_junction_kit")==1 && !maker.held("green_resin") && !maker.held("wood"),"cheap junction costs both ingredients");
    contraptions::MachineWorld m(config,{leyline::profile,77,{}}),normal(config);
    check(!normal.create("green","green_junction").ok,"Green stays opt-in");
    for (const auto& [key,kind,x] : std::vector<std::tuple<std::string,std::string,double>>{
        {"lever","stormglass_lever",0},{"white","white_connection",2},{"blue","blue_delay",4},{"green","green_junction",6},{"drum","cargo_winch",8},{"landing","winch_landing",20},{"feeder","pressure_feeder",10}})
        check(m.create(key,kind,{x,0,0}).ok,"native fixture "+key);
    check(m.attachFeeder("feeder","","forge",{10,0,2},true).ok,"feeder has an owned local forge");
    check(m.link("lever","white",true).ok && m.link("white","blue",true).ok && m.link("blue","green",true).ok && m.link("green","drum",true).ok && m.linkSecond("green","feeder",true).ok && m.link("drum","landing",true).ok,"four-edge grammar reaches two distinct receivers");
    for (const auto* bad : {"lever","white","blue","green"}) {
        check(!m.link("green",bad,true).ok && !m.linkSecond("green",bad,true).ok,"Green refuses a loop or another propagator");
    }
    check(!m.linkSecond("green","drum",true).ok && !m.link("green","feeder",true).ok,"both ports reject reconvergence on one receiver");
    economy::Inventory pack{{"raw_clay",16},{"wood",12}};
    check(m.deposit("drum","wood",10,pack).moved==10 && m.deposit("feeder","raw_clay",16,pack).moved==16 && m.deposit("feeder","wood",2,pack).moved==2,"separate owned inputs and cargo");
    m.wind("drum"); m.wind("feeder");
    check(m.pulse("lever",true,true).ok && m.advanceDelay("blue",3,{}).moved==2,"one held request branches to two operations");
    check(m.state("drum")->energy==0 && m.state("drum")->moving && m.state("feeder")->energy==0 && m.state("feeder")->escrowDrive==1 && m.state("feeder")->escrowInputs==economy::Inventory{{"raw_clay",8}} && m.state("feeder")->escrowFuel==economy::Inventory{{"wood",1}},"each receiver pays its own drive and materials");
    auto saved=m.serialize(); check(m.restore(saved) && m.serialize()==saved,"branched paid work saves exactly");
    check(!m.advanceDelay("blue",100,{}).ok,"no duplicate child execution after restart");
    m.advance("drum",100,true); m.advance("feeder",100,true);
    check(m.state("feeder")->output==economy::Inventory{{"rustclay_brick",4}} && m.state("feeder")->queuedCycles==0,"existing brick output and bounded unaffordable continuation");
    m.wind("drum"); m.wind("feeder");
    check(m.pulse("lever",true,true).ok && m.advanceDelay("blue",3,{true,false,true,true,true}).moved==1,"blocked first branch leaves second independently useful");
    check(m.state("drum")->energy==1 && !m.state("drum")->moving && m.state("feeder")->escrowDrive==1,"blocked receiver spends nothing while clear receiver pays");
    m.cancel("feeder");
    check(m.pulse("lever",true,true).ok && m.advanceDelay("blue",3,{true,true,true,true,false}).moved==1,"unready second receiver does not prevent the first");
    check(m.state("feeder")->energy==1 && m.state("feeder")->input==economy::Inventory{{"raw_clay",8},{"wood",1}},"unready second receiver preserves its exact supplies and drive");
    m.advance("drum",100,true);
    check(m.pulse("lever",true,true).ok && m.linkSecond("green","",true).ok && !m.state("blue")->pendingRequest,"rewiring downstream second port cancels pending parent request");
    check(m.linkSecond("green","feeder",true).ok && !m.advanceDelay("blue",100,{}).ok,"reconnection cannot resurrect branched work");
    saved=m.serialize(); auto corrupt=saved; replaceAll(corrupt,"\"second_link\":\"feeder\"","\"second_link\":\"drum\"");
    check(!m.restore(corrupt) && m.serialize()==saved,"saved reconvergence rejects atomically");
    check(m.erase("green",pack).ok && m.state("blue")->link.empty(),"dismantled junction disconnects incoming delay");
    m.link("blue","drum",true); m.pulse("lever",true,true); m.advanceDelay("blue",.375,{}); m.pause("blue",true);
    saved=m.serialize(); auto v3=saved;
    replaceAll(v3,"\"schema\":"+std::to_string(contraptions::saveSchema),"\"schema\":3");
    replaceAll(v3,",\"second_link\":\"\",\"second_span_length\":0","");
    replaceAll(v3,",\"heat\":0,\"heat_key\":\"\",\"escrow_heat\":0","");
    check(m.restore(v3) && m.serialize()==saved,"published Blue payload preserves paused fractional request on Green migration");
}
void heat(const tuning::Tuning& tuning,contraptions::Config config) {
    const auto* recipe=tuning.crafting.findRecipe("refine_rustclay_brick");
    config.feederRecipeInputs=recipe->inputs; config.feederRecipeOutputs=recipe->outputs;
    config.feederFuelCost=recipe->fuelCost; config.feederFuels=tuning.crafting.fuels;
    economy::PlayerEconomy maker(tuning); maker.worldProfile=leyline::profile; maker.addAvailableStation("workbench");
    maker.inventory={{"red_salt",4},{"wood",4},{"iron_ingot",2}};
    check(maker.craft("assemble_red_heat_buffer").crafted && maker.held("red_heat_buffer_kit")==1 && !maker.held("red_salt") && !maker.held("wood") && !maker.held("iron_ingot"),"buffer kit pays its ordinary frame recipe");
    check(config.heatInput==economy::Inventory{{"red_salt",2}} && config.heatCapacity==4,"paid heat tuning matches Red firing cost");
    check(!tuning.crafting.fuels.count("red_salt"),"Red is not a universal fuel");
    contraptions::MachineWorld m(config,{leyline::profile,77,{}}),normal(config);
    check(!normal.create("red","red_heat_buffer").ok,"heat buffer stays opt-in");
    for (const auto& [key,kind,x] : std::vector<std::tuple<std::string,std::string,double>>{
        {"red","red_heat_buffer",0},{"other","red_heat_buffer",2},{"feeder","pressure_feeder",4},{"far","pressure_feeder",20},
        {"lever","stormglass_lever",6},{"blue","blue_delay",8},{"green","green_junction",10},{"drum","cargo_winch",12},{"landing","winch_landing",24}})
        check(m.create(key,kind,{x,0,0}).ok,"thermal fixture "+key);
    check(m.attachFeeder("feeder","","forge",{4,0,2},true).ok,"thermal feeder owns its forge");
    check(!m.link("red","far",true).ok && !m.link("red","feeder",false).ok && !m.link("red","blue",true).ok,"thermal connection needs nearby clear useful receiver");
    check(m.link("red","feeder",true).ok && m.state("feeder")->heatKey=="red","thermal attachment records both exact owners");
    check(!m.link("other","feeder",true).ok && !m.link("lever","red",true).ok && !m.link("green","red",true).ok,"one heat owner, separate from signals");
    economy::Inventory pack{{"red_salt",20},{"raw_clay",24},{"wood",4}};
    auto saved=m.serialize(); auto inventory=pack;
    check(!m.chargeHeat("red",pack,false).ok && pack==inventory && m.serialize()==saved,"unsupported charging spends no heat input");
    for (int i=0;i<4;++i) check(m.chargeHeat("red",pack,true).ok,"each heat unit is paid");
    check(pack.at("red_salt")==12 && m.state("red")->heat==4 && !m.wind("red").ok,"thermal stock is paid and cannot wind");
    saved=m.serialize(); inventory=pack;
    check(!m.chargeHeat("red",pack,true).ok && m.serialize()==saved && pack==inventory,"capacity refuses without payment");
    check(m.deposit("feeder","raw_clay",24,pack).moved==24 && m.deposit("feeder","wood",4,pack).moved==4,"actual ordinary recipe inputs enter hopper");
    check(!m.start("feeder",true).ok && m.state("red")->heat==4,"heat cannot substitute mechanical work");
    m.wind("feeder"); check(m.start("feeder",true).ok,"paid Red firing starts");
    check(m.state("red")->heat==3 && m.state("feeder")->escrowHeat==1 && m.state("feeder")->escrowInputs==config.feederRecipeInputs && m.state("feeder")->escrowFuel.empty() && m.state("feeder")->input.at("wood")==4,"reserve heat separately, preserving clay/output and ordinary fuel");
    check(!m.chargeHeat("red",pack,true).ok,"reserved thermal return slot prevents overcharging");
    m.advance("feeder",2.25,true); saved=m.serialize();
    check(m.restore(saved) && m.serialize()==saved,"fractional thermal firing and capacity survive restore");
    check(!m.advance("feeder",100,false).ok && m.serialize()==saved,"blocked thermal geometry preserves every held payment");
    check(!m.link("red","",true).ok && !m.erase("red",pack).ok && m.serialize()==saved,"active buffer cannot disconnect or dismantle");
    check(m.cancel("feeder").ok && m.state("red")->heat==4 && m.state("feeder")->energy==1 && m.state("feeder")->input==economy::Inventory{{"raw_clay",24},{"wood",4}},"cancel returns exact heat clay and drive");
    saved=m.serialize(); check(!m.cancel("feeder").ok && m.serialize()==saved,"second cancel cannot duplicate heat");
    check(m.start("feeder",true).ok && m.advance("feeder",8,true).ok && m.state("red")->heat==3 && m.state("feeder")->output==config.feederRecipeOutputs,"completed firing spends one heat for four real bricks");
    m.wind("feeder"); m.start("feeder",true);
    check(m.erase("feeder",pack).ok && m.state("red")->heat==3 && m.state("red")->link.empty() && pack.at("raw_clay")==16 && pack.at("wood")==4 && pack.at("rustclay_brick")==4,"feeder dismantle returns reserved heat and exact owned materials/output once");
    const auto salt=pack.at("red_salt");
    check(m.erase("red",pack).ok && pack.at("red_salt")==salt,"idle buffer dismantle vents heat instead of inventing raw salt");
    check(!m.erase("red",pack).ok,"buffer dismantle cannot duplicate contents");
    // An empty attached buffer never silently burns ordinary hopper fuel.
    m.create("feeder","pressure_feeder",{4,0,0}); m.attachFeeder("feeder","","forge",{4,0,2},true);
    m.link("other","feeder",true); m.deposit("feeder","raw_clay",8,pack); m.deposit("feeder","wood",1,pack); m.wind("feeder");
    saved=m.serialize();
    check(!m.start("feeder",true).ok && m.serialize()==saved,"empty attached heat refuses without ordinary fuel fallback");
    check(m.link("other","",true).ok && m.start("feeder",true).ok && m.state("feeder")->escrowFuel==economy::Inventory{{"wood",1}},"explicit detachment restores original fuel rule");
    check(m.erase("other",pack).ok,"remove thermal fixture before historical payload check");
    m.link("lever","blue",true); m.link("blue","green",true); m.link("green","drum",true); m.linkSecond("green","feeder",true); m.link("drum","landing",true);
    m.request("lever",{}); m.advanceDelay("blue",.625,{}); m.pause("blue",true);
    saved=m.serialize(); auto v4=saved;
    replaceAll(v4,"\"schema\":"+std::to_string(contraptions::saveSchema),"\"schema\":4");
    replaceAll(v4,",\"heat\":0,\"heat_key\":\"\",\"escrow_heat\":0","");
    check(m.restore(v4) && m.serialize()==saved,"published Green migration preserves both ports, pending Blue and active ordinary firing");
    auto bad=saved; replaceAll(bad,"\"heat\":0","\"heat\":5");
    check(!m.restore(bad) && m.serialize()==saved,"over-capacity/wrong-owner heat refuses atomically");
    bad=saved; replaceAll(bad,"\"escrow_heat\":0","\"escrow_heat\":1");
    check(!m.restore(bad) && m.serialize()==saved,"orphaned thermal escrow refuses atomically");
}
void catalysts(const tuning::Tuning& tuning) {
    const std::map<std::string,std::pair<std::string,std::string>> identities{
        {"ember",{"red_salt","Kindling"}},{"frost",{"blue_flake","Smoulder"}},
        {"preserving",{"green_resin","Emberbed"}},{"piercing",{"white_mineral","Cinder Lance"}},{"impact",{"white_mineral","Firebreak"}}};
    const std::map<std::string,std::string> operations{{"ember","fuse_buildup"},{"frost","smoulder_slow"},
        {"preserving","emberbed_seconds"},{"piercing","identity_lance_fraction"},{"impact","identity_firebreak_fraction"}};
    for (const auto& [id,identity] : identities) {
        const auto* recipe=tuning.crafting.findRecipe("forge_faint_"+id);
        check(recipe!=nullptr,"ordinary manufacture exists for "+id); if (!recipe) continue;
        const auto output=id+"_catalyst";
        const economy::Inventory cost{{identity.first,96},{"iron_ingot",id=="impact" ? 6 : 4},{"charcoal",id=="impact" ? 4 : 8}};
        check(recipe->inputs==cost && recipe->outputs==economy::Inventory{{output,1}} && recipe->fuelCost==0 && recipe->station=="forge_basic" && recipe->minimumEra==1,"complete costly colour recipe: "+id);
        economy::PlayerEconomy p(tuning); p.worldProfile=leyline::profile; p.inventory=cost;
        check(!p.craft(recipe->id).crafted && p.inventory==cost,"owned forge required: "+id);
        p.addAvailableStation("forge_basic");
        for (const auto& [item,n] : cost) {
            check(n<=p.carryCap(item),"whole Catalyst recipe fits carried "+item);
            p.inventory=cost; --p.inventory[item]; const auto before=p.inventory;
            check(!p.craft(recipe->id).crafted && p.inventory==before,"missing "+item+" refuses before payment for "+id);
        }
        for (const auto* profile : {"legacy_v1","frontier_v2","frontier_v3","frontier_v4","frontier_v5","frontier_v6"}) {
            p.worldProfile=profile; p.inventory=cost;
            check(!p.craft(recipe->id).crafted && p.inventory==cost,"normal world recipe policy unchanged: "+std::string(profile));
        }
        p.worldProfile=leyline::profile; p.inventory=cost;
        check(p.craft(recipe->id).crafted && p.held(output)==1,"actual ordinary manufacture: "+id);
        for (const auto& [item,n] : cost) { (void)n; check(p.held(item)==0,"exact Catalyst debit: "+item); }
        const auto crafted=p.exportState();
        economy::PlayerEconomy loaded(tuning); loaded.importState(crafted);
        check(loaded.held(output)==1,"manufactured output retains existing save ownership: "+id);
        // The player flow earns this event by real smelting; this native fixture
        // isolates each newly manufactured currency's unchanged Foundry route.
        p.foundryEvent("recipe:smelt_iron");
        check(p.foundryPlaceSkill(1,1,"prototype_heavy_strike") && p.foundryPlace(1,0,"ember") && p.foundryPlaceKind(2,0,output) && p.held(output)==0,"manufactured Catalyst invests into its existing identity: "+id);
        bool named=false;
        for (const auto& effect : foundry::effects(tuning,p.foundry(),p.plate())) if (effect.sourceKind==output && effect.formName==identity.second) named=true;
        const auto form=grammar::skillMutation(tuning,grammar::foundryMods(tuning,p.foundry(),1),"prototype_heavy_strike");
        check(named && form.at(operations.at(id))>0,"manufactured identity retains actual distinct operation: "+id);
        loaded.importState(p.exportState());
        check(grammar::skillMutation(tuning,grammar::foundryMods(tuning,loaded.foundry(),1),"prototype_heavy_strike")==form,"saved crafted identity recomputes exactly: "+id);
        // Grade input fixtures retain the existing campaign gates, station and
        // fuel rules. No grade stock is supplied in the paid engine journey.
        loaded.importState(crafted); loaded.addAvailableStation("forge_improved"); loaded.grantSkillXp("blacksmithing",10000);
        for (const auto& era : tuning.eras.eras) if (!era.triggerWorldEffect.empty()) loaded.recordWorldEffect(era.triggerWorldEffect);
        const auto* stable=tuning.crafting.findRecipe("refine_stable_"+id+"_catalyst");
        const auto* potent=tuning.crafting.findRecipe("refine_potent_"+id+"_catalyst");
        check(stable && potent && stable->inputs==economy::Inventory{{output,1},{"bog_iron",1}} && stable->fuelCost==2 && potent->inputs==economy::Inventory{{"stable_"+output,1},{"silver_ingot",1},{"steel_ingot",1}} && potent->fuelCost==3 && potent->minimumEra==3,"published grade recipes stay exact: "+id);
        loaded.grant("bog_iron",1); loaded.grant("wood",5); loaded.grant("silver_ingot",1); loaded.grant("steel_ingot",1);
        check(loaded.craft(stable->id).crafted && loaded.held(output)==0 && loaded.held("stable_"+output)==1,"existing Stable transformation consumes crafted Faint: "+id);
        check(loaded.craft(potent->id).crafted && loaded.held("stable_"+output)==0 && loaded.held("potent_"+output)==1,"existing Potent transformation consumes owned Stable: "+id);
    }
}
int main(int argc,char** argv) {
    const std::string path=argc>1 ? argv[1] : "data/tuning";
    const auto tuning=tuning::loadAll(path);
    blue(tuning,leyline::Config::load(path+"/leyline.json"),contraptions::Config::load(path+"/contraptions.json"));
    green(tuning,leyline::Config::load(path+"/leyline.json"),contraptions::Config::load(path+"/contraptions.json"));
    heat(tuning,contraptions::Config::load(path+"/contraptions.json"));
    catalysts(tuning);
    std::cout<<"LF2_NATIVE "<<checks<<" checks, "<<failures<<" failures\n";
    return failures ? 1 : 0;
}
