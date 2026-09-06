#include "wroughtwild/contraptions.h"
#include "wroughtwild/json.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace wroughtwild::contraptions;
using wroughtwild::economy::Inventory;
namespace {
int checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
std::string changed(std::string source, const std::string& before, const std::string& after) {
    const auto at = source.find(before);
    if (at == std::string::npos) throw std::runtime_error("test tamper target absent");
    source.replace(at, before.size(), after);
    return source;
}
Config feederConfig(Config config, const std::string& directory) {
    const auto crafting=wroughtwild::json::parseFile(directory+"/crafting.json");
    for (const auto& material : crafting->get("materials").asArray()) config.allowedItems.insert(material->get("id").asString());
    bool recipeFound=false, kitFound=false;
    for (const auto& recipe : crafting->get("recipes").asArray()) {
        if (recipe->get("id").asString()=="refine_rustclay_brick") {
            check(recipe->get("station").asString()=="forge_basic", "feeder copies the existing basic forge recipe");
            check(recipe->get("minimum_skill").asObject().empty() && recipe->get("base_skill_xp").asInt()==0, "decorative recipe has no skill gate or mastery");
            for (const auto& input : recipe->get("inputs").asObject()) config.feederRecipeInputs[input.first]=input.second->asInt();
            for (const auto& output : recipe->get("outputs").asObject()) config.feederRecipeOutputs[output.first]=output.second->asInt();
            config.feederFuelCost=recipe->get("fuel_cost").asInt(); recipeFound=true;
        }
        if (recipe->get("id").asString()=="assemble_pressure_feeder") {
            Inventory inputs;
            for (const auto& input : recipe->get("inputs").asObject()) inputs[input.first]=input.second->asInt();
            check(inputs==Inventory{{"ventlung",1},{"thrumroot",1},{"wood",8},{"iron_ingot",2},{"raw_reed",2}}, "feeder kit has the approved two intact core and frame costs");
            check(recipe->get("outputs").get("pressure_feeder_kit").asInt()==1 && recipe->get("outputs").asObject().size()==1, "kit output is one placed object");
            check(recipe->get("station").asString()=="workbench" && recipe->get("minimum_skill").asObject().empty() && recipe->get("base_skill_xp").asInt()==0 && recipe->get("fuel_cost").asInt()==0 && recipe->get("minimum_era").asInt()==1, "kit uses existing bench access without new mastery fuel or progression gates");
            kitFound=true;
        }
    }
    check(recipeFound && kitFound && config.allowedItems.count("pressure_feeder_kit"), "existing recipe and new kit are in authoritative tuning");
    check(config.feederRecipeInputs==Inventory{{"raw_clay",8}} && config.feederRecipeOutputs==Inventory{{"rustclay_brick",4}} && config.feederFuelCost==1, "approved decorative recipe quantities unchanged");
    for (const auto& fuel : crafting->get("fuels").asObject()) if (fuel.second->type==wroughtwild::json::Type::Number) {
        config.feederFuels[fuel.first]=fuel.second->asInt(); config.allowedItems.insert(fuel.first);
    }
    return config;
}

void feederChecks(Config config, const std::string& directory, const std::string& legacySave) {
    check(!MachineWorld(config).create("unconfigured","pressure_feeder").ok, "unconfigured host cannot create an unsaveable feeder");
    config=feederConfig(std::move(config),directory);
    check(config.pressureSourceStrokes==24 && config.energyCapacity==4 && config.feederInputUnits==64 && config.feederOutputUnits==32 && config.feederBatchCycles==4 && config.feederCycleSeconds==8 && config.feederAttachmentRange==8, "approved pressure budgets are engine-neutral tuning");
    // A seed above JSON's exact numeric integer range exercises the opaque
    // decimal-string identity and prevents accidental lossy seed comparisons.
    const WorldIdentity identity{"frontier_v5",18446744073709551557ull,{{"ppv5_old_blacksmith",{2,0,0},24}}};
    MachineWorld feeder(config,identity);
    check(feeder.sourceRemaining("ppv5_old_blacksmith")==24 && feeder.sourceRemaining("missing")==-1, "only generated source definitions initialize finite pressure");
    check(feeder.validate(feeder.serialize()), "empty source ledger roundtrips before machinery exists");
    auto badIdentity=identity; badIdentity.profile="frontier_v4";
    bool rejected=false;
    try { (void)MachineWorld(config,badIdentity); } catch (const std::exception&) { rejected=true; }
    check(rejected, "native pressure definition cannot silently retrofit an older profile");
    badIdentity=identity; badIdentity.sources.push_back(badIdentity.sources.front()); rejected=false;
    try { (void)MachineWorld(config,badIdentity); } catch (const std::exception&) { rejected=true; }
    check(rejected, "duplicate generated source IDs cannot create two stocks");
    check(!feeder.restore(legacySave), "v5 cannot invent stock from an old schema ledger");
    check(MachineWorld(config,{"legacy_v1",0,{}}).validate(legacySave), "historical context-free schema1 still loads under an old-profile candidate");
    check(feeder.create("feeder","pressure_feeder").ok, "place finite feeder");
    check(!feeder.start("feeder",true).ok && !feeder.charge("feeder",4,true).ok, "unattached machine cannot start or charge");
    const auto unbound=feeder.serialize();
    check(!feeder.attachFeeder("feeder","ppv5_old_blacksmith","forge",{3,0,0},false).ok, "host rejects obstructed or unsupported attachment");
    check(!feeder.attachFeeder("feeder","missing","forge",{3,0,0},true).ok, "unknown source cannot create pressure");
    check(!feeder.attachFeeder("feeder","ppv5_old_blacksmith","forge",{9,0,0},true).ok, "distant forge rejected natively");
    check(!feeder.attachFeeder("feeder","ppv5_old_blacksmith","forge",{0,std::numeric_limits<double>::infinity(),0},true).ok, "nonfinite forge pose rejected");
    check(feeder.serialize()==unbound, "attachment refusals preserve all source and machine state");
    check(feeder.attachFeeder("feeder","ppv5_old_blacksmith","forge",{3,0,0},true).ok, "live player-built forge and nearby source attach");
    check(feeder.create("distant","pressure_feeder",{20,0,0}).ok && !feeder.attachFeeder("distant","ppv5_old_blacksmith","forge_far",{21,0,0},true).ok, "source reach is measured from trusted native geometry");
    Inventory emptyPack;
    check(feeder.erase("distant",emptyPack).ok, "remove inactive distance fixture");
    check(!feeder.charge("feeder",4,false).ok && !feeder.charge("feeder",0,true).ok, "blocked and nonpositive source transfers refuse");
    check(feeder.charge("feeder",100,true).moved==4 && feeder.sourceRemaining("ppv5_old_blacksmith")==20, "source debit and bounded store credit are one transfer");
    const auto charged=feeder.serialize();
    check(!feeder.charge("feeder",4,true).ok && !feeder.wind("feeder").ok && feeder.serialize()==charged, "full stores cannot duplicate source or hand pressure");
    Inventory pack{{"raw_clay",1000},{"wood",100},{"charcoal",100},{"iron_ingot",10},{"rustclay_brick",1}};
    check(!feeder.deposit("feeder","iron_ingot",1,pack).ok && !feeder.deposit("feeder","rustclay_brick",1,pack).ok, "hopper accepts only the selected recipe and ordinary fuel");
    check(feeder.deposit("feeder","raw_clay",32,pack).moved==32 && feeder.deposit("feeder","wood",4,pack).moved==4 && feeder.deposit("feeder","charcoal",2,pack).moved==2, "load exact deliberately held supplies");
    const auto loaded=feeder.serialize();
    check(!feeder.start("feeder",false).ok && feeder.serialize()==loaded, "blocked start reserves nothing");
    check(feeder.start("feeder",true).ok, "local handle reserves one existing firing");
    check(feeder.state("feeder")->escrowInputs==Inventory{{"raw_clay",8}} && feeder.state("feeder")->escrowFuel==Inventory{{"wood",1}} && feeder.state("feeder")->escrowDrive==1 && feeder.state("feeder")->energy==3, "fuel selection matches ordinary lowest-heat first spending with exact escrow");
    check(feeder.state("feeder")->queuedCycles==4 && feeder.state("feeder")->output.empty(), "one start is four bounded cycles with no early outputs");
    const auto reserved=feeder.serialize();
    check(!feeder.start("feeder",true).ok && !feeder.attachFeeder("feeder","","other",{1,0,0},true).ok && feeder.serialize()==reserved, "duplicate start and attachment edits cannot change escrow");
    check(!feeder.wind("feeder").ok && !feeder.charge("feeder",4,true).ok && feeder.sourceRemaining("ppv5_old_blacksmith")==20, "reserved drive still owns a place in the four-stroke store");
    check(!feeder.withdraw("feeder","escrow_inputs","raw_clay",8,1000,pack).ok, "reserved materials are not a second withdrawal port");
    check(feeder.advance("feeder",0.1,true).ok && feeder.advance("feeder",0.2,true).ok && feeder.pause("feeder",true).ok, "fractional firing can be explicitly paused");
    const auto partial=feeder.serialize();
    MachineWorld resumed(config,identity);
    check(resumed.restore(partial) && resumed.serialize()==partial, "fractional time exact escrow pause and source depletion restore together");
    check(!resumed.advance("feeder",1000,true).ok && !resumed.pause("feeder",true).ok && resumed.serialize()==partial, "paused and duplicate pause do not produce catch-up output");
    check(resumed.pause("feeder",false).ok, "resume uses the held firing");
    const auto unpaused=resumed.serialize();
    check(!resumed.advance("feeder",1000,false).ok && resumed.serialize()==unpaused, "unloaded unsupported trial or obstructed host state pauses exact progress");
    check(!resumed.advance("feeder",std::numeric_limits<double>::quiet_NaN(),true).ok && !resumed.advance("feeder",-1,true).ok, "invalid active time cannot corrupt ledger");
    check(resumed.deposit("feeder","raw_clay",100,pack).moved==26, "hopper filling retains capacity for reserved clay and fuel");
    const int sourceBeforeCancel=resumed.sourceRemaining("ppv5_old_blacksmith");
    check(resumed.cancel("feeder").ok && resumed.state("feeder")->energy==4 && resumed.state("feeder")->escrowDrive==0 && resumed.state("feeder")->queuedCycles==0 && resumed.state("feeder")->cycleSeconds==0, "cancellation returns exact drive and clears transaction progress");
    check(resumed.state("feeder")->input==Inventory{{"raw_clay",58},{"wood",4},{"charcoal",2}} && resumed.sourceRemaining("ppv5_old_blacksmith")==sourceBeforeCancel, "cancellation returns exact ingredients and fuel without refilling source");
    const auto cancelled=resumed.serialize();
    check(!resumed.cancel("feeder").ok && resumed.serialize()==cancelled, "cancel is once-only");
    check(resumed.validate(cancelled), "cancelled full hopper is a valid checkpoint");
    auto invalid=[&](const std::string& bad) {
        const auto before=resumed.serialize(); std::string reason;
        check(!resumed.restore(bad,&reason) && !reason.empty(), "corrupt pressure save rejected with reason");
        check(resumed.serialize()==before, "corrupt restore preserves machine and finite source ledger atomically");
    };
    invalid(changed(partial,"\"world_profile\":\"frontier_v5\"","\"world_profile\":\"frontier_v4\""));
    invalid(changed(partial,"\"world_seed\":\"18446744073709551557\"","\"world_seed\":18446744073709551557"));
    invalid(changed(partial,"\"world_seed\":\"18446744073709551557\"","\"world_seed\":\"18446744073709551556\""));
    invalid(changed(partial,"\"sources\":{\"ppv5_old_blacksmith\":20}","\"sources\":{}"));
    invalid(changed(partial,"\"sources\":{\"ppv5_old_blacksmith\":20}","\"sources\":{\"unknown\":20}"));
    invalid(changed(partial,"\"ppv5_old_blacksmith\":20","\"ppv5_old_blacksmith\":25"));
    invalid(changed(partial,"\"ppv5_old_blacksmith\":20","\"ppv5_old_blacksmith\":-1"));
    invalid(changed(partial,"\"ppv5_old_blacksmith\":20","\"ppv5_old_blacksmith\":1.5"));
    invalid(changed(partial,"\"source_id\":\"ppv5_old_blacksmith\"","\"source_id\":\"unknown\""));
    invalid(changed(partial,"\"forge_key\":\"forge\"","\"forge_key\":\"\""));
    invalid(changed(partial,"\"forge_position\":[3,0,0]","\"forge_position\":[9,0,0]"));
    invalid(changed(partial,"\"energy\":3","\"energy\":4"));
    invalid(changed(partial,"\"escrow_drive\":1","\"escrow_drive\":0"));
    invalid(changed(partial,"\"queued_cycles\":4","\"queued_cycles\":0"));
    invalid(changed(partial,"\"queued_cycles\":4","\"queued_cycles\":5"));
    const auto timeStart=partial.find("\"cycle_seconds\":")+16;
    const auto timeEnd=partial.find(',',timeStart);
    invalid(changed(partial,partial.substr(timeStart,timeEnd-timeStart),"8"));
    invalid(changed(partial,"\"escrow_inputs\":{\"raw_clay\":8}","\"escrow_inputs\":{\"raw_clay\":7}"));
    invalid(changed(partial,"\"escrow_fuel\":{\"wood\":1}","\"escrow_fuel\":{}"));
    invalid(changed(partial,"\"escrow_fuel\":{\"wood\":1}","\"escrow_fuel\":{\"wood\":2}"));
    invalid(changed(partial,"\"escrow_fuel\":{\"wood\":1}","\"escrow_fuel\":{\"iron_ingot\":1}"));
    invalid(changed(partial,"\"output\":{}","\"output\":{\"rustclay_brick\":32}"));
    invalid(changed(partial,"\"output\":{}","\"output\":{\"iron_ingot\":4}"));
    invalid(changed(partial,"\"completed_cycles\":0","\"completed_cycles\":2147483647"));
    invalid(changed(partial,"\"kind\":\"pressure_feeder\"","\"kind\":\"magnetic_sorter\""));
    invalid(changed(partial,"\"schema\":2","\"schema\":1"));
    auto otherSeed=identity; --otherSeed.seed;
    check(!MachineWorld(config,otherSeed).validate(partial), "saved-source validation uses the corresponding saved seed");
    auto shifted=identity; shifted.sources.front().position={20,0,0};
    check(!MachineWorld(config,shifted).validate(partial), "trusted generated source geometry validates attachments instead of trusting save poses");

    check(feeder.cancel("feeder").ok, "cancel first paused machine for batch test");
    check(feeder.create("lever","stormglass_lever",{1,0,0}).ok && feeder.link("lever","feeder",true).ok && feeder.pulse("lever",true,true).ok, "existing Stormglass lever starts the feeder's bounded batch");
    check(feeder.validate(feeder.serialize()), "feeder signal connection roundtrips");
    check(feeder.advance("feeder",10000,true).ok && feeder.state("feeder")->completedCycles==1 && feeder.state("feeder")->cycleSeconds==0 && feeder.state("feeder")->output.at("rustclay_brick")==4, "one large active delta completes only one cycle with no multi-cycle catch-up");
    check(feeder.advance("feeder",8,true).ok && feeder.advance("feeder",8,true).ok && feeder.advance("feeder",8,true).ok, "remaining three firings finish");
    check(feeder.state("feeder")->completedCycles==4 && feeder.state("feeder")->output.at("rustclay_brick")==16 && feeder.state("feeder")->energy==0 && feeder.state("feeder")->escrowDrive==0 && feeder.state("feeder")->queuedCycles==0, "four cycles spend four drive and make the same sixteen ordinary bricks");
    check(feeder.state("feeder")->input==Inventory{{"charcoal",2}} && feeder.sourceRemaining("ppv5_old_blacksmith")==20, "ordinary fuel exact item use and source transfers remain distinct");
    const auto finished=feeder.serialize();
    check(!feeder.advance("feeder",8,true).ok && feeder.serialize()==finished, "finished batch cannot produce twice");
    check(feeder.withdraw("feeder","output","rustclay_brick",100,7,pack).moved==7 && feeder.withdraw("feeder","output","rustclay_brick",100,100,pack).moved==9, "completed ordinary bricks collect with normal pack room");
    check(!feeder.withdraw("feeder","output","rustclay_brick",100,100,pack).ok, "outputs have one owner and collect once");
    check(feeder.deposit("feeder","raw_clay",8,pack).moved==8 && feeder.wind("feeder").ok && feeder.start("feeder",true).ok, "manual winding remains available with the source attached");
    check(feeder.state("feeder")->escrowFuel==Inventory{{"charcoal",1}}, "ordinary charcoal selection consumes exactly one item when wood absent");
    check(feeder.advance("feeder",8,true).ok && feeder.state("feeder")->queuedCycles==0 && feeder.state("feeder")->completedCycles==5, "missing next-cycle supplies stop before reserving another firing");

    // Dismantle returns both hopper and in-flight owners, but deliberately vents
    // drive. Replacing the device cannot refill the separate source ledger.
    check(feeder.deposit("feeder","raw_clay",16,pack).moved==16 && feeder.charge("feeder",4,true).moved==4 && feeder.start("feeder",true).ok, "prepare in-flight dismantle");
    const auto beforeDismantle=feeder.serialize();
    Inventory saturated{{"raw_clay",std::numeric_limits<int>::max()}};
    check(!feeder.erase("feeder",saturated).ok && feeder.serialize()==beforeDismantle && saturated.at("raw_clay")==std::numeric_limits<int>::max(), "overflow refuses dismantle without changing any owner");
    Inventory returned;
    check(feeder.erase("feeder",returned).ok && returned==Inventory{{"raw_clay",16},{"charcoal",1},{"rustclay_brick",4}}, "dismantling recovers buffered output and exact escrow ingredients/fuel");
    check(feeder.sourceRemaining("ppv5_old_blacksmith")==16 && feeder.state("lever")->link.empty(), "dismantle vents drive without refilling source and clears incoming signals");
    const auto dismantled=feeder.serialize();
    check(!feeder.erase("feeder",returned).ok && feeder.serialize()==dismantled, "dismantle cannot return escrow twice");
    for (int batch=0;batch<4;++batch) {
        check(feeder.create("feeder","pressure_feeder").ok && feeder.attachFeeder("feeder","ppv5_old_blacksmith","forge",{3,0,0},true).ok, "reusable feeder can be replaced at the same finite source");
        check(feeder.charge("feeder",4,true).moved==4 && feeder.erase("feeder",returned).ok, "vented stores debit source permanently");
    }
    check(feeder.sourceRemaining("ppv5_old_blacksmith")==0 && feeder.serialize().find("\"ppv5_old_blacksmith\":0")!=std::string::npos, "depleted source persists explicitly with zero stock");
    MachineWorld depleted(config,identity);
    check(depleted.restore(feeder.serialize()) && depleted.sourceRemaining("ppv5_old_blacksmith")==0, "reload does not replenish exhausted source");
    check(depleted.create("feeder","pressure_feeder").ok && depleted.attachFeeder("feeder","ppv5_old_blacksmith","forge",{3,0,0},true).ok && !depleted.charge("feeder",4,true).ok && depleted.wind("feeder").ok, "exhaustion preserves hand winding without a currency gate");

    MachineWorld manual(config,{"frontier_v4",17,{}});
    check(manual.create("feeder","pressure_feeder").ok && manual.attachFeeder("feeder","","forge",{1,0,0},true).ok, "old worlds can attach a manual-only feeder without retrofit sources");
    check(!manual.attachFeeder("feeder","ppv5_old_blacksmith","forge",{1,0,0},true).ok && manual.sources().empty(), "old worlds never infer pressure from matching coordinates");
    check(manual.deposit("feeder","raw_clay",8,pack).ok && manual.deposit("feeder","wood",1,pack).ok && manual.wind("feeder").ok && manual.start("feeder",true).ok && manual.advance("feeder",8,true).ok, "hand-powered existing-world recipe works completely");
    check(manual.validate(manual.serialize()), "manual feeder persists without source ownership");

    // Output space is reserved before costs. A nearly full tray leaves all
    // remaining clay/fuel/drive untouched and requires deliberate collection.
    MachineWorld full(config,identity);
    check(full.create("f","pressure_feeder").ok && full.attachFeeder("f","ppv5_old_blacksmith","forge",{1,0,0},true).ok, "prepare output-capacity test");
    for (int batch=0;batch<2;++batch) {
        check(full.deposit("f","raw_clay",32,pack).moved==32 && full.deposit("f","wood",4,pack).moved==4 && full.charge("f",4,true).moved==4 && full.start("f",true).ok, "load and start one full batch");
        for (int cycle=0;cycle<4;++cycle) check(full.advance("f",8,true).ok, "complete capacity-test firing");
    }
    check(full.state("f")->output.at("rustclay_brick")==32, "output tray reaches its exact bounded capacity");
    check(full.deposit("f","raw_clay",8,pack).ok && full.deposit("f","wood",1,pack).ok && full.wind("f").ok, "additional supplies remain owned by hopper");
    const auto capacity=full.serialize();
    check(!full.start("f",true).ok && full.serialize()==capacity, "full output refuses before any input fuel or drive debit");
    check(full.withdraw("f","output","rustclay_brick",1,100,pack).moved==1 && !full.start("f",true).ok, "one free slot cannot reserve a four-brick output");
    check(full.withdraw("f","output","rustclay_brick",3,100,pack).moved==3 && full.start("f",true).ok && full.advance("f",8,true).ok, "making room for a complete output resumes normal work");
    check(full.validate(full.serialize()), "full output final stopped ledger remains valid");

    MachineWorld shared(config,identity);
    check(shared.create("a","pressure_feeder").ok && shared.create("b","pressure_feeder",{1,0,0}).ok &&
        shared.attachFeeder("a","ppv5_old_blacksmith","forge",{3,0,0},true).ok && shared.attachFeeder("b","ppv5_old_blacksmith","forge",{3,0,0},true).ok, "two local feeders share the same world-scoped source owner");
    check(shared.charge("a",4,true).moved==4 && shared.charge("b",4,true).moved==4 && shared.sourceRemaining("ppv5_old_blacksmith")==16, "second feeder debits existing finite stock rather than copying source capacity");
    check(shared.validate(shared.serialize()), "shared source references survive complete ledger validation");
}
}

int main(int argc, char** argv) {
    try {
        auto config = Config::load(std::string(argc > 1 ? argv[1] : "../../data/tuning") + "/contraptions.json");
        config.allowedItems = {"wood", "iron_ore", "iron_ingot", "raw_reed", "stone", "thrumroot"};
        MachineWorld world(config);
        Inventory pack{{"wood", 200}, {"iron_ore", 100}, {"raw_reed", 20}};
        check(world.create("drum", "cargo_winch", {0, 1, 0}).ok, "place drum");
        check(world.create("landing", "winch_landing", {12, 4, 0}).ok, "place landing");
        check(world.create("lever", "stormglass_lever", {1, 1, 0}).ok, "place lever");
        check(world.create("lamp", "lantern_lamp", {2, 1, 0}).ok, "place lamp");
        check(world.create("sorter", "magnetic_sorter", {3, 1, 0}).ok, "place sorter");
        check(world.create("bellows", "ventlung_bellows", {4, 1, 0}).ok, "place bellows");
        check(!world.create("drum", "cargo_winch").ok, "duplicate placement rejects");
        check(!world.create("bad", "conveyor").ok, "unsupported automation rejects");
        check(!world.create("bad", "cargo_winch", {std::numeric_limits<double>::quiet_NaN(), 0, 0}).ok, "nonfinite position rejects");
        check(!world.link("drum", "landing", false).ok, "blocked initial span rejects");
        check(world.link("drum", "landing", true).ok, "fixed span links");
        check(world.link("lever", "drum", true).ok, "lever links receiver");
        check(!world.link("landing", "drum", true).ok, "no graph cycle");
        check(!world.pulse("lever", true, true).ok, "signal is not energy");
        check(world.state("lever")->pulses == 1, "unpowered receiver still shows signal");
        check(world.deposit("drum", "wood", 60, pack).moved == 60, "load cargo explicitly");
        check(world.deposit("drum", "iron_ore", 60, pack).moved == config.cargoUnits - 60, "cargo aggregate capacity");
        check(!world.deposit("drum", "trial_deposit", 1, pack).ok, "unknown and trial state never scanned");
        check(!world.deposit("drum", "wood", -5, pack).ok, "negative transfers reject");
        check(!world.link("drum", "landing", true).ok, "cannot relink loaded basket");
        check(world.wind("drum").ok, "wind by hand");
        check(world.pulse("lever", true, true).ok, "connected experiment starts");
        check(world.state("drum")->energy == 0, "trip energy spent once");
        check(!world.start("drum", true).ok, "duplicate start rejects");
        check(!world.deposit("drum", "raw_reed", 1, pack).ok, "cannot load moving basket");
        check(!world.withdraw("landing", "cargo", "wood", 60, 200, pack).ok, "cannot collect before arrival");
        check(!world.advance("drum", 100, false).ok, "blocked span pauses");
        check(world.state("drum")->progress == 0, "pause retains exact progress");
        check(world.advance("drum", 0.35, true).ok, "travel advances with active engine time");
        const auto travelling = world.serialize();
        check(world.validate(travelling), "midtrip save valid");
        MachineWorld restored(config);
        check(restored.restore(travelling), "resume midtrip");
        check(restored.serialize() == travelling, "exact energy cargo and progress restore");
        check(restored.advance("drum", 100, true).ok, "complete resumed trip");
        check(restored.state("drum")->completedTrips == 1, "once-only completion");
        check(!restored.advance("drum", 100, true).ok, "repeated completion no effect");
        check(!restored.withdraw("drum", "cargo", "wood", 60, 200, pack).ok, "cargo only at arrived endpoint");
        check(restored.withdraw("landing", "cargo", "wood", 60, 7, pack).moved == 7, "pack cap honored");
        check(restored.withdraw("landing", "cargo", "wood", 60, 200, pack).moved == 53, "remaining cargo collected");
        check(!restored.withdraw("landing", "cargo", "wood", 60, 200, pack).ok, "withdraw cannot duplicate");
        check(restored.deposit("landing", "raw_reed", 20, pack).ok, "return haul can load at landing");
        check(restored.wind("drum").ok && restored.start("drum", true).ok, "wind and return with cargo");
        check(restored.advance("drum", 0.1, true).ok, "return underway");
        const int ironBefore = pack["iron_ore"];
        check(restored.erase("landing", pack).ok, "remove endpoint midtrip");
        check(restored.state("drum")->link.empty() && !restored.state("drum")->moving && !restored.state("drum")->atLanding, "missing endpoint recalls basket");
        check(restored.state("drum")->cargo.at("raw_reed") == 20, "recall keeps sole cargo at drum");
        check(restored.erase("drum", pack).ok, "remove drum recovers contents");
        check(pack["iron_ore"] == ironBefore + 36 && pack["raw_reed"] == 20, "all recovered cargo conserved");
        check(!restored.erase("drum", pack).ok, "duplicate removal no reward");
        check(restored.state("lever")->link.empty(), "removed receiver clears signal");

        check(restored.deposit("sorter", "iron_ore", 24, pack).moved == 24, "sorter hand-fed iron");
        check(restored.deposit("sorter", "wood", 24, pack).moved == 24, "sorter mixed batch");
        check(restored.sort("sorter").moved == config.sorterBatchUnits, "bounded batch sorts");
        check(restored.sort("sorter").ok && restored.sort("sorter").ok, "remaining mixed batch sorts");
        check(restored.state("sorter")->ferrous.at("iron_ore") == 24, "iron follows magnet");
        check(restored.state("sorter")->remainder.at("wood") == 24, "other material separate");
        check(!restored.sort("sorter").ok, "empty input stops");
        check(restored.withdraw("sorter", "ferrous", "iron_ore", 100, 100, pack).moved == 24, "take ferrous tray");
        check(restored.withdraw("sorter", "remainder", "wood", 100, 100, pack).moved == 24, "take other tray");

        check(!restored.releaseBellows("bellows", true, 1).ok, "bellows requires pressure");
        check(restored.prime("bellows").ok, "prime by hand");
        check(!restored.releaseBellows("bellows", false, 1).ok, "incompatible target spends nothing");
        check(!restored.releaseBellows("bellows", true, 100).ok, "distant target spends nothing");
        check(restored.state("bellows")->energy == config.windingEnergy, "pressure retained on refusal");
        check(restored.releaseBellows("bellows", true, 1).ok, "nearby existing impact response");
        check(!restored.releaseBellows("bellows", true, 1).ok, "one charge cannot release twice");
        check(restored.link("lever", "lamp", true).ok, "lamp receiver connected");
        check(restored.pulse("lever", true, true).ok && !restored.state("lamp")->lampOn, "signal shutters lamp");
        check(restored.pulse("lever", true, true).ok && restored.state("lamp")->lampOn, "signal opens lamp");

        auto invalid = [&](const std::string& bad) {
            const auto before = world.serialize();
            check(!world.restore(bad), "malformed save rejects");
            check(world.serialize() == before, "failed restore leaves last good world intact");
        };
        invalid(changed(travelling, "\"schema\":1", "\"schema\":2"));
        invalid(changed(travelling, "\"energy\":0", "\"energy\":-1"));
        invalid(changed(travelling, "\"energy\":0", "\"energy\":0.5"));
        invalid(changed(travelling, "\"wood\":60", "\"wood\":60000"));
        invalid(changed(travelling, "\"wood\":60", "\"wood\":-1"));
        invalid(changed(travelling, "\"wood\":60", "\"unknown_currency\":60"));
        invalid(changed(travelling, "\"link\":\"landing\"", "\"link\":\"missing\""));
        invalid(changed(travelling, "\"link\":\"landing\"", "\"link\":\"drum\""));
        invalid(changed(travelling, "\"kind\":\"cargo_winch\"", "\"kind\":\"lantern_lamp\""));
        invalid(changed(travelling, "\"quarter_turns\":0", "\"quarter_turns\":7"));
        invalid(changed(travelling, "\"position\":[4,1,0]", "\"position\":[40000,1,0]"));
        check(restored.validate(restored.serialize()), "final complete world valid");
        feederChecks(config,std::string(argc>1 ? argv[1] : "../../data/tuning"),travelling);
        std::cout << "Contraptions: " << checks << " checks, 0 failures\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL after " << checks << " checks: " << error.what() << '\n';
        return 1;
    }
}
