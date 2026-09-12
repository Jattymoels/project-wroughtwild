# ART-07F1 source and fixture contract

Assigned IDs: `lanternheart`, `stormglass`, `lantern_lamp`, `stormglass_lever`.
This is an isolated source candidate. No normal-game, simulation, tuning,
catalogue or shared queue file is changed. Owner visual acceptance is pending.

The frozen game/data/native revision is
`bbcb3a7dfd235e8f803141ccb57c38e03d6c1708`, verified published on main before
the worktree was created. D4 h04 and D6 v04 receipts and complete package hashes
are prerequisites, verified by `provenance.py`. They supply wood, reed and iron
maps; their source files are unchanged. D-013/D-030 govern the weathered/scarred
art; D-017/D-018/D-021/D-029 and current tables retain gameplay.

Source, physical recovery bundle and mounted fixture use the same selected
near core, at the same metric scale. A bundle mesh represents its native quantity;
it creates no inventory and does not imply a literal one-mesh/one-unit count.
Lanternheart is .60 m tall; Stormglass is .44 m long along Blender X. Original
raw-to-game basis, center and uniform scale are in `asset-audit.json`.
Blender XYZ exports once to Godot `(x,z,-y)` in metres. Source housings persist
separately from depleted ResourceNodes and own no stock.

| Object | Existing Godot body XYZ, metres | Origin and moving parts |
| --- | --- | --- |
| Lanternheart source | .75 × .90 × .75 | Ground; core base .12 m, native work lifts it |
| Stormglass source | 2.20 × 1.12 × 1.35 | Ground; tube center .28 m, tilted in scarred bed |
| Lamp | .55 × 1.06 × .45 | Ground; Heart base .23 m, fixed timber/reed cage |
| Lever | .65 × .95 × .50 | Ground; Lever pivot `(0,.54,0)`, tube center .40 m |

The lever outgoing signal anchor remains native `(0,.95,0)`; the ferrule opens
just beneath it. Lamp reception remains at native height 1.06 m. Endpoints,
bodies, range and obstruction rules stay unchanged.

Lamp recipe: 1 Lanternheart, 2 wood, 2 raw reed. Lever recipe: 1 Stormglass,
3 wood, 1 iron ingot. No new gates, recipe, mastery award or save field.
Lamp on/off changes native light and core emission while preserving the solid.
Stormglass light follows an increase in the native pulse counter and expires
on the existing pulse duration. Failed requests stay quiet; no request produces
drive. F1 uses the real lamp receiver; unchanged regressions test the wound winch.

The shader has no global TIME dependency; its clock pauses with the scene tree.
Natural Lanternheart light remains ambient; source work and requests are separate
events. Ordinary frames, reed and ground stay unlit. Scars have measured
14 mm/6 mm inward channels. Original PBR maps remain separate from linear vertex
R/G/B dark margin, energy and travel. The bored tube has its own cylindrical UV
chart and quiet mineral material. Original source hashes are retained.

Near/middle/far candidates are explicit inspection choices: core triangles
14,000/6,000/2,200 and 12,000/5,000/2,000. Complete fixtures are 23,648 and 18,380
triangles. No full-world budget or adoption distance is approved. The asset-cost
report records surfaces, embedded images, opaque modes and texture estimates;
separate benchmarks record engine totals.

The authored review supplies six finite source units per family and common frame
ingredients. It performs real work, pickup transfer, crafting, placement, use and
saves; it is not a first-hour gathering or regional walk. Existing stock and
geography are independently protected by current regressions. Dismantling uses
native common-frame refunds and returns every rare core exactly once.

The board has more irregular joinery and richer weathering than this candidate.
D4 repeats remain visible on broad boards; the lightning bed is a small isolated
source treatment. The tube is rougher and thinner than the board resonator.
Normal-world composition and lower-spec certification remain open. An exit-time
ObjectDB warning also occurs in the unchanged baseline regression.
