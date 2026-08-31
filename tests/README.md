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
persistent-versus-temporary run-state cleanup, and an end-to-end
vertical-slice economy spine (gather → craft → order → level → forge upgrade
→ armour).

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
