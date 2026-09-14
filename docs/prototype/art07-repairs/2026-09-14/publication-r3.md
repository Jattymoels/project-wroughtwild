# ART-07R3 publication — 14 September 2026

R3 binds retained building face, cut-edge and endgrain maps along actual members, roof slopes and mineral surfaces. Original geometry, maps, collision and all 273 legal shape/material pairs remain.

Full G1/G2/D4/D5/D6 input hashes and the exact submitted seal were verified. The publisher applied the 12 declared files to fresh v02 after hashing all 4,787 original entries, reopened the three packed masters, and replayed both material inspections, catalogues, native payment/refusal transactions and their restores, plus paid-home construction and separate-process restores in both renderers. Fresh persistent-state fingerprints are compared.

Publisher inspected actual timber endgrain and octagonal/chamfer/triangle material views. Owner visual acceptance remains pending; the evidence is labelled catalogue inspection, separate from real paid-home replay.

The [machine-readable publication record](publication-r3.json) contains exact
commits, package identity, changed paths, all retained worker log hashes and the
fresh publisher process arguments, private states and log hashes.
The [worker receipt](receipts/r3.md) retains complete implementation evidence,
tuning explanations, benchmark measurements and limitations.

## Fresh publisher checks

Runtime: `D:\project-wroughtwild-art07-r3\build\art07-repairs\r3\v02\runtime`. All 4,796 declared runtime
source entries still match after execution. Runs used the unchanged shared runner,
fresh logs/private state and the single GPU mutex. These are verification runs,
not repeated timing benchmarks or target-hardware acceptance.

| Publisher job | Wall seconds | Exit |
| --- | ---: | ---: |
| import | 71.57 | 0 |
| publisher-packed-reopen | 1.75 | 0 |
| pass02-r3-forward_plus | 8.85 | 0 |
| pass02-r3-gl_compatibility | 8.98 | 0 |
| pass01-catalogue-forward_plus | 7.96 | 0 |
| pass01-catalogue-gl_compatibility | 7.02 | 0 |
| pass01-transactions-forward_plus | 6.90 | 0 |
| pass01-transactions-restore-forward_plus | 3.84 | 0 |
| pass01-transactions-gl_compatibility | 6.44 | 0 |
| pass01-transactions-restore-gl_compatibility | 4.04 | 0 |
| pass02-paid-r3-forward_plus | 114.72 | 0 |
| pass02-restore-r3-forward_plus | 107.72 | 0 |
| pass02-paid-r3-gl_compatibility | 110.20 | 0 |
| pass02-restore-r3-gl_compatibility | 103.64 | 0 |

## Integration and remaining gates

Original implementation `0d372ae68c7d7b620da27ad7141f9eebae766139` becomes `7bc9be05397e1492feb8fc98488a84cd3bede75d` on main.
Original receipt `22ca7ba702ee9316bca73aa654c25325dbf65988` becomes `ad34112783d233429630921733a38e4beb0a3f03`. Both were integrated by scoped
cherry-pick because R2 publication had advanced main beyond the common worker base.
The exact owned path contents match the worker commits. The publication notes and
delivery index accompany an ordinary non-force push to the approved origin/main;
remote-tip verification is reported separately after pushing.

G2-V02: partial; isolated directional material candidate is technically verified, with owner and combined R8/R9 acceptance pending.

R8 must reconcile G1Materials.material_for, G1Art.piece_mesh and PieceLook.apply_to with R2. Preserve accurate per-piece shape identity when meshes are reused. Edge maps increase loaded textures (worker paid-home values about 4 MiB Forward+ and 3 MiB Compatibility); timings are current-machine observations. Glass retains opacity 0.72 and attenuates heavily through multiple layers; no refraction is supplied. Native transaction screenshots share the original fixed directory; renderer-specific logs and checkpoints remain separate.

All 273 combinations, octagonal/chamfer/triangle support, native bodies, finite
stock, saved geography and paid ownership remain constraints. No ordinary runtime
adoption is implied. See [deliveries.json](deliveries.json) for current availability
and [SETUP](SETUP.md) for the next released wave. Required validators, whitespace,
commit ancestry and unrelated-work preservation are in
[publication checks](publication-r3-checks.json).
