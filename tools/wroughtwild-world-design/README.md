# ART-07 design catalogue tools

This directory authors and validates the environment/placeable **design pass**.
It never edits gameplay, tuning, source meshes or saves. Current production
briefs live in `catalogue.py`; generated readable/machine inventories live in
`docs/art/concepts/environment/2026-09-09-frontier/`.

Run from the repository root with the existing Python runtime:

```powershell
python tools/wroughtwild-world-design/catalogue.py
python tools/wroughtwild-world-design/verify_art.py
```

`catalogue.py --write` regenerates the two catalogue files after deliberately
reviewing changed game inputs or design briefs. The default is read-only and
fails on missing/stale briefs or inventory output. It cross-checks recipes with
native kit discovery and stations, reads body dimensions from current Godot
sources, and applies the existing native material trait contract. The resulting
273 pairings include valid fine shapes and preserve every material restriction.
World/era gates are recorded separately; a legal pair is not a new unlock.

`verify_art.py` checks PNG integrity and hashes, exact submitted prompt bytes,
edit-parent identity, generated-original copies where locally available,
and local Markdown targets. Original generator paths are provenance, not a
checkout dependency; missing local originals do not prevent verifying the
versioned PNG against its recorded hash. Image generation itself is performed
with the built-in image tool, not this script or a paid-service CLI.

Text is stored as UTF-8 LF. Game-source hashes intentionally normalise CRLF to
LF for Git portability; image and submitted-prompt hashes are exact bytes.
The tools introduce no tuning knobs. Sizes and costs in the catalogue are
snapshots of authoritative existing data, not values to apply back to the game.

The gallery records visual limitations. These broad boards need individual
multi-view production images before organic generation; grid pieces and
mechanisms need precise Blender modelling. No raw scene-board-to-mesh export
is accepted as a usable modular kit.
