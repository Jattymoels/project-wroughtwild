# Wroughtwild ART-03 recipe

Bounded source-specific finishing and isolated review for Rimejaw and Vaultcrown.
See the [result](../../docs/art/leyline-studies/2026-09-09/fauna-art03/README.md)
and [work item](../../docs/prototype/fauna-art-2026-09-09.md) before reuse.
The fitted masks/bones are for these exact sources, not a general auto-rigger.

## Rebuild and inspect

Run from the repository root with the already installed Blender 4.5.9 LTS,
Godot 4.5 and the existing Python/NumPy/Pillow runtime. No package installation
or paid service is required. Every build/prepare step expects a **fresh output**.
Keep Blender user resources and Godot APPDATA inside the isolated build folder.
For Blender use `-b --python-exit-code 1 --python SCRIPT -- ARGUMENTS`; the explicit
Python exit code prevents Blender reporting success after a script assertion.

| Step | Script | Arguments after `--` / PowerShell parameters |
| --- | --- | --- |
| Original wolf inspection | `inspect_wolf.py` | new output directory |
| Wolf face/jaw finishing | `finish_wolf.py` | new output directory |
| Wolf scar maps | `build_surface.py` | finished `.blend`, new surface directory |
| Wolf skin/bake/detail levels | `build_rig.py` | surface directory, new rig directory |
| Stag local source | `generate-source.ps1` | `-InputImage ... -Output ...` |
| Stag inspection/normalization | `inspect_stag.py` | source GLB, new inspection directory, yaw `180` degrees |
| Stag eyes | `finish_stag.py` | normalized `.blend`, new finish directory |
| Stag scars | `build_stag_surface.py` | finished `.blend`, new surface directory |
| Stag skin/bake/detail levels | `build_stag_rig.py` | surface directory, new rig directory |
| Reopen wolf source | `audit_source.py` | candidate `.blend`, `rig-report.json`, new audit JSON |
| Reopen stag source | `audit_stag_source.py` | candidate `.blend`, `rig-report.json`, new audit JSON |

`probe_wolf.py` / `probe_stag.py` recover actual source surface positions from
inspected Blender image pixels. `render_wolf.py` provides close source/working
views. Read each script's documented arguments; these are inspection aids, not
procedural anatomy guesses. The exact stag reference prompt is `stag-prompt.txt`.
The original input is retained in the result directory; source generation used
the existing local runtime/model installation recorded by the TRELLIS toolset.

Final delivered chains:

- Wolf: `wolf-finish-v05` → `wolf-surface-v03` → `wolf-rig-v06` → `wolf-review-v04`.
- Stag: `stag-source-v01` → `stag-inspect-v01` → `stag-finish-v01` →
  `stag-surface-v01` → `stag-rig-v06` → `stag-review-v04`.

All are beneath `build/fauna-art03/`. Earlier revisions preserve actual rejected
tests/renders; do not mistake an old structural pass for the final visual result.

## Godot review and packaging

```powershell
& tools/wroughtwild-fauna/prepare_review.ps1 -Surface build/fauna-art03/wolf-surface-v03 -Rig build/fauna-art03/wolf-rig-v06 -Output build/fauna-art03/wolf-new-review
& tools/wroughtwild-fauna/run_review.ps1 -Godot 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -Project build/fauna-art03/wolf-new-review -Mode Import
& tools/wroughtwild-fauna/run_review.ps1 -Godot 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -Project build/fauna-art03/wolf-new-review -Mode Check
```

Use `prepare_stag_review.ps1` for the stag. Then `run_review.ps1` modes `Capture`
and `Benchmark` create evidence and measurements. Run benchmarks sequentially
with no other capture/generation jobs competing. `Review -Visible` explicitly
opens only that isolated project. Space pauses; A changes pose; M light; L
day/shade; D detail; S status override; arrow keys move the camera. P/B compare
pulse period/minimum. The project never loads the game's autoloads or extension.

`prepare_gallery.ps1 -WolfReview ... -StagReview ... -Output ...` copies the
approved ART-02 grove and adds the two candidates and unchanged moth for context.
It preserves the original grove; `run_review.ps1` Import/Capture operate on the
copy. It samples existing ground for near-level rest-pose support and shows one
animal at a time. This is not a spawning, worldgen or gameplay integration tool.

With ordinary Python:

```text
validate.py REVIEW wolf|stag OUTPUT.json
encode_evidence.py REVIEW wolf|stag NEW_OUTPUT
package_handoff.py WOLF_REVIEW STAG_REVIEW WOLF_RIG STAG_RIG GALLERY NEW_OUTPUT
```

Validation reads the actual GLB streams, rather than trusting recipe targets.
Evidence encoding only resizes/encodes real engine frames. Inspect stills and
sampled moving views before accepting an export. The package contains packed
sources, clean review projects and evidence; perform fresh Import/Check runs on
its copied animal projects. Record a manifest of intended package files before
adding any imported cache. Keep generated builds, engine artefacts and local
sources under ignored `build/`; commit only recipes, original reference input,
selected evidence and reports.

## Controls and limitations

`wolf.json` / `stag.json` store source hashes, scale, measured eye targets,
surface fracture paths, colour and pulse settings with plain-language purposes.
`*-rig.json` stores detail targets, normal-map size, gait/pose range and connected
weight diffusion passes. The wolf's `_hoof` bone suffix is retained by this
small shared checking convention; it denotes a paw sole on the wolf.

Both use a 4 s pulse, 22% minimum, 2.8 peak, 0.2 crest and shader normal depth
0.65. Scar widths are expressed as half-widths: wolf 18 mm dark / 5 mm core,
5 mm maximum incision; stag 25 / 6 mm, 6 mm incision. Branch travel is a linear
mask channel separate from core and damage. No gameplay tuning is introduced.
The warm/cool shader input colours are converted from linear to sRGB at binding.

Surface-fit cut planes, bone landmarks, crown masks and smoothing anchors are
specific authoring coordinates in metres, not game balance controls. Preserve
the head/crown and sole anchors when changing them; rerun floor, edge extension
and crown checks. The current rig uses four maximum weights per vertex and
100 Hz exported transform keys. Deep stag grazing is deliberately outside its
reviewed plate-deformation range; the delivered six-second `graze` clip browses
low plants. The mesh still needs appropriate retopology/animation polish for
production. Native movement, body fitting, collision, status/combat adapters and
normal-world performance have separate acceptance requirements.
