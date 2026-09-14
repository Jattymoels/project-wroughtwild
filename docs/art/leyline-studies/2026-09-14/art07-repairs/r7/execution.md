# R7 executed jobs

The actual guarded jobs below all exited 0 with no fatal diagnostic. Logs are in the sealed logs directory, with V01 baselines in evidence/v01-logs. Full argument arrays, process checks, private paths and hashes are in technical-checks.json.

| Job | Seconds | Checks / result text |
| --- | ---: | --- |
| r7-import | 85.93 |  |
| r7-smoke-forward_plus | 87.66 | G1_PACKAGED_LAUNCH_OK |
| r7-smoke-gl_compatibility | 85.28 | G1_PACKAGED_LAUNCH_OK |
| parse-views-01 | 1.26 |  |
| parse-audit-01 | 1.16 |  |
| parse-cover-01 | 1.16 |  |
| parse-mesh_checks-02 | 1.21 |  |
| views-after-forward_plus | 138.39 | R7_VIEWS_OK after 4 views 0 timed samples 0 failures |
| views-after-gl_compatibility | 134.65 | R7_VIEWS_OK after 4 views 0 timed samples 0 failures |
| packed-reopen-01 | 1.52 |  |
| paid-before | 130.63 | G1_PAID 865 checks, 0 failures |
| paid-restart-before | 85.16 | G1_PAID 8 checks, 0 failures |
| paid-after | 132.78 | G1_PAID 865 checks, 0 failures |
| paid-restart-after | 78.95 | G1_PAID 8 checks, 0 failures |
| mesh-checks-01 | 1.24 | R7_MESH_CHECKS 73 checks, 0 failures |
| ecology-before-02 | 198.02 | ECOLOGY_BUILDINGS 102 checks, 0 failures |
| ecology-after-02 | 197.97 | ECOLOGY_BUILDINGS 102 checks, 0 failures |
| catalogue-forward_plus | 9.28 | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| catalogue-gl_compatibility | 6.93 | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| grounding-forward_plus-02 | 2.82 | CODEX_GROUNDING 16 checks, 0 failures |
| grounding-gl_compatibility-02 | 2.65 | CODEX_GROUNDING 16 checks, 0 failures |
| cost-before-forward_plus | 125.47 | R7_VIEWS_OK before 4 views 12 timed samples 0 failures |
| cost-after-forward_plus | 124.17 | R7_VIEWS_OK after 4 views 12 timed samples 0 failures |
| cost-before-gl_compatibility | 128.32 | R7_VIEWS_OK before 4 views 12 timed samples 0 failures |
| cost-after-gl_compatibility | 133.55 | R7_VIEWS_OK after 4 views 12 timed samples 0 failures |
| source-probe-03 | 1.24 |  |
| route-motion-forward_plus | 118.38 | G1_PAID 2 checks, 0 failures |
| views-before-forward_plus-02 | 127.22 | R7_VIEWS_OK before 4 views 0 timed samples 0 failures |
| views-before-gl_compatibility-02 | 125.25 | R7_VIEWS_OK before 4 views 0 timed samples 0 failures |

Run each corresponding job specification through `./tools/wroughtwild-art07-repairs/run.ps1 -Spec <spec>`. The exact job specifications are listed below. route-capture-jobs-01 executes the route, then the four cost jobs serially in separate processes; cost-jobs-01 is the preserved cost-only subset. No capture occurs in a benchmark process.

- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\r7-import-smoke-01.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\accepted-parse-jobs.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\source-probe-jobs-03.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\candidate-view-jobs-01.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\reopen-jobs-01.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\accepted-regression-jobs.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\paid-jobs-01.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\route-capture-jobs-01.json`
- `D:\project-wroughtwild-art07-r7\build\art07-repairs\r7\v02\cost-jobs-01.json`

Accepted lists can assemble individually executed jobs from the preserved original specifications; their IDs, arguments and log hashes are verified against actual runner receipts. Reproduction requires fresh logs/state/evidence paths and must not overwrite these records.

Retained diagnostics:

- The direct standalone grounding scene failed during resource preloading; the owned wrapper preloads the existing sandpit resource graph before running the unchanged original fixture. Original failure log remains.
- V02 first historical ecology test hit the inherited C6 expectation of CataclysmSites, absent in frontier_v3. Owned fixture now supplies an empty typed history container only; original profile/build logic/assertions are retained. Failure log is preserved.
- V02 first mesh-check parser run failed inference of a local Vector3; explicit type fixed in fixture and fresh parse-mesh_checks-02 passed. Failed original log retained.
- V01 first source probe failed because its output directory was missing; corrected before the accepted source probe.
- V01 first view fixture rejected mixed indentation; corrected and explicitly parsed.
- V01 darker/narrow shrub candidate rejected visually; all original images/logs retained. V02 changes only its composition and nonemissive leaf lighting.
- Busy-slot attempts launched no engine and the shared wrapper exposed its missing-empty-log diagnostic; process/mutex guards remained unchanged.
- Existing Compatibility SSAO warnings remain visible; no rendering diagnostic is suppressed.

CPU Python syntax checks and full parent-payload preservation checks also pass. No error filtering, weakened native assertion or receipt substituted for a fresh engine execution is used.
