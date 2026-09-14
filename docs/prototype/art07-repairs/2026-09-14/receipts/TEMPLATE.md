# ART-07RN — task title

Owner correction, 14 September 2026: current AGENTS.md prototype work limits take
precedence. For a review-only or stopped task, a concise achieved/checks/blockers/
limitations report referencing existing artifacts is sufficient. A new package,
full source rehash and the historical package schema below are not required.
Mark unfinished work unverified; do not fabricate a ready delivery to fill fields.

Status: candidate / ready_for_integration / blocked_by_decision.
Owner visual acceptance: pending. Ordinary-world rollout: outside scope.

## Source and scope

Exact worktree/branch, inspected published main base, common game/data/native pin,
consumed manifests and absolute paths/hashes, selected source commits and repairs.
List owned Git paths and every actual changed runtime file/function/setting.
Record original source preservation and any specific overlap for R8 to resolve.

## Result and checks

Describe the reproduced defect and final behavior with measured before/after.
Give exact commands/logs/exit status and known diagnostics, fresh import/reopen and
restart paths, meaningful native assertions, measured device/settings/sample count,
actual image/motion provenance and dimensions. Separate timing, visual and technical
conclusions. State every tuning value/purpose and anything still unmeasured.

## Candidate and limits

Absolute fresh sealed package path and manifest SHA-256, exact file count/bytes,
full manifest verifier command, changes.json and reconstruction/application command.
Do not put the receipt inside its own hashed package. Report retained source/master
paths, maps, selected LODs and how private user paths resolve. Identify blocked
body/geography/architecture decisions without implementing them.

## Commits and publication

Checked implementation commit(s): exact SHA(s). Receipt commit is resolved from
Git history after it is written. Main integration/push: not performed by worker.
Report once and stop; publisher updates the shared delivery index after verification.

The sibling `rN.json` must follow this structure with real values; never submit
the placeholders or mark a blocked candidate ready:

```json
{
  "id": "rN",
  "status": "ready_for_integration",
  "source_commits": ["full checked implementation SHA"],
  "runtime_base": "6bb2e044dcd0bf1788896aa2c19cdf56fee93522",
  "parent_candidates": [],
  "delta_base": "exact common baseline or named verified parent candidate state",
  "package": {
    "path": "absolute fresh local handoff directory",
    "manifest_sha256": "64 lowercase hex characters",
    "files": 0,
    "bytes": 0
  },
  "changes": "changes.json",
  "findings": {"G2-V01": "candidate repair; independent review pending"},
  "checks": [],
  "remaining_limits": [],
  "owner_visual_acceptance": "pending",
  "ordinary_world_rollout": "outside scope"
}
```

Publisher-only deliveries.json row after integration, push and verification:

```json
{
  "rN": {
    "status": "published",
    "source_commit": "exact integrated worker tip or checked cherry-pick",
    "receipt": "docs/prototype/art07-repairs/2026-09-14/receipts/rN.json",
    "package": {"path": "absolute handoff", "manifest_sha256": "verified hash", "files": 0, "bytes": 0}
  }
}
```
