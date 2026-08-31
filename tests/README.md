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

Engine-side automation tests for the Unreal spike live in
`spikes/unreal58/Source/Wroughtwild/Tests/` and run from the editor.
The Godot spike's in-engine checks run fully headless:
`spikes/godot4/run_headless_checks.sh` (see `spikes/godot4/SPIKE.md`).

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
