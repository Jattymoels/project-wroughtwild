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
        round.campaignAward=true;
        auto changed=base;resonance::apply(changed,round);
        check(changed.blocks!=base.blocks,"actual voxel transformation");
        check(changed.nodes.size()==base.nodes.size()+4 && changed.frontierHosts.size()==base.frontierHosts.size()+1 && changed.packs.size()==base.packs.size()+1 && changed.frontierHosts.back().id=="lf4_retained_fen_blue" && changed.packs.back().frontierHostId=="lf4_retained_fen_blue" && changed.packs.back().enemies==std::vector<std::string>{"lf_blue_boar"},"campaign adds exactly four ore lots and one existing finite Blue host");
        bool clearHost=s.hasHost;
        for(const auto& p:s.ore)clearHost &= std::hypot(s.host.x-p.x,s.host.z-p.z)*base.cellSize>=cfg.oreSpacing;
        check(clearHost,"new habitat has a distinct spaced workplace");
        bool oldEdges=true,oldNodes=true,oldCaves=true;
        for(int z=1;z<base.height-1;++z)for(int x=1;x<base.width-1;++x) {
            for(const auto& d:std::vector<std::pair<int,int>>{{1,0},{0,1},{1,1},{-1,1}}) {
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
        // LF-5C replays the first ledger before planning a distinct second event.
        std::vector<resonance::Bounds> firstBounds;
        for(const auto& p:round.columns)firstBounds.push_back({p.x*base.cellSize,p.z*base.cellSize,(p.x+1)*base.cellSize,(p.z+1)*base.cellSize});
        auto second=resonance::prepare(changed,cfg,firstBounds,"excited_uplands");second.campaignAward=true;
        check(second.columns.size()>=32 && second.ore.size()==4 && second.hasHost,"second bounded region has finite useful workplaces");
        check(resonance::State::fromJson(*json::parse(second.toJson())).toJson()==second.toJson(),"second ledger roundtrip exact");
        auto both=changed;resonance::apply(both,second);
        check(both.nodes.size()==base.nodes.size()+8 && both.frontierHosts.size()==base.frontierHosts.size()+2 && both.frontierHosts.back().id=="lf5_excited_uplands_pair" && both.packs.back().enemies==std::vector<std::string>{"lf_paired_boar"},"both distinct ore sets and finite host identities coexist");
        bool firstExact=true,stone=true,edges=true,oldStock=true;
        for(const auto& p:round.columns)for(int y=0;y<base.depth;++y)firstExact &= both.blockAt(p.x,y,p.z)==changed.blockAt(p.x,y,p.z);
        for(const auto& p:second.columns) {
            stone &= p.after-p.before<=3;
            for(int y=0;y<p.before;++y)stone &= both.blockAt(p.x,y,p.z)==changed.blockAt(p.x,y,p.z);
            for(int y=p.before;y<p.after;++y)stone &= both.blockAt(p.x,y,p.z)==worldgen::kStone;
            for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)
                edges &= std::abs(both.at(p.x,p.z).height-both.at(p.x+dx,p.z+dz).height)<=std::max(1,std::abs(changed.at(p.x,p.z).height-changed.at(p.x+dx,p.z+dz).height));
        }
        for(size_t i=0;i<changed.nodes.size();++i) {
            const auto& a=changed.nodes[i];const auto& b=both.nodes[i];
            oldStock &= a.resourceId==b.resourceId && a.x==b.x && a.y==b.y && a.z==b.z && a.unitsOverride==b.unitsOverride && changed.at(a.x,a.z).height==both.at(a.x,a.z).height;
        }
        check(firstExact && stone && edges && oldStock,"first terrain, all finite workplaces, caves and ordinary step bounds survive second stone shelves");
        const auto sc=second.columns[second.columns.size()/2];
        auto protectedSecond=firstBounds;protectedSecond.push_back({sc.x-.5,sc.z-.5,sc.x+5.5,sc.z+5.5});
        auto ps=resonance::prepare(changed,cfg,protectedSecond,"excited_uplands");
        bool kept=true;for(const auto& p:ps.columns)if(p.x>=sc.x-4 && p.x<=sc.x+9 && p.z>=sc.z-4 && p.z<=sc.z+9)kept=false;
        check(kept && ps.toJson()==resonance::prepare(changed,cfg,protectedSecond,"excited_uplands").toJson(),"second paid-footprint protection is deterministic");
        rejected=false;try{(void)resonance::prepare(changed,cfg,{{0,0,10000,10000}},"excited_uplands");}catch(...){rejected=true;}check(rejected,"fully occupied second event explicitly defers");
        auto replay=base;resonance::apply(replay,round);resonance::apply(replay,resonance::State::fromJson(*json::parse(second.toJson())));
        check(replay.blocks==both.blocks,"fresh both-event physical replay is exact");
        std::cout<<"LF5C seed="<<seed<<" second_changed="<<second.columns.size()<<" protected="<<ps.columns.size()<<'\n';
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
