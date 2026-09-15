# PLAY-03 presentation hitch result — 15 September 2026

The selected first boar arrival is resolved in the measured route: its frame
interval fell from **324.760 ms to 7.529 ms**, with the next interval including
first draw at **10.530 ms**. The complete mob still appears at the normal activation
boundary. Shared resource loading now happens during normal world entry before
controls release, adding **892.999 ms** of preparation to the measured New World
entry. This closes the selected presentation freeze, not all reported game lag.

## Cause and correction

The new breakdown measured 306.320 ms inside presentation setup: 297.746 ms in
texture/material acquisition, 8.084 ms acquiring the model, and only 0.089 ms
instantiating it. Registration, bounds/rig fitting, material assignment and initial
animation seek each took less than 0.2 ms. These are nested CPU wall spans, not
separate additive frame costs or evidence of a GPU/shader compilation bottleneck.

`FinishedFauna.prepare_world()` now prepares the existing boar, wolf and stag
shared scenes, exact material templates/textures, and existing fallback meshes.
The real `Sandpit._build_world()` calls it during both normal New World and a
validated fresh-process Continue, while `WorldSeedControls` holds player input.
No actor/model instance is prepared, no dormant pack activates, and no work is
hidden in the fixture's 90-frame settling period. Actor setup still instantiates
and fits the same approved model, duplicates its own material and attaches its
existing animation/status behavior. Standalone actors retain lazy loading.

Preparation uses the existing family definitions and process-lifetime caches.
There are no new tuning values, asset substitutions, spawn/scheduling changes,
count/range changes, gameplay rules, save fields or native changes. The first
slice's hidden legacy mesh improvement remains intact. The six newer replacement
presentation pipelines are unchanged.

## Focused timing evidence

One selected V8 seed-77 pack, index 176: one `ember_whelp` using finished boar at
(338.5, 39, 598.5). Both captures start at the same disclosed pose, 35.146 m away,
then use normal walking with all world/streaming systems active. Activation was
at 27.368 m before and 27.766 m after, inside the unchanged 28 m boundary.
Member count, ID, life, fitted bounds, scale and model position match exactly.

| Observation (ms) | Breakdown before | After preparation |
| --- | ---: | ---: |
| Moving approach median / p95 / worst | 8.933 / 16.383 / 19.976 | 8.688 / 15.577 / 18.536 |
| Arrival interval | 324.760 | 7.529 |
| Pack construction | 313.476 | 0.793 |
| Enemy.configure | 313.075 | 0.577 |
| Presentation setup | 306.320 | 0.326 |
| Model acquisition | 8.084 | 0.006 |
| Texture/material acquisition | 297.746 | 0.003 |
| Next interval including first draw | 14.100 | 10.530 |
| Recovery median / p95 / worst | 8.758 / 15.927 / 20.781 | 8.921 / 15.216 / 19.536 |

Approach includes 169/163 frames; recovery includes 234/231 complete frames over
roughly 2.2 seconds. The after worst approach/recovery intervals include 10.800 /
11.960 ms of chunk work; no resource preparation occurs while walking. First-draw
pre/post wall time is 3.591 ms after; it is not a GPU execution timer.

The direct preparation transfer is 892.999 ms before New World control release:
boar model/material/fallback 9.891/298.837/4.248 ms, wolf 6.899/263.934/3.940 ms,
stag 6.879/291.327/6.198 ms. Boar texture loads account for 87.294 ms base,
74.657 ms ORM, 98.109 ms normal and 36.350 ms scar. Fresh-process Continue spends
924.298 ms in the same preparation, also before control release; a repeated call
reuses the same resources in 0.056 ms.

Total setup was 41.126 seconds in the old direct-build diagnostic fixture and
40.110 seconds through the after fixture's real New World entry. Continue with
the private RF-05 saved-world fixture took 65.849 seconds. These different entry
paths and single samples do not establish an improvement in total loading time;
the added preparation cost above is measured directly.

### Startup and fixture stalls retained explicitly

The fixture relocates the player about 150 m from ordinary New World spawn to the
outside-pack starting pose. That synthetic relocation interval remains **591.310
ms before / 518.024 ms after**, including **339.858 ms** after in synchronous
`ensure_area` streaming. The following settling worst is **70.514 / 67.188 ms**;
the latter includes 58.650 ms of resource streaming. These stalls are retained,
not counted as smooth frames or attributed to the fixed mob presentation path.
They occur before the scripted walk. The concrete separate remedy, if this is
pursued, is to prepare destination terrain/resources before releasing a relocated
player; no teleport/streaming rewrite belongs to this slice.

The before recorder's startup interval dropped 91 detailed arrival events at its
bounded event limit, including the fixture-position marker. Its report fixes the
starting pose and the following relocation interval is retained; the selected
boar arrival breakdown is intact. The after preparation and route are captured.
Full trace paths and selected rows are in the committed
[evidence summary](../../tools/wroughtwild-play03-presentation/evidence/summary.json).
The raw traces/reports/logs remain in `build/play03-presentation/` on this worker.

Measurements used Godot 4.5 stable, Forward+, Ryzen 9 9950X3D, RTX 5090,
1280x720, 120 fps cap and VSync off. No OS/driver-cache purge was performed; this
is first use in a fresh process, not an OS-cold or hardware-wide guarantee.
No screenshots or per-frame disk writes ran inside capture. Observer overhead
and other instrumentation limitations remain recorded in the trace metadata.

## Checks and remaining issues

Three focused jobs addressed the actual risks:

1. Detailed selected arrival breakdown: **11/11** checks passed, exit 0.
2. Corrected route through real New World: **12/12** passed, exit 0; preparation
   before control release, dormant pack until crossing range, complete unchanged
   member/fit, active world/streaming and retained mouse/no-focus flags.
3. Headless fresh-process Continue/resource lifecycle: **22/22** passed, exit 0;
   exact saved native state, paid blocks/stations, loose-drop/death-pack ownership,
   loot counter, V8 lake and pose; no preparation-created actors; idempotent caches;
   independent ordinary/LF materials, LF channel color, isolated status, visible
   full models, single animation listener and unchanged native state on teardown.

One earlier lifecycle attempt failed in the new fixture: live integer arrays
were compared with parsed JSON number arrays, and an unset shader parameter was
converted to Boolean. The fixture now uses RF-05's existing full-precision JSON
normalization and checks the unset template default directly. Its release-listener
expectation was corrected to the existing one-per-actor contract. The same focused
case was rerun successfully; failed logs remain. No gameplay assertion was removed
and production code did not change for that rerun.

Reuse the first slice's 39 lifecycle/fit/death/sleep checks and the retained RF-05
lake/legacy-save evidence for unchanged paths. No broad regression, renderer
matrix, native rebuild or new package was run. Launchers passed PowerShell syntax
checks; the owner-facing launcher was not automatically run. All owned Godot jobs
have exited, the temporary no-focus override is removed, and the mouse was never
controlled or captured.

The earlier unexplained **114.660 ms non-arrival event**, the original underground
lag/correlation, other mob families, and broader gameplay performance remain open.
Owner playtesting is deferred. Earlier resource residency and other hardware are
unmeasured. Normal world-entry loading remains long as reported above. None of
these limitations changes the measured selected arrival result.

## Simple optional owner playtest

Run this yourself; it launches the normal playable game with a private save slot:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/play03-mob-arrival/tools/wroughtwild-play03-presentation/play.ps1" -Trace
```

Choose **Continue saved world / suspended trial** in the actual HUD. On first use,
the saved camera faces the selected pack: keep that direction and hold **W** for
about two seconds. The mouse stays free. The initial pose is explicitly staged
outside activation; there is no coordinate/compass HUD requirement. F5 saves to
this private playtest slot and subsequent launches preserve that progress.

The retained `build/play03-presentation/arrival-start.json` comes from
`D:/Wroughtwild/work/rf05-lakes-swimming/build/rf05/private-world.json`; only initial
player position/yaw/pitch were changed. The launcher copies it once under
`build/play03-presentation/playtest/user/Godot/app_userdata/Wroughtwild/` and
isolates user/local/temp files on D:. It does not read or overwrite the owner's
save and does not change persistent PowerShell policy. This local save fixture
must accompany the launcher if used outside this retained worker; it is not a
committed build artifact.

## Coordinator integration / native status

This continuation follows worker `de0125f2062d9cd628b44bd23e76094676336d11`, already
adopted on main as `87849bda32be28c0d52751979d8bebfba794354c`. Commit only the new
continuation from `codex/play03-mob-arrival`; its exact SHA is supplied in the final
handoff. No merge or push is performed by this worker.

The inherited ignored RF-05 DLL is unchanged and was not rebuilt:
`game/bin/libwroughtwild_sim.windows.x86_64.dll`, SHA256
`fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b`
(rechecked at handoff). Coordinator should keep that compatible native binary.
Generated import sidecars/caches and unrelated untracked artifacts are excluded
from the commit and left in place. No owner-depot source was edited.

## Coordinator adoption and owner response

Worker `039bccf49e6c99c1d40ec78102ccf6cc31efcc0e` is adopted on main as
`1bc19e90a17600dc9556a2cf38d291c0b9027518`. The coordinator reused the worker's
focused evidence and ran one hidden headless import: 4.68 seconds, exit 0,
zero reported errors. The RF-05 DLL remains in place with the matching hash.
No comparison matrix, additional game run or native rebuild was performed;
the import has exited.

The owner says the result "seems to be a massive improvement" and asks why such
an established technique was not the default. This is recorded as positive
feedback, not proof that every family or underground scenario was playtested.
The original integration left first-use synchronous resource loads in the spawn
path. Godot already provides resource caching and background loading facilities;
the game must choose when its resources are prepared. This slice uses synchronous
preparation during world entry, not background streaming. Current AGENTS.md now
requires a proportionate loading/reuse decision during heavier asset integration
and first-use coverage within its existing short smoke when that path changes.
This does not create a benchmark/adoption gate or reopen historical art reviews.

For the same selected check, use the retained D: launcher above. For ordinary
mainline play, launch the command below and choose New World or your usual Continue:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

Encounter a newly activated boar, wolf or stag during ordinary travel. Only the
boar route was timed; the resource preparation covers all three fitted families.
This ordinary main launch uses the normal save slot. Long entry and separate lag
observations remain as documented above.
