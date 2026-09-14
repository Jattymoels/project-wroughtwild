# ART-07R2 measured costs

Three or more fresh processes per mode/backend; paired paid checkpoint/cameras/resources, 1440x900, 4x MSAA, vsync off, 120 warmup and 300 settled samples per view/light. Import, first-use and settled frames are separate. Current-device costs do not establish minimum-hardware acceptance.

## forward_plus

Actual device: NVIDIA GeForce RTX 5090 / AMD Ryzen 9 9950X3D 16-Core Processor; 1.4.325.

| Mode | Each setup, seconds | Setup min / median / max, seconds |
| --- | --- | --- |
| art-off | 11.681 / 11.607 / 11.576 | 11.576 / 11.607 / 11.681 |
| G1 | 91.559 / 90.662 / 92.245 | 90.662 / 91.559 / 92.245 |
| R2 | 58.487 / 58.781 / 58.742 | 58.487 / 58.742 / 58.781 |
| R2 art-off | 11.677 / 11.626 / 11.609 | 11.609 / 11.626 / 11.677 |

Observed median setup reduction: 35.84%. Every R2 run below every G1 run: True.

| Loaded cost | Art-off range | G1 range | R2 range | R2 art-off range |
| --- | --- | --- | --- | --- |
| Textures MiB | 217.08 to 217.08 | 1,307.77 to 1,307.77 | 867.07 to 867.07 | 217.08 to 217.08 |
| Buffers MiB | 80.26 to 80.67 | 206.11 to 212.84 | 206.11 to 212.84 | 80.26 to 80.67 |
| Video allocations MiB | 335.15 to 335.56 | 1,563.78 to 1,570.50 | 1,123.08 to 1,129.81 | 335.15 to 335.56 |
| Unique scene triangles including hidden | 786,695.00 to 795,113.00 | 2,420,221.00 to 2,503,669.00 | 2,420,221.00 to 2,503,669.00 | 786,695.00 to 795,113.00 |
| Unique scene meshes including hidden | 1,403.00 to 1,447.00 | 1,603.00 to 1,626.00 | 1,603.00 to 1,626.00 | 1,403.00 to 1,447.00 |

| Mode / view / light | Settled median min / median / max ms | Largest settled frame ms | Largest warmup frame ms | Largest focus call ms |
| --- | --- | --- | --- | --- | --- |
| art-off / paid-home / day | 1.910 / 1.916 / 1.943 | 2.950 | 207.905 | 100.104 |
| art-off / paid-home / dusk | 1.931 / 1.933 / 1.950 | 2.757 | 4.940 | 100.104 |
| art-off / paid-interior / day | 1.430 / 1.439 / 1.442 | 2.174 | 5.605 | 3.309 |
| art-off / paid-interior / dusk | 1.422 / 1.433 / 1.438 | 2.063 | 4.387 | 3.309 |
| art-off / paid-workshop / day | 2.001 / 2.031 / 2.062 | 3.167 | 9.283 | 18.505 |
| art-off / paid-workshop / dusk | 2.019 / 2.028 / 2.047 | 2.943 | 5.036 | 18.505 |
| art-off / source-trail / day | 1.248 / 1.250 / 1.359 | 2.279 | 10.936 | 345.955 |
| art-off / source-trail / dusk | 1.235 / 1.240 / 1.420 | 2.251 | 4.461 | 345.955 |
| G1 / paid-home / day | 3.482 / 3.521 / 3.525 | 5.232 | 363.815 | 711.173 |
| G1 / paid-home / dusk | 3.453 / 3.495 / 3.509 | 4.869 | 7.648 | 711.173 |
| G1 / paid-interior / day | 3.085 / 3.103 / 3.158 | 3.821 | 21.581 | 3.451 |
| G1 / paid-interior / dusk | 2.996 / 3.104 / 3.146 | 3.940 | 7.210 | 3.451 |
| G1 / paid-workshop / day | 3.718 / 3.734 / 3.779 | 4.975 | 20.320 | 1108.763 |
| G1 / paid-workshop / dusk | 3.744 / 3.758 / 3.774 | 4.423 | 8.053 | 1108.763 |
| G1 / source-trail / day | 2.674 / 2.713 / 2.713 | 3.479 | 13.636 | 3697.776 |
| G1 / source-trail / dusk | 2.671 / 2.681 / 2.681 | 3.579 | 6.338 | 3697.776 |
| R2 / paid-home / day | 3.434 / 3.531 / 3.546 | 4.714 | 316.014 | 537.987 |
| R2 / paid-home / dusk | 3.448 / 3.481 / 3.483 | 4.520 | 7.750 | 537.987 |
| R2 / paid-interior / day | 3.090 / 3.112 / 3.137 | 4.932 | 11.523 | 3.659 |
| R2 / paid-interior / dusk | 3.113 / 3.128 / 3.158 | 4.856 | 7.059 | 3.659 |
| R2 / paid-workshop / day | 3.762 / 3.767 / 3.836 | 5.141 | 17.232 | 631.257 |
| R2 / paid-workshop / dusk | 3.717 / 3.729 / 3.750 | 4.797 | 8.020 | 631.257 |
| R2 / source-trail / day | 2.681 / 2.694 / 2.723 | 3.616 | 14.092 | 2045.204 |
| R2 / source-trail / dusk | 2.654 / 2.692 / 2.708 | 3.341 | 6.181 | 2045.204 |
| R2 art-off / paid-home / day | 1.891 / 1.898 / 1.927 | 2.669 | 209.671 | 98.806 |
| R2 art-off / paid-home / dusk | 1.873 / 1.880 / 1.911 | 2.552 | 4.986 | 98.806 |
| R2 art-off / paid-interior / day | 1.408 / 1.442 / 1.450 | 2.083 | 5.501 | 3.294 |
| R2 art-off / paid-interior / dusk | 1.421 / 1.424 / 1.426 | 2.053 | 4.363 | 3.294 |
| R2 art-off / paid-workshop / day | 2.007 / 2.021 / 2.034 | 2.602 | 8.909 | 18.423 |
| R2 art-off / paid-workshop / dusk | 2.018 / 2.021 / 2.055 | 2.594 | 5.706 | 18.423 |
| R2 art-off / source-trail / day | 1.228 / 1.247 / 1.268 | 1.897 | 9.291 | 341.977 |
| R2 art-off / source-trail / dusk | 1.243 / 1.246 / 1.279 | 1.844 | 4.756 | 341.977 |

## gl_compatibility

Actual device: NVIDIA GeForce RTX 5090 / AMD Ryzen 9 9950X3D 16-Core Processor; 3.3.0 NVIDIA 591.86.

| Mode | Each setup, seconds | Setup min / median / max, seconds |
| --- | --- | --- |
| art-off | 11.186 / 11.086 / 11.125 | 11.086 / 11.125 / 11.186 |
| G1 | 86.889 / 87.130 / 87.223 | 86.889 / 87.130 / 87.223 |
| R2 | 56.874 / 56.680 / 56.785 | 56.680 / 56.785 / 56.874 |
| R2 art-off | 11.428 / 11.249 / 11.135 | 11.135 / 11.249 / 11.428 |

Observed median setup reduction: 34.83%. Every R2 run below every G1 run: True.

| Loaded cost | Art-off range | G1 range | R2 range | R2 art-off range |
| --- | --- | --- | --- | --- |
| Textures MiB | 69.49 to 69.49 | 1,288.49 to 1,288.49 | 789.82 to 789.82 | 69.49 to 69.49 |
| Buffers MiB | 77.71 to 78.12 | 203.89 to 210.61 | 203.89 to 210.61 | 77.71 to 78.12 |
| Video allocations MiB | 147.20 to 147.61 | 1,492.38 to 1,499.10 | 993.71 to 1,000.43 | 147.20 to 147.61 |
| Unique scene triangles including hidden | 786,695.00 to 795,113.00 | 2,420,221.00 to 2,503,669.00 | 2,420,221.00 to 2,503,669.00 | 786,695.00 to 795,113.00 |
| Unique scene meshes including hidden | 1,403.00 to 1,447.00 | 1,603.00 to 1,626.00 | 1,603.00 to 1,626.00 | 1,403.00 to 1,447.00 |

| Mode / view / light | Settled median min / median / max ms | Largest settled frame ms | Largest warmup frame ms | Largest focus call ms |
| --- | --- | --- | --- | --- | --- |
| art-off / paid-home / day | 4.930 / 4.948 / 5.001 | 6.040 | 192.838 | 94.421 |
| art-off / paid-home / dusk | 5.001 / 5.010 / 5.014 | 7.079 | 6.872 | 94.421 |
| art-off / paid-interior / day | 3.191 / 3.247 / 3.284 | 4.420 | 30.261 | 3.923 |
| art-off / paid-interior / dusk | 3.215 / 3.239 / 3.263 | 4.542 | 5.072 | 3.923 |
| art-off / paid-workshop / day | 4.752 / 4.762 / 4.796 | 5.567 | 21.397 | 18.230 |
| art-off / paid-workshop / dusk | 4.760 / 4.798 / 4.833 | 6.437 | 6.592 | 18.230 |
| art-off / source-trail / day | 2.535 / 2.564 / 2.597 | 3.427 | 24.687 | 341.408 |
| art-off / source-trail / dusk | 2.544 / 2.547 / 2.568 | 3.590 | 4.338 | 341.408 |
| G1 / paid-home / day | 5.965 / 5.966 / 5.998 | 7.911 | 263.839 | 676.681 |
| G1 / paid-home / dusk | 5.890 / 5.981 / 6.021 | 7.420 | 8.800 | 676.681 |
| G1 / paid-interior / day | 5.044 / 5.145 / 5.167 | 6.518 | 69.348 | 4.580 |
| G1 / paid-interior / dusk | 5.047 / 5.184 / 5.295 | 7.434 | 10.401 | 4.580 |
| G1 / paid-workshop / day | 5.651 / 5.663 / 5.675 | 7.543 | 41.634 | 1099.907 |
| G1 / paid-workshop / dusk | 5.663 / 5.669 / 5.740 | 7.986 | 8.977 | 1099.907 |
| G1 / source-trail / day | 4.481 / 4.514 / 4.522 | 5.951 | 19.358 | 3625.014 |
| G1 / source-trail / dusk | 4.526 / 4.572 / 4.579 | 5.765 | 7.697 | 3625.014 |
| R2 / paid-home / day | 5.940 / 5.950 / 6.035 | 8.062 | 265.892 | 488.870 |
| R2 / paid-home / dusk | 5.922 / 5.950 / 6.085 | 7.730 | 9.059 | 488.870 |
| R2 / paid-interior / day | 5.061 / 5.149 / 5.152 | 7.253 | 44.419 | 3.537 |
| R2 / paid-interior / dusk | 5.064 / 5.083 / 5.692 | 9.764 | 8.179 | 3.537 |
| R2 / paid-workshop / day | 5.690 / 5.695 / 5.743 | 9.110 | 40.156 | 662.427 |
| R2 / paid-workshop / dusk | 5.627 / 5.627 / 5.693 | 7.147 | 8.905 | 662.427 |
| R2 / source-trail / day | 4.490 / 4.514 / 4.516 | 6.074 | 17.920 | 2047.839 |
| R2 / source-trail / dusk | 4.479 / 4.515 / 4.553 | 6.146 | 7.499 | 2047.839 |
| R2 art-off / paid-home / day | 4.954 / 4.962 / 4.975 | 5.811 | 296.898 | 94.592 |
| R2 art-off / paid-home / dusk | 4.924 / 4.926 / 4.943 | 6.377 | 7.201 | 94.592 |
| R2 art-off / paid-interior / day | 3.138 / 3.239 / 3.305 | 4.260 | 20.076 | 3.365 |
| R2 art-off / paid-interior / dusk | 3.230 / 3.252 / 3.274 | 4.283 | 5.534 | 3.365 |
| R2 art-off / paid-workshop / day | 4.745 / 4.775 / 4.794 | 6.047 | 21.052 | 18.179 |
| R2 art-off / paid-workshop / dusk | 4.744 / 4.774 / 4.801 | 5.679 | 6.603 | 18.179 |
| R2 art-off / source-trail / day | 2.528 / 2.542 / 2.563 | 3.286 | 15.695 | 336.436 |
| R2 art-off / source-trail / dusk | 2.519 / 2.520 / 2.561 | 3.222 | 4.543 | 336.436 |
