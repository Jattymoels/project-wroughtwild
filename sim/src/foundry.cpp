#include "wroughtwild/foundry.h"
#include "wroughtwild/grammar.h"

#include <algorithm>
#include <cstdlib>
#include <functional>
#include <set>
#include <tuple>
#include <string>

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

// --- rails (D-023 slice 9) -----------------------------------------------------

std::vector<Cell> lineCells(const Plate& plate, const std::string& axis, int index) {
    std::vector<Cell> cells;
    if (axis == "row") {
        for (int c = 0; c < plate.cols; ++c)
            if (plate.forged(index, c)) cells.push_back({index, c});
    } else if (axis == "column") {
        for (int r = 0; r < plate.rows; ++r)
            if (plate.forged(r, index)) cells.push_back({r, index});
    }
    return cells;
}

std::vector<std::string> knownPatterns(const tuning::Tuning& tuning, const State& state) {
    std::vector<std::string> known;
    const auto& rails = tuning.foundry.rails;
    const auto* cls = rails.findClass(state.chosenClass);
    const auto* spec = rails.findSpecialisation(state.specialisation);
    if (spec && (!cls || spec->classId != cls->id)) spec = nullptr;
    if (cls) {
        for (const auto& id : cls->patterns) {
            std::string use = id;
            if (spec) {
                const auto it = spec->becomes.find(id);
                if (it != spec->becomes.end()) use = it->second;
            }
            if (rails.findPattern(use) && !hasTag(known, use)) known.push_back(use);
        }
    }
    for (const auto& pattern : rails.patterns) {
        if (!pattern.isManner() || hasTag(known, pattern.id)) continue;
        const auto it = state.kills.find(pattern.taughtByEnemy);
        if (it != state.kills.end() && it->second >= pattern.taughtKills) known.push_back(pattern.id);
    }
    return known;
}

bool patternKnown(const tuning::Tuning& tuning, const State& state, const std::string& pattern) {
    return hasTag(knownPatterns(tuning, state), pattern);
}

const Rail* railAt(const State& state, const std::string& axis, int index) {
    for (const auto& r : state.rails)
        if (r.axis == axis && r.index == index) return &r;
    return nullptr;
}

RailStatus railStatus(const tuning::Tuning& tuning, const State& state, const Plate& plate, const Rail& rail) {
    RailStatus status;
    const auto* pattern = tuning.foundry.rails.findPattern(rail.pattern);
    if (!pattern || pattern->axis != rail.axis) return status;
    const auto cells = lineCells(plate, rail.axis, rail.index);
    if (cells.empty()) return status;
    const auto& cond = pattern->condition;
    status.minimum = cond.minimumPlaced;
    // The line's placed pieces in order: ingots for the condition, tablets
    // for whom the rule speaks to, kinds for the family the line must hold.
    std::vector<std::pair<Cell, const Placement*>> ingots;
    bool skillMet = cond.holdsSkillTag.empty();
    bool kindMet = cond.holdsKindFamily.empty();
    for (const auto& cell : cells) {
        const Placement* p = at(state, cell.row, cell.col);
        if (!p) continue;
        if (p->isIngot()) {
            ingots.push_back({cell, p});
        } else if (p->isTablet()) {
            const auto* skill = tuning.skills.findCombatSkill(p->skill);
            if (!skill) continue;
            if (cond.holdsSkillTag.empty() || hasTag(skill->resolveTags(), cond.holdsSkillTag)) {
                status.skills.push_back(p->skill);
                skillMet = true;
            }
        } else if (p->isCurrency()) {
            const auto* kind = tuning.foundry.findKindOnPlate(p->currency);
            if (kind && kind->family == cond.holdsKindFamily) kindMet = true;
        }
    }
    status.placed = static_cast<int>(ingots.size());
    bool ok = status.placed >= status.minimum;
    auto breaks = [&](const Cell& cell) {
        for (const auto& b : status.breaking)
            if (b.row == cell.row && b.col == cell.col) return;
        status.breaking.push_back(cell);
        ok = false;
    };
    if (!cond.allPlacedAre.empty())
        for (const auto& [cell, p] : ingots)
            if (!hasTag(cond.allPlacedAre, p->ingot)) breaks(cell);
    if (cond.alternating.size() == 2) {
        for (size_t i = 0; i < ingots.size(); ++i) {
            const auto& [cell, p] = ingots[i];
            if (!hasTag(cond.alternating, p->ingot)) breaks(cell);
            else if (i > 0 && ingots[i - 1].second->ingot == p->ingot) breaks(cell);
        }
    }
    if (cond.endsAre.size() == 2) {
        const Placement* a = at(state, cells.front().row, cells.front().col);
        const Placement* b = at(state, cells.back().row, cells.back().col);
        const std::string ia = a && a->isIngot() ? a->ingot : std::string();
        const std::string ib = b && b->isIngot() ? b->ingot : std::string();
        const bool match = (ia == cond.endsAre[0] && ib == cond.endsAre[1]) || (ia == cond.endsAre[1] && ib == cond.endsAre[0]);
        if (!match) {
            ok = false;
            // An end holding the wrong ingot breaks it; an empty end only waits.
            if (!ia.empty() && (!hasTag(cond.endsAre, ia) || (ia == ib && cond.endsAre[0] != cond.endsAre[1]))) breaks(cells.front());
            if (!ib.empty() && (!hasTag(cond.endsAre, ib) || (ia == ib && cond.endsAre[0] != cond.endsAre[1]))) breaks(cells.back());
        }
    }
    status.missingSkill = !skillMet;
    status.missingKind = !kindMet;
    status.holds = ok && skillMet && kindMet;
    return status;
}

int validateRails(const tuning::Tuning& tuning, State& state, const Plate& plate, int allowed) {
    const auto known = knownPatterns(tuning, state);
    std::vector<Rail> kept;
    int dropped = 0;
    for (const auto& rail : state.rails) {
        const auto* pattern = tuning.foundry.rails.findPattern(rail.pattern);
        const bool fits = pattern && pattern->axis == rail.axis && hasTag(known, rail.pattern) &&
                          !lineCells(plate, rail.axis, rail.index).empty();
        const bool taken = std::any_of(kept.begin(), kept.end(), [&](const Rail& k) {
            return (k.axis == rail.axis && k.index == rail.index) || k.pattern == rail.pattern;
        });
        if (fits && !taken && static_cast<int>(kept.size()) < allowed) kept.push_back(rail);
        else ++dropped;
    }
    state.rails.swap(kept);
    return dropped;
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

// --- the metal of an ingot (D-023 slice 10) -----------------------------------

std::string metalOf(const tuning::FoundryDef& def, const Placement& placement) {
    return placement.metal.empty() || !def.findMetal(placement.metal) ? def.defaultMetal() : placement.metal;
}

int castCount(const State& state, const std::string& ingot, const std::string& metal) {
    const auto it = state.metals.find(ingot);
    if (it == state.metals.end()) return 0;
    const auto m = it->second.find(metal);
    return m == it->second.end() ? 0 : m->second;
}

int placedCountOf(const tuning::FoundryDef& def, const State& state, const std::string& ingot, const std::string& metal) {
    int n = 0;
    for (const auto& p : state.plate)
        if (p.ingot == ingot && metalOf(def, p) == metal) ++n;
    return n;
}

int unplacedCountOf(const tuning::FoundryDef& def, const State& state, const std::string& ingot, const std::string& metal) {
    return std::max(0, castCount(state, ingot, metal) - placedCountOf(def, state, ingot, metal));
}

void normaliseMetals(const tuning::FoundryDef& def, State& state) {
    const std::string base = def.defaultMetal();
    for (auto& p : state.plate)
        if (p.isIngot()) p.metal = metalOf(def, p);
    for (const auto& [ingot, owned] : state.owned) {
        auto& counts = state.metals[ingot];
        for (auto it = counts.begin(); it != counts.end();)
            it = (!def.findMetal(it->first) || it->second <= 0) ? counts.erase(it) : std::next(it);
        // What is placed in a metal is at least cast in it; the default gives way.
        for (const auto& m : def.metals) {
            const int placed = placedCountOf(def, state, ingot, m.id);
            if (placed > counts[m.id]) counts[m.id] = placed;
        }
        int sum = 0;
        for (const auto& [metal, count] : counts) sum += count;
        if (sum < owned) counts[base] += owned - sum;
        else if (sum > owned) {
            // Too many cast: the default sheds first, then the rest from the widest down.
            int excess = sum - owned;
            const int placedBase = placedCountOf(def, state, ingot, base);
            const int shed = std::min(excess, std::max(0, counts[base] - placedBase));
            counts[base] -= shed;
            excess -= shed;
            for (auto m = def.metals.rbegin(); m != def.metals.rend() && excess > 0; ++m) {
                const int spare = std::max(0, counts[m->id] - placedCountOf(def, state, ingot, m->id));
                const int take = std::min(excess, spare);
                counts[m->id] -= take;
                excess -= take;
            }
        }
        for (auto it = counts.begin(); it != counts.end();)
            it = it->second <= 0 ? counts.erase(it) : std::next(it);
    }
    for (auto it = state.metals.begin(); it != state.metals.end();)
        it = state.owned.count(it->first) ? std::next(it) : state.metals.erase(it);
}

std::vector<Route> routes(const State& state, const Plate& plate, int row, int col) {
    std::vector<Route> out;
    std::vector<Cell> path;
    std::function<void(int, int)> walk = [&](int r, int c) {
        if (!plate.forged(r, c)) return;
        const auto* here = at(state, r, c);
        if (!here || here->isTablet()) return;
        path.push_back({r, c});
        const int d = depth(plate, r, c);
        if (d == 1 && here->isIngot()) {
            for (const auto& socket : plate.sockets) {
                if (!plate.forged(socket.row, socket.col) || std::abs(socket.row-r)+std::abs(socket.col-c) != 1) continue;
                const auto* tablet = at(state, socket.row, socket.col);
                if (!tablet || !tablet->isTablet()) continue;
                auto complete = path;
                complete.push_back(socket);
                out.push_back({tablet->skill, std::move(complete)});
            }
        } else if (d > 1) {
            for (const auto& [dr, dc] : kSides)
                if (depth(plate, r+dr, c+dc) == d-1) walk(r+dr, c+dc);
        }
        path.pop_back();
    };
    walk(row, col);
    return out;
}

bool flowsToSkill(const State& state, const Plate& plate, int row, int col) {
    return !routes(state, plate, row, col).empty();
}

std::vector<Link> links(const tuning::Tuning& tuning, const State& state, const Plate& plate) {
    std::vector<Link> out;
    const tuning::FoundryDef& def = tuning.foundry;
    if (def.linkFamily.empty()) return out;
    for (const auto& p : state.plate) {
        if (!p.isCurrency() || !kindMayRest(plate, p.row, p.col)) continue;
        const auto* kind = def.findKindOnPlate(p.currency);
        if (!kind || kind->family != def.linkFamily) continue;
        for (const auto& [dr, dc] : kSides) {
            const int sr = p.row + dr, sc = p.col + dc;
            if (!plate.forged(sr, sc) || depth(plate, sr, sc) != 1) continue;
            const Placement* support = at(state, sr, sc);
            if (!support || !support->isIngot()) continue;
            // The skills laid in the sockets this support serves, in the
            // frame's socket order.
            std::vector<std::string> served;
            for (const auto& socket : plate.sockets) {
                if (std::abs(socket.row - sr) + std::abs(socket.col - sc) != 1 || !plate.forged(socket.row, socket.col)) continue;
                const Placement* tablet = at(state, socket.row, socket.col);
                if (tablet && tablet->isTablet() && tuning.skills.findCombatSkill(tablet->skill)) served.push_back(tablet->skill);
            }
            if (served.size() < 2) continue;
            Link link;
            link.first = served[0];
            link.second = served[1];
            link.row = p.row;
            link.col = p.col;
            link.supportRow = sr;
            link.supportCol = sc;
            out.push_back(link);
        }
    }
    return out;
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
    // Pairs: each pair once (right and down from each cell), as far along
    // the row or column as either ingot's metal reaches (slice 10), gaps
    // ignored - iron one cell, bronze two, steel three.
    const int maxReach = def.maxReach();
    auto reachOf = [&](const Placement& p) { return def.metalReach(metalOf(def, p)); };
    for (int r = 0; r < plate.rows; ++r) {
        for (int c = 0; c < plate.cols; ++c) {
            const auto* here = cell(r, c);
            if (!here || !here->isIngot()) continue;
            for (const auto& [dr, dc] : std::vector<std::pair<int, int>>{{0, 1}, {1, 0}}) {
                for (int d = 1; d <= maxReach; ++d) {
                    if (plate.isSocket(r + dr * d, c + dc * d)) break; // never read through a socket
                    const auto* there = cell(r + dr * d, c + dc * d);
                    if (!there || !there->isIngot()) continue;
                    if (std::max(reachOf(*here), reachOf(*there)) < d) continue;
                    const auto* pair = def.findPair(here->ingot, there->ingot);
                    if (!pair) continue;
                    Effect e{"pair", pair->displayName, pair->modifier, pair->value, r, c, std::string()};
                    e.cellRow = r;
                    e.cellCol = c;
                    out.push_back(e);
                }
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
            // Backing: a matching ingot on any side but the socket's, as far
            // as either metal reaches (slice 10), never read through the socket.
            for (const auto& [br, bc] : kSides) {
                if (sr + br == p.row && sc + bc == p.col) continue;
                for (int d = 1; d <= maxReach; ++d) {
                    const int nr = sr + br * d, nc = sc + bc * d;
                    if (plate.isSocket(nr, nc)) break; // never read through a socket
                    const auto* backer = cell(nr, nc);
                    if (!backer || !backer->isIngot() || backer->ingot != beside->ingot) continue;
                    if (std::max(reachOf(*beside), reachOf(*backer)) < d) continue;
                    Effect backing{"backing", ingot->displayName + " backing " + skill->displayName, modifier->id, value, p.row, p.col, p.skill};
                    backing.cellRow = nr;
                    backing.cellCol = nc;
                    out.push_back(backing);
                }
            }
        }
    }
    // A route carries the exact source Kind through EVERY inward ingot.
    // A support shared by two sockets reads once for each skill. Alternate
    // routes to the same reading do not multiply it. Different ingot cells
    // are real investments and add their payloads, within grammar limits.
    auto emitForm = [&](const tuning::FormDef& form, const Placement& ingot, const Placement& tablet,
                        const std::string& source, const std::vector<Cell>& path) {
        const auto* skill = tuning.skills.findCombatSkill(tablet.skill);
        const auto* definition = def.findIngot(ingot.ingot);
        if (!skill || !definition) return;
        auto tags = skill->resolveTags();
        if (form.supportOnly) {
            for (const auto& prior : out) {
                if (prior.skill != tablet.skill) continue;
                const auto* modifier = tuning.items.findModifier(prior.modifier);
                const std::string prefix = "add_grant_tag_";
                if (!modifier || modifier->effectKey.compare(0, prefix.size(), prefix) || prior.value <= 0) continue;
                const auto tag = modifier->effectKey.substr(prefix.size());
                if (tag == "projectile" && skill->delivery != "projectile" && skill->delivery != "strike" && skill->delivery != "cone") continue;
                if (!hasTag(tags, tag)) tags.push_back(tag);
            }
        }
        if (!form.lane.empty() && form.lane != laneOf(tuning, *definition, tags)) return;
        if (!form.skillTag.empty() && !hasTag(tags, form.skillTag)) return;
        if (!form.metal.empty() && reachOf(ingot) < def.metalReach(form.metal)) return;
        for (const auto& fe : form.effects) {
            Effect e{"form", form.displayName + " <- " + definition->displayName,
                     fe.modifier, fe.value, tablet.row, tablet.col, tablet.skill};
            e.cellRow = ingot.row; e.cellCol = ingot.col;
            e.subject = form.family;
            e.packet = fe.packet == "native" ? grammar::nativeType(tuning, skill->resolveTags()) : fe.packet;
            e.formName = form.displayName; e.description = form.description;
            e.sourceKind = source; e.path = path;
            out.push_back(std::move(e));
        }
    };
    for (const auto& p : state.plate) {
        if (!p.isCurrency() || !kindMayRest(plate, p.row, p.col)) continue;
        const auto* kind = def.findKindOnPlate(p.currency);
        const auto paths = routes(state, plate, p.row, p.col);
        if (!kind || paths.empty()) continue;
        if (!kind->modifier.empty()) {
            Effect own{"augment", kind->displayName, kind->modifier, kind->value, p.row, p.col, std::string()};
            own.subject = kind->family; own.cellRow = p.row; own.cellCol = p.col;
            out.push_back(own);
        }
        std::set<std::tuple<int, int, std::string, size_t>> emitted;
        for (const auto& route : paths) {
            const auto& last = route.cells.back();
            const auto* tablet = cell(last.row, last.col);
            if (!tablet) continue;
            std::vector<std::string> upstream;
            for (const auto& step : route.cells) {
                const auto* piece = cell(step.row, step.col);
                if (!piece) continue;
                if (piece->isCurrency()) { upstream.push_back(piece->currency); continue; }
                if (!piece->isIngot()) continue;
                for (size_t i = 0; i < def.forms.size(); ++i) {
                    const auto& form = def.forms[i];
                    if (form.supportOnly || form.ingot != piece->ingot) continue;
                    // Exact identities are mandatory for new forms. The family
                    // fallback remains a loader compatibility contract only.
                    if (form.family != kind->family || (!form.kind.empty() && form.kind != p.currency)) continue;
                    if (!form.upstreamKind.empty()) continue;
                    if (emitted.emplace(piece->row, piece->col, tablet->skill, i).second)
                        emitForm(form, *piece, *tablet, p.currency, route.cells);
                }
                // Ordered compound rules: a downstream Kind acts on the source
                // before its reading reaches this ingot, never on a sibling branch.
                for (size_t k = 1; k < upstream.size(); ++k) {
                    for (size_t i = 0; i < def.forms.size(); ++i) {
                        const auto& form = def.forms[i];
                        if (form.upstreamKind != p.currency || form.kind != upstream[k] || form.ingot != piece->ingot) continue;
                        if (emitted.emplace(piece->row, piece->col, tablet->skill, i).second)
                            emitForm(form, *piece, *tablet, p.currency + ">" + upstream[k], route.cells);
                    }
                }
            }
        }
    }
    // Alloy refinements belong to direct supports, independently of any Kind.
    for (const auto& p : state.plate) {
        if (!p.isIngot() || !plate.forged(p.row, p.col)) continue;
        for (const auto& socket : plate.sockets) {
            if (!plate.forged(socket.row, socket.col) || std::abs(socket.row-p.row)+std::abs(socket.col-p.col) != 1) continue;
            const auto* tablet = cell(socket.row, socket.col);
            if (!tablet || !tablet->isTablet()) continue;
            for (const auto& form : def.forms)
                if (form.supportOnly && form.ingot == p.ingot)
                    emitForm(form, p, *tablet, "", {{p.row, p.col}, socket});
        }
    }
    // Links: the corner between two workings.
    for (const auto& link : links(tuning, state, plate)) {
        const auto* first = tuning.skills.findCombatSkill(link.first);
        const auto* second = tuning.skills.findCombatSkill(link.second);
        const auto* kind = at(state, link.row, link.col);
        const auto* kindDef = kind ? def.findKindOnPlate(kind->currency) : nullptr;
        if (!first || !second || !kindDef) continue;
        Effect e{"link", first->displayName + " <-> " + second->displayName + " (" + kindDef->displayName + ")", std::string(), 0.0,
                 link.row, link.col, link.first};
        e.cellRow = link.supportRow;
        e.cellCol = link.supportCol;
        e.subject = kindDef->family;
        out.push_back(e);
    }
    // Rails (D-023 slice 9): a pattern set in a rail whose line meets its
    // condition bends its rule - for the line's skills (or the ones with
    // the pattern's tag), for every skill with an effect's tag, or on the
    // sheet when the modifier is a self one.
    const auto known = knownPatterns(tuning, state);
    for (const auto& rail : state.rails) {
        if (!hasTag(known, rail.pattern)) continue;
        const auto* pattern = def.rails.findPattern(rail.pattern);
        if (!pattern) continue;
        const RailStatus status = railStatus(tuning, state, plate, rail);
        if (!status.holds) continue;
        const std::string label = pattern->displayName + " (" + rail.axis + " " + std::to_string(rail.index + 1) + ")";
        const int row = rail.axis == "row" ? rail.index : -1;
        const int col = rail.axis == "column" ? rail.index : -1;
        for (const auto& fe : pattern->effects) {
            const auto* modifier = tuning.items.findModifier(fe.modifier);
            if (!modifier) continue;
            auto push = [&](const std::string& skill) {
                Effect e{"rail", label, fe.modifier, fe.value, row, col, skill};
                e.subject = pattern->id;
                e.packet = fe.skillTag;
                out.push_back(e);
            };
            if (modifier->isSelf() || !fe.skillTag.empty()) push(std::string());
            else
                for (const auto& skill : status.skills) push(skill);
        }
    }
    return out;
}

} // namespace wroughtwild::foundry
