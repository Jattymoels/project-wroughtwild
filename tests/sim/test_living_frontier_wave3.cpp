#include "wroughtwild/tuning.h"
#include "wroughtwild/loot.h"
#include <iostream>

using namespace wroughtwild;
int checks = 0, failures = 0;
void check(bool ok, const std::string& label) {
    ++checks;
    if (!ok) { ++failures; std::cerr << "FAIL LF3: " << label << '\n'; }
}
int main(int argc, char** argv) {
    const auto t = tuning::loadAll(argc > 1 ? argv[1] : "data/tuning");
    check(t.world.enemies.size() == 11, "published ordinary population and reward pool stay intact");
    for (const auto& host : t.world.frontierEnemies) {
        check(host.worldProfile == "living_frontier_wave3", "new hosts are explicitly scoped");
        check(t.world.findEnemy(host.id) == &host, "native contact/loot resolves the authored host");
        const auto* b = t.realtime.findBehaviour(host.behaviour);
        check(b != nullptr, "native delivery definition exists");
        for (int seed = 0; seed < 100; ++seed) {
            const auto drops = loot::rollEnemyLoot(t.world, host.id, seed);
            check(!drops.empty(), "every host has useful ordinary loot");
            for (const auto& [id, quantity] : drops)
                check(quantity > 0 && id.find("catalyst") == std::string::npos, "new host reward needs no lucky Catalyst");
        }
    }
    const auto& red = *t.world.findEnemy("lf_red_boar");
    const auto& blue = *t.world.findEnemy("lf_blue_boar");
    check(red.visualId == blue.visualId && red.maxLife == blue.maxLife && red.damage == blue.damage,
          "influence spends one shared animal budget rather than adding a full second kit");
    check(red.damageTaken.empty() && blue.damageTaken.empty() && red.immuneStatuses.empty() && blue.immuneStatuses.empty(),
          "ordinary damage and control remain valid for every class");
    std::cout << "LF3_NATIVE " << checks << " checks, " << failures << " failures\n";
    return failures ? 1 : 0;
}
