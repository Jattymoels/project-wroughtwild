# PLAY-01/03 worker - comfortable movement and unintended underground access

Use the prepared worker at `D:/Wroughtwild/work/play01-movement`, branch
`codex/play01-movement`. Read its `build/play01/SETUP.md` for the actual current-main
base and reused native DLL. Do not recreate the checkout. Main includes A1's R8
art and A2's finished fauna. Owner depot and shared Git metadata remain at
`C:/Users/Matty/Dev/project-wroughtwild`; keep new large outputs/private application
data on D:. The owner starts this worker; do not spawn workers or a review wave.

The owner cannot currently playtest and grants standing approval for this agreed
work. Get a usable improvement into normal play, with honest limits. No further
visual approval, baseline clearance or hard ten-minute extension request applies.

**Owner correction during execution, 15 September 2026:** PLAY-03 is significant
lag underground, not access underground. This supersedes access-fault assumptions
in the original instructions below. [Checked result and remaining question](play01-movement-result-2026-09-15.md).

## Outcome and evidence

Diagnose and fix the reported intermittent stuttering/judder during movement,
and accidental access below terrain with much worse lag. The causes may be related
or separate. Do not assume streaming, shader compilation, collision or art density
is responsible. Preserve approved art, saves, progression and legitimate world rules.

Read current owner AGENTS.md, then the required README/DESIGN/decision/prototype
documents, reusing prior reading where applicable. Read the actual PLAY-01/03
observations in `docs/prototype/art-mainline-adoption-2026-09-14.md` and relevant
world/movement sections of `docs/systems/world-generation.md`.

Useful existing evidence and code:

- Current production: `game/scripts/player.gd` movement/step-up,
  `game/scripts/terrain.gd`, `game/scripts/resource_stream.gd`, existing terrain
  chunk publication/support logic and `game/art/strange_stream.gd` settings.
- `game/tests/travel_performance_review.gd` has frame/process/physics/draw sampling;
  `game/tests/travel_profile_terrain.gd` records terrain work and safety refills.
  Reuse applicable instrumentation, not the old runners' entire test programme.
- `docs/prototype/frame-pacing-2026-09-07.md` records a previously fixed missing-
  support fault under sparse updates and a still-unattributed intermittent pause.
  `stream-scheduling-2026-09-07.md` and `focus-scheduling-2026-09-07.md` describe
  existing work scheduling. Read relevant findings only. Do not replay their
  old hardware/renderer/route matrices or infer today's cause from an older bug.
- Original owner preview is under the C: depot's `build/art-playtest/`.
  `play.ps1` sets private state under `user/ART07G1`; `g1-play.json` was absent
  at coordinator inspection. `runtime/game/g1/paid-home.json` exists as the
  original starting checkpoint. Preserve all originals. Copy only a needed
  checkpoint/log into a D: diagnostic folder and label its provenance.
  Do not rebuild the multi-GB R8 package or adopt its frozen gameplay again.
- The owner did not provide an exact underground coordinate or sequence. You may
  investigate likely terrain/step/support transitions in current main and use
  the preserved starting checkpoint with current code. Label a synthetic case
  separately; do not claim it reproduces the owner's exact incident.
- The preview's `user/ART07G1/logs/godot.log` contains chest-panel refresh/store
  signal-lifetime errors. These are a separate logged UI issue, not evidence of
  the movement cause. Leave them recorded unless causally relevant to this slice.

## Small implementation approach

Restate the concrete outcome, affected systems and initial hypotheses. Start with
one short representative movement sample and inspect real frame spikes alongside
player support/terrain state. Average FPS alone cannot explain intermittent judder.
Use bounded counters/timestamps or existing engine diagnostics; avoid per-frame
disk logging and expensive screenshots that create the disturbance being measured.

Trace the responsible synchronous work or the invalid movement/support transition
before changing it. Make the smallest causal correction. Preserve actor/world
identities, authoritative collisions, saves, finite resources, normal entry and
Continue, octagonal building support, and legitimate caves/digging/terrain changes
where the existing game permits them. Do not mask a hole with a blanket teleport
or disable collision, and do not remove approved art merely to improve an FPS number.

Use narrowly explained tuning only when evidence justifies it. Avoid a new
scheduling framework, graphics-quality overhaul or large refactor. If the two
reports have different causes, prioritise the concrete comfortable-travel fix and
record what remains unconfirmed. A clean repeat alone does not prove a rare stall
fixed. Do not claim both reports solved if only one has supporting evidence.

## Focused checks

Default to three focused jobs, with Forward+ as the only rendered backend:

1. A brief representative diagnosis of movement spikes and terrain/support state,
   using current main and one relevant route/transition. Extend only enough to
   explain a concrete observed event; no all-seed/material/camera matrix or soak.
2. A focused reproduction/regression check of the demonstrated cause after its
   correction. Report relevant spike/event measurements and the exact case tested.
   Reuse the same small setup; no rebuilt baseline project or full pipeline review.
3. A short load/use/Continue check for changed behavior and the directly affected
   collision/ownership contract. Reuse A1/A2 evidence for unchanged art, actors,
   stations and saves rather than rerunning their catalogues.

Use headless checks for state assertions. Any necessary rendered sample must use
the existing `--r8-no-mouse-capture` path and a verified disposable no-focus override
(`display/window/size/no_focus=true`); confirm visible mouse/unfocusable window.
Use scripted player/camera input, never the desktop pointer. Remove the override
before delivery, keep normal manual controls intact and stop all owned processes.

Keep observed failures and unverified risks explicit. If a report remains rare or
unreproduced, deliver the useful scoped fix or lightweight diagnostic with a precise
remaining question; do not spin up new review waves or wait for unavailable human
playtesting. Minor floor/furniture cosmetics and canopy polish are separate work.

## Delivery

Commit the checked slice on `codex/play01-movement`, with a concise result explaining
the cause established, what changes during actual play, checks run, remaining
uncertainty and any tuning purpose. Update the coordination sheet/queue so PLAY-01
and PLAY-03 can have distinct statuses. Preserve the owner guidance, dirty captures,
original saves/packages and unrelated branches. Do not commit logs, caches, private
checkpoints or diagnostic captures en masse. No native DLL or portable rebuild is
required unless the scoped implementation actually changes the native library.

Return exact commit IDs and normal-main launch/playtest steps to the coordinator
for ordinary integration and push to origin/main. Next after this scope is canopy
completeness, then the six approved replacement rigs in individual playable slices.
R9 stays stopped throughout.
