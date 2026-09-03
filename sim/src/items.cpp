#include "wroughtwild/items.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <random>
#include <stdexcept>

namespace wroughtwild::items {

namespace {

// The tier to roll: the requested one, else the highest tier below it, else
// the lowest defined. Lenient on purpose: a wrought roll at tier 2 must not
// fail because one modifier only defines tier 1.
const tuning::ModifierTier* nearestTier(const tuning::ModifierDef& def, int tier) {
    const tuning::ModifierTier* best = nullptr;
    for (const auto& t : def.tiers) {
        if (t.tier == tier) return &t;
        if (t.tier < tier && (!best || t.tier > best->tier)) best = &t;
    }
    if (!best && !def.tiers.empty()) {
        best = &def.tiers.front();
        for (const auto& t : def.tiers)
            if (t.tier < best->tier) best = &t;
    }
    return best;
}

bool startsWith(const std::string& text, const char* prefix) {
    return text.rfind(prefix, 0) == 0;
}

void addStat(StatTotals& totals, const std::string& effectKey, double value) {
    if (effectKey == "add_max_life") totals.maxLife += value;
    else if (effectKey == "add_armour") totals.armour += value;
    else if (effectKey == "add_fire_resistance") totals.fireResistance += value;
    else if (effectKey == "add_area_size") totals.areaSize += value;
}

} // namespace

std::vector<const tuning::ModifierDef*> eligibleModifiers(const tuning::ItemTable& table,
                                                          const tuning::ItemBase& base) {
    std::vector<const tuning::ModifierDef*> eligible;
    for (const auto& def : table.modifiers) {
        bool tagAllowed = std::any_of(def.tags.begin(), def.tags.end(), [&](const std::string& tag) {
            return std::find(base.allowedModifierTags.begin(), base.allowedModifierTags.end(), tag) !=
                   base.allowedModifierTags.end();
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

    std::vector<const tuning::ModifierDef*> pool = eligibleModifiers(table, *base);
    std::mt19937_64 rng(seed);

    int rolls = std::min<int>(propertyCount, static_cast<int>(pool.size()));
    for (int i = 0; i < rolls; ++i) {
        // Weighted pick without replacement.
        double totalWeight = 0.0;
        for (const auto* def : pool) totalWeight += std::max(def->weight, 0.0);
        std::uniform_real_distribution<double> pick(0.0, totalWeight);
        double cursor = pick(rng);
        size_t index = 0;
        for (; index + 1 < pool.size(); ++index) {
            cursor -= std::max(pool[index]->weight, 0.0);
            if (cursor <= 0.0) break;
        }
        const tuning::ModifierDef* def = pool[index];
        pool.erase(pool.begin() + static_cast<long>(index));

        const tuning::ModifierTier* tierDef = nearestTier(*def, tier);
        if (!tierDef) throw std::runtime_error("items: modifier " + def->id + " defines no tiers");

        std::uniform_real_distribution<double> range(tierDef->minimum, tierDef->maximum);
        item.rolledProperties.push_back({def->id, tierDef->tier, range(rng)});
    }
    return item;
}

ItemInstance rollRarityItem(const tuning::ItemTable& table,
                            const std::string& baseId,
                            const std::string& rarityId,
                            int tier,
                            uint64_t seed) {
    const tuning::RarityDef* rarity = table.findRarity(rarityId);
    if (!rarity) throw std::runtime_error("items: unknown rarity " + rarityId);
    std::mt19937_64 rng(seed ^ 0x5DEECE66Dull);
    std::uniform_int_distribution<int> count(rarity->modifiersMin, rarity->modifiersMax);
    ItemInstance item = rollItem(table, baseId, tier, count(rng), seed);
    item.rarity = rarity->id;
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

    const tuning::ModifierDef* def = table.findModifier(process.guaranteedProperty);
    const tuning::ModifierTier* tier = def ? def->findTier(process.resultTier) : nullptr;
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

    // Preservation: replace an existing roll of this modifier only when the
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
    const tuning::ModifierDef* def = table.findModifier(propertyId);
    const tuning::ModifierTier* tierDef = def ? def->findTier(tier) : nullptr;
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

EffectiveRoll effectiveRoll(const tuning::ItemTable& table, const ItemInstance& item,
                            const RolledProperty& rolled) {
    EffectiveRoll out{rolled.tier, rolled.value, false};
    const tuning::ItemBase* base = table.findBase(item.baseId);
    const tuning::ModifierDef* def = table.findModifier(rolled.propertyId);
    if (!base || !def || rolled.tier <= base->tierCap) return out;
    const tuning::ModifierTier* cap = def->findTier(base->tierCap);
    if (!cap) cap = nearestTier(*def, base->tierCap);
    if (!cap) return out;
    out.tier = cap->tier;
    out.value = cap->maximum;
    out.heldBack = true;
    return out;
}

std::vector<const tuning::Breakpoint*> breakpointsFor(const tuning::ModifierDef& def, int tier) {
    std::vector<const tuning::Breakpoint*> out;
    for (const auto& t : def.tiers)
        if (t.tier <= tier)
            for (const auto& bp : t.breakpoints) out.push_back(&bp);
    return out;
}

bool catalystTransfer(const tuning::ItemTable& table, const ItemInstance& source, ItemInstance& target) {
    const tuning::ItemBase* from = table.findBase(source.baseId);
    const tuning::ItemBase* to = table.findBase(target.baseId);
    if (!from || !to || from->slot != to->slot || source.rolledProperties.empty()) return false;
    target.rolledProperties = source.rolledProperties;
    target.rarity = source.rarity;
    return true;
}

StatTotals statTotals(const tuning::ItemTable& table, const ItemInstance& item) {
    StatTotals totals;
    for (const auto& [id, value] : item.implicitProperties) addStat(totals, "add_" + id, value);
    const tuning::ItemBase* base = table.findBase(item.baseId);
    if (base) {
        for (const auto& implicit : base->implicitModifiers) {
            const auto* def = table.findModifier(implicit.id);
            if (def) addStat(totals, def->effectKey, implicit.value);
        }
    }
    for (const auto& rolled : item.rolledProperties) {
        const auto* def = table.findModifier(rolled.propertyId);
        if (!def) continue;
        const EffectiveRoll eff = effectiveRoll(table, item, rolled);
        addStat(totals, def->effectKey, eff.value);
        // A tier's breakpoints that are character stats count on the sheet.
        for (const auto* bp : breakpointsFor(*def, eff.tier))
            if (bp->appliesTo.size() == 1 && bp->appliesTo.front() == "self") addStat(totals, bp->effect, bp->value);
    }
    return totals;
}

std::string formatNumber(double value) {
    char buffer[32];
    if (std::fabs(value - std::round(value)) < 1e-6)
        std::snprintf(buffer, sizeof buffer, "%d", static_cast<int>(std::lround(value)));
    else
        std::snprintf(buffer, sizeof buffer, "%.1f", value);
    return buffer;
}

std::string modifierSentence(const tuning::ModifierDef& def, double value) {
    std::string sentence;
    const bool percent = def.display == "percent";
    // Percentages read as whole numbers: a 0.4003 roll is "40%", not "40.0%".
    const std::string magnitude =
        percent ? formatNumber(std::round(value * 100.0)) + "%" : formatNumber(value);
    if (startsWith(def.effectKey, "add_")) {
        sentence = "+" + magnitude + " " + def.displayName;
    } else if (startsWith(def.effectKey, "increased_")) {
        sentence = magnitude + " increased " + def.displayName;
    } else if (startsWith(def.effectKey, "more_")) {
        sentence = magnitude + " more " + def.displayName;
    } else {
        sentence = def.displayName + " " + magnitude;
    }
    if (!def.isSelf() && !def.appliesToTags.empty()) {
        sentence += " for ";
        for (size_t i = 0; i < def.appliesToTags.size(); ++i) {
            if (i) sentence += "/";
            sentence += def.appliesToTags[i];
        }
        sentence += " skills";
    }
    return sentence;
}

} // namespace wroughtwild::items
