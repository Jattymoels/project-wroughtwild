# PLAY-03 full-roster grouped arrival — 15 September 2026

The reproduced substantial mob-loading freeze is removed from the measured mixed
arrival: **30 mobs in eight native packs**, **900.999 → 13.050 ms** of synchronous
arrival work, with the full frame **950.572 → 40.869 ms**. The same complete
encounter appears. Shared preparation now covers all current creature bodies,
both wisps, LF aliases, and both distinct boss presentation paths.

The remaining 40.869 ms frame still exceeds the approximately 16.7 ms aim. This
is a large improvement in the reported freeze, **not a claim of hitch-free play**.
The measured creation work fits that aim; combined streaming, drawing and physics
do not. A separate scenery pullstone produced a 106.840 ms approach frame. The
original underground correlation and older unrelated spike remain unresolved.

## Cause and implementation

The valid native group reproduces the reported tortoise/archer/cinder-wisp case,
plus its actual generated companions. First-use work dominated:

| First use inside the before group | Measured ms |
| --- | ---: |
| Crane scene acquisition / material textures | 171.262 / 153.895 |
| Porcupine scene acquisition / material textures | 15.029 / 232.565 |
| Tortoise scene acquisition / material textures | 8.575 / 152.316 |
| Cinder Wisp source acquisition / visible mesh conversion | 6.633 / 62.403 |
| Crane / porcupine / tortoise legacy mesh conversion | 12.706 / 14.102 / 19.661 |

Repeated adapter construction was small. Preparing textures alone would leave
first-use mesh conversion and fallback construction, so the correction prepares
those exact shared resources too. `game/art/creature_resources.gd` is one finite
roster helper called by actual New World/validated Continue and TrialController
entry/validated checkpoint restoration. No actor is instantiated or activated by
it. Existing off-tree source scenes are used only to build their cached meshes.

The six adapters now share the same small `prepare_resources()` contract and use
those helpers in lazy standalone setup. Their exact scene, texture, material and
fit definitions remain. Both visible articulated moth skins remain complete;
the later adapters retain their adorned legacy envelopes. The original fitted
boar/wolf/stag preparation and two-point hidden-envelope improvement remain.
Native `enemy_ids()` is profile-filtered, so preparation also resolves each active
profile's fallback roles. LF `visual_id` bodies share resources, not actor state.

The resource-only pass also retains existing Enemy/Boss/Conservator PackedScenes,
prepares the unchanged ward spheres and projectile-head geometry/material
sources, and caches the Conservator's unchanged body/limb/scar geometry. Each
actor retains its own rig, joints, status materials, tells and animation clocks.
Ward geometry/material is immutable; per-projectile materials remain separate.
No spawn order, queue, population reservation, activation range, loot/death rule,
save field, native tuning or art asset changed. No new gameplay tuning exists.
The opt-in recorder's event bound is now 2,048 so a complete capped group and
substeps fit; overflow remains explicit and tested.

### Where the cost moved

Normal New World preparation took **2,364.251 ms** before controls were released,
including the previous approximately 0.9-second fitted-fauna work. The resource-
only intermediate took 2,478.633 ms. Fresh-process Continue preparation took
**2,161.114 ms**; a repeat call took **0.054 ms**. Fresh suspended-LF-trial restore
prepared everything in **2,503.416 ms**, before returning to its cleared boundary.
LF's additional fallback roles took 28.478 ms in the separate rendered coverage
phase, and 6.551 ms through the lifecycle check's actual trial entry.

Those measurements precede the final small Conservator mesh-cache addition; its
separate added startup cost was not timed. Its actual first creation was measured
instead: **19.771 → 2.616 ms**, and creation through first post-draw
**22.251 → 4.512 ms** in an isolated body check. Tyrant's final corresponding
measurements were **0.797 / 6.386 ms**. No hidden actor or renderer warm-up was used.

Total world entry was 41.923 seconds before / 38.256 seconds after; private Continue
was 49.787 seconds. Single runs and incidental machine variation do not establish
a total loading improvement. The cost transfer above is explicit; world entry
remains long. Retaining these current-roster resources increases early residency;
RAM/VRAM impact was not separately measured. No future content is preloaded.

## Generated group and complete timing window

V8 seed 77; native den indices/composition, in order:

| Pack | Complete generated members |
| --- | --- |
| 146 | 3 Cinder Wisps, 1 Ash Hound |
| 149 | 2 Shriekers, 2 Ember Whelps |
| 153 | 4 Ash Hounds |
| 154 | 1 Cinder Archer, 2 Ember Whelps |
| 155 | 1 Shrieker, 4 Ember Whelps |
| 156 | 3 Ember Whelps |
| 159 | 4 Ash Hounds |
| 160 | 2 Hollow Knights, 1 Cinder Wisp |

Totals: **2 tortoises, 1 porcupine archer, 4 cinder moths, 3 cranes, 11 boars and
9 wolves**. Ordered IDs match exactly between captures. No pack was cloned,
trimmed or changed. The disclosed initial pose is
`(879.6091, 53.1000, 557.3909)`, yaw `-0.785398`, outside normal activation.
After 90 settling frames and 30 normal walking frames, the fixture calls the real
`MobPacks.noise_at(player.position, "horn")` propagation once. It measures that
existing 90 m recruitment action directly, not item acquisition or the player's
horn UI/PulseRing. All world/AI/streaming remains active through group recovery.
The native 28 m proximity activation and population rules remain unchanged.

| Process-frame observation (ms) | Before | Final group check |
| --- | ---: | ---: |
| Approach median / p95 / worst (31 intervals) | 7.897 / 13.433 / 18.389 | 7.957 / 11.686 / **106.840** |
| Full arrival interval, including first draw | **950.572** | **40.869** |
| Synchronous horn/group creation | **900.999** | **13.050** |
| Arrival draw pre/post wall observation | 14.723 | 5.151 |
| Following complete interval | 12.063 | 12.468 |
| Recovery median / p95 / worst | 9.410 / 13.636 / **237.240** | 8.994 / 12.764 / 21.637 |
| Initial synthetic relocation interval | 371.057 | 353.298 |
| Worst subsequent settling interval | 111.087 | 90.188 |

Recovery spans roughly 2.2 seconds: 201/240 complete intervals. The final arrival
also includes 7.174 ms of chunk work, 2.611 ms of resource streaming and 5.982 ms
of physics callbacks across two physics ticks; these and the creation/draw spans
are nested/overlapping and must not be summed as independent frame costs. Group
first-update total is 3.737 ms; cached shot-tell creation is at most 0.077 ms and
ward attachment at most 0.009 ms. Ordinary per-member setup is small; no remaining
hundreds-of-milliseconds creature resource acquisition was observed.

The final **106.840 ms approach** event is a scenery **pullstone** arrival:
99.276 ms in that resource arrival, 99.289 ms resource tick. The before recovery's
237.240 ms event also includes a pullstone (104.571 ms) and 108.781 ms draw wall.
The intermediate resource-only run placed that same scenery issue in recovery
at 130.920 ms. None is concealed or relabelled as smooth. A separate scenery
resource-preparation investigation is the concrete next remedy; it is outside the
creature scope. Initial relocation moves the fixture far from normal spawn and
invokes synchronous destination streaming (246.897 ms after in `ensure_area`).
It is not production creature preparation hidden inside the settling wait.

The remaining 40.869 ms group frame would need a separate combined frame-cost
improvement to meet 16.7 ms. The dominant creature first-use omissions are fixed;
spreading the full encounter over frames would change timing/ownership and was
not introduced just to lower that combined number. Ordinary owner play will
establish whether the residual short group hitch needs that further work.

## Full roster coverage

Native definitions come from `world.json` / `trial.json`, checked against the
actual native catalogue and CreatureMotion/Boss dispatch. The 16 body creation
samples below are the final group run's separate coverage phase, after recovery.
Each had a visible complete model/surface and a valid independent rig. Lifecycle
checks additionally covered status separation, fit, reconfiguration and elites.

| ID / family | Prepared/shared path | Creation ms / evidence |
| --- | --- | --- |
| `ember_whelp` | FinishedFauna boar | 0.828; prior envelope fix retained |
| `ash_hound` | FinishedFauna wolf | 0.690 |
| `valley_elk` (passive) | FinishedFauna stag | 0.698 |
| `cinder_archer` | PorcupinePresentation | 1.561 |
| `shrieker` | CranePresentation | 0.658 |
| `stone_husk` | RamPresentation | 0.670 (182.846 before first-use prep) |
| `gloom_crawler` | BeetlePresentation | 0.676 (195.485 before) |
| `bog_lurker` | NymphPresentation | 0.866 (215.169 before) |
| `hollow_knight` | TortoisePresentation + existing ward | 0.664 |
| `marsh_wisp` | Its own full recovered skin/texture + articulated rig | 0.456 (94.569 before) |
| `cinder_wisp` | Its own full recovered skin/texture + articulated rig | 0.497 |
| `lf_white_stag` | Stag visual alias, independent LF state | 0.766 |
| `lf_green_moth` | Marsh moth alias, local scar overlay | 2.298 |
| `lf_paired_boar` | Boar alias, separate collars/held tell | 3.362 |
| `lf_red_boar` | Boar alias, red scar/tell | 2.593 |
| `lf_blue_boar` | Boar alias, blue scar/tell | 2.900 |
| Elite / era variants | Same IDs/resources; native scaling/mechanics retained | All 16 elite bodies checked; unchanged era logic reused |
| `forge_tyrant`, `ash_warden`, `forge_heart` | Boss dispatch forces existing shared Tyrant mesh/rig | Final distinct-body check 0.797 ms creation / 6.386 ms through first draw; no three-fight replay |
| `conservator` | Separate procedural human + cached body/limbs/scars | 2.616 / 4.512 ms; independent animated joints/harness materials checked |

The initial mixed coverage's boss intervals also included test-only campaign
setup/world reactions (2.481/3.067 seconds), so they cannot establish boss display
cost. The final short isolated boss check separates that setup before sampling;
its body timings are not whole-world performance. No new boss art was authored.

## Entry-path coverage and preservation

| Entry | Implementation / evidence | Boundary |
| --- | --- | --- |
| Normal New World | Real WorldSeedControls → Sandpit build → full preparation before release | Measured valid generated group |
| Validated Continue | Same build path; 120-check fresh-process job | Exact RF-05 native state, paid blocks/stations, loose drops/death packs, loot counter and lake retained |
| Passive fauna, surface/cave packs | Prepared resources → unchanged MobPacks / Enemy.spawn | Stag and every body checked; old cave support, counts and sleep/death evidence reused |
| Noise recruitment | Unchanged horn propagation → complete ordered native packs | 30-member group measured |
| Sleeping reactivation | Same unchanged `_spawn_pack` and cached mesh path | Prior exact-survivor/once-only-death evidence reused; no queue/reservation change |
| Sieges | Unchanged `spawn_siege` → Enemy.spawn | Shared spawn/body coverage; no night replay |
| Resource-site defenders | Unchanged `player.spawn_ambush` → Enemy.spawn | Shared spawn/body coverage; native IDs/counts untouched |
| Initial trial groups | Real TrialController entry prepares before returning; actual room entered | Native ordered encounter and cancellation checked |
| Reinforcements/bosses | Same `_spawn_spatial_encounter` / wave logic → shared Enemy/Boss spawns | No wave scheduler change; resources ready at entry, distinct boss displays checked |
| Restored campaign/trial | Preparation after checkpoint validation, before arena return | Fresh LF checkpoint restore: eight checks, exact native ownership, no early actors, empty boundary queue and successful cancellation |

Preparation never mutates native rules, finite hosts or paid ownership. Source
art, collision, aggro/damage, 28 m activation, saves, RF-05 swimming/shore/recovery
and V1–V7/LF geography remain unchanged. Earlier passed boar/lake/save/sleep/death
checks are reused, rather than replaying campaigns or unchanged suites.

## Checks, evidence and limitations

- Valid before group: **26/26**, exit 0. An earlier selection accidentally lay
  outside the map; it is excluded from gameplay evidence, retained separately,
  and the selector now enforces map margins plus a grounded approach assertion.
- Resource-only intermediate: **26/26**, exit 0; 17.877 ms group / 44.656 ms frame.
- Final full-roster rendered pass: **37/38**, exit 1. The only failure was test
  teardown trying to import native state before abandoning the temporary human
  trial. The fixture now abandons/ends first; its exact correction passed in the
  lifecycle and final boss jobs. Group/body data is retained; this is not described
  as a zero-failure renderer run and it was not needlessly replayed.
- Fresh Continue / LF / trial / material lifecycle: **120/120**, exit 0.
- Distinct fresh suspended-trial restore: **8/8**, exit 0, 2.842-second transaction.
- Isolated corrected boss display/material/joint check: **9/9**, exit 0.
- Source diff, launcher syntax and committed evidence checks passed. No broad
  native build, renderer/seed/status matrix, campaign replay, R9 or package work.

The two extra entry/body jobs cover distinct paths expressly included by the
expanded brief. Reruns addressed the concrete invalid route, changed first-update
resources and changed human mesh preparation, not new review waves. The final
human cache was checked by the boss job; group/Continue timing was not replayed
for that independent addition. All owned jobs exited; the no-focus override was
removed. No mouse capture or pointer automation occurred.

[Compact evidence](../../tools/wroughtwild-play03-group/evidence/summary.json)
contains the exact reports, selected frame data, roster and trace paths. Raw
traces/logs remain under `build/play03-group/`, preserving both previous slices.
Hardware: Godot 4.5 stable, Forward+, Ryzen 9 9950X3D / RTX 5090. Group capture:
1280×720, cap 120, VSync off. Isolated boss check is uncapped. Draw observations
are wall time, not GPU execution measurements. No OS/driver cache purge, hidden
quality change, screenshot/readback or per-frame disk writes. Other hardware,
full campaign performance and owner playtesting remain unmeasured/deferred.

## Optional private playtest

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/play03-mob-arrival/tools/wroughtwild-play03-group/play.ps1" -Trace
```

Choose **Continue saved world / suspended trial**. Keep the initial camera
facing, hold **W briefly**, then press **X outside build mode** to blow the horn.
This uses the actual player action and will recruit the nearby generated packs;
precise counts depend on how far/when you walk. The mouse stays free. No compass
or invisible-coordinate instructions are needed. The assistant did not launch it.

The local `group-start.json` derives from the retained private RF-05 arrival
fixture: only the disclosed player pose and **one test shrieker horn** are added.
It is copied once into `build/play03-group/playtest/user/Godot/app_userdata/Wroughtwild/`;
F5/subsequent launches keep that independent progress. User/local/temp/trace data
stay on D:, owner saves are untouched, and execution policy changes only for the
command. Retain `build/play03-group/group-start.json` with this local launcher;
it is intentionally not a committed save/build artifact.

## Coordinator commit and native status

Continue branch `codex/play03-mob-arrival` after worker
`039bccf49e6c99c1d40ec78102ccf6cc31efcc0e` (adopted on main as
`1bc19e90a17600dc9556a2cf38d291c0b9027518`). Only the new checked continuation is
committed; the final handoff supplies its exact SHA. No merge or push is performed.

The unchanged inherited RF-05 native DLL was rechecked, not rebuilt:
`game/bin/libwroughtwild_sim.windows.x86_64.dll`, SHA256
`fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b`.
Coordinator should retain it. Generated import/cache artifacts and unrelated
untracked files are excluded and left in place. PLAY-06 is not part of this slice.

### Mainline adoption — 16 September 2026

Worker `43e7cf3f24933999630fefe65d505104cda31188` was adopted on main as
`9dba2fd7f7085a1c4012018fd217068f0068e9ff`. The existing RF-05 native DLL matched
the hash above and was retained. The coordinator checked the changed resource/
entry paths, full-roster evidence and clean worker source/index, then reused the
worker's functional evidence including its disclosed corrected teardown failure.
No renderer, campaign, native build or performance matrix was repeated.

Main's hidden headless asset/script import passed in **9.88 seconds**, engine
and harness exit 0, **zero reported errors**. Output/private state:
`D:/Wroughtwild/work/play03-mob-arrival/build/play03-group/main-integration-2026-09-16/`.
The process exited and no owned test remains running. Owner captures and unrelated
untracked/import files were preserved. Ordinary publication uses the standing
`origin/main` permission; the coordinator handoff records its final push outcome.

The normal C: owner game now contains this change; quit/relaunch before testing,
then use normal Continue or New World. The separate D: horn/group launcher above
also retains the complete fix and a ready private approach. Neither launcher was
started by the coordinator. Owner playtesting of this continuation is deferred.
PLAY-06 bearings/coordinates was next queued at adoption; the owner subsequently
parked it on 16 September. No navigation worktree/task was started.
