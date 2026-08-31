# Unreal Engine 5.8 Spike (ADR-0001)

**Status:** Spike scaffold — ADR-0001 remains **Open**; this does not select Unreal.
**Purpose:** Run the comparative spike defined in
`docs/decisions/ADR-0001-engine-selection.md` on the Unreal candidate, and
collect the measurements the ADR needs.

The scaffold is entirely text (C++, configs, no binary assets), so it opens
from a clean checkout, diffs in Git and is fully editable by coding agents.
The Unreal MCP server runs **inside a locally running Unreal Editor**
(loopback-only, no auth), so the MCP portion of the spike happens on your
machine, not in a cloud session.

## What the scaffold contains

| Piece | File(s) |
| --- | --- |
| Project + configs | `Wroughtwild.uproject`, `Config/*.ini` |
| Controllable capsule (WASD + mouse, jump) | `WroughtwildCharacter.*` |
| Harvestable resource node (wood/iron family) | `ResourceNode.h/.cpp` |
| Material-family inventory | `WroughtwildInventoryComponent.*` |
| Grid snap-placement preview (green/red), place, remove w/ refund, rotate | `GridPlacementComponent.*`, `PlacedBlock.*`, `WroughtwildGrid.h` |
| Tuning load from `data/tuning/` | `WroughtwildTuningSubsystem.*` |
| Automation tests (the "one automated check") | `Tests/WroughtwildSpikeTests.cpp` |

Default controls: WASD move, mouse look, Space jump, **E** harvest,
**B** toggle build mode, **LMB** place (or harvest outside build mode),
**X** remove block, **R** rotate preview.

## Run it locally

1. Install **Unreal Engine 5.8** (Epic Games Launcher or source build) and a
   C++ toolchain (VS 2022 with C++ workload on Windows; Xcode on macOS).
2. Clone the repo and open `spikes/unreal58/Wroughtwild.uproject`. Accept the
   prompt to build the missing `Wroughtwild` module (or right-click the
   .uproject → Generate project files, then build the `WroughtwildEditor`
   target from your IDE).
3. The project opens with the engine's default map. Create a spike map (or let
   the MCP agent do it — see below): add a floor (any large static mesh or a
   Landscape), a Player Start, a directional light, and a few `ResourceNode`
   actors (set `MaterialFamily` to `wood` or `iron_ore`).
4. Press Play. Harvest a node with E, press B and place/remove blocks; the
   preview shows green for valid placement, red for blocked/unaffordable.

## Connect the MCP server (spike step 2)

1. In the editor: **Edit → Plugins**, search for **Unreal MCP**, enable it and
   restart. The plugin is *experimental*; expect API changes.
2. Follow the plugin's panel/docs to start the local MCP server and generate a
   client configuration. The server is loopback-only with no authentication —
   never expose it beyond localhost.
3. Register it with your local Claude Code:

   ```sh
   claude mcp add --transport http unreal <URL from the plugin, e.g. http://127.0.0.1:PORT/...>
   ```

   (Match the transport/URL to what the plugin's generated config specifies.)
4. Editor tool calls run serially on the game thread — treat the agent as an
   assistant inside the editor, not a headless build pipeline.

## MCP tasks to attempt (record results for the ADR)

1. Inspect the level: list actors, read a `ResourceNode`'s properties.
2. Create the spike scene: floor, Player Start, light, three `ResourceNode`
   actors (two `wood`, one `iron_ore`) — then save the map as
   `Content/Maps/SpikeValley` and set it as the editor startup map.
3. Mutate: move a node, change its `RemainingUnits`, change the placement
   component's `GridSize` default and observe the preview.
4. Run the automation tests: filter `Wroughtwild` in Tools → Test Automation,
   or via the MCP automation toolset. Both `Wroughtwild.Grid.SnapToCellCenter`
   and `Wroughtwild.Tuning.CraftingJsonLoads` must pass.
5. Deliberately ask for something wrong (e.g. delete a non-existent actor) and
   note how recoverable the failure is.

## Measurements to record (per ADR-0001)

- Total time from clean checkout to running Play-In-Editor.
- Whether each MCP task above succeeded, and retry count.
- Git status after the session: which generated files appeared; confirm
  `.gitignore` kept them out.
- Subjective agent reliability and failure recovery.

Compare against the same spike in the other finalist engine before accepting
ADR-0001. Record the accepted engine and exact version in the ADR; only then
does an engine project move into `game/`.

## Known limitations

- Legacy input mappings (text-based, reviewable) are used instead of Enhanced
  Input assets; migrate after engine acceptance.
- No map is committed (maps are binary); scene creation is part of the MCP
  evaluation itself.
- The engine-side code deliberately duplicates only trivial rules (grid math,
  inventory counts). The full economy rules live in the engine-neutral
  `sim/` library, which is the source of truth and is regression-tested
  headlessly in `tests/sim/`.
- Catalyst tempering, trials, combat and save/load are out of spike scope
  (D-007 remains open; the spike only covers ADR-0001's checklist).
