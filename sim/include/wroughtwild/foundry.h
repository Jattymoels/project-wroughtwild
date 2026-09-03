#pragma once

// The Foundry (Wave 5, D-019, docs/systems/progression-eras.md): the point
// system as a made thing. Points are INGOTS - each one verb, a modifier at
// a flat value - placed on a PLATE whose size the era forges. Power is
// arrangement: orthogonally adjacent ingots that match a pair add that
// pair's mechanic; a straight line of matching ingots adds the ingot's
// verb again (the set effect). Numbers on ingots never change; what
// scales is count, arrangement and, later, reach.
//
// Ingots come from milestones (foundry.json sources), never from kills as
// such, and each source grants once. Re-forging (lifting an ingot off the
// plate) costs a little metal. The economy owns the state; this header is
// the pure rules over it.

#include <map>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::foundry {

struct Placement {
    int row = 0, col = 0;
    std::string ingot;
};

struct State {
    std::map<std::string, int> owned;   // ingot id -> total owned (placed and not)
    std::vector<Placement> plate;
    std::vector<std::string> milestones; // source ids already granted
};

struct PlateSize {
    int rows = 3, cols = 3;
};

// One thing the plate is doing right now, for the rules and the panel.
struct Effect {
    std::string kind;     // ingot | pair | line
    std::string label;    // Ember Ingot / Wildfire / Ember line
    std::string modifier; // items.json modifier id
    double value = 0.0;
    int row = -1, col = -1; // the placement (ingot) or the first cell (pair, line)
};

// The plate the era forges (plate_by_era; the last entry serves later eras).
PlateSize plateSize(const tuning::FoundryDef& def, int era);

const Placement* at(const State& state, int row, int col);
int placedCount(const State& state, const std::string& ingot);
int unplacedCount(const State& state, const std::string& ingot);

// Ingots, pairs and lines in force on the plate, in that order.
std::vector<Effect> effects(const tuning::FoundryDef& def, const State& state, PlateSize size);

} // namespace wroughtwild::foundry
