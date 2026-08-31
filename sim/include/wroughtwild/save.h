#pragma once

// Save/load: the whole game state written as JSON text and read back.
// Schema v1 is NOT yet declared stable (AGENTS.md) — it may change until the
// vertical slice is accepted.

#include <map>
#include <string>

#include "wroughtwild/economy.h"
#include "wroughtwild/stats.h"

namespace wroughtwild::save {

struct SaveGame {
    int schemaVersion = 1;
    economy::PlayerEconomy::State economy;
    stats::Equipment equipment;
    // Free-form fields for the hosting game (location, flags, day counter...).
    std::map<std::string, std::string> extra;
};

std::string toJson(const SaveGame& game);

// Throws std::runtime_error on malformed input or an unknown schema version.
SaveGame fromJson(const std::string& text);

bool writeFile(const std::string& path, const SaveGame& game);
SaveGame readFile(const std::string& path);

} // namespace wroughtwild::save
