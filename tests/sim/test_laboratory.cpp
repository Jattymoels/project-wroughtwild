#include "wroughtwild/trial.h"
#include "wroughtwild/save.h"
#include <iostream>
using namespace wroughtwild;
int checks=0,failures=0;
void check(bool b,const char* label){++checks;if(!b){++failures;std::cerr<<"FAIL LF4 "<<label<<'\n';}}
int main(int argc,char** argv) {
    auto t=tuning::loadAll(argc>1?argv[1]:"data/tuning");
    auto source=t.trial.findExpedition("forge_tyrant");
    economy::PlayerEconomy old(t);trial::TrialSession historical(t,old,{},77,source);
    check(historical.floor()->displayName==source->displayName && t.trial.expeditions.size()==3,"published three-story catalogue unchanged");
    economy::PlayerEconomy player(t);player.campaignPolicy=resonance::campaign;player.worldSeed=77;player.inventory["wood"]=7;
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
    check(player.currentEra()==1 && player.resonanceState.phase=="pending" && player.resonanceState.seed==77,"first victory queues for the world seed before era publication");
    check(player.inventory["tyrant_heart"]==1 && player.worldEffectActive("lf4_annex_victory"),"one first-clear trophy and receipt");
    save::SaveGame saved;saved.economy=player.exportState();player.importState(save::fromJson(save::toJson(saved)).economy);
    check(player.resonanceState.phase=="pending" && player.inventory["tyrant_heart"]==1,"pending restart retains one first-clear payout");
    check(player.setCurio("hill_cairn") && !player.setCurio("hill_cairn") && player.currentEra()==1,"remembrance once, without an era or extra payout");
    for(int run=0;run<2;++run) {
        trial::TrialSession repeat(t,player,{},100+run,source);
        while(!repeat.finished()) {
            if(repeat.awaitingFloor())repeat.continueFloor();
            check(repeat.beginRoom(0).started,"repeat native room starts");
            repeat.resolveRoom(true);repeat.skipReward();
        }
        repeat.abandon();
        check(player.inventory["tyrant_heart"]==0 && player.resonanceState.phase=="pending","repeated victory and finished callback cannot repay a spent trophy or transform");
    }
    player.inventory["warden_eye"]=1;
    check(!player.setCurio("drowned_altar") && player.inventory["warden_eye"]==1,"successor preserves owned old curio without enabling deeper gate");
    economy::PlayerEconomy failed(t);failed.campaignPolicy=resonance::campaign;
    trial::TrialSession death(t,failed,{},77,source);death.beginRoom(0);death.resolveRoom(false);
    check(failed.resonanceState.phase=="dormant" && !failed.worldEffectActive("lf4_annex_victory"),"failed Trial cannot queue resonance");
    economy::PlayerEconomy banking(t);banking.campaignPolicy=resonance::campaign;banking.inventory["wood"]=7;
    trial::TrialSession early(t,banking,{},77,source);
    while(!early.canBankAndExit() && !early.finished()) {
        if(early.awaitingFloor())early.continueFloor();
        if(!early.beginRoom(0).started)break;
        early.resolveRoom(true);early.skipReward();
    }
    check(early.canBankAndExit() && !early.bossDefeated(),"ordinary early extraction reached before the warden");
    early.bankAndExit();
    check(early.finished() && banking.inventory["wood"]>=7 && banking.resonanceState.phase=="dormant" && !banking.worldEffectActive("lf4_annex_victory") && !banking.curioHeld("tyrant_heart"),"bank-out restores deposits without a first-clear payout or resonance");
    old.inventory["tyrant_heart"]=1;old.inventory["warden_eye"]=1;
    check(old.setCurio("hill_cairn") && old.currentEra()==2 && old.setCurio("drowned_altar") && old.currentEra()==3,"legacy policy keeps both original curio gates and rewards");
    std::cout<<checks<<" checks, "<<failures<<" failures\n";return failures?1:0;
}
