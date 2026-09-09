#include "wroughtwild/trial.h"
#include "wroughtwild/save.h"
#include <iostream>
using namespace wroughtwild;
int checks=0,failures=0;
void check(bool b,const char* s){++checks;if(!b){++failures;std::cerr<<"FAIL LF5B "<<s<<'\n';}}
int main(int argc,char** argv) {
    const std::string directory=argc>1?argv[1]:"data/tuning";
    auto t=tuning::loadAll(directory);auto source=t.trial.findExpedition("deep_forge");
    economy::PlayerEconomy player(t);player.campaignPolicy=resonance::campaign;player.worldSeed=77;player.inventory["wood"]=7;
    bool refused=false;try{trial::TrialSession blocked(t,player,{},12,source);}catch(...){refused=true;}
    check(refused && player.inventory["wood"]==7,"no Pairing or deposit before first publication");
    auto map=worldgen::generateProfile(t,77,"living_frontier_wave3");
    player.resonanceState=resonance::prepare(map,resonance::Config::load(directory+"/resonance.json"),{});
    player.resonanceState.campaignAward=true;player.recordWorldEffect("lf4_annex_victory");player.recordWorldEffect("stonecut_blocks");
    const auto first=player.resonanceState.toJson();
    auto pristine=player.exportState();
    for(int mode=0;mode<2;++mode) {
        player.importState(pristine);trial::TrialSession failed(t,player,{},42,source);
        failed.beginRoom(0);failed.resolveRoom(mode==1);
        if(mode==1)failed.abandon();
        check(!player.worldEffectActive("lf5_pairing_victory") && !player.curioHeld("warden_eye") && player.currentEra()==2 && player.resonanceState.toJson()==first && player.secondResonance.phase=="dormant","death/abandon never pays first-clear or queues second event");
    }
    player.importState(pristine);
    {
        trial::TrialSession bank(t,player,{},77,source);
        while(!bank.awaitingFloor()) {bank.beginRoom(0);bank.resolveRoom(true);bank.skipReward();}
        bank.bankAndExit();
        check(bank.finished() && !player.worldEffectActive("lf5_pairing_victory") && !player.curioHeld("warden_eye") && player.secondResonance.phase=="dormant" && player.currentEra()==2,"second-laboratory early bank retains haul without first-clear or era");
    }
    player.importState(pristine);
    for(int repeat=0;repeat<2;++repeat) {
        auto session=std::make_unique<trial::TrialSession>(t,player,boons::BuildTags{},123+repeat,source);
        check(session->floor()->displayName=="Pairing Hall" && session->floorCount()==2,"second physical laboratory has its own context");
        for(size_t i=0;i<session->stages().size();++i)for(size_t j=0;j<session->stages()[i].choices.size();++j){
            const auto& room=session->stages()[i].choices[j];const auto& old=source->stages[i].choices[j];
            check(room.module==old.module && room.reward==old.reward && room.encounter.size()==old.encounter.size(),"existing route, rewards and encounter budget retained");
            if(i>=2 && i<=6)check(room.encounter.front()=="lf_paired_boar","every later non-boss branch contains the ordered specimen");
        }
        while(!session->finished()) {
            if(session->awaitingFloor()) {
                const auto cp=session->checkpoint();save::SaveGame save;save.economy=player.exportState();
                player.importState(save::fromJson(save::toJson(save)).economy);
                session=trial::TrialSession::restore(t,player,cp);
                check(session->floor()->displayName=="Pairing Hall" && session->awaitingFloor(),"revision-two boundary restores exact Pairing identity");
                session->continueFloor();
            }
            check(session->beginRoom(0).started,"Pairing native room begins");session->resolveRoom(true);session->skipReward();
        }
        session->abandon();
        check(player.currentEra()==2 && player.resonanceState.toJson()==first && player.secondResonance.phase=="pending" && player.secondResonance.seed==77,"first clear queues second event without publishing an era or replacing first ledger");
        check(player.worldEffectActive("lf5_pairing_victory") && player.inventory["warden_eye"]==(repeat==0?1:0),"first-clear receipt pays one Eye, never replaces a spent Eye");
        player.inventory.erase("warden_eye");
    }
    auto pending=player.exportState();save::SaveGame saved;saved.economy=pending;
    check(save::fromJson(save::toJson(saved)).economy.secondResonance.toJson()==player.secondResonance.toJson(),"native pending restart retains one second event");
    auto missing=save::toJson(saved);const auto field=std::string(",\"resonance_second\":")+player.secondResonance.toJson();
    missing.erase(missing.find(field),field.size());
    auto migrated=save::fromJson(missing).economy;
    check(migrated.secondResonance.toJson()==player.secondResonance.toJson() && migrated.inventory==pending.inventory && migrated.resonanceState.toJson()==first,"LF5B absent-ledger migration queues only the second event, never restores a spent Eye");
    auto reject=[&](auto state,const char* label){save::SaveGame bad;bad.economy=state;bool rejected=false;try{(void)save::fromJson(save::toJson(bad));}catch(...){rejected=true;}check(rejected,label);};
    auto bad=pending;bad.secondResonance.seed=5;reject(bad,"different second seed rejected");
    bad=pending;bad.secondResonance.event="retained_fen";reject(bad,"swapped second ledger rejected");
    bad=pending;bad.resonanceState.campaignAward=false;reject(bad,"second pending requires first physical award");
    bad=pending;bad.worldEffects.push_back("ash_tide");reject(bad,"era three before physical publication rejected");
    bad=pending;bad.secondResonance.phase="dormant";reject(bad,"receipt with explicit dormant second event rejected");
    resonance::apply(map,player.resonanceState);
    player.secondResonance=resonance::prepare(map,resonance::Config::load(directory+"/resonance.json"),{},"excited_uplands");
    player.secondResonance.campaignAward=true;player.recordWorldEffect("ash_tide");
    saved.economy=player.exportState();player.importState(save::fromJson(save::toJson(saved)).economy);
    check(player.currentEra()==3 && player.resonanceState.toJson()==first && !player.curioHeld("warden_eye"),"applied second state advances once and retains spent first-clear ownership");
    check(!player.setCurio("drowned_altar"),"spent Eye cannot be offered");
    player.inventory["warden_eye"]=1;
    check(player.setCurio("drowned_altar") && !player.setCurio("drowned_altar") && player.currentEra()==3,"optional Eye remembrance consumes once and grants no additional era");
    const auto second=player.secondResonance.toJson();
    {
        trial::TrialSession repeat(t,player,{},517,source);
        while(!repeat.finished()) {
            if(repeat.awaitingFloor())repeat.continueFloor();
            repeat.beginRoom(0);repeat.resolveRoom(true);repeat.skipReward();
        }
        repeat.abandon();
    }
    check(player.secondResonance.toJson()==second && player.resonanceState.toJson()==first && player.currentEra()==3 && !player.curioHeld("warden_eye"),"repeat clear after applied event and spent Eye cannot requeue or repay");
    economy::PlayerEconomy legacy(t);trial::TrialSession old(t,legacy,{},1,source);
    check(old.floor()->displayName==source->displayName,"legacy Deep Forge is unchanged");
    std::cout<<checks<<" checks, "<<failures<<" failures\n";return failures?1:0;
}
