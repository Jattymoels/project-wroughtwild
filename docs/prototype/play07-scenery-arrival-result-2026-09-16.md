# PLAY-07: scenery arrival result - 16 September 2026

The measured pullstone loading freeze is removed from ordinary arrival. Its
creation fell from **154.202 to 2.174 ms** in the scoped diagnostic, and the whole
arrival interval fell from **178.281 to 8.656 ms**. The earlier retained group
trace measured 99.276 / 106.840 ms; it established the issue but is not substituted
for this instrumented before capture. All five rare-source families and their
shared F1/F2/F3 fixture helpers now retain their resources through real loading.
Approved geometry, materials, finite ownership, saves, lakes and creature fixes
remain. Owner playtesting is deferred; this is not a claim of hitch-free play.

## Limits that remain

- Thrumroot construction is **8.790 ms first / 4.238 ms repeated**, above the
  existing 2 ms soft node budget. The hundreds-of-milliseconds shared loading
  omission is fixed; its legacy backing and per-node construction remain.
- The unchanged complete 30-mob group creates in **13.720 ms**; its full frame is
  **34.621 ms**, still above 16.7 ms. Prior creature evidence (13.050 / 40.869 ms)
  remains applicable; this slice changes neither encounters nor their scheduler.
- Actual New World entry remains long: 39.582 seconds before / 48.115 seconds
  after. Preparation accounts for 0.934 seconds of the final entry. These single
  runs do not isolate unrelated entry variability or establish a total-load trend.
- Other hardware, other scenery pipelines, sustained play and the old underground
  correlation remain unmeasured. Navigation, fen/lakeside atmosphere and highland
  work were not started. No lower quality, counts or visibility ranges were used.

## Demonstrated cause and correction

The fresh-process Forward+ trace separates scene acquisition, instantiation,
material binding and resource tree entry. The first pullstone's three GLB loads
cost **113.875 + 11.251 + 8.004 = 133.130 ms**. Instantiation totals 0.181 ms;
material binding totals 0.846 ms. Other dispatch/tree-entry work accounts for the
remainder. The existing 2 ms stream budget cannot preempt one synchronous load.

F1 and F3 loaded their source LOD PackedScenes in every attachment. Instantiated
nodes do not retain those PackedScenes, so later attachments can reread them.
The separate source probe reproduced expensive repeated lanternheart (126.997 ms)
and stormglass (90.244 ms) creation. F2's common resource helper likewise returned
resources without keeping a reference; thrumroot repeated creation was 135.471 ms.

The small adapter caches retain the exact existing scenes, with F2's existing R2
texture aliases preserved. `scenery_resources.gd` prepares these finite resources
from `Sandpit._build_world`, after profile validation and before New World or
Continue releases movement/input. It also prepares thrumroot's unchanged cached
legacy backing, which the adopted F2 visual hides. No live source, device, hidden
actor, stock or gameplay state is created by preparation. Lazy adapter loading
still supports standalone scenes; no script-time ResourceNode/Terrain cycle is
introduced. No asynchronous queue or stream scheduling change was needed.

A concrete renderer error appeared when retained stormglass scenes retired their
per-instance immutable bore finishes. A tiny reproduction isolated that lifetime
issue. F1 now retains those unchanged, non-animated finishes with its scenes.
All work/animation shaders remain per-instance. The final rapid-retirement probe
and ordinary route report zero engine errors. This does not replace work shaders
with shared mutable materials.

### Shared path coverage and retained set

| Existing family/path | Shared correction | Source first / repeated creation (ms), before -> after |
| --- | --- | --- |
| Lanternheart, F1 | near/middle/far, lamp, recovered near core; immutable bore finish | 192.161 / 126.997 -> 2.741 / 0.209 |
| Stormglass, F1 | near/middle/far, lever, recovered near core; same lifetime fix | 129.286 / 90.244 -> 2.529 / 0.154 |
| Thrumroot, F2 | exact aliased scene/texture; winch, landing and basket; unchanged backing | 223.268 / 135.471 -> 8.790 / 4.238 |
| Pullstone, F3 | near/middle/far, magnetic sorter | Route: 154.202 -> 2.174; already-warm probe 1.364 / 1.027 -> 0.220 / 0.126 |
| Ventlung, F3 | near/middle/far, bellows | 25.450 / 3.281 -> 0.205 / 0.124 |

The separate probe materialises generated source records after travel; it is not
five additional walking routes. It frees and recreates each source twice. Some
resources were already used by ordinary world scenery, so these are observed
first attachments in this probe, not claims of cold disk access for every asset.

The retained set is **20 PackedScenes**, their referenced textures/materials,
one explicit F2 albedo alias, three adapter scripts, and the existing cached
thrumroot backing meshes. F1 creates/retains immutable plain finishes as needed;
animated materials and nodes remain local. No asset bytes, mesh arrays, transforms,
LOD definitions or native files changed. Early residency increases; RAM/VRAM was
not separately profiled. This is a finite adapter preparation path, not a general
asset-management framework or an instruction to preload the entire game.

## Actual loading and timing windows

Final Forward+ New World preparation: **934.274 ms** before control release.
Headless fresh Continue preparation: **697.527 ms**; total Continue transaction
45.091 seconds. Repeat preparation: **0.016 ms** at the caller (0.007 ms inner
recorded span), with identical cache references, source count and native ownership.
The headless preparation number is not a renderer comparison.

The retained V8 seed-77 route begins at `(879.6091, 53.1000, 557.3909)`, yaw
`-0.785398`, after one disclosed fixture relocation. Ninety settling frames precede
30 normal walking frames. Full world simulation, resource/chunk streaming and
normal creature preparation stay enabled. The existing horn propagation then
recruits the same ordered eight packs / 30 mobs and runs about 2.2 seconds.

| Complete interval observation (ms) | Before | Final |
| --- | ---: | ---: |
| Pullstone creation | 154.202 | **2.174** |
| Pullstone whole arrival frame | 178.281 | **8.656** |
| Walking median / p95 / maximum, 30 intervals | 7.921 / 16.594 / 178.281 | 8.679 / 10.138 / 12.152 |
| Group creation / whole frame | 13.940 / 99.087 | 13.720 / 34.621 |
| Recovery median / p95 / maximum | 8.660 / 12.326 / 58.050 | 8.991 / 13.217 / 18.560 |
| Synthetic relocation frame | 517.646 | 337.242 |
| Subsequent settling maximum | 137.076 | 94.698 |

The final arrival includes resource tick 3.618 ms, chunk tick 2.522 ms and draw
wall observation 1.720 ms. Spans overlap; they must not be added as independent
costs. The group route initially faces away from the pullstone. A separate camera
turn after recovery places it inside the actual camera frustum: first complete
view interval **15.420 ms**, with **10.988 median / 15.288 p95 / 15.420 maximum**
over 29 complete intervals. This measures the draw path, not a new image-quality
approval or GPU execution time. No screenshot/readback occurs during timing.

The last explicit recorder-stop row includes test save serialization and the
separate source probe (384.363 ms final / 1047.855 ms before). It is excluded from
walking, recovery and first-view statistics and retained in raw evidence. The
synthetic relocation/settling costs are also disclosed separately, not relabelled
as ordinary walking or hidden resource preparation. Recorder overflow is zero.

## Focused checks and corrections

Concrete risks: altered source geometry/state, material leakage, lost partial work
or depletion, and release of controls before preparation. Checks actually run:

- Causal before route: **25/25**, engine/runner exit 0. Two earlier harness launches
  failed parsing before world entry; the duplicate local variable was corrected.
- Final normal Forward+ route, full native group, source repeats and explicit
  first view: **28/28**, engine/runner exit 0, zero errors. Two intermediate route
  checks reproduced the material-retirement error and are not called passes.
- Tiny Forward+ retirement reproduction: final exit 0, zero errors for twice
  creating/freeing all five families. Intermediate failed runs are retained.
- Fresh Continue/source lifecycle: **97/99**, exit 1, zero engine errors. Exact
  native possessions/progression, paid blocks/stations, loose ownership, lake,
  all five saved partial sources, an omitted depleted source, work, unload/reload,
  exact finite depletion, collision, LODs and independent work materials passed.
  The two failures were a test calling `wind` on a bellows, whose real action is
  `prime`. The harness was corrected; only that affected device subcheck reran.
- Corrected actual paid bellows craft/place/prime, independent membrane/material,
  exact stored-energy scene restore: **6/6**, exit 0. The earlier lifecycle result
  is not rewritten as a clean 99/99 run. Its passed ownership/Continue evidence
  is reused. The private near-source pose settled on supported ground.
- Source diff, compact evidence generation and PowerShell syntax checked. Existing
  lake, full-roster, trial/restore and unchanged native evidence reused. No native
  rebuild, import sweep, campaign replay, renderer/seed matrix or package copy.

The extra tiny retirement/device jobs address observed failures, not a new review
wave. Automated runs used BOM-free no-focus overrides, the render mutex, retained
process handles and `--r8-no-mouse-capture`. No pointer automation occurred.
All owned tests ended and the temporary override was removed.

[Compact evidence](../../tools/wroughtwild-play07-scenery/evidence/summary.json)
contains exact reports, selected frames and raw trace paths. Outputs remain under
`build/play07-scenery/`; previous PLAY-03 evidence is untouched. Godot 4.5 stable,
Forward+, Ryzen 9 9950X3D / RTX 5090, 1280x720, VSync off, cap 120. Fresh processes
reuse imports and OS/driver caches; no cache purge or unmeasured hardware claim.

## Exact private owner playtest

Run this yourself; the assistant did not launch interactive play:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/play03-mob-arrival/tools/wroughtwild-play07-scenery/play.ps1" -Trace
```

1. Choose **Continue saved world / suspended trial**.
2. Keep the starting facing. A grey pullstone source is about 12 m ahead, up the
   bank. Hold **W** to approach; use **Space** for a ledge. At the source, **E** uses
   its normal four work stages. Then walk around and continue ordinary play.
3. **F5** saves only this private slot. Close normally to flush the optional trace.
   Later launches retain your private saved progress; they do not reset it.

Exact slot:
`D:/Wroughtwild/work/play03-mob-arrival/build/play07-scenery/playtest/user/Godot/app_userdata/Wroughtwild/wroughtwild_save.json`.
Traces are in `build/play07-scenery/playtest/traces/`. User/local/temp environment
changes and PowerShell Bypass are process-scoped. Normal owner saves are untouched.
The mouse remains free; no compass or coordinate display is required.

The initial `scenery-start.json` derives from the retained private RF-05 fixture,
changing only pose to `(837.5, 63.1000, 635.5)`, yaw pi, pitch -0.08. PLAY-07 adds
no items or free resources. Existing fixture paid buildings/ownership remain.
The separate lifecycle input deliberately changes partial/depleted source records
for testing and is **not** the owner playtest input. Keep the local
`scenery-start.json` alongside this launcher; it is intentionally not committed.
`prepare_fixtures.py` recreates missing check inputs without overwriting private
progress; the rendered after check derives the supported playtest pose.

## Coordinator handoff

New continuation only, based on worker `43e7cf3f24933999630fefe65d505104cda31188`.
The final handoff supplies the new checked commit SHA. This worker does not merge
or push main; the coordinator adopts it. Prior approved creature work remains.
Generated imports/UIDs and unrelated worktree artifacts are excluded and untouched.

The inherited RF-05 DLL is unchanged and was hash-checked, not rebuilt or copied:
`game/bin/libwroughtwild_sim.windows.x86_64.dll`, SHA256
`fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b`.
Retain that DLL for integration. No new gameplay tuning or save fields were added.
Stop after this scenery slice.

### Mainline adoption — 16 September

Worker `29e90e4e27f8ad0152547b9f59231d72939fd6f2` is adopted on main as
`c5ceb9fef46d13e413f98cf9b8ed5f05e32f7fb2`. The coordinator checked the small
resource/entry diff, clean worker source/index, retained launcher and compact
evidence. The native DLL matched the recorded hash and was retained unchanged.
The worker's final route/retirement checks and passed ownership/Continue evidence
were reused, preserving the original 97/99 result and the corrected 6/6 device
subcheck. No rendered comparison, native build or package reconstruction repeated.

Main's hidden headless asset/script import passed in **5.36 seconds**, engine
and runner exit 0, **zero reported errors**. Its D: private output is
`build/play07-scenery/main-integration-2026-09-16/` in the retained worker workspace.
The owned process exited. Unrelated owner captures/import artifacts were preserved.
Normal mainline New World/Continue now includes the fix after relaunch; the exact
private launcher above also retains it. Neither was launched interactively by
the coordinator. Final publication status is recorded in the coordinator handoff.

The remaining costs are deferred cleanup notes under the owner's original-plan
rule. Next is [RF-06 fen/lakeside atmosphere](rf06-fen-lakeside-worker-2026-09-16.md),
prepared in its own D: worktree from this integrated source. The owner starts it.
