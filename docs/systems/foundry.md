# The Foundry: Workings, Augments and Rails

**Status:** Owner direction recorded 3 Sep 2026; the interactions below are **proposed** and await acceptance (D-023)  
**Owner:** Human project owner  
**Related decisions:** D-004, D-007, D-014, D-016, D-019, D-020, D-022, D-023  
**Reads with:** [progression-eras.md](progression-eras.md) (the plate as built), [skill-grammar.md](skill-grammar.md) (tags, statuses, hooks), [loot-and-currency.md](loot-and-currency.md), [items-and-modifiers.md](items-and-modifiers.md), [combat-and-builds.md](combat-and-builds.md)

## Purpose and player fantasy

The Foundry is the point system (D-019): points are ingots on a forged
plate, and power is arrangement. D-022 put skills on the plate. This
document takes the owner's next step: the plate is **worked**, the way a
smith works a piece on an anvil. A thing sits in the socket, the metal
around it shapes it, and what a piece of metal *means* depends on what it
is touching.

The fantasy the owner named: the plate limits how many skills you can
optimise, and rewards creativity in placement, the joins between ingots.
Everything below serves those two sentences. The ceiling is meant to be
high; the vocabulary is meant to be small.

## What the owner asked for (3 Sep 2026)

Recorded here so the proposal can be checked against it.

- Supports are **orthogonal only**: the four cells beside the thing in the
  middle, not the ring of eight.
- The plate has **designated spots for the active thing being worked on**:
  a skill, or a defensive currency the owner called a **vanguard**.
- **Trade currency stops being generic.** It splits into kinds: catalysts,
  vanguards (defence), and the like for life and speed. Each kind has two
  uses: **in crafting**, to weight a roll toward a family of modifiers;
  **on the plate**, placed as a piece.
- The **spare cells on the diagonals** hold either more ingots or currency
  that **augments the ingots** beside them. The owner's example: a frost
  skill in the middle, a frost ingot beside it and another frost behind
  that ("matching ingots just enhance the effect"), a fire ingot beside
  the skill that on its own cannot read a cold skill, and an augment on
  the fire ingot that turns it into a new kind of support, **Scald**: the
  frost skill ignites, and ignited enemies take extra cold damage.
- A vanguard **in a corner** gives its own benefit and also transforms the
  supports it touches. A vanguard **in the middle** makes every support a
  benefit to the character: an "increased armour" vanguard supported by a
  frost ingot gives cold resistance and weaker chill from enemies.
- **Class** lives at the edge of the plate: row and column effects
  outside the grid that are unique to your class and that you spec into.
  The owner's example: an archer's column where, if every placed cell is
  a certain ingot, the skill shoots two more projectiles.

## The plate as built (what the code does today)

Four rules, all orthogonal, all in `sim/src/foundry.cpp`:

1. A placed ingot gives its base effect anywhere on the plate.
2. Two ingots touching that match one of ten pairs add that pair's
   mechanic, for everyone.
3. Three matching ingots in a row or column add the verb again.
4. An ingot touching a skill tablet supports that skill alone at twice its
   value, when the modifier can apply to the skill's tags.

Half the ingots (Reach, Vigour, Plate, Ward) are sheet stats and never
support a skill. **Conflict on record:** the design doc and the D-022
commit both use "Reach beside Frost Orb widens the orb" as their example
of a support; the code marks Reach as a self stat and it never supports
anything, and the integration test's effect count only passes because it
does not. Not silently fixed either way (AGENTS.md); the proposal below
makes Reach read area and projectile skills natively, for the owner to
confirm.

## The model: a working

**What a cell means is decided by what it touches.** That is the whole
rule; the rest is vocabulary.

```
   corner    support    corner
  support   [SOCKET]   support
   corner    support    corner
```

| Term | Meaning |
| --- | --- |
| **Socket** | A cell the era forges into the plate. Only a subject can sit in it. Drawn as the anvil's hardy hole. |
| **Subject** | The thing being worked: a **skill tablet**, or a typed currency (**Vanguard**, later **Marrow** and **Quicksilver**). It says what the working is *for*. |
| **Support** | An ingot orthogonally beside a socket. Its **reading** is decided by the subject. The same Frost ingot is cold damage beside a skill, cold resistance beside a Vanguard, a chilling Dash beside a Quicksilver. |
| **Corner** | The four cells diagonal to a socket. Each touches two supports and never the socket. It holds an ingot (pairs and backing) or a currency as an **augment**. |
| **Augment** | A currency in a corner. It transforms the two supports it touches. A **Catalyst** works a support into a **reaction**; a Vanguard, Marrow or Quicksilver lends the supports its own reading as well. |
| **Backing** | A matching ingot touching a support from outside the socket lends its value: the support counts once more. The owner's "matching ingots just enhance the effect". |
| **Link** | Two subjects in sockets side by side. Skill beside skill: one casts the other. Skill beside Vanguard: the Vanguard's trigger casts the skill. |
| **Rail** | A slot outside the plate on each row and column. A class pattern set in a rail reads the whole line and bends a rule while the line meets its condition. |
| **Working** | A socket with its supports and corners: the unit the player thinks in. "My orb working", "my anvil". |

A 3x3 plate is one working. A 3x4 plate is two sockets side by side, so
every cell is a support of one working and a corner of the other, and the
subjects link. A 4x4 plate is two sockets on a diagonal sharing two
supports, with room at the edges for backing and rails.

Proposed sockets per era (`foundry.json sockets_by_era`): era one
`[[1,1]]`; era two `[[1,1],[1,2]]`; era three `[[1,1],[2,2]]`. Whether
the class hall forges one more is an open question below.

### Why sockets rather than "a tablet anywhere"

Sockets make the working visible before anything is placed: the plate
shows where the thing goes, and the rim around it shows which four cells
will read it. They let rails be authored against known positions. And
they carry the owner's phrase literally: the plate has a place for the
thing being worked. The cost is that D-022's tablet-anywhere is narrowed;
a tablet in a non-socket cell would be lifted free when a save loads.

## Subjects and what they make of a support

The current support rule stays: a support beside a **skill** applies its
modifier to that skill alone at `support_multiplier` (2.0) times its
value, when the modifier can read the skill's tags. Two changes: **Reach
reads area and projectile skills natively** (wider area; a projectile
flies further), and a support that cannot read its subject is shown as
**inert** with the fix named ("Vigour cannot read Frost Orb. A Catalyst in
a touching corner would make it Reap.").

The new subjects are currencies. Each has a base of its own and a
**trigger** (used by links):

| Subject | Base when socketed | Trigger |
| --- | --- | --- |
| Skill tablet | none; the skill itself | the skill's status crossing its threshold on an enemy (freeze, ignite, bleed) |
| **Vanguard** (defence) | +8 armour (Bulwark Vanguard) or +5 to every resistance (Warding Vanguard) | a single hit for more than 10% of your life |
| **Marrow** (life) | 1 life a second while nothing has hit you for 4 s | falling below half life |
| **Quicksilver** (tempo) | Dash recovers 20% faster | a Dash |

### Readings: eight ingots, four subjects

| Ingot | Beside a skill tablet | Beside a Vanguard | Beside a Marrow | Beside a Quicksilver |
| --- | --- | --- | --- | --- |
| **Ember** | +24% fire damage (fire skills) | +10 fire resistance; ignite on you burns 25% shorter | Warmth: standing by a fire (a campfire, burning ground) regenerates 2 life a second | your Dash leaves burning ground |
| **Frost** | +24% cold damage (cold skills) | +10 cold resistance; chill on you builds 25% slower | chilled enemies deal 15% less to you | dashing through enemies chills them |
| **Edge** | +24% physical damage (physical skills) | Barbs: an enemy that hits you takes 25 bleed buildup | a kill of a bleeding enemy restores 3 life | dashing through enemies bleeds them |
| **Reach** | area skills 16% wider; projectiles fly 16% further | when you are struck, Barbs and every other answer to the hit reach every enemy within 2.5 m, not only the striker | your shelter's regeneration follows you 10 m past the door | Dash goes 1 m further |
| **Vigour** | inert | +24 life; 2 life a second for 3 s after a hit | +24 life; the Marrow's regeneration doubles | a Dash restores 4 life |
| **Plate** | inert | +16 armour; armour counts against fire at half | armour also reduces burn and bleed damage taken | +8 armour for 1.5 s after a Dash |
| **Ward** | inert | +5 to every resistance; statuses on you decay twice as fast | resistances also slow status buildup on you | a Dash cleanses one status |
| **Haste** | +16% cooldown recovery (attacks and spells) | after a hit you move 15% faster for 2 s | life restored to you from any source is 15% more | Dash recovers 16% faster |

Every number is the ingot's flat value, doubled by the support multiplier
where it is a number at all; most readings are mechanics with one number.
Cold resistance is a new derived stat (there is only fire today); Barbs,
Warmth, the Dash readings and the shelter reach are engine hooks reading
sim numbers, in the ADR-0003 division.

The owner's example reads straight off the table: a Bulwark Vanguard
supported by Frost is +10 cold resistance and slower chill on you.

## Corners: the joins

A corner touches two supports and never the socket. It is where
creativity lives, because it is the only cell that can change what a
support *is*.

**An ingot in a corner** does what ingots do now: its base effect; a pair
with either support it touches (Ember in a corner between Reach and Haste
is Wildfire and Lingering Flame at once); **backing** if it matches a
support it touches. Backing is the proposal that replaces lines: with
today's sources only Edge can ever make a line of three, so the rule is
nearly dead, while a duplicate ingot is common. A matching neighbour
lends its value once; refinement (D-019, later) extends how far a backing
is read.

**A Vanguard, Marrow or Quicksilver in a corner** gives half its socketed
base (a corner Vanguard: +4 armour) and **lends the two supports it
touches its reading**: the Frost support beside your orb is still +24%
cold damage, and with a Vanguard in the corner it is also +10 cold
resistance and slower chill on you. This is how an offence working
carries defence without a second socket, and the answer to "one defence
becomes mandatory" ([combat-and-builds.md](combat-and-builds.md)):
defence can ride any working.

**A Catalyst in a corner** has no base of its own. It **works the two
supports it touches** into their strong form. A support that already
reads the subject is *sharpened*; one that cannot read it is given a
*reaction*, a cross-element mechanic. This is the owner's Scald,
generalised.

### Reactions and sharpenings (skill subjects)

| Support | The skill is... | Becomes | What it does |
| --- | --- | --- | --- |
| Ember | cold | **Scald** | the skill's chill also ignites (+15 ignite buildup); an ignited enemy takes 20% more cold damage |
| Frost | fire | **Quench** | the skill's ignite also chills (+15); a burning enemy that freezes takes the rest of its burn at once |
| Ember | physical | **Temper** | the attack ignites on hit (+15); an ignited enemy takes 20% more physical from it |
| Frost | physical | **Rime** | the attack chills on hit (+15); its shatter novas chill (+30) |
| Edge | cold | **Brittle** | the skill's hits on chilled enemies bleed (+20); a frozen enemy that is bleeding shatters from this spell's own hit |
| Edge | fire | **Sear** | burning enemies hit by the skill bleed (+20); a bleeding burn ticks 50% faster while the enemy moves |
| Reach | single-target | **Arc** | the strike gains a 1.5 m arc: it becomes an area skill and reads area modifiers from then on |
| Reach | projectile | **Split** | +1 fork |
| Reach | area | **Linger** | the area persists on the ground for 1.5 s |
| Frost | cold | **Deep Frost** | chill builds 30% faster for this skill |
| Ember | fire | **Kindling** | ignite builds 30% faster for this skill |
| Edge | physical | **Serration** | bleed builds 30% faster for this skill |
| Haste | any | **Echo** | every fourth cast repeats itself |
| Vigour | any | **Reap** | a kill with the skill restores 3 life |
| Plate | any | **Bracing** | casting the skill grants 8 armour for 2 s |
| Ward | any | **Aegis** | an enemy carrying this skill's status deals 15% less damage to you |

Seven of these reuse resolver keys that exist (`add_ignite_buildup`,
`add_chill_buildup`, `add_fork`, the pair modifiers, the boons'
`repeat_every_nth_hit`); Scald, Quench, Brittle, Sear, Arc, Linger, Reap,
Bracing and Aegis need one hook each, tag-gated like shatter and
proliferate. A Catalyst beside a Vanguard, Marrow or Quicksilver support
sharpens that reading instead (Barbs also stagger; dashing through
freezes outright); that table waits for the third slice.

The catalyst's own element (Ember Catalyst, Preserving Catalyst) matters
in crafting, where it names the domain. On the plate every catalyst reads
as the offence kind and the support and subject decide the reaction; this
keeps the table two-dimensional. An open question below asks whether that
is right.

## Links: subjects side by side

Era two's plate puts two sockets beside each other, so a subject is the
other subject's support. Proposed readings:

- **Skill beside skill: the second casts on the first's trigger.** Frost
  Orb beside Shatter: whenever the orb freezes an enemy, Shatter casts
  itself at that enemy, with its own supports, at its own cooldown. **The
  linked skill leaves the action bar.** This is the answer to the owner's
  action-bar worry (D-022): a plate with two linked skills runs three or
  four skills off a bar that shows the ones you press.
- **Skill beside Vanguard: the Vanguard's trigger casts the skill.** A
  heavy hit casts Frost Nova around you. Marrow's trigger (half life) and
  Quicksilver's (a Dash) do the same beside a skill.
- Vanguard beside Marrow, and the like: the two share their bases (the
  Marrow's regeneration also runs for 3 s after the Vanguard triggers).
  Small on purpose; the sockets are for skills first.

Links are the one part of this proposal that needs an engine hook beyond
the resolver (cast-on-event), the same family of hook the deferred
uniques want ([items-and-modifiers.md](items-and-modifiers.md)).

## Rails: class at the edge of the plate

Each row and each column has one **rail** outside the grid. A **rail
pattern** names a condition on the line and a rule it bends while the
condition holds. The starting class (D-004) grants a list of patterns;
the class hall is where you set them into rails, one rail in era two, two
in era three (`rails_by_era`). Rails are the plate's home for the
rule-bending the uniques were deferred for, and for the wrought forms of
D-019.

Conditions are on **placed** cells, so an empty cell never breaks a rail,
with a minimum count so one ingot never lights one: `all_placed_are:
reach, minimum_placed: 2`, `holds_subject_with_tag: projectile`,
`ends_are: [edge, edge]`.

Class seeds (three classes, two patterns each; a seed, not the roster):

| Class | Pattern | Line condition | Rule bent |
| --- | --- | --- | --- |
| **Ranger** | Volley | column; every placed ingot is Reach (at least 2); a projectile skill's socket in the column | that skill fires 2 more projectiles |
| Ranger | Quarry | row; every placed ingot is Edge (at least 2) | your projectiles pierce one more enemy and bleed those they pass through |
| **Warden** | Shield Wall | row; every placed ingot is Plate or Vigour (at least 2); a Vanguard's socket in the row | armour counts against fire and cold in full |
| Warden | Riposte | column; Edge at both ends | Barbs bleed for twice the buildup and stagger |
| **Kindler** | Pyre | row; every placed ingot is Ember (at least 2) | your ignites proliferate on hit at half buildup, not only on death |
| Kindler | Ashen Step | column; Ember at one end, Haste at the other | burning ground you made heals you 2 life a second and never harms you |

**Manners** (D-020, D-022: the accepted source of later supports) are
rails the world teaches rather than the class: each mob family, after
enough of them have fallen, offers one pattern. The Hound's Manner (row;
Haste and Edge alternating, at least 2): enemies moving toward you take
25% more from your attacks. The Husk's Manner (column; every placed ingot
is Plate, at least 2): standing still for a second grants 16 armour until
you move. Manners go in the same rails and compete with class patterns
for them.

A rail wants a whole line, and a working wants its four supports: a
Volley column full of Reach cannot also be the Ember supports of a fire
working. That collision is the late-game layout puzzle the D-019 curve
asked for ("the whole plate rearranged around a keystone").

## Typed currency

The four kinds are the modifier tag families that `items.json` already
carries: every modifier is tagged offence, defence, life or speed. A
currency kind is a family with a name and a job.

| Kind | Family | In crafting | On the plate |
| --- | --- | --- | --- |
| **Catalyst** | offence (fire, cold, physical) | as now: guarantees the domain, bounds the roll (ADR-0002 C) | corner: works a support into its reaction |
| **Vanguard** | defence (armour, resistance) | the craft draws its first modifier from the defence family | socket: a defence working; corner: lends defence readings |
| **Marrow** | life | the craft draws from the life family | socket: a sustain working; corner: lends life readings |
| **Quicksilver** | speed | the craft draws from the speed family | socket: a tempo working; corner: lends tempo readings |

In crafting the verb is one rule for all four: **adding a kind to a craft
makes the roll draw its first modifier from that family** at the era's
tier (`craft_rolls.currency_weighting`), the catalyst keeping its
stronger guarantee. The base is still certain, the roll is still the
excitement, and now it can be aimed.

**Sources** follow the families' natures, so farming is a choice of where
to hunt: whelps, archers and wisps pay Catalysts; husks and knights pay
Vanguards; the living (elk, the fen's lurkers) pay Marrow; hounds and
crawlers pay Quicksilver. Elites pay an extra one of their family's kind;
trial floors pay a spread; orders pay in the kind of their work (the mine
reinforced pays Vanguards). Every kind stacks in the pack like a material.

**Coin.** The proposal retires the generic coin: the peddler prices in
kinds and changes one kind for another at a rate (`market.exchange`), so
a surplus of one kind is never dead and no kind is ever just a number.
This widens what the 31 Aug direction deferred (currency breadth), because
the owner has now asked for it; the first slice keeps to four kinds, and
four is the cap for the prototype.

## Worked plates

Names are for the doc; the panel says what the working does in a
sentence. Sockets in brackets, currency in braces.

### The Scalding Orb (era one, 3x3)

```
{Catalyst}     Frost      {Vanguard}
  Ember     [Frost Orb]     Plate
    .          Haste          .
```

- Frost, north: +24% cold damage to the orb. The Catalyst touching it:
  **Deep Frost**, chill builds 30% faster. The Vanguard touching it: +10
  cold resistance, chill on you builds slower.
- Ember, west: inert on its own. The Catalyst touching it: **Scald**. The
  orb ignites what it chills, and ignited enemies take 20% more cold.
- Plate, east: inert on its own. The Vanguard touching it: +16 armour.
- Haste, south: the orb recovers 16% faster.
- Bases: +12% cold and +12% fire for everything, +8 armour, +8% recovery;
  the corner Vanguard's +4 armour.

Five ingots, two currencies, one tablet, and the orb is a control spell
with a burn on it while the same plate carries cold resistance and 28
armour. Two layouts of the same pieces play differently: move the
Catalyst to the south-east and Ember stays inert while Haste becomes Echo
and Plate becomes Bracing.

### The Anvil (era one, 3x3)

```
    .          Plate         Plate
  Edge    [Bulwark Vanguard] Vigour
{Marrow}       Frost           .
```

- Plate, north: +16 armour, and the second Plate in the north-east corner
  **backs** it: +16 again. That corner Plate also touches Vigour: the
  **Bulwark** pair, +8.
- Vigour, east: +24 life and 2 life a second for 3 s after a hit.
- Edge, west: **Barbs**, attackers bleed.
- Frost, south: +10 cold resistance, chill on you slower.
- The Marrow in the south-west touches Edge and Frost: kills of bleeding
  enemies restore 3 life; chilled enemies deal 15% less to you.
- Bases: +8 and +8 armour, +12 life, +12% cold and physical for the
  skills you do have.

Sixty-four armour from the plate against a base of nothing: 39% physical
reduction at `armour_reduction_scale` 100, plus 136 life. This is the
era-one defensive spike D-020 asked for ("early item mods are more
defensive"), made of mechanics rather than a bigger sheet, and the
balance sim should confirm the boss rates stay in their band with it.

### Cast on Freeze (era two, 3x4, linked sockets)

```
{Catalyst}     Frost        Frost      {Vanguard}
  Reach     [Frost Orb]   [Shatter]      Plate
    .          Haste        Reach       {Marrow}
```

- The two Frosts back each other: the orb's cold support counts twice, and
  so does Shatter's.
- The Catalyst touches the orb's Frost (**Deep Frost**) and its Reach
  (**Split**: the orb forks twice).
- **The link:** every freeze the orb lands casts Shatter at the frozen
  enemy. Shatter leaves the bar; its Reach support makes the ring 16%
  wider.
- The Vanguard touches Shatter's Frost (cold resistance) and Plate (+16
  armour). The Marrow touches Reach (shelter regeneration follows you out
  the door) and Plate (armour reduces burns and bleeds).

Six ingots of the fourteen that exist by era two. The plate is not full;
the working is. This is the owner's Wave 2 sentence (orb, fork, freeze,
shatter, cascade) running off two bar slots.

### Volley (era three, 4x4, a Ranger rail)

```
              Volley
{Catalyst}     Reach         Ember          .
  Ember     [Ember Bolt]     Haste        Frost
    .          Reach    [Bulwark Vanguard] Edge
    .            .           Plate          .
```

- The second column is the **Volley** rail: both placed ingots are Reach
  and the bolt's socket sits in it. Ember Bolt fires three projectiles.
- The Catalyst touches Reach (**Split**, each bolt forks) and Ember
  (**Kindling**, ignite builds fast). The second Reach support: the bolts
  fly far.
- The Ember in the corner between Reach and Haste is **Wildfire** and
  **Lingering Flame**: burns spread further and last longer.
- The Vanguard shares two supports with the bolt: Haste (faster after a
  hit) and Reach (your answers to a hit reach 2.5 m). Its own: Plate (+16
  armour) and Edge (**Barbs**). The Frost in its corner pairs with Haste
  (**Frostbite**, your attacks chill) and Edge (**Wide Shatter**).

A fan of burning, forking bolts and a plate that bites back. The rail
forced the Reaches into one column; the fire working bent around it.

### Redline (era one, 3x3, a Quicksilver working)

```
    .          Haste           .
  Frost    [Quicksilver]     Ember
{Catalyst}     Edge            .
```

Dash recovers 36% faster; dashing through the train chills and bleeds it
and leaves burning ground behind you. The Catalyst sharpens Frost
(dashing through freezes outright) and Edge (the bleed opens at full).
The train shape this wants is the conga line
([skill-grammar.md](skill-grammar.md)): run straight, turn, cut back
through.

## The ceiling, counted

From eight ingots, four currency kinds, two link readings and a handful of
rails:

| Source | Interactions |
| --- | --- |
| Readings (8 ingots x 4 subjects) | 32 |
| Catalyst forms beside a skill | 16 |
| Corner lendings (3 kinds x 8 ingots) | 24 |
| Pairs (as now) | 10 |
| Backing | every duplicate |
| Links | 3 |
| Rails (class seeds and manners) | 8 |

About ninety distinct things a plate can do, none of them a bigger
number, and the vocabulary grows multiplicatively: a new ingot (era
three's ember-iron and silver are waiting to be ingots) adds four
readings and a column of reactions; a new subject kind adds eight
readings; a new skill tag adds reactions; a new family adds a manner.
That is the D-019 budget in practice: the count of interactions
multiplies, the numbers stay within threefold.

## Numbers and the budget

- Ingot values unchanged. Supports at x2 as now. A corner lending reads at
  x1 (the ingot's value, not doubled). Backing adds the support once more.
- Reactions carry one number each, in the same 15 to 30% band the pairs
  use; rails carry integers.
- The Anvil's 64 armour is the ceiling case for era one and needs the
  oracle: the round-based sim with the Anvil and with the Scalding Orb,
  against the Tyrant and an era-one pack, to confirm neither leaves the
  D-020 band.
- The bar count is the other budget: a linked skill leaves the bar, so
  the plate can run more skills than the bar shows. Cap linked skills at
  the socket count.

## Feedback and interface

- Sockets are drawn on the bare plate. Setting a subject rims its four
  supports and dots its corners; hovering any cell names its role for
  each working it belongs to.
- An inert support is greyed and says what would read it: "Vigour cannot
  read Frost Orb. A Catalyst in a touching corner makes it Reap."
- **Hover preview** for anything in the tray over any cell shows the
  effects list *as it would be* before the click, because lifting costs
  metal.
- The effects list groups by working, the subject as the header, one
  sentence first: "Frost Orb: chills fast, scalds, forks twice. You
  resist cold." The lines under it are the readings, reactions and
  lendings.
- A corner draws its two arcs to the supports it works.
- Rails are headers on rows and columns: the condition in words, lit when
  it holds, and which placed cell breaks it when it does not.
- Every reaction has a silhouette tell on the mob (a scalded mob is a
  frost shell with a flame rim), in the greybox vocabulary of the grammar.

## Tunable parameters

| Parameter | Meaning | Player effect | Initial value |
| --- | --- | --- | --- |
| `sockets_by_era` | where the era forges sockets | how many workings and how they overlap | `[[1,1]]`, `[[1,1],[1,2]]`, `[[1,1],[2,2]]` |
| `support_multiplier` | a support's value against the ingot's base | how much a working is worth over the bare plate | 2.0 (as now) |
| `corner_lending_multiplier` | a corner currency's lending against the base | how much defence an offence working can carry | 1.0 |
| `corner_base_fraction` | a corner currency's own base against its socketed base | whether a corner is worth a currency with no support to work | 0.5 |
| `backing_reach` | how many cells out a matching ingot is read | the value of duplicates; refinement raises it | 1 |
| `reactions[]` | each reaction's number | the strength of a cross-element build | 15 to 30% band |
| `subjects[].trigger` | what fires a link | how often linked skills cast | as tabled |
| `rails_by_era` | rails the player may set | how much class shows on the plate | 0, 1, 2 |
| `rail_patterns[].minimum_placed` | ingots a rail needs before it lights | rails as a commitment, not a freebie | 2 |
| `craft_rolls.currency_weighting` | how strongly a kind aims a craft | crafting as targeting | first modifier from the family |
| `market.exchange` | rate between kinds at the peddler | surplus never dead; farming still a choice | 3:1 |
| family drop kinds and rates | which kind a family pays | where to hunt for what | one per family, elites +1 |

## Failure cases and exploits

- **A vanguard working becomes mandatory.** Countered by corner lending:
  any working can carry the defence it needs. Watch the oracle.
- **Inert supports read as dead cells.** The owner's worry. Countered by
  naming the fix on the cell and by every ingot having a reading beside
  every non-skill subject.
- **Reactions unreadable in first person.** Every reaction needs its tell
  before it ships; a reaction without a silhouette is a stat.
- **Rails become a fill-in puzzle with one answer.** Conditions are on
  placed cells with a minimum, never on every cell; patterns are few and
  compete for rails.
- **Catalysts become a tax.** A Catalyst is never required for a working
  to function; it deepens one. Corner ingots (pairs, backing) must stay
  competitive with corner currency.
- **Currency overload.** Four kinds, hard cap in the prototype; the
  peddler changes kinds so none is a dead stack.
- **The bar empties.** Linked skills leave the bar by design; if a plate
  runs everything off one pressed skill, the cap on links per socket
  count holds it.
- **A duplicate ingot is worth more than a new one.** Backing at x1 and
  reach 1 keeps a duplicate below a new reading.
- **The panel becomes a spreadsheet.** One sentence per working first; the
  list under it collapsed by default.

## Acceptance criteria

- [ ] A tester can say what each of their workings does in a sentence,
      without a number.
- [ ] The same pieces in two layouts play differently in the next fight
      (D-019's criterion, now testable with a Catalyst corner).
- [ ] A tester finds an inert support, reads the fix on the cell, and
      applies it within the session.
- [ ] The Anvil makes the Tyrant survivable without tempered armour, and
      the oracle's rates stay inside the D-020 band with it.
- [ ] A linked skill casts itself and the tester notices the bar has a
      free slot.
- [ ] A rail makes a tester rearrange a working they liked.
- [ ] Sim tests: readings per subject, corner lending and reactions,
      backing, links, rails' conditions, currency weighting in a craft,
      save round-trip with subjects in sockets.

## Open questions (owner decisions)

1. **Sockets fixed per era, or a subject anywhere with a cap?**
   Recommended: fixed sockets, positions in data.
2. **Retire coin?** Recommended: yes, the peddler changes kinds; or keep
   coin for the peddler only.
3. **Reach reads area and projectile skills natively?** The doc/code
   conflict. Recommended: yes.
4. **Links: does the linked skill leave the bar?** Recommended: yes; it
   answers the bar worry.
5. **Class at the start (D-004) with rails set at the hall, or class
   chosen at the hall?** Recommended: as D-004; the hall is where rails
   are set and where one more socket may be forged.
6. **Fold lines into backing?** Recommended: yes; lines are unreachable
   with the sources that exist.
7. **Augments as corner cells, or infused into an ingot (no cell)?**
   Recommended: cells; the owner asked for cells, and geometry is the
   game.
8. **Does a catalyst's element pick the reaction?** Recommended: no; the
   support and subject do. Revisit if the reaction table needs a third
   axis.
9. **Do Marrow and Quicksilver come in the first pass, or after the
   Vanguard proves the model?** Recommended: after.

## Slice order

Each slice is data plus the smallest sim rule, tested headless, the panel
following.

1. **Sockets and the working.** `sockets_by_era`; subjects only in sockets
   (a tablet outside one lifts free on load); supports rimmed and inert
   supports named; Reach reads area and projectile skills; backing
   replaces lines. Save: subject cells validated.
2. **Typed currency.** Four kinds as materials; family drop kinds; coin
   drops become kinds; the peddler prices and changes kinds;
   `currency_weighting` in a craft.
3. **The Vanguard.** As a subject with its eight readings (cold resistance
   as a derived stat; Barbs and the answer's reach as engine hooks); as a
   corner, lending.
4. **Catalyst corners.** Sharpenings first (they reuse keys), then Scald,
   Quench, Temper, Rime; the rest as their hooks land.
5. **Links.** Cast-on-trigger; the linked skill leaves the bar.
6. **Rails.** `rail_patterns`, the class hall as the place they are set,
   two classes' seeds and one manner.
7. **Marrow and Quicksilver**, their readings and corners.
