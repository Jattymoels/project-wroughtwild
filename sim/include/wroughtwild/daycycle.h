#pragma once
// Day and night (Wave 6 slice 5, the world made whole). The world keeps a
// clock; the day runs dawn, day, dusk, night by fractions of its length;
// the night is dark, cold out in the open and wider awake, and a shelter
// is where you mend through it. The owner (4 Sep 2026): "imperative there
// is almost like a forced - go back and continue your shelter, and get
// lost in that for a bit." Pure functions over world.json "day".
#include <string>

#include "wroughtwild/tuning.h"

namespace wroughtwild::daycycle {

// Where the world's clock stands.
struct Info {
    int index = 1;               // day one is the first
    double fraction = 0.0;       // 0..1 through the day
    std::string phase = "day";   // dawn | day | dusk | night
    double daylight = 1.0;       // 1 by day, night_light at the dead of night
    bool night = false;          // dusk is the warning, not the night
    double secondsToNight = 0.0; // until the night begins (0 in it)
    double secondsToDawn = 0.0;  // until the night ends (0 outside it)
};

// The clock is seconds of play since the world began; a new game starts
// start_fraction into day one. No day rules (length 0) means endless day.
Info info(const tuning::DayDef& def, double clockSeconds);

// Life after `seconds` out in the open at night: the cold takes
// exposure_life_per_round per round and stops at the floor. It never
// kills - it sends you home. Life already under the floor is left alone.
double exposed(const tuning::DayDef& def, double roundSeconds, double life, double maxLife, double seconds);

// The siege (Wave 7 slice 3): whether the hounds come on this night of the
// world - never before first_night, then chance_per_night rolled from the
// seed and the day, so a save replays its nights.
bool siegeTonight(const tuning::SiegeDef& def, uint64_t seed, int dayIndex);

// The siege pack for an era: the highest era listed at or under it
// (empty when none is).
const std::vector<std::string>& siegePack(const tuning::SiegeDef& def, int era);

} // namespace wroughtwild::daycycle
