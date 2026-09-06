# The Strange Frontier: generation and terrain delivery

Historical V3 implementation evidence. The approved [Wide Frontier successor](../prototype/wide-frontier-intensive-2026-09-06.md)
now owns fresh-world size and nearby terrain retention. V3 geography and this
record's original measurements remain unchanged.

Implemented from the owner-approved [rare-world intensive](../prototype/rare-world-intensive-2026-09-06.md).
The new `frontier_v3` world is 512 × 512 metres with the existing 48-block
vertical budget. Rootvault Wildwood, Lantern Fen and Glasswind Uplands have
continuous 120–128 metre cores and 18–20 metre terrain transitions. They occupy
optional outer country; the starter supply radii, three material habitats and
Forge journey remain close to their earlier travel distances.

`worldgen.json` owns the new profile. Existing worlds use their own frozen
placement inputs: `worldgen-legacy-v1.json` and `worldgen-frontier-v2.json`.
The original terrain generator remains `worldgen_legacy_v1.inc`; the exact
previous habitat composition is now `worldgen_frontier_v2.inc`. New region,
cave and rare-site composition lives separately in `worldgen_frontier_v3.inc`.
Neither existing profile receives rare deposits or larger dimensions.

The compatibility fingerprints were recorded before changing live tuning.
They cover every block, biome, resource position, landmark, pack member, elite
and patrol destination, and remain exact after the implementation:

| Seed | `legacy_v1` | `frontier_v2` |
| --- | --- | --- |
| 1 | 9567315995627226133 | 18023770114133595108 |
| 7 | 5936621565493496066 | 18150026021804392173 |
| 24 | 13276267164882187656 | 5053789636092139205 |
| 91 | 9716464632784557402 | 18363030457363895559 |

Each rare type has two to four primary sites. Zero to two additional exceptional
sites share a global world budget. A complete site contains a reserved working
circle, an intact finite specimen, a connected approach from spawn and several
grounded clues along the final 28 metres. Sites alternate between their suitable
regions before falling back to another suitable regional footprint. None uses
an ordinary meadow fallback. Repeated site IDs depend on resource identity and
the explicit primary/exceptional slot, independently of definition ordering and
scene activation. Raw material IDs are `lanternheart`, `thrumroot`, `stormglass`,
`pullstone` and `ventlung`; their source definitions carry property tags, staged
interaction labels and a use preview. All five are visible in era one and need
only ordinary contextual work. The existing copper/tin and later ore era gates
remain unchanged.

Ordinary hauls supply 4 Lanternhearts, 3 Thrumroots, 4 Stormglass tubes,
3 Pullstones or 3 Ventlungs. Exceptional compositions contain twice the intact
haul, with no machine-efficiency grade. The first primary site of each type has
a quiet approach; some additional detours have small ordinary biome guard packs.
Guard placement excludes every clue lane and working circle. The larger area
does not multiply all population counts: outside 145 metres, separate stable
hashes retain 28% of ordinary resource nodes and 30% of packs. New sites and
existing progression guarantees are placed and checked independently.

The Rootvault includes a carved, walkable cave entrance and roofed chamber.
Its seven-metre-wide initial approach and descending stair use ordinary terrain
blocks; each route point has ground and headroom. The final 21 `cave_approach`
points describe the authored cave stair, preceded by its validated surface walk.
Existing habitat routes are refreshed after carving so the new passage cannot
invalidate a previously accepted approach.

The native suite `tests/sim/test_strange_frontier.cpp` passes **2,201,784 checks
over 64 seeds**, including sequential seeds and widely spaced 64-bit identities.
It checks exact frozen fingerprints, grounded finite sources, route continuity
and headroom, broad regional cores, real underground access, definition-reorder
stability, complete rare hauls, primary/exceptional budgets and retained starter
supplies. The measured Forge approaches stay between about 170 and 211 metres
for this seed set. Seed coverage is finite; future generation edits must retain
the deterministic guarantees rather than treating these examples as all worlds.

## Nearby geometry and a complete horizon

The entire native block field and resource records remain authoritative.
`TerrainChunkStream` builds exact surface/cave meshes and collision near the
player; an eight-metre sampling of the same native heightfield supplies the
distant skyline. A 32 × 32 visibility mask hides the far approximation wherever
exact detail is visible. It supplies no collision or invented geography.

Initial detail covers 128 metres, travel preparation covers 144 metres and a
176-metre keep radius avoids repeated visual changes while pacing between places.
These values cover the 120-metre resource activation radius. `ensure_area()`
prepares exact terrain synchronously before teleports and saved poses. Ordinary
travel stages native geometry, surface sampling, mesh creation, ground cover and
collision separately. A chunk becomes queryable only when its collision exists.
Excavation cancels an unfinished payload for that chunk and rebuilds from the
current dug blocks. Excavated chunks retain their exact distant silhouette, so
the coarse horizon never visually refills a player's quarry.

The current implementation caches visited exact chunks and their collision;
it hides distant ordinary detail rather than unloading terrain data. This keeps
the initial cost bounded and avoids re-creating explored ground. Maximum terrain
memory can still approach the complete bounded map after extensive exploration.
Resource scene unloading has its own persistent-record mechanism.

Regional silhouettes can be composed before their distant fine chunks exist:
the art lookup uses the native surface height only for an unloaded chunk. When
exact detail arrives, `StrangeSites.refresh_area()` re-grounds that chunk's
existing instances, including a one-metre border. A loaded chunk with no
support remains an excavation or cave void; it does not fall back to invented
ground. Digging and save restoration perform one deferred re-grounding refresh
after the changed terrain, alongside the existing habitat refresh. The owner's
subsequent [ecological composition refinement](strange-ecology-2026-09-06.md)
preserves existing decorative positions during that refresh, adds denser tiled
regional layers and clears their presentation around placed lattice pieces.

`game/tests/terrain_stream_intensive.tscn` passes **49,837 checks**, including
native-derived horizon vertices, exact collision after a distant restore,
profile identity across unrelated preview queries, unpublished partial chunks,
excavation cancellation, near/far mask changes and excavation restoration.
It also verifies populated distant regional silhouettes before exact chunks
exist, preserved approach clearances and exact re-grounding without horizontal
drift after the fine terrain arrives. This count is from the complete headless
review pipeline, which also passed the 7,067-check resource/save suite.
Its optional `--stream-performance` mode records matched rendered travel routes
and separates active preparation from settled frames. It uses the same daylight,
weathered material, camera height, 5 m/s speed, 1920 × 1080 resolution and 120 fps
cap for both profiles. The route begins at each profile's own spawn; their
geography differs, and this terrain/resource fixture does not measure combat
or the separate regional decorative kits.

Initial headless diagnosis measured about 4.0 seconds to create the new world,
including 242 nearby exact chunks and nearby resource scenes. Building each
complete chunk in one frame cost a median 8.38 ms and p95 14.40 ms. Separating
the work reduced the active construction phase to a median 1.63 ms and p95
5.00 ms over 250 samples. These are diagnostic CPU measurements, not rendered
frame-rate claims; the rendered comparison is recorded alongside the captures
under `build/strange-frontier/terrain-stream/`.

The completed rendered comparison uses Forward+ on an RTX 5090. Its two 30-second
routes reported the following:

| Measurement | `frontier_v2` | `frontier_v3` |
| --- | --- | --- |
| Initial terrain/resources | 9.267 s | 4.183 s |
| Frame median | 8.332 ms | 8.332 ms |
| Frame p95 | 8.411 ms | 8.460 ms (+0.58%) |
| Frame p99 | 8.465 ms | 15.853 ms |
| Static memory reported at return | 1.282 GB | 0.931 GB |
| Draw calls in return view | 2,666 | 1,771 |

The overall median and p95 meet the 10% investigation threshold on this route,
but newly prepared terrain still causes intermittent frame spikes. The 524
frames tagged as active preparation have median 8.320 ms and p95 15.853 ms;
the individual construction phases have p95 5.370 ms and maximum 9.529 ms.
The investigation identified surface sampling, cover creation and collision
construction as separately material costs and split them across frames. That
reduces the previous complete-chunk spike, but does not establish smooth travel
on slower machines or eliminate the measured p99 increase. This remains a
performance limitation, explicitly retained in the evidence rather than hidden
by the settled-frame result.

The two profiles run sequentially in one engine process, so shared asset caches
can benefit the second startup. Memory figures are reported engine static
allocations, not peak process/GPU memory. These differences, different generated
geography and the 120 fps cap limit what the comparison proves. The PNG captures
were visually inspected: near ground remains detailed and the complete distant
heightfield stays coherent with the loaded terrain.

All new generation and activation values have plain-language purposes in
`worldgen.json` and `game/art/strange_stream.gd`. Rendering and generation remain
local, deterministic and bounded; no external package, service, infinite world,
new combat family or unattended resource production was introduced.
