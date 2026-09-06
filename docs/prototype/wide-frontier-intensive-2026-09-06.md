# The Wide Frontier — 6 September 2026

Status: implemented and verified; human opening/exploration review remains. “Okay let's do it” accepts
the preceding 1 km generation recommendation: broader biomes, rolling terrain,
more home choices and a calmer opening. This work item governs D-032. The seed
clarification requires random fresh games and reproducible chosen seeds.

## Outcome and scope

Fresh worlds use `frontier_v6`, a finite 1,024 × 1,024 metre landscape with
96 one-metre vertical cells. The target has four times V5's land area. Two
kilometres and infinite generation remain outside this intensive. This is a
measured implementation target, not a performance promise for untested hardware.

Three larger continuous discovery regions retain their identities across hills,
banks, valleys and local Cataclysm scars. Homeward land provides four useful,
reachable building clearings and supply loops. Existing habitats, finite rare
finds, caves, ruined settlements and the accidentally empowered old smithy give
outward travel a purpose. No new material, recipe, machine, currency, mob family,
era, asset dependency or art overhaul is introduced.

The starter heartland is quiet geography, not timed immunity. Wild packs and
their complete patrol segments stay beyond its gathering/noise buffer. Players
can deliberately leave early. V6's first eligible home siege moves from night
two to night three, just after approximately thirty minutes of uninterrupted
starting-clock play; later siege rules remain. This does not guarantee thirty
minutes of survival or require waiting to explore. Existing profiles retain their
pacing. The reported timber-demolition conflict remains outside this work item.

## Implementation slices

1. Freeze V5's exact live inputs and preserve V1–V5 generation fingerprints.
   Add V6-specific landform, population and home-site composition, with deterministic
   source IDs and bounded generation work. Surface relief must not arbitrarily
   turn every high wooded location into rocky hills.
2. Make fresh normal games choose a random seed; support a chosen seed and show
   the current identity. A saved world always restores its original profile,
   seed and mutations. Do not regenerate a running playtest or replace its save.
3. Retire distant unedited terrain mesh, collision and sampling data and recreate
   them on return. Exact edited chunks and seam neighbours remain pinned so a
   distant quarry never appears refilled; report this remaining memory cost.
   Preserve synchronous collision preparation before restore/teleport.
4. Integrate V6 with resource presentation, pressure ledgers, saves and opening
   patrol/siege behaviour. Keep dormant search and diagnostics bounded.
5. Verify native geography and historical identity, gameplay travel/return,
   saving and excavation. Compare cold startup, retained memory and frame times
   on matched V5/V6 routes, including active chunk preparation. Inspect player-height
   daylight and dusk captures. Investigate changes over ten percent and report
   any remaining limits honestly.

## Initial tuning purposes

| Setting | Initial target and purpose |
| --- | --- |
| Map width/height | 1,024 cells each: room for longer biome interiors and distinct home options. |
| Vertical depth | 96 cells: headroom for wooded hills, upland ridges and underground space. |
| Region radii | Approximately 125–160 m: substantial interiors rather than small biome islands. |
| Region transitions | Approximately 35–45 m: blend biome margins and terrain changes. |
| Region distance | Approximately 340 m: put major discoveries beyond the starter supply loops. |
| Quiet heartland | 150 m: room to choose a home, gather and make an initial base. |
| Hostile boundary | 190 m: keep whole patrols away from heartland gathering noise and activation. |
| Home sites | Four 14 m-radius clearings, about 90 m from spawn, with an 18 m blended shoulder: practical building space with differing outlooks. |
| First siege night | Three for V6: keep the existing home pressure after the intended opening. |
| Outer population | A deterministic 0.16 retained fraction of ordinary sources/packs before allocation; composed regions sample their own biome's supplies at this same density. |
| Home supplies | Four trees, three boulders, two stone seams and one iron source beside each clearing: finite starter loops using existing harvesting rules. |
| Dormant pack bins | 64 m search cells: keep nearby activation/noise queries bounded while retaining exact range and patrol rules. |

Final values and plain-language purposes live together in engine-neutral
`worldgen.json` and the existing streaming resource. These are starting playtest
defaults. Human pacing, picturesque home choices and lower-spec performance
remain review questions, not conclusions from scripted checks.

## Acceptance

- Same profile and seed reproduce the same complete world; different seeds
  change terrain/composition. Random generation is not a small preset catalogue.
- V1–V5 terrain, finite resources, routes, pressure identity and save restoration
  remain unchanged. Unknown profiles fail validation before mutation.
- V6 has all existing progression opportunities, four supported reachable home
  sites, larger connected regional cores and measurable local elevation variety.
- Starter supply work areas and routes remain supported and clear. All hostile
  patrol segments respect the quiet boundary, including later-era routes.
- Repeated distant travel does not retain all unedited exact terrain. Return
  preserves cave collision, resource partial work/depletion, excavation and builds.
- The 1 km target is measured in an isolated review process. No existing game,
  editor or player save is stopped, migrated or overwritten by verification.

## Implemented behaviour and verification

The seed chooser accepts 0 through 2,147,483,647. A normal launch chooses a new
random value; Randomise or a typed seed changes it before class selection.
There is no curated seed list. The current seed and profile appear in Help.
Continue validates and generates the saved identity directly, including a
suspended trial, without first generating the proposed fresh world. Generation
shows a rendered preparation message. A failed fresh launch retains the chosen
seed and input pause, restores pre-choice class/economy/loadout, and permits an
explicit retry. [Opening controls and focused evidence](wide-frontier-opening-2026-09-06.md).

V6 separates biome identity from elevation and supplies each composed region
with that biome's real finite gathering sources. Seed 1 has 14,274 resource
records and 937 packs across the square kilometre. Its sampled upland, fen and
wildwood cores span 29, 25 and 23 vertical metres respectively. These are
measurements of one seed, not fixed layouts or a promise of equivalent density
at every viewpoint. The existing authored forms still determine visual quality.

The native map remains one full voxel allocation. Validation, source-ledger
restoration and terrain presentation now reuse the same immutable cached
identity; switching worlds releases the previous cache before allocation.
Nearby presentation retires distant unedited meshes, collision and samplers.
Edited chunks and their seam neighbours remain pinned. Horizon detail samples
each coarse vertex once; the 1 km horizon contains 32,768 triangles. Repeated
travel in the focused fixture built 512 exact chunks, released 492, and ended
with 24 residents including four pinned excavation/seam chunks.

Focused checks passed on the isolated final review runtime:

| Check | Result and scope |
| --- | --- |
| New-world startup | 97 checks: random/chosen seeds, real class choice, validated Continue, exact suspended trial restore, bad identity refusal, failure rollback and retry. |
| Opening and dormant search | 319 checks: exact candidate equivalence, ordinary/foreign patrols, activation/noise, sleeping/spent packs and siege lifecycle. |
| V6 terrain travel | 75 checks: chunk retirement and return, cave collision, pinned excavation, partial/depleted sources, save restoration. V5 equivalent also passed 75 checks. |
| Historical terrain/save regression | 57,897 terrain checks and 21 weathered-save checks, with preserved older-profile fixtures. |
| Pressure economy | 399 native checks; 60 Godot workshop checks each for V5 and V6. Profile, seed and source identity cannot be exchanged to refill stock. |
| Existing Forge lifecycle | 6,193 Godot checks: the authored scene and trial contracts remain compatible with startup/save changes. |
| Full V6 presentation/save review | 26 headless checks for actual site approaches/collision, source identity and atomic capture/restore; 36 rendered checks with the walking route and player-height daylight/dusk views. Matched V5 review passed 17 checks. |

The final native matrix passed **64 seeds and 20 complete historical
fingerprints** (76,183,096 assertions). It covers seeds 1–32, both public range
endpoints, deterministic samples across the remaining 31-bit range, and the
explicit large native seed `111486301962` that exposed the Forge foundation
failure. That seed now retains a complete threshold/gate pair through a bounded
nearby search; already viable gate placements take their original path. A V6-only
habitat wrapper also excludes full home pads and reserves their approaches.
Neither correction edits a frozen helper. The final seed-1 hash is
`14835081786202628356`. The three disjoint batch logs are
`build/wide-frontier/native-final-{a,b,c}.log`. The main simulation regression
suite also passed 224,377 checks.

## Measured cost and remaining preparation regression

Two cold-process V5/V6 pairs used the same final runtime, seed 1, resolution,
camera settings and 150 m walking method. Background verification had finished.
Godot reported Forward+ on the local RTX 5090. This is a local reference machine,
not a minimum-spec certification, and the owner's normal applications could
still share hardware. The 120 fps cap also limits conclusions about spare
rendering capacity.

| Measurement | V5 | V6 |
| --- | --- | --- |
| Cold complete world setup | 5.03–5.19 s | 8.08 s |
| Settled spawn median / p95 | 8.31 / 9.85–10.24 ms | 8.34 / 8.45–8.47 ms |
| All walking frames median / p95 | 8.21 / 8.77–8.79 ms | 8.22–8.24 / 8.72–8.80 ms |
| Frames with pending terrain work median / p95 | 8.14–8.15 / 11.07–11.09 ms | 8.17 / 12.30–12.73 ms |
| Engine static allocations after matched walk | 814–815 MiB | 954–955 MiB |
| Retained exact chunks after matched walk | 337–338 | 355 |

The slower end of terrain-preparation frames is **11–15% higher**, which crosses
the investigation threshold. The second pair recorded the bounded streaming
timers: preparation-stage p95 rose from 7.07 to 10.40 ms while its median stayed
about 1.8 ms; retirement p95 was 0.34 vs 0.32 ms. This localises the remaining
cost to producing new terrain rather than freeing old chunks. All-walk p95
remained effectively level at about 8.8 ms. The preparation regression remains
a documented limitation; splitting expensive preparation stages further is
future optimisation, not a claimed result of this pass.

Startup's increase is dominated by native map composition: approximately
0.56 s in V5 versus 5.22 s in V6. V6's fourfold area and doubled depth produce
eight times the voxel volume. Initial mesh and resource presentation were
cheaper at V6's quieter spawn, partly offsetting that cost. The visible
preparation message addresses the wait; it does not make generation asynchronous.

Memory above is Godot's static-allocation monitor, not total process peak,
native standard-library allocations or GPU memory. The 17% increase during the
matched walk does not establish a hardware memory requirement. Exact unedited
terrain no longer accumulates for the full travel history, but the full native
map and all finite node records remain resident.

Both pairs' manifests are under
`build/wide-frontier/render/build/wide-frontier/frontier_v{5,6}-1/`:
`manifest-first-pair.json` and `manifest.json` (second pair, with preparation
stage timings). Fifteen V6 images cover the starter valley plus four home and
three regional approaches in daylight/dusk. These use actual biome moods and
the middle of the configured day/dusk phases. Reviewed views show open home
ground, wooded slopes, fen banks and exposed upland relief; existing prototype
assets remain visibly provisional.

## Reproducing the review

Build the existing GDExtension with `WW_RUNTIME_OUTPUT_DIRECTORY` set to
`build/wide-frontier/runtime` to avoid replacing a library used by a live game.
Then run the bounded review helper from the repository:

```powershell
./tools/wide_frontier_checks.ps1 -Prepare -ReviewName render -NativeLibrary ./build/wide-frontier/runtime/libwroughtwild_sim.windows.x86_64.dll -Import
./tools/wide_frontier_checks.ps1 -ReviewName render -Scene wide_frontier_review
./tools/wide_frontier_checks.ps1 -ReviewName render -Scene wide_terrain_stream
./tools/wide_frontier_checks.ps1 -ReviewName render -Scene pressure_workshop -UserArgs '--pressure-profile=frontier_v6'
./tools/wide_frontier_checks.ps1 -ReviewName render -Scene wide_frontier_review -Rendered -UserArgs '--review-profile=frontier_v5'
./tools/wide_frontier_checks.ps1 -ReviewName render -Scene wide_frontier_review -Rendered -UserArgs '--review-profile=frontier_v6'
```

The helper copies only the project/data into ignored review output and uses an
isolated user directory. Its timeout owns only the process it started. Reports,
test saves and captures are under `build/wide-frontier`; they are not committed.
The review fixes resolution to 1440×900, FOV to 75, eye height to 1.65 m and
frame cap to 120. Its 30-second approach follows the generated regional route
at 5 m/s; combat and the day clock are disabled. Run performance comparisons
after other verification processes finish. Headless fixture times are not
rendering benchmarks.

## Remaining review limits

Human exploration and first-base pacing still need the owner's playthrough.
Quiet geography and a later first siege create the opportunity; scripted tests
cannot confirm thirty minutes feels right or that the four outlooks are appealing.
Day/dusk views cover all three regional approaches and four home clearings;
these are gameplay presentation captures, not an art-finish approval.

The full native voxel volume, all resource/pack records and pinned edited
chunks still consume memory. This is a finite 1 km implementation, with no
claim that doubling again would be cheap. Process peak, GPU memory, lower-spec
hardware and dense live combat have not been benchmarked in this intensive.
Old saves retain their geography; seeing V6 requires choosing a new world.
