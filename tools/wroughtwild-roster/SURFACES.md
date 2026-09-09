# ART-06B — attached scars on the six selected creatures

Six packed Blender surface sources and a standalone Godot viewer retain the
approved grotesque forms. Shallow physical fractures contain separate core,
damage and travel data in a 2048-pixel UV atlas. Original base/ORM textures are
retained byte-for-byte. The pulse uses an explicit review clock and stops on
pause; no native enemy, work or save clock drives this ambient study.

Run **Launch scar review.ps1** from the local package. It uses the installed
Godot 4.5 executable or accepts `-Godot PATH`, with isolated APPDATA.

- **0** shows all six; **1–6** selects one creature.
- **M** cycles dark damage, steady light, breathing and travelling light.
- **Space** pauses/resumes the light; **Escape** closes the review.
- **Left/right arrows** orbit a selected creature, including while paused;
  **R** restores the original orientation.

These are dense unrigged surface sources. Ordinary-game meshes are unchanged.
Blender shows static peak/off states; the live pulse is implemented in Godot.
Native tell/status adapters, deformation, movement and game-scale collision
remain later work. No later-era body additions are installed in this pass.

## Reproduce

Use the installed pinned Blender 4.5 and Godot 4.5, and fresh ignored output
directories. The source version per creature is retained in `roster.json`.
The selected surface revision is `v04`; older bake directories retain rejected
or superseded review results. No external generation or new dependency is used.

```text
blender --background --python-exit-code 1 --python tools/wroughtwild-roster/build_surfaces.py -- ASSET build/roster-art06b/ASSET-surface-v04
blender --background --python-exit-code 1 --python tools/wroughtwild-roster/render_surfaces.py -- build/roster-art06b/ASSET-surface-v04 build/roster-art06b/ASSET-renders-v04
python tools/wroughtwild-roster/prepare_surfaces.py build/roster-art06b/NEW_REVIEW
godot --headless --path REVIEW --editor --import
godot --path REVIEW -- --check
godot --path REVIEW --rendering-method forward_plus -- --check
godot --path REVIEW -- --capture
python tools/wroughtwild-roster/package_surfaces.py REVIEW NEW_HANDOFF NEW_EVIDENCE
```

Run the Blender commands for each of the six IDs. Preserve each renderer's
`checks.json` as `build/roster-art06b/compatibility-checks.json` and
`forward-checks.json` before the next check overwrites it. Packaging expects
the final six surface/reopening results and both renderer checks. It preserves
actual views and produces a four-second animation from actual engine frames.

## Controls and limits

`surface-study.json` explains every art control. Review sources have a longest
dimension of two studio units, not selected gameplay metres. Damage/core
half-widths are 0.024/0.006 units with small object-space edge variation. The
incision never exceeds 0.002 units and is further limited by local edge length
and triangle altitude; a face must keep its original orientation after float32
export rounding. This is a surface-safe refinement, not wholesale retopology.

The existing source atlas keeps the map attached across rigid transforms and
reserves it for later skinning. Articulated stretching still requires fitted
weights and deformation tests. Small light gaps on rough wool/overlapping
plates are retained rather than bridged through empty space. The ordinary
material remains dominant; fractures do not cover the entire animal.

The shader uses the earlier fauna pulse grammar: four-second period, 22%
minimum, 2.8 peak and 0.20 crest width. Palette is presentation only. Darkening
multiplies the original texture, preserving its variation inside the injury.
There is no bloom, dynamic light, invented attack or changed gameplay state.
The static Blender peak and Godot's steady/animated intensity are separately
labelled comparisons, not a renderer colour-match certification.
