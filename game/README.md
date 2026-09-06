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
world seed and generation profile). Scenes and rules remain text; the curated
Blender-study meshes live under `assets/authored`. `.uid` files are committed
on purpose.

## Run from a clean checkout

The approved world/trial intensives add three resource habitats and eight
finished building materials. New worlds now use `frontier_v5`; loading an older save
keeps its original `legacy_v1`, `frontier_v2`, `frontier_v3` or `frontier_v4` geography. Quarry deposits provide slate and
shellstone, fen banks provide clay and reed, and oldgrowth provides resinheart
and separate corkbark. Refine at the existing yard, bench or forge. The build
palette includes Light Panel and Fixed Glazed Window; reed/cork are coverings,
and pitched roofs still require the existing stonecut unlock.

The Strange Frontier expands new worlds to 512 × 512 m with Rootvault Wildwood,
Lantern Fen and Glasswind Uplands. Look for papery husks, taut roots, lightning
scars, sideways iron grit and empty vent cases. **E** works each finite specimen;
the inventory guide's **Wild finds** tab explains stages and uses. At a workbench,
assemble the lamp, winch, landing, lever, sorter or bellows. Place kits with
**B → Tab**, then **E** for controls. Wind/load the winch, link its landing, and
link a Stormglass lever to trigger it. Ordinary crank operation also works.
**X** dismantles fixtures and recovers their rare core and contents. F5/F9 saves
and restores partial harvesting, links, energy and cargo mid-trip. Existing saves
can obtain components from the previewed completion haul of repeatable Forge runs.

The approved [Cataclysm intensive](../docs/prototype/cataclysm-world-intensive-2026-09-06.md)
keeps that finite world size and connects its discoveries through impact scars,
broken/buried/exposed traces and six small supported ruins. Follow the remnants
of dwellings, waterworks and shelters toward existing rare sources; the Forge
also has a related threshold. These places express the same extreme augmentation
already present in the bench, forge and Foundry. V4 traces remain evidence to
explore; the separate V5 pressure pocket below is the sole source. Old saves
retain their historical generators and receive no new ruins or geography.

Reviewed local mob meshes now use the normal gameplay spawn and motion paths,
with existing bodies, attack clocks and status feedback. Workstations share
restrained recovered components; common broadleaf trees and boulders gain related
detail only inside V4/V5's native augmentation influence. See [generation and compatibility](../docs/art/cataclysm-generation-2026-09-06.md),
[authored kit](../docs/art/cataclysm-kit-2026-09-06.md), and [actor/craft integration and limits](../docs/art/cataclysm-actor-craft-2026-09-06.md).
The owner accepts the current visual finish for now. Performance and ordinary
discovery/combat playtests remain distinct from native and isolated asset checks.

The [pressure workshop](../docs/prototype/pressure-workshop-2026-09-06.md) adds
one V5 hearth accidentally struck by an asteroid. It belonged to an old smithy
before the catastrophe. **E** inspects its finite pressure. At a workbench craft
a pressure feeder, place it beside your own newly placed basic forge, then use
**E → Attach forge and pocket**. Load clay and fuel, draw pressure (or wind by
hand) and start a four-cycle batch. Collect the bricks to build. F5/F9 preserves
mid-cycle work exactly; leaving the area or entering a trial pauses it. V4 and
older saves keep their geography; the feeder still works by hand with a newly
placed forge. Current visual finish is accepted for now; further graphics are
deferred. Test scenes: `pressure_workshop.tscn` and `pressure_feeder_presentation.tscn`.

Use **E** at the Trial Gate for the two-floor Tyrant, Warden and Ash Tide
stories. Inside, inspect physical route markers, defeat the local encounter,
then collect its offering. A cleared descent lift offers Continue, Bank and
leave, or Suspend and quit. **F5** also suspends when standing at that lift;
the next normal launch offers Resume. Suspension retains current life, effects
and unbanked loot. The capstone unlocks selectable repeatable tiers and three
stable run offers. Numerical difficulty and the twenty-/ten-minute full-run
targets remain provisional pending combat playtesting.

Review fixtures are `res://tests/world_intensive.tscn`,
`res://tests/material_intensive.tscn`, `res://tests/trial_intensive.tscn`,
`res://tests/trial_balance.tscn` and `res://experiments/forge_review.tscn`.
The first three run in the standard headless check helper. Balance uses actual
fixed-build casts; the lifecycle test uses forced kills only to verify state.

Building: press **B**, then **Tab** for the visual shape/material picker.
Select a card, inspect its direction with the turn buttons, and use the selection.
**R** rotates in the world; the arrow marks the front. Placement failures now
explain what is blocking the piece. Restart the game to load this UI update.

Gathering now shows work progress and the next yield under the crosshair, with
brief hand/impact feedback. Drops count as carried only after pickup. Restart
the running game to load script changes; existing saves retain their work counts.

The improved building look now includes normal **octagonal construction**:
Chamfer Block and Triangular Slab in the build palette, plus Roof Slope, Roof Hip
and Roof Valley after the existing Forge Tyrant/stonecut unlock. Use B to build,
Tab for shape, Q for material and R to turn the new pieces. Existing buildings
gain the timber, framing and stone materials after restarting/loading your save.
Run the review helper with `-Buildings` for normal-catalogue octagonal placement,
roof collision and save checks, plus interior/exterior screenshots.

Latest owner refinement: nighttime cold health drain is disabled for now.
Restart the running game to reload tuning; existing saves remain compatible.
Normal placed/restored workbenches, mason's yards and forges now share the
station models from the workshop study. `-Stations` on the PowerShell visual
review helper verifies kit placement, save restoration and the forge upgrade,
and captures `build/codex-aesthetic/stations/normal-stations.png`.

The owner-approved [four-part continuation](../docs/art/codex-frontier-continuation-2026-09-05.md)
adds first-person hands/gestures, habitat patches, revised existing landmarks
and an equipment comparison in the pack (`I` → Compare → Equip candidate).
Rebuild the native extension for `compare_equipment`. Run
`powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Continuation`
from the repository root for headless/rendered checks and screenshots; open
`build/codex-aesthetic/index.html` for the gallery. That earlier habitat pass
was decorative; D-027 adds the resource habitats described above.

The default sandpit uses the owner-approved weathered frontier presentation.
Append `-- --crafted-look` for the preceding brighter pass or
`-- --legacy-look` for cubic terrain. These switches do not change the world
seed or generation profile. The experimental roof workshop retains its separate save.
See [the latest material-join report](../docs/art/codex-material-joins-2026-09-05.md).
The default now blends neighbouring rock, soil and turf materials, with quieter
grain and sparse, low stone fragments. Rebuild the native extension for the new
optional mesh-palette argument. Character silhouettes now use the reviewed local
Blender models with the existing runtime pose sampler; they remain faceted
prototype art. Overhead labels cap their close-up size. `-Characters` on the PowerShell review helper captures the
actor studio; `-Grounding` checks plant/chip placement and distance-fade origins.
Creatures now have distance-driven gaits and poses tied to their existing attack
timers. `-Motion` records a playable pose review; see the
[motion report](../docs/art/codex-creature-motion-2026-09-05.md) for controls and limits.

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
   and what you carry top-right; press **I** for the pack screen and **F** for the Foundry. Controls: WASD move, mouse look, Space jump, **E** interact (harvest,
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

**Optional art studies (Codex, 5 Sep 2026):** after building the extension,
`godot --path game -- --crafted-look` runs normal gameplay with experimental
terrain lighting and branching trees. The editable workshop is
`godot --path game res://experiments/roof_workshop.tscn -- --workshop-play`;
its F5/F9 save is separate from the normal game. See
[controls, comparison captures and limitations](../docs/art/codex-crafted-frontier-2026-09-05.md).

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
scene, followed by the expanded gameplay and intensive fixtures in the helper.
The Cataclysm additions are `tests/cataclysm_art_review.tscn`,
`tests/cataclysm_actor_craft.tscn` and `tests/cataclysm_intensive.tscn`; the authored
route review is `tests/cataclysm_review.tscn`. Native generation checks are
`make -C ../tests/sim cataclysm-world` when run from this directory.
Non-zero exit on any failure. Run this
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

## Skill expansion playtest (5 Sep 2026)

Six new pages add Fan Shot, Bodkin Shot, Driving Blow, Reaping Sweep, Cinderburst
and Ashfall. Five more Kind variants support physical/projectile craft rolls,
Foundry control, life on hit, and attack/spell recovery. Restart the game to load
the updated library and tuning, then continue an existing save. Pages are found
through normal drops; characters retain owned skills and mastery.

Open **I → Build guide** for the catalogue, assignment, mastery, Kind hunt sources
and progression. **F** opens the Foundry. Run
`powershell -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Skills`
from the repository root for focused checks and ten rendered review captures;
`-Checks` includes the tests in the full pipeline. The inspection scene grants
fixture resources only and never touches the player's save. See
[tuning and limitations](../docs/prototype/skill-expansion-2026-09-05.md).

## Known engine issue

On a fresh `.godot/` (clean checkout, or after deleting the cache) the very
first `--headless --import` can segfault at the end while Godot 4.5 generates
documentation for the newly discovered GDExtension
([godotengine/godot#111645](https://github.com/godotengine/godot/issues/111645)).
The import work itself completes and every later run is clean;
`run_headless_checks.sh` retries the import once for this reason. Opening the
project in the editor for the first time may likewise crash once — reopen it.
