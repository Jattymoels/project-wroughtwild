# Project storage and retention — 15 September 2026

The owner authorised the recommended storage work only if it preserves the
current remote-access process. The active C: depot remains in place. New large
worker workspaces and outputs should use D:; existing active work is not moved.

Completed cleanup removed all twelve selected duplicate directories, totalling
31.28 GB of logical file data. C: free space increased by approximately 31.45 GB,
from 10.62 GB to 42.08 GB during the operation (other running tasks can affect
these drive-wide readings). The archive retains 6,277 report/script/text files.
No gameplay assets or player saves were changed.

## What was selected for cleanup

The read-only scan found approximately 322.26 GB across Wroughtwild's C: depot
and sibling worktrees. The main depot's ignored `build` directory accounted for
287.52 GB. These are logical file sizes, not exact allocated disk usage. Media
was mostly images/textures and repeated model packages; no common video files
were found in accessible project paths.

Twelve publication/review directories beneath the main depot's `build` were
selected as disposable copies, distinct from the canonical worker handoffs:

- `art07-publication-2026-09-11`
- `art07-publication-2026-09-11-batch3`
- `art07-publication-2026-09-11-batch4`
- `art07-publication-2026-09-11-batch5`
- `art07-publication-2026-09-12`
- `art07-publication-2026-09-13`
- `art07-publication-2026-09-14`
- `art07-repair-publication-r2-2026-09-14`
- `art07-repair-publication-r5-2026-09-14`
- `art07-repair-publication-r67-2026-09-14`
- `art07-repair-publication-r8-2026-09-14`
- `art07-repair-publication-rest-2026-09-14`

Before deletion, top-level files and nested text records/scripts were retained under
`D:/Wroughtwild/archive/publication-records-2026-09-15`, preserving relative paths.
Copied file lengths were verified. This archive preserves reports and machine-readable
evidence, not every image, imported asset or disposable runtime. Committed curated
evidence and original source-package evidence stay in their existing locations.
Historical references to the removed copied runtimes are no longer runnable.

The local cleanup manifest is `build/storage-audit-2026-09-15/cleanup-result.json`,
also retained at the archive root. The original scan and summary remain in that
local audit directory. Generated audit files are intentionally not committed.

## What stays in place

- The C: owner depot, `.git`, all registered worktrees and every branch.
- The active A1 worktree at `D:/project-wroughtwild-mainline-art-a1`, including
  its current helper scripts under the main depot's `build` directory.
- R8's final handoff under `D:/project-wroughtwild-art07-r8/build/art07-repairs/r8/v01/handoff-final`.
- Original ART-01/02/03/04/05/06 packages, approved ART-06C models and ART-07
  canonical source packages, including editable Blender masters.
- The owner's `build/art-playtest` launcher, runtime and private save directory,
  ordinary game saves, uncommitted captures and unrelated local changes.
- Local generation tools/models, Codex configuration, sessions, installed
  runtimes, remote-access services and running server processes.

The large nested `build/art07` tree contains real registered worktrees and unique
ignored packages. It is not safe to treat its entire size as disposable cache.
Moving the active owner depot is deferred because current tasks and server
scripts reference its absolute C: path. No app settings, service lifecycle or
worktree registrations are changed for this cleanup.

## Storage convention for subsequent work

| Purpose | Location |
| --- | --- |
| New explicitly prepared worktrees and scratch outputs | `D:/Wroughtwild/work/<slice>` |
| Newly archived approved editable art and manifests | `D:/Wroughtwild/source-art` |
| Current playable package and one useful previous package | `D:/Wroughtwild/releases` |
| Selected historical reports and evidence | `D:/Wroughtwild/archive` |

These directories are local storage, not an off-device backup. Existing package
paths remain valid; relocation of unique sources needs an explicit source-to-
destination record and dependent-path handling. Do not move files merely to
conform to the new layout while their consumers are active.

Retain selected evidence instead of complete repeated capture runs. Retire
confirmed redundant review copies and unused import caches at the end of a slice
after identifying the retained originals and checking active users. Keep unresolved
bug evidence and player saves. Never purge images, videos or Blender files solely
because they are old. Reuse existing verification; do not reconstruct packages
to prove that disposable copies are disposable.

## Verification scope

Three focused jobs: identify active paths and retained inputs; archive records
and remove only resolved, allowlisted redundant outputs; check preservation,
free space and the documentation diff. No game tests, rendering, broad package
hashing or restarts are required for this storage-only change. The same ten-minute
task budget applies. Gameplay behaviour is unchanged.
