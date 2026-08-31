# ADR-0002: What a Crafting Catalyst Actually Does

**Status:** Proposed — awaiting owner acceptance. D-007 remains open until then.
**Decision owner:** Human project owner
**Prototyped:** Proposal C is implemented provisionally (flagged in code and
data) so the text playtest and balance simulations can exercise the full loop.

## Owner direction (31 August 2026) — scope of this ADR

The owner has narrowed what this ADR is allowed to decide:

- **Catalysts are a farmable currency class, not singular treasures.** In the
  full game they behave like Path of Exile's orbs: stackable dungeon-farmed
  currency items, many types, sitting alongside world-gathered materials as
  the second input stream into crafting. The "one precious catalyst"
  ceremony in the slice (guaranteed shrine drop, kept on death) is
  first-catalyst onboarding, not the steady-state economy.
- **This ADR therefore decides only the *verb shape* for catalyst-type
  items** — what applying one does to an item. It does not decide the
  economy: number of currency types, drop rates, stack sizes, fungibility or
  trade are all deliberately deferred until the core loop is proven
  (prototype boundary: no content breadth).
- Mid/late-game crafting optimisation is explicitly **not** a current goal.

Note that PoE's orbs are themselves "guaranteed verb, random outcome"
mechanics (an Orb of Alchemy always rarifies but rolls the mods), so the
currency-class model is compatible with Proposal C below; new catalyst types
later are new rows in `catalyst_processes`, each with its own verb.

## The decision, in plain terms

The open question D-007 asks of the slice is precise:

> **When the player consumes a catalyst at the forge, what exactly happens to
> the item?**

The answer shapes the balance between the three routes to power: drops
(excitement), crafting (control) and infrastructure (dependability). If
catalysts are too predictable, drops stop being exciting; too random, and
crafting mastery stops mattering.

Sub-questions settled alongside the mechanic:

1. Is the catalyst consumed on use? (All proposals: yes.)
2. Can the result make the item worse? (All proposals: no — a preservation
   rule; "permanent deletion of build-defining items is not intended". Under
   the currency model this also protects new players from the PoE early-game
   trap of wasting rare currency on a ruinous outcome.)
3. Does craft skill change the result, keeping the skill gate meaningful?
4. Do catalysts survive trial death? (Provisionally yes — consistent with the
   currency model: Hades-style runs keep currencies through death, so failed
   attempts still feel like progress.)

## Proposal A — Deterministic upgrader

The catalyst plus a recipe yields an exact, named outcome: "Ember Catalyst +
tempering = +30% fire resistance."

- **For:** total player control; crafting plans are exact; easy to balance.
- **Against:** the forge becomes a vending machine. The drop's excitement dies
  at the moment of use, and item outcomes stop being conversation-worthy.
  Path-of-Exile-style item identity disappears.

## Proposal B — Pure gamble modifier

The catalyst rerolls or adds a random property from the item's allowed pool,
with weighted odds.

- **For:** maximum drop excitement; items become unique stories.
- **Against:** wasting a rare trial reward on a bad roll feels terrible in a
  single-player game with no trade economy to absorb variance; skill and
  facility gates stop mattering at the moment that matters most.

## Proposal C — Constrained roll (recommended, prototyped)

The catalyst **guarantees the domain and bounds the roll**:

- the named property *always* lands (Ember Catalyst → fire resistance), at the
  configured tier — the player always gets the thing they came for;
- the magnitude is rolled within that tier's range, so the moment stays
  exciting and items stay individual;
- craft skill raises the roll's floor (`minimum_roll_fraction_at_skill`), so
  mastery buys consistency without deleting variance;
- preservation: an existing better roll is never downgraded.

- **For:** keeps all three power routes alive — the drop is exciting, the
  craft skill is load-bearing, the forge upgrade is the gate. Matches the
  design pillar "power spikes are felt" without coin-flip regret.
- **Against:** more tuning surface (tier ranges, floor fraction) and the
  weakest rolls must still feel worthwhile, which tier design has to ensure.

## Evidence from the prototype (31 Aug 2026)

Implemented as `catalyst_processes` in `data/tuning/crafting.json` and
`items::catalystTemper` in `sim/`. With the tuned slice numbers (fire
resistance tier 1: 8–15, tier 2: 25–40, floor fraction 0.5 at Blacksmithing
5), 2000-seed balance runs give the intended difficulty story:

| Gear stage | Boss win rate (solo) | Full trial completion |
| --- | --- | --- |
| No armour / untempered armour | 0% | — |
| Basic temper (deterministic ~12%) | 33% | ~60% |
| Catalyst temper (floor roll, 32.5%) | 100% | ~86% |

The catalyst step is unmistakably felt, the basic-temper attempt is genuinely
chancy, and an unprepared attempt teaches rather than randomly succeeds.

## To accept this ADR

Play the text slice (`tools/playtest`), judge whether the ember-tempering
moment works as an introduction to catalyst currency, then either accept
Proposal C as the verb shape for catalyst-type items (update D-007 in the
registry) or direct changes. Accepting it does **not** settle the wider
currency economy — that remains open under D-007 by design.
