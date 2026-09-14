# ART-07R8 combined retained-world candidate

R8 composes the seven published repair candidates on the pinned G1 runtime. It
owns composition, fixture routing, verification and the reproducible handoff;
R1–R7 retain authorship of their repairs. Owner visual acceptance and R9's
independent review remain pending. Ordinary-world rollout is outside scope.

The runtime/data/native revision remains
`6bb2e044dcd0bf1788896aa2c19cdf56fee93522`; DLL SHA-256 is
`0e7c4956b6c870f5879e78f54c5830509b7ae37913055543cc3a6d451298e0e1`.
No newer gameplay checkout, ART-06C rigs, scatter, shapes, recipes, bodies,
collision, stock, payment or save rules were adopted.

## Composition

- Apply R1's 105-file fitted tree delta once. R7's own delta then changes local
  retained-anchor foliage; it does not reapply its inherited R1 tree package.
- Merge G1 art dispatch from R1/R3/R6 and G1 material routing from R2/R3 against
  the common baseline. Preserve per-shape R3 identity and native ember-vein routing.
- Keep R1's already fitted production geometry at unit scale. R2's numeric fit
  cache applies to the old inspection path; no old radius scan is reinstated.
- Apply R5's eight chest body GLBs before regenerating R2's image references.
  Rewritten interchange files preserve every non-image JSON field and GLB BIN byte.
- Regenerate image aliases using final PNG bytes and complete import parameters.
  Apply the exact identity resolver to the final R3/R6/R7 material loaders.
  Mutable work materials remain distinct; only identical texture inputs are reused.
- Preserve R4's terminal teardown in the eight repaired fixtures. Reused older
  R1/projection evidence derivatives receive the same terminal helper in R8 copies.
- The sole R8 player hook is an explicit test-only mouse-capture opt-out. Without
  that flag, the original control branch executes. The test-only no-focus override
  is outside the sealed normal-play runtime.

`changes.json` lists the complete composite delta, baseline hashes, parent owners,
parent function/settings descriptions and explicit overlaps. `records/composition.json`
retains the preflight and application ledger. Whole mutated peer runtimes and saves
were never copied into the candidate. Original G1 paid-home bytes stay unchanged.

## Seven-finding disposition

| Finding | Combined candidate | Remaining limit |
| --- | --- | --- |
| G2-V01 / R1 canopy | Fitted lower trunk and attached broad crown on original trees; source/native/envelope checks and matched views. | Heavy limbs, dark shade and sparse LOD2 foliage still need owner visual review. |
| G2-V02 / R3 building faces | Face/end/edge treatments, legal shape identity and glass rules compose with resource reuse. | Original geometry/repetition and dark interiors remain. Cinderglass opacity remains 0.72; no refraction. |
| G2-V03 / R5 chest seating | All eight authored cabinets/feet retain original storage/body authority. | Full/fine slabs conceal 0.125/0.0625 m of feet. Rear-wall and open-lid ceiling overlaps remain; no new placement or sweep rule. |
| G2-V04 / R6 ore | Material-only treatment for the five native faceted families plus unchanged C5 fallback geometry. | Raised ore volume and physically recessed scars require an unapproved terrain/seat/body decision. This part remains blocked. |
| G2-V05 / R7 understorey | Fuller local plant groups and rooted sway inside unchanged anchor envelopes. | Continuous reference understorey remains unmet: inherited measured eligible envelopes cover only 6.12–8.68% of four windows. No larger envelope/geography rule was invented. |
| G2-T01 / R4 lifecycle | Eight fixture terminal lifecycles plus affected restarts are replayed through the composed helper. | Manual Escape and ordinary-game shutdown remain unchanged; bounded checks do not establish long-session leak freedom. |
| G2-C01 / R2 cost | Exact resource reuse is applied to the final visual candidate and measured with the original R2 protocol. | Setup and texture memory improve; settled frame times increase, and approximately 451-453 ms traversal stalls remain. Current RTX 5090 evidence only; target budget remains unset. |

Runtime acceptance, visual acceptance and target-device clearance are separate.
A technically usable integration package does not mark every visual finding closed.
The exact published proposals are retained in [R6 source options](inherited-r6-source-options.md)
and [R7 coverage/envelope options](inherited-r7-coverage-options.json), with their
source hashes and commits in `inherited-options-lineage.json`. These are predecessor
measurements and unimplemented proposals, not new R8 decisions.

## Evidence and reproduction

The immutable handoff contains full `runtime/`, packed `sources/`, `parents/`,
`baseline_sources/`, exact file maps, original/private replay checkpoints, actual
images/motion, raw failed and successful logs, and comparison evidence. No imported
Godot cache is part of its runtime. Never launch or import the immutable seal in place.

Use the owned `handoff.py verify` command with the separately recorded manifest hash.
Use `workspace.py prepare --id r8 --version <absent version>` followed by
`handoff.py apply --package <seal> --manifest-sha256 <hash> --target <version>/runtime
--tests` for another guarded test copy. The application verifies every original
baseline file before copying and every final runtime file afterwards. Generate fresh
job IDs/logs/private paths and use the unchanged shared `run.ps1` for every engine job.

`play.ps1 -Package <seal> -ManifestSha256 <receipt hash> -Target <absent R8 version> -Renderer forward_plus`
creates and verifies a private full copy, imports it and launches the retained paid
home through the same process guard. It uses normal controls and mouse capture;
Escape releases the cursor. Saves resolve under that version's
`users/play/ART07G1`, not the owner's normal profile. This manual play launcher is
not used for automated capture or benchmark jobs.

All automatic renderer checks use the verified test flag and no-focus window.
The runner retains the single GPU mutex, existing-process deferral and private
APPDATA/LOCALAPPDATA/TEMP/TMP/Blender resources. No other process is interrupted.

## Measured combined cost

All 24 camera processes and six uncaptured traversals passed. All six native walk
records are exactly equal at 135.078021510504 m. Measurements ran alone after
imports/captures, on RTX 5090 / Ryzen 9 9950X3D, at 1440 x 900, 4x MSAA, vsync off
and no FPS cap. Each camera/light has 120 warmup and 300 settled samples. Processes
are fresh with pre-imported assets; OS/GPU caches are not flushed. Original G1 runs
precede R8 runs. This is current-machine evidence, not a minimum-device clearance.

| Measurement | Forward+ G1 to R8 | Compatibility G1 to R8 |
| --- | --- | --- |
| Median setup seconds, three runs | 90.929 to 59.944 (34.08% lower) | 88.603 to 58.823 (33.61% lower) |
| Loaded texture MiB | 1307.77 to 909.95 | 1288.49 to 842.14 |
| Settled median range across camera/light/repeats, ms | 2.857-4.360 to 3.284-5.157 | 3.385-5.237 to 4.332-6.501 |
| Uncaptured traversal median, ms | 4.840 to 5.593 | 5.954 to 7.445 |
| Uncaptured traversal worst frame, ms | 758.823 to 452.610 | 759.453 to 450.776 |

R8's observed setup ranges lie entirely below G1's, but the final visual candidate
has higher settled-frame medians and slightly higher buffer allocations. Streaming
stalls remain material despite smaller maxima in these individual runs. The raw
per-view distributions, setup components and memory counters are in `costs.json`;
`traversal-costs.json` retains all six route reports and their hashes. No threshold
or target-device approval is inferred from the improvements.

## Final reconstruction accounting

All 11 post-seal engine jobs pass. The inherited pressure-workshop probe writes
`runtime/build/pressure-workshop/midcycle.json` and its `.previous` backup. Both
are byte-identical between the original R8 run and fresh reconstruction. They
are preserved under post-seal evidence before the unchanged strict runtime audit;
no assertion or native checkpoint content changes. The initial extra-file audit
failure and its exact resolution remain recorded.

The final handoff includes this post-seal evidence and Git formatting metadata.
Its complete 5,673-file runtime map is byte-identical to the tested reconstruction.
`post-seal/runtime-equivalence.json` links the initial seal, tested runtime and
final file map. The initial seal remains intact. One repository inspection utility
had an empty EOF line removed; its Python AST is identical. Git file-format
attributes retain LF, binary GIFs and valid unified-diff context whitespace.
