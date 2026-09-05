// Owner-approved transformative Foundry, 5 Sep 2026. Included after the
// test harness so exhaustive fixtures use the same check/near reporting.
void testFoundryMutations(const tuning::Tuning& t) {
    const auto frame = foundry::plate(t.foundry,3);
    std::map<std::string,std::string> signature = {
        {"ember_catalyst","ignite_spread"},{"frost_catalyst","field_fraction"},
        {"preserving_catalyst","field_fraction"},{"piercing_catalyst","wave"},
        {"impact_catalyst","impact_radius"},{"vanguard","zone_armour"},
        {"warding_vanguard","ward_charges"},{"marrow","recovery_on_kill"},
        {"sipping_marrow","siphon"},{"quicksilver","trail_fraction"},
        {"striking_quicksilver","echo_delay"},{"casting_quicksilver","echo_delay"}};
    const std::map<std::string,double> baseline = {{"ember_catalyst",.3},{"frost_catalyst",.12},
        {"preserving_catalyst",.18},{"piercing_catalyst",1},{"impact_catalyst",1.8},{"vanguard",10},
        {"warding_vanguard",1},{"marrow",4.5},{"sipping_marrow",.65},{"quicksilver",.16},
        {"striking_quicksilver",.12},{"casting_quicksilver",.55}};
    int baseForms=0;
    std::set<std::pair<std::string,std::string>> pairs;
    for(const auto& form:t.foundry.forms) {
        if(form.supportOnly || !form.upstreamKind.empty() || !form.inputForm.empty()) continue;
        ++baseForms;
        check(!form.kind.empty() && !form.description.empty(),"mutation matrix: exact Kind and player explanation are required");
        check(pairs.emplace(form.kind,form.ingot).second,"mutation matrix: each base pair has one unambiguous rule");
    }
    check(baseForms==96 && pairs.size()==96,"mutation matrix: all twelve Kinds by eight ingots are authored");
    int fixtures=0;
    for(const auto& kind:t.foundry.kinds) for(const auto& ingot:t.foundry.ingots)
    for(const auto& metal:t.foundry.metals) for(const auto& skill:t.skills.combatSkills) {
        foundry::State state;
        state.plate={{1,1,"",skill.id},{1,0,ingot.id,"","",metal.id},{2,0,"","",kind.id}};
        const auto effects=foundry::effects(t,state,frame);
        const auto mods=grammar::foundryMods(t,state,3);
        const auto mutation=grammar::skillMutation(t,mods,skill.id);
        const auto tags=skill.resolveTags();
        const bool attack=std::find(tags.begin(),tags.end(),"attack")!=tags.end();
        const bool spell=std::find(tags.begin(),tags.end(),"spell")!=tags.end();
        const bool compatible=(kind.id!="striking_quicksilver" || attack) && (kind.id!="casting_quicksilver" || spell);
        std::set<std::string> names;
        bool provenance=true;
        for(const auto& e:effects) if(e.sourceKind==kind.id) {
            names.insert(e.formName);
            provenance=provenance && e.path.size()==3 && e.skill==skill.id && e.cellRow==1 && e.cellCol==0;
        }
        const std::string label=kind.id+"/"+ingot.id+"/"+metal.id+"/"+skill.id;
        check(names.size()==(compatible ? 1u:0u) && provenance,"mutation fixture: identity, compatibility and route "+label);
        auto key=kind.id=="frost_catalyst" && ingot.id=="ember" ? "smoulder_slow" : signature.at(kind.id);
        double expected = compatible ? (kind.id=="frost_catalyst" && ingot.id=="ember" ? .25 : baseline.at(kind.id)) : 0;
        const std::map<std::string,std::pair<std::string,double>> frostOps={
            {"frost",{"rime_ring_buildup",20}},{"edge",{"rime_edge_fraction",.06}},
            {"reach",{"whiteout_slow",.4}},{"vigour",{"cold_sap_absorb",3}},
            {"plate",{"permafrost_seconds",.45}},{"ward",{"stillwater_fraction",.08}},
            {"haste",{"hoarfrost_refund",.35}}};
        const std::map<std::string,std::pair<std::string,double>> memoryOps={
            {"ember",{"emberbed_seconds",.6}},{"frost",{"reservoir_seconds",1.2}},
            {"edge",{"wound_memory_seconds",1}},{"reach",{"afterfield_fraction",.12}},
            {"vigour",{"lifebed_life",3}},{"plate",{"held_ground_push",.9}},
            {"ward",{"sanctuary_charges",1}},{"haste",{"lingering_refund",.3}}};
        if(kind.id=="frost_catalyst" && ingot.id!="ember") { key=frostOps.at(ingot.id).first; expected=frostOps.at(ingot.id).second; }
        if(kind.id=="preserving_catalyst") { key=memoryOps.at(ingot.id).first; expected=memoryOps.at(ingot.id).second; }
        if(kind.id=="frost_catalyst" || kind.id=="preserving_catalyst")
            checkNear(mutation.at("field_fraction"),0,1e-9,"Frost/Preserving: no generic damaging pulse is inherited "+label);
        if (kind.id=="ember_catalyst") {
            if (ingot.id=="ember") { key="fuse_buildup"; expected=65; }
            if (ingot.id=="edge") { key="rake_fraction"; expected=.08; }
            if (ingot.id=="reach") { key="ember_hop_buildup"; expected=35; }
            if (ingot.id=="plate") { key="temper_push"; expected=.9; }
            if (ingot.id=="ward") { key="cautery_charges"; expected=1; }
            if (ingot.id=="haste") { key="burn_release_seconds"; expected=.45; }
            if (ingot.id=="vigour") { key="warm_cinder_life"; expected=3; }
            if (ingot.id=="frost") { key="steam_stagger"; expected=.2; }
            checkNear(mutation.at("ignite_spread"),0,1e-9,"Ember identity: no form inherits the old shared ignition spread "+label);
        }
        checkNear(mutation.at(key),expected,1e-9,"mutation fixture: exact Kind operation and baseline "+label);
        bool bounded=true;
        for(const auto& [property,cap]:t.foundry.mutationLimits)
            bounded=bounded && std::isfinite(mutation.at(property)) && mutation.at(property)>=0 && mutation.at(property)<=cap;
        check(bounded,"mutation fixture: every operation is finite and bounded "+label);
        const auto hit=grammar::skillHit(t,mods,skill.id);
        check(hit.empty() || hit.front().type==grammar::nativeType(t,tags),"mutation fixture: acquiring tags never converts the native damage packet "+label);
        ++fixtures;
    }
    check(fixtures==4608,"mutation matrix: 96 pairs x three metals x sixteen skills exercised");

    // Every ordered Kind pair has a defined outcome. Most combine their
    // distinct operations; the two authored ordered recipes intentionally
    // differ. Repeat-Kind copies use the same numeric ceilings.
    int orderedFixtures=0;
    for(const auto& first:t.foundry.kinds) for(const auto& second:t.foundry.kinds)
    for(const auto& ingot:t.foundry.ingots) for(const auto& skill:{"prototype_heavy_strike","prototype_ember_bolt"}) {
        foundry::State state;
        state.plate={{0,3,"","",first.id},{1,3,"","",second.id},{1,2,ingot.id,""},{2,2,"",skill}};
        const auto forward=grammar::skillMutation(t,grammar::foundryMods(t,state,2),skill);
        std::swap(state.plate[0].currency,state.plate[1].currency);
        const auto backward=grammar::skillMutation(t,grammar::foundryMods(t,state,2),skill);
        const bool ordered=(first.id=="frost_catalyst" && second.id=="preserving_catalyst") ||
                           (second.id=="frost_catalyst" && first.id=="preserving_catalyst") ||
                           (ingot.id=="ember" && ((first.id=="frost_catalyst" && second.id=="ember_catalyst") ||
                                                (second.id=="frost_catalyst" && first.id=="ember_catalyst")));
        if(!ordered) check(forward==backward,"compound matrix: independent operations compose without an iteration-order winner");
        bool finite=true;
        for(const auto& [key,value]:forward) finite=finite && std::isfinite(value) && value>=0;
        check(finite,"compound matrix: every ordered pair has a finite result");
        ++orderedFixtures;
    }
    check(orderedFixtures==2304,"compound matrix: 144 ordered Kind pairs x eight ingots x attack/spell exercised");

    // Every skill shell retains typed gear scaling on the new small effects.
    for (const auto& skill : t.skills.combatSkills) {
        foundry::State ember;
        ember.plate={{1,1,"",skill.id},{1,0,"ember",""},{2,0,"","","ember_catalyst"}};
        auto baseMods=grammar::foundryMods(t,ember,1);
        const auto base=grammar::skillMutation(t,baseMods,skill.id);
        baseMods.push_back(grammar::modAt(t.items,"kindling",.5,"weapon"));
        // Flat buildup already belongs to the direct hit; don't duplicate it.
        baseMods.push_back(grammar::modAt(t.items,"smouldering",30,"weapon"));
        const auto scaled=grammar::skillMutation(t,baseMods,skill.id);
        checkNear(base.at("fuse_ignite"),65,1e-9,"Kindling: authored delayed buildup without duplicated direct payload");
        checkNear(scaled.at("fuse_ignite"),97.5,1e-9,"Kindling: ignition investment scales the delayed payload for "+skill.id);
        checkNear(scaled.at("fuse_ignite_boss"),97.5*t.grammar.ignite.bossBuildupMultiplier,1e-9,"Kindling: native boss resistance applies to the fuse");
        ember.plate[1].ingot="reach";
        baseMods=grammar::foundryMods(t,ember,1);
        const auto hop=grammar::skillMutation(t,baseMods,skill.id);
        baseMods.push_back(grammar::modAt(t.items,"wildfire_reach",.4,"charm"));
        baseMods.push_back(grammar::modAt(t.items,"kindling",.5,"weapon"));
        const auto wide=grammar::skillMutation(t,baseMods,skill.id);
        checkNear(wide.at("ember_hop_range"),hop.at("ember_hop_range")*1.4,1e-9,"Wildfire: proliferation gear widens its single target search");
        checkNear(wide.at("ember_hop_ignite"),52.5,1e-9,"Wildfire: ignition gear scales a hop without adding a main hit");
        ember.plate[1].ingot="edge";
        baseMods=grammar::foundryMods(t,ember,1);
        const auto seam=grammar::skillMutation(t,baseMods,skill.id);
        baseMods.push_back(grammar::modAt(t.items,"cold_damage",.5,"charm"));
        checkNear(grammar::skillMutation(t,baseMods,skill.id).at("rake_fire_damage"),seam.at("rake_fire_damage"),1e-9,"Cinder Edge: cold damage never scales the fire seam");
        baseMods.push_back(grammar::modAt(t.items,"fire_damage",.5,"weapon"));
        checkNear(grammar::skillMutation(t,baseMods,skill.id).at("rake_fire_damage"),seam.at("rake_fire_damage")*1.5,1e-9,"Cinder Edge: fire gear scales its bounded secondary packet");
        if (skill.delivery=="dash") checkNear(seam.at("rake_fire_damage"),0,1e-9,"movement has no fabricated Cinder Edge damage");
        ember.plate.push_back({2,1,"ward",""});
        ember.plate.push_back({0,0,"","","ember_catalyst"});
        ember.plate[1].ingot="ward";
        checkNear(grammar::skillMutation(t,grammar::foundryMods(t,ember,3),skill.id).at("cautery_charges"),1,1e-9,"Cautery: multiple routes never create stacked affliction wards");
    }

    for (const auto& skill : t.skills.combatSkills) {
        foundry::State cold;
        cold.plate={{1,1,"",skill.id},{1,0,"frost",""},{2,0,"","","frost_catalyst"}};
        auto cm=grammar::foundryMods(t,cold,1);
        auto base=grammar::skillMutation(t,cm,skill.id);
        cm.push_back(grammar::modAt(t.items,"deep_frost",.5,"charm"));
        cm.push_back(grammar::modAt(t.items,"frostbite",30,"weapon"));
        const auto ring=grammar::skillMutation(t,cm,skill.id);
        checkNear(ring.at("rime_ring_chill"),30,1e-9,"Rimewell: chill investment scales the ring without duplicating direct flat buildup");
        checkNear(ring.at("rime_ring_chill_boss"),30*t.grammar.chill.bossBuildupMultiplier,1e-9,"Rimewell: boss resistance applies to secondary chill");
        cold.plate[1].ingot="ward";
        cm=grammar::foundryMods(t,cold,1);
        base=grammar::skillMutation(t,cm,skill.id);
        cm.push_back(grammar::modAt(t.items,"fire_damage",.5,"weapon"));
        checkNear(grammar::skillMutation(t,cm,skill.id).at("stillwater_cold_damage"),base.at("stillwater_cold_damage"),1e-9,"Stillwater: fire gear does not multiply the returned cold needle");
        cm.push_back(grammar::modAt(t.items,"cold_damage",.5,"weapon"));
        checkNear(grammar::skillMutation(t,cm,skill.id).at("stillwater_cold_damage"),base.at("stillwater_cold_damage")*1.5,1e-9,"Stillwater: cold gear scales the small return packet");
        cold.plate[1].ingot="reach";
        cold.plate[2].currency="preserving_catalyst";
        cm=grammar::foundryMods(t,cold,1);
        base=grammar::skillMutation(t,cm,skill.id);
        const auto type=grammar::nativeType(t,skill.resolveTags());
        for(const auto& packet:t.grammar.damageTypes) {
            if(packet!=type || skill.delivery=="dash") checkNear(base.at("afterfield_"+packet+"_damage"),0,1e-9,"Afterfield: only the actual native damage packet is remembered");
        }
        if(skill.delivery!="dash") check(base.at("afterfield_"+type+"_damage")>0,"Afterfield: each damaging shell has a small native echo");
    }

    // Gear follows real acquired capabilities, with packet type isolation.
    foundry::State smoulder;
    smoulder.plate={{1,1,"","prototype_ember_bolt"},{1,0,"ember",""},{2,0,"","","frost_catalyst"}};
    auto mods=grammar::foundryMods(t,smoulder,1);
    const auto plain=grammar::skillHit(t,mods,"prototype_ember_bolt");
    const auto chill=grammar::chillApplied(t,mods,"prototype_ember_bolt",false);
    mods.push_back(grammar::modAt(t.items,"cold_damage",.5,"weapon"));
    mods.push_back(grammar::modAt(t.items,"deep_frost",.5,"charm"));
    checkNear(grammar::skillHit(t,mods,"prototype_ember_bolt").front().damage,plain.front().damage,1e-9,"Smoulder: cold damage gear does not scale the native fire packet");
    checkNear(grammar::chillApplied(t,mods,"prototype_ember_bolt",false),chill*1.5,1e-9,"Smoulder: cold buildup equipment scales its acquired chill");
    checkNear(grammar::chillApplied(t,mods,"prototype_ember_bolt",true),chill*1.5*t.grammar.chill.bossBuildupMultiplier,1e-9,"Smoulder: boss buildup resistance still applies");
    mods.push_back(grammar::modAt(t.items,"burn_damage",.5,"charm"));
    auto scoped=grammar::modAt(t.items,"lingering_flame",.25,"test");
    scoped.requiresTags={"skill:prototype_ember_bolt"};mods.push_back(scoped);
    checkNear(grammar::skillMutation(t,mods,"prototype_ember_bolt").at("burn_dps"),t.grammar.ignite.damagePerS*1.5,1e-9,"Smoulder: burn equipment scales the one burn");
    checkNear(grammar::skillMutation(t,mods,"prototype_ember_bolt").at("burn_seconds"),t.grammar.ignite.durationS*1.25,1e-9,"Smoulder: skill-scoped duration reaches the burn snapshot");
    checkNear(grammar::skillMutation(t,mods,"prototype_frost_orb").at("smoulder_slow"),0,1e-9,"Smoulder: another skill remains unchanged");
    checkNear(grammar::skillMutation(t,mods,"prototype_frost_orb").at("burn_seconds"),t.grammar.ignite.durationS,1e-9,"Smoulder: duration does not leak between skills");

    // A larger plate has branches, merging paths and intermediate readings.
    foundry::Plate larger; larger.rows=6;larger.cols=6;larger.firstRow=0;larger.lastRow=5;larger.sockets={{3,3}};
    foundry::State branched;
    branched.plate={{0,0,"","","ember_catalyst"},{1,0,"ember",""},{2,0,"edge",""},
        {1,1,"frost",""},{2,1,"haste",""},{2,2,"reach",""},{2,3,"ember",""},{3,3,"","prototype_ember_bolt"}};
    check(foundry::routes(branched,larger,0,0).size()==2,"routes: both strictly inward branches reach the skill");
    auto readings=foundry::effects(t,branched,larger);
    std::map<std::pair<int,int>,int> spreadReadings;
    for(const auto& e:readings) if(e.modifier=="capability_fire") ++spreadReadings[{e.cellRow,e.cellCol}];
    const std::map<std::pair<int,int>,int> expectedReadings={{{1,0},1},{{2,0},1},{{1,1},1},{{2,1},1},{{2,2},1},{{2,3},1}};
    check(spreadReadings==expectedReadings,"routes: six traversed ingots contribute exactly their authored rows after branches merge");
    std::reverse(branched.plate.begin(),branched.plate.end());
    std::map<std::pair<int,int>,int> reversed;
    for(const auto& e:foundry::effects(t,branched,larger)) if(e.modifier=="capability_fire") ++reversed[{e.cellRow,e.cellCol}];
    check(reversed==spreadReadings,"routes: placement iteration order never selects a winning branch");
    branched.plate.erase(std::remove_if(branched.plate.begin(),branched.plate.end(),[](const auto& p){return p.row==2 && p.col==1;}),branched.plate.end());
    check(!foundry::flowsToSkill(branched,larger,0,0),"routes: a missing intermediate cell breaks both routes; alloy reach cannot jump it");

    foundry::State compound;
    compound.plate={{0,3,"","","frost_catalyst"},{1,3,"","","preserving_catalyst"},{1,2,"ember",""},{2,2,"","prototype_ember_bolt"}};
    auto values=grammar::skillMutation(t,grammar::foundryMods(t,compound,2),"prototype_ember_bolt");
    checkNear(values.at("memory_extension"),.8,1e-9,"compound: Frost then Preserving extends the retained memory window");
    checkNear(values.at("smoulder_slow"),.25,1e-9,"compound: upstream Frost still reaches the Ember through another Kind");
    std::swap(compound.plate[0].currency,compound.plate[1].currency);
    auto reverseMods=grammar::foundryMods(t,compound,2);
    checkNear(grammar::skillMutation(t,reverseMods,"prototype_ember_bolt").at("memory_extension"),0,1e-9,"compound: reversing the order changes the compound rule");
    checkNear(grammar::chillApplied(t,reverseMods,"prototype_ember_bolt",false),35,1e-9,"compound: Preserving then Frost gains chill instead of duration");

    foundry::State shared;
    shared.plate={{1,3,"","","preserving_catalyst"},{1,2,"ember",""},{1,1,"","prototype_frost_orb"},{2,2,"","prototype_ember_bolt"}};
    auto sharedMods=grammar::foundryMods(t,shared,1);
    for(const auto& skill: {"prototype_frost_orb","prototype_ember_bolt"})
        checkNear(grammar::skillMutation(t,sharedMods,skill).at("emberbed_seconds"),.6,1e-9,"routes: a shared support delivers its stored-burn operation to both tablets once");
    shared.plate.pop_back();
    check(foundry::routes(shared,frame,1,3).size()==1,"routes: an empty socket receives no flow");

    // Renaming is a resolved view. Existing owned pieces and save coordinates
    // remain stable; even a dormant cadence is kept rather than discarded.
    economy::PlayerEconomy owner(t);
    owner.learnSkill("prototype_ember_bolt");owner.foundryEvent("first_kill:ember_whelp");owner.grant("frost_catalyst",1);
    check(owner.foundryPlaceSkill(1,1,"prototype_ember_bolt") && owner.foundryPlace(1,0,"ember") && owner.foundryPlaceKind(2,0,"frost_catalyst"),"save: mutation fixture is a legal player arrangement");
    save::SaveGame game;game.economy=owner.exportState();
    const auto encoded=save::toJson(game);economy::PlayerEconomy loaded(t);loaded.importState(save::fromJson(encoded).economy);
    check(foundry::at(loaded.foundry(),1,0)->ingot=="ember" && loaded.foundry().owned.at("ember")==1 && loaded.held("frost_catalyst")==0,
          "save: Smoulder stays an owned Ember ingot and one placed Frost Catalyst");
    checkNear(grammar::skillMutation(t,grammar::foundryMods(t,loaded.foundry(),1),"prototype_ember_bolt").at("smoulder_slow"),.25,1e-9,"save: reload recomputes the same transformation");

    // The output form is consumed by a later Kind, rather than added beside it.
    for (const auto& skill : t.skills.combatSkills) {
        foundry::State evolved;
        evolved.plate={{0,3,"","","frost_catalyst"},{1,3,"","","ember_catalyst"},{1,2,"ember",""},{2,2,"",skill.id}};
        auto em=grammar::foundryMods(t,evolved,2);
        auto ev=grammar::skillMutation(t,em,skill.id);
        checkNear(ev.at("steam_fraction"),.06,1e-9,"evolution: Steam Plume resolves for " + skill.id);
        checkNear(ev.at("smoulder_slow"),0,1e-9,"evolution: replaces the Smoulder slow");
        checkNear(ev.at("fuse_buildup"),0,1e-9,"evolution: consumes the participating Kindling fuse");
        std::set<std::string> names;
        for(const auto& e:foundry::effects(t,evolved,foundry::plate(t.foundry,2))) if(!e.formName.empty()) names.insert(e.formName);
        check(names==std::set<std::string>{"Steam Plume"},"evolution: one honest resolved name");
        check(grammar::skillMutation(t,em,"unknown").empty(),"evolution: no unrelated recipient");
        auto cold=em; cold.push_back({"test",{"cold"},"increased_damage",.5,"test"});
        auto scaled=grammar::skillMutation(t,cold,skill.id);
        checkNear(scaled.at("steam_fire_damage"),ev.at("steam_fire_damage"),1e-9,"steam gear: cold investment leaves the fire packet alone");
        checkNear(scaled.at("steam_cold_damage"),ev.at("steam_cold_damage")*1.5,1e-9,"steam gear: cold investment scales only the cold packet");
        if(skill.delivery=="dash") checkNear(ev.at("steam_fire_damage")+ev.at("steam_cold_damage"),0,1e-9,"steam: no damage fabricated for movement");
        std::reverse(evolved.plate.begin(),evolved.plate.end());
        check(grammar::skillMutation(t,grammar::foundryMods(t,evolved,2),skill.id)==ev,"evolution: placement iteration order cannot change the result");
        std::swap(evolved.plate[2].currency,evolved.plate[3].currency);
        checkNear(grammar::skillMutation(t,grammar::foundryMods(t,evolved,2),skill.id).at("steam_fraction"),0,1e-9,"evolution: reversing the physical Kind order does not evolve Smoulder");
    }
    // The evolved ingot can be encountered before the second Kind on a larger plate.
    foundry::Plate evolutionPlate; evolutionPlate.rows=6;evolutionPlate.cols=6;evolutionPlate.firstRow=0;evolutionPlate.lastRow=5;evolutionPlate.sockets={{4,4}};
    foundry::State longer;
    longer.plate={{0,4,"","","frost_catalyst"},{1,4,"ember",""},{2,4,"","","ember_catalyst"},{3,4,"reach",""},{4,4,"","prototype_heavy_strike"}};
    int plumes=0, slow=0;
    for(const auto& e:foundry::effects(t,longer,evolutionPlate)) { if(e.modifier=="mutation_steam_fraction") ++plumes; if(e.modifier=="mutation_smoulder_slow") ++slow; }
    check(plumes==1 && slow==0,"evolution: an intermediate Smoulder becomes Steam Plume through the later Kind");
}
