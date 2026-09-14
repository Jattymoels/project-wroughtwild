# ART-07R8 measured costs

Three or more fresh processes per mode/backend; paired paid checkpoint/cameras/resources, 1440x900, 4x MSAA, vsync off, 120 warmup and 300 settled samples per view/light. Import, first-use and settled frames are separate. Current-device costs do not establish minimum-hardware acceptance.

## forward_plus

Actual device: NVIDIA GeForce RTX 5090 / AMD Ryzen 9 9950X3D 16-Core Processor; 1.4.325.

| Mode | Each setup, seconds | Setup min / median / max, seconds |
| --- | --- | --- |
| art-off | 11.799 / 11.926 / 12.090 | 11.799 / 11.926 / 12.090 |
| G1 | 90.929 / 91.084 / 90.616 | 90.616 / 90.929 / 91.084 |
| R8 | 59.917 / 59.953 / 59.944 | 59.917 / 59.944 / 59.953 |
| R8 art-off | 11.786 / 11.787 / 12.126 | 11.786 / 11.787 / 12.126 |

Observed median setup reduction: 34.08%. Every R8 run below every G1 run: True.

| Loaded cost | Art-off range | G1 range | R8 range | R8 art-off range |
| --- | --- | --- | --- | --- |
| Textures MiB | 217.08 to 217.08 | 1,307.77 to 1,307.77 | 909.95 to 909.95 | 214.61 to 214.61 |
| Buffers MiB | 80.26 to 80.67 | 206.11 to 212.84 | 211.24 to 217.96 | 80.26 to 80.67 |
| Video allocations MiB | 335.15 to 335.56 | 1,563.78 to 1,570.50 | 1,171.08 to 1,177.81 | 332.69 to 333.10 |
| Unique scene triangles including hidden | 786,695.00 to 795,113.00 | 2,420,221.00 to 2,503,669.00 | 2,496,669.00 to 2,580,117.00 | 786,695.00 to 795,113.00 |
| Unique scene meshes including hidden | 1,403.00 to 1,447.00 | 1,603.00 to 1,626.00 | 1,606.00 to 1,629.00 | 1,403.00 to 1,447.00 |

| Mode / view / light | Settled median min / median / max ms | Largest settled frame ms | Largest warmup frame ms | Largest focus call ms |
| --- | --- | --- | --- | --- | --- |
| art-off / paid-home / day | 1.890 / 1.941 / 1.955 | 2.780 | 292.198 | 103.659 |
| art-off / paid-home / dusk | 1.920 / 1.948 / 2.042 | 3.397 | 5.557 | 103.659 |
| art-off / paid-interior / day | 1.470 / 1.488 / 1.561 | 2.386 | 6.134 | 3.488 |
| art-off / paid-interior / dusk | 1.491 / 1.501 / 1.515 | 2.166 | 4.553 | 3.488 |
| art-off / paid-workshop / day | 2.092 / 2.097 / 2.116 | 3.254 | 9.247 | 19.678 |
| art-off / paid-workshop / dusk | 2.064 / 2.114 / 2.120 | 3.098 | 5.595 | 19.678 |
| art-off / source-trail / day | 1.300 / 1.307 / 1.315 | 2.308 | 9.603 | 366.009 |
| art-off / source-trail / dusk | 1.287 / 1.291 / 1.338 | 1.925 | 4.600 | 366.009 |
| G1 / paid-home / day | 3.880 / 3.954 / 4.092 | 7.265 | 235.129 | 717.737 |
| G1 / paid-home / dusk | 3.886 / 3.900 / 3.975 | 5.973 | 7.682 | 717.737 |
| G1 / paid-interior / day | 3.452 / 3.469 / 3.537 | 4.994 | 11.960 | 3.567 |
| G1 / paid-interior / dusk | 3.385 / 3.445 / 3.505 | 5.342 | 7.321 | 3.567 |
| G1 / paid-workshop / day | 4.242 / 4.291 / 4.318 | 9.281 | 22.746 | 1132.402 |
| G1 / paid-workshop / dusk | 4.290 / 4.353 / 4.360 | 7.709 | 8.193 | 1132.402 |
| G1 / source-trail / day | 2.894 / 2.936 / 3.032 | 6.461 | 14.358 | 3818.601 |
| G1 / source-trail / dusk | 2.857 / 2.951 / 3.159 | 5.781 | 6.530 | 3818.601 |
| R8 / paid-home / day | 4.549 / 4.584 / 4.633 | 6.082 | 248.947 | 490.073 |
| R8 / paid-home / dusk | 4.485 / 4.507 / 4.560 | 6.079 | 8.772 | 490.073 |
| R8 / paid-interior / day | 3.926 / 3.947 / 4.044 | 8.666 | 17.262 | 3.511 |
| R8 / paid-interior / dusk | 3.925 / 3.992 / 3.996 | 6.043 | 7.896 | 3.511 |
| R8 / paid-workshop / day | 4.947 / 5.001 / 5.157 | 8.190 | 19.082 | 647.615 |
| R8 / paid-workshop / dusk | 4.974 / 4.997 / 5.040 | 6.874 | 9.446 | 647.615 |
| R8 / source-trail / day | 3.288 / 3.332 / 3.387 | 5.186 | 16.460 | 2085.886 |
| R8 / source-trail / dusk | 3.284 / 3.298 / 3.315 | 5.183 | 6.898 | 2085.886 |
| R8 art-off / paid-home / day | 1.928 / 1.951 / 2.039 | 3.182 | 288.401 | 99.865 |
| R8 art-off / paid-home / dusk | 1.941 / 1.957 / 1.968 | 2.844 | 5.003 | 99.865 |
| R8 art-off / paid-interior / day | 1.492 / 1.505 / 1.515 | 2.158 | 5.930 | 3.434 |
| R8 art-off / paid-interior / dusk | 1.473 / 1.536 / 1.540 | 2.639 | 4.506 | 3.434 |
| R8 art-off / paid-workshop / day | 2.126 / 2.156 / 2.197 | 3.371 | 9.214 | 20.664 |
| R8 art-off / paid-workshop / dusk | 2.061 / 2.087 / 2.137 | 3.419 | 5.543 | 20.664 |
| R8 art-off / source-trail / day | 1.274 / 1.294 / 1.353 | 2.178 | 9.645 | 358.130 |
| R8 art-off / source-trail / dusk | 1.309 / 1.309 / 1.337 | 2.284 | 4.398 | 358.130 |

## gl_compatibility

Actual device: NVIDIA GeForce RTX 5090 / AMD Ryzen 9 9950X3D 16-Core Processor; 3.3.0 NVIDIA 591.86.

| Mode | Each setup, seconds | Setup min / median / max, seconds |
| --- | --- | --- |
| art-off | 11.565 / 11.602 / 11.598 | 11.565 / 11.598 / 11.602 |
| G1 | 89.135 / 88.603 / 88.181 | 88.181 / 88.603 / 89.135 |
| R8 | 58.823 / 59.076 / 58.780 | 58.780 / 58.823 / 59.076 |
| R8 art-off | 11.596 / 11.464 / 11.522 | 11.464 / 11.522 / 11.596 |

Observed median setup reduction: 33.61%. Every R8 run below every G1 run: True.

| Loaded cost | Art-off range | G1 range | R8 range | R8 art-off range |
| --- | --- | --- | --- | --- |
| Textures MiB | 69.49 to 69.49 | 1,288.49 to 1,288.49 | 842.14 to 842.14 | 67.68 to 67.68 |
| Buffers MiB | 77.71 to 78.12 | 203.89 to 210.61 | 208.19 to 214.91 | 77.71 to 88.28 |
| Video allocations MiB | 147.20 to 147.61 | 1,492.38 to 1,499.10 | 1,050.33 to 1,057.05 | 145.39 to 155.95 |
| Unique scene triangles including hidden | 786,695.00 to 795,113.00 | 2,420,221.00 to 2,503,669.00 | 2,496,669.00 to 2,580,117.00 | 786,695.00 to 795,113.00 |
| Unique scene meshes including hidden | 1,403.00 to 1,447.00 | 1,603.00 to 1,626.00 | 1,606.00 to 1,629.00 | 1,403.00 to 1,447.00 |

| Mode / view / light | Settled median min / median / max ms | Largest settled frame ms | Largest warmup frame ms | Largest focus call ms |
| --- | --- | --- | --- | --- | --- |
| art-off / paid-home / day | 4.412 / 4.490 / 4.498 | 6.760 | 177.699 | 99.740 |
| art-off / paid-home / dusk | 4.407 / 4.481 / 4.658 | 6.561 | 6.594 | 99.740 |
| art-off / paid-interior / day | 2.622 / 2.635 / 2.636 | 3.525 | 19.786 | 3.558 |
| art-off / paid-interior / dusk | 2.637 / 2.666 / 2.704 | 3.746 | 4.557 | 3.558 |
| art-off / paid-workshop / day | 4.457 / 4.506 / 4.554 | 6.223 | 19.915 | 18.487 |
| art-off / paid-workshop / dusk | 4.433 / 4.489 / 4.499 | 6.079 | 6.717 | 18.487 |
| art-off / source-trail / day | 2.020 / 2.043 / 2.058 | 2.926 | 16.454 | 355.637 |
| art-off / source-trail / dusk | 2.003 / 2.011 / 2.035 | 2.692 | 3.596 | 355.637 |
| G1 / paid-home / day | 4.862 / 5.024 / 5.086 | 7.104 | 261.728 | 686.404 |
| G1 / paid-home / dusk | 4.827 / 4.955 / 4.959 | 6.871 | 7.743 | 686.404 |
| G1 / paid-interior / day | 4.152 / 4.198 / 4.221 | 5.748 | 41.698 | 3.795 |
| G1 / paid-interior / dusk | 4.218 / 4.238 / 4.268 | 8.816 | 7.262 | 3.795 |
| G1 / paid-workshop / day | 5.083 / 5.103 / 5.138 | 7.189 | 39.017 | 1107.158 |
| G1 / paid-workshop / dusk | 5.061 / 5.119 / 5.237 | 7.504 | 7.857 | 1107.158 |
| G1 / source-trail / day | 3.385 / 3.404 / 3.436 | 5.611 | 18.359 | 3679.247 |
| G1 / source-trail / dusk | 3.420 / 3.477 / 3.628 | 5.238 | 7.081 | 3679.247 |
| R8 / paid-home / day | 5.939 / 5.952 / 6.064 | 8.820 | 280.357 | 490.922 |
| R8 / paid-home / dusk | 5.947 / 5.957 / 6.002 | 9.209 | 9.247 | 490.922 |
| R8 / paid-interior / day | 4.964 / 5.017 / 5.020 | 7.312 | 43.089 | 3.658 |
| R8 / paid-interior / dusk | 4.937 / 4.950 / 4.963 | 6.704 | 7.657 | 3.658 |
| R8 / paid-workshop / day | 6.329 / 6.369 / 6.380 | 9.538 | 50.302 | 659.737 |
| R8 / paid-workshop / dusk | 6.452 / 6.482 / 6.501 | 9.477 | 9.195 | 659.737 |
| R8 / source-trail / day | 4.359 / 4.490 / 4.662 | 8.851 | 19.019 | 2099.641 |
| R8 / source-trail / dusk | 4.332 / 4.404 / 4.834 | 6.885 | 7.080 | 2099.641 |
| R8 art-off / paid-home / day | 4.417 / 4.476 / 4.501 | 6.262 | 169.262 | 99.340 |
| R8 art-off / paid-home / dusk | 4.439 / 4.454 / 4.489 | 6.324 | 6.664 | 99.340 |
| R8 art-off / paid-interior / day | 2.558 / 2.593 / 2.654 | 3.576 | 19.783 | 3.466 |
| R8 art-off / paid-interior / dusk | 2.577 / 2.626 / 2.667 | 3.730 | 4.493 | 3.466 |
| R8 art-off / paid-workshop / day | 4.466 / 4.501 / 4.561 | 6.269 | 19.699 | 18.514 |
| R8 art-off / paid-workshop / dusk | 4.440 / 4.489 / 4.494 | 5.792 | 6.382 | 18.514 |
| R8 art-off / source-trail / day | 2.036 / 2.039 / 2.076 | 2.802 | 15.113 | 353.297 |
| R8 art-off / source-trail / dusk | 2.013 / 2.076 / 2.086 | 3.166 | 3.548 | 353.297 |
