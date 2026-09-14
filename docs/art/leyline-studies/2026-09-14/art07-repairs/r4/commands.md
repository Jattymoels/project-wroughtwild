# R4 commands and reconstruction

Run from `D:/project-wroughtwild-art07-r4` on `codex/art07-r4` using the installed Python at `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

The prepared v01 runtime was reused after `workspace.py inspect --id r4` and full `workspace.py verify --id r4`. `prepared.json`, `evidence/prepared-runtime-check.json`, `evidence/verify-before.txt` and `evidence/verify-after.txt` retain the complete pin and payload hash evidence. No predecessor candidate was consumed: Wave 1 and R4 both have no predecessor requirements.

## Engine execution

Every engine job uses the unchanged shared `tools/wroughtwild-art07-repairs/run.ps1`. The owned wrapper waits at most 60 seconds on the same GPU mutex, then calls that runner; a busy slot launches nothing. It does not remove process checks, diagnostic checks or private user directories.

Completed and final job specifications are preserved at the package root. They include the generated import smoke; unchanged native flows and restarts; unchanged intermittent repeats and scalar-ID observers; reference and repaired twelve-cycle exercises; final native flows/restarts; and fresh native C3 rendering. Each spec records the exact engine, arguments, log and private state directory. Runner metadata records actual start time, PID, duration, settings and log hash.

The final engine command is:

```powershell
& ./tools/wroughtwild-art07-repairs/r4/run_when_free.ps1 -Specs build/art07-repairs/r4/v01/trace-quiet-jobs.json,build/art07-repairs/r4/v01/soak-after-final-jobs.json,build/art07-repairs/r4/v01/after-final-jobs.json,build/art07-repairs/r4/v01/render-after-jobs.json
```

These v01 log paths are an immutable execution record. Replaying requires fresh logs/private paths in a newly prepared absent version; never overwrite the original logs or seal. The work recipe's `snapshot`, `jobs --phase <fresh-name>` and `patch` steps are for an unmodified prepared runtime and deliberately reject existing baseline/master output. Diagnostic helpers in `evidence/diagnostic-source/` are copied only into the worker's `runtime/game/r4/`; they are outside R8's ten-file candidate delta. `evidence/iteration-01/` preserves the earlier helper and observer source before the final UI-drain refinement.

The initial `engine_checks.ps1` pipeline is retained as an executed recipe, not a command to replay over existing output. Its first post-run audit exposed an audit path-resolution bug; after that tool was corrected, the audit rejected E1's remaining orphan StringNames. The initial failing cleanup evidence and the successful final checks remain available in the package.

## Report and seal

After the final engine gates:

```powershell
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r4/finish_evidence.py
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r4/audit.py preservation --record preservation-final-runtime.json
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r4/report.py
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r4/audit.py seal --package 'D:/project-wroughtwild-art07-r4/build/art07-repairs/r4/v01/handoff-v02'
```

`finish_evidence.py` requires fresh 1280x720 native captures whose modification times follow the successful render process start, retains all 42 fall frames, and rechecks the recorded normal files. `report.py` compares every repaired marker with its unchanged native baseline and rejects leaks, warnings, orphan StringNames, assertion/engine errors or mismatched source bytes. `seal` creates a fresh absent handoff and never modifies an existing seal.

## Exact verification and R8 application

```powershell
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r4/audit.py verify --package 'D:/project-wroughtwild-art07-r4/build/art07-repairs/r4/v01/handoff-v02'
```

The verifier checks every payload SHA-256 and byte count and rejects missing or additional files. The receipt records the manifest's own SHA-256.

Publisher/R8-only application recipe, not executed by this worker:

```powershell
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r4/audit.py apply --package 'D:/project-wroughtwild-art07-r4/build/art07-repairs/r4/v01/handoff-v02' --target 'D:/project-wroughtwild-art07-r8/build/art07-repairs/r8/v01/runtime'
```

Use R8's actual fresh prepared runtime version if different. Application verifies the full candidate, pinned data/engine/DLL, every before-hash and every source master before writing only the ten declared files. A fixture-file overlap is rejected before any copy. R8 must reconcile the eight finish-function edits with other reviewed fixture changes and rerun the native evidence. This worker has not written into R8, changed the owner checkout, integrated main or pushed any branch.

The first seal at v01/handoff is retained as an earlier artifact. The final handoff-v02 also records the staged whitespace failure and terminal-newline-only helper normalization; no engine behavior changed.
