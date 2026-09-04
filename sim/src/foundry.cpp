#include "wroughtwild/foundry.h"
#include "wroughtwild/grammar.h"

#include <algorithm>
#include <cstdlib>
#include <functional>

namespace wroughtwild::foundry {

namespace {

const std::vector<std::pair<int, int>> kSides{{0, 1}, {1, 0}, {0, -1}, {-1, 0}};

bool hasTag(const std::vector<std::string>& tags, const std::string& tag) {
    return std::find(tags.begin(), tags.end(), tag) != tags.end();
}

// Which lane an ingot reads a skill in: "same" when its skill modifier can
// read the skill (a Frost beside a cold orb), "added" when only its added
// element can (a Frost beside Ember Bolt), "any" for an ingot with no
// element to add.
std::string laneOf(const tuning::Tuning& tuning, const tuning::IngotDef& ingot,
                   const std::vector<std::string>& skillTags) {
    if (ingot.addedModifier.empty()) return "any";
    const auto* own = tuning.items.findModifier(ingot.supportModifier());
    if (own && !own->isSelf() && grammar::modAppliesToTags(own->appliesToTags, skillTags)) return "same";
    const auto* added = tuning.items.findModifier(ingot.addedModifier);
    if (added && grammar::modAppliesToTags(added->appliesToTags, skillTags)) return "added";
    return "any";
}

} // namespace

bool Plate::inFrame(int row, int col) const {
    return row >= 0 && col >= 0 && row < rows && col < cols;
}

bool Plate::forged(int row, int col) const {
    return inFrame(row, col) && row >= firstRow && row <= lastRow;
}

bool Plate::isSocket(int row, int col) const {
    for (const auto& s : sockets)
        if (s.row == row && s.col == col) return true;
    return false;
}

Plate plate(const tuning::FoundryDef& def, int era) {
    Plate p;
    p.rows = def.frameRows;
    p.cols = def.frameCols;
    if (def.rowsByEra.empty()) {
        p.firstRow = 0;
        p.lastRow = p.rows - 1;
    } else {
        const size_t index = static_cast<size_t>(std::clamp(era, 1, static_cast<int>(def.rowsByEra.size())) - 1);
        p.firstRow = def.rowsByEra[index][0];
        p.lastRow = def.rowsByEra[index][1];
    }
    for (const auto& s : def.sockets) p.sockets.push_back({s[0], s[1]});
    return p;
}

int depth(const Plate& plate, int row, int col) {
    int best = -1;
    for (const auto& s : plate.sockets) {
        const int d = std::abs(s.row - row) + std::abs(s.col - col);
        if (best < 0 || d < best) best = d;
    }
    return best;
}

bool kindMayRest(const Plate& plate, int row, int col) {
    return plate.forged(row, col) && depth(plate, row, col) >= 2;
}

int validate(State& state, const Plate& plate, std::vector<Placement>* lifted) {
    std::vector<Placement> kept;
    int count = 0;
    for (const auto& p : state.plate) {
        const bool taken = std::any_of(kept.begin(), kept.end(), [&](const Placement& k) {
            return (k.row == p.row && k.col == p.col) || (p.isTablet() && k.skill == p.skill);
        });
        const bool socket = plate.isSocket(p.row, p.col);
        // A tablet only in a socket, an ingot never in one, a kind only
        // where it cannot touch a socket (the flow, D-023).
        const bool placeFits = p.isTablet() ? socket : (p.isCurrency() ? kindMayRest(plate, p.row, p.col) : !socket);
        const bool holds = plate.forged(p.row, p.col) && !taken && placeFits;
        if (holds) {
            kept.push_back(p);
        } else {
            ++count;
            if (lifted) lifted->push_back(p);
        }
    }
    state.plate.swap(kept);
    return count;
}

const Placement* at(const State& state, int row, int col) {
    for (const auto& p : state.plate)
        if (p.row == row && p.col == col) return &p;
    return nullptr;
}

const Placement* tabletFor(const State& state, const std::string& skill) {
    for (const auto& p : state.plate)
        if (p.skill == skill) return &p;
    return nullptr;
}

int placedCount(const State& state, const std::string& ingot) {
    int n = 0;
    for (const auto& p : state.plate)
        if (p.ingot == ingot) ++n;
    return n;
}

int unplacedCount(const State& state, const std::string& ingot) {
    auto it = state.owned.find(ingot);
    const int owned = it == state.owned.end() ? 0 : it->second;
    return std::max(0, owned - placedCount(state, ingot));
}

bool flowsToSkill(const State& state, const Plate& plate, int row, int col) {
    // Each step goes to a placed piece one nearer a socket, so the walk
    // always ends; a support (depth 1) reaches the skill only when a
    // socket beside it holds a tablet.
    std::function<bool(int, int)> reaches = [&](int r, int c) -> bool {
        if (!plate.forged(r, c)) return false;
        const Placement* here = at(state, r, c);
        if (!here || here->isTablet()) return false;
        const int d = depth(plate, r, c);
        if (d <= 1) {
            if (!here->isIngot()) return false;
            for (const auto& [dr, dc] : kSides) {
                if (!plate.isSocket(r + dr, c + dc) || !plate.forged(r + dr, c + dc)) continue;
                const Placement* socket = at(state, r + dr, c + dc);
                if (socket && socket->isTablet()) return true;
            }
            return false;
        }
        for (const auto& [dr, dc] : kSides)
            if (plate.forged(r + dr, c + dc) && depth(plate, r + dr, c + dc) == d - 1 && reaches(r + dr, c + dc)) return true;
        return false;
    };
    return reaches(row, col);
}

std::vector<Effect> effects(const tuning::Tuning& tuning, const State& state, const Plate& plate) {
    const tuning::FoundryDef& def = tuning.foundry;
    std::vector<Effect> out;
    auto cell = [&](int r, int c) -> const Placement* {
        if (!plate.forged(r, c)) return nullptr;
        return at(state, r, c);
    };
    // Ingots: every ingot on a forged cell speaks its verb.
    for (const auto& p : state.plate) {
        if (!p.isIngot() || !plate.forged(p.row, p.col)) continue;
        const auto* ingot = def.findIngot(p.ingot);
        if (!ingot) continue;
        Effect e{"ingot", ingot->displayName, ingot->modifier, ingot->value, p.row, p.col, std::string()};
        e.cellRow = p.row;
        e.cellCol = p.col;
        out.push_back(e);
    }
    // Pairs: each orthogonal adjacency once (right and down from each cell).
    for (int r = 0; r < plate.rows; ++r) {
        for (int c = 0; c < plate.cols; ++c) {
            const auto* here = cell(r, c);
            if (!here || !here->isIngot()) continue;
            for (const auto& [dr, dc] : std::vector<std::pair<int, int>>{{0, 1}, {1, 0}}) {
                const auto* there = cell(r + dr, c + dc);
                if (!there || !there->isIngot()) continue;
                const auto* pair = def.findPair(here->ingot, there->ingot);
                if (!pair) continue;
                Effect e{"pair", pair->displayName, pair->modifier, pair->value, r, c, std::string()};
                e.cellRow = r;
                e.cellCol = c;
                out.push_back(e);
            }
        }
    }
    // Workings (D-022, D-023): a tablet in a socket reads the ingots
    // orthogonally beside it, and the skill decides each ingot's reading
    // (slice 2, owner 4 Sep 2026: every ingot reads every skill). The
    // ingot's skill modifier speaks when it can read the skill's tags - a
    // same-element scaling, Reach, the self ingots' weak readings - at
    // support_multiplier times the reading's value, to that skill alone.
    // When it cannot, an element ingot adds its element to the hit
    // instead (kind "added"), the same fraction. A matching ingot touching
    // the reading's cell from any side but the socket's backs it, and the
    // reading counts once more.
    for (const auto& p : state.plate) {
        if (!p.isTablet() || !plate.forged(p.row, p.col) || !plate.isSocket(p.row, p.col)) continue;
        const auto* skill = tuning.skills.findCombatSkill(p.skill);
        if (!skill) continue;
        const auto skillTags = skill->resolveTags();
        for (const auto& [dr, dc] : kSides) {
            const int sr = p.row + dr, sc = p.col + dc;
            const auto* beside = cell(sr, sc);
            if (!beside || !beside->isIngot()) continue;
            const auto* ingot = def.findIngot(beside->ingot);
            if (!ingot) continue;
            std::string kind = "support";
            double value = ingot->supportValue() * def.supportMultiplier;
            const auto* modifier = tuning.items.findModifier(ingot->supportModifier());
            if (!modifier || modifier->isSelf() || !grammar::modAppliesToTags(modifier->appliesToTags, skillTags)) {
                modifier = ingot->addedModifier.empty() ? nullptr : tuning.items.findModifier(ingot->addedModifier);
                if (!modifier || !grammar::modAppliesToTags(modifier->appliesToTags, skillTags)) continue;
                kind = "added";
                value = ingot->value * def.supportMultiplier;
            }
            Effect support{kind, skill->displayName + " <- " + ingot->displayName, modifier->id, value, p.row, p.col, p.skill};
            support.cellRow = sr;
            support.cellCol = sc;
            out.push_back(support);
            for (const auto& [br, bc] : kSides) {
                const int nr = sr + br, nc = sc + bc;
                if (nr == p.row && nc == p.col) continue;
                const auto* backer = cell(nr, nc);
                if (!backer || !backer->isIngot() || backer->ingot != beside->ingot) continue;
                Effect backing{"backing", ingot->displayName + " backing " + skill->displayName, modifier->id, value, p.row, p.col, p.skill};
                backing.cellRow = nr;
                backing.cellCol = nc;
                out.push_back(backing);
            }
        }
    }
    // Kinds (D-023, the flow, owner 4 Sep 2026): a kind rests only where it
    // cannot touch a socket. When a chain of placed pieces leads from it
    // inward to a support beside a laid tablet, its family's base counts
    // (kind "augment") and it works every support it touches into a FORM
    // (kind "form"): the ingot keeps its plain reading and gains the
    // form's, which feeds the skill the support serves - both skills, for
    // a shared support. Which form is the family's, the ingot's and the
    // lane's (same element, added element, any).
    for (const auto& p : state.plate) {
        if (!p.isCurrency() || !kindMayRest(plate, p.row, p.col)) continue;
        const auto* kind = def.findKindOnPlate(p.currency);
        if (!kind) continue;
        if (!flowsToSkill(state, plate, p.row, p.col)) continue;
        if (!kind->modifier.empty()) {
            Effect own{"augment", kind->displayName, kind->modifier, kind->value, p.row, p.col, std::string()};
            own.subject = kind->family;
            own.cellRow = p.row;
            own.cellCol = p.col;
            out.push_back(own);
        }
        for (const auto& [dr, dc] : kSides) {
            const int sr = p.row + dr, sc = p.col + dc;
            if (!plate.forged(sr, sc) || depth(plate, sr, sc) != 1) continue;
            const auto* beside = cell(sr, sc);
            if (!beside || !beside->isIngot()) continue;
            const auto* ingot = def.findIngot(beside->ingot);
            if (!ingot) continue;
            for (const auto& [tr, tc] : kSides) {
                const int socketRow = sr + tr, socketCol = sc + tc;
                if (!plate.isSocket(socketRow, socketCol)) continue;
                const auto* tablet = cell(socketRow, socketCol);
                if (!tablet || !tablet->isTablet()) continue;
                const auto* skill = tuning.skills.findCombatSkill(tablet->skill);
                if (!skill) continue;
                const auto skillTags = skill->resolveTags();
                const std::string lane = laneOf(tuning, *ingot, skillTags);
                for (const auto& form : def.forms) {
                    if (form.family != kind->family || form.ingot != ingot->id) continue;
                    if (!form.kind.empty() && form.kind != p.currency) continue;
                    if (!form.lane.empty() && form.lane != lane) continue;
                    if (!form.skillTag.empty() && !hasTag(skillTags, form.skillTag)) continue;
                    for (const auto& fe : form.effects) {
                        Effect e{"form", form.displayName + " (" + kind->displayName + " on " + ingot->displayName + ")",
                                 fe.modifier, fe.value, socketRow, socketCol, tablet->skill};
                        e.cellRow = sr;
                        e.cellCol = sc;
                        e.subject = kind->family;
                        e.packet = fe.packet == "native" ? grammar::nativeType(tuning, skillTags) : fe.packet;
                        out.push_back(e);
                    }
                }
            }
        }
    }
    return out;
}

} // namespace wroughtwild::foundry
