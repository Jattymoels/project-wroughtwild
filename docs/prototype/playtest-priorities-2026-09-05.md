# Playtest priorities — 5 September 2026

Owner-approved order, following the normal building/art adoption:

1. **Gathering feedback — paramount.** Clear harvesting progress, stronger
   impact feedback, and understandable material gains. Preserve useful slower
   pacing; each action should communicate work and eventual reward.
2. **Building usability.** Visual shape picker, easier roof/corner orientation,
   and clearer placement failures, including the adopted octagonal pieces.
   Implemented in the [building usability pass](../art/codex-building-usability-2026-09-05.md):
   Tab catalogue, rotation inspection/marker, specific refusals and payment checks.
3. **Combat feel.** Distinct weapon/cast presentation and incoming-hit direction.
   Investigate the ranged-enemy playtest report first within this pass.
4. **Reasons to explore.** Small recognisable encounters around existing
   resources and landmarks, using current rewards and progression.

## Combat observations to carry forward

The owner reports that ranged mobs are the most tedious enemies: they deal a
lot of damage and their attacks cannot currently be dodged in play. This is
player feedback, not yet a verified diagnosis of the collision or targeting code.
Audit wind-up visibility, aim tracking/commit time, projectile travel, collision,
cover, range, overlapping pack fire and damage. Reproduce a stationary hit and a
successful spatial evade with the same enemy before deciding which tuning or
behaviour needs to change. Dash remains movement without invulnerability under
the existing decision; this report does not silently authorise an i-frame rule.

Skills also feel insufficiently distinct. The owner suspects presentation is
part of it, but explicitly wants more skills to test and more variation in **how
damage happens, spreads and covers an area**. A colour swap or another damage
multiplier would not satisfy this. Their PoE comparison is a vocabulary reference,
not a request to copy its catalogue or expand to its content scale.

**Separate intensive design task, deferred by the owner:** review the existing
deliveries and select a small complementary set with distinct targeting, timing,
space control and Foundry interactions. Candidate contrasts for discussion include
an impact projectile, a moving persistent hazard, and a delayed expanding blast.
These are proposals, not accepted skills, costs, unlocks or damage rules. Each
chosen skill should have a recognisable silhouette/motion and a different useful
combat situation; compare them in the same encounter. Decide acquisition and
compatibility explicitly before implementing catalogue changes (D-016, D-023).

## Gathering feedback implementation

The work meter reads the current node's saved `drive_progress` / `drive_presses`,
shows the next ordinary harvest yield, and explains missing wedges or heat. It
clears on looking away, depletion, digging, build mode, death or an open panel.
Successful work produces a short hand gesture and deterministic material flakes
at the real ray hit. Refused work produces neither. Heavy strikes keep their
combat gesture. Cosmetic flakes have no collisions or value and disappear in
flight, rather than leaving loose stones on the ground. Target highlighting now
preserves material colour, with a small brightness lift rather than a white wash.

The completion notice says material was **freed** into a drop. The existing
pickup absorption path alone grants inventory and then reports the gain and
actual carried total. No yield, press count, gather rate, tool cost, skill rule,
save schema, or enemy tuning changes in this pass.

Presentation tuning lives in `game/art/gathering_look.tres` with defaults in its
resource script:

| Parameter | Default | Player effect |
| --- | --- | --- |
| fragment_count | 9 | Number of brief flakes per successful work impact |
| max_bursts | 6 | Limits simultaneous effects during rapid input |
| lifetime | 0.48 s | Time before the impact flakes disappear |
| speed | 1.3 m/s | Initial material scatter strength |
| gravity | 4 m/s² | Downward bend of the cosmetic scatter |
| wood_colour / stone_colour | #a1875d / #89857c | Muted wood and mineral impact colours |
| hover_energy | 0.025 | Brightness lift of an aimed resource; hot glow unchanged |
| hand_seconds | 0.24 s | Visual recovery after a work press; never delays a harvest |
| hand_reach | 0.14 m | Forward movement of the working hand |
| meter_width / meter_height | 300 / 5 px | Compact work bar size beneath the crosshair |

Existing press and yield tuning remains in `data/tuning/worldgen.json`; pickup
aggregation remains 2.4 seconds. Sound, held tools and the separate building UI
pass are still outstanding. The meter predicts the ordinary harvest; a hot
seam's strike shortcut remains explained by its existing target text.

Reproduce with `tools/codex_visual_review.ps1 -Gathering`. The dedicated check
drives normal interaction, progress, gates, partial save restoration, panel/aim
visibility, depletion, delayed inventory absorption and the effect budget.
The rendered review uses a real generated tree with AI paused for inspection.

Validation: the full engine regression pipeline passed, including the dedicated
22 gathering checks. Actual 720p and 1080p chopping captures and the collected
yield capture were reviewed. Existing unit-harness engine warnings remain; no
native rules code or tuning JSON changed, so the native library was not rebuilt.
