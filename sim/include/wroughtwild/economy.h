#pragma once

// Craft skills, recipe execution, repetition decay, orders and salvage.
// Deterministic and engine-neutral; all numbers come from tuning tables.

#include <map>
#include <string>
#include <vector>

#include "wroughtwild/foundry.h"
#include "wroughtwild/items.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::economy {

// Material/item counts shared by gathering, crafting, orders and construction:
// "treat building, combat and crafting as one economy".
using Inventory = std::map<std::string, int>;

bool hasAll(const Inventory& inventory, const std::map<std::string, int>& required);
void remove(Inventory& inventory, const std::map<std::string, int>& amounts); // throws if short
void add(Inventory& inventory, const std::map<std::string, int>& amounts);

struct SkillState {
    int xp = 0;
};

// Level implied by cumulative XP against the skill's curve, clamped to the
// prototype maximum. xp_required_by_level[i] is the XP needed for level i+1.
int levelForXp(const tuning::CraftSkillDef& skill, int xp);

// How many skills the bar holds (D-016): four keys, any known skill in any.
constexpr int kSkillBarSize = 4;

class PlayerEconomy {
public:
    explicit PlayerEconomy(const tuning::Tuning& tuning);

    Inventory inventory;
    std::map<std::string, int> currency;
    // Rolled gear (D-014): items with modifiers are instances, not counts;
    // plain crafted gear stays a count in `inventory` until it is worn.
    std::vector<items::ItemInstance> packItems;

    // --- craft skills ---
    int skillXp(const std::string& skillId) const;
    int skillLevel(const std::string& skillId) const;
    void grantSkillXp(const std::string& skillId, int amount);

    // --- combat loadout (D-016: skills are learned, not worn) ---
    // Known skills in learning order (the starting skills first), and the
    // bar: kSkillBarSize slots, each a known skill id or "" for empty. A
    // fresh character knows the starting skills and has them on the bar in
    // skills.json order.
    const std::vector<std::string>& knownSkills() const { return knownSkills_; }
    const std::vector<std::string>& skillBar() const { return skillBar_; }
    bool knowsSkill(const std::string& skillId) const;
    // Learns a skill (a page drop): false when unknown to tuning or already
    // known. A newly learned skill takes the first empty bar slot, if any.
    bool learnSkill(const std::string& skillId);
    // Puts a known skill (or "" to clear) into slot [0, kSkillBarSize). A
    // skill already on the bar moves rather than duplicates. False when the
    // slot is out of range or the skill is not known.
    bool setBarSlot(int slot, const std::string& skillId);

    // --- crafting ---
    struct CraftFailure {
        bool unknownRecipe = false;
        bool stationUnavailable = false;
        bool skillTooLow = false;
        bool missingInputs = false;
        bool missingFuel = false;
        bool any() const {
            return unknownRecipe || stationUnavailable || skillTooLow || missingInputs ||
                   missingFuel;
        }
    };

    struct CraftResult {
        bool crafted = false;
        CraftFailure failure;
        int xpGranted = 0;
        double xpMultiplier = 1.0;
    };

    // Stations the player's built facilities currently provide.
    void addAvailableStation(const std::string& stationId);
    bool stationAvailable(const std::string& stationId) const;

    // forOrder marks crafting directed at a bulk order; per crafting.json it
    // bypasses repetition decay because the output is genuinely consumed.
    // A recipe with an empty station is hand-craftable anywhere and skips
    // the facility and fuel gates.
    CraftResult craft(const std::string& recipeId, bool forOrder = false);

    // --- fuel (the first rung of the power gate) ---
    // Total fuel value carried: sum of count * fuel value per fuel item.
    int fuelValueHeld() const;
    // True when carried fuel covers the recipe's fuel_cost (input materials
    // committed to the craft are not double-counted as fuel).
    bool fuelMet(const std::string& recipeId) const;

    // PROVISIONAL decay rule (open question in crafting-and-skills.md):
    // repetitions 1..full_xp_repetitions grant full XP; repetition n beyond
    // that grants full_xp_repetitions / n, floored at minimum_multiplier.
    double repetitionMultiplier(const std::string& recipeId, bool forOrder) const;

    // --- orders ---
    struct OrderResult {
        bool fulfilled = false;
        bool alreadyFulfilled = false;
        bool missingOutputs = false;
        std::string worldEffect;
    };

    OrderResult fulfillOrder(const std::string& orderId);
    bool orderFulfilled(const std::string& orderId) const;
    bool worldEffectActive(const std::string& effect) const;
    // The current era (1-based, eras.json): the last era in order whose
    // trigger is active, stopping at the first unmet one (D-019).
    int currentEra() const;
    const tuning::EraDef& era() const;
    void recordWorldEffect(const std::string& effect);

    // True when some unfulfilled order demands one of the recipe's outputs.
    // Crafting toward genuine demand is what earns full XP (see forOrder).
    bool recipeFeedsOpenOrder(const std::string& recipeId) const;

    // --- construction of stations ---
    // Pays a station's build_cost (or upgrade_cost when it upgrades another
    // station the player already has) from inventory and currency, then makes
    // the station available. Returns false without paying when blocked.
    bool canBuildStation(const std::string& stationId) const;
    bool buildStation(const std::string& stationId);

    // --- construction of shapes ---
    // A shape costs construction.json's material_cost in whichever family the
    // player selected (construction spec core rule 1: families, not SKUs).
    // Removal refunds floor(cost * removal_refund_fraction) to the same family.
    // A shape may require a world effect (trial completion unlock).
    bool shapeUnlocked(const std::string& shapeId) const;
    // True when the building family can be worked into the shape (it has
    // every trait the shape requires).
    bool shapeAllowsFamily(const std::string& shapeId, const std::string& materialFamily) const;
    bool canAffordPlacement(const std::string& shapeId, const std::string& materialFamily) const;
    bool payPlacement(const std::string& shapeId, const std::string& materialFamily);
    int refundRemoval(const std::string& shapeId, const std::string& materialFamily);

    // --- the peddler (crafting.json market) ---
    // Buys an offer by item id with currency; false when unaffordable/unknown.
    bool buy(const std::string& itemId);

    // --- skill mastery (D-019) ---
    // A cast that fired. Returns the perk texts this use unlocked (usually none).
    std::vector<std::string> noteSkillUse(const std::string& skillId);
    int skillUses(const std::string& skillId) const;
    // Perks unlocked so far for a skill, in order.
    std::vector<const tuning::MasteryPerk*> masteryUnlocked(const std::string& skillId) const;

    // --- the Foundry (D-019, foundry.h) ---
    const foundry::State& foundry() const { return foundry_; }
    // The plate as the current era has forged it (the frame's rows and sockets).
    foundry::Plate plate() const;
    // Reports a milestone ("first_kill:ash_hound", "recipe:smelt_iron",
    // "world_effect:x", "era:2"); returns the ingot ids granted. Each source
    // grants once, and only from its era on.
    std::vector<std::string> foundryEvent(const std::string& event);
    // Sets an unplaced ingot on a free, forged cell of the plate that is
    // not a socket.
    bool foundryPlace(int row, int col, const std::string& ingot);
    // Lifts an ingot off the plate, paying reforge_cost. False when the
    // cell is empty or the metal is short.
    bool foundryRemove(int row, int col);
    // Lays a known skill's tablet in an empty socket (D-022, D-023): false
    // off the forged plate, outside a socket, on a taken cell, for an
    // unknown skill, or when already laid.
    bool foundryPlaceSkill(int row, int col, const std::string& skillId);
    bool canAffordReforge() const;
    // Ingots granted by events the economy raised itself (crafts, world
    // effects, eras), for the host to announce; cleared on read.
    std::vector<std::string> takeFoundryNotices();

    // --- save/load ---
    struct State {
        Inventory inventory;
        std::map<std::string, int> currency;
        std::map<std::string, int> skillXp;
        std::vector<std::string> availableStations;
        std::map<std::string, int> craftCounts;
        std::vector<std::string> fulfilledOrders;
        std::vector<std::string> worldEffects;
        std::vector<items::ItemInstance> packItems;
        std::vector<std::string> knownSkills;
        std::vector<std::string> skillBar;
        foundry::State foundry;
        std::map<std::string, int> skillUses;
    };
    State exportState() const;
    // Restores a state; unknown skill ids are dropped, and an empty known
    // list (a save from before D-016) falls back to the starting skills.
    void importState(const State& state);

    // --- salvage ---
    // Returns floor(input * salvage_return_fraction) of each input of the
    // recipe that produced the item, consuming one unit of the output.
    bool salvage(const std::string& recipeId);

private:
    void resetLoadout(); // starting skills known and on the bar

    const tuning::Tuning& tuning_;
    std::map<std::string, SkillState> skills_;
    std::vector<std::string> availableStations_;
    std::map<std::string, int> craftCounts_; // recipe id -> non-order repetitions
    std::vector<std::string> fulfilledOrders_;
    std::vector<std::string> worldEffects_;
    std::vector<std::string> knownSkills_;
    std::vector<std::string> skillBar_; // always kSkillBarSize entries
    foundry::State foundry_;
    std::vector<std::string> foundryNotices_;
    std::map<std::string, int> skillUses_;
    int craftedGear_ = 0; // seeds crafted rolls
};

} // namespace wroughtwild::economy
