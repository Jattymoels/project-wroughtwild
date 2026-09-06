# Loot and Crafting Economy

## Loose world ownership — INT-07A, 7 September 2026

The [save-reliability slice](../prototype/loose-drop-persistence-2026-09-07.md)
stores uncollected materials, gear, selected skill pages and recoverable death
packs alongside their corresponding player/world state. Restore replaces that
world's physical set without collection, rerolling a page or granting inventory.
Amounts, positions, flight/rest state and elapsed lifetime persist. Existing
material expiry and hauling capacity remain unchanged; gear and pages do not
expire. Completed claims cannot pay twice before their nodes leave the scene.

Outer schema 2 gains the optional versioned `world_drops` field. Validate every
record before importing player state. Missing records in older saves mean an
empty saved set, so loading clears stale live drops; historical omitted yields
cannot be reconstructed. A malformed present payload rejects the save. Full
gear seeds use decimal strings to avoid JSON rounding. Material identifiers
retain the native inventory's open string/count contract.

World drops and death packs cannot be collected during an active trial, and
carried materials cannot be dropped from it. Trial rewards remain in the run's
existing loot record and use its deposit, banking and death rules. Ordinary
world-drop flight and age continue while the player is in a trial.

## Rare wild components — D-029, 6 September 2026

Lanternheart, Thrumroot, Stormglass, Pullstone and Ventlung are finite physical
finds used in reusable fixtures. They are neither a currency nor a new equipment
rank. Learnable local clues lead to guaranteed intact opportunities in the new
regions; ordinary resource nodes do not roll these as jackpot drops. Initial
normal site hauls are respectively 4, 3, 4, 3 and 3; exceptional sites double a
haul. This pays for a complete first experiment and some placement freedom.
Dismantling returns every rare core; existing common-material refunds apply.

Repeatable Forge bosses replenish one displayed component on successful
completion. Existing haul targets determine it: slate/shellstone → Pullstone,
clay → Ventlung, reed → Lanternheart, resinheart/cork → Thrumroot, and
slag/Cinderglass shards → Stormglass. Quantity stays one while ordinary material
hauls scale. Early extraction or death gives no completion component. Saved
offer seeds, target rolls, equipment quality and Kind rewards are unchanged.

**Status:** High-priority open design with provisional prototype direction  
**Related decisions:** D-007

## Purpose and player fantasy

Loot should create the thought, “What can I make or build with this?” rather than merely increasing gear score or a generic currency total.

The system must keep three routes valuable:

- drops provide excitement and shortcuts;
- infrastructure provides dependable access and targeting;
- advanced crafting provides optimisation.

## Proposed economy layers

### Physical materials

Wood, ore, leather, fibres and alloys determine item bases, appearance and baseline properties.

### Knowledge and process

Recipes, skills, specialists, class knowledge and facility technology determine available forms and operations.

### Crafting catalysts

Rare world and trial drops are consumed during physical crafting stages such as smelting, tempering, quenching, engraving or assembly. They may:

- favour a property family;
- preserve an existing property during rework;
- raise the possible quality ceiling;
- convert one property category into another;
- introduce an unusual mechanical interaction.

### Salvage

Unwanted equipment returns a controlled portion of materials and may recover components or knowledge. Salvage should reduce trash without becoming the best source of every input.

### Trade currency

Ordinary currency supports merchants, orders and services. It should not replace the physical material economy or become the only meaningful reward.

**Direction (3 Sep 2026, D-023): currency stops being generic.** The
owner asked for trade currency to split into kinds with jobs: catalysts
(offence), **vanguards** (defence), and their like for life and speed.
Each kind aims a craft toward its modifier family and can be placed on
the Foundry plate as a subject or an augment. The proposal, including
retiring the coin in favour of a peddler who changes kinds, is in
[foundry.md](foundry.md). The owner (4 Sep 2026): retire the coin for
now; a coin and a generated town for trading may return later. This
widens the 31 Aug deferral of currency breadth at the owner's request;
four kinds is the prototype cap.

**Implemented 4 Sep 2026 (D-023 slice 3).** The coin is gone. Five ids
in four families (`crafting.json` `currency_kinds`) are paid by the mob
families whose nature they follow (`world.json` `currency_kind`), once
more by every elite, by the reinforced mine (three Vanguards) and by the
trial's loot room (a spread); the peddler prices goods in kinds and
changes three of one for one of another; a kind added to a gear craft is
spent to aim the roll's first modifier at its family; era three's steel
and silver cast the three purse kinds, catalysts never. Rates are first
guesses for the razor-blade pass. Details in
[progression-eras.md](progression-eras.md#implemented-typed-currency-4-sep-2026-d-023-slice-3).

## Prototype recipe

1. Select an iron armour base.
2. Meet the Blacksmithing and forge-upgrade requirements.
3. Craft a deterministic baseline fire-resistance version without a catalyst.
4. Add an Ember Catalyst during tempering to favour or strengthen fire-related properties.
5. Compare the result in the next boss attempt.

Only one catalyst family is required for the first implementation. Preservation and conversion catalysts may be represented in data but should not be implemented until the core operation is understandable.

## Item outcome philosophy

- Materials and form determine what the item fundamentally is.
- Facilities determine the operations available.
- Skill determines competence and possible quality.
- Catalysts change probability, preservation or interaction rules.
- Randomness creates anticipation but should not routinely destroy long preparation chains.
- Exceptional dropped equipment can bypass an immediate requirement but should not invalidate long-term infrastructure.

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Equipment drop rate | Frequency of direct shortcuts |
| Catalyst drop rate | Excitement and crafting access |
| Property weights | Build targeting and rarity |
| Property tier ceiling | Power progression |
| Catalyst influence | Control versus randomness |
| Preservation cost | Cost of protecting progress |
| Salvage return | Trash reduction and material economy |
| Merchant prices | Trade relevance |

## Failure cases

- Catalysts are renamed PoE orbs with no connection to physical craft stages.
- Too many catalyst types create inventory and learning overload.
- Deterministic crafting eliminates loot excitement.
- Dropped items make facilities pointless.
- High randomness destroys player investment.
- One universal currency dominates every decision.
- Item quantity overwhelms evaluation and storage.

## Prototype acceptance

- The player recognises the Ember Catalyst as valuable before using it.
- Its effect is explained and connected to tempering.
- The baseline deterministic option remains useful.
- The catalyst result meaningfully affects the boss without guaranteeing perfection.
- Unwanted equipment has a clear salvage or trade use.

## Implemented Kind expansion (5 Sep 2026)

The owner-directed [skill expansion](../prototype/skill-expansion-2026-09-05.md)
adds Piercing/Impact Catalysts, Sipping Marrow and Striking/Casting Quicksilver
within the existing four families. Each has a named enemy source, a Foundry
reading, an aimed gear-craft role and the existing three-for-one exchange.
Piercing aims projectile modifiers; Impact aims physical modifiers. The optional
`craft_tag` overrides the default family but never overrides a base's allowed
modifier pool. Six additional unknown-only skill pages use existing page chances
and the same persistent loot sequence. Old gear weights are unchanged.

## Open questions

- Final catalyst operation vocabulary.
- Number of prototype item properties.
- Whether dropped gear can contain catalyst-exclusive interactions.
- How often lucky drops may bypass infrastructure progression.
- Whether catalysts themselves function as player-to-player currency in any future multiplayer version.
