# LAND-02: make Scarwater Basin a real playable place

**Selected implementation task, 16 September 2026. Owner starts the separate session.**

Workspace: `D:/Wroughtwild/work/land02-scarwater-basin`

Branch: `codex/land02-scarwater-basin`

Base and local tools: `build/land02/SETUP.md`.

Act as Wroughtwild's environment artist, world-generation engineer and gameplay implementer for this one complete place. This follows the approved LAND-00 direction and completed [LAND-01 implementation plan](landscape-biomes-influences-plan-2026-09-16.md). Do not repeat creative discovery or ask again whether random generation, the direction, the first biome or ordinary-game integration are wanted.

## What the owner wants to see and feel

The owner says the current game feels like a bare sandpit with sporadic assets. They want a distinctive, visually ambitious **video-game world**: meaningful terrain, strong silhouettes, coherent vegetation, living fauna, places worth exploring and settings that inspire a home. Magic and technology must visibly arise from the lore and shape generation, rather than being attached as coloured decorations after the map is finished. “Go big and graphically awe” applies to the visible outcome, not unlimited scope.

Deliver **Scarwater Basin**, a reusable family of ordinary seeded compositions. A long ridge displaced by an old glancing impact rises above a fixed lake. Gallery Woodland follows recovered banks and swales. A deep, dry living fracture cuts through exposed rock beside a partly damaged old smithy and its existing finite pressure opportunity. A sheltered woodland approach and an open outlook approach connect the reveal to the work site. A scenic dry expansion shelf and a sheltered grove invite different bases. They are two of the four existing home cores, not new compulsory plots.

The place must work from arrival to discovery to source use to paid home building. Terrain, substantial authored forms, ground/plant joins, useful quiet space and gameplay belong in this slice. A greybox, larger scatter pass, isolated asset gallery or showcase-only scene is incomplete. Build and inspect one ordinary generated scene early; improve its dominant weakness before expanding seeded coverage.

## Read first, in this order

1. Current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md`, then its required reading order in this checkout: README, DESIGN, decision registry, vertical slice, acceptance criteria and relevant specifications. Current prototype corrections outrank old exhaustive checks/packaging instructions.
2. `build/land02/SETUP.md`, this brief and the [selected plan](landscape-biomes-influences-plan-2026-09-16.md). LAND-01 is completed; older held/proposed prompts are historical.
3. [World premise](../world-premise.md), [four-force generation guide](land00-influence-generation-reference-2026-09-16.md) and the selected direction/source boundaries in [LAND-00](land00-creative-discovery-result-2026-09-16.md). Follow primary-source research only if it answers a specific production question; no new research wave.
4. View all four PNGs in `docs/prototype/land00-visuals-2026-09-16/`, with their README caveats. Also inspect the three actual RF-09 PNGs in `docs/prototype/rf09-evidence-2026-09-16/` and the [owner's landscape references](../art/references/environment/2026-09-14-reclaimed-frontier/README.md). Concepts are targets, never actual-game evidence or exact terrain stamps.
5. Relevant current [world-generation specification](../systems/world-generation.md), ordinary pressure rules and current entry/save paths. Follow the source leads below only where needed.

## Lore and generation rules

- Keep random/chosen-seed terrain. Same seed plus saved profile reproduces geography; different seeds change underlying country, orientation, shape, biome extents, approaches and home outlooks. No screenshot-coordinate scenery.
- Select influence and eligible host before final landform/habitat composition. White **Impulse** expresses force/displacement; Red **Excitation** activity/accumulation/release; Blue **Retention** holding/preserving; Green **Propagation** branching/spreading. Geometry and host relationships carry identity, with colour reinforcing it.
- Implement **White-led Scarwater only** in this slice. Gallery Woodland is the first new ecological biome. The other force contracts guide extension, not four immediate implementation assignments. Do not permanently map each biome to one colour.
- It is years after the meteor catastrophe. Established recovery, quiet unlit growth and concentrated deep pulses coexist. The old smithy predates an accidental impact/pressure intersection. Do not invent meteor senders, dates, intentional ancient reactors or new lore to explain a mesh.
- Reuse appropriate adopted ordinary fauna with current behavior/rewards in woodland, shore and clearings. White stag host behavior and LF material/device adoption come later. No roster-wide colour variants or new combat powers.
- The ordinary finite pressure owner is separate from LF White mineral/request mechanics. Preserve current paid recipes, source work, stock and return value. Decorative light is not stock, loot, power or damage.

## Implementation scope and source leads

**New ordinary geography:** introduce `frontier_v9` and its separate immutable tuning/composition. Make it the default for ordinary New World random/chosen seeds. Preserve all old Continue identities and saves, V1–V8/LF generation inputs, ordinary campaign/progression, opening supplies/safety, four radius-14 m homes, lake behavior, caves/digging, finite/rare stock and paid construction. No migration or overwrite of owner saves. Future published terrain changes receive a new profile.

Inspect profile and tuning declarations/loaders, `sim/src/worldgen_profiles.cpp`, `sim/include/wroughtwild/worldgen.h`, V8 composer/landscape/lake and ordinary pressure composition. Reuse their useful algorithms through an isolated successor path. Add only the minimum shared place/typed-host metadata that links cause, landform, habitat, source, routes, homes and views. No general ecosystem framework or full four-channel map simulation. New ecological biomes must not accidentally alter discovery-region/rare-site counts or progression requirements.

**Do not miss profile guards.** `sim/src/contraptions.cpp` explicitly guards pressure ownership by profile; V9 must retain ordinary pressure support without enabling LF coloured components. Native bridge geometry/export, engine terrain/scenery selectors, entry/seed controls and `save_manager.gd` also use named profiles. Audit these specific V8 gates for successor eligibility; do not replace every historical profile check indiscriminately. Include V9 in the corrected surface-mesh path consistently across rendering, collision, sampling and picking.

**Real depth:** implement a native open dry slot/ravine outside original lake contact and cave openings. Start near 4–8 m wide, 2–4 m deep, 14–26 m long, with a visible floor and walkout ends compatible with current traversal. The whole basin can start around 280 m across/24 m relief within current 1,024 × 1,024 × 96 extent. Tune these design defaults for the scene; do not force concept proportions. Existing `leyline_fissures.gd` is cosmetic surface dressing and cannot supply this physical recess alone.

Resolve mesh/collision/contact in the first scene. Walls/lips must meet the cut rather than float or conceal an opaque terrain face. Digging removes/refreshes unsupported dressing; paid structures clear or occlude decoration normally. No hidden floor, separate uneditable collision landscape, fake hole or no-dig workaround. Preserve real lake exits and legitimate cave access.

**Seed composition:** build the plan's dependency order, route/view reservations and deterministic bounded fallback. Vary landform proportions/offset, lake aspect and bank, woodland bands and approach/home relationships. Guaranteed payoff survives fallback. A second seed must look like another place produced by the rules; rotation/prop jitter alone is weak variety. Keep the original one fixed lake, three discovery regions and five rare sites.

**Art and atmosphere:** author the small substantial kit from the plan: displaced strata/fracture forms, irregular lips/joins, inset restrained pulse, two tree silhouettes/root banks and a connected middle-growth family. Reuse RF ground/litter/plant materials, adopted fauna and actual smithy/stations where suitable. Fix silhouette and composition before filling gaps with repeated clumps. Preserve value separation in shade and visible low/middle/canopy layers. No new paid service, dependency, engine migration or whole-roster replacement.

Store editable masters or reproducible recipes and selected exports with source/provenance notes. Large production output belongs in this D: worktree. Prepare/reuse shared art resources during actual world entry, not first encounter. Follow the existing native build approach and produce a matching DLL for this checkout when native sources change; do not test changed C++ against an old DLL.

## Work order and completion

1. Briefly restate the visible result, affected boundaries and routine assumptions. Implement the successor entry/generation/place data and first real terrain cut as part of this slice; do not publish an infrastructure-only substitute.
2. Create one representative ordinary seeded basin with first-pass substantial kit, lake/woodland transitions, source approaches and home ground. Capture an actual player-height view early. Inspect it, identify the dominant visual gap and revise within the task.
3. Finish the small kit and coherent habitat placement. Carry the same force through offset rock, scar and braced roots. Reserve meaningful sight openings and usable margins. Use the second seed to test the composition rule, not to start an exhaustive matrix.
4. Complete ordinary source/paid-building use, edit/Continue integration, focused checks and selected game pictures. Normal New World must reach this work without a special showcase flag.
5. Commit checked source/art/docs on the worker branch. Return the result and matching native output details to this coordinator. Stop after LAND-02. Do not merge/push main, launch subsequent sessions or implement Dry Steppe/LF adoption.

Success must be stated in player terms: the approach reveals a recognisable displaced landscape; the woodland feels connected to banks and water; the scar has real depth and usable contact; the work site supplies an existing useful action; both home settings suggest a build and can accept paid construction. The same effect remains readable without depending on bright emission. Report what is achieved and what remains weak honestly. Passing technical checks does not establish the requested aesthetic result.

## Focused verification and comfort

Name the concrete risk before checking. Default to at most three focused verification jobs on Forward+, with the early scene inspection incorporated into development rather than a camera matrix:

1. **Generation/ownership risk:** targeted successor determinism, valid bounded composition/fallback, dry routes/home support/cave-lake separation and ordinary pressure identity. Use the representative seed and one contrasting seed; exercise a specific fallback case if needed, not broad seed enumeration. Reuse existing immutable-profile evidence and check only changed dispatch/guards.
2. **Actual-use/visual risk:** short normal New World entry including first use, walk reveal/approaches/scar exits, use pressure through existing paid mechanics, and place a paid floor/station at a home. Inspect player-height form, shade, ground joins and source readability. Keep roughly three useful actual-game captures covering reveal, scar/work site and home; a second seed overview can replace a redundant shot.
3. **Restoration/edit risk:** one targeted Continue with a terrain edit, paid placement and changed finite pressure state; ensure correct saved geography, stock, support refresh and collision. Add the relevant existing old-profile restore case only where changed code justifies it. Use isolated test saves, never the owner's live save.

Build/import as needed for the changed native/art work. No benchmark gate, both-renderer matrix, all-profile replay, parent-package copying/hashing, sealed release or recursive review. There is no hard ten-minute stop for routine completion. Keep checks focused and reuse applicable evidence. Report unavailable hardware/owner playtesting as limits, not new gates.

Use background art jobs. Rendered tests must use the verified test-only mouse-capture opt-out and a non-focusing window where supported; hidden launch alone is insufficient. Reuse corrected BOM-free UTF-8 override/process handling from current launchers. End owned test processes before handoff.

## Required handoff

- Commit source, useful runtime assets/recipes, tuning with plain-language purposes and affected specifications. Do not commit caches, DLLs, private saves or generated packages.
- Write `docs/prototype/land02-scarwater-result-2026-09-16.md` with achieved player experience first, appearance and functional results separately, seeds/profile used, source/DLL provenance and exact local artifact paths, checks actually run, remaining issues and checked SHA.
- Retain selected actual game PNGs in `docs/prototype/land02-evidence-2026-09-16/`; display useful images directly in chat and label them as actual gameplay. Concepts stay labelled separately.
- Update the coordinator sheet briefly. Carry non-blocking additions to this wave's closeout; do not reorder the next slice. A concrete inability to deliver the selected playable behavior needs attention now; speculative risks and unrelated polish do not.

The owner has selected this direction and ordinary integration. Routine implementation choices, art iteration, checked commits and preparation need no repeated approval. The coordinator handles main adoption/push after this worker returns. No follow-on task starts automatically.
