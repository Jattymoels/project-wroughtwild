// LF-1 binding. Rules own stock and claims; the engine owns physical reach and
// obstruction. World construction/whole-checkpoint load are the only binders.
namespace {
Dictionary leyline_result(const wroughtwild::leyline::Result& result) {
    Dictionary d; d["ok"]=result.ok; d["moved"]=result.moved; d["message"]=to_godot(result.message); return d;
}
}
bool WroughtwildSim::leyline_bind_world(const String& profile, int seed) {
    if (!tuning_ || trial_) return false;
    if (profile != wroughtwild::leyline::profile) { leylines_.reset(); leyline_positions_.clear(); return true; }
    if (seed < 0) return false;
    if (!leylines_ || leylines_->seed() != static_cast<uint64_t>(seed))
        leylines_ = std::make_unique<wroughtwild::leyline::World>(leyline_config_,static_cast<uint64_t>(seed));
    machine_world_identity(profile,seed);
    leyline_positions_.clear();
    for (const auto& s : leyline_config_.sources) {
        const auto at = wroughtwild::leyline::World::anchor(s,*world_cache_);
        leyline_positions_[s.id] = Vector3((at.x+.5)*world_cache_->cellSize,at.y*world_cache_->cellSize,(at.z+.5)*world_cache_->cellSize);
    }
    return true;
}
Array WroughtwildSim::leyline_sources() const {
    Array result;
    if (!leylines_) return result;
    for (const auto& source : leylines_->config().sources) {
        const auto& state = leylines_->state(source.id);
        Dictionary d;
        d["id"]=to_godot(source.id); d["label"]=to_godot(source.label); d["material"]=to_godot(source.material);
        d["position"]=leyline_positions_.at(source.id);
        d["manifestation"]=state.manifestation; d["lot"]=state.lot; d["lots"]=source.lots;
        d["work"]=state.work; d["steps"]=static_cast<int>(source.stages.size());
        d["next_work"]=to_godot(source.stages.at(state.work));
        d["units_per_lot"]=source.units; d["rare_per_10000"]=source.rarePer10000;
        d["rare_item"]=to_godot(source.rareItem); d["claim"]=to_dictionary(state.claim);
        d["formation"]=state.formation; d["formation_seconds"]=source.formationSeconds;
        // Hidden outcomes intentionally never enter discovery or inspection UI.
        result.push_back(d);
    }
    return result;
}
Dictionary WroughtwildSim::leyline_work(const String& id) {
    if (!leylines_ || trial_) return leyline_result({false,0,"Extraction waits outside trials."});
    try { return leyline_result(leylines_->work(to_std(id))); }
    catch (const std::exception& e) { return leyline_result({false,0,e.what()}); }
}
Dictionary WroughtwildSim::leyline_collect(const String& id,const String& item) {
    if (!leylines_ || trial_) return leyline_result({false,0,"Extraction waits outside trials."});
    try { return leyline_result(leylines_->collect(to_std(id),to_std(item),*player_)); }
    catch (const std::exception& e) { return leyline_result({false,0,e.what()}); }
}
void WroughtwildSim::leyline_tick(double seconds,const PackedStringArray& blocked) {
    if (!leylines_ || trial_) return;
    std::set<std::string> ids; for (int i=0;i<blocked.size();++i) ids.insert(to_std(blocked[i]));
    leylines_->advance(seconds,ids);
}
String WroughtwildSim::leyline_save() const { return leylines_ ? to_godot(leylines_->serialize()) : String(); }
bool WroughtwildSim::leyline_validate_world(const String& text,const String& profile,int seed) const {
    if (profile != wroughtwild::leyline::profile) return text.is_empty();
    if (!tuning_ || seed < 0 || text.is_empty()) return false;
    wroughtwild::leyline::World candidate(leyline_config_,static_cast<uint64_t>(seed));
    return candidate.restore(to_std(text));
}
bool WroughtwildSim::leyline_load_world(const String& text,const String& profile,int seed) {
    if (trial_ || !leyline_validate_world(text,profile,seed)) return false;
    if (profile != wroughtwild::leyline::profile) { leylines_.reset(); leyline_positions_.clear(); return true; }
    auto candidate=std::make_unique<wroughtwild::leyline::World>(leyline_config_,static_cast<uint64_t>(seed));
    if (!candidate->restore(to_std(text))) return false;
    leylines_.swap(candidate); return leyline_bind_world(profile,seed);
}
