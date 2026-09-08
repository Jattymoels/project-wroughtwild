# INT-05B — Contact and encounter pressure

Status: **Implemented, owner review pending.** Baseline `9c82cbb`, clean main matching origin/main.
Owner: Matty. Delivery: Codex. “Continue on with 05B” selects only this slice
from the [playtest plan](playtest-iterations-2026-09-07.md).

## Outcome and plan

Make hounds threaten inattentive retreat and ranged attacks constrain movement
while remaining dodgeable. Reproduce contact on open ground and in existing
Forge modules before changing range, movement, commitment or shot travel.
Record actual player-controller movement, attack starts/releases, distances,
hits and damage; distinguish successful evasion from broken contact.

Then concentrate fighting and stage mixed reinforcements inside the existing
eight modules, preserving solid cover, traversable routes, optional-room
independence, open retreat, exits, lifts and boss space. Keep the 24 living-enemy
and two-major-hazard limits. Use bounded documented tuning, not a new room or
enemy framework. Compare matched dense-fight timing and investigate >10% changes.

Affected: Enemy, spatial projectile delivery, ForgeDungeon/TrialController,
combat_realtime.json, trial.json and the native tuning bridge if needed.
D-010 / ADR-0003 owns rules versus space/time, D-012 preserves the train and
movement-only dash, D-025 preserves build identities, D-028 governs trial state.
No damage, life, mastery, player sustain or Foundry tuning is selected here.
INT-05C handles that next. No world profile, population-generator, saved geography,
inventory/reward ownership or timber-demolition change is included.

The owner's exact build/encounter is unknown. Representative deterministic
cases and measured initial tuning can proceed; final difficulty and enjoyment
remain owner review. No missing architectural or progression decision blocks
the contact audit. Preserve the unmodified baseline, copied game/data, isolated
APPDATA and owned hidden processes under ignored `build/forge-pressure/`.
Never load the normal save or stop the owner's running playtest.

The completed slice updates the queue/specifications. Commit and ordinary push
are reported separately in delivery under the owner's standing permission.

## Reproduced failures and corrections

The common fixture runs ten seconds per case at 60 physics ticks/s with the
real player capsule/controller, an unarmoured Warden and no constructed Foundry
defence. Enemy starts are 2.3 m for the hound and 7 m for archer/wisp. It records
windup starts, committed target direction, releases, positions, horizontal
centre distance, approximate horizontal capsule gap, landed damage and shot
flight. Combat state resets between cases; native ownership remains exact.

On open ground the baseline hound makes three attempts during straight retreat,
starting at 1.59–1.60 m but releasing at 2.93 m, outside its unchanged 1.84 m
release allowance. It stops for the whole windup while the player walks away.
The correction is a collision-respecting 1.1 m step along the direction selected
at windup start. The first retreat contact is now at 1.825 m after 1.85 seconds.
A 100-degree forward sector prevents that step from turning a sidestep into a
360-degree bite. The original hound also lands eight bites through the fixed
solid barrier; the new start/release cover checks prevent all of them.

Counts below are **landed hits / releases**, baseline → current:

| Open-ground case | Hound | Archer | Marsh wisp |
| --- | --- | --- | --- |
| Stationary | 8/8 → 8/8 | 4/4 → 4/4 | 6/7 → 7/7 |
| Straight retreat, 50 m unobstructed route | 0/3 → 7/7 | 0/1 → 1/1 | 0/1 → 1/1 |
| Deliberate lateral evasion | 7/8 → 0/8 | 0/4 → 0/4 | 0/7 → 0/7 |
| Stationary behind solid barrier | 8/8 → 0/0 | 0/4 → 0/0 | 0/7 → 0/0 |

Current straight-retreat shots land after 0.733 s of flight for the archer and
0.817 s for the wisp. They retain committed aim, finite travel and real collision;
neither leads nor homes. Walking laterally during charge or flight still works.
Native damage rolls vary across launches; these counts do not imply a change
to damage per hit. Hound harry explains its additional contacts after the first.

The matching actual Threshold module has the same stationary results. Straight
retreat reaches a room wall after about 11.2 m: baseline/current hits are hound
6/7, archer 2/3 and wisp 4/5. Thus the original bite is not universally broken:
it can hit a player whose retreat is physically stopped. Deliberate clear
sidesteps change hound contacts 5 → 0; both shooters remain at zero. All three
current barrier cases prevent contact. No wall or capsule collision is ignored.

The first fixture held a world-X direction, which became straight retreat when
the hound turned. It was corrected for **both** versions to sidestep relative
to each committed attack. In the Forge it chooses a clear capsule sweep rather
than walking blindly into a pillar. Tests retain zero-hit dodge assertions.
The old radial hound then fails those assertions; the current forward bite
passes. The separate 20/60 Hz check uses actual engine tick rates and published
collider poses: an unobstructed step measures 1.100000 m at each rate, retains
its original direction, and is cancelled by stagger.

A second current-candidate probe exposed a real ranged corner failure in the
Kiln Hall: archers/wisps reached a clear thin sight line but their projectile
radius clipped the kiln. They released 3/8 shots without a hit over 15 seconds.
Firing readiness now checks the actual muzzle and swept shot sphere. A blocked
shooter continues its existing navigation path rather than holding preferred
distance at that corner. Final actual walking/contact measurements are hound
21.11 m / 0.77 m hit distance, archer 18.54 m / 6.05 m, and wisp 14.13 m / 5.97 m.
Each reaches a stationary target around the solid kiln and lands its first
released attack. The kiln geometry and navigation clearance are unchanged.

## Mixed groups and safe arrivals

The baseline Threshold spawns six melee bodies with no reserves. A forced
second group reproduces an arrival 0.117 m from both player and survivor.
The current native opening has melee, hounds, an archer and a kindler, followed
by six mixed reserves. The equivalent overlap probe places new bodies at least
5.116 m from the player and 3.341 m from the original survivors. Filling without
kills stops at 24; every remaining ID stays queued. Removing all eligible floor
cells produces no fallback spawn, loss or duplication. A room cannot reward
until its living enemies, reserves and major hazards are cleared.

Ordered native arrays contain 12/14/16 enemies per ordinary Tyrant/Deep/Capstone
room. They mix the existing family roles in successive groups of at most six;
boss rosters remain 1/3/3. Map condition reserves still append through their
existing rules. Existing per-wave rare assignment also remains: more groups
can produce more rares, which matters for elite-kill recovery in INT-05C.

Groups alternate preferred entry-side and rear positions around the current
cover. Selection uses current navigable cells within a central 16×16 m area
with a 1 m inset, 1.7 m body spacing and 5 m player clearance. Room outlines,
cover, optional room access, open retreat and the original boss/lift routes are
unchanged. Failed/full arrivals retry on the warning interval; no queued enemy
is consumed until it receives a safe position. A boss keeps its central point
when clear, otherwise receives a checked alternative inside its original room.

The normal arrival interval is six seconds; its last two seconds show an actual
HUD warning. A fast clear also leaves the full warning before the next group.
Map-specific intervals remain in force. Captured and inspected at normal
first-person height in the existing world lighting:
[advance warning](references/forge-pressure-2026-09-08-warning.png),
[two mixed groups](references/forge-pressure-2026-09-08-groups.png).
The HUD warning and live/reserve counts are legible. Existing distant nameplates
overlap in the denser group; this pass does not claim to solve label crowding.

## Tuning and authority

| File / values | Player-facing purpose |
| --- | --- |
| `combat_realtime.json`: fast `windup_advance_m=1.1`, `attack_arc_degrees=100` | Catch inattentive straight walking while committing to a dodgeable forward bite; physical motion still respects collision, slow and stagger. Chase 5.5 m/s, windup 0.25 s and reach stay unchanged. |
| Same: archer projectile speed 10 → 18 m/s; wisp 8 → 16 m/s and range 12 → 14 m | Shots can catch straight retreat from preferred distance, while existing 0.6/0.5 s charges and sideways avoidance remain. Archer range stays 14 m; neither radius nor damage changes. |
| `trial.json`: native ordinary counts 12/14/16; wave size 10 → 6 | More total mixed pressure, split into readable arrivals rather than raising the 24-living cap. |
| Same: default delay 8 → 6 s, notice 2 s | Maintain pressure with an advance warning, including after an early clear. Blocked arrivals reuse the notice interval for retry. |
| Same: area 16×16 m, side offset 2 m, front/rear offsets +2/−3 m | Concentrate arrival positions around existing entry lanes and cover while retaining the whole traversable room. |
| Same: spacing 1.7 m, player clearance 5 m | Avoid stacked bodies and close surprise spawns. |

The native bridge exposes the two optional melee-delivery values and rejects
negative advance, nonpositive windup with advance, and arcs outside (0,360].
Other behaviours default to zero advance and the original full radial sector.
All values have plain-language purposes in their tuning data. No damage/life,
player recovery, mastery, equipment, Foundry identity, enemy/hazard cap, room
topology, progression or saved-geography value changed.

## Verification and performance

- Native suite: **224,379 checks, zero failures**; GDExtension Release build
  succeeds with the installed compiler. The normal ignored DLL now exactly
  matches the tested isolated DLL; the build output setting is restored.
- Current open and Forge contact: **20 + 20 checks**; groups/queue/ownership:
  **22**; warning, kiln navigation and committed bites: **24**; fresh-process
  pre-05B boundary import: **7**. All pass. The preserved version fails the
  corresponding 3 open, 2 Forge and 4 grouping/arrival assertions as reported.
- Existing ranged fairness **53**, horde **43**, boss tells **163**, trial
  lifecycle **6,218**, integration **273**, physical traversal **122** all pass.
  The route walks **814.9 m through all eight module treatments**, real doors,
  optional store, offerings, cleared lift, save/restore and final extraction.
- Rendered three-story inspection **89** and dense workload **4** pass. Screens
  are inspection poses with enemies held; they are not difficulty evidence.
- The old-version native economy and cleared-floor checkpoint import in a
  fresh current process with exact deposit, loot, route, boons/weaknesses, life
  and combat clocks. Continue enters the same next floor using current rosters.
  No checkpoint content revision or save schema changes are necessary.

Matched rendered seed-77 workload: 24 enemies, eight ignites, four Foundry fields
and two fixed major warnings; 3 s warmup plus 5 s sampling, no screenshot
readbacks during sampling, uncapped rendering and Dummy audio. Same machine,
copied world and effects; the new contact changes actual movement/collision.

| Milliseconds | Baseline | Initial correction | Final |
| --- | ---: | ---: | ---: |
| Frame median | 1.152 | 1.153 | 1.134 |
| Frame p95 | 3.330 | 3.667 | 3.621 |
| Mean physics | 3.308 | 3.592 | 3.511 |
| Mean process | 1.935 | 2.048 | 1.944 |

The initial p95 change was **+10.1%**, triggering investigation. Trial pursuit
performed a sight ray even when melee, distance or an already blocked shot
unconditionally required a path. Skipping only those redundant rays retains
the same path decision. Final p95 is **+8.7%**, median **−1.6%**, mean physics
**+6.1%**. This is a bounded sample, not a guarantee on other hardware, and
increased physical contact still costs work.

## Live combat and limitations

The existing `trial_balance --smoke` fixture makes six real fights per version
with no forced kills: prepared Warden/Ranger/Kindler, one tier-one pack and one
boss each, legal equipment/Foundry configuration, gate seed 741103, offer zero,
same conditions and controller policy. Thirty-second timeouts are not clears.
Setup errors and floor rescues are zero in both versions.

| Prepared cohort | Pack baseline → current | Boss baseline → current |
| --- | --- | --- |
| Ranger | timeout, 6 kills → timeout, 17 kills | death 25.87 s → death 13.03 s |
| Warden | clear 27.27 s → death 17.57 s | death 10.87 s → death 8.77 s |
| Kindler | clear 24.30 s → timeout, 18 kills | timeout → death 18.63 s |

That is **2 clears / 2 deaths / 2 timeouts → 0 clears / 4 deaths / 2 timeouts**.
Pack damage received changes 24.84 → 91.71, 63.01 → 102.14 and 12.24 → 51.05
for Ranger/Warden/Kindler. Actual live peaks are 10–12; the separate no-kill
probe reaches the hard cap of 24. Boss support contact changes despite unchanged
boss damage/rosters. This shows increased pressure and possible overtuning for
these policies; it does **not** establish balanced classes, viable human early
melee, full-run endurance or the owner's exact poor-gear/one-upgrade case.

The owner's build, seed, position and execution remain unknown. The evasion
fixture reacts immediately and chooses a clear sidestep; it proves spatial
avoidability rather than a human reaction-time guarantee. Damage rolls, dense
frame timing and a single bot policy do not establish statistical balance.
Larger packs also amplify proliferation and kill recovery. INT-05C must measure
those effects separately; no damage/sustain calibration was smuggled into this
slice. INT-05C and the remaining world slices are **not started**.

## Reproduction and isolation

Use `tools/home_review.ps1 -ReviewSet forge-pressure` with preserved `baseline`
and copied `current` projects under ignored `build/forge-pressure/`. The helper
uses separate APPDATA, hidden bounded processes and Dummy audio. Baseline
replays only common test fixtures against preserved production. No normal save
was loaded, and no owner playtest process was stopped.

Run `enemy_contact_review` normally and with `--forge-contact`,
`forge_pressure_review`, and current `forge_pressure_checks`; the latter's
`--restore-baseline` mode imports the boundary/economy written by the baseline
review in a fresh process. `forge_readability_review --performance-only` gives
matched timing; `--skip-performance --pressure-captures` gives the three-story
visual review. `trial_balance --smoke` records the live combat sample. Native
tests use the existing engine-neutral sources and installed compiler; no new
dependency is introduced.

Raw matrices, logs and full live-fight reports remain under each phase's
`captures/`, `build/intensives/` and the review root's `logs/`. The two selected
screens and this measured record are committed evidence; generated binaries,
caches and isolated saves stay ignored. Routine Git diff/whitespace checks
pass; publication is reported separately after the checked commit and push.
