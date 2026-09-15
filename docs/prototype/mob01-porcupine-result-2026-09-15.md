# MOB-01 — playable porcupine Cinder Archer

The ordinary Cinder Archer now uses the approved porcupine with a fitted
17-bone skin, four-beat locomotion, breathing, shoulder-comb brace and native
shot recoil. Its worker supports normal new-world and Continue paths. Standing
owner approval applies; hands-on playtesting is deferred. The checked commit
is ready for coordinator integration into main.

## Remaining limits

- The original upright capsule (0.35 m radius, 1.3 m height) and targeting remain.
  The animal is roughly 2.4 m long, 1.45 m wide and 1.5 m tall including quills,
  extending outside that collider. A presentation offset places the shoulder
  comb near the unchanged 1.05 m muzzle; no bone-driven shot origin is added.
- Short paws can slide at native chase speed. No terrain foot IK, facial
  articulation or LOD switching. Generated topology, dense fur and source face
  irregularities remain. This is not manual retopology.
- The old hidden envelope mesh remains cached for labels/setup. Visible geometry
  totals 154,400 triangles. Population/hardware performance and broad campaign
  regression were not measured.
- PLAY-03 underground lag remains open; canopy blunt ends are polish. Station/
  campaign feedback is deferred. Reclaimed Frontier, physical era additions and
  boss art stay queued. Ram, crane, beetle, nymph and tortoise are separate slices.
  R9 stays stopped.

## Integration and provenance

Selected immutable input:
`D:/Wroughtwild/source-art/mob01-porcupine/input-art06c`.
Setup's five-file receipt and retained original ART-06C source are reused.
New editable master:
`D:/Wroughtwild/source-art/mob01-porcupine/rig-v04/porcupine-rigged.blend`.
The dense 280,126-triangle host retains exact geometry and UVs. Two eyes and ten
rooted whiskers retain 4,432 triangles and follow the head. One automatic
collapse-decimated host has 149,968 triangles after duplicate-face cleanup.
No source animal generation, atlas rebake or new normal map.

[Recipes and controls](../../tools/wroughtwild-porcupine/README.md) and
[rig report](../../tools/wroughtwild-porcupine/rig-report.json) retain the fit.
The runtime manifest records source and map hashes; all three maps are
byte-identical, including the repaired muzzle strip. ART-06C's textured dark
injury and connected pulse remain. Native status overrides ambient emission;
eyes/whiskers stay non-emissive.

`CreatureMotion` adds one Cinder Archer dispatch branch. The small
`PorcupinePresentation` subclass supplies rig/material/size setup and reuses A2
sampling. Other fauna adapters, simulation, combat tuning, population, navigation,
loot, bodies and save code are unchanged. Travel advances walk; native windup
fraction braces; only `attack_released` starts cosmetic recovery. Animations
never fire shots. Pause, freeze, stagger, hit/burn/bleed and death preserve native
priority. Actors have independent bones/material state and shared meshes/maps.

## Checks actually run

Three focused jobs; Forward+ was the sole rendered backend:

1. **Source/rig/export:** selected source and attachment identity, unchanged dense
   UVs, normalized one-to-four weights for dense/runtime/face meshes, and actual
   saved idle/walk/windup/release deformations. Final paw-target error is below
   0.000000125 studio units; representative geometry is finite, with maximum
   displacement below 0.156 units. Native views retain face, quills and channels.
   Blender identified duplicate faces from reduction and removed them before
   export. Initial checker attempts had stale post-reopen object/scene references;
   corrected. The first visual exposed an inverted foreleg knee; fixed in rig-v04.
2. **Import/native actors:** initial game import and changed-asset reimport passed.
   **42 assertions passed** for identity/numbers/capsule, clips/materials, roaming,
   committed tell/aim, release timing, one shot, speed/origin, sidestep/cover,
   freeze/stagger, hit/burn/bleed, pause, shared resources, independent state,
   reconfiguration and one affected A2 boar smoke. The first fixture placed the
   player's centre at ground height, correctly blocking projectile clearance,
   and checked walk after its stopping point. Corrected height and earlier
   observation pass the original assertions. Automatic approval review rejected
   removing the walk-pose assertion; it was retained. No assertion was weakened.
3. **Ordinary lifecycle:** **18 assertions passed** in seed 77 `frontier_v6`, using
   an actual Cinder Archer pack and normal Sandpit/SaveManager. Streaming returns
   the original actor count with one rig each. Continue preserves world identity,
   exact simulation/finite-source ownership and kill stream. Death stops sampling
   and removes the actor; another hit cannot pay twice. Loose rewards/progression
   survive a second Continue. Ordinary mob repopulation remains unchanged; this
   is not a finite-host permanence claim. The first fixture omitted the normal
   scene inheritance; it was stopped and corrected, retaining its failed log.

The source inspection/build/import/check sequence ran approximately 09:52–10:09
Adelaide, including focused fixes; initial reading and final documentation/Git
work are additional. No broad review or benchmark ran. Final engine logs contain
no script/shader errors. Logs, private saves and frame sequences remain on D: in
`build/mob01/`; dense masters and caches stay out of Git.

A fresh process audit before this handoff reported **MOB01_OWNED_PROCESS_COUNT=0**
and **MOB01_OVERRIDE_EXISTS=False**. Capture used the shared nonblocking render
mutex, verified mouse opt-out and an asserted unfocusable window. Automatic
approval review requested this explicit audit before accepting the cleanup claim.

[Native idle](../art/mob01-porcupine-2026-09-15/porcupine-idle.png) ·
[Native brace](../art/mob01-porcupine-2026-09-15/porcupine-brace.png) ·
[3.34-second motion](../art/mob01-porcupine-2026-09-15/porcupine-motion.gif).
The clip uses scripted camera/roam/player placement; the actual Enemy drives
walk, commitment and shots. It is technical evidence, not owner playtesting.

## Commit and normal-main playtest

Worker: `codex/mob01-porcupine`, based on
`3c9ec7e05d92ea59ac7e750c2f07b5039479e8bb`. This result and the complete checked
slice are committed together; the delivery message gives the exact SHA.
**Main integration and origin/main push are pending the coordinator.** No worker
push or main publication is claimed. Reuse the passed evidence above.

After integration, launch normally:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

1. Continue an existing world or choose a class/new seed. No MOB-01, showcase or
   art-preview flag is required. Existing optional campaign flags keep their meaning.
2. Find a Cinder Archer pack. Watch the walk, face, quill growth and travelling
   channels. Approach within normal ranged distance: brace precedes one shot/recoil.
3. Sidestep committed aim or use cover; try existing freeze/stagger and pause.
   Save normally, restart and Continue.

Before main integration, the same command can use
`--path 'D:/Wroughtwild/work/mob01-porcupine/game'`. Normal launches use normal
saves; automated checks used private D: application data only.
