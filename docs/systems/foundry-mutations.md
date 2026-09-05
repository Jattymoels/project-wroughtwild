# Foundry mutation grammar

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
and Steambrand now have separate timing, collection and control mechanics.
The remaining five Ember readings and other Kind/ingot rows still require the
same identity review; the 96-row coverage count is not 96 distinct mechanics.

Evolved forms retain strike, sweep, projectile or ground delivery. Movement
alone cannot make a damaging contact. Steam Plume shares one first-hit token
across each cast's fan/forks/delayed burst, and a player-wide 2.4-second gate.
The ambiguous `Smoulder +2` shorthand now says `Smoulder / 3 forms` on two lines;
the tooltip explains that this counts separate named effects, not evolution level.

### Installed early identity pass

| Route | Mechanic | Budget and gear |
| --- | --- | --- |
| Ember → Haste: Flashfire | A follow-up hit releases up to 0.45 s of an existing burn immediately and subtracts that burn time | Once per target per second; copies cap at 0.75 s. It spends the originating burn snapshot, including its burn gear, rather than adding another DoT. |
| Ember → Vigour: Bloodfire | A new ignition sheds a warm cinder at the victim; approach within 1.4 m to collect 3 life | One cinder per player every 2 s, disappears after 6 s, requires clear cover for pickup. Copies cap at 6 base life; ordinary heal scaling applies. |
| Ember → Frost: Steambrand | Hit an already chilled enemy to release a 1.6 m steam puff that interrupts nearby enemies for 0.2 s | No puff damage. One puff per player every 1.5 s; area/reach gear scales its space; bosses get one quarter of its stagger. Copies cap at 0.3 s. |

These three retain +45 ignite buildup; Steambrand also retains +20 chill. Their
old shared ignition-spread hook is removed, along with the form's old 1.5 kill
heal or 12% kill refund. Ordinary direct ingot support is retained. Secondary
fields do not trigger these new contact/ignition hooks. A burn's natural last
tick now stops at its actual remaining time, so a long frame cannot create extra
damage after Flashfire has spent part of it.

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
- This route replaces Smoulder's 25% slow and the participating Kindling spread.
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
| Frost → Preserving → ingot | **Kept Rime:** +0.8 seconds of retained field duration, within the 4.8-second cap |
| Preserving → Frost → ingot | **Rime Memory:** +15 chill buildup per full hit; pulses apply their hit fraction |
| Frost → Ember → Ember ingot | **Steam Plume:** replaces Smoulder and the participating Kindling reading with the evolved plume contract above |

Every other ordered pair currently has the same combined mechanical result when reversed.
It does not silently pick whichever Kind was iterated last. This defines the
current grammar without inventing a bespoke named reaction for all 144 ordered
pairs. Longer paths use these same composable rules. Future mutually exclusive
deliveries need an explicit conflict rule before adding them.

## Kind operations

| Kind | Baseline operation through one iron ingot |
| --- | --- |
| Ember Catalyst | +45 ignite buildup; Haste releases stored burn, Vigour sheds collectible healing, Frost releases a harmless interrupting puff. The other five ingots retain 30% ignition spread. |
| Frost Catalyst | +35 chill; a 1.6 m impact field pulses 12% of hit and buildup three times over 2.4 s; Ember instead becomes Smoulder |
| Preserving Catalyst | A 1.8 m impact field pulses 18% of hit and buildup three times over 2.4 s |
| Piercing Catalyst | Strikes/sweeps become travelling waves; projectiles/waves pierce one extra enemy |
| Impact Catalyst | Strikes/sweeps become travelling impact waves; projectile contact bursts over 1.8 m, replacing the direct hit; +0.12 s stagger |
| Bulwark Vanguard | Casting plants a 2 m seal: +10 armour while inside, for 3.2 s; strongest covering seal wins |
| Warding Vanguard | Casting plants a 2 m veil which intercepts one incoming projectile, for 3.2 s |
| Marrow | A direct-hit kill leaves a 1.8 m recovery bed, paying 4.5 life over four pulses if you stand inside |
| Sipping Marrow | Each landed direct hit sends 0.65 life back in a visible mote; it pays on arrival |
| Quicksilver | Casting leaves a 1.8 m afterimage at the casting position; three 16% hit/buildup pulses over 2.4 s |
| Striking Quicksilver | Every third attack repeats after 0.12 s; spell tablets do not read this cadence |
| Casting Quicksilver | Every third spell repeats after 0.55 s; attack tablets do not read this cadence |

Each ingot adds its own flavour to that operation: Ember +20 ignite, Frost +20
chill, Edge +20 bleed, Reach +18% reach, Vigour +1.5 life on kill, Plate +4 cast
armour, Ward +5% status ward, Haste +12% cooldown refund on kill. Smoulder has
its own explicit payload below. The three revised Ember readings use the
mechanics above instead of the Vigour/Haste form additions. These are first-pass
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

Pulses apply fractional buildup as well as fractional damage, respect solid
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

The evolution follow-up passed **28,519 native checks**, **138 focused Godot
checks**, and the complete headless pipeline. Added coverage verifies conserved
Flashfire burn damage, collectible Bloodfire healing, harmless/cover-blocked
Steambrand control, consuming and order-sensitive evolution across all sixteen
skills, independently scaled fire/cold steam packets, and one plume across a
cast's delayed projectiles, sweep or ground detonation. Movement fabricates no
hit. Eight rendered captures were reviewed, including the new early Ember
workings and Steam Plume.

Run `tools/codex_visual_review.ps1 -Foundry` for the focused gameplay checks and
eight real screenshots. `-Checks` includes this suite in the full pipeline.

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
