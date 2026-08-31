# Headless Tools

Both tools run anywhere with a C++ compiler — no game engine required. They
sit on top of the engine-neutral rules library in `sim/`, which is exactly the
role the eventual 3D engine will play.

## Text playtest — play the vertical slice today

The complete design loop (gather → build a forge → fulfil the mine order →
level Blacksmithing → upgrade the forge → craft and temper armour → run the
trial → recover the Ember Catalyst → ember-temper → defeat the Forge Tyrant →
unlock a new construction material) playable in a terminal.

```sh
cd tools
make build/playtest
./build/playtest ../data/tuning        # interactive
./build/playtest ../data/tuning auto   # combat plays itself (for scripts)
```

Type `help` in game. Combat is round-based: `a` area strike, `h` heavy
strike, `d` dash (dodges the round — watch for the boss's fire warning),
`w` wait. `save`/`load` exercise the real save schema.

What to evaluate while playing (the vertical-slice tuning questions):

- Do you understand why the trial is hard before you have fire resistance?
- Does the mine order make fitting production feel useful?
- Does the ember-tempering moment feel worth another trial run?
- Does dying make you want to re-enter?

## Balance simulator — thousands of playthroughs per second

```sh
cd tools
make balance
```

Reports Blacksmithing pacing (useful work vs spam), catalyst roll
distributions, boss win rates per gear stage (2000 seeds each) and full-trial
completion rates. Re-run after any change to `data/tuning/` to see what the
change does to the difficulty story before anyone plays it.
