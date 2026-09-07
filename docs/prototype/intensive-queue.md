# Wroughtwild intensive queue

Updated: 7 September 2026. Owner: Matty. Delivery: Codex.

The owner asked to keep track of the seven intensives discussed after the Wide
Frontier pass and make a plan for the first one. This is the current planning
queue; the [numbered waves](roadmap-waves.md) remain a historical record.
Recording an idea here does not mark it implemented or approve unspecified new
game rules. Existing accepted work items and decisions remain authoritative.

## Tracked slices

IDs stay stable when priorities change. The order below preserves the original
discussion; the suggested execution order follows the table.

| ID | Intensive | Concrete outcome | Status / next step | Later owner review |
| --- | --- | --- | --- | --- |
| INT-01 | First-hour clarity | Existing gathering, material processing, crafting and first-home options explain their requirements and next actions. | **Implemented, review pending.** [Outcome and evidence](first-hour-clarity-plan-2026-09-07.md), including shorter primary panel text and optional detail. | Can the owner understand a material, choose a useful project and find the next step without outside explanation? |
| INT-02 | Exploration and environmental storytelling | Existing landmarks, approaches and resource clues communicate surviving civilisation, accidental impact and useful discoveries. | **INT-02A implemented, review pending:** [read the remains, follow the find](exploration-storytelling-2026-09-07.md). Existing smithy route, truthful rare clues and visible work/use handoffs verified; fuller graphical direction remains separate. | Are places inviting and clues understandable during ordinary exploration? |
| INT-03 | Building and home development | Complete houses/workshops expose and resolve awkward placement, joins and interior usability. | **INT-03A/B implemented, review pending:** [home usability](home-workshop-usability-2026-09-07.md) and [reliable placement/return](home-placement-persistence-2026-09-07.md). Station previews/clearance, material joins, actual walking, complete terrain footprints and saved door poses verified. A furnishing kit is a separate content selection; farming is not included. | Is making and using a home comfortable and expressive? |
| INT-04 | Sound, animation and interaction feedback | Existing gathering, footsteps, stations and surroundings gain consistent material and state feedback. | **INT-04A/B implemented, review pending:** [interaction feedback](interaction-feedback-2026-09-07.md) and [grounded footsteps / nearby ambience](footsteps-ambience-2026-09-07.md). Actual work, hauling, manual crafting, walking support and existing biome/shelter state now own bounded local sound. Listening reels, lifecycle and matched walking evidence are recorded. | Do feedback and ambience feel convincing through repeated use? |
| INT-05 | Dungeon presentation and traversal | Existing Forge rooms, junctions, secrets, transitions and boss tells are easier to read and traverse. | **INT-05A implemented, review pending:** [read the Forge](forge-readability-2026-09-07.md). Clear branch previews, distinct fixture roles, exact danger outlines and live fixture navigation are verified through 815 m of actual walking, full trial/save checks and matched active-effect captures. | Do routes and tells make sense, including under Foundry effects? |
| INT-06 | Workshop usability | The existing finite feeder clearly communicates inputs, output, stored work, source exhaustion and blocked states. | **INT-06A implemented, review pending:** [understand and operate the workshop](workshop-usability-2026-09-07.md). Exact readiness/load amounts, short supply/drive pages, retained live controls and truthful load visuals pass actual button, save and matched rendering checks. Broader lines and renewable supply remain separate proposals. | Can the owner build it, diagnose a stop and see why it is useful? |
| INT-07 | Performance and reliability | Measured loading/terrain stalls improve, and long travel, large builds and save recovery stay dependable. | **INT-07A/B/C/D/E implemented, review pending:** [loose-drop persistence](loose-drop-persistence-2026-09-07.md), [faster preparation](world-performance-2026-09-07.md), and [session reliability](session-reliability-2026-09-07.md). Setup improves 36%; generated-home circuits, fresh restarts and damaged-save recovery pass. [INT-07D](travel-performance-2026-09-07.md) removes the measured resource-highlight pause. [INT-07E](stream-scheduling-2026-09-07.md) spreads collision/leyline work across frames, with another 20–22% lower worst frame in the final matched comparisons and exact output/lifecycle checks. An earlier unattributed frame gap remains documented. | Do saving and ordinary play remain dependable and smooth? |

Suggested sequence: **INT-01 first**, then INT-02; INT-07 can accompany those
when its changes and measurement workload are independent. Follow with INT-03
and INT-04, then the focused INT-05/INT-06 refinements as review exposes needs.
This is a working priority order, not a promise to run every item automatically.
The loose-drop issue reproduced during INT-01 was handled first as INT-07A.
INT-02A and INT-03A now have isolated gameplay captures and functional evidence.
INT-03B resolves the three placement/save cases recorded in the home audit.
INT-04A/B now have action, save, actual walking, listening-reel and matched
performance evidence. INT-05A now has physical traversal, exact danger/fixture
checks, complete lifecycle regression and matched presentation/timing evidence.
INT-06A now has actual button/ownership checks, a finite source-to-brick handoff,
720p/1080p comparisons and bounded live-work timing. INT-07B now reduces measured
V6 generation and terrain-preparation costs with preserved world/mesh output,
physical lifecycle checks and matched rendering. INT-07C now records repeated
travel, large-home returns, exact workshop resumption and repaired save recovery,
including preservation of the good backup when saving again. Normal populated
world loads remain about a second. INT-07D now prepares resource-highlight
shaders, retains resource scenes and batches equivalent leyline geometry. Two
matched rendered routes improve their worst frames by 44–48%, with steady
frame rates unchanged at the cap. Remaining collision publication and scenery
creation bursts are addressed by [INT-07E](stream-scheduling-2026-09-07.md):
separate collision preparation, queued cosmetic tiles sharing terrain slots,
and an elapsed resource-creation budget. Exact presentation, 30/60 fps simulated
coverage, historical worlds and fresh-process home/workshop restoration pass.
The final matched comparisons improve worst frames another 20–22%; an earlier
unattributed long gap stays recorded. Coincident focus/retirement/payload work is
the next bounded candidate. The recorded slices still await owner review.
Combat-number calibration remains separate. Owner playtesting remains
deferred while away and does not block independent work.

## Delivery and tracking

Use these states: **Queued → Plan ready → In progress → Implemented, review
pending → Complete**. A technical check passing does not establish enjoyment.
An implemented slice can await a short owner review while another independent
slice progresses. Record a real blocker separately from that review state.

For each implementation, link one bounded work item that records:

- the player-visible outcome, existing features reused and explicit scope;
- small deliverable steps, current step and dependencies;
- relevant functional, save and presentation checks, with evidence paths;
- measured performance where the change could affect it;
- commit/review links, known limitations and a few focused owner questions.

Update this table and its work item when work starts, scope changes, a slice is
delivered or feedback arrives. Keep evidence and unresolved questions with the
item. Use the owner's standing main-branch workflow for authorised changes;
retain normal saves and running playtests during isolated verification.

## Separate queue

The [build/trial calibration proposal](playtest-feedback-2026-09-06.md),
[chase itemisation](../systems/foundry-mutations.md#itemisation-and-future-work),
broader production, cultivation and dedicated class halls remain separate
threads of design. This queue does not change their status. A new generator
size/profile, combat-number pass, loot economy or furnishing catalogue is not
implied by a presentation/usability item. The known timber-demolition conflict
remains outside these slices.

INT-07A also recorded a separate gear-preview issue: native collection uses the
current era, so advancing an era before collecting can change a previewed
drop. The save fix preserves the existing claim; an itemisation correction
needs its own bounded follow-up.

## Activity

| Date | Item | Result |
| --- | --- | --- |
| 7 Sep 2026 | Queue | Seven discussed intensives recorded at the owner's request. |
| 7 Sep 2026 | INT-01 | Read-only code/spec audit completed against `062b7e7`; concrete plan written. No gameplay edits or runtime checks performed for the planning task. |
| 7 Sep 2026 | INT-01 | Four approved slices and the panel-density addition implemented. Native UI checks, three class journeys and matched 720p/1080p captures recorded in the work item. Owner usability review remains pending. |
| 7 Sep 2026 | INT-07 | Loose-drop loss/duplication reproduced by INT-01's planned save probe. Separate bounded reliability follow-up recorded; ordinary saves and drop rules unchanged by INT-01. |
| 7 Sep 2026 | INT-07A | Owner authorised the next work while away. Loose materials, gear, pages and death packs now restore as a single world-owned set; trial suspension and successful New World cleanup covered. Isolated evidence and compatibility limits are in the work item. |
| 7 Sep 2026 | Publishing | Owner reconfirmed ordinary main pushes; `3229ab4` published to origin/main. |
| 7 Sep 2026 | INT-02A | Existing smithy gains bounded inert remains; five rare families have truthful clues, finite discovery cues, staged work text and opt-in native use links. Matched day/dusk and 720p/1080p UI captures, V5/V6 smithy checks and affected regressions pass. Owner discovery review remains pending. |
| 7 Sep 2026 | INT-03A | Shared station previews/body, retained material joins and actual step clearance corrected. Two paid homes, three class journeys, save/storage checks and matched rendering pass. Earlier first-home evidence is corrected to require actual entry. Owner comfort review remains pending; separate placement/save findings are recorded. |
| 7 Sep 2026 | INT-03B | Owner approved the next slice. Complete native footprints refuse buried ends; station kits clear built obstructions; optional validated door poses survive saves. Focused and affected regression evidence is recorded in the work item. Owner comfort review remains pending. |
| 7 Sep 2026 | INT-04A | Owner continued to the next slice after confirming main publication. Accepted resource work, release, actual hauling and local manual craft gain distinct short sounds; visual/save refreshes stay silent. Bounded voices, exact native ownership, station response, first-home journeys and rendered evidence pass. Cold synthesis cost is recorded separately; human listening remains pending. |
| 7 Sep 2026 | INT-04B | Owner said "Continue on !". Six grounded contact textures and four quiet existing-biome beds now use actual support and shelter. Narrow-edge contact sampling corrected; slopes, pauses, saves and trial transitions verified. Separate voice budgets, historical profiles, listening samples and matched walking timing are recorded. Human listening remains pending; INT-05 is next. |
| 7 Sep 2026 | INT-05A | Owner said "Yep let's do it". Buried branch plaques, indistinct fixture states and overlapping hostile tells are corrected. Live fixture navigation resolves a reproduced boss/conduit obstruction; fixed floor caching reduces event rebuilds to about 4–5 ms. Actual 815 m walking, both-floor equivalence, full lifecycle and matched rendering pass. Owner visual/comprehension review remains pending; INT-06 is next. |
| 7 Sep 2026 | INT-06A | Owner said "Continue". Exact native readiness and load amounts replace apparent readiness without supplies; short feeder pages retain live controls and separate input, held work, drive and output. Fuel-only visuals corrected. Actual buttons, full native/save regressions and 72 matched captures pass; bounded timing stays within the 10% regression threshold. Owner usability review remains pending; existing V6 preparation costs are the next candidate. |
| 7 Sep 2026 | INT-07B | Owner said "Yes continue" and continued the measured pass. Equivalent cave/clearance computation, collision setup and unchanged leyline reuse preserve 64 full worlds and 84 mesh payloads. Native generation improves 57–58%; full setup 36%, pending-work p95 23% on the matched rendered route. Collision, excavation, finite state and save checks pass. Occasional long frames and long-session reliability remain recorded limits. |
| 7 Sep 2026 | INT-07C | Owner said "Yep continue". Damaged saves now recover a validated previous checkpoint explicitly; invalid building sets reject before live changes, and subsequent normal saves retain the good backup. Sixteen generated-home circuits over two seeds, two fresh-process recipe completions and affected historical/trial checks total 9,188 passing assertions. Matched normal-load median changes less than 1%; no scene-node accumulation observed. Human review and remaining rendered travel spikes stay separate. |
| 7 Sep 2026 | INT-07D | Owner said “Yep keep going with optimisation”. Resource-highlight shader preparation removes the measured renderer pause; lazy scene retention and equivalent batched leyline assembly reduce repeated work. Two final seeded routes improve worst frames 44–48%; 470 resource-state hashes and 155 leyline hashes match, with historical/streaming/harvest/save checks passing. Ordinary frame rates remain near the cap; remaining collision/scenery bursts and human review stay open. |
| 7 Sep 2026 | INT-07E | Owner said “Perfect, continue”. Collision preparation and non-colliding leyline updates now use separate work slots; ordinary resource creation also respects a 2 ms soft budget. Exact terrain/resource/leyline output, interrupted publication, simulated 30/60 fps coverage, historical geography and four home/save circuits plus fresh restart pass. Final matched worst frames improve 20–22%; an earlier unattributed gap and remaining focus/retirement bursts stay explicit. Owner review remains pending. |
