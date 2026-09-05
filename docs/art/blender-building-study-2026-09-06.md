# Blender building study — 6 September 2026

Author: Codex (OpenAI).

The owner requested a Blender MCP and a start on authored aesthetics, meshes and
hitboxes, selected **building pieces: meshes and collision fit**, and explicitly
approved official portable Blender. This authorises the local art tool and a
small building study under D-013/D-017. It does not select new construction rules
or change D-010's Godot ownership of hit detection.

Implemented a local Python stdio MCP with three tools: locate Blender, build a
study, and poll its results. Installed checksum-verified portable Blender 4.5.9
under the ignored build folder. No Python package, add-on, online asset service,
runtime dependency or externally sourced art was added.

The first study contains a timber wall, post and beam based on existing metre
dimensions and palette. It exports an editable Blender scene, individual GLBs,
separate collision proxies, baked timber textures and a render. A decorative cap
on the assembled display covers coincident beam faces; that join treatment is a
study proposal, not a new piece, automatic trim rule or runtime change.

All presentation controls and their purposes live in
[`study.json`](../../tools/wroughtwild-blender/study.json). There are no new
gameplay tuning values or save fields. See the
[tool README](../../tools/wroughtwild-blender/README.md) for commands and limits.

Validation: five Python protocol/error-path tests pass. An actual MCP wire client
initialises the server, starts Blender and polls a successful export/render job.
Godot 4.5 imports all six GLBs into an isolated project; **34 checks pass** for
dimensions, pivots, visible/collision separation, collider ownership, physical
ray hits/misses, wall seams and rotation. The packaged JSON manifest also passes
the provided plugin validator: its unused YAML import was supplied with a
fail-fast shim because PyYAML is absent; no YAML file is included or parsed.

Sandboxed Godot reports inaccessible OS certificates and editor-settings paths;
explicit local log paths avoid its user-log startup failure. Asset import and
all checks complete successfully. No game-wide suite was required because the
study does not edit or depend on the current game implementation.

Visual QA also caught and corrected the baked texture colour space for glTF.
The Godot capture uses a fixed-size SubViewport so a hidden Windows window cannot
shrink its output. The reviewed local artifacts are in
`build/blender-study/ff30d528ef514a67ac060e6fabc3ed34/`: `building-study.blend`,
`building-study.png`, six GLBs and `godot-review/godot-review.png`.

Remaining work: visual direction review, reduced wall draw calls, fine variants,
roof/door/stair studies and first-person capsule traversal. This is a deliberately
small authored-asset pipeline, not live Blender UI control or finished art. Normal
play still uses its existing meshes and collisions; the separately ongoing
gameplay edits were left untouched.
