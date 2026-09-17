# Owner playtest: scarcity, earned machinery, combat and construction

Recorded 17 September 2026. These are owner observations and exploratory ideas,
followed by coordinator recommendations. No gameplay changes, new wave, numerical
balance or implementation dispatch are approved by recording this note. LAND
remains 7/7 stages delivered, including 5/5 implementation slices integrated.

## What the owner experienced

- Early resource poverty feels good. The Foundry becomes powerful too early with
  dropped ingots/Kinds and the combined catalyst, ingot and mastery damage spike.
  Proposed remedy: forge finished ingots from raw drops instead of finding them
  on mobs. Forging/ore gathering has not yet been explored extensively by the owner.
- One nighttime pack overwhelmed and killed the player; the fear was enjoyable.
  General pack density can remain, provided particular biomes/night and valuable
  meteor areas offer threatening groups or enhanced creatures and richer resources.
- Stone gathering itself is enjoyable, but throughput feels suited to bench
  recipes rather than house construction. Preserve initial friction, then earn a
  better method through gathering, exploration, refining and device construction.
- Natural caves currently feel unsuccessful: few/no mobs noticed, and falling in
  without supplies may make escape impossible. This is reported experience/risk,
  not a reproduced universal softlock. The owner is undecided between improving
  caves and suspending natural cavities while retaining diggable layered ground,
  ore and underground homes.
- Building feels good, but repeatedly opening Tab to rotate pieces is frustrating.
  The owner wants direct rotation and straight diagonal walls with endpoints on
  square-grid vertices, enabling octagonal rooms alongside existing triangles.

## Owner proposals to retain

An early placeable extractor performs the function of a drill, but should look
fantastical and appropriate to a lone survivor. The first version requires the
player to operate it directly. It is slow, but yields stone faster with less
searching than vein/wedge gathering; it wears out relatively quickly. Discovering
coloured resources, refining them and learning how to connect them improves it:
White could bring other ores; Blue could improve durability (other ideas invited);
Red speeds extraction with some extra wear but a clear net benefit; Green could
occasionally duplicate stone. Later exploration, labs/bosses and eras could enable
colour combinations, automation and greater power/volatility. The owner wants
this earned-capability pattern in other resource activities, possibly excluding
tree cutting. A literal industrial drill is not the requested aesthetic.

Rare ores should feel momentous and materially change a build or unlock a useful
tool/production capability. Each class should start with a crude suitable weapon;
weapon actions require the appropriate bow, blade or wand/conduit. Inherent area
skills may remain independent because packs need practical answers. Cold should
noticeably slow before eventually freezing. Bleed/ignite should apply more
reliably with smaller individual damage and capped stacking, making tough enemies
engaging. Boss resistance should prevent trivialisation. These are desired feel
and proposed mechanics, not selected proc rates, stack counts or a claim about
the precise rules of the owner's Path of Exile reference.

## Coordinator recommendation: earn a change in how work is done

Preserve the satisfying lean beginning, then make exploration unlock a different
activity, not merely a larger number. The resource loop is: want a larger home →
outgrow hand gathering → build a basic extractor → discover enhanced hosts →
refine a useful force → modify the tool → build a more capable workshop/home.
This directly supports the ambition/capability loop in [DESIGN](../DESIGN.md).

### Economy and danger

Recommend workshop-produced finished ingots, with suitable raw inputs replacing
routine finished-ingot drops. Audit ordinary mobs, elite bonuses, chests and trial
rewards together when implementing, rather than assuming one drop table owns all
acquisition. Preserve already owned items. Here “forge” means the crafting station;
the capital-F Forge combat trial is a separate system, and mandatory combat-trial
gating is not inferred from this note.

Keep an early interesting Foundry mutation, but postpone the large multiplicative
damage payoff. Tune acquisition and the combined catalyst/ingot/mastery result
before increasing danger globally. Existing [D-025 Foundry direction](../systems/foundry.md)
explicitly values early Kind identity: revise that contract deliberately if needed.
Dangerous resource pockets should have readable warning, an approach/escape route
and a worthwhile finite reward. Quieter building land remains useful. More mobs
everywhere would dilute these choices and is not the owner's request.

### Proposed extractor: a Stoneheart frame

Working name and original concept, not an accepted asset brief: a lashed timber
and stone frame drives a heavy resonating wedge into a visible cut. The survivor
works its lever; connected force modules visibly change its motion and the rock's
response. Start with a mechanical frame, then augment it. Retain the costly frame
and service a cheap wearing tooth/insert rather than repeatedly destroying the
whole machine. Its stone throughput must support a modest house within an
enjoyable session; exact rates need one representative house bill of materials.

| Force | Recommended upgrade | Lore and economic boundary |
| --- | --- | --- |
| White / Impulse | Separate and eject mineral inclusions alongside stone | Force fractures real host material. Recover ores actually present; do not roll precious metal from arbitrary dirt. |
| Blue / Retention | Hold alignment/pressure, reducing wear and interruptions | Preservation makes longer work sessions possible. Later it could retain manually charged strokes for a short autonomous burst; retained work is paid work. |
| Red / Excitation | Faster driven pulses with moderately increased tooth wear | Clear net throughput benefit after servicing, visibly more active rather than only red light. |
| Green / Propagation | Spread the fracture through connected rock, recovering more usable stone per action | Recommend improved recovery from a finite reserve. Literal matter duplication is the owner's alternative proposal and needs an explicit economy-rule change. |

The existing Green junction branches requests and each receiver pays its own
inputs; it does not duplicate matter ([construction](../systems/construction.md)).
These extractor upgrades are new proposals, not capabilities of existing devices.
Visible excavation, yield and depletion must agree; respect paid structures,
support/collision, protected ownership and save/reload accounting. Do not turn
rare-ore exploration into idle lottery farming. Prove manual extraction plus one
colour first, then expand modules/combinations. Later autonomy should visibly add
a source of drive and material handling, not appear just because a timer expires.

### Combat and caves

Give starting equipment a practical identity, while preserving skill ownership
and cross-class build freedom. Weapon-required action tags and innate exceptions
need a deliberate update against D-016's skills/equipment separation, including
what happens on weapon swapping and death. Do not accidentally leave a starter
with an unusable bar or remove its only pack answer.

Recommend readable chill slowing into freeze, and reliable lower-damage DoT
applications with a per-target cap and explicit duration/refresh rules. Existing
code already builds chill toward freeze (`game/scripts/enemy.gd`); desired slow
feel and stacking are not established by that fact. Prefer understandable boss
resistance over unexplained repeated failed applications. Existing enemy
immunities (including Hollow Knight ignite immunity in world tuning) must be
considered explicitly when assessing the owner's tough-enemy example.

Retain excavation and underground building. First verify the reported escape
problem in one representative fall with low supplies and settle a dependable
escape method. Do not erase caves or fill old saves from this observation.
Recommend deferring a large cave-content expansion; cave improvement versus fewer
natural cavities in future generation remains an owner decision. The absence of
encountered fauna does not establish that every generated cave is empty.

### Direct rotation and square-grid octagons

Source inspection finds default **R** (`game/project.godot`, physical key 82)
calling `rotate_preview` through `game/scripts/player.gd`. In
`game/scripts/grid_placement.gd` it turns shapes marked oriented by quarter-turns.
Current chamfer/triangle pieces are oriented. Ordinary face-snapped walls use the
target face instead. This was not tested live in this documentation task; an
affected shape or remapped key may still expose a bug. Record missing on-screen
guidance/current-input feedback as a usability concern, not a nonexistent feature.

Yes: straight walls along square edges and corner-to-corner diagonals can make
octagonal rooms. Current `codex_corner` is a chamfer block reserving a whole cell;
it is not the owner's proposed thin diagonal segment. A proper version needs
diagonal segment addresses/occupancy, endpoint snapping, collision, joins,
door/floor/roof treatment, costs and saved ownership. A diagonal span is sqrt(2)
times an edge span, so visual length and cost need a conscious rule. Shared
endpoints must join cleanly; crossing diagonals must not silently overlap.

There is no evidence here of an engine ceiling: the project already has diagonal
forms and distinct lattice element types. The work is extending these rules.
Clipped-corner octagons fit a square grid; an exactly regular octagon cannot have
all vertices on one uniform square lattice. Approximation/finer snapping suffices
for practical octagonal homes unless exact regularity is explicitly requested.

## Proposed follow-on priorities — no new wave dispatched

1. Finish consolidating this playtest round. Separate actual escape/progression
   blockers and control defects from optional mechanics. Keep the good scarcity,
   dramatic world and frightening occasional encounter as design anchors.
2. Design a bounded early progression/resource loop: finished-ingot acquisition,
   Foundry power pacing, rare-ore capabilities and a modest home's stone demand.
   This is now the coordinator's recommended planning priority before expanding
   weighted biome breadth; it gives richer regions concrete reasons to visit.
3. Build one approved extraction progression once scoped; baseline plus one force,
   with real excavation and save ownership. Plan combat/status and diagonal-wall
   work separately rather than placing every note inside that implementation.
4. Feed the agreed resource rewards and local danger into the previously proposed
   biome × influence × host catalogue and weighted generation contract. Prove
   single-force cases before rare mixtures. Colour combinations, era escalation,
   full automation and cave-content expansion remain later proposals.

No new slice IDs/count are selected. Existing specifications remain authoritative
until a concrete work item selects changes. This note records observations and
recommendations only; documentation links/diff are checked, with no imports,
gameplay tests, benchmarks or worker launches.
