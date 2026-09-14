# ART-07R1 publication — 14 September 2026

R1 widens the retained B1 crowns by fitting only the lower trunk. Native bodies, tree heights, selected LOD2, stock and source seating remain unchanged.

Full G1/G2/B1/C4 inputs and the submitted seal were verified before application. The publisher copied the selected packed models and source masters into v04, reopened two masters and all 19 exports, and reproduced source/UV/packed-map, triangle, height and material-binding audits. A fresh import, both renderer smoke jobs, native B1 flow with partial/final separate-process restores, and both 273-pair catalogues pass.

Publisher inspected actual Forward+ broadleaf/pine pairs and player-height home day/shade/dusk views. Crowns visibly spread while existing thin foliage, blunt limbs, strong lower flare and dark shade remain. Owner visual acceptance is pending.

The [machine-readable publication record](publication-r1.json) contains exact
commits, package identity, changed paths, all retained worker log hashes and the
fresh publisher process arguments, private states and log hashes.
The [worker receipt](receipts/r1.md) retains complete implementation evidence,
tuning explanations, benchmark measurements and limitations.

## Fresh publisher checks

Runtime: `D:\project-wroughtwild-art07-r1\build\art07-repairs\r1\v04\runtime`. All 4,891 declared runtime
source entries still match after execution. Runs used the unchanged shared runner,
fresh logs/private state and the single GPU mutex. These are verification runs,
not repeated timing benchmarks or target-hardware acceptance.

| Publisher job | Wall seconds | Exit |
| --- | ---: | ---: |
| publisher-reopen | 19.55 | 0 |
| publisher-source_audit | 8.90 | 0 |
| import | 82.73 | 0 |
| smoke-forward_plus | 89.12 | 0 |
| smoke-gl_compatibility | 84.76 | 0 |
| b1-after | 1.79 | 0 |
| b1-partial | 1.70 | 0 |
| b1-final | 1.68 | 0 |
| catalogue-forward_plus | 8.00 | 0 |
| catalogue-gl_compatibility | 7.31 | 0 |

## Integration and remaining gates

Original implementation `baf781a38e970fef52c47d4faa6a864aa479e60b` becomes `bd91501c8a7b17c9808aa606a10c14f0f46cab0a` on main.
Original receipt `5a35e6f0a30dc79981571f33a18c7dcff2550e7d` becomes `2e4de363eb770a475375fdb21fccbca3fbe7e86e`. Both were integrated by scoped
cherry-pick because R2 publication had advanced main beyond the common worker base.
The exact owned path contents match the worker commits. The publication notes and
delivery index accompany an ordinary non-force push to the approved origin/main;
remote-tip verification is reported separately after pushing.

G2-V01: partial; isolated canopy fit is technically verified, with visual acceptance and combined R8/R9 review pending.

Preserve worker-reported warning history, sparse LOD2 leaves, dark shade and renderer response. The worker reports higher GPU cost from wider foliage; current-machine timings and projected crown AABBs establish neither minimum-hardware acceptance nor opaque leaf coverage. R8 must merge G1Art.resource with R2 reuse and R7 habitat presentation. The publisher did not repeat the full paid-route benchmark suite.

All 273 combinations, octagonal/chamfer/triangle support, native bodies, finite
stock, saved geography and paid ownership remain constraints. No ordinary runtime
adoption is implied. See [deliveries.json](deliveries.json) for current availability
and [SETUP](SETUP.md) for the next released wave. Required validators, whitespace,
commit ancestry and unrelated-work preservation are in
[publication checks](publication-r1-checks.json).
