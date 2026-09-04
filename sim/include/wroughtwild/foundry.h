#pragma once

// The Foundry (Wave 5, D-019, docs/systems/progression-eras.md; D-023,
// docs/systems/foundry.md): the point system as a made thing. Points are
// INGOTS - each one verb, a modifier at a flat value - placed on a PLATE.
// The plate is a FRAME whose rows the eras forge, with SOCKETS that take a
// subject (a skill tablet). A socket with the ingots orthogonally beside
// it (its SUPPORTS) is a WORKING: a support reads the socket's skill, and
// the skill decides the reading - an element ingot scales a skill of its
// own element and ADDS its element to any other skill's hit; the self
// ingots read a skill weakly (D-023 slice 2: nothing on the plate is
// inert). A matching ingot touching a support from any side but the
// socket's BACKS it, so the support counts once more. Orthogonally
// adjacent ingots that match a pair add that pair's mechanic for everyone.
// Numbers on ingots never change; what scales is count, arrangement and,
// later, reach.
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
    std::string ingot; // an ingot placement ("" for a tablet or a kind)
    std::string skill; // a skill tablet (D-022): the skill laid on this cell
    std::string currency{}; // a currency kind (D-023 slice 4): a subject in a socket, an augment elsewhere
    bool isTablet() const { return !skill.empty(); }
    bool isIngot() const { return !ingot.empty(); }
    bool isCurrency() const { return !currency.empty(); }
};

struct State {
    std::map<std::string, int> owned;   // ingot id -> total owned (placed and not)
    std::vector<Placement> plate;
    std::vector<std::string> milestones; // source ids already granted
};

struct Cell {
    int row = 0, col = 0;
};

// The plate as the era has forged it (D-023): the frame, the rows the era
// has unlocked, and the sockets that take a subject.
struct Plate {
    int rows = 4, cols = 4;        // the frame
    int firstRow = 0, lastRow = 3; // the forged rows, inclusive
    std::vector<Cell> sockets;

    bool inFrame(int row, int col) const;
    bool forged(int row, int col) const; // inside the frame and in a forged row
    bool isSocket(int row, int col) const;
    int forgedRows() const { return lastRow - firstRow + 1; }
};

// One thing the plate is doing right now, for the rules and the panel.
struct Effect {
    std::string kind;     // ingot | pair | support | added | backing | subject | augment | lending
    std::string label;    // Ember Ingot / Wildfire / Frost Orb <- Frost Ingot / Frost Ingot backing Frost Orb
    std::string modifier; // items.json modifier id
    double value = 0.0;
    int row = -1, col = -1; // the placement (ingot), the first cell (pair) or the socket (support, backing)
    std::string skill;    // support, added, backing of a skill working: the one skill it applies to
    int cellRow = -1, cellCol = -1; // the ingot cell the effect comes from
    std::string subject{}; // subject, augment, lending, and a Vanguard working's support and backing: the kind
};

// The plate the era has forged (rows_by_era; the last entry serves later eras).
Plate plate(const tuning::FoundryDef& def, int era);

// Lifts every placement the plate cannot hold - an unforged row, a tablet
// outside a socket, an ingot inside one, a second thing on a cell, a
// second tablet for a skill - and returns how many it lifted. Run on load.
// `lifted`, when given, receives what was lifted (a kind must go back to
// the purse).
int validate(State& state, const Plate& plate, std::vector<Placement>* lifted = nullptr);

const Placement* at(const State& state, int row, int col);
int placedCount(const State& state, const std::string& ingot);
int unplacedCount(const State& state, const std::string& ingot);

// The tablet for a skill, if laid.
const Placement* tabletFor(const State& state, const std::string& skill);

// Ingots, pairs, then each working's readings - a support (the ingot's
// skill modifier, when it can read the skill's tags) or an added element
// (an element ingot beside a skill of another element) - each with its
// backing; then each Vanguard working (a kind in a socket: its base, and
// every ingot beside it read as defence); then each augment (a kind on a
// non-socket cell: a fraction of its base, and its readings lent to the
// skill supports it touches). The skill and modifier tables decide which
// reading an ingot gives.
std::vector<Effect> effects(const tuning::Tuning& tuning, const State& state, const Plate& plate);

} // namespace wroughtwild::foundry
