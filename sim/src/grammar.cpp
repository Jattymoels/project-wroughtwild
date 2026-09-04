#include "wroughtwild/grammar.h"

#include <algorithm>
#include <cmath>

namespace wroughtwild::grammar {

namespace {

const tuning::CombatSkillDef* findSkill(const tuning::Tuning& tuning, const std::string& skillId) {
    for (const auto& def : tuning.skills.combatSkills)
        if (def.id == skillId) return &def;
    return nullptr;
}

double skillNumber(const tuning::CombatSkillDef& def, const std::string& key, double fallback) {
    auto it = def.numbers.find(key);
    return it == def.numbers.end() ? fallback : it->second;
}

bool has(const std::vector<std::string>& tags, const std::string& tag) {
    return std::find(tags.begin(), tags.end(), tag) != tags.end();
}

// The tags a packet of `type` resolves its damage against: the skill's
// tags with its element swapped for the packet's, so cold gear scales the
// cold packet and fire gear the fire one, and a spell's mods scale both.
std::vector<std::string> packetTags(const tuning::Tuning& tuning, const std::vector<std::string>& skillTags,
                                    const std::string& type) {
    std::vector<std::string> tags;
    for (const auto& tag : skillTags)
        if (!has(tuning.grammar.damageTypes, tag)) tags.push_back(tag);
    tags.push_back(type);
    return tags;
}

// Buildup for one status: the skill's own payload number (0 when it has
// none - a flat add_* mod matching the tags can still supply one), scaled by
// mods matching the skill's tags, then by the boss resistance rule.
double statusApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                     const std::string& skillId, const char* payloadKey,
                     const char* resolveKey, double bossMultiplier, bool isBoss) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, payloadKey, 0.0);
    double applied = resolve(active, def->resolveTags(), resolveKey, base);
    if (applied <= 0.0) return 0.0;
    if (isBoss) applied *= bossMultiplier;
    return applied;
}

} // namespace

bool modAppliesToTags(const std::vector<std::string>& appliesToTags,
                      const std::vector<std::string>& tags) {
    if (appliesToTags.empty()) return true;
    for (const auto& wanted : appliesToTags)
        if (std::find(tags.begin(), tags.end(), wanted) != tags.end()) return true;
    return false;
}

bool modApplies(const ActiveMod& mod, const std::vector<std::string>& tags) {
    if (!modAppliesToTags(mod.appliesToTags, tags)) return false;
    for (const auto& required : mod.requiresTags)
        if (!has(tags, required)) return false;
    return true;
}

std::string nativeType(const tuning::Tuning& tuning, const std::vector<std::string>& skillTags) {
    for (const auto& type : tuning.grammar.damageTypes)
        if (has(skillTags, type)) return type;
    return tuning.grammar.damageTypes.empty() ? "physical" : tuning.grammar.damageTypes.front();
}

double resolve(const ActiveMods& active,
               const std::vector<std::string>& tags,
               const std::string& key,
               double base) {
    double flat = 0.0;
    double increased = 0.0;
    double more = 1.0;
    const std::string add = "add_" + key;
    const std::string inc = "increased_" + key;
    const std::string mre = "more_" + key;
    for (const auto& mod : active) {
        if (!modApplies(mod, tags)) continue;
        if (mod.effectKey == add) flat += mod.value;
        else if (mod.effectKey == inc) increased += mod.value;
        else if (mod.effectKey == mre) more *= (1.0 + mod.value);
    }
    return (base + flat) * (1.0 + increased) * more;
}

ActiveMods gearMods(const tuning::ItemTable& table, const stats::Equipment& equipment) {
    ActiveMods mods;
    for (const auto& [slot, item] : equipment.slots) {
        const tuning::ItemBase* base = table.findBase(item.baseId);
        if (base) {
            for (const auto& implicit : base->implicitModifiers) {
                const auto* def = table.findModifier(implicit.id);
                if (def) mods.push_back({def->id, def->appliesToTags, def->effectKey, implicit.value, slot});
            }
        }
        for (const auto& rolled : item.rolledProperties) {
            const auto* def = table.findModifier(rolled.propertyId);
            if (!def) continue;
            // The base caps what the roll can say (D-019 held-back rule), and
            // the tier it does say brings its breakpoints with it.
            const items::EffectiveRoll eff = items::effectiveRoll(table, item, rolled);
            mods.push_back({def->id, def->appliesToTags, def->effectKey, eff.value, slot});
            for (const auto* bp : items::breakpointsFor(*def, eff.tier))
                mods.push_back({def->id + "@" + bp->effect, bp->appliesTo, bp->effect, bp->value, slot});
        }
    }
    return mods;
}

double defaultValue(const tuning::ModifierDef& def) {
    const tuning::ModifierTier* first = def.findTier(1);
    if (!first && !def.tiers.empty()) first = &def.tiers.front();
    return first ? first->maximum : 0.0;
}

ActiveMod modAt(const tuning::ItemTable& table, const std::string& modifierId, double value,
                const std::string& source) {
    const auto* def = table.findModifier(modifierId);
    if (!def) return {modifierId, {}, "", 0.0, source};
    return {def->id, def->appliesToTags, def->effectKey, value, source};
}

ActiveMods masteryMods(const tuning::Tuning& tuning, const std::map<std::string, int>& skillUses) {
    ActiveMods mods;
    for (const auto& def : tuning.skills.combatSkills) {
        auto it = skillUses.find(def.id);
        const int uses = it == skillUses.end() ? 0 : it->second;
        for (const auto& perk : def.mastery) {
            if (perk.uses > uses) continue;
            ActiveMod mod = modAt(tuning.items, perk.modifier, perk.value, "mastery:" + def.id);
            mod.appliesToTags = {"skill:" + def.id}; // this skill alone
            mods.push_back(std::move(mod));
        }
    }
    return mods;
}

ActiveMods foundryMods(const tuning::Tuning& tuning, const foundry::State& state, int era) {
    ActiveMods mods;
    const auto plate = foundry::plate(tuning.foundry, era);
    for (const auto& effect : foundry::effects(tuning, state, plate)) {
        ActiveMod mod = modAt(tuning.items, effect.modifier, effect.value, "foundry:" + effect.kind);
        // A reading speaks to that skill alone, and only to the part of it
        // its modifier is about: a Frost support scales the orb's cold and
        // never the fire an Ember support adds to the same orb.
        if (!effect.skill.empty()) mod.requiresTags = {"skill:" + effect.skill};
        // A form speaks to the whole skill it feeds, or to the one packet it
        // names, whatever its modifier's applies_to says (Scald's ignite
        // lands on a cold orb).
        if (effect.kind == "form") {
            mod.appliesToTags.clear();
            if (!effect.packet.empty()) mod.appliesToTags = {effect.packet};
        }
        mods.push_back(std::move(mod));
    }
    return mods;
}

int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0;
    double base = skillNumber(*def, "fork_count", 0.0);
    return static_cast<int>(std::floor(resolve(active, def->resolveTags(), "fork", base)));
}

double forkDamageFraction(const tuning::Tuning& tuning, const std::string& skillId,
                          int generation) {
    const auto* def = findSkill(tuning, skillId);
    if (!def || generation <= 0) return 1.0;
    double fraction = skillNumber(*def, "fork_damage_fraction", 1.0);
    return std::pow(fraction, generation);
}

double chillApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss) {
    return statusApplied(tuning, active, skillId, "chill_buildup", "chill_buildup",
                         tuning.grammar.chill.bossBuildupMultiplier, isBoss);
}

double igniteApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                     const std::string& skillId, bool isBoss) {
    return statusApplied(tuning, active, skillId, "ignite_buildup", "ignite_buildup",
                         tuning.grammar.ignite.bossBuildupMultiplier, isBoss);
}

double bleedApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss) {
    return statusApplied(tuning, active, skillId, "bleed_buildup", "bleed_buildup",
                         tuning.grammar.bleed.bossBuildupMultiplier, isBoss);
}

DotStatus igniteStatus(const tuning::Tuning& tuning, const ActiveMods& active) {
    const auto& cfg = tuning.grammar.ignite;
    DotStatus status;
    status.buildupMax = cfg.buildupMax;
    status.decayPerS = cfg.decayPerS;
    status.durationS = resolve(active, {"fire", "ignite"}, "ignite_duration", cfg.durationS);
    status.damagePerS = resolve(active, {"fire", "ignite"}, "burn_damage", cfg.damagePerS);
    return status;
}

DotStatus bleedStatus(const tuning::Tuning& tuning, const ActiveMods& active) {
    const auto& cfg = tuning.grammar.bleed;
    DotStatus status;
    status.buildupMax = cfg.buildupMax;
    status.decayPerS = cfg.decayPerS;
    status.durationS = resolve(active, {"physical", "bleed"}, "bleed_duration", cfg.durationS);
    status.damagePerS = resolve(active, {"physical", "bleed"}, "bleed_damage", cfg.damagePerS);
    status.movingMultiplier = cfg.movingMultiplier;
    return status;
}

Hit skillHit(const tuning::Tuning& tuning, const ActiveMods& active,
             const std::string& skillId) {
    return skillHit(tuning, active, skillId, {});
}

Hit skillHit(const tuning::Tuning& tuning, const ActiveMods& active,
             const std::string& skillId, const std::vector<std::string>& targetStatuses) {
    Hit hit;
    const auto* def = findSkill(tuning, skillId);
    if (!def) return hit;
    const double base = skillNumber(*def, "base_damage", 0.0);
    if (base <= 0.0) return hit; // a movement skill has no hit
    const auto tags = def->resolveTags();
    const std::string native = nativeType(tuning, tags);
    // A form's "an ignited enemy takes 20% more" (D-023): every packet is
    // multiplied by the resolved damage_vs_<status> for each status the
    // struck mob carries, against the packet's own tags.
    auto against = [&](const std::vector<std::string>& packetTags_, double damage) {
        for (const auto& status : targetStatuses) damage *= resolve(active, packetTags_, "damage_vs_" + status, 1.0);
        return damage;
    };
    hit.push_back({native, against(tags, resolve(active, tags, "damage", base)), false});
    // The added-element lane (D-023 slice 2): each other type the plate
    // adds is its own packet, the same fraction of the base hit the
    // same-element lane would have increased it by, scaled by its own
    // type's gear. Where the boil and scald builds start.
    for (const auto& type : tuning.grammar.damageTypes) {
        if (type == native) continue;
        const double fraction = resolve(active, tags, "as_" + type, 0.0);
        if (fraction <= 0.0) continue;
        const auto ptags = packetTags(tuning, tags, type);
        hit.push_back({type, against(ptags, resolve(active, ptags, "damage", base * fraction)), true});
    }
    return hit;
}

double skillDamage(const tuning::Tuning& tuning, const ActiveMods& active,
                   const std::string& skillId) {
    double total = 0.0;
    for (const auto& packet : skillHit(tuning, active, skillId)) total += packet.damage;
    return total;
}

double skillLifeOnKill(const tuning::Tuning& tuning, const ActiveMods& active,
                       const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    return std::max(0.0, resolve(active, def->resolveTags(), "life_on_kill", 0.0));
}

double skillCastArmour(const tuning::Tuning& tuning, const ActiveMods& active,
                       const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    return std::max(0.0, resolve(active, def->resolveTags(), "armour_on_cast", 0.0));
}

double wardMultiplier(const tuning::Tuning& tuning, const ActiveMods& active,
                      const std::vector<std::string>& carriedStatuses) {
    double multiplier = 1.0;
    if (carriedStatuses.empty()) return multiplier;
    for (const auto& def : tuning.skills.combatSkills) {
        const double ward = resolve(active, def.resolveTags(), "status_ward", 0.0);
        if (ward <= 0.0) continue;
        // The skill's status is whichever it applies right now: its own
        // payload, or one a modifier gave it.
        const bool carried = (has(carriedStatuses, "chill") && chillApplied(tuning, active, def.id, false) > 0.0) ||
                             (has(carriedStatuses, "ignite") && igniteApplied(tuning, active, def.id, false) > 0.0) ||
                             (has(carriedStatuses, "bleed") && bleedApplied(tuning, active, def.id, false) > 0.0);
        if (carried) multiplier *= std::max(0.0, 1.0 - ward);
    }
    return multiplier;
}

double skillReach(const tuning::Tuning& tuning, const ActiveMods& active,
                  const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 1.0;
    return resolve(active, def->resolveTags(), "reach", 1.0);
}

double skillCooldownSeconds(const tuning::Tuning& tuning, const ActiveMods& active,
                            const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, "cooldown_seconds", 0.0);
    double recovery = resolve(active, def->resolveTags(), "cooldown_recovery", 1.0);
    return recovery > 0.0 ? base / recovery : base;
}

ShatterParams shatterFor(const tuning::Tuning& tuning, const ActiveMods& active,
                         const std::string& skillId) {
    ShatterParams params;
    const auto& hook = tuning.grammar.shatter;
    const auto* def = findSkill(tuning, skillId);
    if (!def || !modAppliesToTags(hook.triggerTags, def->resolveTags()) || hook.triggerTags.empty())
        return params;
    params.enabled = true;
    params.novaDamage = hook.novaDamage;
    params.novaDamageType = hook.novaDamageType;
    params.executesFrozen = hook.executesFrozen;
    params.executesBoss = hook.executesBoss;
    // Shatter mods target the "shatter" tag by convention.
    params.novaRadiusM = resolve(active, {"shatter", "cold"}, "shatter_radius", hook.novaRadiusM);
    return params;
}

ProliferateParams proliferateFor(const tuning::Tuning& tuning, const ActiveMods& active) {
    ProliferateParams params;
    const auto& hook = tuning.grammar.proliferate;
    params.enabled = hook.enabled;
    // Proliferate mods target the "proliferate" tag by convention.
    params.radiusM = resolve(active, {"proliferate", "fire"}, "proliferate_radius", hook.radiusM);
    params.spreadBuildup = resolve(active, {"proliferate", "fire", "ignite"}, "proliferate_buildup",
                                   hook.spreadBuildup);
    return params;
}

} // namespace wroughtwild::grammar
