# Project Wroughtwild

Project Wroughtwild is an early single-player sandbox ARPG prototype built around one core loop:

> See an ambition → identify the missing capability → explore, fight, craft or build toward it → realise the ambition → choose the next one.

The intended game combines self-directed construction, persistent ARPG buildcraft, repeatable variable trials, useful craft-skill progression and gradual production automation. The repository holds the design, an engine-neutral rules library with a playable text slice, and the **Godot 4.5-stable** engine project in `game/` (accepted in [ADR-0001](docs/decisions/ADR-0001-engine-selection.md) on 31 August 2026).

## Run it

- **Engine project:** download Godot 4.5-stable (single executable) and open `game/project.godot`, or `godot --path game`. Headless checks: `GODOT=/path/to/godot game/run_headless_checks.sh`. See [game/README.md](game/README.md).
- **Rules tests (no engine, needs g++ and make):** `cd tests/sim && make`.
- **Text playtest of the whole slice:** `cd tools && make build/playtest && ./build/playtest ../data/tuning`.

## Start here

1. Read [docs/DESIGN.md](docs/DESIGN.md) for the game vision and current boundaries.
2. Read [docs/prototype/vertical-slice.md](docs/prototype/vertical-slice.md) for the first playable target.
3. Check [docs/decisions/registry.md](docs/decisions/registry.md) before making design assumptions.
4. Read the relevant file under [docs/systems](docs/systems) before implementing a system.
5. AI coding agents must follow [AGENTS.md](AGENTS.md).

## Current phase

**Phase:** Vertical-slice greybox in Godot 4.5 (engine accepted 31 August 2026); rules already playable headless via `tools/playtest`.

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
spikes/godot4/                 ADR-0001 Godot 4.5 comparative spike (historical; seeded game/)
third_party/godot-cpp          Submodule: Godot's GDExtension C++ bindings (pinned godot-4.5-stable)
game/                          Godot 4.5-stable engine project (presentation layer)
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
