# Measured F5 standalone reviews

RTX 5090 / driver 591.86 / Godot 4.5 / 1600 × 1000 / 4× MSAA / bloom off / VSync enabled. Each renderer/family has six fixed source, device and overview day/shade cases, near LOD, 60 warm-up and 150 measured frames per case. Native clocks are held. No other generation, capture, compiler, encoder or engine process competed.

The table reports the range of per-case medians and maximum per-case p95/worst, draws/primitives and texture allocation. These are whole-review figures with the original backdrop. VSync presentation pacing dominates wall frames; no uncapped throughput, low-spec or populated-world claim. Full individual cases include GPU p50/p95/worst and render-CPU p50/p95 in conformance.json.

| Family | Renderer | Frame p50 range ms | Max p95 ms | Worst ms | Max GPU p95 ms | Draw range | Max primitives | Texture MiB |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Red | Forward+ | 6.937–6.993 | 7.476 | 7.945 | 1.223 | 83–345 | 3,358,420 | 499.3 |
| Red | Compatibility | 6.953–6.955 | 6.996 | 7.057 | 0.675 | 84–370 | 3,358,420 | 408.6 |
| White | Forward+ | 6.951–6.995 | 7.487 | 8.062 | 1.217 | 80–133 | 3,253,118 | 477.3 |
| White | Compatibility | 6.952–6.954 | 7.001 | 7.035 | 0.813 | 81–155 | 3,253,118 | 407.9 |
| Blue | Forward+ | 6.970–6.997 | 7.455 | 7.909 | 1.231 | 106–150 | 3,216,356 | 621.3 |
| Blue | Compatibility | 6.952–6.958 | 6.993 | 7.089 | 0.745 | 107–173 | 3,216,356 | 578.6 |
| Green | Forward+ | 6.957–6.988 | 7.452 | 7.700 | 1.154 | 115–208 | 2,744,414 | 769.7 |
| Green | Compatibility | 6.950–6.954 | 6.993 | 7.028 | 0.847 | 132–231 | 2,744,414 | 746.9 |

The rejected initial Red benchmark logged shader-cache MAX_PATH errors. It is preserved under logs/benchmark-False-v02*, excluded from this table. Final v03 benchmark logs have exit code 0 and no engine/shader errors. Historical ART-04 benchmark methods and baselines differ, so no like-for-like speedup is claimed.
