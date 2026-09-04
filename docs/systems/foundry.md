# The Foundry: Workings, Augments and Rails

**Status:** Owner direction recorded 3 Sep 2026; owner answers 4 Sep 2026 (all thirteen questions); **slices 1 (the frame), 2 (every ingot reads every skill), 3 (typed currency), 4 and 5 (the flow: kinds in the detached cells, the first forms) 6 (kinds as variants; the reactions' hooks), 7 (links re-homed; Arc), 8 (the Marrow's and the Quicksilver's forms) 9 (rails: the class's surround from the start, specialised further at the trial) and 10 (the metal of an ingot) implemented 4 Sep 2026**; the rest of the interactions below are **proposed** (D-023)  
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

### Answers (4 Sep 2026)

1. **Sockets fixed** "for now until we see how it feels". Era one is a
   **two-row, four-column** plate with two sockets; the owner drew them
   in the top row's second cell and the bottom row's fourth cell, "don't
   take it as gospel, push back if you think better". The push-back is
   under [The frame](#the-frame-recommended-4-sep-2026).
2. **Coin retired** for now; "a coin/generated town for trading should be
   something in the future".
3. **Reach reads area and projectile skills natively.** Yes.
4. Links and the bar: the owner asked what it means; explained under
   [Links](#links-a-catalyst-between-two-subjects), answer pending.
5. **Class at the start** (D-004), rails set at the class hall. Yes,
   with the rails moved forward: the owner, later the same day, "before you actually begin the game you choose a class, and in era 1 you can still access the plate/foundry, so that base plate's surrounding modifiers are determined by that first selection. Then once you complete trials you specialise further, getting a view of what the surround modifiers can become."
   So the class is chosen before play and its two patterns are the
   plate's surround from era one; the trial's completion offers a
   specialisation that says what each becomes. Built as slice 9 (a first
   reading that put the class at the trial was corrected the same day).
6. Lines folded into backing: the owner asked what it means; explained
   under [Corners](#corners-the-joins), answer pending.
7. **Augments are corner cells**, not infusions. Yes.
8. **A catalyst's element does not pick the reaction.** Yes.
9. **Marrow and Quicksilver after the Vanguard** proves the model. Yes.

Two more things the owner said: progression can be gated on the plate's
size ("only 2 rows era 1") and on **ingot quality, type and rarity**; and
ingots have properties of their own that crafting can use. Both are taken
up under [Progression gates on the plate](#progression-gates-on-the-plate).

10. **The recommended socket layout** (a row and one column apart, both
    workings growing whole on the frame). Yes, 4 Sep.
11. **Every ingot reads every skill.** The owner: "I don't think we need
    to restrict 'cold damage incr' to only cold spells ... adding a cold
    damage on the spell means you might pursue different builds and head
    towards a 'boil' or 'scald' type build"; the same-element support "is
    augmenting one lane which may be better early without other
    interactions available to the player." Taken up under
    [Subjects](#subjects-and-what-they-make-of-a-support): an element
    ingot beside a skill of another element adds that element's damage
    natively, and the Catalyst turns the added element into its status
    and its interaction.

## The plate as built (what the code does today)

Since slices 1 and 2 (4 Sep 2026), in `sim/src/foundry.cpp` and
`sim/src/grammar.cpp`:

1. The plate is a 4x4 frame; era one has rows 1 and 2 forged, era two adds
   row 0, era three row 3. Sockets at (1,1) and (2,2) take a tablet and
   nothing else; an ingot goes on any other forged cell.
2. A placed ingot gives its base effect anywhere on the plate.
3. Two ingots touching that match one of ten pairs add that pair's
   mechanic, for everyone.
4. An ingot beside a socket reads the socket's skill alone at twice its
   value, and the skill decides the reading. Ember, Frost and Edge scale a
   skill of their own element; beside any other skill they **add** their
   element to the hit as a second typed packet at the same fraction
   (slice 2). Haste reads attacks and spells; Reach reads area, projectile
   and single-target skills through the `reach` multiplier the engine
   applies to the delivery.
5. A matching ingot touching a support from any side but the socket's
   backs it: the support counts once more. The line rule is gone.
6. The player's hit is a list of typed packets (`grammar::skillHit`), each
   scaled by its own type's modifiers, each met by a mob's `damage_taken`
   on its own (the Hollow Knight and the Cinder Wisp take a quarter of
   fire; nothing is immune). A reading keeps its modifier's type and
   requires its skill's tag.
7. Vigour, Plate and Ward read a skill weakly: a kill with it restores 1
   life; casting it grants 4 armour for `cast_armour_seconds`; an enemy
   carrying its status deals 5% less to you.
8. Typed currency (slice 3, `sim/src/economy.cpp`): the coin is retired;
   five ids in four families (the catalysts, the Vanguard, the Marrow, the
   Quicksilver) are paid by the families whose nature they follow, one
   more by every elite; the peddler changes three of one for one of
   another; a kind added to a gear craft aims its first modifier at the
   kind's family; rare metal casts the three purse kinds.
9. The flow (slices 4 and 5, `sim/src/foundry.cpp`): only a skill sits
   in a socket; a kind from the purse rests where it cannot touch one,
   gives its family's base forward while a chain of pieces leads inward
   to a laid tablet, and works every support it touches into a form
   (`forms`) that feeds the skill: the Catalyst's sharpenings and
   reactions, the Vanguard's defensive twists. A form's reaction can
   make the skill apply the added element's status and deal more to an
   enemy carrying it (`damage_vs_<status>`; the engine tells the sim
   what the struck mob carries). Cold resistance is a derived stat;
   Barbs, Answer Reach and Haste after a hit are engine hooks. It lifts
   for the re-forge cost and returns to the purse.

10. Kinds as variants and the reactions' hooks (slice 6): every currency
   id has its own base on the plate; Echo (every fourth cast repeats),
   Quench (a burning enemy the skill freezes takes the rest of its burn at
   once), Rime (the skill's shatter novas chill), Sear (the burn it lights
   ticks faster while the enemy moves and bleeds) and Brittle (a frozen,
   bleeding enemy shatters from the spell's own hit) are engine hooks
   reading sim numbers; Serration, Brittle and Sear bleed through
   `laceration`.

11. Links (slice 7, `foundry::links`, `grammar::linkedCasts`): a
   Catalyst in the corner beyond a support shared by two sockets links
   the two skills; when one's payload crosses a status threshold on an
   enemy the other casts itself at that enemy, off the bar, with its own
   cooldown. Arc: Reach worked by a Catalyst beside a strike sweeps every
   enemy within reach and 1.5 m either side.

12. The Marrow's and the Quicksilver's forms (slice 8): sustain twists
   (Cauterise, Cold Blood, Bloodletting, Far Leech, Hale, Scar Tissue,
   Warded Blood, Lifeline) and tempo twists (Hot Hands, Cold Snap, Quick
   Cut, Long Step, Second Breath, Braced Step, Sure Step, Fleet), with
   their hooks: life on hit, a cooldown refund and a burst of speed on a
   kill, every heal amplified, and the Dash's reach, life, armour and
   recovery on the sheet.

13. Rails (slice 9): the plate's surround. A class - Ranger, Warden or
   Kindler - is chosen before play begins, and its two patterns may go
   in the rails outside the rows and columns from era one (one rail in
   era one, two in era two, three in era three). A pattern set in a rail
   reads its whole line's placed cells and bends its rule while the line
   holds; the panel says which cell breaks it. The Tyrant's forge is the
   first trial: its completion offers a specialisation from the class's
   two, each shown as a view of what every pattern becomes, and a rail
   already holding a pattern becomes with it. The two manners (the
   Hound's, the Husk's) are taught by kills and join the rails. *Later the
   same day:* the class also sets the starting kit
   (`rails.classes[].starting_skills`): the Ranger's Bow Shot, Rend and
   Area Strike; the Warden's Heavy Strike, Area Strike and Frost Nova; the
   Kindler's Ember Bolt, Cinder Sweep and Frost Orb; everyone's Dash. The
   base four stay the kit of a character with no class and become pages
   for the classes without them.

14. The metal of an ingot (slice 10): every ingot is cast in iron;
   at a built forge an ingot in hand is re-cast in the era's alloy
   (bronze from era two for a bronze ingot, steel from era three for a
   steel one), which never changes its number and widens how far its
   backing and pairs are read - one, two, three cells along its row or
   column, gaps ignored, never through a socket. The first elite hound,
   husk and knight and the deeper forge pay an ingot already cast in the
   era's alloy. Eight compound forms need the support cast in bronze or
   steel: Bronze Kindling, Bronze Deep Frost, Bronze Serration, Steel
   Split, Bronze Stand Fast, Bronze Second Wind, Bronze Cauterise, Steel
   Fleet.

Still to come from the tables below: Linger, the Vanguard of dodge and
the rest of the variants, compound forms of a kind worked by another
kind, the class hall proper (D-004, kept in documentation for now: the
owner, 4 Sep 2026). The Reach
conflict recorded on 3 Sep is settled: the owner said yes, and the code
now reads skills with it.

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

### The frame (recommended, 4 Sep 2026)

The plate is a **4x4 frame whose rows the eras unlock**: era one has rows
1 and 2 (the owner's two-row, four-column plate), era two forges row 0
above it, era three forges row 3 below (`rows_by_era`). The two sockets
are forged at (1,1) and (2,2) and never move, so nothing on the plate
shifts when the plate grows and a save needs no migration. Era one:

```
   .     [A]      .       .        row 1
   .      .      [B]      .        row 2
```

Each era-one working has **three supports and one corner**, and two of
the supports (the cell between the sockets on each row) serve both
workings. Neither working is whole: that is the size gate the owner asked
for. Era two makes A whole (four supports, three corners); era three
makes B whole. The far cells (0,3) and (3,0) belong to no working: they
are for backing, rails, or a socket the class hall forges.

**The owner's layout and the push-back.** The owner drew the sockets one
cell further apart:

```
   .     [A]      .       .
   .      .       .      [B]
```

That gives A three supports and two corners, and B two supports and one
corner; the two share one support-and-corner pair. B sits on the east
edge, so it never becomes a whole working on the 4x4 already accepted in
D-019 (three supports and two corners at best, without a fifth column).
The recommended layout keeps everything the owner asked for (two rows,
four columns, two fixed sockets) and moves B one cell west, so that B
grows whole on the 4x4, and the two workings **share two supports from
day one**, the join the owner values ("an ingot between two subjects
serves both"). The decision is the owner's; either is one line of data.

**Space pressure arrives on day one.** Era one forges twelve ingots and
the plate has six free cells, so from the seventh ingot the tray is a
reserve and one iron re-forges between layouts. If a milestone ingot with
nowhere to go feels bad in play, move the first-kills of families that
live beyond the heartland to era two rather than widen the plate.

### The flow (owner, 4 Sep 2026, later that day)

The owner, after seeing the socketed Vanguard and its corner lending:
"we just don't allow the non-skills to be placed in the main subject of
the foundry tablet. So vanguards and catalysts can only go into the edge
cases where they give forward their base to the flow of the tablet, but
also transform/mutate along the way the ingots/other catalysts or
vanguards/marrows etc until it hits the skill. We can leave scaling
defenses to itemisation." And the firm line: **ingots are base;
catalysts add offensive creativity; vanguards add creative defensives.**

The rule as built:

- **Only a skill sits in a socket.** The Vanguard, Marrow and Quicksilver
  columns of the subject table below are withdrawn; those kinds are
  augments, never subjects.
- **A kind rests where it cannot touch a socket.** A cell's *depth* is
  its distance to the nearest socket: supports at 1, corners at 2, the
  far cells at 3. A kind goes at depth 2 or more; a socket or a support
  cell refuses it.
- **Everything flows one way, inward.** A kind gives its family's base
  forward only while a chain of placed pieces, each a step nearer a
  socket, leads to a support beside a laid tablet. A kind that flows to
  nothing gives nothing. A far kind flows through a corner kind.
- **A kind works every support it touches into a form.** The ingot keeps
  its plain reading and gains the form's, which feeds the skill that
  support serves; a shared support feeds both skills. The form is the
  family's, the ingot's and the lane's (`forms`): the Catalyst's
  same-element lane sharpens (Deep Frost, Kindling, Serration, Split),
  its added-element lane reacts (Scald, Temper, Quench, Rime, Brittle,
  Sear); the Vanguard's forms are defensive and sustaining twists (Frost
  Leech, Quickstep, Barbs, Stand Fast). Every Vanguard row is a proposal
  drafted from the owner's two examples, one line to strike.
- **Defence scales on gear**, not the plate; a kind's base is small and
  flat (the Vanguard +4 armour; the Catalyst none).
- **Compound forms** (a kind worked by another kind, an ingot's metal or
  rarity as a condition, the owner's "haste beside a fire catalyst and a
  rare frost") are the next step; the table has no rows for them yet.

Consequences: the socketed Vanguard of slice 4 is gone (its readings
live on as Vanguard forms); links, which put a Catalyst in a shared
support cell, need a new home, since a kind cannot rest beside a socket.

**Kinds are lists of variants (owner, 4 Sep 2026, later still).** "The
'Vanguard' is a list of various defensives - i.e. + armor, + dodge, +
resistances, etc. Marrow can +life, +leach, +recoup, etc. Quicksilver, +
move speed, + attack speed, + cast speed. I think that moves the
catalysts into more 'mechanical' changes, fire catalyst may be a
'augment fire' which has various cool effects like the scald. I think
yeah they dont have a base, but they do cooler transformations." As
built: `kinds` in foundry.json is per variant (a currency id, its family,
the name a cell shows, its own base); the forms are the family's, with an
optional `kind` to narrow one to a variant, which is where "augment fire"
will live. Variants in: the Bulwark Vanguard (+4 armour) and the Warding
Vanguard (+5 to every resistance, from the peddler's exchange for now);
the Marrow of life (+6); the Quicksilver of hands (+4% cooldown
recovery). Waiting for their stats: the Vanguard of dodge, the Marrows of
leech and recoup, the Quicksilvers of move, attack and cast speed.

### Why sockets rather than "a tablet anywhere"

Sockets make the working visible before anything is placed: the plate
shows where the thing goes, and the rim around it shows which cells will
read it. They let rails be authored against known positions. And they
carry the owner's phrase literally: the plate has a place for the thing
being worked. The cost is that D-022's tablet-anywhere is narrowed; a
tablet in a non-socket cell is lifted free when a save loads.

## Progression gates on the plate

Four axes, every one of them data, none of them a bigger number:

1. **Rows.** Two in era one, three in era two, four in era three
   (`rows_by_era`). A working becomes whole only when the world does.
2. **Sockets.** Two forged from the start; whether the class hall forges a
   third at a far cell is open question 10.
3. **The metal of an ingot (quality and rarity).** Every ingot is cast in
   a metal, iron by default (`Placement.metal`). At the forge an ingot is
   **re-cast in the era's alloy**: bronze in era two, steel in era three.
   This is D-019's refinement. The metal never changes the ingot's number;
   it widens **reach**: how far the ingot's backing and pairs are read
   (iron one cell, bronze two, steel three; `ingot_metals[].reach`).
   Supports stay orthogonal and adjacent whatever the metal, the owner's
   rule. Rarity is the same axis from the other end: an elite or a trial
   floor may pay an ingot already cast in alloy. A candidate for later,
   not proposed here: the metal's trait doing one more thing (ores are
   properties), a malleable bronze ingot keeping its reaction after the
   catalyst is lifted.
   *As built (slice 10, 4 Sep 2026):* `ingot_metals` iron 1, bronze 2,
   steel 3, each with the era that allows it and its re-cast cost (one
   ingot of the alloy, at `recast_station`); re-casting takes the
   narrowest casting in hand; placing takes the widest; a reading is
   never taken through a socket; sources may say `metal: "alloy"`.
4. **Currency kinds.** Which kinds drop, from which families, from which
   era.

**Ingots and crafting.** Ingots do not go into crafts: they are forged
once by milestones and never lost (D-019). Crafts go into ingots: the
forge re-casts them. The consumable that carries a property into a craft
is the currency kind (a Vanguard aims a chest at defence; an Ember
Catalyst guarantees fire resistance, as now). So the owner's "ingots have
properties crafting can use" is true in this direction: the alloy you can
smelt is the quality your ingots can reach.

## Subjects and what they make of a support

**What "the subject decides how an ingot reads" means.** An ingot has one
verb and one number, and it gives its base to you wherever it sits: a
Frost ingot is +12% cold damage for every cold skill you have, anywhere on
the plate. Beside a socket it says a second thing, and the thing in the
socket picks which. Beside Frost Orb's tablet it is +24% cold damage for
the orb alone. Beside a Bulwark Vanguard it is +10 cold resistance and
slower chill on you. Beside a Quicksilver it makes your Dash chill what it
passes through. The player never chooses the reading; placement does. In
data it is one table, verb by subject kind (`readings`), and the table
below is that table.

The current support rule stays: a support beside a **skill** applies its
modifier to that skill alone at `support_multiplier` (2.0) times its
value. Two changes. **Reach reads area and projectile skills natively**
(wider area; a projectile flies further). And, the owner's rule (4 Sep):
**every ingot reads every skill; nothing is inert.** An element ingot
beside a skill of its own element scales it, the one-lane support that
is strongest early; beside a skill of another element it **adds that
element's damage** to the hit as a second packet, so a Frost ingot beside
Ember Bolt makes a fire-and-cold bolt and a build can head toward boil
or scald before any catalyst arrives. The owner's words: "I don't think
we need to restrict 'cold damage incr' to only cold spells ... adding a
cold damage on the spell means you might pursue different builds." The
self ingots (Vigour, Plate, Ward) read a skill weakly on their own and
fully once a Catalyst sharpens them. The two lanes trade the same
number: +24% increased is the same hit as +24% of the hit added, but the
added packet is its own type, scaled by that type's gear, and it is what
the Catalyst turns into a status and an interaction.

The new subjects are currencies. Each has a base of its own and a
**trigger** (used by links):

> **Withdrawn 4 Sep 2026 (the flow).** Currencies never sit in a socket.
> The rows below for the Vanguard, Marrow and Quicksilver as subjects,
> and the three subject columns of the readings table, are kept for the
> record; what a kind does now is under [The flow](#the-flow-owner-4-sep-2026-later-that-day)
> and the `forms` table in `foundry.json`.

| Subject | Base when socketed | Trigger |
| --- | --- | --- |
| Skill tablet | none; the skill itself | the skill's status crossing its threshold on an enemy (freeze, ignite, bleed) |
| **Vanguard** (defence) | +8 armour (Bulwark Vanguard) or +5 to every resistance (Warding Vanguard) | a single hit for more than 10% of your life |
| **Marrow** (life) | 1 life a second while nothing has hit you for 4 s | falling below half life |
| **Quicksilver** (tempo) | Dash recovers 20% faster | a Dash |

### Readings: eight ingots, four subjects

| Ingot | Beside a skill tablet | Beside a Vanguard | Beside a Marrow | Beside a Quicksilver |
| --- | --- | --- | --- | --- |
| **Ember** | fire skill: +24% fire damage; any other: adds fire damage equal to 24% of the hit | +10 fire resistance; ignite on you burns 25% shorter | Warmth: standing by a fire (a campfire, burning ground) regenerates 2 life a second | your Dash leaves burning ground |
| **Frost** | cold skill: +24% cold damage; any other: adds cold damage equal to 24% of the hit | +10 cold resistance; chill on you builds 25% slower | chilled enemies deal 15% less to you | dashing through enemies chills them |
| **Edge** | physical skill: +24% physical damage; any other: adds physical damage equal to 24% of the hit | Barbs: an enemy that hits you takes 25 bleed buildup | a kill of a bleeding enemy restores 3 life | dashing through enemies bleeds them |
| **Reach** | area skill 16% wider; projectile flies 16% further; strike reaches 16% further | when you are struck, Barbs and every other answer to the hit reach every enemy within 2.5 m, not only the striker | your shelter's regeneration follows you 10 m past the door | Dash goes 1 m further |
| **Vigour** | a kill with the skill restores 1 life | +24 life; 2 life a second for 3 s after a hit | +24 life; the Marrow's regeneration doubles | a Dash restores 4 life |
| **Plate** | casting the skill grants 4 armour for 2 s | +16 armour; armour counts against fire at half | armour also reduces burn and bleed damage taken | +8 armour for 1.5 s after a Dash |
| **Ward** | an enemy carrying the skill's status deals 5% less to you | +5 to every resistance; statuses on you decay twice as fast | resistances also slow status buildup on you | a Dash cleanses one status |
| **Haste** | +16% cooldown recovery (attacks and spells) | after a hit you move 15% faster for 2 s | life restored to you from any source is 15% more | Dash recovers 16% faster |

Every number is the ingot's flat value, doubled by the support multiplier
where it is a number at all; most readings are mechanics with one number.
Cold resistance is a new derived stat (there is only fire today); Barbs,
Warmth, the Dash readings and the shelter reach are engine hooks reading
sim numbers, in the ADR-0003 division.

The owner's example reads straight off the table: a Bulwark Vanguard
supported by Frost is +10 cold resistance and slower chill on you.

**As built (4 Sep 2026).** The Vanguard column was built as a socketed
subject in slice 4 and withdrawn the same day by the flow; its readings
survive as the Vanguard's forms (Cinder Guard, Cold Ward, Barbs, Far
Answer, Quickstep, Stand Fast, Frost Leech, Second Wind), each feeding
the skill whose support the Vanguard touches.

## Corners: the joins

A corner touches two supports and never the socket. It is where
creativity lives, because it is the only cell that can change what a
support *is*.

**An ingot in a corner** does what ingots do now: its base effect; a pair
with either support it touches (Ember in a corner between Reach and Haste
is Wildfire and Lingering Flame at once); **backing** if it matches a
support it touches.

**Backing, and what "fold lines into backing" means (question 6).** Today
the plate has a rule for three matching ingots in a straight row or
column: the verb is added once more. It almost never fires, because the
milestones only ever forge one or two of most ingots (Edge is the only
ingot that arrives three times, and the third comes in era two). Backing
is the same reward for a smaller shape: **a second Frost touching your
Frost support makes that support count once more**. Two ingots, touching,
in any direction, instead of three in a line. The line rule is dropped
because backing already covers it (a line into a socket is a support and
its backing). A duplicate ingot therefore always has a job. Refinement
(the metal of the ingot, above) widens how far a backing is read.

**A Vanguard, Marrow or Quicksilver in a corner** gives half its socketed
base (a corner Vanguard: +4 armour) and **lends the two supports it
touches its reading**: the Frost support beside your orb is still +24%
cold damage, and with a Vanguard in the corner it is also +10 cold
resistance and slower chill on you. This is how an offence working
carries defence without a second socket, and the answer to "one defence
becomes mandatory" ([combat-and-builds.md](combat-and-builds.md)):
defence can ride any working.

**A Catalyst in a corner** has no base of its own. It **works the two
supports it touches** into their strong form. A same-element support is
*sharpened* (its status builds faster); an added-element support gains
its **reaction**: the added damage now applies its status too, and the
two elements on one hit interact. This is the owner's Scald, generalised:
the Frost ingot beside Ember Bolt added cold; with the Catalyst the cold
also chills, and a burning enemy that freezes is quenched.

### Native and sharpened (skill subjects)

The native reading is in the table above; this is what the Catalyst makes of it.

| Support | The skill is... | Becomes | What it does |
| --- | --- | --- | --- |
| Ember | cold | **Scald** | the added fire also ignites (+15 ignite buildup); an ignited enemy takes 20% more cold damage |
| Frost | fire | **Quench** | the added cold also chills (+15); a burning enemy that freezes takes the rest of its burn at once |
| Ember | physical | **Temper** | the added fire also ignites (+15); an ignited enemy takes 20% more physical from it |
| Frost | physical | **Rime** | the added cold also chills (+15); the attack's shatter novas chill (+30) |
| Edge | cold | **Brittle** | the added physical also bleeds (+20); a frozen enemy that is bleeding shatters from this spell's own hit |
| Edge | fire | **Sear** | the added physical also bleeds (+20); a bleeding burn ticks 50% faster while the enemy moves |
| Reach | single-target | **Arc** | the strike gains a 1.5 m arc: it becomes an area skill and reads area modifiers from then on |
| Reach | projectile | **Split** | +1 fork |
| Reach | area | **Linger** | the area persists on the ground for 1.5 s |
| Frost | cold | **Deep Frost** | chill builds 30% faster for this skill |
| Ember | fire | **Kindling** | ignite builds 30% faster for this skill |
| Edge | physical | **Serration** | the skill's hits bleed (+20 buildup); its bleeds build 30% faster |
| Haste | any | **Echo** | every fourth cast repeats itself |
| Vigour | any | **Reap** | a kill with the skill restores 3 life, and 1 life a second for 3 s |
| Plate | any | **Bracing** | casting the skill grants 8 armour for 2 s, and the cast cannot be interrupted |
| Ward | any | **Aegis** | an enemy carrying this skill's status deals 15% less to you, and its own status cannot reach you |

Seven of these reuse resolver keys that exist (`add_ignite_buildup`,
`add_chill_buildup`, `add_fork`, the pair modifiers, the boons'
`repeat_every_nth_hit`); Scald, Quench, Brittle, Sear, Arc, Linger, Reap,
Bracing and Aegis need one hook each, tag-gated like shatter and
proliferate. The added element itself is the one sim change under all of
them: `skillDamage` returns one number today and a hit has no type on the
player's side; an added element makes a hit a list of typed packets
(`grammar::skillHit`), each scaled by its own type's modifiers and each
carrying its own status once sharpened, which is the "type mix" the
grammar always promised. A Catalyst beside a Vanguard, Marrow or Quicksilver support
sharpens that reading instead (Barbs also stagger; dashing through
freezes outright); that table waits for the third slice.

The catalyst's own element (Ember Catalyst, Preserving Catalyst) matters
in crafting, where it names the domain. On the plate every catalyst reads
as the offence kind and the support and subject decide the reaction; this
keeps the table two-dimensional. An open question below asks whether that
is right.

## Links: a Catalyst between two subjects

> **Re-homed and built (4 Sep 2026, slice 7).** A kind cannot rest in a
> support cell, so the link lives in the corner beyond a shared support:
> a Catalyst resting at (1,3) or (2,0) in era one, touching the support
> both sockets serve, links the two skills laid there. Each casts the
> other on its own trigger (a freeze, an ignite, a bleed), at the enemy
> the trigger landed on, with its own cooldown, on or off the bar; a
> linked cast never fires another link. The Catalyst still works that
> support into its form: the link is what the corner between two workings
> does on top. `links.family` in foundry.json names who links. The bar
> does not yet mark a linked skill; the HUD says when one casts itself.

Sockets are never side by side on the frame, but the two workings share
two support cells from era one. **A Catalyst placed in a shared support
cell links the two subjects it touches.** A Catalyst touching only one
subject has nothing to read, and the panel says so.

**What "the linked skill leaves the bar" means (question 4).** Today
every skill you use sits in one of the four action-bar slots and you
press it. A linked skill is cast *for* you by the other subject's
trigger, so it no longer needs a slot: Frost Orb linked to Shatter means
that whenever the orb freezes an enemy, Shatter casts itself at that
enemy, with its own supports and its own cooldown, and you never press
Shatter again. The bar slot Shatter used is free for something else.
That is the whole meaning: the plate can run more skills than the bar
shows, which was the owner's worry in D-022.

- **Skill and skill:** the second casts on the first's trigger. Which is
  "first" is whichever trigger fires; a bleed skill linked to a fire skill
  runs both ways.
- **Skill and Vanguard, Marrow or Quicksilver:** the currency's trigger
  casts the skill. A heavy hit casts Frost Nova around you; a Dash casts
  Rend at the enemy you pass through.
- **Vanguard and Marrow, and the like:** the two share their bases (the
  Marrow's regeneration also runs for 3 s after the Vanguard triggers).

The link costs one of the two best cells on the plate, a cell that would
otherwise support both subjects, and a Catalyst. That is the trade: two
skills as one, for a support. Cast-on-event is an engine hook, the same
family the deferred uniques want
([items-and-modifiers.md](items-and-modifiers.md)).

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

**As built (4 Sep 2026, slice 9).** The owner's later words: "before you actually begin the game you choose a class, and in era 1 you can still access the plate/foundry, so that base plate's surrounding modifiers are determined by that first selection. Then once you complete trials you specialise further, getting a view of what the surround modifiers can become." The
class is chosen before play in its own panel (the sandpit opens it; a
save that carries a class never sees it). The three seeds above are the
three classes, tuned as written with three changes: Volley's minimum is
one placed Reach, because in era one a socket's column has a single
free cell and the socket is the commitment; Shield Wall's "a Vanguard's
socket in the row" is "a Vanguard rests in the row" (kinds never sit in
sockets); Riposte and Ashen Step read the line's two end cells, which
move when an era forges a row (an era-two Riposte on rows 1 and 3 waits
for an Edge on row 4 in era three). Rails allowed: one in era one, two
in era two, three in era three (`rails.by_era`); one rail per pattern;
set and cleared in the panel for free (a rail is class, not metal). The
Tyrant's forge is the first trial (`rails.specialise_on_world_effect`):
its completion offers, once, one of the class's two **specialisations** -
Sharpshooter or Fletcher, Bulwark or Sentinel, Pyromancer or
Hearthkeeper - and each is a **view**: the panel writes what every
pattern becomes (Volley into Fusillade or Split Volley, Quarry into Deep
Quarry or Hamstring, Shield Wall into Iron Wall or Bastion, Riposte into
Retaliation or Counterstroke, Pyre into Conflagration or Smoulder, Ashen
Step into Ash Walker or Hearth), and on the choice a rail already holding
the base pattern becomes the grown one. A grown pattern (`from`)
inherits its base's axis and condition and changes only the rule.
Conditions are `all_placed_are`, `alternating`, `ends_are`,
`minimum_placed`, `holds_skill_tag` (the rule speaks to that skill),
`holds_kind_family`. A rule speaks to the line's skills, to every skill
with a tag (Quarry's `skill_tag: projectile`) or to the sheet. The
manners are taught by kills the engine already reports (twelve hounds,
eight husks) and any class may set them. The engine's half: a projectile
fan (Volley), pierce with the fork on the last stop (Quarry), armour
against the elements after resistance (Shield Wall), the Barbs doubled
and a half-second stagger (Riposte), the ignite spreading on the hit
(Pyre), burning ground healing (Ashen Step), more against an enemy whose
velocity points at you (the Hound's Manner), and armour after a second
of stillness (the Husk's Manner).

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
four is the cap for the prototype. The owner (4 Sep): retire the coin for now;
a coin and a generated town for trading may return later.

**Currency on the plate is invested, not spent.** A Catalyst or Vanguard
placed in a corner, a socket or a link lifts for the re-forge cost like
an ingot and returns to the pack; it is a piece, not a consumable. Only a
craft consumes a kind.

**As built (4 Sep 2026, slice 3).** `crafting.json` `currency_kinds` (five
ids: the two catalysts, offence; vanguard, defence; marrow, life;
quicksilver, speed), `currencies` (the three cast kinds in the purse; the
catalysts stay pack materials for tempering), `market` (goods for a
Marrow or a Quicksilver; `exchange` three for one among four kinds, the
Ember Catalyst excluded), `craft_rolls.currency_weighting`
(`aimed_minimum_rarity` keen), three `cast_*` recipes on era-three metal;
`world.json` `currency_kind` per family with one loot entry each, elites
one more; the reinforced mine pays three Vanguards, the forge upgrade
costs two, the trial's loot room pays a spread. Every rate is a first
guess. Currency on the plate waits for the Vanguard and the corners.

## Worked plates

Names are for the doc; the panel says what the working does in a
sentence. Sockets in brackets, currency in braces, the frame's rows as
the era has forged them.

### The Scalding Orb (era one)

```
   Ember      [Frost Orb]        Frost          Vigour
 {Catalyst}     Haste      [Bulwark Vanguard]   Plate
```

- Ember, west of the orb: adds fire damage to the orb, a cold-and-fire
  bolt. The Catalyst in the corner touches it: **Scald**. The added fire
  ignites, and ignited enemies take 20% more cold.
- Frost, the shared cell: +24% cold damage to the orb, and +10 cold
  resistance with slower chill on you for the Vanguard.
- Haste, the other shared cell: the orb recovers 16% faster; you move
  faster after a hit. The Catalyst touches it too: **Echo**, every fourth
  orb repeats.
- Plate, east of the Vanguard: +16 armour. The Vigour in the Vanguard's
  corner touches it: the **Bulwark** pair, +8.
- Bases: +12% fire and cold, +8% recovery, +12 life, +8 armour; the
  Vanguard's own +8.

All eight cells used, five of the twelve ingots era one forges: 40
armour, 112 life, cold resistance, and a control spell with a burn on it.
Move the Catalyst and the orb stops scalding; that is the criterion.

### Cast on Freeze (era one, a link)

```
   Frost      [Frost Orb]        Reach        {Vanguard}
 {Catalyst}   {Catalyst}       [Shatter]        Frost
```

- Frost, west: +24% cold to the orb; the corner Catalyst touches it:
  **Deep Frost**, chill builds fast.
- The Catalyst in the shared cell touches both sockets: **the link**.
  Every freeze the orb lands casts Shatter at the frozen enemy. Shatter
  leaves the bar.
- Reach, the other shared cell: the orb flies further; Shatter's ring is
  wider.
- Frost, east: +24% cold to Shatter. The Vanguard in Shatter's corner
  touches it: cold resistance; and Reach: your answers to a hit reach 2.5
  m. Its own +4 armour.

Three ingots, two Catalysts, one Vanguard: the owner's Wave 2 sentence
(orb, freeze, shatter, cascade) on one bar slot in era one, at the price
of the plate's best cell.

### Redline (era one, a Quicksilver)

```
   Edge         [Rend]           Frost        {Catalyst}
   Edge          Haste       [Quicksilver]      Ember
```

- Edge, west: +24% physical to Rend. The second Edge in Rend's corner
  **backs** it: +24% again; and touches Haste: **Serration**.
- Frost, shared: adds cold to Rend's blow; the Catalyst in the
  Quicksilver's corner touches it: **Rime**, the added cold chills. For
  the Quicksilver it reads as dashing through chills, sharpened by the
  same Catalyst: freezes outright.
- Haste, shared: Rend recovers faster; Dash recovers faster.
- Ember, east: Dash leaves burning ground, and the Catalyst makes it burn
  longer. The Quicksilver's own: Dash recovers 20% faster.

Dash through the line and it is frozen and burning behind you; Rend opens
it and the bleed's moving multiplier finishes it. The conga line
([skill-grammar.md](skill-grammar.md)).

### The Anvil (era two, row 0 forged)

```
   Plate         Plate          {Marrow}          .
   Edge    [Bulwark Vanguard]    Frost        {Catalyst}
 {Catalyst}     Vigour       [Heavy Strike]     Edge
```

- Plate, north: +16 armour; the Plate in the corner **backs** it, +16
  again.
- Edge, west: **Barbs**, attackers bleed; the corner Catalyst touches it:
  Barbs also stagger.
- Vigour, shared: +24 life and regeneration after a hit for the Vanguard;
  a life on kill for the strike, and the same Catalyst touches it:
  **Reap**, kills restore 3 and regenerate.
- Frost, shared: cold resistance for the Vanguard; added cold on the
  strike, and the strike's corner Catalyst touches it: **Rime**, the
  added cold chills.
- Edge, east of the strike: +24% physical; the Catalyst: **Serration**,
  the strike bleeds.
- The Marrow touches Plate (armour reduces burns and bleeds) and Frost
  (chilled enemies deal 15% less).

Fifty-six armour and 136 life from the plate, the D-020 defensive spike
in mechanics, and a strike that chills, bleeds and reaps. The far cell
(0,3) is empty: it belongs to no working yet.

### Volley (era three, a Ranger rail)

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

- Sockets are drawn on the bare plate, and the rows the era has not
  forged are drawn as the plate's unworked edge, so the player can see
  the working that is not yet whole. Setting a subject rims its supports
  and dots its corners; hovering any cell names its role for each
  working it belongs to.
- Every support's reading is written on its cell, and a Catalyst's
  corner shows what it would make of each: "Frost: adds cold to Ember
  Bolt. With a Catalyst here: Quench." No cell is ever blank.
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
| `rows_by_era` | which rows of the 4x4 frame the era has forged | the size gate; when a working becomes whole | `[1,2]`, `[0,2]`, `[0,3]` |
| `sockets` | the frame cells that take a subject | how many workings and how they overlap | `[[1,1],[2,2]]` |
| `ingot_metals[].reach` | how far an ingot of that metal is read for backing and pairs | the quality axis; refinement | iron 1, bronze 2, steel 3 |
| `ingot_metals[].recast_cost` | what re-casting one ingot in the metal costs at the forge | the alloy you can smelt is the quality your ingots reach | one ingot of the alloy |
| `forms[].metal` | the least metal a compound form needs its support cast in | refinement changing what a kind makes of a support | bronze, steel |
| `support_multiplier` | a support's value against the ingot's base | how much a working is worth over the bare plate | 2.0 (as now) |
| `corner_lending_multiplier` | a corner currency's lending against the base | how much defence an offence working can carry | 1.0 |
| `corner_base_fraction` | a corner currency's own base against its socketed base | whether a corner is worth a currency with no support to work | 0.5 |
| `reactions[]` | each reaction's number | the strength of a cross-element build | 15 to 30% band |
| `subjects[].trigger` | what fires a link | how often linked skills cast | as tabled |
| `rails.by_era` | rails the player may set | how much class shows on the plate | 1, 2, 3 |
| `rails.patterns[].condition.minimum_placed` | ingots a rail needs before it lights | rails as a commitment, not a freebie | 2 |
| `rails.patterns[].taught_by.kills` | kills of a family before its manner is known | the world teaching at the pace of a hunt | hounds 12, husks 8 |
| `craft_rolls.currency_weighting` | how strongly a kind aims a craft | crafting as targeting | first modifier from the family |
| `market.exchange` | rate between kinds at the peddler | surplus never dead; farming still a choice | 3:1 |
| family drop kinds and rates | which kind a family pays | where to hunt for what | one per family, elites +1 |

## Failure cases and exploits

- **A vanguard working becomes mandatory.** Countered by corner lending:
  any working can carry the defence it needs. Watch the oracle.
- **The one-lane support always wins.** If +24% of your own element is
  always better than an added element, no one builds boil or scald.
  Countered by the added packet scaling with its own type's gear and by
  the Catalyst's reaction living only on the added lane; watch the ratio
  in the oracle.
- **The two-element hit is unreadable.** A bolt that is fire and cold
  needs both tells on the mob; a packet without a tell is a stat.
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
- [ ] A tester builds a two-element skill from the plate alone, and can
      say what the second element is doing.
- [ ] The Anvil makes the Tyrant survivable without tempered armour, and
      the oracle's rates stay inside the D-020 band with it.
- [ ] A linked skill casts itself and the tester notices the bar has a
      free slot.
- [ ] A rail makes a tester rearrange a working they liked.
- [ ] Sim tests: readings per subject, corner lending and reactions,
      backing, links, rails' conditions, currency weighting in a craft,
      save round-trip with subjects in sockets.

## Open questions (owner decisions)

Answered 4 Sep 2026: 1 (fixed sockets, two rows by four in era one), 2
(coin retired for now), 3 (Reach reads natively: yes), 5 (class at the
start, rails at the hall: yes), 7 (corner cells: yes), 8 (the support and
subject pick the reaction: yes), 9 (Marrow and Quicksilver after the
Vanguard: yes). Pending: 4 and 6, explained in place above.

10. Answered 4 Sep: the recommended socket layout, a row and one column
    apart.
11. **Does the class hall forge a third socket** at a far cell of the
    frame, (0,3) or (3,0)? Recommended: yes, in era three, as the hall's
    reward alongside the rails.
12. **Twelve era-one ingots for six cells:** accept the reserve, or move
    the beyond-the-heartland first-kills to era two? Recommended: accept
    it and watch the playtest.
13. **Currency lifts for the re-forge cost and returns to the pack?**
    Recommended: yes; it is a piece, not a consumable.

## Slice order

Each slice is data plus the smallest sim rule, tested headless, the panel
following.

1. **The frame and the working** *(landed 4 Sep 2026)*. `rows_by_era`
   and `sockets` on a 4x4 frame (era one rows 1 and 2); subjects only in
   sockets (a tablet outside one lifts free on load); supports rimmed and
   every reading written on its cell; Reach reads area, projectile and
   strike skills; backing replaces lines. Save: subject cells validated;
   placements in forged rows only.
2. **Every ingot reads every skill** *(landed 4 Sep 2026)*. The typed
   packet (`skillHit`), added elements, the weak self readings; mob
   immunities by packet type in the engine.
3. **Typed currency** *(landed 4 Sep 2026; the lift from the plate waits
   for slices 4 and 5)*. Four kinds; family drop kinds; coin retired, its
   drops and prices become kinds, the peddler changes kinds;
   `currency_weighting` in a craft; currency lifts from the plate for the
   re-forge cost.
4. **The Vanguard** *(landed 4 Sep 2026 as a socketed subject; withdrawn
   the same day by the flow, its readings now Vanguard forms)*.
5. **The flow and the first forms** *(landed 4 Sep 2026)*. Kinds only in
   the detached cells; the base flowing inward; forms keyed by family,
   ingot and lane: the sharpenings, Scald, Temper, Quench and Rime as far
   as existing keys carry them, Brittle and Sear as their "more against a
   status" halves, the Vanguard's eight proposed forms.
6. **Kinds as variants; the reactions' hooks** *(landed 4 Sep 2026)*.
   Every currency id with its own base (the Warding Vanguard the first
   extra variant); Echo, Quench, Rime, Sear and Brittle as engine hooks;
   Serration, Brittle and Sear bleeding. Still ahead: Arc, Linger,
   compound forms, the variants waiting on stats.
7. **Links** *(landed 4 Sep 2026)*. Re-homed to the corner beyond a
   shared support; cast on trigger at the struck enemy; on or off the
   bar. Arc landed with it. Still ahead: the bar marking a linked skill.
8. **Marrow and Quicksilver's forms** *(landed 4 Sep 2026, taken before
   rails because rails need a class choice and a class hall that do not
   exist yet)*. Sixteen forms; the Dash's on the sheet. Still ahead: the
   rest of their variants, and the readings that need player statuses or
   ground hooks (burning ground from a Dash, dashing through enemies).
9. **Rails** *(landed 4 Sep 2026 on the owner's answer: the class
   before play, its patterns the plate's surround from era one, the
   trial's completion a specialisation that shows what they become)*.
   Three classes of two patterns, six specialisations that grow them,
   two manners, the Tyrant's forge as the first trial, rails set in the
   panel. Still ahead: the class hall as an authored place (D-004) and
   deeper trials as later specialisations, a manner per family.
10. **The metal of an ingot** *(landed 4 Sep 2026)*. Re-casting at the
   forge in the era's alloy; reach for backing and pairs; alloy-cast
   ingots from the first elites and the deeper forge; eight compound
   forms conditioned on the support's metal. Rarity is the alloy from the
   other end, as the gate above says; no separate rarity field.
