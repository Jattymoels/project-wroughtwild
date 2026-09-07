# INT-03A — A home you can build and use

Status: **Implemented, owner review pending.** Baseline: `db6674b` on main.

The owner approved continuing after INT-02A, with home/workshop placement,
joins and comfortable interiors next. Ordinary main commits/pushes remain
authorised. Owner playtesting is deferred while away; verification uses copied
projects and separate save paths.

## Outcome and boundaries

Build and use two complete examples with the existing catalogue: an early
timber shelter and a developed mixed-material workshop. Placement previews must
describe what will stand there, changing a wall material must update its joins,
and enough physical headroom must exist for actual entry and station use.

D-017's lattice and D-018/D-027's material rules remain authoritative. Preserve
costs, refunds, shape dimensions, existing station bodies, roof unlocks and
shelter semantics. No new forms, furnishings, auto-build action, structural
simulation, demolition policy, recipes or automation network is included.
The earlier proposal to lower station bodies is not adopted by this slice.
The recorded timber-demolition conflict stays outside it.

## Audit and small implementation plan

1. Preserve the baseline and reproduce concrete faults. Station kits currently
   probe a 1.8 × 1.2 × 1.8 m generic box rather than the existing 0.96 × 2 ×
   0.96 m station body. A nearby station can therefore reject a one-cell
   neighbour that would fit. The world ghost also differs from catalogue art.
2. Use the existing station body and actual shared current-tier mesh for station
   placement and inspection. Clear stale selection materials and keep rotation,
   anchor, kit payment, physical station access and saves consistent. This does
   not change the body's dimensions or introduce station dismantling.
3. Refresh existing corner-trim materials when native adjoining-family results
   change; use the same door/frame material roles in catalogue and world.
   Keep native trim selection, costs, poses and collision unchanged.
4. Audit real walking and headroom in the two homes. The earlier first-hour
   fixture proves an enclosure through teleported probes but puts a 1.92 m
   capsule under a nominal two-cell slab ceiling. Replace any impossible review
   layout with an ordinary build that physically fits; reproduce suspected
   shallow-step rejection before choosing a movement correction. Preserve the
   existing maximum step, capsule and collision dimensions.
5. Verify complete paid builds, real door/station/chest interactions, walking,
   shelter, storage and save/load; inspect daylight/dusk and placement captures.
   Run affected regression scenes and measure representative interior rendering.

No new gameplay decision is needed for correcting preview mismatch or stale
materials. If walking reproduction requires a new movement ability or collision
policy, record that separately rather than invent it to pass a fixture.

## Systems and evidence

Affected systems: GridPlacement, StationSite and its existing body resource,
BuildPalette/BuildThumbnail, player step-up only if reproduced, and focused
home/material review fixtures. Native construction and world tuning remain
unchanged. Any new presentation value must carry its plain-language purpose.

Evidence stays under ignored `build/home/`. Authored inspection ground isolates
building geometry; existing generated-world first-hour checks cover the real
resource/station chain. Fixed review stock and the existing roof unlock may be
supplied to demonstrate a developed house; that is not pacing or economy
certification. Scripted walking and rendering do not establish human comfort
or final graphical quality. The owner can review those later.

## Separate findings

The audit also identified existing behaviours for a later bounded
placement/save slice: terrain refusal tests the anchor rather than every
occupied element (off-grid long/tall pieces can extend into rock), and restored
doors currently close rather than retaining their open pose. Ordinary station
kits also retain the existing PlacedBlock exclusion: a built slab or beam above
the one-cell registry stand-in can overlap the station body. Shared body extents
correct station-to-station fit and ordinary prop checks, but do not close that
separate built-ceiling loophole. Supporting faces and D-017's intentional
element-based piece overlaps must be distinguished in a follow-up. They are recorded
for reproduction and a concrete correction; none is silently changed here.
The current home evidence does not certify those cases.

## Delivered behaviour

Station ghosts now show the actual bench, yard or forge at the eventual floor
anchor and yaw. The original body is a shared resource instead of a mismatched
preview constant; adjacent one-cell stations can be placed and paid normally.
An upgraded forge appears in both previews, including a retained selection
after upgrading or loading an earlier save. Window surface overrides no longer
leak onto a subsequently selected station or fixture.

Existing corner posts now follow changes in their native adjoining family;
removing timber beside surviving stone changes the retained post immediately.
Catalogue doors, posts and beams use the same surface treatment as placed pieces.

The baseline movement check reproduced a half-metre step blocked under a 2.45 m
ceiling despite sufficient room for the 1.92 m capsule. The player now finds the
actual walkable top at the blocking contact and sweeps the required lift/stride.
Straight and diagonal approaches pass; insufficient ceilings and a 0.75 m wall
remain blocked. An initial correction exposed wall climbing, which was fixed
without relaxing those controls. Capsule, maximum step and landing clearance
retain their existing values; no new movement ability or tuning was introduced.

The generated-world first-hour fixture now pays for a physically enterable
46-wood home and walks through its real door. This corrects earlier evidence:
the old two-cell slab layout established shelter through an interior teleport
but did not physically fit the player. Optional guide detail now explains
headroom above the walking floor and a flush threshold.

## Verification and reproduction

Godot 4.5 stable ran serially in copies under ignored `build/home/`, with separate
APPDATA. No ordinary saves or ongoing game sessions were used. The baseline was
preserved before production edits and received only the common review fixtures.

| Check | Result |
| --- | --- |
| `home_station_placement` | 98 passing checks: three kit types, four rotations, actual ray ghosts, adjacent payment, occupied/overhead refusal, prior window materials, retained upgrade/load selection and exact original restored bodies. The final fixture reproduces 41 baseline failures; its check count differs because failed placement leaves fewer saved stations. |
| `home_material_joins` | 141 passing checks: retained mixed corners through changes and repeated saves, unchanged native population/geometry, and nine catalogue/ghost/placed material cases. |
| `home_headroom` | 30 passing checks; the same final fixture fails four baseline assertions for straight/diagonal tight-ceiling entry. Height, insufficient clearance and taller-wall controls remain. |
| `home_workshop_review` | 1,027 headless / 1,049 rendered checks, passing on current; the matched baseline rendered run also passes 1,049. Two paid homes contain 302 pieces, six stations and two independent stores. Actual E, stair walking, capsule working positions, door collision, shelter and atomic save restoration pass. |
| `first_hour_journey` | 290 passing checks each for Ranger, Warden and Kindler in actual V6 seed 77, with no inventory or station grants. Travel/pickup timing is accelerated and hostiles are disabled; this does not establish pacing or combat balance. |
| Existing-world `exploration_review` | Baseline 102 / current 111 passing checks, including unchanged native fingerprints and the established route. |

Affected regressions pass: build usability **39**, materials **158**, integration
**273**, feel **17**, crafted terrain traversal **23**, horde **43**, establishment
guide **138**, panel density **60**, pressure workshop **60**, contraptions **85**.
The four new scenes are registered in the ordinary headless pipeline. Native
rules/tuning did not change; no native rebuild was required. Fresh isolated
import and `git diff --check` pass.

The full-home save comparison also reproduced Godot sanitizing auto-generated
`@` node names on restore in the untouched baseline. Its assertion now applies
that same engine name conversion and still compares every saved station field,
including stable identity, ownership, parent, exact position and orientation.
No production save field or ownership behaviour was changed to satisfy it.

Reproduce with `tools/home_review.ps1 -Prepare -Import`. Add
`-Scenes home_workshop_review -Rendered -ExtraArguments '--home-capture'` for
the matched inspection scene. `-Phase baseline` reuses the preserved baseline;
preparation refuses to overwrite it. For class journeys select
`-Scenes first_hour_journey -ExtraArguments '--journey-class=ranger'` (or Warden/
Kindler in lowercase). Engine windows are hidden/offscreen and bounded; the
helper stops only its own child processes on timeout or script failure.

Ten images per phase live in `build/home/{baseline,current}/captures/home/`:
day/dusk interiors/exteriors and one actual station ghost per home. The local
comparison gallery is `build/home/index.html`. Rendered `manifest.json` and
`manifest-headless.json` stay separate so routine checks preserve visual
evidence. Inspection stock and the existing roof unlock are disclosed; the
review scene adds no player-facing automatic building action or furnishing kit.

## Performance and remaining review

Home views use Forward+ at 1280 × 720, FOV 75, fixed cameras, disabled VSync,
90 warm frames and 600 measured process-frame intervals; screenshot readback is
outside timing. These two completed homes use the same placed counts and draws
before/after. Measurements are isolated static presentation samples on this
machine, not large-settlement or lower-end hardware certification.

| Home view, daylight | Baseline median / p95 ms | Current median / p95 ms |
| --- | --- | --- |
| Early timber exterior | 0.908 / 0.986 | 0.902 / 0.946 |
| Early timber interior | 0.739 / 0.813 | 0.733 / 0.785 |
| Developed exterior | 0.664 / 0.723 | 0.660 / 0.713 |
| Developed interior | 0.509 / 0.595 | 0.503 / 0.554 |

All eight home daylight/dusk median and p95 comparisons stay below the ten
percent regression threshold. Draw counts remain 1,587/1,248 for the timber
views and 1,215/704 for the developed views; larger settlements remain unmeasured.

The existing generated-world route also ran at its original 1440 × 900 settings.
The first pair showed a smithy p95 increase of 17–23% with identical draw counts
and 7,871 ms world setup in both versions. Both initial manifests are retained
as `manifest-initial.json`. A serial repeat without concurrent image inspection
did not reproduce that increase: world setup **7,784 → 7,703 ms**, terrain
**7,225 → 7,147 ms**, smithy daylight median/p95 **0.796/0.924 → 0.774/0.903 ms**,
dusk **0.793/0.933 → 0.788/0.914 ms**. Ventlung dusk p95 increased **7.5%**;
all repeated startup/median/p95 increases stayed below ten percent. This supports
run-to-run variation, not a claimed performance improvement. V6 preparation cost
remains tracked under INT-07.

Owner review remains deferred: making a home, recognizing its entrance, comfort
in a small room and eventual graphical finish still need human judgment. The
authored examples expose the existing material range; their flat inspection
ground does not certify all terrain slopes or seeds. The separately recorded
placement/save cases above are now addressed by [INT-03B](home-placement-persistence-2026-09-07.md) before the queued
sound/interaction-feedback brief. No combat calibration, new generation,
farming, furnishing catalogue or larger automation is implied.
