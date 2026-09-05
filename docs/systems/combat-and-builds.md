# Combat and Persistent Builds

**Status:** Core philosophy accepted; implementation open  
**Related decisions:** D-001, D-004

## Purpose and player fantasy

The player owns a persistent build that becomes faster, stronger and more expressive over time. The same underlying skill can behave differently through supports, passives, equipment and class specialisation.

The target is Path of Exile-like expression, not Path of Exile-scale content.

Owner playtest, 5 Sep 2026: ranged mobs feel overly damaging and undodgeable;
skills need stronger visual identities and more distinct delivery/spread/area
behaviours to experiment with. Investigation and a separate skill-vocabulary
design task are recorded in the [priority work list](../prototype/playtest-priorities-2026-09-05.md).
The owner retained gathering and building usability ahead of this larger pass.

The approved ranged-fairness follow-up replaces the instant radial hit for
archers and wisps with aim committed at windup start and a straight travelling
projectile. Sidestepping and solid cover can prevent contact; existing hit
damage and movement-only dash remain unchanged. See the
[implementation and tuning](../art/codex-ranged-fairness-2026-09-05.md).

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

## Verbs: equal threat, different shape (4 Sep 2026, Wave 8 slice 1)

The owner: a slower mob that hits harder is fine "as long as the danger
levels get the same feel as the faster hounds", and never a zone ladder.
So every family carries one **verb** (`combat_realtime.json` behaviours
`verb`, `verb_seconds`, `verb_strength`, `verb_radius_m`,
`verb_arc_degrees`, `verb_cap`), the one thing it does that changes how
you fight, and the sim keeps every family in one **threat band**
(`combat::threatScore`: damage per round × reach × bulk × the verb's
control weight; `tests/sim` asserts each family within 0.55 to 1.6 of
the median and each biome's mean pack threat in one band, the shrieker
aside - its threat is who it invites).

| Family | Verb | In play | Your answer |
| --- | --- | --- | --- |
| Hound (`fast`) | harry | the bite slows you 35 percent for 2.5 s; marked, it sprints | stagger, push, stillness |
| Husk (`guard`) | guard | its front (110 degrees) takes 60 percent less until staggered | flank, stagger, pierce |
| Archer (`ranged`) | mark | marked for 6 s: the hunters run 1.35× at you | kill it first, break the line |
| Lurker (`lurker`) | root | held 1.2 s unless you dash | dash, cold |
| Wisps (`skirmisher`) | kindle | every 4 s lights an ally within 6 m; its bite burns, 25 percent more | cold, or the wisp first |
| Crawler (`swarm`) | swarm | each crawler within 4 m adds 15 percent to the bite, to 60 | area, barbs |
| Knight (`knight`) | ward | allies within 5 m take 30 percent less until it is staggered | stagger the knight |
| Shrieker | recruit | the scream (D-012) | kill it first |
| Whelp (`melee`) | none | the baseline | - |

The engine does what the sim says: `enemy.gd` reads the verb and its
numbers, `bite_damage`/`bite_type` carry the swarm and the kindle,
`guards_against`, `wards`/`warded_by`, `swarm_multiplier`,
`kindle_nearest`; `player_combat.gd` suffers the harry, the root and the
mark (`_suffer_verb`, the HUD's life line reads them), applies the guard
and the ward in `deal`, and a dash breaks a root (`player.gd`). The
knight shows its ward as a pale aura; the verbs colour their families.
The eras transform the verbs (Wave 8 slice 3, `eras.json`
`mob_mechanics`): once the deep wakes the husk's guard covers forty
degrees more and the wisp lights two allies; in the ash tide the lurker
holds 0.6 s longer and the knight's ward takes fifteen points more.

## The train and the ceiling (4 Sep 2026, Wave 7 slice 2)

Density should be the threat. **The train** (`combat_realtime.json`
`horde` `train_window_seconds`, `train_bonus_per_hit`,
`train_max_bonus`): a bite that follows bites from *other* mobs inside
the window lands a bonus harder per earlier mouth, to the cap - a lone
whelp is a chore, three together are a problem. `combat::trainMultiplier`
is the rule; `player_combat.gd` remembers who bit when and the HUD's hit
line reads "Ember Whelp · the train x1.2". **The ceiling**: each era caps
how much of a hit armour may take away (`eras.json`
`armour_reduction_cap`; see progression-eras). The heartland's mobs now
hit harder (whelp 6, hound 4, husk 8) and are fewer (world-generation):
deadly hits and sparse packs early, dense packs and scaled health later,
in the trials.

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

**The horn and the siege (Wave 7 slice 3, 4 Sep 2026).** A shrieker's
kill may leave its horn; the pack carries one (hauling cap 1). X outside build
mode blows it (in build mode X removes the aimed piece):
the `horn` noise, ninety metres, and a ring that tells the radius - every
idle mob and dormant pack inside it comes. It is PoE's map opened on the
player's terms, on day two if they dare, for the drop tables' best; it
rings `horn_cooldown_seconds` between blows. The siege is the night
testing the house: `world.json` `siege` rolls each night from the second
(`daycycle::siegeTonight`, seed and day, so a save replays its nights),
the dusk notice carries the howl, and once the night is old enough and
the player is home the era's pack takes shape in the dark around home,
hunting from the start (`MobPacks.tick_siege`, `spawn_siege`); dawn
dismisses what is left. A chaser pressed against a placed piece
scratches at it once a second (`Enemy._scratch_if_blocked` →
`PlacedBlock.scratch`): the piece shakes, the HUD says "Something
scratches at the wall panel", and a breaker - era 2's husks carry
`breaks_timber` - wears a timber piece down until it gives. Stone and
iron never give. Death sends you home once you have one.
