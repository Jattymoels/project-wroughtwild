#pragma once

// Typed views over data/tuning/*.json. Loading is strict: a missing required
// field throws rather than defaulting, so tuning mistakes surface in tests.

#include <cstdint>
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
    std::string kitItem; // placing this crafted item founds the station ("" = none)
};

struct Recipe {
    std::string id;
    std::string displayName;
    std::string station; // "" = hand-craftable anywhere, no facility or fuel gate
    std::map<std::string, int> minimumSkill; // skill id -> level
    std::map<std::string, int> inputs;       // material id -> count
    std::map<std::string, int> outputs;      // item id -> count
    int baseSkillXp = 0;
    int fuelCost = 0; // fuel value burned by the station per craft
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

// Non-catalyst tempering: the deterministic baseline (tier midpoint) route.
struct BasicTemper {
    std::string process = "basic_temper"; // a station must list this process
    std::string property = "fire_resistance";
    int tier = 1;
};

struct CraftingTable {
    std::vector<Station> stations;
    std::vector<Recipe> recipes;
    std::vector<Order> orders;
    std::vector<CatalystProcess> catalystProcesses;
    BasicTemper basicTemper;
    double salvageReturnFraction = 0.0;
    RepetitionDecay repetitionDecay;
    std::map<std::string, int> fuels; // item id -> fuel value per unit

    const Station* findStation(const std::string& id) const;
    const Recipe* findRecipe(const std::string& id) const;
    const Order* findOrder(const std::string& id) const;
    const CatalystProcess* findCatalystProcess(const std::string& id) const;
    // Station founded by placing kit item id, or nullptr.
    const Station* findStationForKit(const std::string& kitItemId) const;
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

struct LootEntry {
    std::string item;
    int minCount = 1;
    int maxCount = 1;
    double chance = 1.0;
};

struct EnemyDef {
    std::string id;
    std::string displayName;
    double maxLife = 1.0;
    std::string behaviour;
    double damage = 0.0;
    std::string damageType; // "physical" or "fire"
    int attackPeriodRounds = 1;
    std::vector<LootEntry> loot;
};

struct GatherSite {
    std::string id;
    std::string displayName;
    std::map<std::string, int> yieldsPerAction;
    double ambushChance = 0.0;
    std::vector<std::string> ambushEnemies;
    std::string ambushRemovedByWorldEffect; // empty when ambushes are permanent
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

// --- construction.json -------------------------------------------------------

struct ShapeDef {
    std::string id;
    std::string displayName;
    int materialCost = 1; // units of whichever material family the player selected
    double sizeM[3] = {1.0, 1.0, 1.0};
    std::string requiresWorldEffect; // empty = available from the start
};

struct ConstructionTable {
    double gridSizeMetres = 1.0;
    double placementRangeMetres = 10.0;
    double removalRefundFraction = 0.0;
    std::vector<ShapeDef> shapes;

    const ShapeDef* findShape(const std::string& id) const;
};

// --- combat_realtime.json ----------------------------------------------------
// Time-and-space tunables for the real-time engine host (ADR-0003). Numbers
// that affect damage, life or mitigation never live here.

struct BehaviourRealtime {
    double moveSpeedMps = 0.0;
    double attackRangeM = 0.0;
    double preferredDistanceM = 0.0; // 0 = close to melee range
    double aggroRangeM = 0.0;
    double windupSeconds = 0.0;
};

struct BossRealtime {
    double moveSpeedMps = 0.0;
    double clawRangeM = 0.0;
    double clawWindupSeconds = 0.0;
    double breathRangeM = 0.0;
    double breathConeDegrees = 0.0;
    double breathTelegraphSeconds = 0.0;
};

struct RealtimeTable {
    double roundSeconds = 1.0; // sim rounds -> seconds
    double playerMoveSpeedMps = 0.0;
    double playerMeleeReachM = 0.0;
    std::map<std::string, BehaviourRealtime> behaviours; // keyed by EnemyDef::behaviour
    BossRealtime boss;
    double dashInvulnerableSeconds = 0.0;
    double dashDurationSeconds = 0.0;

    const BehaviourRealtime* findBehaviour(const std::string& id) const;
};

// --- worldgen.json -----------------------------------------------------------
// Seed-generated bounded sandpit (D-003): terrain character, biome rules,
// node yields and the guaranteed-content rules every valid seed must satisfy.

struct MapParams {
    int widthCells = 96;
    int heightCells = 96;
    double cellSizeM = 1.0;
    int baseHeight = 1;
    int heightScale = 6;
    double heightFrequency = 0.03;
    int heightOctaves = 3;
    double moistureFrequency = 0.015;
};

struct BiomeDef {
    std::string id;
    std::string displayName;
    std::string surface; // visual key: grass | forest_floor | rock | ash
    // Matching rules; first biome whose set bounds all pass wins, the last
    // biome in the list is the fallback. -1 / 2.0 mean "unset".
    int heightMin = -1;
    int heightMax = -1;
    double moistureMin = -1.0;
    double moistureMax = 2.0;
    std::map<std::string, double> nodeDensity; // node type -> per-cell chance
    double packDensity = 0.0;
    std::vector<std::vector<std::string>> packs; // possible pack compositions
};

struct NodeTypeDef {
    std::string id;
    std::string displayName;
    std::string materialFamily;
    int units = 10;
    int unitsPerHarvest = 2;
    std::string visual;
};

struct WorldgenGuarantees {
    std::string spawnBiome;
    double spawnClearRadiusM = 8.0;
    double nearRadiusM = 40.0;
    std::map<std::string, int> minNodesNear; // node type -> minimum count
    std::string gateBiome;
    double gateMinDistanceM = 45.0;
    double packMinDistanceFromSpawnM = 20.0;
};

struct WorldgenTable {
    uint64_t defaultSeed = 1;
    MapParams map;
    std::vector<BiomeDef> biomes;
    std::map<std::string, NodeTypeDef> nodeTypes;
    WorldgenGuarantees guarantees;

    const BiomeDef* findBiome(const std::string& id) const;
};

// --- loading -----------------------------------------------------------------

CraftingTable loadCrafting(const std::string& path);
WorldgenTable loadWorldgen(const std::string& path);
ConstructionTable loadConstruction(const std::string& path);
RealtimeTable loadRealtime(const std::string& path);
SkillTable loadSkills(const std::string& path);
ItemTable loadItems(const std::string& path);
BoonTable loadBoons(const std::string& path);
WorldTable loadWorld(const std::string& path);
TrialTable loadTrial(const std::string& path);

// Loads all tuning files from a data/tuning directory.
struct Tuning {
    CraftingTable crafting;
    ConstructionTable construction;
    SkillTable skills;
    ItemTable items;
    BoonTable boons;
    WorldTable world;
    TrialTable trial;
    RealtimeTable realtime;
    WorldgenTable worldgen;
};

Tuning loadAll(const std::string& tuningDirectory);

} // namespace wroughtwild::tuning
