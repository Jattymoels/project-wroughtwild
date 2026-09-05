# Proposed intensives: exploration, progression and expressive building

**Author: Codex (OpenAI), not Claude.**

## Owner steer and implementation update — 5 September 2026

Implementation: `52a54fd` on `codex/aesthetic-experiments` (Codex).

The owner subsequently authorised experiments, prioritising aesthetics and
allowing progression work only if quick. This replaces the priority order
in the original assessment below. It does **not** accept all proposed game
rules or supersede D-013/D-018.

Codex implemented an opt-in surface/ground-cover comparison, corrected
inward-facing procedural props, and built an isolated octagonal room using
triangular block pieces on the existing lattice. The experiment tests actual
collision, enclosure, removal and in-memory save restoration. It confirms
the cheaper block route is feasible for diagonal inner walls, but its empty
half-cell loses shelter and its exterior remains stepped. No default shape
unlock, lattice migration or siege policy was introduced.

See [Codex experiment results and reproduction](../art/codex-aesthetic-experiments-2026-09-05.md)
for current implementation, screenshots, checks and limitations. The original
inspection statements below describe the earlier review at `e8b8d55`, before
these changes.

### Revised recommendations after the response

- The expedition loop already has much of its machinery. Era/source
  eligibility and a fen deposit are bounded slices; proving the interaction
  between exploration and build growth remains the larger pacing task.
  A fixed-session baseline should precede retuning.
- "Facility bypass, never era bypass" is a promising **proposal**, not an
  accepted loot rule. Era filtering alone does not decide how ordinary mobs,
  exceptional rares and trials differ as equipment sources.
- Siege demolition remains unresolved. The response's proposed D-025 reverses
  D-018; it is not a housekeeping fix. No such decision has been recorded.
- Start with block-based chamfers before considering new diagonal lattice
  addresses. The lab now provides evidence of both benefits and limitations.
- Advance aesthetics through a small visual comparison. The current result
  suggests landform silhouettes need attention after surface noise; an art
  policy change should follow review of that evidence.

## Original assessment (before implementation)

**Status: proposal for owner discussion; no gameplay decisions accepted or changed.**
Reviewed 5 September 2026 against `main` at `e8b8d55`.

The requested outcome is a bounded, first-person crafting adventure where
exploration, permanent build growth and architecture reinforce one another.
Eras change the threats across the existing world; trials and exceptional
world encounters provide exciting rewards. Construction should comfortably
support an octagonal home without requiring block-by-block approximations.

My recommendation is to prioritise the progression intensive below, with a
short visual/building feasibility experiment before committing to the larger
architecture intensive. Validate both through the same ambition: preparing
for a trial and returning to improve an octagonal workshop.

**What was inspected and what remains unverified**

- Read the required design, registry and prototype documents, then relevant
  construction, art, world-generation, crafting, itemisation, era and Foundry
  specifications. Traced their current tuning and key implementation paths.
- `project-wroughtwild` is the current main checkout. Git identifies
  `wroughtwild-foundry` as a worktree of the same repository on `wave6/plate`
  at `9fa4b9b`, an older Foundry slice already contained in main. There are
  no branch commits in `main..wave6/plate`. Its working-directory status
  could not be inspected through Git because of its ownership check; no
  global Git settings were changed. This is not an audit of unidentified
  remote game repositories.
- This combines source/tuning review with three captured runtime views.
  After the owner supplied the existing shell workflow, the pinned console
  binary was verified at
  `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe` and a temporary
  scene captured seed 1, era 1, Warden, at 1920x1080. The character was
  stationary and the camera repositioned automatically. This was not a
  hands-on combat/building session or a measurement of progression pace.
- No gameplay code, tuning, saves, dependencies or accepted decisions were
  changed. The capture script passed Godot's syntax check and its windowed
  run produced all three PNGs without reported script errors. The complete
  automated gameplay suite was not run. Pacing conclusions remain
  hypotheses to validate in play.

**Diagnosis: several connections exist, but combat can short-circuit them**

The game already contains a promising material loop: copper and tin surface
in era two, bronze unlocks the arch and better item capacity, and the same
alloy refines Foundry ingots. Fire-setting and heavy impacts working stone
are particularly valuable examples of combat abilities doing useful world
work. These should become the organising pattern for progression.

The following details weaken that pattern:

| Evidence in the current implementation | Likely player consequence |
| --- | --- |
| [Enemy gear rolling](../../sim/src/loot.cpp), `rollEnemyGear`, chooses uniformly from the entire item-base list. Era and elite status change rolled modifier tier, without filtering bases. Three of the fourteen current bases are bronze. [Trial room rewards](../../sim/src/trial.cpp) also select from the complete base list. | An ordinary early kill can supply equipment whose crafting route requires later materials or facilities. A lucky shortcut is intended; unrestricted base selection makes the size and frequency of that shortcut uncontrolled. |
| [World loot](../../data/tuning/world.json) gives most gear-dropping families a 3–6% chance per ordinary kill; current elite prefixes multiply it by three. | That is 3–6 expected gear pieces per 100 ordinary kills, or 9–18 per 100 corresponding elite kills. These are table expectations, not measured hourly rates. Density can turn individually small chances into frequent inventory decisions. |
| Stone Husks always drop 2–4 split stone and sometimes iron; their documented purpose explicitly makes killing them a mining route. Several other mobs also supply ore. | Combat can provide materials, currency, skill discoveries and equipment in the same activity. Harvesting needs a distinctive benefit to compete. |
| The [Improved Forge](../../data/tuning/crafting.json) requires three bog iron. Lurkers drop 1–2 at 60%; Marsh Wisps drop one at 15%. There is no bog-iron harvest node in [world generation](../../data/tuning/worldgen.json). | The geographically specific resource gate is actually a monster-drop gate. It motivates a trip to the fen, but offers little prospecting, extraction or resource discovery. |
| [Foundry sources and refinement](../../data/tuning/foundry.json) award ingots through first kills and useful-work milestones. Recasting costs one bronze or steel ingot at a basic forge, subject to era. | The connection to crafting is real, but the material investment in a major Foundry improvement is small. The plate can feel like a talent screen progressing alongside the workshop. |
| [Crafted rarity](../../sim/src/economy.cpp) follows skill level; wrought chance is 15% at Blacksmithing 4 and 30% at 5. Gear roll tier follows era. | Repeated common-input crafts can deliver high rarity without discovering a special ingredient. Rarity, process mastery and material discovery are only partially connected. |

This does not prove drops alone cause the pacing problem. Time to reach a
deposit, gather it, evaluate equipment and obtain a useful modifier must be
measured. Reducing drops in isolation could simply remove rewards while
leaving the same progression structure.

**Intensive 1 — Make an expedition change the build and the workshop**

Proposed objective: prove one complete, deliberately paced preparation loop
across era one and the first era transition, using existing systems and a
minimal rare-resource addition.

1. **Capture the baseline.** Record a fresh-character route through first
   shelter, first useful gear, first Foundry interaction, improved forge and
   first trial attempt. Log the source of every equipped improvement and
   meaningful ingredient. Record combat, gathering, travel and menu time
   separately. Use a fixed seed and class for before/after comparison, then
   check the other starting classes and additional seeds.
2. **Give reward sources distinct jobs.** Propose ordinary mobs primarily
   pay modest, thematic materials and occasional discoveries; elites pay
   targeted catalysts and exceptional equipment; trials pay dependable
   progress toward selected advanced crafts plus rare jackpots. Harvesting
   provides the reliable bulk and distinctive natural ingredients. Preserve
   occasional complete-item surprises. Define eligible bases by source and
   era, with any intentional early exceptions explicitly authored. Apply
   the policy to world loot and trial rewards together.
3. **Make bog iron a place worth finding.** Reuse the existing ingredient
   as a readable fen deposit with a purposeful extraction step, rather than
   adding another currency. Reduce its ordinary-mob supply only once this
   route works. Keep all biomes accessible: the fen has a different resource
   and encounter composition, not a mandatory next-zone level. Ensure every
   starting class has a baseline extraction method; build interactions may
   improve efficiency without requiring the upgrade being crafted.
4. **Give advanced crafting a rare ingredient with a clear purpose.**
   Prototype one named rare ingredient or deposit variant alongside existing
   copper/tin/bronze. Common materials make a competent base; the rare input
   enables a particular process, capacity or controlled improvement. A
   catalyst targets the resulting modifier interaction. Decide which gate
   the ingredient replaces or strengthens; avoid adding a fifth repetitive
   lock to every recipe. Keep material traits useful across eras instead of
   replacing every old ore with a universally stronger one.
5. **Spend the expedition's discoveries in both permanent systems.** Let
   that processing capability improve one existing item and recast one
   existing Foundry support. Retain early skill tablets and a simple support
   interaction so the opening still feels like an ARPG. Gate advanced
   capacity and interactions through purposeful expeditions. Keep layout
   experimentation affordable; rarity should constrain acquisition more
   than rearrangement.
6. **Make the return visible.** The same expedition/process opens one
   architectural expression, using the existing bronze/arch relationship
   as the first candidate. Prefer an unlocked cut or treatment that then
   consumes common building material over spending a rare catalyst on each
   wall. The workshop visibly records what the character has learned.

An illustrative target story, not an accepted recipe chain:

> I found a promising deposit but could not work it efficiently. I prepared
> at home, returned and claimed it. Processing the haul let me improve my
> weapon and change a Foundry interaction. That helped me handle the trial.
> Its reward gave me a reason to revisit the world and add a new form to my
> workshop.

Rare should describe an exciting, targetable discovery. Required progress
must not depend on unlimited retries at an undisclosed spawn chance. In a
finite world, guarantee an accessible minimum supply or a deliberately
specified recovery route, accounting for optional spending and failed
experiments. Place additional deposits randomly for surprise. A rare input
should buy a useful result even when optional modifiers roll poorly.

Trials and dangerous world encounters can offer alternate routes to some
special reagents. Preserve source identity: ordinary enemy farming should
not provide every natural resource and every finished upgrade efficiently.
The first prototype should test one overlap rather than making every reward
interchangeable through the peddler.

Completion evidence:

- A tester can name the place, preparation and crafting operation that made
  the next fight easier, then identify a self-chosen next ambition.
- One physical expedition improves gear, a Foundry option and construction
  vocabulary through understandable steps. It need not pay for every option
  at once; choosing the next investment is part of the loop.
- A gathering-led preparation route and an elite/trial-led route both make
  progress. Compare useful outcomes per time and risk, not raw item counts.
- The original 20–40 minute slice target is measured, not silently expanded.
  If a slower first-era session is desired, revise that target explicitly.
- Focused checks cover source/era base eligibility, costs and XP, consumed
  rare inputs, targeting/preservation, Foundry refinement, finite resource
  guarantees, death recovery and save/load. Existing checks remain intact.

Affected areas: D-007, D-014, D-016, D-019 and D-023; `world.json`,
`worldgen.json`, `crafting.json`, `items.json`, `foundry.json`, `trial.json`
and possibly `eras.json`; the loot/economy/world-generation sim paths,
resource presentation and work panels. Document each new value by the
experience it controls: search distance, accessible supply, extraction
effort, rare-input cost, reward frequency, targeting strength or time to a
new interaction. No numerical retuning is accepted by this proposal.

**Intensive 2 — Build an octagonal frontier workshop**

There are two separate problems to test: the world's visual identity and
the shapes construction permits. An octagonal house will help the second;
it will not automatically change a horizon of textured cubes.

The captured [spawn view](../../build/visual-review/01-spawn.png),
[overlook](../../build/visual-review/02-valley-overlook.png) and
[terrain detail](../../build/visual-review/03-terrain-detail.png) show why:
high-frequency green pixel variation covers the ground and vertical steps,
small terraces recur throughout the visible valley, and trees and ground
cover fill much of it with similar visual density. The distant rim reads
as a fairly continuous stepped boundary in these views. Individual trees
already have non-cubic silhouettes, so simply replacing props will not
resolve the whole effect. Larger clearings, distinct groves, readable rock
formations and calmer material surfaces are useful comparison candidates.
These observations concern the captured starting area, not every biome or
seed. The PNGs and capture logs are local ignored artifacts under `build/`.

The existing [art direction](../art/art-direction.md) deliberately calls
for cubic terrain/buildings and 16×16 nearest-filtered textures.
[Terrain rendering](../../game/scripts/terrain.gd) instantiates `BoxMesh`
blocks. Changing this visual identity therefore needs an explicit revision
to D-013, while retaining whichever palette and danger-lighting principles
the owner still wants.

Proposed sequence:

1. **A small visual comparison.** Use one seed and matching camera views of
   a meadow, rocky threshold and workshop. Compare the current treatment
   with broader material texture, less visible per-cube repetition,
   irregular rock/vegetation silhouettes and more deliberate architectural
   edges. Keep the bright frontier/dark threshold contrast. Judge actual
   rendered views before commissioning art or rebuilding terrain.
2. **Prove an eight-sided room.** Extend the existing orthogonal kit with
   45-degree wall segments, triangular floor infill and the minimum corner
   joins needed to close one usable room. Start with a square footprint
   whose corners are cut off. This yields an eight-sided building; an exact
   regular octagon with equal-length sides is a further dimensional choice
   because diagonal grid spans have different lengths from straight spans.
3. **Prove the rules agree with the room.** The current
   [lattice](../../sim/include/wroughtwild/lattice.h) only addresses
   axis-aligned faces/edges, and [shelter detection](../../sim/src/lattice.cpp)
   flood-fills through those faces. Prototype a canonical address and
   occupancy/enclosure representation for diagonal boundaries. The result
   must agree across the preview, placement, collision, doors, removal and
   shelter detection. Rotating the mesh alone is insufficient. Record the
   D-017 extension and a save migration before integrating it.
4. **Finish the usable kit.** Add only the roof transitions, trims and
   connections needed for an octagonal workshop joined to an ordinary
   rectangular wing. Test both construction scales. Evaluate the current
   50% removal refund: repeated correction already costs materials, so new
   snapping must not make experimentation excessively expensive.
5. **Reassess terrain after the building test.** If improved materials,
   silhouettes and architecture still leave the world too cube-dominated,
   compare a small alternative terrain surface treatment. Any actual
   smoothing must preserve readable excavation, collision, resource access
   and building anchors. A full terrain replacement is a separate decision,
   not a prerequisite for trying diagonal buildings.

Difficulty judgement: an octagonal kit is a bounded, plausible extension.
The mesh work is smaller than the placement/enclosure/save work. Smooth
editable terrain plus unrestricted building angles would be a much larger
architecture change. Neither a new engine nor an octagonal world grid has
been shown necessary by this review.

Completion evidence: the owner can build, enter, roof, extend and edit an
octagonal workshop without invisible blockers or unwanted gaps; it counts
as shelter and survives save/reload; old rectangular buildings still work;
and matching world views demonstrate a visual direction the owner prefers.
Measure frame cost on the current world as well as a dense test building.

Affected areas: D-013, D-017 and D-018; construction tuning, lattice and
save representation, `grid_placement.gd`, `piece_mesh.gd`, `placed_block.gd`,
terrain/material presentation and focused placement/shelter integration
checks. Shape cost, snapping tolerances and refunds need documented tuning.

**Decisions to resolve before the relevant implementation**

- **Construction conflict:** D-018 says mobs never demolish placed pieces.
  `eras.json` enables `breaks_timber` for husks, and
  [PlacedBlock.scratch](../../game/scripts/placed_block.gd) removes `wood`
  pieces after twelve scratches. The later roadmap describes the siege,
  but the registry has not recorded a superseding decision. Other timber
  families are not matched by that literal `wood` check. Resolve the policy
  explicitly; this review changes neither code nor decision text.
- Whether exceptional early drops may bypass a facility only, or also a
  material/era gate. Preserve surprise intentionally, with bounded scope.
- Whether the first rare resource mainly unlocks a reusable process or is
  spent per advanced craft. Prefer a reusable process for building shapes
  and carefully bounded consumption for equipment optimisation.
- Whether eight-sided grid-compatible rooms meet the initial architecture
  goal, and which parts of D-013's cubic/pixel-texture direction to replace.

**Observing and operating Godot**

The owner clarified that Claude uses the console binary and temporary
self-driving scenes, with no MCP, addon or editor connection. That workflow
was reproduced successfully during this review; no new integration is
required for scripted observation.

- Binary: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe`;
  verified version `4.5.stable.official.876b29033`.
- Use absolute project paths. Run the existing
  [headless pipeline](../../game/run_headless_checks.sh) for gameplay
  checks. Rebuild the GDExtension after sim/binding changes and build the
  C++ tests separately. Neither was changed for this capture.
- Put a temporary scene/script in an ignored scratch directory inside
  `game/`, instance the sandpit, choose a class through the panel method,
  position the camera, await `RenderingServer.frame_post_draw`, save
  `get_viewport().get_texture().get_image()` and quit. Run without
  `--headless` for actual rendered screenshots.
- The review used a hidden window, an external 55-second process timeout
  and `--quit-after 260` as a second limit. It captured at scripted frames
  80, 140 and 200 and exited normally. Logs include the seed and each
  camera position. Images were opened and inspected locally.
- In this environment the first sandboxed check crashed while opening
  Godot's user-log directory. The approved run outside the sandbox passed.
  This was separate from the repository's documented first-import crash.
- Temporary capture source is removed after use; PNGs/logs stay under
  ignored `build/visual-review`. No existing save was loaded or written.
  Check Git status after running Godot and restore only generated changes
  attributable to that run, preserving unrelated work.

This establishes rendering and scripted state control, including class
selection. The next intensive should extend the same approach to harvesting,
placement and Foundry interactions and combine it with the owner's
hands-on judgement of combat, snapping and progression pace. The existing
[interface contract](../systems/interface.md) already exposes panel actions
as methods for this purpose.
