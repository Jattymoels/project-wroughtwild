# R7 combined R1-canopy / R7-cover world costs

Godot 4.5 stable, RTX 5090, driver 32.0.15.9186, Ryzen 9 9950X3D (16 cores/32 threads),
32 GB RAM, Windows 11 Home. The adapter is recorded independently by each renderer.
Both renderers use 1440 x 900, 4x MSAA, VSync off and matched terrain-sampled cameras.
Each row has 120 warmup frames then 300 settled wall-frame samples per mode. The four
benchmark processes run separately from imports, generation, reopening and captures,
under the unchanged shared guard. No competing art/compiler process was observed.

Before is common pinned G1 plus published R1. After adds only R7. Values are full
world costs including both canopy and cover, other G1 assets and hidden resource
stages. Unique mesh triangles are not multiplied by instance count; submitted visible
primitives are reported separately. Texture/buffer totals are backend allocations,
not a promise of physical VRAM residency. Scene transitions and streaming cost are
not represented by these settled samples; the actual route is separately evidenced.
No minimum-hardware target or frame budget was supplied, and R2 is not included.

| Renderer / view / light | Frame median before → after ms | P95 before → after ms | P95 change | GPU median before → after ms | Draw calls before → after | Visible primitives before → after |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| forward_plus / home-player-height / day | 3.933 → 4.369 | 5.061 → 4.974 | -1.7% | 2.429 → 2.922 | 1147 → 1409 | 8,211,573 → 9,568,845 |
| forward_plus / home-player-height / shade | 3.992 → 4.465 | 4.649 → 5.310 | +14.2% | 2.429 → 2.904 | 1147 → 1409 | 8,211,567 → 9,568,839 |
| forward_plus / home-player-height / dusk | 3.960 → 4.305 | 4.452 → 4.829 | +8.5% | 2.429 → 2.904 | 1146 → 1409 | 8,211,573 → 9,568,851 |
| forward_plus / route-player-height / day | 3.002 → 3.229 | 3.435 → 3.738 | +8.8% | 1.639 → 1.876 | 523 → 709 | 4,692,196 → 6,142,742 |
| forward_plus / route-player-height / shade | 2.997 → 3.233 | 3.446 → 3.808 | +10.5% | 1.639 → 1.878 | 523 → 709 | 4,692,196 → 6,142,742 |
| forward_plus / route-player-height / dusk | 3.186 → 3.280 | 3.893 → 3.865 | -0.7% | 1.640 → 1.876 | 523 → 709 | 4,692,196 → 6,142,742 |
| forward_plus / clearing-player-height / day | 4.231 → 4.458 | 4.985 → 5.576 | +11.9% | 2.267 → 2.548 | 1160 → 1358 | 7,558,725 → 8,594,631 |
| forward_plus / clearing-player-height / shade | 4.039 → 4.615 | 4.715 → 6.397 | +35.7% | 2.267 → 2.501 | 1160 → 1358 | 7,558,725 → 8,594,631 |
| forward_plus / clearing-player-height / dusk | 4.182 → 4.844 | 5.379 → 6.339 | +17.8% | 2.271 → 2.677 | 1160 → 1358 | 7,558,725 → 8,594,631 |
| forward_plus / habitat-player-height / day | 4.979 → 5.567 | 6.633 → 6.717 | +1.3% | 3.749 → 4.317 | 1322 → 1568 | 11,813,589 → 13,805,469 |
| forward_plus / habitat-player-height / shade | 6.862 → 5.634 | 7.978 → 6.968 | -12.7% | 3.746 → 4.243 | 1322 → 1568 | 11,813,589 → 13,805,469 |
| forward_plus / habitat-player-height / dusk | 7.362 → 5.439 | 8.324 → 6.172 | -25.9% | 3.768 → 4.243 | 1322 → 1568 | 11,813,589 → 13,805,469 |
| gl_compatibility / home-player-height / day | 7.126 → 7.686 | 8.532 → 8.491 | -0.5% | 3.276 → 3.371 | 3580 → 4392 | 8,211,573 → 9,568,839 |
| gl_compatibility / home-player-height / shade | 6.959 → 7.679 | 7.919 → 8.559 | +8.1% | 3.223 → 3.446 | 3583 → 4395 | 8,211,579 → 9,568,845 |
| gl_compatibility / home-player-height / dusk | 6.845 → 7.795 | 7.656 → 8.557 | +11.8% | 3.103 → 3.495 | 3579 → 4398 | 8,211,567 → 9,568,851 |
| gl_compatibility / route-player-height / day | 5.316 → 5.876 | 6.368 → 7.205 | +13.1% | 1.521 → 2.037 | 1913 → 2658 | 4,692,196 → 6,142,742 |
| gl_compatibility / route-player-height / shade | 5.217 → 5.714 | 6.159 → 6.453 | +4.8% | 1.524 → 2.064 | 1913 → 2658 | 4,692,196 → 6,142,742 |
| gl_compatibility / route-player-height / dusk | 5.203 → 5.746 | 5.907 → 6.569 | +11.2% | 1.520 → 2.069 | 1913 → 2658 | 4,692,196 → 6,142,742 |
| gl_compatibility / clearing-player-height / day | 6.919 → 7.402 | 7.862 → 8.273 | +5.2% | 3.317 → 3.142 | 3773 → 4390 | 7,558,725 → 8,594,631 |
| gl_compatibility / clearing-player-height / shade | 6.941 → 7.572 | 8.164 → 8.750 | +7.2% | 3.052 → 3.235 | 3774 → 4390 | 7,558,725 → 8,594,631 |
| gl_compatibility / clearing-player-height / dusk | 6.932 → 7.443 | 8.133 → 8.428 | +3.6% | 3.224 → 3.132 | 3772 → 4389 | 7,558,725 → 8,594,631 |
| gl_compatibility / habitat-player-height / day | 8.024 → 9.134 | 9.067 → 10.031 | +10.6% | 3.618 → 5.053 | 4293 → 5191 | 11,813,589 → 13,805,469 |
| gl_compatibility / habitat-player-height / shade | 8.077 → 8.904 | 9.332 → 9.693 | +3.9% | 3.599 → 4.951 | 4293 → 5191 | 11,813,589 → 13,805,469 |
| gl_compatibility / habitat-player-height / dusk | 7.960 → 9.140 | 9.509 → 10.009 | +5.3% | 3.593 → 5.064 | 4293 → 5191 | 11,813,589 → 13,805,469 |

| Renderer / view (day) | Unique triangles before → after | Unique meshes before → after | Loaded texture MiB before → after | Loaded buffer MiB before → after |
| --- | ---: | ---: | ---: | ---: |
| forward_plus / home-player-height | 2,469,697 → 2,545,281 | 1622 → 1625 | 1307.77 → 1339.77 | 209.87 → 214.25 |
| forward_plus / route-player-height | 2,392,651 → 2,468,235 | 1594 → 1597 | 1307.77 → 1339.77 | 203.74 → 208.12 |
| forward_plus / clearing-player-height | 2,493,737 → 2,569,321 | 1623 → 1626 | 1307.77 → 1339.77 | 211.85 → 216.23 |
| forward_plus / habitat-player-height | 2,823,848 → 2,899,432 | 1645 → 1648 | 1318.61 → 1350.61 | 228.33 → 232.71 |
| gl_compatibility / home-player-height | 2,469,697 → 2,545,281 | 1622 → 1625 | 1288.49 → 1331.16 | 207.67 → 212.04 |
| gl_compatibility / route-player-height | 2,392,651 → 2,468,235 | 1594 → 1597 | 1288.49 → 1331.16 | 201.53 → 205.90 |
| gl_compatibility / clearing-player-height | 2,493,737 → 2,569,321 | 1623 → 1626 | 1288.49 → 1331.16 | 209.61 → 213.98 |
| gl_compatibility / habitat-player-height | 2,823,848 → 2,899,432 | 1645 → 1648 | 1299.28 → 1341.95 | 226.16 → 230.54 |

Raw samples, GPU P95/worst, wall worst, render CPU median and all allocation counters are retained in technical-checks.json and the engine reports. A zero backend GPU timing would mean unavailable, not a zero-cost frame. These are one paired run per renderer, not replicated acceptance statistics.

The own addition is 75,584 unique live-scene triangles in every matched day case. Reported texture allocation rises by 32 MiB in Forward+ and about 42.7 MiB in Compatibility. Maximum observed P95 increases across the 12 cases per renderer are 35.7% and 13.1%; maximum candidate P95 values are 6.968 and 10.031 ms respectively. Mixed before/after improvements and regressions are retained without attributing all variation to R7; one paired run is not replicated acceptance evidence.
