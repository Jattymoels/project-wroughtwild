# PLAY-05 — reliable chest transfer controls

Work in `D:/Wroughtwild/work/play05-chest`, branch `codex/play05-chest`.
Read `build/play05/SETUP.md` for the actual main base and unchanged native DLL.
Use this checkout even if the task opens at the C: owner depot. The owner starts
this worker; return its checked commit to the coordinator for main integration.

## Outcome

Make the existing chest Store/Take buttons safe to use repeatedly, correcting
the concrete signal-lifetime errors recorded during the owner's preview. Preserve
the normal interaction, actual transferred quantities, native capacity validation
and paid storage through ordinary Continue. Keep the current art and game rules.
This is a small usability/reliability slice, not a redesign or station audit.

The owner asked for the next work after PLAY-03 found no demonstrated lag cause.
Standing approval covers ordinary scoped implementation and publication. PLAY-03
is parked pending the next owner playthrough; do not investigate it here. PLAY-04
station enjoyment/usefulness remains human feedback. All six replacement mobs are
already adopted. R9 stays stopped; no hard ten-minute cutoff or art approval gate.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, reusing unchanged prior reading. Then read only:

- `docs/systems/construction.md`, especially the chest/hauling contract;
- `docs/prototype/building-loads-2026-09-08.md` for accepted capacities under
  D-005/D-006/D-017; reuse its evidence rather than its old review programme;
- `game/scripts/chest_panel.gd` and directly relevant player/placed-block wiring;
- the small storage portions of `game/tests/home_workshop_review.gd` and the
  actual UI-event pattern in `game/tests/custom_panel_refresh.gd`. Do not run
  either full historical suite by default.

## Concrete evidence and smallest fix

Retained original log:
`C:/Users/Matty/Dev/project-wroughtwild/build/art-playtest/user/ART07G1/logs/godot.log`.
It contains three errors saying an object was freed while emitting a signal,
with `ChestPanel.refresh()` called by `store()`. Preserve the original log and
private preview state. This is not evidence of lost items or a cause of lag.

Current main's `_add_row()` connects a button's `pressed` signal to `store()` or
`take()`. Those operations call `refresh()`, which removes and synchronously
frees every old row. Start by reproducing the reported lifecycle path through a
real button signal or scripted UI input, not solely a direct call to `store()`.
The older home fixture's direct calls verify quantities but skip the emitter.

Correct the lifecycle at the narrowest suitable point. If refresh/free/action
work is deferred, make sure obsolete buttons cannot issue duplicate transfers
or apply a stale action to a different chest after close/reopen. Preserve the
existing method return values and native transaction authority. Reuse existing
UI patterns where useful; do not introduce a generic panel framework.

Keep displayed pack/chest counts, empty/full feedback and current store identity
truthful after each accepted action. Fix only a directly demonstrated adjacent
problem needed for this interaction to work. No new capacities, remote crafting,
inventory sorting feature, chest art, economy, station behavior or save schema.
Tiny visual polish and slab appearances stay in the backlog.

## Focused checks and delivery

Name the concrete risk before checking. Normally use these three small groups,
combining closely related cases in one fixture rather than a broad matrix:

1. Reproduce the reported error through an actual Store button and verify the
   correction with Store/Take controls, including an emptied row. Assert native
   totals move exactly once and inspect engine errors; never suppress diagnostics.
2. Check the changed lifecycle boundary: immediate repeated activation and
   close/reopen or chest switching while a refresh is pending. Include one native
   capacity refusal/partial transfer if that path is affected. Old callbacks must
   not move stock into a newly selected store. Reuse unrelated native evidence.
3. One short normal open/use/close and relevant paid-store Continue check, reusing
   existing save helpers. No whole campaign/home journey or repeated world rebuild.
   If the fix leaves save/ownership code untouched, keep the restoration check to
   this chest's exact contents and identity; do not rerun every save scenario.

Prefer headless fixtures with scripted input: no desktop pointer movement. A
rendered capture is optional only if useful to demonstrate a visible change, on
Forward+ with verified no-focus/visible mouse and `--r8-no-mouse-capture`. Follow
the corrected MOB-06 launcher patterns, BOM-free overrides and owned process
handle/exit checks. No hardware baseline, benchmark, package reconstruction or
multi-camera review. Stop all owned checks and remove only owned temporary files.

Own the narrow production fix, scoped tests/runner under `game/tests/` and
`tools/wroughtwild-play05/`, and
`docs/prototype/play05-chest-result-2026-09-15.md`. Keep imports, logs, private
saves, APPDATA/TEMP and large output on D:. Do not touch owner captures, real saves,
other worktrees, Git/app/remote settings or unrelated generated sidecars. Do not
rebuild the native library unless a necessary scoped native edit requires it.

Commit on `codex/play05-chest` and return the exact checked SHA. Lead with the
actual player-visible behavior, then checks run, remaining limits and commit/push
status. Give exact normal-game playtest steps: open a paid chest, store/take,
close/reopen, and Continue with expected quantities. Leave aggregate tracking and
main publication to the coordinator. Do not start another work item afterward.
