# LAND-02B: environment foundations and Scarwater production

**Owner-selected corrective production, before LAND-03.** On 16 September the
owner accepted the visual-pipeline diagnosis and said: “Yes can we go ahead with
those suggestions. If we need to spend substantial time getting it right either
through generated assets or maths/Dev work for collisions and world building,
do it.” This authorises substantial focused asset and engineering work to reach
the selected look. It supersedes treating Scarwater's central visual shortfall as
end-of-wave polish. It does not authorise an exhaustive verification wave.

Workspace: `D:/Wroughtwild/work/land02b-scarwater-art`

Branch: `codex/land02b-scarwater-art`

The owner starts this separate session. Coordinator prepares/integrates; no
automatic worker launch. This is implementation and art production, ending in
ordinary playable seeded worlds. Do not return another planning-only assignment.

**Further owner emphasis:** examine whether early choices in the base Godot game
implementation have limited every biome. The owner explicitly invited this thought
without interrupting progress. Start at the shared terrain/rendering foundation
and fix demonstrated limits there; Scarwater is the representative playable proof,
not a restriction to adding more biome-specific dressing. Necessary shared
foundation changes are in scope, with old-profile compatibility kept explicit.

## The outcome to deliver

Create a convincing Scarwater environment whose dominant forms and composition
substantially approach the approved [concept and annotated layout](land00-visuals-2026-09-16/README.md).
The target is a recovered, inhabited-feeling place that inspires exploration and
a home. The [LAND-02 pictures](land02-scarwater-result-2026-09-16.md#actual-game-pictures)
show useful gameplay but an inadequate visual foundation: broad mesa-like walls
and regular bands, thin repeated crowns, bare transitions and a wire-like light
seam. Those are the problems to solve here. Functional completion cannot stand
in for visual completion.

Deliver these three connected player-height experiences:

1. **The reveal:** foreground trees/rooted bank frame a lake and an unmistakably
   displaced, broken rock skyline. Large angled faces, interrupted ridges, deep
   joints and recovered ledges create depth at landscape scale. It reads as
   fractured rock even with mineral colour and emission removed. The home shelf
   and old smithy are legible destinations within that composition.
2. **The close encounter:** a substantial dry fissure has irregular real lips,
   walls, a visible floor, readable walkout/contact and recessed White energy
   within cracks. The old smithy and braced vegetation echo the displacement.
   The player reaches and uses the existing finite pressure opportunity.
3. **The home:** one quiet dry setting has a compelling outlook, connected low,
   middle and canopy layers, believable ground/root/shore joins and space for
   paid building. Quiet ground looks intentional. The sheltered alternative and
   the remaining home choices continue to work.

Do not dilute this into small texture changes or more scatter. Photographic
identity with an image is not required; recognisable large forms, surface depth,
coherent habitat, lighting hierarchy and useful space are. The concept is a
design target, not a fixed terrain stamp or an actual game screenshot.

## Required reading and current facts

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md`, then its required
foundations. Read `build/land02b/SETUP.md`, this brief, [world premise](../world-premise.md),
[selected LAND plan](landscape-biomes-influences-plan-2026-09-16.md),
[four-force reference](land00-influence-generation-reference-2026-09-16.md),
[pipeline diagnosis](land02-visual-pipeline-diagnosis-2026-09-16.md) and
[LAND-02 result](land02-scarwater-result-2026-09-16.md). View concept/layout 01/02,
the colour/host boards, relevant original owner references and the retained game
pictures. Do not spend the session making another aspirational full-scene board.

V9 is already published on main through `1f03247` / `4113c8b`, adoption `d496739`.
Its paid source/use, walking and Continue evidence is reusable for unchanged
behavior; its aesthetic ambition remains unmet. The existing kit was entirely
scripted Blender geometry, not image-to-3D. No evidence establishes a local-model
or engine ceiling. The ridge's broad height functions and shader bands are known
causes of its current appearance. Read only the relevant production/native paths.

## Lore and world constraints

Random/chosen-seed generation remains fundamental. White **Impulse** displaces
eligible rock and loads/braces living hosts; colour reinforces the physical
effect. The underlying country, influence direction, ridge arrangement, habitat
and routes vary by seed. Same seed plus immutable saved profile repeats. Assets
and relationship rules may be deliberately authored; the shipped place cannot
be a coordinate-locked showcase.

Keep the years-after recovery: established earthy vegetation, old damage and
concentrated remaining force. Most growth is unlit. The smithy predates an
accidental impact/source intersection. Do not invent meteor origins, intentional
ancient alien installations or new resource/combat rules. The ordinary finite
pressure owner remains separate from LF White mineral/request semantics. No LF
source/device adoption, new biome or creature replacement is part of this pass.

Keep existing source stock/costs, ordinary campaign, opening protection, four
radius-14 m home cores, finite/rare ownership, lake rules, cave access, excavation
and paid construction. A compelling environment is the purpose of the technical
work; a new general terrain framework, larger/infinite world or engine migration
is not the selected objective.

## Production method: make the missing forms

### First: resolve the shared environment foundation

Answer the owner's base-implementation question with a short source-backed
decision record and working geometry early in this same production task. The
coordinator has identified these actual starting points:

| Layer | Current choice, not an assumed Godot limit | Required production question |
| --- | --- | --- |
| World data | A full 3D block field, with one-metre cells and integer column heights; caves already exist | Which game/ownership/digging semantics should stay at cell scale, and where can the visible/contact surface gain the detail or structure the art needs? Do not misdiagnose the whole world as a purely 2D heightmap |
| Surface extraction | Native `build_world_chunk` averages solid/air edge crossings and gradients; V9 shallow unbroken roofs use averaged heightfield corners, with voxel paths around edits/caves | Are sharp angled faces and fracture joints being lost by field generation, sampling or normal/surface smoothing? Demonstrate an actual wedge/joint and fix the responsible stage, preserving contact/picking |
| Near/far terrain | Exact nearby chunks plus a coarse horizon and masks/skirts | Can the intended landmark silhouette and joins survive distance transitions? A detailed near asset cannot compensate for a wrong far silhouette |
| Materials/presentation | Surface-kind palette, world-space material layers and constrained normal/roughness treatment; LAND-02's bands change appearance rather than landmark geometry | Does the shared material/lighting pipeline support the needed rock/bark/soil response and readable depth? Fix genuinely shared constraints before adding another specialised colour layer |

Inspect the relevant native-to-Godot path, render settings, material/export path,
collision and edit mapping only as needed for these questions. Identify what can
be retained, what must change and why. Use Godot's established facilities where
appropriate; do not infer engine incapability from our custom implementation.
Do not automatically turn a one-metre gameplay grid into a one-metre visual-detail
ceiling. Also do not assume that increasing global resolution fixes composition
or materials. Exact algorithms are routine choices within this authorised work;
preserve old saves and costs rather than seeking repeated permission for them.

Deliver the chosen implementation with the scene. Record it concisely in
`docs/prototype/land02b-environment-foundation-2026-09-16.md`, including the concrete
visible limitation, source location, chosen change, render/contact/edit ownership
and reusable consequences for later biomes. Avoid a generic project audit or an
open-ended architecture report. Proceed directly from that diagnosis to production.

### A. Establish a real asset route

Use the existing image-to-3D installation on one bounded fractured-rock or root
candidate early, unless a retained equivalent asset already demonstrably supplies
the needed form. Generate an isolated asset input with the built-in image tool
when useful; apply its current skill. A whole landscape image is not an asset
extraction input. Inspect the generated mesh and material in Blender, including
its silhouette, useful faces, hidden side, ground joins and real scale. Make a
specific judgement about what needs sculpting, rebuilding, UV/material work or
replacement. Do not infer quality from the input image or triangle count.

The established local route is documented in [ART production process](art07-production/PROCESS.md)
and the [TRELLIS local record](../art/leyline-studies/2026-09-08/wolf-image3d/trellis-local/README.md).
Use those for actual CLI/model paths, GPU coordination and export mechanics only.
Their historical hash/review/package requirements do not supersede current
prototype limits. Reuse installed models from C: and write output to this D:
worker; do not copy or reinstall the bundle. One GPU job at a time, preserve peer
processes. No model bake-off or new external service is requested.

Then choose the production method that actually supplies the form: generated
starting mesh plus Blender cleanup, directly authored Blender geometry, or a
carefully designed procedural model. Scripts are allowed, but procedural output
must undergo shape/material/composition iteration. Repeating the old slab/tube
recipes with higher counts is insufficient. If local generation fails or produces
poor topology, continue useful direct authoring/engineering; report the limitation
without treating that tool as mandatory for every asset.

### B. Build three substantial assemblies, not a large catalogue

| Assembly | Required structure and material work | In-game role |
| --- | --- | --- |
| Fractured cliff/ridge | Large leaning/offset planes, wedge separations, broken tops, irregular bedding thickness, sheltered ledges and basal rubble. Begin with roughly 12–25 m-tall controllable sections spanning 8–20 m, composed into the existing larger ridge envelope; these are tuneable art scales, not guaranteed geometry. Use several major masses with different silhouettes instead of one smooth wall covered in stripes | Carries the skyline and middle-distance depth. Rock form must occupy the scale seen in the reference; small 3 m stones cannot do this job |
| Gallery tree/root/bank | A convincing irregular canopy volume, readable trunk/branch hierarchy, rooted ground contact and a deliberate root-bank/understorey transition. Preserve harvestable tree yields/ownership; roots/dressing do not create stock. Develop one excellent assembly and a purposeful contrasting silhouette, rather than multiplying near-identical crowns | Frames the reveal and shelters the home/route. Broad canopy masses and negative space matter more than adding individual leaf triangles |
| Fissure wall/lip/interior | Interlocking fractured edges, recessed channels, contact debris and readable mineral depth. White light travels within actual structure; it is not an exposed wire or a painted stripe. Keep usable floor/exits and the pressure work position clear | Close-range proof that lore, geometry and gameplay describe the same place |

Author material response alongside shape: rock/bark base colour, roughness and
normal/detail treatment where useful, consistent texel scale, restrained mineral
variation and credible soil/moss/root transitions. Prefer reusable material sets
and deliberate blends to baked illumination or flat vertex colour alone. Retain
editable masters/reproducible recipes and selected game exports. A beautiful
Blender render alone does not close an assembly; inspect it under game lighting.

### C. Compose lighting, water and growth together

Match the reference's hierarchy: a sheltered foreground, readable middle planes,
distinct distant silhouette and useful light on the route/home. Tune existing
day/era-compatible environment and materials; avoid crushing shade or flat global
brightness. Improve shore/water response within the fixed-lake system where it
materially affects this scene. No weather system or fluid simulation.

Resolve transitions at the actual scale of the camera: cliff foot to soil,
trunk/root to bank, bank to shallow water, and quiet home edge to undergrowth.
Use continuous masses and intentional openings. Inspect the scene without bright
emission once during normal iteration to establish that forms carry the effect.

## Terrain, collisions and editable-world engineering

Substantial targeted mathematical/native development is authorised when the
present height/meshing approach cannot carry the required forms. Do not silently
reduce the reference to the old terrain representation for implementation ease.
Conversely, do not adopt a new general engine/framework before demonstrating the
specific shape/contact need in this place.

Use **`frontier_v10`** for changed physical geography in this corrective slice,
with separate immutable inputs and normal New World selection. Preserve V1–V9
and LF Continue; do not reshape saved V9 terrain or overwrite owner saves. The
later LAND-03 draft must use the next unpublished profile (expected V11), not
reuse V10. Save identity is selected now, not a question to reopen.

Investigate and implement one coherent representation for the large fractured
mass and its edits. Begin from the current native voxel/roof mesh and explicit
fracture planes/volumes; retain controllable sharp edges and deliberate angled
surfaces rather than globally smoothing everything. Local refinement, different
surface extraction or deterministic detailed terrain modules are allowed if
needed, with their cost and save/contact implications documented. Choose a
bounded local solution; avoid increasing resolution across the entire 1 km world
just to improve this ridge. The particular algorithm is a production choice to
settle through the first working geometry, not a separate research assignment.

Whichever representation is chosen must satisfy the same contact contract:

- Walkable surfaces and obstacles agree with the visible substantial forms.
  Render and collision use the same surface description, or a documented close
  approximation with no visible floating, clipping or phantom barriers.
- A terrain hit maps to the actual editable owner/cell/region. Digging changes
  visible and collision geometry together and removes unsupported details;
  Continue reconstructs those edits deterministically. Do not conceal opaque
  terrain behind a fake hole or leave an uneditable cliff shell over removed land.
- Paid floors/stations use the same support/contact understanding and retain
  exact ownership. Do not add no-dig/no-build exceptions to make art fit.
- Native cave openings, lake original beds and dry exits remain honest. Large
  fractures must not become unintentional one-way traps or invalidate both paths.
- Chunk boundaries and near/far presentation retain matching silhouettes and
  do not leave visible cracks or popping walls. Prepare/reuse shared resources
  at entry; rebuild only affected geometry after edits. Do not add full-world
  mesh/collision rebuilds in active movement callbacks.

Core source leads: `sim/src/worldgen_frontier_v9.inc`, profile dispatch and tuning,
`sim/include/wroughtwild/worldgen.h`, bridge surface/corner/collision/picking in
`game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp`, engine `terrain.gd`,
`terrain_chunk_stream.gd`, LAND-02 art/cover/shaders and current build/ownership
paths. Source inspection follows a specific shape/contact problem. Changed native
code requires a matching DLL built against the existing local Godot ABI.

## Work milestones and visual completion

These are production milestones within one worker, not separate approval gates:

1. **Foundation, hero form and contact:** resolve the demonstrated shared
   representation/rendering limits, then produce a substantial cliff/fissure portion and a
   tree/root asset through the selected pipeline. Put them into the ordinary
   generated scene early. Resolve the main shape/contact risk while their scale
   and construction can still change.
2. **One convincing ordinary scene:** finish major geometry, materials, framing,
   habitat joins and lighting around the reveal, scar and home. Show actual game
   images during progress. Name the largest mismatch to the reference and revise
   it. Existing V9 captures are diagnostic evidence, not the new quality target.
3. **Reusable seeded production:** carry the proven forms/relations into the
   ordinary generator. Inspect one contrasting seed to establish meaningful
   variation of silhouette, enclosure, routes and outlook. Preserve the play loop
   and refine the result in the game, including close contact and distant view.
4. **Delivery:** finish changed-state checks, retain the useful assets/evidence,
   commit and return the playable result with specific remaining limits.

The owner explicitly accepts substantial production effort. Do not impose an
arbitrary short execution deadline, stop at the first generated candidate or
declare success because a procedural asset file and functional tests exist.
Viewport inspection, targeted re-authoring and geometry iteration are part of
making the requested environment. They are not a reason to start an exhaustive
verification matrix. No recurring timer, automatic continuation task or new
agent session is requested.

At completion, an ordinary game picture must visibly demonstrate broken angled
rock masses at landmark scale, a convincing rooted canopy composition, a deep
structured scar and connected ground/material transitions. If the dominant view
is still a striped mesa, generic repeated trees or a luminous line on a plain
floor, continue the authorised production work. Do not move those central failures
back into LAND-05 cleanup. Smaller local irregularities can remain documented.
If an actual tool/technical blocker prevents completion, state that outcome as
incomplete with concrete evidence and what must change; do not claim visual
success or substitute another concept image.

## Focused checks and handoff

Name the concrete risk and default to three focused verification jobs on one
renderer, Forward+, reusing unchanged LAND-02 evidence:

1. Targeted new-profile determinism, protected geography and actual rendered/
   collision/picking consistency for the changed representation. Use the
   representative and one contrasting seed, not a seed/asset/camera matrix.
2. A short actual New World use route: reveal, both routes, near-wall/fissure
   contact and exits, existing paid pressure use and home placement. Inspect
   appearance and resource first use. No broad performance benchmark gate.
3. Targeted edit/Continue: cut the new representative surface, confirm visual/
   collision/support updates, retain a paid build and consumed finite source,
   restore them exactly, and reuse or run the specific old-profile check needed
   by changed dispatch. Never use the owner's live save.

Keep background Blender/generation jobs and verified no-mouse-capture/non-focusing
rendered checks; retain process handles and BOM-free overrides. Stop owned
processes at handoff. Reuse current tools and models. No package reconstruction,
parent rehash, all-master reopen, renderer matrix or old ART R9 review.

Commit source, selected runtime assets and material maps, recipes and explained
tuning. Keep editable masters on D: with exact retained paths and provenance;
do not commit private saves, build products, DLLs or caches. Write
`docs/prototype/land02b-scarwater-production-result-2026-09-16.md` with achieved
appearance/play first, remaining limits, methods actually used, terrain/contact
design, seeds/profile, checks, matching DLL/master paths and checked SHA.
Retain a small selected set of actual ordinary game pictures in
`docs/prototype/land02b-evidence-2026-09-16/` and show them directly in chat.
Include a comparison of major reference qualities and actual achievement; a
list of implemented features alone is insufficient.

Update coordination briefly. Coordinator handles main adoption and normal push;
routine production/integration is already authorised. Stop after LAND-02B.
LAND-03 remains queued after this result; no subsequent worker starts automatically.
