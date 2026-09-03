#include "wroughtwild/foundry.h"

#include <algorithm>

namespace wroughtwild::foundry {

PlateSize plateSize(const tuning::FoundryDef& def, int era) {
    PlateSize size;
    if (def.plateByEra.empty()) return size;
    const size_t index = static_cast<size_t>(std::clamp(era, 1, static_cast<int>(def.plateByEra.size())) - 1);
    size.rows = def.plateByEra[index][0];
    size.cols = def.plateByEra[index][1];
    return size;
}

const Placement* at(const State& state, int row, int col) {
    for (const auto& p : state.plate)
        if (p.row == row && p.col == col) return &p;
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

std::vector<Effect> effects(const tuning::FoundryDef& def, const State& state, PlateSize size) {
    std::vector<Effect> out;
    auto cell = [&](int r, int c) -> const Placement* {
        if (r < 0 || c < 0 || r >= size.rows || c >= size.cols) return nullptr;
        return at(state, r, c);
    };
    // Ingots: every placement inside the plate speaks its verb.
    for (const auto& p : state.plate) {
        if (p.row >= size.rows || p.col >= size.cols) continue; // off a plate that shrank (never, but safe)
        const auto* ingot = def.findIngot(p.ingot);
        if (!ingot) continue;
        out.push_back({"ingot", ingot->displayName, ingot->modifier, ingot->value, p.row, p.col});
    }
    // Pairs: each orthogonal adjacency once (right and down from each cell).
    for (int r = 0; r < size.rows; ++r) {
        for (int c = 0; c < size.cols; ++c) {
            const auto* here = cell(r, c);
            if (!here) continue;
            for (const auto& [dr, dc] : std::vector<std::pair<int, int>>{{0, 1}, {1, 0}}) {
                const auto* there = cell(r + dr, c + dc);
                if (!there) continue;
                const auto* pair = def.findPair(here->ingot, there->ingot);
                if (!pair) continue;
                out.push_back({"pair", pair->displayName, pair->modifier, pair->value, r, c});
            }
        }
    }
    // Lines: runs of line_length matching ingots along a row or a column
    // (a run of four is one line, not two).
    auto scan = [&](int fixed, bool alongRow) {
        const int length = alongRow ? size.cols : size.rows;
        int runStart = 0;
        std::string runIngot;
        auto flush = [&](int end) {
            const int run = end - runStart;
            if (run >= def.lineLength && !runIngot.empty()) {
                const auto* ingot = def.findIngot(runIngot);
                if (ingot) {
                    const int r = alongRow ? fixed : runStart;
                    const int c = alongRow ? runStart : fixed;
                    out.push_back({"line", ingot->displayName + " line", ingot->modifier,
                                   ingot->value * def.lineBonus, r, c});
                }
            }
        };
        for (int i = 0; i <= length; ++i) {
            const Placement* p = i < length ? (alongRow ? cell(fixed, i) : cell(i, fixed)) : nullptr;
            const std::string id = p ? p->ingot : std::string();
            if (id != runIngot) {
                flush(i);
                runStart = i;
                runIngot = id;
            }
        }
    };
    for (int r = 0; r < size.rows; ++r) scan(r, true);
    for (int c = 0; c < size.cols; ++c) scan(c, false);
    return out;
}

} // namespace wroughtwild::foundry
