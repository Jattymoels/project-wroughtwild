#pragma once

// The Strange Frontier's small local fixtures. Signals request a cycle; hand
// winding supplies energy. No unloaded-time production, world inventory scan,
// item physics or general production graph belongs here. The bounded feeder
// reserves one existing decorative recipe at a time, without economy mastery.
#include <cstdint>
#include <vector>
#include <array>
#include <map>
#include <set>
#include <string>
#include "wroughtwild/economy.h"

namespace wroughtwild::contraptions {

struct Config {
    int maximumMachines = 128;
    int cargoUnits = 96;
    int sorterInputUnits = 64;
    int sorterTrayUnits = 64;
    int sorterBatchUnits = 16;
    int energyCapacity = 4;
    int windingEnergy = 1;
    int tripEnergy = 1;
    int bellowsEnergy = 1;
    double maximumSpan = 32;
    double signalRange = 24;
    double bellowsRange = 3;
    double cargoMetresPerSecond = 3;
    double minimumTripSeconds = 0.5;
    double maximumCoordinate = 1024;
    int pressureSourceStrokes = 24;
    int feederInputUnits = 64;
    int feederOutputUnits = 32;
    int feederBatchCycles = 4;
    double feederCycleSeconds = 8;
    double feederAttachmentRange = 8;
    // Host copies the approved existing recipe and fuel table from Tuning.
    economy::Inventory feederRecipeInputs, feederRecipeOutputs, feederFuels;
    int feederFuelCost = 0;
    std::set<std::string> ferrousItems;
    // The host fills this with ordinary inventory IDs from its item tables.
    // Empty supports small standalone rules fixtures; production sets it.
    std::set<std::string> allowedItems;
    static Config load(const std::string& path);
};

struct PressureSource {
    std::string id;
    std::array<double, 3> position = {0, 0, 0};
    int capacity = 24;
};
struct WorldIdentity {
    std::string profile;
    std::uint64_t seed = 0;
    std::vector<PressureSource> sources;
};

struct State {
    std::string key, kind;
    std::array<double, 3> position = {0, 0, 0};
    int quarterTurns = 0;
    std::string link;
    double spanLength = 0;
    int energy = 0;
    bool lampOn = true;
    bool moving = false;
    bool atLanding = false;
    double progress = 0;
    int completedTrips = 0;
    int pulses = 0;
    // A travelling basket has ONE owner, its winch. A landing has no copy.
    economy::Inventory cargo, input, ferrous, remainder;
    std::string sourceId, forgeKey;
    std::array<double, 3> forgePosition = {0, 0, 0};
    economy::Inventory output, escrowInputs, escrowFuel;
    int escrowDrive = 0, queuedCycles = 0, completedCycles = 0;
    double cycleSeconds = 0;
    bool feederPaused = false;
};

struct Result {
    bool ok = false;
    int moved = 0;
    std::string message;
};

struct FeederLoadPreview {
    std::string item;
    int requested = 0;
    Result result;
};
struct FeederInspection {
    bool available = false;
    std::string message;
    std::map<std::string, Result> actions;
    std::vector<FeederLoadPreview> loads;
};

class MachineWorld {
public:
    explicit MachineWorld(Config config, WorldIdentity identity = {});
    const Config& config() const { return config_; }
    const WorldIdentity& identity() const { return identity_; }
    const std::map<std::string, int>& sources() const { return sources_; }
    int sourceRemaining(const std::string& id) const;
    const std::map<std::string, State>& states() const { return states_; }
    const State* state(const std::string& key) const;
    static bool knownKind(const std::string& kind);
    Result create(const std::string& key, const std::string& kind,
                  const std::array<double, 3>& position = {0, 0, 0}, int quarterTurns = 0);
    // Host refunds recipe cores and frames only after success. Contents return
    // intact even when the ordinary gathering cap is lower; demolition cannot
    // destroy cargo. Erasing a landing recalls its basket, including mid-trip.
    Result erase(const std::string& key, economy::Inventory& pack);
    // Host certifies unobstructed supported endpoints; native verifies actual
    // saved positions, distance and allowed one-hop topology as well.
    Result link(const std::string& source, const std::string& target, bool clear);
    Result wind(const std::string& key);
    Result start(const std::string& key, bool clear);
    Result advance(const std::string& key, double seconds, bool clear);
    Result pulse(const std::string& key, bool signalClear, bool spanClear);
    Result toggleLamp(const std::string& key);
    Result prime(const std::string& key);
    // Caller first validates a nearby ResourceNode with a current impact
    // response, then applies that existing response exactly once on success.
    Result releaseBellows(const std::string& key, bool compatibleTarget, double distance);
    // port: cargo (winch/landing), input/ferrous/remainder (sorter),
    // input/output (feeder). Escrow never exposes an extra inventory port.
    Result deposit(const std::string& key, const std::string& item, int count,
                   economy::Inventory& pack);
    Result withdraw(const std::string& key, const std::string& port,
                    const std::string& item, int count, int packRoom,
                    economy::Inventory& pack);
    Result sort(const std::string& key);
    // Source may be empty for hand-powered operation in an older world. The
    // host certifies a live player-built basic forge, support and clear space.
    Result attachFeeder(const std::string& key, const std::string& sourceId,
                        const std::string& forgeKey, const std::array<double, 3>& forgePosition,
                        bool ready);
    Result charge(const std::string& key, int count, bool ready);
    Result cancel(const std::string& key);
    Result pause(const std::string& key, bool paused);
    // Preview the existing actions on independent bounded copies. Inspection
    // neither reserves work nor changes source stock, inventory or saved state.
    FeederInspection inspectFeeder(const std::string& key, bool physicalReady,
                                  const economy::Inventory& pack) const;
    std::string serialize() const;
    bool validate(const std::string& source, std::string* reason = nullptr) const;
    // Parses/validates everything into a temporary world before swapping.
    bool restore(const std::string& source, std::string* reason = nullptr);

private:
    Config config_;
    WorldIdentity identity_;
    std::map<std::string, int> sources_;
    std::map<std::string, State> states_;
    State* mutableState(const std::string& key);
    State* cargoOwner(const std::string& key);
    bool itemAllowed(const std::string& item) const;
    const PressureSource* sourceDefinition(const std::string& id) const;
    bool feederItem(const std::string& item) const;
    bool feederRecipeReady() const;
    Result reserveFeeder(State& state);
    std::map<std::string, State> parse(const std::string& source, std::map<std::string,int>* stocks = nullptr) const;
};

} // namespace wroughtwild::contraptions
