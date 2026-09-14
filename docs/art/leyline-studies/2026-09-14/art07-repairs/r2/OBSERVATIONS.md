# ART-07R2 first use, traversal and retained geometry

The primary startup comparison is in [costs.md](costs.md). Its 24 fresh processes
contain three observations per mode/backend both before and after, with the same
paid checkpoint, cameras, resources and settings. Median setup improved by 35.84%
in Forward+ and 34.83% in Compatibility; the before/after observed setup ranges
do not overlap. Settled frames, per-view focus and warmup stalls are reported
separately in that table and in its raw reports.

Fresh editor import wall times were 85.300 seconds for original `v01`, 70.828 for
timing-only diagnostic `v02`, and 63.085 for candidate `v03`. These are single
import observations, not repeated startup samples or an independently established
import speedup. Source scripts and imported-cache contents differ in the diagnostic
copy. Every benchmark started afterward, in a fresh private process.

## Uncaptured actual traversal

Each row below is one fresh process, using the actual G1 input/controller route.
All six routes completed exactly 135.078021510504 metres without a stalled waypoint.
No screenshots, imports or generation ran in these timing jobs. The inherited
physics settling period remains; recorded intervals start with movement input.
There is one traversal observation per listed condition, so these tails do not
establish a repeatability band of their own.

| Backend / condition | Recorded process frames | Median ms | p95 ms | Worst ms |
| --- | --- | --- | --- | --- |
| Forward+ / original art-off | 12,768 | 1.679 | 4.085 | 22.282 |
| Forward+ / original G1 | 3,947 | 3.823 | 9.443 | 748.767 |
| Forward+ / R2 | 4,571 | 3.637 | 7.615 | 437.400 |
| Compatibility / original art-off | 6,891 | 3.159 | 6.149 | 30.910 |
| Compatibility / original G1 | 2,416 | 7.036 | 25.007 | 746.804 |
| Compatibility / R2 | 2,846 | 6.439 | 10.494 | 456.368 |

Streaming/first-use stalls remain visible in R2. Lower setup and texture allocation
do not mean every traversal frame meets an unapproved performance target. These
are fresh-process observations after import; OS and global driver caches were not
flushed. Raw intervals, route positions and actual engine/device settings are in
each `traversal.json`, distinct from the separately captured motion.

## Actual matched captures and geometry

Thirty camera/light captures per renderer give 60 before/after pairs at 1440 x 900.
Fifty-nine pairs are pixel-identical. The Compatibility `red_home_margin/day` pair
has one colour channel at one pixel differing by one level out of 255; no channel
differs by more than one. No image-generation model or retouching was used. These
are actual runtime outputs, taken at a fixed 60-frame presentation cadence outside
all benchmark windows. Owner visual acceptance remains pending.

Every pair also matches exact resource IDs, positions, finite stock, work progress,
ordered visible/hidden part transforms and full mesh surface-array digests.
The expanded unique geometry inventory includes the scene, retained B3 originals,
AuthoredAssets, D1-D3, E1-E3, G1 cover and C6 LOD caches. Both renderers have the same
unchanged observed ranges across these wider views:

| Retained base geometry measure | Before and after range |
| --- | --- |
| Unique meshes | 1,034 to 1,679 |
| Base triangles | 1,126,091 to 2,674,818 |
| Vertices | 2,709,484 to 6,818,228 |
| Surfaces | 1,195 to 2,047 |

This is a union of reachable unique base meshes, including hidden work stages;
instances are not multiplied. Alternate imported index-LOD triangles are not
added to base triangles. The unchanged loaded buffer ranges in the primary cost
table separately include renderer internals and caches. R2 reduces texture
allocation; it does not claim a geometry or buffer reduction.

Exact duplicate PNG disk bytes are retained. Forward+ texture allocation drops
from 1,307.77 to 867.07 MiB; Compatibility drops from 1,288.49 to 789.82 MiB. These
are actual backend allocations and are distinct from the 1,061,048,169 redundant
PNG bytes on disk. Final comparable runtime and full sealed-package disk sizes
are recorded in `disk-costs.json` and the receipt, including evidence/master overhead.

The comparable production runtime payload grows from 3,438,257,458 bytes in 4,787
files to 3,438,342,971 bytes in 4,789 files (85,513 added bytes). All redundant PNG
files and embedded GLB image bytes remain. This is a measured loaded-texture saving,
with no claimed disk-size reduction. The larger sealed bundle separately includes
original masters, baseline source bytes, logs, images, motion and private test saves.
