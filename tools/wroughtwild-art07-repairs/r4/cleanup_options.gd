extends RefCounted
## R4 fixture controls only. No player, audio palette or native tuning changes.
const PREDISPOSE_FRAMES := 3 # Let queued two-frame UI layout callbacks finish while their owned controls still exist.
const MIX_PASSES := 2 # Observe two real mixer progress events after stopping owned voices.
const MAIN_FRAMES := 2 # Allow deferred node frees and main-thread audio retirements.
const POLL_SLEEP_MS := 1 # Yield CPU so accelerated headless frames cannot starve the mixer.
const TIMEOUT_SECONDS := 2.0 # Fail visibly if owned playback cannot retire; never treat a timeout as success.
const SOAK_ITERATIONS := 12 # Bounded repeated create/work/restore/dispose sample, not a long-session claim.
