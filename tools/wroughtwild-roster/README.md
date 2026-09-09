# ART-06 remaining animal source review

The later [ART-06B surface handoff](SURFACES.md) adds individually attached
fracture maps, safe shallow incisions and actual travelling light to these
preserved sources. This document retains the earlier raw-source recipe.

This is the design and **unrigged source** stage of the existing imagegen → local
TRELLIS → Blender → Godot pipeline. It contains six new ordinary-mob animal
directions with stronger structural corruption. Extra physical augmentations per
existing era are the owner's continuing direction, not implemented variants here.
Normal game meshes, bodies, saves, spawning and progression are not replaced.

The six species are porcupine (Cinder Archer), bighorn ram (Stone Husk), crane
(Shrieker), ground beetle (Gloom Crawler), dragonfly nymph (Bog Lurker) and
tortoise (Hollow Knight). The original armadillo proposal was rejected as too
close to the boar and was never sent to TRELLIS. Boar, wolf, stag and moth retain
their liked sources. The Conservator remains human; boss finishing is later.

## Review locally

Run **Launch source review.ps1** in the generated source handoff. It uses the
installed Godot 4.5 executable, or accepts `-Godot PATH`. The review has its own
APPDATA and no game/simulation/save autoloads. It compares source geometry in
uniform studio units; it does not promise gameplay size or body fit.

- 1–6: choose the animal.
- B: compare the earlier approved ancestry concept's source and stronger source.
- C: clay/material comparison.
- Space: rotate; arrows: orbit, including below the body.
- Escape: close.

Each `sources/ANIMAL/` includes the packed editable Blender inspection source,
seven actual geometry renders, concept inputs, exact stronger prompt, generation
provenance and reopening checks. `review/assets/` contains untouched before/after
GLBs. The stronger concept is `v02`, except the ram's `v03` and nymph's `v04`.
The ram's v01 was the rejected armadillo. The nymph's v02 generated eight legs;
v03 still had ambiguous attachments and was not generated. The v04 dorsal view
makes the three-pair anatomy explicit. Source bytes are hashed independently
of engine imports; a successful import is not an anatomy acceptance check.

## Reproduce from the repository

All jobs use fresh ignored output directories. No extra service, package or
global install is required. Use the previously installed local TRELLIS runtime,
Blender 4.5 and Godot 4.5. Built-in image generation/editing made the concept PNGs;
the adjacent exact prompt files record inputs and revisions.

```powershell
./tools/wroughtwild-roster/generate-source.ps1 -Asset cinder_archer -InputImage docs/art/concepts/creatures/2026-09-09-roster/cinder_archer-v02.png -Output build/roster-art06/cinder_archer-source-rebuild
```

TRELLIS settings match the earlier local animal pipeline: pinned v0.6.0,
resolution 1024, seed 42, GPU required, BiRefNet with retained cutout, PNG export,
eight CPU threads. Run one GPU generation at a time. The pinned model/release
manifest remains in `tools/wroughtwild-trellis/install-manifest.json`.

Blender commands, using `--background --python-exit-code 1 --python SCRIPT --`:

```text
inspect_source.py SOURCE.glb NEW_INSPECTION
verify_reopen.py INSPECTION NEW_RESULT.json
```

Inspection uniformly centres and scales only the review object, preserving the
raw GLB. It counts actual buffers, tests finite geometry and records degenerate
faces, texture presence and the source's lack of skin/animation/emission maps.
Front/side meanings must be established from the animal; azimuth labels describe
the imported coordinate system. Clay/top/underside views expose failure areas.
The packed Blender source is reopened and its mesh streams compared exactly.

With ordinary Python:

```text
prepare_review.py NEW_REVIEW
package_sources.py CHECKED_REVIEW NEW_HANDOFF
```

Import with Godot `--headless --path REVIEW --editor --import`. Use a real renderer
for `--path REVIEW -- --check` and `-- --capture`; no normal game project or native
DLL is involved. `--rendering-method forward_plus` selects the additional renderer
check; the default source viewer is Compatibility. Do not call this a full-world
performance or minimum-hardware certification.

## Meaning and limits

These are textured dense generated sources, **not finished animated game assets**.
Source generation does not supply independent pulse/core/flow masks, deformation
topology, animation, body fitting, status/tell integration or tested runtime LODs.
Raw illustration highlights are baked into albedo; no working magical pulse is
claimed. Preserve the no-glow dark scar and author attached light in finishing.
Do not flatten the source to an arbitrary low-poly budget to hide these gaps.

Before adoption, resolve the recorded anatomy defects, fit the actual gait and
combat poses, author scar masks, compare detail levels, and verify the real native
roles and retained collision. The upright legacy capsule does not automatically
fit the new animals. Later era additions require their own visual comparison and
must not change the existing three-era campaign or add combat rules.
