# Foundry mutations: the build is made along the path

**Status:** Owner approved implementation on 5 Sep 2026, adding continued
weapon/armour support and future build-defining rare modifiers. The proposal below
is preserved as the design record. The installed contracts, tuning, completed
scope and remaining boundaries are in [foundry-mutations.md](../systems/foundry-mutations.md)
(D-025). No owned skill, item or ingot IDs were migrated or removed.

## Requested outcome

The owner wants a compact set of useful base skills which acquire much of their
identity inside the Foundry. The previous expansion added breadth, but preserved
too much family-wide behaviour and therefore did not deliver this fantasy.
The intended eventual catalogue can exceed today's sixteen skills while staying
well below PoE's scale; no current skill deletion is requested.

The owner establishes these distinctions:

- Direct supporting ingots give straightforward additions early. Better
  forging, facilities and resources unlock richer additive capabilities later,
  including mastery and propagation. They remain understandable building blocks.
- A specific Catalyst or other Kind changes the meaning of the path it enters.
  It biases inward toward the skill, mutating/enhancing what it passes through.
- Early Kinds should already make a noticeable difference to how a fight is
  played. Larger plates and developed materials allow more elaborate builds.
- The supporting ingot's visible name should become its resolved form, while its
  underlying ingot and material remain inspectable.
- The grammar must account for every supported combination, including later
  routes, branching, convergence and additional Kinds.

These supersede the earlier generic-catalyst interpretation of D-023 and refine
D-019/D-020: restrained early numerical power is compatible with an early
transformative mechanic. The old statement that a catalyst's own element does
not determine its plate reaction is superseded by this owner direction.

## Audit of the present implementation

At `8f753d3`, there are eight ingots, eleven Kind variants and three ingot metals.
Of 51 `foundry.json` form rows, 47 are family-wide; four specify a particular
Kind. Ember and Preserving Catalysts consequently select identical form rows.
Piercing and Impact inherit those same rows and add only two specific rows each.
The defensive, life and speed variants have different bases but share forms.

`foundry::flowsToSkill` returns a connectivity boolean. `foundry::effects`
then reads supports immediately beside each Kind; it does not carry a mutated
description of the skill through every intermediate piece. A distant Kind can
contribute its base through a connection without its identity transforming the
intermediate route. The panel displays the original ingot name and puts forms
in explanatory text. These are substantive gaps, not just missing visual effects.

Affected implementation: `sim/src/foundry.cpp`, `sim/src/grammar.cpp`, tuning
schemas/binding views, real-time skill/status delivery, Foundry previews and save
compatibility. Relevant tuning: `foundry.json`, `items.json`, `grammar.json`,
`skills.json`, `combat_realtime.json` and Kind sources in `crafting/world.json`.

## Proposed division of responsibilities

| Part | Question it answers | Example |
| --- | --- | --- |
| Base skill | How does the player begin the action? | Fire projectile, close strike, aimed ground mark |
| Supporting ingot | What capability is added? | Fire damage, reach, recovery, later an extra fork |
| Ingot material / working | How fully can that capability be expressed? | A simple support develops a propagation or mastery addition |
| Specific Kind | How does that capability behave differently? | Preserve a detonation on the ground, convert burning into slowing smoulder |
| Route and other pieces | How are those behaviours combined? | A preserved smoulder becomes a place to lead pursuers through |
| Gear | Which parts of the resulting build are worth investing in? | Burn duration, chill buildup and spread can all matter to the same build |

Ordinary ingots should add to the skill. A mutation can replace a delivery,
status application or trigger, and must say what it replaces. An impressive
mechanic need not multiply single-target damage or erase the danger of a pack.

## A worked example: Smoulder

The owner's example is the reference case:

```
Frost Catalyst → Ember support → a skill capable of igniting
                    ↓
              Smoulder support
```

There is currently no Frost Catalyst item. Adding one is part of this proposed
elemental vocabulary, not a claim about the installed catalogue.

Proposed behaviour: the affected skill's ignite application becomes Smoulder.
It burns and slows, changing a fire build into a way of controlling the pursuing
train. Its form is visible on the support, skill preview and affected enemies.

The rule needs an explicit compatibility contract rather than several accidental
bonuses: Smoulder inherits the intended burn scaling, exposes its cold-control
component to appropriate chill/freeze investment, and states how proliferation
copies it. It must not tick both an original ignite and a copied Smoulder for
free, count one application as two triggers, or silently grant a full freeze.

Proposed progression through this build:

1. **Early:** a single Frost → Ember path makes a small burning, slowing pack.
   The player starts placing damage in a choke rather than just racing damage.
2. **Middle:** improved supports add reach/propagation, while another available
   route changes where or how that Smoulder persists. Gear improves its useful
   components, rather than only fire damage.
3. **Late:** a deliberate compound working can turn the build into travelling
   embers, controlled territory or a freeze-triggered reaction. These are
   alternatives to author, not three automatic rewards for reaching an era.

## Specific Kind identities — proposed authoring brief

Family determines broad purpose; the exact Kind selects the mutation. None of
these should silently inherit every mutation belonging to its family.

| Current Kind | Its proposed verb | Distinct play opportunity to develop |
| --- | --- | --- |
| Ember Catalyst | Kindle / combust | Turn a support's contribution into a fire event: an impact flares, a wound carries embers, a recovery event reignites a marked target |
| Preserving Catalyst | Anchor / retain | Let a normally fleeting action remain at a place, on a target or as a stored charge; persistence changes positioning and timing |
| Piercing Catalyst | Pass through / carry onward | Carry a payload through a line or release it beyond the first contact; its identity is passage, not a generic fork bonus |
| Impact Catalyst | Break / discharge | Turn contact, stagger or collision into a release: a shock front, a delayed rupture or a payload deposited at impact |
| Bulwark Vanguard | Brace / answer | Make a supported action establish a defensive stance or position that answers pressure; it should change when the player stands and commits |
| Warding Vanguard | Intercept / shelter | Make the action create a ward against a defined threat; control an approach or intercept a projectile rather than just add armour |
| Marrow | Gather / recover | The working leaves recoverable vitality at meaningful places or moments, creating an excursion-and-return rhythm |
| Sipping Marrow | Siphon / return | The working extracts life through its own delivery: a returning hit, wound or maintained connection; sustain follows how it is played |
| Quicksilver | Carry / reposition | Tie the working to movement, leaving or carrying its effect as the player changes position |
| Striking Quicksilver | Follow through / sequence | Change attack rhythm: a follow-up, alternate stroke or advancing sequence; generic recovery alone is insufficient |
| Casting Quicksilver | Echo / prepare | Change spell timing: a staged release, placed echo or prepared follow-up; any new input requirement must be designed explicitly |

Proposed Frost Catalyst supplies **quench / bind with cold**, including the
Smoulder example. The first implementation should prove strong identities with
existing deliveries before introducing every new spatial primitive above.

These are identity briefs, not 88 finished pair rules. A later catalogue must
not claim exhaustiveness merely because every cell contains a fancy name.

## Proposed flow grammar

A working resolves to a readable skill description plus its gameplay effects.
Keep provenance: which source Kind, which ordered route, which transformed
support, which receiving skill. The C++ simulation resolves these facts once;
the UI and Godot delivery consume the same result.

1. Only skills occupy sockets; supports remain orthogonal, Kinds outside the
   immediate ring. Preserve these accepted physical placement rules initially.
2. Retain strictly inward steps for the first version. All connected inward
   branches are visible. Do not choose an invisible winner by iteration order.
3. A Kind contributes its identity to each valid branch. Each encountered ingot
   transforms that branch's contribution; another Kind can transform its meaning
   through an explicit compound rule. Order matters: preserving fire and firing
   a preserved charge need not be the same result.
4. A route can affect both skills if it genuinely reaches both workings. It
   cannot broadcast mutations to unrelated skills or jump empty cells merely
   because an alloy reads backing across a gap.
5. Branches that reconverge do not count the same source contribution twice.
   Separate compatible effects can coexist. Two incompatible replacements must
   produce an explicit composition or a visible conflict before commitment;
   neither an arbitrary winner nor an enormous pile of all effects is acceptable.
6. A repeated Kind is not automatically another full multiplier. The catalogue
   must specify whether repetition reinforces, transforms, passes through or
   conflicts. Exact stack budgets remain tuning work.
7. Re-resolve effective capabilities after a mutation. If a strike becomes a
   travelling wave, propagation and area modifiers should read the capability
   they actually affect; the printed original skill tags are insufficient.
8. Secondary effects retain their source and bounded propagation budget.
   Child events cannot reset the budget by passing through a different Kind.
   Existing boss and cover rules must remain explicit in each applicable verb.

The proposed deterministic resolution order is: base delivery and support
capabilities → inward mutation paths → compatible composition and derived tags
→ gear/mastery scaling of those resulting capabilities → bounded event hooks.
Replacement rules need a dependency order or named combination; avoid repeatedly
rewriting until a result happens to stop changing.

### Decisions to settle in the concrete grammar

- The exact Smoulder contract: ignite threshold, slow source, freeze eligibility,
  spread inheritance and boss response. The owner's example establishes the
  fantasy but does not fix all these rules or numbers.
- Which current ingot pair/rail effects remain independent additive capabilities
  and which belong in Kind mutations; otherwise the old generic mechanics can
  continue to obscure the new distinction.
- Whether future larger layouts retain strict nearest-socket depth or use
  per-destination routes. The current global-depth rule can reject a route which
  temporarily moves sideways relative to another socket. Inspect actual enlarged
  layouts before extending the routing contract.
- How the UI presents a genuine conflict at a shared support. Proposed default:
  preview and refuse the conflicting change; preserve the last valid arrangement.
- How existing layouts adopt changed meanings. Preserve owned pieces, skills,
  mastery and coordinates; show before/after behaviour and recover any invalid
  placement without loss. Do not silently delete the recent skills.

These materially affect play and compatibility. Per the repository workflow,
they are proposals for review, not rules to invent during implementation.

## Exhaustive coverage means two things

**Local meaning:** enumerate all eight ingots × eleven current Kind identities =
88 pairs, each across iron/bronze/steel and the supported delivery/capability
lanes. The current sixteen-skill catalogue gives 4,224 direct fixture combinations
before legality/filtering; this count is a coverage inventory, not a claim that
every combination should receive a different mechanic. Adding Frost would make
96 pairs and 4,608 such fixtures. The generator must report actual legal cases,
resolved names, effective tags, hooks and explicit non-matches from live tuning.

**Composition:** the pair matrix is insufficient. Cover sequential Kinds,
inward branches, convergence, shared supports/two sockets, disconnected paths,
repeat identities, incompatible replacements, alloy thresholds and save reloads.
For the finite prototype board, enumerate legal route shapes and test symmetry,
placement-order independence and bounded event generation. Larger boards should
exercise the same invariants, not require hand-writing every full layout.

Each authored rule needs: stable ID; exact Kind; input capability/support;
required material traits; output name; additive/replacement operation; effective
tags; trigger and propagation behaviour; compatibility/stacking; boss/cover
response; visual signature; tuning explanation; and a concrete example fixture.

An unsupported interaction must be an explicit explained passthrough or conflict.
A promising combination shown as a transformation must change behaviour, not
only its title. Coverage tooling should flag accidental identical Kind profiles.

## UI: inspect the made thing

The support cell's primary name becomes **Smoulder**, with **Ember · Iron** as
its material identity below. Selecting it highlights the exact inward paths and
shows which receiving skill gets which reading. A shared support can have two
readings; select the working to inspect each rather than choosing one label
arbitrarily.

Before placement, show a concrete change:

> Ember Bolt → Smouldering Bolt
>
> Ignite becomes a slowing burn.
>
> Frost Catalyst → Ember (Iron) → Ember Bolt
>
> Benefits from: burn scaling; the explicitly supported cold-control and spread
> modifiers.
>
> Loses/replaces: ordinary ignite application from this skill.

The same preview lists blocked paths, conflicts and the next material capability.
Effect names/wording come from resolved backend data. A cosmetic rename in Godot
must never be able to disagree with combat. Inventory and saves keep stable IDs;
contextual names are derived views.

## Proposed implementation order

1. Author the specific-Kind matrix and composition contract; audit generic
   forms and current pair/rail effects against it. Use complete worked builds
   for bow, melee and fire/cold to choose the first mutations.
2. Replace the connectivity-only reading with a resolved route carrying identity
   and provenance. Expose the result in the Foundry preview and supporting cells.
3. Implement an early set that visibly changes timing, positioning and status
   use. Smoulder, persistence, passage and impact should already distinguish
   several builds using the same small skill set.
4. Extend additive ingot capabilities through the existing forge/material
   progression, then add authored compound routes on the larger plate.
5. Validate exhaustive local fixtures, composition invariants, actual combat,
   migration and the clarity of before/after previews. Playtest one compact
   encounter with the same base skill in several arrangements.

Success: after moving one Kind, the player can predict a change, see a changed
support and skill, play the next fight differently, and explain why a previously
irrelevant gear modifier is now useful.
