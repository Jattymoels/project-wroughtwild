# Wide Frontier opening and seed controls — 6 September 2026

Implemented under the approved [Wide Frontier intensive](wide-frontier-intensive-2026-09-06.md).

A fresh normal Sandpit launch proposes a random integer seed in the existing
class chooser. The player can type a reproducible seed or press Randomise, then
choose their class to generate that world once. Zero through 2,147,483,647 are
valid; malformed or out-of-range input visibly prevents launch. An optional
`--world-seed=N` supplies the field. Random choices come from the engine RNG,
not a list of handcrafted seeds. The same generation profile and seed define
the geography. The existing Help overlay shows both after entry and restoration.

When a save exists, Continue uses the existing validated `player.load_game`
operation from the empty world. It does not generate the proposed fresh world
first, write the source save, or add a second class/trial prompt. A saved class
continues directly; a historical save without a class still needs the existing
class choice. Invalid restoration leaves the chooser and physics pause intact.
No player save is replaced until the normal explicit save operation. Class
descriptions and seed controls scroll within the available window height. A
temporary backdrop covers the not-yet-generated scene until entry.

Class selection submits a rendered “Preparing your world…” frame before the
synchronous generation starts. If generation returns no usable world, the
chooser stays paused and restores the pre-choice rules snapshot, including
class, inventory and skill loadout. The same seed remains visible beside an
actionable error; choosing another seed is explicit, with no automatic reroll.
Successful generation releases play once. Continue retains its validated
restoration path.

The chooser applies only to the actual normal `sandpit.tscn` scene. Embedded
fixtures, inherited rendered reviews and headless runs retain their deterministic
exported seed (normally 1); a direct headless Sandpit also accepts the explicit
seed argument. Fresh Sandpits now default to `frontier_v6`; existing saves keep
their own profile and seed.

V6 packs read `starter_first_siege_night = 3` from their native map. Nights before
it cannot roll or directly spawn a home siege. Later chance, home proximity,
elapsed-night arrival and dawn dismissal are unchanged. Older profiles ignore
that V6 field and retain their native night-two rule. The native 150 m quiet
heartland and complete patrol segments beyond 190 m provide the geographical
opening; this code adds no player immunity or restriction on early exploration.

Only V6 uses a dormant-pack spatial index. Its exported
`dormant_cell_width_m = 64` controls lookup cost, not activation range or noise
strength. Conservative bins include each den and the complete ordinary and
later-era foreign route. Candidates remain in generated order, then pass the
existing actual three-dimensional position and distance tests. Active packs
continue to patrol and sleep; survivors return to dormant search while spent
packs stay spent. Legacy profiles retain the prior full-list search.

Focused isolated checks on 6 September:

- `new_world_startup`: 97 checks, no failures. Real class API, largest chosen
  seed, zero/parser/random contracts, layout at 1280×720, and exact V5
  save/Continue from an empty generated host. Invalid suspension, missing finite
  pressure ledger, missing seed and an overflowing seed all refuse before
  economy import, world generation or physics release. The source save's bytes
  remain unchanged. A real Tyrant boundary reached through physical route and
  reward APIs also suspends and Continues from the empty chooser with exact
  life, cooldown, deposited economy, unbanked loot and choices. The restored
  checkpoint cannot redeposit its inventory. Forced kills prepare this
  lifecycle case; it is not a human difficulty measurement.
  Controlled generation refusals also verify the pre-generation feedback,
  exact class/economy/loadout rollback, retained pause and seed, repeat failure
  without accumulated kits, and an explicit successful retry in the same chooser.
- `wide_frontier_pacing`: 319 checks, no failures. Native V6 metadata and
  exhaustive-equivalence checks over a synthetic 1 km layout, both routes,
  several night positions, query radii and vertical separation. Actual pack
  activation, population order, moving targets, sleep, spent state, muffled
  noise, siege arrival, once-only spawning and dawn dismissal are exercised.
  The largest candidate group was 99 of 1,024 packs. This is a bounded-search
  correctness observation, not a measured frame-time improvement.

Run the owned scenes in the prepared isolated project with
`tools/wide_frontier_opening_checks.ps1 -Scene new_world_startup` and
`-Scene wide_frontier_pacing`. `-Capture` renders the actual normal chooser to
`build/wide-frontier/seed-chooser.png` without choosing a class or generating
terrain. Test saves are isolated fixture files; the
player's running game and save are untouched. Whole-world generation/performance
evidence and human pacing limitations belong to the main intensive report.

`-Preparing` captures the real preparation frame to
`build/wide-frontier/seed-preparing.png` before a controlled host refuses
generation. This verifies the frame is actually rendered while terrain remains
empty; it is not a measurement of native generation duration.
