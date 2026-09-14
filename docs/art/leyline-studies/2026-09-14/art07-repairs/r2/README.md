# ART-07R2 â€” setup and resource residency

The isolated R2 candidate reduces median paid-world setup from 91.559 to 58.742
seconds in Forward+ and from 87.130 to 56.785 seconds in Compatibility. All three
candidate observations per backend are below all three unchanged G1 observations.
Loaded textures fall from 1,307.77 to 867.07 MiB and from 1,288.49 to 789.82 MiB,
respectively. Primary benchmark buffer ranges and matched retained geometry are
unchanged; the separate reload buffer difference is recorded in `CHECKS.md`. See [costs.md](costs.md)
for every setup observation, controls, min/median/max and separate first-use costs.

The change shares only byte-and-import-equivalent textures, retains complete
material cache identities, memoizes repeated terrain queries during one B3
projection, and reuses B1's unchanged radius measurement. It introduces no tuning
values, mesh simplification, work-stage removal, lower texture detail, shorter
streaming distances, density changes or native ownership rules.

Sixty actual matched image pairs retain exact resource state and full surface-array
geometry. Fifty-nine are byte-identical; the remaining pair differs by one RGB
channel level at one pixel, with identical alpha. Original PNGs and real motion
frames are retained for owner review. The RTX 5090 results do not establish
acceptance on an owner-selected target device. Owner visual acceptance is pending;
ordinary-world rollout is outside scope.

## Source and execution

The worktree is `D:/project-wroughtwild-art07-r2`, branch `codex/art07-r2`. Initial
clean HEAD and the read-only published `origin/main` check both resolved to
`473ae7604b3841899c29629cf59f8836ed528424`. No owner checkout or peer worktree was
changed. R2 is in released wave 1 with no candidate predecessors. The runtime
remains pinned to `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`.

The common source is
`D:/project-wroughtwild-art07-g2/build/art07/g2/v01/sealed`, manifest
`fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd`.
The G2 evidence manifest is
`49827ac3fe3522a92cb74eecdf60cd857e1157b08f5d57f2d273c617606e93a1`.
Full `workspace.py verify --id r2` input results are retained at
`evidence/v01/input-verification-01.log` in the seal. The prepared 4,787 runtime
entries / 3,438,257,458 bytes were independently hashed before launch. All original
PNG maps and packed Blender masters remain unchanged; lossless interchange image
references and the affected scripts are the changed source derivatives.

D-013/D-030 govern appearance, with D-017, finite stock and the established
save/streaming contracts preserved. There is no unresolved body, seat or geography
decision within this change. Native retirement diagnostics remain a separately
reported lifecycle limitation, not a new rule; see [DIAGNOSTICS.md](DIAGNOSTICS.md).

All engine processes use the unchanged shared `run.ps1`, its process checks and
single `Local\Wroughtwild-Art07-GPU` mutex. The R2 queue performs a bounded wait
on that same mutex before invoking the runner. APPDATA, LOCALAPPDATA, TEMP/TMP and
Blender resources are private under this task's build tree. Other observed jobs
were left running. Benchmarks ran alone, separately from import and capture jobs.

## Review and reconstruction

- [METHOD.md](METHOD.md): timing boundaries, actual hardware, allocation scope and
  unchanged source profiling.
- [OBSERVATIONS.md](OBSERVATIONS.md): traversal, hidden geometry, matched images
  and first-use limitations.
- [CHECKS.md](CHECKS.md): actual process results, native/restart checks and reload
  allocations, with hashes of the underlying logs.
- [DIAGNOSTICS.md](DIAGNOSTICS.md): failed attempts, corrections and retained limits.
- [APPLICATION.md](APPLICATION.md): exact common-baseline reconstruction and
  composition with R1/R3/R7, plus R5/R6 source overlaps and R4 lifecycle review.

The final receipt gives the exact seal, manifest hash, source and receipt commits,
and any verification performed after sealing. `changes.json` lists every runtime
file/function/setting and baseline-relative hash. The worker commits only R2-owned
paths and does not push; the serial publisher handles main integration.
