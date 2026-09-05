# Places worth discovering — world intensive

Status: owner approved for implementation, 6 September 2026. Author: Codex.
Decision D-027. This work item is the bounded exception to the original small
material catalogue: eight finished families, three resource habitats, two new
wall-face forms, and integration through the already approved Blender pipeline.

Playable slices are implemented. See the [combined implementation review](intensives-review-2026-09-06.md)
and [world evidence](../art/world-habitat-intensive-2026-09-06.md) for checks,
captures, performance and remaining owner acceptance.

## Outcome

Keep the weathered frontier and readable meadow. A quarry escarpment supplies
slate and shellstone; a fen hollow supplies clay and reeds; an oldgrowth grove
supplies resinheart logs and separate corkbark deadfall. These become slate,
shellstone, rustclay brick, woven reed, resinheart and corkbark. Trials supply
furnace slag and cinderglass shards for vitrified basalt and framed cinderglass.
Trial caches replenish ordinary source ingredients without another knowledge
gate. Deposits remain finite.

Use existing yard, bench and forge processes, at most one refinement step.
Contextual interaction always completes harvesting; skill properties can shorten
it. Covering enables light panels and pitched roofs without granting joinery;
existing roof eligibility and stonecut_blocks remain. Glazing enables a fixed
window. Both new forms occupy a wall face, seal shelter and block projectiles.

## Compatibility and delivery

World identity is generation profile plus seed. Freeze legacy generation and
placement inputs. Old saves without a profile mean legacy_v1; newly created worlds
use frontier_v2. Existing geography is not enriched or regenerated with new rules.
Reject unknown profiles. Nodes keep stable identities and saved depletion/work.

Deliver quarry end to end, then fen/grove, then the trial palette. Integrate
authored visual meshes without adding duplicate colliders. Demonstrate three
small buildings, matched daylight/dusk routes and performance against the prior
field route. Every valid new seed must offer all three reachable habitats.

## Verification and limits

Test legacy geometry/identity, profile cache isolation, deterministic placement,
reachability, grounding, depleted and partially worked resources, recipes,
restricted forms, roofs, window collision/enclosure and inventory/storage.
Report startup and median/p95 frame timing; investigate changes above 10%.
Record exact implementation evidence and provisional tuning when checks finish.

The existing D-018 timber-demolition conflict is outside this work item. No
durability tier, full hydrology, multiplayer, external package or automation is
introduced. The ongoing combat and class playtest remains authoritative for its
own tuning.
