# Test Strategy

Prioritise deterministic rules and regression-prone interactions.

## Available now: headless simulation tests

`tests/sim/` tests the engine-neutral rules library in `sim/` directly against
`data/tuning/*.json` — no engine required:

```sh
cd tests/sim
make
```

Current coverage: tuning loading, craft-skill XP curve and level clamp,
crafting gates (station, skill, inputs), repetition decay and its order
exemption, order fulfilment and consumption, salvage, deterministic item
property rolls with tag/tier bounds, boon offer rules and compatibility,
persistent-versus-temporary run-state cleanup, an end-to-end vertical-slice
economy spine (gather → craft → order → level → forge upgrade → armour),
derived stats and damage mitigation, catalyst tempering (skill gate, bounded
rolls, preservation, determinism), station construction costs, seeded combat
(boon/weakness effect interpretation, determinism), trial death contracts
(deposit/restore, catalyst survival, boon cleanup, full run to boss kill),
and save/load round-trips.

`tools/` adds two headless executables on the same rules: a playable text
version of the whole slice and a balance simulator (see `tools/README.md`).

The engine project's in-engine checks run fully headless:
`game/run_headless_checks.sh` (unit tests, a physics integration test of the
placement loop, and a scene smoke run; see `game/README.md`). Run them before
every commit touching `game/`.

The historical Godot spike keeps its own copy of these checks
(`spikes/godot4/run_headless_checks.sh`). The Unreal 5.8 spike was removed
from the tree after ADR-0001 was accepted; its source and automation tests
remain in git history (see the ADR's spike status).

Expected test categories:

- crafting costs and output;
- craft-skill XP and repetition decay;
- order fulfilment and consumption;
- equipment property generation;
- catalyst influence and preservation;
- persistent versus temporary effect cleanup;
- boon tag compatibility;
- death inventory rules;
- save/reload;
- world-seed progression guarantees;
- construction material accounting.

Where engine-level automation is difficult, build small headless simulations for economy and balance curves.
