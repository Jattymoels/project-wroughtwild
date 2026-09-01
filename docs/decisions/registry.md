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
| D-011 | World shape | The world is an open sandpit with no quest-hub town: Valheim/Minecraft moment-to-moment feel (start with nothing, harvest, build, get jumped), PoE/Diablo-style mob packs and itemisation in the open world, roguelite dungeons as the innovation layer; development proceeds in the four waves of [prototype/roadmap-waves.md](../prototype/roadmap-waves.md) | Accepted direction | Sandpit playtest (end of Wave 1) |
| D-012 | Combat perspective | Combat is first-person (a third-person toggle may remain for greybox debugging): the build clears hordes but the player only engages what is in front of them, trading PoE's screen-clear for personal-scale danger. Horde pressure is CoD-Zombies-style: open-world mobs are deliberately "stupid zombies" — persistent chasers that bunch up and can be trained by a player who stays close — but aggro is NOT eternal: genuinely running away breaks the chase, at the cost of a dangerous disengage. Build expression comes from damage *mechanics* (cone/cleave AoE, ground effects the train is led through, bleed/poison/ignite tag-and-run, chill/freeze choke-making, single-target speed) rather than raw numbers; the mechanic vocabulary arrives with Wave 2 items and Wave 3 mobs, horde/wave rooms with Wave 4. Dungeon AI may later become smarter than the open world's — a deliberate contrast, not an accident | Accepted direction | First-person greybox playtest (Wave 1.5) |
| D-013 | Art direction | "Bright frontier, dark thresholds" ([art/art-direction.md](../art/art-direction.md)): vibrant, saturated, Minecraft-warm overworld whose light and saturation drain toward danger (enemy biomes, dungeon thresholds) — PoE's use of darkness without its gore; menace is told by light, fog and silhouette, never blood. Blocky terrain and buildings, chunky low-poly props, smoother low-poly characters; one master palette governs all textures, tints, fog and VFX | Accepted direction | First art-pass playtest, or character modelling begins |
| D-009 | Engine | Godot 4.5-stable (`4.5.stable.official.876b29033`) is the prototype engine; the engine project lives in `game/`, gameplay rules stay in the engine-neutral `sim/` library bound via GDExtension; `godot-cpp` is the only approved third-party dependency ([ADR-0001](ADR-0001-engine-selection.md)) | Accepted | Terrain scale, world streaming, construction density or visual targets outgrow Godot (ADR-0001 exit condition) |
| D-014 | Itemisation | Wave 2 scope per [systems/items-and-modifiers.md](../systems/items-and-modifiers.md): one modifier pool where mods attach to tags (never sockets) with the increased/more schema; three slots (weapon, chest, charm); rarity by rolled-mod count (plain / keen / wrought) plus hand-authored uniques with rule-bending interactions; any modifier may drop — catalysts target a domain rather than gate it; the weapon carries the delivery skill (working assumption); equipment swaps never destroy a tempered item; upskilling points wait for a later wave | Accepted direction (owner answers 1 Sep 2026) | The first keen/wrought/unique items are playtested |
| D-015 | Interface | Per [systems/interface.md](../systems/interface.md): four layers only — HUD (life bar, action bar, holdings strip, notices, crosshair), pack screen (I), one work-panel type (cards in a scroll area), help overlay (H); the mouse is captured unless a panel needs it; panels never compute rules and every panel is a headless test surface; one code-built Theme from the master palette | Proposed (first slice implemented 1 Sep 2026) | Owner plays the first interface slice |

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

- **D-015 (1 Sep 2026):** the interface spec is a proposal; its first slice
  is already in the build because it is the instrument the itemisation
  playtest needs. D-014 was answered the same evening and is now an
  accepted direction; only "the weapon decides delivery" remains a working
  assumption the owner has not explicitly confirmed.

## Registering a decision

Add an entry when a choice materially affects player experience, save data, system boundaries, architecture or prototype scope. Create a separate ADR when the rationale, alternatives or consequences require more than one table row.

Never rewrite the meaning of an accepted entry without recording what superseded it.
