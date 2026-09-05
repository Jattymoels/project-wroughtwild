# Foundry mutation grammar

Owner-approved update, 6 September 2026 (D-026): Equipment catalyst grades alias their original Kind during plate evaluation. Grade-specific ownership, placement and lifting remain exact; Faint/Stable/Potent currently share the authored mutation rather than multiplying its damage. See the [forge implementation record](../prototype/forge-clarity-and-early-pacing-2026-09-06.md#implemented-outcome--6-september-2026) for tuning, sources and save compatibility.

**Status: implemented, owner-approved 5 Sep 2026 (D-025).** The owner approved
the [direction proposal](../prototype/foundry-mutation-direction-2026-09-05.md)
and added that weapons/armour must continue helping builds, with rare modifiers
eventually capable of motivating a different Foundry arrangement.

This replaces the old family-wide form tables in [foundry.md](foundry.md).
The existing frame, ownership, placement costs, milestones, classes, rails,
shared-support links and save IDs remain. All sixteen learned skills remain.

## Owner playtest correction: further evolution

After this first implementation, the owner approved transformations becoming
inputs to later transformations along a Kind chain. Their reference is Smoulder
under further Ember influence becoming **Steam Plume**: the supported skill's
first struck target anchors ground eruptions that pulse fire/cold damage.
The first concrete evolution is now installed: **Frost Catalyst → Ember Catalyst
→ Ember ingot → skill**. The input form is Smoulder; the later Ember consumes it
and its own Kindling reading at that ingot, producing Steam Plume. On longer
plates the intermediate Ember ingot can also precede the second Kind. Other
supports/branches remain independent. The detailed contract is below.

The same playtest exposed a local identity gap: Ember + Haste (**Flashfire**) and
Ember + Vigour (**Bloodfire**) initially shared +45 ignite and 30% ignition spread,
differing only by a small kill refund or heal. The owner asked for more creative
Era 1 effects with modest damage: the chosen base skill supplies speed, reach,
area and ailment feel, while the Foundry changes its use. Flashfire, Bloodfire
and Steambrand received separate timing, collection and control mechanics.
The owner's subsequent approval completes all eight early Ember readings with
the five mechanics below. The approved continuation now completes Frost and
Preserving as well: 24 base readings have individual roles. The remaining
Kind/ingot families still need their identity review; 96 rows do not mean 96
distinct mechanics.

Evolved forms retain strike, sweep, projectile or ground delivery. Movement
alone cannot make a damaging contact. Steam Plume shares one first-hit token
across each cast's fan/forks/delayed burst, and a player-wide 2.4-second gate.
The ambiguous `Smoulder +2` shorthand now says `Smoulder / 3 forms` on two lines;
the tooltip explains that this counts separate named effects, not evolution level.

### Installed early identity pass

| Route | Mechanic | Budget and gear |
| --- | --- | --- |
| Ember → Ember: Kindling | The first unlit victim carries a 0.9 s fuse that delivers 65 ignite buildup; no extra hit packet | One fuse per cast and one per player every 2.4 s. Copies cap at 100 buildup before ignition gear and boss resistance. Cancels if the target dies or is already burning. |
| Ember → Edge: Cinder Edge | Hit a burning **or** bleeding enemy to mark a narrow 3 m seam behind it; after 0.25 s it flashes for 8% of the base hit as fire | Excludes the original victim. One seam per cast and every 1.4 s per player; copies cap at 15% per recipient. Fire/area/attack-or-spell gear scales damage; area/reach scales length and 0.55 m half-width. Cover blocks both the visible seam and its damage. |
| Ember → Reach: Wildfire | Hit a burning victim to send one travelling spark to the nearest visible unlit enemy; it carries 35 ignite buildup and no hit damage | One hop per cast and every 1.5 s per player; copies cap at 60 buildup before ignition gear/boss resistance. 4.5 m search before reach/proliferation gear, 10 m/s travel, 1.2 s lifetime. No retargeting or onward hop; newly blocking cover stops it. |
| Ember → Plate: Furnace Plate | Hit a burning victim to heat a single personal charge for 2.5 s. The next damaging enemy hit you take spends it on a 2.4 m heat ring that pushes the nearby pack 0.9 m | Once every 3 s per player. Copies cap at 1.5 m push; bosses move one quarter as far. Area/reach scales radius; cover blocks the push. No extra damage, stagger or absorption; dodged hits and environmental damage do not spend it. |
| Ember → Ward: Cautery | A new ignition clears one active affliction, root before harry before mark. If already clear, it instead stores a 3 s ward against the next of those afflictions | Once every 3 s per player; never more than one charge. The afflicting hit still deals damage. A cleanse does not also award a ward, and other enemy verbs do not spend one. |
| Ember → Haste: Flashfire | A follow-up hit releases up to 0.45 s of an existing burn immediately and subtracts that burn time | Once per target per second; copies cap at 0.75 s. It spends the originating burn snapshot, including its burn gear, rather than adding another DoT. |
| Ember → Vigour: Bloodfire | A new ignition sheds a warm cinder at the victim; approach within 1.4 m to collect 3 life | One cinder per player every 2 s, disappears after 6 s, requires clear cover for pickup. Copies cap at 6 base life; ordinary heal scaling applies. |
| Ember → Frost: Steambrand | Hit an already chilled enemy to release a 1.6 m steam puff that interrupts nearby enemies for 0.2 s | No puff damage. One puff per player every 1.5 s; area/reach gear scales its space; bosses get one quarter of its stagger. Copies cap at 0.3 s. |

All eight supply +45 ignite buildup to the main hit; Steambrand also supplies
+20 chill, and Cinder Edge +20 bleed. Their old shared ignition-spread hook and
generic ingot-flavour additions are removed. Ordinary direct ingot support,
pairs, backing and alloy refinements remain. A burn's natural last
tick now stops at its actual remaining time, so a long frame cannot create extra
damage after Flashfire has spent part of it.

The new contact operations read the ailments present **before** Flashfire spends
burn time and before this hit applies its payload. Thus Cinder Edge can read an
existing burn even if Flashfire spends its last fraction. They share each cast's
context across fans, forks and delayed bursts. Each operation commits its first
eligible contact even if its player-wide time gate is unavailable. Wildfire needs
a reachable unlit recipient before committing. A fresh cast cannot refresh an
attached fuse or an unspent personal charge. Names never determine behaviour.

Fuses and sparks snapshot their sim-resolved buildup, burn and Sear when created;
seams snapshot their fire packet and geometry. Increased/more ignition investment
scales their authored buildup; flat buildup still belongs to the main hit and is
not paid twice. Ordinary boss buildup resistance and ignite immunity apply.
The base fuse's 65 plus a plain 45-buildup strike can light a normal enemy after
the delay even with normal buildup decay; a resistant boss needs more work.

Terminal fuse/spark ignition may trigger **only** the separately limited Bloodfire
cinder and Cautery cleanse/ward. This lets those supports cooperate. It cannot
make another fuse, spark, seam, link, echo or mastery use. Existing burn-on-death
proliferation still applies. Steam Plume and the cold/memory events below have explicit secondary-event contracts.
There are at most twelve live Ember event nodes per player, independently of the
existing field/mote limits. Excess events are rejected without a free payout;
death and save application cancel all of them. No combat charge is saved.

### Three early arrangements with one skill

All three fit the original era-one working: Heavy Strike at (1,1), an Ember
Catalyst at (2,0), and the two ingots at (1,0) and (2,1). No new page, rail or
alloy is required. The cast remains Heavy Strike in each case.

| Ingots | What changes in play |
| --- | --- |
| Ember + Reach | **Kindling / Wildfire:** light the first victim with a delayed fuse; follow up to carry ignition to an unlit neighbour. Proliferation reach and ignition gear support this spreading build. |
| Edge + Haste | **Cinder Edge / Flashfire:** line enemies behind a burning or bleeding victim, then spend burn early while cutting the rear rank. Fire/area investment and ordinary Haste recovery support repeated commitments. |
| Plate + Ward | **Furnace Plate / Cautery:** ignite to clear or prevent an affliction, then hit the burning victim to prepare a shove when an enemy lands its next hit. Ordinary armour and Ward mitigation still do the actual damage reduction. |

These are playtest arrangements, not claims of equal damage or solved balance.
All sixteen skill shells resolve every Ember reading; damaging contact is still
required. Dash cannot invent a fuse, seam, spark or ignition reward just by moving.

### Frost: space, contact and movement

All eight Frost readings now have separate roles. Smoulder retains its existing
slowing-burn contract. The other seven supply +35 chill to the main hit;
Rime Edge also supplies +20 bleed. Their former generic 12% impact fields and
extra ingot-flavour additions are removed. Direct supports and alloys remain.

| Route | Early mechanic | Bounds and equipment |
| --- | --- | --- |
| Frost → Frost: Rimewell | First contact sends a ring to 2 m over 0.8 s; each visible enemy receives 20 chill once, without hit damage | One ring per cast and per player every 2 s. Buildup caps at 35 before increased/more chill and boss resistance; flat main-hit buildup is not paid again. |
| Frost → Edge: Rime Edge | Hit an already chilled/frozen victim; after 0.2 s two lateral ice cuts hit its neighbours for 6% of base hit as cold | Excludes the original victim. 2.4 m to either side, 0.4 m half-width along the attack direction. One pair per cast/every 2 s; fraction caps at 12%. Cold/area/attack-or-spell damage gear applies; area/reach scales the cuts, cover stops them. No added buildup. |
| Frost → Reach: Whiteout | Hit a chilled victim to leave a 1.7 m mist for 2.4 s; crossing enemy shots lose 40% speed for their remaining flight | One mist per cast/every 2 s; slow caps at 55%, applied only once per shot. Full swept travel respects cover and integrates the speed change at mist entry. No damage. |
| Frost → Vigour: Cold Sap | A chilled hit draws ice skin for 2.5 s; the next damaging enemy hit loses up to 3 damage after armour/resistance | One charge every 3 s, never stacks; caps at 6 absorption. Dodged, fully mitigated and environmental hits do not spend it. It does not block an enemy's affliction. |
| Frost → Plate: Permafrost | Bind an already chilled victim's feet for 0.45 s; it can still attack | One bind per cast/every 2 s; duration caps at 0.65 s. Bosses lose 25% movement instead of stopping. Chill immunity prevents the bind. No stagger, freeze or interrupt. |
| Frost → Ward: Stillwater | A real cast leaves a 1.3 m ice mirror for 1.6 s; catch one shot and return a needle to its living shooter | One mirror every 3 s. Needle starts at 8% of base hit as cold plus 15 chill; damage fraction caps at 15%, each capability reads its gear and boss resistance. Travels at 12 m/s, expires after 1.2 s, respects cover; no child attacks. |
| Frost → Haste: Hoarfrost | Hit a chilled enemy to recover 0.35 s of the longest remaining movement cooldown | One recovery per cast/every 2 s; caps at 0.6 s. No attack refund and no banking while movement is ready. |

A Frost contact reads existing chill before that hit's payload. This encourages
an opener and follow-up; Rimewell can start that control without prior chill.
The rings, ice cuts, mist and mirror have separate visual geometry. Cold Sap
shows its available charge in the ordinary combat HUD.

### Preserving: keep a useful moment

Preserving no longer gives all eight supports the same 18% damage/buildup field.
It keeps time, a position or one future opportunity according to the ingot.
Ember, Frost and Edge retain +20 ignite, chill and bleed respectively on the main
hit. Other former flavour bonuses are removed; direct ingot support remains.
All eight operations have a player-wide 3 s gate per operation. Contact effects
also spend one eligible-contact token per real cast, shared by fans and forks.

| Route | Early mechanic | Bounds and equipment |
| --- | --- | --- |
| Preserving → Ember: Emberbed | A burning hit moves up to 0.6 s of the existing burn into a 1.8 m bed; two pulses 0.8 s apart share that stored fire damage | Removes exactly that time from the burn. Caps at 1 s taken; snapshots originating burn gear/Sear. The original victim inside the bed receives the same total burn budget, while neighbours can receive the redistributed portion. No new buildup or child event. |
| Preserving → Frost: Cold Reservoir | Hit a chilled victim to hold its buildup against decay for 1.2 s | Base hold caps at 1.8 s; actual freeze duration keeps counting down normally. No additional buildup or damage. |
| Preserving → Edge: Wound Memory | A bleeding hit gives one wound up to 1 s of stationary preservation; both bleed time and damage pause, resuming while moving or after that credit is spent | Credit caps at 1.5 s, available during the 3.2 s memory window. Refreshing an existing bleed cannot replenish it; a new wound can. A long final bleed tick pays only the actual remaining duration. |
| Preserving → Reach: Afterfield | First contact leaves a 1.8 m field for 3.2 s; its first new arrival triggers one 12% echo of the original native hit for newcomers inside | Every visible original occupant is remembered and excluded. Fraction caps at 20%; native damage/area/attack-or-spell gear applies. No acquired-element duplication, buildup or child attacks. |
| Preserving → Vigour: Lifebed | A real cast marks its old position for 3.2 s; leave its 1.8 m bed and return to collect 3 life once | Standing still pays nothing. Base recovery caps at 6 before healing gear. Return must be in range and clear of cover. |
| Preserving → Plate: Held Ground | A real cast leaves a 1.8 m seal for 3.2 s; shove its first arriving enemy 0.9 m outward | Original occupants are ignored. One charge; push caps at 1.5 m and bosses receive a quarter. No damage. |
| Preserving → Ward: Sanctuary | A direct-hit kill leaves a 1.8 m ward for 3.2 s; it catches one enemy shot | One charge regardless of duplicate readings, no reflection. Secondary/DoT kills do not create it. Cover before the ward stops the shot first. |
| Preserving → Haste: Lingering Step | After a real cast, use a different skill within 3.2 s to recover 0.3 s of the first skill's remaining cooldown | One personal memory; refund caps at 0.6 s and floors at zero. Repeats/linked casts neither create nor spend it. The completing skill retains its own cooldown. HUD prompts the switch. |

Kept Rime now extends these memory windows by 0.8 s, capped at 0.8 s across
copies. Its authoring key is `mutation_memory_extension`, replacing the obsolete
retained-field duration reading. Cold Reservoir lasts longer; positional memories
wait longer; Wound Memory's opportunity lasts longer but its pause credit does
not grow. Emberbed uses three pulses instead of two, dividing **the same** removed
burn damage across them. It never grants three copies of the stored burn.
This is a duration refinement; Steam Plume remains the first consuming evolution.

Frost and Preserving share a maximum of sixteen live event nodes per player.
Excess events are rejected without a free payload. Player death/load cancels
charges, needles and marks and releases their own temporary status clocks.
No transient charge is saved. All new values and ceilings are explained beside
`mutation_limits`; read-only modifier definitions stay outside the loot pool.

All sixteen skill shells resolve these forms. Damage and contact mechanics need
an actual hit; movement has no base damage. A Dash can plant Stillwater (its
caught-shot needle has chill but zero invented hit damage), Lifebed or Held
Ground, or participate in Lingering Step. It cannot seed Rimewell, Smoulder,
Emberbed or Afterfield just by moving. The Foundry inspector says so explicitly.

### Four more arrangements to playtest

Use the original working: the skill at (1,1), Kind at (2,0), and the two ingots
at (1,0)/(2,1). These test roles, not claims of equivalent power.

| Skill / Kind / ingots | Intent |
| --- | --- |
| Bow Shot / Frost / Reach + Ward | **Whiteout + Stillwater:** shape incoming projectile lanes and time a one-shot return while keeping the bow's original delivery. |
| Heavy Strike / Frost / Edge + Haste | **Rime Edge + Hoarfrost:** follow a chilled opener with lateral cuts, recovering some movement to reposition. |
| Heavy Strike / Preserving / Ember + Reach | **Emberbed + Afterfield:** spend part of an existing burn into the ground and draw fresh enemies through the place where you struck. |
| Bow Shot / Preserving / Vigour + Haste | **Lifebed + Lingering Step:** leave a casting mark, switch to another skill, then return for a small recovery. |

### Steam Plume contract

- The original skill still hits in its chosen delivery and native damage type.
  The first eligible enemy struck anchors a 1.7 m field for 2.4 s; area/reach gear
  scales its radius. A missed strike, empty ground detonation or movement alone
  cannot seed a plume. A cast blocked by the shared time gate cannot seed one on
  a later contact; a later real cast gets its own first-contact token.
- Three pulses, 0.8 s apart, each start from 6% of the skill's base hit: half fire,
  half cold. Each part resolves its own damage/area/attack-or-spell gear in the
  sim, then snapshots when the field is created. Each enemy applies its own
  fire/cold resistance, positional guard and ward. Cover blocks the pulse.
  This is 18% of base hit over the entire field before investment, not three
  full copies of the skill. Stacked readings cap at 10% per pulse.
- This route replaces Smoulder's 25% slow and the participating Kindling fuse.
  The main hit retains 40 ignite and 20 chill buildup, so gear can still develop
  its burn/freeze lanes. Steam pulses themselves apply no buildup, shatter,
  links, recovery or additional mutation triggers. Existing enemy death rules
  still apply if a pulse kills an enemy that was already burning.
- The existing 12-field limit applies. Save application and death cancel fields,
  cinders and cosmetic puffs. Owned skills, ingots, Kinds and coordinates persist.
- `FormDef.id` gives a stable authoring identity; `input_form` matches that
  resolved identity plus the later exact Kind. One physical Kind performs at
  most one rewrite. The loader rejects missing inputs, duplicate IDs and
  ambiguous input/Kind rules. This pass authors one evolution, not an automatic
  recipe for every repeated Kind or a complete late-game progression catalogue.

## Player contract

- Ingots keep their ordinary additions. Iron is the accessible starting point.
  Bronze and steel direct supports gain additional mastery/control/recovery
  readings; Reach gains projectile pierce at bronze and a fork at steel.
- A **specific Kind** transforms every ingot on its inward route. There is no
  common Catalyst reaction inherited by every offensive Kind.
- The ingot cell displays its resolved name, retaining the owned ingot and metal
  in the tooltip. Workings describe the resulting mechanics. Hovering a cell
  draws the native resolver's route. Selecting a piece previews the actual
  placement on a copy of the economy, including ownership and legality checks.
- Equipment scales the resulting capabilities. A travelling melee wave keeps
  `attack` and acquires `projectile`; projectile weapon/charm modifiers now have
  a job in that build. Smoulder acquires cold/chill while retaining its fire burn.
  Armour and shields still provide mitigation beneath positional protection.

## Routing and combination rules

Depth is Manhattan distance to the nearest socket, including empty sockets.
Kinds rest at depth two or greater. Each step is orthogonal, forged, occupied
and exactly one depth nearer a socket. A live route ends at an ingot adjoining
a laid, known skill. Gaps, diagonals, outward steps and empty tablets do not
conduct. Alloy reach still applies to backing/pairs, and never jumps a flow gap.

Every branch is followed. A source Kind transforms every ingot encountered,
including intermediate ingots beyond the direct support. A downstream Kind
normally retains the upstream identity: both deliver their readings. An explicit
`input_form` evolution consumes the participating local readings instead. A shared support
can deliver to both socketed skills.

One source Kind, ingot cell, receiving skill and form row is emitted once even
when two routes reconverge. Separate ingot cells are separate investments.
Duplicate Kinds add their numerical readings within the operation ceilings;
boolean capabilities do not stack. Multiple cadence readings retain the shortest
cadence, rather than summing into a slower repeat. Separate overlapping fields
can contribute, subject to the field budget; numerical balance still needs playtesting.

Ordered Kind pairs normally compose their individual operations. Three authored
ordered readings currently go beyond that default:

| Inward order | Additional reading |
| --- | --- |
| Frost → Preserving → ingot | **Kept Rime:** +0.8 s to Preserving memory windows; longer Emberbed divides the same stored damage |
| Preserving → Frost → ingot | **Rime Memory:** +15 chill buildup per full hit; secondary cold/memory events do not pay this again |
| Frost → Ember → Ember ingot | **Steam Plume:** replaces Smoulder and the participating Kindling reading with the evolved plume contract above |

Every other ordered pair currently has the same combined mechanical result when reversed.
It does not silently pick whichever Kind was iterated last. This defines the
current grammar without inventing a bespoke named reaction for all 144 ordered
pairs. Longer paths use these same composable rules. Future mutually exclusive
deliveries need an explicit conflict rule before adding them.

## Kind operations

| Kind | Baseline operation through one iron ingot |
| --- | --- |
| Ember Catalyst | +45 ignite buildup; eight distinct ingot mechanics: delayed fuse, chilled interrupt, narrow seam, travelling spark, collectible healing, reactive push, affliction cleanse/ward and stored-burn release. See the early identity table above. |
| Frost Catalyst | Eight separate cold/control roles: Smoulder, an expanding chill ring, lateral cuts, shot-slowing mist, ice skin, foot binding, a reflected needle and movement recovery. See Frost above. |
| Preserving Catalyst | Eight separate memory roles: stored burn, retained chill, a held wound, a newcomer echo, return recovery, an arrival shove, a kill ward and a switching refund. See Preserving above. |
| Piercing Catalyst | Strikes/sweeps become travelling waves; projectiles/waves pierce one extra enemy |
| Impact Catalyst | Strikes/sweeps become travelling impact waves; projectile contact bursts over 1.8 m, replacing the direct hit; +0.12 s stagger |
| Bulwark Vanguard | Casting plants a 2 m seal: +10 armour while inside, for 3.2 s; strongest covering seal wins |
| Warding Vanguard | Casting plants a 2 m veil which intercepts one incoming projectile, for 3.2 s |
| Marrow | A direct-hit kill leaves a 1.8 m recovery bed, paying 4.5 life over four pulses if you stand inside |
| Sipping Marrow | Each landed direct hit sends 0.65 life back in a visible mote; it pays on arrival |
| Quicksilver | Casting leaves a 1.8 m afterimage at the casting position; three 16% hit/buildup pulses over 2.4 s |
| Striking Quicksilver | Every third attack repeats after 0.12 s; spell tablets do not read this cadence |
| Casting Quicksilver | Every third spell repeats after 0.55 s; attack tablets do not read this cadence |

Outside the completed Ember, Frost and Preserving families, each ingot adds its own flavour to that operation: Ember +20 ignite, Frost +20
chill, Edge +20 bleed, Reach +18% reach, Vigour +1.5 life on kill, Plate +4 cast
armour, Ward +5% status ward, Haste +12% cooldown refund on kill. Smoulder has
its own explicit payload below. The three completed families use the
individual mechanics and explicitly retained ailment additions above. These are first-pass
values, not balance claims.

The current sixteen skills are not all equally useful with every Kind. Movement
tablets have no hit to retain or pierce, although cast seals and trails can be
created; trails then only deliver status payloads supplied by the build. A ground
spell retains its ground delivery when given Impact/Piercing, and never acquires
a phantom projectile tag. Cadence incompatibility is shown as no compatible
mutation in the flow inspector. These are deliberate compatibility boundaries.

## Smoulder

Frost Catalyst → Ember Ingot → skill produces **Smoulder**. That reading grants
40 ignite and 20 chill buildup. Existing skill payloads and eligible equipment
add to these. Ignite still uses the existing 100 threshold, decay and boss
buildup resistance; crossing it starts one fire burn with an attached 25% slow.

- The slow lasts exactly as long as the burn. There is no second fire DoT.
- Bosses receive one quarter of the movement loss. Chill-immune enemies reject
  the slow; ignite immunity prevents the burn. Freeze remains a separate buildup
  threshold, with its existing boss resistance and shatter protection.
- Fire burn modifiers and per-skill duration readings scale the burn. Cold
  buildup gear scales the acquired chill. Cold *damage* does not multiply the
  native fire packet or fire DoT merely because cold is now an effective tag.
- Re-ignition replaces/refreshes the single burn and its slow with the new
  ignition's snapshot. Death proliferation and Ember's on-ignite spread carry
  that burn snapshot and Smoulder identity; spread does not recursively invoke
  another on-ignite spread. A later ordinary ignition can replace Smoulder.
- Ordinary burn/shatter behaviours remain valid. Smoulder is compatible with
  a freezing build; it does not grant a free freeze or boss execution.

Frost Catalysts drop from Gloom Crawlers at the initial 7% chance and are in the
existing three-for-one exchange. They aim gear crafts at the cold modifier pool.
They use the existing catalyst pack/material convention; no new currency family.

## Engine boundaries and budgets

`data/tuning/foundry.json` owns all forms, refinement values and `mutation_limits`.
Its limits' `design_purpose` explains every number. New modifier entries in
`items.json` use the `reading` tag and never enter the random equipment pool.
The native simulation resolves names, paths, modifiers, acquired tags and caps;
Godot owns collision, cover, time, visuals and choosing spatial recipients.

Initial ceilings: 45% Smoulder slow, 4.8 s retained field, 50% hit/buildup per
pulse, 4 m base field radius, 40% trail pulse, 3 m base impact radius, 24 seal
armour, three ward charges, ten recovery life, two siphoned life per hit,
0.8 s echo delay and 100% ignition spread. Area and reach equipment scale area
radii. The pulse interval is 0.8 s. A player can have twelve fields and twenty-four
returning motes; a new field replaces the oldest at capacity. Excess motes pay
no extra heal. Melee waves travel 12 m at 16 m/s before reach; motes return at 9 m/s.

Legacy generic fields apply fractional buildup as well as fractional damage, respect solid
cover, and do not shatter, trigger links, create more fields or generate return
motes/recovery beds. Direct-hit recovery currently excludes shatter-cascade and
DoT-only kills. This is a reported prototype boundary, not a promise of universal
on-kill attribution. Ordinary life-on-hit/kill gear hooks retain their existing
semantics. Repeated casts do not award mastery, reset the real cooldown or
schedule another echo; they use your aim when the repeat fires.

Ward interception checks the full enemy-projectile segment up to its first
world/player collision, plus cover from the seal. A fast shot cannot tunnel
through a ward and a wall cannot be bypassed to reach it. Fields are projected
onto nearby ground for presentation. All mutation nodes cancel on death/save
application; cadence counters and mutation caches clear when a save is applied.

Projectile delivery is committed on launch. Damage/buildup resolve against the
current build when they land, consistent with existing projectiles; ignition
snapshots its DoT. Full cast-time snapshots and attribution for delayed kills
remain future work if playtesting calls for them.

## Itemisation and future work

Foundry forms grant capabilities, equipment scales them, and crafting/material
progression increases what direct ingots can express. Item pools, rarity counts,
held-back tiers and owned rolls are preserved. No new random rare affix catalogue
is introduced in this pass.

The next itemisation pass should author a **small set** of scarce rule-changing
modifiers that encourage new arrangements: e.g. an item interested in cold buildup
on a burn, or in a projectile produced by an attack. These remain proposals;
they should use the same tag/operation contracts, with explicit proc budgets and
compatibility tests rather than another source of generic damage multipliers.

## Verification

Native tests cover all 4,608 base Kind/ingot/metal/skill fixtures, all 2,304 ordered
Kind-pair/ingot/attack-or-spell fixtures, larger-plate branches and reconvergence,
packet isolation, gear scaling, scoped burn duration and unchanged save IDs.
The Godot suite exercises Smoulder, boss slow, spread, pulse timing/cover,
travelling melee, one-hit impact bursts, wards, armour position, recovery,
return timing, echoes, non-mutating previews, 720p layout and death cleanup.
Existing economy, loot, combat, world and save suites also run.

The completed Ember pass passed **29,038 native checks**, **246 focused Godot
checks**, and the complete headless pipeline. Added coverage verifies conserved
Flashfire burn damage, collectible Bloodfire healing, harmless/cover-blocked
Steambrand control, consuming and order-sensitive evolution across all sixteen
skills, independently scaled fire/cold steam packets, and one plume across a
cast's delayed projectiles, sweep or ground detonation. Movement fabricates no
hit. The Ember extension covers fuse timing/decay/immunity, snapshot buildup and
equipment scaling, one-hop arrival/cover, the seam's shape and single packet,
retaliation consumption/boss push, single-affliction cleanse/prevention, and
death/load/budget cleanup. Fourteen rendered captures include three different
Heavy Strike arrangements alongside the earlier workings and Steam Plume.

The Frost/Preserving continuation adds tests for each role, exact swept mist
entry, post-mitigation absorption, preserved ailment budgets, movement
compatibility, entry/return requirements, expiry, cover and death/load cleanup.
Native checks now total **29,934**, with **449 focused Godot checks** and the complete headless pipeline passing.
Eight more rendered captures pair real Foundry arrangements
with their runtime effects.

Run `tools/codex_visual_review.ps1 -Foundry` for the focused gameplay checks and
twenty-two real screenshots. `-Checks` includes this suite in the full pipeline.

The following table is the complete current base-name matrix. Numeric effects
remain authoritative in the tuning file; names never replace persistent IDs.

| Kind | Ember | Frost | Edge | Reach | Vigour | Plate | Ward | Haste |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Ember Catalyst | Kindling | Steambrand | Cinder Edge | Wildfire | Bloodfire | Furnace Plate | Cautery | Flashfire |
| Preserving Catalyst | Emberbed | Cold Reservoir | Wound Memory | Afterfield | Lifebed | Held Ground | Sanctuary | Lingering Step |
| Bulwark Vanguard | Furnace Bastion | Rime Bastion | Blade Bastion | Broad Bastion | Living Bastion | Bulwark | Guardpost | Quickbrace |
| Warding Vanguard | Ember Veil | Rime Veil | Razor Veil | Wide Veil | Living Veil | Iron Veil | Aegis | Fleeting Veil |
| Marrow | Phoenix Bed | Winterroot | Bloodroot | Harvest Ground | Second Spring | Ironroot | Safe Harbour | Fleet Harvest |
| Quicksilver | Cinder Wake | Frost Wake | Razor Wake | Long Wake | Living Wake | Iron Wake | Warded Wake | Afterimage |
| Piercing Catalyst | Cinder Lance | Ice Lance | Razor Wave | Throughline | Blood Thread | Breach | Wardneedle | Quicklance |
| Impact Catalyst | Firebreak | Glacier Break | Concussion | Shock Ring | Heartbreak | Anvil Fall | Sealbreak | Snapburst |
| Sipping Marrow | Cinder Siphon | Cold Siphon | Bloodletter | Long Drink | Deep Drink | Iron Drink | Ward Siphon | Quick Sip |
| Striking Quicksilver | Cinder Refrain | Frost Refrain | Doublecut | Sweeping Refrain | Sustaining Refrain | Braced Refrain | Guarded Refrain | Threefold Step |
| Casting Quicksilver | Ember Echo | Frost Echo | Blade Echo | Wide Echo | Living Echo | Braced Echo | Warded Echo | Aftercast |
| Frost Catalyst | Smoulder | Rimewell | Rime Edge | Whiteout | Cold Sap | Permafrost | Stillwater | Hoarfrost |
