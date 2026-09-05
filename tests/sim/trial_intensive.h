// Approved Forge arc: route/state/reward tests, independent of presentation.
void testTrialIntensive(const tuning::Tuning& t) {
    check(t.trial.modules.size() == 8 && t.trial.conditions.size() == 8, "intensive: bounded module and condition catalogues");
    check(t.trial.expeditions.size() == 3 && t.boons.boons.size() == 12 && t.boons.weaknesses.size() == 3,
          "intensive: three stories, twelve boons and three bargains");
    const boons::BuildTags tags = {"attack", "area", "projectile", "physical", "movement", "single_target"};
    for (const auto& story : t.trial.expeditions) {
        check(story.floorCount == 2 && story.stages.size() == 8, "intensive: two story floors");
        int offers = 0;
        for (const auto& stage : story.stages) {
            if (stage.choices.front().reward == "boon_offer") ++offers;
            for (const auto& room : stage.choices)
                check(std::find(t.trial.modules.begin(), t.trial.modules.end(), room.module) != t.trial.modules.end(),
                      "intensive: every route names an authored module");
        }
        check(offers == 4, "intensive: four story boon opportunities");
        economy::PlayerEconomy owner(t);
        owner.inventory["wood"] = 17;
        trial::TrialSession run(t, owner, tags, 937, &story);
        check(owner.inventory.empty(), "intensive: entry deposits carried goods");
        check(run.claimSecret().rewardType == "secret" && run.claimSecret().rewardType.empty(),
              "intensive: optional secret rewards only once per run");
        for (int stage = 0; stage < 4; ++stage) {
            check(run.beginRoom(0).started, "intensive: story encounter starts");
            auto outcome = run.resolveRoom(true);
            if (!outcome.boonOffer.empty()) check(run.acceptBoonFromOffer(outcome.boonOffer.front()->id), "intensive: offered boon accepted");
            if (!outcome.offeredWeakness.empty()) check(run.acceptOfferedWeakness(), "intensive: offered bargain accepted");
            run.skipReward();
        }
        check(run.awaitingFloor() && run.floorIndex() == 1 && run.canSuspend(), "intensive: settled boundary points to next floor");
        check(!run.beginRoom(0).started, "intensive: boundary cannot skip descent decision");
        const auto snapshot = run.checkpoint();
        economy::PlayerEconomy resumedOwner(t);
        resumedOwner.inventory["wood"] = 9;
        auto resumed = trial::TrialSession::restore(t, resumedOwner, snapshot);
        check(resumedOwner.inventory.at("wood") == 9, "intensive: restore factory never redeposits or mutates economy");
        check(resumed->runLoot() == run.runLoot() && resumed->route() == run.route() &&
              resumed->runState().activeBoons == run.runState().activeBoons,
              "intensive: suspended route, rewards and temporary build round-trip");
        auto bad = save::fromJson(snapshot);
        bad.extra["content_revision"] = "999";
        bool rejected = false;
        try { auto invalid = trial::TrialSession::restore(t, resumedOwner, save::toJson(bad)); (void)invalid; }
        catch (const std::exception&) { rejected = true; }
        check(rejected && resumedOwner.inventory.at("wood") == 9, "intensive: revision mismatch fails without mutation");
        bad = save::fromJson(snapshot);
        bad.extra["route"] = "999|0|0|0";
        rejected = false;
        try { auto invalid = trial::TrialSession::restore(t, resumedOwner, save::toJson(bad)); (void)invalid; }
        catch (const std::exception&) { rejected = true; }
        check(rejected, "intensive: invalid route checkpoint refused");
        check(run.continueFloor() && resumed->continueFloor(), "intensive: next floor opens explicitly");
        check(run.claimSecret().rewardType.empty(), "intensive: later floors cannot create another optional secret");
        for (int stage = 4; stage < 8; ++stage) {
            const auto originalStart = run.beginRoom(0), resumedStart = resumed->beginRoom(0);
            check(originalStart.seed == resumedStart.seed && originalStart.encounter == resumedStart.encounter,
                  "intensive: suspension preserves future encounter randomness");
            const auto original = run.resolveRoom(true), restored = resumed->resolveRoom(true);
            check(original.materials == restored.materials && original.rewardType == restored.rewardType,
                  "intensive: resumed rewards match uninterrupted run");
            if (!original.boonOffer.empty()) {
                check(original.boonOffer.front()->id == restored.boonOffer.front()->id, "intensive: offer randomness retained");
                run.acceptBoonFromOffer(original.boonOffer.front()->id);
                resumed->acceptBoonFromOffer(restored.boonOffer.front()->id);
            }
            run.skipReward(); resumed->skipReward();
        }
        check(owner.inventory.at("wood") == 17 && resumedOwner.inventory.at("wood") == 17,
              "intensive: both completions return exactly the deposited stack");
        check(run.bossDefeated() && run.runState().activeBoons.empty(), "intensive: completion clears temporary build");
        if (!story.completionCurio.empty()) {
            check(owner.held(story.completionCurio) == 1 && !owner.worldEffectActive(story.completionUnlock),
                  "intensive: story boss leaves curio and does not advance era");
        } else {
            check(owner.worldEffectActive("forge_arc_complete") && owner.currentEra() == 1,
                  "intensive: capstone completion does not create another era");
        }
    }
    trial::GateState gate;
    gate.maxTier = 20;
    for (int tier = 1; tier <= 20; ++tier) {
        const auto first = trial::mapOffers(t, gate, tier), repeated = trial::mapOffers(t, gate, tier);
        check(first.size() == 3 && first[0].id == repeated[0].id, "maps: three reproducible offers per selected tier");
        for (const auto& offer : first) {
            std::set<std::string> unique(offer.conditions.begin(), offer.conditions.end());
            check(unique.size() == offer.conditions.size() && offer.conditions.size() == static_cast<size_t>(tier <= 3 ? 2 : (tier <= 7 ? 3 : 4)),
                  "maps: tier condition count without duplicate rolls");
            int majorHazards = 0;
            std::set<std::string> effects;
            for (const auto& id : offer.conditions) {
                const auto* condition = t.trial.findCondition(id);
                majorHazards += condition->majorHazard ? 1 : 0;
                for (const auto& [key, value] : condition->effects) {
                    (void)value;
                    check(effects.insert(key).second, "maps: overlapping condition effects are never rolled together");
                }
            }
            check(majorHazards <= 2, "maps: offer bounds major area hazard definitions");
        }
    }
    const auto original = trial::mapOffers(t, gate, 1);
    auto reloaded = trial::GateState::fromJson(gate.toJson());
    check(trial::mapOffers(t, reloaded, 1)[1].id == original[1].id, "maps: save/reload does not reroll offers");
    reloaded.enteredMap();
    check(trial::mapOffers(t, reloaded, 1)[1].id != original[1].id, "maps: successful entry advances offer batch");
    trial::GateState progress;
    check(trial::mapOffers(t, progress, 2).empty(), "maps: uncleared next tier unavailable");
    progress.clearedMap(1);
    check(progress.maxTier == 2 && !trial::mapOffers(t, progress, 2).empty(), "maps: clear unlocks next tier");
    economy::PlayerEconomy mapper(t);
    mapper.inventory["wood"] = 11;
    trial::TrialSession map(t, mapper, tags, original[0]);
    int boonOffers = 0;
    for (int stage = 0; stage < 5; ++stage) {
        map.beginRoom(0);
        auto outcome = map.resolveRoom(stage != 4);
        if (outcome.rewardType == "boon_offer") ++boonOffers;
        map.skipReward();
    }
    check(boonOffers == 2 && map.floorCount() == 1 && map.playerDied(), "maps: short one-floor run has two offers");
    check(mapper.held("wood") == 11 && mapper.held("ember_catalyst") == 1,
          "maps: death restores deposit and secured Ember");
    for (const auto& id : t.trial.haulItems) check(mapper.held(id) == 0, "maps: unbanked material haul is lost on death");
    check(!map.canSuspend() && progress.maxTier == 2, "maps: no mid-map suspend or implicit failed-run tier grant");
    for (const auto& offer : original) {
        economy::PlayerEconomy hauled(t);
        trial::TrialSession targetRun(t, hauled, tags, offer);
        auto secret = targetRun.claimSecret();
        const int expected = static_cast<int>(std::floor(t.trial.mapHaulUnits.at(offer.materialTarget) * offer.rewardMultiplier));
        check(secret.materials.at(offer.materialTarget) == expected, "maps: shown target and reward multiplier determine actual ingredient haul");
        targetRun.beginRoom(0); targetRun.resolveRoom(true); targetRun.skipReward();
        targetRun.beginRoom(0); auto cache = targetRun.resolveRoom(true);
        check(cache.materials.at(offer.materialTarget) == expected, "maps: physical cache replenishes the selected source ingredient");
        const auto before = targetRun.runLoot();
        targetRun.resolveRoom(true);
        check(targetRun.runLoot() == before, "maps: repeat completion call cannot duplicate a cache");
        targetRun.abandon();
    }
    std::set<std::string> bargains;
    const auto* firstStory = t.trial.findExpedition("forge_tyrant");
    for (int seed = 1; seed <= 12; ++seed) {
        economy::PlayerEconomy bargainer(t);
        trial::TrialSession bargain(t, bargainer, tags, seed, firstStory);
        for (int stage = 0; stage < 3; ++stage) {
            bargain.beginRoom(0); auto result = bargain.resolveRoom(true);
            if (!result.offeredWeakness.empty()) bargains.insert(result.offeredWeakness);
            bargain.skipReward();
        }
        bargain.abandon();
    }
    check(bargains.size() == 3, "intensive: all three optional weaknesses can be offered");
    {
        economy::PlayerEconomy explorer(t);
        trial::TrialSession explored(t, explorer, tags, 513, firstStory);
        for (int stage = 0; stage < 4; ++stage) {
            explored.beginRoom(0); explored.resolveRoom(true); explored.skipReward();
        }
        check(explored.canSuspend() && explored.claimSecret().rewardType == "secret",
              "intensive: cleared-floor exploration can claim its secret before descent");
        const auto secretSave = explored.checkpoint();
        auto continued = trial::TrialSession::restore(t, explorer, secretSave);
        check(continued->claimSecret().rewardType.empty(), "intensive: boundary-secret claim survives suspension without duplication");
        explored.abandon();
    }
    for (const boons::BuildTags& classTags : std::vector<boons::BuildTags>{
             {"area", "attack", "movement", "single_target"},
             {"area", "attack", "projectile", "movement", "single_target"},
             {"area", "spell", "projectile", "movement"}}) {
        boons::RunState state;
        for (int i = 0; i < 4; ++i) {
            const auto offer = boons::generateOffer(t.boons, classTags, state, 41 + i);
            check(offer.size() == 3, "intensive: every fixed class receives three compatible options at all four shrines");
            for (const auto* boon : offer) check(boons::isCompatible(*boon, classTags, state), "intensive: no incompatible shrine choices");
            boons::acceptBoon(t.boons, offer.front()->id, classTags, state);
        }
    }
    save::SaveGame exact;
    exact.economy.dayClock = 13.123456789012345;
    exact.economy.skillPractice["test"] = 0.12345678901234567;
    const auto exactRestored = save::fromJson(save::toJson(exact));
    checkNear(exactRestored.economy.dayClock, exact.economy.dayClock, 0.0, "intensive: checkpoint clock keeps full floating-point precision");
    checkNear(exactRestored.economy.skillPractice.at("test"), exact.economy.skillPractice.at("test"), 0.0, "intensive: saved permanent skill progress is exact");
    combat::HitStream hits(7123);
    combat::CombatMods mods;
    mods.repeatHitCount = 3; mods.repeatDamageMultiplier = 0.6;
    const auto& skill = t.skills.combatSkills.front();
    for (int i = 0; i < 5; ++i) hits.playerHit(skill, mods, false);
    auto restoredHits = combat::HitStream::restore(hits.checkpoint());
    for (int i = 0; i < 12; ++i)
        checkNear(restoredHits.playerHit(skill, mods, true), hits.playerHit(skill, mods, true), 0.0,
                  "intensive: hit variance and repeat-hit counter resume exactly");
}
