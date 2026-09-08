#include "wroughtwild/contraptions.h"
#include "wroughtwild/json.h"

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <limits>
#include <sstream>
#include <stdexcept>

namespace wroughtwild::contraptions {
namespace {
using Inventory = economy::Inventory;
Result yes(const std::string& text, int count = 0) { return {true, count, text}; }
Result no(const std::string& text) { return {false, 0, text}; }
int units(const Inventory& inventory) {
    long long total = 0;
    for (const auto& entry : inventory) total += entry.second;
    return static_cast<int>(std::min(total, static_cast<long long>(std::numeric_limits<int>::max())));
}
bool identifier(const std::string& value) {
    if (value.empty() || value.size() > 160) return false;
    for (unsigned char c : value) if (c < 32 || c == 127) return false;
    return true;
}
int integer(const json::Value& value, int lower, int upper) {
    const double number = value.asNumber();
    if (!std::isfinite(number) || number < lower || number > upper || std::floor(number) != number)
        throw std::runtime_error("contraptions: invalid integer");
    return static_cast<int>(number);
}
double finite(const json::Value& value, double lower, double upper) {
    const double number = value.asNumber();
    if (!std::isfinite(number) || number < lower || number > upper)
        throw std::runtime_error("contraptions: invalid number");
    return number;
}
double distance(const State& a, const State& b) {
    double square = 0;
    for (int i = 0; i < 3; ++i) square += std::pow(a.position[i] - b.position[i], 2);
    return std::sqrt(square);
}
double distance(const std::array<double,3>& a, const std::array<double,3>& b) {
    double square = 0;
    for (int i=0;i<3;++i) square += std::pow(a[i]-b[i],2);
    return std::sqrt(square);
}
std::string quoted(const std::string& value) {
    std::ostringstream out;
    out << '"';
    for (unsigned char c : value) {
        if (c == '"' || c == '\\') out << '\\' << c;
        else if (c < 32) out << "\\u" << std::hex << std::setw(4) << std::setfill('0') << int(c) << std::dec;
        else out << c;
    }
    out << '"';
    return out.str();
}
void writeInventory(std::ostream& out, const Inventory& inventory) {
    out << '{';
    bool first = true;
    for (const auto& entry : inventory) {
        if (!first) out << ',';
        first = false;
        out << quoted(entry.first) << ':' << entry.second;
    }
    out << '}';
}
void reduce(Inventory& inventory, const std::string& item, int count) {
    auto it = inventory.find(item);
    it->second -= count;
    if (it->second == 0) inventory.erase(it);
}
bool addSafe(Inventory& destination, const Inventory& input) {
    for (const auto& entry : input) {
        auto existing = destination.find(entry.first);
        const int current = existing == destination.end() ? 0 : existing->second;
        if (current < 0 || current > std::numeric_limits<int>::max() - entry.second) return false;
        destination[entry.first] = current + entry.second;
    }
    return true;
}
// Match ordinary crafting: after reserving ingredients, spend lower-heat fuel
// first, with stable item-id order for ties. No quality or mastery path runs.
bool selectFuel(const Inventory& available, const Config& config, Inventory& chosen) {
    std::vector<std::pair<int,std::string>> fuels;
    for (const auto& entry : config.feederFuels) fuels.emplace_back(entry.second,entry.first);
    std::sort(fuels.begin(),fuels.end());
    int needed=config.feederFuelCost;
    for (const auto& fuel : fuels) {
        const auto held=available.find(fuel.second);
        if (needed<=0) break;
        if (held==available.end()) continue;
        const int take=static_cast<int>(std::min<long long>(held->second,(static_cast<long long>(needed)+fuel.first-1)/fuel.first));
        if (take>0) { chosen[fuel.second]=take; needed-=take*fuel.first; }
    }
    return needed<=0;
}
}

Config Config::load(const std::string& path) {
    const auto root = json::parseFile(path);
    Config c;
    c.maximumMachines = integer(root->get("maximum_machines"), 1, 4096);
    c.cargoUnits = integer(root->get("cargo_units"), 1, 100000);
    c.sorterInputUnits = integer(root->get("sorter_input_units"), 1, 100000);
    c.sorterTrayUnits = integer(root->get("sorter_tray_units"), 1, 100000);
    c.sorterBatchUnits = integer(root->get("sorter_batch_units"), 1, 100000);
    c.energyCapacity = integer(root->get("energy_capacity"), 1, 100000);
    c.windingEnergy = integer(root->get("winding_energy"), 1, c.energyCapacity);
    c.tripEnergy = integer(root->get("trip_energy"), 1, c.energyCapacity);
    c.bellowsEnergy = integer(root->get("bellows_energy"), 1, c.energyCapacity);
    c.maximumSpan = finite(root->get("maximum_span"), 0.01, 1024);
    c.signalRange = finite(root->get("signal_range"), 0.01, 1024);
    c.delaySeconds = finite(root->get("delay_seconds"), .01, 60);
    c.bellowsRange = finite(root->get("bellows_range"), 0.01, 32);
    c.cargoMetresPerSecond = finite(root->get("cargo_metres_per_second"), 0.01, 100);
    c.minimumTripSeconds = finite(root->get("minimum_trip_seconds"), 0.01, 60);
    c.maximumCoordinate = finite(root->get("maximum_coordinate"), 1, 100000);
    c.pressureSourceStrokes = integer(root->get("pressure_source_strokes"),1,100000);
    c.feederInputUnits = integer(root->get("feeder_input_units"),1,100000);
    c.feederOutputUnits = integer(root->get("feeder_output_units"),1,100000);
    c.feederBatchCycles = integer(root->get("feeder_batch_cycles"),1,100);
    c.feederCycleSeconds = finite(root->get("feeder_cycle_seconds"),.01,3600);
    c.feederAttachmentRange = finite(root->get("feeder_attachment_range"),.01,64);
    c.heatCapacity = integer(root->get("heat_capacity"),1,100);
    c.heatInput.clear();
    for (const auto& [id,n] : root->get("heat_input").asObject()) {
        if (!identifier(id)) throw std::runtime_error("contraptions: invalid thermal input");
        c.heatInput[id]=integer(*n,1,100000);
    }
    if (c.heatInput.empty()) throw std::runtime_error("contraptions: heat must be paid");
    for (const auto& item : root->get("ferrous_items").asArray()) {
        if (!identifier(item->asString()) || !c.ferrousItems.insert(item->asString()).second)
            throw std::runtime_error("contraptions: duplicate or invalid ferrous item");
    }
    if (c.ferrousItems.empty()) throw std::runtime_error("contraptions: ferrous property set is empty");
    return c;
}

MachineWorld::MachineWorld(Config config, WorldIdentity identity) : config_(std::move(config)), identity_(std::move(identity)) {
    if (!identity_.profile.empty() && !identifier(identity_.profile)) throw std::runtime_error("contraptions: invalid world profile");
    if (!identity_.sources.empty() && identity_.profile != "frontier_v5" && identity_.profile != "frontier_v6" && identity_.profile != "living_frontier_wave1") throw std::runtime_error("contraptions: pressure belongs only to its frozen source profile");
    for (const auto& source : identity_.sources) {
        if (!identifier(source.id) || source.capacity != config_.pressureSourceStrokes || !sources_.emplace(source.id,source.capacity).second)
            throw std::runtime_error("contraptions: invalid native pressure source");
        for (double value : source.position) if (!std::isfinite(value) || std::abs(value)>config_.maximumCoordinate)
            throw std::runtime_error("contraptions: invalid native source position");
    }
}
const PressureSource* MachineWorld::sourceDefinition(const std::string& id) const {
    for (const auto& source : identity_.sources) if (source.id==id) return &source;
    return nullptr;
}
int MachineWorld::sourceRemaining(const std::string& id) const {
    const auto found=sources_.find(id);
    return found==sources_.end() ? -1 : found->second;
}
const State* MachineWorld::state(const std::string& key) const {
    const auto it = states_.find(key);
    return it == states_.end() ? nullptr : &it->second;
}
State* MachineWorld::mutableState(const std::string& key) {
    const auto it = states_.find(key);
    return it == states_.end() ? nullptr : &it->second;
}
bool MachineWorld::knownKind(const std::string& kind) {
    return kind == "lantern_lamp" || kind == "cargo_winch" || kind == "winch_landing" ||
           kind == "stormglass_lever" || kind == "magnetic_sorter" || kind == "ventlung_bellows" || kind == "pressure_feeder" || kind == "white_connection" || kind == "blue_delay" || kind == "green_junction" || kind == "red_heat_buffer";
}
bool MachineWorld::itemAllowed(const std::string& item) const {
    return identifier(item) && (config_.allowedItems.empty() || config_.allowedItems.count(item) > 0);
}
Result MachineWorld::create(const std::string& key, const std::string& kind,
                            const std::array<double, 3>& position, int quarterTurns) {
    if (!knownKind(kind) || !identifier(key)) return no("Unknown fixture or invalid placement key.");
    if ((kind=="white_connection" || kind=="blue_delay" || kind=="green_junction" || kind=="red_heat_buffer") && identity_.profile!="living_frontier_wave1") return no("Coloured components belong to the Living Frontier experiment.");
    if (kind=="pressure_feeder" && !feederRecipeReady()) return no("The existing decorative forge recipe is unavailable.");
    if (state(key)) return no("That placement already contains a fixture.");
    if (states_.size() >= static_cast<size_t>(config_.maximumMachines)) return no("The world's fixture limit is reached.");
    if (quarterTurns < 0 || quarterTurns > 3) return no("Invalid fixture orientation.");
    for (double coordinate : position)
        if (!std::isfinite(coordinate) || std::abs(coordinate) > config_.maximumCoordinate) return no("Invalid fixture position.");
    State s;
    s.key = key; s.kind = kind; s.position = position; s.quarterTurns = quarterTurns;
    states_.emplace(key, std::move(s));
    return yes("Fixture placed.");
}
Result MachineWorld::erase(const std::string& key, Inventory& pack) {
    const auto* current = state(key);
    if (!current) return no("The fixture is already removed.");
    if (current->kind=="red_heat_buffer") {
        const auto* feeder=state(current->link);
        if (feeder && feeder->escrowDrive) return no("Finish or cancel the firing before dismantling its heat buffer.");
    }
    Inventory returned = pack;
    for (const Inventory* contents : {&current->cargo, &current->input, &current->ferrous, &current->remainder,
                                    &current->output, &current->escrowInputs, &current->escrowFuel})
        if (!addSafe(returned, *contents)) return no("The recovered contents would overflow the pack.");
    const int vented=current->heat;
    if (current->escrowHeat) {
        auto* buffer=mutableState(current->heatKey);
        if (!buffer || buffer->heat>config_.heatCapacity-current->escrowHeat) return no("Reserved heat cannot return to its owner.");
        buffer->heat+=current->escrowHeat;
    }
    if (current->kind=="red_heat_buffer") {
        if (auto* feeder=mutableState(current->link)) feeder->heatKey.clear();
    }
    invalidateDelays(key);
    // Recall a basket before destroying its landing. Keep its one inventory at
    // the drum; a signal link never owns or receives cargo.
    for (auto& entry : states_) if (entry.second.link == key) {
        auto& source = entry.second;
        source.link.clear(); source.spanLength = 0;
        if (source.kind == "cargo_winch") {
            source.moving = false; source.atLanding = false; source.progress = 0;
        }
    }
    for (auto& [id,s] : states_) if (s.secondLink==key) { (void)id; s.secondLink.clear(); s.secondSpanLength=0; }
    pack.swap(returned);
    states_.erase(key);
    return yes(vented ? "Recovered the frame; vented "+std::to_string(vented)+" unused heat. Spent charge salt does not return." : "Recovered the fixture and all its contents.");
}
Result MachineWorld::link(const std::string& source, const std::string& target, bool clear) {
    auto* from = mutableState(source);
    if (from && from->kind=="red_heat_buffer") return linkHeat(*from,target,clear);
    if (from && target.empty() && (from->kind=="stormglass_lever" || from->kind=="white_connection" || from->kind=="blue_delay" || from->kind=="green_junction")) {
        invalidateDelays(source);
        from->link.clear(); from->spanLength=0;
        return yes("Signal disconnected. A departed basket keeps its paid trip and cargo.");
    }
    const auto* to = state(target);
    if (!from || !to || from == to) return no("Choose two different placed fixtures.");
    if (!clear) return no("The supported span must be clear.");
    const double length = distance(*from, *to);
    if (from->kind == "cargo_winch") {
        if (to->kind != "winch_landing") return no("A cargo drum links to a fixed landing.");
        if (from->moving || from->atLanding || !from->cargo.empty()) return no("Return and empty the basket before changing its landing.");
        if (length <= 0 || length > config_.maximumSpan) return no("The landing is outside the winch's local span.");
        for (const auto& entry : states_)
            if (entry.first != source && entry.second.kind == "cargo_winch" && entry.second.link == target)
                return no("That landing already belongs to another drum.");
    } else if (from->kind == "stormglass_lever") {
        if (to->kind != "cargo_winch" && to->kind != "lantern_lamp" && to->kind != "pressure_feeder" && to->kind != "white_connection" && to->kind != "blue_delay" && to->kind != "green_junction") return no("Stormglass requests one local operation or a coloured connection.");
        if (length > config_.signalRange) return no("The receiver is outside local signal range.");
    } else if (from->kind == "white_connection") {
        if (to->kind != "cargo_winch" && to->kind != "pressure_feeder" && to->kind != "blue_delay" && to->kind != "green_junction") return no("White forwards one request to a paid receiver, Blue delay or Green junction.");
        if (length > config_.signalRange) return no("The drum is outside local signal range.");
    } else if (from->kind == "blue_delay") {
        if (to->kind != "cargo_winch" && to->kind != "pressure_feeder" && to->kind != "green_junction") return no("Blue releases to a paid receiver or Green junction.");
        if (length > config_.signalRange) return no("The receiver is outside local signal range.");
    } else if (from->kind == "green_junction") {
        if ((to->kind!="cargo_winch" && to->kind!="pressure_feeder") || target==from->secondLink) return no("Choose a distinct paid receiver for each Green port.");
        if (length > config_.signalRange) return no("The receiver is outside local signal range.");
    } else return no("This fixture does not send a link.");
    if (from->link != target) invalidateDelays(source);
    from->link = target; from->spanLength = length;
    return yes("Linked. Signals request work; the drum still needs winding.");
}
Result MachineWorld::linkSecond(const std::string& source, const std::string& target, bool clear) {
    auto* from=mutableState(source);
    if (!from || from->kind!="green_junction") return no("Only Green has a second signal port.");
    if (target.empty()) {
        invalidateDelays(source); from->secondLink.clear(); from->secondSpanLength=0;
        return yes("Second signal disconnected; any held request on this route was cancelled.");
    }
    const auto* to=state(target);
    if (!to || target==from->link || (to->kind!="cargo_winch" && to->kind!="pressure_feeder")) return no("Choose a distinct paid receiver for each Green port.");
    if (!clear || distance(*from,*to)>config_.signalRange) return no("The supported second signal span must be clear and local.");
    if (from->secondLink!=target) invalidateDelays(source);
    from->secondLink=target; from->secondSpanLength=distance(*from,*to);
    return yes("Second receiver linked. It pays its own work and materials.");
}
Result MachineWorld::linkHeat(State& buffer, const std::string& target, bool clear) {
    auto* previous=mutableState(buffer.link);
    if (previous && previous->escrowDrive) return no("Finish or cancel the firing before changing its thermal connection.");
    auto* feeder=mutableState(target);
    if (!target.empty()) {
        if (!feeder || feeder->kind!="pressure_feeder" || feeder->escrowDrive) return no("Choose an idle pressure feeder.");
        if (!feeder->heatKey.empty() && feeder->heatKey!=buffer.key) return no("That feeder already owns a heat connection.");
        if (!clear || distance(buffer,*feeder)>config_.feederAttachmentRange) return no("Support both ends and clear the local thermal connection.");
    }
    if (previous) previous->heatKey.clear();
    buffer.link=target; buffer.spanLength=feeder ? distance(buffer,*feeder) : 0;
    if (feeder) feeder->heatKey=buffer.key;
    return yes(feeder ? "Red heat attached. The feeder pays one stored heat and its own winding per firing." : "Heat disconnected. The feeder uses its ordinary fuel again.");
}
Result MachineWorld::chargeHeat(const std::string& key, Inventory& pack, bool supported) {
    auto* buffer=mutableState(key);
    if (!buffer || buffer->kind!="red_heat_buffer") return no("No Red heat buffer is placed here.");
    if (!supported) return no("Restore physical support before charging heat.");
    const auto* feeder=state(buffer->link);
    const int reserved=feeder ? feeder->escrowHeat : 0;
    if (buffer->heat+reserved>=config_.heatCapacity) return no("The heat buffer is full, including reserved heat's return space.");
    for (const auto& [item,count] : config_.heatInput) {
        const auto held=pack.find(item);
        if (held==pack.end() || held->second<count) return no("Carry every displayed ingredient for one paid heat charge.");
    }
    for (const auto& [item,count] : config_.heatInput) reduce(pack,item,count);
    ++buffer->heat;
    return yes("Paid for one stored heat. Mechanical winding remains separate.",1);
}
Result MachineWorld::wind(const std::string& key) {
    auto* s = mutableState(key);
    if (!s || (s->kind != "cargo_winch" && s->kind != "pressure_feeder")) return no("Only a Thrumroot drum or feeder stores winding.");
    if (s->moving) return no("Let the basket finish its trip before winding.");
    const int added = std::min(config_.windingEnergy, config_.energyCapacity - s->energy - s->escrowDrive);
    if (added <= 0) return no("The drum is fully wound.");
    s->energy += added;
    return yes("Wound the drum. One operation is stored.", added);
}
Result MachineWorld::start(const std::string& key, bool clear) {
    auto* s = mutableState(key);
    if (s && s->kind=="pressure_feeder") {
        if (s->escrowDrive || s->queuedCycles) return no("The feeder already owns a batch; resume or cancel it.");
        if (!clear || s->forgeKey.empty()) return no("Attach a supported, unobstructed player-built basic forge first.");
        auto result=reserveFeeder(*s);
        if (result.ok) { s->queuedCycles=config_.feederBatchCycles; s->feederPaused=false; }
        return result;
    }
    if (!s || s->kind != "cargo_winch") return no("The receiver is not a cargo drum.");
    if (s->moving) return no("The basket is already travelling.");
    const auto* target = state(s->link);
    if (!target || target->kind != "winch_landing") return no("Connect a supported landing first.");
    if (!clear) return no("The basket's span is blocked. Clear it before departure.");
    if (s->energy < config_.tripEnergy) return no("The drum is unwound. A signal cannot supply energy.");
    if (s->completedTrips == std::numeric_limits<int>::max()) return no("The drum's trip counter is full.");
    s->energy -= config_.tripEnergy;
    s->moving = true; s->progress = 0;
    return yes("The basket departs.");
}
Result MachineWorld::advance(const std::string& key, double seconds, bool clear) {
    auto* s = mutableState(key);
    if (s && s->kind=="blue_delay") return advanceDelay(key,seconds,clear,true);
    if (s && s->kind=="pressure_feeder") {
        if (!std::isfinite(seconds) || seconds<0) return no("Invalid elapsed time.");
        if (!s->escrowDrive) return no("The feeder has no reserved cycle.");
        if (!clear || s->feederPaused) return no("The feeder is paused; its reserved materials and drive remain safe.");
        s->cycleSeconds=std::min(config_.feederCycleSeconds,s->cycleSeconds+seconds);
        if (s->cycleSeconds<config_.feederCycleSeconds) return yes("The feeder is firing its reserved batch.");
        addSafe(s->output,config_.feederRecipeOutputs); // Space belongs to this escrow already.
        s->escrowInputs.clear(); s->escrowFuel.clear(); s->escrowHeat=0; s->escrowDrive=0; s->cycleSeconds=0;
        ++s->completedCycles; --s->queuedCycles;
        if (s->queuedCycles>0) {
            auto next=reserveFeeder(*s);
            if (!next.ok) { s->queuedCycles=0; return yes("Bricks completed. Batch stopped: "+next.message,units(config_.feederRecipeOutputs)); }
        }
        // Discard surplus delta: one call cannot catch up several absent cycles.
        return yes("Reserved materials became finished bricks once.",units(config_.feederRecipeOutputs));
    }
    if (!s || s->kind != "cargo_winch") return no("No cargo drum is placed here.");
    if (!std::isfinite(seconds) || seconds < 0) return no("Invalid elapsed time.");
    if (!s->moving) return no("The basket is stationary.");
    if (!clear) return no("The basket is paused by a blocked span; its cargo is safe.");
    if (!state(s->link)) return no("The landing is missing.");
    const double duration = std::max(config_.minimumTripSeconds, s->spanLength / config_.cargoMetresPerSecond);
    s->progress = std::min(1.0, s->progress + seconds / duration);
    if (s->progress >= 1) {
        s->moving = false; s->atLanding = !s->atLanding; s->progress = 0;
        ++s->completedTrips;
        return yes("The basket has arrived. Its contents can now be collected.");
    }
    return yes("The basket is travelling.");
}
Result MachineWorld::pulse(const std::string& key, bool signalClear, bool spanClear) {
    return request(key,{signalClear,true,true,spanClear,spanClear});
}
Result MachineWorld::request(const std::string& key, const SignalSpace& space) {
    auto* s=mutableState(key);
    if (!s || s->kind!="stormglass_lever") return no("This is not a Stormglass lever.");
    return forward(*s,space);
}
Result MachineWorld::forward(State& from, const SignalSpace& space) {
    auto* target=mutableState(from.link);
    if (!target) return no("Signal output disconnected. Choose its receiver.");
    auto* white=target->kind=="white_connection" ? target : nullptr;
    if (white) {
        target=mutableState(white->link);
        if (!target) return no("White output disconnected. Choose its receiver.");
    }
    if (!space.path) return no("Clear and support the signal path.");
    if (target->kind=="blue_delay" && (!state(target->link) || target->pendingRequest)) return no("Blue is disconnected or already holds one request.");
    if ((from.kind=="stormglass_lever" && from.pulses==std::numeric_limits<int>::max()) || (white && white->pulses==std::numeric_limits<int>::max()) ||
        ((target->kind=="blue_delay" || target->kind=="green_junction") && target->pulses==std::numeric_limits<int>::max())) return no("The signal counter is full.");
    if (from.kind=="stormglass_lever") ++from.pulses;
    if (white) ++white->pulses;
    if (target->kind=="blue_delay") {
        ++target->pulses; target->pendingRequest=true; target->delayPaused=false; target->delaySeconds=0;
        return yes("Blue holds one request. Each receiver pays its own work at release.");
    }
    if (target->kind=="green_junction") {
        ++target->pulses;
        // Ports cannot share a receiver or target another component. No loop,
        // reconvergence, recursion or queued child request is possible.
        auto first=space.firstLink ? start(target->link,space.firstReceiver) : no("First signal span blocked.");
        auto second=space.secondLink ? start(target->secondLink,space.secondReceiver) : no("Second signal span blocked.");
        return {first.ok || second.ok,static_cast<int>(first.ok)+static_cast<int>(second.ok),"First: "+first.message+" Second: "+second.message};
    }
    if (target->kind=="lantern_lamp") return toggleLamp(target->key);
    return start(target->key,space.firstReceiver);
}
bool MachineWorld::signalReaches(const std::string& from, const std::string& target) const {
    const State* s=state(from);
    // The ordered lever -> White -> Blue -> receiver topology is acyclic.
    for (int step=0; s && step<5; ++step) {
        if (s->key==target) return true;
        if (s->kind=="green_junction") return s->link==target || s->secondLink==target;
        if (s->kind!="stormglass_lever" && s->kind!="white_connection" && s->kind!="blue_delay") break;
        s=state(s->link);
    }
    return false;
}
void MachineWorld::invalidateDelays(const std::string& changed) {
    for (auto& [key,s] : states_) if (s.kind=="blue_delay" && s.pendingRequest &&
        (signalReaches(changed,key) || signalReaches(key,changed))) {
        s.pendingRequest=false; s.delayPaused=false; s.delaySeconds=0;
    }
}
Result MachineWorld::advanceDelay(const std::string& key, double seconds, bool signalClear, bool receiverClear) {
    return advanceDelay(key,seconds,{signalClear,true,true,receiverClear,receiverClear});
}
Result MachineWorld::advanceDelay(const std::string& key, double seconds, const SignalSpace& space) {
    auto* s=mutableState(key);
    if (!s || s->kind!="blue_delay" || !s->pendingRequest) return no("Blue has no pending request.");
    if (!std::isfinite(seconds) || seconds<0) return no("Invalid elapsed time.");
    if (s->delayPaused || !space.path) return no("Blue is holding: paused or its output span/support is blocked.");
    if (!state(s->link)) return no("Blue output is disconnected.");
    s->delaySeconds=std::min(config_.delaySeconds,s->delaySeconds+seconds);
    if (s->delaySeconds<config_.delaySeconds) return yes("Blue holds one request during its visible delay.");
    s->pendingRequest=false; s->delayPaused=false; s->delaySeconds=0;
    const auto result=forward(*s,space);
    return {result.ok,result.moved,"Blue released its request once. "+result.message};
}
Result MachineWorld::toggleLamp(const std::string& key) {
    auto* s = mutableState(key);
    if (!s || s->kind != "lantern_lamp") return no("This receiver is not a Lanternheart lamp.");
    s->lampOn = !s->lampOn;
    return yes(s->lampOn ? "The Lanternheart opens warmly." : "The Lanternheart is shuttered.");
}
Result MachineWorld::prime(const std::string& key) {
    auto* s = mutableState(key);
    if (!s || s->kind != "ventlung_bellows") return no("Only Ventlung bellows hold primed pressure.");
    const int added = std::min(config_.windingEnergy, config_.energyCapacity - s->energy);
    if (added <= 0) return no("The chamber is already primed.");
    s->energy += added;
    return yes("Primed the bellows by hand.", added);
}
Result MachineWorld::releaseBellows(const std::string& key, bool compatibleTarget, double range) {
    auto* s = mutableState(key);
    if (!s || s->kind != "ventlung_bellows") return no("No bellows are placed here.");
    if (!compatibleTarget || !std::isfinite(range) || range < 0 || range > config_.bellowsRange)
        return no("Aim the bellows at a nearby set wedge or impact-responsive seam.");
    if (s->energy < config_.bellowsEnergy) return no("Prime the chamber by hand first.");
    s->energy -= config_.bellowsEnergy;
    return yes("Released pressure: the pulse drives the existing impact response.");
}
State* MachineWorld::cargoOwner(const std::string& key) {
    auto* s = mutableState(key);
    if (!s) return nullptr;
    if (s->kind == "cargo_winch") return !s->moving && !s->atLanding ? s : nullptr;
    if (s->kind == "winch_landing")
        for (auto& entry : states_) {
            auto& winch = entry.second;
            if (winch.kind == "cargo_winch" && winch.link == key && !winch.moving && winch.atLanding) return &winch;
        }
    return nullptr;
}
Result MachineWorld::deposit(const std::string& key, const std::string& item, int count, Inventory& pack) {
    if (count <= 0 || !itemAllowed(item)) return no("Choose an ordinary carried ingredient.");
    auto held = pack.find(item);
    if (held == pack.end() || held->second <= 0) return no("That ingredient is not in your pack.");
    auto* s = mutableState(key);
    if (!s) return no("No fixture is placed here.");
    Inventory* target = nullptr;
    int capacity = 0;
    if (s->kind == "magnetic_sorter") { target = &s->input; capacity = config_.sorterInputUnits; }
    else if (s->kind == "pressure_feeder" && feederItem(item)) {
        target=&s->input; capacity=config_.feederInputUnits-units(s->escrowInputs)-units(s->escrowFuel);
    }
    else if (auto* owner = cargoOwner(key)) { target = &owner->cargo; capacity = config_.cargoUnits; }
    if (!target) return no("Wait for the basket at this endpoint, or use a sorter input.");
    const int moved = std::min({count, held->second, capacity - units(*target)});
    if (moved <= 0) return no("This input is full.");
    (*target)[item] += moved;
    reduce(pack, item, moved);
    return yes("Loaded the carried ingredients.", moved);
}
Result MachineWorld::withdraw(const std::string& key, const std::string& port,
                              const std::string& item, int count, int packRoom, Inventory& pack) {
    if (count <= 0 || packRoom <= 0 || !itemAllowed(item)) return no("There is no pack room for that ingredient.");
    auto* s = mutableState(key);
    if (!s) return no("No fixture is placed here.");
    Inventory* source = nullptr;
    if (port == "cargo") { if (auto* owner = cargoOwner(key)) source = &owner->cargo; }
    if (s->kind == "magnetic_sorter") {
        if (port == "input") source = &s->input;
        if (port == "ferrous") source = &s->ferrous;
        if (port == "remainder") source = &s->remainder;
    }
    if (s->kind == "pressure_feeder") {
        if (port=="input") source=&s->input;
        if (port=="output") source=&s->output;
    }
    if (!source) return no("That tray or stationary basket is not available here.");
    const auto held = source->find(item);
    if (held == source->end()) return no("That ingredient is not in this container.");
    const auto previous = pack.find(item);
    const int existing = previous == pack.end() ? 0 : previous->second;
    if (existing < 0) return no("Invalid pack count.");
    const int moved = std::min({count, held->second, packRoom, std::numeric_limits<int>::max() - existing});
    if (moved <= 0) return no("There is no pack room for that ingredient.");
    pack[item] = existing + moved;
    reduce(*source, item, moved);
    return yes("Collected the ingredients.", moved);
}
Result MachineWorld::sort(const std::string& key) {
    auto* s = mutableState(key);
    if (!s || s->kind != "magnetic_sorter") return no("Only a Pullstone chute separates the hand-fed batch.");
    int moved = 0;
    for (auto it = s->input.begin(); it != s->input.end() && moved < config_.sorterBatchUnits;) {
        Inventory& tray = config_.ferrousItems.count(it->first) ? s->ferrous : s->remainder;
        const int count = std::min({it->second, config_.sorterBatchUnits - moved, config_.sorterTrayUnits - units(tray)});
        if (count > 0) { tray[it->first] += count; it->second -= count; moved += count; }
        if (it->second == 0) it = s->input.erase(it); else ++it;
    }
    return moved > 0 ? yes("Iron follows the magnet; the other ingredients fall into the second tray.", moved) : no("The input is empty or its destination tray is full.");
}

bool MachineWorld::feederItem(const std::string& item) const {
    return itemAllowed(item) && (config_.feederRecipeInputs.count(item)>0 || config_.feederFuels.count(item)>0);
}
bool MachineWorld::feederRecipeReady() const {
    if (config_.feederRecipeInputs.empty() || config_.feederRecipeOutputs.empty() || config_.feederFuelCost<0) return false;
    for (const auto* items : {&config_.feederRecipeInputs,&config_.feederRecipeOutputs,&config_.feederFuels})
        for (const auto& item : *items) if (!itemAllowed(item.first) || item.second<=0 || item.second>100000) return false;
    return config_.feederFuelCost<=100000 && (config_.feederFuelCost==0 || !config_.feederFuels.empty());
}
Result MachineWorld::reserveFeeder(State& s) {
    if (!feederRecipeReady()) return no("The existing decorative forge recipe is unavailable.");
    if (s.energy<1) return no("Store a pressure stroke or wind the feeder by hand.");
    if (s.completedCycles==std::numeric_limits<int>::max()) return no("The feeder's completed-cycle counter is full.");
    if (units(s.output)>config_.feederOutputUnits-units(config_.feederRecipeOutputs)) return no("Collect bricks to make room for the complete output.");
    Inventory available=s.input;
    for (const auto& item : config_.feederRecipeInputs) {
        const auto held=available.find(item.first);
        if (held==available.end() || held->second<item.second) return no("Load all clay for one complete firing.");
        reduce(available,item.first,item.second);
    }
    Inventory fuel;
    State* buffer=nullptr;
    if (!s.heatKey.empty()) {
        buffer=mutableState(s.heatKey);
        if (!buffer || buffer->kind!="red_heat_buffer" || buffer->link!=s.key || buffer->heat<1) return no("Charge the attached Red buffer; stored drive supplies motion, not heat.");
    } else if (!selectFuel(available,config_,fuel)) return no("Load ordinary forge fuel; pressure supplies motion, not heat.");
    for (const auto& item : fuel) reduce(available,item.first,item.second);
    s.input.swap(available); s.escrowInputs=config_.feederRecipeInputs; s.escrowFuel=std::move(fuel);
    if (buffer) { --buffer->heat; s.escrowHeat=1; }
    --s.energy; s.escrowDrive=1; s.cycleSeconds=0;
    return yes("Reserved one firing's exact clay, heat, drive and output space.");
}
Result MachineWorld::attachFeeder(const std::string& key, const std::string& sourceId,
                                const std::string& forgeKey, const std::array<double,3>& forgePosition, bool ready) {
    auto* s=mutableState(key);
    if (!s || s->kind!="pressure_feeder") return no("No pressure feeder is placed here.");
    if (s->escrowDrive || s->queuedCycles) return no("Finish or cancel the reserved cycle before changing attachments.");
    if (!ready || !identifier(forgeKey)) return no("Choose a supported, unobstructed player-built basic forge.");
    for (double value : forgePosition) if (!std::isfinite(value) || std::abs(value)>config_.maximumCoordinate) return no("Invalid forge position.");
    if (distance(s->position,forgePosition)>config_.feederAttachmentRange) return no("Build the basic forge within the feeder's local reach.");
    if (!sourceId.empty()) {
        const auto* source=sourceDefinition(sourceId);
        if (!source || distance(s->position,source->position)>config_.feederAttachmentRange) return no("Choose this world's pressure pocket within local reach.");
    }
    s->sourceId=sourceId; s->forgeKey=forgeKey; s->forgePosition=forgePosition;
    return yes(sourceId.empty() ? "Forge attached. Hand winding supplies each stroke." : "Forge and finite pressure pocket attached.");
}
Result MachineWorld::charge(const std::string& key, int count, bool ready) {
    auto* s=mutableState(key);
    if (!s || s->kind!="pressure_feeder" || count<=0) return no("Choose a positive pressure transfer at a placed feeder.");
    if (!ready || s->forgeKey.empty()) return no("The attached source and player-built forge must be supported and clear.");
    const auto* source=sourceDefinition(s->sourceId);
    if (!source || distance(s->position,source->position)>config_.feederAttachmentRange) return no("Attach this world's nearby pressure pocket first.");
    auto stock=sources_.find(s->sourceId);
    if (stock==sources_.end()) return no("This world has no such pressure stock.");
    const int moved=std::min({count,stock->second,config_.energyCapacity-s->energy-s->escrowDrive});
    if (moved<=0) return no(stock->second==0 ? "The pocket is exhausted. Hand winding still works." : "The feeder's four-stroke store is full, including its reserved stroke.");
    stock->second-=moved; s->energy+=moved;
    return yes("Transferred finite pressure into the feeder once.",moved);
}
Result MachineWorld::cancel(const std::string& key) {
    auto* s=mutableState(key);
    if (s && s->kind=="blue_delay") {
        if (!s->pendingRequest) return no("Blue has no pending request.");
        s->pendingRequest=false; s->delayPaused=false; s->delaySeconds=0;
        return yes("Cancelled the held request. No receiver work was spent.");
    }
    if (!s || s->kind!="pressure_feeder" || !s->escrowDrive) return no("The feeder has no reserved cycle to cancel.");
    Inventory returned=s->input;
    if (!addSafe(returned,s->escrowInputs) || !addSafe(returned,s->escrowFuel) || units(returned)>config_.feederInputUnits ||
        s->energy+s->escrowDrive>config_.energyCapacity) return no("Reserved contents cannot be returned safely.");
    if (s->escrowHeat) {
        auto* buffer=mutableState(s->heatKey);
        if (!buffer || buffer->heat>config_.heatCapacity-s->escrowHeat) return no("Reserved heat cannot return to its owner.");
        buffer->heat+=s->escrowHeat;
    }
    s->input.swap(returned); s->energy+=s->escrowDrive; s->escrowHeat=0;
    s->escrowInputs.clear(); s->escrowFuel.clear(); s->escrowDrive=0; s->queuedCycles=0; s->cycleSeconds=0; s->feederPaused=false;
    return yes("Cancelled. Reserved clay, exact thermal payment and drive returned once; completed bricks remain bricks.");
}
Result MachineWorld::pause(const std::string& key, bool paused) {
    auto* s=mutableState(key);
    if (s && s->kind=="blue_delay") {
        if (!s->pendingRequest || s->delayPaused==paused) return no("No change to the held request.");
        s->delayPaused=paused;
        return yes(paused ? "Blue paused with its exact remaining delay." : "Blue resumed its same request.");
    }
    if (!s || s->kind!="pressure_feeder" || !s->escrowDrive) return no("The feeder has no reserved cycle to pause or resume.");
    if (s->feederPaused==paused) return no(paused ? "The feeder is already paused." : "The feeder is already running.");
    s->feederPaused=paused;
    return yes(paused ? "Paused with the exact firing held safely." : "Resumed the same reserved firing; no extra materials were taken.");
}

FeederInspection MachineWorld::inspectFeeder(const std::string& key, bool physicalReady,
                                            const Inventory& pack) const {
    FeederInspection inspection;
    const auto* s=state(key);
    inspection.available=s && s->kind=="pressure_feeder";
    if (!inspection.available) inspection.message="No pressure feeder is placed here.";
    for (const auto* action : {"start","charge","wind","pause","resume","cancel"}) {
        Result result=no(inspection.message);
        if (inspection.available) {
            // Each action sees the same original ledger. A successful charge
            // preview must not make the start or winding preview look ready.
            MachineWorld copy(*this);
            const std::string id(action);
            if (id=="start") result=copy.start(key,physicalReady);
            else if (id=="charge") result=copy.charge(key,config_.energyCapacity,physicalReady);
            else if (id=="wind") result=copy.wind(key);
            else if (id=="pause" || id=="resume") result=copy.pause(key,id=="pause");
            else if (id=="cancel") result=copy.cancel(key);
        }
        inspection.actions.emplace(action,std::move(result));
    }
    if (!inspection.available) return inspection;
    for (const auto& held : pack) {
        if (held.second<=0 || !feederItem(held.first)) continue;
        const auto ingredient=config_.feederRecipeInputs.find(held.first);
        int perCycle=0;
        if (ingredient!=config_.feederRecipeInputs.end()) perCycle=ingredient->second;
        else {
            const int heat=config_.feederFuels.at(held.first);
            perCycle=std::max(1,(config_.feederFuelCost+heat-1)/heat);
        }
        const int requested=static_cast<int>(std::min<long long>(held.second,static_cast<long long>(perCycle)*config_.feederBatchCycles));
        MachineWorld copy(*this);
        auto carried=pack;
        inspection.loads.push_back({held.first,requested,copy.deposit(key,held.first,requested,carried)});
    }
    return inspection;
}

std::string MachineWorld::serialize() const {
    std::ostringstream out;
    out << std::setprecision(std::numeric_limits<double>::max_digits10);
    bool scoped=!identity_.profile.empty();
    for (const auto& entry : states_) if (entry.second.kind=="pressure_feeder") scoped=true;
    const bool experimental=identity_.profile=="living_frontier_wave1";
    out << "{\"schema\":" << (experimental ? saveSchema : scoped ? 2 : 1);
    if (scoped) {
        out << ",\"world_profile\":" << quoted(identity_.profile) << ",\"world_seed\":" << quoted(std::to_string(identity_.seed)) << ",\"sources\":";
        writeInventory(out,sources_);
    }
    out << ",\"machines\":[";
    bool first = true;
    for (const auto& entry : states_) {
        const State& s = entry.second;
        if (!first) out << ',';
        first = false;
        out << "{\"key\":" << quoted(s.key) << ",\"kind\":" << quoted(s.kind)
            << ",\"position\":[" << s.position[0] << ',' << s.position[1] << ',' << s.position[2] << ']'
            << ",\"quarter_turns\":" << s.quarterTurns << ",\"link\":" << quoted(s.link)
            << ",\"span_length\":" << s.spanLength << ",\"energy\":" << s.energy
            << ",\"lamp_on\":" << (s.lampOn ? "true" : "false")
            << ",\"moving\":" << (s.moving ? "true" : "false")
            << ",\"at_landing\":" << (s.atLanding ? "true" : "false")
            << ",\"progress\":" << s.progress << ",\"completed_trips\":" << s.completedTrips
            << ",\"pulses\":" << s.pulses << ",\"cargo\":";
        writeInventory(out, s.cargo); out << ",\"input\":"; writeInventory(out, s.input);
        out << ",\"ferrous\":"; writeInventory(out, s.ferrous); out << ",\"remainder\":";
        writeInventory(out, s.remainder);
        if (scoped) {
            out << ",\"source_id\":" << quoted(s.sourceId) << ",\"forge_key\":" << quoted(s.forgeKey)
                << ",\"forge_position\":[" << s.forgePosition[0] << ',' << s.forgePosition[1] << ',' << s.forgePosition[2] << ']'
                << ",\"escrow_drive\":" << s.escrowDrive << ",\"queued_cycles\":" << s.queuedCycles
                << ",\"completed_cycles\":" << s.completedCycles << ",\"cycle_seconds\":" << s.cycleSeconds
                << ",\"feeder_paused\":" << (s.feederPaused ? "true" : "false") << ",\"output\":";
            writeInventory(out,s.output); out << ",\"escrow_inputs\":"; writeInventory(out,s.escrowInputs);
            out << ",\"escrow_fuel\":"; writeInventory(out,s.escrowFuel);
        }
        if (experimental) out << ",\"pending_request\":" << (s.pendingRequest ? "true" : "false")
            << ",\"delay_paused\":" << (s.delayPaused ? "true" : "false") << ",\"delay_seconds\":" << s.delaySeconds
            << ",\"second_link\":" << quoted(s.secondLink) << ",\"second_span_length\":" << s.secondSpanLength
            << ",\"heat\":" << s.heat << ",\"heat_key\":" << quoted(s.heatKey) << ",\"escrow_heat\":" << s.escrowHeat;
        out << '}';
    }
    out << "]}";
    return out.str();
}

std::map<std::string, State> MachineWorld::parse(const std::string& source, std::map<std::string,int>* stocks) const {
    const auto document = json::parse(source);
    const int schema=integer(document->get("schema"),1,saveSchema);
    if (schema>=3 && identity_.profile!="living_frontier_wave1") throw std::runtime_error("contraptions: experimental schema outside its world");
    std::map<std::string,int> restoredStocks;
    if (schema==1) {
        if (identity_.profile=="frontier_v5" || identity_.profile=="frontier_v6" || !identity_.sources.empty()) throw std::runtime_error("contraptions: source world requires its complete pressure ledger");
        if (document->find("sources") || document->find("world_profile") || document->find("world_seed")) throw std::runtime_error("contraptions: unscoped save cannot contain source identity");
    } else {
        if (document->get("world_profile").asString()!=identity_.profile || document->get("world_seed").asString()!=std::to_string(identity_.seed))
            throw std::runtime_error("contraptions: pressure ledger belongs to a different world");
        const auto& savedSources=document->get("sources").asObject();
        if (savedSources.size()!=identity_.sources.size()) throw std::runtime_error("contraptions: incomplete native pressure source ledger");
        for (const auto& sourceDefinition : identity_.sources) {
            const auto found=savedSources.find(sourceDefinition.id);
            if (found==savedSources.end()) throw std::runtime_error("contraptions: missing native pressure source");
            restoredStocks.emplace(sourceDefinition.id,integer(*found->second,0,sourceDefinition.capacity));
        }
    }
    const auto& machines = document->get("machines").asArray();
    if (machines.size() > static_cast<size_t>(config_.maximumMachines)) throw std::runtime_error("contraptions: too many machines");
    std::map<std::string, State> result;
    auto readInventory = [&](const json::Value& object, int cap) {
        Inventory inventory;
        long long total = 0;
        for (const auto& entry : object.asObject()) {
            if (!itemAllowed(entry.first)) throw std::runtime_error("contraptions: unknown cargo ingredient");
            const int count = integer(*entry.second, 1, cap);
            total += count;
            if (total > cap) throw std::runtime_error("contraptions: container capacity exceeded");
            inventory.emplace(entry.first, count);
        }
        return inventory;
    };
    for (const auto& record : machines) {
        State s;
        s.key = record->get("key").asString(); s.kind = record->get("kind").asString();
        if (!identifier(s.key) || !knownKind(s.kind)) throw std::runtime_error("contraptions: invalid fixture identity");
        const auto& position = record->get("position").asArray();
        if (position.size() != 3) throw std::runtime_error("contraptions: invalid position");
        for (int i = 0; i < 3; ++i) s.position[i] = finite(*position[i], -config_.maximumCoordinate, config_.maximumCoordinate);
        s.quarterTurns = integer(record->get("quarter_turns"), 0, 3);
        s.link = record->get("link").asString();
        s.spanLength = finite(record->get("span_length"), 0, std::max(config_.maximumSpan, config_.signalRange));
        s.energy = integer(record->get("energy"), 0, config_.energyCapacity);
        s.lampOn = record->get("lamp_on").asBool();
        s.moving = record->get("moving").asBool(); s.atLanding = record->get("at_landing").asBool();
        s.progress = finite(record->get("progress"), 0, 1);
        s.completedTrips = integer(record->get("completed_trips"), 0, std::numeric_limits<int>::max());
        s.pulses = integer(record->get("pulses"), 0, std::numeric_limits<int>::max());
        s.cargo = readInventory(record->get("cargo"), config_.cargoUnits);
        s.input = readInventory(record->get("input"), s.kind=="pressure_feeder" ? config_.feederInputUnits : config_.sorterInputUnits);
        s.ferrous = readInventory(record->get("ferrous"), config_.sorterTrayUnits);
        s.remainder = readInventory(record->get("remainder"), config_.sorterTrayUnits);
        if (s.kind != "cargo_winch" && (!s.cargo.empty() || s.moving || s.atLanding || s.progress != 0 || s.completedTrips != 0))
            throw std::runtime_error("contraptions: cargo belongs only to its drum");
        if (s.kind != "magnetic_sorter" && ((!s.input.empty() && s.kind!="pressure_feeder") || !s.ferrous.empty() || !s.remainder.empty()))
            throw std::runtime_error("contraptions: trays belong only to a sorter");
        for (const auto& item : s.ferrous) if (!config_.ferrousItems.count(item.first)) throw std::runtime_error("contraptions: nonferrous magnetic output");
        for (const auto& item : s.remainder) if (config_.ferrousItems.count(item.first)) throw std::runtime_error("contraptions: ferrous ordinary output");
        if (s.kind != "cargo_winch" && s.kind != "ventlung_bellows" && s.kind!="pressure_feeder" && s.energy != 0) throw std::runtime_error("contraptions: invalid stored energy");
        if (s.kind != "stormglass_lever" && s.kind != "white_connection" && s.kind != "blue_delay" && s.kind != "green_junction" && s.pulses != 0) throw std::runtime_error("contraptions: invalid signal counter");
        if ((s.kind == "white_connection" || s.kind == "blue_delay" || s.kind == "green_junction" || s.kind=="red_heat_buffer") && identity_.profile != "living_frontier_wave1") throw std::runtime_error("contraptions: coloured component outside its experiment");
        if (schema>=5) {
            s.heat=integer(record->get("heat"),0,config_.heatCapacity);
            s.heatKey=record->get("heat_key").asString();
            s.escrowHeat=integer(record->get("escrow_heat"),0,1);
        } else if (s.kind=="red_heat_buffer" || record->find("heat") || record->find("heat_key") || record->find("escrow_heat")) throw std::runtime_error("contraptions: thermal state needs its complete schema");
        if ((s.kind!="red_heat_buffer" && s.heat) || (s.kind!="pressure_feeder" && (!s.heatKey.empty() || s.escrowHeat))) throw std::runtime_error("contraptions: thermal stock has the wrong owner");
        if (schema>=4) {
            s.secondLink=record->get("second_link").asString();
            s.secondSpanLength=finite(record->get("second_span_length"),0,config_.signalRange);
        } else if (s.kind=="green_junction" || record->find("second_link") || record->find("second_span_length")) throw std::runtime_error("contraptions: Green needs its complete port schema");
        if (s.kind!="green_junction" && (!s.secondLink.empty() || s.secondSpanLength!=0)) throw std::runtime_error("contraptions: only Green has a second signal port");
        if (schema>=3) {
            s.pendingRequest=record->get("pending_request").asBool();
            s.delayPaused=record->get("delay_paused").asBool();
            s.delaySeconds=finite(record->get("delay_seconds"),0,config_.delaySeconds);
        } else if (s.kind=="blue_delay" || record->find("pending_request") || record->find("delay_paused") || record->find("delay_seconds")) throw std::runtime_error("contraptions: Blue needs its complete delay schema");
        if ((s.kind!="blue_delay" && s.pendingRequest) || (!s.pendingRequest && (s.delayPaused || s.delaySeconds!=0)) ||
            (s.pendingRequest && (s.link.empty() || s.delaySeconds>=config_.delaySeconds))) throw std::runtime_error("contraptions: invalid held request");
        if (!s.moving && s.progress != 0) throw std::runtime_error("contraptions: stationary basket has progress");
        if (s.moving && (s.progress >= 1 || s.completedTrips == std::numeric_limits<int>::max())) throw std::runtime_error("contraptions: invalid travelling basket");
        if (schema>=2) {
            s.sourceId=record->get("source_id").asString(); s.forgeKey=record->get("forge_key").asString();
            const auto& forgePosition=record->get("forge_position").asArray();
            if (forgePosition.size()!=3) throw std::runtime_error("contraptions: invalid forge position");
            for (int i=0;i<3;++i) s.forgePosition[i]=finite(*forgePosition[i],-config_.maximumCoordinate,config_.maximumCoordinate);
            s.escrowDrive=integer(record->get("escrow_drive"),0,1);
            s.queuedCycles=integer(record->get("queued_cycles"),0,config_.feederBatchCycles);
            s.completedCycles=integer(record->get("completed_cycles"),0,std::numeric_limits<int>::max());
            s.cycleSeconds=finite(record->get("cycle_seconds"),0,config_.feederCycleSeconds);
            s.feederPaused=record->get("feeder_paused").asBool();
            s.output=readInventory(record->get("output"),config_.feederOutputUnits);
            s.escrowInputs=readInventory(record->get("escrow_inputs"),config_.feederInputUnits);
            s.escrowFuel=readInventory(record->get("escrow_fuel"),config_.feederInputUnits);
        } else if (s.kind=="pressure_feeder" || record->find("escrow_drive") || record->find("source_id")) {
            throw std::runtime_error("contraptions: feeder needs the complete transaction schema");
        }
        if (s.kind=="pressure_feeder") {
            if (!feederRecipeReady()) throw std::runtime_error("contraptions: feeder recipe unavailable");
            for (const auto& item : s.input) if (!feederItem(item.first)) throw std::runtime_error("contraptions: hopper item is not clay or allowed fuel");
            for (const auto& item : s.output) if (!config_.feederRecipeOutputs.count(item.first)) throw std::runtime_error("contraptions: unknown recipe output");
            if (s.forgeKey.empty()) {
                if (s.escrowDrive || !s.sourceId.empty() || s.forgePosition!=std::array<double,3>{0,0,0}) throw std::runtime_error("contraptions: unattached feeder owns a forge transaction");
            } else if (!identifier(s.forgeKey) || distance(s.position,s.forgePosition)>config_.feederAttachmentRange) throw std::runtime_error("contraptions: invalid or distant forge attachment");
            if (!s.sourceId.empty()) {
                const auto* definition=sourceDefinition(s.sourceId);
                if (!definition || distance(s.position,definition->position)>config_.feederAttachmentRange) throw std::runtime_error("contraptions: invalid or distant pressure source attachment");
            }
            if (s.energy+s.escrowDrive>config_.energyCapacity || units(s.input)+units(s.escrowInputs)+units(s.escrowFuel)>config_.feederInputUnits)
                throw std::runtime_error("contraptions: escrow no longer owns its return capacity");
            if (s.escrowDrive) {
                Inventory exactFuel;
                if (s.queuedCycles==0 || s.cycleSeconds>=config_.feederCycleSeconds || s.completedCycles==std::numeric_limits<int>::max() ||
                    s.escrowInputs!=config_.feederRecipeInputs ||
                    (s.heatKey.empty() ? s.escrowHeat!=0 || !selectFuel(s.escrowFuel,config_,exactFuel) || exactFuel!=s.escrowFuel : s.escrowHeat!=1 || !s.escrowFuel.empty()) ||
                    units(s.output)>config_.feederOutputUnits-units(config_.feederRecipeOutputs)) throw std::runtime_error("contraptions: invalid reserved firing");
            } else if (s.escrowHeat || s.queuedCycles || s.cycleSeconds!=0 || s.feederPaused || !s.escrowInputs.empty() || !s.escrowFuel.empty()) throw std::runtime_error("contraptions: idle feeder owns orphaned escrow");
        } else if (!s.sourceId.empty() || !s.forgeKey.empty() || s.forgePosition!=std::array<double,3>{0,0,0} ||
                   !s.output.empty() || !s.escrowInputs.empty() || !s.escrowFuel.empty() || s.escrowDrive || s.queuedCycles || s.completedCycles || s.cycleSeconds!=0 || s.feederPaused) {
            throw std::runtime_error("contraptions: recipe escrow belongs only to its feeder");
        }
        if (!result.emplace(s.key, std::move(s)).second) throw std::runtime_error("contraptions: duplicate fixture key");
    }
    std::set<std::string> usedLandings;
    for (const auto& entry : result) {
        const State& s = entry.second;
        if (!s.heatKey.empty()) {
            const auto found=result.find(s.heatKey);
            if (found==result.end() || found->second.kind!="red_heat_buffer" || found->second.link!=s.key ||
                found->second.heat+s.escrowHeat>config_.heatCapacity) throw std::runtime_error("contraptions: invalid thermal owner or return capacity");
        }
        if (s.secondLink.empty()) {
            if (s.secondSpanLength!=0) throw std::runtime_error("contraptions: disconnected second port has a span");
        } else {
            const auto t=result.find(s.secondLink);
            if (s.kind!="green_junction" || s.secondLink==s.link || t==result.end() ||
                (t->second.kind!="cargo_winch" && t->second.kind!="pressure_feeder") || distance(s,t->second)>config_.signalRange ||
                std::abs(distance(s,t->second)-s.secondSpanLength)>.000001) throw std::runtime_error("contraptions: invalid or duplicate second receiver");
        }
        if (s.link.empty()) {
            if (s.spanLength != 0 || s.moving || s.atLanding) throw std::runtime_error("contraptions: unlinked active basket");
            continue;
        }
        auto target = result.find(s.link);
        if (target == result.end() || target->first == s.key) throw std::runtime_error("contraptions: dangling fixture link");
        const State& t = target->second;
        const double length = distance(s, t);
        if (std::abs(length - s.spanLength) > 0.000001) throw std::runtime_error("contraptions: link span disagrees with placed endpoints");
        if (s.kind == "cargo_winch") {
            if (t.kind != "winch_landing" || length <= 0 || length > config_.maximumSpan || !usedLandings.insert(t.key).second)
                throw std::runtime_error("contraptions: invalid or shared landing");
        } else if (s.kind == "stormglass_lever") {
            if ((t.kind != "cargo_winch" && t.kind != "lantern_lamp" && t.kind!="pressure_feeder" && t.kind!="white_connection" && t.kind!="blue_delay" && t.kind!="green_junction") || length > config_.signalRange)
                throw std::runtime_error("contraptions: invalid signal receiver");
        } else if (s.kind == "white_connection") {
            if ((t.kind != "cargo_winch" && t.kind!="pressure_feeder" && t.kind!="blue_delay" && t.kind!="green_junction") || length > config_.signalRange) throw std::runtime_error("contraptions: invalid White receiver");
        } else if (s.kind == "blue_delay") {
            if ((t.kind != "cargo_winch" && t.kind!="pressure_feeder" && t.kind!="green_junction") || length > config_.signalRange) throw std::runtime_error("contraptions: invalid Blue receiver");
        } else if (s.kind == "red_heat_buffer") {
            if (t.kind!="pressure_feeder" || t.heatKey!=s.key || length>config_.feederAttachmentRange) throw std::runtime_error("contraptions: invalid thermal connection");
        } else if (s.kind == "green_junction") {
            if ((t.kind!="cargo_winch" && t.kind!="pressure_feeder") || length>config_.signalRange || s.link==s.secondLink) throw std::runtime_error("contraptions: invalid or duplicate Green receiver");
        } else throw std::runtime_error("contraptions: this fixture cannot send links");
    }
    if (stocks) stocks->swap(restoredStocks);
    return result;
}
bool MachineWorld::validate(const std::string& source, std::string* reason) const {
    try { (void)parse(source); if (reason) reason->clear(); return true; }
    catch (const std::exception& error) { if (reason) *reason = error.what(); return false; }
}
bool MachineWorld::restore(const std::string& source, std::string* reason) {
    try { std::map<std::string,int> stock; auto restored = parse(source,&stock); states_.swap(restored); sources_.swap(stock); if (reason) reason->clear(); return true; }
    catch (const std::exception& error) { if (reason) *reason = error.what(); return false; }
}

} // namespace wroughtwild::contraptions
