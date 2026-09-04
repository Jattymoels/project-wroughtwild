# Wroughtwild — Master Design

**Status:** Early concept  
**Design version:** 0.6  
**Prototype status:** Not yet implemented

## Pitch

A self-directed sandbox ARPG where the player builds a frontier operation, explores a dangerous world and uses targeted gathering, useful crafting work and repeatable trials to unlock increasingly expressive construction and persistent character builds.

## Core fantasy

The player begins with common materials, crude tools and a small shelter. The world already contains visible places, resources and threats beyond their current capability.

> See something desirable → discover what capability is missing → prepare and progress → claim it → build or craft something previously impossible → choose the next ambition.

The player is both an adventurer and a maker. Progress is visible in the character, equipment, workshops, transport network, outposts and eventual main settlement.

## Working identity

- **Minecraft-style self-directed discovery and constrained construction**
- **Hades-style repeatable trials, branching choices, secrets and interacting temporary boons**
- **Path of Exile-style persistent loot, crafting and build expression**
- **Expert-modpack-style production gates and earned automation**
- **An unscaled frontier that presents ambitions before the player can achieve them**

These references describe design influences, not a promise to reproduce their content scale.

## Design pillars

1. **The world does not wait for the player.** Desirable and dangerous content may appear nearby long before it can be conquered.
2. **Progression expands vocabulary.** New tiers unlock behaviours, materials, shapes and interactions—not only larger numbers.
3. **Goals are self-directed.** The game supplies constraints and opportunities; the player decides what to pursue.
4. **Building and combat share an economy.** Trials improve crafting and construction; infrastructure improves expedition capability.
5. **Power spikes are felt.** A new equipment interaction, resistance solution, tool or production tier materially changes play.
6. **Failure is diagnostic.** Death should communicate mechanics, insufficient power, run adaptation or a deliberate build weakness.
7. **Friction should produce value.** Repetition is welcome when its outputs satisfy real trade, infrastructure or creative demand.

## Primary loop

1. Observe an inaccessible goal.
2. Identify blockers: threat, distance, tool, skill, resistance, resource or technology.
3. Complete achievable gathering, construction, trade or combat work.
4. Improve equipment, craft skill, facilities or transport.
5. Undertake a targeted expedition or repeatable trial.
6. Recover materials, catalysts, knowledge or equipment.
7. Convert those rewards into a new capability.
8. Re-attempt the goal and choose the next ambition.

## Progression layers

### World and settlements

The prototype uses a bounded seed-generated region. Terrain, biome placement, elevation and resources vary, while critical class halls, settlements and trials use authored modules with guaranteed placement rules.

The long-term settlement arc is:

> Shelter → resource outposts → transport network → ambitious main settlement.

### Construction

Construction uses a consistent grid with forgiving physics. Materials are gathered by family and refined into an unlocked shape palette. Functional objects suggest architecture without prescribing it: an enchanting table can live in a tower, library, cellar or outdoor shrine.

See [systems/construction.md](systems/construction.md).

### Craft skills and production

Crafting uses four complementary gates:

1. knowledge;
2. minimum skill;
3. facility and power;
4. resources.

Early scarcity establishes value before mechanical assistance and automation multiply production. Repeated crafting should satisfy useful demand such as orders, mine reinforcement, rails, tools and machine components.

See [systems/crafting-and-skills.md](systems/crafting-and-skills.md).

### Character build

Most direct power comes from persistent skills, passive choices and equipment. Baseline equipment permits careful survival; exceptional loot and advanced crafting create speed, damage and defensive power spikes.

A starting class provides initial identity and leads toward an authored class hall that opens a further vertical specialisation path.

See [systems/combat-and-builds.md](systems/combat-and-builds.md).

### Repeatable trials

The permanent build enters intact. Branching rooms, boons, weaknesses and secrets temporarily alter how that build handles the current attempt without replacing it.

See [systems/dungeon-runs.md](systems/dungeon-runs.md).

### Loot and crafting catalysts

Physical resources establish an item's base. Skills, facilities and recipes provide controlled processes. Rare combat and exploration catalysts influence tempering, quenching, engraving, preservation and unusual modifier interactions.

See [systems/loot-and-currency.md](systems/loot-and-currency.md).

### Eras and the Foundry

The world is the campaign: it changes state in eras on milestones the
player chooses to hit, and never adds a zone. Points are ingots placed on
a forged plate; ores are properties rather than ranks. See
[systems/progression-eras.md](systems/progression-eras.md) (D-019).
The plate is worked in **workings**: a subject in a socket, supports
beside it, augments in the corners, class rails at the edge. See
[systems/foundry.md](systems/foundry.md) (D-023, proposed).

## Death contracts

- Before a structured trial, ordinary carried possessions are stored at the entrance.
- Trial death does not remove permanent equipment or settlement progress.
- Open-world death drops carried inventory for recovery.
- Equipment binding is a provisional progression mechanic that eventually returns important equipment with the player.
- Permanent deletion of build-defining items is not intended.

## Progression arc

**Early — Survive and imagine:** establish shelter, fear dangerous regions and manually gather valuable materials.

**Midgame — Target and expand:** develop a build, establish outposts, fulfil larger production demands and unlock transport.

**Late game — Master and specialise:** maintain specialised equipment, automate common resources and construct an ambitious main settlement.

**Endgame — Manufacture challenges:** eventually modify increasingly difficult trials for rare build and crafting rewards. Endgame is outside the initial prototype.

## Prototype boundary

The first slice is deliberately small:

- one player class and class-hall path;
- one bounded region;
- a few construction shapes and materials;
- one useful craft-skill demand chain;
- one forge upgrade;
- one repeatable trial and boss;
- a small boon and catalyst pool;
- no co-op, raids, infinite world or broad automation.

See [prototype/vertical-slice.md](prototype/vertical-slice.md).

## Current highest-risk design question

The loot/crafting economy must make all three routes valuable:

- drops provide excitement and shortcuts;
- infrastructure provides dependable access and control;
- advanced crafting provides optimisation.

If one route dominates, another major system becomes irrelevant.

## Documentation map

- [GLOSSARY.md](GLOSSARY.md)
- [prototype/vertical-slice.md](prototype/vertical-slice.md)
- [prototype/acceptance-criteria.md](prototype/acceptance-criteria.md)
- [systems/construction.md](systems/construction.md)
- [systems/crafting-and-skills.md](systems/crafting-and-skills.md)
- [systems/combat-and-builds.md](systems/combat-and-builds.md)
- [systems/dungeon-runs.md](systems/dungeon-runs.md)
- [systems/loot-and-currency.md](systems/loot-and-currency.md)
- [systems/world-generation.md](systems/world-generation.md)
- [systems/progression-eras.md](systems/progression-eras.md)
- [systems/foundry.md](systems/foundry.md)
- [decisions/registry.md](decisions/registry.md)
- [research/engine-ai-integrations.md](research/engine-ai-integrations.md)
