# Repeatable Trial Runs

**Status:** Core philosophy accepted; prototype structure provisional  
**Related decisions:** D-001, D-006

## Purpose and player fantasy

Trials repeatedly test a persistent build under varying routes, boons, weaknesses and mechanics. The player should return from failure understanding what happened and imagining how the next attempt could succeed.

“Dungeon” describes a trial structure, not necessarily an underground place. A trial may be a temple, tower, corrupted forest, mine or fortress.

## Prototype scope

- one trial theme;
- a short branching room graph;
- three enemy behaviours;
- one boss;
- approximately 12–20 boons;
- three weaknesses or curses;
- one secret or rare event;
- entrance inventory deposit;
- no procedural room geometry requirement—authored rooms may be rearranged.

## Run sequence

1. Deposit ordinary carried inventory at the entrance.
2. Review known trial information and select any starting preparation.
3. Enter with the persistent build intact.
4. Choose between room routes, rewards or risks.
5. Acquire temporary boons and weaknesses.
6. Fight a boss that exposes build and run trade-offs.
7. Succeed and secure rewards, or die and return without permanent build loss.

## Temporary adaptation rules

- Boons interact with persistent skill tags and mechanics.
- A boon may amplify a strength, compensate for a weakness or create a risky interaction.
- A run must not replace the active skill set or permanent tree.
- Boons should interact with one another so players can recognise emerging combinations.
- Poor synergy may make a run harder, but generation should provide redirection or salvage choices.

Example for an area-focused build:

- echo area effects to improve clearing further;
- concentrate area against isolated enemies to improve boss damage;
- accept faster enemies for greater area and rewards;
- acquire a second boon that benefits from the enemy-speed weakness.

## Failure categories

- **Execution:** mechanics were misplayed.
- **Persistent power:** equipment or build is underdeveloped.
- **Run adaptation:** temporary choices failed to form sufficient synergy.
- **Build trade-off:** the build excelled at clearing but exposed weak single-target damage, defence or sustain.

Boss pressure may ramp through mechanics or attrition. Burst builds shorten exposure; defensive builds survive longer; clear-oriented builds may need compensating run choices.

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Room count | Run duration and investment |
| Branch frequency | Decision density |
| Boon offer count | Control versus randomness |
| Boon weighting | Compatibility and replay variety |
| Weakness reward multiplier | Risk appetite |
| Boss pressure ramp | Value of single-target damage and sustain |
| Secured reward timing | Tension around death |
| Secret frequency | Discovery and anticipation |

## Failure cases

- The best boon is always obvious.
- Tag-aware weighting becomes so generous that every run assembles the same synergy.
- Bad luck creates visibly unwinnable attempts.
- The permanent build trivialises all room decisions.
- Runs become repetitive because room ordering changes without meaningful context.
- Zero loss makes abandoning a weak run optimal.

## Prototype acceptance

- Two attempts with the same build present meaningfully different choices.
- The player can explain why the boss attempt failed.
- At least one boon pair creates a discoverable interaction.
- Death encourages preparation or re-entry rather than save reloading.

## Open questions

- Treatment of loot found after trial entry but before death.
- Universal versus trial-specific boon pools.
- Weighting by current build tags.
- Exact persistent-to-temporary power budget.
