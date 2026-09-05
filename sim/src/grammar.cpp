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
    double applied = resolve(active, effectiveTags(tuning, active, skillId), resolveKey, base);
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

std::vector<std::string> effectiveTags(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    const auto* skill = findSkill(tuning, skillId);
    if (!skill) return {};
    auto tags = skill->resolveTags();
    const auto base = tags; // grants never recursively make other grants eligible
    const std::string prefix = "add_grant_tag_";
    for (const auto& mod : active) {
        if (mod.effectKey.compare(0, prefix.size(), prefix) || mod.value <= 0 || !modApplies(mod, base)) continue;
        const auto tag = mod.effectKey.substr(prefix.size());
        if (tag == "projectile" && skill->delivery != "projectile" && skill->delivery != "strike" && skill->delivery != "cone") continue;
        if (!has(tags, tag)) tags.push_back(tag);
    }
    return tags;
}

std::map<std::string, double> skillMutation(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    std::map<std::string, double> result;
    const auto* skill = findSkill(tuning, skillId);
    if (!skill) return result;
    const auto tags = effectiveTags(tuning, active, skillId);
    for (const auto& [key, cap] : tuning.foundry.mutationLimits)
        result[key] = std::clamp(resolve(active, tags, "foundry_" + key, 0.0), 0.0, cap);
    // The burn belongs to this skill. Its acquired tags open gear scaling,
    // but cold DAMAGE never scales a fire burn: damage packets keep their type.
    auto burnTags = packetTags(tuning, tags, "fire");
    if (!has(burnTags, "ignite")) burnTags.push_back("ignite");
    result["burn_dps"] = std::max(0.0, resolve(active, burnTags, "burn_damage", tuning.grammar.ignite.damagePerS));
    result["burn_seconds"] = std::max(0.0, resolve(active, burnTags, "ignite_duration", tuning.grammar.ignite.durationS));
    // Steam is a small secondary hit with two independently scaled packets.
    // Its delivery stays local to the plume, not a conversion of the main hit.
    for (const std::string type : {"fire", "cold"}) {
        auto steamTags = packetTags(tuning, tags, type);
        if (!has(steamTags, "area")) steamTags.push_back("area");
        const double base = skillNumber(*skill, "base_damage", 0.0);
        result["steam_" + type + "_damage"] = base <= 0 ? 0 :
            std::max(0.0, resolve(active, steamTags, "damage", base)) * result["steam_fraction"] * 0.5;
    }
    // Authored secondary buildup scales with increased/more ignition gear,
    // without paying the main hit's flat buildup a second time.
    for (const std::string hook : {"fuse", "ember_hop"}) {
        const double base = result[hook + "_buildup"];
        result[hook + "_ignite"] = std::max(0.0,
            resolve(active, burnTags, "ignite_buildup", base) - resolve(active, burnTags, "ignite_buildup", 0.0));
        result[hook + "_ignite_boss"] = result[hook + "_ignite"] * tuning.grammar.ignite.bossBuildupMultiplier;
    }
    auto rakeTags = packetTags(tuning, tags, "fire");
    if (!has(rakeTags, "area")) rakeTags.push_back("area");
    const double baseHit = skillNumber(*skill, "base_damage", 0.0);
    result["rake_fire_damage"] = baseHit <= 0 ? 0 :
        std::max(0.0, resolve(active, rakeTags, "damage", baseHit)) * result["rake_fraction"];
    // Wildfire is a single propagation hop, not another skill projectile.
    auto hopTags = burnTags;
    if (!has(hopTags, "proliferate")) hopTags.push_back("proliferate");
    result["ember_hop_range"] = result["ember_hop_buildup"] <= 0 ? 0 :
        std::max(0.0, resolve(active, hopTags, "proliferate_radius",
            tuning.foundry.mutationLimits.at("ember_hop_radius"))) * skillReach(tuning, active, skillId);
    auto coldTags = packetTags(tuning, tags, "cold");
    if (!has(coldTags, "chill")) coldTags.push_back("chill");
    for (const std::string hook : {"rime_ring", "stillwater"}) {
        const double base = hook == "rime_ring" ? result["rime_ring_buildup"] :
            (result["stillwater_fraction"] > 0 ? tuning.foundry.mutationLimits.at("stillwater_chill") : 0);
        result[hook + "_chill"] = std::max(0.0, resolve(active, coldTags, "chill_buildup", base) - resolve(active, coldTags, "chill_buildup", 0));
        result[hook + "_chill_boss"] = result[hook + "_chill"] * tuning.grammar.chill.bossBuildupMultiplier;
    }
    if (!has(coldTags, "area")) coldTags.push_back("area");
    for (const std::string hook : {"rime_edge", "stillwater"})
        result[hook + "_cold_damage"] = baseHit <= 0 ? 0 : std::max(0.0, resolve(active, coldTags, "damage", baseHit)) * result[hook + "_fraction"];
    const auto originalType = nativeType(tuning, skill->resolveTags());
    for (const auto& type : tuning.grammar.damageTypes) {
        auto echoTags = packetTags(tuning, tags, type);
        if (!has(echoTags, "area")) echoTags.push_back("area");
        result["afterfield_" + type + "_damage"] = baseHit <= 0 || type != originalType ? 0 :
            std::max(0.0, resolve(active, echoTags, "damage", baseHit)) * result["afterfield_fraction"];
    }
    return result;
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
            for (const auto* bp : items::breakpointsFor(*def, eff.tier, rolled.crafted))
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
        for (const auto& perk : def.legacyMastery) {
            if (perk.uses > uses) continue;
            ActiveMod mod = modAt(tuning.items, perk.modifier, perk.value, "mastery:" + def.id);
            mod.appliesToTags = {"skill:" + def.id}; // this skill alone
            mods.push_back(std::move(mod));
        }
    }
    return mods;
}

ActiveMods earnedMasteryMods(const tuning::Tuning& tuning, const std::map<std::string, std::vector<tuning::MasteryPerk>>& earned) {
    ActiveMods mods;
    for (const auto& [skill, perks] : earned) for (const auto& perk : perks) {
        auto mod = modAt(tuning.items, perk.modifier, perk.value, "mastery:" + skill);
        mod.appliesToTags = {"skill:" + skill}; mods.push_back(mod);
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
        // A rail's rule scoped by a skill tag speaks to every skill with it
        // (Quarry: your projectiles), whatever the modifier's applies_to.
        if (effect.kind == "rail" && !effect.packet.empty()) mod.appliesToTags = {effect.packet};
        mods.push_back(std::move(mod));
    }
    return mods;
}

int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0;
    double base = skillNumber(*def, "fork_count", 0.0);
    return static_cast<int>(std::floor(resolve(active, effectiveTags(tuning, active, skillId), "fork", base)));
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
    const auto tags = effectiveTags(tuning, active, skillId);
    const std::string native = nativeType(tuning, def->resolveTags());
    // A form's "an ignited enemy takes 20% more" (D-023): every packet is
    // multiplied by the resolved damage_vs_<status> for each status the
    // struck mob carries, against the packet's own tags.
    auto against = [&](const std::vector<std::string>& packetTags_, double damage) {
        for (const auto& status : targetStatuses) damage *= resolve(active, packetTags_, "damage_vs_" + status, 1.0);
        return damage;
    };
    const auto nativeTags = packetTags(tuning, tags, native);
    hit.push_back({native, against(nativeTags, resolve(active, nativeTags, "damage", base)), false});
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
    return std::max(0.0, resolve(active, effectiveTags(tuning, active, skillId), "life_on_kill", 0.0));
}

double skillCastArmour(const tuning::Tuning& tuning, const ActiveMods& active,
                       const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    // The skill's own swing armour is the base the reading adds to.
    return std::max(0.0, resolve(active, effectiveTags(tuning, active, skillId), "armour_on_cast", skillNumber(*def, "swing_armour", 0.0)));
}

double skillSwingSeconds(const tuning::Tuning& tuning, const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    return def ? std::max(0.0, skillNumber(*def, "swing_seconds", 0.0)) : 0.0;
}

double skillStagger(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId, bool isBoss) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    const double seconds = std::max(0.0, resolve(active, effectiveTags(tuning, active, skillId), "stagger", skillNumber(*def, "stagger_seconds", 0.0)));
    return isBoss ? seconds * tuning.grammar.melee.bossStaggerMultiplier : seconds;
}

double skillPush(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId, bool isBoss) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    const double metres = std::max(0.0, resolve(active, effectiveTags(tuning, active, skillId), "push", skillNumber(*def, "push_m", 0.0)));
    return isBoss ? metres * tuning.grammar.melee.bossPushMultiplier : metres;
}

namespace {
double skillNumberResolved(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId,
                           const std::string& key) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    return std::max(0.0, resolve(active, effectiveTags(tuning, active, skillId), key, skillNumber(*def, key, 0.0)));
}
} // namespace

int skillEchoEvery(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    const auto tags = effectiveTags(tuning, active, skillId);
    int every = 0;
    for (const auto& mod : active)
        if (mod.effectKey == "add_echo_every" && mod.value > 0 && modApplies(mod, tags))
            every = every == 0 ? static_cast<int>(mod.value) : std::min(every, static_cast<int>(mod.value));
    return every;
}

bool skillQuenches(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "quench") > 0.0;
}

double skillNovaChill(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "nova_chill");
}

double skillSear(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "sear");
}

bool skillBrittle(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "brittle") > 0.0;
}

double skillArc(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "arc");
}

double skillLifeOnHit(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "life_on_hit");
}

int skillProjectiles(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 1;
    const double base = skillNumber(*def, "projectiles", 1.0);
    return std::max(1, static_cast<int>(std::floor(resolve(active, effectiveTags(tuning, active, skillId), "projectiles", base))));
}

int skillPierce(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return static_cast<int>(std::floor(skillNumberResolved(tuning, active, skillId, "pierce")));
}

double skillRefundOnKill(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return std::min(1.0, skillNumberResolved(tuning, active, skillId, "refund_on_kill"));
}

double skillHasteOnKill(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId) {
    return skillNumberResolved(tuning, active, skillId, "haste_on_kill");
}

std::vector<std::string> skillTriggers(const tuning::Tuning& tuning, const ActiveMods& active,
                                       const std::string& skillId) {
    std::vector<std::string> triggers;
    if (chillApplied(tuning, active, skillId, false) > 0.0) triggers.push_back("freeze");
    if (igniteApplied(tuning, active, skillId, false) > 0.0) triggers.push_back("ignite");
    if (bleedApplied(tuning, active, skillId, false) > 0.0) triggers.push_back("bleed");
    return triggers;
}

std::vector<std::string> linkedCasts(const tuning::Tuning& tuning, const ActiveMods& active,
                                     const foundry::State& state, const foundry::Plate& plate,
                                     const std::string& skillId, const std::string& trigger) {
    std::vector<std::string> casts;
    if (!has(skillTriggers(tuning, active, skillId), trigger)) return casts;
    for (const auto& link : foundry::links(tuning, state, plate)) {
        const std::string other = link.first == skillId ? link.second : link.second == skillId ? link.first : std::string();
        if (!other.empty() && !has(casts, other)) casts.push_back(other);
    }
    return casts;
}

double wardMultiplier(const tuning::Tuning& tuning, const ActiveMods& active,
                      const std::vector<std::string>& carriedStatuses) {
    double multiplier = 1.0;
    if (carriedStatuses.empty()) return multiplier;
    for (const auto& def : tuning.skills.combatSkills) {
        const double ward = resolve(active, effectiveTags(tuning, active, def.id), "status_ward", 0.0);
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
    return resolve(active, effectiveTags(tuning, active, skillId), "reach", 1.0);
}

double skillCooldownSeconds(const tuning::Tuning& tuning, const ActiveMods& active,
                            const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, "cooldown_seconds", 0.0);
    double recovery = resolve(active, effectiveTags(tuning, active, skillId), "cooldown_recovery", 1.0);
    return recovery > 0.0 ? base / recovery : base;
}

ShatterParams shatterFor(const tuning::Tuning& tuning, const ActiveMods& active,
                         const std::string& skillId) {
    ShatterParams params;
    const auto& hook = tuning.grammar.shatter;
    const auto* def = findSkill(tuning, skillId);
    if (!def || !modAppliesToTags(hook.triggerTags, effectiveTags(tuning, active, skillId)) || hook.triggerTags.empty())
        return params;
    params.enabled = true;
    params.novaDamage = hook.novaDamage;
    params.novaDamageType = hook.novaDamageType;
    params.executesFrozen = hook.executesFrozen;
    params.executesBoss = hook.executesBoss;
    // Shatter mods target the "shatter" tag by convention.
    auto novaTags = effectiveTags(tuning, active, skillId);
    for (const auto& tag : {std::string("shatter"), hook.novaDamageType})
        if (!has(novaTags, tag)) novaTags.push_back(tag);
    params.novaRadiusM = resolve(active, novaTags, "shatter_radius", hook.novaRadiusM);
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
