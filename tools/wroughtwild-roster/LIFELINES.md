# ART-06C — deep living channels and porcupine face

Six dense editable sources extend the approved mutations into broad, branching
lifelines. Their apparent depth comes from measured mesh incisions. The UV mask
holds energy inside the darker injury, and pulse travel derives from connected
surface distances. All six original TRELLIS GLBs remain unchanged.

The porcupine retains its blunt nose, small ears and natural dark eyes. Coarse
projecting whiskers are trimmed, their roots blended, and ten fine tapered
whiskers replace the rigid fan. Two small non-emissive lenses fit measured eye
sockets. These parts are tagged for a future head rig; no rig exists yet.

The repaired muzzle has a separate UV strip, baked from clean original surface
colour. Its 2048×2560 albedo/ORM atlases retain every original 2048×2048 pixel
above the added strip. Original PNG bytes are also retained separately. The
other five creatures keep their original texture files unchanged.

Run **Launch lifeline review.ps1** inside the local handoff. It uses an isolated
APPDATA and the installed Godot 4.5, or accepts `-Godot PATH`.

- **0** shows all six; **1–6** selects a creature.
- **M** cycles dark, steady, breathing and travelling light.
- **Space** pauses the pulse; **arrows** orbit; **R** resets; **Escape** exits.

## Reproduction

Use fresh ignored directories. Source versions are recorded in `roster.json`.
The final selected outputs are `build/roster-art06c/ASSET-surface-v02` and
`ASSET-renders-v02`; earlier numbered candidates remain local inspection history.

```text
blender -b --python-exit-code 1 --python tools/wroughtwild-roster/build_surfaces.py -- ASSET NEW_SOURCE --config lifeline-study.json
blender -b --python-exit-code 1 --python tools/wroughtwild-roster/render_surfaces.py -- SOURCE NEW_RENDERS
python tools/wroughtwild-roster/prepare_surfaces.py NEW_REVIEW --lifelines
godot --headless --path REVIEW --editor --import
godot --path REVIEW -- --check
godot --path REVIEW --rendering-method forward_plus -- --check
godot --path REVIEW -- --capture
python tools/wroughtwild-roster/package_lifelines.py REVIEW NEW_HANDOFF NEW_EVIDENCE
```

Add `--face` to the porcupine reopening command for front and oblique close-ups.
Preserve the renderer outputs as `compatibility-checks.json` and
`forward-checks.json` in the ART-06C build root before the next check replaces
`checks.json`. Packaging verifies measured depth, exact imports, original
textures, repaired atlas pixels, masks, both renderers and captured pulse.

## Art controls and limits

`lifeline-study.json` documents the controls. The longest source dimension is
two studio units, not game metres. Maximum geometric recession is 0.032 units;
its smooth falloff spans a 0.078-unit half-width. Dark damage/core half-widths
are 0.063/0.026, with branch taper and deterministic edge variation. The thin
0.002 bump is additional surface texture and is not counted as physical depth.
Each exposed route must measure a median of at least 0.012 units, with at least
0.014 across the model. Actual before/after BVH rays are retained in reports.

The four-second pulse uses 32% residual light, 2.4 peak emission and a 0.20 crest
width. A 0.045-unit timing join connects neighboring branches on the same flank.
It adds no geometry across a cavity. Separate exposed networks retain separate
roots; fur and overlapping plates can conceal parts of the channels. The pulse
is ambient anatomy, with no healing, attack, work or gameplay meaning assigned.

Face envelope width/flare restrict removal to measured coarse whiskers; twenty
local smoothing iterations blend their roots. Whiskers taper from 0.0009-unit
radius. The 512-row texture strip reserves unique UV space for the repaired
muzzle. These source-specific operations are not a generic creature generator.

Blender renders static off/peak states; Godot verifies live travel without bloom.
Rigs, deformation, runtime detail levels, era growth, body/attack fit, native
adoption and populated-world performance remain later work. Raw source texture
and fur imperfections remain visible at extreme close range.
