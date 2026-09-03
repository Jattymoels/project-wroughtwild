# Items and Modifiers

**Status:** Accepted direction (D-014, owner answers 1 September 2026); slice 1 implemented  
**Owner:** Unassigned  
**Related decisions:** D-007 (open), D-012, ADR-0002 (proposal C, provisional), D-014 (proposed)  
**Related documents:** [skill-grammar.md](skill-grammar.md) (the design space this spec builds from), [combat-and-builds.md](combat-and-builds.md), [loot-and-currency.md](loot-and-currency.md), [interface.md](interface.md)

## Purpose and player fantasy

Path of Exile's persistent build expression, felt in first person: a drop or a
craft changes *how you move* against a train, not just how big a number is
(D-012). The player should be able to say, after any session, "I got stronger
because this item made my orb fork twice" — design pillar 5 (power spikes are
felt) and the slice criterion "a tester can state why they became stronger".

## Prototype scope (the Wave 2 slice)

The smallest itemisation that lets **two archetypes** from skill-grammar.md be
assembled from gear — Glacier (freeze-shatter, the owner's example) and
Wildfire or Redline — on top of the machinery that already exists
(`items.json` property tiers, `ItemInstance`, `grammar.json` tag-targeted mods,
the increased/more resolver, catalyst tempering).

Included:

- **Three equipment slots:** `weapon` (new), `chest` (exists), `charm` (new).
  A weapon carries offensive implicits, chest carries defence, charm carries
  one build-defining mod. *(Since D-016 no slot grants a skill — skills are
  learned from pages; gear only scales them by tag.)*
- **Bases** (all craftable at the forge, all data): Iron Mace, Frost Sceptre,
  Iron Chest Armour (exists), Ember Charm. Wood and stone remain construction
  families; gear is iron with a catalyst-flavoured accent.
- **One modifier pool** replacing the two parallel schemas we have today
  (`items.json property_definitions` and `grammar.json skill_mods`): every
  modifier has `applies_to_tags`, an `effect` (`add_*`, `increased_*`,
  `more_*`) and `tiers`. Defensive properties are modifiers whose tag is
  `self` (max life, fire resistance). ~15 modifiers at launch, the minimum
  vocabulary from skill-grammar.md.
- **Rarity by modifier count:** *plain* (0 rolled), *keen* (1–2), *wrought*
  (3–4), plus **unique** — hand-authored items with legendary or weird
  interactions (owner direction: a unique bends a rule, e.g. "frozen enemies
  you shatter re-freeze their neighbours", "your forks fork"), authored one
  at a time in data with a `design_purpose`. No sockets ever (mods attach
  to tags).
- **Sources, in order of reliability:** craft a plain base at the forge →
  temper with a catalyst to add a *guaranteed-domain* mod (ADR-0002 C, as
  now) → trial room and boss rewards roll keen/wrought gear deterministically
  from the run seed → open-world packs drop keen gear rarely (rate in data,
  tuned in Wave 3 with elite modifiers). **Any modifier can drop** (owner
  direction): the catalyst's value is *targeting* — it guarantees the domain
  you need — not exclusivity. Uniques come from the trial (boss and, later,
  secrets), never from crafting.
- **Statuses and hooks** from the grammar: chill/freeze/shatter exist;
  Wave 2 adds ignite + proliferate and bleed (the training tax), each with a
  silhouette-visible greybox tell.
- **Balance sim** extended to find breakpoints ("chill per orb vs whelp freeze
  threshold") the way it tuned the Tyrant.

Excluded from the slice (deliberately): upskilling points (owner: hold off
until a later wave), rings/boots/helmet slots, item level/requirements,
sockets, trade, currency breadth beyond the two catalyst types (owner
direction, 31 Aug 2026).

## Implemented so far (slice 1, 1 September 2026)

- `items.json` v2: one `modifiers[]` pool (each with tags, `applies_to`, an
  effect key, tiers and a `design_purpose`), three `slots`, three
  `rarities`, five bases (Iron Mace, Frost Sceptre, Ember Wand, Iron Chest
  Armour, Ember Charm) with implicit modifiers. `grammar.json` no longer
  carries skill mods, and since D-016 no base has `grants_skill` — the
  loader rejects it.
- `sim`: `rollRarityItem`, `gearMods` (the active set from worn gear),
  `resolve` over magnitudes, `skillDamage`, `skillCooldownSeconds`,
  `deriveStats` via effect keys, pack items in the economy and the save,
  trial rooms dropping gear by reward type (`trial.json item_rewards`).
- Engine: pack screen item cards (rarity edge, stats, per-modifier
  sentences, wear / take off), plain crafted gear wearable from its stack,
  reward notices name the drop, recipes for the mace, sceptre and charm.
- Not yet: the weapon gating which skills are on the bar, world drops
  from packs, the compare view, removal of the F1–F3 debug toggles.
- **D-019 (3 Sep 2026):** tiers carry breakpoints (mechanics, not only
  numbers), bases cap the tier their metal can express, rolls above the
  cap are held back until a Preserving Transfer moves them to a base that
  holds them, and drop tiers are era-bound. See
  [progression-eras.md](progression-eras.md).
- **Uniques: deferred by the owner (1 Sep 2026, "keep them noted").** The
  intent stays on record: hand-authored items whose modifier bends a rule
  rather than a number (candidates: "shattered enemies re-freeze their
  neighbours", "your forks fork", "chill also slows your cooldowns down
  and your enemies more"). They need engine hooks beyond the resolver, so
  they arrive after the core loop is judged, not before.

## Inputs and outputs

| Inputs | Outputs |
| --- | --- |
| Crafting: recipes producing plain bases (needs the forge, Blacksmithing level) | An `ItemInstance` in the pack |
| Catalysts (trial-sourced currency class) + forge processes | A guaranteed-domain modifier on a worn item |
| Trial rewards, mob loot tables (seeded) | Keen/wrought items with rolled modifiers |
| Worn items across the three slots | Derived stats (life, armour, resistances) **and** the active modifier set every skill resolves against |
| Boons (temporary, per run) | The same modifier set, added for the run only |

## Rules and state transitions

Accepted already (in code):

1. An item is `base + implicit properties + rolled properties`; rolls are
   deterministic per seed; tempering never lowers an existing roll
   (`items.cpp`).
2. Skill numbers are resolved by the sim from base skill × active mods, with
   `add_*` flat, `increased_*` summed within its bucket, `more_*` multiplied
   (`grammar.cpp`). The engine expresses the result in space and time.

Proposed for Wave 2:

3. **One pool.** `items.json` gains `modifiers[]`; `property_definitions` and
   `grammar.json skill_mods` migrate into it. A modifier:
   `{id, display_name, applies_to_tags, effect: {key: value_at_tier}, tiers:
   [{tier, minimum, maximum}], weight, design_purpose}`. `applies_to_tags:
   ["self"]` marks a defensive stat.
4. **Active modifier set = worn items' rolled + implicit mods ∪ run boons.**
   The `active_skill_mods_` spike scaffolding (F1–F3) is removed once the
   Frost Sceptre and Ember Charm exist; the inventory screen shows the set.
5. **Rarity is count, not a stat:** plain 0, keen 1–2, wrought 3–4 rolled
   mods, each distinct, each tier-rolled by the source (trial stage index or
   pack tier decides the tier band; data).
6. **Skills are found, not worn** (D-016, superseding slice 1's "weapon
   decides delivery"). Skills stay data in `skills.json` with a `delivery`,
   tags and a `drop_weight`; the starting four fill the free bar and the
   rest arrive as mob-dropped skill pages. Gear never puts a skill on the
   bar — its modifiers scale whatever tagged skills the player fights with
   (start-with-nothing still holds: the starting four need no gear at all).
7. **Equip anywhere from the pack** (the inventory screen), not only at the
   forge; tempering stays at the forge. Swapping returns the old item to the
   pack *with* its mods (the current "returns as a bare base" rule goes —
   losing a tempered item to a misclick is failure that teaches nothing).
8. **Boss status resistance** stays a day-one rule: `boss_buildup_multiplier`
   per status, and the shatter execute flag is off for elites/bosses.

## System relationships

Consumes: crafting recipes and Blacksmithing gates (crafting-and-skills.md);
catalysts and trial rewards (dungeon-runs.md, loot-and-currency.md); the
grammar resolver and status matrix (skill-grammar.md).
Supplies: derived stats and the active mod set to combat (combat-and-builds.md);
the reasons a player builds a forge, runs a trial, or walks into the wastes
(design pillar 4: building and combat share an economy); the content the
interface must make legible (interface.md).

## Tunable parameters

| Parameter | Meaning | Expected player effect | Initial test value |
| --- | --- | --- | --- |
| `rarity_mod_counts` | rolled mods per rarity | how much a drop can change a build | plain 0, keen 1–2, wrought 3–4 |
| `modifiers[].tiers` | value range per tier | the size of a felt spike | one tier per mod at launch, two for the Glacier line |
| `modifiers[].weight` | roll weight | which builds drops excite | equal, then bias toward the worn weapon's tags |
| `trial_reward_tier_by_stage` | tier band per room | why to push deeper | stage 1–2 → T1, boss → T2 |
| `pack_drop_chance_keen` | keen drop per kill | open-world excitement without invalidating the forge | 0.03 |
| `boss_buildup_multiplier` | status build-up on bosses | bosses can be chilled, not permafrozen | 0.25 (exists) |

## Feedback and interface

See [interface.md](interface.md). The minimum: an **item card** (name, rarity
colour, implicit, each mod as a sentence — "+1 fork to projectile skills"),
a **compare** against the worn item, and the active modifier set visible on
the inventory screen so a tester can answer "why am I stronger".

## Failure cases and exploits

- **Multiplier runaway:** guarded by increased/more; the balance sim asserts
  no two-item combination exceeds a damage ceiling per stage.
- **Drops invalidate infrastructure:** capped by tier bands — world drops
  never exceed T1; T2 requires the forge or the boss (loot-and-currency.md
  philosophy).
- **Readability soup:** one accent colour per damage type; a mob shows at
  most one status silhouette; cascades shrink per generation.
- **Irrelevant slots:** a slot nobody fills within a session is cut, not
  padded with filler mods.

## Acceptance criteria

- [ ] Two archetypes are assemblable from gear alone within one slice run
      (Glacier and one other), verified by a scripted headless run.
- [ ] Every modifier is data with a `design_purpose`; the resolver has a
      `tests/sim` case per effect key.
- [ ] A tester can read an item card and state what it changes.
- [ ] Swapping equipment never destroys a tempered item.
- [ ] The balance sim reports the freeze breakpoint (orbs to freeze a whelp)
      for the plain, keen and wrought Glacier sets.

## Owner answers (1 September 2026) — now D-014

1. Slots: weapon / chest / charm for now.
2. Rarity names confirmed (plain / keen / wrought), **plus a unique tier**
   with legendary or weird interactions.
3. Weapon decides delivery — not answered explicitly; rule 6 stands as the
   working assumption until the owner objects.
4. Random drops **can** carry any modifier; catalysts exist to *target* a
   domain when you need a guarantee, not to gate modifiers.
5. Upskilling points wait for a later wave.
