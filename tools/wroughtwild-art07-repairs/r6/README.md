# ART-07R6 retained ore surface

Run only in `D:/project-wroughtwild-art07-r6`, branch `codex/art07-r6`.
The common runtime stays at `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`.
This is an isolated candidate and verification fixture. It does not install art
in the normal game checkout.

## Construction

1. Use the installed Python to run the unchanged `../workspace.py inspect --id r6`
   and `../workspace.py verify --id r6`. Keep the full verification output.
2. Reuse the byte-verified `build/art07-repairs/r6/v01/prepared.json` runtime.
   `stage.py` verifies every original entry before its first mutation and applies
   only the two bounded presentation changes described below.
3. `project_masks.py` reads verified original C5 glTF/bin vertex fields. Its fresh
   `projection-v01` output records all source hashes and the atlas hash. It refuses
   to overwrite that source conversion. Run `stage.py` again to install the atlas.
4. `jobs.py <surface|c5|probe|benchmark|reopen> <fresh-version>` creates fresh job
   specifications. `launch.ps1 -Spec <jobs.json>` waits in bounded intervals for
   the shared GPU mutex, then calls the unchanged `../run.ps1`. The shared runner
   retains its process checks, private user paths, fatal diagnostics and receipts.
   A deferred launch is not a run. Use `-From <job-id>` only for jobs whose logs
   do not yet exist. Never reuse a completed or failed job's log paths.
5. `evidence.py` requires the five successful run groups, verifies each log receipt,
   compares complete native snapshots and copies actual stills/controller frames.
6. `package.py seal <fresh-handoff> --runs <run-names...>` seals the runtime,
   masters, tools and full selected run evidence. `package.py verify <handoff>`
   checks the exact file set, byte counts and every hash.
7. `apply.py --baseline <verified-G1-seal> --package <R6-seal> --out <fresh-R6-build>`
   reconstructs a new private runtime after verifying all baseline runtime bytes
   and every before/after hash. It refuses existing destinations and locations
   outside this task's ignored build tree.

The installed Python is
`C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Every engine or Blender invocation must remain inside the shared runner. Source
projection is a CPU conversion using the already installed NumPy and Pillow.

## Runtime delta

`stage.py` derives `game/c5/native_resource.gd` and `game/g1/art.gd` from the
original verified G1 package, rather than modifying normal source. The adapter
attaches a material to the native `GroundedSeam`, synchronises native remaining
units/cracks/heat, and reapplies that material after native excavation refresh.
It hides the surface immediately at exhaustion, before the native retirement
scale can detach it from a slope. The inherited removal/collider behavior stays
unchanged. Dispatch also recognises the actual native `ember_vein` visual key.
Persistent generated resource IDs are never replaced with art-family IDs.

`surface.gdshader` does not displace vertices, write depth, discard pixels or add
geometry. The full remaining picking ribbon retains a visible host.
Back faces remain culled as in the native material. Mineral
coverage recedes according to current stock divided by the full native definition,
including after loading a partial save. Controls and purposes are in `surface.json`;
colour/roughness/metallic values come from unchanged C5 `kit.json`.

The shader resource retains the following finish controls: triplanar weight power
4 favours the closest surface plane; host roughness clamps to 0.7–1.0; mineral
blend 0.88 retains host texture; the mineral grain multiplier is
`0.55 + 1.8 * stone.r`; scar darkening is 0.72. Native state emission varies from
0.10 to 0.40 with mineral coverage. Native heat uses RGB `(1, 0.18, 0.018)`,
amplitude 0.65, pulse `0.65 + 0.35 * sin(phase)` and a 0.35-radian/metre spatial
phase. The atlas UV clamps (0.001/0.999 across, 0.004/0.996 within a row) keep
linear samples inside their own source state. These tune shading and readability,
not surface height or collision. All gameplay quantities remain source-owned.

`pack_master.py` adds the derived field atlas and controls to a new copy of the
packed C5 master. `reopen.py` opens that copy in a separate guarded Blender process
and checks original vertex/topology/colour/material-slot/object-pose signatures.
Original models and maps are preserved; there is no new faceted slab.

## Evidence scope

`review.gd` uses actual seed-77 LF3 resource definitions and native terrain chunks,
including a slope/chunk edge and existing cave-floor copper/tin. It compares every
candidate vertex, target triangle, transform and layer/mask with the native node,
checks physical support, performs native work, saves/reloads partial state, and
removes/restores a voxel using native excavation. Motion comes from input actions
and the unchanged player controller. Inspection cameras and acquisition are paced
by the harness and are not a continuous human campaign.

The C5 derivative preserves every original assertion in order; it changes only
private checkpoint/output locations and adds player/close captures. Full G1
art-on/off probes compare the entire paid snapshot and geography hash. Benchmarks
exclude import, generation and captures and record 240 frames after 60 warmup
frames per ore, per renderer and art mode. Current-machine timings do not clear
minimum hardware. The receipt identifies the actual successful runs, limitations,
candidate manifest and source commits; owner visual acceptance remains pending.
