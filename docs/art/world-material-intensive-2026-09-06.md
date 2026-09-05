# World materials and authored habitat integration

Owner-approved implementation, 6 September 2026. Author: Codex (OpenAI).
The material scope is eight finished building families and two wall-face forms.
Existing Blender authoring tools and study documents are preserved. Fifteen
reviewed visual GLBs are curated in `game/assets/authored/manifest.json`, with
source paths and SHA-256 hashes: wall/post/beam, tree/boulder, four habitat props
and six furnishings. Existing gameplay collision remains authoritative; no
collision export or proposed lower workstation body is adopted.

`PieceLook` is the shared lookup for placed geometry, placement ghosts and
catalogue meshes/materials. The selected catalogue card renders the actual
material once in one viewport; small cards remain inexpensive geometry swatches.
Timber, pine, bog oak, ash and resinheart have separate grain, board width,
roughness and colour profiles, rather than tint alone. Slate, fossil shellstone,
brick, reed weave, cork and basalt have individual surface treatments. Glass
uses a translucent fixed pane inside an integral frame and muntins. Panels and
windows retain a full wall-face collider and normal shelter occupancy.

`HabitatResourceArt` gives six sources distinct labels, meshes and finite work
presentation. Contextual work always suffices; existing heavy impact accelerates
stone/clay/bark work. Trees fall and leave a stump; exhausted beds leave a low
decorative scar for the current visit. Resource meshes/collision reproject after
digging. `HabitatSites` places shared mesh batches around resources and approaches,
shallow moving fen pools, restrained foliage movement and sparse motes. Rebuilding
world identity replaces this presentation; excavation refreshes its support tests.

Art controls and purposes live beside their resources: `material_library.gd/.tres`
defines family surface profiles and frame dimensions; `habitat_sites_look.gd`
defines clearances, bounded accent/mote counts, visibility, wind and puddle size.
The shader profile's `pattern` selects the surface treatment, `spacing` is its
course width in metres, `grain` is fibre/detail density, `roughness` controls
surface sheen, and `base/accent` are its two quiet material colours. Roof courses
follow the piece's slope orientation. Imported single meshes retain generated
distance LODs; repeated props use MultiMesh.

Verification: `game/tests/material_intensive.tscn` exercises the nineteen-family
catalogue, one-step recipes, covering/glazing restrictions, preserved roof
eligibility and unlocks, cached authored art, per-family grain, finite partial
harvest and physical centre-ray collision. Three normal-shape demo buildings
and matched day/dusk/interior/catalogue captures are written to
`build/intensives/materials/`. Native `tests/sim/material_intensive.inc` additionally
checks exact crafting/payment/refund/storage contracts. Current test counts and
the full trial/world results belong to the implementation work items.

The final material render passes 165 checks and supplies seven captures, including
individual lodge/workhouse/cabin views. The lodge has a low fieldstone plinth and
basalt chimney; the workhouse combines fired brick with muted woven panels; the
cabin has a cork-roof porch using the existing full and half posts. Imported
decoration is grounded from its actual mesh bounds. Forty independent outward-face
checks cover the irregular slate/clay strata, including their capped undersides.
The review page is `build/intensives/materials/index.html`.

Fen dressing searches 96 stable candidate positions across its footprint for up
to three shallow pools. Each candidate samples its own terrain height, preserves
the 2 m resource and 1.8 m approach clearances, rejects over 0.12 m of surface
rise across the pool, and has no collider. World rebuilding replaces the prior
habitat presentation; excavation coalesces that refresh across affected chunks.

Matched legacy field-route comparison (same seed1/fixture193, 1920×1080 Forward+,
120fps cap, RTX5090): startup 8.902→8.974s (+0.8%); walking median
7.776→7.939ms (+2.1%), p95 9.378→9.262ms (−1.2%); combat median
7.672→7.633ms (−0.5%), p95 11.661→11.858ms (+1.7%). Distance, cast count,
damage frames and peak enemies match exactly. Samples include frame pacing;
they do not establish lower-spec GPU performance. Baseline and after manifests
are under `build/intensives/baseline/` and `build/intensives/field-after/`.

Forge architecture uses the same vitrified basalt, shellstone, fired brick and
cinderglass lookup as construction. Heat-marked block courses, banded piers,
framed glazed openings, floor borders and curated workshop meshes distinguish
the eight modules without adding gameplay obstacles. Furnishings sit on existing
solid cover and align to their imported bounds. Forge light gain is 1.65 to keep
enemy bodies readable in basalt rooms; fixtures stay quieter than orange danger
tells. Furnishings fade at 45 m and lamps at 38 m. Shared BoxMesh geometry by size
reduced measured Forge draw calls from about 1,959 to 1,077 without changing
collision, room layout or navigation.

`game/experiments/forge_review.tscn` records real native route/choice/reward
transitions, two floors and all three story completions. Its full route passes
579 checks and writes 516 frames to `build/intensives/forge/index.html`. The fixture
teleports between review poses, grants immunity and forces encounter clears;
it is accelerated spatial/presentation evidence, not a normal playthrough,
difficulty calibration or the twenty-minute target. Separate final boss-cycle
excerpts pass 171 checks and record 108 frames under `build/intensives/forge/boss/`.
Those follow the removal of
spatial boss hopping and the final corridor side-wall correction. Headless
regression/combat work can run during visual recording, so recording cadence is
not the authoritative matched performance result.

The review's `--performance-only` mode compares identical 24-enemy cohorts with
eight ignites and four persistent Foundry fields, the same build, seed 193,
camera distance, 1440×900 Forward+ resolution and 120fps cap. Both cohorts use
120 warmup frames and 600 measured frames with no screenshot readback. The
original arena measured median 8.308 ms / p95 10.204 ms; the final sealed Forge
floor with navigation measured 9.607 / 10.653 ms (+15.64% / +4.40%). The median
exceeds the ten-percent investigation threshold. Repeated quiet runs held the
Forge near 9.60 ms while the legacy median varied with frame pacing. With AI
paused, an earlier matched static cohort measured 8.494→8.165 ms; this suggests
the live simulation is the larger incremental cost rather than rendering alone.
Final mean physics time rises 2.376→3.113 ms. Mesh sharing reduced draw calls
without removing art; the final added boundary/connector walls bring the Forge
to about 1,105 calls against 542 in the original arena. The residual median
increase is reported, not hidden behind the earlier lower comparison. Exact
counters are in `build/intensives/forge/performance.json`. The final pass ran
without the other headless test processes. It does not establish performance
on lower-spec hardware or with an uncapped population.

No broad art dependency, additional construction form, currency, discovery gate,
structural simulation or change to the reported timber-demolition conflict is
included. Current sandbox-only certificate and shader-cache write messages do
not prevent the completed Forward+ renders.
