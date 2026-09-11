# ART-07F3 — Pullstone sorter and Ventlung bellows

An isolated, native-backed presentation handoff for `pullstone`, `ventlung`,
`magnetic_sorter`, and `ventlung_bellows`. Normal-world adoption and owner visual
acceptance are separate. See [CONTRACT.md](CONTRACT.md) for F4's unchanged bounds,
origins, native endpoints, stock identities, payment, work and refund contracts.

## Inputs and lineage

The game/data/native baseline is `4b5d89b376765fbf4d46049aa099e0bb154a82da`.
The dedicated branch is `codex/art07-f3`. The worktree is
`C:/Users/Matty/Dev/project-wroughtwild/build/art07/f3/worktree`.
All relative paths below start there. No tracked game, simulation, tuning,
catalogue, queue, other slice or normal save is changed.

The original single-object PNGs and exact image-generation prompts live in
`docs/art/leyline-studies/2026-09-09/art07/f3/`. Each was generated independently
with the built-in image tool, then processed locally by the approved Windows
TRELLIS route. Original PNG/cutout/GLB and all ten model hashes are recorded by
`provenance.py` and the immutable generation logs. The pinned release is v0.6.0;
the actual GLB identifies build commit `16f3109e82f3922033bfa62b83c42899678b7b6f`,
CUDA, 1024, seed 42, BiRefNet removal, PNG textures and eight CPU threads.

Selected raw files (never overwritten):

- `build/art07/f3/v03/pullstone/source.glb`:
  `16530d51bce2f5dd3af5d4b5abfe59cd34ffa2fdb9e126e8591592d0cb9a4946`
- `build/art07/f3/v02/ventlung/source.glb`:
  `b896196ed2c19be4012ea27f7948492ccc99a1b3363a1035fac0176833885e5b`

D4's checked h04 package contributes metric wood face/end albedo, normal and
ORM maps; D6's checked v04 package contributes iron. Their exact paths and
verified whole-package hashes are in `provenance.py`, the receipt, and package
provenance. Material inputs are read-only. The bellows uses wood and reed, with
no iron fitting that would imply an additional recipe cost.

`gpu-slot.ps1`, native freezing/building and check orchestration are bounded
F3-local derivatives of the inspected D6 helpers. `inspect_sources.py` follows
the existing grove/roster multi-angle inspection convention. Apparatus geometry,
scar deformation, runtime adapter, native review and packaging are F3-specific.

## Reproduction

Use the approved depot tools, without downloading or installing anything:

- Python: `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`
- Blender: `C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe`
- Godot: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe`

Actual invocations and exit codes are preserved beside each build run and in
the delivery receipt. Allocate a fresh version for every generated candidate.
The sequence is `provenance.py`, `generate.ps1` once per input,
`inspect_sources.py`, `build_assets.py`, `select_far.py`, `asset_cost.py`, `build-native.ps1` with
the explicit baseline revision, `freeze_game.py`, then `install_review.py`.
The installer accepts only an ignored F3 game copy. Start with a fresh frozen
copy if an install fails; partial copies are not handoffs.

Every Blender command uses `--background --threads 8 --python-exit-code 1`.
All rendered jobs use `queued-job.ps1` and `gpu-slot.ps1`, the shared
`Local\Wroughtwild-Art07-GPU` mutex and read-only process checks. A busy slot
causes a bounded defer; no foreign process is stopped. APPDATA and Blender user
resources are isolated and restored after launch. Run headless checks through
`run-godot.ps1`, never through the owner's normal project/save directory.

`run-godot.ps1 -Project <copied-game> -Output <fresh-log> -Mode import` imports
the project. Modes `checks`, `restart`, and `restart-depleted` exercise normal
placement/payment, mixed native sorting, priming/discharge, obstruction,
finite work, normal SaveManager, exact dismantling and separate-process reload.
Modes `capture` and `motion` accept `-Renderer forward_plus` or
`-Renderer gl_compatibility`. Run `benchmark` separately after compilers,
generation and captures have finished. A render process is never a benchmark.

`native_review.ps1` runs the current unchanged regression scenes. `native_checks.py`
compiles/runs current C++ core and world intensive checks with strict warnings.
The custom authored stage grants inspection ingredients to pay the real recipes;
it is not a first-hour acquisition or generated-region composition test.

`package.py <asset-folder> <copied-game> <fresh-handoff>` seals source, isolated
runtime, recipes, evidence and provenance. `fresh_copy.py <handoff> <fresh-copy>`
verifies every file before any import. Open the packed master and independently
import GLBs with `reopen.py <fresh-copy/source> <fresh-reopen-output>` in a new
Blender process. Never import the canonical sealed package in place.

## Review controls and limitations

In the copied game's `-- --interactive` mode: 0 overview, 1 Pullstone, 2 Ventlung,
3 sorter, 4 bellows, L grant/load the labelled mixed test batch, S sort, B prime,
R release through the existing target route, W perform ordinary finite source
work, F5 save and F9 restore the isolated checkpoint, Escape quit. A source's
normal work controls and device work panels remain authoritative. One prepared
seam is supplied for inspection; release consumes its wedge normally.

The recovered master closes touching raw triangles through a small voxel surface
recovery, followed by interpolated nearest-polygon UV transfer from the unchanged
surface donor. It does not transfer UVs from unrelated nearest vertices. The
original dense source and donor remain hidden, separately editable collections.
The texture transfer and lower LOD silhouette are candidates for owner review.
Host stone is a quiet, deliberately simple fitting around the authored organic
core; further weathering and environmental dressing are not implied complete.

Scar depth is measured by before/after BVH rays. `settings.json` explains each
art control. Original albedo/ORM stay separate from the linear R/G/B damage,
energy and travel channels. Zero emission and peak Blender images share their
camera/exposure; runtime movement uses accepted work and pauses with the tree.
The scar shader has no TIME input, bloom dependency or per-scar point light.

Near/middle/far variants are delivered for the finite source cores. The isolated
review switches these explicitly at a fixed camera to expose silhouette changes;
distance policies are left to later ordinary-world adoption. Devices use their
complete near core, with all frame and moving parts measured together. Texture
images are still the source 2048 maps and the D4/D6 maps; no lower-spec approval
or final streaming/LOD budget is claimed. Performance reports identify actual
hardware, scene, resolution, samples and renderer memory.

The selected asset folder is `build/art07/f3/v22/assets`, derived from v09.
`select_far.py` retains the rejected 3,750-triangle Ventlung far mesh in the
packed source and uses the cleaner 8,500-triangle middle geometry at far distance.
This conservative fallback retains the folded silhouette and does not claim any
further distance saving. Pullstone's near/middle/far exports are 18,000/6,500/1,400;
Ventlung's are 22,000/8,500/8,500. Complete devices are 22,040 and 25,284 triangles.

After making and verifying a disposable handoff copy, use its root launcher:
`./launch.ps1 -Mode import`, then `./launch.ps1 -Renderer forward_plus -Show`.
The explicit Show switch opens the interactive review for the owner; automated
validation launches stay hidden. Its saves live under the copy's `user/F3Native`.
The original sealed package is never launched or imported in place.
