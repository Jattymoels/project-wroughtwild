# Vertical-Slice Acceptance Criteria

These are player-visible outcomes, not a substitute for implementation-level tests.

## Repository and configuration

- [x] The selected engine and version are recorded in an accepted ADR. *(ADR-0001, Godot 4.5-stable)*
- [x] The project launches from a clean checkout using documented steps. *(`game/README.md`)*
- [x] Core tuning values are externalised from game logic. *(`data/tuning/*.json`, read only through `sim/`)*
- [ ] A deterministic test seed is available.

## World and persistence

- [x] A bounded region loads with required wood, iron, forge location and trial entrance. *(authored greybox valley: two wood nodes, iron node, forge site, mine board, trial gate + arena)*
- [ ] Critical progression resources cannot be absent from a valid seed.
- [x] Player state, equipment, placed structures and storage survive save/reload. *(F5/F9; `SaveManager` writes the sim's SaveGame JSON plus blocks, nodes and pose; integration-tested. Equipment round-trips through the schema but nothing equips it yet.)*

## Construction

- [ ] The player can place and remove the prototype shape set on a consistent grid. *(grid placement works; two shapes so far — cube, and the stonecut slab unlocked by the trial; the spec wants six to eight)*
- [x] Shapes consume the selected material family rather than separate inventory SKUs. *(`construction.json` shape cost paid via `sim`)*
- [x] Placement preview communicates valid and invalid placement. *(green/red preview, integration-tested)*
- [x] Buildings do not collapse through structural-integrity simulation. *(none exists by design)*

## Crafting and skills

- [x] The player can gather iron and produce useful mine-reinforcement components. *(iron node → forge site → smelt → fittings, all via `sim`; integration-tested)*
- [x] Completing the order consumes output and grants an understandable reward. *(mine board panel: fittings consumed, trade currency + Blacksmithing XP paid, world effect recorded)*
- [x] Blacksmithing progress is visible and unlocks the forge-upgrade path. *(HUD and panel show level/xp; Improved Forge upgrade row appears at the built forge)*
- [x] Repeating the cheapest irrelevant recipe is less effective than useful work. *(repetition decay in `sim`; panel marks order-feeding recipes ★ and reports reduced XP)*
- [x] The upgraded forge can produce baseline fire resistance deterministically. *(Quench at the Improved Forge: tier-1 midpoint from `crafting.json` `basic_temper`, no roll)*

## Combat and build

- [x] The prototype class has a recognisable persistent play pattern. *(area strike / heavy strike / dash in real time, three enemy behaviours; ADR-0003)*
- [x] Equipment changes persistent offence or defence visibly. *(wear armour at the forge; HUD shows armour and fire resistance; every hit is mitigated through `sim`)*
- [x] The player can survive appropriate content slowly with baseline defensive preparation. *(balance sim: armour + quench completes 60% of runs and wins the boss 33%; bare armour 0% — confirm by playtest)*
- [x] Damage, defence and area/single-target trade-offs are measurable. *(every hit is a sim number; integration test asserts bands; balance sim is the oracle)*

## Trial

- [x] The player deposits ordinary inventory before entry. *(gate → `TrialSession` deposit; HUD shows it; integration-tested)*
- [x] At least one room presents a meaningful branching choice. *(stages 1–2 offer two doors with different encounters and rewards; bank-or-push before the boss)*
- [x] Temporary boons modify the persistent build without replacing it. *(offers via the sim; `combat_mods` change per hit; run state cleared at run end)*
- [x] The boss exposes insufficient fire resistance or another deliberate weakness clearly. *(telegraphed 42 fire breath every 2 s; unresisted it lands in band — integration-tested)*
- [x] Trial death preserves permanent equipment and permits immediate reconsideration. *(death contract: deposit and catalysts back at the gate, no pack dropped, re-enter at once)*

## Loot and catalyst crafting

- [x] The Ember Catalyst is recognisably valuable when it drops. *(shrine room; notice says death cannot take it; it is the one loot kept on death)*
- [x] Its crafting effect is explained before consumption. *(forge panel states the guaranteed property, tier range, skill floor and preservation rule; the catalyst is only consumed once the temper applies)*
- [x] It participates in a forge operation rather than being a generic stat token. *(Ember-Tempering is a `catalyst_processes` row: needs the Improved Forge and Blacksmithing 5)*
- [x] The resulting equipment improvement is visible in the subsequent boss attempt. *(HUD fire resistance; breath damage mitigated through `sim` — a playtest should confirm it reads in the fight)*

## Open-world death

- [x] Carried inventory drops at a recoverable location. *(`DroppedBundle` at the death spot; integration-tested)*
- [x] The recovery location is communicated clearly. *(HUD notice + glowing pack; a map marker is a later polish item)*
- [x] Build-defining equipment is not permanently destroyed. *(`drop_inventory` touches materials only; equipment and currency stay)*

## Slice-level validation

- [ ] The complete loop can be played in approximately 20–40 minutes after onboarding.
- [ ] A tester can state why they became stronger.
- [ ] A tester can identify at least one self-chosen next ambition.
- [ ] No excluded system is required to make the loop understandable.
