# ADR-0001: Engine Selection

**Status:** Accepted — **Godot 4.5-stable** (`4.5.stable.official.876b29033`), 31 August 2026  
**Decision owner:** Human project owner

## Context

The prototype requires 3D action combat, grid-based construction, simple generated terrain, save persistence and data-driven tuning. The project should remain approachable to a solo developer using AI assistance.

An MCP integration does not replace a game engine. It exposes structured editor and project operations to an AI agent. The game will still use an established engine; no custom engine is proposed.

See [../research/engine-ai-integrations.md](../research/engine-ai-integrations.md) for the time-stamped integration review.

## Options under consideration

### Godot 4

Advantages:

- GDScript is approachable for someone familiar with Python;
- text-oriented project files are generally friendly to Git and coding agents;
- lightweight iteration and no licence cost;
- suitable for a disposable greybox prototype.
- multiple community MCP add-ons can inspect and drive live editor state.

Risks:

- smaller ecosystem for advanced 3D sandbox and voxel tooling;
- more custom work may be required if the prototype grows toward production scope.
- current MCP options are community-maintained dependencies rather than a first-party engine feature.

### Unity

Advantages:

- mature 3D, navigation, asset and procedural-generation ecosystem;
- C# is well supported by coding agents and conventional testing tools;
- stronger candidate if the prototype is expected to become the production foundation.
- Unity 6 provides an official MCP server for external agents and a project-aware in-editor assistant.
- official structured editor integration reduces the need for custom editor automation.

Risks:

- heavier editor and project complexity;
- generated/imported artefacts require careful repository hygiene.
- official AI tooling is currently beta and requires Unity 6 or newer.

### Unreal Engine

Advantages:

- strong high-end 3D, animation, combat and procedural tooling;
- capable visual scripting.
- Unreal Engine 5.8 ships an official experimental MCP server that supports Codex configuration and structured editor toolsets.
- MCP can inspect and manipulate actors, materials, lighting, editor UI and automation tests through local editor APIs.

Risks:

- C++ and engine complexity remain high for the first learning prototype;
- binary Blueprint assets remain harder for ordinary diff review, although MCP improves agent visibility and editor control;
- the official MCP feature is experimental, incomplete and subject to API changes;
- editor tool invocations are serialized and should not be treated as a mature autonomous build pipeline.

## Decision criteria

1. Time to produce the first complete loop.
2. Ease of source control and AI-assisted changes, including official editor integration.
3. Ability to separate simulation rules from presentation.
4. Adequacy of 3D navigation, construction placement and save persistence.
5. Probability that prototype code will be retained in a future production version.

## Current leaning

- **Unity 6** currently appears to offer the strongest middle ground for a prototype intended to survive into production: mature 3D tooling, C# and an official MCP server.
- **Godot 4** remains attractive for the lightest learning-first prototype, accepting community MCP dependencies and more possible custom 3D work.
- **Unreal Engine 5.8** is now a credible AI-assisted option because of its official MCP plugin, especially if visual quality and procedural tooling outweigh editor and C++ complexity. Its MCP maturity must be treated as experimental.

Before accepting an engine, create the same tiny spike in the final two candidates:

1. open the project from a clean checkout;
2. let an AI agent inspect the editor through MCP;
3. create a small scene with a controllable capsule, resource node and snap-placement preview;
4. run one automated check;
5. compare total setup time, Git changes and agent reliability.

No implementation should begin until the owner accepts an option and records the exact engine version.

## Decision (31 August 2026)

The owner accepts **Godot 4.5-stable** (`4.5.stable.official.876b29033`, pinned; upgrade only by a recorded decision) as the prototype engine. The engine project lives in `game/`, seeded from the verified `spikes/godot4/` scaffold.

Rationale, against the criteria:

1. **Time to first loop** — the Godot spike went from clean checkout to a fully verified, playable scene in minutes with a single 76 MB binary; the Unreal spike needed ~30 GB of engine plus Visual Studio, two source fixes before it compiled at all, and a human at the keyboard for the MCP evaluation.
2. **Source control and AI-assisted change** — the decisive criterion for a solo developer working mostly through an AI editor. Godot scenes and resources are text, the whole in-engine check suite runs headless, and an agent can fix, re-run and verify without the editor open or a human present. Unreal's first-party MCP server is the better *live-editor* agent experience, but maps are binary, the editor rewrites committed config on every settings save, and every agent action requires a running local editor.
3. **Separating rules from presentation** — unaffected by engine choice: the rules already live in the engine-neutral `sim/` C++17 library with its own headless regression suite. Godot consumes it through a thin GDExtension binding (next task); the engine layer stays presentation, input and scenes.
4. **3D adequacy** — everything the vertical slice needs exists natively: `CharacterBody3D`, physics traces, grid placement (already integration-tested), `GridMap`/`MultiMesh` for the small construction catalogue, heightmap or plugin terrain, `NavigationServer3D`, Jolt physics, text saves. The prototype boundaries (bounded world, small catalogue) keep it inside Godot's comfort zone.
5. **Retention into production** — the weakest criterion for Godot and accepted knowingly; see the exit condition.

**Exit condition.** Revisit this decision if terrain scale, world streaming or construction density outgrows what Godot handles comfortably, or if production visual targets demand it. Because `sim/` is engine-neutral, the cost of switching is the presentation layer only — keep it that way.

**Dependencies approved by this decision:** `godot-cpp` (Godot's official GDExtension C++ bindings, pinned to the matching 4.5 branch) as the sole third-party dependency, solely to bind `sim/` into the engine. Community MCP add-ons remain unapproved until individually reviewed.

**Not chosen:** Unity 6 was the pre-spike leaning but was never spiked (Hub/licence activation blocks unattended setup); Unreal 5.8 was fully spiked (see below) and set aside for the daily-workflow costs above, not for capability.

## Spike status

> Both spike directories were removed from the tree after acceptance: `spikes/unreal58/` in the cleanup commit that followed (last present at `1dab955`), and `spikes/godot4/` once `game/` had superseded it (last present at `b738f02`). Everything below remains retrievable from git history.

- **Unreal Engine 5.8:** spike scaffold committed at `spikes/unreal58/` (31 August 2026, owner-directed). It is text-only (C++, configs, no binary assets) and covers the checklist above: clean-checkout open, controllable capsule, resource node, grid snap-placement preview and two automation tests. The MCP inspection step must be run on the owner's machine because the Unreal MCP server only runs inside a locally launched editor; `spikes/unreal58/SPIKE.md` is the runbook and lists the measurements to record. **This does not accept the ADR** — the comparison spike in the other finalist remains outstanding.
- **Godot 4:** spike scaffold committed at `spikes/godot4/` (31 August 2026), mirroring the Unreal spike piece for piece on pinned Godot **4.5-stable**. Unlike the Unreal scaffold it was **executed and verified headless in the real engine** before commit: project import, unit tests, an in-engine physics integration test of the placement loop, and a 120-frame scene smoke run all pass (`spikes/godot4/run_headless_checks.sh`). The editor-MCP evaluation (community add-ons) remains a local step; `spikes/godot4/SPIKE.md` is the runbook. **This does not accept the ADR.**
- **Unreal Engine 5.8 — local run and MCP session (31 August 2026, owner's machine):** the scaffold had never been compiled; first build failed on a missing include path (`Tests/` subfolder) and UE 5.8 ships no `BasicShapes/Capsule` mesh, both fixed. Clean-checkout-to-Play was dominated by installs (~30 GB engine download, Visual Studio 2022 game workload); the module itself compiles in ~10 s and both automation tests pass headless (`UnrealEditor-Cmd -ExecCmds="Automation RunTests Wroughtwild"`). MCP runbook results with Epic's `ModelContextProtocol` plugin driving Claude over HTTP: **task 1 inspect — pass** (level, actors, `ResourceNode` class and properties discovered); **task 2 create scene — pass with one human step** (no "new level" tool exists and `AssetTools.duplicate` on a map produces an unsaveable copy referencing the source's private BSP model, so the owner did File → New Level → Save As; the agent then spawned floor, lights, sky, Player Start and three `ResourceNode`s in 1.6 s, set material families, saved the map and set it as startup map via `ConfigSettingsToolset`); **task 3 mutate — pass** (moved a node, changed `RemainingUnits`, changed and restored the `GridSize` class default; the visual preview check still needs a human because MCP cannot send gameplay input); **task 4 automation — pass** (`AutomationTestToolset` discovered in 2.4 s, both tests Success in 0.5 s); **task 5 deliberate errors — pass** (non-existent actor, non-existent level and a typo'd property all returned precise errors, level unharmed). PIE can be started, screenshotted and stopped by the agent (~3 s to BeginPlay). Retry count: 6 argument-name misses in ~40 calls, every one recoverable from the schema returned in the error; parameters marked optional are frequently mandatory at call time. Git hygiene: the editor rewrote `DefaultInput.ini` (harmless bloat) and injected an `AndroidFileServer` section with a `SecurityToken` into `DefaultEngine.ini` on every settings save, and the Launcher had not registered the engine so the first double-click rewrote `EngineAssociation` to a machine GUID — all reverted by hand; `*.slnx` added to the ignore list. **This does not accept the ADR** — the Godot MCP evaluation (community add-ons) remains outstanding.
- Cross-spike finding: the placement range must exceed the third-person camera set-back; Godot's integration test caught the too-short default, and the fix was back-ported to the Unreal spike.
- Engine-neutral economy rules were extracted to `sim/` with headless tests in `tests/sim/`, so the rules layer is portable to whichever engine is accepted.
- Practical note for the comparison: Godot is the only shortlisted engine whose spike can be executed and regression-tested by a cloud coding agent (single binary, headless mode, text scenes). Unreal compiles only on a full local install; Unity requires Hub/licence activation and was not spiked in-container.
