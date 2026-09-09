# Living Frontier Wave 5 — bounded contract and evidence

Owner authorization: 9 September 2026. Baseline `9231f13`, following the
[independent Wave 4 clearance](living-frontier-wave4-review-2026-09-09.md).
Implement LF-5A, LF-5B, LF-5C in that order, check/commit/ordinarily push each
slice, then stop for orchestrator review. This contract is recorded before
implementation. Unrelated fauna/workshop art remains outside these commits.

**Independent review:** [LF5-R1](living-frontier-wave5-review-2026-09-09.md)
must be repaired before LF-6. The double-host-failure fallback leaves movement
disabled after a successful ordinary load; the existing traversal helper masks
that gap by re-enabling physics. This review records the defect, not its repair.

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
byte in meaning, all receipts and stock. In those LF4 saves an absent second
field means **dormant Excited Uplands**. The explicitly retained intermediate
LF5B victory receipt instead migrates to pending using the first event's seed,
without another Eye; its earlier suspended boundary remains dormant. Pending first
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

Checked commit **`0482211`**, ordinarily pushed to `origin/main`.

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

### LF-5B — Pairing laboratory

Checked commit **`e92561a`**, ordinarily pushed to `origin/main`.

`pairing_laboratory.json` selects a Blue reminder in stage zero, Red in stage
one and one paired specimen replacing an ordinary enemy in every branch of
stages two through six. The original final Warden and two supports remain.
Encounter counts, room topology, ordinary per-run materials/gear/boons, deposits
and death rules are unchanged. Three inspectable gallery records teach the
sequence, show the operator's shift from preservation to imposed alteration,
and foreshadow the second return interlock and central human harness.

The same saved LF4 campaign opens the existing Pairing front body after its
first physical award. Central/map APIs remain closed. Pairing uses boundary
revision two; Annex revision one is preserved. First victory records
`lf5_pairing_victory` and pays one Eye, including after replayed callbacks or a
spent Eye. During this checked intermediate slice, that receipt does not yet
queue/publish the second event. **LF-5C will migrate an LF-5B victory lacking a
second ledger to pending using the first event's saved seed**, without replaying
its Eye; historical LF4 records without that receipt gain only a dormant second
ledger. This bounds intermediate-checkpoint compatibility before LF-5C.

Cabinet size, offset and record spacing reuse LF4 values. Cabinets occupy the
three teaching chambers. A first candidate extended them through later rooms;
the actual route ray caught a cabinet obstructing stage six. Keeping later
rooms' existing conduits clears that regression, verified by the same full walk.
The final route passes **152 checks / 824.9 m**, with a separate **four-check
fresh-process suspended restart**. It physically uses the existing site door,
inspects all records, traverses every stage and optional reward, and returns to
the exact Pairing approach with one Eye/receipt and the original first ledger.
The route fixture intentionally disables damage and forces encounters; it
does not establish full-Trial combat balance. It starts from the frozen LF4
applied campaign containing the spent Heart, dead Blue host and depleted ore.

Historical fixture origins and the deliberately derived dormant case are
documented in [the fixture record](../../game/tests/fixtures/lf4-published-saves.md).
Native Annex and Pairing checks pass **55 / 60**, including early failure,
abandon, repeat victory, spent trophy and preserved first-event state. Existing
save recovery passes **175**, Trial lifecycle **6,221**, old Forge traversal
**122 / 814.9 m**, and the complete Annex journey **172 / 824.5 m**. All have
zero failures. The Annex publication measured **17,743 ms** in this rerun.
Its synchronous pause remains an LF-5C performance/presentation concern.
All 24 complete generated approaches in seeds **5 / 77** pass again (**59 / 61**
checks), including historical paid-save ownership and every laboratory shell.
Scoped whitespace checks pass. No production-art source is changed by LF-5B.

### LF-5C selections before implementation

Keep `resonance` as the original version-one Retained Fen ledger and add
`resonance_second`, also version one, with event ID `excited_uplands`. Missing
second ledger means dormant, except the explicitly documented LF-5B first-clear
receipt migration above. Both seeds must agree with the outer world. Second
pending/applied requires the first campaign publication; `ash_tide` requires
the second applied award and Pairing receipt. Reject swapped/unknown ledgers.

Excited Uplands receives parallel raised mineral shelves: maximum **three metres**,
**twelve-metre ridge spacing**, with unchanged one-metre step relaxation and
three-metre edge/protection blending. Added rock uses existing stone voxels,
with four finite alternating iron/silver deposits of eight units and one finite
`lf5_excited_uplands_pair` boar. No existing biome cell, source, finite node,
first-event column/workplace or published approach is moved/replaced. This is
one regional opportunity; there is no new heat hazard or global ecology.

Only first Pairing victory creates the receipt/Eye. Its pending event publishes
on safe return and grants existing `ash_tide`; the drowned altar consumes a
held Eye once as remembrance, without another unlock/payout. Era-three ordinary
skills/recipes/fauna mechanics follow the existing era tables. The native
candidate should retain its already prepared terrain cache, avoiding one
redundant regeneration. Show a preparing notice before synchronous publication.
On a host publication failure restore the pending live checkpoint and save it
again for retry. If host rollback fails, retain the recoverable committed disk
candidate, restore the prior native era and require reload explicitly.

### LF-5C — second physical event and era three

Implemented within the recorded selections above. First victory queues only
the second event; the existing era-three Foundry grant is delivered with
`ash_tide` after physical publication, not with the Eye. The separate second
ledger extends the existing campaign and both launch flags select its same
default save. No earlier campaign is silently converted. The first ledger is
replayed before the second and its actual columns join the protected mask.
Only the current event's four resource IDs are appended during publication:
this explicitly prevents replenishing the already depleted first ore set.

Candidate preparation reuses its voxel cache when exporting the prepared node
list. A preparing notice is scheduled before synchronous work. If installation
fails, the publisher restores and saves the pending world; a separately injected
failure of both installation and host rollback leaves a complete disk candidate,
restores the prior native era, stops player movement and requests reload. Reload
must successfully install the physical world before gameplay continues.

Current coupled native checks pass **632 assertions across 37 seeds**, including
both independent ledgers, exact voxel replay, original resource workplaces,
caves, ordinary step limits, paid-footprint protection and occupied-region
deferral. Existing generation fingerprints remain unchanged (**17,716 checks**).
Main simulation, sources/recipes and machines pass **224,380 / 213,482 / 601**.
Malformed and mixed save refusals are deliberate negative fixtures.
Native Annex/Pairing settlement checks pass **55 / 72**: early bank-out,
death/abandon, suspended boundary, absent-ledger migration, wrong/mixed events,
repeat victories before and after publication, and both spent trophies.

The second physical transaction passes **133 checks**. Real gathered wood pays
for footing/support, spanning beam, chest and open door inside a candidate
Excited Uplands patch. Actual excavation, stored wood, source records, cargo
connections and a recovery bundle survive. Machine kits and recovery contents
are declared fixtures; placement and cargo use their normal paying APIs. A
nearby hostile defers publication after saving pending ownership. Invalid disk
paths, fully occupied preparation and injected host failure cannot advance the
live era. Double host-failure/reload passes another **eight checks**.

Actual controller walks and collision rays cross both the original bank and
new shelves. The new host instantiates the ordered specimen, then a forced
death checks finite ownership and duplicate callbacks. This death is not combat
evidence. The original dead Blue host and depleted copper/partial tin survive.
New iron is worked cold; silver is heated with an actually placed, paid charcoal
fire. Actual work and pickup collection deplete eight iron units and leave six
of eight silver units. Existing paid iron/silver recipes spend that ore. Ordinary
charcoal/wood and the archived basic-forge skill/access isolate this useful
material proof; it is not acquisition from zero or proof of steel manufacture.
The existing era-three steel/Foundry rules are retained and covered natively.

The final complete Pairing journey passes **155 checks / 824.9 m** and its
separate suspended restart passes **four**. Its ordinary safe return publishes
the second event, preserves the first ledger and retains a real pending checkpoint
for a separate-process resume. All route encounters intentionally force outcomes
and disable damage. The independent live hybrid suite passes **2,801**, single
influences **234**, and rendered tells **five** again. Latest actual starting-weapon
fights took **3.90 / 4.60 / 3.78 s**, with **5 / 6 / 8 casts**; all had one release
and finished at 100 life through successful counterplay. The earlier Ranger
receipt was 3.70 s/five casts. No invulnerability, Catalyst or injected damage
counts toward either set of combat wins.

The full Wave-4 review regression passes unchanged: protected first publication
**96**, isolated pending/applied restart **22 / 8**, historical paid seeds 5/77
**35 / 37**, save recovery **175**, Trial lifecycle **6,221**, legacy Forge walk
**122 / 814.9 m**, Annex journey **172 / 824.5 m**, and first-campaign pending /
applied restart **4 / 6**. The repeated source and machine checks retain all five
Catalyst recipes and separate signal/work/heat costs. No production-art source
is changed; the independent ART-04 commit is retained in history.
All **24 complete approaches in seeds 5 / 77** pass again (**59 / 61 checks**) on
the final world-cache code, alongside their historical paid-save fixtures.

Frozen-save compatibility results:

| Prior checkpoint | Required result | Checks |
| --- | --- | --- |
| LF4 dormant, deliberately derived old-format fixture | Only dormant second ledger; paid ownership unchanged; future schema cannot fall back to old backup | 15 |
| LF4 native first-return pending | Publishes only first event/era two; second stays dormant | 23 |
| LF4 paid isolated pending | Preserves structures, excavation, cargo and recovery; no campaign milestone without receipt | 23 |
| LF4 applied, spent Heart/depleted copper/dead Blue host | First ledger and finite ownership retained, second dormant | 13 |
| Published LF5B first clear | Missing second ledger becomes pending, never pays another Eye; then publishes era three | 23 |
| Published LF5B suspended boundary | Restores the existing Pairing revision, deposit/haul and no victory; second dormant | 14 |

All pass. The archived Pairing pickup's restored yaw differs by **2.98e-8
radians** through Godot's float32 basis/Euler conversion. Spatial drop fields
are checked within **1e-6**; all counts, item/gear seeds, age and other ownership
fields remain exact. Restarts freeze fixture pickup motion before comparing,
so ordinary flight is not mistaken for migration loss. See the frozen fixture
record for origins; no historical bytes are regenerated to make these pass.

Separate-process second-pending, applied and actual-Pairing-return resumes pass
**13 / 22 / 13 checks** with both physical ledgers. Applied restart retains every native owned field,
spent Eye, both dead hosts, depleted new iron and partial silver. The host-failure
fallback also reloads the committed candidate without another reward.

Measured second publications on this host: **13,911 ms** for the full Pairing
return, **14,482 ms** for the final isolated protected transaction,
**15,908 ms** for its pending restart, and **13,452 ms** for the actual-return
checkpoint's separate-process resume. An earlier transaction under concurrent
regression load took **21,233 ms**. The actual-renderer check measured
**14,459 ms** (matched-coverage capture rerun **14,524 ms**) and passed **four assertions**, including a rendered preparing
notice while still in era two. The before/preparing/applied observer captures
are inspected; they are not a human first-person playtest. Current first-event
regressions measured **21,149 / 14,549 ms** for Annex return/pending load.
These are implementation receipts, not controlled performance benchmarks.
The final complete campaign sequence repeats the protected transaction at
**14,243 ms** and pending resume at **13,769 ms**, with the same geometry and
ownership assertions. JSON parsing, affected documentation links and scoped
whitespace checks also pass.

Reproduction on this Windows checkout, after building the current GDExtension:

```powershell
./tools/living_frontier_wave5_checks.ps1 -Pairing -Campaign -Native
./tools/living_frontier_wave5_checks.ps1 -Hybrid -Visuals -TransitionVisuals
./tools/living_frontier_wave3_checks.ps1 -Routes
./tools/living_frontier_wave4_checks.ps1 -Terrain -Campaign -Legacy
```

Native executables link the current built simulation objects. Test saves/logs
live in isolated `build/lf5`, `build/lf4` and `build/lf3` directories. Rendered
evidence is local under `captures/lf5`; normal user saves are not used. The
headless runner includes both generations and compatibility cases. Optional
transition visuals need the campaign fixtures created by the first command.

Remaining limits: synchronous publication still freezes gameplay; a notice and
one removed regeneration do not establish transition comfort. The shelves are a
bounded regional change, not global ecology, fluid/heat terrain or an animation
system. Full-Trial human combat, novice tell recognition, narrative/discovery,
art and performance acceptance remain open. **Stop here for orchestrator review
after LF-5A/B/C. No human uber-boss, captured controls or optional Heat has begun.**
