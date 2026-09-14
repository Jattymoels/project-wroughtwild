# ART-07R4 â€” fixture shutdown cleanup

G2-T01 has a fixture-only candidate repair. All eight unchanged original cases
reproduced AudioStreamWAV / AudioStreamPlaybackWAV shutdown leaks. Exact-ID
observer runs attribute them to action-sound players below the completed fixture.
All 22 repaired native runs, including fresh-process partial/final/depleted
restores, pass the unchanged assertions and finish without ObjectDB, leaked
instance, orphan StringName, warning or fatal-error diagnostics.

Owner visual acceptance remains pending. Ordinary-world rollout is outside scope.

## Evidence

Counts below show a selected fresh unchanged baseline, followed by its repaired
flow. Leaks are intermittent; every repeat, including clean baseline runs, is
retained. The exact-ID attribution column refers to a separate observed run of
the same unchanged fixture, not cross-process ID matching.

| Fixture | Before WAV / playback | After WAV / playback | Trace IDs matched |
|---|---:|---:|---:|
| B3 | 7 / 20 | 0 / 0 | 14 / 14 |
| C1 | 11 / 18 | 0 / 0 | 16 / 16 |
| C2 | 7 / 24 | 0 / 0 | 15 / 15 |
| C3 | 8 / 14 | 0 / 0 | 22 / 22 |
| C4 | 5 / 9 | 0 / 0 | 14 / 14 |
| E1 | 2 / 2 | 0 / 0 | 4 / 4 |
| F2 | 5 / 5 | 0 / 0 | 10 / 10 |
| F3 | 9 / 9 | 0 / 0 | 16 / 16 |

See checks.json for exact log paths/hashes, native assertion markers, process
IDs, private state locations and the complete restart matrix. Full verbose
stdout/stderr, runner metadata, JSON saves and ID-to-cue/owner records are sealed.
No assertion or diagnostic was removed or whitelisted. The three verbose render
logs retain NVAPI's application-profile message
`NVAPI_EXECUTABLE_ALREADY_IN_USE(code -167)`; it is separate from ObjectDB
shutdown and native assertion results. The prepared Compatibility smoke retains
its SSAO/Forward+ feature warning. These diagnostics were not suppressed or
classified as expected invalid input. The affected matrix
produces no expected invalid-input warning. G2's separate invalid-input and
save-recovery warnings remain in the preserved original report; they are not
cleanup successes.

## Repeated lifecycle

Twelve cycles use the original B3 native presentation adapter and Wroughtwild
work/SaveManager path: create a player and finite boulder, work to partial stock,
write/read and compare identity/work/ownership, deplete once, collect exactly nine
units, write/read exhausted state, then dispose that cycle's descendants.

Both reference and repaired exercises pass 156 checks. Reference exercise:
5.213219 seconds, 7
observed playback references still alive at its last release measurement.
Repaired exercise: 7.024718 seconds, zero observed playback
references after each disposal. Expired weak observers are removed before the
object sample. Shared PCM clips remain cached and usable by the next cycle.

| Cycle | Objects after release | Resources | Nodes | Orphans | Observed playback alive |
|---:|---:|---:|---:|---:|---:|
| 1 | 1811 | 240 | 4 | 0 | 0 |
| 2 | 1811 | 240 | 4 | 0 | 0 |
| 3 | 1811 | 240 | 4 | 0 | 0 |
| 4 | 1811 | 240 | 4 | 0 | 0 |
| 5 | 1811 | 240 | 4 | 0 | 0 |
| 6 | 1811 | 240 | 4 | 0 | 0 |
| 7 | 1811 | 240 | 4 | 0 | 0 |
| 8 | 1811 | 240 | 4 | 0 | 0 |
| 9 | 1811 | 240 | 4 | 0 | 0 |
| 10 | 1811 | 240 | 4 | 0 | 0 |
| 11 | 1811 | 240 | 4 | 0 | 0 |
| 12 | 1811 | 240 | 4 | 0 | 0 |

checks.json records counts before player/resource creation (with the empty cycle
scope already added), before disposal and after release in both exercises,
including static-byte samples. Counts are Godot Performance/ObjectDB monitors,
not process RSS. Both reference and repaired release counts are stable over these
12 cycles. The reference count includes seven live WeakRef observer objects in
addition to the seven still-observed playbacks, so the 14-object difference must
not be described as 14 leaked runtime objects. The reference also exits without
an ObjectDB warning in this run: a pending playback at a sample is not proof of
permanent growth. Static memory includes the
intentionally retained measurement dictionaries and shared caches. These short,
accelerated samples do not establish a long-session, process-RSS, VRAM or
minimum-hardware memory bound.

## Patch and cost

Only finish in B3/C1/C2/C3/C4/F3, finish_e1 in E1 and _done in F2 change. They
release completed fixture descendants, wait for observable audio retirement,
then allow the completion coroutine to unwind before normal deferred quit.
fixture_cleanup.gd and cleanup_options.gd are shared by these test fixtures.
There is **no reusable runtime patch**: InteractionSound, its PCM palette/cache,
native simulation, resource adapters, ordinary game, data and save code remain unchanged.
Source checks prove that every original assertion and every byte outside the
eight finish functions is identical. After engine verification, the two helper
masters had one terminal blank line removed for the staged whitespace check.
Their executable bytes are identical to evidence/diagnostic-source/ after
trimming terminal CR/LF; no extra engine run is claimed for this formatting-only
change. evidence/final-formatting.json retains the earlier hashes and seal.

Teardown elapsed time across 22 headless native jobs: minimum
0.097903 s, median 0.138003 s, maximum
0.185310 s. These are diagnostic teardown timings, not frame benchmarks.
Automatic fixture completion is the measured path; manual Escape exits and
ordinary-game shutdown are unchanged and outside this evidence.
Native tests use the pinned Godot 4.5 engine, headless, fixed 60 FPS; the 12-cycle
exercise has the same settings. The machine is Ryzen 9 9950X3D (16 cores / 32
threads), 33,446,744,064 bytes RAM, Windows 11 Home 26200. Render evidence uses
Compatibility, RTX 5090, 1280Ã—720, fixed 60 FPS. Actual settings/device and all
wrapper durations are in hardware.json and the engine logs. No benchmark was
mixed with import, generation or capture.

## Controls and limits

No player-facing tuning changed. Fixture controls are three pre-disposal frames for queued two-frame UI layout callbacks; two observed mixer
progress events after stop; two main-thread frames for deferred deletion;
one millisecond CPU yield per poll; a two-second failure deadline; twelve
lifecycle cycles. The fixed exercise seed is 7704. Its nine stock units,
three-unit harvest, three drive presses and four initial work calls establish
six units plus one partial press after the first three-unit release. Eight
setup physics frames initialize the native fixture; 48 settle frames allow its
existing depletion animation to finish. Two release frames sample deferred
cleanup. The Warden class and posed player position (0, 1.1, 5) are test inputs,
not a movement or balance change. All values and purposes are retained in the
owned source.

Fresh C3 captures include 42 native fall frames and full/partial/depletion/
aftermath images. They are the existing original models and LOD selection, with
posed native work; no mesh, map, body or animation asset changed. No Blender
generation/reopen was needed. This is not human playtime or owner art acceptance.
All 273 legal pairs and native rules are preserved by unchanged game/data/DLL
hashes; no new shape, recipe, scatter, geography, rig or ordinary rollout occurs.

## R8 application

changes.json names exactly ten fixture-only baseline-relative files and hashes.
No peer repair was consumed. R8 must merge these finish-function changes if
another repair touches the same review file; a hash mismatch is an overlap,
not permission for last-file-wins copying. Shared runtime source edits from R2
are outside this delta. The guarded apply command rejects a changed before-hash.

The original runtime source, G2 review and eight source packages were fully
rehashed before consumption and after repair. 1385 normal
game/sim/data/save files were preserved with no added, missing or changed file.
The pinned runtime is 6bb2e044dcd0bf1788896aa2c19cdf56fee93522, regardless of the
newer documentation checkout. All engine processes used the unchanged shared
runner, one GPU mutex, existing-process checks and private APPDATA/local/temp/
Blender paths. Busy jobs were deferred without interruption.

See the receipt for package identity and commit SHAs. The worker does not push
main or update the shared delivery index.
