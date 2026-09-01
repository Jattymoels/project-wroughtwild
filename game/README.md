# Game Project — Godot 4.5-stable

This is the engine project for Project Wroughtwild, accepted in
[ADR-0001](../docs/decisions/ADR-0001-engine-selection.md) on 31 August 2026.
Engine version is pinned to **Godot 4.5-stable**
(`4.5.stable.official.876b29033`); upgrade only through a recorded decision.

It grew out of the ADR-0001 Godot spike (since removed from the tree) and now
holds the **Wave 1 sandpit** (docs/prototype/roadmap-waves.md): a
seed-generated open world of blocky biome terrain — meadow, deep forest,
rocky hills, ember wastes — with scattered trees, boulders and iron veins,
roaming mob packs that drop loot, and a start-with-nothing survival opening:
hand-craft a workbench kit from gathered wood, place it, assemble a forge
kit, place that, and keep the forge fuelled. On top of the sandpit sits the
whole vertical-slice loop: the mine order, real-time combat, the trial and
its boss, armour and catalyst tempering, and save/load (saves carry the
world seed). Every file except the 16×16 pixel textures is text (`.tscn`
scenes included) so the project diffs in Git; `.uid` files are committed on
purpose.

## Run from a clean checkout

> **Build the rules extension first** (next section). Without it the world
> loads but nothing is interactable — you can walk, dodge and jump, while
> harvesting, building and the forge are all dead, because every interactive
> script depends on the compiled `WroughtwildSim` library. The game now shows
> a full-screen notice when this happens instead of failing silently.

1. Download Godot 4.5-stable for your platform (a single executable, no
   installer) and put it somewhere convenient.
2. Open `game/project.godot` with it, or launch directly:

   ```sh
   godot --path game            # play the main scene
   godot --path game -e         # open the editor
   ```

3. The game is **first-person** (D-012); **V** toggles third person for
   debugging. The HUD (docs/systems/interface.md) shows a life bar with
   defences bottom-left, the action bar with cooldown sweeps bottom-centre
   and what you carry top-right; press **I** for the pack screen. Controls: WASD move, mouse look, Space jump, **E** interact (harvest,
   work at a station, read the board, open the gate), **C** craft by hand,
   **B** toggle build mode, **Tab** cycle shapes and crafted station kits,
   **LMB** place (or harvest outside build mode), **X** remove block, **R** rotate (for panels, beams and pillars this also picks which face or corner of the cell they sit against), **1** area strike, **2** heavy strike, **3** Frost Orb
   (the grammar-spike projectile: it forks down a bunched pack and builds
   chill toward a freeze; strike a frozen mob with **1** to shatter it),
   **F1–F3** toggle the three spike skill-mods (Forked Lattice, Deep Frost,
   Wide Shatter — scaffolding until Wave 2 puts mods on gear), **Shift** dash
   (a pure movement burst - no invulnerability, D-012), **I** pack (what you carry and wear, vitals, spike-mod toggles; wear armour here), **H** help overlay, **Esc** close a panel, **F5** save, **F9** load
   (`user://wroughtwild_save.json`). Dying drops your materials in a pack
   where you fell; walk back for it.
4. **The first hour, from nothing:** harvest trees (E) → **C** → craft the
   Workbench Kit → **B**, **Tab** to the kit, place it → E the bench to
   assemble a Forge Kit (needs wood, stone from boulders, iron ore from
   veins — the rocky hills have both, and their Stone Husks drop them too)
   → place the forge → keep it fed with wood or charcoal, because every
   smelt and forging burns fuel. Harvests and mob kills pay out as glowing
   material chips that pop out, bounce, and vacuum into you when you walk
   near (the green ticker under the notices counts them in); nodes visibly
   wear down as you work them and shrink away when spent. The thing under
   your crosshair names itself ("wood ×12 — E to gather") and harvestables
   glow while you look at them. Mob packs wake as you approach; every kill
   scatters loot where the mob fell. Light follows the land (D-013): safe
   biomes are bright and saturated, the deep forest closes in, and the
   Ember Wastes drain the light before the first pack appears. Chasers are D-012 stupid zombies: they
   keep coming while you stay near (bunch them and pay the train off with
   the cone-shaped area strike), give up only when you genuinely run, and
   an idle stray joins the fight the moment you hit it. The crosshair reads
   your aim (green = E-interact in reach, red = enemy in melee reach) and
   blips on a landed hit.
5. The **trial gate** waits far out in the ember wastes. E stows your goods and opens the
   run: pick a door, clear the room in the arena, take or refuse what the
   shrine offers, bank out after the catalyst shrine or push on to the Forge
   Tyrant. Its breath is telegraphed (it glows and the HUD warns you); step
   or dash OUT of the cone - dash is pure movement now, with no
   invulnerability (D-012). Dying in the trial returns you to the
   gate with your deposit and any catalyst; run materials are lost. E inside
   the run brings the doors back if you closed the panel.
6. Back at the forge: wear crafted armour, **Quench** it at the Improved
   Forge for a fixed baseline of fire resistance, and **Ember-temper** it with
   a recovered catalyst (Blacksmithing 5) for a rolled tier-2 resistance;
   the panel states each effect before anything is consumed. Killing the
   Tyrant unlocks the **Stonecut Slab** shape: **Tab** cycles shapes in build
   mode.

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
integration test of the full placement loop (`tests/integration.tscn`) → the
D-012 horde test (`tests/horde.tscn`: chase persistence, training
separation, give-up, cone strike, dash) → the grammar-spike test
(`tests/grammar.tscn`: orb flight and forking, freeze breakpoints, the
shatter cascade) → the world-feel test (`tests/feel.tscn`: pickup magnet
and absorb-to-grant, harvest feedback, buffered jump) → a 120-frame smoke
run of the main
scene. Non-zero exit on any failure. Run this
before every commit that touches `game/`.

## Layout

```text
project.godot           Project settings, input map, autoloads (text)
scenes/                 Greybox scenes (player, resource node, placed block, forge site, order board,
                        enemy, boss, dropped pack, trial gate, trial arena, valley)
scripts/                Presentation/input scripts: player, placement, player combat (timers and
                        targeting only), enemy behaviours, boss, trial controller (doors/fight/
                        reward flow over the sim's TrialSession), station site, order board, HUD,
                        work panel, save manager. No rules live here (ADR-0003).
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
