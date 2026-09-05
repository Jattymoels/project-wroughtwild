# Decision Registry

Owner follow-through, 5 Sep 2026: “Lets do it” approves the next building
usability pass: visual selection, roof/corner orientation and actionable placement
feedback. Tab while building now opens the catalogue. Existing construction
rules and unlocks remain; [implementation](../art/codex-building-usability-2026-09-05.md).

Owner prioritisation, 5 Sep 2026: gathering feedback is paramount, followed by
building usability, combat feel and reasons to explore. Ranged-mob dodge/damage
concerns and a separate intensive skill-variety task are recorded for later work
in the [playtest priorities](../prototype/playtest-priorities-2026-09-05.md).
This approves the presentation follow-through; new skills and combat rules are
not selected by this prioritisation.

Owner clarification, 5 Sep 2026: “I wanted the improved building look too”,
including the octagonal build. This adopts the workshop's building materials,
chamfer blocks, triangular slabs and three roof transitions into normal play.
The corner/slab costs mirror existing cube/slab costs; pitched roofs keep the
existing stonecut unlock and wedge cost, with joinery materials for timber roofs.
The five existing study IDs are retained. This supersedes the earlier lab-only
building/catalogue statements below. [Implementation](../art/codex-normal-building-2026-09-05.md).

Owner revision, 5 Sep 2026: nighttime cold exposure is disabled for now
(`world.json` `day.exposure_life_per_round = 0`), superseding the earlier
forced-return health drain. Night lighting, enemy behaviour and faster shelter
healing remain. The owner also identified the missing workshop station visuals:
the workbench, mason's yard and forge art is now shared with normal placed
stations rather than confined to the roof-workshop study. The demonstration
building and roof catalogue remain a separate lab; station rules are unchanged.

Owner approval, 5 Sep 2026: “Yep work through those 4” approves first-person
presence, habitat variety, recognisable places and equipment comparison.
This continues D-013 presentation and the existing interface/itemisation scope.
The implementation improves existing landmark sites and adds decorative rotten
debris, without new progression, yields or save fields.
[Evidence and limits](../art/codex-frontier-continuation-2026-09-05.md).

Latest owner refinement, 5 Sep 2026: preserve the stronger meadow image; improve
the quality of rock/soil/turf transitions and replace the amateurish loose-stone
scatter. This is a further D-013 presentation refinement, not a world-generator
or gameplay change. [Evidence](../art/codex-material-joins-2026-09-05.md).

Owner follow-through, 5 Sep 2026 (D-013 presentation): retain smoother terrain
silhouettes but add material definition and ground detail in response to the
owner's screenshot of bland grey/soil bands. Continue prototype character
silhouettes, bounded enemy labels, terrain-shadow review and startup optimisation.
Implementation evidence: [surface/character pass](../art/codex-surface-character-2026-09-05.md).

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
| D-004 | Classes | Starting class leads toward a guaranteed class hall providing another vertical progression path. Made concrete 4 Sep 2026 (D-023 slice 9): the class is chosen before play and its two rail patterns are the Foundry plate's surround from era one; completing the first trial (the Tyrant's forge, standing in for the hall) offers a specialisation that shows what each pattern becomes. The class also sets the starting skills (owner, 4 Sep 2026, later: "more initial skills, not frost orb - a bow shot, or a strike for warden"): the Ranger's Bow Shot, Rend, Area Strike; the Warden's Heavy Strike, Area Strike, Frost Nova; the Kindler's Ember Bolt, Cinder Sweep, Frost Orb; everyone's Dash. The class hall stays documentation for now (owner, 4 Sep) | Accepted direction | The class hall is built as an authored module; deeper trials as later specialisations |
| D-005 | Settlements | Encourage small resource outposts before an ambitious main settlement; unlock fast transport and logistics | Accepted direction | World scale and travel time are measurable |
| D-006 | Death | Trials protect stored possessions; open-world death drops carried inventory; binding eventually protects important gear | Provisional | Death and recovery playtest |
| D-007 | Crafting economy | Combine physical materials and infrastructure with rare crafting catalysts from combat and exploration | High-priority open | Itemisation prototype begins |
| D-008 | Input | Initial building interface targets mouse and keyboard only | Accepted | Controller scope is considered |
| D-010 | Combat | The sim owns combat numbers (derived stats, mitigation, boon mods, per-hit damage, trial structure); the engine owns time and space (movement, hitboxes, timers); `round_seconds` bridges the two clocks; the round-based encounter stays the balance oracle ([ADR-0003](ADR-0003-combat-authority.md)) | Accepted | Real-time feel needs a rule the round model cannot express, or a second combat archetype is added |
| D-011 | World shape | The world is an open sandpit with no quest-hub town: Valheim/Minecraft moment-to-moment feel (start with nothing, harvest, build, get jumped), PoE/Diablo-style mob packs and itemisation in the open world, roguelite dungeons as the innovation layer; development proceeds in the four waves of [prototype/roadmap-waves.md](../prototype/roadmap-waves.md) | Accepted direction | Sandpit playtest (end of Wave 1) |
| D-012 | Combat perspective | Combat is first-person (a third-person toggle may remain for greybox debugging): the build clears hordes but the player only engages what is in front of them, trading PoE's screen-clear for personal-scale danger. Horde pressure is CoD-Zombies-style: open-world mobs are deliberately "stupid zombies" — persistent chasers that bunch up and can be trained by a player who stays close — but aggro is NOT eternal: genuinely running away breaks the chase, at the cost of a dangerous disengage. Build expression comes from damage *mechanics* (cone/cleave AoE, ground effects the train is led through, bleed/poison/ignite tag-and-run, chill/freeze choke-making, single-target speed) rather than raw numbers; the mechanic vocabulary arrives with Wave 2 items and Wave 3 mobs, horde/wave rooms with Wave 4. Dungeon AI may later become smarter than the open world's — a deliberate contrast, not an accident | Accepted direction | First-person greybox playtest (Wave 1.5) |
| D-013 | Art direction | Owner revision, 5 Sep 2026: weathered frontier, dark thresholds ([art/art-direction.md](../art/art-direction.md)). The crafted pass is approved for main; move away from its cartoon feel toward earthier colour, stronger shape and restrained light, while remaining lighter than the owner's V Rising/Valheim reference. Softer editable terrain, legible daylight, distinct biome danger and the established bloodless VFX remain. This supersedes the 1 Sep storybook saturation/cubic-only presentation; the original brief is retained in the art document. Roof unlocks and contour generation remain studies | Accepted direction (owner revision, 5 Sep 2026) | Player-height review and a longer varied field playtest |
| D-009 | Engine | Godot 4.5-stable (`4.5.stable.official.876b29033`) is the prototype engine; the engine project lives in `game/`, gameplay rules stay in the engine-neutral `sim/` library bound via GDExtension; `godot-cpp` is the only approved third-party dependency ([ADR-0001](ADR-0001-engine-selection.md)) | Accepted | Terrain scale, world streaming, construction density or visual targets outgrow Godot (ADR-0001 exit condition) |
| D-014 | Itemisation | Wave 2 scope per [systems/items-and-modifiers.md](../systems/items-and-modifiers.md): one modifier pool where mods attach to tags (never sockets) with the increased/more schema; three slots (weapon, chest, charm); rarity by rolled-mod count (plain / keen / wrought) plus hand-authored uniques with rule-bending interactions; any modifier may drop — catalysts target a domain rather than gate it; the weapon carries the delivery skill (working assumption); equipment swaps never destroy a tempered item; upskilling points wait for a later wave | Accepted direction (owner answers 1 Sep 2026) | The first keen/wrought/unique items are playtested |
| D-015 | Interface | Per [systems/interface.md](../systems/interface.md): four layers only — HUD (life bar, action bar, holdings strip, notices, crosshair), pack screen (I), one work-panel type (cards in a scroll area), help overlay (H); the mouse is captured unless a panel needs it; panels never compute rules and every panel is a headless test surface; one code-built Theme from the master palette | Proposed (first slice implemented 1 Sep 2026) | Owner plays the first interface slice |
| D-016 | Skills | Skills are found, not worn (supersedes D-014's "the weapon carries the delivery skill" working assumption, per owner direction 2 Sep 2026: PoE's many-skills-with-interacting-grammars over gear-defined archetypes). Each skill is one data entry in `skills.json` — delivery (cone / strike / projectile / dash), tags, payload numbers; the starting four fill a free four-slot bar and the rest are learned from skill pages that mobs drop (weighted among unknown skills, never duplicates). Gear only ever scales skills through tag-targeted modifiers; hooks (shatter, proliferate) trigger by tag, never by skill id, so a page found tomorrow joins the combos it is tagged for. Build identity = the tags on the bar. Statuses are buildup-with-threshold (chill/freeze, ignite/burn, bleed) with the day-one boss resistance multiplier; shatter never executes a boss (`executes_boss` tunable, default false) — the freeze window is the reward | Accepted direction (implemented 2 Sep 2026) | Wave 3 mob families stress the grammar, or a skill that cannot be one data entry appears |
| D-017 | Building | Pieces are addressed by lattice element, never by cell-plus-slot: a block occupies a cell, a wall or floor a face two cells share, a post or beam an edge four cells share, each with one canonical address (`sim/lattice.h`). The single placement rule is "the nearest free element of the piece's kind to the crosshair"; orientation comes from the element, so only oriented blocks turn with R; two pieces conflict only when they want the same element. Corners where walls end or meet grow a post visual on their own. No structural-support rules — the lattice's shape is all the physical honesty a build needs ([systems/construction.md](../systems/construction.md)) | Accepted direction (owner "lets do it" 3 Sep 2026; slice 1 implemented) | The owner's building playtest, or a piece that cannot be one element (diagonals, curves) |
| D-018 | Building materials | Building families are data with a source item, a look and **traits**; shapes require traits, so a material's properties gate the forms it can be worked into (joinery for doors, masonry for cut stone, metal for spans, malleable reserved for the coming alloy and its curved forms) rather than a tech tree. Placed pieces are never demolished by mobs: a timber house is a house at every tier (owner, 3 Sep 2026); base threat is pressure around the build, not damage to it ([systems/construction.md](../systems/construction.md)); the encroachment nests built on this were retired 4 Sep 2026 (D-024) | Accepted direction (owner steer 3 Sep 2026; three families + girder implemented) | An alloy family lands, or the base-threat design is playtested |
| D-019 | Progression | Per [systems/progression-eras.md](../systems/progression-eras.md): **eras are the campaign** (the world changes state on player-chosen milestones; mobs scale per era, never per player; no zones unlock), **the Foundry** is the point system (ingots placed on a forged plate; adjacency, lines, wrought forms; refinement widens reach, numbers stay flat; respec is re-forging), and **ores are properties, not ranks** (one trait vocabulary across building materials, item bases and ingots; modifier tiers are mechanic breakpoints; held-back modifiers as the early taste; a threefold global number budget). Encroachment belongs to era two | Accepted direction (owner "lets do it" 3 Sep 2026) | The first era transition is playtested |
| D-023 | The Foundry | Per [systems/foundry.md](../systems/foundry.md): the plate is worked in **workings** - a **subject** (a skill tablet, or a typed currency: the **Vanguard** for defence, later Marrow for life and Quicksilver for tempo) sits in a **socket** the era forges; the ingots orthogonally beside it are **supports** whose reading the subject decides (the same Frost ingot is cold damage beside a skill, cold resistance beside a Vanguard); the four **corners** hold ingots (pairs, backing) or currency as **augments** (a Catalyst works a support into a cross-element reaction such as Scald; a Vanguard lends the supports its defensive reading); subjects side by side **link**; class and mob-family manners live in **rails** on the rows and columns. Trade currency splits into typed kinds that serve both crafting (aiming a roll at a modifier family) and the plate | Accepted direction (owner answers 3 and 4 Sep 2026, "start slice one" 4 Sep 2026); slice 1 (the frame, sockets, backing, Reach), slice 2 (every ingot reads every skill: added elements as typed packets, the self ingots' weak readings, mob resistance by packet type) slice 3 (typed currency: the coin retired for four kinds the families pay, the peddler changes, a craft is aimed with and rare metal casts) slice 4 (the Vanguard as a socketed subject, withdrawn the same day) slice 5 (the flow: only skills in sockets; kinds in the detached cells giving their base forward and working the supports they touch into forms - the Catalyst's sharpenings and reactions, the Vanguard's defensive twists) slice 6 (kinds as lists of variants with a base each; Echo, Quench, Rime, Sear and Brittle as engine hooks) slice 7 (links re-homed to the corner beyond a shared support, casting on trigger at the struck enemy; Arc), slice 8 (the Marrow's sustain forms and the Quicksilver's tempo forms with their hooks) slice 9 (rails: the class's surround from the start, a specialisation at the trial that says what each pattern becomes; two manners) and slice 10 (the metal of an ingot: re-cast at the forge in the era's alloy, reach for backing and pairs, alloy-cast ingots from elites and the deeper forge, compound forms on the metal) implemented 4 Sep 2026; the remaining interactions are proposed | The frame is playtested; the first corner augment lands |
| D-024 | Base threat | Nests (encroachment slice 1, D-018) retired: the owner (4 Sep 2026) found them "not rewarding" and that they "don't feel natural to the world"; mob AI behaviours are to be reassessed later, and the base threat waits for that. The sim module, the engine's nest and encroachment scripts, the world.json block and the era flags are gone; the design record stays in world-generation.md | Accepted (owner, 4 Sep 2026) | Mob AI behaviours are reassessed |

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
  than zones unlocking. Encroachment slice 1 stayed merged as era two's
  mechanic until it was retired (D-024, 4 Sep 2026).

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

- **D-023 (3 Sep 2026, the plate as a working):** the owner, on the
  Foundry as the talent tree: "I was iffy on the Foundry process for a
  'talent tree' progression mechanic but I think I like it. It limits the
  amount of spells you can optimise, it also allows creativity in
  placement to optimise joins between ingot placements." Confirmed
  orthogonal-only supports ("not the entire tablet"), then set the
  direction: the plate has "designated spots for the 'active' thing being
  worked on ie skill or vanguard"; trade currency "can stop being a
  generic 'trade currency' resource and start to be properly split into
  things like catalysts, or vanguards (a defensive currency that imbues
  various list of defenses) and then similar for life, or speed", usable
  "in crafting gear to augment/weight towards certain modifiers or placed
  in the Foundry"; "the spare cells in the diagonals can be either placed
  with ingots or trade currency ... to augment the ingots" (the Scald
  example: an augmented fire ingot lets a frost skill ignite, and ignited
  enemies take extra cold); a vanguard in the middle makes every support a
  benefit to the character ("an 'incr armor' supported by a frost ingot
  provides additional cold resistance and reduction of chill effect");
  and class as row/column effects "exterior to the plate" you spec into
  ("for an archer one column effect ... gives '+2 projectiles shot if all
  placed spots are 'X' ingot"). Recorded and built out as proposals in
  [systems/foundry.md](../systems/foundry.md) with nine owner questions
  and a slice order; nothing is implemented. **Conflict found on the
  way:** the D-022 doc and commit say "Reach beside Frost Orb widens the
  orb", but the code marks Reach as a self stat that never supports;
  neither side was changed (AGENTS.md), question 3 in the spec.
  **4 Sep 2026:** the owner answered: sockets "fixed for now until we
  see how it feels", era one a two-row, four-column plate with two
  sockets (their sketch put them a row and two columns apart; the spec
  recommends a row and one column apart so both workings grow whole on
  the 4x4, the owner having invited push-back); the coin retired for now,
  "a coin/generated town for trading should be something in the future";
  Reach reads skills (settling the conflict above in the doc's favour,
  still to be implemented); class at the start with rails at the hall;
  augments as corner cells; the support and subject pick the reaction;
  Marrow and Quicksilver after the Vanguard. They also want progression
  gated on the plate's size and on ingot quality, type and rarity, taken
  up in the spec as the frame's rows and the metal of an ingot. Links and
  the folding of lines into backing are explained in the spec and await
  their answer.
  Later on 4 Sep the owner took the recommended socket layout and set
  one more rule: "I don't think we need to restrict 'cold damage incr' to
  only cold spells ... adding a cold damage on the spell means you might
  pursue different builds and head towards a 'boil' or 'scald' type
  build"; the same-element support is "augmenting one lane which may be
  better early". In the spec: every ingot reads every skill, an element
  ingot beside a skill of another element adds that element's damage as
  a second packet, the Catalyst turns the added element into its status
  and its interaction, and no support is ever inert. The owner then
  answered 4 (a linked skill leaves the bar: yes) and 6 (lines fold into
  backing: yes) and said "start slice one". **Slice 1 landed the same
  day:** the frame (`rows_by_era`, `sockets`), tablets only in sockets,
  backing in place of lines, Reach reading area, projectile and strike
  skills through a `reach` multiplier the engine applies, every reading
  written on its cell, stale saves lifted free on load. Sim tests pass
  (3216); the engine tests were rewritten to the frame and await a run on
  a machine with Godot.
  **Slice 2 landed 4 Sep 2026** on the owner's rule that every ingot reads
  every skill: the player's hit is a list of typed packets
  (`grammar::skillHit`; the hit stream rolls them as one hit); an element
  ingot beside a skill of another element adds its element as a second
  packet at the same fraction, scaled by that type's own gear and never by
  the skill's (a reading keeps its modifier's type and requires its
  skill's tag); Vigour, Plate and Ward read a skill weakly (a life on
  kill, four armour for two seconds after a cast, five percent less from
  an enemy carrying the skill's status); a mob takes its own share of
  each packet type (`damage_taken`) and the engine deals packet by packet
  (the Hollow Knight and the Cinder Wisp take a quarter of fire: they
  shipped fire-immune and the owner, the same day, asked for "heavy
  reduced damage taken by fire, not completely fire immune").
  The frame's engine tests ran on this machine first and passed unchanged.
  Sim tests 3294; engine unit 342, integration 217; all
  headless checks pass.
  **Slice 3 landed 4 Sep 2026** on the owner's "Lets do it ... dont
  overthink it, go ahead", with two notes for the record: drop rates are
  "real razorblade tuning", and the kinds might "also be crafted if enough
  rare resources are found". The coin is retired (its drops, the mine's
  reward, the forge upgrade and the peddler's prices are now kinds); five
  ids in four families (catalysts, Vanguard, Marrow, Quicksilver) are paid
  by the families whose nature they follow and once more by every elite;
  the peddler changes three of one for one of another; a kind added to a
  gear craft is spent to draw the first modifier from its family and lift
  a plain result to keen; three recipes cast the purse kinds from era
  three's steel and silver, catalysts never. Every rate is a first guess.
  Sim tests 3367; engine unit 345, integration 217.
  **Slice 4 landed 4 Sep 2026** ("okay go next slice"): the first currency
  on the plate. A Vanguard from the purse in a socket is a defence
  working (+8 armour, every ingot beside it read as defence at twice its
  Vanguard value: fire and cold resistance, Barbs, the answer's reach,
  life, armour, all resistances, haste after a hit); in a corner it gives
  half its base and lends its readings at x1 to the skill supports it
  touches; it lifts for the re-forge cost and returns to the purse, and a
  stale one goes back to the purse on load. Cold resistance joins the
  sheet; Barbs, Answer Reach and Haste are engine hooks. The readings'
  second halves that need statuses on the player wait. Sim tests 3409;
  engine unit 348, integration 220.
  **The flow, 4 Sep 2026, later.** The owner, shown the socketed Vanguard
  and the corner lending: "we just don't allow the non-skills to be
  placed in the main subject of the foundry tablet. So vanguards and
  catalysts can only go into the edge cases where they give forward their
  base to the flow of the tablet, but also transform/mutate along the way
  the ingots/other catalysts or vanguards/marrows etc until it hits the
  skill. We can leave scaling defenses to itemisation." And the line:
  "ingots are generally base, and catalysts add offensive creativeness,
  vanguards add creative defensives." **Slice 5 landed on it:** only a
  skill sits in a socket; a kind rests where it cannot touch one (depth
  two or more), gives its family's base forward only while a chain of
  pieces leads inward to a laid tablet, and works every support it
  touches into a form that feeds the skill (`forms`: the Catalyst's
  sharpenings and reactions as far as existing keys carry them, with a
  new "more against a status" resolution fed by the struck mob's
  statuses; the Vanguard's eight forms as proposals from the owner's
  Frost Leech and Max Speed). The socketed Vanguard is withdrawn; links
  need a new home. Sim tests 3418; engine unit 349, integration
  220.
  **Variants, 4 Sep 2026, later still.** The owner: "the 'Vanguard' is a
  list of various defensives - i.e. + armor, + dodge, + resistances, etc.
  Marrow can +life, +leach, +recoup, etc. Quicksilver, + move speed, +
  attack speed, + cast speed. I think that moves the catalysts into more
  'mechanical' changes, fire catalyst may be a 'augment fire' which has
  various cool effects like the scald. I think yeah they dont have a base,
  but they do cooler transformations." **Slice 6 landed on it:** `kinds`
  per currency id with its own base (the Warding Vanguard the first extra
  variant), forms narrowable to a variant, and the reactions' hook halves
  as engine hooks (Echo, Quench, Rime, Sear, Brittle). Sim tests 3447;
  engine unit 349, integration 220, grammar 52.
  **Slice 7 landed 4 Sep 2026** ("Keep going ... Continue to be creative
  with interactions"): the link re-homed to the flow - a Catalyst in the
  corner beyond a support two sockets share links the two skills, and
  when one's payload crosses a status threshold on an enemy the other
  casts itself at that enemy, off the bar, with its own cooldown, both
  ways; and Arc, Reach worked by a Catalyst beside a strike sweeping
  every enemy within reach and a metre and a half either side. Sim tests
  3469; engine unit 350, integration 220, grammar
  56.
  **Slice 8 landed 4 Sep 2026:** the Marrow's eight sustain forms and the
  Quicksilver's eight tempo forms (the spec's readings where a hook was
  cheap, proposals where it was not), with life on hit, a cooldown refund
  and a burst of speed on a kill, every heal amplified, and the Dash's
  reach, life, armour and recovery on the sheet. Taken before rails,
  which need D-004's class at the start and the class hall. Sim tests
  3511; engine unit 351, integration 220, grammar
  56.
  **Slice 9 landed 4 Sep 2026**, on the owner's answer that makes D-004
  concrete ("before you actually begin the game you choose a class, and in era 1 you can still access the plate/foundry, so that base plate's surrounding modifiers are determined by that first selection. Then once you complete trials you specialise further, getting a view of what the surround modifiers can become."): rails as the class's surround. The class - Ranger,
  Warden or Kindler, two patterns each - is chosen before play in its own
  panel; a pattern set in a rail reads its whole row or column and bends
  its rule while the line holds (one rail in era one, two in era two,
  three in era three, one per pattern); the Tyrant's forge is the first
  trial and its completion offers, once, one of the class's two
  specialisations, each a view of what every pattern becomes, the rails
  becoming with it; the Hound's and the Husk's manners are taught by
  kills and join them. The engine fans projectiles, pierces, counts
  armour against the elements, doubles and staggers the Barbs, spreads
  ignites on the hit, makes burning ground heal, punishes approach and
  rewards stillness. A first reading that put the class at the trial was
  corrected the same day. Sim tests 3587; engine unit 357, integration 224,
  grammar 63.
  **Slice 10 landed 4 Sep 2026:** the metal of an ingot, D-019's
  refinement. Every ingot is cast in iron; a built forge re-casts one in
  hand in the era's alloy (bronze, then steel) for one ingot of it, which
  never changes the number and widens how far its backing and pairs are
  read (one, two, three cells, never through a socket); the first elite
  hound, husk and knight and the deeper forge pay an ingot already cast
  in alloy; eight compound forms need the support cast in bronze or
  steel. The class hall stays a documented intent (owner, 4 Sep). Sim
  tests 3619; engine unit 358, integration 224, grammar 63.

## Registering a decision

### Owner-approved combat follow-up — 5 September 2026

The owner subsequently approved incoming-hit direction and existing weapon/cast
presentation. The [presentation report](../art/codex-combat-presentation-2026-09-05.md)
records the completed first-person feedback under D-010/D-012/D-013. The separate
skill-variety design remains unselected; no new skills or combat rules were added.

Following gathering and building usability, the owner approved addressing
undodgeable ranged attacks first. Under D-010 / ADR-0003, archers and wisps now
commit aim at windup start and release physical, cover-blocked projectiles;
the existing damage rules, cadence and movement-only dash remain. The
[implementation report](../art/codex-ranged-fairness-2026-09-05.md) records
the diagnosis, tuning and tests, plus the owner's X building-removal regression.
This does not accept the separately deferred skill-catalogue proposals.

### Experiment record — Codex, 5 September 2026

The owner authorised aesthetic experiments before progression retuning.
[Codex's report](../art/codex-aesthetic-experiments-2026-09-05.md) records the
opt-in material comparison and block-based octagon feasibility test. Author
and implementer: **Codex (OpenAI), not Claude**. This is an experiment record,
not a new accepted decision: D-013 remains the default art direction, and
D-018's conflict with siege demolition remains unresolved. No D-025 was
accepted or created by this work.

The owner subsequently asked Codex to continue these recommendations. The
[continuation report](../art/codex-aesthetic-intensive-2026-09-05.md) records
faceted terrain, an isolated contour profile and the larger octagonal workshop
with corner-aware shelter. These remain experiments under that authorisation;
the default art direction, ordinary shape unlocks and siege policy are unchanged.

The owner then authorised the next aesthetic steps. The
[crafted frontier report](../art/codex-crafted-frontier-2026-09-05.md) records
calmer terrain lighting, branching trees and an editable modular-roof workshop
with its own save. This remains an experiment record, not adoption of a new
art policy, construction unlock or siege decision.

The owner then explicitly approved merging `92313d5` into `main` and requested
a less cartoon-like art direction. The local merge and subsequent
[weathered frontier pass](../art/codex-weathered-frontier-2026-09-05.md) are
recorded under the revised D-013 above. This supersedes the earlier opt-in-only
status for the sandpit presentation; the roof catalogue remains a separate lab.

### Owner-directed skill expansion — 5 September 2026

After playtesting the combat presentation, the owner requested skill expansion,
progression and catalysts/Kinds serving bow and melee beyond Ember/Frost. The
[implementation work item](../prototype/skill-expansion-2026-09-05.md) supersedes
the earlier deferral of skill variety: six discoverable skills, five variants
within the existing four Kind families, and an in-pack progression guide under
D-016/D-019/D-023. Existing pages, mastery, class kits, alloys and era gates are
the progression structure; names and numbers are provisional playtest tuning.

The reload audit also exposed generic starting skills being added to Rangers,
contrary to class-kit behaviour. The owner explicitly approved fixing future
reloads while keeping all already owned skills. Saved discoveries remain and
only the chosen class's kit is ensured on reload. No save-schema change.

### Procedure

Add an entry when a choice materially affects player experience, save data, system boundaries, architecture or prototype scope. Create a separate ADR when the rationale, alternatives or consequences require more than one table row.

Never rewrite the meaning of an accepted entry without recording what superseded it.
