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
3. The project opens on `Content/Maps/SpikeValley` (set as the editor startup
   map). The map was built entirely through the MCP server on 31 August 2026:
   a 40 m × 40 m floor, directional light, sky light, sky atmosphere, Player
   Start and three `ResourceNode` actors (`WoodNode_A`, `WoodNode_B`,
   `IronNode`). It is the one binary asset in the spike (`.umap`, ~25 KB).
4. Press Play. Harvest a node with E, press B and place/remove blocks; the
   preview shows green for valid placement, red for blocked/unaffordable.

## Connect the MCP server (spike step 2)

1. In the editor: **Edit → Plugins**, enable **Unreal MCP** *and* **All
   Toolsets** (without the latter the server exposes almost no tools), then
   restart. `Wroughtwild.uproject` already lists `ModelContextProtocol` as
   enabled. The plugin is *experimental*; expect API changes.
2. The plugin has **no panel**. Start the server from the editor console
   (backtick key, or the Output Log command bar):

   ```text
   ModelContextProtocol.StartServer
   ModelContextProtocol.GenerateClientConfig ClaudeCode
   ```

   The first listens on `http://127.0.0.1:8000/mcp` (loopback-only, no
   authentication — never expose it beyond localhost; port/path and an
   auto-start toggle live under Edit → Editor Preferences → General → Model
   Context Protocol). The second writes `.mcp.json` next to the `.uproject`.
3. Launch Claude Code from `spikes/unreal58/` so it picks up `.mcp.json`, or
   register the server globally:

   ```sh
   claude mcp add --transport http unreal http://127.0.0.1:8000/mcp
   ```

4. Editor tool calls run serially on the game thread — treat the agent as an
   assistant inside the editor, not a headless build pipeline. The server runs
   in "tool search" mode: only `list_toolsets`, `describe_toolset` and
   `call_tool` are advertised; every real tool needs a `describe_toolset`
   round-trip first, and argument names cannot be guessed (see the session
   findings in `docs/decisions/ADR-0001-engine-selection.md`).

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
- `Content/Maps/SpikeValley.umap` is the one committed binary asset; it was
  created by the MCP evaluation itself. Creating a *new* level is the one step
  MCP cannot do (no tool exists, and `AssetTools.duplicate` on a map yields an
  unsaveable copy), so a human does File → New Level → Save As once.
- UE 5.8 ships no `BasicShapes/Capsule`; the player body uses the engine
  Cylinder instead.
- The engine-side code deliberately duplicates only trivial rules (grid math,
  inventory counts). The full economy rules live in the engine-neutral
  `sim/` library, which is the source of truth and is regression-tested
  headlessly in `tests/sim/`.
- Catalyst tempering, trials, combat and save/load are out of spike scope
  (D-007 remains open; the spike only covers ADR-0001's checklist).
