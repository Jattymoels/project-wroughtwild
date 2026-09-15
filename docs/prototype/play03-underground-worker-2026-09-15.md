# PLAY-03 — diagnose significant underground lag

Work in `D:/Wroughtwild/work/play03-underground`, branch
`codex/play03-underground`. Read `build/play03/SETUP.md` for the actual main base
and unchanged native DLL. Use this checkout even if the task opens at the C:
owner depot. The owner starts this worker; do not launch other tasks or reviewers.

## Outcome

Investigate the owner's significant underground slowdown and deliver a small
causal correction if reproduced. If it remains elusive, finish a lightweight,
opt-in local capture that can explain the next real incident, with exact usage
and honest remaining uncertainty. Do not invent a fix or call a clean route proof
that the reported issue is solved. This is a focused bug slice, not performance
clearance for the newly integrated art.

The owner clarified that underground access is not the defect. Preserve legitimate
caves/digging and ordinary terrain collision. No blanket teleport, access barrier,
automatic terrain repair or removal of approved art. Current main includes A1/A2,
PLAY-01/02 and all six base replacement mobs; preserve them and existing saves,
campaign progression, ownership, generation profiles and octagonal buildings.

After the tortoise handoff the owner approved its visuals and asked for the next
slice. Standing approval covers scoped implementation, checked integration and
ordinary publication. The coordinator owns mainline integration and push. There
is no hard ten-minute cutoff, new art approval or benchmark gate. R9 stays stopped.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, reusing unchanged prior reading. Then read:

- `docs/prototype/play01-movement-result-2026-09-15.md`, especially the established
  stone-seam cause and the distinct still-open cave finding;
- `docs/prototype/art-mainline-adoption-2026-09-14.md` for the original report;
- relevant current movement, excavation, streaming and save/collision sections
  of `docs/systems/world-generation.md` and the accepted decisions it references;
- relevant existing profiler/terrain/player/resource code below. Read only a
  linked historical performance report that helps explain a concrete observation.

Historical R9 prerequisites and old hardware/renderer review programmes are not
instructions to repeat. The six-mob rig/adoption batch is complete.

## Known evidence and the missing window

PLAY-01 fixed synchronous stone-seam decoration and published `d396d9e`.
One physical surface route's worst frame fell from 188 to 45 ms. Native ribbons,
collision, final decoration and ownership were preserved; decorative overlays
can arrive later under the existing shared soft budget. Do not redo that review
or claim every movement stall was solved.

The old cave sample used seed 1 / `frontier_v6`, a synthetically selected clear
floor near `(495.5, 25.01, 361.5)` with surface Y about 31. It prepared the area
synchronously and warmed up before timing four seconds standing and eight seconds
walking/falling. Timed worst frames were about 13.5/18.9 ms. One safety refill
was recorded outside or across the wider session. It was not the owner's precise
location and did not reproduce sustained lag.

The owner subsequently clarified the remembered onset: lag began as soon as they
went underground or fell into a hole. It felt as though something needed to load,
and felt different from the stuttering above ground. This is a report of onset
and character, not evidence that loading is the cause or that the slowdown was
brief. Active digging was not identified as necessary to trigger it.

**Do not merely repeat that prewarmed clean window.** First inspect the missing
transition from above ground into a cave or hole, including relevant synchronous
preparation/publication, then continue through landing and a stationary period.
Begin timing before the entry/drop so its first stalled frames are retained.
Choose one code-guided scenario and one seed/checkpoint. Keep setup costs
and ordinary play costs clearly labelled; never silently exclude the suspected
event as warmup. Synthetic staging is allowed but must be labelled, with a clear
distinction between fixture-only preparation and an actual production call path.

The owner's exact incident seed/location/save, duration and whether lag persisted
while stationary remain unknown. Retain the transition and subsequent stationary
phase in the single trace so an entry burst can be distinguished from continuing
work. Do not wait for unavailable owner playtesting or assume the surface
stone-seam cause explains this distinct report.

Useful existing implementation:

- `game/tests/play01_movement_review.gd` and `.tscn` show the prior cave selection
  and timing gap; `play01_profile_player.gd` times unchanged controller/step work.
- `game/tests/travel_performance_review.gd` and `travel_profile_terrain.gd` have
  frame/process/physics/render observations, chunk stages, pending work, retirement
  and safety-refill counters. Reuse the small useful pieces, not their full runner.
- `game/scripts/terrain.gd`, `resource_stream.gd`, player movement/excavation and
  relevant chunk-stream code remain the production authority. Follow an observed
  cost into actor, renderer or UI work only if the trace points there.
- Prior diagnostic logs/traces are retained at
  `D:/Wroughtwild/work/play01-movement/build/play01/`. Reuse them in place.
- The original R8 starting checkpoint remains at
  `C:/Users/Matty/Dev/project-wroughtwild/build/art-playtest/runtime/game/g1/paid-home.json`.
  It is a starting checkpoint, not the owner's incident save. Only if relevant,
  copy that single file to private D: data and note provenance. Never import the
  preview's frozen game, rebuild its package or overwrite any owner save.

## Small implementation and three focused job groups

Before running anything, name the concrete risk and initial hypotheses. Don't
assume the new fauna, terrain, GPU, streaming, collision or world depth is guilty.
Use bounded in-memory timestamps/counters, flush after sampling, and keep costly
support queries, per-frame disk writes and screenshots out of timed windows.
Average FPS alone is insufficient; retain frame spikes, location/phase and the
relevant subsystem event. Engine render wait is not automatically GPU execution
time. Identify attribution limits and any meaningful observer overhead.

1. **One focused diagnostic.** Inspect the relevant path, then use one short
   current-main scenario covering the transition and settled state. Keep native
   collision, normal world work and actor behavior active. No route/seed/renderer
   matrix, repeated benchmark, long soak or package baseline reconstruction.
2. **One cause-specific correction/check.** If a responsible cost or scheduling
   fault is demonstrated, make the smallest complete fix and verify that event
   plus its behavior contract. A before/after observation of this same event is
   useful evidence, not permission to expand into a general benchmark programme.
   If nothing slow is reproduced, don't keep sampling random caves. Instead make
   a small opt-in bounded local diagnostic for an actual future play session.
   Keep it off by default, preserve normal controls, report its overhead/limits
   and provide one clear start/stop or launch procedure. Do not build a telemetry
   framework, add a service, record unbounded logs or upload private player data.
3. **One directly relevant use/Continue check.** If runtime scheduling/collision
   changes, check affected support/edits and paid ownership through ordinary load.
   If only a diagnostic is added, check activation/deactivation and safe exit;
   reuse existing unchanged save and fauna evidence instead of replaying it all.

Preserve existing assertions and failed logs. Fix a harness issue without rerunning
unaffected evidence just to obtain a clean report. Stop when this bounded delivery
has enough evidence; further uncertainty can remain documented. No unsupported
performance claim, reduced content/visual quality, new scheduling framework,
native rewrite or broad refactor. Native builds are needed only if the scoped
change actually touches the native library.

Use headless checks where rendering is not required. The one rendered backend is
Forward+. Use the corrected MOB-06 runner patterns: nonblocking
`Local\WroughtwildArtRender` held until the owned process exits, BOM-free UTF-8
no-focus override, verified `--r8-no-mouse-capture`, visible mouse and an asserted
unfocusable window. Keep presentation/timing settings recorded; don't quietly
throttle a measurement. Script camera/input, never the owner's desktop pointer.
Use private D: APPDATA/TEMP/saves and logs. Remove owned overrides and end every
owned process at handoff; preserve active peer jobs and remote-access tooling.

## Handoff

Own `tools/wroughtwild-play03/`, scoped test/diagnostic files under `game/tests/`,
the narrowly needed production edits and
`docs/prototype/play03-underground-result-2026-09-15.md`. Keep large raw traces,
private checkpoints and temporary data on D:. Commit compact evidence and exact
reproduction instructions without owner save contents. Leave aggregate queue
updates and mainline publication to the coordinator.

Commit on `codex/play03-underground` and return the exact SHA. Lead with what
changes for the player, or exactly what the new diagnostic will let us discover.
Then report cause established versus still unknown, checks actually run, tuning
purpose if any, known limits and commit/push status. Include normal-game launch
steps and precise diagnostic instructions if delivered. Owner saves, ordinary
Continue/campaign flow and approved art remain intact. A diagnostic-only delivery
leaves PLAY-03 open; do not mark the lag fixed without supporting evidence.

Station/home usability and campaign feedback remain the next playtest questions.
Later-era forms, bosses and Reclaimed Frontier landscape direction stay separate;
do not start them or another review wave during this slice.
