# PLAY-03 — underground transition and local incident recorder

The game now has an opt-in local recorder for the next underground lag incident.
It retains entry, falling and stationary intervals, location, streaming work and
controller/render observations without changing controls or quality.
**Diagnostic-only progress: PLAY-03 remains open. No lag fix is claimed.**

Coordinator adoption, 15 September: worker `13d5bdd` is integrated on main as
`cbc6f67`. The 7 transition and 19 recorder checks below were reused; one hidden
headless main import passed in 6.8 seconds, exit 0, no reported errors. No further
underground run was made. The owner is happy to wait for their next playthrough;
investigation is parked until new incident evidence or an explicit request.
Normal play keeps the recorder off. Use the optional launch instructions below
when that playthrough is convenient; no playtest is needed now.

The completed staged drop had brief entry spikes but did not reproduce continuing
underground slowdown. The owner's exact save/location, duration and stationary
behavior remain unknown. Owner playtesting is deferred.

## Scope and findings

Worktree: `D:/Wroughtwild/work/play03-underground`, branch
`codex/play03-underground`, base `85a67b22544f7525ec0bdf7cb74636dafefc4dda`.
Current owner rules and required reading were followed. No gameplay decision,
tuning, save field, native build, dependency, art replacement, movement restriction
or streaming schedule changed.

The risk was a missing entry window: PLAY-01 prepared and warmed its cave before
timing. Initial hypotheses were synchronous area/resource work, continuing
controller/actor cost and rendering work. Terrain chunks cover full vertical
columns; resource selection uses X/Z distance. Depth alone does not request a
separate underground layer. The terrain guard uses 3D distance; this does not
rule out every depth-related cost.

### Completed transition

Godot 4.5-stable, RTX 5090, Ryzen 9 9950X3D, Forward+, 1280x720, VSync off,
120fps cap, Dummy audio. Visible mouse and `WINDOW_FLAG_NO_FOCUS` assertions
passed using a BOM-free override and `--r8-no-mouse-capture`.

Two selector attempts failed before sampling: no six-metre native drop was found
in the bounded 160m spawn area, first for a 3x3 footprint, then for the actual
capsule in loaded chunks. Both failed logs remain; these are failed fixtures,
not passed gameplay checks or evidence that ordinary caves fail.

The completed fixture instead uses the previously recorded seed-1 V6 cave at
X=495.5, Z=361.5. The saved-edit application path opens a **synthetic** 3x3 shaft,
removing solid voxels only at Y>=25. The player is staged at Y=32.1, held for two
frames for the normal stream guard, then released under ordinary gravity and
collision. It lands at Y=24.9605, followed by four seconds with stationary input.
Combat, actors and world processing remain active. This is not the owner's route,
normal digging input, or a save compatibility test. No owner save was used.

Timing starts before staging/edit application, with no arrival warmup. World
setup took 34.358s and is separately recorded. The synthetic edit took 47.191ms,
included in the staging frame. No screenshots, rendered support queries or
per-frame writes occur inside sampling. Existing observers add unmeasured overhead.

| Window | Frames | Median | p95 | Worst |
| --- | ---: | ---: | ---: | ---: |
| Synthetic edit, relocation and arrival guard | 2 | 864.844ms | 864.844ms | 864.844ms |
| Entry and physical fall | 136 | 8.172ms | 12.960ms | 51.603ms |
| After landing, stationary input | 481 | 8.035ms | 10.892ms | 14.414ms |

Staging frames took 864.844 and 64.609ms. The first contains 250.769ms in Terrain's
callback and 182.676ms between render pre/post signals, plus fixture/deferred work
and first rendering. These overlapping observations cannot be added. This pause
is not an ordinary underground benchmark.

The fall has two frames above 33.33ms: 51.603 and 35.240ms. Terrain callbacks take
46.882 and 30.555ms, versus last chunk phases of 2.360 and 2.291ms. Other callback
work, including resource arrivals, is implicated but not precisely identified.
Player callbacks stay below 0.12ms. No safety refill is counted; relocation's
guard is separate. No stationary frame exceeds 33.33ms. Decoration remains queued,
so standing still does not mean every background job has finished.

This does not justify a causal correction. The recorder adds separate chunk and
resource tick timing, synchronous area counts/duration and the slowest constructed
resource visual per interval to capture the next actual incident.

## Normal play and incident capture

After coordinator integration, ordinary play needs no new flag:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

To record an incident, use the normal game and its usual save/campaign options,
adding one argument after `--`:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game' -- '--play03-trace=D:/Wroughtwild/work/play03-underground/build/play03/player-traces'
```

Keep `--living-frontier-wave7` if that is the usual campaign option. Before
integration, substitute this worker's `game` path. Continue or start normally;
recording does not choose or copy a save. Visit the affected hole/cave. After lag
starts, stand still about five seconds, then **close the game normally** to stop
and write one timestamped JSON file in the chosen D: folder. Save first using
normal controls if desired; recording does not save the game. Force-killing or
crashing loses the unflushed trace. Launch without the argument to leave it off.

The ring holds only the latest 7,200 intervals (~60s at 120fps, ~120s at 60fps),
so close soon after the incident. Memory is bounded for long sessions. There are
no timed disk writes, new key bindings, uploads or services. Files contain seed,
profile, coordinates, counters, timings and hardware/render settings, not save or
inventory payloads. Everything stays local. Startup/loads can be retained too;
the final row can be a partial stop interval.

Inspect one file locally:

```powershell
& './tools/wroughtwild-play03/read_trace.ps1' -Trace 'D:/.../play03-<timestamp>.json'
```

- `chunk_tick_ms` / `resource_tick_ms`: separate stream callback time.
- `ensure_area_ms`: synchronous completion, including calls not counted as refills.
- `resource_arrival_max_ms` / `resource_arrival_visual`: slowest construction in
  an interval, excluding the initial PackedScene load.
- `player_physics_ms` / `physics_callbacks_ms`: player and all observed physics
  callbacks. The latter does not isolate individual actors.
- `process_to_draw_ms` / `draw_wall_ms`: engine intervals, **not GPU execution time**.
  Engine monitors are sampled and nested timers overlap.
- `stage_before`: queued work, not proof it ran. Actor count updates at 1Hz.
  `surface_y` is a native reference, not a collision/support query.

## Checks, limits and delivery

- Headless import: exit 0, no reported errors, 36.49s.
- Completed Forward+ drop: **7 checks, zero failures**, 45.47s including setup.
  Real landing, four seconds afterward, active combat/packs, no additional edits,
  visible mouse and no-focus checks passed.
- Headless recorder use/lifecycle: **19 checks, zero failures**, exit 0, no reported
  errors, 33.10s. Normal world load, actual timing hooks, unchanged controls/native
  state at stop, no sampling writes, ring order/bound, idempotent stop and tree-exit
  flushing passed. An earlier test-only type-inference error was corrected; its
  failed log and terminated process result remain.
- Row collection peaked at 0.057ms in the small headless check. Hook overhead and
  post-stop JSON/disk work are excluded; rendered recorder overhead is unmeasured.
  The rendered transition predates the recorder hooks.
- Unchanged PLAY-01 paid-home Continue/save and adopted fauna evidence is reused.
  No paid save was copied or replayed. No broad regression, hardware clearance,
  renderer/seed matrix, baseline reconstruction or R9 work ran.
- The reported cause remains unknown. Disk write failure is reported; crashes
  cannot flush this in-memory recorder. There is no new gameplay tuning.

Raw traces, failed logs and private APPDATA/LOCALAPPDATA/TEMP are in the worker's
`build/play03/`. Compact evidence is in `tools/wroughtwild-play03/evidence/summary.json`.
All owned checks exited and the temporary no-focus override was removed.
Generated import outputs remain local and are excluded from the scoped commit.
Automatic approval review rejected restoring asset import sidecars because it
could overwrite pre-existing changes; they were left untouched after that rejection.

Optional reproduction from this worker (not new integration gates):

```powershell
& './tools/wroughtwild-play03/run_checks.ps1' -Job transition -Output 'D:/Wroughtwild/work/play03-underground/build/play03/new-transition'
& './tools/wroughtwild-play03/run_checks.ps1' -Job diagnostic -Output 'D:/Wroughtwild/work/play03-underground/build/play03/new-recorder-check'
```

The checked worker commit is returned on `codex/play03-underground`. Mainline
integration and ordinary push belong to the coordinator; this worker does not
merge or push. PLAY-03 remains open.
