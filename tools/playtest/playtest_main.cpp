// Wroughtwild text playtest: the complete vertical-slice loop, playable in a
// terminal. This program is only a thin "presentation layer" — every rule
// (crafting, XP, combat damage, death contracts, saves) comes from the
// engine-neutral sim/ library, exactly the role the 3D engine will later play.
//
//   make -C tools build/playtest && ./tools/build/playtest data/tuning
//
// Reads commands from stdin, so it can also be driven by a scripted file.

#include <algorithm>
#include <cstdio>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/items.h"
#include "wroughtwild/save.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/trial.h"
#include "wroughtwild/tuning.h"

using namespace wroughtwild;

namespace {

// Set by the "auto" argument: combat runs on the scripted auto policy so the
// whole game can be driven by piped command files.
bool gAutoCombat = false;

struct Game {
    tuning::Tuning t;
    economy::PlayerEconomy economy;
    stats::Equipment equipment;
    std::string location = "camp";
    int actions = 0; // rough time measure: one gather/craft batch = one action
    bool bossDefeated = false;
    // Open-world death: where dropped inventory waits for recovery.
    std::string droppedAt;
    economy::Inventory droppedInventory;
    uint64_t seedCounter = 1;

    explicit Game(tuning::Tuning tuningIn)
        : t(std::move(tuningIn)), economy(t) {}

    uint64_t nextSeed() { return 0x9E3779B97F4A7C15ull * ++seedCounter; }
    stats::DerivedStats playerStats() const {
        return stats::deriveStats(t.world.playerBase, equipment);
    }
    boons::BuildTags buildTags() const {
        boons::BuildTags tags;
        for (const auto& skill : t.skills.combatSkills)
            for (const auto& tag : skill.tags) tags.push_back(tag);
        return tags;
    }
};

bool readLine(std::string& line) {
    std::cout << "> " << std::flush;
    return static_cast<bool>(std::getline(std::cin, line));
}

std::vector<std::string> tokenize(const std::string& line) {
    std::istringstream stream(line);
    std::vector<std::string> tokens;
    std::string token;
    while (stream >> token) tokens.push_back(token);
    return tokens;
}

void printHelp() {
    std::cout <<
        "Commands:\n"
        "  status               your life, skill, gear and inventory\n"
        "  go <camp|forest|mine|gate>   travel\n"
        "  gather               collect materials at the current site\n"
        "  build forge          build the basic forge (at camp)\n"
        "  upgrade forge        upgrade to the improved forge (at camp)\n"
        "  recipes              list what you can craft\n"
        "  craft <recipe> [n]   craft at your forge\n"
        "  order                view or fulfil the mine reinforcement order\n"
        "  equip                wear the iron chest armour you crafted\n"
        "  temper               basic temper: baseline fire resistance\n"
        "  temper catalyst      ember-temper your armour (needs the catalyst)\n"
        "  trial                enter the trial (at gate)\n"
        "  save / load [file]   save or restore the game\n"
        "  help / quit\n";
}

void printStatus(const Game& game) {
    auto stats = game.playerStats();
    std::cout << "Location: " << game.location << "   (actions taken: " << game.actions << ")\n";
    std::cout << "Life " << static_cast<int>(stats.maxLife)
              << " | armour " << static_cast<int>(stats.armour)
              << " | fire resistance " << static_cast<int>(stats.fireResistancePercent) << "%\n";
    std::cout << "Blacksmithing level " << game.economy.skillLevel("blacksmithing") << " ("
              << game.economy.skillXp("blacksmithing") << " xp)\n";
    std::cout << "Forge: "
              << (game.economy.stationAvailable("forge_improved") ? "improved"
                  : game.economy.stationAvailable("forge_basic") ? "basic" : "none")
              << "\n";
    for (const auto& [slot, item] : game.equipment.slots) {
        std::cout << "Equipped " << slot << ": " << item.baseId;
        for (const auto& rolled : item.rolledProperties)
            std::cout << " [" << rolled.propertyId << " " << static_cast<int>(rolled.value)
                      << " (t" << rolled.tier << ")]";
        std::cout << "\n";
    }
    std::cout << "Inventory:";
    bool any = false;
    for (const auto& [id, count] : game.economy.inventory)
        if (count > 0) { std::cout << " " << id << " x" << count; any = true; }
    for (const auto& [id, count] : game.economy.currency)
        if (count > 0) { std::cout << " " << id << " x" << count; any = true; }
    if (!any) std::cout << " (empty)";
    std::cout << "\n";
    if (game.bossDefeated)
        std::cout << "The trial stands conquered. Unlocked: "
                  << game.t.trial.completionUnlock << "\n";
}

// Interactive combat: show the room each round, ask for a key. On EOF or bad
// input, the auto policy takes over so scripted runs finish cleanly.
combat::Action interactiveAction(const combat::CombatView& view) {
    if (gAutoCombat) return combat::autoPolicy(view);
    std::cout << "-- round " << view.round << " -- life "
              << static_cast<int>(view.playerLife) << "/"
              << static_cast<int>(view.playerMaxLife) << "\n";
    for (size_t i = 0; i < view.enemies->size(); ++i) {
        const auto& enemy = (*view.enemies)[i];
        if (enemy.alive())
            std::cout << "  [" << i << "] " << enemy.displayName << " "
                      << static_cast<int>(enemy.life) << "/" << static_cast<int>(enemy.maxLife)
                      << "\n";
    }
    if (view.breathIncoming) std::cout << "  *** FIRE INCOMING - dash (d) to evade! ***\n";
    std::cout << "  (a)rea strike  (h)eavy strike  (d)ash  (w)ait";
    for (size_t i = 0; i < view.skills->size(); ++i) {
        const auto& slot = (*view.skills)[i];
        if (!slot.ready())
            std::cout << "  [" << slot.def->displayName << " ready in "
                      << slot.cooldownRemaining << "]";
    }
    std::cout << "\n";

    std::string line;
    if (!readLine(line)) return combat::autoPolicy(view);
    char key = line.empty() ? 'w' : static_cast<char>(std::tolower(line[0]));

    auto findSkill = [&](const std::string& tag) {
        for (size_t i = 0; i < view.skills->size(); ++i) {
            const auto& def = *(*view.skills)[i].def;
            if (std::find(def.tags.begin(), def.tags.end(), tag) != def.tags.end())
                return static_cast<int>(i);
        }
        return -1;
    };
    int target = 0;
    for (size_t i = 0; i < view.enemies->size(); ++i)
        if ((*view.enemies)[i].alive()) { target = static_cast<int>(i); break; }

    switch (key) {
    case 'a': return {findSkill("area"), target};
    case 'h': return {findSkill("single_target"), target};
    case 'd': return {findSkill("movement"), target};
    case 'q': return combat::autoPolicy(view); // hand over to the auto player
    default: return {-1, target};
    }
}

void printCombatLog(const std::vector<std::string>& log) {
    for (const auto& line : log) std::cout << "  " << line << "\n";
}

void doGather(Game& game) {
    const tuning::GatherSite* site = nullptr;
    if (game.location == "forest") site = game.t.world.findSite("valley_forest");
    if (game.location == "mine") site = game.t.world.findSite("old_mine");
    if (!site) {
        std::cout << "Nothing to gather here. Try the forest or the mine.\n";
        return;
    }
    ++game.actions;

    // Reinforcing the mine (the order's world effect) clears its ambushes.
    double ambushChance = site->ambushChance;
    if (game.economy.worldEffectActive("old_mine_reinforced")) ambushChance = 0.0;

    uint64_t seed = game.nextSeed();
    if (ambushChance > 0.0 && (seed % 1000) < static_cast<uint64_t>(ambushChance * 1000)) {
        std::cout << "An ambush in the dark!\n";
        std::vector<std::string> log;
        auto result = combat::runEncounter(game.t, game.playerStats(), combat::CombatMods{},
                                           site->ambushEnemies, seed, interactiveAction, &log);
        printCombatLog(log);
        if (!result.victory) {
            // Open-world death contract: carried inventory drops here.
            std::cout << "You fall. Your carried goods lie where you fell (" << site->displayName
                      << "); your equipment stays with you. You wake at camp.\n";
            game.droppedAt = game.location;
            game.droppedInventory = game.economy.inventory;
            game.economy.inventory.clear();
            game.location = "camp";
            return;
        }
    }

    if (!game.droppedAt.empty() && game.droppedAt == game.location) {
        std::cout << "You recover your dropped goods.\n";
        economy::add(game.economy.inventory, game.droppedInventory);
        game.droppedInventory.clear();
        game.droppedAt.clear();
    }

    for (const auto& [id, amount] : site->yieldsPerAction) {
        game.economy.inventory[id] += amount;
        std::cout << "Gathered " << amount << " " << id << ".\n";
    }
}

void doCraft(Game& game, const std::vector<std::string>& args) {
    if (game.location != "camp") {
        std::cout << "Your forge is at camp.\n";
        return;
    }
    if (args.size() < 2) {
        std::cout << "craft <recipe> [count]\n";
        return;
    }
    int count = args.size() >= 3 ? std::max(1, std::atoi(args[2].c_str())) : 1;
    // Crafting toward the open mine order is genuinely useful work, so it
    // keeps full XP; once the mine is reinforced, repetition decay applies.
    const auto* recipe = game.t.crafting.findRecipe(args[1]);
    bool forOrder = recipe &&
        std::find(recipe->useCategories.begin(), recipe->useCategories.end(), "orders") !=
            recipe->useCategories.end() &&
        !game.economy.worldEffectActive("old_mine_reinforced");
    for (int i = 0; i < count; ++i) {
        auto result = game.economy.craft(args[1], forOrder);
        if (!result.crafted) {
            if (result.failure.unknownRecipe) std::cout << "No such recipe.\n";
            if (result.failure.stationUnavailable) std::cout << "You need the right forge.\n";
            if (result.failure.skillTooLow) std::cout << "Your blacksmithing is too low.\n";
            if (result.failure.missingInputs) std::cout << "Not enough materials.\n";
            if (result.failure.missingFuel) std::cout << "The forge is cold - it needs fuel (wood or charcoal).\n";
            return;
        }
        ++game.actions;
        std::cout << "Crafted " << args[1] << " (+" << result.xpGranted << " xp";
        if (result.xpMultiplier < 1.0)
            std::cout << ", reduced - this work serves no real demand";
        std::cout << ")\n";
    }
    std::cout << "Blacksmithing " << game.economy.skillLevel("blacksmithing") << " ("
              << game.economy.skillXp("blacksmithing") << " xp)\n";
}

void doOrder(Game& game) {
    const auto* order = game.t.crafting.findOrder("reinforce_old_mine");
    if (!order) return;
    auto result = game.economy.fulfillOrder(order->id);
    if (result.fulfilled) {
        std::cout << "The mine crew hauls away your fittings. The old mine is reinforced -\n"
                     "its tunnels are safe now, and the foreman pays well.\n";
        return;
    }
    if (result.alreadyFulfilled) {
        std::cout << "The mine is already reinforced.\n";
        return;
    }
    std::cout << order->displayName << ": deliver";
    for (const auto& [id, amount] : order->requiredOutputs)
        std::cout << " " << amount << " " << id << " (you have "
                  << game.economy.inventory[id] << ")";
    std::cout << ".\n";
}

void doEquip(Game& game) {
    // Crafted gear now rolls into the pack (D-019); a plain stack still counts.
    for (size_t i = 0; i < game.economy.packItems.size(); ++i) {
        if (game.economy.packItems[i].baseId == "iron_chest_armour") {
            game.equipment.slots["chest"] = game.economy.packItems[i];
            game.economy.packItems.erase(game.economy.packItems.begin() + static_cast<long>(i));
            std::cout << "You wear the armour from your pack.\n";
            return;
        }
    }
    auto held = game.economy.inventory.find("iron_chest_armour");
    if (held == game.economy.inventory.end() || held->second < 1) {
        std::cout << "You have no armour to wear. Craft iron_chest_armour first.\n";
        return;
    }
    held->second -= 1;
    items::ItemInstance armour;
    armour.baseId = "iron_chest_armour";
    const auto* base = game.t.items.findBase("iron_chest_armour");
    if (base) armour.implicitProperties = base->implicitProperties;
    game.equipment.slots["chest"] = armour;
    std::cout << "You strap on the iron chest armour.\n";
}

void doTemper(Game& game, bool withCatalyst) {
    auto slot = game.equipment.slots.find("chest");
    if (slot == game.equipment.slots.end()) {
        std::cout << "Equip your armour first.\n";
        return;
    }
    if (!game.economy.stationAvailable("forge_improved")) {
        std::cout << "Tempering needs the improved forge.\n";
        return;
    }

    if (!withCatalyst) {
        items::basicTemper(game.t.items, slot->second, "fire_resistance", 1);
        std::cout << "You quench the plates carefully. Baseline fire resistance: "
                  << static_cast<int>(items::propertyTotal(slot->second, "fire_resistance"))
                  << "%.\n";
        return;
    }

    const auto* process = game.t.crafting.findCatalystProcess("ember_catalyst_tempering");
    if (!process) return;
    auto catalyst = game.economy.inventory.find(process->catalyst);
    if (catalyst == game.economy.inventory.end() || catalyst->second < 1) {
        std::cout << "You need an Ember Catalyst - the trial holds them.\n";
        return;
    }
    auto result = items::catalystTemper(game.t.items, *process, slot->second,
                                        game.economy.skillLevel("blacksmithing"),
                                        game.nextSeed());
    if (result.skillTooLow) {
        std::cout << "The catalyst's heat is beyond your skill (blacksmithing 5 required).\n";
        return;
    }
    catalyst->second -= 1;
    std::cout << "The catalyst flares as it burns into the metal. Fire resistance is now "
              << static_cast<int>(items::propertyTotal(slot->second, "fire_resistance"))
              << "% (was " << static_cast<int>(result.previousValue) << ").\n";
}

void doTrial(Game& game) {
    if (game.location != "gate") {
        std::cout << "The trial gate stands east of camp. (go gate)\n";
        return;
    }
    std::cout << "You stow your ordinary goods in the gate lockers and step inside.\n";
    trial::TrialSession session(game.t, game.economy, game.buildTags(), game.nextSeed());
    auto playerStats = game.playerStats();

    while (!session.finished()) {
        const auto& stage = session.currentStage();
        int choice = 0;
        if (stage.choices.size() > 1) {
            std::cout << "Two doors:\n";
            for (size_t i = 0; i < stage.choices.size(); ++i)
                std::cout << "  [" << i << "] " << stage.choices[i].displayName << "\n";
            std::string line;
            if (readLine(line) && !line.empty()) choice = std::atoi(line.c_str());
            choice = std::clamp(choice, 0, static_cast<int>(stage.choices.size()) - 1);
        } else {
            std::cout << "Ahead: " << stage.choices[0].displayName << "\n";
        }

        std::vector<std::string> log;
        auto outcome = session.enterRoom(choice, playerStats, interactiveAction, &log);
        printCombatLog(log);
        if (!outcome.combat.victory) break;

        if (!outcome.boonOffer.empty()) {
            std::cout << "A shrine offers a temporary blessing:\n";
            for (size_t i = 0; i < outcome.boonOffer.size(); ++i)
                std::cout << "  [" << i << "] " << outcome.boonOffer[i]->displayName << " - "
                          << outcome.boonOffer[i]->designPurpose << "\n";
            std::string line;
            int pick = 0;
            if (readLine(line) && !line.empty()) pick = std::atoi(line.c_str());
            pick = std::clamp(pick, 0, static_cast<int>(outcome.boonOffer.size()) - 1);
            session.acceptBoonFromOffer(outcome.boonOffer[pick]->id);
            std::cout << "The blessing settles over you - for this run only.\n";
        }
        if (!outcome.offeredWeakness.empty()) {
            std::cout << "A cursed altar offers greater rewards for greater danger. Accept? (y/n)\n";
            std::string line;
            if (readLine(line) && !line.empty() && std::tolower(line[0]) == 'y') {
                session.acceptOfferedWeakness();
                std::cout << "The enemies ahead quicken...\n";
            }
        }
        if (outcome.catalystRecovered)
            std::cout << "You prise an EMBER CATALYST from the shrine - it thrums with heat.\n"
                         "Even death cannot take this knowledge from you now.\n";
        for (const auto& [id, amount] : outcome.materials)
            std::cout << "You claim " << amount << " " << id << ".\n";

        if (session.canBankAndExit() && !session.finished()) {
            std::cout << "A side passage leads out. Bank your loot and leave, or press on? (leave/press)\n";
            std::string line;
            if (readLine(line) && line.rfind("leave", 0) == 0) {
                session.bankAndExit();
                std::cout << "You slip out with your prizes. The Tyrant waits.\n";
            }
        }
    }

    if (session.playerDied())
        std::cout << "You wake at the gate. Your stored goods are untouched"
                  << (game.economy.inventory.count(game.t.trial.catalystItem)
                          ? ", and the catalyst is still in your hand."
                          : ".")
                  << " The Tyrant's weakness to prepared steel is clearer now.\n";
    if (session.bossDefeated()) {
        game.bossDefeated = true;
        std::cout << "The Forge Tyrant falls! Deep in its forge you find mastery of "
                  << game.t.trial.completionUnlock
                  << " - a new material for your constructions.\n";
    }
}

void doSave(Game& game, const std::string& path) {
    save::SaveGame data;
    data.economy = game.economy.exportState();
    data.equipment = game.equipment;
    data.extra["location"] = game.location;
    data.extra["actions"] = std::to_string(game.actions);
    data.extra["boss_defeated"] = game.bossDefeated ? "1" : "0";
    data.extra["dropped_at"] = game.droppedAt;
    std::cout << (save::writeFile(path, data) ? "Saved.\n" : "Could not save.\n");
}

void doLoad(Game& game, const std::string& path) {
    try {
        save::SaveGame data = save::readFile(path);
        game.economy.importState(data.economy);
        game.equipment = data.equipment;
        game.location = data.extra.count("location") ? data.extra["location"] : "camp";
        game.actions = data.extra.count("actions") ? std::atoi(data.extra["actions"].c_str()) : 0;
        game.bossDefeated = data.extra.count("boss_defeated") && data.extra["boss_defeated"] == "1";
        game.droppedAt = data.extra.count("dropped_at") ? data.extra["dropped_at"] : "";
        std::cout << "Loaded.\n";
    } catch (const std::exception& e) {
        std::cout << "Could not load: " << e.what() << "\n";
    }
}

} // namespace

int main(int argc, char** argv) {
    std::string tuningDir = argc > 1 ? argv[1] : "../../data/tuning";
    if (argc > 2 && std::string(argv[2]) == "auto") gAutoCombat = true;
    tuning::Tuning t;
    try {
        t = tuning::loadAll(tuningDir);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "cannot load tuning from %s: %s\n", tuningDir.c_str(), e.what());
        return 2;
    }

    Game game(std::move(t));
    std::cout <<
        "=== WROUGHTWILD - vertical slice playtest ===\n"
        "A small valley. Your camp is bare. To the west, a forest; below it, an old\n"
        "mine. To the east, a trial gate seals away something that breathes fire.\n"
        "Type 'help' for commands.\n";

    std::string line;
    while (readLine(line)) {
        auto args = tokenize(line);
        if (args.empty()) continue;
        const std::string& cmd = args[0];

        if (cmd == "quit" || cmd == "exit") break;
        else if (cmd == "help") printHelp();
        else if (cmd == "status") printStatus(game);
        else if (cmd == "go" && args.size() >= 2) {
            static const std::vector<std::string> places = {"camp", "forest", "mine", "gate"};
            if (std::find(places.begin(), places.end(), args[1]) != places.end()) {
                game.location = args[1];
                std::cout << "You travel to the " << args[1] << ".\n";
            } else std::cout << "Unknown place.\n";
        }
        else if (cmd == "gather") doGather(game);
        else if (cmd == "build" && args.size() >= 2 && args[1] == "forge") {
            if (game.economy.buildStation("forge_basic"))
                std::cout << "You raise a basic forge from timber and ore.\n";
            else std::cout << "You lack the materials (15 wood, 4 iron ore) or already have one.\n";
        }
        else if (cmd == "upgrade" && args.size() >= 2 && args[1] == "forge") {
            if (game.economy.buildStation("forge_improved"))
                std::cout << "Bellows, better fittings, hotter fire: the improved forge is ready.\n";
            else std::cout << "You need the basic forge, 30 trade_currency and 6 iron_fittings.\n";
        }
        else if (cmd == "recipes") {
            for (const auto& recipe : game.t.crafting.recipes) {
                std::cout << "  " << recipe.id << " @" << recipe.station << " (skill";
                for (const auto& [skill, level] : recipe.minimumSkill)
                    std::cout << " " << skill << " " << level;
                std::cout << "):";
                for (const auto& [id, amount] : recipe.inputs)
                    std::cout << " " << amount << " " << id;
                std::cout << " ->";
                for (const auto& [id, amount] : recipe.outputs)
                    std::cout << " " << amount << " " << id;
                std::cout << "\n";
            }
        }
        else if (cmd == "craft") doCraft(game, args);
        else if (cmd == "order") doOrder(game);
        else if (cmd == "equip") doEquip(game);
        else if (cmd == "temper")
            doTemper(game, args.size() >= 2 && args[1] == "catalyst");
        else if (cmd == "trial") doTrial(game);
        else if (cmd == "save") doSave(game, args.size() >= 2 ? args[1] : "wroughtwild_save.json");
        else if (cmd == "load") doLoad(game, args.size() >= 2 ? args[1] : "wroughtwild_save.json");
        else std::cout << "Unknown command. Type 'help'.\n";
    }
    std::cout << "Farewell, wrightwarden.\n";
    return 0;
}
