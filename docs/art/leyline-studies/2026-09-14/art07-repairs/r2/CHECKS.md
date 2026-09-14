# ART-07R2 actual checks

All jobs below are fresh candidate engine processes. Each retained log JSON records
the exact executable, arguments, start, wall duration, exit status, private paths
and combined-log SHA-256. Each accepted job exited zero with no fatal diagnostic
or competing process. Failed attempts remain separately visible in `DIAGNOSTICS.md`
and the full engine-job index; no receipt or static comparison is labelled an engine run.

## Native and restart results

| Fresh v03 job / log stem | Actual result line |
| --- | --- |
| `unit` | 398 checks, 0 failures |
| `probe-art` | G1_PROBE 9 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| `probe-baseline` | G1_PROBE 9 checks, 0 failures / map 550b2d742314136a71a8c177920059bd245996e744b8722c8ba8c68afbde4a70 |
| `b1-flow` | B1_NATIVE_OK 15 |
| `b1--restore-partial` | B1_NATIVE_OK 6 |
| `b1--restore-final` | B1_NATIVE_OK 6 |
| `b3-flow` | B3_NATIVE_OK 16621 |
| `b3--restore-partial` | B3_NATIVE_OK 10 |
| `b3--restore-final` | B3_NATIVE_OK 8 |
| `c1-flow` | C1_NATIVE_OK flow 20 |
| `c1--restore-partial` | C1_NATIVE_OK partial-restart 9 |
| `c1--restore-final` | C1_NATIVE_OK final-restart 7 |
| `c2-flow` | C2_NATIVE_RESULT 25 checks, 0 failures |
| `c2--restore-partial` | C2_NATIVE_RESULT 12 checks, 0 failures |
| `c2--restore-final` | C2_NATIVE_RESULT 10 checks, 0 failures |
| `c3-flow` | C3_NATIVE_OK 21 |
| `c3--restore-partial` | C3_NATIVE_OK 9 |
| `c3--restore-final` | C3_NATIVE_OK 9 |
| `c4-flow` | C4_NATIVE_OK 35 |
| `c4--restore-partial` | C4_NATIVE_OK 22 |
| `c4--restore-final` | C4_NATIVE_OK 22 |
| `c5-flow` | C5_NATIVE_OK 121 |
| `c5--restore-partial` | C5_NATIVE_OK 66 |
| `c5--restore-final` | C5_NATIVE_OK 52 |
| `e1-flow` | E1_CHECKS 304 checks, 0 failures |
| `e1-restore` | E1_RESTORE 132 checks, 0 failures |
| `e2-flow` | E2_CHECKS 162 checks, 0 failures |
| `e2-restore` | E2_RESTORE 12 checks, 0 failures |
| `e3-flow` | E3_CHECKS 775 checks, 0 failures |
| `e3-restore` | E3_RESTART 33 checks, 0 failures |
| `f1-flow` | F1_CHECKS 118 checks, 0 failures |
| `f1-restart` | F1_RESTART 56 checks, 0 failures |
| `f2-flow-b` | F2_CHECKS 50 checks 0 failures |
| `f2-restart` | F2_RESTART 29 checks 0 failures |
| `f3-flow` | F3_CHECKS 306 checks, 0 failures |
| `f3-restart` | F3_RESTART 248 checks, 0 failures |
| `projection-equivalence-b` | B3_NATIVE_OK 16676 |
| `paid-art` | G1_PAID 865 checks, 0 failures |
| `paid-art-restart` | G1_PAID 8 checks, 0 failures |
| `paid-baseline` | G1_PAID 865 checks, 0 failures |
| `living_frontier_flow-flow` | LF1_PLAYER_FLOW 733 checks, 0 failures |
| `living_frontier_flow-restore` | LF1_PLAYER_FLOW 15 checks, 0 failures |
| `living_frontier_wave2_flow-flow` | LF2_PLAYER_FLOW 216 checks, 0 failures |
| `living_frontier_wave2_flow-restore` | LF2_PLAYER_FLOW 26 checks, 0 failures |
| `living_frontier_green_flow-flow` | LF2_PLAYER_FLOW 129 checks, 0 failures |
| `living_frontier_green_flow-restore` | LF2_PLAYER_FLOW 9 checks, 0 failures |
| `living_frontier_heat_flow-flow` | LF2_PLAYER_FLOW 324 checks, 0 failures |
| `living_frontier_heat_flow-restore` | LF2_PLAYER_FLOW 14 checks, 0 failures |
| `catalogue-forward_plus` | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| `catalogue-gl_compatibility` | G1_CATALOGUE 1861 checks, 0 failures; 273 legal pairs |
| `f4-forward_plus` | F4_CHECKS 227 checks, 0 failures |
| `f4-restore-forward_plus` | F4_RESTORE 32 checks, 0 failures |
| `f4-exhausted-forward_plus` | F4_EXHAUSTED-RESTORE 29 checks, 0 failures |
| `reload-release-forward_plus-b` | R2_RELOAD_CHECKS 43 checks, 0 failures |
| `reload-restart-forward_plus-b` | R2_RELOAD_CHECKS 14 checks, 0 failures |
| `f4-gl_compatibility` | F4_CHECKS 227 checks, 0 failures |
| `f4-restore-gl_compatibility` | F4_RESTORE 32 checks, 0 failures |
| `f4-exhausted-gl_compatibility` | F4_EXHAUSTED-RESTORE 29 checks, 0 failures |
| `reload-release-gl_compatibility-b` | R2_RELOAD_CHECKS 43 checks, 0 failures |
| `reload-restart-gl_compatibility-b` | R2_RELOAD_CHECKS 14 checks, 0 failures |

B3 retains the original 16,621 assertions; the differential check adds exact mesh
and grounded picking-shape comparisons across changed support samplers. The two
catalogue processes each retain all 273 legal pairs, including triangle, octagonal
and chamfered uses. F4 inherits native pause, physical blockage, cancel/ownership,
partial paused restore and exhausted restore assertions. No ordinary gameplay
assertion, diagnostic guard or work state was removed.

## Repeated reload allocations

These are separate fixed-60-cadence native flows, not benchmark setup samples.
Two process frames and a rendered boundary separate visits. Each renderer passes
43 flow checks over three route/home/read cycles and 14 fresh-process restart
checks. Every native owner field and saved geography remains exact.

| Renderer | Point | Texture MiB | Buffer MiB |
| --- | --- | --- | --- |
| forward_plus | initial | 866.949707 | 206.777336 |
| forward_plus | cycle 1 | 870.949707 | 222.218498 |
| forward_plus | cycle 2 | 870.949707 | 222.224358 |
| forward_plus | cycle 3 | 870.949707 | 222.230217 |
| forward_plus | after native work | 871.119629 | 199.094894 |
| gl_compatibility | initial | 789.698779 | 202.543720 |
| gl_compatibility | cycle 1 | 795.032111 | 210.089161 |
| gl_compatibility | cycle 2 | 795.032111 | 210.089161 |
| gl_compatibility | cycle 3 | 795.032111 | 210.089161 |
| gl_compatibility | after native work | 795.157109 | 194.863621 |

Initial visits populate additional texture/cache data. Texture allocation is flat
across cycles 1 to 3. Forward+ buffers increase by 6,144 bytes per later cycle;
Compatibility is unchanged. The post-work scene is different, so its smaller
buffer count is not claimed as a same-scene saving. Three cycles do not establish
leak freedom, complete resource release or a target-device residency budget.

## Evidence locations and commands

In the seal, logs/specs live under `evidence/v01/`, `evidence/v02/` and
`evidence/v03/`. `evidence/v03/analysis/engine-jobs.json` indexes every actual job,
including failures. All engine execution used:

```powershell
& tools/wroughtwild-art07-repairs/r2/queue.ps1 -Specs @('<spec path>')
```

The retained executed specifications include `import-smoke.json` in each version;
v01 `benchmark-retry-jobs.json`; v02 `benchmark-jobs.json`; v03
`benchmark-jobs.json`, `control-benchmark-jobs.json`, `render-replay-jobs.json`,
`native-replay-jobs.json`, `remaining-native-rendered.json` and
`reload-rendered-paced-jobs.json`. Later fixes have their own fresh specifications;
the job index arguments and log hashes are authoritative.

Static checks are separate: full input/source hashes, 14 inverse source-replay
substitutions, five inherited display wrappers, Python AST parsing, PowerShell
syntax, exact geometry/native fingerprints, 60 RGBA image comparisons and full
sealed file-set verification. The final receipt records the source/receipt commits
and the fresh post-seal application/reopen check.

The four matched-view jobs produced 120 original 1440 x 900 PNGs (60 pairs).
F4 motion uses 60 actual PNG frames; the controller route uses 77. The two small
GIF previews record every original frame hash and playback cadence; they are
resized/paletted previews, not benchmark frames. Living Frontier native flows also
retain their actual 1440 x 900 captures. Owner review remains pending.

## Unchanged G1 reload attribution

The unchanged v01 production runtime also completed the same frame-paced flow in
both real renderers: 43 checks, zero failures each. Its fresh logs are
`reload-paced-g1-forward_plus` (293.80 seconds whole process) and
`reload-paced-g1-gl_compatibility` (285.75 seconds whole process). The complete
before/after cycle counters and timings are in
`evidence/v03/analysis/reload-cost-comparison.json`. This confirms the comparison
cadence without relabelling the separate immediate-retirement diagnostic as passing.

| Reload backend | G1 textures, cycles 1 to 3 MiB | R2 textures, cycles 1 to 3 MiB | G1 buffers, cycles 1 to 3 MiB | R2 buffers, cycles 1 to 3 MiB |
| --- | --- | --- | --- | --- |
| forward_plus | 1311.644043 to 1311.644043 | 870.949707 to 870.949707 | 221.928871 to 221.940590 | 222.218498 to 222.230217 |
| gl_compatibility | 1293.698699 to 1293.698699 | 795.032111 to 795.032111 | 210.089161 to 210.089161 | 210.089161 to 210.089161 |

Forward+ R2 retains 303,696 additional buffer bytes (about 0.29 MiB) after these
reloads compared with G1. Both have the same 6,144-byte increase per later cycle.
The scene geometry counts match, but backend buffers include renderer internals;
no unsupported cause or leak-free conclusion is assigned to this difference.
Compatibility post-reload buffer allocation matches exactly. The separately
measured primary startup/camera buffer ranges remain unchanged.

The final pre-seal index contains 110 successful engine processes and 7 retained failed
attempts across v01/v02/v03. The successful subset includes all 24 repeated
benchmark processes and the 60 native jobs tabulated above. Prelaunch mutex
deferrals and static tooling corrections are documented separately. The final
v01 production rehash confirms all 4,787 original source files remain unchanged.
