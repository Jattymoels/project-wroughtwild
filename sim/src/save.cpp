#include "wroughtwild/save.h"

#include <fstream>
#include <sstream>
#include <stdexcept>

#include "wroughtwild/json.h"

namespace wroughtwild::save {

namespace {

std::string escape(const std::string& text) {
    std::string out;
    for (char c : text) {
        switch (c) {
        case '"': out += "\\\""; break;
        case '\\': out += "\\\\"; break;
        case '\n': out += "\\n"; break;
        case '\t': out += "\\t"; break;
        case '\r': out += "\\r"; break;
        default: out += c;
        }
    }
    return out;
}

void writeIntMap(std::ostringstream& out, const std::map<std::string, int>& map) {
    out << "{";
    bool first = true;
    for (const auto& [key, value] : map) {
        if (!first) out << ",";
        first = false;
        out << "\"" << escape(key) << "\":" << value;
    }
    out << "}";
}

void writeStringList(std::ostringstream& out, const std::vector<std::string>& list) {
    out << "[";
    for (size_t i = 0; i < list.size(); ++i) {
        if (i) out << ",";
        out << "\"" << escape(list[i]) << "\"";
    }
    out << "]";
}

std::map<std::string, int> readIntMap(const json::Value& v) {
    std::map<std::string, int> out;
    for (const auto& [key, value] : v.asObject()) out[key] = value->asInt();
    return out;
}

std::vector<std::string> readStringList(const json::Value& v) {
    std::vector<std::string> out;
    for (const auto& item : v.asArray()) out.push_back(item->asString());
    return out;
}

} // namespace

std::string toJson(const SaveGame& game) {
    std::ostringstream out;
    out.precision(17); // round-trip doubles exactly
    out << "{\"schema_version\":" << game.schemaVersion << ",\"economy\":{";

    out << "\"inventory\":";
    writeIntMap(out, game.economy.inventory);
    out << ",\"currency\":";
    writeIntMap(out, game.economy.currency);
    out << ",\"skill_xp\":";
    writeIntMap(out, game.economy.skillXp);
    out << ",\"stations\":";
    writeStringList(out, game.economy.availableStations);
    out << ",\"craft_counts\":";
    writeIntMap(out, game.economy.craftCounts);
    out << ",\"fulfilled_orders\":";
    writeStringList(out, game.economy.fulfilledOrders);
    out << ",\"world_effects\":";
    writeStringList(out, game.economy.worldEffects);
    out << "},\"equipment\":{";

    bool firstSlot = true;
    for (const auto& [slot, item] : game.equipment.slots) {
        if (!firstSlot) out << ",";
        firstSlot = false;
        out << "\"" << escape(slot) << "\":{\"base\":\"" << escape(item.baseId)
            << "\",\"implicit\":{";
        bool first = true;
        for (const auto& [id, value] : item.implicitProperties) {
            if (!first) out << ",";
            first = false;
            out << "\"" << escape(id) << "\":" << value;
        }
        out << "},\"rolled\":[";
        for (size_t i = 0; i < item.rolledProperties.size(); ++i) {
            const auto& rolled = item.rolledProperties[i];
            if (i) out << ",";
            out << "{\"id\":\"" << escape(rolled.propertyId) << "\",\"tier\":" << rolled.tier
                << ",\"value\":" << rolled.value << "}";
        }
        out << "]}";
    }
    out << "},\"extra\":{";

    bool firstExtra = true;
    for (const auto& [key, value] : game.extra) {
        if (!firstExtra) out << ",";
        firstExtra = false;
        out << "\"" << escape(key) << "\":\"" << escape(value) << "\"";
    }
    out << "}}";
    return out.str();
}

SaveGame fromJson(const std::string& text) {
    auto doc = json::parse(text);
    SaveGame game;
    game.schemaVersion = doc->get("schema_version").asInt();
    if (game.schemaVersion != 1)
        throw std::runtime_error("save: unknown schema version " +
                                 std::to_string(game.schemaVersion));

    const json::Value& eco = doc->get("economy");
    game.economy.inventory = readIntMap(eco.get("inventory"));
    game.economy.currency = readIntMap(eco.get("currency"));
    game.economy.skillXp = readIntMap(eco.get("skill_xp"));
    game.economy.availableStations = readStringList(eco.get("stations"));
    game.economy.craftCounts = readIntMap(eco.get("craft_counts"));
    game.economy.fulfilledOrders = readStringList(eco.get("fulfilled_orders"));
    game.economy.worldEffects = readStringList(eco.get("world_effects"));

    for (const auto& [slot, itemValue] : doc->get("equipment").asObject()) {
        items::ItemInstance item;
        item.baseId = itemValue->get("base").asString();
        for (const auto& [id, value] : itemValue->get("implicit").asObject())
            item.implicitProperties[id] = value->asNumber();
        for (const auto& rolled : itemValue->get("rolled").asArray()) {
            items::RolledProperty property;
            property.propertyId = rolled->get("id").asString();
            property.tier = rolled->get("tier").asInt();
            property.value = rolled->get("value").asNumber();
            item.rolledProperties.push_back(std::move(property));
        }
        game.equipment.slots[slot] = std::move(item);
    }

    for (const auto& [key, value] : doc->get("extra").asObject())
        game.extra[key] = value->asString();
    return game;
}

bool writeFile(const std::string& path, const SaveGame& game) {
    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    if (!stream) return false;
    stream << toJson(game);
    return static_cast<bool>(stream);
}

SaveGame readFile(const std::string& path) {
    std::ifstream stream(path, std::ios::binary);
    if (!stream) throw std::runtime_error("save: cannot open " + path);
    std::ostringstream buffer;
    buffer << stream.rdbuf();
    return fromJson(buffer.str());
}

} // namespace wroughtwild::save
