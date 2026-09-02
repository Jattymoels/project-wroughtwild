# The Skill Grammar — First-Person Build Composition

**Status:** Ideation for Wave 2 (owner-directed, 1 September 2026); the
first grammar slice is implemented (2 September 2026) — see
[Implemented](#implemented-the-wave-2-grammar-slice-2-september-2026).
**Related:** D-012 (first-person, trainable hordes), D-016 (skills are
found, not worn), roadmap Waves 2–4,
[combat-and-builds.md](combat-and-builds.md).

## The thesis

The game's identity risk and its biggest opportunity are the same thing:
PoE-depth build composition delivered in first person. The composition
system must produce the moment the owner described:

> Hit the pack with an orb that forks through the mob and freezes them,
> shatter the frozen with a second spell that cones outward — then scale
> it: quicker freeze, longer forks, wider cone, more damage.

Everything below decomposes that sentence into data-driven parts.

## Core insight: your build decides how you train

In CoD Zombies everyone trains the same circle. Here, the geometry of your
damage dictates the geometry of your herding — the same mobs demand a
different dance per archetype:

| Build geometry | Wanted train shape | The dance |
| --- | --- | --- |
| Cone / nova | Tight ball | Classic Zombies circling, then turn and delete |
| Piercing orb | Conga line | Run straight, turn, bowl through the column |
| Chain | Loose spread | Gaps to jump; over-bunching wastes chains |
| Ground effects | A corridor | Paint the floor, lead the train through it |
| Freeze | A wall | Frozen mobs stay solid: your damage builds cover |
| Knockback melee | A front | Shove the line, own the space |

This is replayability top-down ARPGs never get: in PoE you never had to
*move* differently per build. Here you do. Every mechanic added to the game
should be asked: **what train shape does this want?** If the answer is
"none", it is probably a stat, not a mechanic.

## The grammar

A combat action is a sentence with four slots. Each slot is data, each slot
is a modifier target, and the sim owns every number (ADR-0003).

### 1. Delivery — the spatial shape (engine expresses, data defines)

`bolt` (fast single projectile) · `orb` (slow, travels through) · `cone`
(the Wave 1.5 area strike) · `nova` (ring around self — wants to be
surrounded: deliberately terrifying in first person) · `beam` · `ground`
(patch/trail) · `strike` (melee arc). Spatial parameters: speed, width or
angle, range, duration.

### 2. Propagation — what a hit does next

`pierce N` · `fork N` (split to N new targets on hit) · `chain N` (jump to
nearest untouched) · `cascade` (re-cast a smaller copy at the impact point;
shrinks per generation) · `echo` (repeat after a delay). Propagation is what
makes a train light up, and each kind prefers a different train shape.

### 3. Payload — damage and status buildup

Damage packet (type mix: physical/fire/cold/…) plus **status appliers**.
Statuses are the glue between skills and must be silhouette-visible on the
mob (greybox: frozen = blue crystal shell, ignited = flame rim, bleeding =
red drip, poisoned = green haze):

- **chill → freeze**: buildup stacks; crossing the threshold freezes.
  Frozen mobs are solid obstacles (emergent chokepoints from your own
  damage). Sets up shatter.
- **ignite**: burning DoT; sets up proliferation.
- **bleed**: DoT that ticks harder while the mob moves — a *training tax*:
  tag the train, keep it walking, let it melt behind you.
- **poison**: stacking DoT for tanky elites; the patient archetype.
- **knockback / stagger**: physical space control.

### 4. On-event hooks — the combo makers

`on_frozen_shattered → cold nova at the corpse` ·
`on_ignited_death → proliferate ignite to neighbours` ·
`on_kill → trigger skill X` · `on_bleeding_hit → amplified damage`.
Hooks are why two skills become one build: freeze feeds shatter, ignite
feeds the chain reaction that eats a train from the front backwards.

### The owner's example in grammar form

`orb + fork(2) + chill payload` → freeze threshold crossed →
`cone + shatter hook` → shatter novas cascade down the frozen line.
Scaling axes, each a separate mod target: chill buildup rate / freeze
duration / shatter radius; fork count / fork range / damage retained per
fork; cone angle / cast speed / cold damage.

## Where mods come from (no gem sockets needed)

One modifier pool, many taps — all resolving identically in the sim:

- **weapon implicits** (a frost sceptre grants `+1 fork to cold skills`),
- **armour/gear affixes** (the Wave 2 itemisation pass),
- **upskilling points** (permanent, the "where do I spend" question),
- **trial boons** (temporary, already built — see below),
- **catalyst-crafted affixes** (the ADR-0002 currency class, later).

Two schema rules to lock in from day one:

1. **Mods attach to tags, not skills.** "+1 fork to `projectile`", "20%
   wider `cone`", "chill 30% stronger". A random drop can excite any build
   sharing the tag — PoE's cross-pollination without its socket UI.
2. **`increased` vs `more` from the start.** Additive within a bucket,
   multiplicative across buckets. It is the only proven cure for runaway
   multiplier compounding, nearly free to adopt now and brutal to retrofit.

**The machinery already exists.** Boon `effects` operations
(`repeat_every_nth_hit`, `damage_multiplier_against_isolated`) *are*
support mods: tag-gated, sim-resolved, engine-expressed. Wave 2 grows that
vocabulary from ~5 operations to ~25 and lets gear supply them permanently,
not just boons temporarily.

## Archetype seeds (slice-scale, one line each)

- **Glacier** — chill/freeze/shatter control; builds walls, fights behind
  its own ice. (The owner's example.)
- **Wildfire** — ignite + proliferate; light the head of the train, walk
  away while it burns backwards.
- **Redline** — attack/cast speed + bleed; face the train and drill
  through it head-on.
- **Stormcaller** — chain; wants spread, punishes over-bunching, the
  contrarian trainer.
- **Bulwark** — knockback/stagger melee; owns a doorway like a wall of
  steel.

Five dances, one world. The slice does not need five finished archetypes —
it needs the grammar plus enough parts that two of these are assemblable.

## Minimum vocabulary for the slice (scope guard)

PoE ships ~250 skills × ~130 supports. The Wave 2 slice needs:

- 3 deliveries (orb, cone, ground), 3 propagations (pierce, fork, cascade),
- 3 statuses (chill/freeze, ignite, bleed), 2 hooks (shatter, proliferate),
- ~15 tag-targeted mods across gear/points/boons.

That already contains the freeze-shatter build, Wildfire, and most of
Redline. Breadth is content, not architecture; it can grow every wave.

## Feel: breakpoints over percentages

"Power spikes are felt" (design pillar 5). Prefer mods that cross visible
thresholds to mods that add invisible percent: the moment one orb freezes a
whelp in a single pass, the moment a fork reaches the *third* rank of the
train, the moment the shatter cone clears the screen. The balance simulator
should learn to find these breakpoints (e.g. "chill per orb vs whelp freeze
threshold") the same way it tuned the Tyrant.

## Known risks and their day-one countermeasures

- **Readability soup** (late-PoE particle blindness, worse in first
  person): statuses as silhouette changes not particle storms; cap
  simultaneous proc VFX; cascades shrink per generation; one accent colour
  per damage type, never mixed on one mob.
- **Boss trivialisation**: status resistance/diminishing returns on bosses
  in the schema from the first status (or the Tyrant dies permafrozen).
- **Multiplier runaway**: the increased/more split, above.
- **Performance**: propagation fan-out is capped per cast generation;
  greybox VFX are meshes and tints, not particle systems.

## Implemented: the Wave 2 grammar slice (2 September 2026)

**Skills are found, not worn (D-016).** Each skill is one entry in
`skills.json`: a `delivery` the engine dispatches on (`cone`, `strike`,
`projectile`, `dash`), tags, payload numbers, `starting` and `drop_weight`.
The starting four (Area Strike, Heavy Strike, Frost Orb, Dash) fill a free
four-slot bar; Ember Bolt, Rend and Frost Nova arrive as mob-dropped skill
pages (weighted among skills the player does not know — a page is never a
duplicate). Keys 1–4 cast the bar; Shift stays the dash reflex wherever
Dash is slotted; the pack screen (I) assigns slots. Known skills and the
bar are in the save (an old save resets to the starting loadout). Gear
never grants a skill; hooks trigger by tag, never skill id — so a page
found tomorrow joins the combos it is tagged for, which is the whole point.

In play: three statuses (chill/freeze, ignite, bleed), two hooks (shatter,
proliferate), forking, and per-skill spatial overrides (Frost Nova is a
`cone` whose `cone_degrees` 360 makes it a ring). Statuses read on the mob
silhouette: ice blue, flame rim, blood dark. The one deliberate deviation
from the ideation list: `dash` replaced `ground` as the fourth delivery for
now — ground patches want the Wave 3 mob pass to matter.

**Where every number lives** (all tunable without touching code):

| Knob | File | Keys |
| --- | --- | --- |
| Skill payloads, cooldowns, drop weights | `skills.json` | `combat_skills[]`: `base_damage`, `chill_buildup`/`ignite_buildup`/`bleed_buildup`, `fork_count`, `cooldown_seconds`, `starting`, `drop_weight` |
| Status thresholds and DoTs | `grammar.json` | `statuses.*`: `buildup_max`, `decay_per_s`, `freeze_duration_s`/`duration_s`, `damage_per_s`, `moving_multiplier` (bleed), `boss_buildup_multiplier` |
| Shatter | `grammar.json` | `hooks.shatter`: `trigger_tags` (attacks), `nova_damage`, `nova_radius_m`, `executes_frozen`, `executes_boss` (false: a frozen boss takes the nova and thaws) |
| Proliferate | `grammar.json` | `hooks.proliferate`: `enabled`, `radius_m`, `spread_buildup` |
| Tag-targeted modifiers | `items.json` | `modifiers[]`: `applies_to`, effect key (`add_*`/`increased_*`/`more_*`), tiers |
| Projectile/arc space | `combat_realtime.json` | `skills.<id>`: `speed_mps`, `hit_radius_m`, `max_range_m`, `fork_range_m`, `cone_degrees` override |
| Drop chances | `world.json` | per-enemy loot: `{"gear": rarity, "tier", "chance"}`, `{"skill_page": true, "chance"}` |

Resolution is the day-one rule throughout:
`(base + Σadd) × (1 + Σincreased) × Π(1 + more)` over mods whose
`applies_to` tags intersect the skill's tags. A flat `add_<status>_buildup`
roll gives a payload to a skill that lacks it (a Frostbite mace chills with
plain strikes) — cross-pollination without sockets.

## What this means per wave

- **Wave 2** implements the grammar's sim side (statuses, hooks, tag-mod
  resolution, increased/more) + the minimum vocabulary + gear that carries
  mods. Balance sims extend to status/propagation breakpoints.
- **Wave 3** tunes mob life/resists per status archetype and adds
  elite modifiers that interact with statuses (e.g. "Unfreezable",
  "Ignite-immune husk") so builds meet resistance, PoE-style.
- **Wave 4** lets boons and dungeon modifiers bend the grammar (the
  roguelite: "your forks chain", "frozen enemies explode twice").
