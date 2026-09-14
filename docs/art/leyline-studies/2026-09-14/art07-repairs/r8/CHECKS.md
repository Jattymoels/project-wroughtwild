# R8 verification

The concrete acceptance matrix has 191 required successful fresh processes. Raw process receipts, commands, private paths, exit statuses and verified log hashes are in `records/acceptance.json` and `evidence/job-index.json`. Retained earlier failures remain separate.

| Required run | Whole-process seconds | Native/result markers |
| --- | --- | --- |
| v01 / import | 78.706 |  |
| v01 / smoke-forward_plus | 65.720 | G1_PACKAGED_LAUNCH_OK |
| v01 / smoke-gl_compatibility | 63.258 | G1_PACKAGED_LAUNCH_OK |
| v01 / import-final-sources | 15.317 |  |
| v01 / unit | 7.805 | 398 checks, 0 failures |
| v01 / ecology | 132.186 | ECOLOGY_BUILDINGS 102 checks, 0 failures |
| v01 / paid-art-forward_plus-02 | 97.198 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-art-forward_plus | 60.659 | G1_PAID 8 checks, 0 failures |
| v01 / probe-art-forward_plus | 75.985 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / paid-baseline-forward_plus | 24.452 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-baseline-forward_plus | 12.273 | G1_PAID 8 checks, 0 failures |
| v01 / probe-baseline-forward_plus | 27.218 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / catalogue-forward_plus | 7.514 | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| v01 / actors-forward_plus | 3.495 | G2_FAUNA 50 checks, 0 failures |
| v01 / grounding-forward_plus | 2.985 | CODEX_GROUNDING 16 checks, 0 failures |
| v01 / mesh-envelope-forward_plus | 2.742 | R7_MESH_CHECKS 73 checks, 0 failures |
| v01 / paid-art-gl_compatibility | 97.912 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-art-gl_compatibility | 60.604 | G1_PAID 8 checks, 0 failures |
| v01 / probe-art-gl_compatibility | 73.999 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / paid-baseline-gl_compatibility | 26.663 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-baseline-gl_compatibility | 12.352 | G1_PAID 8 checks, 0 failures |
| v01 / probe-baseline-gl_compatibility | 26.076 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / catalogue-gl_compatibility | 6.853 | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| v01 / actors-gl_compatibility | 3.263 | G2_FAUNA 50 checks, 0 failures |
| v01 / grounding-gl_compatibility | 3.019 | CODEX_GROUNDING 16 checks, 0 failures |
| v01 / mesh-envelope-gl_compatibility | 2.639 | R7_MESH_CHECKS 73 checks, 0 failures |
| v01 / projection-equivalence-clean | 5.107 | B3_NATIVE_OK 16676 |
| v01 / cleanup-b3-flow-forward_plus | 4.874 | B3_NATIVE_OK 16645 |
| v01 / cleanup-b3-partial-forward_plus | 2.538 | B3_NATIVE_OK 10 |
| v01 / cleanup-b3-final-forward_plus | 2.464 | B3_NATIVE_OK 8 |
| v01 / cleanup-c1-flow-forward_plus | 7.345 | C1_NATIVE_OK flow 83 |
| v01 / cleanup-c1-partial-forward_plus | 2.624 | C1_NATIVE_OK partial-restart 9 |
| v01 / cleanup-c1-final-forward_plus | 2.568 | C1_NATIVE_OK final-restart 7 |
| v01 / cleanup-c2-flow-forward_plus | 4.000 | C2_NATIVE_RESULT 41 checks, 0 failures |
| v01 / cleanup-c2-partial-forward_plus | 2.554 | C2_NATIVE_RESULT 13 checks, 0 failures |
| v01 / cleanup-c2-final-forward_plus | 2.545 | C2_NATIVE_RESULT 11 checks, 0 failures |
| v01 / cleanup-c3-flow-forward_plus | 4.281 | C3_NATIVE_OK 68 |
| v01 / cleanup-c3-partial-forward_plus | 2.593 | C3_NATIVE_OK 9 |
| v01 / cleanup-c3-final-forward_plus | 2.494 | C3_NATIVE_OK 9 |
| v01 / cleanup-c4-flow-forward_plus | 3.855 | C4_NATIVE_OK 80 |
| v01 / cleanup-c4-partial-forward_plus | 2.496 | C4_NATIVE_OK 22 |
| v01 / cleanup-c4-final-forward_plus | 2.439 | C4_NATIVE_OK 22 |
| v01 / cleanup-e1-flow-forward_plus | 4.020 | E1_CHECKS 304 checks, 0 failures |
| v01 / cleanup-e1-restart-forward_plus | 3.239 | E1_RESTORE 132 checks, 0 failures |
| v01 / cleanup-f2-flow-forward_plus | 3.416 | F2_CHECKS 50 checks 0 failures |
| v01 / cleanup-f2-restart-forward_plus | 2.981 | F2_RESTART 29 checks 0 failures |
| v01 / cleanup-f3-flow-forward_plus | 3.574 | F3_CHECKS 306 checks, 0 failures |
| v01 / cleanup-f3-restart-forward_plus | 2.830 | F3_RESTART 248 checks, 0 failures |
| v01 / cleanup-f3-depleted-forward_plus | 3.076 | F3_RESTART-DEPLETED 247 checks, 0 failures |
| v01 / cleanup-b3-flow-gl_compatibility | 5.072 | B3_NATIVE_OK 16645 |
| v01 / cleanup-b3-partial-gl_compatibility | 2.931 | B3_NATIVE_OK 10 |
| v01 / cleanup-b3-final-gl_compatibility | 2.876 | B3_NATIVE_OK 8 |
| v01 / cleanup-c1-flow-gl_compatibility | 7.088 | C1_NATIVE_OK flow 83 |
| v01 / cleanup-c1-partial-gl_compatibility | 3.006 | C1_NATIVE_OK partial-restart 9 |
| v01 / cleanup-c1-final-gl_compatibility | 2.993 | C1_NATIVE_OK final-restart 7 |
| v01 / cleanup-c2-flow-gl_compatibility | 3.872 | C2_NATIVE_RESULT 41 checks, 0 failures |
| v01 / cleanup-c2-partial-gl_compatibility | 2.917 | C2_NATIVE_RESULT 13 checks, 0 failures |
| v01 / cleanup-c2-final-gl_compatibility | 2.907 | C2_NATIVE_RESULT 11 checks, 0 failures |
| v01 / cleanup-c3-flow-gl_compatibility | 4.233 | C3_NATIVE_OK 68 |
| v01 / cleanup-c3-partial-gl_compatibility | 3.112 | C3_NATIVE_OK 9 |
| v01 / cleanup-c3-final-gl_compatibility | 2.973 | C3_NATIVE_OK 9 |
| v01 / cleanup-c4-flow-gl_compatibility | 3.984 | C4_NATIVE_OK 80 |
| v01 / cleanup-c4-partial-gl_compatibility | 2.853 | C4_NATIVE_OK 22 |
| v01 / cleanup-c4-final-gl_compatibility | 2.826 | C4_NATIVE_OK 22 |
| v01 / cleanup-e1-flow-gl_compatibility | 3.921 | E1_CHECKS 304 checks, 0 failures |
| v01 / cleanup-e1-restart-gl_compatibility | 3.405 | E1_RESTORE 132 checks, 0 failures |
| v01 / cleanup-f2-flow-gl_compatibility | 3.023 | F2_CHECKS 50 checks 0 failures |
| v01 / cleanup-f2-restart-gl_compatibility | 3.250 | F2_RESTART 29 checks 0 failures |
| v01 / cleanup-f3-flow-gl_compatibility | 3.246 | F3_CHECKS 306 checks, 0 failures |
| v01 / cleanup-f3-restart-gl_compatibility | 3.184 | F3_RESTART 248 checks, 0 failures |
| v01 / cleanup-f3-depleted-gl_compatibility | 3.395 | F3_RESTART-DEPLETED 247 checks, 0 failures |
| v01 / canopy-b1-flow-forward_plus | 6.168 | B1_NATIVE_OK 83 |
| v01 / canopy-b1-partial-forward_plus | 4.488 | B1_NATIVE_OK 30 |
| v01 / canopy-b1-final-forward_plus | 4.572 | B1_NATIVE_OK 30 |
| v01 / canopy-c4-flow-forward_plus | 5.836 | C4_NATIVE_OK 104 |
| v01 / canopy-c4-partial-forward_plus | 4.477 | C4_NATIVE_OK 46 |
| v01 / canopy-c4-final-forward_plus | 4.419 | C4_NATIVE_OK 46 |
| v01 / f4-flow-forward_plus | 78.470 | F4_CHECKS 227 checks, 0 failures |
| v01 / f4-fractional-forward_plus | 57.803 | F4_RESTORE 32 checks, 0 failures |
| v01 / f4-exhausted-forward_plus | 56.260 | F4_EXHAUSTED-RESTORE 29 checks, 0 failures |
| v01 / reload-flow-forward_plus | 199.295 | R2_RELOAD_CHECKS 43 checks, 0 failures |
| v01 / reload-restart-forward_plus | 75.810 | R2_RELOAD_CHECKS 14 checks, 0 failures |
| v01 / chest-flow-forward_plus | 8.662 | R5_CAPTURE 294 checks, 0 failures |
| v01 / chest-restore-forward_plus | 3.934 | R5_RESTORE 32 checks, 0 failures |
| v01 / ore-flow-forward_plus | 34.142 | R6_CHECKS 4528 checks, 0 failures |
| v01 / ore-restart-forward_plus | 21.120 | R6_CHECKS 2234 checks, 0 failures |
| v01 / canopy-b1-flow-gl_compatibility | 6.273 | B1_NATIVE_OK 83 |
| v01 / canopy-b1-partial-gl_compatibility | 4.898 | B1_NATIVE_OK 30 |
| v01 / canopy-b1-final-gl_compatibility | 4.806 | B1_NATIVE_OK 30 |
| v01 / canopy-c4-flow-gl_compatibility | 5.887 | C4_NATIVE_OK 104 |
| v01 / canopy-c4-partial-gl_compatibility | 4.776 | C4_NATIVE_OK 46 |
| v01 / canopy-c4-final-gl_compatibility | 4.782 | C4_NATIVE_OK 46 |
| v01 / f4-flow-gl_compatibility | 77.520 | F4_CHECKS 227 checks, 0 failures |
| v01 / f4-fractional-gl_compatibility | 56.483 | F4_RESTORE 32 checks, 0 failures |
| v01 / f4-exhausted-gl_compatibility | 56.636 | F4_EXHAUSTED-RESTORE 29 checks, 0 failures |
| v01 / reload-flow-gl_compatibility | 196.582 | R2_RELOAD_CHECKS 43 checks, 0 failures |
| v01 / reload-restart-gl_compatibility | 74.751 | R2_RELOAD_CHECKS 14 checks, 0 failures |
| v01 / chest-flow-gl_compatibility | 9.178 | R5_CAPTURE 294 checks, 0 failures |
| v01 / chest-restore-gl_compatibility | 4.282 | R5_RESTORE 32 checks, 0 failures |
| v01 / ore-flow-gl_compatibility | 32.649 | R6_CHECKS 4528 checks, 0 failures |
| v01 / ore-restart-gl_compatibility | 20.754 | R6_CHECKS 2234 checks, 0 failures |
| v01 / extra-e2-flow-forward_plus | 4.548 | E2_CHECKS 162 checks, 0 failures |
| v01 / extra-e2-restart-forward_plus | 3.125 | E2_RESTORE 12 checks, 0 failures |
| v01 / extra-e3-flow-forward_plus | 5.092 | E3_CHECKS 775 checks, 0 failures |
| v01 / extra-e3-restart-forward_plus | 4.238 | E3_RESTART 33 checks, 0 failures |
| v01 / extra-f1-flow-forward_plus | 3.618 | F1_CHECKS 118 checks, 0 failures |
| v01 / extra-f1-restart-forward_plus | 2.961 | F1_RESTART 56 checks, 0 failures |
| v01 / extra-f1-depleted-forward_plus | 3.246 | F1_RESTART-DEPLETED 55 checks, 0 failures |
| v01 / extra-c5-flow-forward_plus | 5.420 | C5_NATIVE_OK 178 |
| v01 / extra-c5-partial-forward_plus | 2.435 | C5_NATIVE_OK 66 |
| v01 / extra-c5-final-forward_plus | 2.490 | C5_NATIVE_OK 52 |
| v01 / extra-e2-flow-gl_compatibility | 4.314 | E2_CHECKS 162 checks, 0 failures |
| v01 / extra-e2-restart-gl_compatibility | 3.217 | E2_RESTORE 12 checks, 0 failures |
| v01 / extra-e3-flow-gl_compatibility | 4.700 | E3_CHECKS 775 checks, 0 failures |
| v01 / extra-e3-restart-gl_compatibility | 4.541 | E3_RESTART 33 checks, 0 failures |
| v01 / extra-f1-flow-gl_compatibility | 3.385 | F1_CHECKS 118 checks, 0 failures |
| v01 / extra-f1-restart-gl_compatibility | 3.271 | F1_RESTART 56 checks, 0 failures |
| v01 / extra-f1-depleted-gl_compatibility | 3.564 | F1_RESTART-DEPLETED 55 checks, 0 failures |
| v01 / extra-c5-flow-gl_compatibility | 5.428 | C5_NATIVE_OK 178 |
| v01 / extra-c5-partial-gl_compatibility | 2.808 | C5_NATIVE_OK 66 |
| v01 / extra-c5-final-gl_compatibility | 2.787 | C5_NATIVE_OK 52 |
| v01 / reopen-r1 | 19.264 | R1_FRESH_REOPEN_OK 2 19 |
| v01 / reopen-r3 | 1.603 | R3_PACKED_SOURCE_REOPEN_OK 3 masters 102 images |
| v01 / reopen-r5 | 78.286 | R5_REOPEN_OK 16 |
| v01 / reopen-r6 | 16.957 | R6_MASTER_REOPEN 153 meshes 7 packed images |
| v01 / reopen-r7 | 1.535 | R7_PACKED_REOPEN_OK 2 |
| v01 / comfort-live-forward_plus | 63.048 | R8_COMFORT verified 120 rendered player frames; cursor visible; window no-focus |
| v01 / comfort-live-gl_compatibility | 62.049 | R8_COMFORT verified 120 rendered player frames; cursor visible; window no-focus |
| v01 / building-combined-forward_plus | 8.549 | R3_INSPECTION 469 checks, 0 failures, 91 retained pieces |
| v01 / building-g1-forward_plus | 8.328 | R3_INSPECTION 458 checks, 0 failures, 91 retained pieces |
| v01 / full-kit-forward_plus | 159.288 | G1_REVIEW_OK 15 views, 0 matched samples |
| v01 / habitat-forward_plus | 112.350 | R7_VIEWS_OK after 4 views 0 timed samples 0 failures |
| v01 / walk-forward_plus | 92.981 | G1_PAID 2 checks, 0 failures |
| v01 / building-combined-gl_compatibility | 8.706 | R3_INSPECTION 469 checks, 0 failures, 91 retained pieces |
| v01 / building-g1-gl_compatibility | 8.379 | R3_INSPECTION 458 checks, 0 failures, 91 retained pieces |
| v01 / full-kit-gl_compatibility | 140.363 | G1_REVIEW_OK 15 views, 0 matched samples |
| v01 / habitat-gl_compatibility | 112.103 | R7_VIEWS_OK after 4 views 0 timed samples 0 failures |
| v01 / walk-gl_compatibility | 95.551 | G1_PAID 2 checks, 0 failures |
| v02 / import | 85.346 |  |
| v02 / smoke-forward_plus | 96.868 | G1_PACKAGED_LAUNCH_OK |
| v02 / smoke-gl_compatibility | 92.808 | G1_PACKAGED_LAUNCH_OK |
| v02 / original-full-kit-forward_plus | 239.246 | G1_REVIEW_OK 15 views, 0 matched samples |
| v02 / original-full-kit-gl_compatibility | 212.480 | G1_REVIEW_OK 15 views, 0 matched samples |
| v01 / import-v01-encoding-final | 4.780 |  |
| v01 / smoke-forward_plus-v01-encoding-final | 64.484 | G1_PACKAGED_LAUNCH_OK |
| v01 / smoke-gl_compatibility-v01-encoding-final | 62.342 | G1_PACKAGED_LAUNCH_OK |
| v02 / import-v02-encoding-final | 4.346 |  |
| v02 / smoke-forward_plus-v02-encoding-final | 95.449 | G1_PACKAGED_LAUNCH_OK |
| v02 / smoke-gl_compatibility-v02-encoding-final | 92.107 | G1_PACKAGED_LAUNCH_OK |
| v01 / paid-art-forward_plus-final | 97.051 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-art-forward_plus-final | 60.227 | G1_PAID 8 checks, 0 failures |
| v01 / probe-art-forward_plus-final | 75.640 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / paid-baseline-forward_plus-final | 24.259 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-baseline-forward_plus-final | 12.275 | G1_PAID 8 checks, 0 failures |
| v01 / probe-baseline-forward_plus-final | 26.533 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / paid-art-gl_compatibility-final | 96.395 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-art-gl_compatibility-final | 59.391 | G1_PAID 8 checks, 0 failures |
| v01 / probe-art-gl_compatibility-final | 73.260 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v01 / paid-baseline-gl_compatibility-final | 26.362 | G1_PAID 865 checks, 0 failures |
| v01 / paid-restart-baseline-gl_compatibility-final | 12.220 | G1_PAID 8 checks, 0 failures |
| v01 / probe-baseline-gl_compatibility-final | 25.569 | G1_PROBE 10 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| v02 / original-benchmark-art-forward_plus-01 | 115.019 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-baseline-forward_plus-01 | 21.898 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-art-forward_plus-02 | 115.308 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-baseline-forward_plus-02 | 21.918 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-art-forward_plus-03 | 114.428 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-baseline-forward_plus-03 | 22.291 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-art-gl_compatibility-01 | 112.735 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-baseline-gl_compatibility-01 | 25.179 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-art-gl_compatibility-02 | 112.403 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-baseline-gl_compatibility-02 | 25.203 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-art-gl_compatibility-03 | 111.691 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-benchmark-baseline-gl_compatibility-03 | 25.162 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-art-forward_plus-01 | 83.436 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-baseline-forward_plus-01 | 21.891 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-art-forward_plus-02 | 83.527 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-baseline-forward_plus-02 | 21.794 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-art-forward_plus-03 | 83.334 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-baseline-forward_plus-03 | 22.491 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-art-gl_compatibility-01 | 83.894 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-baseline-gl_compatibility-01 | 25.126 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-art-gl_compatibility-02 | 83.846 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-baseline-gl_compatibility-02 | 24.942 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-art-gl_compatibility-03 | 83.694 | G1_REVIEW_OK 4 views, 8 matched samples |
| v01 / benchmark-baseline-gl_compatibility-03 | 24.927 | G1_REVIEW_OK 4 views, 8 matched samples |
| v02 / original-traversal-art-forward_plus | 123.304 | G1_PAID 4 checks, 0 failures |
| v02 / original-traversal-baseline-forward_plus | 38.294 | G1_PAID 4 checks, 0 failures |
| v02 / original-traversal-art-gl_compatibility | 119.894 | G1_PAID 4 checks, 0 failures |
| v02 / original-traversal-baseline-gl_compatibility | 37.933 | G1_PAID 4 checks, 0 failures |
| v01 / traversal-art-forward_plus | 88.710 | G1_PAID 4 checks, 0 failures |
| v01 / traversal-art-gl_compatibility | 86.871 | G1_PAID 4 checks, 0 failures |

These whole-process durations include setup, assertions/captures and shutdown. They are not substituted for the separately measured setup or settled-frame values in `costs.md`. Native/reload timings recorded during fixture runs are diagnostic, not isolated benchmark samples.

All four paid flows pass 865 checks; four fresh-process restores pass eight. Initial/paid/final save fingerprints, route records and final-hook geography match between art-on/off and between renderers. The canonical full probe also matches the verified historical G1 snapshot; that historical comparison is explicitly not a fresh G1 engine run. Only ephemeral generated station scene names are omitted, never persistent station keys or saved poses.

All eight R4 fixtures have 44 successful fresh flow/restore jobs. Every terminal report has zero children and observed playbacks and no ObjectDB leak warning. F4 retains native escrow/payment/drive, real pause/block and synchronous fractional/exhausted recovery. The native save manager bytes and call order remain unchanged.

Packed-source reopens cover two tree masters and 19 exports; three building material masters with 102 images; the chest master with 16 body/lid exports; the selected ore master with 153 meshes and seven packed images; and two retained ground-cover masters. Exact before/after input hashes and all copied selected source hashes are checked.

Both live comfort jobs observe 120 rendered player process frames with visible mouse mode and the real window no-focus flag. No desktop pointer movement is automated. Normal-play runtime excludes the override and preserves the original capture branch.

Runtime gates are separate from owner visual acceptance, continuous human first-hour play and minimum-hardware clearance. See `README.md`, `TUNING.md`, `DIAGNOSTICS.md` and `image-provenance.json`.
