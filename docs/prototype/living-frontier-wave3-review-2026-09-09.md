# Living Frontier Wave 3 — orchestrator review

9 September 2026. Reviewed baseline:
`11322c9` (publication handoff), containing LF-3A `df5a0c1`, LF-3B `0cec19f`
and LF-3C `118bded`. Interleaved ART-01 commits and active grove/art work are
separate. This review changes documentation only; no gameplay tuning is added.

**Verdict: one blocking route-correctness issue before Wave 4.** The animal,
material, manufacture and saved-ownership checks pass. However, the generated
laboratory walks ignore the solid shells placed on those walks. In seed 5 this
breaks the actual visible Collection Annex trail. Passing terrain-route tests
therefore do not establish a complete physical approach.

The [bounded implementation contract](living-frontier-wave3-2026-09-09.md) and
[implementation handoff](living-frontier-wave3-handoff-2026-09-09.md) retain
their selected behaviour, receipts and limits. This review does not give an
unconditional Wave 4 all-clear.

## LF3-R1 — The trail runs through a sealed laboratory

Priority: P2; repair and verify before adding the playable laboratory campaign.

In [the native composition](../../sim/src/worldgen_living_frontier_wave3.inc#L95),
`lab.approach` uses the original terrain walk. The later
[`laboratoryTrail`](../../sim/src/worldgen_living_frontier_wave3.inc#L102)
roots that same walk at the Red source. Neither walk excludes any laboratory
shell. Ending outside the front wall does not prevent the route from entering
the back wall and crossing the interior first.

[FrontierSites](../../game/scripts/frontier_sites.gd) then creates the actual
solid exteriors and places the visible collection marks along this native route.
The current native `routeCheck` checks supported terrain cells and adjacent
single-height steps; it does not test the added walls or player body clearance.

Independent reproduction in a new `living_frontier_wave3` world:

1. Use seed **5** and follow the generated Red-source-to-Collection-Annex trail.
2. Near the end of its 263-point walk, segment 256 runs from ground cell centre
   `(587.5,50,693.5)` to `(587.5,50,694.5)`.
3. At 0.9 m above that ground, an engine physics ray hits the real
   `ExteriorBody` at `(587.5,50.9,693.825)`, the Annex's back wall.
4. The route crosses the sealed interior and hits a second wall before ending
   outside the front. A player cannot follow that marked segment as generated.

The same independent probe finds **seed 77's Central Laboratory approach**
crossing two actual walls. Its first collision is segment 233, from
`(688.5,42.9,568.5)` to `(688.5,42.9,569.5)`, hitting at
`(688.5,42.9,568.825)`. Seed 77's Collection Annex trail and the four source
cue walks did not hit laboratory walls in this probe.

```text
LF3_PROBE_ROUTE lf3_central_laboratory_approach samples=240 wall_hits=2
LF3_ROUTE_PROBE seed=77 routes_blocked=1
LF3_PROBE_CANDIDATE seed=5 trail_inside=lf3_collection_annex
LF3_PROBE_ROUTE laboratory_trail_seed_5 samples=263 wall_hits=2
LF3_ROUTE_PROBE seed=5 actual_trail_blocked=1
```

This is a route/collision diagnostic over the actual generated scenes, not a
claim that the entire laboratory is unreachable by walking around its exterior.
It exposes an invalid authored trail and a missing physical-route guarantee.
No inventory, stock, collision or generation code was changed by the probe.
Local ignored diagnostic files are `game/tmp/lf3_orchestrator_probe.gd`, its
`.tscn`, and `build/lf3/orchestrator-route-probe.out.log`.

Required repair:

- Compute the approaches and visible trail against the final physical shell
  footprints, with enough clearance for the ordinary player body. Cover all
  three laboratories and ensure habitat/source cue paths remain valid too.
- Preserve published terrain, home/source/host/lab positions, finite resource
  identities, future-region envelopes and all owned state. Correct derived
  paths and non-blocking dressing without reseeding a saved world or moving a
  laboratory beneath construction.
- Add seed 5 and seed 77 regressions that would fail on this implementation.
  Check the complete generated path against actual solid shell geometry and
  ordinary traversal, not just terrain heights or a teleported endpoint.
- Repeat the deterministic seed sweep and verify a saved Wave 3 world, including
  paid construction overlapping the old cosmetic trail. Corrected marks must
  retain the existing rule that paid occupied space wins.

## Independent checks completed

The current GDExtension was rebuilt successfully before the engine rerun.

| Check | Independently observed result |
| --- | --- |
| Native Wave 3 generation, recipes, loot and machine ownership | 16,830 checks across the documented 37 seeds, zero failures |
| Existing native rules / Wave 1 / Wave 2 | 224,380 / 213,482 / 601 checks, zero failures |
| Red/Blue contact and ordinary starting classes | 222 checks, zero failures |
| Habitat, finite loot, collision and paid construction | 76 checks, zero failures |
| Fresh-process habitat/death-pack recovery | 18 checks, zero failures |
| Fresh paid zero-found-Catalyst progression | 940 checks, zero failures |
| Fresh-process paid progression and owned state | Seven checks, zero failures |
| Existing world/Forge contact | 20 + 20 checks, zero failures |
| Seven affected engine regressions | Catalogue 52, contraptions 85, pressure 60, loose drops 148, save recovery 175, weathered save 21, wide-frontier pacing 319; zero failures |
| Review document links and scoped whitespace | 57 local targets, no missing files; whitespace checks pass |

The expected malformed-save fixtures emit explicit refusal warnings. The
independent engine reruns were headless. Committed boar tells, White/Green
habitats and the seed-77 Collection Annex terminus were visually inspected.
The author's complete 111-invocation engine pipeline and four Foundry scenes
remain separately recorded evidence; this review did not rerun every scene.

Commands: `tools/living_frontier_wave3_checks.ps1 -Native` and
`-Hosts -Habitat -HabitatRestore -Trail -TrailRestore`, followed by the two
existing contact cases and seven named regressions using the existing runner.
Engine tests used isolated APPDATA, with additional regressions under
`build/lf3/orchestrator-regression/`. The diagnostic used its own isolated
APPDATA and created no normal user save.

The passing suites establish useful work beyond the route defect: distinct
Red/Blue counterplay; passive White/Green hosts; once-only finite material
rewards; five payable existing Catalyst identities; preserved source/machine
ownership and legacy profiles. The acquisition policy remains deliberately
unchanged. The handoff's inventory of later replacement reward paths remains
work for the successor campaign, not a completed global migration.

Travel, gathering dispatch and formation clocks are accelerated in the paid
fixture. Human discovery, reaction comfort, extraction cadence and final art
acceptance remain open. The transformation regions are declarations only;
current construction/restart checks do not prove safety through a future terrain
change.

## Next-session boundary

Begin with **LF3-R1**, retaining its before evidence. Finish and verify that
repair before treating Wave 3 as the foundation for the next campaign wave.

After the repair gate passes, the next bounded work item is
[LF-4A → LF-4B → LF-4C](living-frontier-roadmap-2026-09-08.md#lf-4--first-laboratory-first-changing-era):

1. Prove one real physical transformation in an isolated world. Preserve paid
   homes, supports, excavation, workspaces, machinery, material ownership and
   ordinary recovery approaches; exercise pending-event restart before enabling
   progression to trigger it.
2. Complete the first laboratory Trial at its existing visible site, with
   containment apparatus, altered specimens and readable evidence of the human
   survivor and the failsafe. Retain the accidental old smithy's history.
3. Its first victory queues resonance; safe return changes the actual world into
   era two and adds a useful exploration/material opportunity. Select an explicit
   successor contract for the existing curio gates and rewards. Award once and
   transform once, including reload, suspended runs and repeat victories.

Keep unfinished successor campaign work opt-in and preserve the old profiles'
campaign and acquisition policies. All three existing lab locations and both
declared future regions constrain the work. Hybrids, the second era transition,
the human uber-boss and configurable Heat remain later waves. Record the bounded
contract, relevant decisions, tuning and unresolved material questions before
editing; stop after the next checked wave for orchestrator review.
