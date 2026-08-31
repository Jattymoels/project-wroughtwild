# Game Project — Godot 4.5-stable

This is the engine project for Project Wroughtwild, accepted in
[ADR-0001](../docs/decisions/ADR-0001-engine-selection.md) on 31 August 2026.
Engine version is pinned to **Godot 4.5-stable**
(`4.5.stable.official.876b29033`); upgrade only through a recorded decision.

It was seeded from the verified `spikes/godot4/` scaffold and currently
contains the greybox vertical-slice valley: a controllable capsule, harvestable
resource nodes, a material-family inventory and grid snap-placement with a
green/red preview. Every file is text (`.tscn` scenes included) so the whole
project diffs in Git; `.uid` files are committed on purpose.

## Run from a clean checkout

1. Download Godot 4.5-stable for your platform (a single executable, no
   installer) and put it somewhere convenient.
2. Open `game/project.godot` with it, or launch directly:

   ```sh
   godot --path game            # play the main scene
   godot --path game -e         # open the editor
   ```

3. Controls: WASD move, mouse look, Space jump, **E** interact (harvest a
   node, build or use the forge, read the mine board), **B** toggle build
   mode, **LMB** place (or harvest outside build mode), **X** remove block,
   **R** rotate preview, **1** area strike, **2** heavy strike, **Shift**
   dash (brief invulnerability), **Esc** close a panel, **F5** save, **F9**
   load (`user://wroughtwild_save.json`). Harvesting the iron node can
   trigger the Old Mine ambush from `world.json` until the mine order is
   fulfilled; dying drops your materials in a pack where you fell.

## Build the rules extension (once per checkout, and after `sim/` changes)

The economy rules are compiled into the project as a GDExtension
(`extensions/wroughtwild_sim`, binding the `../sim` library through
`godot-cpp`). Needs CMake ≥ 3.22, Python 3 (godot-cpp's binding generator)
and a C++17 compiler (MinGW-w64 GCC on Windows, clang/gcc elsewhere):

```sh
git submodule update --init                       # third_party/godot-cpp, pinned godot-4.5-stable
cmake -S game/extensions/wroughtwild_sim -B build/gdext -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build build/gdext -j
```

This produces `bin/libwroughtwild_sim.<platform>.x86_64.<ext>` next to the
committed `bin/wroughtwild_sim.gdextension`. Binaries are ignored by Git.
Without it the project still opens, but `tests/run_tests.gd` fails its
`sim:` checks and any script calling `WroughtwildSim` errors.

## Automated checks (headless, no GPU)

```sh
GODOT=/path/to/Godot_v4.5-stable ./run_headless_checks.sh
```

Runs project import → unit tests (`tests/run_tests.gd`) → in-engine physics
integration test of the full placement loop (`tests/integration.tscn`) → a
120-frame smoke run of the main scene. Non-zero exit on any failure. Run this
before every commit that touches `game/`.

## Layout

```text
project.godot           Project settings, input map, autoloads (text)
scenes/                 Greybox scenes (player, resource node, placed block, forge site, order board,
                        enemy, dropped pack, valley)
scripts/                Presentation/input scripts: player, placement, player combat (timers and
                        targeting only), enemy behaviours, station site, order board, HUD, work
                        panel, save manager. No rules live here (ADR-0003).
extensions/             wroughtwild_sim GDExtension source + CMake (binds ../sim)
bin/                    .gdextension descriptor (committed) + built binaries (ignored)
tests/                  Headless unit + integration tests
run_headless_checks.sh  The check pipeline above
```

## Boundaries

- **Rules live in `sim/`, not here.** The engine-neutral C++17 library in
  `../sim` is the source of truth for crafting, skills, items, boons, combat,
  trials and saves, regression-tested in `../tests/sim`. Scripts here may
  duplicate only trivial glue (grid maths, inventory counts). The binding from
  `sim/` into Godot is a GDExtension using `godot-cpp`, the one third-party
  dependency approved by ADR-0001.
- The `Sim` autoload (`scripts/sim.gd`) owns the one `WroughtwildSim`
  instance and loads `../data/tuning/*.json` through it at startup. Inventory
  counts, construction costs and refunds, grid size and placement range all
  come from there; never hard-code tunables in scripts. Headless `--script`
  tests get an isolated instance via `sim.gd`'s `shared()` fallback.
- Keep `.godot/`, exports and editor state out of Git (see `.gitignore`).
  After an editor session, check `git status`: the editor may rewrite the
  header comment of `project.godot`; restore it if so.

## Known engine issue

On a fresh `.godot/` (clean checkout, or after deleting the cache) the very
first `--headless --import` can segfault at the end while Godot 4.5 generates
documentation for the newly discovered GDExtension
([godotengine/godot#111645](https://github.com/godotengine/godot/issues/111645)).
The import work itself completes and every later run is clean;
`run_headless_checks.sh` retries the import once for this reason. Opening the
project in the editor for the first time may likewise crash once — reopen it.
