# Living Frontier Wave 5 — bounded contract and evidence

Owner authorization: 9 September 2026. Baseline `9231f13`, following the
[independent Wave 4 clearance](living-frontier-wave4-review-2026-09-09.md).
Implement LF-5A, LF-5B, LF-5C in that order, check/commit/ordinarily push each
slice, then stop for orchestrator review. This contract is recorded before
implementation. Unrelated fauna/workshop art remains outside these commits.

## Scope and selected implementation

Affected authorities: D-010 combat numbers/time split, D-006 Trial ownership,
D-017 paid construction, D-019/D-028 campaign milestones, D-032 frozen geography
and D-033 extraction. Relevant data: `world.json`, `combat_realtime.json`,
`laboratory.json`, a separate Pairing treatment, and `resonance.json`.
No new recipe, currency, source renewal rule or mandatory Catalyst is selected.

1. **LF-5A:** one paired version of the existing boar. Blue holds a charge at
   the position marked when its attack begins; Red then warns and releases at
   that same position. The host remains still during both phases. This replaces
   its ordinary attack: one damage payment, no simultaneous charge contact,
   root or lingering burn. Ordinary movement out of the mark is sufficient;
   existing stagger/freeze cancels the whole sequence, with exposed recovery.
   Starting equipment and skills must win real fights for all three classes.
   Initial tuning retains 75 life and six fire damage; one-second Blue hold,
   one-second Red warning, 3.2 m radius and 1.5-second recovery. A narrow marked
   perimeter, phase words and separate Blue/Red apparatus cues show the order.
2. **LF-5B:** open the existing Pairing Hall after the first physical campaign
   publication. Retain the existing Deep Forge two-floor/eight-stage topology,
   Warden, deposits, choices, suspension and per-run reward contract. Introduce
   one paired specimen per selected teaching encounter in place of an existing
   enemy, following a single-influence reminder. Useful existing material/gear
   rewards remain; records show the human operator deliberately imposing an
   ordered pairing and diverting its failsafe toward Excited Uplands. The
   apparatus Warden is not the later human boss. Central entry/maps stay closed.
3. **LF-5C:** Pairing's first victory grants one Eye and queues a separate
   Excited Uplands event. Safe publication creates a contrasting raised mineral
   shelf within that already declared envelope, exposes four finite iron/silver
   deposits and adds one finite paired host. Existing `ash_tide`/era-three
   Foundry and steel capabilities follow only successful physical publication.
   No molten-water damage, sliding, new material or extra ecological system is
   implied. The Eye is optional once-only remembrance at the drowned altar,
   without another era switch or reward. Repeat victories keep ordinary loot.

These selections implement the approved ordered specimen, second lab and
second transformation with existing rules/assets. No unresolved design choice
blocks this bounded implementation. Human difficulty, narrative comprehension,
art acceptance and transition comfort remain review questions.

## Compatibility and publication contract

Extend the saved `living_frontier_wave4` campaign in place, keeping its published
name and immutable `living_frontier_wave3` geography. Existing LF4 dormant,
pending and applied saves retain their original first-event ledger byte for
byte in meaning, all receipts and stock. An absent second-event field means
**dormant Excited Uplands**, never a queued or applied event. Pending first
returns finish only the first event; Pairing requires its campaign award.
Applied first returns preserve depleted ore, dead host and spent Heart.
Legacy/non-LF4 policy retains its original campaign and acquisition.

The second ledger has its own event identity, seed, sparse columns, workplaces,
award and first-clear receipt. Replay first then second against the same base;
never replace/replan the first event. Validate both events and their milestones
before live mutation. Unknown event/version and mixed era/terrain records refuse.
Preserve existing Trial boundary revisions; distinguish the new Pairing run.

Reuse the isolated protected candidate transaction: save pending ownership,
defer during combat/active Trial, protect current construction/supports/doors,
stations, machine endpoints/spans/cargo, excavation, resources, source workplaces,
returns and recovery, then validate and write the complete candidate. Physical
restoration must succeed before exposing the era in the live world. Failed
preparation/write retains pending; interrupted committed publication is completed
by restart. Fully occupied ground explicitly defers. First-event terrain and
finite opportunities are also protected during second preparation.

## Verification plan

- Real hybrid release/hit/escape/cancellation/recovery at 20 and 60 physics ticks;
  all-class fights with paid ordinary starting weapons, empty Foundry and live
  incoming damage. Record actual casts, damage, time and outcomes. No forced
  death or invulnerability may count as combat evidence.
- Existing full approaches plus Pairing front-door interaction, both floors,
  records, choices, useful rewards, exact return and suspended restart. Label
  forced route-fixture outcomes explicitly.
- Native deterministic seed sweep for both events together, old terrain/stock,
  protected construction and failed/duplicate settlement. Existing source,
  machine, recipe and legacy Trial/save regressions.
- Frozen pre-change LF4 dormant/pending/applied checkpoints, paid protection,
  first-event depletion and fresh-process second-pending/applied restart; death,
  abandon, repeated victory, spent trophies and invalid mixed checkpoints.
- Actual physical second-shelf walking/collision and useful finite harvesting /
  paid crafting. Report supplied fixture ingredients and accelerated work.
- Measure publication milliseconds separately from combat/travel. Present a
  visible preparing message before synchronous publication; measure the pause
  without claiming seamless or accepted performance.

## Results

### LF-5A — ordered specimen

One `lf_paired_boar` reuses the existing boar asset and ordinary damage/control
rules. Its fixed mark is centred on the host's position at commitment, not the
player's later position. The native `paired_boar` behaviour owns the selected
numbers; `release_warning_seconds = 1` is the new second-phase timing value.
The existing hold/release/radius/recovery fields retain their documented roles.
Two simple imposed collars, phase words and the exact stationary ring identify
the sequence without changing the concurrent source animal art.

`tools/living_frontier_wave5_checks.ps1 -Hybrid -Visuals -Native` supplies the
reproducible checks. The final hybrid run passes **2,801 assertions** across
eighteen contact cases and three real fights. Both physics rates demonstrate
one full Blue hold and one full Red warning; staying or returning into the
mark pays one native hit, while ordinary late side/back movement, physical
cover and cancellation prevent it. The separately labelled death case injects
fatal damage only to verify cancellation; it is not combat-win evidence.

Actual Warden/Ranger/Kindler starting-weapon fights take **3.90 / 3.70 / 3.78 s**,
using **5 / 5 / 8 casts**, respectively. Each specimen releases once and dies
through real casts/statuses; each player finishes at 100 life after successful
counterplay. Incoming damage processing stays enabled and invulnerability is
zero. Workbench access and wood/hide inputs are supplied combat fixtures, then
ordinary recipes pay for the cudgel/bow/focus; no Catalyst, Foundry piece, armour,
extra skill or injected damage completes these fights. This is isolated baseline
capability evidence, not full-Trial balance or a human playthrough.

The unchanged single-influence contact/fight suite passes **234 assertions**.
The 37-seed native geography/host sweep passes **17,716**, retaining every
published geography fingerprint; first-laboratory native checks pass **55** and
first-transformation checks **373**. Rendered live Blue/Red/recovery captures
pass five assertions and are visually inspected in `captures/lf5/`; they use an
observer camera, not claimed first-person human evidence. The final current
native main/source/machine regressions pass **224,380 / 213,482 / 601** checks,
all zero failures. Changed JSON, contract links and scoped whitespace pass.

Limitations: simple collars/ring/words are prototype presentation. Human tell
recognition under a crowded Trial, difficulty and creature art remain open.
The scene `res://tests/living_frontier_hybrid.tscn` isolates this first specimen;
LF-5B puts it into the physical campaign. Waves 6–7, other hybrids, broad ecology
and factory automation remain excluded.
