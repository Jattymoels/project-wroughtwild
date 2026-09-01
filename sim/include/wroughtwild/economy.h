#pragma once

// Craft skills, recipe execution, repetition decay, orders and salvage.
// Deterministic and engine-neutral; all numbers come from tuning tables.

#include <map>
#include <string>
#include <vector>

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

class PlayerEconomy {
public:
    explicit PlayerEconomy(const tuning::Tuning& tuning) : tuning_(tuning) {}

    Inventory inventory;
    std::map<std::string, int> currency;
    // Rolled gear (D-014): items with modifiers are instances, not counts;
    // plain crafted gear stays a count in `inventory` until it is worn.
    std::vector<items::ItemInstance> packItems;

    // --- skills ---
    int skillXp(const std::string& skillId) const;
    int skillLevel(const std::string& skillId) const;
    void grantSkillXp(const std::string& skillId, int amount);

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
    bool canAffordPlacement(const std::string& shapeId, const std::string& materialFamily) const;
    bool payPlacement(const std::string& shapeId, const std::string& materialFamily);
    int refundRemoval(const std::string& shapeId, const std::string& materialFamily);

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
    };
    State exportState() const;
    void importState(const State& state);

    // --- salvage ---
    // Returns floor(input * salvage_return_fraction) of each input of the
    // recipe that produced the item, consuming one unit of the output.
    bool salvage(const std::string& recipeId);

private:
    const tuning::Tuning& tuning_;
    std::map<std::string, SkillState> skills_;
    std::vector<std::string> availableStations_;
    std::map<std::string, int> craftCounts_; // recipe id -> non-order repetitions
    std::vector<std::string> fulfilledOrders_;
    std::vector<std::string> worldEffects_;
};

} // namespace wroughtwild::economy
