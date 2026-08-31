# Decision Registry

Statuses:

- **Accepted:** use as a requirement until deliberately superseded.
- **Accepted direction:** principle is accepted; implementation remains flexible.
- **Provisional:** implement minimally or prototype alternatives.
- **Open:** do not silently decide during implementation.

| ID | Area | Decision | Status | Revisit when |
| --- | --- | --- | --- | --- |
| D-001 | Prototype | Begin with a small single-player vertical slice; exclude co-op, raids, infinite generation, broad automation and large construction sets | Accepted | Core loop is proven |
| D-002 | Craft skills | Repetition and skill friction are desirable when outputs satisfy useful world, trade or construction demand | Accepted direction | Crafting prototype exposes pacing or exploit problems |
| D-003 | World | Generate bounded terrain, biomes, elevation and resources; place authored critical content through guaranteed rules | Provisional | First generation prototype |
| D-004 | Classes | Starting class leads toward a guaranteed class hall providing another vertical progression path | Provisional | Combat prototype defines skill architecture |
| D-005 | Settlements | Encourage small resource outposts before an ambitious main settlement; unlock fast transport and logistics | Accepted direction | World scale and travel time are measurable |
| D-006 | Death | Trials protect stored possessions; open-world death drops carried inventory; binding eventually protects important gear | Provisional | Death and recovery playtest |
| D-007 | Crafting economy | Combine physical materials and infrastructure with rare crafting catalysts from combat and exploration | High-priority open | Itemisation prototype begins |
| D-008 | Input | Initial building interface targets mouse and keyboard only | Accepted | Controller scope is considered |
| D-010 | Combat | The sim owns combat numbers (derived stats, mitigation, boon mods, per-hit damage, trial structure); the engine owns time and space (movement, hitboxes, timers); `round_seconds` bridges the two clocks; the round-based encounter stays the balance oracle ([ADR-0003](ADR-0003-combat-authority.md)) | Accepted | Real-time feel needs a rule the round model cannot express, or a second combat archetype is added |
| D-009 | Engine | Godot 4.5-stable (`4.5.stable.official.876b29033`) is the prototype engine; the engine project lives in `game/`, gameplay rules stay in the engine-neutral `sim/` library bound via GDExtension; `godot-cpp` is the only approved third-party dependency ([ADR-0001](ADR-0001-engine-selection.md)) | Accepted | Terrain scale, world streaming, construction density or visual targets outgrow Godot (ADR-0001 exit condition) |

## Proposals awaiting acceptance

- [ADR-0002](ADR-0002-catalyst-crafting.md) proposes the *verb shape* for
  catalyst-type items (what applying one does). Proposal C is implemented
  provisionally in `sim/` and `data/tuning/crafting.json` so the playtest can
  exercise it; D-007 stays open until the owner accepts.
- Owner direction (31 Aug 2026): catalysts are a farmable currency class
  (PoE-orb-like, dungeon-sourced, multiple types expected), not singular
  treasures. Currency-economy breadth — type count, drop rates, stacking,
  fungibility, trade — is deliberately deferred until the core loop is
  proven; do not over-design mid/late-game crafting now.

## Registering a decision

Add an entry when a choice materially affects player experience, save data, system boundaries, architecture or prototype scope. Create a separate ADR when the rationale, alternatives or consequences require more than one table row.

Never rewrite the meaning of an accepted entry without recording what superseded it.
