#pragma once

// Typed views over data/tuning/*.json. Loading is strict: a missing required
// field throws rather than defaulting, so tuning mistakes surface in tests.

#include <map>
#include <string>
#include <vector>

namespace wroughtwild::tuning {

// --- crafting.json -----------------------------------------------------------

struct Station {
    std::string id;
    std::string displayName;
    int tier = 0;
    std::vector<std::string> supportedProcesses;
};

struct Recipe {
    std::string id;
    std::string displayName;
    std::string station;
    std::map<std::string, int> minimumSkill; // skill id -> level
    std::map<std::string, int> inputs;       // material id -> count
    std::map<std::string, int> outputs;      // item id -> count
    int baseSkillXp = 0;
    std::vector<std::string> useCategories;
};

struct Order {
    std::string id;
    std::string displayName;
    std::map<std::string, int> requiredOutputs;
    std::map<std::string, int> rewards;      // reward id -> amount
    std::string worldEffect;
};

struct RepetitionDecay {
    bool enabled = false;
    int fullXpRepetitions = 0;
    double minimumMultiplier = 1.0;
    bool orderCraftingIgnoresDecay = false;
};

struct CraftingTable {
    std::vector<Station> stations;
    std::vector<Recipe> recipes;
    std::vector<Order> orders;
    double salvageReturnFraction = 0.0;
    RepetitionDecay repetitionDecay;

    const Station* findStation(const std::string& id) const;
    const Recipe* findRecipe(const std::string& id) const;
    const Order* findOrder(const std::string& id) const;
};

// --- skills.json -------------------------------------------------------------

struct CraftSkillDef {
    std::string id;
    std::string displayName;
    int maximumPrototypeLevel = 1;
    std::vector<int> xpRequiredByLevel; // cumulative XP needed to reach level i+1
};

struct CombatSkillDef {
    std::string id;
    std::string displayName;
    std::vector<std::string> tags;
    std::map<std::string, double> numbers; // remaining numeric fields verbatim
};

struct SkillTable {
    std::vector<CraftSkillDef> craftSkills;
    std::vector<CombatSkillDef> combatSkills;

    const CraftSkillDef* findCraftSkill(const std::string& id) const;
};

// --- items.json --------------------------------------------------------------

struct PropertyTier {
    int tier = 0;
    double minimum = 0.0;
    double maximum = 0.0;
};

struct PropertyDef {
    std::string id;
    std::string displayName;
    std::vector<std::string> tags;
    std::vector<PropertyTier> tiers;
};

struct ItemBase {
    std::string id;
    std::string displayName;
    std::string material;
    std::map<std::string, double> implicitProperties;
    std::vector<std::string> allowedPropertyTags;
};

struct ItemTable {
    std::vector<PropertyDef> propertyDefinitions;
    std::vector<ItemBase> itemBases;

    const ItemBase* findBase(const std::string& id) const;
};

// --- boons.json --------------------------------------------------------------

struct BoonEffect {
    std::string operation;
    std::map<std::string, double> parameters;
};

struct BoonDef {
    std::string id;
    std::string displayName;
    std::vector<std::string> requiresAnyTags;
    std::string requiresWeakness; // empty when unconditional
    std::vector<BoonEffect> effects;
    std::string designPurpose;
};

struct WeaknessDef {
    std::string id;
    std::string displayName;
    std::vector<BoonEffect> effects;
    double baseRewardMultiplier = 1.0;
};

struct OfferRules {
    int optionsPerOffer = 3;
    bool allowIncompatibleOptions = false;
    int minimumUnweightedOptionCount = 0;
};

struct BoonTable {
    std::vector<BoonDef> boons;
    std::vector<WeaknessDef> weaknesses;
    OfferRules offerRules;

    const BoonDef* findBoon(const std::string& id) const;
};

// --- loading -----------------------------------------------------------------

CraftingTable loadCrafting(const std::string& path);
SkillTable loadSkills(const std::string& path);
ItemTable loadItems(const std::string& path);
BoonTable loadBoons(const std::string& path);

// Loads all four files from a data/tuning directory.
struct Tuning {
    CraftingTable crafting;
    SkillTable skills;
    ItemTable items;
    BoonTable boons;
};

Tuning loadAll(const std::string& tuningDirectory);

} // namespace wroughtwild::tuning
