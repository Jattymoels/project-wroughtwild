# MOB-04 beetle production and playable integration

The approved ART-06C ground beetle now appears on the normal Gloom Crawler. Its
six fitted leg chains use an alternating tripod walk, its supported antennae move
quietly, and its mandibles brace and bite on the existing native melee clock.
The shared CreatureMotion/FinishedFauna sampler remains the single driver.

See [result, checks and limits](../../docs/prototype/mob04-beetle-result-2026-09-15.md).
No generation, new animal, gameplay tuning or save field is introduced.

## Reproduce only when relevant

From this checkout, use the installed Blender 4.5.9 and existing Python runtime.
The builder requires a new source directory and retains the original dense host.
Stop after any failed command; do not capture an old export after a failed build.

```powershell
$beetleBlender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$beetlePython = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$env:APPDATA = 'D:/Wroughtwild/work/mob04-beetle/build/mob04/user'
$env:TEMP = 'D:/Wroughtwild/work/mob04-beetle/build/mob04/temp'
& $beetleBlender --background --threads 6 --python-exit-code 1 --python tools/wroughtwild-mob04-beetle/build_beetle.py -- D:/Wroughtwild/source-art/mob04-beetle/input-art06c D:/Wroughtwild/source-art/mob04-beetle/NEW_VERSION game/assets/authored/roster/gloom_crawler
& $beetlePython tools/wroughtwild-mob04-beetle/prepare_asset.py D:/Wroughtwild/source-art/mob04-beetle/NEW_VERSION game/assets/authored/roster/gloom_crawler
& $beetleBlender --background --python-exit-code 1 --python tools/wroughtwild-mob04-beetle/check_saved.py -- D:/Wroughtwild/source-art/mob04-beetle/NEW_VERSION build/mob04/source-checks.json
./tools/wroughtwild-mob04-beetle/run_checks.ps1 -Job import
./tools/wroughtwild-mob04-beetle/run_checks.ps1 -Job native -Capture
./tools/wroughtwild-mob04-beetle/run_checks.ps1 -Job restore
& $beetlePython tools/wroughtwild-mob04-beetle/encode_media.py build/mob04/integration game/tests/mob04/evidence
```

These are reproduction commands, not an instruction to restart the completed
checks. The runner uses private D: data, a nonblocking Local\WroughtwildArtRender
mutex, an owned temporary no-focus override and `--r8-no-mouse-capture`. The native
fixture asserts visible mouse/unfocusable window, uses scripted targets/cameras,
and captures 270 frames. It retains the mutex until process exit and removes its
own override in `finally`. Evidence has `.gdignore` and is never runtime input.

## Source and visual controls

`rig.json` explains the fitted joints, automatic 80,000-triangle target, stance
sink, 60% stance phase, .12-unit foot sweep, .065-unit lift, head/mandible angles
and subtle antenna motion. Tripods are fore-L / mid-R / hind-L and their opposite.
The shell and exposed lamellae share rigid body support; there are no wing flaps.
At most three normalized influences survive per vertex in the selected export.

The source faces +Y in Blender, exporting to native -Z in Godot. Uniform .72
metres per source unit preserves aspect ratio. Native swarm receives no .76
humanoid reduction. Family/elite scale on the parent is inherited once.

The actual foot sweep represents .2 source units/cycle, or .144 metres at .72.
A deliberate one-metre cosmetic cycle yields five quick insect cycles/second at
native 5 m/s and accepts sliding. It never drives movement or contact. The idle
and walk clips loop; windup follows the actor's normalized .25-second warning.
The release target of .22 seconds bakes to .225 at 40 Hz; its full span is sampled
inside CreatureMotion's existing .22-second visual window. Clips contain no
root motion or gameplay events. Descriptor material values preserve the ART-06C
base/ORM/scar maps, direct Godot colour (.26,.54,.62), damage tint (.16,.14,.12),
four-second connected pulse, 2.4 peak, .32 residual and .20 crest. No normal map.

The native fixture uses a deterministic repeated combat seed to compare the
actual randomised mitigated hit. A stationary physics step clears cached contact
after removing its cover fixture. Continue compares the complete drop snapshot
in the same JSON number representation; it never relaxes ownership equality.
