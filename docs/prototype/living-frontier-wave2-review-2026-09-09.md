# Living Frontier Wave 2 — orchestrator review

9 September 2026. Reviewed baseline:
`2d247fd19747729fc67b60773dc3329968cb64a1`.
The scoped implementation commits are `51ce129` (LF1-R1), `4718317` (LF-2A),
`4bda377` (LF-2B), `75ae963` (LF-2C) and `2d247fd` (LF-2D).
Interleaved wolf/TRELLIS/art commits and working files belong to separate work.

**Verdict: Wave 2 passes technical review; clear to start a bounded Wave 3
work item. No blocking correctness issue was found.** LF1-R1 is independently
verified closed. This is clearance to build on the implemented foundation;
source discovery, pacing, visual comfort and long-term balance still need owner
playtesting. It does not activate the experiment for ordinary saved worlds or
implement later campaign waves.

This review changes documentation only and introduces no tuning or gameplay
rules. The [implementation contract and paid walkthrough](living-frontier-wave2-2026-09-08.md)
remain authoritative for selected Wave 2 behaviour.

## What was reviewed

- **Physical source repair:** paid block support restores the original Red and
  White anchors after excavation, including already saved undermining. Partial
  work, released claims, fixed outcomes and capped formation survive. Workspace
  obstruction still refuses work; removing and replacing support does not refill
  the source.
- **Blue and Green:** one saved Blue request waits its remaining three seconds;
  pause, obstruction, route changes and cancellation cannot replay it. Green
  attempts two distinct terminal receivers independently. Native linking and
  loading enforce the bounded ordering, while engine geometry checks the actual
  supports and spans. Each successful receiver supplies its own winding and
  ingredients.
- **Red heat:** paid Salt becomes bounded heat held by one buffer and its linked
  feeder. Available heat plus reserved return capacity stays within four. Firing
  still pays clay and mechanical work. Cancellation and feeder removal return
  held heat once; idle buffer removal vents unused heat. An empty attached buffer
  does not silently switch to ordinary hopper fuel.
- **Useful manufacture and construction:** all five existing offensive Catalyst
  identities have payable ordinary recipes. Their Foundry operations and grade
  refinement remain intact. The combined workshop transports real fired bricks,
  powers a separately paid firing and builds ordinary pieces from delivered stock.
- **Compatibility:** source versions 1–4 and experimental machine versions 1–5
  retain their published state through explicit introductions. Ordinary profiles
  retain their recipe/acquisition policy. Missing mandatory or future-version
  payloads refuse rather than resetting ownership or silently rolling it back.

## Independent verification

The current native extension build succeeded. The documented runners were
executed against the reviewed source and tuning, using isolated test APPDATA.

| Check | Independently observed result |
| --- | --- |
| Native source/recipe/connection suite | 213,482 checks, zero failures |
| Native Wave 2 suite | 601 checks, zero failures |
| Red/White physical repair and fresh-process recovery | 154 + 64 checks, zero failures |
| Blue paid migration journey and fresh restart | 182 + 26 checks, zero failures |
| Green paid journey and fresh restart | 129 + 9 checks, zero failures |
| Red heat paid journey and fresh restart | 324 + 14 checks, zero failures |
| All-Catalyst paid workshop and fresh restart | 488 + 10 checks, zero failures |
| Seven affected engine regressions | Catalogue 52, contraptions 85, pressure 60, loose drops 148, save recovery 175, weathered save 21, wide-frontier pacing 319; zero failures |
| Scoped committed diff whitespace | Pass |

Commands used after the extension build:

```powershell
./tools/living_frontier_checks.ps1 -Repair
./tools/living_frontier_wave2_checks.ps1 -Native
./tools/living_frontier_wave2_checks.ps1 -Blue -Restore -Green -GreenRestore -Heat -HeatRestore -Workshop -WorkshopRestore -Regression
```

The Blue check reused the existing paid historical Wave 1 checkpoint rather
than replacing it with a fresh bootstrap. Its 182 checks therefore differ from
the author's 216-check current-bootstrap receipt. Both later sources were
introduced through the saved journey, and subsequent slices continued its actual
payments and ownership. The malformed-save fixtures' refusal warnings are
expected; the runs reported no failed checks.

The committed Blue countdown, Green ports, Red heat store, combined workshop
and paid brick foundation captures were visually inspected. These screenshots
show legible component controls, separate connections and the useful building
output. This independent engine rerun was headless. The author's broader full
engine pipeline and existing native rules receipts are retained in the handoff;
this review did not rerun every unrelated engine scene.

Logs: `build/lf1/support-repair*`, `build/lf2/test_leyline.log`,
`build/lf2/test_living_frontier_wave2.log`, `build/lf2/*-flow.out.log`,
`build/lf2/*-restart.out.log` and the named regression logs. Normal user saves
and unrelated working files were not used as test fixtures.

## Remaining playtest questions

These do not block the next bounded experiment:

- Discover the four hosts without coordinates and repair an undermined one
  through ordinary building input.
- Judge whether four work steps per lot, 96 raw per Catalyst and a capped
  ten-minute active-world formation leave enough enjoyable exploration and
  useful construction between manufacture goals. Impact and Piercing share
  White, so their combined demand deliberately exceeds one manifestation.
- Try the three-second delay and both Green branches in a personal workshop;
  compare direct firing with paid Red heat storage.

The harness accelerates travel, resource dispatch and clocks and controls enemy
AI. Its exact payment and save evidence does not establish novice comprehension,
combat pressure or a satisfying human session length.

## Next-session boundary — LF-3

Use the [roadmap's LF-3 slices](living-frontier-roadmap-2026-09-08.md#lf-3--make-the-inhabitants-and-rewards-share-those-rules)
and the [extraction/economy proposal](leyline-catalyst-extraction-2026-09-08.md)
for context. Read the repository's required design/decision documents first,
then only the relevant combat, population, loot, world and save specifications.
Record the bounded Wave 3 contract before changing behaviour; select details
from owner direction and accepted decisions, and surface any materially missing
player-experience, architecture or compatibility decision.

1. **LF-3A — One animal, two influences.** Deliver related hosts with distinct
   tells, capabilities and counterplay. A colour must change a combat decision;
   ordinary movement, starting skills and equipment must remain sufficient.
2. **LF-3B — Small living habitat.** Establish a minimum four-influence sample
   linking animal scars, source cues, passive habits and useful drops. Teach Red
   and Blue separately before their later laboratory hybrid. Retain calm places
   and ordinary ancestry rather than multiplying every animal into four variants.
3. **LF-3C — Rewards and the campaign trail.** Connect the reward economy and one
   readable artificial trace toward a laboratory. Preserve the five implemented
   manufacture routes. Prove no-Catalyst and unlucky progression before enabling
   replacement acquisition for a new saved-world policy; legacy worlds retain
   their selected policy and owned state.

Before the successor becomes a normal saved-world choice, establish all three
physical laboratory sites with visible approaches and define both future
transformation regions. Reserve space through actual visible sites from the
beginning, not a future entrance under a paid home or invisible blanket building
exclusions. Keep an incomplete successor opt-in. Existing experimental saves
also need an explicit compatibility contract; do not reseed them to acquire the
new geography.

Carry Wave 1–2 ownership, repair, source renewal, ordinary recipes and separate
signal/work/heat costs forward. Verify new encounters across starting classes,
source reachability across deterministic seeds, useful drops and payment without
lucky Catalysts, and restart/death/reward ownership as affected. Keep the current
acquisition and curio campaign coherent until the successor's complete paths pass.

Respect the owner's [animal/scar art direction](leyline-asset-roadmap-2026-09-09.md)
and separate art work. Reuse suitable existing assets or placeholders; a dense
unrigged image-to-3D source is not a required runtime dependency.

Stop after the three checked Wave 3 slices and prepare the next orchestrator
handoff. Laboratory encounters, forced hybrids, failsafe events, physical era
transitions, the human uber-boss and configurable Heat remain later waves.
