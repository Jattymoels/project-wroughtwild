# Engine AI and MCP Integration Review

**Reviewed:** 31 August 2026  
**Purpose:** Determine whether an existing engine can expose editor operations to AI agents without building custom engine or editor infrastructure.

## Conclusion

Use an established game engine. MCP is an integration layer that allows an AI agent to inspect and invoke editor functionality; it is not a game engine and does not remove the need to implement game rules, content, save systems, UI or testing.

Both Unreal Engine and Unity now provide official MCP integrations. Godot has active community MCP add-ons. Wroughtwild should not build its own engine or its own MCP bridge before testing these existing options.

## Unreal Engine 5.8

Epic documents an official **Unreal MCP** plugin in Unreal Engine 5.8. It embeds a local HTTP MCP server inside the editor and can generate configuration for clients including Codex. Default toolsets expose operations such as actor manipulation, lighting, material instances, object inspection and automation tests. Custom tools can be authored through Unreal Python or C++ toolsets.

Important limitations:

- Epic labels the feature experimental.
- Documentation warns that features and APIs are incomplete and subject to change.
- The default server is loopback-only and has no authentication; it must not be exposed remotely.
- Editor tool invocations run serially on the game thread.
- Binary Blueprint assets remain less transparent in normal Git diffs even when MCP can inspect them.

Primary sources:

- [Unreal MCP in Unreal Editor](https://dev.epicgames.com/documentation/unreal-engine/unreal-mcp-in-unreal-editor)
- [AI Features, Tools, and Plugins in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/ai-features-tools-and-plugins-in-unreal-engine)

## Unity 6

Unity provides an official MCP server as part of its current AI tooling for Unity 6 and newer. It allows external IDEs and agents to bridge into Unity. Unity also offers a project-aware editor assistant and an AI gateway for supported third-party agents.

Relevant current constraints:

- Unity's AI tools are beta.
- The official MCP server requires Unity 6 or newer.
- Unity states that the MCP server itself is free and does not consume AI credits.
- The broader in-editor assistant and cloud-linked features have separate setup and commercial terms.

Primary sources:

- [Unity AI game-development tools](https://unity.com/features/ai)
- [Unity AI documentation](https://docs.unity.com/en-us/ai)
- [Register custom Unity MCP tools](https://docs.unity.cn/Packages/com.unity.ai.assistant%402.9/manual/integration/unity-mcp-tool-registration.html)

## Godot 4

Godot's asset library contains community-maintained MCP add-ons that can connect agents to live editor state, scenes, scripts, runtime errors, screenshots and tests. One current Godot Editor MCP listing advertises a broad typed tool surface and GUT test support.

This is promising for a lightweight prototype, but it differs from the Unreal and Unity situation:

- integrations are community projects rather than an official Godot engine feature;
- installation, security model, compatibility and maintenance vary by add-on;
- some alternatives require Godot's C#/.NET edition while others support GDScript workflows;
- the project would assume more third-party integration risk.

Primary sources:

- [Godot Editor MCP asset](https://godotengine.org/asset-library/asset/5434)
- [Godot-MCP asset](https://godotengine.org/asset-library/asset/5245)
- [Godot MCP Bridge asset](https://godotengine.org/asset-library/asset/5409)

## Recommendation for Wroughtwild

Do not select an engine solely because it has MCP. First evaluate ordinary engine suitability, then use MCP maturity as a major AI-workflow criterion.

Current shortlist:

1. **Unity 6:** strongest balance of production-capable 3D tooling, text-based C# workflows and official MCP support.
2. **Unreal Engine 5.8:** strongest high-end and procedural toolset with credible official AI integration, but higher complexity and experimental MCP risk.
3. **Godot 4:** fastest lightweight learning option, with attractive community MCP tooling but more integration and long-term 3D uncertainty.

Run a one-day comparative spike in the final two candidates before accepting ADR-0001. The spike should measure setup, editor inspection, scene mutation, test execution, Git reviewability and recovery from a failed AI action.
