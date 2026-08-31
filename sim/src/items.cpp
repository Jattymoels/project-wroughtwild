#include "wroughtwild/items.h"

#include <algorithm>
#include <random>
#include <stdexcept>

namespace wroughtwild::items {

std::vector<const tuning::PropertyDef*> eligibleProperties(const tuning::ItemTable& table,
                                                           const tuning::ItemBase& base) {
    std::vector<const tuning::PropertyDef*> eligible;
    for (const auto& def : table.propertyDefinitions) {
        bool tagAllowed = std::any_of(def.tags.begin(), def.tags.end(), [&](const std::string& tag) {
            return std::find(base.allowedPropertyTags.begin(), base.allowedPropertyTags.end(), tag) !=
                   base.allowedPropertyTags.end();
        });
        if (tagAllowed) eligible.push_back(&def);
    }
    return eligible;
}

ItemInstance rollItem(const tuning::ItemTable& table,
                      const std::string& baseId,
                      int tier,
                      int propertyCount,
                      uint64_t seed) {
    const tuning::ItemBase* base = table.findBase(baseId);
    if (!base) throw std::runtime_error("items: unknown item base " + baseId);

    ItemInstance item;
    item.baseId = baseId;
    item.implicitProperties = base->implicitProperties;

    std::vector<const tuning::PropertyDef*> pool = eligibleProperties(table, *base);
    std::mt19937_64 rng(seed);

    int rolls = std::min<int>(propertyCount, static_cast<int>(pool.size()));
    for (int i = 0; i < rolls; ++i) {
        std::uniform_int_distribution<size_t> pick(0, pool.size() - 1);
        size_t index = pick(rng);
        const tuning::PropertyDef* def = pool[index];
        pool.erase(pool.begin() + index);

        const tuning::PropertyTier* tierDef = nullptr;
        for (const auto& t : def->tiers)
            if (t.tier == tier) tierDef = &t;
        if (!tierDef)
            throw std::runtime_error("items: property " + def->id + " has no tier " +
                                     std::to_string(tier));

        std::uniform_real_distribution<double> range(tierDef->minimum, tierDef->maximum);
        item.rolledProperties.push_back({def->id, tier, range(rng)});
    }
    return item;
}

double propertyTotal(const ItemInstance& item, const std::string& propertyId) {
    double total = 0.0;
    auto implicitIt = item.implicitProperties.find(propertyId);
    if (implicitIt != item.implicitProperties.end()) total += implicitIt->second;
    for (const auto& rolled : item.rolledProperties)
        if (rolled.propertyId == propertyId) total += rolled.value;
    return total;
}

} // namespace wroughtwild::items
