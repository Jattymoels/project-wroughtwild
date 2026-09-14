# ART-07R7 recipes

These recipes own only the R7 candidate and inspection fixtures. Run them from
`D:/project-wroughtwild-art07-r7` on `codex/art07-r7`. Original runtime, sources,
normal saves, owner checkout and other repairs remain read-only. Python is the
installed `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

## Verified inputs and versions

`workspace.py inspect --id r7` and `workspace.py verify --id r7` passed against
the published wave-1 gates before consumption. Full results are retained in
`build/art07-repairs/r7/v02/input-verification-r7-01.txt`. V01 was the prepared
common runtime plus published R1; its executed BEFORE captures are the comparison
baseline. V01's first composition was rejected visually and preserved. V02 is a
fresh prepared runtime plus the same R1 delta and the revised R7 composition.
The game/data/native pin is `6bb2e044dcd0bf1788896aa2c19cdf56fee93522` throughout.

All engine and Blender jobs use the unchanged `tools/wroughtwild-art07-repairs/run.ps1`.
For example, `./tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r7/v02/candidate-view-jobs-01.json`.
Its actual execution receipts preserve argument arrays, log SHA-256, private paths,
exit status, process checks and benchmark competitors. The job specifications are
immutable execution records; reruns need fresh IDs, logs, evidence directories and
private user paths. Do not rerun the old specs against occupied paths.

The job series was guarded by the same reentrant `Local\Wroughtwild-Art07-GPU`
mutex in the calling PowerShell thread between jobs. Each unchanged runner still
performs its own process check. Busy attempts defer without launching an engine.
No other process is interrupted. `APPDATA` is the recorded job state path, with
`LOCALAPPDATA=state/local`, `TEMP=TMP=state/temp`, and Blender resources in
`state/blender-user`. Godot's retained custom user directory resolves to
`state/ART07G1`. A restart deliberately uses its own corresponding paid-flow state.

## Recipes and responsibilities

- `consume.py`: verify prepared originals and the whole published R1 payload; apply
  only the 105 declared R1 files and record the exact parent runtime hashes.
- `setup_probe.py` / `source_probe.gd`: measure actual source and retained envelopes.
- `install.py`: apply the four explicit parent-relative presentation hooks, copy
  R7 materials/composition/settings, and write fresh import/smoke job specifications.
- `cover.gd`, `surface.gdshader`, `settings.json`: the candidate behavior. All sources
  share each retained root, use uniform scales and local yaw, fit inside the old
  mesh envelope including wind, and add no placement or collision authority.
- `setup_evidence.py`, `views.gd`, `audit.gd`: matched four-camera captures, actual
  roots/anchors/bodies/geography, parent crown bounds/overlaps, three light settings,
  near/middle/far views, live clock motion and separate settled benchmarks. The
  paired paid and route fixtures derive from R1 without removing native assertions.
- `setup_checks.py`, `mesh_checks.gd`: every composed vertex at both sway extrema,
  exact rooted bases, native catalogue, physics grounding, building clearing and
  excavation. The historical ecology fixture supplies an empty typed history
  container required by G1's C6 inspection adapter; its profile, native build
  function and assertions are otherwise retained. The first missing-container
  error is preserved, not filtered from logs.
- `reopen.py`: freshly reopen both unchanged packed B2 masters in Blender; record
  packed images and verify unchanged bytes. No source master, exported source mesh
  or texture pixel is edited by R7.
- `provenance.py`: exact copies of executed V01 BEFORE evidence and logs, plus
  rejected candidate records. It explicitly identifies baseline reuse.
- `coverage.py`, `roles.py`: all 33 roles, actual envelopes/counts and a conservative
  XZ footprint union with proposals for unmet reference fullness. No new geography.
- `collect.py`: strict recomputation of preservation, native/restart, vertex, cost
  and actual job/log checks. Failed diagnostics are retained separately.
- `present.py`: resize/tile real PNGs and encode actual captured frames. Source hashes,
  frame dimensions, measured or nominal playback intervals and operations are logged.
- `package.py seal handoff-final`: gated exact-file-set seal with R1 ancestry separated from R7;
  `package.py verify <absolute handoff>`: rehash every file and reject missing/extras.
- `apply.py <absolute handoff> <fresh prepared runtime>`: verify both candidates,
  apply the declared R1 delta once, then apply only R7's own delta.

## Reconstruct the sealed candidate

Choose an absent version, for example `v03` only if it is still absent:

```powershell
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/workspace.py prepare --id r7 --version v03
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/wroughtwild-art07-repairs/r7/apply.py D:/project-wroughtwild-art07-r7/build/art07-repairs/r7/v02/handoff-final D:/project-wroughtwild-art07-r7/build/art07-repairs/r7/v03/runtime
./tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r7/v03/import-smoke.json
```

`apply.py` validates fresh prepared before hashes; it cannot apply twice. For a new
source iteration, choose an absent version in `common.py`, prepare it, then run
consume, setup_probe, install, setup_evidence and setup_checks. Historical provenance
recipes name the executed V01/V02 records intentionally; do not rewrite their paths
and call old captures fresh runs. A fresh iteration must create its own evidence
specifications and comparisons. Keep timing jobs separate from imports, captures,
reopening and image encoding.

## Integration boundary

R1's canopy geometry/fit is the declared parent; its bytes and crown measurements
are unchanged. Published R2 has no direct file overlap with R7's four parent hooks,
but it repackages images in `game/b2/assets/sapling-shrub-lod2.glb` and supplies
texture aliases. R8 must apply that source-packaging delta once and validate R7's
material bindings after alias composition. R7's `changes.json` does not replace that
GLB. R2 performance changes were not consumed into these measurements. No loading
optimization, ordinary rollout, new body, recipe, scatter or save migration is added.
