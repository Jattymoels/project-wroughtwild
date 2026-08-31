# Project Wroughtwild

Project Wroughtwild is an early single-player sandbox ARPG prototype built around one core loop:

> See an ambition → identify the missing capability → explore, fight, craft or build toward it → realise the ambition → choose the next one.

The intended game combines self-directed construction, persistent ARPG buildcraft, repeatable variable trials, useful craft-skill progression and gradual production automation. The current repository is a design and prototype scaffold; no engine has been selected and no production game code exists yet.

## Start here

1. Read [docs/DESIGN.md](docs/DESIGN.md) for the game vision and current boundaries.
2. Read [docs/prototype/vertical-slice.md](docs/prototype/vertical-slice.md) for the first playable target.
3. Check [docs/decisions/registry.md](docs/decisions/registry.md) before making design assumptions.
4. Read the relevant file under [docs/systems](docs/systems) before implementing a system.
5. AI coding agents must follow [AGENTS.md](AGENTS.md).

## Current phase

**Phase:** Pre-production design and vertical-slice planning.

The prototype intentionally excludes co-op, raids, an infinite world, extensive automation, multiple complete classes and a large construction catalogue. Its purpose is to prove that returning from a trial makes the player excited to improve their build, base or production capability—and that those improvements make them want to venture out again.

## Repository map

```text
docs/DESIGN.md                 Master design and system relationships
docs/GLOSSARY.md               Shared vocabulary
docs/SYSTEM_SPEC_TEMPLATE.md   Template for new system specifications
docs/prototype/                Vertical-slice scope and acceptance criteria
docs/systems/                  Focused gameplay system specifications
docs/decisions/                Decision registry and architecture records
docs/research/                 Time-stamped external research notes
data/tuning/                   Engine-neutral tuning placeholders
sim/                           Engine-neutral C++ simulation core (rules layer)
tools/                         Text playtest of the vertical slice + balance simulator
spikes/unreal58/               ADR-0001 Unreal Engine 5.8 comparative spike
spikes/godot4/                 ADR-0001 Godot 4.5 comparative spike (headless-verified)
game/                          Future engine project (after ADR-0001 acceptance)
tests/                         Automated and simulation tests (tests/sim runs headless)
```

## Development principles

- Keep game rules data-driven where practical.
- Separate permanent progression from run-specific dungeon effects.
- Prefer useful friction over arbitrary grind.
- Treat building, combat and crafting as one economy.
- Prototype one complete return loop before adding content breadth.
- Record meaningful design decisions rather than silently embedding them in code.

## Licence

No licence has been selected. All rights are reserved until one is added explicitly.
