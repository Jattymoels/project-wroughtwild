# ART-07R2 application and composition

Use the exact common G1 runtime at native/game/data revision
`6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. The newer repair documentation checkout
is not a new runtime baseline. Original packages remain read-only. No peer runtime
was consumed. The receipt records the actual sealed manifest identity and checked
source commit; the package excludes its own receipt.

## Reconstruct in this assigned worktree

From `D:/project-wroughtwild-art07-r2`, using the installed Python recorded in
`inputs.json`:

```powershell
$repairPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $repairPython -B tools/wroughtwild-art07-repairs/workspace.py inspect --id r2
& $repairPython -B tools/wroughtwild-art07-repairs/workspace.py verify --id r2
& $repairPython -B tools/wroughtwild-art07-repairs/workspace.py prepare --id r2 --version vNN
& $repairPython -B tools/wroughtwild-art07-repairs/r2/source.py --version vNN
& $repairPython -B tools/wroughtwild-art07-repairs/r2/material_keys.py --version vNN
```

Choose an absent version for `vNN`; never reuse a sealed candidate. These two R2
source recipes verify before-hashes and assert each intended text replacement.
They preserve native data/binaries and the exact PNG bytes/import parameters.
They do not run Blender or regenerate meshes. `source.py` rewrites only the
`images` section of selected interchange scenes, retaining every non-image JSON
field and all non-JSON GLB chunks exactly. `material_keys.py` preserves distinct
shader inputs when formerly separate texture objects become shared.

An alternative exact application command is supplied by `handoff.py apply`.
Supply `--package`, the receipt's `--manifest-sha256`, and an explicitly prepared
`--target .../build/art07-repairs/r2/vNN/runtime`. It verifies the entire seal and
all 4,787 original runtime entries before applying any file. It refuses a peer
candidate or any conflicting source hash. `--with-evidence-harness` also installs
the recorded additive R2 scenes. It does not import or launch the engine.

For new evidence scenes reconstructed from source recipes, install them before
import (omit these installs when `apply --with-evidence-harness` already supplied
the exact files):

```powershell
& $repairPython -B tools/wroughtwild-art07-repairs/r2/measure.py install --version vNN
& $repairPython -B tools/wroughtwild-art07-repairs/r2/install_checks.py --version vNN
& $repairPython -B tools/wroughtwild-art07-repairs/r2/native_renderers.py --version vNN
& $repairPython -B tools/wroughtwild-art07-repairs/r2/check_jobs.py --version vNN
& $repairPython -B tools/wroughtwild-art07-repairs/r2/replays.py --version vNN
```

Use the generated `render-replay-jobs.json` and `native-replay-jobs.json` for
those source replays. `controls.py --version vNN` adds the six candidate art-off
benchmark jobs; `benchmark-jobs.json` contains the six candidate art-on jobs.
Keep the two sets separate from import and capture jobs.

The catalogue, captures and reload checks must run before the paid acquisition
check writes its disposable `g1/paid-home.json` fixture. Then `checkpoint.py --version
vNN` restores only that fixture from verified original bytes. Native continuation
jobs share their own private checkpoint directory in the correct dependency order.

Run the generated `vNN/import-smoke.json` through the unchanged shared runner:

```powershell
& tools/wroughtwild-art07-repairs/r2/queue.ps1 -Specs @('build/art07-repairs/r2/vNN/import-smoke.json')
```

Every later engine job also goes through `run.ps1`, with fresh logs and private
state under the assigned build tree. `queue.ps1` waits for the same single GPU
mutex for one bounded list of jobs; the shared runner still checks existing
processes and benchmark competitors. Never launch the copied executable directly
against the owner's user profile. `ART07G1` resolves inside each job's private
APPDATA; LOCALAPPDATA, TEMP/TMP and Blender resources are also private. Import,
benchmarks and captures are separate jobs. Never stop another process.

## Compose with R1/R3/R7 and the remaining repairs

`changes.json` inventories every baseline-relative production and evidence file,
exact before/after hashes, functions/settings and overlaps. Its production delta
has 238 modified original files and two added files. Evidence helpers live only
under `game/r2`. Whole-file last-writer copying over another candidate is not a
valid integration procedure.

| Affected file or family | R2 operation | Composition requirement |
| --- | --- | --- |
| `game/b1/native_tree.gd`, `_apply_visual` | Cache the original radius measurement by fixed source kind and burial | R1 owns final trunk/crown fit. Compute the memo from its final geometry and fit inputs; do not reinstate the old fit through an R2 file copy. |
| `game/b3/native_resource.gd`, `reproject`, `_r2_height` | Reuse identical scalar terrain queries during one synchronous rebuild | Preserve R6's final supported surface geometry. Query coordinates, reference height, reach and safety checks stay authoritative; discard the memo after each rebuild. |
| C1 `present.gd` and C6 `adapter.gd` | Preserve complete actual shader-input cache identity | Retain tint, ORM, vertex-colour and conform/scar inputs while composing R3/R7's final materials. Sharing a texture does not make all materials equivalent. |
| C5/E1/E2/E3/F2/F4/G1 material loaders | Resolve exact equivalent texture paths | R3/R5/R7 may edit material roles or paths. Apply the lookup to final loaders while retaining per-instance work materials and shader colour-space declarations. |
| 226 `.gltf`/`.glb` source scenes | Lossless image reference changes | R1/R3/R5/R6/R7 own geometry/fit in their areas. Apply only valid image references to the final combined scene; preserve its new non-image fields and BIN data. |
| `game/r2/resources.gd`, `texture-aliases.json` | Exact content/import identity map | Rebuild from the final composed PNG bytes and full import parameters. Never reuse an alias merely because a filename or earlier hash matched. |

The selected canonical path is the shortest then lexical existing path within a
byte-and-import-identical group. This is deterministic packaging, not a visual
tuning value. The complete import parameter comparison includes normal processing,
channel mappings, mipmaps, size limits and compression. Identical PNGs with different
import semantics are kept separate. Texture objects may be shared; mutable work
materials and their native owners are not newly shared.

The B1 radius cache stores numbers only. B3's query memo is call-local and keyed by
Float64 scalar pairs, preserving the original query precision. No cache retains
terrain samples across edits, release/re-entry, geography changes or save reads.
All existing fit constants, projection reach, state transitions and LOD selections
remain unchanged. There are no new presentation tuning values.

## Retained sources and limits

The seal retains original packed Blender masters and lineage under `g1_originals/`,
original changed-file bytes under `baseline_sources/`, the modified source scenes
and scripts under `game/`, and both proof inventories at `evidence/v03/`.
No Blender master, PNG map, mesh topology, UV, rig, sampler role or world placement
was edited. Fresh engine import reopens the lossless interchange derivatives;
this is not a claim of newly modelled or freshly edited Blender masters.

Normal game/sim/data/saves and ordinary rollout are outside this pilot. The original
paid test writes a checkpoint inside its disposable copied runtime; `checkpoint.py`
restores only that fixture from verified original bytes after checking that the
written state came from this task's own paid test report. Its separate private user
saves remain evidence. The production checkpoint in the seal must match the common
G1 hash.

A current RTX 5090 measurement does not establish an owner-selected target-device
budget. Owner visual review and target-device acceptance remain pending. R4 owns the separate lifecycle work. R2 retains an immediate-retirement
material diagnostic and does not change native stream retirement to hide it; see
`DIAGNOSTICS.md`. The successful reload harness allows actual rendered frame
boundaries between route visits. R8 must
repeat the relevant combined checks after composing all changes; these isolated
results do not clear the unfinished combined candidate.
