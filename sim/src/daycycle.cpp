#include "wroughtwild/daycycle.h"

#include <algorithm>
#include <cmath>

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

double exposed(const tuning::DayDef& def, double roundSeconds, double life, double maxLife, double seconds) {
    const double floor = def.exposureFloorFraction * maxLife;
    if (life <= floor || seconds <= 0.0 || roundSeconds <= 0.0) return life;
    const double perSecond = def.exposureLifePerRound / roundSeconds;
    return std::max(floor, life - perSecond * seconds);
}

} // namespace wroughtwild::daycycle
