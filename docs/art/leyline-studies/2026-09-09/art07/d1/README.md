# ART-07D1 actual model evidence

Ten directly modelled core lattice pieces at the unchanged native metre sizes.
The source candidate is `models-v06`, based on game/data/native revision
`56ce6bbe343012205690cf669491372958b80662`. Owner visual acceptance is pending.

The Blender overview and six-angle sheets show the actual packed source in
provisional colour and neutral clay. Godot images show the actual exported GLBs
through the existing native placement/body/material path in a copied game.
The posed scene uses native automatic wall seam posts; these are existing game
geometry, not additional D1 exports. The isolated checks separately exercise
paid coarse placement and fresh-process saves with explicitly granted stock.

Both renderer sets include catalogue, native L-corner/support/ceiling, neutral,
shade, dusk and underside images. Each `*-orbit.webp` contains 48 actual captured
camera positions in order, resized to 960 × 600 and compressed for chat review
(83 ms per displayed frame). Raw 1440 × 900 PNG sequences are in the handoff.
This is a static kit: orbiting the camera does not imply moving assets or a pulse.

| Renderer | Distance parameter | p50 ms | p95 ms | Worst ms | Draws | Primitives |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Forward+ | 6 m | .399 | .698 | .913 | 32 | 26,380 |
| Forward+ | 12 m | .394 | .685 | .829 | 57 | 35,106 |
| Forward+ | 24 m | .391 | .646 | .810 | 116 | 46,706 |
| Compatibility | 6 m | .514 | .575 | 1.005 | 131 | 26,380 |
| Compatibility | 12 m | .541 | .617 | .700 | 181 | 35,106 |
| Compatibility | 24 m | .576 | .642 | .876 | 251 | 46,706 |

Conditions: RTX 5090, driver 591.86, Godot 4.5 stable, 1440 × 900, VSync off,
uncapped, same static native gallery, 180 warmup and 360 sampled process-frame
intervals per distance. Captures, encoding, generation and compilation were absent
during the two separate benchmark processes. These are engine frame intervals,
not GPU timestamp measurements or a normal play-session frame-rate guarantee.
Farther views include more objects; there is no LOD switching or isolated shadow
pass timing. Whole-review texture memory was 96,584,192 bytes in Forward+ and
12,949,532 in Compatibility; video memory was 138,442,064 / 47,698,212 bytes.
These totals include the native materials, authored ground and review objects.
No lower-spec device or integrated campaign performance approval is claimed.

All ten meshes total 3,408 triangles, one surface each, and 494,000 GLB bytes.
The small provisional Blender colour maps and the native family shaders differ;
the material-production slices still own final material richness. Compatibility
is brighter under the same light settings. Thin grooves can alias at distance;
observed module contacts retain their fitted native envelopes. Neutral inspection
and the actual orbit sequences are provided for the owner's visual review.

The receipt in `docs/prototype/art07-production/receipts/d1.md` records the local
handoff, exact commands, checks, hashes and publication status. `geometry-manifest.json`
lists selected runtime hashes, and `original-inputs-final.json` rechecks
all 45 original source, input, manifest and binary hashes without changing them.
`handoff-verification.json` records the final fresh-copy checks: all 110 Godot
PNGs match the canonical captures byte for byte, all ten GLB audits pass, and
the canonical handoff's 1,597 file hashes remain unchanged after verification.
