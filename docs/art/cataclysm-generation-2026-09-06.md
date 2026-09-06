# Cataclysm generation: native implementation review

This records the native slice of the approved [cataclysm intensive](../prototype/cataclysm-world-intensive-2026-09-06.md). It does not certify visual acceptance or install the proposed extraction/automation follow-on.

## Implemented

`frontier_v4` retains the finite 512 × 512 × 48 cell world and the existing three discovery regions. Independent bounded angular offsets and irregular regional margins replace equal circular placement. The same impact history shapes broad host ridges, shallow impact bowls, broken rims and shallow channels along exposed traces. The starter clearing remains outside the augmentation field.

Three stable regional impact anchors form a connected cycle of curved traces. Six local branches connect that history to inhabited remnants: a woodland dwelling linked to Thrumroot, reed homestead linked to Lanternheart, pressure cistern linked to Ventlung, quarry shelter linked to Stormglass, herder waystation linked to Pullstone, and the existing Forge gate's threshold. Each trace has a stable ID and independently seeded broken, buried or exposed segments. These are terrain and presentation records, with no damage, power supply, economic gate or new stock.

The six ruins reserve complete flat foundations before rare placement, with gentle skirts joining the surrounding ground. Gate terrain is the most constrained, so its foundation is selected first from a bounded neighbourhood; regional dwellings then choose suitable homeward ground. Native paths model the authored walls at the margins and retain the central three-metre walking strip. Every ruin records its arrival route and a separate direct route to the existing discovery or gate. Ruin damage points away from the associated impact.

The five finite rare-source definitions retain their existing primary-site budgets, exceptional budget, first hauls, class-independent interactions and era visibility. Primary discovery placement prefers a short journey from its associated ruin. Working circles exclude ruins and impact fragments. Existing material habitats, the authored Rootvault cave and the Tyrant/Warden landmark progression remain available. Forge distance remains within the existing 160–215 m goal.

For seed 1, the Rootvault ruin stands at native cell `(352, 19, 148)` and records a 40-cell route to `rsv4_thrumroot_primary_0`. Godot positions use cell-centred metres. The rendered authoring review uses this actual generated relationship rather than a separate demonstration layout.

## Compatibility

The exact pre-change V3 tuning is preserved in `data/tuning/worldgen-frontier-v3.json`. Legacy, V2 and V3 select their own frozen inputs; their composition helpers remain isolated from the V4 implementation. Profile identity remains part of the world cache and terrain query contract. Old profiles return no impact, ruin, trace or augmentation records.

The focused test captures geometry, complete resource IDs, quantities, site identities and approaches for seeds 1, 7, 24 and 91. All twelve historical results remain exact after deliberately corrupting the live V4 tuning in the test. This protects regenerated terrain beneath saved excavation and the identities used to restore depleted and partially harvested nodes. Godot save restoration and presentation clearing are verified separately by the parent integration suite.

| Frozen profile | Seed 1 complete fingerprint | Seed 7 | Seed 24 | Seed 91 |
| --- | --- | --- | --- | --- |
| legacy_v1 | 1899602153114217418 | 736845089599793829 | 7709451517322904450 | 2672371686718130021 |
| frontier_v2 | 5430446987841818078 | 3258464633623945865 | 10270373463809211055 | 15565090014744201037 |
| frontier_v3 | 12362207930465321087 | 14231361409912523888 | 4253842255980360217 | 8552760223992271840 |

## Validation

The dedicated `cataclysm-world` native target passes **25,959,555 checks** over 64 seeds: 1–32 and 32 larger deterministic seeds. It validates frozen fingerprints, exact regeneration, definition-order independence, bounded history records, grounded resources, every arrival and discovery path, ruin collision margins, complete foundations, finite unchanged hauls, working clearances, starter/progression supplies, trace grounding and the normalized augmentation field. The longest ruin-to-discovery route in this matrix is 51 cells. A separate initial generation probe also completed all sequential seeds 1–64, bringing the distinct generated sample to 96 seeds.

The existing suites also pass after the profile-loader change: **36,589 simulation checks**, **595,376 material/habitat checks**, and **2,201,784 frozen V3 checks**, with zero failures. They were compiled with the established C++17 compiler and `-Wall -Wextra -Werror -O1`.

Local evidence: `build/cataclysm/native-tests.log`, `build/cataclysm/probe.log`, `build/cataclysm/baseline-fingerprints.txt`, and the `sim-regressions.log`, `world-intensive-regressions.log`, and `strange-frontier-regressions.log` files beside them. The Windows Make invocation could not resolve its shell recipe, so these successful regression runs used direct compiler invocations with the same source lists and flags; no test assertion was weakened.

The existing Godot extension builds successfully with the accepted payload: `impacts`, `leylines`, `ruins`, region history tags, and a row-major `PackedFloat32Array` `augmentation_field` whose values lie in `[0,1]`. Every route and foundation uses the same cell-centred world conversion as earlier habitat paths.

## Tuning and limits

`worldgen.json` contains an explicit `cataclysm` group with a plain-language purpose for each parameter. It bounds impact offsets and dimensions, influence and terrain depth, regional variation, trace width/detail/curvature, foundation dimensions/skirt/accepted relief, preferred ruin/discovery distance, the Forge threshold search, and ordinary path clearance. Parser limits reject values outside this intensive's finite composition budget.

There is no infinite terrain, flowing-water simulation, new rare capability, extraction currency or powered factory. The base cave system remains the existing geology plus the authored Rootvault stair/chamber; this pass adds connected surface history rather than a new underground network. Passing a bounded seed matrix does not prove every possible seed or finish every vista. Godot's actual collision, excavation, save restore, authored asset fit, lighting and performance remain part of integrated review. No performance claim is inferred from native generation checks.
