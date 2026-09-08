#include "wroughtwild/leyline.h"
#include "wroughtwild/json.h"
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace wroughtwild::leyline {
namespace {
int integer(const json::Value& v, int low, int high) {
    const double n = v.asNumber();
    if (!std::isfinite(n) || n < low || n > high || std::floor(n) != n)
        throw std::runtime_error("Invalid leyline integer.");
    return static_cast<int>(n);
}
double number(const json::Value& v, double low, double high) {
    const double n = v.asNumber();
    if (!std::isfinite(n) || n < low || n > high) throw std::runtime_error("Invalid leyline clock or offset.");
    return n;
}
bool identifier(const std::string& s) {
    return !s.empty() && s.size() < 80 && s.find_first_not_of("abcdefghijklmnopqrstuvwxyz0123456789_") == std::string::npos;
}
uint64_t mix(uint64_t v) {
    v += 0x9e3779b97f4a7c15ull;
    v = (v ^ (v >> 30)) * 0xbf58476d1ce4e5b9ull;
    v = (v ^ (v >> 27)) * 0x94d049bb133111ebull;
    return v ^ (v >> 31);
}
}
Config Config::load(const std::string& path) {
    Config c;
    const auto doc = json::parseFile(path);
    if (integer(doc->get("version"), 1, 1) != 1) throw std::runtime_error("Unknown leyline tuning.");
    std::set<std::string> ids;
    for (const auto& value : doc->get("sources").asArray()) {
        Source s;
        s.id = value->get("id").asString(); s.label = value->get("label").asString();
        s.material = value->get("material").asString(); s.rareItem = value->get("rare_item").asString();
        if (!identifier(s.id) || !identifier(s.material) || (!s.rareItem.empty() && !identifier(s.rareItem)) || !ids.insert(s.id).second)
            throw std::runtime_error("Invalid or duplicate leyline source.");
        s.homeIndex = integer(value->get("home_index"), 0, 3);
        s.offsetX = number(value->get("offset_x_m"), -10, 10); s.offsetZ = number(value->get("offset_z_m"), -10, 10);
        s.lots = integer(value->get("lots"), 1, 32); s.units = integer(value->get("units_per_lot"), 1, 240);
        s.rarePer10000 = integer(value->get("rare_per_10000"), 0, 10000);
        s.formationSeconds = number(value->get("formation_seconds"), 1, 86400);
        for (const auto& stage : value->get("work_stages").asArray()) s.stages.push_back(stage->asString());
        if (s.stages.empty() || s.stages.size() > 16 || (s.rareItem.empty() && s.rarePer10000)) throw std::runtime_error("Invalid leyline work/rare definition.");
        c.sources.push_back(s);
    }
    if (c.sources.empty() || c.sources.size() > 2) throw std::runtime_error("LF-1 permits one Red and one White host only.");
    return c;
}
World::World(Config config, uint64_t seed) : config_(std::move(config)), seed_(seed) {
    for (const auto& s : config_.sources) form(s, states_[s.id]);
}
const Source& World::source(const std::string& id) const {
    for (const auto& s : config_.sources) if (s.id == id) return s;
    throw std::runtime_error("Unknown leyline host.");
}
const State& World::state(const std::string& id) const { return states_.at(id); }
worldgen::SurfacePoint World::anchor(const Source& s, const worldgen::WorldMap& map) {
    const auto& home = map.homeSites.at(static_cast<size_t>(s.homeIndex));
    const int x = home.x + static_cast<int>(std::round(s.offsetX / map.cellSize));
    const int z = home.z + static_cast<int>(std::round(s.offsetZ / map.cellSize));
    if (!map.inBounds(x,z) || std::hypot(s.offsetX,s.offsetZ) + 2 > home.radiusM)
        throw std::runtime_error("Leyline host leaves its guaranteed clear home margin.");
    return {x, map.topSolid(x,z), z};
}
void World::form(const Source& source, State& state) {
    state.lot = 0; state.work = 0; state.formation = 0; state.outcomes.clear();
    uint64_t salt = 1469598103934665603ull;
    for (unsigned char c : source.id) salt = (salt ^ c) * 1099511628211ull;
    for (int i = 0; i < source.lots; ++i)
        state.outcomes += mix(seed_ ^ salt ^ mix(static_cast<uint64_t>(state.manifestation)) ^ mix(static_cast<uint64_t>(i) + 73)) % 10000 < static_cast<uint64_t>(source.rarePer10000) ? '1' : '0';
}
Result World::work(const std::string& id) {
    const auto& s = source(id); auto& state = states_.at(id);
    if (!state.claim.empty()) return {false,0,"Collect the released lot before drawing another."};
    if (state.lot >= s.lots) return {false,0,"The host is forming. Return after more overworld activity."};
    if (++state.work < static_cast<int>(s.stages.size())) return {true,0,s.stages[state.work]};
    state.claim[s.material] = s.units;
    if (state.outcomes.at(state.lot) == '1') state.claim[s.rareItem] = 1;
    ++state.lot; state.work = 0;
    return {true,s.units,"Lot released. Collect the material from the exposed host."};
}
Result World::collect(const std::string& id, const std::string& item, economy::PlayerEconomy& player) {
    auto& claim = states_.at(id).claim;
    const auto found = claim.find(item);
    if (found == claim.end()) return {false,0,"That claim has already been collected."};
    const int moved = std::min(found->second, player.carryRoom(item));
    if (moved <= 0) return {false,0,"Pack full. This lot stays here for collection."};
    player.grant(item,moved);
    found->second -= moved;
    if (!found->second) claim.erase(found);
    return {true,moved,"Collected. Any remainder stays with this source."};
}
void World::advance(double seconds, const std::set<std::string>& blocked) {
    if (!std::isfinite(seconds) || seconds <= 0) return;
    for (const auto& s : config_.sources) {
        auto& state = states_.at(s.id);
        if (state.lot < s.lots || !state.claim.empty() || state.manifestation == 1000000000) continue;
        state.formation = std::min(s.formationSeconds, state.formation + seconds);
        if (state.formation >= s.formationSeconds && !blocked.count(s.id)) { ++state.manifestation; form(s,state); }
    }
}
std::string World::serialize() const {
    std::ostringstream out; out << std::setprecision(17);
    out << "{\"version\":1,\"profile\":\"" << profile << "\",\"seed\":\"" << seed_ << "\",\"sources\":{";
    bool first = true;
    for (const auto& [id,s] : states_) {
        if (!first) out << ',';
        first = false;
        out << '"' << id << "\":{\"manifestation\":" << s.manifestation << ",\"lot\":" << s.lot << ",\"work\":" << s.work
            << ",\"formation\":" << s.formation << ",\"outcomes\":\"" << s.outcomes << "\",\"claim\":{";
        bool firstItem = true;
        for (const auto& [item,n] : s.claim) { if (!firstItem) out << ','; firstItem = false; out << '"' << item << "\":" << n; }
        out << "}}";
    }
    out << "}}"; return out.str();
}
bool World::restore(const std::string& text, std::string* reason) {
    try {
        const auto doc = json::parse(text);
        integer(doc->get("version"),1,1);
        if (doc->get("profile").asString() != profile || doc->get("seed").asString() != std::to_string(seed_)) throw std::runtime_error("Leyline world identity mismatch.");
        const auto& records = doc->get("sources").asObject();
        if (records.size() != config_.sources.size()) throw std::runtime_error("Missing or unknown leyline source.");
        std::map<std::string,State> next;
        for (const auto& def : config_.sources) {
            const auto& record = *records.at(def.id); State s;
            s.manifestation = integer(record.get("manifestation"),0,1000000000);
            s.lot = integer(record.get("lot"),0,def.lots);
            s.work = integer(record.get("work"),0,static_cast<int>(def.stages.size())-1);
            s.formation = number(record.get("formation"),0,def.formationSeconds);
            s.outcomes = record.get("outcomes").asString();
            if (s.outcomes.size() != static_cast<size_t>(def.lots) || s.outcomes.find_first_not_of("01") != std::string::npos) throw std::runtime_error("Invalid fixed lot outcomes.");
            for (const auto& [id,n] : record.get("claim").asObject()) {
                if (id != def.material && (def.rareItem.empty() || id != def.rareItem)) throw std::runtime_error("Invalid claim item.");
                s.claim[id] = integer(*n,1,id == def.material ? def.units : 1);
                if (id == def.rareItem && (s.lot == 0 || s.outcomes[s.lot-1] != '1')) throw std::runtime_error("Rare claim has no completed winning lot.");
            }
            if ((!s.claim.empty() && (s.lot == 0 || s.work != 0 || s.formation != 0)) || (s.lot == def.lots && s.work != 0) || (s.lot < def.lots && s.formation != 0)) throw std::runtime_error("Inconsistent leyline work and claims.");
            if (def.rareItem.empty() && s.outcomes.find('1') != std::string::npos) throw std::runtime_error("This host has no rare pool.");
            next.emplace(def.id,s);
        }
        states_.swap(next); return true;
    } catch (const std::exception& e) { if (reason) *reason = e.what(); return false; }
}
} // namespace wroughtwild::leyline
