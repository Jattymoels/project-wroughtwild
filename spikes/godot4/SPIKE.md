# Godot 4 Spike (ADR-0001)

**Status:** Spike scaffold — ADR-0001 remains **Open**; this does not select Godot.
**Engine:** Godot **4.5-stable** (`4.5.stable.official.876b29033`), pinned for the spike.
**Purpose:** Run the comparative spike defined in
`docs/decisions/ADR-0001-engine-selection.md` on the Godot candidate,
mirroring `spikes/unreal58/` piece for piece.

Unlike the Unreal scaffold, **this project has been executed and verified in
the real engine**: the pinned Godot binary ran the import, the unit tests, an
in-engine physics integration test of the full placement loop, and a
120-frame headless run of the main scene, all passing, before each commit.

## What the scaffold contains

| Piece | File(s) |
| --- | --- |
| Project, input map, autoload | `project.godot` |
| Controllable capsule (WASD + mouse, jump) | `scenes/player.tscn`, `scripts/player.gd` |
| Harvestable resource node (wood/iron family) | `scenes/resource_node.tscn`, `scripts/resource_node.gd` |
| Material-family inventory | `scripts/inventory.gd` |
| Grid snap-placement preview (green/red), place, remove w/ refund, rotate | `scripts/grid_placement.gd`, `scripts/grid.gd`, `scenes/placed_block.tscn` |
| Playable spike scene (floor, sun, player, three nodes) | `scenes/spike_valley.tscn` |
| Tuning load from `data/tuning/` | `scripts/tuning.gd` (autoload `Tuning`) |
| Automated checks | `tests/run_tests.gd`, `tests/integration.tscn`, `run_headless_checks.sh` |

Controls (identical to the Unreal spike): WASD move, mouse look, Space jump,
**E** harvest, **B** toggle build mode, **LMB** place (or harvest outside
build mode), **X** remove block, **R** rotate preview.

Every file is text (`.tscn` scenes included), so the whole project diffs in
Git and needs no binary assets.

## Run it locally

1. Download **Godot 4.5-stable** for your platform (a single executable).
2. Open `spikes/godot4/project.godot` with it — no build step, no compile.
3. Press Play. Walk to a cylinder and harvest with E, press B and place/remove
   blocks; the preview shows green for valid placement, red for
   blocked/unaffordable.

## Headless checks (run anywhere, no GPU)

```sh
GODOT=/path/to/Godot_v4.5-stable ./run_headless_checks.sh
```

Runs: project import → unit tests (grid math, inventory, tuning load,
harvest depletion, scene instantiation) → in-engine integration test
(preview validity for unaffordable/valid cells, placement consuming
material, removal with partial refund, across real physics frames) → a
120-frame smoke run of the main scene. Non-zero exit on any failure.

## MCP evaluation (spike step 2 — local machine)

Godot has no official MCP server; the candidates are community add-ons (see
`docs/research/engine-ai-integrations.md`). On your machine:

1. Install one of the reviewed add-ons from the Asset Library (e.g. "Godot
   Editor MCP" or "Godot-MCP") into this project — note this adds a
   third-party dependency, which per AGENTS.md is an explicit-approval
   decision to record with the ADR measurement.
2. Follow its README to start the bridge and register it with your local
   Claude Code (`claude mcp add ...`).
3. Attempt the same tasks as the Unreal runbook: inspect the scene tree,
   read/modify a `ResourceNode`'s exported properties, move a node, run the
   headless checks, and try one deliberately wrong operation to judge
   failure recovery.

## Measurements to record (per ADR-0001)

- Total time from clean checkout to Play — expected to be minutes; compare
  against Unreal's install + first compile.
- Whether each MCP task succeeded, retry count, and add-on maintenance risk.
- Git status after an editor session: what the editor touched (imports live
  in the ignored `.godot/`; `.uid` files are committed on purpose).
- Subjective agent reliability and failure recovery.

## Known limitations

- Headless runs exercise logic and physics but render nothing; "does the
  preview look right" still needs local eyes.
- The camera/placement geometry is deliberately simple (spring-arm
  third-person); the placement range must exceed the camera set-back — a
  constraint found by the integration test here and back-ported to the
  Unreal spike.
- The engine-side code duplicates only trivial rules (grid math, inventory
  counts). The full economy rules live in the engine-neutral `sim/` library,
  regression-tested in `tests/sim/`.
- Catalyst tempering, trials, combat and save/load are out of spike scope
  (D-007 remains open; the spike only covers ADR-0001's checklist).
