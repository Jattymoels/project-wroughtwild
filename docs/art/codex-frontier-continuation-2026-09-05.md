# First-person presence, habitat, landmarks and equipment comparison

Owner-approved four-part continuation, 5 September 2026.
Implemented by **Codex (OpenAI)** from `5959cbb` on local main.

## Outcome and scope

The owner approved all four proposed follow-ups after noting that the world
remained barren above grass height. This pass covers first-person presence,
environment variety, recognisable places and equipment comparison. It follows
the revised D-013 weathered frontier direction and existing interface/item
rules. No new game rules, progression rewards, resource economy, external
assets or save fields were introduced.

First-person gloved hands now sway with actual travel, gesture when an existing
skill spends its cooldown, and recoil on confirmed hits. Physical strikes,
cones, projectiles and dash use different poses; cold/fire casts briefly show
their established colour. Refused casts do not restart a gesture. Hands hide
in third person, build mode, death and interaction panels. Two wrist-lane rays
withdraw them near solid walls. All movement is on visual children: camera,
body, aim, damage and cooldown timing remain owned by the existing systems.

Habitat patches add pointed-leaf shrubs, pinnate fern beds, short rotten
deadfall and rooted stumps. Deterministic patch noise creates groups with
open ground between them. Meadow ferns are less frequent than forest/fen
ferns; the wastes receive only woody debris. Four footprint samples reject
steep or unsupported locations, and roots follow the actual rendered/collision
surface. Spawn, resource work areas, gates and landmarks have clear space.
Chunk rebuilds regenerate cover from the edited surface without saved
decoration state. Shared meshes and per-chunk MultiMeshes bound draw overhead.

Default seed 1 contains **562 clusters**: 237 shrubs, 269 fern beds, 20 short
deadfall pieces and 36 stumps. Its densest chunk contains 20. The rotten debris
is small, non-colliding and decorative; harvestable wood remains in existing
resource trees. This avoids silently adding another wood source.

The existing cairn, drowned altar and ember rift gain chamfered, uneven stone
edges and distinct socket/radial/fault inlays. Trees within 6.5 m become bare
snags to open site sightlines. Their saved IDs, anchors, harvest work, wood
yields, felling and collision stay intact. Existing landmark locations,
curio interactions, rewards and collision footprints are unchanged. These
are improvements to the existing three site designs, not additional POIs.

Carried plain and rolled equipment cards now offer Compare. A native read-only
view resolves a copied equipment set through the same stat and modifier
functions used during play. Current and candidate cards retain implicit and
rolled modifiers, active breakpoints and held-back tiers. The table shows
life, armour, both resistances, area bonus and changed known-skill payload,
cooldown, reach, projectile count and pierce. Payload is per hit before enemy
defence, critical rolls and trial boons; it is not DPS. Conditional effects
remain visible as item-card sentences. Equip candidate is explicit and
revalidates the candidate before using the existing equip/return-to-pack rule.
Both pack and comparison panels were centred correctly and checked at 720p;
comparison also has a 1080p capture. Scrollable content leaves back/equip usable.

## Presentation controls

All resources use documented script exports, with defaults loaded by their
matching `.tres` files. Geometry offsets are authored mesh/pose proportions.

| Resource / controls | Default | What the player sees |
| --- | --- | --- |
| `first_person_look`: `hand_position` | (0.24, -0.25, -0.43) m | Wrist placement beside the crosshair |
| `strike_seconds`, `cast_seconds` | 0.28 / 0.36 s | Gesture recovery after the real cast instant |
| `impact_seconds`, `impact_recoil` | 0.09 s / 0.018 m | Short hand response to a landed hit |
| `stride_sway` | 0.009 m | Restrained hand bob while walking |
| `wall_reach`, `wall_margin` | 0.95 / 0.08 m | Withdraw before hands cross nearby solid geometry |
| `sleeve_colour`, `glove_colour` | #444a3c / #65513b | Worn olive cloth and brown leather |
| `habitat_look`: `patch_metres`, `patch_threshold` | 18 m / 0.08 | Breadth and scarcity of habitat patches |
| `shrub_density`, `fern_density` | 0.075 / 0.16 | Per eligible cell chance at full patch strength |
| `deadfall_density`, `stump_density` | 0.008 / 0.008 | Occasional woody remnants |
| `clearing_metres`, `resource_clearance` | 10 m / 2 cells | Open spawn and resource work areas |
| `max_rise`, `visibility_metres` | 0.3 m / 75 m | Reject uneven footprints; fade distant cover |
| `shrub_green`, `fern_green`, `bark`, `rot` | #3b4a2c / #4e6340 / #40362c / #6d6750 | Muted leaves and decayed wood |
| `landmark_look`: `bevel_fraction` | 0.14 | Broken/chamfered stone corners |
| `canopy_clearance_metres` | 6.5 m | Bare resource trees around existing sites |
| `stone_colour`, `drowned_colour`, `rift_colour` | #626455 / #45584f / #27262b | Distinct site stone palettes |
| `inlay_colour`, `cold_inlay` | #a38b52 / #84a8a0 | Restrained warm socket and cold altar detail |

## Verification and reproduction

The native GDExtension rebuilt successfully. The full headless pipeline passed:
unit 397, art 11, integration 265, horde 43, grammar 68, feel 17, faceted terrain
66, traversal 23, roof workshop 768, woodland 16, weathered save 9,
presentation 29, material transitions 74, creature motion 100, and continuation
82, plus the 120-frame main-scene smoke run. The original unit suite retains
its known off-tree/dummy-renderer exit diagnostics; the other suites were clean.

The **82 continuation checks also passed with the real renderer**. They cover
preview non-mutation and actual stat/cooldown agreement for every equipment
base, rolled modifiers, explicit/stale equip handling, panel bounds and close
lifecycle, committed/refused skill gestures, camera/body invariance, wall
withdrawal, deterministic habitat rebuilding, resource clearance, grounding,
removed support and landmark interaction/collision retention. Headless habitat
checks use retained world placement records because Godot's dummy renderer
does not retain MultiMesh transform buffers; rendered checks read the buffers.

Run from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Checks
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Continuation
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -FieldRoute
```

`-Continuation` renders nine actual Godot images in
`build/codex-aesthetic/continuation/`. The inspection fixture pauses AI and
supplies comparison equipment; it never loads or changes a player save.
The gallery is `build/codex-aesthetic/index.html`. Captures and logs are ignored
generated artifacts, while source fixtures are committed.

The live field route passed all 7 checks: 142.97 m travelled, 32 peak enemies,
26 casts and 49 damage frames, matching the preceding motion pass. On this
RTX 5090 at 1920×1080 Forward+ and a 120 fps cap, walk median/p95 frame intervals
were 7.776/9.378 ms (previous 8.007/9.332), combat 7.672/11.661 ms
(previous 7.541/11.866). Terrain startup increased from 8.530 to 8.902 s,
including 4.854 s for chunks and 3.923 s for resources. These short paced samples
include fixture healing and are not isolated GPU measurements or a balance verdict.

## Limits

Hands remain rigid procedural forms, without held weapon models, articulated
fingers or a bow rig. Wrist rays handle facing walls, not full arm collision
against every side edge. Habitat remains static, non-interactive prototype
dressing; it does not yet clear itself around subsequently placed buildings.
Existing terrain editing removes unsupported clusters. Leaves and branch
silhouettes need further art refinement, and sparse patches deliberately leave
much of the landscape open. Landmark collisions remain coarse original boxes,
with their existing limitations on uneven ground. Comparison shows exact
unconditional values for its listed fields, not a simulation of conditional
damage, trigger chains, trial boons or survivability.
