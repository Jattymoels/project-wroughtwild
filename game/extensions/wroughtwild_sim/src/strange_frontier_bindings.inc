// Included inside namespace godot. The engine certifies space; native rules own
// all contents, energy, refunds and transaction state.
namespace {
Dictionary machine_result(const wroughtwild::contraptions::Result& r) {
    Dictionary d; d["ok"]=r.ok; d["moved"]=r.moved; d["message"]=to_godot(r.message); return d;
}
Dictionary machine_unavailable() { return machine_result({false,0,"Contraptions wait outside trials."}); }
const char* machine_kinds[] = {"lantern_lamp","cargo_winch","winch_landing","stormglass_lever","magnetic_sorter","ventlung_bellows","pressure_feeder"};
}

PackedStringArray WroughtwildSim::contraption_kinds() const {
    PackedStringArray ids; for (auto kind : machine_kinds) ids.push_back(kind); return ids;
}
String WroughtwildSim::contraption_kind_for_kit(const String& kit) const {
    for (auto kind : machine_kinds) if (kit==String(kind)+"_kit") return kind;
    return {};
}
bool WroughtwildSim::contraption_place(const String& kind, const String& key, const Vector3& at, int rotation) {
    if (!contraptions_ || trial_) return false;
    const std::string kit=to_std(kind)+"_kit";
    if (!wroughtwild::economy::hasAll(player_->inventory,{{kit,1}})) return false;
    const auto result=contraptions_->create(to_std(key),to_std(kind),{at.x,at.y,at.z},rotation);
    if (!result.ok) { last_error_=to_godot(result.message); return false; }
    wroughtwild::economy::remove(player_->inventory,{{kit,1}});
    return true;
}
Dictionary WroughtwildSim::contraption_remove(const String& key) {
    if (!contraptions_ || trial_) return machine_unavailable();
    const auto* state=contraptions_->state(to_std(key));
    if (!state) return machine_result({false,0,"That fixture is already gone."});
    const auto* recipe=tuning_->crafting.findRecipe("assemble_"+state->kind);
    // Preview refunds and cargo against one temporary inventory. A refusal
    // must preserve the intact fixture and its contents, including an extreme
    // restored pack count that cannot accept another recovered core.
    auto recovered=player_->inventory;
    if (recipe) {
        const std::set<std::string> cores={"lanternheart","thrumroot","stormglass","pullstone","ventlung"};
        for (const auto& [id,amount] : recipe->inputs) {
            const int refund=cores.count(id) ? amount : static_cast<int>(std::floor(amount*tuning_->construction.removalRefundFraction));
            if (refund<=0) continue;
            const auto found=recovered.find(id);
            const int existing=found==recovered.end() ? 0 : found->second;
            if (existing<0 || existing>std::numeric_limits<int>::max()-refund)
                return machine_result({false,0,"The recovered core or frame would overflow the pack. Make room before dismantling."});
            recovered[id]=existing+refund;
        }
    }
    const auto result=contraptions_->erase(to_std(key),recovered);
    if (result.ok) player_->inventory.swap(recovered);
    return machine_result(result);
}
PackedStringArray WroughtwildSim::contraption_ids() const {
    PackedStringArray ids;
    if (contraptions_) for (const auto& [id,state] : contraptions_->states()) { (void)state; ids.push_back(to_godot(id)); }
    return ids;
}
Dictionary WroughtwildSim::contraption_state(const String& key) const {
    Dictionary d;
    const auto* s=contraptions_ ? contraptions_->state(to_std(key)) : nullptr;
    if (!s) return d;
    d["key"]=to_godot(s->key); d["kind"]=to_godot(s->kind);
    d["position"]=Vector3(s->position[0],s->position[1],s->position[2]);
    d["quarter_turns"]=s->quarterTurns; d["link"]=to_godot(s->link);
    d["span_length"]=s->spanLength; d["energy"]=s->energy; d["lamp_on"]=s->lampOn;
    d["moving"]=s->moving; d["at_landing"]=s->atLanding; d["progress"]=s->progress;
    d["completed_trips"]=s->completedTrips; d["pulses"]=s->pulses;
    d["cargo"]=to_dictionary(s->cargo); d["input"]=to_dictionary(s->input);
    d["ferrous"]=to_dictionary(s->ferrous); d["remainder"]=to_dictionary(s->remainder);
    d["source_id"]=to_godot(s->sourceId); d["forge_key"]=to_godot(s->forgeKey);
    d["forge_position"]=Vector3(s->forgePosition[0],s->forgePosition[1],s->forgePosition[2]);
    d["output"]=to_dictionary(s->output); d["escrow_inputs"]=to_dictionary(s->escrowInputs);
    d["escrow_fuel"]=to_dictionary(s->escrowFuel); d["escrow_drive"]=s->escrowDrive;
    d["queued_cycles"]=s->queuedCycles; d["cycle_seconds"]=s->cycleSeconds;
    d["completed_cycles"]=s->completedCycles; d["feeder_paused"]=s->feederPaused;
    return d;
}
Dictionary WroughtwildSim::contraption_config() const {
    Dictionary d; if (!contraptions_) return d;
    const auto& c=contraptions_->config();
    d["maximum_machines"]=c.maximumMachines; d["cargo_units"]=c.cargoUnits;
    d["sorter_input_units"]=c.sorterInputUnits; d["sorter_tray_units"]=c.sorterTrayUnits;
    d["sorter_batch_units"]=c.sorterBatchUnits; d["energy_capacity"]=c.energyCapacity;
    d["winding_energy"]=c.windingEnergy; d["trip_energy"]=c.tripEnergy; d["bellows_energy"]=c.bellowsEnergy;
    d["maximum_span"]=c.maximumSpan; d["signal_range"]=c.signalRange; d["bellows_range"]=c.bellowsRange;
    d["cargo_metres_per_second"]=c.cargoMetresPerSecond; d["minimum_trip_seconds"]=c.minimumTripSeconds;
    d["pressure_source_strokes"]=c.pressureSourceStrokes;
    d["feeder_input_units"]=c.feederInputUnits; d["feeder_output_units"]=c.feederOutputUnits;
    d["feeder_batch_cycles"]=c.feederBatchCycles; d["feeder_cycle_seconds"]=c.feederCycleSeconds;
    d["feeder_attachment_range"]=c.feederAttachmentRange;
    d["feeder_inputs"]=to_dictionary(c.feederRecipeInputs); d["feeder_outputs"]=to_dictionary(c.feederRecipeOutputs);
    d["feeder_fuels"]=to_dictionary(c.feederFuels); d["feeder_fuel_cost"]=c.feederFuelCost;
    return d;
}
Dictionary WroughtwildSim::contraption_feeder_inspect(const String& key,bool physical_ready) const {
    Dictionary d,actions;
    Array loads;
    d["available"]=false;
    if (!contraptions_ || !player_ || trial_) {
        d["message"]="Contraptions wait outside trials.";
        for (const auto* action : {"start","charge","wind","pause","resume","cancel"})
            actions[action]=machine_unavailable();
    } else {
        const auto inspection=contraptions_->inspectFeeder(to_std(key),physical_ready,player_->inventory);
        d["available"]=inspection.available;
        d["message"]=to_godot(inspection.message);
        for (const auto& action : inspection.actions) actions[to_godot(action.first)]=machine_result(action.second);
        for (const auto& load : inspection.loads) {
            auto row=machine_result(load.result);
            row["item"]=to_godot(load.item); row["requested"]=load.requested;
            loads.push_back(row);
        }
    }
    d["actions"]=actions; d["loads"]=loads;
    return d;
}
Dictionary WroughtwildSim::contraption_link(const String& key,const String& target,bool clear) {
    return contraptions_ && !trial_ ? machine_result(contraptions_->link(to_std(key),to_std(target),clear)) : machine_unavailable();
}
Dictionary WroughtwildSim::contraption_action(const String& key,const String& action,bool clear,bool other_clear,double distance) {
    if (!contraptions_ || trial_) return machine_unavailable();
    const auto id=to_std(key);
    if (action=="wind") return machine_result(contraptions_->wind(id));
    if (action=="start") return machine_result(contraptions_->start(id,clear));
    if (action=="pulse") return machine_result(contraptions_->pulse(id,clear,other_clear));
    if (action=="toggle") return machine_result(contraptions_->toggleLamp(id));
    if (action=="prime") return machine_result(contraptions_->prime(id));
    if (action=="release") return machine_result(contraptions_->releaseBellows(id,clear,distance));
    if (action=="sort") return machine_result(contraptions_->sort(id));
    if (action=="charge") return machine_result(contraptions_->charge(id,contraptions_->config().energyCapacity,clear));
    if (action=="cancel") return machine_result(contraptions_->cancel(id));
    if (action=="pause" || action=="resume") return machine_result(contraptions_->pause(id,action=="pause"));
    return machine_result({false,0,"Unknown fixture action."});
}
Dictionary WroughtwildSim::contraption_tick(const String& key,double seconds,bool clear) {
    return contraptions_ && !trial_ ? machine_result(contraptions_->advance(to_std(key),seconds,clear)) : machine_unavailable();
}
Dictionary WroughtwildSim::contraption_deposit(const String& key,const String& item,int count) {
    return contraptions_ && !trial_ ? machine_result(contraptions_->deposit(to_std(key),to_std(item),count,player_->inventory)) : machine_unavailable();
}
Dictionary WroughtwildSim::contraption_withdraw(const String& key,const String& port,const String& item,int count) {
    return contraptions_ && !trial_ ? machine_result(contraptions_->withdraw(to_std(key),to_std(port),to_std(item),count,player_->carryRoom(to_std(item)),player_->inventory)) : machine_unavailable();
}
String WroughtwildSim::contraption_save() const { return contraptions_ ? to_godot(contraptions_->serialize()) : String(); }
bool WroughtwildSim::contraption_validate(const String& text) const {
    return contraptions_ && (text.is_empty() ? contraptions_->identity().sources.empty() : contraptions_->validate(to_std(text)));
}
bool WroughtwildSim::contraption_load(const String& text) {
    if (!contraptions_ || trial_) return false;
    if (text.is_empty()) {
        if (!contraptions_->identity().sources.empty()) { last_error_="Missing pressure-source ledger."; return false; }
        auto c=contraptions_->config(); auto identity=contraptions_->identity();
        contraptions_=std::make_unique<wroughtwild::contraptions::MachineWorld>(c,identity); return true;
    }
    std::string reason;
    if (contraptions_->restore(to_std(text),&reason)) return true;
    last_error_=to_godot(reason); return false;
}
wroughtwild::contraptions::WorldIdentity WroughtwildSim::machine_world_identity(const String& profile, int seed) const {
    const auto id=to_std(profile);
    if (!tuning_ || !contraptions_ || !wroughtwild::worldgen::knownProfile(id))
        throw std::runtime_error("Unknown pressure-source world.");
    const auto native_seed=static_cast<uint64_t>(seed);
    // Validation may populate the immutable last-world cache, but never changes
    // the selected profile, player or source ledger. The subsequent load and
    // terrain build reuse this identity instead of generating a 1 km world three
    // times. One cache replaces the former temporary second voxel allocation.
    if (!world_cache_ || world_cache_->profileId!=id || world_cache_->seed!=native_seed) {
        world_cache_.reset();
        world_cache_=std::make_unique<wroughtwild::worldgen::WorldMap>(wroughtwild::worldgen::generateProfile(*tuning_,native_seed,id));
    }
    const auto* map=world_cache_.get();
    wroughtwild::contraptions::WorldIdentity identity;
    identity.profile=id; identity.seed=native_seed;
    for (const auto& source:map->pressurePockets)
        identity.sources.push_back({source.id,{(source.x+0.5)*map->cellSize,source.y*map->cellSize,(source.z+0.5)*map->cellSize},contraptions_->config().pressureSourceStrokes});
    return identity;
}
bool WroughtwildSim::contraption_bind_world(const String& profile,int seed) {
    if (!contraptions_ || trial_) return false;
    // World construction is the only initializer. Reading a map never creates
    // pressure, and rebuilding the same world never restores spent stock.
    const auto& identity=contraptions_->identity();
    if (identity.profile==to_std(profile) && identity.seed==static_cast<uint64_t>(seed)) return true;
    try {
        auto next=std::make_unique<wroughtwild::contraptions::MachineWorld>(contraptions_->config(),machine_world_identity(profile,seed));
        contraptions_.swap(next); return true;
    } catch (const std::exception& e) { last_error_=to_godot(e.what()); return false; }
}
bool WroughtwildSim::contraption_validate_world(const String& text,const String& profile,int seed) const {
    if (!contraptions_) return false;
    try {
        wroughtwild::contraptions::MachineWorld candidate(contraptions_->config(),machine_world_identity(profile,seed));
        // A source world owns its complete ledger even before the first tap.
        if (text.is_empty()) return candidate.identity().sources.empty();
        return candidate.validate(to_std(text));
    } catch (const std::exception&) { return false; }
}
bool WroughtwildSim::contraption_load_world(const String& text,const String& profile,int seed) {
    if (!contraptions_ || trial_) return false;
    try {
        auto candidate=std::make_unique<wroughtwild::contraptions::MachineWorld>(contraptions_->config(),machine_world_identity(profile,seed));
        std::string reason;
        if (text.is_empty() ? !candidate->identity().sources.empty() : !candidate->restore(to_std(text),&reason)) {
            last_error_=reason.empty() ? String("Missing pressure-source ledger.") : to_godot(reason); return false;
        }
        contraptions_.swap(candidate); return true;
    } catch (const std::exception& e) { last_error_=to_godot(e.what()); return false; }
}
Array WroughtwildSim::contraption_pressure_sources() const {
    Array result; if (!contraptions_) return result;
    for (const auto& source:contraptions_->identity().sources) {
        Dictionary d; d["id"]=to_godot(source.id);
        d["position"]=Vector3(source.position[0],source.position[1],source.position[2]);
        d["capacity"]=source.capacity; d["remaining"]=contraptions_->sourceRemaining(source.id);
        result.push_back(d);
    }
    return result;
}
Dictionary WroughtwildSim::contraption_attach_feeder(const String& key,const String& source_id,const String& forge_key,const Vector3& forge_position,bool clear) {
    return contraptions_ && !trial_ ? machine_result(contraptions_->attachFeeder(to_std(key),to_std(source_id),to_std(forge_key),{forge_position.x,forge_position.y,forge_position.z},clear)) : machine_unavailable();
}
Array WroughtwildSim::rare_resource_guide() const {
    Array result; if (!tuning_) return result;
    // Recipes and observations remain inspectable in every generation profile;
    // this is information, never a discovery gate or an exact-location reveal.
    for (const auto& [id,node] : tuning_->worldgen.nodeTypes) {
        if (node.properties.empty() || node.usePreview.empty()) continue;
        Dictionary d; d["id"]=to_godot(id); d["display_name"]=to_godot(node.displayName);
        d["use_preview"]=to_godot(node.usePreview); d["properties"]=strings_to_packed(node.properties);
        d["harvest_stages"]=strings_to_packed(node.harvestStages);
        result.push_back(d);
    }
    return result;
}
