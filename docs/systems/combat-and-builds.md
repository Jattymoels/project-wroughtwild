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
