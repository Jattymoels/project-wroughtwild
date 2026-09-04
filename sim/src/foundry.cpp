#include "wroughtwild/foundry.h"
#include "wroughtwild/grammar.h"

#include <algorithm>

namespace wroughtwild::foundry {

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

int validate(State& state, const Plate& plate, std::vector<Placement>* lifted) {
    std::vector<Placement> kept;
    int count = 0;
    for (const auto& p : state.plate) {
        const bool taken = std::any_of(kept.begin(), kept.end(), [&](const Placement& k) {
            return (k.row == p.row && k.col == p.col) || (p.isTablet() && k.skill == p.skill);
        });
        const bool socket = plate.isSocket(p.row, p.col);
        // A tablet only in a socket, an ingot never in one, a kind anywhere forged.
        const bool placeFits = p.isTablet() ? socket : (p.isCurrency() ? true : !socket);
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

std::vector<Effect> effects(const tuning::Tuning& tuning, const State& state, const Plate& plate) {
    const tuning::FoundryDef& def = tuning.foundry;
    std::vector<Effect> out;
    static const std::vector<std::pair<int, int>> kSides{{0, 1}, {1, 0}, {0, -1}, {-1, 0}};
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
    // Vanguard workings (D-023 slice 4): a kind in a socket gives its base
    // and every ingot beside it reads as defence - its vanguard reading at
    // support_multiplier - backing counting once more, exactly as a skill
    // working reads, with the subject deciding the reading.
    for (const auto& p : state.plate) {
        if (!p.isCurrency() || !plate.forged(p.row, p.col) || !plate.isSocket(p.row, p.col)) continue;
        const auto* subject = def.findSubject(p.currency);
        if (!subject) continue;
        Effect own{"subject", subject->displayName, subject->modifier, subject->value, p.row, p.col, std::string()};
        own.subject = p.currency;
        own.cellRow = p.row;
        own.cellCol = p.col;
        out.push_back(own);
        for (const auto& [dr, dc] : kSides) {
            const int sr = p.row + dr, sc = p.col + dc;
            const auto* beside = cell(sr, sc);
            if (!beside || !beside->isIngot()) continue;
            const auto* ingot = def.findIngot(beside->ingot);
            if (!ingot) continue;
            const auto* modifier = tuning.items.findModifier(ingot->vanguardReading());
            if (!modifier) continue;
            const double value = ingot->vanguardReadingValue() * def.supportMultiplier;
            Effect support{"support", subject->displayName + " <- " + ingot->displayName, modifier->id, value, p.row, p.col, std::string()};
            support.subject = p.currency;
            support.cellRow = sr;
            support.cellCol = sc;
            out.push_back(support);
            for (const auto& [br, bc] : kSides) {
                const int nr = sr + br, nc = sc + bc;
                if (nr == p.row && nc == p.col) continue;
                const auto* backer = cell(nr, nc);
                if (!backer || !backer->isIngot() || backer->ingot != beside->ingot) continue;
                Effect backing{"backing", ingot->displayName + " backing " + subject->displayName, modifier->id, value, p.row, p.col, std::string()};
                backing.subject = p.currency;
                backing.cellRow = nr;
                backing.cellCol = nc;
                out.push_back(backing);
            }
        }
    }
    // Augments: a kind on a non-socket cell gives a fraction of its base and
    // lends its readings to every ingot it touches that supports a skill's
    // socket - the way an offence working carries defence.
    for (const auto& p : state.plate) {
        if (!p.isCurrency() || !plate.forged(p.row, p.col) || plate.isSocket(p.row, p.col)) continue;
        const auto* subject = def.findSubject(p.currency);
        if (!subject) continue;
        Effect own{"augment", subject->displayName + " in a corner", subject->modifier, subject->value * def.cornerBaseFraction, p.row, p.col, std::string()};
        own.subject = p.currency;
        own.cellRow = p.row;
        own.cellCol = p.col;
        out.push_back(own);
        for (const auto& [dr, dc] : kSides) {
            const int nr = p.row + dr, nc = p.col + dc;
            const auto* beside = cell(nr, nc);
            if (!beside || !beside->isIngot()) continue;
            bool supportsSkill = false;
            for (const auto& [sr, sc] : kSides) {
                const auto* socket = cell(nr + sr, nc + sc);
                if (socket && socket->isTablet() && plate.isSocket(nr + sr, nc + sc)) supportsSkill = true;
            }
            if (!supportsSkill) continue;
            const auto* ingot = def.findIngot(beside->ingot);
            if (!ingot) continue;
            const auto* modifier = tuning.items.findModifier(ingot->vanguardReading());
            if (!modifier) continue;
            Effect lending{"lending", ingot->displayName + " <- " + subject->displayName, modifier->id,
                           ingot->vanguardReadingValue() * def.cornerLendingMultiplier, p.row, p.col, std::string()};
            lending.subject = p.currency;
            lending.cellRow = nr;
            lending.cellCol = nc;
            out.push_back(lending);
        }
    }
    return out;
}

} // namespace wroughtwild::foundry
