# ART-07C3 — resinheart and corkbark source handoff

Owns only `resinheart_tree` and `corkbark_deadfall`. This is an isolated source,
material and native-state study; ordinary-world adoption and owner visual
acceptance remain separate. See `docs/prototype/art07-production/receipts/c3.md`
for the selected absolute version paths, hashes, commands and limitations.

The full-width buttressed hero retains B1's approved oak anatomy and deep
incisions. Its broad root/body does **not** fit the native 0.805 × 4.5 × 0.805 m
tree envelope. The separate fitted candidate keeps that body and a full upper
crown. Its slimmer lower trunk is a visible compromise; changing the gameplay
footprint requires a separate decision. Neither this recipe nor the review
enlarges a native body. The full-width model is displayed only as a labelled
static source study, not used by the work adapter or physical route.

Cork is a separate 18-unit deposit, with three actual six-unit harvests and
three contextual presses per harvest. Three closed porous sleeves expose
progressively more of a lighter inner deadwood core. Resinheart takes six
chops for its existing 24 logs and leaves one native session-only inert stump.
The adapter reads `remaining_units`; it creates no new stock or save field.
The native shrink, lean, fall and disappearance clocks remain authoritative.
At zero cork stock the final worked mesh stays alive through the native .3 s
shrink. The existing session-only low aftermath uses matching C3 bark at the
same native scale; it has no collision, yield or saved identity.
The saved callback refreshes sleeve art before the next work action.

## Reproduction

Run from the C3 worktree. Existing binaries are read from the canonical depot:

- Python: `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`
- Blender: `C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe`
- Godot: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe`

`prerequisites.py` specifies the exact published B1/B2 local handoffs and
manifest hashes. A clone does not contain these ignored packages. Transfer
those verified packages or reconstruct their published receipts first.
No new imagegen/TRELLIS generation, model download, service or package is used.
The original B1/B2 generation metadata remains in their verified receipts.

Use new output directories for each production stage. The following names are
argument placeholders; the receipt/job JSONs record the actual executed paths:

```text
python prerequisites.py RUN/prerequisites.json
blender --background --threads 8 --python-exit-code 1 --python inspect.py -- INSPECTION
blender --background --threads 8 --python-exit-code 1 --python build.py -- KIT
blender --background --threads 8 --python-exit-code 1 --python audit.py -- KIT AUDIT.json
python prepare.py KIT REVIEW
python prepare_native.py CURRENT
python attach_native.py REVIEW CURRENT/game
godot --headless --editor --path REVIEW --import
godot --headless --editor --path CURRENT/game --import
run-current-checks.ps1 -Project CURRENT/game -Logs LOGS
run-stage.ps1 -Project REVIEW -Logs LOGS -Stage Capture
run-stage.ps1 -Project REVIEW -Logs LOGS -Stage Motion
run-stage.ps1 -Project REVIEW -Logs LOGS -Stage Walk
run-stage.ps1 -Project CURRENT/game -Logs LOGS -Stage Native
run-stage.ps1 -Project REVIEW -Logs LOGS -Stage Benchmark
python encode.py KIT REVIEW CURRENT/game MEDIA
python package.py KIT REVIEW CURRENT RUN NEW_HANDOFF
python verify_package.py NEW_HANDOFF NEW_COPY
python fresh_verify.py NEW_HANDOFF REPLAYED_COPY RUN
```

Use `run-job.ps1` for all Blender/Godot commands to record executable, arguments,
PID, exit, duration and isolated APPDATA/LOCALAPPDATA/Blender settings. Blender
build/inspection uses Cycles **CPU**, eight threads. Actual engine captures and
benchmarks acquire `Local\Wroughtwild-Art07-GPU`; leave other jobs intact.
Benchmarks additionally require an agreed CPU-quiet window and no captures,
imports or generation. The script's conservative process guard may yield to
headless jobs. That is a scheduling refusal, not an approval rejection.

`prepare_native.py` freezes `f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9`, proves
game/sim/data equivalence with B1's compiled revision, and verifies the reused
native DLL before copying it. The normal checkout's DLL and saves are untouched.
The separate-process native fixture uses its own `user://c3-partial.json` and
`user://c3-final.json`. Work and pickup absorption use real native methods with
posed actors; this is not a paid first-hour campaign or a generated habitat.
The final cork presses are spaced by sixteen process frames to let each native
.18 s work punch finish before sampling the .3 s depletion. Same-frame posed
presses overlap those inherited tweens; this slice does not change that game
behavior. The fixture asserts the C3 mesh remains alive while native scale
shrinks, then verifies the single inert aftermath and its absence on reload.

## Source/material controls

`kit.json` describes the metre transform, crown clearance, radius, incision,
LOD distances and explicit wind/pulse clock. Blender (x,y,z) becomes Godot
(x,z,-y) once through glTF. Base origins remain at the native saved anchors;
source roots extend below the ground, and the review ground seats them there.

The fitted incision uses a 105 mm damage half-width and 38 mm light-core
half-width along inherited B1 channels, with at most 65 mm inward radial cut.
These are asset-authoring dimensions, not gameplay numbers. Source coordinates
and original maps remain in SOURCE. Broadening starts above 4.55 m and completes
by 6.2 m; far simplification is projected back inside the same trunk envelope.
Near/middle branchlets are reseated against the fitted parent; petioles are
reseated against those branchlets. Far geometry is a silhouette, not an
attachment master.

The deadfall's three sleeves use 277 mm nominal outer radius, 205 mm inner
radius, 15 mm irregular ridges and rolled lips, and up to 11 mm actual pits.
That deeper inner sleeve repairs an observed detached end section. This is one
fitted source profile, not a general bark fitting algorithm. Cut ends are planar
with their own grain charts; longitudinal wood uses a separate lengthwise
chart. Recovered cork and resinheart samples are closed, non-emitting material
specimens, not new construction shapes or kits.

Albedo is sRGB; ORM and UV2 scar/wind channels are linear. All images are packed
in the editable master. The Godot cook shares images by content hash, limits
them to 1024 pixels, keeps explicit mipmaps and verifies every retained non-image
buffer view byte. Original embedded source images remain in the master/GLBs.
No image alpha cards, per-scar light or bloom is used. Native hover/heat is a
separate shader input from the ambient altered-host pulse. Ordinary boards,
stumps, recovered samples and cork have no magical emission.

## Review

WASD/mouse, L day/shade/dusk, M scar emission, Space pause, 0 automatic detail,
1/2/3 forced detail, R reset, Escape cursor. The standalone physical route uses
a 0.32 m radius, 1.8 m capsule and the unchanged native tree/deadfall boxes on an
authored flat patch. It has no inventory, harvesting, placement or saves.
`Capture` includes labelled full-width source images after the fitted study.

`launch-review.ps1` verifies the canonical hashes, copies to a **fresh** location,
verifies the copy, and imports only that copy. Use `-Mode review -Visible` for
an owner-visible window. Keep the canonical handoff immutable. Reopen its copied
packed master and run `audit.py` on the copied `source/` independently.

Limitations to carry forward: narrow fitted lower trunk; full-width hero needs a
footprint decision before adoption; visible discrete LOD changes; faceted close
bark; sparse/repeated distant crown shapes; site-authored flat contacts; simple
porous sleeves rather than sculpted bark chips; opaque overlap and shadow cost;
no arbitrary slopes, normal-world streaming budget or lower-spec approval.
