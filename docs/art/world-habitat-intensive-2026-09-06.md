# World habitats: implementation and gameplay review

Owner-approved world intensive, 6 September 2026. Author: Codex (OpenAI).
The [work item](../prototype/world-intensive-2026-09-06.md), D-027, expands
the finite world material vocabulary while preserving its weathered frontier.

All three source habitats exist in new `frontier_v2` worlds. The native generator
chooses complete, supported resource clusters beside an open route from spawn,
with native-biome preference and the documented meadow-edge fallback. Legacy
worlds keep the exact pre-intensive terrain, resources, landmarks and packs;
generation identity and query caches include both profile and seed. Separate
source labels, instance IDs and finished material families prevent presentation
names from becoming inventory or save identity.

Normal-gameplay review exposed and corrected two concrete art faults: the new
strata initially had inward faces, and the fen's first three pool candidates
could all be rejected. Strata now have outward surfaces and a closed underside;
an independent mesh-normal test covers their faces. Fen dressing searches 96
deterministic candidates across the supported footprint, using each candidate's
actual terrain height, and places up to three separated shallow pools. Collision
and resource rules remain unchanged. Ordinary grove pines within the new habitat
use the authored broadleaf silhouette, with taller resinheart resources and
separate bark-bearing trunks. Leaves show restrained movement and transmitted
skylight while the gathering floor remains open.

Seed 1 demonstrates these places without changing the new-world seed:

| Place | Surface cell | Guaranteed approach |
| --- | --- | --- |
| Rustwater Hollow | (66, 14, 154) | 107 connected surface points |
| Resinheart Grove | (201, 17, 251) | 133 connected surface points |
| Shellcut Escarpment | (92, 20, 228) | 137 connected surface points |

The review fixture records matched daylight/dusk views, six source-material
views, shallow water, and twelve player-height positions along each approach.
The interactive local gallery is `build/intensives/world/index.html`; the raw
PNG files and `manifest.json` sit beside it. These are gameplay renderer captures,
not concept images. The [material review](world-material-intensive-2026-09-06.md)
covers the three example buildings, their surfaces, authored imports and matched
legacy field-route performance.

`tests/sim/test_world_intensive.cpp` passes 595,376 assertions over 64 seeds,
including complete legacy fingerprints at seeds 1, 7, 24 and 91, source identity,
determinism under definition reordering, reachable clear approaches, source
grounding, starter guarantees and the material/form matrix. The actual-world
engine fixture passes 5,939 headless checks: profile restoration, old/unknown
profiles, six contextual harvest loops, depleted and partially worked sources,
excavation, material buildings and atomic disk saves. Each test writes only its
isolated `build/intensives/world/checkpoint.json` and backup.

The final rendered fixture passes 6,043 checks with no failures and produces 49
images. It also rejects nine malformed world/checkpoint variants before changing
the economy, player pose, resource set or generation identity. Startup resume and
ordinary loading both recover a valid previous file if a synced current file is
truncated. Required collection, lattice, resource, station, pose and suspended
combat fields are checked before world restoration begins.

Performance review uses identical camera transforms in the dense grove under
frontier and legacy profiles, a thirty-frame warmup and 150 measured frames.
The final capture manifest records startup, median/p95 frame times, draw calls
and primitives. The measured comparison is:

| Measurement | Legacy | Frontier | Change |
| --- | ---: | ---: | ---: |
| Terrain startup | 9.674 s | 9.357 s | −3.28% |
| Dense grove median | 6.942 ms | 6.946 ms | +0.06% |
| Dense grove p95 | 7.490 ms | 7.626 ms | +1.82% |
| Draw calls | 1,233 | 1,264 | +2.51% |
| Rendered primitives | 2,521,357 | 3,289,767 | +30.48% |

The added canopy increases geometry cost; frame times remain below the 10%
regression threshold in this matched view. These measurements describe the test machine's Forward+
renderer (RTX 5090); lower-spec performance still needs a matching hardware run.
The existing field-route regressions stay below the requested 10% threshold.
Certificate-store and optional shader-cache writes are denied in the tool
sandbox; they do not prevent the completed gameplay renders.

No new hydrology, renewable nodes, discovery currency, recipe gate, structural
simulation or timber-demolition rule is introduced. The existing terrain and
ordinary distant foliage retain their established stylisation; this intensive
adds composed resource places and architectural range within that visual style.
