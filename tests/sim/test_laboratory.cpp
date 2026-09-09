#include "wroughtwild/trial.h"
#include "wroughtwild/save.h"
#include <iostream>
using namespace wroughtwild;
int checks=0,failures=0;
void check(bool b,const char* label){++checks;if(!b){++failures;std::cerr<<"FAIL LF4B "<<label<<'\n';}}
int main(int argc,char** argv) {
    auto t=tuning::loadAll(argc>1?argv[1]:"data/tuning");
    auto source=t.trial.findExpedition("forge_tyrant");
    economy::PlayerEconomy old(t);trial::TrialSession historical(t,old,{},77,source);
    check(historical.floor()->displayName==source->displayName && t.trial.expeditions.size()==3,"published three-story catalogue unchanged");
    economy::PlayerEconomy player(t);player.campaignPolicy=resonance::campaign;player.inventory["wood"]=7;
    auto session=std::make_unique<trial::TrialSession>(t,player,boons::BuildTags{},77,source);
    check(session->floor()->displayName=="Collection Annex" && session->floorCount()==2,"policy selects complete two-floor laboratory");
    check(player.inventory.empty(),"ordinary belongings deposited");
    for(size_t i=0;i<session->stages().size();++i) {
        const auto& stage=session->stages()[i];
        for(size_t j=0;j<stage.choices.size();++j) {
            const auto& room=stage.choices[j];const auto& original=source->stages[i].choices[j];
            check(room.id==original.id && room.reward==original.reward && room.module==original.module && room.encounter.size()==original.encounter.size(),"native route and ordinary reward identity retained");
            if(i<2)check(room.encounter.front()==(i==0?"lf_red_boar":"lf_blue_boar"),"each branch includes the selected single-influence specimen");
        }
    }
    int encounters=0;
    while(!session->finished() && encounters<8) {
        if(session->awaitingFloor()) {
            const auto checkpoint=session->checkpoint();
            session=trial::TrialSession::restore(t,player,checkpoint);
            check(session->floor()->displayName=="Collection Annex" && session->awaitingFloor(),"suspended first floor restores same laboratory policy");
            check(session->continueFloor(),"second floor opens from the saved boundary");
        }
        check(session->beginRoom(0).started,"real native stage enters");
        session->resolveRoom(true); session->skipReward(); ++encounters;
    }
    check(encounters==8 && session->bossDefeated() && session->finished(),"full first laboratory resolves");
    check(player.inventory["wood"]>=7,"deposited belongings restored");
    check(player.currentEra()==1 && player.resonanceState.phase=="dormant","LF-4B does not yet schedule progression");
    std::cout<<checks<<" checks, "<<failures<<" failures\n";return failures?1:0;
}
