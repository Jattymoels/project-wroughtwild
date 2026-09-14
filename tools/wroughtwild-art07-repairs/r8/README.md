# R8 tool entry points

Work only in `D:/project-wroughtwild-art07-r8` on `codex/art07-r8`. The common
runtime and R1–R7 seals are immutable prerequisites. Read the R8 prompt and shared
contract before running these tools. All scripts use the installed Python with
`-B`; no new dependency or service is required.

The implementation records these stages:

1. `workspace.py inspect/verify --id r8`, then reuse/prepare an exact baseline.
2. `inspect_inputs.py`, `compose.py --version v01`, `aliases.py --version v01
   --tag preimport`, and the guarded import. `aliases.py --tag postimport`
   regenerates exact aliases after all import parameters exist; import again.
3. `stage_sources.py` copies and rehashes declared master/support files.
4. `jobs.py`, `fixtures.py`, `cleanup_derivatives.py`, `comfort_jobs.py` and
   `reopen_jobs.py` prepare the bounded evidence matrix. R8 trace derivatives and
   corrected fresh-job specifications are retained with all original failures.
5. `baseline.py` instruments a separately prepared original comparison copy;
   `measurement_completion.py` supplies the exact R2 inventory/traversal harness.
6. Use **only** `tools/wroughtwild-art07-repairs/run.ps1` for Godot/Blender execution.
   Never reuse a log path or run benchmark jobs alongside imports, generation,
   captures or other engine/compiler processes. Generated specifications are
   concrete recorded runs, not a recurring queue or a monitor.
7. `job_index.py`, `visuals.py`, `costs.py --before v02 --after v01 --out <docs>`,
   `audit_composition.py --tag final`, `check_tools.py <fresh output>`, and
   `acceptance.py` validate actual results. Repeat full original/repair input
   verification after all source consumption/reopens.
8. `handoff.py seal --version v01` requires the completed acceptance record. It
   refuses an existing seal. `verify --package <path> --manifest-sha256 <hash>`
   checks the exact file set, total, sizes and every payload hash.
9. For independent reconstruction, prepare an absent version using the unchanged
   workspace helper, then `handoff.py apply --package <path> --manifest-sha256
   <hash> --target <version>/runtime --tests`. It requires the exact fresh original
   file set and hashes before applying the complete composite. `clone` instead
   verifies and copies the full handoff into an absent runtime path.

The default preparation recipes intentionally refuse existing outputs. Their fixed
v01/v02 paths describe the recorded experiment. Use the verified handoff's guarded
`apply`/`clone` workflow for another independent run rather than overwriting the
experiment. Source seals, normal saves, peer worktrees and the owner checkout stay
read-only. The package's normal runtime excludes the test-only no-focus override.
`play.ps1` is an explicit manual launcher with normal mouse capture and private saves.

See the owned R8 documentation for composition, seven-finding disposition, tuning,
actual check/cost results, diagnostics and image provenance. All original failures
remain failures. R8 creates no next task, monitor, shared queue edit or main push.

For the recorded v03 reconstruction, `finish.py capture` preserves the two exact
inherited pressure-workshop checkpoint files under evidence before the unchanged
`postseal.py audit`. After it passes, `finish.py seal` creates an absent
`handoff-final`, retains the first seal, refreshes only tools/documentation and adds
post-seal evidence. It rechecks every final runtime byte against the tested copy.
The resulting `final-package.json` is the receipt/R9 input identity.
