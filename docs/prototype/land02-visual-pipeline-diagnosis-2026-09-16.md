# LAND-02: why the game is far from the reference

The owner asked why the result remains nowhere near the designs and whether the
limitation is the agent model, design pipeline or local image-to-3D model. This
note answers from LAND-02's actual source and retained pictures. No new renderer,
asset production, model comparison or benchmark was run for this diagnosis.

## Findings, not speculation about tools

**Image-to-3D did not produce this kit.** `tools/wroughtwild-land02/build_kit.py`
constructs all nine exports with scripted tubes, leaf sprays and polygonal slabs.
`game/land02/source.json` and `SOURCE.md` identify this method. There is no evidence
that the local image-to-3D model caused this slice's visual shortfall.

**The reference's main shapes were not built at comparable scale or complexity.**
`sim/src/worldgen_frontier_v9.inc` makes the ridge through broad height functions
and offset segments. `game/land02/ground.gdshaderinc` supplies repeated mineral
bands. The three small strata meshes are stacks of shallow slabs about 3.7 m
across; they do not supply the large angled, fractured faces, broken crowns and
irregular silhouette that dominate the reference. The visible result is broad
mesa-like walls with stripes. Changing plant density or colour cannot solve this.

**Asset construction was procedural approximation, with limited material work.**
The tree recipes create regular branch/leaf patterns and use vertex colours;
the two trees each have 23,398 triangles. The gap is therefore not explained by
polygon count alone. Canopy masses, trunk/root transitions, bark/mineral surface
character and placement hierarchy need deliberate art work. Repetition remains
visible despite variation in individual leaves.

**Lighting and scene composition remain a separate gap.** The target has framed
foreground shade, separated middle/distant planes, convincing cliff/shore contact,
surface variation and stronger water/material response. The captures have a more
uniformly exposed open view and broad simple surfaces. Better individual meshes
would help but would not by themselves reproduce the environment.

**The production/acceptance process let the mismatch persist.** The brief asked for
an early player-height scene and revision of its dominant weakness. The worker
did revise geometry and traversal, but the large visual mismatch remained at
handoff. The coordinator initially proposed filing it under end-of-wave cleanup.
That understates a central requested outcome. Functional integration is useful;
the visual ambition remains unmet, rather than being merely incidental polish.

There is no inspected evidence that Godot or the local 3D model imposes this whole
quality gap. The current terrain representation does make sharp fracture geometry
and terrain/art/edit contact harder. It is a specific engineering constraint to
solve alongside authoring, not proof that the broad simple result is the best
achievable. No alternative agent/model was tested, so attributing the gap to a
model ranking would be speculation. Agent implementation choices and insufficient
visual follow-through are evidenced problems in this pass.

## Recommended correction, not an automatic new assignment

Before expanding environment production, establish one convincing ordinary
Scarwater scene using the same gameplay and generation path. Spend the art work
on a substantial fractured cliff module/group, a properly shaped canopy/root
assembly, and a convincing real fissure wall/lip/interior, with materials and
scene lighting composed together. Keep digging/contact and paid construction
honest. Inspect against the reference from a comparable player-height view and
revise the dominant visible differences before treating the art approach as proven.

Image-to-3D can be evaluated on one bounded rock or root asset if selected for
that production task, with Blender cleanup and actual-game material inspection.
Do not assume installing a different model fixes missing terrain silhouette,
composition or lighting. Direct authored modelling is also a valid route. No
specific replacement model/service or new dependency is recommended by this note.

Once that scene works, carry its forms and relationships into seed-varied rules.
Random terrain remains a requirement; proving an art target in one ordinary seed
does not make the shipped map fixed. The reference's finish should also be mapped
to a realistic game-native target with explicit geometry/material/lighting work,
rather than promising that a short procedural kit will approximate it automatically.

This is a recommendation to correct the production approach before more breadth.
The owner has not yet selected a replacement slice or changed the sequence.
LAND-03's brief exists as a draft; its workspace and worker have not been started.
LAND-02's checked playable work remains adopted. No additional implementation or
new review wave is authorised merely by recording this diagnosis.
