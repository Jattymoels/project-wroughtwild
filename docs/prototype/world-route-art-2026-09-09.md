# ART-05 — One existing Red world route

**Technical route pilot delivered; owner visual review pending — 9 September 2026.** The owner approved Green:
“Love it, continue”, selecting the next [roadmap](leyline-asset-roadmap-2026-09-09.md)
slice. This is the first bounded world integration; broader reuse follows its checks.

## Outcome and selected footprint

Fit the approved ART-01 boar, ART-02 trees/rock and ART-04 Red source/material/buffer
to their existing owners in an actual isolated Living Frontier world. Preserve
resource records, native collision, gathering, source claims, paid placement,
attack warnings, status priority, streaming and full-save restoration.

The seed-77 LF-3 footprint inspection found the Red source at (469.5,31,438.5),
its existing boar habitat at (463.5,47,348.5), and their native source route.
There are 24 tree and 25 boulder records within 24 metres, alongside seams and
one iron vein. The candidate old smithy is at (216,28,660), far from this source;
using it would not demonstrate the existing source/animal relation. The Red
route therefore supplies the bounded pilot. No source, animal or resource moves.

The smaller native tree silhouette is about 4.69 m high. Fit uniformly inside its
existing visual envelope and preserve its trunk body; do not transplant the
composed grove's taller forms, 52-tree layout or 834 understory placements. Root
banks and new ground coverage await a matching existing placement footprint.

## Affected systems, decisions and assumptions

Presentation adapters target ResourceNode, LeylineSource, ContraptionSite and
Enemy, with actual Sandpit terrain/resource/pack streaming and SaveManager.
D-013/D-030 govern readable appearance; D-010/D-017/D-033 and the existing LF work
items govern behavior, ownership and saved geography. No native tuning, physics,
AI, terrain profile, enemy cap, progression or save schema changes are selected.

Concurrent Wave 7 gameplay is being edited separately. Freeze committed game/data
and native code at `8aec10ef3b1df190e23fc4f32bc910877e8ded86`; overlay only this
art recipe in a separate project and APPDATA. Never replace the running game DLL.
The pilot is opt-in and local; global adoption and long-term asset promotion are
separate from raw generated handoffs under ignored build/. No new package/service.

## Small implementation and verification plan

1. Record Green approval and inspect native route/visual/body footprints.
2. Cook deduplicated maximum-2k textures and unchanged mesh/skin/animation buffers
   from approved handoffs. Bind the surviving native owner nodes only.
3. Drive boar movement/status/attack poses from actual actors and device light from
   actual paid work. Preserve original attack footprints and interaction panels.
4. Exercise real player movement, finite gathering, paid valid/blocked placement,
   source ownership, combat, streaming and fresh-process full-save restoration.
   Distinguish paced fixture setup from actual input-driven movement/combat.
5. Capture matched day/dusk and measure normal/crowded baseline versus integration.
   Deliver the isolated playable pilot and evidence; report failures and fit limits
   before any broader reuse, then commit and push only the checked art slice.

## Delivered implementation

The local playable package is `build/art05/red-route-handoff/` (1,480 manifest
files, 244,892,498 bytes). `Launch route.ps1` opens its own copied game/data and
APPDATA. It starts from the actually paid workshop before the finite boar hunt;
F5/F9 and later launches use only that pilot's save. Fresh package import and
ordinary-controller smoke checks passed, and all delivered file hashes remained
unchanged after reimport. The manifest excludes generated engine caches.

The [recipe](../../tools/wroughtwild-route/README.md) and
[actual engine evidence](../art/leyline-studies/2026-09-09/world-route/README.md)
record the implementation. A small presentation adapter binds surviving resource,
source, fixture and enemy nodes. It retains source/body ownership and native
movement, work, attack tells, statuses, fall/shrink, depletion and restart. Old
procedural boar movement is stopped while its native warning remains active.
Stable scar phases derive from existing owner identities and survive streaming.

The cook contains 12 explicit mesh roles and 34 deduplicated maximum-2k textures
(77,058,356 PNG bytes), retaining the approved scar settings, exact geometry/skin/
animation buffer bytes and 100 Hz import. Quiet hosts have a blank scar mask.
Stored/paused heat stays steady; work advances only from native progress and
completed-cycle changes. Raw claims and the existing rare marker remain separate.

## Checks and results

- **926 asset checks:** every input hash, geometry/skin/animation buffer, hierarchy,
  external texture and explicit import setting.
- **249 integrated route checks**, including 135.18 m of actual input/controller
  walking, paid crafting/camera placement, rejected overlap retaining the kit,
  source collection, partial/depleted harvesting, stream retirement/re-entry,
  native freeze/pose/status priority and actual boar combat. The existing starting
  casts defeated the boar; a native release and its warning/skin windup occurred.
  No test invulnerability, material grants or new progression was introduced.
- **245 original-presentation route checks:** same native baseline and operations;
  135.08 m controller walk. The four additional art checks cover the fitted freeze
  adapter. Acquisition/travel setup uses the existing paced journey helpers;
  the measured route walk itself uses controller movement without teleports.
- **8 fresh-process checks:** exact source, inventory/progression and fixture
  state; one usable buffer; no regrown harvested tree or respawned finite boar.
- **12 native component checks:** the unchanged ART-04 paid LF-1 checkpoint verifies
  paused fractional work, real resume, obstruction, completion wrap and no replay.
  This independent component check does not transplant that checkpoint's geography
  or claim a pressure feeder was built at the new pilot workshop.
- Matched actual day/dusk source/trail/boar/buffer pictures; sampled walk/combat
  clips; fresh standalone import/playable smoke; exact final package hashes.

Checks found and corrected deferred attachment to already retired resource nodes,
a renderer teardown error from changing original render layers, an uninitialised
pose when frozen immediately, and false work on restoring a paused fractional
firing. Final checks pass without engine/script/shader errors apart from the exact
retained Windows sandbox certificate-store startup warning. The initial stress
fixture also rejected an invalid hillside height sample; final fixtures use each
actor's actual local supported height. No native collision was relaxed.

## Matched desktop cost and limits

Forward+, RTX 5090, 1280×800, native default presentation and enabled VSync.
Six comparisons have identical cameras, resource IDs/counts and terrain chunk
counts. Each uses 120 warmup and 300 measured frames without screenshots inside
timing. Resource arrivals are completed and terrain streaming is held stationary
for these fixed views; the separate movement test exercises live streaming.

| Scene | Original GPU median, day/dusk | Integrated GPU median, day/dusk |
| --- | --- | --- |
| Source and nearby grove | 0.540 / 0.538 ms | 1.486 / 1.484 ms |
| One boar | 0.389 / 0.388 ms | 0.514 / 0.514 ms |
| 24 live boars, labelled cap-sized fixture | 0.500 / 0.500 ms | 1.002 / 1.002 ms |

Integrated frame medians are 4.03–4.18 ms with VSync, so these are not uncapped FPS
claims. GPU p95 is 0.729–1.719 ms. Loaded texture memory rises from about 115–118
MiB to 339–406 MiB. The source view submits about 6.98 million primitives; the
nearby grove is the principal geometry cost. The explicit boar is 64,983 triangles,
each tree host 84,990 plus its 85,800-triangle far canopy, rock 54,996, source
11,999, and buffer 15,617. Counts/timings are retained, not replaced with optimistic
budgets. The 24-actor fixture changes no normal-world spawn rule or enemy cap.

This first pilot uses explicit mid boar/source geometry and far canopy geometry.
The cook also retains far candidates for later measured adoption. Automatic
runtime distance switching, GPU texture compression and lower-spec hardware
are not certified here. Compatibility in the full world and the concurrently
changed Wave 7 gameplay remain outside this pinned Forward+ proof.

The visible remaining gap is older ground cover, distant canopies, scenery and
terrain shading around the new assets. No extra plant/resource placement, new
geography/profile, root-bank placement, density change or gameplay rule is implied.
The grove's composed layout was not transplanted. Its smaller fitted trees do not
establish a new taller-tree collision/placement policy. Long-term asset promotion
and wider adoption remain separate from raw local handoffs under ignored build/.

`route.json` documents corridor/affected radii, gait-distance/rooting presentation
and inherited grove light levels. Source/work/claim/storage gains and scar colours
remain those of the approved handoffs. **The technical pilot is complete; owner
review of this actual world presentation is the next art gate before broader reuse.**
