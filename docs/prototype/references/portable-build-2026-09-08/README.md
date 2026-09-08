# Portable build evidence — 8 September 2026

[INT-08B work item](../../portable-build-2026-09-08.md).

`verification.json` records the unchanged review package's manifest, file
hashes, actual engine/device information and isolated paths. All gameplay
processes use separate saves and Dummy audio outside the checkout, with the
package directory and working directory distinct. Rendered captures use
1280×720 Forward+ on the local RTX 5090.

- `baseline-tuning.txt`: original export cannot find native tuning despite
  shipping it beside the executable.
- `baseline-startup.txt`: actual pre-change rendered startup reports the
  seed-control null-column error. Its 95 checks alone did not constitute a
  pass; the helper rejected its script error. This baseline is retained.
- `prepare-trial.txt`: clean headless fixture preparation against the earlier
  runtime, 93 passing checks. Forced clears prepare a generated-world boundary,
  without certifying combat difficulty.
- `first-launch.png`: corrected normal class/seed screen.
- `fresh.txt` / `fresh.png`: 116 checks, finite gathering, exact kit crafting,
  one visible usable workbench and saved preferences/world.
- `restart.txt` / `restart.png`: 95 checks, fresh-process Continue.
- `existing.txt` / `existing.png`: 94 checks on the previously checked INT-03D
  V6 seed-77 built-home checkpoint, 182 pieces and three stations.
- `trial.txt` / `trial.png`: 98 checks, exact resumed checkpoint and combat
  values, repeated suspension and continued floor-two presentation.
- `missing-tuning.txt`: one expected-failure diagnostic check on a separate
  incomplete copy. It cannot use the repository's tuning as a fallback.

The focused total is **497** including preparation. Screenshots depict the
actual exported runtime; they are not edited mockups or art-acceptance claims.
Owned fixture saves stay in ignored local evidence; no owner save is included.

`full-suite.txt` and `full-suite-completion.txt` retain test summary lines from
the complete repository headless command sequence. The first segment passes
27,258 assertions before the Strange Frontier fixture's missing ignored output
directory causes two failures. Its corrected rerun and every remaining command
pass 84,445 assertions, ending in the normal main-scene smoke run. Total:
**111,703 passing assertions**, zero script errors. The corrected test adds a
directory precondition; it preserves all save/ownership assertions.
Full raw logs remain under ignored
`build/windows/current-20260908-142928/logs/`. The second segment starts at the
failed `strange_frontier.tscn` command and retains the rest of the tracked shell
helper verbatim. The startup-column correction was tested through rendered
normal launches separately and copied into the suite source before completion.

Initial direct live-vs-parsed comparisons flagged two representation differences
without changed ownership: a JSON binary64 parse rounding step and equivalent
String/StringName cooldown-key encoding. The final tests compare exact saved
JSON, exact decoded combat values and the engine's binary32 return Vector3;
they use no numeric tolerance or relaxed ownership counts.

Builds are local artifacts, excluded from Git. The clean committed source can
be exported again with the documented helper; its manifest records the revision
used and its own binary hashes. This evidence does not establish compatibility
on a second computer, signing, other drivers or owner comfort.
