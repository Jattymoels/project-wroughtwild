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
// THE FLOW (owner, 4 Sep 2026): only a skill sits in a socket; a currency
// KIND rests where it cannot touch one, gives its base forward when a
// chain of pieces leads inward to a laid tablet, and works every support
// it touches into a FORM that feeds the skill. Numbers on ingots never
// change; what scales is count, arrangement and, later, reach.
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
    std::string currency{}; // a currency kind (D-023): an augment on a cell that cannot touch a socket
    std::string metal{};    // the metal an ingot is cast in (slice 10; "" = the default)
    bool isTablet() const { return !skill.empty(); }
    bool isIngot() const { return !ingot.empty(); }
    bool isCurrency() const { return !currency.empty(); }
};

// A rail (D-023 slice 9): a slot outside the grid on one row or column,
// holding a pattern that reads the whole line.
struct Rail {
    std::string axis;    // "row" | "column"
    int index = 0;       // the row or the column
    std::string pattern; // a rail pattern id (tuning.foundry.rails.patterns)
};

struct State {
    std::map<std::string, int> owned;   // ingot id -> total owned (placed and not)
    std::vector<Placement> plate;
    std::vector<std::string> milestones; // source ids already granted
    // The surround (D-023 slice 9, owner 4 Sep 2026): the class chosen
    // before play began, the specialisation chosen after the first trial
    // ("" until then), the rails set, and the kills per family that teach
    // the manners.
    std::string chosenClass{};
    std::string specialisation{};
    std::vector<Rail> rails{};
    std::map<std::string, int> kills{};
    // The metal of an ingot (slice 10): ingot id -> metal -> how many are
    // cast in it, placed or not. The counts of an ingot sum to owned[ingot]
    // once normalised; an older save has none and is all the default.
    std::map<std::string, std::map<std::string, int>> metals{};
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
    std::string kind;     // ingot | pair | support | added | backing | augment | form | link
    std::string label;    // Ember Ingot / Wildfire / Frost Orb <- Frost Ingot / Frost Ingot backing Frost Orb
    std::string modifier; // items.json modifier id
    double value = 0.0;
    int row = -1, col = -1; // the placement (ingot), the first cell (pair) or the socket (support, backing)
    std::string skill;    // support, added, backing of a skill working: the one skill it applies to
    int cellRow = -1, cellCol = -1; // the ingot cell the effect comes from
    std::string subject{}; // augment, form: the kind's family (offence, defence, life, speed); rail: the pattern id
    std::string packet{};  // form: the packet type the effect speaks to ("" = the whole skill); rail: the skill tag the rule is scoped to
};

// The plate the era has forged (rows_by_era; the last entry serves later eras).
Plate plate(const tuning::FoundryDef& def, int era);

// The flow (D-023, owner 4 Sep 2026). A cell's depth is its Manhattan
// distance to the nearest socket: supports sit at 1, corners at 2, the far
// cells at 3. A kind rests only at depth 2 or more, where it cannot touch
// a socket. It flows when a chain of placed pieces, each one step nearer
// a socket, reaches a support beside a laid tablet.
int depth(const Plate& plate, int row, int col);
bool kindMayRest(const Plate& plate, int row, int col);
bool flowsToSkill(const State& state, const Plate& plate, int row, int col);

// A link (D-023, re-homed to the flow): a kind of the link family in a
// corner touching a support that serves two sockets links the two skills
// laid there - each casts the other on its own trigger.
struct Link {
    std::string first, second;            // the two skills
    int row = -1, col = -1;               // the kind's cell
    int supportRow = -1, supportCol = -1; // the shared support it touches
};
std::vector<Link> links(const tuning::Tuning& tuning, const State& state, const Plate& plate);

// Rails (D-023 slice 9; owner, 4 Sep 2026: "before you actually begin
// the game you choose a class ... that base plate's surrounding
// modifiers are determined by that first selection. Then once you
// complete trials you specialise further, getting a view of what the
// surround modifiers can become"). Each row and column has one rail
// outside the grid; a pattern set in it reads the line's PLACED cells and
// bends a rule while its condition holds. The patterns a player knows are
// the class's - each replaced by what the specialisation says it becomes,
// once one is chosen - and the manners the world has taught (kills per
// family).
struct RailStatus {
    bool holds = false;
    int placed = 0;  // ingots placed in the line
    int minimum = 0; // the pattern's minimum_placed
    std::vector<Cell> breaking;      // placed cells that break the condition
    bool missingSkill = false;       // no socket in the line holds a skill with the pattern's tag
    bool missingKind = false;        // no kind of the pattern's family rests in the line
    std::vector<std::string> skills; // the skills laid in the line the rule speaks to
};
// The forged cells of a row or column, in line order (empty for a row the
// era has not forged, or an axis or index off the frame).
std::vector<Cell> lineCells(const Plate& plate, const std::string& axis, int index);
std::vector<std::string> knownPatterns(const tuning::Tuning& tuning, const State& state);
bool patternKnown(const tuning::Tuning& tuning, const State& state, const std::string& pattern);
const Rail* railAt(const State& state, const std::string& axis, int index);
RailStatus railStatus(const tuning::Tuning& tuning, const State& state, const Plate& plate, const Rail& rail);
// Drops every rail the state cannot hold - an unknown or unlearned
// pattern, an unforged row, a second rail on a slot or a second slot for
// a pattern, more than `allowed` - keeping the first. Run on load.
int validateRails(const tuning::Tuning& tuning, State& state, const Plate& plate, int allowed);

// Lifts every placement the plate cannot hold - an unforged row, a tablet
// outside a socket, an ingot inside one, a kind touching one, a second
// thing on a cell, a second tablet for a skill - and returns how many it
// lifted. Run on load. `lifted`, when given, receives what was lifted (a
// kind must go back to the purse).
int validate(State& state, const Plate& plate, std::vector<Placement>* lifted = nullptr);

const Placement* at(const State& state, int row, int col);
int placedCount(const State& state, const std::string& ingot);
int unplacedCount(const State& state, const std::string& ingot);

// The metal of an ingot (D-023 slice 10). The metal a placement is cast
// in (the default for ""); how many of an ingot are cast in a metal, and
// how many of those are not on the plate. normaliseMetals makes the
// counts sum to owned (the default metal absorbs the difference) and
// gives every placement a known metal; run on load and after a grant.
std::string metalOf(const tuning::FoundryDef& def, const Placement& placement);
int castCount(const State& state, const std::string& ingot, const std::string& metal);
int placedCountOf(const tuning::FoundryDef& def, const State& state, const std::string& ingot, const std::string& metal);
int unplacedCountOf(const tuning::FoundryDef& def, const State& state, const std::string& ingot, const std::string& metal);
void normaliseMetals(const tuning::FoundryDef& def, State& state);

// The tablet for a skill, if laid.
const Placement* tabletFor(const State& state, const std::string& skill);

// Ingots, pairs (either ingot's metal reaching the other along its row or
// column, gaps ignored), then each working's readings - a support (the ingot's
// skill modifier, when it can read the skill's tags) or an added element
// (an element ingot beside a skill of another element) - each with its
// backing; then each kind that flows: its base (augment) and the forms it
// works the supports it touches into, each feeding the skill that support
// serves. The skill and modifier tables decide which reading an ingot
// gives; the kind's family, the ingot and the lane decide the form. Last,
// each rail whose condition holds: its rule (kind "rail"), to the line's
// skills, to every skill with a tag, or to the sheet.
std::vector<Effect> effects(const tuning::Tuning& tuning, const State& state, const Plate& plate);

} // namespace wroughtwild::foundry
