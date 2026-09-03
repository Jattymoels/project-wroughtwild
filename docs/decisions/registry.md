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
| D-016 | Skills | Skills are found, not worn (supersedes D-014's "the weapon carries the delivery skill" working assumption, per owner direction 2 Sep 2026: PoE's many-skills-with-interacting-grammars over gear-defined archetypes). Each skill is one data entry in `skills.json` — delivery (cone / strike / projectile / dash), tags, payload numbers; the starting four fill a free four-slot bar and the rest are learned from skill pages that mobs drop (weighted among unknown skills, never duplicates). Gear only ever scales skills through tag-targeted modifiers; hooks (shatter, proliferate) trigger by tag, never by skill id, so a page found tomorrow joins the combos it is tagged for. Build identity = the tags on the bar. Statuses are buildup-with-threshold (chill/freeze, ignite/burn, bleed) with the day-one boss resistance multiplier; shatter never executes a boss (`executes_boss` tunable, default false) — the freeze window is the reward | Accepted direction (implemented 2 Sep 2026) | Wave 3 mob families stress the grammar, or a skill that cannot be one data entry appears |
| D-017 | Building | Pieces are addressed by lattice element, never by cell-plus-slot: a block occupies a cell, a wall or floor a face two cells share, a post or beam an edge four cells share, each with one canonical address (`sim/lattice.h`). The single placement rule is "the nearest free element of the piece's kind to the crosshair"; orientation comes from the element, so only oriented blocks turn with R; two pieces conflict only when they want the same element. Corners where walls end or meet grow a post visual on their own. No structural-support rules — the lattice's shape is all the physical honesty a build needs ([systems/construction.md](../systems/construction.md)) | Accepted direction (owner "lets do it" 3 Sep 2026; slice 1 implemented) | The owner's building playtest, or a piece that cannot be one element (diagonals, curves) |
| D-018 | Building materials | Building families are data with a source item, a look and **traits**; shapes require traits, so a material's properties gate the forms it can be worked into (joinery for doors, masonry for cut stone, metal for spans, malleable reserved for the coming alloy and its curved forms) rather than a tech tree. Placed pieces are never demolished by mobs: a timber house is a house at every tier (owner, 3 Sep 2026); base threat is pressure around the build, not damage to it ([systems/construction.md](../systems/construction.md)) | Accepted direction (owner steer 3 Sep 2026; three families + girder implemented) | An alloy family lands, or the base-threat design is playtested |
| D-019 | Progression | Per [systems/progression-eras.md](../systems/progression-eras.md): **eras are the campaign** (the world changes state on player-chosen milestones; mobs scale per era, never per player; no zones unlock), **the Foundry** is the point system (ingots placed on a forged plate; adjacency, lines, wrought forms; refinement widens reach, numbers stay flat; respec is re-forging), and **ores are properties, not ranks** (one trait vocabulary across building materials, item bases and ingots; modifier tiers are mechanic breakpoints; held-back modifiers as the early taste; a threefold global number budget). Encroachment belongs to era two | Accepted direction (owner "lets do it" 3 Sep 2026) | The first era transition is playtested |

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
  accepted direction.
- **D-016 (2 Sep 2026):** resolves the one loose thread of D-014 — "the
  weapon decides delivery" is dropped. The owner's steer ("diablo/last epoch
  lend themselves to designed archetypes based on gear vs poe where its many
  skills with interesting grammars interacting") makes skills their own
  found things and leaves gear purely multiplicative. Uniques remain noted
  and deferred in [systems/items-and-modifiers.md](../systems/items-and-modifiers.md).
- **D-017 (3 Sep 2026):** the owner's four building screenshots (a rotated
  wall landing on the far side of its cell, a wall refusing to join another,
  a cube refused beside a panel, a post going sideways instead of stacking)
  were one bug — cell chosen by the ray, position-in-cell chosen by R. The
  owner asked for "an innovative thought process ... intuitive from the
  engine's point of view"; the lattice answer was proposed and accepted
  ("Okay perfect lets do it"). Slice 2 (vocabulary: registry at half
  cells with footprints, floor slab un-gated, stairs, a two-cell door, the
  roof wedge as the trial reward) and 2b (fine mode: G swaps the selection
  for a half-scale twin on the same rule) and 3 (shelter: an enclosed
  room under a size cap regenerates life once settled; `world.json`
  `shelter`) landed the same day.

- **D-019 (3 Sep 2026):** the owner's worry — "builds through passive
  skills or a talent tree have tension with a procedural world, and rely
  more on itemisation, which ... becomes '50% increased cold vs 45%'" —
  and their pull toward "the world develops and advances with you" rather
  than zones unlocking. Encroachment slice 1 stays merged but is era two's
  mechanic; nests do not settle in era one.

- **D-020 (3 Sep 2026, progression pacing):** the owner, after the full
  arc: "we definitely get too powerful too quick ... think of the first
  time getting into a world and feeling like exploring, originally without
  danger, figuring out you can't break stone without a tool ... more like
  early MMOs in terms of combat where there's lots of mobs and it takes a
  while to kill things ... I'd rather our combat start a bit more powerful
  though but none of the interactions or powerful +1s ... early item mods
  are more defensive, or small additions to damage (outside of really
  lucky drops) ... some sort of support style skill category ... I don't
  just want it to copy POE." The survey showed the curve was short because
  the floor sat at the ceiling (a day-one Heavy Strike two-shot every
  era-one mob). Accepted and landed the same day: **long fights** (mob
  life ×2.5, mob damage ×0.7, player numbers untouched, bosses untouched,
  oracle rates in band), **the quiet heartland** (the first danger ring at
  a third density, hostile packs 40 m off the door, grazers placed by
  their own rule inside it), **the era-one pool** (`from_tier` on every
  interaction modifier; sceptres' implicit a small cold add, not a fork;
  damage tiers 5-10 / 15-25 / 30-45 %), and **fire-setting** as the first
  capability gate — the owner found the pickaxe "played out" ("almost
  every survival craft game is sticks trees and rocks"); of the
  alternatives offered (fire-setting, frame-to-cut, can't-carry, places
  teach, creatures as excavators) they chose fire-setting: a campfire laid
  from a fuel family heats the rock beside it, cold cracks what is hot,
  cracked rock digs by hand; wood fires crack stone and iron, charcoal
  reaches the alloy ores; bedrock never. **Skills on the Foundry plate**
  (a skill tablet laid on the plate is supported by the ingots touching
  it) is the accepted support direction, to build next; "manners learned
  from mobs" is the accepted source of later supports.

- **D-021 (3 Sep 2026, masonry is the unlock, not stone):** the owner,
  on the fire-setting gate: "doesn't scratch the itch as I don't want to
  enforce a cold aspect to crack stone and doesn't really scale to mid
  game"; they brought a second opinion whose reframe we adopted — ask "why
  is stone not yet a practical building material" rather than "how do I
  stop the player mining." Accepted and landed: **fieldstone** (boulders by
  hand; lays only a footing and a dry wall, `only_for_trait: rough`, never
  a house), **stone seams** worked with hand-made **timber wedges** (E
  drives a wedge over four presses; a heavy blow drives it at once; a hot
  seam splits whole under one blow), **the mason's yard** (a kit station
  that dresses two split stones into one stone; the forge kit's eight
  stone is the first masonry ambition), the stone creatures paying split
  stone, cracked strata paying split stone, and iron by hand. Fire-setting
  stays as one material response: hot rock is softened, and impact or cold
  cracks it; nothing needs cold. Two rules written down: **materials have
  responses, skills have properties** (one grammar for enemies and the
  world), and **Baseline, Exploit, Synergy** — E always works, a skill
  property shortcuts it, two properties do better; exploits buy time or
  yield, never access. The first strike-driven split is a Foundry
  milestone (`work:strike_split`). Archetype-specific work (an archer's
  precision) waits until the grammar proves itself in play.

- **D-022 (3 Sep 2026, skills on the plate):** the owner asked for a
  support-style category attached to a main skill that does not copy Path
  of Exile's gems, and worried about action-bar space; they could not find
  the plate in play (it opened only from the forge, behind the yard) and
  it held no skills. Landed: skill tablets on the Foundry plate, ingots
  beside a tablet supporting that skill alone (tag-checked, ×2, free to
  lift), F opening the Foundry anywhere, the first dressed block as a
  milestone. Manners learned from mob families remain the accepted source
  of later supports.

## Registering a decision

Add an entry when a choice materially affects player experience, save data, system boundaries, architecture or prototype scope. Create a separate ADR when the rationale, alternatives or consequences require more than one table row.

Never rewrite the meaning of an accepted entry without recording what superseded it.
