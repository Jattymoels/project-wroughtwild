# ART-07R2 retained diagnostics

Every actual engine attempt remains in the package, including fatal attempts.
A later successful run has its own fresh log and private state. The shared runner
was not changed: a fatal diagnostic fails the job even if earlier assertions pass.
No assertion was removed, lowered or reclassified as a successful fresh run.

## Corrected additive harness defects

| Attempt | Observed failure | Correction and evidence |
| --- | --- | --- |
| v01 `benchmark-baseline-forward_plus-01` | GDScript could not infer the new texture-inventory key's type | Explicit `int` in the additive inventory. All 12 unchanged-production comparisons reran as fresh `-b` jobs. |
| v03 `f2-flow` | The new evidence directory did not exist, so `_done` received a null FileAccess | Create only that directory at the start of the additive replay. Inverse substitution restores all original lines/assertions. Fresh `f2-flow-b` and `f2-restart` passed. |
| v03 `projection-equivalence` | The added oracle incorrectly demanded a box after native grounded-surface refresh | The pinned `resource_node.gd` uses `GroundedSeam.create_trimesh_shape` there. The corrected added oracle checks the actual ConcavePolygonShape3D faces, pose, enabled state and masks against unchanged G1. Original B3 plain-fixture box checks remain. Fresh `projection-equivalence-b` passed 16,676 checks. |
| v03 `reload-release` | Raw Variant comparison treated JSON floats as unequal to runtime integers; an engine-generated station name is normalized by the original restore | Compare all persisted values through a JSON roundtrip and use the fully verified original G1 post-restore probe as the initial oracle. No keys are omitted; opaque sim/ledger strings remain exact. Fresh art-on/art-off probe bytes also exactly match original G1 evidence. |

Failed projection/reload harness snapshots are retained under
`evidence/v03/analysis/failed-harness/`. The final source replay substitutions and
hashes are recorded independently. Shutdown ObjectDB warnings in successful source
inspections, and deliberate unit-test warning diagnostics, remain in stderr and
the job index; they are not silently discarded.

The non-engine checkpoint restoration guard initially stopped without changing
any file: the paid report shortened one position value to `32.9700012207031`,
while SaveManager's full-precision JSON retained `32.970001220703125`. The corrected
guard recovers only the native Float32 Vector3 position components, requires exact
equality of the entire remaining saved state against a successful paid report,
and preserves the written fixture bytes before restoring the original. Its exact
origin proof is retained. Native save code and assertions were unchanged.

## Immediate retirement limitation

The early reload harness retired newly created render instances without a rendered
frame boundary. R2 produced material-null diagnostics at
`resource_stream.gd:161` (`node.free()`), both in the dummy headless renderer and
in Forward+. The unchanged G1 headless reference reproduces the same diagnostic
in a fresh process (`v01/reload-headless-g1-reference.log`). A separate unchanged
G1 Forward+ process also reproduces the same four material-null diagnostics at
that line (`v01/reload-zero-frame-g1-forward_plus.log`, 104.019 seconds, fatal
exit -1, log SHA-256
`bbe1eec31dabe18c5331ce55729e5a69ea3a63b4e4c579de4f87ded3a43d87fa`).
The frame-paced original G1 flows pass both renderers. This attributes the
immediate-retirement failure to the common baseline; it does not declare it fixed.

The final additive flow permits two process frames and an actual rendered boundary
after each visit/read. All owner and geography checks still run, including checks
before that boundary. Three home/route/read cycles, actual partial work,
release/re-entry, exhaustion and fresh-process restore pass in each renderer.
These passes do not clear the immediate-retirement stress failure, establish
long-duration leak freedom or claim an R4 lifecycle repair. The original native
streaming/retirement implementation remains unchanged. R4/R8 integration must keep
this evidence visible when evaluating resource lifetime changes.

## Scheduling and scope

An initial v01 import attempt was deferred before any child launched, then hit the
shared runner's missing-log reporting defect. The runner remains unchanged. The
owned queue acquires the same mutex first, then invokes the existing guarded runner.
A separate bounded wait for the original-G1 Forward+ stress reference expired while
the R2 native suite held the slot; it launched no engine process. Such deferrals
are not performance samples or successful tests. No other process was stopped.
There were no automatic approval rejections during this task.

The 24 repeated benchmark processes support the setup and loaded-texture result.
Imports, first-focus/warmup, single observations of controller traversal, fixed-cadence
captures and native flows have different timing boundaries. OS/driver caches were
not flushed. Streaming spikes remain, and no minimum-hardware budget or target-device
acceptance is inferred. Owner visual acceptance remains pending.
