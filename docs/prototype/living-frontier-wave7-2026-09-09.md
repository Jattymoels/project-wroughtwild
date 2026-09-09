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

LF-7A publication: local commit **`afdb4bb`**, followed by a successful ordinary
push to `origin/main`. The concurrent ART-04 commit and all other art work were
preserved outside that slice.

## LF-7B continuity checks

The campaign and earlier-defect matrix passes with the return-save changes:

- LF5-R1: **24 + 15** checks, including actual ordinary-load movement and a
  fresh process. Measured baseline/recovered travel is **2.416 / 2.499 m**.
- LF3-R1: seed **5: 59** and **77: 61** checks; every one of the 24 full routes
  passes, with **zero shell contacts**.
- Paid field journey: **940 + 7** checks including a fresh process. Actual
  harvesting, all five ordinary Catalyst recipes, paid brick construction and
  source work pass without an intact-Catalyst shortcut. Travel and the 600-second
  active source-formation interval are compressed in this existing fixture;
  materials, stock, stations and unlocks are not granted by it. This starts in
  an earlier campaign state; the separate archived-ending loop checks retention
  of owned work across experiments.
- Pairing **155 + 4**, second terrain **133**, host recovery **8**, pending
  **13**, applied **22**, physical return **13**, and six historical archives
  **15 / 23 / 23 / 13 / 23 / 14** checks pass. Pairing travels **824.86 m**.
- Legacy save recovery **175**, Trial lifecycle **6,221**, Forge route **122**
  (**814.9 m**) and Annex **172** (**824.53 m**) pass.
- Conservator combat **1,867**, Central route/live finale **186**, boundary **4**,
  saved ending **36**, later world death **30**, failed ending write **194**,
  retried ending **36**, retried later death **30**, physical controls **13**,
  natural Trial death **47** and fresh death restore **18** pass. The final human
  fights live for **11.22 s / 23 casts** in the route fixture; earlier encounters
  still use explicit forced setup. Neither terrain event nor the ending repeats.
- Eight native suites total **456,985 checks**, zero failures: general rules,
  finite sources, machines, generation, both laboratories, resonance and Central.
  This is in addition to LF-7A's 54,286 laboratory configuration/settlement checks.

The existing synchronous second-publication pause remains **20.9–21.0 s** in
these checks. This work adds no terrain event or background publication system.

## LF-7B implementation and complete-loop evidence

Every ordinary laboratory return now checkpoints the already settled native
state and owned world. The return page states the result and actual recovered
haul, then opens another configuration. Failed writes keep the previous disk
checkpoint, show a retry action and prevent another experiment until saving
succeeds. Ordinary save also clears the warning; neither retry settles rewards.
Success, early banking, abandonment and natural death all use this path.

The former terminal gallery fixture did not expose the existing native bank
action. Captured runs now have a physical entrance-side exit, usable between
encounters; banking opens after the fourth reward and cannot award the boss
core or next tier. The old rear offering position also failed the full route:
the next navigation query ended on a disconnected patch by the claimed cache,
and capsule backtracking did not complete. Laboratory offerings now use the
open front apron. No partial path, forced teleport or skipped interaction is
accepted by the repaired route checks. Legacy placements remain unchanged.

New presentation tuning in `game/art/forge_look.gd`:

| Parameter | Value | Player experience |
| --- | --- | --- |
| `laboratory_reward_offset` | `(0, 0, 6)` metres from room centre | Clear space to claim the offering and return to the gallery, away from rear cover/cabinets. |
| `laboratory_exit_position` | `(-3, 0, 8)` metres in the gallery | Reach abandonment before the first encounter and banking before the boss without crossing an uncleared seal. |

No combat, recipe, source, machine or terrain tuning changes in LF-7B. The
LF-7A tier cap, pressure compatibility, 1.25 targeted-haul factor and repeat
record text remain the only configuration/content additions.

- The complete headless journey passes **5,589 checks** before the final
  rendered evidence pass. All five rooms fight live at 60 Hz: **90.53 seconds,
  107 committed casts, 49 enemy deaths**, **176.61 incoming damage** recovered
  through the build, and a minimum life fraction of **31.59%**. The boss takes
  **11.53 seconds**; actual telegraph-aware movement avoids its released damage.
  No enemy is force-killed and life is not reset between the five rooms.
- This is saved tier-one run two with **no extra pressure**, retaining its
  rolled Warded Rares and Volatile Rares risks (the report stores exact IDs and
  descriptions). The prepared archived melee character pays ordinary iron mace, bronze mail,
  temper and three Marrow recipes, then the normal three-for-one exchange for
  Sipping Marrow. Its historical classless heavy-strike/area-strike/frost-nova/dash
  bar remains; the two attacks share the existing Vigour/Edge recovery path.
  This is an old-save full-run case, separate from the three named class probes.
  Supplied recipe inputs/facilities and historical earned-ingot events
  are explicit fixtures. An additionally manufactured Faint Ember stays owned
  and unused; an intact lucky Catalyst does not supply the combat build.
- Actual cache, optional secret and core match native preview quantities.
  Material inventory and the separate Kind purse are compared independently;
  all three gear rewards and duplicate-settlement refusal are checked. After
  returning, physical controls select tier two and a new saved offer batch.
- A separate exit fixture forces four prior outcomes to isolate paid banking.
  Actual walking/E and the bank button preserve exactly the earned haul and
  gear without unlocking a tier. Early abandonment disables banking; two real
  failed writes retain previous checkpoint bytes, followed by a working physical
  retry with no second payout.
- Natural death uses **seven real released hits, 135.62 damage in 3.53 seconds**.
  Four setup rooms are forced and life restored only for this separate death
  fixture. Death loses unbanked rewards, returns deposits/purse/equipment and
  saves a usable next configuration while retaining the ending and both events.
- Fresh-process completed, retry and death saves pass **45 checks**, including
  exact native state, construction, resource/source state, machines, loose
  ownership, campaign continuity and physically reopening the controls.
- Geometry matrix: **256 checks**, **4,584.94 metres** of actual capsule travel
  across **eight existing modules × five room positions**. Route and reward rays,
  entry-side exit, pre-boss bank access and fight-time exit lock all pass. This
  changes only presentation module selection and explicitly forces outcomes;
  it is not additional combat evidence.
- Final isolated pressure rerun remains **12 live samples / zero setup failures**
  and **107 contact/effect checks**. Physical configuration remains **42 checks**.

Earlier attempts are retained in `build/lf7` and are not represented as wins:
starter and prepared builds died; the one-skill Crossfire recovery run reached
room four before death. A test craft initially requested armour above the
fixture's skill, then a disabled recipe name; those setup errors were corrected.
The full-route bot also overrode danger evasion while walking into the boss
room; its fixed-seed final policy now honours warnings during that approach.
The first reward oracle mistakenly counted purse Kinds as bag materials; the
final check requires both stores to match their separate destinations.

The evidence does **not** certify all full runs at every tier/pressure, human
difficulty/readability, production visuals, or a fresh uncompressed campaign
from empty inventory through the final repeat. Full added-pressure victories
and upper-tier human balance remain unverified. The complete base run,
isolated pressure contacts/fights, prior paid field journey and archived-world
continuity are separate evidence. No world expansion or further wave follows
this slice; stop for orchestrator review after publication.

Final rendered rerun: **5,601 checks, zero failures**, adding exact gear-rarity
and rolled-modifier-tier assertions to the 5,589-check headless journey. Its
five live fight results match the fixed-seed headless sample above. Configuration
is **43 rendered checks**; ordinary return checkpoint takes **258–274 ms**,
  archived loads **11.27–13.55 s**, and entries **189–209 ms**. Editor registration
and a fresh `--living-frontier-wave7` 120-frame smoke launch pass without engine
errors. Inspected pages: [saved completion](../../captures/lf7/completed-return.png),
[physical exit](../../captures/lf7/physical-exit.png), and
[failed-write retry](../../captures/lf7/return-save-retry.png). These pages fit the
1280×720 viewport. The offer list still requires scrolling, and the existing HUD
and world labels remain visible behind the translucent panels; readability is
not presented as final art acceptance.
