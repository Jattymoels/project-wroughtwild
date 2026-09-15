# PLAY-03 continuation: remove the remaining presentation freeze

Completed and adopted 15 September 2026 as `1bc19e9`, from worker `039bccf`.
[Measured result and playtest](play03-presentation-hitch-result-2026-09-15.md):
selected arrival 324.760 to 7.529 ms, with about 0.9 s of entry preparation.
The dispatch below is retained history; do not restart it automatically.

Original task and checkout:

- Workspace: `D:/Wroughtwild/work/play03-mob-arrival`.
- Branch: `codex/play03-mob-arrival`, completed first slice `de0125f2062d9cd628b44bd23e76094676336d11`.
- Main adopted that slice as `87849bda32be28c0d52751979d8bebfba794354c`.
- Current brief: this file in the owner depot; it supersedes the initial SETUP's
  instruction to stop after the smallest improvement. Do not replay the adopted
  commit, reset the branch, reconstruct a package or start another worktree.
- The owner resumes the worker; the coordinator integrates and pushes afterward.

## Outcome

The owner challenged the first result because significant lag remained. The
measured 443 to 324 ms improvement is useful, but a roughly one-third-second
freeze is still the reported defect. Do not describe it as acceptable prototype
performance or count functional assertions as a smoothness result.

Pursue the remaining measured presentation setup cost until the selected normal
first arrival no longer produces the conspicuous freeze, or identify a concrete
technical blocker and the implementation needed to resolve it. Do not stop after
another small saving if the dominant measured operation is still actionable.
Keep the implementation focused on that causal path; this is not a general
performance intensive, all-mob rewrite or production performance certification.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and follow its
required reading order, reusing unchanged project context. Then read the adopted
[result](play03-mob-arrival-result-2026-09-15.md), existing retained receipt and
trace, and this continuation. The old worker result in the D: checkout still
describes its pre-adoption handoff; the coordinator section in main is current.

## Known target and next implementation

The selected V8 seed-77 pack is index 176, one `ember_whelp` using the finished
boar, at (338.5,39,598.5). The existing fixture begins outside its 28 m activation
range and walks normally. After the first fix: 324.445 ms arrival interval,
314.657 ms Enemy.configure, 307.916 ms presentation setup, then 15.578 ms interval
including first draw. These nested spans overlap. The hidden recovered mesh is
already reduced from 125.855 to 0.049 ms; preserve that improvement.

Break down `FinishedFauna.setup` inside the existing opt-in recorder: first model
resource acquisition, scene instantiation/registration, rig and bounds discovery,
texture/material acquisition and assignment, initial animation seek, and any
other observed substantial substep. Do not guess that all 308 ms is disk loading
or shader compilation. CPU call durations and draw wall observations are not GPU
execution times. Ordinary startup grazers already load; selected boar first use
is the relevant initial condition.

Use the measured breakdown to implement the smallest complete removal of the
dominant on-arrival stall. Resource preparation/caching, less repeated setup,
bounded staged preparation or a narrow startup preparation step are possibilities,
not prescribed diagnoses. If shared code helps the other finished fauna naturally,
keep that reuse; do not open all six replacement pipelines without evidence.

Production preparation is allowed. The old fixture's assertions that the boar
cache is empty immediately before walking described the old implementation; they
must not prevent a real preparation fix. If the design changes resource readiness,
replace those assertions with checks of the new production contract and record
where preparation occurs. Do not preload only inside the fixture or conceal the
cost in its 90-frame waiting period. Capture all interactive approach/preparation,
activation, first draw and recovered frames. A startup-only transfer must happen
in the actual normal New World and Continue paths before controls are usable,
with added startup time reported. For preparation while moving, report the worst
preparation frame as well as arrival. Deferring the same freeze is not success.

Aim for arrival work to fit an ordinary frame, approximately 16.7 ms at 60 fps.
This is a focused engineering aim, not a whole-game hardware benchmark gate.
Report actual approach/arrival intervals and attributable costs. Any remaining
conspicuous freeze stays open with its measured reason and a concrete next remedy;
do not relabel it fixed merely because the percentage improved.

## Preservation and focused verification

Keep adopted art, animation, fit, labels, status/elite/LF tells, mob counts,
activation/aggro rules, collision and death/loot ownership. Never leave invisible
active enemies or suppress the encounter to improve a timing. Preparing resources
must not make dormant mobs active early. If spawning/scheduling changes, preserve
ordering, exact sleeping survivors and finite hosts, and check the affected
world/Continue/trial cancellation and population-reservation boundaries.

Preserve RF-05 lakes/swimming/shore guards/recovery and V1-V7/LF saves, paid
ownership and campaign rules. Keep the current RF-05 DLL unchanged unless native
source actually changes; its SHA256 is
`fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b`.
Use existing imports and ABI inputs; no fresh package or native baseline build.

Reuse the first worker's evidence. Default to three focused jobs on Forward+:

1. One targeted breakdown of the already reproduced presentation path, using the
   existing route and bounded recorder. Retain the previous before/after pair.
2. The same route after the complete correction, covering any production
   preparation and first use through recovery. Report where time moved and check
   the ordinary entry path if startup preparation changed it.
3. Focused headless preservation/lifecycle checks for the behavior actually changed.

Concrete failures or changed implementation can justify a focused rerun; there
is no hard ten-minute cutoff. Stop verification when evidence is sufficient, not
implementation while the known dominant stall is still straightforward to address.
No species/seed/renderer matrix, driver cache purge, broad benchmark or R9 work.
The later unexplained 114.660 ms event had no arrival; keep it recorded and do not
divert into a separate investigation unless new evidence connects it to this path.

Use the existing verified mouse opt-out, BOM-free no-focus override and renderer
mutex. No pointer automation or automatic interactive game launch. Keep all output
on D:, use new result directories so first-slice traces survive, and end owned jobs.
No per-frame trace-file writes or screenshots inside the timing window.

## Delivery

Write `docs/prototype/play03-presentation-hitch-result-2026-09-15.md`: actual
gameplay improvement, dominant cost and correction, complete approach/arrival
timings, checks, remaining defects, any new tuning, native status and commit SHA.
State clearly whether this is a resolved selected case or still a partial fix.
Supply simple playtest directions usable with the actual HUD, or an isolated
launcher with a disclosed starting pose outside the pack. There is currently no
player coordinate/compass display; do not rely on unseen coordinates alone.
For `.ps1` instructions use `powershell.exe -NoProfile -ExecutionPolicy Bypass
-File "<absolute path>"`; do not change persistent execution policy.

Commit only the checked continuation on the existing branch, report its SHA for
coordinator adoption, and stop. Do not merge/push main or begin unrelated work.
