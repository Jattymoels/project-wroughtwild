# ART-07R5 — chest visual seating

The R5 work item changes authored chest-body fit only. It preserves the G1
runtime/native pin `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`, all eight chest
families, native body/placement/targeting, hinge authority, original lid bytes,
960 shared storage units, costs and saved placement. No runtime fitting rule,
new collider, recipe, shape, material or ordinary-world rollout is introduced.

The candidate shortens the lower cabinet below its fixed upper rim and adds
four small same-family feet. The cabinet underside clears the ordinary slab;
the feet reach nominal flat ground. Fine slabs conceal half their exposed
length and ordinary slabs conceal it all. This is a deliberate authored visual
fit, not a claim of zero mesh penetration below a slab. Actual source/runtime
views, complete contact measurements and remaining terrain/wall/ceiling limits
are in the R5 evidence and receipt.

## Source and controls

`blender_fit.py` opens a verified packed E3 master. It retains a separate original
chest collection, all fuel/reference content and all 42 packed images. Lower-body
vertices change only vertically; all vertices at/above 0.06 m, horizontal bounds
and eight lid GLBs stay exact. Feet derive from the original bevelled bottom
solid, with metric UVs and connected joints. `fit.json` explains each dimension.
Blender X/Y/Z maps to Godot X/Z/-Y, as in E3. Body and lid are still separate
exports. Every source solid remains closed, outward and nondegenerate.

This source copy is read only:
`build/art07-repairs/r5/v01/original-source/source/e3_home.blend`.
New candidate source and exports are in `v02/models`; `v02/reopen-v02` is a separate
Blender process reopening that packed master and importing every exported GLB.
The task changes only eight GLB body files and the corresponding measured rows
in `game/e3/geometry.json` of the copied runtime. `changes.json` is authoritative.

## Checks and reproduction

Use the installed Python and Blender paths from repair `inputs.json`. All engine
and Blender invocations go through the unchanged repair `run.ps1`, with fresh
logs and private APPDATA/local/temp/Blender resources. Defer to existing jobs;
never terminate a peer. The source is already verified, so do not run setup into
an existing version or source-output directory.

- `prepare.py verify-prepared` checks the prepared original runtime entries.
- `prepare.py copy-master` copies and rehashes the selected E3 master/exports.
- `prepare.py install-harness [--version vNN]` installs only R5 review fixtures.
- `evidence_jobs.py vNN label` writes fresh capture/restore/benchmark/terrain jobs.
- `source_jobs.py vNN` writes fit/reopen specifications in an absent job set.
  The completed v02 jobs and corrected `blender-reopen-v02.json` are retained.
- `apply_candidate.py` installs the selected exported v02 bodies and metadata.
- `audit.py` compares before/after runtime entries, texture bytes, exact lids,
  native body/pose/hinge/ownership, retained terrain and source clearance in both renderers.
- `package.py seal <fresh-absolute-path>` seals the selected candidate/evidence.
- `package.py verify <absolute-package-path>` rehashes its complete exact file set.

`review.gd` uses explicitly supplied stock with ordinary native payment, refused
unpaid/duplicate placements, one owner, actual E targeting, deposit/withdrawal
and separate-process restore. Its twelve cases cover all eight materials,
ordinary/fine slabs, rear wall and low ceiling. Motion is driven by the real
panel and engine delta; it is sampled during physics frames, not an authored
animation substituted for interaction. `terrain_review.gd` inherits the actual
sandpit scene, restores G1's paid LF3/77 home and pays for three explicitly granted
terrain probes on unchanged geography. These are controlled tests, not a new
first-hour or human acceptance claim. Benchmarks have separate processes and
300 settled samples, without image captures during sampling.

To apply a seal for independent review, prepare a new absent version using
`workspace.py prepare --id r5 --version vNN`, then run:

```powershell
& $repairPython tools/wroughtwild-art07-repairs/r5/apply_package.py --package <verified-seal> --runtime D:/project-wroughtwild-art07-r5/build/art07-repairs/r5/vNN/runtime
```

The application verifies the whole seal and every before-hash before writing
only its declared delta. Then install the R5 harness, write fresh job specs, and
run the prepared import/smoke and selected evidence specs through `run.ps1`.
Never import or play directly inside the sealed package.

R8 must reconcile the replacement GLBs with R2's texture-storage changes. R5
consumes no predecessor delta; published R1–R4 are wave gates only. Copying the
whole R5 runtime into R8 would incorrectly overwrite independent repairs.

## Measured fit and authoring values

| Quantity (metres unless stated) | Value | Purpose |
|---|---:|---|
| Original lower cabinet | -0.500 | Reproduce the inherited overlap at the unchanged native pose. |
| New cabinet underside | -0.225 | Meet the full slab top at native pose +0.350. |
| Fixed upper region begins | +0.060 | Preserve the upper rim, hinge attachment and cavity opening. |
| Feet bottom | -0.350 | Contact nominal flat ground. |
| Foot centres X / depth | +/-0.400 / +/-0.290 | Four inset contacts stay within the original width and depth. |
| Foot width | 0.080 | Narrow supports under the raised cabinet. |
| Foot joint overlap | 0.020 | Join each support into the lower cabinet. |
| Derived exposed feet / geometric height | 0.125 / 0.145 | Flat contact and connected joints; slabs conceal some or all exposed height. |
| Derived lower cabinet vertical factor | 0.508928571 | Map -0.500..+0.060 onto -0.225..+0.060. |

The eight editable fit values and their purposes live in `fit.json`. These are
source-authoring controls, not placement logic. The visible closed envelope is
1.000 x 0.550 x 0.800 m; the physical/storage envelope remains 1.000 x 0.700 x
0.800 m. Each closed chest has 6,768 triangles (body 4,720; lid 2,048), up from
6,336, a 432-triangle / 6.82% increase. No LOD policy changes; the same E3 parts
and embedded maps remain selected at runtime.

Foot UVs retain E3's metric map scale: 0.5 m cross grain/metal repeat, 2 m
longitudinal timber repeat, and (0.173, 0.287) offsets. Side faces use vertical
wood grain and top/bottom faces use the original end-grain material. This adds
no texture, shader, material family or loading setting.

The source inspection stage uses a visible 200 m support plane at -0.350 m,
1200 x 900 PNG, Cycles CPU, 16 samples / 8 threads, AgX, orthographic scale 1.85
closed / 2.45 open, and target height 0.08 / 0.25 m. Broad key/fill/rim lights
are 500/350/600 W, size 3 m, to expose join/contact geometry. The source-only
opening inspection rotates around Blender (0, 0.354, 0.090) by -78 degrees,
matching the unchanged native hinge; runtime evidence uses actual panel ticks.
The original narrower open framing is retained but is not selected evidence.

Runtime inspection uses 1440 x 900, 4x MSAA, vsync off, linear tonemapping and
no glow. Closed/open camera distances are 2.3/3.0 m with aim offsets -0.12/+0.20 m
and 42-degree FOV. Terrain uses 45 degrees and aisle/outdoor views to keep the
full chest in frame. These camera changes are review-only. Two settling frames
per captured image and every-second-frame motion samples make capture paced;
GIF timing comes from recorded wall-clock timestamps. Lid authority remains
3.8 radians/s and -78 degrees, unchanged from E3. Benchmarks settle 120 frames
then sample 300 process-frame intervals in a separate process with no captures.
The 0.0001 m comparison tolerance accommodates floating-point transforms; it is
never a native placement tolerance. Source nondegeneracy uses 1e-10 cross-product
magnitude and import bounds use 1e-5 m tolerance.

`curate.py` copies selected full PNGs byte for byte, records hashes/provenance,
and encodes the actual sampled lid frames as GIF with 10 ms duration rounding.
It creates the evidence directory only when absent. The sealed package retains
every raw frame, failed attempt and original/candidate report. Inspection stock
is explicit (200 per chest source material, plus 17 wood / 23 stone for each
storage exercise; withdrawal 3 stone), and retained-terrain probes receive 18
wood. None of that stock is a gameplay grant or an ordinary-world change.
