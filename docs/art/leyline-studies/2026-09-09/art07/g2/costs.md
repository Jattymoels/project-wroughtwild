# G2 independent combined-cost replay

RTX 5090, 1440x900, 4x MSAA, vsync off, 120 warmup/300 sampled wall frames per camera/light; no captures or generation in benchmark processes. Max is independently recorded by the G2-only derivative.

These are local measurements, not an approved runtime budget or lower-spec clearance. Loaded allocations include hidden/prefetched work stages and LODs; unique triangles count base meshes once, including hidden meshes.

## forward_plus

Engine-clock setup through paid checkpoint/camera setup: 11.808 s baseline / 91.306 s art. One process each; includes world construction and paid restore, excludes subsequent per-view focus/warmup.

| Camera / light | Baseline median / p95 / worst ms | Art median / p95 / worst ms | Baseline / art draws |
| --- | ---: | ---: | ---: |
| paid-home / day | 1.908/2.310/2.467 | 3.729/5.023/5.642 | 708 / 1138 |
| paid-home / dusk | 1.965/2.459/2.813 | 3.591/4.041/6.617 | 708 / 1138 |
| paid-interior / day | 1.441/1.940/2.060 | 3.157/3.621/4.056 | 675 / 1040 |
| paid-interior / dusk | 1.455/1.901/2.341 | 3.207/3.705/4.199 | 675 / 1040 |
| paid-workshop / day | 2.034/2.495/2.856 | 3.921/4.499/6.145 | 724 / 880 |
| paid-workshop / dusk | 2.039/2.538/3.123 | 3.857/4.353/5.423 | 724 / 880 |
| source-trail / day | 1.264/1.725/1.851 | 2.762/3.134/3.415 | 400 / 508 |
| source-trail / dusk | 1.265/1.674/1.856 | 2.802/3.184/3.727 | 400 / 508 |

| Loaded cost | Baseline range | Art range |
| --- | ---: | ---: |
| Textures MiB | 217.1â€“217.1 | 1,307.8â€“1,307.8 |
| Buffers MiB | 80.3â€“80.7 | 206.1â€“212.8 |
| Video allocations MiB | 335.2â€“335.6 | 1,563.8â€“1,570.5 |
| Unique triangles incl. hidden | 786,695â€“795,113 | 2,420,221â€“2,503,669 |
| Unique surfaces incl. hidden | 1,471â€“1,515 | 1,913â€“1,958 |
| Instances incl. hidden/MultiMesh | 26,106â€“28,892 | 28,632â€“31,295 |

## gl_compatibility

Engine-clock setup through paid checkpoint/camera setup: 11.319 s baseline / 87.482 s art. One process each; includes world construction and paid restore, excludes subsequent per-view focus/warmup.

| Camera / light | Baseline median / p95 / worst ms | Art median / p95 / worst ms | Baseline / art draws |
| --- | ---: | ---: | ---: |
| paid-home / day | 5.180/5.784/6.293 | 6.589/7.407/8.956 | 7225 / 3730 |
| paid-home / dusk | 5.098/5.675/6.321 | 6.505/7.405/8.678 | 7231 / 3736 |
| paid-interior / day | 3.452/3.986/4.369 | 5.435/6.480/7.693 | 2305 / 2553 |
| paid-interior / dusk | 3.460/3.907/5.081 | 5.421/6.165/7.094 | 2305 / 2553 |
| paid-workshop / day | 4.986/5.584/6.289 | 6.205/7.278/8.241 | 6592 / 4392 |
| paid-workshop / dusk | 4.981/5.553/5.950 | 6.156/6.902/7.801 | 6592 / 4392 |
| source-trail / day | 2.656/3.115/3.327 | 4.798/5.544/6.090 | 1322 / 1852 |
| source-trail / dusk | 2.656/3.050/3.342 | 4.813/5.592/7.086 | 1322 / 1852 |

| Loaded cost | Baseline range | Art range |
| --- | ---: | ---: |
| Textures MiB | 69.5â€“69.5 | 1,288.5â€“1,288.5 |
| Buffers MiB | 77.7â€“78.1 | 203.9â€“210.6 |
| Video allocations MiB | 147.2â€“147.6 | 1,492.4â€“1,499.1 |
| Unique triangles incl. hidden | 786,695â€“795,113 | 2,420,221â€“2,503,669 |
| Unique surfaces incl. hidden | 1,471â€“1,515 | 1,913â€“1,958 |
| Instances incl. hidden/MultiMesh | 26,106â€“28,892 | 28,632â€“31,295 |
