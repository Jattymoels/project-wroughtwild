#include "wroughtwild/trial.h"
#include "wroughtwild/save.h"
#include <algorithm>
#include <cmath>
#include <iostream>
using namespace wroughtwild;
int checks=0, failures=0;
void check(bool ok,const char* label){++checks;if(!ok){++failures;std::cerr<<"FAIL LF7 "<<label<<'\n';}}
int main(int argc,char** argv) {
    const std::string directory=argc>1?argv[1]:"data/tuning";
    const auto tuning=tuning::loadAll(directory);
    trial::GateState gate;
    const auto old=gate.toJson();
    check(trial::GateState::fromJson(old).toJson()==old,"legacy gate stays byte-identical without configuration fields");
    gate.maxTier=10;
    gate.lastTier=3;gate.lastPressure="crossfire";
    check(trial::GateState::fromJson(gate.toJson()).toJson()==gate.toJson(),"remembered configuration round trips exactly");
    economy::PlayerEconomy player(tuning);
    player.campaignPolicy=resonance::campaign;player.worldSeed=77;player.inventory["wood"]=7;
    auto world=worldgen::generateProfile(tuning,77,"living_frontier_wave3");
    const auto config=resonance::Config::load(directory+"/resonance.json");
    player.resonanceState=resonance::prepare(world,config,{});player.resonanceState.campaignAward=true;
    player.recordWorldEffect("lf4_annex_victory");player.recordWorldEffect("stonecut_blocks");
    resonance::apply(world,player.resonanceState);
    player.secondResonance=resonance::prepare(world,config,{},"excited_uplands");player.secondResonance.campaignAward=true;
    player.recordWorldEffect("lf5_pairing_victory");player.recordWorldEffect("ash_tide");
    auto offer=trial::mapOffers(tuning,gate,1).front();
    trial::configureLaboratory(tuning,offer,"");
    bool refused=false;
    try { trial::TrialSession blocked(tuning,player,{},offer); } catch(...) {refused=true;}
    check(refused && player.inventory["wood"]==7,"unfinished ending refuses before deposit");
    player.recordWorldEffect("forge_arc_complete");
    const auto ready=player.exportState();
    const auto first=player.resonanceState.toJson(),second=player.secondResonance.toJson();
    for(int seed=1;seed<=32;++seed) for(int tier=1;tier<=10;++tier) {
        gate.batchSeed=seed;
        const auto saved=gate.toJson();
        const auto offers=trial::mapOffers(tuning,gate,tier);
        const auto reopened=trial::mapOffers(tuning,trial::GateState::fromJson(saved),tier);
        for(size_t slot=0;slot<offers.size();++slot) {
            const auto& base=offers[slot];
            check(base.id==reopened[slot].id && base.conditions==reopened[slot].conditions && base.moduleOrder==reopened[slot].moduleOrder && base.materialTarget==reopened[slot].materialTarget,"saved offer identity survives reopening/load");
            for(const std::string pressure : {"","crossfire","relentless_boss"}) {
                auto selected=base;
                const auto refusal=trial::configureLaboratory(tuning,selected,pressure);
                const bool duplicate=std::find(base.conditions.begin(),base.conditions.end(),pressure)!=base.conditions.end();
                check(refusal.empty()!=duplicate,"duplicate pressure refused; compatible or none accepted");
                check(gate.toJson()==saved,"browsing never changes gate seed/tier/remembered setting");
                if(!refusal.empty()) {check(selected.conditions==base.conditions && !selected.laboratory,"refusal leaves frozen offer intact");continue;}
                check(selected.id==base.id && selected.seed==base.seed && selected.moduleOrder==base.moduleOrder && selected.bossId==base.bossId && selected.materialTarget==base.materialTarget,"configuration preserves roll, creature and target");
                check(selected.rewardMultiplier==base.rewardMultiplier,"pressure cannot inflate general reward multiplier");
                player.importState(ready);
                trial::TrialSession run(tuning,player,{},selected);
                check(run.laboratoryExperiment() && run.pressure()==pressure && run.boss().id!="conservator" && run.floorCount()==1 && run.stages().size()==5,"bounded session commits settings and never resurrects the human");
                auto expected=tuning.trial.materialsReward;
                for(auto& [id,units]:expected) units=static_cast<int>(std::floor(units*base.rewardMultiplier));
                const int target=static_cast<int>(std::floor(tuning.trial.mapHaulUnits.at(base.materialTarget)*base.rewardMultiplier*(pressure.empty()?1.0:1.25)));
                expected[base.materialTarget]+=target;
                check(trial::targetHaul(tuning,selected)==target,"shared target preview matches independent exact rounding");
                const auto secret=run.claimSecret();
                check(secret.materials==std::map<std::string,int>{{base.materialTarget,target}} && run.claimSecret().materials.empty(),"optional secret pays previewed target once");
                const auto mods=run.currentMods();
                for(const auto& id:selected.conditions) for(const auto& [key,value]:tuning.trial.findCondition(id)->effects)
                    check(mods.trialEffects.at(key)==value,"selected and rolled effects reach the actual combat mods");
                for(int stage=0;stage<5;++stage) {
                    check(run.beginRoom(0).started,"configured room starts");
                    const auto result=run.resolveRoom(true);run.skipReward();
                    if(stage==1) check(result.materials==expected,"cache pays exactly previewed general/target quantities");
                    if(stage==3) check(result.rewardType=="equipment" && !result.catalystRecovered && result.items.size()==1 && result.items[0].rarity=="wrought","equipment cache has fixed gear without guaranteed Catalyst");
                    if(stage==4) check(result.materials==tuning.trial.mapCompletionComponents.at(base.materialTarget),"boss core remains exact and unmultiplied");
                }
                check(run.bossDefeated() && player.inventory["wood"]==7 && player.inventory[tuning.trial.catalystItem]==0,"win returns deposit without inventing Catalyst");
                save::SaveGame done;done.economy=player.exportState();const auto once=save::toJson(done);
                run.resolveRoom(true);run.claimSecret();run.bankAndExit();run.abandon();done.economy=player.exportState();
                check(save::toJson(done)==once,"all repeated completion paths pay nothing");
                check(player.resonanceState.toJson()==first && player.secondResonance.toJson()==second && player.currentEra()==3,"all tiers/pressures retain both terrain events and era");
            }
        }
    }
    for(int mode=0;mode<3;++mode) {
        player.importState(ready);
        trial::TrialSession run(tuning,player,{},offer);
        for(int stage=0;stage<(mode==2?4:2);++stage){run.beginRoom(0);run.resolveRoom(true);run.skipReward();}
        if(mode==0){run.beginRoom(0);run.resolveRoom(false);}else if(mode==1)run.abandon();else run.bankAndExit();
        check(run.finished() && !run.bossDefeated() && player.inventory["wood"]==7,"death/abandon/bank preserve deposit without boss completion");
        for(const auto& [id,units]:tuning.trial.mapCompletionComponents.at(offer.materialTarget)){(void)units;check(player.inventory[id]==0,"death/abandon/bank cannot pay boss component");}
        check((player.inventory[offer.materialTarget]>0)==(mode==2),"only banking retains earned source haul");
    }
    auto invalid=trial::mapOffers(tuning,gate,1).front();
    check(!trial::configureLaboratory(tuning,invalid,"unknown").empty(),"unknown pressure refused");
    invalid.tier=11;check(!trial::configureLaboratory(tuning,invalid,"").empty(),"LF tier eleven refused");
    auto altered=tuning;
    altered.trial.conditions.front().effects={{"boss_recovery_multiplier",.9}};
    invalid=trial::mapOffers(tuning,gate,1).front();invalid.conditions={altered.trial.conditions.front().id};
    check(!trial::configureLaboratory(altered,invalid,"relentless_boss").empty(),"shared effect keys refused");
    altered=tuning;
    for(auto& condition:altered.trial.conditions)if(condition.id=="relentless_boss")condition.incompatible={"crowded_packs"};
    invalid.conditions={"crowded_packs"};check(!trial::configureLaboratory(altered,invalid,"relentless_boss").empty(),"explicit incompatibility refused");
    altered=tuning;for(auto& condition:altered.trial.conditions)if(condition.id=="relentless_boss")condition.majorHazard=true;
    invalid.conditions={"furnace_hazards","volatile_rares"};check(!trial::configureLaboratory(altered,invalid,"relentless_boss").empty(),"third major hazard refused");
    economy::PlayerEconomy legacy(tuning);
    const auto legacyOffer=trial::mapOffers(tuning,gate,1).front();
    trial::TrialSession legacyRun(tuning,legacy,{},legacyOffer);
    for(int i=0;i<4;++i){legacyRun.beginRoom(0);auto result=legacyRun.resolveRoom(true);legacyRun.skipReward();if(i==3)check(result.catalystRecovered,"old Forge offers retain their guaranteed shrine");}
    std::cout<<"LF7 native: "<<checks<<" checks, "<<failures<<" failures\n";
    return failures?1:0;
}
