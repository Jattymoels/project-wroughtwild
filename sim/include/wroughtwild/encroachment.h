#pragma once

// Encroachment (Wave 4, D-018's base-threat half): the world pushes back at
// the edge of what the player claims, without ever touching a wall. Once
// the player has a home (a shelter they have rested in), packs settle into
// NESTS on the fringe of it. A nest is a nuisance, not a siege: its pack
// respawns while it stands, it grows a tier at a time, and within its
// blight rest in the shelter is uneasy. Nest-born kills drop only a
// fraction of normal loot and tearing a nest down drops nothing, so a nest
// is worth clearing to end the nuisance and never worth farming - waiting
// only makes the neighbourhood worse. A cleared nest leaves a scar where
// nothing settles for a while.
//
// The sim owns the rules (when, where, how big, what drops); the engine
// owns the clock it feeds in, the nodes it raises and the fights.

#include <cstdint>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::encroachment {

struct Nest {
    int id = 0;
    double x = 0.0, z = 0.0; // world metres
    int tier = 1;            // 1-based index into the tuning's pack tiers
    double bornAt = 0.0;
    double lastGrowthAt = 0.0;
};

struct Scar {
    double x = 0.0, z = 0.0;
    double until = 0.0;
};

class Encroachment {
public:
    Encroachment(const tuning::EncroachmentDef& def, uint64_t seed);

    // Advances the rules to `now` (seconds of world time). `hasHome` and
    // the home position come from the engine (the last shelter rested in).
    // Returns the nests born by this call, for the engine to raise.
    std::vector<Nest> tick(double now, bool hasHome, double homeX, double homeZ);

    const std::vector<Nest>& nests() const { return nests_; }
    const Nest* find(int id) const;
    // The enemy ids a nest of this tier fields (its pack).
    const std::vector<std::string>& packFor(int tier) const;
    // Shelter regen multiplier at a position: 1 clear, uneasy in a blight.
    double restMultiplierAt(double x, double z) const;
    // Tears a nest down: gone, and a scar keeps the spot quiet a while.
    bool clear(int id, double now);
    // Whether a nest-born kill drops loot at all (a fraction do).
    bool killDrops(uint64_t killSeed) const;
    // Highest tier standing, 0 with no nests - the pressure gauge.
    int pressure() const;

private:
    bool spotFree(double x, double z, double now) const;
    uint64_t hash(uint64_t salt) const;

    const tuning::EncroachmentDef& def_;
    uint64_t seed_;
    std::vector<Nest> nests_;
    std::vector<Scar> scars_;
    int nextId_ = 1;
    double lastSettleAt_ = 0.0;
    bool started_ = false;
};

} // namespace wroughtwild::encroachment
