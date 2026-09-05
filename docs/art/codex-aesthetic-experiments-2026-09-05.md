# Aesthetic experiments — 5 September 2026

**Author and implementer: Codex (OpenAI), not Claude.**
Branch: `codex/aesthetic-experiments`, starting at `e8b8d55`.
Status: owner-authorised experiments; candidate art and corner shape are
not accepted default design. D-013 and D-018 are not superseded.

The owner prioritised the Minecraft-like aesthetic and expressive building
over progression retuning. This work produces a reproducible comparison and
a construction feasibility result. It does not claim to complete the larger
aesthetic intensive or establish progression pace from stationary captures.

## What changed

1. **Procedural prop repair, active in normal play.** Icosahedron faces and
   trunk facets were wound inward. Canopies showed their hollow backs and
   rocks received inward-facing normals. Reversing these triangles restores
   exterior faces while preserving vertices, seeded colour rolls, collision
   and world layout. This fits D-013's existing faceted props.
2. **Opt-in landscape candidate.** `--frontier-look` uses continuous
   world-space colour variation instead of repeating pixel tiles on terrain.
   Turf has exposed soil sides; decorative cover forms sparse/lush patches
   and uses tapered blades with consistent lighting on both sides. Terrain
   geometry, excavation, resources and biome layout use the same simulation.
   The profile does not enter save data.
3. **Isolated corner-block lab.** An oriented `corner` form reuses the roof
   wedge turned on its end, including its convex collision hull. The tuning
   reader recognises the form. The shape exists only in a fixture appended
   to a copied tuning directory; the normal catalogue and unlocks are unchanged.
4. **Review tools.** Fixed-camera scenes, bounded PowerShell runs, capture
   manifests and an offline comparison gallery are checked in. Generated
   screenshots, logs and fixture copies remain ignored in `build/`.

## Visual findings

The comparison uses seed 1, Warden, day 1 at fraction 0.1, 1920×1080,
Godot 4.5 stable and Forward+. Both variants include the prop repair.
Camera, target, time, renderer, primitive counts and draw calls are recorded
in each manifest. Five views cover spawn, an overlook, forest, fen and ember
wastes. The capture scenes do not read or write a player save.

Codex's assessment: the candidate ground is calmer and exposes soil strata
more clearly. Narrow cover silhouettes reduce the repeated card appearance.
However, long horizontal terraces, regularly spaced vegetation and simple
canopy masses still dominate. The candidate also risks looking too smooth
and pale in the meadow. Surface replacement alone does not resolve the
owner's aesthetic complaint. These are visual judgements, not owner approval.

The captures record roughly 5.4–6.9 million rendered primitives and
8.6–10.5 thousand draw calls across views. The candidate adds some geometry;
these counters are not GPU timing or performance acceptance results.

## Octagon findings

The lab builds a ten-metre-wide timber room with three-metre walls,
three corner blocks along each chamfer, a straight doorway, floor and roof.
It drives normal placement and SaveManager paths without player input.
The roof is hidden only for screenshots; enclosure checks use the roof.

| Probe | Observed result |
| --- | --- |
| Four corner rotations | Prism form and convex collision restored in all four orientations |
| Ray through empty half / across diagonal | Empty half is clear; diagonal face collides with the corner |
| Room centre | Enclosed; removing the central roof slab breaks enclosure, replacing it restores enclosure |
| Save round trip | All shape IDs, families, addresses and rotations survive JSON serialization and restoration using schema 2 |
| Whole-cell occupancy | Another block cannot occupy the reserved cell |
| Empty half of corner | Physically empty but not sheltered; the flood fill treats the whole cell as occupied |
| Open straight door | Still sheltered under existing registry behaviour; opening changes engine collision, not occupancy |
| Appearance | Diagonal inner wall, thick stepped exterior; floor/roof cells also retain square outlines |

The response was right that a lattice migration is unnecessary for this
limited form. It understated the semantic mismatch at the empty half-cell.
The shape is therefore a lab result, not a finished build-tool addition.
Save restoration was tested **with the lab fixture loaded**. A save containing
`codex_corner` is not portable to normal tuning. The lab never writes a player
save and disables input, including the player's save/load keys.

## Reproduce and review

From the repository root, using the installed pinned console binary:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Octagon
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Checks
```

Open `build/codex-aesthetic/index.html`; it needs no server or packages.
The first command captures ten landscape images; the second captures the
octagon cutaway/interior and writes `octagon/observations.json`. Each Godot
invocation has a 55-second external process limit. Only processes started by
that invocation are stopped on timeout. The helper accepts `-Godot` for
another binary path. Build products are not committed; rebuild the extension
before running the lab after a clean checkout.

To play the normal sandpit with candidate materials:

```powershell
& C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe --path game -- --frontier-look
```

This is ordinary gameplay with its ordinary save controls. Omit the flag
to return to pixel surfaces. The isolated lab is a separate scene,
`res://experiments/octagon_lab.tscn`, and loads copied tuning.

## Tuning and boundaries

The profile is [frontier_look.tres](../../game/art/frontier_look.tres), with
exported defaults in [frontier_look.gd](../../game/art/frontier_look.gd).
Each profile control has a plain-language `design_purpose` entry.

| Control | Current default | Player-facing purpose |
| --- | --- | --- |
| Top and side palettes | Art palette plus biome/stratum tints | Retain material identity; expose soil below turf |
| Broad patch / detail size | 12 m / 0.8 m | Connect adjacent blocks; retain close-range grain |
| Colour variation | 0.28 | Surface contrast against props and threats |
| Grass edge depth | 0.18 block | Turf hanging over soil edges |
| Cover patch size | 9 m | Alternate open ground and lush patches |
| Sparse / dense multiplier | 0.08 / 1.7 | Scale existing biome cover density |
| Blades / width / lean | 5 / 0.065 / 0.28 | Silhouette and spread relative to plant width |
| Decorative scale | 1.2 | Plant size at first-person height; no collision effect |
| Corner fixture cost | 2 units | Cube-equivalent placeholder, not progression tuning |

No external art, package or service was introduced. There is no save schema
change, diagonal door, terrain smoothing, navigation rewrite or new resource.
The siege contradiction and literal `wood` check remain explicitly unresolved.

## Validation

- Rebuilt GDExtension successfully with the installed MinGW toolchain.
- C++ simulation: **4,579 checks, zero failures**, compiled with the existing
  Makefile's source set and flags (`-std=c++17 -Wall -Wextra -Werror -O1`).
  Compilation was invoked directly because its `mkdir -p` recipe failed
  under the Windows command shell; the Makefile itself was not changed.
- Godot: unit **397**, art **11**, integration **265**, horde **43**, grammar
  **68**, feel **17** checks, all zero failures; main-scene smoke **120 frames**.
- Octagon: headless **240**, windowed **242** checks, zero failures; the latter
  also checks screenshot output. Real physics, placement, enclosure and save paths
  are exercised. Empty-half/open-door observations are reported limitations.
- Ten landscape captures completed without reported script errors.

The existing unit suite exits successfully but emits an off-tree `data.tree`
diagnostic from `mob_packs.gd` and dummy-renderer fixture leak messages, plus
deliberately invalid-input warnings. The review runner preserves the existing
suite's exit-code contract for that suite; it always rejects script errors
and failed checks. Other runs also reject engine `ERROR:` lines. No existing
test or assertion was weakened to accept these experiments.

## Recommended next intensive

**Landform silhouette and a complete octagonal workshop**, with two reviewable
milestones before changing default art direction:

1. Compare a few terrain presentation treatments at the same cameras: less
   uniform terrace edges, stronger biome plant silhouettes and grounded
   material variation. Keep dig/build collision readable. If rendering
   diverges from the editable voxel surface, demonstrate that difference at
   excavation and placement boundaries explicitly.
2. Build one workshop whose interior and exterior both read as eight-sided,
   with a coherent floor, roof and doorway. First decide whether thick
   chamfers are acceptable. Resolve empty-half shelter before offering these
   pieces in normal play, with placement/removal, collision and save checks.
   Thin diagonals remain a separate architectural decision if the block
   compromise fails visual review.

Progression retuning is deferred to preserve the owner's aesthetic priority.
A short [baseline worksheet](../prototype/codex-progression-baseline-2026-09-05.md)
captures pacing questions without adding a telemetry framework or claiming
that the proposed era/source rules have been accepted.
