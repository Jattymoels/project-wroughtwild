# Loot and Crafting Economy

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

## Open questions

- Final catalyst operation vocabulary.
- Number of prototype item properties.
- Whether dropped gear can contain catalyst-exclusive interactions.
- How often lucky drops may bypass infrastructure progression.
- Whether catalysts themselves function as player-to-player currency in any future multiplayer version.
