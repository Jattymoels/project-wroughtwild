# Emberroot Grove — ART-02

An isolated 38.3 m woodland walk using the approved boar and six environment
roles. [Scope, actual evidence and limits](../../docs/prototype/affected-grove-2026-09-09.md).
This folder never loads the game extension or normal saves.

## Delivered local files

`build/grove-art02/emberroot-handoff/` contains the packed editable composition,
tree/rock finishing sources, normal-bake source, clean Godot project, review
images/animations and SHA-256 manifest. Open `editable/emberroot-grove.blend`
to rearrange the setting. Its 25 packed images, boar armature and six actions
reopen. Blender shows **steady** emission; Godot supplies the exact moving light
and lighting comparisons. Manual Blender edits are not reverse-translated into
the recipes: preserve them before rebuilding.

The clean handoff was copied to `build/grove-art02/handoff-reimport/` and
reimported/checked there. Importing the clean delivery in place will add Godot
caches and rewrite import recipes; those are not part of its original manifest.

```powershell
& tools/wroughtwild-grove/run_review.ps1 -Godot C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Project build/grove-art02/emberroot-handoff/review -Mode Review -Visible
```

WASD/mouse walk/look; L cycles day/shade/dusk; M toggles scars; Space pauses
cosmetic motion and movement; R returns to the beginning; Escape releases the
mouse. There is no harvesting, inventory, enemy AI or combat here. The runner
uses its own APPDATA, defaults to a hidden window, prints its PID and may stop
only a process it just created if that process reports a script/shader error.

## Sources and prompts

Three original images were generated with the **built-in image-generation tool**:

- [Tree input](../../docs/art/leyline-studies/2026-09-09/grove-art02/tree-input-v01.png),
  exact [tree prompt](tree-prompt.txt).
- [Rock input](../../docs/art/leyline-studies/2026-09-09/grove-art02/rock-input-v01.png),
  exact [rock prompt](rock-prompt.txt).
- [Forest-floor albedo](../../docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png),
  exact [floor prompt](floor-prompt.txt). The shader blends offset/rotated samples;
  generated seamlessness is not assumed to be mathematically exact.

The already installed local TRELLIS v0.6.0 CUDA route reconstructed the tree
and rock at resolution 1024, seed 42, PNG textures, eight CPU threads. No new
package, model download, subscription or hosted 3D service was added.
Raw exports remain untouched under `build/grove-art02/tree-source-v01/tree.glb`
and `rock-source-v01/rock.glb`; hashes and complete arguments are in the evidence.
The boar input is the existing ART-01 clean review handoff, unchanged.

## Reproduce

Use Blender 4.5.9, the existing Python with NumPy/Pillow, and Godot 4.5. Set
`BLENDER_USER_RESOURCES` to an ignored task folder before background Blender runs.
Every authoring command requires **fresh output directories**. The outline
below uses placeholders; all paths are relative to the repository.

```text
generate-source.ps1 -InputImage TREE_INPUT -Output RAW_TREE -Asset tree
generate-source.ps1 -InputImage ROCK_INPUT -Output RAW_ROCK -Asset rock
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/prepare_tree.py -- RAW_TREE/tree.glb TREE_INSPECTION
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/prepare_tree.py -- RAW_ROCK/rock.glb ROCK_INSPECTION rock
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/finish_host.py -- TREE_INSPECTION/tree-source.blend tools/wroughtwild-grove/grove.json TREE
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/finish_host.py -- ROCK_INSPECTION/rock-source.blend tools/wroughtwild-grove/rock.json ROCK
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/bake_tree_normal.py -- TREE/tree-finished.blend NORMAL
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/build_grove.py -- TREE tools/wroughtwild-grove/grove.json KIT ROCK
prepare_review.ps1 -Tree TREE -Kit KIT -Rock ROCK -Normal NORMAL -Boar ART01_REVIEW -Output REVIEW
run_review.ps1 -Godot GODOT -Project REVIEW -Mode Import
run_review.ps1 -Godot GODOT -Project REVIEW -Mode Check
run_review.ps1 -Godot GODOT -Project REVIEW -Mode Capture
run_review.ps1 -Godot GODOT -Project REVIEW -Mode Benchmark
run_review.ps1 -Godot GODOT -Project REVIEW -Mode Walk
python tools/wroughtwild-grove/verify.py REVIEW VERIFY.json
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/assemble_editable.py -- KIT REVIEW EDITABLE
blender --background --threads 8 --python-exit-code 1 --python tools/wroughtwild-grove/audit_sources.py -- AUDIT.json EDITABLE/emberroot-grove.blend TREE/tree-finished.blend ROCK/rock-finished.blend NORMAL/tree-normal-bake.blend
python tools/wroughtwild-grove/package.py REVIEW EDITABLE TREE ROCK NORMAL NEW_HANDOFF
```

The PowerShell filenames in that outline are under `tools/wroughtwild-grove/`.
Pinned delivered inputs: tree finish v03, rock finish v01, normal v01, kit v05,
review v06, editable v01. Earlier study folders contain rejected/intermediate
geometry and are not the delivered candidates. A clone alone does not contain
the raw local generated GLBs or packed working masters.

## Controls and limits

`grove.json` explains scale, seed, leaf shape/density, canopy detail distances,
route, review lighting and scar controls. `rock.json` contains its inspected
surface paths. `landform.py` and the authored placement section of
`build_grove.py` describe this one composition, including stream banks and the
background rise. These are asset/layout authoring coordinates, not a new world
generator. The physical review capsule is 0.32 m radius and 1.8 m tall; it does
not replace the game's player or enemy bodies.

Host base/ORM/scar/normal maps remain separate. Scar RGB means core/dark
damage/travel; only base colour uses sRGB. The quiet tree binds an empty scar
mask. The grove explicitly reuses a copy of the ART-01 scar shader, with a
pause-aware clock, four-second period, 2.8 peak and 22% minimum. No bloom or
per-scar lights. This is ambient presentation, never a ready/work/attack signal.

The detailed and distant canopies contain the same 780 attached sprays;
individual leaves retain lobed outlines near the observer and simpler folded
outlines beyond 18 m, with a 2 m fade. Exact sources, geometry, counts and
measurements are recorded in the result. Broader tree/understory LODs, compressed
textures, automatic host placement, real-world streaming and lower-spec testing
remain later integration work.
