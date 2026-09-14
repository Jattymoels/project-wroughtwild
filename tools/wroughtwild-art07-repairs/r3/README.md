# ART-07R3 material binding

R3 is an isolated presentation candidate for G2-V02. It retains G1 game/data/native
revision `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. The prepared worktree is
`D:/project-wroughtwild-art07-r3`, branch `codex/art07-r3`, inspected clean at
`473ae7604b3841899c29629cf59f8836ed528424`. The preparation record predates this
notes commit; its runtime entries are independently rehashed before application.

The implementation uses the original D4/D5 face and cut-edge maps and D6 shared
metal maps. It changes no authored texture, GLB vertex/index/normal data, collision,
recipe, native stock, saved geography, construction address or unlock. The E3 chest
and fire keep their existing embedded materials and seating. No R2 runtime is copied.

`install.py` applies three exact, baseline-relative hooks to the private runtime:
G1 material dispatch, shape metadata on retained G1 meshes, and PieceLook material
binding. All new runtime files live under `game/r3`. These are explicit overlaps
with R2's resource/material/mesh reuse work for serial reconciliation. Use the
file/function hashes in `changes.json`; never overwrite a peer's whole file.

`--r3-baseline` selects sealed G1 material binding on the same G1 meshes. It differs
from G1's older `--baseline`, which disables the whole ART-07 integration. R3's
comparison leaves canopy, resources, world settings and other ART-07 work intact.

The shader selects one metric plane and the appropriate original map per fragment.
Timber follows member length, existing horizontal rails and roof fall lines. Opposite
faces get right-handed tangent frames. A run shares its metric origin; full and fine
members crop identical repeats. Door mapping moves with its actual leaf. The metal
seam response uses D6's existing tint/metallicity on protected geometric recesses.
Glass uses the original 0.72 opacity with backface culling and alpha blending; its
integral frame uses the opaque edge maps. No refraction or extra pass is added.

All presentation controls and their purposes are in `settings.json`. D4/D5 repeat
metres, source colours, opacity and seam traits remain in the original D4-D6 JSON.
D6 retains the G1 fallback repeat of 0.5 by 0.5 metres for its shared maps. Rails
are measured from D1/D2/D3 source recipes, with the native 0.045 m panel batten and
0.075 m window frame. The 10 cm diagnostic grid is explicitly labelled and never
active in ordinary candidate rendering.

Commands use the installed Python:
`C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
From this worktree, inspect/verify with the unchanged workspace helper, then use
`install.py --check-base` once before application and `install.py` to apply R3.
`make_jobs.py BATCH --prefix FRESH_ID` creates non-overwriting job specifications.
Batches are `inspection`, `catalogue`, `transactions`, `paid`, `benchmark`, `import`.
Run every specification through `tools/wroughtwild-art07-repairs/run.ps1 -Spec PATH`.
The required generated `v01/import-smoke.json` remains unchanged. A failed log is
retained; a corrected attempt needs a fresh specification/log name.

The inspection fixture explicitly supplies catalogue stock and the existing roof
reward. It is separate from `home.gd`, which loads the original no-grants paid home,
uses held resources and ordinary recipe/payment/placement, writes its private
checkpoint, and restores it in a new process. Its motion uses native controller
input and collision. The original 273-pair catalogue and transaction assertions
are run unchanged. Benchmark jobs contain no image saving and refuse competition.
Current-machine results do not establish a minimum-hardware budget.

Capture settings are fixed at 1440 by 900, 4x MSAA and VSync off. Inspection camera
positions/targets are recorded with results; FOV is 55 degrees (paid home: 60).
The material laboratory uses day energy 1.15/ambient 0.45, shade 0.12/0.35, and dusk
0.4/0.22. Dusk lowers the sun from -0.85 to -0.2 radians, retaining yaw -0.55.
These are controlled comparison lighting, not new world/weather settings. Paid
views use the retained world mood with a 0.12 shade or 0.35 dusk sunlight multiplier.
Benchmarks use 120 settled warmup frames and 300 samples per view/lighting pair.

Source references: the selected building board, D4-D6 material contracts, D-013,
D-017 and D-018, and [Godot 4.5 spatial shader documentation](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/spatial_shader.html).
Source/master reopen is read-only; no authored map/geometry replacement is claimed.
Independent integration/review, owner visual acceptance and ordinary rollout remain
separate. Executed results and limitations belong in the final R3 receipt.

The material selector derives broad block sides from the existing native `element`
tag. Mineral blocks and chamfers retain bedding around their sides. Slabs, thin
panels and roof cuts use the measured edge repeat. Roof topology comes from the
existing slope/hip/valley form; timber length follows the slope through vertical
cut faces as well as across the covering. This introduces no shape or roof gate.

`run-batch.ps1` is an owned execution wrapper around the unchanged shared runner.
It holds the same reentrant mutex between a finite list of specifications. The final
wrapper makes one continuous acquisition wait, giving up after 900 seconds if the
slot stays busy; the outer tool yields so status can still be reported. Earlier
45-second requeued attempts are retained as unlaunched deferrals. It checks existing
processes before launch. `-Then` names subsequent finite
specifications; it creates no recurring task. The generated smoke specification
is executed unchanged, with `-From` used only for its previously unlaunched jobs.

The paid motion records 90 controller observations and the actual engine physics
frame stamps. Capture can span extra ticks while awaiting rendered frames; the
receipt reports those actual ticks. Playback is illustrative, not a frame-time
benchmark. A native movement-distance assertion detects a stalled capture.
`binding_inventory()` reports the actual original image paths bound by the
construction material cache; loaded backend memory is reported separately.

`verify.py` checks protected runtime bytes and matched geometry/cameras/costs.
`fingerprints.py` compares all persistent paid fields and separate-process restores,
omitting only ephemeral Godot station node names, as the retained G1 verifier does.
`seal.py` creates a fresh exact-set package only after committed source/evidence and
a completed check index. `seal.py --verify ABSOLUTE_PACKAGE` verifies every byte and
rejects missing or extra files. Receipts remain outside their own hashed package.

Capture-end counters can reflect the final diagnostic camera or controller view.
They are raw snapshots, not paired draw-cost conclusions. Use the separate benchmark
samples matched by camera and lighting for draw, geometry and timing comparisons.
The explicit mesh/normal/index signatures verify geometry independently of camera
culling. All first-pass evidence is retained; final roof and glass evidence is the
corrected second pass, identified explicitly in the receipt.

The unchanged native transaction suite has one fixed screenshot directory. Its
retained screenshots are from the later Compatibility run; both renderers have
separate fresh runner logs and private checkpoints. The dedicated R3 material and
paid-home comparisons use separate renderer/run directories throughout.

Serial integration must reconcile the three shared hooks with R2. Preserve the
per-piece shape identity if mesh reuse changes: a mesh shared across distinct IDs
must not let one piece overwrite another's orientation metadata. Retain R2's
resource reuse while applying R3's material dispatch and surface binding. The
standalone installer always reconstructs this candidate from the verified common
baseline; it is not a merge tool for an already modified peer runtime.
