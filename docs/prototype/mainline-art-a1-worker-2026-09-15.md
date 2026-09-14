# A1 worker — put the completed R8 kit into ordinary Wroughtwild

The owner starts this worker manually. Do not create another task or reviewer.

## Workspace

- Owner depot: `C:/Users/Matty/Dev/project-wroughtwild`, branch `main`.
- Worker checkout: `D:/project-wroughtwild-mainline-art-a1`.
- Worker branch: `codex/mainline-art-a1`, based on current main including this handoff.
- Engine: `C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe`.
- Read-only R8 input: `D:/project-wroughtwild-art07-r8/build/art07-repairs/r8/v01/handoff-final`.
- Runtime input beneath it: `runtime/game/`; read its `runtime-files.json`,
  `changes.json` and relevant adapter files, without a full rehash or reconstruction.
- Put new test logs/private APPDATA under the worker's ignored `build/a1/`.
  Do not run the input package or overwrite its files.
- Coordinator setup records the actual base, setup duration and native-DLL reuse
  in the worker's ignored `build/a1/SETUP.md`. Its old countdown is superseded by
  the owner's 15 September clarification in the current depot's AGENTS.md.
- C: had only about 400 MB free at setup; a full checkout there failed and Git
  removed it. D: has ample space. This linked worktree still stores Git objects
  in the C: owner depot: check capacity before staging large new assets. Preserve
  old packages/saves and report a concrete capacity blocker; do not delete them.

If the workspace is already prepared, use it; do not recreate it. If absent, the
coordinator can prepare it once from the owner depot using:

```powershell
git -C C:/Users/Matty/Dev/project-wroughtwild worktree add D:/project-wroughtwild-mainline-art-a1 codex/mainline-art-a1
git -C D:/project-wroughtwild-mainline-art-a1 merge --ff-only main
```

## Exact implementation instruction

Read `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md`, then the worker checkout's
README, DESIGN, decision registry, vertical slice and acceptance criteria in
their required order. Read `docs/prototype/art-mainline-adoption-2026-09-14.md`,
the current coordination sheet, and only the art/construction/world/source-device
specification sections needed for this port. Historical no-rollout/R9/benchmark
requirements are superseded by the owner's explicit approval and current limits.

Restate the outcome, affected systems and assumptions, then implement a small
plan. **Make the finished R8 environment/building/resource/station/device kit
appear in the normal game**, through normal new-world and Continue entry and
existing supported campaign profiles. This includes the completed ART-04 colour
families already consumed by R8. It is a presentation port into current main,
not another showcase or a reconstruction of the old paid-home game.

Current Git inspection found game/, sim/ and data/ identical to R8's frozen
`6bb2e044dcd0bf1788896aa2c19cdf56fee93522` source pin. Use that existing evidence
while unchanged. If main advances, inspect only the resulting relevant changes.
Keep current main authoritative; never reset it or overwrite gameplay wholesale.

Use `tools/wroughtwild-art07/g1/prepare.py` as an explicit integration-hook map,
and the **final R8 runtime** for the repaired production modules/assets. The G1
recipe predates repairs and is not the selected asset version. R8's changes.json
is relative to G2, so it alone is not the complete normal-game adoption diff.
Relevant hooks include resource_stream/terrain and resource restoration,
piece_look/placed_block, station_look/station_site, ground cover/ruin presentation,
strange_resource_art, leyline_source, contraption_site and pressure_pocket.

Copy only runtime dependencies actually required by these hooks, including R2's
shared textures/resource aliases and the final repaired shaders/geometry. Preserve
resource path references and add required assets to tracked production paths.
Do not ship tests, captures, private checkpoints, full masters, engines, DLLs or
import caches. Do not retain absolute D: or build/ dependencies in the playable
game. Do not commit a large single binary that exceeds the destination's existing
file constraints; retain the delivered external texture sharing.

Keep `res://scenes/sandpit.tscn` as the ordinary entry. Do not install the G1
paid-home bootstrap, fixed seed, private save-path override or baseline switch
as normal-game requirements. Existing recipes/profile eligibility still determine
which devices a world can acquire; art approval does not unlock LF mechanics in
legacy worlds. Preserve both terrain events, campaign progress, ownership,
resource depletion, saves, placement costs/bodies, doors and octagonal shapes.
Presentation should follow native state on load without replaying work/rewards.

Fauna is the next separate adoption slice: retain the existing actor set in A1
and list it honestly. The latest finished ART-01/03 fauna and native adapter work
must be adopted in A2; they are not part of the six unfinished ART-06C rigs.
Do not regenerate or rig those six here. R9 stays stopped.

Keep PLAY-01 stutter, PLAY-03 accidental underground access/worse lag, PLAY-02
incomplete-looking canopies and PLAY-04 untried stations documented. Their fixes
follow adoption. A concrete load/save/gameplay failure encountered during this
port is actionable; cosmetic gaps and unmeasured hardware are not new gates.

## Short verification, then delivery

Before checks, name the actual risks: missing runtime resources, loss of restored
presentation/native ownership, and changed construction/device interaction.
Use no more than three focused jobs, with Forward+ as the sole rendered backend:

1. One import/load check of the actual production project and required assets.
2. One short ordinary new-world → gather/place/use → save → Continue path using
   private test state. Include a representative octagonal piece/door and an
   ordinary station, exercising the changed hooks rather than a catalogue matrix.
3. One existing saved LF workshop load/use check for the changed source/device
   callbacks, checking restoration does not create work, stock or rewards.

Reuse existing fixture setup/evidence; no all-seed, all-material, actor or
renderer matrices. The owner removed the hard ten-minute cutoff on 15 September:
finish focused diagnostics, small fixes, Git checks and delivery without asking
for a token extension. Reuse the passed worker checks during integration. Keep
verification proportionate and report unverified limits; do not restart gameplay
checks to resolve a delivery-script issue. Early look, feel and atmosphere matter
more than minor polish. Broad pipeline/baseline/camera reviews remain out of scope.

Automated runs must not capture the desktop mouse. Port the existing
`--r8-no-mouse-capture` test-only branch from R8 to current player code, verify
it reaches all capture paths, and use a disposable no-focus test override for
rendered work. The input package's test-support override references its own
comfort scene; do not copy it blindly into production. Normal manual play retains
mouse capture and Escape release. Prefer headless checks where they answer the
risk; do not start a rendered run until cursor release is established. Stop only
your processes and leave no testing running when handing back.

Document inherited/changed art settings and their purposes without inventing
gameplay tuning. Add a concise adoption result and update the current coordination
sheet/queue. Commit only your completed checked slice on `codex/mainline-art-a1`.
The coordinator will integrate those commits into main and perform the ordinary
non-force origin/main push under standing permission; no separate approval or
independent review is needed. Never stage the owner's unrelated captures/saves.

Return a short report beginning with the actual gameplay improvement, then
remaining issues, checks and elapsed verification time, exact commit IDs, and
explicit main/push status. Supply an exact normal-main launch command and a few
playtest steps: Continue an existing world, look at resources/trees, place/use
one station, and build/use an octagonal section. Explain the existing separate
LF launch when asking the owner to try colour devices; do not claim they are
available in every historical world. Do not make a portable rebuild a completion
requirement. This slice is complete only when its assets load from the ordinary
project and the coordinator can publish that playable change.
