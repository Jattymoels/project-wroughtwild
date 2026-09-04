#include "wroughtwild/daycycle.h"

#include <algorithm>
#include <cmath>
#include <cstdint>

namespace wroughtwild::daycycle {

namespace {
double smooth(double t) {
    t = std::clamp(t, 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}
double lerp(double a, double b, double t) { return a + (b - a) * t; }
} // namespace

Info info(const tuning::DayDef& def, double clockSeconds) {
    Info out;
    if (def.lengthSeconds <= 0.0) return out;
    const double total = def.startFraction * def.lengthSeconds + std::max(0.0, clockSeconds);
    const double days = std::floor(total / def.lengthSeconds);
    out.index = static_cast<int>(days) + 1;
    out.fraction = std::clamp(total / def.lengthSeconds - days, 0.0, 1.0);
    const double f = out.fraction;
    if (f < def.dawnEnd) {
        out.phase = "dawn";
        out.daylight = lerp(def.nightLight, 1.0, smooth(f / def.dawnEnd));
    } else if (f < def.dayEnd) {
        out.phase = "day";
        out.daylight = 1.0;
    } else if (f < def.duskEnd) {
        out.phase = "dusk";
        out.daylight = lerp(1.0, def.nightLight, smooth((f - def.dayEnd) / (def.duskEnd - def.dayEnd)));
    } else {
        out.phase = "night";
        out.daylight = def.nightLight;
        out.night = true;
    }
    out.secondsToNight = out.night ? 0.0 : (def.duskEnd - f) * def.lengthSeconds;
    out.secondsToDawn = out.night ? (1.0 - f) * def.lengthSeconds : 0.0;
    return out;
}

bool siegeTonight(const tuning::SiegeDef& def, uint64_t seed, int dayIndex) {
    if (def.firstNight <= 0 || dayIndex < def.firstNight || def.chancePerNight <= 0.0) return false;
    uint64_t h = seed ^ 0x9E3779B97F4A7C15ull;
    h ^= static_cast<uint64_t>(dayIndex) * 0xBF58476D1CE4E5B9ull;
    h ^= h >> 31;
    h *= 0x94D049BB133111EBull;
    h ^= h >> 29;
    const double roll = static_cast<double>(h % 1000003ull) / 1000003.0;
    return roll < def.chancePerNight;
}

const std::vector<std::string>& siegePack(const tuning::SiegeDef& def, int era) {
    static const std::vector<std::string> none;
    const std::vector<std::string>* best = &none;
    for (const auto& [at, pack] : def.packByEra)
        if (at <= era) best = &pack;
    return *best;
}

double exposed(const tuning::DayDef& def, double roundSeconds, double life, double maxLife, double seconds) {
    const double floor = def.exposureFloorFraction * maxLife;
    if (life <= floor || seconds <= 0.0 || roundSeconds <= 0.0) return life;
    const double perSecond = def.exposureLifePerRound / roundSeconds;
    return std::max(floor, life - perSecond * seconds);
}

} // namespace wroughtwild::daycycle
