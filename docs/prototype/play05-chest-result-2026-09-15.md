# PLAY-05 — reliable chest transfer controls

Store/Take buttons now survive their own refresh and are safe to use repeatedly.
Counts and messages update immediately, while retired controls cannot move stock
again after refresh, close/reopen or switching to another chest. Native transfer
quantities, capacities, paid storage, save format and approved art are unchanged.

Owner playtesting remains deferred. This is a focused interaction fix, not a
station enjoyment review or a performance result. PLAY-04 remains owner feedback;
PLAY-03 underground lag/diagnosis stays parked and unresolved. R9 remains stopped.

## Scope and cause

- Worker: `D:/Wroughtwild/work/play05-chest`, branch `codex/play05-chest`.
- Prepared main base: `cb5367a3b3ac0a395694bd41fc49cfdf66db1154`.
- [Approved work item](play05-chest-worker-2026-09-15.md), current owner-depot
  `AGENTS.md`, D-005/D-006/D-017 and the
  [accepted hauling contract](building-loads-2026-09-08.md) govern this slice.
- The retained preview log reports three signal-emitter lifetime errors from
  `ChestPanel.refresh()` inside `store()`. It and the preview's saves were read
  only; neither was copied or changed. This error does not establish item loss
  or explain underground lag.

`chest_panel.gd` used `free()` on every row during the button's `pressed` signal.
Its new `_clear_rows()` disables and disconnects each old row's buttons, removes
that row immediately, and uses `queue_free()` so deletion waits for signal
emission to finish. Closing the panel uses the same cleanup. Transactions and
refresh remain synchronous, preserving `store()`/`take()` return values and
native authority; there is no deferred transfer to target another selected chest.

No new tuning, capacity, save field, migration, art, dependency or gameplay rule
was introduced. The unchanged native DLL prepared in SETUP was reused without
rebuilding or copying another runtime package.

## Focused verification

Godot 4.5-stable, headless with Dummy audio. No rendered capture or desktop input
was needed. Scripted viewport clicks and real button signals exercised the normal
player/chest wiring on authored ground with fixed fixture stock. The two chests
were placed through the normal catalogue/payment path: 49 wood minus two six-wood
chests left 37. This does not measure gathering pace or a generated-world campaign.

| Check | Actual outcome |
| --- | --- |
| Worktree import/setup | Exit 0, no engine errors; 37.26 seconds. Imports/private state stayed on D:. |
| Original Store-button reproduction | 14 assertions passed, but one matching signal-emitter error occurred. Engine exited 0; the runner correctly failed with exit 1 on that diagnostic. Ten wood moved exactly once. |
| Fixed transfers and lifecycle boundaries | **196 assertions passed**, exit 0, no engine errors. Real signals and viewport clicks cover Store/Take 10/all, immediate repeat activation, empty sides, removal of an emptied family, close/reopen, switching stores before queued deletion, synchronous return values and truthful counts/messages. |
| Native capacity edges in that same fixture | A five-unit remaining chest space accepts only five; a full chest refuses. Two remaining pack spaces accept only two; a full wood family refuses. Existing 960 shared chest units and 240 carried wood remain exact. |
| Fresh-process Continue and use | **45 assertions passed**, exit 0, no engine errors. The real Continue button invokes `player.load_game()`/`SaveManager`; both paid blocks and store keys, every receipt quantity, 27 carried wood, 10 in the first chest and an empty second chest restore. E access, Take/Store and close/reopen retain those counts. |
| Source checks | Focused Git diff/whitespace and runner syntax checks accompany the checked worker commit. |

The first Continue attempt passed the explicit 27/10 quantity and use checks but
failed two whole-dictionary receipt comparisons: JSON reads numbers as floats,
where native dictionaries contain integers. The fixture now compares both sides
in the same JSON representation, keeping every key and quantity. Only this
Continue check was rerun; the production fix and passed transfer cases did not
change. The initial failed stdout/stderr are retained beside the final logs.

Commands from this worker root:

```powershell
./tools/wroughtwild-play05/run_checks.ps1 -Job import
./tools/wroughtwild-play05/run_checks.ps1 -Job transfers
./tools/wroughtwild-play05/run_checks.ps1 -Job restore
```

`transfers` writes the isolated checkpoint used by `restore`; use the same
`-Output` for both. `-Job reproduce` runs only the initial Store signal path and
also fails on any engine error; the recorded baseline used the original panel.
The runner retains process handles, validates exit codes and engine diagnostics,
and stops its owned process on failure/timeout. All owned check processes ended.

Evidence is local and ignored:

- `build/play05/baseline/`: import and original reproduction logs/results.
- `build/play05/checks/`: transfer and Continue logs/results, focused ownership
  receipt and private APPDATA/LOCALAPPDATA/TEMP. No real save was accessed.
- The worktree's generated import caches/sidecars are local test artifacts, not
  part of the worker commit. Approved source/runtime assets remain untouched.

## Normal-game use / Continue steps

After coordinator integration, launch the normal game or Continue an existing
world. Default keys below follow existing bindings if remapped.

1. Open a paid chest with **E**. To place one, use **B → Tab → Chest → Timber**;
   normal placement costs six wood. For the example, start with an empty chest
   and **37 carried wood after placement**.
2. Click **10 »** twice: pack/chest become **27/10**, then **17/20**.
3. Click **« 10** once: **27/10**. Close with **Esc**, then reopen with **E**:
   those counts remain **27/10**.
4. Close, press **F5** to save, quit, launch normally and select
   **Continue saved world / suspended trial**. Reopen the same chest:
   **27 carried / 10 stored wood**, with the same chest and material.
5. **« Take all** gives **37/0**; **Store all »** gives **0/37**. With other
   quantities, native room/carry limits decide the actual moved amount and the
   message reports that amount. A full destination leaves ownership unchanged.

Full generated-world travel, other save scenarios, hardware performance and
human station comfort were not retested; applicable unchanged ownership evidence
from INT-03D was reused. No new observed gameplay failure remains in this scope.

## Delivery

The checked worker commit is returned by exact SHA for coordinator integration.
This worker does not integrate into main, push, rebuild a playtest package or
start the next task. Main publication and aggregate tracking remain with the
coordinator.
