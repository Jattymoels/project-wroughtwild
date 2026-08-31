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
    std::map<std::string, int> buildCost;   // material or currency id -> amount
    std::string upgradeFrom;                // empty when built from scratch
    std::map<std::string, int> upgradeCost;
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

// PROVISIONAL: Proposal C of ADR-0002; D-007 remains open. The catalyst
// guarantees the property domain, the magnitude stays a bounded roll.
struct CatalystProcess {
    std::string id;
    std::string displayName;
    std::string catalyst; // item id consumed
    std::string station;
    std::string process;
    std::map<std::string, int> minimumSkill;
    std::string guaranteedProperty;
    int resultTier = 1;
    double minimumRollFractionAtSkill = 0.0;
};

struct CraftingTable {
    std::vector<Station> stations;
    std::vector<Recipe> recipes;
    std::vector<Order> orders;
    std::vector<CatalystProcess> catalystProcesses;
    double salvageReturnFraction = 0.0;
    RepetitionDecay repetitionDecay;

    const Station* findStation(const std::string& id) const;
    const Recipe* findRecipe(const std::string& id) const;
    const Order* findOrder(const std::string& id) const;
    const CatalystProcess* findCatalystProcess(const std::string& id) const;
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

// --- world.json --------------------------------------------------------------

struct PlayerBase {
    double maxLife = 100.0;
    double armourReductionScale = 100.0;
    double resistanceCapPercent = 75.0;
};

struct EnemyDef {
    std::string id;
    std::string displayName;
    double maxLife = 1.0;
    std::string behaviour;
    double damage = 0.0;
    std::string damageType; // "physical" or "fire"
    int attackPeriodRounds = 1;
};

struct GatherSite {
    std::string id;
    std::string displayName;
    std::map<std::string, int> yieldsPerAction;
    double ambushChance = 0.0;
    std::vector<std::string> ambushEnemies;
};

struct WorldTable {
    PlayerBase playerBase;
    std::vector<EnemyDef> enemies;
    std::vector<GatherSite> gatheringSites;
    bool droppedInventoryRecoverable = true;

    const EnemyDef* findEnemy(const std::string& id) const;
    const GatherSite* findSite(const std::string& id) const;
};

// --- trial.json --------------------------------------------------------------

struct BossDef {
    std::string id;
    std::string displayName;
    double maxLife = 1.0;
    double clawDamage = 0.0;
    std::string clawDamageType;
    int clawPeriodRounds = 1;
    double breathDamage = 0.0;
    std::string breathDamageType;
    int breathPeriodRounds = 3;
    int breathTelegraphRounds = 1;
};

struct RoomChoice {
    std::string id;
    std::string displayName;
    std::vector<std::string> encounter; // enemy ids; the boss id means the boss
    std::string reward; // boon_offer | weakness_offer | materials | catalyst | completion
};

struct TrialStage {
    std::vector<RoomChoice> choices;
};

struct TrialTable {
    BossDef boss;
    std::vector<TrialStage> stages;
    int exitAfterStage = -1; // stage index after which the player may bank and leave
    std::map<std::string, int> materialsReward;
    std::string catalystItem;
    std::string completionUnlock;
    bool keepCatalystsOnDeath = true;
    bool loseRunMaterialsOnDeath = true;
};

// --- loading -----------------------------------------------------------------

CraftingTable loadCrafting(const std::string& path);
SkillTable loadSkills(const std::string& path);
ItemTable loadItems(const std::string& path);
BoonTable loadBoons(const std::string& path);
WorldTable loadWorld(const std::string& path);
TrialTable loadTrial(const std::string& path);

// Loads all tuning files from a data/tuning directory.
struct Tuning {
    CraftingTable crafting;
    SkillTable skills;
    ItemTable items;
    BoonTable boons;
    WorldTable world;
    TrialTable trial;
};

Tuning loadAll(const std::string& tuningDirectory);

} // namespace wroughtwild::tuning
