# INT-01 — First-hour clarity

Status: **Plan ready; implementation not started.**
Owner requested the plan on 7 September 2026. This records a proposed bounded
implementation, following the accepted station/ingredient presentation rules.
Baseline: `062b7e7`. [Current intensive queue](intensive-queue.md).

## Outcome

The player can recognise what they gathered, understand what makes it useful,
choose an existing home or crafting project and see the next achievable step.
They can move through the early loop without a separate explanation from the
developer. “First-hour” describes the part of the game being clarified, not a
new timer or a promised completion time.

Support several self-chosen ambitions. A wooden home and storage can progress
alongside the workshop chain; neither requires a compulsory tour of every bench.
The masonry route needs its actual dependencies explained: handcraft the bench
and timber wedges; use the bench to make a frame and yard kit, and the wedges
to work seams for split stone; dress that stone at the placed yard; craft the
forge kit at the bench, then place and fuel it for ore work. Fieldstone supplies
the yard kit, while dressed stone supplies the forge kit. Read exact costs from
current recipes. Wedges can be made before placing a bench.

## Established foundations and findings

The existing [station catalogue](crafting-catalogue-station-pass-2026-09-06.md)
already filters by physical station family, sorts ready crafts first, supports
explicit ingredient references, shows native costs and offers a pin. Building
has a catalogue, rotation guidance and placement refusals. Gathering has saved
work progress and physical pickup feedback. The pack has character and wild-find
guides. Extend those surfaces rather than building another tutorial framework.

The following are read-only code findings, not new runtime test results:

| Finding | Evidence | Planned response |
| --- | --- | --- |
| Pins retain only a recipe ID and ask for a default native preview. A chosen batch/grade/Kind can lose its requirements context. | [ForgeCatalogue](../../game/scripts/forge_catalogue.gd): `pinned`, `_process`, `_render_detail`. | Keep the selected recipe, batch, grade and Kind context in the session pin; display the matching native preview. |
| Ingredient Back stores only a recipe ID; selecting it resets craft options. | `ForgeCatalogue.history`, `select_recipe`, Back action. | Restore the parent selection and options when returning through ingredient references. |
| Raw costs have no source explanation in recipe detail; View recipe exists only when a producer recipe is found. | `ForgeCatalogue._render_detail`; native `craft_preview` cost metadata in [WroughtwildSim](../../game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp). | Add bounded source/work/use explanations for early raw ingredients, alongside existing producer-recipe links. |
| Help says dug stone pays "stone", and a resource refusal says fire "then cold" even though impact cracks hot ore. The refusal wording conflicts with D-021. | [HUD](../../game/scripts/hud.gd) help; [ResourceNode](../../game/scripts/resource_node.gd) `work_refusal` and `strike`. | Follow D-021: name split stone accurately and explain existing impact/cold alternatives. Correct presentation, preserving the accepted gathering rules. |
| Successful kit crafting says only "Crafted <name>"; the placement catalogue has guidance after the player finds it. | [WorkPanel](../../game/scripts/work_panel.gd) `craft`; `ForgeCatalogue._make`. | Give station-kit crafts a concise handoff to the existing build catalogue and world interaction. |
| The guide's Progression page explains character/Foundry/era progression, not the first physical home/workshop chain. | [BuildGuide](../../game/scripts/build_guide.gd), [InventoryPanel](../../game/scripts/inventory_panel.gd). | Add a short optional “Getting established” guide within the existing pack surface. |
| Wild finds and ordinary material tiles offer little navigation from a held resource to a useful recipe. | `BuildGuide._wild_finds`, `InventoryPanel` material rows. | In this intensive, connect the early materials used by the selected home/workshop journey; leave a catalogue-wide expansion for later evidence. |

The pins, history, source help and kit handoff are presentation/data-flow
defects or omissions; the two help messages require wording corrections.
Whether the optional guide improves understanding is a usability hypothesis to
review later. Existing guide/catalogue fixtures often supply stations and stock,
so they do not establish comprehension of the fresh opening.

## Implementation slices

### 1. Preserve the project the player selected

Start here. Give recipe history and pins the same small craft-selection record,
containing only the fields needed by existing native previews and UI navigation.
Preserve batches, grade, Kind and parent operation through drill-down/Back.
Pin requirements for that chosen operation, including real fuel availability
after ingredients are reserved. A reference still tells the player which
physical station is required and cannot craft remotely.

Keep the current session-only pin lifetime. Browsing, pinning, changing quantity
or returning Back cannot spend ingredients, award XP or alter equipment. A save
schema change or persistent project system is outside this pass.

### 2. Explain source → material → use at the point of confusion

Cover the existing early chain: wood, fieldstone, timber wedges, split stone,
dressed stone, iron ore/ingots, fuel, timber frames and station kits. Keep source
ingredients distinct from finished building families. For example, fieldstone
and dressed stone must not both be described simply as interchangeable stone.
Distinguish ordinary recipe wood from other timber species when the recipe
requires that exact ingredient; this plan does not introduce substitution.

Use current recipe outputs, source IDs, harvest presentation and material traits
for one shared read-only explanation lookup. Add only missing presentation
descriptions; do not duplicate recipes, yields or availability calculations in
the UI. Show where something generally comes from, the ordinary work required,
and its immediate use. Hints reveal no exact undiscovered map coordinates.

Reuse the ingredient detail/back path and native preview. Link to the existing
producer recipe when one exists; explain gathering when it does not. A compatible
skill is a helpful shortcut, never described as a new class requirement.

### 3. Make getting established understandable and optional

Add a compact “Getting established” page to the existing pack guide with three
plain-language choices: **make a first home**, **work stone**, **set up a forge**.
Give each its immediate useful outcome, current requirement and a link to the
relevant existing recipe or build controls. Keep the character/Foundry pages and
Wild finds reachable, with clear names for their different purposes.

Explain the gaps between actions: a crafted kit goes into inventory and must be
placed; a placed station is operated in the world; harvested material becomes a
physical drop before collection; nearby stored stock is not automatically carried
stock. Use live state and existing previews when declaring something ready.

Provide guidance on request. Avoid a mandatory quest sequence, new unlock flag,
automatic rewards, repeated modal prompts or automatic objective pins. The guide
must remain useful when the player already has a home or loads an older world.

### 4. Finish the first-home handoff and verify the whole journey

Use one simple home with a functioning doorway, shelter and chest, plus the
early stations, to find missing instructions and confusing refusals. Explain
existing shelter/roof restrictions rather than changing them. Put corrections
in the existing placement, help or station surface that owns the action.
Explain the existing slab-roof option before the pitched-roof unlock, and link
the full-pack chest suggestion to its existing building entry.

Run a fresh-stock journey through normal interaction, pickup, crafting and paid
placement APIs. Start with ordinary supplies actually gathered in the world.
Exercise at least the bench, yard, forge and a useful existing output. Separate
fixture-seeded negative cases from this complete journey. Record a short capture
sequence so the owner can judge the result without repeating every step.
Use the ordinary generated-world kit route; authored greybox stations have a
different construction path and cannot stand in for this check.

## Affected systems and contracts

- **Presentation:** `forge_catalogue.gd`, `work_panel.gd`, `build_guide.gd`,
  `inventory_panel.gd`; gathering, placement and HUD help only where the journey
  identifies a specific missing explanation.
- **Rules/data:** reuse native `craft_preview`, recipe/station/material/source
  definitions. A bounded read-only metadata addition may be needed for sources;
  keep calculations authoritative in the simulation.
- **Decisions:** D-017 placement; D-019 progression; D-021 ordinary gathering and
  masonry distinctions; D-025 Foundry; D-026 crafting presentation; D-027 material
  families; D-032 world/save identity. See the [registry](../decisions/registry.md).
- **Specifications to update with implementation:** [interface](../systems/interface.md),
  [crafting](../systems/crafting-and-skills.md), and construction/gathering help
  only if their presentation contract changes. No gameplay-rule ADR is proposed
  by this planning task.

No changes to combat, costs, yields, skill/era gates, harvest speed, roof unlocks,
world generation, source depletion or death/suspension rules. No new materials,
recipes, furnishings or automation. Preserve normal saves and the running game.
No gameplay tuning values are planned; any presentation limits added during
implementation must have a plain-language purpose beside them.

## Verification and completion

- Extend existing `crafting_catalogue` / `forge_progression` fixtures for exact
  non-default batch, grade and Kind pins; changing holdings; fuel reservation;
  two-level ingredient navigation; and physical-station refusal. Assert outcomes
  against native previews rather than reproducing their calculations.
- Check source descriptions against actual early gathering and refinement rules.
  Ordinary contextual work must remain possible for Ranger, Warden and Kindler.
- Check the complete fresh opening, kit placement, shelter and chest interactions.
  Relevant existing fixtures include `gathering_feedback`, `build_usability`,
  `integration`, `new_world_startup` and `weathered_save`; run those affected by
  the final changes rather than the entire project suite indiscriminately.
- Save/restore at meaningful boundaries: partial harvesting, a crafted unplaced
  kit, and a home with stored resources. Guidance cannot grant, consume or double
  count inventory. Continue retains original world identity and progression.
  Probe saving before harvest then loading before pickup, and saving after a
  material drop is released then restarting. Pickup lifetime and save handling
  make these worthwhile loss/duplication checks; neither failure has been
  reproduced in this planning task. If confirmed, record a separate bounded
  reliability fix under INT-07 rather than silently changing the drop contract.
- Review at 1280×720 and 1920×1080: readable requirements, reachable controls,
  correct mouse capture, optional guide access and no pin/HUD overlap during
  ordinary play. Opening guide/recipe views should not generate the world again.
- Deliver code, updated specs, focused check results, before/after captures and
  limitations in this work item; update INT-01 to **Implemented, review pending**.

The owner's later review has three questions: Can you explain why a material is
not yet usable? Can you find the next step for a chosen home or craft project?
Can you ignore the guidance and continue exploring freely? Automated checks
establish operation; they do not certify those answers or a sixty-minute pace.

## Plan decisions and next action

Assumptions: optional assistance, existing station and placement rules, a small
early-material scope, and session-only UI state. No missing decision blocks the
first implementation slice. Broader tutorial progression, persistent project
tracking or economic changes would be separate design choices if later requested.

**Next action:** implement slice 1, with focused failing cases for a multi-batch
material pin and non-default equipment selection returning from ingredient detail,
then add the smallest shared selection state that makes those cases correct.
No runtime or gameplay changes have been made by this planning task.
