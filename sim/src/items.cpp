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

TemperResult catalystTemper(const tuning::ItemTable& table,
                            const tuning::CatalystProcess& process,
                            ItemInstance& item,
                            int craftSkillLevel,
                            uint64_t seed) {
    TemperResult result;

    for (const auto& [skillId, level] : process.minimumSkill) {
        (void)skillId;
        if (craftSkillLevel < level) {
            result.skillTooLow = true;
            return result;
        }
    }

    const tuning::PropertyDef* def = nullptr;
    for (const auto& d : table.propertyDefinitions)
        if (d.id == process.guaranteedProperty) def = &d;
    const tuning::PropertyTier* tier = nullptr;
    if (def)
        for (const auto& t : def->tiers)
            if (t.tier == process.resultTier) tier = &t;
    if (!tier) {
        result.wrongTier = true;
        return result;
    }

    // Skill raises the floor of the roll: mastery buys consistency.
    double floorValue =
        tier->minimum + process.minimumRollFractionAtSkill * (tier->maximum - tier->minimum);
    std::mt19937_64 rng(seed);
    std::uniform_real_distribution<double> range(floorValue, tier->maximum);
    double rolled = range(rng);

    // Preservation: replace an existing roll of this property only when the
    // new roll is strictly better; the catalyst can never make an item worse.
    for (auto& existing : item.rolledProperties) {
        if (existing.propertyId != process.guaranteedProperty) continue;
        result.previousValue = existing.value;
        if (rolled > existing.value) {
            existing.tier = process.resultTier;
            existing.value = rolled;
            result.rolledValue = rolled;
        } else {
            result.rolledValue = existing.value;
        }
        result.applied = true;
        return result;
    }

    item.rolledProperties.push_back({process.guaranteedProperty, process.resultTier, rolled});
    result.rolledValue = rolled;
    result.applied = true;
    return result;
}

bool basicTemper(const tuning::ItemTable& table,
                 ItemInstance& item,
                 const std::string& propertyId,
                 int tier) {
    const tuning::PropertyTier* tierDef = nullptr;
    for (const auto& def : table.propertyDefinitions)
        if (def.id == propertyId)
            for (const auto& t : def.tiers)
                if (t.tier == tier) tierDef = &t;
    if (!tierDef) return false;

    double value = (tierDef->minimum + tierDef->maximum) / 2.0;
    for (auto& existing : item.rolledProperties) {
        if (existing.propertyId != propertyId) continue;
        if (value > existing.value) {
            existing.tier = tier;
            existing.value = value;
        }
        return true;
    }
    item.rolledProperties.push_back({propertyId, tier, value});
    return true;
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
