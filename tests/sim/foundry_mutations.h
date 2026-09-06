// Owner-approved transformative Foundry, 5 Sep 2026. Included after the
// test harness so exhaustive fixtures use the same check/near reporting.
// Independent expectations: these are authored roles, not values copied at
// runtime from the same JSON being tested. Display names are not signatures.
const std::map<std::string,std::pair<std::string,double>>& completedIdentityOperations() {
    static const std::map<std::string,std::pair<std::string,double>> roles = {
        {"piercing_catalyst:ember",{"identity_lance_fraction",.10}},
        {"piercing_catalyst:frost",{"identity_ice_buildup",30}},
        {"piercing_catalyst:edge",{"identity_razor_fraction",.10}},
        {"piercing_catalyst:reach",{"identity_through_fraction",.08}},
        {"piercing_catalyst:vigour",{"identity_thread_life",2}},
        {"piercing_catalyst:plate",{"identity_breach_push",.65}},
        {"piercing_catalyst:ward",{"identity_needle_seconds",.35}},
        {"piercing_catalyst:haste",{"identity_quick_refund",.3}},
        {"impact_catalyst:ember",{"identity_firebreak_fraction",.10}},
        {"impact_catalyst:frost",{"identity_glacier_push",.8}},
        {"impact_catalyst:edge",{"identity_concussion_fraction",.12}},
        {"impact_catalyst:reach",{"identity_shock_fraction",.10}},
        {"impact_catalyst:vigour",{"identity_heartbreak_fraction",.14}},
        {"impact_catalyst:plate",{"identity_anvil_fraction",.14}},
        {"impact_catalyst:ward",{"identity_sealbreak_seconds",.45}},
        {"impact_catalyst:haste",{"identity_snap_fraction",.10}},
        {"vanguard:ember",{"identity_guard_furnace_absorb",4}},
        {"vanguard:frost",{"identity_guard_rime_buildup",30}},
        {"vanguard:edge",{"identity_guard_blade_fraction",.12}},
        {"vanguard:reach",{"identity_guard_broad_push",1.3}},
        {"vanguard:vigour",{"identity_guard_living_recovery",5}},
        {"vanguard:plate",{"identity_guard_plate_absorb",9}},
        {"vanguard:ward",{"identity_guard_post_reduction",.2}},
        {"vanguard:haste",{"identity_guard_quick_absorb",5}},
        {"warding_vanguard:ember",{"identity_veil_ember_fraction",.1}},
        {"warding_vanguard:frost",{"identity_veil_rime_buildup",40}},
        {"warding_vanguard:edge",{"identity_veil_razor_fraction",.1}},
        {"warding_vanguard:reach",{"identity_veil_wide_screen",1}},
        {"warding_vanguard:vigour",{"identity_veil_living_life",3}},
        {"warding_vanguard:plate",{"identity_veil_iron_absorb",4}},
        {"warding_vanguard:ward",{"identity_veil_aegis_threshold",.4}},
        {"warding_vanguard:haste",{"identity_veil_fleeting_refund",.4}},
        {"marrow:ember",{"identity_phoenix_life",2.5}},
        {"marrow:frost",{"identity_winterroot_life",2.5}},
        {"marrow:edge",{"identity_bloodroot_life",2.5}},
        {"marrow:reach",{"identity_harvest_life",2.5}},
        {"marrow:vigour",{"identity_spring_life",2.5}},
        {"marrow:plate",{"identity_ironroot_life",2.5}},
        {"marrow:ward",{"identity_harbour_life",2.5}},
        {"marrow:haste",{"identity_fleet_life",2.5}},
        {"sipping_marrow:ember",{"identity_cinder_life",2.5}},
        {"sipping_marrow:frost",{"identity_cold_sip_life",2.5}},
        {"sipping_marrow:edge",{"identity_bloodletter_life",2.5}},
        {"sipping_marrow:reach",{"identity_long_drink_life",2.5}},
        {"sipping_marrow:vigour",{"identity_deep_drink_life",2.5}},
        {"sipping_marrow:plate",{"identity_iron_drink_life",2.5}},
        {"sipping_marrow:ward",{"identity_ward_sip_life",2.5}},
        {"sipping_marrow:haste",{"identity_quick_sip_life",2.5}},
        {"quicksilver:ember",{"identity_tempo_cinder_fraction",.08}},
        {"quicksilver:frost",{"identity_tempo_frost_buildup",20}},
        {"quicksilver:edge",{"identity_tempo_razor_fraction",.1}},
        {"quicksilver:reach",{"identity_tempo_long_push",.9}},
        {"quicksilver:vigour",{"identity_tempo_living_life",2}},
        {"quicksilver:plate",{"identity_tempo_iron_push",1}},
        {"quicksilver:ward",{"identity_tempo_ward_cleanse",1}},
        {"quicksilver:haste",{"identity_tempo_after_fraction",.1}},
        {"striking_quicksilver:ember",{"identity_tempo_s_cinder_fraction",.08}},
        {"striking_quicksilver:frost",{"identity_tempo_s_frost_buildup",25}},
        {"striking_quicksilver:edge",{"identity_tempo_s_double_fraction",.1}},
        {"striking_quicksilver:reach",{"identity_tempo_s_sweep_fraction",.08}},
        {"striking_quicksilver:vigour",{"identity_tempo_s_sustain_life",3}},
        {"striking_quicksilver:plate",{"identity_tempo_s_brace_armour",6}},
        {"striking_quicksilver:ward",{"identity_tempo_s_guard_stagger",.25}},
        {"striking_quicksilver:haste",{"identity_tempo_s_step_refund",.6}},
        {"casting_quicksilver:ember",{"identity_tempo_c_ember_fraction",.1}},
        {"casting_quicksilver:frost",{"identity_tempo_c_frost_buildup",20}},
        {"casting_quicksilver:edge",{"identity_tempo_c_blade_fraction",.1}},
        {"casting_quicksilver:reach",{"identity_tempo_c_wide_fraction",.1}},
        {"casting_quicksilver:vigour",{"identity_tempo_c_living_life",3}},
        {"casting_quicksilver:plate",{"identity_tempo_c_brace_armour",7}},
        {"casting_quicksilver:ward",{"identity_tempo_c_ward_charges",1}},
        {"casting_quicksilver:haste",{"identity_tempo_c_after_refund",.45}}
    };
    return roles;
}

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
    const auto& identities=completedIdentityOperations();
    check(identities.size()==72,"identity matrix: seventy-two independently enumerated new roles");
    int baseForms=0;
    std::set<std::pair<std::string,std::string>> pairs;
    std::set<std::vector<std::pair<std::string,double>>> operations;
    for(const auto& form:t.foundry.forms) {
        if(form.supportOnly || !form.upstreamKind.empty() || !form.inputForm.empty()) continue;
        ++baseForms;
        check(!form.kind.empty() && !form.description.empty(),"mutation matrix: exact Kind and player explanation are required");
        check(pairs.emplace(form.kind,form.ingot).second,"mutation matrix: each base pair has one unambiguous rule");
        std::vector<std::pair<std::string,double>> operation;
        for(const auto& effect:form.effects)
            if(effect.modifier.rfind("mutation_",0)==0) operation.push_back({effect.modifier,effect.value});
        std::sort(operation.begin(),operation.end());
        check(!operation.empty() && operations.insert(operation).second,"identity matrix: actual operation definitions differ, not just displayed names "+form.id);
    }
    check(baseForms==96 && pairs.size()==96,"mutation matrix: all twelve Kinds by eight ingots are authored");
    check(operations.size()==96,"identity matrix: ninety-six different operation definitions");
    int fixtures=0, aliasFixtures=0;
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
        std::string key=kind.id=="frost_catalyst" && ingot.id=="ember" ? "smoulder_slow" : signature.at(kind.id);
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
        const auto identity=identities.find(kind.id+":"+ingot.id);
        if(identity!=identities.end()) {
            key=identity->second.first;
            expected=compatible ? identity->second.second : 0;
            // Ingot aliases must not silently carry their retired common pulse,
            // recovery or every-third-use operation alongside the new identity.
            for(const auto& retired:{"zone_armour","ward_charges","recovery_on_kill","siphon","trail_fraction","echo_delay"})
                checkNear(mutation.at(retired),0,1e-9,"identity matrix: retired shared operation remains absent "+label+"/"+retired);
            check(grammar::skillEchoEvery(t,mods,skill.id)==0,"identity matrix: no automatic every-third repeat remains "+label);
        }
        checkNear(mutation.at(key),expected,1e-9,"mutation fixture: exact Kind operation and baseline "+label);
        bool bounded=true;
        for(const auto& [property,cap]:t.foundry.mutationLimits)
            bounded=bounded && std::isfinite(mutation.at(property)) && mutation.at(property)>=0 && mutation.at(property)<=cap;
        check(bounded,"mutation fixture: every operation is finite and bounded "+label);
        const auto hit=grammar::skillHit(t,mods,skill.id);
        check(hit.empty() || hit.front().type==grammar::nativeType(t,tags),"mutation fixture: acquiring tags never converts the native damage packet "+label);
        for(const auto& grade:t.crafting.currencyKinds) {
            if(grade.canonicalKind!=kind.id) continue;
            auto graded=state;
            graded.plate.back().currency=grade.id;
            check(grammar::skillMutation(t,grammar::foundryMods(t,graded,3),skill.id)==mutation,
                  "identity grades: full resolved behaviour aliases its original Kind "+grade.id+"/"+label);
            check(graded.plate.back().currency==grade.id,"identity grades: resolution never rewrites placed ownership identity");
            ++aliasFixtures;
        }
        ++fixtures;
    }
    check(fixtures==4608,"mutation matrix: 96 pairs x three metals x sixteen skills exercised");
    check(aliasFixtures==13824,"identity grades: thirty-six owned Kind IDs x eight ingots x three alloys x sixteen skills");

    // Every graded item remains exact inventory through a legal plate/save/lift
    // lifecycle. Canonical behaviour does not permit paying with another grade.
    for(const auto& grade:t.crafting.currencyKinds) {
        economy::PlayerEconomy owner(t);
        owner.learnSkill("prototype_heavy_strike");
        owner.foundryEvent("first_kill:ember_whelp");
        owner.grant(grade.id,1);
        if(grade.id!=grade.canonicalKind) owner.grant(grade.canonicalKind,1);
        const int canonicalBefore=owner.held(grade.canonicalKind);
        check(owner.foundryPlaceSkill(1,1,"prototype_heavy_strike") && owner.foundryPlace(1,0,"ember") && owner.foundryPlaceKind(2,0,grade.id),
              "identity grades: legal placement pays exact owned grade "+grade.id);
        check(owner.held(grade.id)==0 && (grade.id==grade.canonicalKind || owner.held(grade.canonicalKind)==canonicalBefore),
              "identity grades: placing an alias cannot consume canonical stock "+grade.id);
        owner.grant("iron_ingot",1);
        save::SaveGame saved; saved.economy=owner.exportState();
        economy::PlayerEconomy loaded(t); loaded.importState(save::fromJson(save::toJson(saved)).economy);
        const auto* placed=foundry::at(loaded.foundry(),2,0);
        check(placed && placed->currency==grade.id && loaded.held(grade.id)==0,
              "identity grades: save restores the exact invested item, even on an incompatible skill "+grade.id);
        check(loaded.foundryRemove(2,0) && loaded.held(grade.id)==1 &&
                  (grade.id==grade.canonicalKind || loaded.held(grade.canonicalKind)==canonicalBefore),
              "identity grades: paid lifting returns the exact grade once "+grade.id);
    }

    // A repeated Kind at two independent branches adds its authored value only
    // to its receiving skill and then obeys the operation-specific ceiling.
    for(const auto& [id,operation]:identities) {
        const auto split=id.find(':');
        const std::string kind=id.substr(0,split);
        const std::string ingot=id.substr(split+1);
        const std::string skill=kind=="casting_quicksilver" ? "prototype_ember_bolt" : "prototype_heavy_strike";
        foundry::State doubled;
        doubled.plate={{1,1,"",skill},{1,0,ingot,""},{2,0,"","",kind},{0,0,"","",kind}};
        const auto mods=grammar::foundryMods(t,doubled,3);
        const auto mutation=grammar::skillMutation(t,mods,skill);
        checkNear(mutation.at(operation.first),std::min(operation.second*2,t.foundry.mutationLimits.at(operation.first)),1e-9,
                  "identity copies: duplicate routes obey the authored ceiling "+id);
        checkNear(grammar::skillMutation(t,mods,"prototype_frost_orb").at(operation.first),0,1e-9,
                  "identity copies: no leakage to an unconnected skill "+id);
        std::reverse(doubled.plate.begin(),doubled.plate.end());
        check(grammar::skillMutation(t,grammar::foundryMods(t,doubled,3),skill)==mutation,
              "identity copies: reversed container order retains both routes "+id);
        doubled.plate.erase(std::remove_if(doubled.plate.begin(),doubled.plate.end(),[](const auto& p){return p.row==1 && p.col==0;}),doubled.plate.end());
        checkNear(grammar::skillMutation(t,grammar::foundryMods(t,doubled,3),skill).at(operation.first),0,1e-9,
                  "identity copies: removing the sole connecting support removes both readings "+id);
    }

    // Every ordered Kind pair has a defined outcome. Most combine their
    // distinct operations; the two authored ordered recipes intentionally
    // differ. Repeat-Kind copies use the same numeric ceilings.
    int orderedFixtures=0;
    for(const auto& first:t.foundry.kinds) for(const auto& second:t.foundry.kinds)
    for(const auto& ingot:t.foundry.ingots) for(const auto& metal:t.foundry.metals) for(const auto& skillDef:t.skills.combatSkills) {
        const auto& skill=skillDef.id;
        foundry::State state;
        state.plate={{0,3,"","",first.id},{1,3,"","",second.id},{1,2,ingot.id,"","",metal.id},{2,2,"",skill}};
        const auto forward=grammar::skillMutation(t,grammar::foundryMods(t,state,3),skill);
        std::swap(state.plate[0].currency,state.plate[1].currency);
        const auto backward=grammar::skillMutation(t,grammar::foundryMods(t,state,3),skill);
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
    check(orderedFixtures==55296,"compound matrix: 144 ordered Kind pairs x eight ingots x three alloys x sixteen skills exercised");

    // The new event packet path must preserve typed equipment investment, and
    // a movement-only shell must never manufacture damage from a fraction.
    auto value=[](const std::map<std::string,double>& values,const std::string& key) {
        const auto it=values.find(key); return it==values.end() ? 0.0 : it->second;
    };
    int packetFixtures=0, buildupFixtures=0;
    for(const auto& [id,operation]:identities) for(const auto& skill:t.skills.combatSkills) {
        const auto split=id.find(':');
        const std::string kind=id.substr(0,split);
        const std::string ingot=id.substr(split+1);
        foundry::State state;
        state.plate={{1,1,"",skill.id},{1,0,ingot,""},{2,0,"","",kind}};
        auto mods=grammar::foundryMods(t,state,3);
        const auto base=grammar::skillMutation(t,mods,skill.id);
        if(operation.first.size()>9 && operation.first.compare(operation.first.size()-9,9,"_fraction")==0) {
            const auto prefix=operation.first.substr(0,operation.first.size()-9);
            mods.push_back(grammar::modAt(t.items,"fire_damage",.5,"weapon"));
            const auto raised=grammar::skillMutation(t,mods,skill.id);
            checkNear(value(raised,prefix+"_cold_damage"),value(base,prefix+"_cold_damage"),1e-9,"identity packets: fire equipment leaves cold alone "+id+"/"+skill.id);
            checkNear(value(raised,prefix+"_physical_damage"),value(base,prefix+"_physical_damage"),1e-9,"identity packets: fire equipment leaves physical alone "+id+"/"+skill.id);
            if(value(base,prefix+"_fire_damage")>0) check(value(raised,prefix+"_fire_damage")>value(base,prefix+"_fire_damage"),"identity packets: actual fire investment improves fire aftermath "+id+"/"+skill.id);
            if(skill.delivery=="dash") for(const auto& type:t.grammar.damageTypes)
                checkNear(value(raised,prefix+"_"+type+"_damage"),0,1e-9,"identity packets: movement has no invented damage "+id);
            ++packetFixtures;
        }
        if(operation.first.size()>8 && operation.first.compare(operation.first.size()-8,8,"_buildup")==0 && base.at(operation.first)>0) {
            const auto prefix=operation.first.substr(0,operation.first.size()-8);
            mods.push_back(grammar::modAt(t.items,"deep_frost",.5,"weapon"));
            mods.push_back(grammar::modAt(t.items,"frostbite",40,"weapon"));
            const auto raised=grammar::skillMutation(t,mods,skill.id);
            checkNear(value(raised,prefix+"_chill"),value(base,prefix+"_chill")*1.5,1e-9,"identity buildup: chill investment scales without duplicating flat main-hit buildup "+id+"/"+skill.id);
            checkNear(value(raised,prefix+"_chill_boss"),value(raised,prefix+"_chill")*t.grammar.chill.bossBuildupMultiplier,1e-9,"identity buildup: native boss resistance remains authoritative "+id+"/"+skill.id);
            ++buildupFixtures;
        }
    }
    check(packetFixtures>0 && buildupFixtures>0,"identity scaling: authored damage and status paths both exercised");
    std::printf("FOUNDRY_IDENTITY_MATRIX base=%d aliases=%d ordered=%d packets=%d buildup=%d\n",fixtures,aliasFixtures,orderedFixtures,packetFixtures,buildupFixtures);

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
