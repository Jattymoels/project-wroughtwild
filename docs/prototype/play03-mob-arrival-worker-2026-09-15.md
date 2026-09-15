# PLAY-03 â€” remove the brief hitch when mobs appear

Status: first partial improvement integrated on main as `87849bd`, 15 September 2026.
[Measured result and remaining hitch](play03-mob-arrival-result-2026-09-15.md):
443 ms to 324 ms on the selected arrival; PLAY-03 remains open.
The [presentation continuation is also adopted](play03-presentation-hitch-result-2026-09-15.md)
as `1bc19e9`: selected first boar arrival 324.760 to 7.529 ms. Both worker scopes
are complete; broader lag observations remain open.
Worktree: `D:/Wroughtwild/work/play03-mob-arrival`.
Branch: `codex/play03-mob-arrival`. Setup: `build/play03-arrival/SETUP.md`.
The owner starts this worker; the coordinator integrates the checked result and
matching native runtime into main and pushes. Stop after this slice.

## Outcome and reading

The owner reports large lag when nearby mobs visibly appear in ordinary overworld
play, then clarified **"A brief hitch, then recovers"**. Diagnose the actual
arrival cost and implement the smallest supported improvement. The suggested
connection to the earlier long underground fall is not yet proven. Keep the
original lag issue open to any remaining evidence; do not manufacture an access
restriction, a permanent-population benchmark or a claim that every hitch is fixed.

Read the current owner depot's `AGENTS.md` and follow its required reading order.
Then read [the owner evidence and inspected call paths](play03-mob-arrival-followup-2026-09-15.md),
[the existing recorder result](play03-underground-result-2026-09-15.md),
[RF-05's adopted result](rf05-lakes-swimming-result-2026-09-15.md), and only the
relevant combat, loot/save and world-generation specifications. Reuse their
applicable evidence. R9 stays stopped; there is no hard ten-minute completion gate.

## Capture the arrival, not an already-warmed scene

Use the existing opt-in `play03_trace.gd` and small bounded phase markers to
distinguish dormant activation, support queries, per-member instantiation,
`Enemy.configure`, `CreatureMotion.attach`/presentation setup, and first active/
rendered frames. Include the pack/member count and role needed to interpret the
event. Timings must be attributed to their actual frame/interval; nested timings
are not additive. The existing one-Hz enemy count is insufficient for attribution.
Render setup/wall-time counters are not direct GPU execution measurements.

Start with one reachable ordinary non-trial overworld pack in V8, seed 77 unless
that gives no useful nearby case. A bounded choice of a pack is fine; the exact
owner species/location is unknown. Stage the initial player pose outside its
28 m activation radius, disclose that setup, then approach using real movement.
Start recording before activation and preserve the first use of the selected
creature's assets. Do not call its model/scene loader, preview it, create hidden
actors, or walk through the spawn radius before the diagnostic window. Do not
purge system/driver caches or claim an OS-cold cache without evidence.

One short session can include a later arrival of the same role and immediately
recovered frames when needed to separate first-use work from repeated setup.
Do not scan every species, seed, camera, biome, renderer or hardware target.
Keep ordinary physics, AI, terrain/resource streaming and quality active; record
competing work rather than silently disabling it. No capture readback, per-frame
JSON writes, shader inspection or screenshot generation inside timed intervals.
Use existing bounds/ring storage and write the receipt after the window.

## Make the demonstrated improvement

The pre-RF05 source inspection found synchronous whole-pack construction and
first-use model/material loads. These are leads, not timing conclusions. RF-05
adds V8 eligibility and a bounded `Enemy._move_on_land` lake guard; preserve it.
Follow the measured cost before choosing preparation/caching, spreading creation,
removing duplicate setup or a more specific correction. Do not rewrite a broad
streaming framework or move the same long hitch to an unmeasured later frame.

Preserve approved creature models, materials and animations, encounter counts,
28 m activation semantics, aggro/damage/loot, quiet opening and existing caps.
Do not gain a performance result by suppressing underground mobs, lowering detail,
changing frame caps/quality or disabling the arrival itself. If work is prepared
ahead of activation, dormant mobs must not become live/attackable early. Avoid
invisible active enemies or missing collision during staged presentation.

If construction becomes queued, reserve capacity once and preserve deterministic
member order, exact sleeping survivors, finite defeated hosts, elite/escort
selection, noise recruitment and death/loot ownership. Cancellation on world
replacement, Continue and trial entry must not create duplicates, resurrect a
defeated actor or leak work into another world. Check only the lifecycle boundaries
actually affected; do not reopen all six mob delivery suites.

Preserve V8 lakes, shore constraints, surface swimming, paid support and floating
recovery, plus V1â€“V7/LF saved geography. Do not reseed, migrate saves, alter native
generation inputs or change campaign rules. Any new scheduling control belongs
in an existing suitable tuning resource with a plain-language purpose.

If the reported hitch does not reproduce in the bounded case, deliver the useful
targeted incident markers and exact limitation; do not substitute an assumed fix
or expand into a general performance intensive. The task result must distinguish
diagnostic progress from a demonstrated improvement.

## Three focused jobs and delivery

1. One short causal arrival capture on Forward+ with the scoped phase markers.
2. The same arrival after the justified correction, with the same world/route and
   comparable asset-use state; report the actual pause and where the work went.
   This is a focused check of the reported defect, not an art baseline gate.
3. A headless lifecycle/ownership check for the behavior changed, including
   cancellation/Continue if scheduling changes. Reuse unchanged RF-05 and mob
   evidence. Rerun a focused check only for an observed failure or changed behavior.

Use the verified test-only `--r8-no-mouse-capture` opt-out, BOM-free no-focus
override and `Local\WroughtwildArtRender` mutex. Do not use the desktop pointer.
Keep all compilation/import/trace/private-save output on D: and end owned jobs.
The inherited DLL already implements RF-05; rebuild only if native source changes,
using the existing ABI and incremental objects. Never replace the owner depot DLL.

Write `docs/prototype/play03-mob-arrival-result-2026-09-15.md` with actual gameplay,
measured cause/improvement or diagnostic-only limitation, focused checks, tuning,
exact normal playtest route/flags and commit/native status. Retain a small trace
summary, not a full package. If useful, show a short representative clip outside
the timing window; an extra media production job is not required for a hitch fix.
Commit checked source and selected evidence on this branch, report the matching
DLL path/hash if rebuilt or the inherited hash if unchanged, and stop for adoption.
