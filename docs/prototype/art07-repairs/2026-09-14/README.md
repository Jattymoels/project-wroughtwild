# ART-07 repairs — plan, prompts and setup

**Prepared at the owner’s request, 14 September 2026.** All 26 original ART-07
slices remain delivered. This follow-up addresses the seven open G2 findings
through seven repairs, one integration and one independent review. No repair
implementation or new worker task is started by preparing this pack.

Start with **R1–R4**, one task per prepared worktree. Copy the full fenced prompt
from the linked file. [Setup](SETUP.md) and the [actual workspace record](workspaces.json)
give paths, copied runtime state and commands. GPU jobs remain serial; ordinary
source work can proceed independently in separate tasks.

| Wave | Task / prompt | Concrete result | Candidate dependency |
| --- | --- | --- | --- |
| 1 | [R1 — Restore broad canopy silhouettes](prompts/R1.md) | Restore crown mass in the retained pilot while fitting the lower trunk to the existing native collision and work envelope. | Common G1/G2 baseline |
| 1 | [R2 — Reduce setup time and asset residency](prompts/R2.md) | Reduce measured setup and unnecessary resident art resources in the isolated pilot while retaining visible quality and native behavior. | Common G1/G2 baseline |
| 1 | [R3 — Finish building face, end and edge materials](prompts/R3.md) | Make existing building forms read as constructed materials with appropriate face, end and edge treatment. | Common G1/G2 baseline |
| 1 | [R4 — Attribute and fix fixture cleanup warnings](prompts/R4.md) | Identify the leaked objects in the eight reported source fixtures and correct their owned lifecycle cleanup. | Common G1/G2 baseline |
| 2 | [R5 — Correct chest visual seating](prompts/R5.md) | Remove the visible chest/floor intersection using a visual fit compatible with the existing physical seat and storage behavior. | Common G1/G2 baseline |
| 2 | [R6 — Resolve faceted-ore visual coverage](prompts/R6.md) | Provide a coherent existing-ore presentation on ordinary faceted terrain within its retained surface and excavation envelope. | Common G1/G2 baseline |
| 2 | [R7 — Compose fuller habitat at retained anchors](prompts/R7.md) | Improve ground and canopy composition using existing retained decorative anchors and the published R1 canopy candidate. | R1 |
| 3 | [R8 — Integrate the seven repaired candidates](prompts/R8.md) | Produce one reproducible isolated retained-world package combining all seven published repair candidates. | R1, R2, R3, R4, R5, R6, R7 |
| 4 | [R9 — Independently review the repaired full kit](prompts/R9.md) | Close the owner-stopped R9 review using existing results; identify practical adoption blockers and explicit limitations. | R8 |

Wave 2 starts after all four first-wave candidates are checked and published.
R7 additionally consumes R1’s canopy. R8 requires all seven repairs; R9 requires
R8 and a **separate task that did not implement R1–R8**. Later wave directories
and input packages are not pre-marked ready. A blocked decision remains open.

The [common contract](COMMON.md) defines owned paths and unchanged gameplay.
The [machine-readable plan](plan.json) holds task scope and gates; the
[publisher-owned delivery index](deliveries.json) records only verified deliveries.
Use the [publisher prompt](prompts/PUBLISH.md) for serial integration and dispatch.

## Findings and acceptance

| G2 finding | Repair |
| --- | --- |
| G2-V01 | [R1](prompts/R1.md) |
| G2-C01 | [R2](prompts/R2.md) |
| G2-V02 | [R3](prompts/R3.md) |
| G2-T01 | [R4](prompts/R4.md) |
| G2-V03 | [R5](prompts/R5.md) |
| G2-V04 | [R6](prompts/R6.md) |
| G2-V05 | [R7](prompts/R7.md) |

R1 restores crown mass while retaining native tree bodies. R2 measures and
reduces setup/residency without disguising the cost by removing visible content.
R3 finishes the existing materials and joins. R4 attributes the eight fixture
cleanup warnings. The next wave addresses chest seating, faceted ore and
retained-anchor habitat composition. R8 resolves shared-file overlaps explicitly.

The original [G2 findings and measurements](../../art07-production/publication-2026-09-14.md)
remain the comparison. All 273 building combinations, octagonal support, native
ownership, collision, finite stock and geography are fixed constraints. The six
ART-06C animal rigs/adoption and normal-world rollout remain separate work.

**Performance target:** measure the actual current RTX 5090 machine first.
Minimum hardware and an acceptance budget remain open unless the owner selects
them. R2 and R8/R9 distinguish import, repeated startup, first-use/traversal and
settled frame costs. No invented numerical budget substitutes for measurements.

Technical repair evidence, owner visual acceptance and target-device clearance
are separate outcomes. New geography/body/seat rules require an explicit decision
only if the existing contract cannot support the bounded visual repair.

## Validation and sources

[inputs.json](inputs.json) pins the original G1 runtime, G2 seal and source index.
The setup copy helper hashes every copied runtime entry and preserves all original
packages. No cache/import, source regeneration or simulation change is part of setup.
[Preparation evidence](setup-checks.json) records actual checks and limitations.

Run the installed Python with `tools/wroughtwild-art07-repairs/dispatch.py` to
validate scopes, finding coverage, dependency gates, links and generated prompts.
`--write` regenerates this index and the nine worker prompts from plan.json.
