# Landforms and octagonal workshop — 5 September 2026

**Author and implementer: Codex (OpenAI), not Claude.**
Branch: `codex/aesthetic-experiments`. Owner-authorised continuation of the
[first experiments](codex-aesthetic-experiments-2026-09-05.md), after the owner
prioritised aesthetics and asked to continue the recommendations.

Attribution correction: the earlier Codex commits `52a54fd` and `bcae290`
inherited the repository's Claude Git identity despite their explicit Codex
messages. Their work was Codex's. This continuation sets both Git author and
committer to Codex (OpenAI) explicitly without rewriting those commits.

Status: implemented, tested experiments for review. D-013 remains the default;
these results do not accept a replacement art direction. Progression retuning
and the D-018 siege conflict remain deferred. No D-025 was created.

## Result and assessment

Follow-up: [calmer terrain, branching trees and the editable roof workshop](codex-crafted-frontier-2026-09-05.md)
implements the next visual and traversal experiments, with fresh captures and checks.

The gallery now compares **faceted terrain against cubic terrain in the same
generated world**, with identical cameras, materials and daylight. This is a
more substantial visual change than the first surface-material pass: exposed
corners become sloping facets, breaking the square stair outline. My assessment
is that it is the stronger candidate to walk through next, but the repeated
triangles, sparse tree silhouettes and washed-out distant surfaces remain
visible. This does not finish the aesthetic problem.

A separate comparison regenerates winding contours with stronger relief.
It uses the same seed and fixed cameras, but biome boundaries, resources,
threats and biome-dependent lighting can change. It is a fresh-world study,
not a geometry-only comparison. Original camera names identify their anchors;
they do not guarantee the regenerated anchor remains in that biome.

The workshop has diagonal interior **and exterior** walls, clipped floors
and ceilings, a straight door, workbench, mason's yard, fuelled forge and
storage. Thick chamfers achieve the silhouette without diagonal lattice
addresses or a save migration. The empty half of a corner now receives
shelter while its solid half does not. The hipped roof and exposed framing
are **decorative lab geometry**, not new player-placeable or saved pieces.
The saved ceiling provides shelter; removing it leaks even under the roof cap.

## Clarification: the tree and boulder repair

The owner correctly noted that trees and rocks looked identical on both sides
of the original HTML comparison. **Both sides already included the repair.**
The earlier “fixed hollow-looking tree and rock faces” wording meant reversing
inward-facing procedural triangles, not redesigning trees or terrain cliffs.

The gallery now has a separate close-up before/after. The before reconstructs
the pre-repair triangle order of a seeded tree and boulder; the after uses the
current meshes. Vertices, colours, camera and lighting are identical. Codex
inspected both rendered images: the old canopy and boulder appear hollow,
while the corrected ones show their exterior faces. This repair was already
committed in `52a54fd`; this continuation makes its evidence unambiguous.

## Implementation and compatibility

- `--faceted-look` builds an exposed-surface mesh and matching collision from
  the existing voxel field. Shared corner positions derive deterministically
  from nearby solid/air crossings. Face centres retain the original resource
  anchor height. Each collision triangle carries its source voxel, so digging
  selects that voxel rather than guessing from a slanted normal. Excavation
  rebuilds diagonal neighbouring chunks when necessary. Voxel edits retain
  their existing representation and restoration path.
- The optional contour profile changes generation itself. Only its isolated
  comparison scene loads copied tuning; it never loads a player save. Zero
  height warp preserves the ordinary generator's existing path.
- Corner shelter clips shared faces against the prism's empty half-space;
  point/edge-only contact is not a passage. Placement continues reserving the
  whole original cell. Partly empty fine volumes count as whole volumes toward
  the existing shelter size cap, conservatively. Open doors retain the
  specification's existing sheltered behaviour.
- Corner forms are restricted to oriented square blocks or floors matching
  their grid extent. Floor corners have four yaw orientations. The fixture
  catalogue contains `codex_corner` and `codex_corner_floor`; ordinary unlocks
  and material costs are unchanged. Schema-2 round trips work **with that
  fixture loaded**, not as portable saves for the ordinary catalogue.
- Lab input is disabled and no player save is written. Workshop stations use
  existing station and crafting rules, provisioned directly for the fixture.

## Reproduce

Rebuild the GDExtension after simulation or binding changes. From the repo root:

```powershell
cmake --build build/gdext -j 4
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Landforms
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Workshop
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Props
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Octagon
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Checks
```

Use one mode switch per invocation. With no switch the helper regenerates the
first surface comparison. Open `build/codex-aesthetic/index.html`; screenshots,
manifests and logs stay ignored in `build/`. The checked-in HTML is the source
template. Every engine invocation is externally bounded to 55 seconds.

For ordinary gameplay with faceted surfaces on the normal world generator:

```powershell
& C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe --path game -- --faceted-look
```

This also enables the frontier terrain material; it does not enable the
fresh-world contour profile. Ordinary gameplay retains its ordinary save
controls. Omit the flag to restore cubic presentation.

## Tuning

The [contour fixture](../../game/experiments/landform_profile.json) gives every
control a plain-language purpose. Normal `worldgen.json` is unchanged.

| Control | Normal / fixture | Purpose |
| --- | --- | --- |
| Base height | 12 / 7 | Offset increased relief toward the existing valley elevation |
| Height scale | 10 / 20 | Stronger rises and hollows |
| Height frequency | 0.02 / 0.025 | Slightly closer hills |
| Height octaves | 3 / 3 | Retain three detail scales |
| Height warp metres | 0 / 24 | Bend contours sideways in noise space |
| Height warp frequency | 0.018 / 0.018 | Breadth of the contour bends; positive, finite |
| Corner floor fixture cost | 1 | Placeholder per triangular slab; no accepted economy tuning |

Warp amplitude must be finite and non-negative. The existing frontier palette
and cover controls remain in `game/art/frontier_look.tres`. The faceting method
has no new gameplay tuning. Roof height, framing and colours are scene-study
geometry, not a newly introduced player progression system.

## Validation and limits

- GDExtension rebuilt; C++ **4,627 checks, zero failures**, including corner
  orientations, precise shelter queries and repeatable contour generation
  with resource/gate guarantees on seeds 1, 7 and 29.
- Existing Godot suites: unit **397**, art **11**, integration **265**, horde
  **43**, grammar **68**, feel **17**, zero failures; **120-frame** main smoke.
- Faceted terrain: **50 checks, zero failures**. Actual collision rays select
  the correct editable voxel; excavation updates four chunks at a corner,
  leaves matching seam vertices, changes burial checks and restores exactly.
- Workshop: **632 headless / 635 windowed checks**, zero failures. Placement,
  corner collision, roof leakage, existing forge fuel/crafting, chest contents
  and piece/station save restoration are exercised.
- Original octagon: **243 headless / 245 windowed checks**, zero failures.
- Fifteen landform screenshots and separate prop before/after captured;
  workshop exterior, cutaway and interior inspected in the actual renderer.

The inherited unit-fixture off-tree and dummy-renderer diagnostics remain as
documented in the first report; the suite succeeds and no assertion is weakened.
Other review modes reject engine errors as well as script errors and failures.

These are automated probes and fixed-camera captures, not a full movement or
combat playtest. Foliage and resource strips may intersect or float near the
rounded edges away from their preserved anchors. Complex excavated caves and
navigation need longer play before default adoption. Building still uses voxel
occupancy, so visually empty slivers do not become newly available build cells.
Geometry counters are not GPU timings or performance acceptance.

Recommended review: walk, dig and build on the faceted candidate; judge the
workshop's thick walls at eye level. If that silhouette is wanted, the next
bounded construction step is a usable roof/transition palette. Thin diagonal
walls and diagonal doors still require their own design decision. A distinct
tree silhouette pass remains outstanding; the face repair did not provide it.
