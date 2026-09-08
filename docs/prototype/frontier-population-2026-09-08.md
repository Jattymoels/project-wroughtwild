# INT-02C — surface population and the shellstone approaches

**Status:** Implemented and checked; owner review pending. Starting production
was clean `main` at `7deb309`. This completes only the
[INT-02C work item](playtest-iterations-2026-09-07.md#int-02c-explain-and-repair-empty-stretches).
INT-02B art production has not begun in this slice.

## Outcome and scope

Surface patrols now follow the ground across hills. Each spawning surface member
uses its own body footprint and current terrain support, including excavation.
Previously a night patrol could materialise inside a hill, and the spread of a
daytime pack could place members inside adjacent higher cells. Actual enemy
bodies reproduce both failures before the correction.

The quarry approaches also have a separate distribution issue: the sampled
routes are near the protected starter area and generally outside hostile
activation range. Correct grounding does not populate those gaps. This slice
changes no generator, den placement, biome roster, cap, resource stock, inventory,
save schema or progression. No tuning value was introduced.

Affected systems: `MobPacks`, its generated-terrain regression fixtures and the
isolated review runner. D-003/ADR-0003 retains native geography and rules;
D-012 retains simple open-world chase, real collision and movement-only defence;
D-032 retains V6's quiet opening and frozen profile. Era-dependent foreign
routes retain their existing horizontal paths. The owner's exact profile, seed,
location and time remain unknown. Representative existing seeds were sufficient
to begin; no normal save was loaded or modified and no owner process was stopped.

The implementation plan was to preserve the baseline, count native records and
runtime candidates, reproduce bad grounding against real terrain, correct only
the demonstrated runtime fault, then compare identity, lifecycle and rendered
walks. No missing architecture or compatibility decision was needed for that fix.

## Native census and the quiet approaches

[Population maps](references/population-2026-09-08/population-maps.png) and
[retained measurements](references/population-2026-09-08/measurements.json)
contain biome counts, five distance bands, regional counts, quarry mapping and
ordinary/foreign patrol samples. Map circles show horizontal reach; actual
activation also checks height in 3D.

| V6 seed | All packs | Surface hostile packs | Cave packs | Grazer packs | Quarry biome / distance from spawn |
| --- | ---: | ---: | ---: | ---: | --- |
| 1 | 937 | 472 | 138 | 327 | rocky hills / 183m |
| 77 | 786 | 362 | 110 | 314 | rocky hills / 202m |
| 193 | 927 | 516 | 110 | 301 | rocky hills / 202m |

These are packs, not individual enemies. None of the three seeds has a hostile
den inside 190m. The 0–150m band contains 146, 129 and 135 grazer packs respectively.
The 190–300m band has 85, 57 and 100 surface hostile packs; 300–500m has 233, 230
and 252. A healthy world-wide count does not promise an encounter at each quarry.

All three quarry centres sit outside the named region cores. Their approach
cells are mostly meadow: 233 of 253 for seed 1, 209 of 287 for 77, and 201 of 231
for 193. Seed 77 also crosses 14 forest cells; the remaining cells are rocky
hills. The named cores themselves can be sparse:

| Core / native surface hostile dens | Seed 1 | Seed 77 | Seed 193 |
| --- | ---: | ---: | ---: |
| Glasswind Uplands (160m radius) | 5 | 1 | 3 |
| Lantern Fen (125m radius) | 7 | 13 | 2 |
| Rootvault Wildwood (145m radius) | 16 | 7 | 22 |

There are no wrong-biome surface hostile dens inside those cores. V6's landscape
composition removes packs whose old biome no longer matches a composed region;
its regional replenishment pass replenishes resources, not packs. Combined with
the profile's retained outer fraction, this explains why a named landscape can
look much emptier than the world-wide count suggests. That is frozen generation
behaviour, not an activation defect to patch by inserting runtime enemies.

Sampling every tenth authored approach point gives 26/29/24 points. By day,
none lies within the 28m activation range of a surface hostile pack. The nearest
sample-to-hostile distances are 48.1/65.3/101.8m. Sampled ordinary and foreign
patrol states at 17%, 50% and 82% of night still have zero qualifying points.
Seed 77 gets close at midnight (28.5m); this is a sampled result, not proof of an
encounter-free route at every location and hour. Shellstone names a finite
resource habitat, not a distinct enemy biome.

## Reproduced runtime faults and correction

At 17% of an ordinary night, before correction:

| Seed | Surface anchors >2m below ground | >2m above ground | Worst depth |
| --- | ---: | ---: | ---: |
| 1 | 57 | 86 | 12.82m |
| 77 | 46 | 86 | 6.04m |
| 193 | 64 | 131 | 14.75m |

The old runtime interpolated X, Y and Z between a den and its endpoint. The
endpoint heights are valid; the straight chord between them is not the walking
surface. The final common seed-1 fixture fails **36 of 338 checks** against the
preserved baseline. Four hounds at generated pack 421 start inside the hill and
fall another 10.9m over 90 physics frames. Daytime spread and excavated support
also fail. This is independent evidence, not an inference from the owner image.

The correction keeps the interpolated horizontal position and samples the
surface height there. Surface members then find support under the columns
covered by the actual scene capsule radius, checking the mutable voxel field
and available rendered surface. They retain the original spawn ring and settling
allowance. Their final pose is assigned before scene entry, so physics and
`MobGrid` never see a temporary actor at the parent's origin. Cave members keep
their authored interior floor and vertical activation rules.

All sampled current surface anchors are within 2m of the ground (zero failures
above or below). The native-route tests additionally require exact sampled
height agreement for every patrol at five phases, unchanged horizontal paths,
the quiet boundary, cave heights and identical indexed/exhaustive candidate
order on the actual quarry approaches. Real bodies settle on generated faceted
collision. Initial solid-volume checks remain strict; settled support is checked
against the actual triangles, since rounded faces can lie inside their source
voxel. Excavation is tested by spawning a real member over a separately dug
fixture, not by accepting the pristine height map.

## Player-height walks and ordinary activation

The full Sandpit scene was run in separate hidden, silent rendered processes,
with isolated APPDATA. The scripted observer follows the last 60 route segments
at 5m/s and a 1.65m eye. Terrain streaming, population ticks, sleep and enemy AI
remain active; observer attacks and the advancing world clock are disabled.
Night patrol state is fixed at 17% and rendered in dusk light for inspection,
explicitly labelled on the captures. These are observation walks, not difficulty
or ordinary movement-input tests.

| Seed | Walk distance, each lighting state | Peak live enemies | Hostile packs activated on route |
| --- | ---: | ---: | ---: |
| 1 | 76.2m | 12 grazers | 0 |
| 77 | 64.6m | 2 grazers | 0 |
| 193 | 68.3m | 12 grazers | 0 |

Leaving the approach for the nearest actual hostile anchor activates its native
pack through the ordinary tick: meadow whelps for seeds 1/193, forest hounds for
77. Their normal chase, jumps and attack states are recorded. Seed 1's day walk
also drops from 12 live grazers to 2 as distant calm packs sleep. The existing
319-check lifecycle fixture verifies return, spent packs, noise, cap priority,
foreign routes and night-three siege eligibility. No missing-index or premature
terrain-retirement failure was found in these samples.

Retained views include the start, middle and quarry end of each day walk,
the dusk endpoint, and day/night hostile encounters. Examples:
[seed 1 quarry](references/population-2026-09-08/seed-1-quarry-day-59.png),
[seed 77 approach](references/population-2026-09-08/seed-77-quarry-day-30.png),
[seed 193 dusk](references/population-2026-09-08/seed-193-quarry-night-59.png),
and [seed 77 native hounds](references/population-2026-09-08/seed-77-native-hostiles-day.png).

## Checks and reproduction

| Check | Final result |
| --- | --- |
| Generated grounding, routes, candidate order, cave floor and excavation | 338 / 354 / 328 checks for seeds 1 / 77 / 193; zero failures |
| Full engine script suite | 398 checks; zero failures |
| Existing indexed population lifecycle | 319 checks; zero failures |
| Existing horde / loot persistence / integration | 43 / 30 / 273 checks; zero failures |
| V6 terrain retirement, excavation and finite-source lifecycle | 75 checks; zero failures |
| Historical weathered save | 21 checks; zero failures |
| Full rendered walks and automatic encounters | 14 checks per seed; zero failures |
| Native before/after identity | Matching SHA-256 of voxels, pack records and finite resource records for all three seeds; all horizontal runtime positions also match |

The isolated roots are `build/frontier-population/{baseline,current}` and
`build/frontier-population/appdata/{baseline,current}`. Logs are under
`build/frontier-population/logs`. The native extension and tuning were unchanged;
no replacement of the owner's loaded DLL was needed. Example commands:

```powershell
./tools/home_review.ps1 -ReviewSet frontier-population -Phase current -Prepare -Import -Scenes population_grounding,population_audit -Seed 1
./tools/home_review.ps1 -ReviewSet frontier-population -Phase current -Rendered -Scenes population_walk -Seed 77 -ExtraArguments '--weathered-look'
```

Repeat for the other seeds. Preserve baseline before production changes; the
baseline runner replays only common test fixtures. Its grounding test is expected
to exit nonzero. `tools/population_report.py` compares measurements and draws the
maps with the already bundled Pillow, then copies unedited captures to its output
directory. No dependency was added to the game.

## Limits and proposed follow-up

This does not identify the owner's exact encounter or certify every cave and
cliff. Open-world enemies still use D-012's simple chase/hop rules, so steep
terrain can interrupt pursuit. Fixing spawn support is not a general navigation
system. Existing session sleep and spent-pack rules are unchanged; this is not
a population-persistence redesign. The sparse middle distance and final encounter
comfort remain owner review items.

**Proposal only, not approved or implemented:** if a more threatening quarry
journey is wanted, evaluate a versioned generator successor with an explicitly
reviewed hostile encounter on the outward side of the existing 190m boundary,
reachable from the resource approach. Keep the inner starter catchment calm,
use the real underlying biome, compare several seeds, and keep older profiles
and saves exact. Also audit post-composition regional den coverage explicitly,
rather than relying on a whole-world pack total. A higher global density/cap or retroactive saved-world spawns
are not selected. INT-02B remains the next separate planned slice.
