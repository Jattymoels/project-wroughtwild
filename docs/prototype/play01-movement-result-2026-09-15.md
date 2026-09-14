# PLAY-01 movement result and PLAY-03 underground follow-up

Walking now spreads stone-seam decoration over frames instead of stopping to
project a whole seam at once. On the same short physical walk, the worst frame
fell from 188 ms to 45 ms. Native collision, the resource ribbon, finite work,
approved final geometry and saved ownership are preserved.

**Limits:** this fixes a demonstrated source of repeated interruptions, not every
possible stall. The owner clarified during this worker that PLAY-03 concerns
**significant lag underground, not access underground**. That report remains
open. One current-code natural-cave sample did not reproduce sustained slowdown;
it is not the owner's incident location. Owner playtesting remains deferred.

## Established cause and change

Base: `4cec6073462afbaad425684945d7cb35e494e2d7`, prepared worker
`D:/Wroughtwild/work/play01-movement`, branch `codex/play01-movement`.

The first Forward+ sample caught 28 frames above 50 ms. The slow frames spent
roughly 150–176 ms in Terrain's callback while a stone seam materialised; the
terrain preparation phase itself took only a few milliseconds. More precise
arrival timing located 150–187 ms in B3 seam scene readiness. A tiny synthetic
projection probe separated array reads (about 1.6 ms), surface completion (about
1.5 ms) and the triangle loop (about 58 ms even with constant-time fake ground).
Real ground adds roughly 27,000 cached-coordinate surface queries per seam.
Tree construction was generally below 1 ms after its first load. No tree,
material, native terrain, player controller or rendering-quality change was made.

`b3/native_resource.gd` retains the original triangle tests and output order but
can yield within projection. `ResourceStream` gives those jobs the remainder of
its existing shared `resource_build_budget_ms` after native resource arrivals.
This is the same 2 ms soft work budget, not 2 ms per resource. There is no new
setting or saved field. Surface reads/completion remain indivisible; the final
small regression observed a largest slot of 4.302 ms.

The ordinary native ribbon and collider are installed immediately. The decorative
overlay stays hidden until all of its surfaces are ready. Terrain refresh replaces
unfinished work; retirement and restore cancel weak queued jobs. Initial resource
creation and explicit immediate focus/Continue complete the decoration synchronously.
No blanket player relocation, terrain repair or change to cave/digging rules exists.

**Presentation tradeoff:** decorative seams can arrive later than their native
ribbons while work is queued. The surface sample peaked at 20 pending overlays
and ended with four; the cave sample ended with 59. Dense arrivals can therefore
leave visible native ribbons for several seconds before their full decoration
appears. First-load asset creation can still exceed the soft budget. Initial
world/Continue loading and explicit area preparation remain synchronous.

## Checks actually performed

One Godot 4.5-stable Forward+ backend on the RTX 5090, 1280 × 720, 120 fps cap.
Rendered runs asserted visible mouse and `WINDOW_FLAG_NO_FOCUS`, using
`--r8-no-mouse-capture` and a disposable `display/window/size/no_focus=true`
override. Scripted movement used the real controller, collision, mobs and world
processing. No screenshots or per-frame disk writes occurred in timed windows.
All owned processes have exited, and `game/override.cfg` was removed.

The work stayed in three focused areas: causal diagnosis (with short attribution
extensions), seam regression, and Continue/use. The owner's later clarification
added one focused cave sample. No seed/renderer/material matrix, native rebuild,
full package copy, independent review or R9 work ran. Import through final trace
and fixture checks took about 25 minutes including analysis and harness corrections;
required reading and final documentation/Git work are additional.

### Physical surface route

Seed 1 V6, walk east from the normal spawn for 18 seconds. Both samples reached
the same position about 35 m east, where the unchanged controller meets an
obstacle. These are short representative samples, not minimum-hardware clearance.

| Sample | Frames | Median | p95 | Worst | Frames >50 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before | 1,588 | 8.689 ms | 11.477 ms | 187.906 ms | 28 |
| After | 2,152 | 8.211 ms | 9.570 ms | 44.993 ms | 0 |

No safety refill occurred on that surface route. The after sample retained
movement, mouse and no-focus checks. Its newly added support assertion initially
mistook native voxels for the rounded walking surface. Inspection showed grounded
capsules above the actual triangles. Corrected offline validation reused all
2,152 rows: minimum capsule-bottom clearance was +0.000110 m. The original failed
harness log is retained; the sample was not replayed to repair an assertion.
The future fixture checks triangle support and passed a headless script check.

### Exact decoration and lifecycle

`game/tests/play01_seam_regression.gd`: **11 checks, zero failures**. Its small
committed geometry digest comes from the original B3 projector at this worker's
base, on one synthetic sloped footprint with a hole. It checks initial and edited
vertices/normals/UVs/materials, native collision, partial work/stock, yielding,
complete publication, coalesced edit cancellation and retirement. The cut has an
explicit assertion that it changes the reference geometry.

Two harness issues were corrected without changing production geometry: JSON
numbers needed matching numeric types for the digest comparison, and the first
synthetic cut lay outside the narrow seam and needed a real overlapping cut.
The original projector generated the corrected reference before the staged check.

### Continue and paid ownership

`game/tests/play01_continue.tscn`: **19 checks, zero failures**. The normal Continue
handler loaded a private copy of the original R8 seed-77 LF paid-home starting
checkpoint. Actual capsule floor contact and movement passed. Native progression,
blocks, stations, contraptions, leylines, resource records and loose drops survived
a save/reload exactly. Immediate focus finished its queued overlays.

The sole copied source was the 6.5 MB checkpoint at
`C:/Users/Matty/Dev/project-wroughtwild/build/art-playtest/runtime/game/g1/paid-home.json`.
Its D: copy and provenance are under `build/play01/`. The owner's missing
`user/ART07G1/g1-play.json`, original preview, logs and other saves were untouched.
Unchanged A1/A2 art/actor evidence is reused. The separately logged historical
chest-panel signal-lifetime issue remains outside this slice.

### Underground lag: still open

After the owner corrected the report, the fixture selected a clear capsule position
on a generated seed-1 cave floor at approximately `(495.5, 25.01, 361.5)`, with
the surface overhead at Y=31. It sampled four seconds standing and eight seconds
walking/falling naturally between cave levels. The final Y was 2.21. Native
collision, mobs and streaming stayed enabled; this was synthetic diagnostic
placement, not a game feature or the owner's precise route.

| Cave window | Frames | Median | p95 | Worst |
| --- | ---: | ---: | ---: | ---: |
| Standing | 478 | 8.170 ms | 10.337 ms | 13.528 ms |
| Walking / dropping | 961 | 8.198 ms | 9.826 ms | 18.899 ms |

This current-code sample does not establish a before/after underground improvement.
Initial area preparation and warmup were outside these timed windows; the session
recorded one safety refill. Entry pauses, other locations, denser activity and the
owner's sustained underground slowdown remain unconfirmed. The next useful evidence
is whether the slowdown persists while stationary and a cave/dug-area location or
save from the affected play session. Do not reinterpret that as an access defect.

The surface-only support assertion was inappropriate while falling between cave
floors. Its original failure remains recorded. Missing support also revealed
non-JSON infinity in diagnostic output: the readable copy maps only those heights
to null and retains the raw original. The future fixture now writes null directly
and verifies its underground starting condition rather than demanding continuous
floor support. Collected timings were reused, not rerun for a clean exit code.

## Local evidence and rerun commands

Private logs, the raw/validated traces, original-projector copy and checkpoint:
`D:/Wroughtwild/work/play01-movement/build/play01/`. They are not committed en masse.
Godot import caches/sidecars remain local. The committed test scripts and tiny
reference digest contain no owner save data.

From the worker, with APPDATA and LOCALAPPDATA set to private D: directories:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --headless --path game --script res://tests/play01_seam_regression.gd
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --headless --path game res://tests/play01_continue.tscn
```

Continue uses `build/play01/paid-home-original.json`, or an explicit private
`--play01-checkpoint=...` argument. The optional movement fixture is
`res://tests/play01_movement_review.tscn`; add `--play01-underground` for the cave.
Rendered sampling requires both the temporary no-focus override and mouse opt-out;
remove the override afterward. Its `--review-output=...` selects a private folder.
No additional run is required for ordinary coordinator integration of unchanged inputs.

## Integration and ordinary play

This is a checked worker delivery for main integration. The exact worker commit
is returned with the handoff. No main integration or remote push was performed by
this worker. The coordinator can cherry-pick that commit and reuse these checks.

After integration, launch the normal game:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

Use Continue or start a normal world; no PLAY01 flag is needed. Walk through a
resource-rich area, then try the cave/dug location that previously became slow.
Save and Continue normally. Existing LF campaigns keep their usual
`--living-frontier-wave7` launch option. PLAY-03 remains the underground-lag
follow-up; canopy completeness and the six approved rigs remain the next art work.
