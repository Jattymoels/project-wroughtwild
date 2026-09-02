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
    std::vector<std::string> currencies; // ids that live in the purse, not the pack

    bool isCurrency(const std::string& id) const;
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

// A combat skill (D-016): skills are learned, not worn. Each carries its own
// delivery, tags and payload numbers; gear only scales them by tag.
struct CombatSkillDef {
    std::string id;
    std::string displayName;
    std::string delivery = "strike"; // cone | strike | projectile | dash - the engine's shape
    std::vector<std::string> tags;
    bool starting = false;   // known from the first moment (and on the round model's bar)
    double dropWeight = 0.0; // relative chance among unknown skills when a page drops (0 = never)
    std::map<std::string, double> numbers; // remaining numeric fields verbatim
};

struct SkillTable {
    std::vector<CraftSkillDef> craftSkills;
    std::vector<CombatSkillDef> combatSkills;

    const CraftSkillDef* findCraftSkill(const std::string& id) const;
    const CombatSkillDef* findCombatSkill(const std::string& id) const;
    // Ids of the starting skills, in skills.json order.
    std::vector<std::string> startingSkillIds() const;
};

// --- items.json --------------------------------------------------------------
// One modifier pool (D-014): character stats and skill modifiers are the
// same kind of thing, told apart by applies_to ("self" versus skill tags).

struct ModifierTier {
    int tier = 0;
    double minimum = 0.0;
    double maximum = 0.0;
};

struct ModifierDef {
    std::string id;
    std::string displayName;
    std::vector<std::string> tags;          // what it is about; a base's roll pool is by these
    std::vector<std::string> appliesToTags; // {"self"} = a character stat; else the skill tags it excites
    std::string effectKey;                  // add_<x> flat | increased_<x> additive | more_<x> multiplicative
    std::string display = "flat";           // "flat" | "percent", for the sentence
    std::vector<ModifierTier> tiers;
    double weight = 1.0;
    std::string designPurpose;

    bool isSelf() const;
    const ModifierTier* findTier(int tier) const;
};
using PropertyDef = ModifierDef;
using PropertyTier = ModifierTier;

struct ImplicitModifier {
    std::string id;
    double value = 0.0;
};

struct ItemBase {
    std::string id;
    std::string displayName;
    std::string material;
    std::string slot = "chest";
    std::map<std::string, double> implicitProperties;
    std::vector<ImplicitModifier> implicitModifiers;
    std::vector<std::string> allowedModifierTags;
};

struct RarityDef {
    std::string id;
    std::string displayName;
    int modifiersMin = 0;
    int modifiersMax = 0;
};

struct ItemTable {
    std::vector<std::string> slots; // display order
    std::vector<RarityDef> rarities;
    std::vector<ModifierDef> modifiers;
    std::vector<ItemBase> itemBases;

    const ItemBase* findBase(const std::string& id) const;
    const ModifierDef* findModifier(const std::string& id) const;
    const RarityDef* findRarity(const std::string& id) const;
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

// One line of a mob's loot table. Three kinds (D-016): a material stack, a
// rolled gear piece of a rarity and tier, or a skill page that teaches one
// skill the player does not yet know.
struct LootEntry {
    std::string kind = "item"; // item | gear | skill_page
    std::string item;          // item kind: the material id
    int minCount = 1;
    int maxCount = 1;
    double chance = 1.0;
    std::string gearRarity;    // gear kind: rarity id
    int gearTier = 1;          // gear kind: modifier tier
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

// An elite prefix a spawned mob can carry (Wave 3): named, felt, and
// interacting with the status grammar rather than only multiplying
// numbers. The worldgen danger rings decide who spawns elite; the drop
// bonuses are why elites are hunted (pages and gear concentrate here).
struct EliteModifierDef {
    std::string id;
    std::string displayName; // a prefix: "Unfreezable Stone Husk"
    double lifeMultiplier = 1.0;
    double speedMultiplier = 1.0;
    double damageMultiplier = 1.0;
    std::vector<std::string> immuneStatuses; // of: chill, ignite, bleed
    double deathBurstDamage = 0.0;           // > 0: explodes on death
    double deathBurstRadiusM = 0.0;
    std::string deathBurstType = "fire";
    int extraLootRolls = 0;            // extra material-table rolls per kill
    double gearChanceMultiplier = 1.0; // scales every gear loot entry
    double pageChanceMultiplier = 1.0; // scales every skill-page entry
};

struct WorldTable {
    PlayerBase playerBase;
    std::vector<EnemyDef> enemies;
    std::vector<EliteModifierDef> eliteModifiers;
    std::vector<GatherSite> gatheringSites;
    bool droppedInventoryRecoverable = true;

    const EnemyDef* findEnemy(const std::string& id) const;
    const EliteModifierDef* findEliteModifier(const std::string& id) const;
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
    // Gear a cleared room drops, keyed by the room's reward type (D-014).
    struct ItemReward {
        std::string rarity;
        int tier = 1;
    };
    std::map<std::string, ItemReward> itemRewards;
    bool keepCatalystsOnDeath = true;
    bool loseRunMaterialsOnDeath = true;
};

// --- construction.json -------------------------------------------------------

struct ShapeDef {
    std::string id;
    std::string displayName;
    int materialCost = 1; // units of whichever material family the player selected
    double sizeM[3] = {1.0, 1.0, 1.0};
    // Where the shape sits inside its grid cell: "centre", "face" (flush
    // against the side its rotation points at) or "corner" (tucked into that
    // corner). Presentation reads it to make thin shapes meet at corners.
    std::string anchor = "centre";
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
    // D-012: chase persists until the player stays beyond this for the
    // horde's give_up_seconds; 0 means "never gives up".
    double giveUpDistanceM = 0.0;
    // Shrieker fields (0 on everything else): while aggroed it screams
    // every screamPeriodSeconds, waking idle mobs within screamRadiusM -
    // the aggro chain that builds the Zombies wave feeling (D-012).
    double screamPeriodSeconds = 0.0;
    double screamRadiusM = 0.0;
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
    double playerConeDegrees = 360.0; // first-person area-strike arc (D-012)
    std::map<std::string, BehaviourRealtime> behaviours; // keyed by EnemyDef::behaviour
    BossRealtime boss;
    double dashInvulnerableSeconds = 0.0;
    double dashDurationSeconds = 0.0;
    // D-012 horde feel: chasers push apart into a train, and lose interest
    // only after the player stays beyond give-up range this long.
    double hordeSeparationRadiusM = 0.0;
    double hordeSeparationStrengthMps = 0.0;
    double hordeGiveUpSeconds = 0.0;
    // The 3D world's rule: a mob aggroes on and reaches the player only
    // within this vertical band - nothing bites through a floor or a cliff.
    double hordeVerticalReachM = 2.5;
    // Per-skill space-and-time tunables (projectile speed, ranges...),
    // numeric fields verbatim; keyed by skill id.
    std::map<std::string, std::map<std::string, double>> skillSpatials;

    const BehaviourRealtime* findBehaviour(const std::string& id) const;
};

// --- grammar.json ------------------------------------------------------------
// The Wave 2 grammar (docs/systems/skill-grammar.md): statuses and hooks.
// The tag-targeted modifiers that scale them live in items.json (D-014).

struct ChillStatus {
    double buildupMax = 100.0;
    double freezeDurationS = 2.5;
    double decayPerS = 30.0;
    double bossBuildupMultiplier = 0.25; // day-one boss status resistance
};

// A damage-over-time status (ignite, bleed): buildup crosses the threshold,
// then the mob takes damagePerS for durationS. Bleed's movingMultiplier
// scales the tick while the mob walks (ignite's stays 1).
struct DotStatusDef {
    double buildupMax = 100.0;
    double durationS = 0.0;
    double damagePerS = 0.0;
    double decayPerS = 0.0;
    double bossBuildupMultiplier = 0.25;
    double movingMultiplier = 1.0;
};

struct ShatterHook {
    std::vector<std::string> triggerTags; // skills carrying any of these tags trigger it
    double novaDamage = 0.0;
    std::string novaDamageType = "cold";
    double novaRadiusM = 0.0;
    bool executesFrozen = true;
    bool executesBoss = false; // frozen bosses take the nova but survive the execute
};

// Proliferate: a burning mob's death spreads its ignite to neighbours.
struct ProliferateHook {
    bool enabled = false;
    double radiusM = 0.0;
    double spreadBuildup = 0.0; // ignite buildup each neighbour receives
};

struct GrammarTable {
    ChillStatus chill;
    DotStatusDef ignite;
    DotStatusDef bleed;
    ShatterHook shatter;
    ProliferateHook proliferate;
};

// --- worldgen.json -----------------------------------------------------------
// Seed-generated bounded sandpit (D-003): terrain character, biome rules,
// node yields and the guaranteed-content rules every valid seed must satisfy.

struct MapParams {
    int widthCells = 96;
    int heightCells = 96;
    double cellSizeM = 1.0;
    int worldDepth = 48; // vertical block levels; y=0 is bedrock
    int baseHeight = 1;
    int heightScale = 6;
    double heightFrequency = 0.03;
    int heightOctaves = 3;
    double moistureFrequency = 0.015;
};

// The second terrain layer: localized craggy massifs on top of the rolling
// base, so the world has real verticality where cragginess runs high.
struct MountainParams {
    int extraScale = 0; // 0 disables the layer
    double frequency = 0.05;
    double cragginessFrequency = 0.012;
    double cragginessThreshold = 0.62;
};

struct StrataParams {
    int dirtDepth = 3; // dirt blocks under the surface block; stone below
};

// Carved cave systems: two intersecting 3D noise level-sets make winding
// tunnels, a third opens caverns low down; near-surface tunnel tops may
// breach as natural entrances.
struct CaveParams {
    bool enabled = false;
    double tunnelFrequency = 0.06;
    double tunnelWidth = 0.07;       // carve where |n1-.5|+|n2-.5| < width
    double cavernFrequency = 0.045;
    double cavernThreshold = 0.76;
    double cavernMaxYFraction = 0.5; // caverns only this far up a column
    int minY = 1;                    // never carve bedrock
    int surfaceMargin = 2;           // tunnels stay this far under the top...
    double breachChance = 0.35;      // ...except breach columns become entrances
    std::map<std::string, double> nodeDensity; // node type -> per-cave-floor chance
    // Cave-dwelling packs, rolled on roofed cave floors like nodes.
    std::vector<std::vector<std::string>> packs;
    double packDensity = 0.0;
};

// Danger scales with distance from spawn: the first ring whose radius
// contains the cell decides pack density, pack size and how often a pack
// carries an elite.
struct DangerRing {
    double radiusM = 0.0;
    double packDensityMultiplier = 1.0;
    int packSizeBonus = 0;     // extra members appended from the pack's own kind
    double eliteChance = 0.0;  // chance one member spawns with an elite modifier
};

// What breaking one generic terrain block costs and pays, per block kind
// ("surface", "dirt", "stone", "bedrock"). Digging is the engine's act;
// these are its rules.
struct BlockRule {
    bool breakable = true;
    double digSeconds = 1.0;
    std::map<std::string, int> yields; // material family -> count
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
    MountainParams mountains;
    StrataParams strata;
    CaveParams caves;
    std::vector<DangerRing> dangerRings;
    std::map<std::string, BlockRule> blockRules; // by block kind name
    std::vector<BiomeDef> biomes;
    std::map<std::string, NodeTypeDef> nodeTypes;
    WorldgenGuarantees guarantees;

    const BiomeDef* findBiome(const std::string& id) const;
    // The pack-density multiplier for a cell this far from spawn (1.0 when
    // no rings are tuned).
    double dangerMultiplierAt(double distanceM) const;
    // The whole ring for a distance (nullptr when none are tuned).
    const DangerRing* dangerRingAt(double distanceM) const;
};

// --- loading -----------------------------------------------------------------

CraftingTable loadCrafting(const std::string& path);
WorldgenTable loadWorldgen(const std::string& path);
GrammarTable loadGrammar(const std::string& path);
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
    GrammarTable grammar;
};

Tuning loadAll(const std::string& tuningDirectory);

} // namespace wroughtwild::tuning
