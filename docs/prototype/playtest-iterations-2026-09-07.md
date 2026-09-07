# From owner playtest to the next intensives

**Status:** Plan ready. The owner requested planning on 7 September 2026 after
finishing their notes. This records requested outcomes and proposed implementation
slices; it does not claim fixes, approve unspecified mechanics or select final
tuning. Baseline inspected: `75dc399`.

This round takes priority over the previous general convenience/export proposal.
Each slice is delivered with its own implementation evidence and ordinary checked
main-branch commit/push. Human testing is not required to begin reproduction,
instrumentation or an initial candidate; enjoyment and final tuning remain human
judgements. Preserve the owner's current game, saves and running processes.

## Complete feedback ledger

| Owner observation / request | Planned response |
| --- | --- |
| Every block placement produces significant lag, especially beside a hill. | INT-03C: measure placement frames and their immediate/deferred work on flat ground and slopes. |
| Ambient sound drawls continuously and is annoying. | INT-04C: remove the persistent drone from the default mix; develop restrained intermittent ambience and a mute control. |
| Shellstone country seemed nearly mob-free except for a stone husk. | INT-02C: distinguish generated population, activation, navigation and deliberate quiet areas. |
| Explain selecting mastery. | INT-01B: distinguish automatic skill practice, class specialisation and freely arranged rail patterns. Plain-language explanation below. |
| Pack limits make building frustrating; constantly gathering trees for a small house. | INT-03D: larger common-resource loads, plus a separate house-cost/yield audit. |
| CURRENT FLOW is unreadable; the workings on the right are useful. | INT-01B: repair the flow inspection area while preserving the useful workings panel. |
| No armour and two ingots plus a catalyst leave little danger in the trial. | INT-05B/C: enemy contact, encounter pressure and a controlled early power comparison. |
| Hounds do little; ranged attacks are easily avoided. Suggest reach/projectile speed changes. | INT-05B: inspect pursuit, attack commitment, reach and projectile travel before selecting values. |
| Tighter spaces and much greater pack density could improve trials. | INT-05B: concentrate encounters within existing modules and use staged mixed reinforcements. |
| Workbench should fit in the photographed corner. | INT-03C: match station preview, anchor and body fit against the actual wall/floor geometry. |
| Magnetic sorter and a kit called glassstone disappear when placed. | INT-03C: test every contraption kit through normal placement; second identity is unconfirmed. |
| Second screenshot is too barren/bare. | INT-02B/C: regional composition and population, measured at player height and across distance. |
| Enjoyed finding ruins and following veins towards discoveries. | Preserve this exploration loop and finite discovery payoff throughout the world pass. |
| Early melee is hard and slow; hit/kill recovery makes it better; movement/dash needs more. | INT-05C: compare early tempo, recovery and movement alongside power progression. |
| One Foundry upgrade makes poor gear too strong; adjust enemies and perhaps player scaling without losing cool interactions. | INT-05C: retain behaviour identities; separate damage, coverage and sustain contributions before numerical changes. |

The attached screenshots are retained as unedited owner evidence:
[corner placement](references/playtest-2026-09-07-corner.png) and
[barren landscape](references/playtest-2026-09-07-barren.png).
Image 1 shows a red workbench preview and a building-obstruction refusal; it does
not prove which collider caused rejection. Image 2 shows a sparse, dark landscape;
darkness alone does not explain the reported lack of detail. Neither image
identifies the exact seed, world profile, position, class or trial conditions.
Those are unknown, not prerequisites for investigating representative cases.

## Intensive A — Build comfortably and keep what you place

### INT-03C: placement transactions, corner fit and frame stalls — first

Owner implementation instruction: continue only this bounded slice from planning
commit `80dde32`, verify, update the queue, commit and push. Current evidence and
uncertainties: [INT-03C implementation record](placement-reliability-2026-09-07.md).

**Outcome:** legal corner placement works, paid fixtures remain visible and usable,
and placing a block does not repeatedly interrupt building.

1. Preserve a baseline. Build identical small/large homes on flat ground, a slope
   and excavated ground. Record the click frame and following frames separately
   from ordinary walking. Trace native placement, terrain queries, trim updates,
   scenery clearance, shelter work, collision publication and rendering.
2. Reproduce the photographed wall corner with the current station dimensions,
   both lattice scales, four rotations and floor variants. Correct anchors or
   excessive refusal where demonstrated. Preserve genuinely blocked ceilings,
   movement/projectile collision and honest previews; do not simply ignore walls.
3. Exercise all fixture kits through the actual build controls, including sorter,
   Stormglass lever and other possible matches for the unidentified kit. Verify
   payment, native registration, scene creation, pose, visibility, interaction,
   scene reload, save/restore and dismantling. Investigate below-ground placement
   and missing visuals as well as failed spawning. A failed placement must retain
   the kit; a successful one must create exactly one usable fixture.
4. Optimise the reproduced expensive placement work while keeping immediate
   collision/ownership correct. Restrict cosmetic refresh to affected areas where
   evidence supports it; verify eventually cleared scenery after rapid building.

**Evidence:** matched per-placement median/p95/worst frames and time traces;
normal-control kit cases; corner screenshots and actual capsule/ray checks;
exact inventory/machine/source accounting before and after restart. Review any
remaining visible stall rather than accepting a percentage improvement alone.
Do not refund the owner's reported kits automatically without establishing what
exists in their save.

**Affected:** `grid_placement.gd`, station/contraption presentation, native machine
placement, scenery clearance, shelter/terrain queries and save validation as
reproduction warrants. D-010/D-017/D-031/D-032 and construction/world specs apply.
The existing full trim/scenery refresh is a lead, not a diagnosed root cause.

### INT-03D: a useful building load

**Outcome:** carry enough ordinary resources to make meaningful progress on a
small home without constant hauling interruptions.

Measure the actual bill for a modest paid home and workshop, refinement losses,
harvest work, carried capacity and chest transfers. Current `world.json` caps
wood at 60, many common materials at 40 and chest contents at 240. Compare larger
common-material capacities against that bill; choose and explain an initial
candidate before editing. Keep special-item caps, equipment, finite deposits,
pickup leftovers and trial/death ownership intact. Check whether chest capacity
needs a corresponding increase; preserve stored quantities in all cases.

Carry capacity reduces trips, not the number of trees needed. Report excessive
house costs or poor yields separately; do not quietly change all three factors
together. Validate real gathering/refining/building, full-pack collection and
storage/save boundaries. Relevant tuning: `world.json` hauling, and construction
and crafting costs only if a separate measured revision is selected.

## Intensive B — Quiet sound and readable choices

### INT-04C: retire the drone

**Outcome:** the world leaves room for work, footsteps, danger and discovery.
First remove the rejected continuous bed from the default listening experience,
with an explicit ambience mute/level control. Then audition short, irregular,
locally appropriate textures with meaningful quiet gaps. Avoid invented creature
or machinery cues that imply gameplay objects. Retain useful work/collection
feedback and distinguish ambience from critical combat signals.

Review several minutes of meadow, exposed stone, vegetation and shelter at normal
volume, including gathering and fights. Verify transitions, bounded voices,
mute persistence and unchanged gameplay RNG. Existing synthesized audio can be
reworked locally; no external audio package is assumed. `environment_sound*`,
the listener and preferences are the affected presentation systems under D-013.
Human listening acceptance remains open; a waveform test cannot establish it.

### INT-01B: Foundry flow and mastery explanation

**Outcome:** inspecting a cell gives a readable consequence without covering the
plate or losing the useful workings panel. Reproduce CURRENT FLOW with short and
long mutation paths at 720p, the supplied image sizes and 1080p. Give the section
adequate contrast, wrapping and independent scrolling; summarise the selected
path and put extended detail behind an intentional action. Preserve preview
versus current-state distinction, costs and actual native effect descriptions.

Explain the current rules consistently in the appropriate panels:

- **Skill mastery is automatic:** qualifying use earns practice and unlocks the
  listed milestones. It is not a choice between perks. Empty casts and automatic
  repeats do not supply practice under the current meaningful-use rules.
- **Class specialisation is the one-time choice after the Tyrant unlock:** it
  evolves the class's rail patterns. Warden offers Bulwark or Sentinel; Ranger
  offers Sharpshooter or Fletcher; Kindler offers Pyromancer or Hearthkeeper.
  Show what changes before committing, and make permanence visible.
- **Rail patterns are arrangements:** known patterns can be set/cleared freely
  within the existing limit. Their line conditions must hold for their effects
  to apply. Choosing a specialisation does not make all rails active everywhere.

The owner's exact screen meant by mastery is unknown; these distinctions avoid
assuming which of the three they meant. Preserve the existing progression rules.
Verify real selection/inspection controls, long-path layouts, no browsing spend,
and before/after native effects. Affected: `foundry_panel.gd`, build/skill guides
and interface wording under D-023/D-025/D-026; no new currency or mastery system.

## Intensive C — Threatening encounters and earned power

### INT-05B: enemies that can create pressure

**Outcome:** hounds can threaten an inattentive player and ranged enemies constrain
movement while remaining dodgeable. Test contact before increasing damage.

Use fixed open-ground and existing Forge-module encounters. Record pursuit,
navigation, capsule-to-target distance, wind-up start/commit/release, actual hit
distance, attacks attempted/landed and projectile travel. Compare stationary,
straight-retreating and actively evading players. Distinguish a broken attack
from an appropriate successful dodge; preserve spatial projectiles and cover.

Then redress encounter positions within the eight existing modules: tighter
occupied fighting areas, useful cover and mixed melee/ranged/support roles with
readable reinforcement groups. Increase pressure within the existing 24 active
enemy and two-major-hazard limits first; more total enemies can arrive over time.
Keep traversable paths, optional-room independence, exits, lifts and boss space.
Do not add lock-in rules, new rooms or raise the caps implicitly.

Validate real combat contact and corridor navigation, with full route and
suspension regressions. Compare dense-fight performance to a matched baseline
and investigate regressions over 10%. Relevant sources include enemy/trial
controllers, navigation, `world.json`, `combat_realtime.json` and `trial.json`;
put each range, speed, timing and population revision in documented tuning.

### INT-05C: the first upgrade reveals a build; progression strengthens it

**Outcome:** preserve proliferation/catalyst identities while making equipment
and subsequent investment matter. Preserve a workable early melee opening.

Use the same legal skill, poor gear, starting life, route and conditions for a
before/after comparison of two ingots and one compatible catalyst. The owner's
exact arrangement is unavailable: label representative cases explicitly. Include
clear-focused proliferation, single-target and recovery-focused cases, then
prepared and developed gear. Cover Warden, Ranger and Kindler; temporary boons
remain identical or absent during causal comparisons.

Measure direct damage, secondary damage and coverage, effects triggered, damage
received, hit/kill healing, kill/clear times and boss-tell exposure. Check duplicate
procs or unintended scaling before treating them as balance. Larger packs may
amplify both proliferation and kill-healing, so density alone may worsen the spike.

Tune in recorded, separate steps: contact/pressure from INT-05B; enemy durability
and damage where justified; excessive early player multipliers, inherited
secondary damage or sustain where demonstrated. Retain distinct behaviours and
payoffs. Avoid a universal player nerf that worsens the already slow opening.
Review melee movement/dash distance, recovery, responsiveness and attack recovery
against actual tells. Movement-only dash remains the baseline; invulnerability,
animation cancelling or extra charges require an explicit new decision.

Initial candidates aim for visible preparation benefits and meaningful threat to
an unarmoured character, not guaranteed failure. Run full story attempts and
repeatable tiers 1–10 with reported limits after focused comparisons; the existing
20-/10-minute run targets remain provisional. Automated combat checks can expose
failure modes, but final difficulty/build satisfaction waits for owner review.
Affected: combat/Foundry/grammar/skills/items and enemy/trial tuning under
D-010/D-012/D-025/D-028. No removal of the approved interaction vocabulary.

## Intensive D — A frontier worth inhabiting

### INT-02C: explain and repair empty stretches

Audit native pack counts, regional/biome mapping, starter exclusions, activation,
despawn and pathing along quarry/shellstone approaches. Shellstone is a resource
habitat, not proof of a separate enemy biome; identify the actual underlying
region before changing its roster. Use several existing seeds including 1 and
77, distance bands and day/night states. Separate missing spawns from intentional
quiet ground or a sparse distribution. Preserve the calmer starter catchment.

Fix demonstrated runtime failures under current rules. If den placement or
generation density must change, propose a versioned generator successor rather
than modifying frozen profiles or silently populating saved geography. Decide
that scope from the audit; a new profile is not already approved here. Produce
player-height population maps/walks and normal enemy activation evidence.

### INT-02B: one finished place, then its reusable surroundings

Develop the existing proposed Blender visual target around an asteroid-struck
pre-cataclysm smithy, its approach and an existing rare host. Work on distinctive
rock/tree silhouettes, clustered understory, weathered ruin materials, ground
transitions, contact shadows and restrained leyline light. Examine foreground,
middle distance and horizon at daylight and dusk. Dense local props alone will
not resolve an empty middle distance like image 2.

Preserve the enjoyable ruin-to-vein-to-discovery journey, clear work areas,
surviving low-tech craft and accidental augmentation. Reuse the approved local
Blender authoring pipeline; no external assets or a new art service. Compare the
complete scene in Godot before expanding its reusable kit to regional variants.
Treat any changed placement footprint/collision or saved generation input as a
separate compatibility decision, not cosmetic licence. Keep finite resources
and their depleted appearances truthful.

Deliver editable recipes/sources, curated exports and appropriate distant detail,
plus matched walks, screenshots, interaction/collision checks and performance.
Owner direction can be reviewed on a phone through images/clips; final approval
in ordinary play remains separate. This develops the existing INT-02B proposal
instead of creating a duplicate graphics intensive.

## Delivery order and stopping points

Recommended sequence: **03C → 03D → 04C → 01B → 05B → 05C → 02C → 02B**.
The population audit and art baseline preparation can occur during independent
work; no autonomous background agents or scheduled jobs are created by this plan.
The broad INT-08A settings proposal follows the urgent audio/UI needs. INT-08B
portable export remains useful but lower priority than reproduced playtest issues.

For each slice record reproduction, selected implementation, plain-language
tuning purposes, exact checks, before/after evidence and remaining limitations.
Use isolated saves and current builds; never use scripted forced kills as proof
of difficulty. Retest the owner's changed experience with a short focused prompt
when they return, rather than asking them to repeat the entire checklist.

No new infinite world, broad automation, production service or progression gate
is included. The prior timber-demolition conflict and era-sensitive gear-preview
follow-up remain separate. This planning turn changes only documentation and
preserves the owner's two supplied reference images; no runtime tests or fixes
are claimed.
