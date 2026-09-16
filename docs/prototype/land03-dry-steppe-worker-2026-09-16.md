# LAND-03: Dry Steppe, Red and useful four-force acquisition

**Draft for the selected next slice; workspace not prepared and worker not started.**
The owner raised the reference-to-game quality gap during LAND-02 adoption. Read
the [pipeline diagnosis](land02-visual-pipeline-diagnosis-2026-09-16.md) and settle
that production approach before dispatching this draft. No new sequence is
automatically selected by the diagnosis.

Workspace: `D:/Wroughtwild/work/land03-dry-steppe`

Branch: `codex/land03-dry-steppe`

Read current owner-depot `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required foundations, then `build/land03/SETUP.md`, this brief, the [selected LAND plan](landscape-biomes-influences-plan-2026-09-16.md), [four-force reference](land00-influence-generation-reference-2026-09-16.md), [world premise](../world-premise.md) and [LAND-02 result](land02-scarwater-result-2026-09-16.md). View boards 03/04 in `land00-visuals-2026-09-16/`, their caveats and LAND-02's actual evidence. Use current [world generation](../systems/world-generation.md) and implemented [Living Frontier](living-frontier-roadmap-2026-09-08.md) contracts for the concrete dependencies below. Do not repeat LAND-00/01 or reopen the selected direction.

## Player-visible result

Deliver a new ordinary seeded **Dry Steppe** place: low connected grass/shrub masses, exposed irregular mineral ribs, shallow eroded cuts, long views and sheltered hollows. It must differ from Gallery Woodland in landform, vegetation structure, sightlines, traversal and home setting. It is living dry country, not recoloured meadow or Ember Wastes. Use terrain and a small substantial authored kit together.

Red **Excitation** affects susceptible mineral and plant hosts before final terrain/habitat composition. Concentrated swollen inclusions deform a cut bank; irregular recessed release structures and tough local growth echo that accumulation. Red reinforces these forms with local gathering/releasing light. No universal lava, fire biome, passive damage or invented power follows from the colour.

From the approach, a legible mineral/growth landmark gives a reason to leave the broad trail. A more open ridge-side approach and a sheltered low-cut approach reveal different aspects of the place and reach the usable Red source. The existing selected Red boar host and its source-related behavior occupy a separate safe-to-observe discovery route, away from the source workplace and quiet starter country. A dry sheltered work hollow and an open outlook create different building ambitions using current costs and the existing four home cores. Preserve Scarwater's two useful home settings; do not add a fifth compulsory site or crowd all sources/encounters onto the player's doorstep.

The player can perform existing Red source work, collect the real material, use existing manufacture and build/use a paid Red heat buffer in their own workshop. The same fresh world also exposes the existing White, Blue and Green sources and devices as a coherent acquisition set. Red receives this slice's authored place and teaching-host emphasis; the remaining three journeys and selected hosts are LAND-04. All four sources must actually be reachable and usable, not hidden records or fake glowing scenery.

## Carry the creative requirement forward

LAND-02 delivered real geography, walking, paid work and restoration. The coordinator's picture assessment finds the full visual ambition **still unmet**: broad mesa-like walls and regular bands dominate; trees repeat; the inset seam remains thin. These are recorded LAND closeout weaknesses, not evidence that functional checks establish atmosphere. Stay on the selected sequence, but do not reproduce those weaknesses as Dry Steppe's artistic target.

Build one representative ordinary generated Steppe scene early. Inspect at player height against the references. If it reads as flat tinted grass, a uniform wall or isolated decorative objects, revise the dominant form/composition weakness before expanding rules. Art and readable terrain are part of this task. A greybox or source-port-only delivery is incomplete. Reuse LAND-02/RF materials and systems where suitable; purpose-made land/plant/host joins are authorised. No new dependency, paid service, engine change or general art overhaul.

## Generation and compatibility

Introduce **`frontier_v10`** with separate frozen generation inputs/composition and select it for ordinary random/chosen-seed New World. Preserve V1–V9 and LF Continue without migration, reseeding or ownership changes. Do not edit published V9 geography to insert the new country. Preserve Scarwater's complete useful composition in the successor while adding the contrasting habitat; existing lake behavior, caves/digging, opening protections, four radius-14 m homes, discovery regions and rare families remain.

Seed, substrate and exposure select eligible Steppe country; typed Red influence and hosts then shape local land, recovery, source siting and routes. Vary location/orientation, rib/cut proportions, low-growth bands and route/home relationships. Same saved profile/seed repeats; different seeds must change spatial composition, not just tint/prop jitter. Reuse deterministic bounded candidate selection with a useful fallback. Protect existing cave/water/quiet-home constraints before dressing. Avoid long unwalkable walls, flooded terrestrial routes or inaccessible source anchors. Physical shapes belong in shared native terrain/contact; dressing follows support and refreshes after digging/paid construction.

Add only the place/host data needed by the selected composition. Do not create a global four-channel simulation or a general procedural framework. Define tunables and their plain-language player purpose next to values. New ecology remains distinct from discovery-region/progression definitions. Ordinary fauna fits the habitat; only the existing `lf_red_boar` teaching host is newly adapted here. No blanket four-colour creature variants or new attacks/drops.

## Adopt the existing acquisition system coherently

The plan deliberately adopts the current complete four-source ledger because restore expects all declared sources and devices share acquisition support. This is a scoped move into ordinary fresh V10, independently of the LF campaign. **Keep ordinary `legacy` campaign policy.** Do not enable `living_frontier_wave4`, laboratories, Conservator progression, era transformations or unrelated LF campaign content to make devices available.

Preserve the current IDs and native ownership of `red_home_margin`, `white_home_margin`, `blue_home_margin` and `green_home_margin`; their names do not require every new anchor to occupy a home centre. Source geography can refer to the new place while ownership remains stable within the saved world. Keep existing raw materials, rare rules and recipe costs. Current tuning is eight lots of sixteen units, four manual stages, and ten minutes of eligible active-overworld renewal after depletion/claims. No offline, paused or trial growth; no free matter, stock recreation on scene reload or duplicated rare roll. Confirm these contracts in current tuning rather than copying a second economy.

White requests an action, Blue delays a request, Green branches requests, and Red stores/uses paid heat. Reuse existing device costs, limits, connection/range semantics, paid inputs and invalid-operation handling. Normal recipes, placement UI, use and Continue must agree on support. Keep the ordinary finite pressure pocket, rare sites and resource depletion as separate owners. A coloured pulse is never proof of stock or power.

Use the existing source/host placement and behavior contracts without importing their laboratories: Red host beyond the 150 m quiet start (current minimum 170 m), separated from source work (current source-host route 65–130 m), with the existing finite encounter/ownership and return behavior. Preserve current source/host caps and encounter rules. Do not add respawning host farms or a new reward loop.

Concrete source leads:

- `sim/src/worldgen_frontier_v9.inc`, profile dispatch, tuning loaders, native bridge mesh/export and engine profile gates: create isolated V10 and retain V9's corrected terrain/contact/art paths where applicable.
- `sim/include/wroughtwild/leyline.h`, `sim/src/leyline.cpp`, `data/tuning/leyline.json`: supports, four-source state, formation/claims and restore. Legacy LF's internal ledger profile tag is not a reason to change old payloads or skip new-world identity validation.
- `game/extensions/wroughtwild_sim/src/leyline_bindings.inc`, `strange_frontier_bindings.inc`, `sim/src/contraptions.cpp`: bind/validate/load, geometry anchors, device availability and independent placement/save gates. World rebinding must not carry another world's stock merely because its seed matches.
- `game/scripts/leyline_source.gd`, `frontier_sites.gd`, `data/tuning/crafting.json`, existing selected LF host and mob presentation paths: ordinary reach/UI/recipes/behavior and resource preparation. Update experiment-only UI text for the new ordinary use where needed.
- `game/scripts/save_manager.gd`, normal entry/seed selection and terrain/cover/edit paths: atomic restored identity, exact claims/paid state and correct reconstruction. Missing, extra or wrong-world owners must not be silently initialised as fresh stock.

Use narrow capability/profile changes with legacy-compatible behavior. Do not globally turn every LF support check on for normal saves. Prepare shared source/device/creature resources at actual New World/validated Continue entry, reuse them during arrival and edits, and keep heavy loading out of movement callbacks. Build a matching worker DLL with existing local tools; do not test new native sources against the previous binary.

## Focused implementation and evidence

Make the representative place first, then complete the source-to-craft/device loop and save integration. Keep one renderer, Forward+, and default to three focused jobs named for their concrete risks:

1. **New generation and ownership:** deterministic V10 composition on one representative and one contrasting seed, usable fallback/approaches, all four real source anchors, protected starter/homes and separate finite ledgers. Reuse old-profile evidence; target only changed dispatch/identity paths.
2. **Actual ordinary use and appearance:** real New World entry, player-height Steppe exploration, existing Red host behavior, manual source work/collection, paid Red manufacture/buffer use and a paid home placement. Exercise existing White/Blue/Green request semantics through a small real paid setup so adoption is usable, without a campaign replay. Staged recipe inputs are allowed for a short check but must be disclosed; they do not prove acquisition pacing/balance. Retain roughly three useful actual-game images covering reveal, affected host/source and home/workshop context.
3. **Restore and rejection:** targeted Continue retaining partial source work, outstanding claim/depletion, paid device state, terrain edit and builds; reject wrong-world/missing ownership atomically and preserve the relevant old V9/LF restore behavior. Reuse existing eligible-time/device tests rather than another timed ten-minute gameplay wait or broad matrix. Test pause/trial/no-offline semantics through focused state advancement where the adoption changed support.

Inspect and improve visible form during normal development; do not substitute a large screenshot matrix. Follow current no-mouse-capture/non-focusing rendering requirements and isolated test saves. No benchmarks, whole-package copying/hashing, all-profile replay, repeated art-master reopening or independent review wave. End owned test processes.

## Handoff and stop

Commit checked source, selected runtime art/recipes, explained tuning and affected specs on the worker branch. Write `docs/prototype/land03-dry-steppe-result-2026-09-16.md` with player outcome, appearance separately from functional checks, actual failures/limits, seeds/profile, native/source-art paths and SHA. Retain selected PNGs in `docs/prototype/land03-evidence-2026-09-16/` and show actual game pictures directly in chat. Keep concepts labelled separately.

Update the coordination sheet briefly. Add non-blocking issues to LAND-05 closeout; do not schedule extra slices or repair Scarwater's whole art direction within LAND-03. LAND-04's three remaining journeys stay next. The owner has selected this work and ordinary integration; routine details need no repeated approval. Coordinator handles main adoption/push. Stop after LAND-03; do not launch further workers.
