# Living Frontier Wave 7 — captured experiments

Owner authorization: 9 September 2026, LF-7A then LF-7B only, followed by
orchestrator review. The [Wave 6 review](living-frontier-wave6-review-2026-09-09.md)
clears both earlier repairs. Unrelated art and local diagnostics stay outside
these slices. Human difficulty/readability acceptance remains separate.

## Configuration contract — recorded before implementation

Affected systems: D-006 Trial ownership, D-010 combat authority, D-019/D-028
campaign/offers and D-032/D-033 retained geography/economy. Extend the existing
native MapOffer, GateState and TrialSession, the Central E page and ordinary
Trial controller. `trial.json` owns the bounded configuration and reward tuning.
No missing decision blocks this selection within the approved handoff.

- Captured Central opens the existing three saved offers and unlocked tiers
  through one page. Five rooms, one floor, two boon choices, optional secret,
  bank before the boss, no active-fight suspension. LF experiments cap at tier
  ten; old Forge policies and saved batches retain their existing definitions.
- Each offer retains its seed, modules, material target, boss and rolled
  conditions. Repeat opponents are the existing creature Tyrant, Ash Warden
  and Forge Heart, operated as contained Forge trials. The human is never used
  in this roster. Existing laboratory apparatus dresses the reused rooms.
- Select **none**, **Crossfire** (two extra shots across an 18-degree fan), or
  **Relentless Boss** (recovery and attack cadence multiplied by 0.8;
  warnings unchanged). These are the existing condition effects; descriptions
  now make their actual numbers explicit.
  At most one selected pressure supplements the two/four rolled conditions.
  Reject duplicates, shared effect keys, explicit incompatibilities and more
  than two major hazards. An incompatible option stays visible and disabled;
  selection never rerolls an offer. Living enemies remain capped at 24.
- The extra pressure multiplies only the selected source-material haul by
  **1.25** in the salvage cache and optional secret, rounded down after the
  existing tier/rolled-condition and temporary boon multipliers. General iron
  and purse Kind amounts keep their existing multiplier. Equipment count,
  rarity and tier and the one completion component do not improve. The LF
  equipment cache retains the former shrine's wrought tier-one gear, but pays
  no guaranteed Catalyst. Legacy shrine rewards remain unchanged. Preview exact
  base cache/secret/component quantities, gear rewards and temporary-boon caveat.
- Previewing is free. Successful native entry freezes the selected pressure
  into the run, remembers its tier/pressure and consumes the existing batch.
  Reject stale offer identity and invalid settings before depositing goods.
  Optional remembered fields preserve version-one gate saves and do not change
  their offer rolls. Only a completed boss unlocks the next tier, up to ten here.
- LF-7B checkpoints each normal experiment return with its already settled
  haul, gate batch and remembered configuration. Failed saves leave live
  ownership with visible retry; retry cannot settle again. Before that checkpoint,
  a crash returns to the preceding save, as for existing non-suspendable maps.
  No mid-fight save/resume or new persistent reward receipt is introduced.
- Both terrain ledgers, once-only ending, three eras, source stock/renewal,
  paid construction, excavation, machines, loose drops and recipes remain.
  The experiment pays building sources and one contraption core; bulk wood,
  ores, magical media, fuel and deliberate Catalyst manufacture still need
  ordinary field work and facilities. Run pressure is neither an era nor Red
  crafting heat. There is no further transformation, currency or production loop.

## Small implementation plan

1. LF-7A: native configuration/preview/entry validation and the physical Central
   controls; test saved-offer stability, live effects, entry and compatibility.
2. LF-7B: complete/return/reconfigure and checkpoint retry; exact reward and
   death/bank/abandon tests, fresh processes and paid field-to-building proof.
3. Carry both LF5-R1 movement and seed 5/77 full route regressions, campaign
   terrain/ownership matrix, native economy/source/machine checks and rendered
   controls. Measure live combat and repeat/campaign transitions separately.
4. Record checked evidence, tuning and remaining limits; commit/push scoped
   slices under standing permission and stop for review.

Implementation and verification evidence follows below; this contract alone
does not claim those checks have run.

## LF-7A evidence

Captured Central now offers the existing saved tiers/runs with a free pressure
selection and exact native previews. The run commits identity, effects and
targeted reward factor at entry. Optional gate fields retain the last successful
tier/pressure; unconfigured historical gate serialization remains byte-identical.
The experimental equipment cache and reused creature opponents leave the human
ending resolved. Gallery records distinguish isolated repeats from old failsafes.
`--living-frontier-wave7` continues the same LF4 save and LF3 geography.

- Native configuration/settlement: **54,286 checks**, zero failures across
  32 batches, ten tiers and all compatible selections. Exact cache/secret/core,
  legacy shrine, gear, deposit, duplicate settlement, death/abandon/bank,
  incompatibility and both terrain ledgers pass. Encounters are forced only
  for these rule-state tests.
- Physical Central controls: **42 headless / 43 rendered checks**, zero
  failures. Actual capsule approach, E ray, Enter-key button activation,
  pressure selection, save/reload, stale/invalid entry and exact committed
  native settings pass. Forced exit isolates ownership; no live fight is
  claimed by this fixture.
- Actual pressure effects: **107 checks**, zero failures at 20/60 Hz. Three
  Crossfire projectiles release; standing takes **7.22 / 8.83 damage**, while
  real side movement and solid cover take zero. Relentless uses the native
  shortened recovery/cadence with full warning, committed aim, cover, freeze
  and actual damage. Controlled contact positions/clock probes and forced
  cleanup remain distinct from the live fights.
- Twelve isolated live starter samples at 60 Hz: **five wins, seven deaths**;
  no forced enemy deaths, immunity or Foundry/Catalyst. Paid wood weapons and
  hide vests use supplied inputs and synthetic campaign access. Crossfire's
  selected first compatible offer produces boss wins for all three classes
  (11.53 s; 15.40 / 8.45 / 7.42 incoming damage). Kindler also wins both pack
  samples (10.50 / 32.33 s; 60.70 / 84.03 damage). Other samples die in
  6.88–20.92 s. Offers differ between pressures, so this is feasibility and
  failure evidence, not a matched difficulty comparison. Four earlier rooms
  are forced only to establish isolated boss samples.

The imported synthetic ending fixture preserves paid world ownership from the
Wave 6 review. Its uncompressed SHA256 is
`c20d7e8cfe5771e4deeb4790fe8a21816c07c6bfa7f26ede711fb2fd2ea03d42`;
the archive is `game/tests/fixtures/lf6-published-ending.json.gz`. It supplies
campaign access, not a claim of a fresh full-campaign playthrough in this fixture.
Logs/reports are isolated in `build/lf7`; the standard runners include native
configuration and physical control/effect checks. Additional compatibility and
publication receipts follow. LF-7B still owns automatic repeat-return saves,
retry/reconfigure and the complete live-run/field-work proof.

LF-7A compatibility rerun also passes saved ending **36**, later world death
**30**, native Central **47**, frozen-generation/routes **17,716**, Annex **55**
and Pairing **72** checks. The final controls/render rerun remains **42/43**.
Measured entry is **150–252 ms**; ordinary archived-ending restore is
**12.1–17.3 s** across these concurrent checks, not isolated performance testing.
The source/terrain/full campaign matrix continues into LF-7B. Inspected captures:
[configuration](../../captures/lf7/configuration.png) and
[reward preview](../../captures/lf7/reward-preview.png). The page scrolls;
existing campaign HUD text behind it remains a readability limitation.
