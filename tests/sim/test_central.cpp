#include "wroughtwild/trial.h"
#include "wroughtwild/save.h"
#include <iostream>
using namespace wroughtwild;
int checks=0, failures=0;
void check(bool ok,const char* label){++checks;if(!ok){++failures;std::cerr<<"FAIL LF6 "<<label<<'\n';}}
int main(int argc,char** argv){
    const std::string directory=argc>1?argv[1]:"data/tuning";
    const auto tuning=tuning::loadAll(directory);
    const auto* original=tuning.trial.findExpedition("forge_capstone");
    economy::PlayerEconomy player(tuning);
    player.campaignPolicy=resonance::campaign;player.worldSeed=77;player.inventory["wood"]=7;
    bool refused=false;try{trial::TrialSession blocked(tuning,player,{},1,original);}catch(...){refused=true;}
    check(refused && player.inventory["wood"]==7,"unpublished Central refuses before deposit");
    auto map=worldgen::generateProfile(tuning,77,"living_frontier_wave3");
    const auto config=resonance::Config::load(directory+"/resonance.json");
    player.resonanceState=resonance::prepare(map,config,{});
    player.resonanceState.campaignAward=true;
    player.recordWorldEffect("lf4_annex_victory");player.recordWorldEffect("stonecut_blocks");
    resonance::apply(map,player.resonanceState);
    player.secondResonance=resonance::prepare(map,config,{},"excited_uplands");
    player.secondResonance.campaignAward=true;
    player.recordWorldEffect("lf5_pairing_victory");player.recordWorldEffect("ash_tide");
    const auto ready=player.exportState();
    const auto first=player.resonanceState.toJson(),second=player.secondResonance.toJson();
    for(int mode=0;mode<3;++mode){
        player.importState(ready);
        trial::TrialSession run(tuning,player,{},60+mode,original);
        check(run.boss().id=="conservator" && run.floor()->displayName=="Central Laboratory","dedicated human and Central treatment selected");
        if(mode==0){run.beginRoom(0);run.resolveRoom(false);}
        if(mode==1){run.beginRoom(0);run.resolveRoom(true);run.abandon();}
        if(mode==2){while(!run.awaitingFloor()){run.beginRoom(0);run.resolveRoom(true);run.skipReward();}run.bankAndExit();}
        check(!player.worldEffectActive("forge_arc_complete") && player.inventory["wood"]>=7 && player.currentEra()==3,"death, abandonment and early bank return deposit without ending");
        check(player.resonanceState.toJson()==first && player.secondResonance.toJson()==second,"failed runs preserve both transformations exactly");
    }
    player.importState(ready);
    auto run=std::make_unique<trial::TrialSession>(tuning,player,boons::BuildTags{},811,original);
    for(size_t i=0;i<run->stages().size();++i)for(size_t j=0;j<run->stages()[i].choices.size();++j){
        const auto& room=run->stages()[i].choices[j];const auto& old=original->stages[i].choices[j];
        check(room.module==old.module && room.reward==old.reward,"existing topology and reward roles retained");
        if(room.reward=="completion")check(room.encounter==std::vector<std::string>{"conservator"},"final room contains only the dedicated human");
        else check(room.encounter.size()==old.encounter.size(),"ordinary encounter budget retained");
    }
    while(!run->finished()){
        if(run->awaitingFloor()){
            const auto checkpoint=run->checkpoint();
            save::SaveGame saved;saved.economy=player.exportState();
            player.importState(save::fromJson(save::toJson(saved)).economy);
            run=trial::TrialSession::restore(tuning,player,checkpoint);
            check(run->checkpoint()==checkpoint && run->boss().id=="conservator","Central revision-three checkpoint restores exact ownership and identity");
            auto completed=player.exportState();completed.worldEffects.push_back("forge_arc_complete");
            player.importState(completed);refused=false;
            try{auto invalid=trial::TrialSession::restore(tuning,player,checkpoint);}catch(...){refused=true;}
            check(refused,"resolved story cannot restore an old boundary into another human fight");
            player.importState(saved.economy);
            run->continueFloor();
        }
        check(run->beginRoom(0).started,"Central stage begins");run->resolveRoom(true);run->skipReward();
    }
    save::SaveGame ended;ended.economy=player.exportState();const auto once=save::toJson(ended);
    check(player.worldEffectActive("forge_arc_complete") && player.currentEra()==3,"one completion receipt owns ending and control without another era");
    run->resolveRoom(true);run->abandon();ended.economy=player.exportState();
    check(save::toJson(ended)==once,"duplicate resolution and abandon after victory cannot repay");
    player.importState(save::fromJson(once).economy);
    refused=false;try{trial::TrialSession repeat(tuning,player,{},999,original);}catch(...){refused=true;}
    ended.economy=player.exportState();
    check(refused && save::toJson(ended)==once,"completed restart refuses re-entry before any deposit or reward");
    check(player.resonanceState.toJson()==first && player.secondResonance.toJson()==second,"ending preserves exact first and second ledgers");
    ended.economy.earnedMastery["prototype_area_strike"]={};
    const auto unearned=save::toJson(ended);
    check(save::toJson(save::fromJson(unearned))==unearned,"meaningful casts below a mastery threshold retain their exact empty earned list");
    auto invalid=ready;invalid.secondResonance.campaignAward=false;invalid.worldEffects.push_back("forge_arc_complete");
    save::SaveGame bad;bad.economy=invalid;refused=false;try{(void)save::fromJson(save::toJson(bad));}catch(...){refused=true;}
    check(refused,"mixed ending and physical-award state refuses");
    economy::PlayerEconomy legacy(tuning);trial::TrialSession old(tuning,legacy,{},1,original);
    check(old.boss().id=="forge_heart" && old.floor()->displayName==original->displayName,"legacy capstone remains its published encounter");
    std::cout<<"LF6_NATIVE "<<checks<<" checks, "<<failures<<" failures\n";
    return failures?1:0;
}
