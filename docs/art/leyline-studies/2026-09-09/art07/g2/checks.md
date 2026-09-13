# G2 executed checks

All 64 owned subprocesses exited 0. Native assertions are unchanged; the misnamed paid replay is explicitly excluded from restart proof. Full logs, exact arguments and isolated state paths are sealed locally.

| Job | Seconds | Result |
| --- | ---: | --- |
| b1 | 1.77 | B1_NATIVE_OK 15 |
| b3 | 2.65 | B3_NATIVE_OK 16621 |
| benchmark-art-forward_plus | 113.25 | G1_REVIEW_OK 4 views, 8 matched samples |
| benchmark-art-gl_compatibility | 114.68 | G1_REVIEW_OK 4 views, 8 matched samples |
| benchmark-baseline-forward_plus | 21.25 | G1_REVIEW_OK 4 views, 8 matched samples |
| benchmark-baseline-gl_compatibility | 26.76 | G1_REVIEW_OK 4 views, 8 matched samples |
| blender-reopen | 52.88 | G1_BLENDER_REOPEN_OK 30 6 |
| c1-partial | 1.62 | C1_NATIVE_OK partial-restart 9 |
| c1 | 1.71 | C1_NATIVE_OK flow 20 |
| c2-partial | 1.62 | C2_NATIVE_RESULT 12 checks, 0 failures |
| c2 | 1.61 | C2_NATIVE_RESULT 25 checks, 0 failures |
| c3-partial | 1.62 | C3_NATIVE_OK 9 |
| c3 | 1.61 | C3_NATIVE_OK 21 |
| c4-partial | 1.53 | C4_NATIVE_OK 22 |
| c4 | 1.53 | C4_NATIVE_OK 35 |
| c5-partial | 1.52 | C5_NATIVE_OK 66 |
| c5 | 1.70 | C5_NATIVE_OK 121 |
| canopy | 86.10 | G2_CANOPY 8 checks, 0 failures; 321 live trees |
| catalogue-forward_plus | 7.32 | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| catalogue-gl_compatibility | 6.89 | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| d1-restart | 3.04 | D1_RESTART 7676 checks, 0 failures |
| d1 | 3.23 | D1_PLACEMENT 8169 checks, 0 failures |
| d2-restart | 3.04 | D2_RESTART 6164 checks, 0 failures |
| d2 | 3.07 | D2_PLACEMENT 6563 checks, 0 failures |
| d3-restart | 6.54 | D3_RESTART 40431 checks, 0 failures |
| d3 | 5.70 | D3_PLACEMENT 35310 checks, 0 failures |
| e1-restart | 2.19 | E1_RESTORE 132 checks, 0 failures |
| e1 | 2.36 | E1_CHECKS 304 checks, 0 failures |
| e2-restart | 2.07 | E2_RESTORE 12 checks, 0 failures |
| e2 | 2.82 | E2_CHECKS 162 checks, 0 failures |
| e3-restart | 3.28 | E3_RESTART 33 checks, 0 failures |
| e3 | 3.40 | E3_CHECKS 775 checks, 0 failures |
| f1-restart | 2.82 | F1_RESTART 56 checks, 0 failures |
| f1 | 2.81 | F1_CHECKS 118 checks, 0 failures |
| f2-restart | 2.07 | F2_RESTART 29 checks 0 failures |
| f2 | 1.80 | F2_CHECKS 50 checks 0 failures |
| f3-restart | 2.64 | F3_RESTART 248 checks, 0 failures |
| f3 | 2.45 | F3_CHECKS 306 checks, 0 failures |
| f4-exhausted-forward_plus | 96.42 | F4_EXHAUSTED-RESTORE 29 checks, 0 failures |
| f4-exhausted-gl_compatibility | 92.40 | F4_EXHAUSTED-RESTORE 29 checks, 0 failures |
| f4-forward_plus | 118.03 | F4_CHECKS 227 checks, 0 failures |
| f4-gl_compatibility | 115.52 | F4_CHECKS 227 checks, 0 failures |
| f4-restart-forward_plus | 96.34 | F4_RESTORE 32 checks, 0 failures |
| f4-restart-gl_compatibility | 93.07 | F4_RESTORE 32 checks, 0 failures |
| fauna-forward_plus | 3.23 | G2_FAUNA 50 checks, 0 failures |
| fauna-gl_compatibility | 3.44 | G2_FAUNA 50 checks, 0 failures |
| home | 3.00 | HOME_WORKSHOP_REVIEW 1027 checks, 0 failures |
| import | 73.26 | Exit 0; detailed import/render log retained. |
| local-scenery | 87.54 | PLACEMENT_SCENERY 5254 checks, 0 failures |
| paid-art-restart | 121.65 | G1_PAID 865 checks, 0 failures |
| paid-art | 121.45 | G1_PAID 865 checks, 0 failures |
| paid-baseline | 18.25 | G1_PAID 865 checks, 0 failures |
| paid-fresh-restart | 85.66 | G1_PAID 8 checks, 0 failures |
| placement-restart | 2.83 | PLACEMENT_RESTART 60 checks, 0 failures |
| placement | 3.76 | PLACEMENT_TRANSACTIONS 470 checks, 0 failures |
| probe-art | 100.10 | G1_PROBE 9 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| probe-baseline | 24.10 | G1_PROBE 9 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| save-recovery | 3.75 | SAVE_RECOVERY 175 checks, 0 failures |
| smoke-forward_plus | 95.46 | Exit 0; detailed import/render log retained. |
| smoke-gl_compatibility | 91.40 | Exit 0; detailed import/render log retained. |
| unit | 20.20 | 398 checks, 0 failures |
| views-forward_plus | 206.42 | G1_REVIEW_OK 15 views, 0 matched samples |
| views-gl_compatibility | 199.88 | G1_REVIEW_OK 15 views, 0 matched samples |
| walk | 129.29 | G1_PAID 2 checks, 0 failures |

Warnings remain visible in the audit: expected invalid-input/save-recovery cases; SSAO unsupported by Compatibility (both art and baseline); ObjectDB shutdown warnings in eight isolated source fixture runs. The latter are a bounded cleanup handback, not proof of leak-free long sessions. No fatal engine/script diagnostic was accepted.
