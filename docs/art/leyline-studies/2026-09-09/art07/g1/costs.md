# G1 measured combined cost

Godot 4.5-stable / NVIDIA RTX 5090; Vulkan 1.4.325 Forward+ and OpenGL 3.3 driver 591.86 Compatibility. 1440x900, 4x MSAA, vsync disabled, 120 warmup frames, 300 sampled frames per camera/light. Fixed same paid checkpoint and native active IDs. Separate processes; no capture during timing.

All four process receipts record exit 0 and no competing Godot, Blender, TRELLIS or compiler process. The runner holds the shared GPU mutex and checks for new competitors during the run. These are local hardware measurements, not a lower-end performance acceptance.

Each row compares the same native active resource IDs, generated chunk count, camera and target. Texture totals are backend allocations, including hidden/prefetched resources. Buffer/video totals include renderer allocations beyond mesh data. Geometry below counts unique live-scene base meshes, including hidden stages and LODs, without multiplying by instances.

## forward_plus

| View / light | Baseline median / p95 ms | Art median / p95 ms | Art Δ median ms | Baseline / art draws |
| --- | ---: | ---: | ---: | ---: |
| paid-home / day | 1.964 / 2.377 | 3.464 / 3.879 | +1.500 | 708 / 1138 |
| paid-home / dusk | 1.940 / 2.347 | 3.504 / 3.905 | +1.564 | 708 / 1138 |
| paid-interior / day | 1.448 / 1.974 | 3.197 / 3.923 | +1.749 | 675 / 1040 |
| paid-interior / dusk | 1.453 / 1.957 | 3.160 / 3.616 | +1.707 | 675 / 1040 |
| paid-workshop / day | 2.087 / 2.585 | 3.835 / 4.395 | +1.748 | 724 / 880 |
| paid-workshop / dusk | 2.074 / 2.510 | 3.782 / 4.203 | +1.708 | 724 / 880 |
| source-trail / day | 1.282 / 1.717 | 2.666 / 3.046 | +1.384 | 400 / 508 |
| source-trail / dusk | 1.277 / 1.767 | 2.693 / 3.061 | +1.416 | 400 / 508 |

| Loaded cost across these views | Baseline range | Art range |
| --- | ---: | ---: |
| Textures (MiB) | 217.1–217.1 | 1,307.8–1,307.8 |
| Buffers (MiB) | 80.3–80.7 | 206.1–212.8 |
| Video allocations (MiB) | 335.2–335.6 | 1,563.8–1,570.5 |
| Unique triangles | 786,695–795,113 | 2,420,221–2,503,669 |
| Unique vertices | 2,225,845–2,251,099 | 6,241,578–6,492,282 |
| Unique indices | 483,372–483,372 | 2,304,132–2,306,076 |
| Unique meshes | 1,403–1,447 | 1,603–1,626 |
| Unique surfaces | 1,471–1,515 | 1,913–1,958 |
| Mesh instances incl. MultiMesh / hidden | 26,106–28,892 | 28,632–31,295 |

## gl_compatibility

| View / light | Baseline median / p95 ms | Art median / p95 ms | Art Δ median ms | Baseline / art draws |
| --- | ---: | ---: | ---: | ---: |
| paid-home / day | 5.018 / 5.609 | 6.154 / 6.916 | +1.136 | 7225 / 3729 |
| paid-home / dusk | 5.001 / 5.581 | 6.146 / 6.904 | +1.145 | 7230 / 3734 |
| paid-interior / day | 3.295 / 3.832 | 5.342 / 6.140 | +2.047 | 2305 / 2553 |
| paid-interior / dusk | 3.297 / 3.817 | 5.186 / 5.934 | +1.889 | 2305 / 2553 |
| paid-workshop / day | 4.843 / 5.461 | 5.805 / 6.410 | +0.962 | 6592 / 4392 |
| paid-workshop / dusk | 4.842 / 5.338 | 5.726 / 6.518 | +0.884 | 6592 / 4392 |
| source-trail / day | 2.568 / 2.904 | 4.729 / 5.833 | +2.161 | 1322 / 1852 |
| source-trail / dusk | 2.569 / 2.888 | 4.748 / 5.802 | +2.179 | 1322 / 1852 |

| Loaded cost across these views | Baseline range | Art range |
| --- | ---: | ---: |
| Textures (MiB) | 69.5–69.5 | 1,288.5–1,288.5 |
| Buffers (MiB) | 77.7–78.1 | 203.9–210.6 |
| Video allocations (MiB) | 147.2–147.6 | 1,492.4–1,499.1 |
| Unique triangles | 786,695–795,113 | 2,420,221–2,503,669 |
| Unique vertices | 2,225,845–2,251,099 | 6,241,578–6,492,282 |
| Unique indices | 483,372–483,372 | 2,304,132–2,306,076 |
| Unique meshes | 1,403–1,447 | 1,603–1,626 |
| Unique surfaces | 1,471–1,515 | 1,913–1,958 |
| Mesh instances incl. MultiMesh / hidden | 26,106–28,892 | 28,632–31,295 |

## Explicit detail choices

| Input | Combined pilot choice |
| --- | --- |
| B1 / C4 canopy | Published LOD2 for live trees, original native narrow body fit; distant native canopy unchanged. |
| B2 / B4 cover | B2 LOD2 meadow/edge grass and sparse fern in existing cover envelopes; B4 rooted sway only, analytic study-ground conformance disabled. Other source composition roles remain supporting inspection assets. |
| B3, C1, C2, C3 | Published LOD0 and native source work stages, including hidden stages. |
| C5 | LOD0 only for original fallback/labelled fixture; normal faceted thin ribbon retained. |
| C6 | Published LOD0/1/2, automatic at 10/24 m. Same native poses/bodies. |
| D1/D2/D3 | Complete authored fixed building solids; native collider decomposition and all chamfer/triangle/octagonal uses retained. |
| D4/D5/D6 | Original published family texture maps; 19 material families. Generic building faces use metric triplanar mapping. |
| E1/E2 | Published near station solids for native station dispatch. All near/middle/far tiers separately checked. |
| E3 | Published complete family-specific chest/fire solids and original native seating/hinge. |
| F1/F3 | Near source/default device view; source adapters also retain hidden middle/far resources. |
| F2 | Published fixed winch/landing/basket and near Thrumroot. |
| F4 | Near feeder/pocket; all near/middle/far full-body sweeps checked separately. |
| F5 | Published mid source/fixture solids; independent fragment detail and linear scar atlases retained. |

G1 settings: material normal strength 0.45, frame shade 0.72, canopy/cover LOD2, F5 middle detail, inherited rooted plant bend 0.018 and leaf multipliers (0.85, 0.72, 0.60). Every parameter has its plain-language purpose in `game/g1/settings.json`; source-specific controls remain in their published module JSON/resources. No gameplay tuning changed.

The longer regional tour separately loaded 1,371,473,408 texture bytes and 109,558,450 buffer bytes under Forward+; its final scene had 1,049,353 unique triangles and 10,251 mesh instances. This different camera/streaming tour is not substituted for the paired paid-route benchmark above. GPU render-time samples and visible primitive counts remain in the full JSON; wall frame times above include the whole frame.
