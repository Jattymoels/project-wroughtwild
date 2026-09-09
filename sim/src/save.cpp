#include "wroughtwild/save.h"

#include <fstream>
#include <iomanip>
#include <limits>
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

// One item: base, rarity, implicit numeric properties, rolled modifiers.
void writeItem(std::ostringstream& out, const items::ItemInstance& item) {
    out << "{\"base\":\"" << escape(item.baseId) << "\",\"rarity\":\"" << escape(item.rarity)
        << "\",\"workpiece_tier\":" << item.workpieceTier << ",\"implicit\":{";
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
            << ",\"value\":" << rolled.value << ",\"crafted\":" << (rolled.crafted ? "true" : "false") << "}";
    }
    out << "]}";
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

items::ItemInstance readItem(const json::Value& v) {
    items::ItemInstance item;
    item.baseId = v.get("base").asString();
    if (auto tier = v.find("workpiece_tier")) item.workpieceTier = tier->asInt();
    if (auto rarity = v.find("rarity")) item.rarity = rarity->asString();
    for (const auto& [id, value] : v.get("implicit").asObject())
        item.implicitProperties[id] = value->asNumber();
    for (const auto& rolled : v.get("rolled").asArray()) {
        items::RolledProperty property;
        property.propertyId = rolled->get("id").asString();
        property.tier = rolled->get("tier").asInt();
        property.value = rolled->get("value").asNumber();
        if (auto crafted = rolled->find("crafted")) property.crafted = crafted->asBool();
        item.rolledProperties.push_back(std::move(property));
    }
    return item;
}

} // namespace

std::string itemListToJson(const std::vector<items::ItemInstance>& items) {
    std::ostringstream out;
    out << std::setprecision(std::numeric_limits<double>::max_digits10);
    out.precision(17);
    out << '[';
    for (size_t i = 0; i < items.size(); ++i) {
        if (i) out << ',';
        writeItem(out, items[i]);
    }
    out << ']';
    return out.str();
}
std::vector<items::ItemInstance> itemListFromJson(const std::string& text) {
    std::vector<items::ItemInstance> items;
    auto value = json::parse(text);
    for (const auto& item : value->asArray()) items.push_back(readItem(*item));
    return items;
}

std::string toJson(const SaveGame& game) {
    std::ostringstream out;
    out << std::setprecision(std::numeric_limits<double>::max_digits10);
    out.precision(17); // round-trip doubles exactly
    out << "{\"schema_version\":" << game.schemaVersion << ",\"economy\":{";

    out << "\"inventory\":";
    writeIntMap(out, game.economy.inventory);
    if (game.economy.campaignPolicy != "legacy") {
        out << ",\"campaign_policy\":\"" << escape(game.economy.campaignPolicy) << "\",\"resonance\":" << game.economy.resonanceState.toJson();
    }
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
    out << ",\"pack_items\":[";
    for (size_t i = 0; i < game.economy.packItems.size(); ++i) {
        if (i) out << ",";
        writeItem(out, game.economy.packItems[i]);
    }
    out << "],\"known_skills\":";
    writeStringList(out, game.economy.knownSkills);
    out << ",\"skill_bar\":";
    writeStringList(out, game.economy.skillBar);
    out << ",\"day_clock\":" << game.economy.dayClock;
    // The stores (Wave 6 slice 6): chest key -> family -> count.
    out << ",\"stores\":{";
    bool firstStore = true;
    for (const auto& [key, contents] : game.economy.stores) {
        if (!firstStore) out << ",";
        firstStore = false;
        out << "\"" << escape(key) << "\":";
        writeIntMap(out, contents);
    }
    out << "}";
    out << ",\"foundry\":{\"owned\":";
    writeIntMap(out, game.economy.foundry.owned);
    out << ",\"plate\":[";
    for (size_t i = 0; i < game.economy.foundry.plate.size(); ++i) {
        const auto& p = game.economy.foundry.plate[i];
        if (i) out << ",";
        out << "{\"row\":" << p.row << ",\"col\":" << p.col << ",\"ingot\":\"" << escape(p.ingot) << "\"";
        if (p.isTablet()) out << ",\"skill\":\"" << escape(p.skill) << "\"";
        if (p.isCurrency()) out << ",\"currency\":\"" << escape(p.currency) << "\"";
        if (!p.metal.empty()) out << ",\"metal\":\"" << escape(p.metal) << "\"";
        out << "}";
    }
    out << "],\"milestones\":";
    writeStringList(out, game.economy.foundry.milestones);
    // The surround (D-023 slice 9): the class, the specialisation, the rails, the kills.
    out << ",\"class\":\"" << escape(game.economy.foundry.chosenClass) << "\"";
    out << ",\"specialisation\":\"" << escape(game.economy.foundry.specialisation) << "\",\"rails\":[";
    for (size_t i = 0; i < game.economy.foundry.rails.size(); ++i) {
        const auto& r = game.economy.foundry.rails[i];
        if (i) out << ",";
        out << "{\"axis\":\"" << escape(r.axis) << "\",\"index\":" << r.index << ",\"pattern\":\"" << escape(r.pattern) << "\"}";
    }
    out << "],\"kills\":";
    writeIntMap(out, game.economy.foundry.kills);
    // The metals (slice 10): ingot -> metal -> count.
    out << ",\"metals\":{";
    bool firstMetal = true;
    for (const auto& [ingot, counts] : game.economy.foundry.metals) {
        if (!firstMetal) out << ",";
        firstMetal = false;
        out << "\"" << escape(ingot) << "\":";
        writeIntMap(out, counts);
    }
    out << "}},\"skill_uses\":";
    writeIntMap(out, game.economy.skillUses);
    out << ",\"mastery_version\":" << game.economy.masteryVersion << ",\"crafted_gear\":" << game.economy.craftedGear;
    out << ",\"skill_practice\":{";
    bool firstPractice = true;
    for (const auto& [id, points] : game.economy.skillPractice) {
        if (!firstPractice) out << ",";
        firstPractice = false;
        out << "\"" << escape(id) << "\":" << points;
    }
    out << "},\"earned_mastery\":{";
    bool firstMastery = true;
    for (const auto& [id, perks] : game.economy.earnedMastery) {
        if (!firstMastery) out << ",";
        firstMastery = false;
        out << "\"" << escape(id) << "\":[";
        for (size_t i = 0; i < perks.size(); ++i) {
            if (i) out << ",";
            const auto& perk = perks[i];
            out << "{\"uses\":" << perk.uses << ",\"modifier\":\"" << escape(perk.modifier)
                << "\",\"value\":" << perk.value << ",\"text\":\"" << escape(perk.text) << "\"}";
        }
        out << "]";
    }
    out << "}},\"equipment\":{";

    bool firstSlot = true;
    for (const auto& [slot, item] : game.equipment.slots) {
        if (!firstSlot) out << ",";
        firstSlot = false;
        out << "\"" << escape(slot) << "\":";
        writeItem(out, item);
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
    if (auto policy = eco.find("campaign_policy")) game.economy.campaignPolicy = policy->asString();
    if (game.economy.campaignPolicy != "legacy" && game.economy.campaignPolicy != resonance::campaign)
        throw std::runtime_error("save: unsupported campaign policy");
    if (game.economy.campaignPolicy == resonance::campaign) game.economy.resonanceState = resonance::State::fromJson(eco.get("resonance"));
    else if (eco.find("resonance")) throw std::runtime_error("save: legacy campaign cannot contain a resonance event");
    game.economy.inventory = readIntMap(eco.get("inventory"));
    game.economy.currency = readIntMap(eco.get("currency"));
    game.economy.skillXp = readIntMap(eco.get("skill_xp"));
    game.economy.availableStations = readStringList(eco.get("stations"));
    game.economy.craftCounts = readIntMap(eco.get("craft_counts"));
    game.economy.fulfilledOrders = readStringList(eco.get("fulfilled_orders"));
    game.economy.worldEffects = readStringList(eco.get("world_effects"));
    // Saves written before D-014 carry no pack items.
    if (auto pack = eco.find("pack_items"))
        for (const auto& itemValue : pack->asArray())
            game.economy.packItems.push_back(readItem(*itemValue));
    // Saves written before D-016 carry no loadout; importState starts one.
    if (auto known = eco.find("known_skills")) game.economy.knownSkills = readStringList(*known);
    if (auto bar = eco.find("skill_bar")) game.economy.skillBar = readStringList(*bar);
    // Saves written before Wave 6 slice 5 carry no clock: day one, morning.
    if (auto clock = eco.find("day_clock")) game.economy.dayClock = clock->asNumber();
    // Saves written before Wave 6 slice 6 carry no stores.
    if (auto stores = eco.find("stores"))
        for (const auto& [key, contents] : stores->asObject()) game.economy.stores[key] = readIntMap(*contents);
    // Saves written before D-019 carry no Foundry.
    if (auto f = eco.find("foundry")) {
        game.economy.foundry.owned = readIntMap(f->get("owned"));
        for (const auto& p : f->get("plate").asArray()) {
            foundry::Placement placement;
            placement.row = p->get("row").asInt();
            placement.col = p->get("col").asInt();
            placement.ingot = p->get("ingot").asString();
            if (auto skill = p->find("skill")) placement.skill = skill->asString();
            if (auto currency = p->find("currency")) placement.currency = currency->asString();
            if (auto metal = p->find("metal")) placement.metal = metal->asString();
            game.economy.foundry.plate.push_back(placement);
        }
        game.economy.foundry.milestones = readStringList(f->get("milestones"));
        // Saves written before D-023 slice 9 carry no surround.
        if (auto cls = f->find("class")) game.economy.foundry.chosenClass = cls->asString();
        if (auto spec = f->find("specialisation")) game.economy.foundry.specialisation = spec->asString();
        if (auto rails = f->find("rails")) {
            for (const auto& r : rails->asArray()) {
                foundry::Rail rail;
                rail.axis = r->get("axis").asString();
                rail.index = r->get("index").asInt();
                rail.pattern = r->get("pattern").asString();
                game.economy.foundry.rails.push_back(rail);
            }
        }
        if (auto kills = f->find("kills")) game.economy.foundry.kills = readIntMap(*kills);
        // Saves written before slice 10 carry no metals: all iron on import.
        if (auto metals = f->find("metals"))
            for (const auto& [ingot, counts] : metals->asObject()) game.economy.foundry.metals[ingot] = readIntMap(*counts);
    }
    if (auto uses = eco.find("skill_uses")) game.economy.skillUses = readIntMap(*uses);
    game.economy.masteryVersion = eco.find("mastery_version") ? eco.get("mastery_version").asInt() : 0;
    if (auto count = eco.find("crafted_gear")) game.economy.craftedGear = count->asInt();
    if (auto points = eco.find("skill_practice")) for (const auto& [id, value] : points->asObject()) game.economy.skillPractice[id] = value->asNumber();
    if (auto mastery = eco.find("earned_mastery")) for (const auto& [id, perks] : mastery->asObject()) {
        for (const auto& p : perks->asArray()) game.economy.earnedMastery[id].push_back({p->get("uses").asInt(), p->get("modifier").asString(), p->get("value").asNumber(), p->get("text").asString()});
    }

    for (const auto& [slot, itemValue] : doc->get("equipment").asObject())
        game.equipment.slots[slot] = readItem(*itemValue);

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
