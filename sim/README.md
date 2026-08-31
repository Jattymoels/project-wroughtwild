# Engine-Neutral Simulation Core

Portable C++17 rules library for Wroughtwild's deterministic gameplay economy.
It has no engine or third-party dependencies, so it can be compiled headless for
tests here and later into whichever engine ADR-0001 accepts.

## Contents

```text
include/wroughtwild/json.h      Minimal JSON reader (tuning files only)
include/wroughtwild/tuning.h    Typed loading of data/tuning/*.json
include/wroughtwild/economy.h   Craft skills, recipes, repetition decay, orders, salvage
include/wroughtwild/items.h     Deterministic equipment property rolls
include/wroughtwild/boons.h     Trial boon/weakness offers; run state vs persistent build
src/                            Implementations
```

## Rules source

All numbers come from `data/tuning/*.json`. The library refuses to craft, level
or offer anything the data does not define.

Provisional rules implemented here (flagged in code, not accepted decisions):

- **Repetition decay curve** (open question in
  `docs/systems/crafting-and-skills.md`): after `full_xp_repetitions` crafts of
  the same recipe, XP multiplier = `full_xp_repetitions / repetition_index`,
  floored at `minimum_multiplier`. Order-directed crafting ignores decay per
  `crafting.json`.
- **Salvage** returns `floor(input × salvage_return_fraction)` per input
  material of the recipe that produced the item.

Catalyst tempering is deliberately **not** implemented: D-007 (crafting
economy / catalysts) is a high-priority open decision.

## Running tests

```sh
cd tests/sim
make          # builds with g++ -std=c++17 and runs the suite
```
