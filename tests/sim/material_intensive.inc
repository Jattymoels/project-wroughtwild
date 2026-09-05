// Included in test_main.cpp's local test namespace. The approved catalogue is
// an economy contract: raw items never become structural building families.
void testMaterialIntensive(const tuning::Tuning& t) {
    const std::vector<std::string> families = {"slate", "shellstone", "rustclay_brick", "woven_reed",
        "resinheart", "corkbark", "vitrified_basalt", "cinderglass"};
    const std::vector<std::string> sources = {"raw_slate", "raw_shellstone", "raw_clay", "raw_reed",
        "resinheart_log", "raw_corkbark", "furnace_slag", "cinderglass_shard"};
    check(t.construction.materials.size() == 19, "intensive: exactly eight finished families expand the eleven existing families");
    economy::PlayerEconomy player(t);
    for (size_t i = 0; i < families.size(); ++i) {
        const auto& id = families[i];
        const auto* family = t.construction.findMaterial(id);
        const auto* recipe = t.crafting.findRecipe("refine_" + id);
        check(family && family->source == id && !t.construction.findMaterial(sources[i]),
              "intensive: " + id + " is finished construction, its raw source is not");
        check(recipe && recipe->inputs.size() == 1 && recipe->inputs.count(sources[i]) &&
              recipe->outputs.size() == 1 && recipe->outputs.at(id) == 4 && recipe->minimumSkill.empty(),
              "intensive: " + id + " has one four-unit refinement without a skill gate");
        if (!recipe) continue;
        economy::PlayerEconomy maker(t);
        maker.inventory[sources[i]] = recipe->inputs.at(sources[i]);
        maker.inventory["wood"] = 20;
        check(!maker.craft(recipe->id).crafted && maker.inventory[sources[i]] == recipe->inputs.at(sources[i]),
              "intensive: missing station cannot consume " + sources[i]);
        maker.addAvailableStation(recipe->station);
        check(maker.craft(recipe->id).crafted && maker.inventory[sources[i]] == 0 && maker.inventory[id] == 4,
              "intensive: the existing station consumes the exact source once for " + id);
        const auto shape = id == "cinderglass" ? "glazed_window" : id == "woven_reed" || id == "corkbark" ? "light_panel" : "cube";
        const auto* def = t.construction.findShape(shape);
        const int prior = maker.inventory[id];
        check(maker.payPlacement(shape,id) && maker.inventory[id] == prior-def->materialCost,
              "intensive: a placed " + id + " pays its finished family");
        const int refund = static_cast<int>(std::floor(def->materialCost*t.construction.removalRefundFraction));
        check(maker.refundRemoval(shape,id) == refund && maker.inventory[id] == prior-def->materialCost+refund,
              "intensive: removal refunds the same finished " + id + " family");
        check(maker.storeDeposit("intensive_chest",id,1) == 1 && maker.storeWithdraw("intensive_chest",id,1) == 1,
              "intensive: ordinary storage accepts " + id);
    }
    for (const auto& id : {"woven_reed", "corkbark"}) {
        for (const auto& shape : {"cube", "wall_panel", "door", "chest", "beam", "half_cube"})
            check(!player.shapeAllowsFamily(shape,id), std::string("intensive: covering ")+id+" refuses "+shape);
        for (const auto& shape : {"light_panel", "codex_roof_slope", "codex_roof_hip", "codex_roof_valley"})
            check(player.shapeAllowsFamily(shape,id), std::string("intensive: covering ")+id+" admits "+shape);
    }
    for (const auto& id : {"wood", "pine", "bog_oak", "ash_wood", "iron", "bronze", "steel"})
        for (const auto& shape : {"codex_roof_slope", "codex_roof_hip", "codex_roof_valley"})
            check(player.shapeAllowsFamily(shape,id), std::string("intensive: previously eligible roof ")+id+" retains "+shape);
    for (const auto& shape : {"codex_roof_slope", "codex_roof_hip", "codex_roof_valley", "roof_wedge"})
        check(!player.shapeUnlocked(shape), std::string("intensive: material discovery cannot bypass stonecut unlock for ")+shape);
    player.recordWorldEffect("stonecut_blocks");
    for (const auto& shape : {"codex_roof_slope", "codex_roof_hip", "codex_roof_valley", "roof_wedge"})
        check(player.shapeUnlocked(shape), std::string("intensive: existing stonecut reward still unlocks ")+shape);
    check(player.shapeAllowsFamily("glazed_window","cinderglass") && !player.shapeAllowsFamily("cube","cinderglass"),
          "intensive: glazing stays in its fixed framed window");
}
