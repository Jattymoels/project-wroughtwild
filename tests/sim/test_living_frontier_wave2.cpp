#include "wroughtwild/leyline.h"
#include "wroughtwild/contraptions.h"
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
    for (int version : {1,2}) for (int seed=0;seed<16;++seed) {
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
    replaceAll(v2,"\"schema\":3","\"schema\":2");
    replaceAll(v2,",\"pending_request\":false,\"delay_paused\":false,\"delay_seconds\":0","");
    check(m.restore(v2) && m.serialize()==saved,"published Wave 1 machine payload migrates without reset");
}
int main(int argc,char** argv) {
    const std::string path=argc>1 ? argv[1] : "data/tuning";
    const auto tuning=tuning::loadAll(path);
    blue(tuning,leyline::Config::load(path+"/leyline.json"),contraptions::Config::load(path+"/contraptions.json"));
    std::cout<<"LF2_NATIVE "<<checks<<" checks, "<<failures<<" failures\n";
    return failures ? 1 : 0;
}
