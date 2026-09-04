# Combat and Persistent Builds

**Status:** Core philosophy accepted; implementation open  
**Related decisions:** D-001, D-004

## Purpose and player fantasy

The player owns a persistent build that becomes faster, stronger and more expressive over time. The same underlying skill can behave differently through supports, passives, equipment and class specialisation.

The target is Path of Exile-like expression, not Path of Exile-scale content.

## Prototype scope

- one starting class;
- two or three active skills;
- a small passive or upgrade tree;
- several support-style modifiers;
- life, defence and one elemental resistance;
- clear-speed versus single-target trade-off;
- one representative class-hall upgrade path;
- simple placeholder animations and effects.

## Persistent build layers

1. Starting class and initial attributes or mechanics.
2. Active skills.
3. Support or behaviour modifiers.
4. Passive investments.
5. Equipment bases and properties.
6. Class-hall specialisation.

Temporary trial boons are not part of persistent build storage and must be visually and technically distinguishable.

## Power philosophy

- Baseline equipment with adequate life and resistance permits careful, slow progress.
- Endgame-quality equipment would create speed, damage, coverage and strong defence.
- Offensive safety comes from removing threats quickly; defensive safety comes from mitigation and sustain.
- Builds may deliberately trade boss damage for clear speed, coverage for concentration or damage for durability.
- No prototype build should solve every axis simultaneously.

## Class hall

The chosen class points toward an authored class hall guaranteed within the generated world. Finding it opens another vertical path, similar to a specialisation or ascendancy, while preserving access to broader build systems.

The prototype implements only one representative hall and one meaningful choice.

**Made concrete 4 Sep 2026 (D-023 slice 9).** The class - Ranger,
Warden or Kindler - is chosen before play begins, and its two rail
patterns are the Foundry plate's surround from era one. Completing the
first trial offers a specialisation from the class's two, each shown as
what every pattern becomes; until the hall is built as an authored
module, the Tyrant's forge stands in for it. See
[foundry.md](foundry.md), "Rails". The class also sets the starting
skills (4 Sep 2026, later): a bow shot for the Ranger, strikes and a
nova for the Warden, a bolt and a burning sweep for the Kindler, the
Dash for everyone; the base four are pages for the classes without
them.

## Melee's space control (4 Sep 2026)

The grammar doc's "knockback / stagger: physical space control", built.
A strike or a sweep carries three numbers in `skills.json`:
`stagger_seconds` (the mob it hits halts that long and loses its wind-up:
the heavy strike 0.4, Rend 0.3, the area strike 0.15, the cinder sweep
0.1), `push_m` (it is shoved that far along the blow: the area strike
1.2, the sweep 0.8, the heavy strike 0.5, Rend 0.3) and `swing_armour`
for `swing_seconds` (the armour committing to the swing grants you: the
heavy strike 12 for half a second, Rend 10, the area strike 8, the sweep
6 - on the same clock as the Plate reading's armour on cast, which adds
to it). A boss takes half the stagger and none of the push
(`grammar.json` `hooks.melee`). The sim resolves all three
(`add_stagger`, `add_push`, `add_armour_on_cast`), so a modifier or a
rail can grow them; the engine halts the mob (`Enemy.stagger`) and pays
the shove over a tenth of a second whatever the mob was doing
(`Enemy.shove`). Tests: sim 3678, integration 225, grammar 68 (a staggered
whelp, a braced swing, a shoved line).

## Tags

Skills and effects should use composable tags such as:

- attack;
- spell;
- projectile;
- area;
- fire;
- physical;
- movement;
- defensive;
- persistent;
- triggered.

Boons and item properties should query tags rather than hard-code every skill name where practical.

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Base damage and cadence | Core feel and time-to-kill |
| Area size | Clear speed and positioning demand |
| Single-target scaling | Boss viability |
| Life and mitigation curves | Forgiveness and defensive value |
| Resistance cap/effect | Strength of preparation requirement |
| Support multipliers | Build-expression power and interaction risk |
| Passive-point rate | Frequency of permanent decisions |
| Respec cost | Experimentation versus commitment |

## Failure cases

- Supports become obvious damage multipliers rather than behavioural choices.
- One defence is mandatory for every build.
- Temporary boons overpower permanent investment.
- Visual effects make mechanics unreadable.
- Class choice becomes either meaningless or permanently restrictive.
- Equipment upgrades become pure gear-score increases.

## Prototype acceptance

- The class has a recognisable play pattern before entering a trial.
- At least two viable configurations express a clear trade-off.
- Equipment preparation visibly changes boss survivability.
- A temporary boon changes the run without changing the stored build.

## Open questions

- Division between class skills, common skills, loot and specialist teaching.
- Passive-tree topology.
- Respec philosophy.
- Persistent-to-temporary power budget.

## Population (3 Sep 2026)

The owner's crowds lagged a good PC. Three causes, three rules. Every mob
registers in `MobGrid` (a 3 m spatial hash, double-buffered per physics
frame) and every "who is near me" - separation, the shrieker's scream,
ignite proliferation - reads a few buckets instead of the whole enemies
group. `MobPacks` caps the live population (`combat_realtime.json`
`horde.max_live_mobs`) and puts a woken pack back to sleep when all its
members are calm, unhurt for `sleep_after_seconds` and `sleep_range_m`
from the player: survivors return at full life when you come back, the
dead stay dead, and a returning pack is exactly its survivors (no second
helping of era bonuses). Trial-bound mobs never sleep.

**Noise and patrols (Wave 7 slice 1, 4 Sep 2026).** The world hears what
you do. `combat_realtime.json` `noise` carries a radius per source kind -
a press (`work`), a blow on a set wedge (`strike`), a boulder cracking
(`rock_crack`), a tree coming down (`tree_fall`), a hit landing either
way (`fight`, at most once a second), the shrieker's horn (`horn`, slice
3) - and `MobPacks.noise_at` wakes every idle mob and dormant pack inside
it, the shrieker's scream generalised. A source inside a closed room
carries `muffle` of its radius: walls are why the house matters at
night. Patrolling packs (the biome's `patrols` flag, worldgen's route)
stand wherever the night has walked them (`pack_position`); their calm
members roam toward that place at a walk (`Enemy.roam_to`) and are back
in the den by dawn.
