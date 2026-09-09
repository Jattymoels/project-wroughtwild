#include "wroughtwild/resonance.h"
#include "wroughtwild/save.h"
#include <iostream>
#include <cmath>
using namespace wroughtwild;
int checks=0,failures=0;
void check(bool b,const std::string& label) {++checks;if(!b){++failures;std::cerr<<"FAIL LF4A "<<label<<'\n';}}
int main(int argc,char** argv) {
    auto tuning=tuning::loadAll(argc>1?argv[1]:"data/tuning");
    auto cfg=resonance::Config::load(std::string(argc>1?argv[1]:"data/tuning")+"/resonance.json");
    std::vector<int> seeds;for(int s=0;s<32;++s)seeds.push_back(s);for(int s:{42,77,256,1337,2147483647})seeds.push_back(s);
    for(int seed:seeds) {
        auto base=worldgen::generateProfile(tuning,seed,"living_frontier_wave3");
        resonance::State s;
        try {s=resonance::prepare(base,cfg,{});}catch(const std::exception& e){check(false,std::to_string(seed)+": "+e.what());continue;}
        check(s.columns.size()>=32 && s.ore.size()==4,"meaningful finite opportunity");
        auto round=resonance::State::fromJson(*json::parse(s.toJson()));check(round.toJson()==s.toJson(),"exact event replay record");
        auto changed=base;resonance::apply(changed,round);
        check(changed.blocks!=base.blocks,"actual voxel transformation");
        bool oldEdges=true,oldNodes=true,oldCaves=true;
        for(int z=1;z<base.height-1;++z)for(int x=1;x<base.width-1;++x) {
            for(const auto& d:std::vector<std::pair<int,int>>{{1,0},{0,1}}) {
                const int before=std::abs(base.at(x,z).height-base.at(x+d.first,z+d.second).height);
                const int after=std::abs(changed.at(x,z).height-changed.at(x+d.first,z+d.second).height);
                oldEdges &= after<=std::max(1,before);
            }
        }
        for(const auto& n:base.nodes) oldNodes &= changed.at(n.x,n.z).height==base.at(n.x,n.z).height;
        for(const auto& c:s.columns) for(int y=0;y<c.before;++y) oldCaves &= changed.blockAt(c.x,y,c.z)==base.blockAt(c.x,y,c.z);
        check(oldEdges && oldNodes && oldCaves,"ordinary edges, original resources and subterranean columns survive");
        const auto c=s.columns[s.columns.size()/2];
        std::vector<resonance::Bounds> bounds={{c.x-.5,c.z-.5,c.x+5.5,c.z+5.5}};
        auto protectedState=resonance::prepare(base,cfg,bounds);
        bool protectedAll=true;
        for(const auto& p:protectedState.columns) if(p.x>=c.x-4 && p.x<=c.x+9 && p.z>=c.z-4 && p.z<=c.z+9)protectedAll=false;
        check(protectedAll,"whole paid footprint and workspace retained");
        check(protectedState.toJson()==resonance::prepare(base,cfg,bounds).toJson(),"protection plan deterministic");
        bool rejected=false;
        try{(void)resonance::prepare(base,cfg,{{0,0,10000,10000}});}catch(...){rejected=true;}
        check(rejected,"fully occupied event explicitly deferred");
        auto corrupt=s;corrupt.seed=static_cast<uint64_t>(seed)+1;rejected=false;
        try{resonance::validate(base,corrupt);}catch(...){rejected=true;}check(rejected,"foreign seed rejected");
        std::cout<<"LF4A seed="<<seed<<" changed="<<s.columns.size()<<" protected_changed="<<protectedState.columns.size()<<'\n';
    }
    economy::PlayerEconomy player(tuning);save::SaveGame game;game.economy=player.exportState();
    check(save::toJson(game).find("campaign_policy")==std::string::npos,"legacy serialization unchanged");
    player.campaignPolicy=resonance::campaign;player.resonanceState.phase="pending";player.resonanceState.seed=77;
    game.economy=player.exportState();auto restored=save::fromJson(save::toJson(game));
    check(restored.economy.campaignPolicy==resonance::campaign && restored.economy.resonanceState.phase=="pending","pending policy survives native restart");
    check(player.currentEra()==1,"isolated event introduces no progression trigger");
    std::cout<<checks<<" checks, "<<failures<<" failures\n";return failures?1:0;
}
