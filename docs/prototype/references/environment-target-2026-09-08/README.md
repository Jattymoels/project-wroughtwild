# INT-02B field evidence

These are original 1440×900 Godot viewport captures, not generated illustrations
or repainted screenshots. The [implementation report](../../environment-target-2026-09-08.md)
contains the selected before/after comparisons, checks, costs and limitations.

Each phase/seed directory contains its complete raw `manifest.json`; only a
curated subset of PNGs is checked in. Full captures remain under the isolated
`build/environment-target/{baseline,current}/captures/seed-{77,1}` locally.
The baseline production copy is `a7c3854`. The same review fixture ran on both
versions, including the exact grounded camera checks and continuous path samples.

Seed 77's walk frames show the existing 76 m smithy approach/departure at four
points, with daylight and dusk versions. Frame names refer to native path
segments, not elapsed seconds:

| Segment | Before, day | After, day | Before, dusk | After, dusk |
| --- | --- | --- | --- | --- |
| 0 | [View](baseline/seed-77/walk-day-000.png) | [View](current/seed-77/walk-day-000.png) | [View](baseline/seed-77/walk-dusk-000.png) | [View](current/seed-77/walk-dusk-000.png) |
| 20 | [View](baseline/seed-77/walk-day-020.png) | [View](current/seed-77/walk-day-020.png) | [View](baseline/seed-77/walk-dusk-020.png) | [View](current/seed-77/walk-dusk-020.png) |
| 40 | [View](baseline/seed-77/walk-day-040.png) | [View](current/seed-77/walk-day-040.png) | [View](baseline/seed-77/walk-dusk-040.png) | [View](current/seed-77/walk-dusk-040.png) |
| 60 | [View](baseline/seed-77/walk-day-060.png) | [View](current/seed-77/walk-day-060.png) | [View](baseline/seed-77/walk-dusk-060.png) | [View](current/seed-77/walk-dusk-060.png) |

The scripted camera follows production streaming at fixed simulation steps;
this does not claim a human played the route or judge its discovery/difficulty.
The two original 7 September owner screenshots remain in their original paths.
