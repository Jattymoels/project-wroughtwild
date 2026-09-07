# Vertical-Slice Acceptance Criteria

These are player-visible outcomes, not a substitute for implementation-level tests.

## Repository and configuration

- [x] The selected engine and version are recorded in an accepted ADR. *(ADR-0001, Godot 4.5-stable)*
- [x] The project launches from a clean checkout using documented steps. *(`game/README.md`)*
- [x] Core tuning values are externalised from game logic. *(`data/tuning/*.json`, read only through `sim/`)*
- [x] A deterministic test seed is available. *(`worldgen.json` `default_seed`; `sandpit.gd` builds from `world_seed` and saves carry their seed; `tests/sim` proves `worldgen::generate` is identical per seed and differs across seeds)*

## World and persistence

- [x] A bounded region loads with required wood, iron, forge location and trial entrance. *(authored greybox valley: two wood nodes, iron node, forge site, mine board, trial gate + arena)*
- [x] Critical progression resources cannot be absent from a valid seed. *(D-003 guarantees in `worldgen.json` — safe meadow spawn, wood/stone/iron within a short walk, packs off the doorstep, trial gate far in the wastes — checked by `tests/sim` across 60 seeds)*
- [x] Player state, equipment, placed structures and storage survive save/reload. *(F5/F9; `SaveManager` writes the sim's SaveGame JSON plus blocks, nodes and pose; integration-tested. Equipment round-trips through the schema but nothing equips it yet.)*
- [x] Loose materials, gear, selected pages and death packs restore with their
  matching world/inventory without loss or duplication. Old saves lacking drop
  records clear stale live drops. *(INT-07A: actual generated-tree restart,
  partial hauling, expiry, repeated loads and trial suspension;
  [evidence](loose-drop-persistence-2026-09-07.md).)*

## Construction

- [x] The player can place and remove the prototype shape set on a consistent grid. *(six shapes in `construction.json` — cube, wall panel, pillar, beam, step, and the trial-unlocked stonecut slab; Tab cycles, R rotates; sizes and anchors are data — panels, beams and pillars sit flush to the face or corner R selects, so pieces meet at corners and share corner cells)*
- [x] Shapes consume the selected material family rather than separate inventory SKUs. *(`construction.json` shape cost paid via `sim`)*
- [x] Placement preview communicates valid and invalid placement. *(green/red preview, integration-tested)*
- [x] Buildings do not collapse through structural-integrity simulation. *(none exists by design)*

## Crafting and skills

- [x] The player can gather iron and produce useful mine-reinforcement components. *(iron node → forge site → smelt → fittings, all via `sim`; integration-tested)*
- [x] Completing the order consumes output and grants an understandable reward. *(mine board panel: fittings consumed, three Vanguards + Blacksmithing XP paid since the kinds replaced the coin (D-023 slice 3), world effect recorded)*
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

## Approved world and Forge additions (D-027 / D-028)

- [x] New generation profiles contain reachable quarry, fen and oldgrowth habitats; old saves retain the frozen generator and placement inputs.
- [x] Eight finished materials have one-step recipes and shared placed/preview/catalogue art. Coverings and glazing respect form restrictions and existing roof unlocks.
- [x] Three story identities use connected two-floor Forge routes, local encounter ownership, physical rewards, optional secrets and four boon opportunities.
- [x] The capstone grants `forge_arc_complete`; repeatable offers remain stable across gate reopening, tier changes and save/load, with completion unlocking the next tier.
- [x] Cleared-floor suspension restores the matching build, inventory deposit, loot, choices, life and effect clocks without another deposit or healing.
- [ ] Prepared familiar players complete story/repeatable runs near the twenty-/ten-minute targets. Fixed-build encounter samples inform tuning; they do not certify full-run pacing.
- [ ] Ranger, Warden and Kindler difficulty at tiers 1–10 is accepted after actual combat/class playtests. Higher-tier numerical scaling remains unverified.
- [ ] Owner accepts the final habitat walks, three material buildings and Forge/boss presentation under Foundry effects.

## The Strange Frontier (D-029)

- [x] `frontier_v3` has three broad regions and reachable finite opportunities
  for all five rare resources; both old profiles match frozen fingerprints.
- [x] Contextual gathering and first-haul recipes work without class or discovery
  gates; fixtures use the existing workbench and kit placement interface.
- [x] Scene unloading preserves partial harvesting and depletion. Save restoration
  validates machine state before mutation and preserves mid-trip cargo ownership.
- [x] Signals request work separately from stored energy. A blocked winch pauses;
  sorting remains hand-fed; dismantling recovers rare cores and contents.
- [x] V3 regions use clustered canopy, shoreline growth and weathered shelves;
  actual authored footprints preserve approaches and gathering spaces.
- [x] Regional décor, ordinary grass and habitat cover clear around V3 buildings;
  removal, streamed chunks, excavation and save restoration retain valid poses
  without altering finite stock or older-profile presentation.
- [ ] The refined regional art feels convincing during ordinary play. Matched
  day/dusk captures and walking reviews are available in the
  [art refinement report](frontier-art-refinement-2026-09-06.md).
- [ ] Owner accepts discovery excitement, regional travel and contraption usefulness
  during normal play. Scripted generation, interaction and visual checks establish
  operation, not this judgement.

## Cataclysm Northstar (D-030)

- [x] New `frontier_v4` worlds compose three impacts, connected technological
  traces, supported ruins and links to existing finite discoveries; a 64-seed
  matrix validates the geography. Legacy/v2/v3 complete fingerprints remain exact.
- [x] Native augmentation influences terrain, vegetation and common-resource
  presentation. Ruins and the existing craft/actor roster share the authored
  material vocabulary without changing interaction or combat rules.
- [x] Normal interaction releases a rare component into physical drops;
  collecting it enables the existing useful recipe. Partial work and depletion
  survive the normal save/restore path.
- [x] Paid building placement clears overlapping ruin visuals and collision;
  saved buildings retain that clearance, and aimed dismantling restores
  supported scenery. Real player capsules can traverse ruin interiors.
- [x] Owner accepts the current visual finish for now (6 September 2026);
  a later graphical pass remains planned.
- [ ] Legibility of surviving civilisation, impact damage and augmentation
  during ordinary discovery and combat has been confirmed in player testing.
  Evidence and limits: [implementation review](cataclysm-implementation-2026-09-06.md).
- [x] One bounded pressure-feeder loop has accepted recipe, source/energy,
  ownership and failure contracts under D-031. Broader production is deferred.

## Pressure workshop (D-031)

- [x] An old blacksmith's ruin accidentally struck by an asteroid supplies one
  finite pressure pocket in V5; V4 and previous saves retain their geography.
- [x] Actual local forge/feeder interaction produces the existing clay bricks.
- [x] Exact source, escrow, buffers and progress survive pause/save/restore;
  cancellation, extraction and dismantling cannot duplicate items or drive.
- [x] Rendered site and brick-building review passes; user workshop feel remains
  a separate playtest. [Work item](pressure-workshop-2026-09-06.md).

## Exploration clarity (INT-02A)

- [x] Existing V5/V6 smithies gain bounded, grounded old-craft and damage
  evidence using native route/source associations. Existing collision, paid
  building suppression, excavation and save restoration remain valid.
- [x] Five rare families use inert clue remains; periodic discovery cues respect
  saved finite stock, including unloaded resources and exhaustion.
- [x] Existing native work stages appear in the compact progress display, and
  opt-in Source/use pages link actual recipe consumers without granting remote
  station crafting. Matched world captures and 720p/1080p UI checks pass.
- [ ] The owner understands the ruined smithy and resource handoff during
  ordinary discovery. [Evidence and limits](exploration-storytelling-2026-09-07.md).

## Home/workshop usability (INT-03A)

- [x] Station ghosts use placed geometry, floor anchor, yaw and current tier;
  station-to-station fit uses the unchanged body and normal kit payment.
- [x] Retained mixed-material corners and catalogue frame/door roles match
  placed materials through edits and repeated restoration.
- [x] Real capsule walking handles sufficient tight-ceiling steps, including
  diagonal approaches, while rejecting insufficient clearance and taller walls.
- [x] Two complete paid homes support E, station/chest use, stairs, shelter and
  exact save/storage restoration. All three class journeys physically enter
  their paid first shelter; matched home and existing-world evidence is recorded.
- [ ] Owner finds building and using a home comfortable.
  [Evidence and limits](home-workshop-usability-2026-09-07.md).

## Placement and returning home (INT-03B)

- [x] Every element of a new piece's native footprint respects edited terrain,
  including long/tall pieces and fine-grid anchors. Mine lining, exposed edges
  and ordinary D-017 piece overlaps remain valid; refused placement spends no
  material. Saved buildings restore without new-placement revalidation.
- [x] Station kits refuse obstructing player-built walls, beams and ceilings
  while preserving intended slab contact, neighbouring pieces, existing body
  dimensions and exact kit payment.
- [x] Optional boolean door state restores the same leaf and collision pose
  through atomic saves and repeated loads, with both axes and hinges covered.
  A player saved in an open doorway remains clear of the restored leaf; real E
  interaction still works. Malformed state rejects before live mutation; older
  schema-2 records retain the closed default. Shelter and inventory rules remain.
- [ ] Owner confirms these placement and return-home interactions feel reliable
  during ordinary building. Focused checks pass; this human review remains
  separate. [Scope and evidence](home-placement-persistence-2026-09-07.md).

## Placement reliability (INT-03C)

- [x] Legal full/half-grid corner previews and placed stations share a pose
  that clears both walls with unchanged body dimensions; actual rays, capsule
  collision, blocked ceilings/walls, payment and saved offsets are checked.
- [x] Local construction refresh produces the same completed scenery geometry,
  visibility and collision as a full refresh through rapid edits and save
  replacement, with measured placement-frame comparisons.
- [x] All seven fixture kits survive actual catalogue/camera/click placement,
  interaction and isolated fresh-process restoration with one owner each.
- [ ] The original disappearing-kit report is reproduced or explained using
  its actual saved circumstances. Current representative cases pass; no
  speculative inventory correction is made. [Evidence](placement-reliability-2026-09-07.md).
- [ ] Owner confirms ordinary corner building and placement comfort.

## Common building loads (INT-03D)

- [x] A useful timber home/workshop and quarry building increment fit one
  common-material haul each. Matched generated-source work, recipe costs and
  actual paid construction remain exact.
- [x] Larger common loads and shared chest capacity preserve partial pickups,
  special caps, crafted overflow, old/over-cap saves, death recovery and trial
  deposits. Completed generated homes and ownership checkpoints restore in
  fresh isolated processes.
- [ ] Owner accepts ordinary building/hauling comfort. The measured project
  still requires seventeen trees; capacity changes do not reduce that work.
  [Evidence and limits](building-loads-2026-09-08.md).

## Interaction feedback (INT-04A)

- [x] Accepted resource work, release and positive material collection have
  distinct short cues; refusals, empty results and full packs never sound successful.
- [x] Wood/fibre/earth/mineral contacts and five rare hosts retain separate
  timbres; cosmetic variation leaves gameplay RNG unchanged. Rare visual, hover
  and saved-progress restoration cannot replay work. Finite discovery cues remain.
- [x] A successful manual craft, including a batch, responds once at the actual
  local station or player. Surface response has no collision, ownership or fuel
  effect; failed/browsing/remote/restore paths remain quiet. Grade, potency and
  exact native costs, XP and item rolls are unchanged.
- [x] Shared playback caps at eight voices across scene roots, rapid collection
  coalesces, short voices expire and the fixed cache stays bounded. Actual
  first-person captures, listening reel and matched timing are recorded in the
  [work item](interaction-feedback-2026-09-07.md).
- [ ] Owner accepts timbre, volume and repeated-use comfort in ordinary play.

## Ground and ambience (INT-04B)

[Scope and evidence](footsteps-ambience-2026-09-07.md).

- [x] Actual grounded distance and support drive material contact, including
  existing built materials, current terrain strata, slopes and narrow ledges.
  Walls, air, dash, disabled play and panels do not accumulate walking sounds.
- [x] Existing V1–V6 biome surfaces supply four restrained outdoor beds, reduced
  by existing shelter. Bounds, invalid maps, trial context and world identity
  changes cannot carry stale outdoor sound into another place.
- [x] Same-position loads, trial restore/transition, death and pause clear
  cosmetic playback without changing native ownership, RNG, hearing or rare
  finite-stock eligibility. Voice/cache limits, Master mute and independent
  action feedback are verified; labelled listening samples are available.
- [ ] Owner accepts walking repetition, material timbre and relative volume
  alongside combat, work and rare discovery in ordinary play.

## Quiet ambience and player control (INT-04C)

[Implementation and listening limits](quiet-ambience-2026-09-08.md) supersede
INT-04B's continuous-bed design following the owner's rejected drone.

- [x] Baseline continuous occupancy is reproduced across four three-minute
  contexts. Non-looping local textures now leave 12–24 second quiet gaps, keep
  one retained voice, and do not repeat an adjacent variant.
- [x] H exposes working mouse/keyboard level and mute controls at 540p, 720p
  and 1080p. Input cannot pass to gameplay or an underlying pack panel.
- [x] Mute/zero stops current ambience, unmute starts quietly, and level/mute
  survive fresh processes and world restore in separate device preferences.
- [x] V1–V6 surface lookup, shelter, pause/death/trial/restore boundaries and
  bounded synthesis pass. Native ownership and gameplay RNG remain exact;
  work/footstep gain and Master are independent of ambient mute.
- [x] Normal-gain three-minute listening files and mixed work/walking copies
  are exported, with cold startup and steady route timings recorded separately.
- [ ] Owner accepts timbre, repetition and relative level during ordinary
  work, exploration and fights on their listening setup. Offline PCM and
  Dummy-audio regression do not establish this subjective acceptance.

## Forge readability and traversal (INT-05A)

[Scope and evidence](forge-readability-2026-09-07.md).

- [x] Both physical branch approaches expose native reward/danger previews;
  route, offering, lift, secret and conduit roles have restrained distinct forms.
  Compact world text preserves a full aimed preview, and final galleries do not
  promise another floor. Secret words remain limited to interaction reach.
- [x] Actual player movement and interaction traverse all eight room treatments,
  claim optional and mandatory rewards, suspend/restore at the reached boundary
  and extract through the existing boss completion.
- [x] The Warden reaches its existing claw range around runtime conduit bodies;
  adding/replacing/removing fixture bodies restores the appropriate nav cells
  while retaining one map/region and cancelling work on floor teardown.
- [x] Hostile outlines retain the exact existing cone/disc/lane extents and
  warning clocks; freeze/death cleanup, guard/recovery, cover and actual damage
  remain correct. Burning ground shows its full affected radius until expiry.
- [ ] Owner accepts route comprehension and tell recognition during ordinary
  combat. Difficulty, build strength and target run durations remain uncalibrated
  by these presentation/forced-clear checks.

## Whole-slice playtest

The [Wide Frontier intensive](wide-frontier-intensive-2026-09-06.md), D-032,
adds a finite 1 km successor with random/chosen seeds, broader rolling biome
interiors, four home clearings and a buffered opening. Its scoped generation,
save, terrain-retention and performance evidence is tracked in that work item.
Older worlds retain their original geography.

- [ ] Owner confirms V6 offers appealing home choices and a useful first
  thirty minutes of gathering/building before outward exploration and pressure.

- [ ] The complete loop can be played in approximately 20–40 minutes after onboarding.
- [ ] A tester can state why they became stronger.
- [ ] A tester can identify at least one self-chosen next ambition.
- [ ] No excluded system is required to make the loop understandable.
