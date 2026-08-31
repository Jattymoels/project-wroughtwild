# ADR-0001: Engine Selection

**Status:** Open  
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
