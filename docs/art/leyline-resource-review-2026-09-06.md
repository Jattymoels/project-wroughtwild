# Leyline and rare-resource graphics review

Implemented by Codex (OpenAI), 6 September 2026, under the
[owner-approved graphics work item](../prototype/leyline-resource-visual-2026-09-06.md).
Baseline source: `e51a014d6cb3a420b842edab0007076db48345a4`. The supplied
environmental reference informed the fractures and luminous deposits; its
character and interface were excluded.

## Result

Exposed native traces now have narrow, asymmetric dark mouths, chipped lips,
mostly unlit side branches and fine interrupted cool light. The five existing
rare finds have distinct rough hosts and contained luminous detail. The first
rendered iteration exposed overly regular conduits, a hidden Lanternheart and
floating Stormglass strands. The final pass narrows the fractures, opens the
hollow and fits the mineral seams to their actual authored surfaces.

The old smithy remains an accidental asteroid strike through a pre-cataclysm
ruin. Empty pressure hides its membrane and stock light, including under hover.
World generation, source identities, native quantities, recipes and saves are
unchanged. No new world or save migration is needed. Existing crafted fixture
art and the unrelated timber-demolition conflict remain outside this pass.

[Leyline implementation and tuning](leyline-fissures-2026-09-06.md) and
[rare-resource implementation and tuning](rare-resource-finish-2026-09-06.md)
record the local geometry, surface and state controls.

## Actual views and verification

The local comparison gallery is `build/leyline-visual/index.html`. It includes
seven exact matched player-height cameras in V5 seed 1, each in daylight and
dusk: an exposed connected trace, all five primary finds and the struck smithy.
The review uses Godot 4.5 Forward+, 1440 × 900, FOV 75 and a grounded 1.65 m eye.
The character and HUD are hidden. These are actual generated-world captures,
not concept art or a substitute for the owner's ordinary playthrough.

| Check | Final result |
| --- | --- |
| Integrated rendered graphics/state review | 177 checks, zero failures. |
| Existing Cataclysm intensive | 170 checks, zero failures. |
| Existing Strange Frontier | 7,073 checks, zero failures. |
| Existing pressure workshop | 60 checks, zero failures. |

The integrated checks compare exact native block, height, node, rare-site,
impact, trace and pressure-source hashes with the baseline. They exercise normal
E work, partial-work rebuild/save/restore, all five finite whole-haul pickups,
depleted-save restoration, stable collision envelopes, contained light state
and transient hover reset. Current rare nodes release the whole haul after
their work presses; a separately labelled synthetic reduced-stock restore
checks the visual denominator without changing that economy.

An isolated source appearance probe supplies 24/12/0 pressure states without
altering the native ledger. Real transfers and workshop saves are covered by
the existing workshop suite. Fourteen support checks cover missing ground,
an abrupt three-metre excavation face, complete support loss and exact rebuild.
Additional checks cover native buried/broken exposure, building suppression
and deterministic restoration of the same fracture mesh.

Review processes run separately with hidden/offscreen windows and save only
under ignored `build/` paths. The owner's running game, editor and normal save
were not stopped or replaced. No native rebuild or external dependency was
needed. Captures, manifests and intermediate iterations remain local artifacts.

## Rendering cost and limits

The final seam network contains 42,728 generated triangles before distance
culling, with one opaque surface per trace tile and no additional lights or
physics. Fine traces retire at 140 metres; rare detail at 48 metres. The sampled
tile contains 826 triangles, and its surface sits 1.8–3.6 cm above exact ground.
It is a shaded surface fracture, not a physical hole in the terrain.

Index-aware added rare geometry ranges from 792 to 2,512 triangles per kind,
with two additional meshes per find and a third for Pullstone grit. Cached
surface fitting, uncapped four-sided filaments and small approved host-chip
meshes replace unnecessarily dense provisional geometry. No geometry is rebuilt
each frame. Light and local drift use shader time; native state controls stock.

Each matched view warms for 90 frames and measures 600 uncapped frames.
Screenshot readback is excluded. Final setup measured 5,763 ms against the
baseline's 5,941 ms. Median frame times across the 14 final views are
1.16–1.59 ms, from 18.2% lower to 0.1% higher than their matched baselines.
Final p95 values are 2.07–3.22 ms. The earlier Lanternheart/Pullstone tail
outliers did not persist at their initial sizes after refinement. Thirteen
final p95 comparisons are within +8.1% or lower; Pullstone dusk is +11.1%
(2.293 ms versus 2.063 ms). The original matrix is retained rather than replaced
by a repeat chosen for a better number.

A single warmed repeat of Pullstone dusk retained the unresolved margin:
median/p95 1.423/2.853 ms against the original full-capture 1.161/2.293 ms.
Final and repeat rendering counts match exactly: 694 draws, 787,698 primitives,
353 loaded chunks and 1,119 active resources. Against the baseline, that view
adds 12 draws and 10,014 primitives (about 1.3%). The repeat passed its 41
view/camera checks, but does not isolate the timing cause. Both measurements
are preserved in the original `after` and separate `perf-repeat` manifests.
Further isolated profiling of this view remains open; no additional benchmark
was run to select a favourable result.

These wall-frame measurements may share hardware with the owner's playthrough.
They do not establish a speedup or certify moving-world streaming performance.
The previously reported cold terrain/view hitches remain unresolved. The hosts
retain their stylised, faceted silhouettes; Ventlung's daylight light is subtle
and clearer at dusk. Broader regional modelling and production visual polish
were not part of this bounded pass. Human visual acceptance remains with the
owner.

## Reproduce

With the existing extension and imported local assets available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/leyline_visual_review.ps1 -Phase after
powershell -NoProfile -ExecutionPolicy Bypass -File tools/leyline_review_gallery.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/cataclysm_review.ps1 -Scene cataclysm_intensive
powershell -NoProfile -ExecutionPolicy Bypass -File tools/cataclysm_review.ps1 -Scene strange_frontier
powershell -NoProfile -ExecutionPolicy Bypass -File tools/cataclysm_review.ps1 -Scene pressure_workshop
```

The baseline is intentionally preserved by the runner. A fresh checkout needs
the baseline captured at the stated base commit before comparing later art.
