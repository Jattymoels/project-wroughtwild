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
| INT-03 | Building and home development | Complete houses/workshops expose and resolve awkward placement, joins and interior usability. | Queued. The catalogue, materials and wall forms already exist. A furnishing kit is a separate content selection; farming is not included. | Is making and using a home comfortable and expressive? |
| INT-04 | Sound, animation and interaction feedback | Existing gathering, footsteps, stations and surroundings gain consistent material and state feedback. | Queued for presentation/asset brief. Use the established local pipeline; new external assets/services require an explicit choice. | Do feedback and ambience feel convincing through repeated use? |
| INT-05 | Dungeon presentation and traversal | Existing Forge rooms, junctions, secrets, transitions and boss tells are easier to read and traverse. | Queued. The [Forge arc](trial-intensive-2026-09-06.md) already exists. Identify spatial/readability gaps without changing combat numbers. | Do routes and tells make sense, including under Foundry effects? |
| INT-06 | Workshop usability | The existing finite feeder clearly communicates inputs, output, stored work, source exhaustion and blocked states. | Queued. Demonstrate the existing [pressure-to-brick loop](pressure-workshop-2026-09-06.md); broader lines and renewable supply remain separate proposals. | Can the owner build it, diagnose a stop and see why it is useful? |
| INT-07 | Performance and reliability | Measured loading/terrain stalls improve, and long travel, large builds and save recovery stay dependable. | **INT-07A implemented, review pending:** [loose-drop persistence](loose-drop-persistence-2026-09-07.md), following the reproduced loss/duplication. The [V6 preparation cost](wide-frontier-intensive-2026-09-06.md#measured-cost-and-remaining-preparation-regression) remains tracked separately. | Do saving and ordinary play remain dependable and smooth? |

Suggested sequence: **INT-01 first**, then INT-02; INT-07 can accompany those
when its changes and measurement workload are independent. Follow with INT-03
and INT-04, then the focused INT-05/INT-06 refinements as review exposes needs.
This is a working priority order, not a promise to run every item automatically.
The loose-drop issue reproduced during INT-01 was handled first as INT-07A.
INT-02A now has isolated gameplay captures and functional evidence. The next
queued brief is INT-03: audit actual home/workshop placement, joins and interior
use before choosing a bounded fix. Owner playtesting remains deferred while
away and does not block that audit.

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
