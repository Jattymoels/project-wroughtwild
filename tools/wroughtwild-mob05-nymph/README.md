# MOB-05 nymph production and playable integration

The approved six-legged ART-06C v04 dragonfly nymph now appears on the ordinary
Bog Lurker. Six fitted three-bone legs carry an overlapping tripod walk; three
abdominal supports keep the legless segmented layers together. The existing
head and compact labium brace and release on native melee timing. Two antennae
move quietly. CreatureMotion/FinishedFauna remains the single animation driver.

See [result, checks, normal launch and limits](../../docs/prototype/mob05-nymph-result-2026-09-15.md).
No new animal, game rule, gameplay tuning or save field is introduced.

## Reproduce only when relevant

Use a new source version; never overwrite the immutable ART-06C input. The
builder retains its dense host and original packed maps beside the runtime rig.
Stop after a failed build; do not test an older export as if the build passed.

```powershell
$nymphBlender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$nymphPython = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$env:APPDATA = 'D:/Wroughtwild/work/mob05-nymph/build/mob05/user'
$env:TEMP = 'D:/Wroughtwild/work/mob05-nymph/build/mob05/temp'
& $nymphBlender --background --threads 6 --python-exit-code 1 --python tools/wroughtwild-mob05-nymph/build_nymph.py -- D:/Wroughtwild/source-art/mob05-nymph/input-art06c D:/Wroughtwild/source-art/mob05-nymph/NEW_VERSION game/assets/authored/roster/bog_lurker
& $nymphPython tools/wroughtwild-mob05-nymph/prepare_asset.py D:/Wroughtwild/source-art/mob05-nymph/NEW_VERSION game/assets/authored/roster/bog_lurker
& $nymphBlender --background --threads 6 --python-exit-code 1 --python tools/wroughtwild-mob05-nymph/check_saved.py -- D:/Wroughtwild/source-art/mob05-nymph/NEW_VERSION build/mob05/source-checks.json
./tools/wroughtwild-mob05-nymph/run_checks.ps1 -Job import
./tools/wroughtwild-mob05-nymph/run_checks.ps1 -Job native -Capture
./tools/wroughtwild-mob05-nymph/run_checks.ps1 -Job restore
& $nymphPython tools/wroughtwild-mob05-nymph/encode_media.py build/mob05/integration game/tests/mob05/evidence
```

These are reproduction commands, not a request to rerun passed evidence. The
runner uses private D: APPDATA/TEMP, an owned no-focus override, the nonblocking
`Local\WroughtwildArtRender` mutex and `--r8-no-mouse-capture`. The native fixture
asserts visible cursor and unfocusable window before scripted camera/target
capture. `finally` ends its process, releases the mutex and removes its override.
Selected evidence has `.gdignore` and is not runtime input.

## Source fit and visual controls

[rig.json](rig.json) documents all controls and their purposes. The nymph faces
-Y in Blender, exporting to +Z in Godot. A 180-degree yaw aligns its head with
native -Z. Uniform .82 metres/source unit preserves the animal's proportions;
the parent's existing 1.4 family size and optional 1.3 elite scale apply once.
There is no .76 humanoid reduction or compensating scale.

The 80,000-triangle automatic collapse target yielded 79,995 triangles after
validation removed five duplicate faces; this is not manual retopology. The
290,654-triangle source remains intact. There are 27 bones, one skin surface,
and at most three normalized weights. Abdominal vertices never use leg weights.

A .016-unit body lift clears the low underside. The planted solver uses measured
foot minima, .10-unit sweep, .05-unit lift and 65 percent stance; opposite
tripods overlap on the ground. .002-unit idle breathing and .006-radian abdominal
flex keep the heavy animal restrained. These are local flat-floor targets,
without terrain IK. The actual source travel is .153846 units/cycle. A deliberate
.9-metre cosmetic cycle gives about 1.43 cycles/sec at native 1.8m/s and family
1.4, accepting sliding instead of changing movement.

Head angles are -.11-radian anticipation and .13-radian follow-through. The
folded labium tucks -.10 radians, opens briefly .24 radians and extends only
.045 source units. This is a short visual release with no tether, hurtbox or
root application. Antennae sweep .04 radians. Idle/walk clips are 4/1.2 seconds;
windup's .9-second authored span follows the native normalized clock. The .22
release target bakes to .225 seconds at 40Hz; the complete span is sampled into
CreatureMotion's existing .22-second cosmetic window. There is no root motion.

The original base/ORM/scar PNGs are copied byte-for-byte. The existing ART-06C
shader/status adapter retains source colour (.33,.65,.18), damage tint
(.16,.14,.12), four-second connected pulse, 2.4 peak, .32 residual and .20 crest.
Native status tint takes priority. No normal bake or new shader is introduced.

The Continue fixture serializes both sides with SaveManager's full precision;
default JSON stringify rounds nonempty drop values and cannot establish exact
equality. Every ownership field and spatial/clock value remains compared.
