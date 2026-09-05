# A calmer frontier and an editable workshop

Author and implementer: **Codex (OpenAI)**, 5 September 2026.
Branch: `codex/aesthetic-experiments`. Continues the owner's request to take
the next aesthetic steps and spend time exploring solutions.

Status: implemented experimental candidate, not a replacement for D-013.
Normal world generation, loot, progression and ordinary shape unlocks are
unchanged. D-018's previously reported siege-policy conflict remains deferred.

## What changed and why

Subsequent owner review: this pass was approved and merged into local `main`.
The [weathered frontier continuation](codex-weathered-frontier-2026-09-05.md)
records the owner's darker art direction and the following scenery/performance work.

The previous terrain rounded the geometry but gave each small triangle its
own lighting normal. The hard grass/dirt slope cutoff added another triangle
pattern. The candidate computes a shared, material-independent normal from
the solid/air samples around each lattice corner, blends turf gradually by
slope and reduces colour variation. Shared samples agree across chunks and
are regenerated after excavation. Render vertices, collision triangles,
source-voxel picking and saved excavation data are unchanged.

`--crafted-look` enables this candidate, the existing frontier materials and
the new branching trees. `--faceted-look` still selects the earlier flat-lit
candidate. Omitting both keeps the normal cubic presentation.

Trees now have actual branch forks and layered foliage masses: broad meadow
crowns, tapered forest crowns, low spreading fen trees and bare waste snags.
Colour follows crown height instead of independently changing every face.
Geometry is deterministic per existing visual seed. The resource node still
owns harvest state, world scale, position, highlighting and trunk collision.
Roots, upper branches and foliage are visual geometry. No additional assets,
packages, resources or harvesting rules were introduced.

The workshop demonstrates **64 individually editable pitched roof pieces**
over a lower octagonal ceiling. Three lab forms suffice: slope, convex hip and
concave valley. They use existing oriented block addresses, quarter turns and
half-grid anchoring; the valley uses two convex collision halves so its dip
does not become an invisible solid roof. Roof crease normals remain flat,
avoiding the dented tile appearance seen in the first render. The lab corner
form also gets flat crease normals.

The lower octagonal ceiling and occupied roof blocks provide enclosure.
Removing a ceiling panel outside the raised roof really breaks shelter.
The upper roof can be removed/rebuilt, and its shape, material and orientation
round-trip through the existing schema. Roof pieces reserve full blocks,
just as the existing wedge does; this is not precise attic-volume simulation.

The new workshop lab can be played: movement, building, shape/material
selection, rotation, removal, crafting, storage and save/load use the existing
player and sim paths. Materials are supplied for experimentation. F5/F9 are
overridden in the lab player to use **`user://codex_workshop_study.json`**;
they cannot read/write the ordinary `wroughtwild_save.json`. The automated
playable smoke uses a separate ignored file under `build/` instead.

Plank joints, interior/exterior framing, station silhouettes, warm lights and
the surrounding ground are explicitly lab presentation. They are not new
unlockable content, fuel simulation or player-owned decoration. Station
silhouettes fit inside their existing collision envelope. These details are
reapplied after restoration and when the player adds pieces.

## Reproduce

Rebuild the extension after sim or binding changes. From the repository root:

```powershell
cmake --build build/gdext -j 4
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Crafted
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Woodland
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Roofs
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Traversal
```

Each helper invocation has a 55-second limit per Godot process. Captures,
copied fixture tuning, logs and manifests stay ignored under
`build/codex-aesthetic/`. The gallery source is
`tools/codex_aesthetic_gallery.html` and is copied to the build folder.

Normal gameplay with the new terrain/tree candidate:

```powershell
& C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe --path game -- --crafted-look
```

Editable workshop, with its isolated catalogue and save:

```powershell
& C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe --path game res://experiments/roof_workshop.tscn -- --workshop-play
```

WASD/mouse, Space jump, B build, Tab shape, Q material, R rotate, LMB place,
X remove, E interact, F5/F9 save/load. The ordinary game command above retains
the ordinary game's save controls; only the workshop scene isolates saves.

## Controls and boundaries

| File / control | Player-visible purpose |
| --- | --- |
| `game/art/crafted_look.tres`: `soft_terrain` | Shared normals soften the tiny surface facets; collision stays exact. |
| `turf_slope_start=0.25`, `turf_slope_end=0.8` | Gradual soil-to-turf blend from steep to gentle ground, using upward normal component. |
| `colour_variation=0.16` (previous 0.28) | Quiet colour contrast so props and landforms are easier to read. |
| `game/art/woodland_look.tres`: biome profiles | Height, trunk radius/lean, branch count/spread/rise, crown radius/depth, taper and pointed crowns; each has its purpose in the resource. |
| `radial_segments=9` | Broad foliage planes with a bounded mesh budget. |
| `game/experiments/roof_shapes.json` | One-metre footprint, half-metre pitch and provisional cost of one material per study piece. Joinery required; no accepted gameplay unlock. |
| `game/art/workshop_wood.gdshader` | 0.28 m boards and 0.012 m joint width give the lab timber a restrained material read. `timber` selects the wall/ceiling shade. |
| `roof_workshop.gd` scene dimensions/lights | A 14 m octagonal footprint, 8 m raised roof and warm interior context; fixture geometry, not progression tuning. |

## Evidence

- C++ simulation suite: **4,627 checks, zero failures**, built with the
  existing warning/error flags after roof-form validation changed.
- Existing Godot suites: unit **397**, art **11**, integration **265**, horde
  **43**, grammar **68**, feel **17**, zero failed assertions; main smoke
  completed. The inherited unit fixture's dummy-renderer/off-tree diagnostics
  remain; no assertions or error rules were weakened.
- Faceted terrain: **66 checks**, including exact normals and triangle
  restoration after digging, collision picking and chunk rebuilds.
- New controller traversal: **23 checks**, a 13.85 m walk across the chunk
  seam and a 1.00 m elevation change using the actual player controller.
  Shared-normal seam and unit-length checks pass.
- Roof lab: **768 headless / 771 windowed checks**, zero failures. Includes
  rotated hip/valley collision rays, hard crease
  normals, the actual ray/preview/payment placement path, removal, shelter
  leakage, fueled crafting, stored contents and save restoration.
- Playable lab smoke: **700 checks**, zero failures. Verifies a grounded
  player, selectable roof shapes,
  isolated disk save/load and an actual rendered player view.
- Woodland: **18 checks** in the renderer, including deterministic geometry,
  changed seeds, nondegenerate correctly wound triangles and fewer than
  1,400 triangles per tree.

The landscape comparison preserves seed, generated world, camera and daylight
between the old and new art passes. It changes both normals/material and trees;
the separate woodland panel isolates tree silhouettes. The contour-generation
study from the previous report remains a separate gallery option.

Five fixed views also record 35 process-frame intervals after ten settling
frames. On this PC's RTX 5090 / Forward+ run, the new candidate's medians were
3.89–6.67 ms; the spawn p95 was 16.67 ms. At the overlook, rendered primitive
counts rose from about 3.36 million to 4.17 million with the richer trees.
These short, stationary samples include frame pacing; they are **not isolated
GPU timings, combat performance acceptance or evidence for weaker hardware**.

## Assessment and next decisions

This makes the landscape substantially quieter and the workshop testable from
inside. It does not finish the art direction. Soft lighting still exposes
rounded voxel ripples; the terrain's large-scale shape and distant haze remain
recognisably inherited. Some cover and long resource strips can still float
near rounded edges, and upper tree branches retain visual-only collision.
The isolated pine view also shows thin self-shadow bands across some foliage;
foliage overlap and shadow settings need a closer pass before art adoption.
The walk test is one short route, not a full cave, combat or progression run.

The workshop still has thick diagonal walls and a straight one-metre door.
Its shape saves require the lab catalogue. The raised square hip is a practical
small-palette solution over the octagonal lower roof; an entirely pitched
octagonal roof and thin diagonal doors need a separate geometric decision.
There is no normal-game roof unlock or economics change in this pass.

Recommended next review: judge the calmer terrain and new tree shapes at eye
level, then edit the workshop in the lab. If the direction is preferred,
ground decorative cover/resource strips on the actual surface and profile a
longer moving/combat route before adoption. Decide the desired wall thickness
and roof unlock before promoting the construction catalogue. Progression
retuning remains behind its fixed-session baseline and the unresolved loot
and siege policy choices recorded in the original proposal.
