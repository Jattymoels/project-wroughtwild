# Vertical-Slice Acceptance Criteria

These are player-visible outcomes, not a substitute for implementation-level tests.

## Repository and configuration

- [x] The selected engine and version are recorded in an accepted ADR. *(ADR-0001, Godot 4.5-stable)*
- [x] The project launches from a clean checkout using documented steps. *(`game/README.md`)*
- [x] Core tuning values are externalised from game logic. *(`data/tuning/*.json`, read only through `sim/`)*
- [ ] A deterministic test seed is available.

## World and persistence

- [ ] A bounded region loads with required wood, iron, forge location and trial entrance.
- [ ] Critical progression resources cannot be absent from a valid seed.
- [ ] Player state, equipment, placed structures and storage survive save/reload.

## Construction

- [ ] The player can place and remove the prototype shape set on a consistent grid. *(grid placement works; only the cube shape exists so far)*
- [x] Shapes consume the selected material family rather than separate inventory SKUs. *(`construction.json` shape cost paid via `sim`)*
- [x] Placement preview communicates valid and invalid placement. *(green/red preview, integration-tested)*
- [x] Buildings do not collapse through structural-integrity simulation. *(none exists by design)*

## Crafting and skills

- [ ] The player can gather iron and produce useful mine-reinforcement components.
- [ ] Completing the order consumes output and grants an understandable reward.
- [ ] Blacksmithing progress is visible and unlocks the forge-upgrade path.
- [ ] Repeating the cheapest irrelevant recipe is less effective than useful work.
- [ ] The upgraded forge can produce baseline fire resistance deterministically.

## Combat and build

- [ ] The prototype class has a recognisable persistent play pattern.
- [ ] Equipment changes persistent offence or defence visibly.
- [ ] The player can survive appropriate content slowly with baseline defensive preparation.
- [ ] Damage, defence and area/single-target trade-offs are measurable.

## Trial

- [ ] The player deposits ordinary inventory before entry.
- [ ] At least one room presents a meaningful branching choice.
- [ ] Temporary boons modify the persistent build without replacing it.
- [ ] The boss exposes insufficient fire resistance or another deliberate weakness clearly.
- [ ] Trial death preserves permanent equipment and permits immediate reconsideration.

## Loot and catalyst crafting

- [ ] The Ember Catalyst is recognisably valuable when it drops.
- [ ] Its crafting effect is explained before consumption.
- [ ] It participates in a forge operation rather than being a generic stat token.
- [ ] The resulting equipment improvement is visible in the subsequent boss attempt.

## Open-world death

- [ ] Carried inventory drops at a recoverable location.
- [ ] The recovery location is communicated clearly.
- [ ] Build-defining equipment is not permanently destroyed.

## Slice-level validation

- [ ] The complete loop can be played in approximately 20–40 minutes after onboarding.
- [ ] A tester can state why they became stronger.
- [ ] A tester can identify at least one self-chosen next ambition.
- [ ] No excluded system is required to make the loop understandable.
